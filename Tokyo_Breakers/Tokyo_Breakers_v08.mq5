//+------------------------------------------------------------------+
//|                                               Tokyo Breakers.mq5 |
//|                                             Jose Antonio Montero |
//|                      https://www.linkedin.com/in/joseamontero/   |
//+------------------------------------------------------------------+
#property copyright "Jose Antonio Montero"
#property link      "https://www.linkedin.com/in/joseamontero/"
#property version   "2.02"

//--- Include the trading library
#include <Trade\Trade.mqh>

//--- Input Parameters
input group "Configuración Indicador (Bandas de Bollinger)"
input int BB_Period = 21;              // Periodo de las Bandas de Bollinger
input double BB_Deviation = 1.3;       // Desviación de las Bandas de Bollinger

input group "Configuración Indicador Momentum"
input int Momentum_Period = 12;          // Período del Momentum
input double Momentum_Buy_Level = 109;   // Umbral para compras
input double Momentum_Sell_Level = 99.5; // Umbral para ventas

input group "Gestión de Riesgo"
input double LotSize = 0.3;            // Tamaño de lote inicial
input int SL_Points = 400;             // Stop Loss en puntos
input int TP_Points = 300;             // Take Profit en puntos
input bool UseTrailingStop = false;    // Activar/desactivar Trailing Stop
input int TrailingStopActivation = 200;// Puntos de beneficio para activar trailing stop
input int TrailingStopStep = 200;      // Paso en puntos para ajustar el trailing stop
input int MaxPositions = 1;            // Máximo número de posiciones abiertas por dirección

input group "Configuración Operaciones"
input bool UseComboMultiplier = true;  // Activar/desactivar multiplicador de contratos
input double ComboMultiplier = 1.5;    // Multiplicador para el tamaño del lote tras ganancia
input double MaxContractSize = 0.6;    // Tamaño máximo del contrato
input bool UseBreakoutDistance = false; // Activar/desactivar apertura por rotura en la misma vela
input int BreakoutDistancePoints = 164;// Distancia en puntos gráficos para rotura en la misma vela
input int MaxComboSteps = 2;           // Máximo número de veces que se aplica el multiplicador

input group "Gestión de Cuenta (FTMO y Similares)"
input double MaxDailyLossFTMO = 500.0; // Pérdida diaria máxima permitida (USD)
input double SafetyBeltFactor = 0.8;   // Factor de cinturón de seguridad (0.0 a 1.0)
input bool UseBalanceTarget = false;   // Activar/desactivar objetivo de saldo
input double BalanceTarget = 11000.0;  // Saldo objetivo para cerrar el bot (USD)
input double MinOperatingBalance = 9050.0; // Saldo mínimo operativo (USD)

//--- Global Variables
int bb_handle;                                     // Handle para Bandas de Bollinger
int momentum_handle;                               // Handle para Momentum
double bb_upper[], bb_lower[], bb_mid[];           // Buffers para Bandas de Bollinger
double momentum_values[];                          // Buffer para Momentum
datetime last_bar;                                 // Control de nueva vela
bool waiting_for_inside_close = false;             // Indica si estamos esperando un cierre dentro de las Bandas
bool trading_disabled = false;                     // Indica si el trading está deshabilitado por pérdida diaria
double daily_start_balance;                        // Balance al inicio del día
datetime last_day_reset;                           // Último reseteo diario
double realized_loss = 0.0;                        // Pérdida realizada del día
double effective_max_daily_loss;                   // Límite de pérdida diaria con cinturón de seguridad
bool last_trade_winning = false;                   // Indica si la última operación fue ganadora
double current_lot_size = LotSize;                 // Tamaño de lote actual
int trailing_stop_step;                            // Variable global para el paso del trailing stop
datetime last_close_time;                          // Última vez que se cerró una posición
bool operation_opened_in_current_candle = false;   // Indica si se abrió una operación en la vela actual
double last_close_price = 0.0;                     // Último precio de cierre
ulong open_tickets[];                              // Lista de tickets abiertos
ulong closed_tickets[];                            // Lista de tickets cerrados recientemente
datetime last_processed_transaction;               // Última transacción procesada
ulong last_processed_deal;                         // Último ID de deal procesado
int combo_step_count = 0;                          // Contador de operaciones ganadoras consecutivas

