//+------------------------------------------------------------------+
//|                                                 John Wick H4.mq5 |
//|                                             Jose Antonio Montero |
//|                        https://www.linkedin.com/in/joseamontero/ |
//+------------------------------------------------------------------+
#property copyright "Jose Antonio Montero"
#property link      "https://www.linkedin.com/in/joseamontero/"
#property version   "2.00"

//--- Include the trading library
#include <Trade\Trade.mqh>

//--- Input Parameters
input group "Configuración Indicador (Bandas de Bollinger)"
input int BB_Period = 36;               // Periodo de las Bandas de Bollinger
input double BB_Deviation = 2.0;        // Desviación de las Bandas de Bollinger

input group "Gestión de Riesgo"
input double LotSize = 0.5;             // Tamaño de lote inicial
input double MaxContractSize = 0.5;     // Tamaño máximo del contrato
input bool UseComboMultiplier = true;   // Activar/desactivar multiplicador de contratos
input double ComboMultiplier = 2.0;     // Multiplicador para el tamaño del lote tras ganancia
input int SL_Points = 700;              // Stop Loss en puntos (1 punto = 0.00001 en AUDCAD)
input bool UseTrailingStop = true;      // Activar/desactivar Trailing Stop
input int TrailingStopActivation = 150; // Puntos de beneficio para activar trailing stop
input int TrailingStopStep = 10;        // Paso en puntos para ajustar el trailing stop

input group "Configuración Operaciones"
input int MaxPositions = 2;             // Máximo número de posiciones abiertas por dirección
input int CandleSeparation = 7;         // Separación mínima en velas entre operaciones en la misma dirección
input bool UseBreakoutDistance = true;  // Activar/desactivar apertura por rotura en la misma vela
input int BreakoutDistancePoints = 150; // Distancia en puntos gráficos para rotura en la misma vela

input group "Gestión de Cuenta (FTMO y Similares)"
input double MaxDailyLossFTMO = 500.0;  // Pérdida diaria máxima permitida (USD)
input double SafetyBeltFactor = 0.5;    // Factor de cinturón de seguridad (0.0 a 1.0)
input double MinOperatingBalance = 9050.0; // Saldo mínimo operativo (USD)
input bool UseBalanceTarget = true;     // Activar/desactivar objetivo de saldo
input double BalanceTarget = 11000.0;   // Saldo objetivo para cerrar el bot (USD)

//--- Global Variables
int bb_handle;                          // Handle para Bandas de Bollinger
double bb_upper[], bb_lower[], bb_mid[]; // Buffers para Bandas de Bollinger
datetime last_bar;                       // Control de nueva vela
datetime last_buy_time;                 // Hora de la última compra abierta
datetime last_sell_time;                // Hora de la última venta abierta
bool trading_disabled = false;          // Indica si el trading está deshabilitado por pérdida diaria
double daily_start_balance;             // Balance al inicio del día
datetime last_day_reset;                // Último reseteo diario
double realized_loss = 0.0;             // Pérdida realizada del día
double effective_max_daily_loss;        // Límite de pérdida diaria con cinturón de seguridad
bool last_trade_winning = false;        // Indica si la última operación fue ganadora
double current_lot_size = LotSize;      // Tamaño de lote actual
int trailing_stop_step;                 // Variable global para el paso del trailing stop

