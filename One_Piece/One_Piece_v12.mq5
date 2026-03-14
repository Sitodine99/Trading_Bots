//+------------------------------------------------------------------+
//|                                                 One_Piece.v12.mq5|
//|                                              Jose Antonio Montero|
//|                         https://www.linkedin.com/in/joseamontero/|
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.05"

#include <Trade\Trade.mqh> // Incluir biblioteca para operaciones

double swingHighs_Array[];
double swingLows_Array[];

//-------------------------- Variables de entrada --------------------
input group "General"
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Marco temporal para el análisis

input group "Gestión de Riesgo"
input double LotSize = 0.6;                 // Volumen de la operación (lotes)
input int    SL_Points = 1920;               // Stop Loss en puntos gráficos
input int    TP_Points = 1850;               // Take Profit en puntos gráficos
input int    MaxPositions = 1;               // Máximo número de posiciones abiertas

input bool   UseTrailingStop = true;         // Activar/desactivar Trailing Stop
input int    TrailingStopActivation = 1900;  // Puntos para activar el trailing (beneficio)
input int    TrailingStopStep = 1120;         // Paso en puntos del trailing (bloques)

input group "Confirmaciones Adicionales"
input bool ConfirmBreakoutWithClose = false; // Confirmar ruptura con cierre de vela

input group "Gestión de Cuenta (FTMO y Similares)"
input double MaxDailyLossFTMO = 5000.0;       // Pérdida diaria máxima permitida (USD)
input double SafetyBeltFactor = 0.95;        // Factor de cinturón de seguridad (0.0 a 1.0)
input double MinOperatingBalance = 90050.0;   // Saldo mínimo operativo (USD)
input bool   UseBalanceTarget = true;        // Activar objetivo de saldo
input double BalanceTarget = 110001.0;        // Saldo objetivo para cerrar el bot (USD)

input group "Swing Parameters"
input int SwingLength = 10;                  // Número de velas para detectar swings (antes estaba fijo a 10)
input int MaxScanBars = 1500;                // Máximo barras para scan histórico al iniciar (ajusta según rendimiento)

//--------------------------- Global variables -----------------------
CTrade   trade;
static datetime last_bar;

double  daily_start_balance;     // Balance al inicio del día
datetime last_day_reset;         // Último reseteo diario
double  realized_loss = 0.0;     // Pérdida realizada del día
bool    trading_disabled = false;// Trading deshabilitado por pérdida diaria
double  effective_max_daily_loss;// Límite de pérdida diaria con cinturón de seguridad

double pendingSwingHigh = -1.0;
double pendingSwingLow = -1.0;

ENUM_TIMEFRAMES used_period;

//====================================================================
// Auxiliares (nuevas funciones mínimas para persistencia por reconstrucción)
//====================================================================
// Mantener arr[0] = último swing (más reciente), arr[1] = anterior (si existe)
void UpdateSwingArray(double &arr[], double value)
{
   if (ArraySize(arr) == 0)
   {
      ArrayResize(arr, 1);
      arr[0] = value;
   }
   else if (ArraySize(arr) == 1)
   {
      // hacer espacio para 2 y desplazar
      ArrayResize(arr, 2);
      arr[1] = arr[0];
      arr[0] = value;
   }
   else
   {
      // mantener sólo últimos 2 (como esperaba el resto del EA)
      arr[1] = arr[0];
      arr[0] = value;
   }
}

// Buscar índice de barra cuyo high/low coincide con price (limitado a barras disponibles)
int FindSwingIndex(double price, bool isHigh)
{
   int bars = iBars(_Symbol, used_period);
   for (int i = 0; i < bars; i++)
      if ((isHigh && high(i) == price) || (!isHigh && low(i) == price)) return i;
   return -1;
}

// Borra objetos previos Swing_ y Break_ para evitar duplicados al reiniciar
void ClearSwingBreakObjects()
{
   // Borrar todo lo que empiece por "Swing" y "Break"
   int total = ObjectsTotal(0);
   string name;
   for (int i = total - 1; i >= 0; i--)
   {
      name = ObjectName(0, i);
      if (StringFind(name, "Swing") == 0 || StringFind(name, "Break") == 0)
         ObjectDelete(0, name);
   }
   Print("LOG: Objetos Swing y Break previos borrados.");
}