//+---------------------------------------------------------------------+
//| Normalizar el tamaño del lote según las especificaciones del bróker |
//+---------------------------------------------------------------------+
double NormalizeLotSize(double lot)
{
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double normalized_lot = MathRound(lot / lot_step) * lot_step;
   normalized_lot = MathMax(min_lot, MathMin(max_lot, normalized_lot));
   int digits = (int)-MathLog10(lot_step);
   normalized_lot = NormalizeDouble(normalized_lot, digits);

   return normalized_lot;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("🚀 === INICIANDO EA Tokyo Breakers v2.02 ===");
   Print("📅 Fecha: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
   Print("💱 Símbolo: ", _Symbol, " | ⏰ Timeframe: H1");
   
   if(_Symbol != "USDJPY")
   {
      Print("❌ [ERROR] Este EA solo funciona con USDJPY. Símbolo actual: ", _Symbol);
      return(INIT_PARAMETERS_INCORRECT);
   }

   bb_handle = iBands(_Symbol, PERIOD_H1, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
   momentum_handle = iMomentum(_Symbol, PERIOD_H1, Momentum_Period, PRICE_CLOSE);

   if(bb_handle == INVALID_HANDLE || momentum_handle == INVALID_HANDLE)
   {
      Print("❌ [ERROR] No se pudieron inicializar los indicadores. Código de error: ", GetLastError());
      if(bb_handle != INVALID_HANDLE) IndicatorRelease(bb_handle);
      if(momentum_handle != INVALID_HANDLE) IndicatorRelease(momentum_handle);
      return(INIT_FAILED);
   }

   Print("📊 Indicadores inicializados:");
   Print("  ➡️ Bandas de Bollinger: Periodo = ", BB_Period, ", Desviación = ", BB_Deviation);
   Print("  ➡️ Momentum: Periodo = ", Momentum_Period, ", Umbral Compras = ", Momentum_Buy_Level, ", Umbral Ventas = ", Momentum_Sell_Level);

   ArraySetAsSeries(bb_upper, true);
   ArraySetAsSeries(bb_lower, true);
   ArraySetAsSeries(bb_mid, true);
   ArraySetAsSeries(momentum_values, true);

   daily_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   last_day_reset = TimeCurrent();
   last_close_time = 0;
   realized_loss = 0.0;
   trading_disabled = false;
   operation_opened_in_current_candle = false;
   ArrayResize(open_tickets, 0);
   ArrayResize(closed_tickets, 0);
   last_processed_transaction = 0;
   last_processed_deal = 0;

   // Cerrar posiciones preexistentes en USDJPY
   Print("🛑 [INFO] Verificando posiciones preexistentes en USDJPY...");
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         CTrade trade;
         if(trade.PositionClose(ticket))
         {
            Print("🔒 [INFO] Posición preexistente cerrada: Ticket = ", ticket);
         }
         else
         {
            Print("❌ [ERROR] No se pudo cerrar posición preexistente ", ticket, ": ", trade.ResultRetcodeDescription());
         }
      }
   }
   Print("✅ [INFO] No hay posiciones preexistentes abiertas.");

   // Verificación inicial para detectar si el precio está fuera de las bandas
   double close_price = iClose(_Symbol, PERIOD_H1, 1);
   double bb_upper_val[1], bb_lower_val[1];
   if(CopyBuffer(bb_handle, 1, 1, 1, bb_upper_val) >= 1 && CopyBuffer(bb_handle, 2, 1, 1, bb_lower_val) >= 1)
   {
      if(close_price > bb_upper_val[0] || close_price < bb_lower_val[0])
      {
         waiting_for_inside_close = true;
         Print("🔔 [INFO] Precio inicial fuera de las Bandas de Bollinger (", close_price, "). Esperando cierre dentro de las bandas.");
      }
      else
      {
         waiting_for_inside_close = false;
         Print("✅ [INFO] Precio inicial dentro de las Bandas de Bollinger (", close_price, "). Listo para operar.");
      }
      last_close_price = close_price;
   }
   else
   {
      waiting_for_inside_close = true;
      Print("❌ [ERROR] No se pudieron obtener las Bandas de Bollinger al inicio. Esperando cierre dentro de las bandas.");
   }

   if(SafetyBeltFactor <= 0.0 || SafetyBeltFactor > 1.0)
   {
      Print("⚠️ [WARNING] SafetyBeltFactor debe estar entre 0.0 y 1.0. Usando 0.95 por defecto.");
      effective_max_daily_loss = MaxDailyLossFTMO * 0.95;
   }
   else
   {
      effective_max_daily_loss = MaxDailyLossFTMO * SafetyBeltFactor;
   }
   Print("💰 [INFO] Límite de pérdida diaria: ", DoubleToString(effective_max_daily_loss, 2), " USD");
   Print("💰 [INFO] Balance inicial: ", DoubleToString(daily_start_balance, 2), " USD");

   if(TrailingStopActivation <= 0)
   {
      Print("❌ [ERROR] TrailingStopActivation debe ser mayor que 0.");
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(TrailingStopStep <= 0)
   {
      Print("⚠️ [WARNING] TrailingStopStep debe ser mayor que 0. Usando 10 por defecto.");
      trailing_stop_step = 10;
   }
   else
   {
      trailing_stop_step = TrailingStopStep;
   }
   Print("📈 [INFO] Trailing Stop: Activación = ", TrailingStopActivation, " puntos, Paso = ", TrailingStopStep, " puntos");

   if(MaxComboSteps < 1)
   {
      Print("❌ [ERROR] MaxComboSteps debe ser mayor o igual a 1.");
      return(INIT_PARAMETERS_INCORRECT);
   }
   combo_step_count = 0;
   current_lot_size = NormalizeLotSize(LotSize);
   Print("🔢 [INFO] Inicialización: Lote inicial = ", DoubleToString(current_lot_size, 4), ", Combo Step = ", combo_step_count);

   Print("✅ === EA INICIALIZADO CORRECTAMENTE ===");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("🛑 === FINALIZANDO EA Tokyo Breakers ===");
   Print("📅 Fecha: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
   Print("📊 Motivo de finalización: ", reason);
   if(bb_handle != INVALID_HANDLE) 
   {
      IndicatorRelease(bb_handle);
      Print("🗑️ [INFO] Indicador Bandas de Bollinger liberado.");
   }
   if(momentum_handle != INVALID_HANDLE) 
   {
      IndicatorRelease(momentum_handle);
      Print("🗑️ [INFO] Indicador Momentum liberado.");
   }
   ArrayFree(open_tickets);
   ArrayFree(closed_tickets);
   Print("🗑️ [INFO] Listas de tickets liberadas.");
   Print("✅ === EA FINALIZADO ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   CheckDailyReset();

   if(trading_disabled)
   {
      Print("⛔ [INFO] Trading desactivado. Esperando reseteo a las 00:00 (España).");
      return;
   }

   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   if(UseBalanceTarget && BalanceTarget > 0 && current_balance >= BalanceTarget && current_equity >= BalanceTarget)
   {
      Print("🎯 [EVENTO] Objetivo de saldo alcanzado: Balance = ", DoubleToString(current_balance, 2), ", Equity = ", DoubleToString(current_equity, 2), ", Objetivo = ", DoubleToString(BalanceTarget, 2), " USD");
      CloseAllPositions();
      trading_disabled = true;
      Print("⛔ [INFO] Trading desactivado permanentemente tras alcanzar objetivo.");
      return;
   }

   if(current_equity < MinOperatingBalance)
   {
      Print("🚨 [EVENTO] Equity por debajo del mínimo: Equity = ", DoubleToString(current_equity, 2), ", Mínimo = ", DoubleToString(MinOperatingBalance, 2), " USD");
      CloseAllPositions();
      trading_disabled = true;
      Print("⛔ [INFO] Trading desactivado permanentemente por equity bajo.");
      return;
   }

   double total_daily_loss = CalculateTotalDailyLoss();
   if(total_daily_loss <= -effective_max_daily_loss)
   {
      Print("🚨 [EVENTO] Límite de pérdida diaria alcanzado: Pérdida = ", DoubleToString(total_daily_loss, 2), ", Límite = ", DoubleToString(-effective_max_daily_loss, 2), " USD");
      CloseAllPositions();
      trading_disabled = true;
      Print("⛔ [INFO] Trading desactivado hasta las 00:00 (España).");
      return;
   }

   // Restablecer bandera al inicio de una nueva vela
   datetime current_bar = iTime(_Symbol, PERIOD_H1, 0);
   if(current_bar != last_bar)
   {
      Print("🕒 [INFO] Nueva vela H1: ", TimeToString(current_bar, TIME_DATE|TIME_MINUTES));
      operation_opened_in_current_candle = false;
      last_bar = current_bar;
      CheckTradingConditions();
   }

   if(UseBreakoutDistance)
   {
      CheckBreakoutConditions();
   }

   CheckExitConditions();
}

//+------------------------------------------------------------------+
//| Trade transaction handler for manual closes                      |
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
            ulong ticket = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
            long deal_reason = HistoryDealGetInteger(trans.deal, DEAL_REASON);
            
            // Ignorar si el deal ya fue procesado
            if(trans.deal == last_processed_deal)
            {
               Print("⚠️ [INFO] Deal ", trans.deal, " ignorado: ya procesado.");
               return;
            }

            // Ignorar si el ticket ya fue cerrado
            for(int i = 0; i < ArraySize(closed_tickets); i++)
            {
               if(closed_tickets[i] == ticket)
               {
                  Print("⚠️ [INFO] Transacción para ticket ", ticket, " ignorada: ya cerrada.");
                  return;
               }
            }

            // Ignorar si la transacción es muy reciente
            if(TimeCurrent() - last_processed_transaction < 1)
            {
               Print("⚠️ [INFO] Transacción para ticket ", ticket, " ignorada: evento demasiado reciente.");
               return;
            }

            // Verificar si el ticket estaba en la lista de abiertos
            bool is_valid_ticket = false;
            for(int i = 0; i < ArraySize(open_tickets); i++)
            {
               if(open_tickets[i] == ticket)
               {
                  is_valid_ticket = true;
                  break;
               }
            }

            if(!is_valid_ticket)
            {
               Print("⚠️ [WARNING] Cierre detectado para ticket desconocido: ", ticket, ", Motivo = ", deal_reason);
               return;
            }

            // Procesar cierres automáticos y manuales
            if(deal_reason == DEAL_REASON_TP || deal_reason == DEAL_REASON_SL || deal_reason == DEAL_REASON_CLIENT)
            {
               double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
               bool was_winning = (profit > 0);
               Print("📊 [EVENTO] Operación cerrada: Ticket = ", ticket, ", Profit = ", DoubleToString(profit, 2), " USD, Ganadora = ", was_winning ? "Sí" : "No");
            
               // Registrar el ticket como cerrado
               ArrayResize(closed_tickets, ArraySize(closed_tickets) + 1);
               closed_tickets[ArraySize(closed_tickets) - 1] = ticket;
            
               // Eliminar de la lista de abiertos
               int idx = -1;
               for(int i = 0; i < ArraySize(open_tickets); i++)
               {
                  if(open_tickets[i] == ticket)
                  {
                     idx = i;
                     break;
                  }
               }
               if(idx >= 0)
               {
                  for(int i = idx; i < ArraySize(open_tickets) - 1; i++)
                     open_tickets[i] = open_tickets[i + 1];
                  ArrayResize(open_tickets, ArraySize(open_tickets) - 1);
               }
            
               if(UseComboMultiplier)
               {
                  last_trade_winning = was_winning;
                  UpdateLotSize(was_winning);
               }

               last_processed_transaction = TimeCurrent();
               last_processed_deal = trans.deal;
            }
         }
      }
   }
}

