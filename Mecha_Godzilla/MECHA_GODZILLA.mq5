//+------------------------------------------------------------------+
//|                                              MECHA-GODZILLA.mq5  |
//|                                             Jose Antonio Montero |
//|                        https://www.linkedin.com/in/joseamontero/ |
//+------------------------------------------------------------------+

#property copyright "Jose Antonio Montero"
#property link      "https://www.linkedin.com/in/joseamontero/"
#property version   "1.23"

#include <Trade\Trade.mqh>

//--- Input Parameters
input group "Configuración General"
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;                    // Marco temporal
input double InitialBalance = 10000.0;                          // Saldo inicial de la cuenta en USD
input double FixedContractSize = 0.25;                          // Tamaño fijo del contrato
input group "Configuración del Grid"
input bool UseCandleBasedCentralPoint = false;                  // Usar cálculo del punto central basado en velas
input int CandlesToConsider = 500;                              // Nº de velas para el cálculo (UseCandleBasedCentralPoint = true )
input double FixedCentralPoint = 5355.0;                        // Punto central fijo (UseCandleBasedCentralPoint = false)
input double GridDistancePointsGraphics = 1500.0;               // Distancia entre niveles del grid (puntos)
input int MaxGridLevels = 50;                                   // Máximo número de niveles en el grid
input int MaxPositionsPerLevel = 2;                             // Máximo número de posiciones por nivel del grid
input bool LimitGridPositions = true;                           // Activar/desactivar límite de posiciones abiertas en el grid
input int MaxGridPositions = 6;                                 // Máximo número de posiciones abiertas en el grid (excluye coberturas)
input group "Gestión de Posiciones"
input bool UseStopLoss = false;                                 // Usar stop loss
input double StopLossPointsGraphics = 1500.0;                   // Stop loss en puntos (posiciones normales)
input group "Configuración de Coberturas (Hedging)"
input bool UseHedging = false;                                  // Activar/desactivar coberturas
input double HedgeContractSize = 0.1;                           // Tamaño del contrato para coberturas
input double HedgePointsBeforeSL = 50.0;                        // Puntos gráficos antes del SL para la cobertura
input bool UseHedgeStopLoss = false;                            // Activar/desactivar stop loss para las coberturas
input double HedgeStopLossPoints = 200.0;                       // Stop loss en puntos gráficos para las coberturas
input double HedgeTakeProfitPoints = 200.0;                     // Take profit en puntos gráficos para las coberturas
input group "Filtro ATR"
input bool UseAtrFilter = false;                                // Activar/desactivar filtro de ATR
input int AtrPeriod = 14;                                       // Período del ATR
input double AtrHigh = 0.0020;                                  // Límite superior del ATR (en valor absoluto, ej. 0.0020 = 20 pips)
input double AtrLow = 0.0005;                                   // Límite inferior del ATR (en valor absoluto, ej. 0.0005 = 5 pips)
input group "Gestión de Cuenta (FTMO y Similares)"
input bool UseBalanceTarget = true;                             // Activar/desactivar objetivo de saldo
input double BalanceTarget = 9565.68;                           // Saldo objetivo para cerrar el bot (USD)
input double MinOperatingBalance = 9050.0;                      // Saldo mínimo operativo (USD)
input double MaxDailyLossFTMO = 500.0;                          // Pérdida diaria máxima permitida por FTMO (USD)
input double SafetyBeltFactor = 0.5;                            // Factor de cinturón de seguridad (0.0 a 1.0, ej. 0.5 = 50%)

//--- Global Variables
double gridLevelsBuy[];
double gridLevelsSell[];
double centralPoint;
bool botActive = true;
CTrade trade;
double dailyStartBalance = 0.0;
datetime lastDayReset = 0;
bool tradingDisabled = false;
double minEquity = InitialBalance;
bool isInitialized = false;
int initialLevelSell = -1;
int initialLevelBuy = -1;
bool levelClosedSell[];
bool levelClosedBuy[];
int additionalPositionsOpenedSell[];
int additionalPositionsOpenedBuy[];
datetime lastStateSave = 0;
double realizedLoss = 0.0;  // Pérdida realizada del día actual
double effectiveMaxDailyLoss;   // Límite efectivo con cinturón de seguridad
datetime lastCandleTime = 0;    // Tiempo de la última vela procesada
int candlesSinceRecalc = 0;     // Contador de velas desde el último recálculo
datetime lastGridRecalcTime = 0;// Tiempo del último recálculo del grid
double lastPrice = 0.0;         // Precio anterior para detectar cruces
//--- ATR Variables
int atrHandle;                  // Handle del indicador ATR
double atrValues[];             // Array para almacenar los valores del ATR
double atrMax = 0.0;            // ATR máximo
double atrMin = DBL_MAX;        // ATR mínimo
double atrSum = 0.0;            // Suma de los valores del ATR para calcular el promedio
int atrCount = 0;               // Contador de valores del ATR