//====================================================================
// utilidades (sin cambios importantes)
//====================================================================
double NormalizeLotSize(double lot)
{
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double normalized_lot = MathRound(lot / lot_step) * lot_step;
   normalized_lot = MathMax(min_lot, MathMin(max_lot, normalized_lot));
   int digits = (int)-MathLog10(lot_step);
   return NormalizeDouble(normalized_lot, digits);
}

double CalculateRiskUSD(double lot_size, int sl_points)
{
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   return lot_size * sl_points * tick_value;
}

bool ValidateStopLevels(double price, double sl, double tp)
{
   // Nivel mínimo y freeze level del bróker
   double min_stop_level = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double freeze_level   = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;

   if (min_stop_level > 0)
   {
      if (MathAbs(price - sl) < min_stop_level || MathAbs(price - tp) < min_stop_level)
      {
         Print("LOG Error: SL/TP demasiado cerca. MinStopLevel: ", DoubleToString(min_stop_level, _Digits));
         return false;
      }
   }
   if (freeze_level > 0)
   {
      if (MathAbs(price - sl) < freeze_level || MathAbs(price - tp) < freeze_level)
      {
         Print("LOG Error: dentro del FreezeLevel. Freeze: ", DoubleToString(freeze_level, _Digits));
         return false;
      }
   }
   return true;
}

//====================================================================
// Trailing Stop INSTANTÁNEO y ESCALONADO (sin cambios lógicos)
//====================================================================
bool ModifySLIfBetter(ulong ticket, double new_sl, double keep_tp)
{
   double price_now = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                      ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                      : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(!ValidateStopLevels(price_now, new_sl, keep_tp)) return false;

   double cur_sl = PositionGetDouble(POSITION_SL);
   if (cur_sl == new_sl || (cur_sl != 0.0 && ((PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && new_sl <= cur_sl) ||
                                              (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && new_sl >= cur_sl))))
      return false;

   if(trade.PositionModify(ticket, new_sl, keep_tp))
   {
      Print("LOG: SL modificado exitosamente para ticket ", ticket, " a ", DoubleToString(new_sl, _Digits));
      return true;
   }

   Print("LOG Trailing ERROR | Ticket:", ticket, " | Retcode:", trade.ResultRetcode(), " (", trade.ResultRetcodeDescription(), ")");
   return false;
}

void ManageTrailingStop(ulong ticket)
{
   if(!UseTrailingStop) return;

   if(!PositionSelectByTicket(ticket))
   {
      Print("LOG: No se pudo seleccionar la posición #", ticket);
      return;
   }

   ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(pos_type != POSITION_TYPE_BUY && pos_type != POSITION_TYPE_SELL) return;

   const double open_price   = PositionGetDouble(POSITION_PRICE_OPEN);
   const double current_tp   = PositionGetDouble(POSITION_TP);
   const double bid          = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask          = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double current_price= (pos_type == POSITION_TYPE_BUY) ? bid : ask;

   double points_profit = (pos_type == POSITION_TYPE_BUY)
                          ? (current_price - open_price) / _Point
                          : (open_price - current_price) / _Point;

   if(points_profit < TrailingStopActivation) 
   {
      return;
   }

   int blocks = (int)MathFloor((points_profit - TrailingStopActivation) / TrailingStopStep) + 1;
   if (blocks < 1) blocks = 1;

   double desired_sl;
   if (pos_type == POSITION_TYPE_BUY)
      desired_sl = NormalizeDouble(open_price + (blocks * TrailingStopStep * _Point), _Digits);
   else
      desired_sl = NormalizeDouble(open_price - (blocks * TrailingStopStep * _Point), _Digits);

   if (pos_type == POSITION_TYPE_BUY && desired_sl > bid) desired_sl = bid - (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point);
   if (pos_type == POSITION_TYPE_SELL && desired_sl < ask) desired_sl = ask + (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point);

   if(ModifySLIfBetter(ticket, desired_sl, current_tp))
   {
      Print((pos_type==POSITION_TYPE_BUY ? "LOG BUY" : "LOG SELL"),
            " Trailing Escalonado -> Bloques: ", blocks,
            " | SL: ", DoubleToString(desired_sl, _Digits),
            " | ProfitPts: ", (int)points_profit);
   }
}

//====================================================================
// gestión de posiciones (sin cambios)
//====================================================================
int CountOpenPositions()
{
   int count = 0;
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
         count++;
   }
   return count;
}