//+-------------------------------------------------------------------+
//| Actualizar tamaño del lote basado en el resultado de la operación |
//+-------------------------------------------------------------------+
void UpdateLotSize(bool was_winning)
{
   if(!UseComboMultiplier)
   {
      current_lot_size = LotSize;
      combo_step_count = 0;
      return;
   }

   if(was_winning)
   {
      combo_step_count++;
      if(combo_step_count <= MaxComboSteps)
      {
         double new_lot_size = current_lot_size * ComboMultiplier;
         new_lot_size = MathMin(new_lot_size, MaxContractSize);
         current_lot_size = NormalizeLotSize(new_lot_size);
         Print("🔢 [INFO] Ganadora paso ", combo_step_count, ": lote actualizado = ", DoubleToString(current_lot_size, 4));
      }
      else
      {
         current_lot_size = LotSize;
         combo_step_count = 0;
         Print("🔁 [INFO] Máximo de pasos alcanzado (", MaxComboSteps, "). Reiniciando lote a ", DoubleToString(current_lot_size, 4));
      }
   }
   else
   {
      current_lot_size = LotSize;
      combo_step_count = 0;
      Print("🔻 [INFO] Operación perdedora. Reinicio de lote a ", DoubleToString(current_lot_size, 4));
   }
}

//+------------------------------------------------------------------+
//| Verificar condiciones de rotura en la vela actual                |
//+------------------------------------------------------------------+
void CheckBreakoutConditions()
{
   if(CopyBuffer(bb_handle, 1, 0, 1, bb_upper) < 1 || CopyBuffer(bb_handle, 2, 0, 1, bb_lower) < 1)
   {
      Print("⚠️ [WARNING] No se pudieron obtener datos de las Bandas de Bollinger en CheckBreakoutConditions.");
      return;
   }

   if(operation_opened_in_current_candle)
   {
      Print("⏳ [INFO] Operación ya abierta en esta vela. Esperando nueva vela.");
      return;
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(waiting_for_inside_close)
   {
      Print("⏳ [INFO] Esperando cierre dentro de las Bandas de Bollinger.");
      return;
   }

   datetime current_time = TimeCurrent();
   if(current_time - last_close_time < 60)
   {
      Print("⏳ [INFO] Tiempo desde último cierre (", current_time - last_close_time, " seg) menor a 60 seg. Evitando nueva operación.");
      return;
   }

   double distance = BreakoutDistancePoints * _Point;

   if(ask > bb_upper[0] + distance && CountOpenPositions(POSITION_TYPE_BUY) < MaxPositions)
   {
      Print("📈 [EVENTO] Compra por ruptura: Ask = ", DoubleToString(ask, _Digits), ", Banda Superior + Distancia = ", DoubleToString(bb_upper[0] + distance, _Digits));
      OpenBuyTrade();
      operation_opened_in_current_candle = true;
   }

   if(bid < bb_lower[0] - distance && CountOpenPositions(POSITION_TYPE_SELL) < MaxPositions)
   {
      Print("📉 [EVENTO] Venta por ruptura: Bid = ", DoubleToString(bid, _Digits), ", Banda Inferior - Distancia = ", DoubleToString(bb_lower[0] - distance, _Digits));
      OpenSellTrade();
      operation_opened_in_current_candle = true;
   }
}

//+------------------------------------------------------------------+
//| Contar posiciones abiertas por tipo                              |
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
//| Verificar condiciones de entrada                                 |
//+------------------------------------------------------------------+
void CheckTradingConditions()
{
   if(CopyBuffer(bb_handle, 1, 0, 2, bb_upper) < 2 || CopyBuffer(bb_handle, 2, 0, 2, bb_lower) < 2 ||
      CopyBuffer(momentum_handle, 0, 0, 2, momentum_values) < 2)
   {
      Print("⚠️ [WARNING] No se pudieron obtener datos de indicadores en CheckTradingConditions.");
      return;
   }

   if(operation_opened_in_current_candle)
   {
      Print("⏳ [INFO] Operación ya abierta en esta vela. Esperando nueva vela.");
      return;
   }

   double close_price = iClose(_Symbol, PERIOD_H1, 1);

   if(waiting_for_inside_close)
   {
      if(close_price > bb_lower[1] && close_price < bb_upper[1])
      {
         waiting_for_inside_close = false;
         Print("🔔 [EVENTO] Cierre dentro de las Bandas: Precio = ", DoubleToString(close_price, _Digits), ", Banda Inf = ", DoubleToString(bb_lower[1], _Digits), ", Banda Sup = ", DoubleToString(bb_upper[1], _Digits));
      }
      else
      {
         Print("⏳ [INFO] Precio fuera de las Bandas: ", DoubleToString(close_price, _Digits));
      }
      return;
   }

   datetime current_time = TimeCurrent();
   if(current_time - last_close_time < 60)
   {
      Print("⏳ [INFO] Tiempo desde último cierre (", current_time - last_close_time, " seg) menor a 60 seg. Evitando nueva operación.");
      return;
   }

   if(close_price > bb_upper[1] && momentum_values[1] > Momentum_Buy_Level && CountOpenPositions(POSITION_TYPE_BUY) < MaxPositions)
   {
      Print("📈 [EVENTO] Condición de compra: Precio = ", DoubleToString(close_price, _Digits), ", Banda Sup = ", DoubleToString(bb_upper[1], _Digits), ", Momentum = ", DoubleToString(momentum_values[1], 2), ", Umbral = ", Momentum_Buy_Level);
      OpenBuyTrade();
      operation_opened_in_current_candle = true;
   }

   if(close_price < bb_lower[1] && momentum_values[1] < Momentum_Sell_Level && CountOpenPositions(POSITION_TYPE_SELL) < MaxPositions)
   {
      Print("📉 [EVENTO] Condición de venta: Precio = ", DoubleToString(close_price, _Digits), ", Banda Inf = ", DoubleToString(bb_lower[1], _Digits), ", Momentum = ", DoubleToString(momentum_values[1], 2), ", Umbral = ", Momentum_Sell_Level);
      OpenSellTrade();
      operation_opened_in_current_candle = true;
   }

   last_close_price = close_price;
}

//+------------------------------------------------------------------+
//| Abrir operación de venta                                         |
//+------------------------------------------------------------------+
void OpenSellTrade()
{
   CTrade trade;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = ask + SL_Points * _Point;
   double tp = ask - TP_Points * _Point;

   double lot_size = NormalizeLotSize(MathMin(current_lot_size, MaxContractSize));

   if(lot_size < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) || 
      lot_size > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX))
   {
      Print("❌ [ERROR] Tamaño de lote inválido: Calculado = ", DoubleToString(lot_size, 4), ", Mínimo = ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), 4), ", Máximo = ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), 4));
      return;
   }

   if(trade.Sell(lot_size, _Symbol, ask, sl, tp))
   {
      waiting_for_inside_close = true;
      ulong ticket = trade.ResultOrder();
      ArrayResize(open_tickets, ArraySize(open_tickets) + 1);
      open_tickets[ArraySize(open_tickets) - 1] = ticket;
      Print("✅ [EVENTO] Venta abierta: Ticket = ", ticket, ", Lote = ", DoubleToString(lot_size, 4), ", Precio = ", DoubleToString(ask, _Digits), ", SL = ", DoubleToString(sl, _Digits), ", TP = ", DoubleToString(tp, _Digits));
   }
   else
   {
      Print("❌ [ERROR] No se pudo abrir venta: Código = ", trade.ResultRetcodeDescription(), ", Lote = ", DoubleToString(lot_size, 4));
   }
}