struct HedgePosition {
   ulong ticketMain;    // Ticket de la posición principal
   ulong ticketHedge;   // Ticket de la orden de cobertura
};
HedgePosition hedgePositions[];
int hedgeCount = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   ArrayResize(gridLevelsBuy, MaxGridLevels);
   ArrayResize(gridLevelsSell, MaxGridLevels);
   ArrayResize(levelClosedSell, MaxGridLevels);
   ArrayResize(levelClosedBuy, MaxGridLevels);
   ArrayResize(additionalPositionsOpenedSell, MaxGridLevels);
   ArrayResize(additionalPositionsOpenedBuy, MaxGridLevels);
   ArrayResize(hedgePositions, MaxGridLevels * MaxPositionsPerLevel);
   ArrayInitialize(levelClosedSell, false);
   ArrayInitialize(levelClosedBuy, false);
   ArrayInitialize(additionalPositionsOpenedSell, 0);
   ArrayInitialize(additionalPositionsOpenedBuy, 0);
   hedgeCount = 0;
   
   if(SafetyBeltFactor <= 0.0 || SafetyBeltFactor > 1.0) {
      Print("Error: SafetyBeltFactor debe estar entre 0.0 y 1.0. Usando 0.95 por defecto.");
      effectiveMaxDailyLoss = MaxDailyLossFTMO * 0.95;
   } else {
      effectiveMaxDailyLoss = MaxDailyLossFTMO * SafetyBeltFactor;
   }
   Print("Inicio - Límite efectivo de pérdida diaria: ", DoubleToString(effectiveMaxDailyLoss, 2), " USD");
   
   if(GlobalVariableCheck("BotState_Initialized") && GlobalVariableGet("BotState_SymbolStr") == _Symbol) {
      RestoreState();
      Print("Bot restaurado: Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
   } else {
      GlobalVariablesDeleteAll("BotState_");
      dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      lastDayReset = TimeCurrent();
      tradingDisabled = false;
      isInitialized = false;
      initialLevelSell = -1;
      initialLevelBuy = -1;
      realizedLoss = 0.0;
      lastCandleTime = iTime(_Symbol, Timeframe, 0);
      candlesSinceRecalc = 0;
      lastGridRecalcTime = TimeCurrent();
      lastPrice = 0.0;
      CalculateGrid();
      Print("Bot iniciado desde cero: Balance = ", DoubleToString(dailyStartBalance, 2), " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
      GlobalVariableSet("BotState_SymbolStr", _Symbol);
   }
   
   // Inicializar el indicador ATR
   atrHandle = iATR(_Symbol, Timeframe, AtrPeriod);
   if(atrHandle == INVALID_HANDLE) {
      Print("Error al inicializar el indicador ATR: ", GetLastError());
      return(INIT_FAILED);
   }
   
   DrawGridLines();
   lastStateSave = TimeCurrent();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(reason != REASON_CHARTCLOSE && reason != REASON_REMOVE) {
      SaveState();
      Print("Estado guardado antes de desconexión: Motivo = ", reason);
   } else {
      GlobalVariablesDeleteAll("BotState_");
      Print("Bot cerrado manualmente, estado borrado: Motivo = ", reason);
   }
   ObjectsDeleteAll(0, "GridLine_");
   
   // Imprimir estadísticas del ATR al final de la simulación
   if(atrCount > 0) {
      double atrAverage = atrSum / atrCount;
      Print("Estadísticas del ATR durante la simulación:");
      Print("ATR Máximo: ", DoubleToString(atrMax, 5));
      Print("ATR Mínimo: ", DoubleToString(atrMin, 5));
      Print("ATR Medio: ", DoubleToString(atrAverage, 5));
   } else {
      Print("No se calcularon valores del ATR durante la simulación.");
   }
   
   // Liberar el handle del indicador ATR
   if(atrHandle != INVALID_HANDLE) {
      IndicatorRelease(atrHandle);
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!botActive) {
      Print("Bot no activo: botActive = false");
      return;
   }

   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   datetime currentTime = TimeCurrent();
   if(currentTime - lastStateSave >= 3600) {
      SaveState();
      lastStateSave = currentTime;
      Print("Estado guardado: Balance = ", DoubleToString(currentBalance, 2), " | Equity = ", DoubleToString(currentEquity, 2));
   }
   
   datetime currentCandleTime = iTime(_Symbol, Timeframe, 0);
   if(currentCandleTime != lastCandleTime) {
      lastCandleTime = currentCandleTime;
      candlesSinceRecalc++;
      
      // Calcular el ATR en cada nueva vela
      double atr[];
      ArraySetAsSeries(atr, true);
      if(CopyBuffer(atrHandle, 0, 0, 1, atr) > 0) {
         double currentAtr = atr[0];
         if(currentAtr > atrMax) atrMax = currentAtr;
         if(currentAtr < atrMin) atrMin = currentAtr;
         atrSum += currentAtr;
         atrCount++;
      } else {
         Print("Error al obtener el valor del ATR: ", GetLastError());
      }
   }

   if(candlesSinceRecalc >= CandlesToConsider && UseCandleBasedCentralPoint) { // Solo recalcula si usa velas
      Print("Grid recalculado después de ", CandlesToConsider, " velas");
      CalculateGrid();
      DrawGridLines();
      CloseAllHedgeOrders();
      hedgeCount = 0;
      candlesSinceRecalc = 0;
      lastGridRecalcTime = currentTime;
      isInitialized = false;
   }
   
   // Modificación: Cerrar cuando tanto el saldo como la equidad alcanzan o superan el BalanceTarget
   if(UseBalanceTarget && currentBalance >= BalanceTarget && currentEquity >= BalanceTarget) {
      CloseAllPositions();
      CloseAllHedgeOrders();
      botActive = false;
      Print("Objetivo alcanzado: Balance = ", DoubleToString(currentBalance, 2), 
            " | Equity = ", DoubleToString(currentEquity, 2), 
            " | Todas las operaciones cerradas.");
      return;
   }
   
   if(currentEquity < MinOperatingBalance) {
      CloseAllPositions();
      CloseAllHedgeOrders();
      botActive = false;
      Print("Parada por equity mínimo: Equity = ", DoubleToString(currentEquity, 2), " < ", DoubleToString(MinOperatingBalance, 2));
      return;
   }
   
   CheckDailyReset();
   double totalDailyLoss = CalculateTotalDailyLoss();
   
   if(totalDailyLoss <= -effectiveMaxDailyLoss) {
      CloseAllPositions();
      CloseAllHedgeOrders();
      tradingDisabled = true;
      Print("Límite diario alcanzado: Pérdida = ", DoubleToString(totalDailyLoss, 2), " | Equity = ", DoubleToString(currentEquity, 2), " | Balance = ", DoubleToString(currentBalance, 2));
      return;
   }
   
   if(tradingDisabled) {
      Print("Trading deshabilitado: tradingDisabled = true");
      return;
   }

   if(!isInitialized) {
      initialLevelBuy = -1;
      initialLevelSell = -1;
      for(int i = 0; i < MaxGridLevels; i++) {
         if(currentPrice <= gridLevelsBuy[i] && gridLevelsBuy[i] > 0.0) {
            initialLevelBuy = i;
            break;
         }
         if(currentPrice >= gridLevelsSell[i] && gridLevelsSell[i] > 0.0) {
            initialLevelSell = i;
            break;
         }
      }
      
      isInitialized = true;
      lastPrice = currentPrice;
      Print("Bot inicializado: Buy Level = ", initialLevelBuy == -1 ? -1 : initialLevelBuy, " | Sell Level = ", initialLevelSell == -1 ? -1 : initialLevelSell, " | centralPoint = ", DoubleToString(centralPoint, 5));
      return;
   }
   
   ManageBuyPositions(currentPrice);
   ManageSellPositions(currentPrice);

   if(MathAbs(currentPrice - centralPoint) <= _Point) {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         if(PositionGetSymbol(i) == _Symbol) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
            CloseHedgeOrder(ticket);
            Print("Posición cerrada al tocar Nivel 0: Ticket #", ticket, " | Precio = ", DoubleToString(currentPrice, 5));
         }
      }
      ArrayInitialize(levelClosedBuy, false);
      ArrayInitialize(levelClosedSell, false);
      ArrayInitialize(additionalPositionsOpenedBuy, 0);
      ArrayInitialize(additionalPositionsOpenedSell, 0);
      isInitialized = false;
   }
   lastPrice = currentPrice;
}