void CloseAllPositions()
{
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         double profit = PositionGetDouble(POSITION_PROFIT);
         if (trade.PositionClose(ticket))
            Print("LOG POSICIÓN CERRADA: Ticket #", ticket, " | Razón: Cierre masivo | Profit: ", DoubleToString(profit, 2));
         else
            Print("LOG ERROR: No se pudo cerrar posición #", ticket, ": ", trade.ResultRetcodeDescription());
      }
   }
}

//====================================================================
// control diario (sin cambios)
//====================================================================
void CheckDailyReset()
{
   datetime utc_time = TimeGMT();
   MqlDateTime utc_struct; TimeToStruct(utc_time, utc_struct);

   int hour_offset = (utc_struct.mon >= 3 && utc_struct.mon <= 10) ? 2 : 1;
   datetime spanish_time = utc_time + hour_offset * 3600;
   MqlDateTime spanish_struct; TimeToStruct(spanish_time, spanish_struct);

   bool is_reset_time = (spanish_struct.hour == 0 && spanish_struct.min == 0 && utc_time > last_day_reset + 60);
   if (is_reset_time)
   {
      daily_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      last_day_reset = utc_time;
      realized_loss = 0.0;
      Print("LOG RESETEO DIARIO REALIZADO: Balance inicial = $", DoubleToString(daily_start_balance, 2));
      if (trading_disabled)
      {
         trading_disabled = false;
         Print("LOG TRADING REACTIVADO: Operaciones habilitadas a las 00:00 España");
      }
   }
}

double CalculateTotalDailyLoss()
{
   double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double floating_pl = 0.0;

   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
         floating_pl += PositionGetDouble(POSITION_PROFIT);
   }

   realized_loss = current_balance - daily_start_balance;
   double total = realized_loss + floating_pl;
   return total;
}