//+------------------------------------------------------------------+
//| Abrir operación de compra                                        |
//+------------------------------------------------------------------+
void OpenBuyTrade()
{
   CTrade trade;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = bid - SL_Points * _Point;
   double tp = bid + TP_Points * _Point;

   double lot_size = NormalizeLotSize(MathMin(current_lot_size, MaxContractSize));

   if(lot_size < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) || 
      lot_size > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX))
   {
      Print("❌ [ERROR] Tamaño de lote inválido: Calculado = ", DoubleToString(lot_size, 4), ", Mínimo = ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), 4), ", Máximo = ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), 4));
      return;
   }

   if(trade.Buy(lot_size, _Symbol, bid, sl, tp))
   {
      waiting_for_inside_close = true;
      ulong ticket = trade.ResultOrder();
      ArrayResize(open_tickets, ArraySize(open_tickets) + 1);
      open_tickets[ArraySize(open_tickets) - 1] = ticket;
      Print("✅ [EVENTO] Compra abierta: Ticket = ", ticket, ", Lote = ", DoubleToString(lot_size, 4), ", Precio = ", DoubleToString(bid, _Digits), ", SL = ", DoubleToString(sl, _Digits), ", TP = ", DoubleToString(tp, _Digits));
   }
   else
   {
      Print("❌ [ERROR] No se pudo abrir compra: Código = ", trade.ResultRetcodeDescription(), ", Lote = ", DoubleToString(lot_size, 4));
   }
}