//+------------------------------------------------------------------+
//| Normalizar el tamaño del lote según las especificaciones del bróker |
//+------------------------------------------------------------------+
double NormalizeLotSize(double lot)
{
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   // Redondear al múltiplo más cercano de lot_step
   double normalized_lot = MathRound(lot / lot_step) * lot_step;

   // Asegurar que esté dentro de los límites mínimo y máximo
   normalized_lot = MathMax(min_lot, MathMin(max_lot, normalized_lot));

   // Normalizar a la precisión correcta
   int digits = (int)-MathLog10(lot_step);
   normalized_lot = NormalizeDouble(normalized_lot, digits);

   return normalized_lot;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   if(_Symbol != "AUDCAD")
   {
      Print("🚨 ERROR: Este bot solo funciona con AUDCAD");
      return(INIT_PARAMETERS_INCORRECT);
   }

   bb_handle = iBands(_Symbol, PERIOD_H4, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
   if(bb_handle == INVALID_HANDLE)
   {
      Print("🚨 ERROR: No se pudo crear el indicador Bollinger");
      return(INIT_FAILED);
   }

   ArraySetAsSeries(bb_upper, true);
   ArraySetAsSeries(bb_lower, true);
   ArraySetAsSeries(bb_mid, true);

   last_buy_time = 0;
   last_sell_time = 0;

   daily_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   last_day_reset = TimeCurrent();
   realized_loss = 0.0;
   trading_disabled = false;
   if(SafetyBeltFactor <= 0.0 || SafetyBeltFactor > 1.0)
   {
      effective_max_daily_loss = MaxDailyLossFTMO * 0.95;
      Print("⚠️ WARNING: SafetyBeltFactor inválido, usando 0.95 | Límite diario: $", DoubleToString(effective_max_daily_loss, 2));
   }
   else
   {
      effective_max_daily_loss = MaxDailyLossFTMO * SafetyBeltFactor;
      Print("✅ INICIO: Límite de pérdida diaria establecido en $", DoubleToString(effective_max_daily_loss, 2));
   }

   if(TrailingStopActivation <= 0)
   {
      Print("🚨 ERROR: TrailingStopActivation debe ser mayor que 0");
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(TrailingStopStep <= 0)
   {
      Print("⚠️ WARNING: TrailingStopStep inválido, usando 10 puntos");
      trailing_stop_step = 10;
   }
   else
   {
      trailing_stop_step = TrailingStopStep;
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(bb_handle != INVALID_HANDLE) IndicatorRelease(bb_handle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   CheckDailyReset();

   if(trading_disabled)
   {
      static bool wait_logged = false;
      if(!wait_logged)
      {
         Print("⏳ ESPERANDO: Trading deshabilitado, esperando reseteo diario a las 00:00 España");
         wait_logged = true;
      }
      return;
   }

   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   if(UseBalanceTarget && BalanceTarget > 0 && current_balance >= BalanceTarget && current_equity >= BalanceTarget)
   {
      CloseAllPositions();
      trading_disabled = true;
      Print("🎯 OBJETIVO ALCANZADO: Balance = $", DoubleToString(current_balance, 2), 
            " | Equity = $", DoubleToString(current_equity, 2), " | Trading detenido");
      return;
   }

   if(current_equity < MinOperatingBalance)
   {
      CloseAllPositions();
      trading_disabled = true;
      Print("🛑 PARADA: Equity = $", DoubleToString(current_equity, 2), 
            " < Saldo mínimo ($", DoubleToString(MinOperatingBalance, 2), ") | Trading detenido");
      return;
   }

   double total_daily_loss = CalculateTotalDailyLoss();
   if(total_daily_loss <= -effective_max_daily_loss)
   {
      CloseAllPositions();
      trading_disabled = true;
      Print("🚨 PÉRDIDA DIARIA MÁXIMA ALCANZADA: $", DoubleToString(total_daily_loss, 2), 
            " | Trading detenido hasta reseteo diario");
      return;
   }

   if(UseBreakoutDistance)
   {
      CheckBreakoutConditions();
   }

   datetime current_bar = iTime(_Symbol, PERIOD_H4, 0);
   if(current_bar != last_bar)
   {
      last_bar = current_bar;
      CheckTradingConditions();
   }

   CheckExitConditions();
}

//+------------------------------------------------------------------+
//| Trade transaction handler for manual closes                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      if(HistoryDealSelect(trans.deal))
      {
         if(HistoryDealGetString(trans.deal, DEAL_SYMBOL) == _Symbol &&
            HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
            double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
            bool was_winning = (profit > 0);
            if(UseComboMultiplier)
            {
               last_trade_winning = was_winning;
               double new_lot_size = was_winning ? current_lot_size * ComboMultiplier : LotSize;
               current_lot_size = NormalizeLotSize(new_lot_size);
               Print("🔢 LOTE ACTUALIZADO (CIERRE MANUAL): Calculado = ", DoubleToString(new_lot_size, 2), 
                     " | Normalizado = ", DoubleToString(current_lot_size, 2), 
                     " | Ganadora = ", was_winning, " | Profit = ", DoubleToString(profit, 2));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Verificar condiciones de rotura en la vela actual                  |
//+------------------------------------------------------------------+
void CheckBreakoutConditions()
{
   if(CopyBuffer(bb_handle, 1, 0, 1, bb_upper) < 1 || CopyBuffer(bb_handle, 2, 0, 1, bb_lower) < 1)
   {
      return;
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   datetime current_time = TimeCurrent();

   bool can_open_sell = true;
   if(last_sell_time > 0)
   {
      int bars_since_last_sell = iBarShift(_Symbol, PERIOD_H4, last_sell_time, current_time);
      if(bars_since_last_sell < CandleSeparation)
         can_open_sell = false;
   }

   bool can_open_buy = true;
   if(last_buy_time > 0)
   {
      int bars_since_last_buy = iBarShift(_Symbol, PERIOD_H4, last_buy_time, current_time);
      if(bars_since_last_buy < CandleSeparation)
         can_open_buy = false;
   }

   double distance = BreakoutDistancePoints * _Point;

   if(ask > bb_upper[0] + distance && CountOpenPositions(POSITION_TYPE_SELL) < MaxPositions && can_open_sell)
   {
      OpenSellTrade();
   }

   if(bid < bb_lower[0] - distance && CountOpenPositions(POSITION_TYPE_BUY) < MaxPositions && can_open_buy)
   {
      OpenBuyTrade();
   }
}

//+------------------------------------------------------------------+
//| Contar posiciones abiertas por tipo                               |
//+------------------------------------------------------------------+
int CountOpenPositions(ENUM_POSITION_TYPE type)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         if(PositionGetInteger(POSITION_TYPE) == type)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Verificar condiciones de entrada                                  |
//+------------------------------------------------------------------+
void CheckTradingConditions()
{
   if(CopyBuffer(bb_handle, 1, 0, 2, bb_upper) < 2 || 
      CopyBuffer(bb_handle, 2, 0, 2, bb_lower) < 2 || 
      CopyBuffer(bb_handle, 0, 0, 2, bb_mid) < 2)
   {
      return;
   }

   double close_price = iClose(_Symbol, PERIOD_H4, 1);
   datetime current_time = iTime(_Symbol, PERIOD_H4, 0);

   bool can_open_sell = true;
   if(last_sell_time > 0)
   {
      int bars_since_last_sell = iBarShift(_Symbol, PERIOD_H4, last_sell_time, current_time);
      if(bars_since_last_sell < CandleSeparation)
         can_open_sell = false;
   }

   bool can_open_buy = true;
   if(last_buy_time > 0)
   {
      int bars_since_last_buy = iBarShift(_Symbol, PERIOD_H4, last_buy_time, current_time);
      if(bars_since_last_buy < CandleSeparation)
         can_open_buy = false;
   }

   if(close_price > bb_upper[1] && CountOpenPositions(POSITION_TYPE_SELL) < MaxPositions && can_open_sell)
   {
      OpenSellTrade();
   }

   if(close_price < bb_lower[1] && CountOpenPositions(POSITION_TYPE_BUY) < MaxPositions && can_open_buy)
   {
      OpenBuyTrade();
   }
}

//+------------------------------------------------------------------+
//| Abrir operación de venta                                          |
//+------------------------------------------------------------------+
void OpenSellTrade()
{
   CTrade trade;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = ask + SL_Points * _Point;
   double tp = 0;

   double lot_size = NormalizeLotSize(MathMin(current_lot_size, MaxContractSize));

   if(lot_size < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) || 
      lot_size > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX))
   {
      Print("🚨 ERROR: Tamaño de lote inválido: ", DoubleToString(lot_size, 2), 
            " | Min = ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), 2), 
            " | Max = ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), 2));
      return;
   }

   if(trade.Sell(lot_size, _Symbol, ask, sl, tp))
   {
      last_sell_time = iTime(_Symbol, PERIOD_H4, 0);
      Print("📉 VENTA ABIERTA: Ticket #", trade.ResultOrder(), 
            " | Lote: ", DoubleToString(lot_size, 2), 
            " | Precio: ", DoubleToString(ask, _Digits), 
            " | SL: ", DoubleToString(sl, _Digits));
   }
   else
   {
      Print("🚨 ERROR: No se pudo abrir venta: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Abrir operación de compra                                         |
//+------------------------------------------------------------------+
void OpenBuyTrade()
{
   CTrade trade;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = bid - SL_Points * _Point;
   double tp = 0;

   double lot_size = NormalizeLotSize(MathMin(current_lot_size, MaxContractSize));

   if(lot_size < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) || 
      lot_size > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX))
   {
      Print("🚨 ERROR: Tamaño de lote inválido: ", DoubleToString(lot_size, 2), 
            " | Min = ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), 2), 
            " | Max = ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), 2));
      return;
   }

   if(trade.Buy(lot_size, _Symbol, bid, sl, tp))
   {
      last_buy_time = iTime(_Symbol, PERIOD_H4, 0);
      Print("📈 COMPRA ABIERTA: Ticket #", trade.ResultOrder(), 
            " | Lote: ", DoubleToString(lot_size, 2), 
            " | Precio: ", DoubleToString(bid, _Digits), 
            " | SL: ", DoubleToString(sl, _Digits));
   }
   else
   {
      Print("🚨 ERROR: No se pudo abrir compra: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Verificar condiciones de salida y gestionar Trailing Stop         |
//+------------------------------------------------------------------+
void CheckExitConditions()
{
   if(CopyBuffer(bb_handle, 0, 0, 1, bb_mid) < 1)
   {
      return;
   }

   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl_price = PositionGetDouble(POSITION_SL);

         bool close_position = false;
         if(pos_type == POSITION_TYPE_BUY && current_price >= bb_mid[0])
            close_position = true;
         else if(pos_type == POSITION_TYPE_SELL && current_price <= bb_mid[0])
            close_position = true;

         bool hit_sl = false;
         if(pos_type == POSITION_TYPE_BUY && current_price <= sl_price)
            hit_sl = true;
         else if(pos_type == POSITION_TYPE_SELL && current_price >= sl_price)
            hit_sl = true;

         if(close_position || hit_sl)
         {
            string reason = hit_sl ? "Stop Loss" : "Banda central";
            ClosePosition(ticket, reason, profit);
            continue;
         }

         if(UseTrailingStop)
         {
            ManageTrailingStop(ticket, pos_type, open_price, current_price);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Gestionar Trailing Stop                                           |
//+------------------------------------------------------------------+
void ManageTrailingStop(ulong ticket, ENUM_POSITION_TYPE pos_type, double open_price, double current_price)
{
   if(!UseTrailingStop)
      return;

   CTrade trade;
   double current_sl = PositionGetDouble(POSITION_SL);
   double points_profit = 0.0;

   if(pos_type == POSITION_TYPE_BUY)
   {
      points_profit = (current_price - open_price) / _Point;

      if(points_profit >= TrailingStopActivation)
      {
         double new_sl = current_price - trailing_stop_step * _Point;
         if(current_sl < new_sl)
         {
            if(trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP)))
            {
               Print("🔧 TRAILING STOP AJUSTADO: Ticket #", ticket, 
                     " | Nuevo SL: ", DoubleToString(new_sl, _Digits), 
                     " | Trailing: ", trailing_stop_step, " puntos");
            }
         }
      }
   }
   else if(pos_type == POSITION_TYPE_SELL)
   {
      points_profit = (open_price - current_price) / _Point;

      if(points_profit >= TrailingStopActivation)
      {
         double new_sl = current_price + trailing_stop_step * _Point;
         if(current_sl == 0 || current_sl > new_sl)
         {
            if(trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP)))
            {
               Print("🔧 TRAILING STOP AJUSTADO: Ticket #", ticket, 
                     " | Nuevo SL: ", DoubleToString(new_sl, _Digits), 
                     " | Trailing: ", trailing_stop_step, " puntos");
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Cerrar posición                                                   |
//+------------------------------------------------------------------+
void ClosePosition(ulong ticket, string reason, double profit)
{
   CTrade trade;
   bool was_winning = (profit > 0);

   if(trade.PositionClose(ticket))
   {
      Print("🔒 POSICIÓN CERRADA: Ticket #", ticket, " | Razón: ", reason, 
            " | Profit: ", DoubleToString(profit, 2));
      if(UseComboMultiplier)
      {
         last_trade_winning = was_winning;
         double new_lot_size = was_winning ? current_lot_size * ComboMultiplier : LotSize;
         current_lot_size = NormalizeLotSize(new_lot_size);
         Print("🔢 LOTE ACTUALIZADO: Calculado = ", DoubleToString(new_lot_size, 2), 
               " | Normalizado = ", DoubleToString(current_lot_size, 2), 
               " | Ganadora = ", was_winning);
      }
   }
   else
   {
      Print("🚨 ERROR: No se pudo cerrar posición #", ticket, ": ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Cerrar todas las posiciones                                       |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         double profit = PositionGetDouble(POSITION_PROFIT);
         ClosePosition(ticket, "Cierre masivo", profit);
      }
   }
   current_lot_size = NormalizeLotSize(LotSize);
   Print("🔄 LOTE RESETEADO: Tamaño de lote = ", DoubleToString(current_lot_size, 2));
}

//+------------------------------------------------------------------+
//| Verificar reseteo diario                                          |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   datetime utc_time = TimeGMT();
   MqlDateTime utc_struct;
   TimeToStruct(utc_time, utc_struct);

   int hour_offset = (utc_struct.mon >= 3 && utc_struct.mon <= 10) ? 2 : 1;
   datetime spanish_time = utc_time + hour_offset * 3600;
   MqlDateTime spanish_struct;
   TimeToStruct(spanish_time, spanish_struct);

   bool is_reset_time = (spanish_struct.hour == 0 && spanish_struct.min == 0 && utc_time > last_day_reset + 60);
   if(is_reset_time)
   {
      daily_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      last_day_reset = utc_time;
      realized_loss = 0.0;
      Print("🔄 RESETEO DIARIO REALIZADO: Balance inicial = $", DoubleToString(daily_start_balance, 2));
      if(trading_disabled)
      {
         trading_disabled = false;
         last_buy_time = 0;
         last_sell_time = 0;
         Print("✅ TRADING REACTIVADO: Operaciones habilitadas a las 00:00 España");
      }
   }
}

//+------------------------------------------------------------------+
//| Calcular pérdida diaria total                                     |
//+------------------------------------------------------------------+
double CalculateTotalDailyLoss()
{
   double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double floating_loss = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         floating_loss += PositionGetDouble(POSITION_PROFIT);
      }
   }

   realized_loss = current_balance - daily_start_balance;
   double total_loss = realized_loss + floating_loss;
   return total_loss;
}