//====================================================================
// ciclo de vida
//====================================================================
int OnInit()
{
   used_period = (TimeFrame == PERIOD_CURRENT ? _Period : TimeFrame);

   ArraySetAsSeries(swingHighs_Array, true);
   ArraySetAsSeries(swingLows_Array, true);
   last_bar = 0;

   // Validaciones (idénticas a las tuyas)
   if (SL_Points <= 0 || TP_Points <= 0)
   {
      Print("LOG Error: SL_Points y TP_Points deben ser > 0");
      return INIT_PARAMETERS_INCORRECT;
   }
   if (LotSize <= 0)
   {
      Print("LOG Error: LotSize debe ser > 0");
      return INIT_PARAMETERS_INCORRECT;
   }
   if (MaxPositions < 1)
   {
      Print("LOG Error: MaxPositions debe ser al menos 1");
      return INIT_PARAMETERS_INCORRECT;
   }
   if (UseTrailingStop && (TrailingStopActivation <= 0 || TrailingStopStep <= 0))
   {
      Print("LOG Error: TrailingStopActivation y TrailingStopStep deben ser > 0");
      return INIT_PARAMETERS_INCORRECT;
   }

   // Vars de gestión de riesgo
   daily_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   last_day_reset = TimeCurrent();
   realized_loss = 0.0;
   trading_disabled = false;

   if (SafetyBeltFactor <= 0.0 || SafetyBeltFactor > 1.0)
   {
      effective_max_daily_loss = MaxDailyLossFTMO * 0.95;
      Print("LOG WARNING: SafetyBeltFactor inválido, usando 0.95 | Límite diario: $", DoubleToString(effective_max_daily_loss, 2));
   }
   else
   {
      effective_max_daily_loss = MaxDailyLossFTMO * SafetyBeltFactor;
      Print("LOG INICIO: Límite de pérdida diaria establecido en $", DoubleToString(effective_max_daily_loss, 2));
   }

   // Info inicial
   double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double tick_value   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double normalized_lot = NormalizeLotSize(LotSize);

   if (normalized_lot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
   {
      Print("LOG Error: LotSize ", DoubleToString(LotSize, 2), " es menor que el mínimo permitido (",
            DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), 2), ")");
      return INIT_PARAMETERS_INCORRECT;
   }

   double risk_usd = CalculateRiskUSD(normalized_lot, SL_Points);
   Print("LOG One Piece v01 Inicializado | Símbolo: ", _Symbol,
         " | Spread: ", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), " puntos",
         " | Contract Size: ", DoubleToString(contract_size, 0),
         " | Tick Value: ", DoubleToString(tick_value, 2),
         " | LotSize Normalizado: ", DoubleToString(normalized_lot, 2),
         " | Riesgo por operación (SL=", SL_Points, "): ", DoubleToString(risk_usd, 2), " USD");

   // ==== RECONSTRUCCIÓN RETROACTIVA DE SWINGS Y BREAKS ====
   //Borrar objetos previos para evitar duplicados
   ClearSwingBreakObjects();

   int length = MathMax(1, SwingLength);
   int total_bars = iBars(_Symbol, used_period);
   int max_scan = MathMin(MaxScanBars, total_bars - 1);

   double last_high = 0.0, last_low = 0.0;
   int last_high_shift = total_bars;
   int last_low_shift = total_bars;

   // Barrer histórico desde 'length' hasta max_scan (igual lógica que cuando corría en tiempo real)
   Print("LOG: Iniciando reconstrucción histórica de swings (barras escaneadas: ", max_scan, ")");
   for (int i = max_scan - 1; i >= length; i--)
   {
      bool isHigh = true, isLow = true;
      for (int a = 1; a <= length; a++)
      {
         int left = i + a, right = i - a;
         if (left >= total_bars) { isHigh = isLow = false; break; }
         if (high(i) <= high(right) || high(i) < high(left)) isHigh = false;
         if (low(i) >= low(right) || low(i) > low(left)) isLow = false;
      }

      if (isHigh)
      {
         string name = "SwingH_" + IntegerToString(i);
         drawSwingPoint(name, time(i), high(i), 77, clrBlue, -1);
         if (last_high_shift == total_bars || i < last_high_shift)
         {
            last_high = high(i);
            last_high_shift = i;
         }
         UpdateSwingArray(swingHighs_Array, high(i));
      }
      if (isLow)
      {
         string name = "SwingL_" + IntegerToString(i);
         drawSwingPoint(name, time(i), low(i), 77, clrRed, +1);
         if (last_low_shift == total_bars || i < last_low_shift)
         {
            last_low = low(i);
            last_low_shift = i;
         }
         UpdateSwingArray(swingLows_Array, low(i));
      }
   }

   // Detectar si el último swing histórico fue roto y dibujar break histórico si corresponde
   if (last_high_shift != total_bars)
   {
      bool broken = false;
      int break_shift = -1;
      for (int j = last_high_shift - 1; j >= 0; j--)
      {
         if (high(j) > last_high)
         {
            broken = true;
            break_shift = j;
            break;
         }
      }
      if (broken)
      {
         drawBreakLevel("BreakH_" + IntegerToString(last_high_shift),
                        time(last_high_shift), last_high,
                        time(break_shift), last_high, clrBlue, -1);
         Print("LOG: Break histórico de Swing High detectado @ índice ", last_high_shift);
      }
      else
      {
         pendingSwingHigh = last_high;
         Print("LOG: Pendiente Swing High sin break: ", last_high);
      }
   }

   if (last_low_shift != total_bars)
   {
      bool broken = false;
      int break_shift = -1;
      for (int j = last_low_shift - 1; j >= 0; j--)
      {
         if (low(j) < last_low)
         {
            broken = true;
            break_shift = j;
            break;
         }
      }
      if (broken)
      {
         drawBreakLevel("BreakL_" + IntegerToString(last_low_shift),
                        time(last_low_shift), last_low,
                        time(break_shift), last_low, clrRed, +1);
         Print("LOG: Break histórico de Swing Low detectado @ índice ", last_low_shift);
      }
      else
      {
         pendingSwingLow = last_low;
         Print("LOG: Pendiente Swing Low sin break: ", last_low);
      }
   }

   Print("LOG RECONSTRUCCIÓN: swings cargados (H size=", ArraySize(swingHighs_Array), " L size=", ArraySize(swingLows_Array), ")");
   // ==== FIN RECONSTRUCCIÓN ====

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   // Dejamos como antes: borrar objetos Swing_ y Break_ al quitar el EA
   ObjectsDeleteAll(0, "Swing_", 0);
   ObjectsDeleteAll(0, "Break_", 0);
   Print("LOG One Piece v01 Finalizado | Motivo: ", reason);
}