//+------------------------------------------------------------------+
//| Verificar condiciones de salida y gestionar Trailing Stop        |
//+------------------------------------------------------------------+
void CheckExitConditions()
{
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl_price = PositionGetDouble(POSITION_SL);
         double tp_price = PositionGetDouble(POSITION_TP);

         bool hit_sl = (pos_type == POSITION_TYPE_BUY && current_price <= sl_price) ||
                       (pos_type == POSITION_TYPE_SELL && current_price >= sl_price);
         bool hit_tp = (pos_type == POSITION_TYPE_BUY && current_price >= tp_price) ||
                       (pos_type == POSITION_TYPE_SELL && current_price <= tp_price);

         if(hit_sl || hit_tp)
         {
            string reason = hit_sl ? "Stop Loss" : "Take Profit";
            Print("🔔 [EVENTO] Cierre automático: Ticket = ", ticket, ", Motivo = ", reason, ", Precio = ", DoubleToString(current_price, _Digits));
            ClosePosition(ticket, reason);
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
//| Gestionar Trailing Stop                                          |
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
               Print("📈 [INFO] Trailing Stop ajustado para Compra: Ticket = ", ticket, ", Nuevo SL = ", DoubleToString(new_sl, _Digits));
               if(!PositionSelectByTicket(ticket))
               {
                  ClosePosition(ticket, "Trailing Stop");
               }
            }
            else
            {
               Print("❌ [ERROR] No se pudo ajustar Trailing Stop para compra: ", trade.ResultRetcodeDescription());
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
               Print("📉 [INFO] Trailing Stop ajustado para Venta: Ticket = ", ticket, ", Nuevo SL = ", DoubleToString(new_sl, _Digits));
               if(!PositionSelectByTicket(ticket))
               {
                  ClosePosition(ticket, "Trailing Stop");
               }
            }
            else
            {
               Print("❌ [ERROR] No se pudo ajustar Trailing Stop para venta: ", trade.ResultRetcodeDescription());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Cerrar posición                                                  |
//+------------------------------------------------------------------+
void ClosePosition(ulong ticket, string reason)
{
   CTrade trade;
   double profit = 0.0;
   bool was_winning = false;

   // Verificar si el ticket ya fue cerrado
   for(int i = 0; i < ArraySize(closed_tickets); i++)
   {
      if(closed_tickets[i] == ticket)
      {
         Print("⚠️ [INFO] Intento de cerrar ticket ", ticket, " ignorado: ya cerrado.");
         return;
      }
   }

   // Obtener el beneficio neto desde el historial después del cierre
   if(trade.PositionClose(ticket))
   {
      waiting_for_inside_close = true;
      last_close_time = TimeCurrent();
      
      // Registrar el ticket como cerrado
      ArrayResize(closed_tickets, ArraySize(closed_tickets) + 1);
      closed_tickets[ArraySize(closed_tickets) - 1] = ticket;
      
      // Eliminar de la lista de abiertos
      int idx = -1;
      for(int i = 0; i < ArraySize(open_tickets); i++)
      {
         if(open_tickets[i] == ticket)
         {
            idx = i;
            break;
         }
      }
      if(idx >= 0)
      {
         for(int i = idx; i < ArraySize(open_tickets) - 1; i++)
            open_tickets[i] = open_tickets[i + 1];
         ArrayResize(open_tickets, ArraySize(open_tickets) - 1);
      }

      // Obtener el beneficio neto desde el historial
      HistorySelect(last_close_time - 60, last_close_time + 60);
      for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
      {
         ulong deal_ticket = HistoryDealGetTicket(i);
         if(HistoryDealSelect(deal_ticket) && HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID) == ticket &&
            HistoryDealGetInteger(deal_ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
            profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
            was_winning = (profit > 0);
            break;
         }
      }

      Print("🔒 [EVENTO] Posición cerrada: Ticket = ", ticket, ", Motivo = ", reason, ", Profit = ", DoubleToString(profit, 2), " USD, Ganadora = ", was_winning ? "Sí" : "No");
      
      if(UseComboMultiplier)
      {
         last_trade_winning = was_winning;
         UpdateLotSize(was_winning);
      }
   }
   else
   {
      Print("❌ [ERROR] No se pudo cerrar la posición ", ticket, ": ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Cerrar todas las posiciones                                      |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   Print("🛑 [EVENTO] Cierre masivo de posiciones:");
   bool was_winning = false;
   int closed_positions = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         Print("  🎫 Cerrando posición: Ticket ", ticket);
         ClosePosition(ticket, "Cierre masivo");
         was_winning = last_trade_winning;
         closed_positions++;
      }
   }
   if(UseComboMultiplier && closed_positions > 0)
   {
      UpdateLotSize(was_winning);
   }
   Print("✅ [INFO] Todas las posiciones cerradas.");
}

//+------------------------------------------------------------------+
//| Verificar reseteo diario para gestión de riesgo                  |
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
      
      // Limpiar la lista de tickets cerrados
      ArrayResize(closed_tickets, 0);
      Print("🗑️ [INFO] Lista de tickets cerrados limpiada.");

      if(trading_disabled)
      {
         trading_disabled = false;
         Print("🔄 [EVENTO] Trading reactivado: Balance = ", DoubleToString(daily_start_balance, 2), " USD, Fecha = ", TimeToString(utc_time, TIME_DATE|TIME_MINUTES), " (00:00 España)");
      }
      else
      {
         Print("🔄 [EVENTO] Reseteo diario: Balance = ", DoubleToString(daily_start_balance, 2), " USD, Fecha = ", TimeToString(utc_time, TIME_DATE|TIME_MINUTES), " (00:00 España)");
      }
   }
}

//+------------------------------------------------------------------+
//| Calcular pérdida diaria total                                    |
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