//+------------------------------------------------------------------+
int CountGridPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol) {
         string comment = PositionGetString(POSITION_COMMENT);
         if(StringFind(comment, "Level ") >= 0 && StringFind(comment, "Hedge") < 0) {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
void OpenHedgeOrder(ENUM_POSITION_TYPE mainType, ulong ticketMain, double slPrice, int level)
{
   double hedgePrice, hedgeSL, hedgeTP;
   int attempts = 0;
   bool success = false;
   
   while(attempts < 3 && !success) {
      if(mainType == POSITION_TYPE_BUY) {
         hedgePrice = slPrice + HedgePointsBeforeSL * _Point;
         hedgeSL = UseHedgeStopLoss ? hedgePrice + HedgeStopLossPoints * _Point : 0.0;
         hedgeTP = hedgePrice - HedgeTakeProfitPoints * _Point;
         Print("Intentando abrir SellStop: Precio = ", DoubleToString(hedgePrice, 5), " | Volumen = ", DoubleToString(HedgeContractSize, 2), 
               " | SL = ", DoubleToString(hedgeSL, 5), " | TP = ", DoubleToString(hedgeTP, 5));
         if(trade.SellStop(HedgeContractSize, hedgePrice, _Symbol, hedgeSL, hedgeTP, ORDER_TIME_GTC, 0, "Hedge for Buy Level " + IntegerToString(level))) {
            success = true;
         } else {
            Print("Fallo al colocar SellStop de cobertura: Error = ", GetLastError(), " | Intento = ", attempts + 1);
            Sleep(100);
         }
      } else if(mainType == POSITION_TYPE_SELL) {
         hedgePrice = slPrice - HedgePointsBeforeSL * _Point;
         hedgeSL = UseHedgeStopLoss ? hedgePrice - HedgeStopLossPoints * _Point : 0.0;
         hedgeTP = hedgePrice + HedgeTakeProfitPoints * _Point;
         Print("Intentando abrir BuyStop: Precio = ", DoubleToString(hedgePrice, 5), " | Volumen = ", DoubleToString(HedgeContractSize, 2), 
               " | SL = ", DoubleToString(hedgeSL, 5), " | TP = ", DoubleToString(hedgeTP, 5));
         if(trade.BuyStop(HedgeContractSize, hedgePrice, _Symbol, hedgeSL, hedgeTP, ORDER_TIME_GTC, 0, "Hedge for Sell Level " + IntegerToString(level))) {
            success = true;
         } else {
            Print("Fallo al colocar BuyStop de cobertura: Error = ", GetLastError(), " | Intento = ", attempts + 1);
            Sleep(100);
         }
      }
      attempts++;
   }
   
   if(success) {
      ulong ticketHedge = trade.ResultOrder();
      if(ticketHedge > 0) {
         hedgePositions[hedgeCount].ticketMain = ticketMain;
         hedgePositions[hedgeCount].ticketHedge = ticketHedge;
         hedgeCount++;
         Print("Orden de cobertura colocada: Main Ticket = ", ticketMain, " | Hedge Ticket = ", ticketHedge, " | Nivel = ", level);
      } else {
         Print("Fallo al obtener ticket de cobertura: Error = ", GetLastError());
      }
   } else {
      Print("Fallo al abrir orden de cobertura tras ", attempts, " intentos para Main Ticket = ", ticketMain);
   }
}

//+------------------------------------------------------------------+
void CloseHedgeOrder(ulong ticketMain)
{
   for(int i = 0; i < hedgeCount; i++) {
      if(hedgePositions[i].ticketMain == ticketMain) {
         trade.OrderDelete(hedgePositions[i].ticketHedge);
         Print("Orden de cobertura cerrada: Main Ticket = ", ticketMain, " | Hedge Ticket = ", hedgePositions[i].ticketHedge);
         if(i < hedgeCount - 1) {
            hedgePositions[i] = hedgePositions[hedgeCount - 1];
         }
         hedgeCount--;
         break;
      }
   }
}

//+------------------------------------------------------------------+
void CloseAllHedgeOrders()
{
   for(int i = hedgeCount - 1; i >= 0; i--) {
      trade.OrderDelete(hedgePositions[i].ticketHedge);
      Print("Orden de cobertura cerrada (cierre masivo): Hedge Ticket = ", hedgePositions[i].ticketHedge);
      hedgeCount--;
   }
}

//+------------------------------------------------------------------+
void SaveState()
{
   GlobalVariableSet("BotState_Active", botActive ? 1.0 : 0.0);
   GlobalVariableSet("BotState_DailyStartBalance", dailyStartBalance);
   GlobalVariableSet("BotState_LastDayReset", (double)lastDayReset);
   GlobalVariableSet("BotState_TradingDisabled", tradingDisabled ? 1.0 : 0.0);
   GlobalVariableSet("BotState_MinEquity", minEquity);
   GlobalVariableSet("BotState_Initialized", isInitialized ? 1.0 : 0.0);
   GlobalVariableSet("BotState_InitialLevelSell", initialLevelSell);
   GlobalVariableSet("BotState_InitialLevelBuy", initialLevelBuy);
   GlobalVariableSet("BotState_CentralPoint", centralPoint);
   GlobalVariableSet("BotState_SymbolStr", _Symbol);
   GlobalVariableSet("BotState_RealizedLoss", realizedLoss);
   GlobalVariableSet("BotState_LastCandleTime", (double)lastCandleTime);
   GlobalVariableSet("BotState_CandlesSinceRecalc", candlesSinceRecalc);
   GlobalVariableSet("BotState_LastGridRecalcTime", (double)lastGridRecalcTime);
   GlobalVariableSet("BotState_LastPrice", lastPrice);
   
   for(int i = 0; i < MaxGridLevels; i++) {
      GlobalVariableSet("BotState_GridBuy_" + IntegerToString(i), gridLevelsBuy[i]);
      GlobalVariableSet("BotState_GridSell_" + IntegerToString(i), gridLevelsSell[i]);
      GlobalVariableSet("BotState_LevelClosedSell_" + IntegerToString(i), levelClosedSell[i] ? 1.0 : 0.0);
      GlobalVariableSet("BotState_LevelClosedBuy_" + IntegerToString(i), levelClosedBuy[i] ? 1.0 : 0.0);
      GlobalVariableSet("BotState_AdditionalSell_" + IntegerToString(i), additionalPositionsOpenedSell[i]);
      GlobalVariableSet("BotState_AdditionalBuy_" + IntegerToString(i), additionalPositionsOpenedBuy[i]);
   }
}

//+------------------------------------------------------------------+
void RestoreState()
{
   botActive = GlobalVariableGet("BotState_Active") == 1.0;
   dailyStartBalance = GlobalVariableGet("BotState_DailyStartBalance");
   lastDayReset = (datetime)GlobalVariableGet("BotState_LastDayReset");
   tradingDisabled = GlobalVariableGet("BotState_TradingDisabled") == 1.0;
   minEquity = GlobalVariableGet("BotState_MinEquity");
   isInitialized = GlobalVariableGet("BotState_Initialized") == 1.0;
   initialLevelSell = (int)GlobalVariableGet("BotState_InitialLevelSell");
   initialLevelBuy = (int)GlobalVariableGet("BotState_InitialLevelBuy");
   centralPoint = GlobalVariableGet("BotState_CentralPoint");
   realizedLoss = GlobalVariableGet("BotState_RealizedLoss");
   lastCandleTime = (datetime)GlobalVariableGet("BotState_LastCandleTime");
   candlesSinceRecalc = (int)GlobalVariableGet("BotState_CandlesSinceRecalc");
   lastGridRecalcTime = (datetime)GlobalVariableGet("BotState_LastGridRecalcTime");
   lastPrice = GlobalVariableGet("BotState_LastPrice");
   
   for(int i = 0; i < MaxGridLevels; i++) {
      gridLevelsBuy[i] = GlobalVariableGet("BotState_GridBuy_" + IntegerToString(i));
      gridLevelsSell[i] = GlobalVariableGet("BotState_GridSell_" + IntegerToString(i));
      levelClosedSell[i] = GlobalVariableGet("BotState_LevelClosedSell_" + IntegerToString(i)) == 1.0;
      levelClosedBuy[i] = GlobalVariableGet("BotState_LevelClosedBuy_" + IntegerToString(i)) == 1.0;
      additionalPositionsOpenedSell[i] = (int)GlobalVariableGet("BotState_AdditionalSell_" + IntegerToString(i));
      additionalPositionsOpenedBuy[i] = (int)GlobalVariableGet("BotState_AdditionalBuy_" + IntegerToString(i));
   }
}

//+------------------------------------------------------------------+
void CheckDailyReset()
{
   datetime utcTime = TimeGMT();
   MqlDateTime utcStruct;
   TimeToStruct(utcTime, utcStruct);
   
   int hourOffset = (utcStruct.mon >= 3 && utcStruct.mon <= 10) ? 2 : 1;
   datetime spanishTime = utcTime + hourOffset * 3600;
   MqlDateTime spanishStruct;
   TimeToStruct(spanishTime, spanishStruct);

   if(utcStruct.hour == (22 + (hourOffset == 1 ? 1 : 0)) && utcStruct.min == 0 && utcTime > lastDayReset + 60) {
      dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      lastDayReset = utcTime;
      realizedLoss = 0.0;
      if(tradingDisabled) {
         isInitialized = false;
         tradingDisabled = false;
         ArrayInitialize(levelClosedSell, false);
         ArrayInitialize(levelClosedBuy, false);
         ArrayInitialize(additionalPositionsOpenedSell, 0);
         ArrayInitialize(additionalPositionsOpenedBuy, 0);
         Print("Reset tras pérdida máxima: Balance = ", DoubleToString(dailyStartBalance, 2), " | Hora España = ", spanishStruct.hour, ":", spanishStruct.min);
      } else {
         Print("Reset diario: Balance = ", DoubleToString(dailyStartBalance, 2), " | Hora España = ", spanishStruct.hour, ":", spanishStruct.min);
      }
   }
}

//+------------------------------------------------------------------+
double CalculateTotalDailyLoss()
{
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double floatingLoss = 0.0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol) {
         floatingLoss += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   realizedLoss = currentBalance - dailyStartBalance;
   double totalLoss = realizedLoss + floatingLoss;
   return totalLoss;
}

//+------------------------------------------------------------------+
void CalculateGrid()
{
   if(UseCandleBasedCentralPoint) {
      // Cálculo basado en velas (comportamiento original)
      int bars = iBars(_Symbol, Timeframe);
      if(bars < CandlesToConsider) {
         Print("Error: No hay suficientes barras (", bars, ") para ", CandlesToConsider);
         return;
      }
      double high = iHigh(_Symbol, Timeframe, iHighest(_Symbol, Timeframe, MODE_HIGH, CandlesToConsider, 1));
      double low = iLow(_Symbol, Timeframe, iLowest(_Symbol, Timeframe, MODE_LOW, CandlesToConsider, 1));
      if(high == 0 || low == 0) {
         Print("Error: high o low no válidos");
         return;
      }
      centralPoint = (high + low) / 2;
      Print("Punto central calculado con velas: ", DoubleToString(centralPoint, 5));
   } else {
      // Usar el valor fijo proporcionado por el usuario
      if(FixedCentralPoint <= 0.0) {
         Print("Error: FixedCentralPoint debe ser mayor que 0. Usando precio actual como fallback.");
         centralPoint = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      } else {
         centralPoint = FixedCentralPoint;
      }
      Print("Punto central establecido manualmente: ", DoubleToString(centralPoint, 5));
   }

   double levelDistance = GridDistancePointsGraphics * _Point;
   
   for(int i = 0; i < MaxGridLevels; i++) {
      gridLevelsBuy[i] = centralPoint - (levelDistance * (i + 1));
      gridLevelsSell[i] = centralPoint + (levelDistance * (i + 1));
   }
}

//+------------------------------------------------------------------+
void DrawGridLines()
{
   ObjectsDeleteAll(0, "GridLine_");
   
   if(ObjectCreate(0, "GridLine_Level_0", OBJ_HLINE, 0, 0, centralPoint)) {
      ObjectSetInteger(0, "GridLine_Level_0", OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, "GridLine_Level_0", OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, "GridLine_Level_0", OBJPROP_WIDTH, 2);
   }
   
   for(int i = 0; i < MaxGridLevels; i++) {
      string nameBuy = "GridLine_Buy_Level_" + IntegerToString(i);
      if(ObjectCreate(0, nameBuy, OBJ_HLINE, 0, 0, gridLevelsBuy[i])) {
         ObjectSetInteger(0, nameBuy, OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, nameBuy, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, nameBuy, OBJPROP_WIDTH, 1);
      }
      
      string nameSell = "GridLine_Sell_Level_" + IntegerToString(i);
      if(ObjectCreate(0, nameSell, OBJ_HLINE, 0, 0, gridLevelsSell[i])) {
         ObjectSetInteger(0, nameSell, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, nameSell, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, nameSell, OBJPROP_WIDTH, 1);
      }
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
int CountPositionsAtLevel(ENUM_POSITION_TYPE type, int level)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_TYPE) == type && 
         StringFind(PositionGetString(POSITION_COMMENT), "Level " + IntegerToString(level)) >= 0) {
         count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
bool IsAtrWithinRange()
{
   if(!UseAtrFilter) return true;
   
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(atrHandle, 0, 0, 1, atr) <= 0) {
      Print("Error al obtener el valor del ATR: ", GetLastError());
      return false;
   }
   
   double currentAtr = atr[0];
   if(currentAtr < AtrLow || currentAtr > AtrHigh) {
      Print("No se abrirán nuevas operaciones - ATR fuera de rango: ", DoubleToString(currentAtr, 5), 
            " | Rango permitido: [", DoubleToString(AtrLow, 5), ", ", DoubleToString(AtrHigh, 5), "]");
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
void ManageBuyPositions(double currentPrice)
{
   if(!botActive || !isInitialized || tradingDisabled) {
      Print("ManageBuyPositions: No se ejecuta - botActive = ", botActive, " | isInitialized = ", isInitialized, " | tradingDisabled = ", tradingDisabled);
      return;
   }
   
   int highestBuyLevel = -1;
   for(int i = MaxGridLevels - 1; i >= 0; i--) {
      if(PositionExists(POSITION_TYPE_BUY, i)) {
         highestBuyLevel = i;
         break;
      }
   }

   for(int i = 0; i < MaxGridLevels; i++) {
      int positionsAtLevel = CountPositionsAtLevel(POSITION_TYPE_BUY, i);
      
      if(lastPrice > gridLevelsBuy[i] && currentPrice <= gridLevelsBuy[i]) {
         Print("ManageBuyPositions: Precio cruza nivel de compra ", i, " hacia abajo | gridLevelsBuy[", i, "] = ", DoubleToString(gridLevelsBuy[i], 5), 
               " | lastPrice = ", DoubleToString(lastPrice, 5), " | currentPrice = ", DoubleToString(currentPrice, 5), " | positionsAtLevel = ", positionsAtLevel);
         
         if(positionsAtLevel > 0) {
            Print("ManageBuyPositions: No se abre compra - Ya hay ", positionsAtLevel, " posiciones abiertas en este nivel");
            continue;
         }
         
         if(i == MaxGridLevels - 1 || highestBuyLevel == -1 || highestBuyLevel < i || (i < MaxGridLevels - 1 && levelClosedBuy[i+1])) {
            if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) {
               Print("ManageBuyPositions: No se abre compra - Límite de posiciones en el grid alcanzado (", MaxGridPositions, ")");
               continue;
            }
            if(!IsAtrWithinRange()) {
               Print("ManageBuyPositions: No se abre compra - Filtro de ATR no permite nuevas operaciones");
               continue;
            }
            double slPrice = UseStopLoss ? gridLevelsBuy[i] - StopLossPointsGraphics * _Point : 0;
            if(trade.Buy(FixedContractSize, _Symbol, 0, slPrice, 0, "Buy Level " + IntegerToString(i))) {
               ulong ticketMain = trade.ResultDeal();
               Print("Compra abierta nivel ", i, " | Precio = ", DoubleToString(currentPrice, 5), " | SL = ", DoubleToString(slPrice, 5), " | Ticket = ", ticketMain);
               if(UseHedging && ticketMain > 0 && UseStopLoss) {
                  OpenHedgeOrder(POSITION_TYPE_BUY, ticketMain, slPrice, i);
               }
               levelClosedBuy[i] = false;
               additionalPositionsOpenedBuy[i] = 0;
            } else {
               Print("ManageBuyPositions: Fallo al abrir compra: Error = ", GetLastError());
            }
            break;
         } else {
            Print("ManageBuyPositions: No se abre compra - Condición de nivel no cumplida: i = ", i, " | highestBuyLevel = ", highestBuyLevel, 
                  " | levelClosedBuy[", i+1, "] = ", levelClosedBuy[i+1]);
         }
      }

      if(i > 0 && currentPrice >= gridLevelsBuy[i-1] && PositionExists(POSITION_TYPE_BUY, i)) {
         bool positionsClosed = false;
         if(PositionExists(POSITION_TYPE_BUY, i)) {
            ClosePosition(POSITION_TYPE_BUY, i);
            Print("Compra cerrada nivel ", i, " | Precio = ", DoubleToString(currentPrice, 5), " | Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), 
                  " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
            levelClosedBuy[i] = true;
            positionsClosed = true;
         }

         int positionsAtUpperLevel = CountPositionsAtLevel(POSITION_TYPE_BUY, i-1);
         if(positionsClosed && positionsAtUpperLevel == 1 && additionalPositionsOpenedBuy[i-1] < 1) {
            if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) {
               Print("Límite de posiciones en el grid alcanzado (", MaxGridPositions, "). No se abrirá una nueva posición de compra.");
               continue;
            }
            if(!IsAtrWithinRange()) {
               Print("ManageBuyPositions: No se abre compra adicional - Filtro de ATR no permite nuevas operaciones");
               continue;
            }
            double slPrice = UseStopLoss ? gridLevelsBuy[i-1] - StopLossPointsGraphics * _Point : 0;
            if(trade.Buy(FixedContractSize, _Symbol, 0, slPrice, 0, "Buy Level " + IntegerToString(i-1))) {
               ulong ticketMain = trade.ResultDeal();
               Print("Compra adicional nivel ", i-1, " | Precio = ", DoubleToString(currentPrice, 5), " | SL = ", DoubleToString(slPrice, 5), " | Ticket = ", ticketMain);
               if(UseHedging && ticketMain > 0 && UseStopLoss) {
                  OpenHedgeOrder(POSITION_TYPE_BUY, ticketMain, slPrice, i-1);
               }
               levelClosedBuy[i-1] = false;
               additionalPositionsOpenedBuy[i-1] = 1;
            } else {
               Print("Fallo al abrir compra adicional: Error = ", GetLastError());
            }
         }
         break;
      }

      if(currentPrice >= centralPoint && PositionExists(POSITION_TYPE_BUY, 0)) {
         ClosePosition(POSITION_TYPE_BUY, 0);
         Print("Compra cerrada nivel 0 por centralPoint | Precio = ", DoubleToString(currentPrice, 5), " | Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), 
               " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
         levelClosedBuy[0] = true;
      }
   }
}

//+------------------------------------------------------------------+
void ManageSellPositions(double currentPrice)
{
   if(!botActive || !isInitialized || tradingDisabled) {
      Print("ManageSellPositions: No se ejecuta - botActive = ", botActive, " | isInitialized = ", isInitialized, " | tradingDisabled = ", tradingDisabled);
      return;
   }
   
   int highestSellLevel = -1;
   for(int i = MaxGridLevels - 1; i >= 0; i--) {
      if(PositionExists(POSITION_TYPE_SELL, i)) {
         highestSellLevel = i;
         break;
      }
   }

   for(int i = 0; i < MaxGridLevels; i++) {
      int positionsAtLevel = CountPositionsAtLevel(POSITION_TYPE_SELL, i);
      
      if(lastPrice < gridLevelsSell[i] && currentPrice >= gridLevelsSell[i]) {
         Print("ManageSellPositions: Precio cruza nivel de venta ", i, " hacia arriba | gridLevelsSell[", i, "] = ", DoubleToString(gridLevelsSell[i], 5), 
               " | lastPrice = ", DoubleToString(lastPrice, 5), " | currentPrice = ", DoubleToString(currentPrice, 5), " | positionsAtLevel = ", positionsAtLevel);
         
         if(positionsAtLevel > 0) {
            Print("ManageSellPositions: No se abre venta - Ya hay ", positionsAtLevel, " posiciones abiertas en este nivel");
            continue;
         }
         
         if(i == MaxGridLevels - 1 || highestSellLevel == -1 || highestSellLevel < i || (i < MaxGridLevels - 1 && levelClosedSell[i+1])) {
            if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) {
               Print("ManageSellPositions: No se abre venta - Límite de posiciones en el grid alcanzado (", MaxGridPositions, ")");
               continue;
            }
            if(!IsAtrWithinRange()) {
               Print("ManageSellPositions: No se abre venta - Filtro de ATR no permite nuevas operaciones");
               continue;
            }
            double slPrice = UseStopLoss ? gridLevelsSell[i] + StopLossPointsGraphics * _Point : 0;
            if(trade.Sell(FixedContractSize, _Symbol, 0, slPrice, 0, "Sell Level " + IntegerToString(i))) {
               ulong ticketMain = trade.ResultDeal();
               Print("Venta abierta nivel ", i, " | Precio = ", DoubleToString(currentPrice, 5), " | SL = ", DoubleToString(slPrice, 5), " | Ticket = ", ticketMain);
               if(UseHedging && ticketMain > 0 && UseStopLoss) {
                  OpenHedgeOrder(POSITION_TYPE_SELL, ticketMain, slPrice, i);
               }
               levelClosedSell[i] = false;
               additionalPositionsOpenedSell[i] = 0;
            } else {
               Print("ManageSellPositions: Fallo al abrir venta: Error = ", GetLastError());
            }
            break;
         } else {
            Print("ManageSellPositions: No se abre venta - Condición de nivel no cumplida: i = ", i, " | highestSellLevel = ", highestSellLevel, 
                  " | levelClosedSell[", i+1, "] = ", levelClosedSell[i+1]);
         }
      }

      if(i > 0 && currentPrice < gridLevelsSell[i-1] && PositionExists(POSITION_TYPE_SELL, i)) {
         bool positionsClosed = false;
         for(int j = MaxGridLevels - 1; j >= i; j--) {
            if(PositionExists(POSITION_TYPE_SELL, j)) {
               ClosePosition(POSITION_TYPE_SELL, j);
               Print("Venta cerrada nivel ", j, " | Precio = ", DoubleToString(currentPrice, 5), " | Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), 
                     " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
               levelClosedSell[j] = true;
               positionsClosed = true;
            }
         }

         int positionsAtLowerLevel = CountPositionsAtLevel(POSITION_TYPE_SELL, i-1);
         if(positionsClosed && positionsAtLowerLevel == 1 && additionalPositionsOpenedSell[i-1] < 1) {
            if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) {
               Print("Límite de posiciones en el grid alcanzado (", MaxGridPositions, "). No se abrirá una nueva posición de venta.");
               continue;
            }
            if(!IsAtrWithinRange()) {
               Print("ManageSellPositions: No se abre venta adicional - Filtro de ATR no permite nuevas operaciones");
               continue;
            }
            double slPrice = UseStopLoss ? gridLevelsSell[i-1] + StopLossPointsGraphics * _Point : 0;
            if(trade.Sell(FixedContractSize, _Symbol, 0, slPrice, 0, "Sell Level " + IntegerToString(i-1))) {
               ulong ticketMain = trade.ResultDeal();
               Print("Venta adicional nivel ", i-1, " | Precio = ", DoubleToString(currentPrice, 5), " | SL = ", DoubleToString(slPrice, 5), " | Ticket = ", ticketMain);
               if(UseHedging && ticketMain > 0 && UseStopLoss) {
                  OpenHedgeOrder(POSITION_TYPE_SELL, ticketMain, slPrice, i-1);
               }
               levelClosedSell[i-1] = false;
               additionalPositionsOpenedSell[i-1] = 1;
            } else {
               Print("Fallo al abrir venta adicional: Error = ", GetLastError());
            }
         }
      }

      if(currentPrice <= centralPoint && PositionExists(POSITION_TYPE_SELL, 0)) {
         ClosePosition(POSITION_TYPE_SELL, 0);
         Print("Venta cerrada nivel 0 por centralPoint | Precio = ", DoubleToString(currentPrice, 5), " | Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), 
               " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
         levelClosedSell[0] = true;
      }
   }
}

//+------------------------------------------------------------------+
bool PositionExists(ENUM_POSITION_TYPE type, int level)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_TYPE) == type && 
         StringFind(PositionGetString(POSITION_COMMENT), "Level " + IntegerToString(level)) >= 0) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
void ClosePosition(ENUM_POSITION_TYPE type, int level)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_TYPE) == type && 
         StringFind(PositionGetString(POSITION_COMMENT), "Level " + IntegerToString(level)) >= 0) {
         ulong ticket = PositionGetTicket(i);
         trade.PositionClose(ticket);
         CloseHedgeOrder(ticket);
      }
   }
}

//+------------------------------------------------------------------+
void CloseAllPositions()
{
   int attempts = 0;
   while(PositionsTotal() > 0 && attempts < 10) {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         if(PositionGetSymbol(i) == _Symbol) {
            ulong ticket = PositionGetTicket(i);
            if(trade.PositionClose(ticket)) {
               CloseHedgeOrder(ticket);
               Print("Posición cerrada: Ticket #", ticket);
            } else {
               Print("Error al cerrar posición: Ticket #", ticket, " | Error = ", GetLastError());
            }
         }
      }
      Sleep(100);
      attempts++;
   }
   if(PositionsTotal() > 0) {
      Print("Error: No se cerraron todas las posiciones tras ", attempts, " intentos");
   } else {
      Print("Todas las posiciones cerradas correctamente");
   }
}
//+------------------------------------------------------------------+