//====================================================================
// OnTick (idéntico a tu versión original salvo que usa SwingLength variable)
//====================================================================
void OnTick()
{
   // Verificar reseteo diario
   CheckDailyReset();

   // Trailing SIEMPRE antes de cualquier otra lógica
   if (UseTrailingStop)
   {
      for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            ManageTrailingStop(ticket);
         }
      }
   }

   // Bloqueos de gestión de cuenta
   if (trading_disabled)
   {
      return;
   }

   // Objetivo de balance
   double current_equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if (UseBalanceTarget && BalanceTarget > 0 && current_balance >= BalanceTarget && current_equity >= BalanceTarget)
   {
      CloseAllPositions();
      trading_disabled = true;
      Print("LOG OBJETIVO ALCANZADO: Balance = $", DoubleToString(current_balance, 2),
            " | Equity = $", DoubleToString(current_equity, 2), " | Trading detenido");
      return;
   }

   // Saldo mínimo operativo
   if (current_equity < MinOperatingBalance)
   {
      CloseAllPositions();
      trading_disabled = true;
      Print("LOG PARADA: Equity = $", DoubleToString(current_equity, 2),
            " < Saldo mínimo ($", DoubleToString(MinOperatingBalance, 2), ") | Trading detenido");
      return;
   }

   // Límite de pérdida diaria
   double total_daily_loss = CalculateTotalDailyLoss();
   if (total_daily_loss <= -effective_max_daily_loss)
   {
      CloseAllPositions();
      trading_disabled = true;
      Print("LOG PÉRDIDA DIARIA MÁXIMA ALCANZADA: $", DoubleToString(total_daily_loss, 2),
            " | Trading detenido hasta reseteo diario");
      return;
   }

   // Respetar número de posiciones máximas
   if (CountOpenPositions() >= MaxPositions)
   {
      return;
   }

   //---------------- Señal basada en swings ----------------
   static bool isNewBar = false;
   int currBars = iBars(_Symbol, used_period);
   static int prevBars = currBars;
   if (prevBars == currBars) { 
      isNewBar = false; 
   }
   else { 
      isNewBar = true; 
      prevBars = currBars; 
   }

   int length = MathMax(1, SwingLength);
   int right_index, left_index;
   int curr_bar = length;
   bool isSwingHigh = true, isSwingLow = true;

   if (isNewBar)
   {
      for (int a = 1; a <= length; a++)
      {
         right_index = curr_bar - a;
         left_index  = curr_bar + a;
         if ((high(curr_bar) <= high(right_index)) || (high(curr_bar) < high(left_index)))
            isSwingHigh = false;
         if ((low(curr_bar) >= low(right_index)) || (low(curr_bar) > low(left_index)))
            isSwingLow = false;
      }

      if (isSwingHigh)
      {
         pendingSwingHigh = high(curr_bar);
         Print("LOG: SWING HIGH detectado @ BAR INDEX ", curr_bar, " H: ", high(curr_bar));
         drawSwingPoint("SwingH_" + IntegerToString(curr_bar), time(curr_bar), high(curr_bar), 77, clrBlue, -1);

         UpdateSwingArray(swingHighs_Array, pendingSwingHigh);
      }
      if (isSwingLow)
      {
         pendingSwingLow = low(curr_bar);
         Print("LOG: SWING LOW detectado @ BAR INDEX ", curr_bar, " L: ", low(curr_bar));
         drawSwingPoint("SwingL_" + IntegerToString(curr_bar), time(curr_bar), low(curr_bar), 77, clrRed, +1);

         UpdateSwingArray(swingLows_Array, pendingSwingLow);
      }
   }

   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double last_close = iClose(_Symbol, used_period, 1); // Cierre vela anterior

   // ------------------ Señales de compra ------------------
   if (pendingSwingHigh > 0 && (ConfirmBreakoutWithClose ? last_close > pendingSwingHigh : Ask > pendingSwingHigh))
   {
      Print("LOG $$$$$$$$$ BUY SIGNAL NOW. BREAK OF SWING HIGH | Confirmado con: ",
            ConfirmBreakoutWithClose ? "Cierre (" + DoubleToString(last_close, _Digits) + " > " + DoubleToString(pendingSwingHigh, _Digits) + ")"
                                     : "Precio (" + DoubleToString(Ask, _Digits) + " > " + DoubleToString(pendingSwingHigh, _Digits) + ")");
      int swing_H_index = FindSwingIndex(pendingSwingHigh, true);
      if (swing_H_index == -1) { 
         pendingSwingHigh = -1.0; 
         Print("LOG: Índice de Swing High no encontrado, invalidando pendiente.");
         return; 
      }

      bool isMSS_High = false;
      if (ArraySize(swingHighs_Array) >= 2 && ArraySize(swingLows_Array) >= 2)
         isMSS_High = swingHighs_Array[0] > swingHighs_Array[1] && swingLows_Array[0] > swingLows_Array[1];

      double sl_level = NormalizeDouble(Ask - SL_Points * _Point, _Digits);
      double tp_level = NormalizeDouble(Ask + TP_Points * _Point, _Digits);

      if (!ValidateStopLevels(Ask, sl_level, tp_level)) { 
         pendingSwingHigh = -1.0; 
         Print("LOG: Niveles SL/TP inválidos para BUY, invalidando pendiente.");
         return; 
      }

      double lot_size = NormalizeLotSize(LotSize);
      if (lot_size < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
      {
         Print("LOG Error: Tamaño de lote inválido: ", DoubleToString(lot_size, 2));
         pendingSwingHigh = -1.0; return;
      }

      double risk_usd = CalculateRiskUSD(lot_size, SL_Points);
      Print("LOG Abriendo compra | Riesgo: ", DoubleToString(risk_usd, 2), " USD | SL=", sl_level, " | TP=", tp_level, " | Volumen=", lot_size);

      if (trade.Buy(lot_size, _Symbol, Ask, sl_level, tp_level))
         Print("LOG Compra abierta: Ticket=", trade.ResultDeal(), " | Riesgo=", DoubleToString(risk_usd, 2), " USD");
      else
         Print("LOG Error al abrir compra: ", GetLastError());

      if (isMSS_High)
      {
         Print("LOG Alert! This is a Market Structure Shift (MSS) UPTREND");
         drawBreakLevel_MSS("BreakH_MSS_" + IntegerToString(swing_H_index), time(swing_H_index), high(swing_H_index),
                            time(0), high(swing_H_index), clrDarkGreen, -1);
      }
      else
      {
         drawBreakLevel("BreakH_" + IntegerToString(swing_H_index), time(swing_H_index), high(swing_H_index),
                        time(0), high(swing_H_index), clrBlue, -1);
      }

      pendingSwingHigh = -1.0;
      return;
   }

   // ------------------ Señales de venta -------------------
   if (pendingSwingLow > 0 && (ConfirmBreakoutWithClose ? last_close < pendingSwingLow : Bid < pendingSwingLow))
   {
      Print("LOG $$$$$$$$$ SELL SIGNAL NOW. BREAK OF SWING LOW | Confirmado con: ",
            ConfirmBreakoutWithClose ? "Cierre (" + DoubleToString(last_close, _Digits) + " < " + DoubleToString(pendingSwingLow, _Digits) + ")"
                                     : "Precio (" + DoubleToString(Bid, _Digits) + " < " + DoubleToString(pendingSwingLow, _Digits) + ")");
      int swing_L_index = FindSwingIndex(pendingSwingLow, false);
      if (swing_L_index == -1) { 
         pendingSwingLow = -1.0; 
         Print("LOG: Índice de Swing Low no encontrado, invalidando pendiente.");
         return; 
      }

      bool isMSS_Low = false;
      if (ArraySize(swingHighs_Array) >= 2 && ArraySize(swingLows_Array) >= 2)
         isMSS_Low = swingHighs_Array[0] < swingHighs_Array[1] && swingLows_Array[0] < swingLows_Array[1];

      double sl_level = NormalizeDouble(Bid + SL_Points * _Point, _Digits);
      double tp_level = NormalizeDouble(Bid - TP_Points * _Point, _Digits);

      if (!ValidateStopLevels(Bid, sl_level, tp_level)) { 
         pendingSwingLow = -1.0; 
         Print("LOG: Niveles SL/TP inválidos para SELL, invalidando pendiente.");
         return; 
      }

      double lot_size = NormalizeLotSize(LotSize);
      if (lot_size < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
      {
         Print("LOG Error: Tamaño de lote inválido: ", DoubleToString(lot_size, 2));
         pendingSwingLow = -1.0; return;
      }

      double risk_usd = CalculateRiskUSD(lot_size, SL_Points);
      Print("LOG Abriendo venta | Riesgo: ", DoubleToString(risk_usd, 2), " USD | SL=", sl_level, " | TP=", tp_level, " | Volumen=", lot_size);

      if (trade.Sell(lot_size, _Symbol, Bid, sl_level, tp_level))
         Print("LOG Venta abierta: Ticket=", trade.ResultDeal(), " | Riesgo=", DoubleToString(risk_usd, 2), " USD");
      else
         Print("LOG Error al abrir venta: ", GetLastError());

      if (isMSS_Low)
      {
         Print("LOG Alert! This is a Market Structure Shift (MSS) DOWNTREND");
         drawBreakLevel_MSS("BreakL_MSS_" + IntegerToString(swing_L_index), time(swing_L_index), low(swing_L_index),
                            time(0), low(swing_L_index), clrBlack, +1);
      }
      else
      {
         drawBreakLevel("BreakL_" + IntegerToString(swing_L_index), time(swing_L_index), low(swing_L_index),
                        time(0), low(swing_L_index), clrRed, +1);
      }

      pendingSwingLow = -1.0;
      return;
   }
}

//====================================================================
// auxiliares gráficos (idénticos con pequeña mejora: nombres de texto únicos)
//====================================================================
double high(int index)  { return iHigh(_Symbol, used_period, index); }
double low(int index)   { return iLow(_Symbol, used_period, index); }
datetime time(int index){ return iTime(_Symbol, used_period, index); }

void drawSwingPoint(string objName, datetime t, double price, int arrCode, color clr, int direction)
{
   // Si existe, actualizar; si no, crear
   if (ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_ARROW, 0, t, price);
      ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrCode);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 10);
   }
   else
   {
      ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrCode);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(0, objName, OBJPROP_TIME, 0, t);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, price);
   }

   if (direction > 0) ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
   if (direction < 0) ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);

   string objName_Descr = objName + "_Descr";
   if (ObjectFind(0, objName_Descr) < 0)
   {
      ObjectCreate(0, objName_Descr, OBJ_TEXT, 0, t, price);
      ObjectSetInteger(0, objName_Descr, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName_Descr, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, objName_Descr, OBJPROP_TEXT, "  BoS");
   }
   else
   {
      ObjectSetInteger(0, objName_Descr, OBJPROP_TIME, 0, t);
      ObjectSetDouble(0, objName_Descr, OBJPROP_PRICE, 0, price);
   }

   if (direction > 0) ObjectSetInteger(0, objName_Descr, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   if (direction < 0) ObjectSetInteger(0, objName_Descr, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);

   ChartRedraw(0);
}

void drawBreakLevel(string objName, datetime time1, double price1, datetime time2, double price2, color clr, int direction)
{
   if (ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_ARROWED_LINE, 0, time1, price1, time2, price2);
      ObjectSetInteger(0, objName, OBJPROP_TIME, 0, time1);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, price1);
      ObjectSetInteger(0, objName, OBJPROP_TIME, 1, time2);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, price2);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);

      string objName_Descr = objName + "_Descr";
      ObjectCreate(0, objName_Descr, OBJ_TEXT, 0, time2, price2);
      ObjectSetInteger(0, objName_Descr, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName_Descr, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, objName_Descr, OBJPROP_TEXT, "Break  ");
      if (direction > 0) ObjectSetInteger(0, objName_Descr, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      if (direction < 0) ObjectSetInteger(0, objName_Descr, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
   }
   ChartRedraw(0);
}

void drawBreakLevel_MSS(string objName, datetime time1, double price1, datetime time2, double price2, color clr, int direction)
{
   if (ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_ARROWED_LINE, 0, time1, price1, time2, price2);
      ObjectSetInteger(0, objName, OBJPROP_TIME, 0, time1);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, price1);
      ObjectSetInteger(0, objName, OBJPROP_TIME, 1, time2);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, price2);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 4);

      string objName_Descr = objName + "_Descr";
      ObjectCreate(0, objName_Descr, OBJ_TEXT, 0, time2, price2);
      ObjectSetInteger(0, objName_Descr, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName_Descr, OBJPROP_FONTSIZE, 13);
      ObjectSetString(0, objName_Descr, OBJPROP_TEXT, "Break (MSS)  ");
      if (direction > 0) ObjectSetInteger(0, objName_Descr, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      if (direction < 0) ObjectSetInteger(0, objName_Descr, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
   }
   ChartRedraw(0);
}
//+------------------------------------------------------------------+