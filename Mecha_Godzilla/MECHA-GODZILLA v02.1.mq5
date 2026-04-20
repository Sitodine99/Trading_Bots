//+------------------------------------------------------------------+
//|                                              MECHA-GODZILLA.mq5  |
//|                                             Jose Antonio Montero |
//|                        https://www.linkedin.com/in/joseamontero/ |
//+------------------------------------------------------------------+
// v2.1 - Correcciones aplicadas:
//   [FIX-1] ManageSellPositions: cierre en cascada → cierre individual + break simétrico con BUY
//   [FIX-2] SaveState/RestoreState: símbolo incluido en nombre de variable → restauración funcional
//   [FIX-3] PositionExists/ClosePosition/CountPositionsAtLevel: StringFind → comparación exacta → sin colisiones de nivel
//   [FIX-4] MaxPositionsPerLevel: parámetro conectado a la lógica de apertura adicional
//   [FIX-5] Hedging: deal ticket → position ticket mediante GetPositionTicketFromDeal()
//   [FIX-6] CheckDailyReset: ventana de minuto → comparación de fecha → reset garantizado cada día
//   [FIX-7] Logs: eliminados Print() que se disparaban en cada tick sin operar
//   [FIX-8] Cierre por grid solo si beneficio flotante >= MinProfitToClose (evita cierres en pérdida por spread)
//   [FIX-9] Cierre en OnTick por centralPoint exacto: aplica MinProfitToClose antes de cerrar
//   [FIX-10] Paradas de seguridad (balance objetivo, equity mínimo, pérdida diaria) cierran TODO el gráfico
//   [FIX-11] Posiciones pre-existentes al iniciar el bot son capturadas y excluidas de toda gestión
//+------------------------------------------------------------------+

#property copyright "Jose Antonio Montero"
#property link      "https://www.linkedin.com/in/joseamontero/"
#property version   "2.21"

#include <Trade\Trade.mqh>

//--- Input Parameters
input group "Configuración General"
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;                    // Marco temporal
input double InitialBalance = 500.0;                          // Saldo inicial de la cuenta en USD
input double FixedContractSize = 0.01;                          // Tamaño fijo del contrato
input group "Configuración del Grid"
input bool UseCandleBasedCentralPoint = false;                  // Usar cálculo del punto central basado en velas
input int CandlesToConsider = 500;                              // Nº de velas para el cálculo (UseCandleBasedCentralPoint = true)
input double FixedCentralPoint = 0.98092;                        // Punto central fijo (UseCandleBasedCentralPoint = false)
input double GridDistancePointsGraphics = 60.0;               // Distancia entre niveles del grid (puntos)
input int MaxGridLevels = 50;                                   // Máximo número de niveles en el grid
input int MaxPositionsPerLevel = 2;                             // Máximo número de posiciones por nivel del grid
input bool LimitGridPositions = true;                           // Activar/desactivar límite de posiciones abiertas en el grid
input int MaxGridPositions = 15;                                 // Máximo número de posiciones abiertas en el grid (excluye coberturas)
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
input group "Gestión de Posiciones — Cierre"
input double MinProfitToClose = 0.0;                            // Beneficio mínimo (USD) para cerrar por lógica de grid (0 = breakeven)
input group "Gestión de Cuenta"
input bool UseBalanceTarget = true;                             // Activar/desactivar objetivo de saldo
input double BalanceTarget = 605.0;                           // Saldo objetivo para cerrar el bot (USD)
input double MinOperatingBalance = 1.0;                      // Saldo mínimo operativo (USD)
input double MaxDailyLoss = 150.0;                              // Pérdida diaria máxima permitida (USD)
input double SafetyBeltFactor = 1.0;                            // Factor de cinturón de seguridad (0.0 a 1.0, ej. 0.5 = 50%)

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
double realizedLoss = 0.0;
double effectiveMaxDailyLoss;
datetime lastCandleTime = 0;
int candlesSinceRecalc = 0;
datetime lastGridRecalcTime = 0;
double lastPrice = 0.0;
//--- ATR Variables
int atrHandle;
double atrValues[];
double atrMax = 0.0;
double atrMin = DBL_MAX;
double atrSum = 0.0;
int atrCount = 0;

struct HedgePosition {
   ulong ticketMain;
   ulong ticketHedge;
};
HedgePosition hedgePositions[];
int hedgeCount = 0;

//--- [FIX-11] Posiciones pre-existentes al iniciar el bot (no serán gestionadas)
ulong preExistingTickets[];
int preExistingCount = 0;

//+------------------------------------------------------------------+
// [FIX-2] Nombre de variable de estado incluye símbolo para evitar
//         colisiones entre instancias y permitir restauración real
//+------------------------------------------------------------------+
string StateKey(string name) { return "BotState_" + _Symbol + "_" + name; }

//+------------------------------------------------------------------+
// [FIX-11] Devuelve true si el ticket corresponde a una posición que
//          ya estaba abierta cuando el bot se inició (no se gestiona)
//+------------------------------------------------------------------+
bool IsPreExisting(ulong ticket)
{
   for(int i = 0; i < preExistingCount; i++)
      if(preExistingTickets[i] == ticket) return true;
   return false;
}

//+------------------------------------------------------------------+
// [FIX-11] Captura los tickets de todas las posiciones abiertas ahora
//          para excluirlas de la gestión del bot
//+------------------------------------------------------------------+
void CapturePreExistingPositions()
{
   preExistingCount = 0;
   ArrayResize(preExistingTickets, PositionsTotal());
   for(int i = 0; i < PositionsTotal(); i++) {
      if(PositionGetSymbol(i) == _Symbol) {
         preExistingTickets[preExistingCount] = PositionGetTicket(i);
         preExistingCount++;
         Print("Posición pre-existente ignorada por el bot: Ticket #",
               PositionGetTicket(i),
               " | Tipo = ", (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL"),
               " | Precio apertura = ", DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), 5));
      }
   }
   if(preExistingCount > 0)
      Print("Total posiciones pre-existentes capturadas: ", preExistingCount,
            " — no serán gestionadas ni cerradas por el bot.");
}

//+------------------------------------------------------------------+
// [FIX-5] Obtiene el position ticket a partir del deal ticket
//+------------------------------------------------------------------+
ulong GetPositionTicketFromDeal(ulong dealTicket)
{
   if(HistoryDealSelect(dealTicket))
      return (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   return 0;
}

//+------------------------------------------------------------------+
// [FIX-3] Comparación exacta de comentario de posición por nivel
//+------------------------------------------------------------------+
bool CommentMatchesLevel(string comment, ENUM_POSITION_TYPE type, int level)
{
   string expected = (type == POSITION_TYPE_BUY ? "Buy" : "Sell") + " Level " + IntegerToString(level);
   return (comment == expected);
}
//+------------------------------------------------------------------+
// [FIX-8] Devuelve el beneficio flotante total de todas las posiciones
//         de un nivel dado. Usado para evitar cierres en pérdida por grid.
//+------------------------------------------------------------------+
double GetLevelProfit(ENUM_POSITION_TYPE type, int level)
{
   double totalProfit = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&   // [FIX-11]
         PositionGetInteger(POSITION_TYPE) == type &&
         CommentMatchesLevel(PositionGetString(POSITION_COMMENT), type, level))
         totalProfit += PositionGetDouble(POSITION_PROFIT);
   }
   return totalProfit;
}

//+------------------------------------------------------------------+
int OnInit()
{
   ArrayResize(gridLevelsBuy, MaxGridLevels);
   ArrayResize(gridLevelsSell, MaxGridLevels);
   ArrayResize(levelClosedSell, MaxGridLevels);
   ArrayResize(levelClosedBuy, MaxGridLevels);
   ArrayResize(additionalPositionsOpenedSell, MaxGridLevels);
   ArrayResize(additionalPositionsOpenedBuy, MaxGridLevels);
   // [FIX-4] Array dimensionado con MaxPositionsPerLevel que ahora es funcional
   ArrayResize(hedgePositions, MaxGridLevels * MaxPositionsPerLevel);
   ArrayInitialize(levelClosedSell, false);
   ArrayInitialize(levelClosedBuy, false);
   ArrayInitialize(additionalPositionsOpenedSell, 0);
   ArrayInitialize(additionalPositionsOpenedBuy, 0);
   hedgeCount = 0;

   if(SafetyBeltFactor <= 0.0 || SafetyBeltFactor > 1.0) {
      Print("Error: SafetyBeltFactor debe estar entre 0.0 y 1.0. Usando 0.95 por defecto.");
      effectiveMaxDailyLoss = MaxDailyLoss * 0.95;
   } else {
      effectiveMaxDailyLoss = MaxDailyLoss * SafetyBeltFactor;
   }
   Print("Inicio - Límite efectivo de pérdida diaria: ", DoubleToString(effectiveMaxDailyLoss, 2), " USD");

   // [FIX-2] Condición de restauración usa clave por símbolo → nunca falla por comparación string/double
   if(GlobalVariableCheck(StateKey("Initialized"))) {
      RestoreState();
      Print("Bot restaurado: Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
            " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
   } else {
      // [FIX-2] Borra solo variables de ESTE símbolo, no de todos los bots
      GlobalVariablesDeleteAll("BotState_" + _Symbol + "_");
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
      Print("Bot iniciado desde cero: Balance = ", DoubleToString(dailyStartBalance, 2),
            " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
   }

   atrHandle = iATR(_Symbol, Timeframe, AtrPeriod);
   if(atrHandle == INVALID_HANDLE) {
      Print("Error al inicializar el indicador ATR: ", GetLastError());
      return(INIT_FAILED);
   }

   // [FIX-11] Capturar posiciones ya abiertas — el bot no las gestionará
   CapturePreExistingPositions();

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
      // [FIX-2] Borra solo variables de este símbolo
      GlobalVariablesDeleteAll("BotState_" + _Symbol + "_");
      Print("Bot cerrado manualmente, estado borrado: Motivo = ", reason);
   }
   ObjectsDeleteAll(0, "GridLine_");

   if(atrCount > 0) {
      double atrAverage = atrSum / atrCount;
      Print("Estadísticas del ATR durante la simulación:");
      Print("ATR Máximo: ", DoubleToString(atrMax, 5));
      Print("ATR Mínimo: ", DoubleToString(atrMin, 5));
      Print("ATR Medio: ", DoubleToString(atrAverage, 5));
   } else {
      Print("No se calcularon valores del ATR durante la simulación.");
   }

   if(atrHandle != INVALID_HANDLE)
      IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!botActive) return;  // [FIX-7] Sin Print en cada tick cuando el bot no está activo

   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   datetime currentTime = TimeCurrent();
   if(currentTime - lastStateSave >= 3600) {
      SaveState();
      lastStateSave = currentTime;
      Print("Estado guardado: Balance = ", DoubleToString(currentBalance, 2),
            " | Equity = ", DoubleToString(currentEquity, 2));
   }

   datetime currentCandleTime = iTime(_Symbol, Timeframe, 0);
   if(currentCandleTime != lastCandleTime) {
      lastCandleTime = currentCandleTime;
      candlesSinceRecalc++;

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

   if(candlesSinceRecalc >= CandlesToConsider && UseCandleBasedCentralPoint) {
      Print("Grid recalculado después de ", CandlesToConsider, " velas");
      CalculateGrid();
      DrawGridLines();
      CloseAllHedgeOrders();
      hedgeCount = 0;
      candlesSinceRecalc = 0;
      lastGridRecalcTime = currentTime;
      isInitialized = false;
   }

   if(UseBalanceTarget && currentBalance >= BalanceTarget && currentEquity >= BalanceTarget) {
      CloseAllPositions();
      CloseAllHedgeOrders();
      botActive = false;
      Print("Objetivo de saldo alcanzado: Balance = ", DoubleToString(currentBalance, 2),
            " | Equity = ", DoubleToString(currentEquity, 2),
            " | Todas las posiciones cerradas.");
      return;
   }

   if(currentEquity < MinOperatingBalance) {
      CloseAllPositions();
      CloseAllHedgeOrders();
      botActive = false;
      Print("Parada por equity mínimo: Equity = ", DoubleToString(currentEquity, 2),
            " < ", DoubleToString(MinOperatingBalance, 2),
            " | Todas las posiciones cerradas.");
      return;
   }

   CheckDailyReset();
   double totalDailyLoss = CalculateTotalDailyLoss();

   if(totalDailyLoss <= -effectiveMaxDailyLoss) {
      CloseAllPositions();
      CloseAllHedgeOrders();
      tradingDisabled = true;
      Print("Límite diario alcanzado: Pérdida = ", DoubleToString(totalDailyLoss, 2),
            " | Equity = ", DoubleToString(currentEquity, 2),
            " | Balance = ", DoubleToString(currentBalance, 2),
            " | Todas las posiciones cerradas.");
      return;
   }

   if(tradingDisabled) return;  // [FIX-7] Sin Print en cada tick cuando trading está deshabilitado

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
      Print("Bot inicializado: Buy Level = ", initialLevelBuy, " | Sell Level = ", initialLevelSell,
            " | centralPoint = ", DoubleToString(centralPoint, 5));
      return;
   }

   ManageBuyPositions(currentPrice);
   ManageSellPositions(currentPrice);

   if(MathAbs(currentPrice - centralPoint) <= _Point) {
      // [FIX-9] Solo cerrar posiciones que tengan beneficio >= MinProfitToClose
      bool allProfitable = true;
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         if(PositionGetSymbol(i) == _Symbol && !IsPreExisting(PositionGetTicket(i))) {
            if(PositionGetDouble(POSITION_PROFIT) < MinProfitToClose) {
               allProfitable = false;
               Print("Cierre centralPoint pospuesto: Ticket #", PositionGetTicket(i),
                     " | Beneficio = ", DoubleToString(PositionGetDouble(POSITION_PROFIT), 2),
                     " USD — esperando ", DoubleToString(MinProfitToClose, 2), " USD mínimo");
            }
         }
      }
      if(allProfitable) {
         for(int i = PositionsTotal() - 1; i >= 0; i--) {
            if(PositionGetSymbol(i) == _Symbol && !IsPreExisting(PositionGetTicket(i))) {
               ulong ticket = PositionGetTicket(i);
               trade.PositionClose(ticket);
               CloseHedgeOrder(ticket);
               Print("Posición cerrada al tocar Nivel 0: Ticket #", ticket,
                     " | Precio = ", DoubleToString(currentPrice, 5));
            }
         }
         ArrayInitialize(levelClosedBuy, false);
         ArrayInitialize(levelClosedSell, false);
         ArrayInitialize(additionalPositionsOpenedBuy, 0);
         ArrayInitialize(additionalPositionsOpenedSell, 0);
         isInitialized = false;
      }
   }
   lastPrice = currentPrice;
}

//+------------------------------------------------------------------+
int CountGridPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i))) {   // [FIX-11]
         string comment = PositionGetString(POSITION_COMMENT);
         if(StringFind(comment, "Level ") >= 0 && StringFind(comment, "Hedge") < 0)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
void OpenHedgeOrder(ENUM_POSITION_TYPE mainType, ulong positionTicket, double slPrice, int level)
{
   double hedgePrice, hedgeSL, hedgeTP;
   int attempts = 0;
   bool success = false;

   while(attempts < 3 && !success) {
      if(mainType == POSITION_TYPE_BUY) {
         hedgePrice = slPrice + HedgePointsBeforeSL * _Point;
         hedgeSL = UseHedgeStopLoss ? hedgePrice + HedgeStopLossPoints * _Point : 0.0;
         hedgeTP = hedgePrice - HedgeTakeProfitPoints * _Point;
         Print("Intentando abrir SellStop: Precio = ", DoubleToString(hedgePrice, 5),
               " | Volumen = ", DoubleToString(HedgeContractSize, 2),
               " | SL = ", DoubleToString(hedgeSL, 5), " | TP = ", DoubleToString(hedgeTP, 5));
         if(trade.SellStop(HedgeContractSize, hedgePrice, _Symbol, hedgeSL, hedgeTP,
                           ORDER_TIME_GTC, 0, "Hedge for Buy Level " + IntegerToString(level)))
            success = true;
         else {
            Print("Fallo al colocar SellStop de cobertura: Error = ", GetLastError(),
                  " | Intento = ", attempts + 1);
            Sleep(100);
         }
      } else if(mainType == POSITION_TYPE_SELL) {
         hedgePrice = slPrice - HedgePointsBeforeSL * _Point;
         hedgeSL = UseHedgeStopLoss ? hedgePrice - HedgeStopLossPoints * _Point : 0.0;
         hedgeTP = hedgePrice + HedgeTakeProfitPoints * _Point;
         Print("Intentando abrir BuyStop: Precio = ", DoubleToString(hedgePrice, 5),
               " | Volumen = ", DoubleToString(HedgeContractSize, 2),
               " | SL = ", DoubleToString(hedgeSL, 5), " | TP = ", DoubleToString(hedgeTP, 5));
         if(trade.BuyStop(HedgeContractSize, hedgePrice, _Symbol, hedgeSL, hedgeTP,
                          ORDER_TIME_GTC, 0, "Hedge for Sell Level " + IntegerToString(level)))
            success = true;
         else {
            Print("Fallo al colocar BuyStop de cobertura: Error = ", GetLastError(),
                  " | Intento = ", attempts + 1);
            Sleep(100);
         }
      }
      attempts++;
   }

   if(success) {
      ulong ticketHedge = trade.ResultOrder();
      if(ticketHedge > 0) {
         hedgePositions[hedgeCount].ticketMain  = positionTicket;  // [FIX-5] position ticket, no deal ticket
         hedgePositions[hedgeCount].ticketHedge = ticketHedge;
         hedgeCount++;
         Print("Orden de cobertura colocada: Main Position Ticket = ", positionTicket,
               " | Hedge Ticket = ", ticketHedge, " | Nivel = ", level);
      } else {
         Print("Fallo al obtener ticket de cobertura: Error = ", GetLastError());
      }
   } else {
      Print("Fallo al abrir orden de cobertura tras ", attempts,
            " intentos para Position Ticket = ", positionTicket);
   }
}

//+------------------------------------------------------------------+
void CloseHedgeOrder(ulong positionTicket)
{
   for(int i = 0; i < hedgeCount; i++) {
      if(hedgePositions[i].ticketMain == positionTicket) {
         trade.OrderDelete(hedgePositions[i].ticketHedge);
         Print("Orden de cobertura cerrada: Main Ticket = ", positionTicket,
               " | Hedge Ticket = ", hedgePositions[i].ticketHedge);
         if(i < hedgeCount - 1)
            hedgePositions[i] = hedgePositions[hedgeCount - 1];
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
   // [FIX-2] Todas las variables usan clave con símbolo incluido
   GlobalVariableSet(StateKey("Active"),              botActive ? 1.0 : 0.0);
   GlobalVariableSet(StateKey("DailyStartBalance"),   dailyStartBalance);
   GlobalVariableSet(StateKey("LastDayReset"),        (double)lastDayReset);
   GlobalVariableSet(StateKey("TradingDisabled"),     tradingDisabled ? 1.0 : 0.0);
   GlobalVariableSet(StateKey("MinEquity"),           minEquity);
   GlobalVariableSet(StateKey("Initialized"),         isInitialized ? 1.0 : 0.0);
   GlobalVariableSet(StateKey("InitialLevelSell"),    initialLevelSell);
   GlobalVariableSet(StateKey("InitialLevelBuy"),     initialLevelBuy);
   GlobalVariableSet(StateKey("CentralPoint"),        centralPoint);
   GlobalVariableSet(StateKey("RealizedLoss"),        realizedLoss);
   GlobalVariableSet(StateKey("LastCandleTime"),      (double)lastCandleTime);
   GlobalVariableSet(StateKey("CandlesSinceRecalc"),  candlesSinceRecalc);
   GlobalVariableSet(StateKey("LastGridRecalcTime"),  (double)lastGridRecalcTime);
   GlobalVariableSet(StateKey("LastPrice"),           lastPrice);

   for(int i = 0; i < MaxGridLevels; i++) {
      GlobalVariableSet(StateKey("GridBuy_")           + IntegerToString(i), gridLevelsBuy[i]);
      GlobalVariableSet(StateKey("GridSell_")          + IntegerToString(i), gridLevelsSell[i]);
      GlobalVariableSet(StateKey("LevelClosedSell_")   + IntegerToString(i), levelClosedSell[i] ? 1.0 : 0.0);
      GlobalVariableSet(StateKey("LevelClosedBuy_")    + IntegerToString(i), levelClosedBuy[i] ? 1.0 : 0.0);
      GlobalVariableSet(StateKey("AdditionalSell_")    + IntegerToString(i), additionalPositionsOpenedSell[i]);
      GlobalVariableSet(StateKey("AdditionalBuy_")     + IntegerToString(i), additionalPositionsOpenedBuy[i]);
   }
}

//+------------------------------------------------------------------+
void RestoreState()
{
   // [FIX-2] Todas las lecturas usan la misma clave con símbolo
   botActive         = GlobalVariableGet(StateKey("Active")) == 1.0;
   dailyStartBalance = GlobalVariableGet(StateKey("DailyStartBalance"));
   lastDayReset      = (datetime)GlobalVariableGet(StateKey("LastDayReset"));
   tradingDisabled   = GlobalVariableGet(StateKey("TradingDisabled")) == 1.0;
   minEquity         = GlobalVariableGet(StateKey("MinEquity"));
   isInitialized     = GlobalVariableGet(StateKey("Initialized")) == 1.0;
   initialLevelSell  = (int)GlobalVariableGet(StateKey("InitialLevelSell"));
   initialLevelBuy   = (int)GlobalVariableGet(StateKey("InitialLevelBuy"));
   centralPoint      = GlobalVariableGet(StateKey("CentralPoint"));
   realizedLoss      = GlobalVariableGet(StateKey("RealizedLoss"));
   lastCandleTime    = (datetime)GlobalVariableGet(StateKey("LastCandleTime"));
   candlesSinceRecalc= (int)GlobalVariableGet(StateKey("CandlesSinceRecalc"));
   lastGridRecalcTime= (datetime)GlobalVariableGet(StateKey("LastGridRecalcTime"));
   lastPrice         = GlobalVariableGet(StateKey("LastPrice"));

   for(int i = 0; i < MaxGridLevels; i++) {
      gridLevelsBuy[i]                  = GlobalVariableGet(StateKey("GridBuy_")         + IntegerToString(i));
      gridLevelsSell[i]                 = GlobalVariableGet(StateKey("GridSell_")        + IntegerToString(i));
      levelClosedSell[i]                = GlobalVariableGet(StateKey("LevelClosedSell_") + IntegerToString(i)) == 1.0;
      levelClosedBuy[i]                 = GlobalVariableGet(StateKey("LevelClosedBuy_")  + IntegerToString(i)) == 1.0;
      additionalPositionsOpenedSell[i]  = (int)GlobalVariableGet(StateKey("AdditionalSell_") + IntegerToString(i));
      additionalPositionsOpenedBuy[i]   = (int)GlobalVariableGet(StateKey("AdditionalBuy_")  + IntegerToString(i));
   }
}

//+------------------------------------------------------------------+
// [FIX-6] Reset basado en cambio de fecha española, no en ventana de minuto
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   datetime utcTime = TimeGMT();
   MqlDateTime utcStruct;
   TimeToStruct(utcTime, utcStruct);

   int hourOffset = (utcStruct.mon >= 3 && utcStruct.mon <= 10) ? 2 : 1;

   datetime spanishNow = utcTime + hourOffset * 3600;
   MqlDateTime spanishNowStruct;
   TimeToStruct(spanishNow, spanishNowStruct);

   datetime spanishLastReset = lastDayReset + hourOffset * 3600;
   MqlDateTime spanishLastResetStruct;
   TimeToStruct(spanishLastReset, spanishLastResetStruct);

   bool newDay = (spanishNowStruct.day  != spanishLastResetStruct.day  ||
                  spanishNowStruct.mon  != spanishLastResetStruct.mon  ||
                  spanishNowStruct.year != spanishLastResetStruct.year);

   if(newDay) {
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
         Print("Reset tras pérdida máxima: Balance = ", DoubleToString(dailyStartBalance, 2),
               " | Fecha España = ", spanishNowStruct.day, "/", spanishNowStruct.mon, "/", spanishNowStruct.year);
      } else {
         Print("Reset diario: Balance = ", DoubleToString(dailyStartBalance, 2),
               " | Fecha España = ", spanishNowStruct.day, "/", spanishNowStruct.mon, "/", spanishNowStruct.year);
      }
   }
}

//+------------------------------------------------------------------+
double CalculateTotalDailyLoss()
{
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double floatingLoss = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol)
         floatingLoss += PositionGetDouble(POSITION_PROFIT);
   }

   realizedLoss = currentBalance - dailyStartBalance;
   double totalLoss = realizedLoss + floatingLoss;
   return totalLoss;
}

//+------------------------------------------------------------------+
void CalculateGrid()
{
   if(UseCandleBasedCentralPoint) {
      int bars = iBars(_Symbol, Timeframe);
      if(bars < CandlesToConsider) {
         Print("Error: No hay suficientes barras (", bars, ") para ", CandlesToConsider);
         return;
      }
      double high = iHigh(_Symbol, Timeframe, iHighest(_Symbol, Timeframe, MODE_HIGH, CandlesToConsider, 1));
      double low  = iLow (_Symbol, Timeframe, iLowest (_Symbol, Timeframe, MODE_LOW,  CandlesToConsider, 1));
      if(high == 0 || low == 0) {
         Print("Error: high o low no válidos");
         return;
      }
      centralPoint = (high + low) / 2;
      Print("Punto central calculado con velas: ", DoubleToString(centralPoint, 5));
   } else {
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
      gridLevelsBuy[i]  = centralPoint - (levelDistance * (i + 1));
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
// [FIX-3] Comparación exacta: elimina colisiones entre nivel 1 y 10, 11...
//+------------------------------------------------------------------+
int CountPositionsAtLevel(ENUM_POSITION_TYPE type, int level)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&   // [FIX-11]
         PositionGetInteger(POSITION_TYPE) == type &&
         CommentMatchesLevel(PositionGetString(POSITION_COMMENT), type, level))
         count++;
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
   if(!botActive || !isInitialized || tradingDisabled) return;

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
         Print("ManageBuyPositions: Precio cruza nivel ", i, " hacia abajo",
               " | gridLevelsBuy = ", DoubleToString(gridLevelsBuy[i], 5),
               " | positionsAtLevel = ", positionsAtLevel);

         if(positionsAtLevel > 0) {
            Print("ManageBuyPositions: No se abre compra - Ya hay ", positionsAtLevel, " posiciones en nivel ", i);
            continue;
         }

         if(i == MaxGridLevels - 1 || highestBuyLevel == -1 || highestBuyLevel < i ||
            (i < MaxGridLevels - 1 && levelClosedBuy[i+1])) {
            if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) {
               Print("ManageBuyPositions: Límite de posiciones alcanzado (", MaxGridPositions, ")");
               continue;
            }
            if(!IsAtrWithinRange()) {
               Print("ManageBuyPositions: Filtro ATR no permite apertura");
               continue;
            }
            double slPrice = UseStopLoss ? gridLevelsBuy[i] - StopLossPointsGraphics * _Point : 0;
            if(trade.Buy(FixedContractSize, _Symbol, 0, slPrice, 0, "Buy Level " + IntegerToString(i))) {
               ulong dealTicket = trade.ResultDeal();
               Print("Compra abierta nivel ", i, " | Precio = ", DoubleToString(currentPrice, 5),
                     " | SL = ", DoubleToString(slPrice, 5), " | Deal = ", dealTicket);
               // [FIX-5] Obtener position ticket a partir del deal ticket
               if(UseHedging && dealTicket > 0 && UseStopLoss) {
                  ulong posTicket = GetPositionTicketFromDeal(dealTicket);
                  if(posTicket > 0)
                     OpenHedgeOrder(POSITION_TYPE_BUY, posTicket, slPrice, i);
                  else
                     Print("Warning: No se pudo obtener position ticket para deal ", dealTicket);
               }
               levelClosedBuy[i] = false;
               additionalPositionsOpenedBuy[i] = 0;
            } else {
               Print("ManageBuyPositions: Fallo al abrir compra: Error = ", GetLastError());
            }
            break;
         } else {
            Print("ManageBuyPositions: Condición de nivel no cumplida: i = ", i,
                  " | highestBuyLevel = ", highestBuyLevel,
                  " | levelClosedBuy[", i+1, "] = ", (i < MaxGridLevels-1 ? levelClosedBuy[i+1] : false));
         }
      }

      if(i > 0 && currentPrice >= gridLevelsBuy[i-1] && PositionExists(POSITION_TYPE_BUY, i)) {
         // [FIX-8] No cerrar si la posición está en pérdida (spread en el momento del cruce)
         double levelProfit = GetLevelProfit(POSITION_TYPE_BUY, i);
         if(levelProfit < MinProfitToClose) {
            Print("ManageBuyPositions: Nivel ", i, " en pérdida (", DoubleToString(levelProfit, 2),
                  " USD) — esperando beneficio mínimo de ", DoubleToString(MinProfitToClose, 2), " USD");
            break;
         }
         bool positionsClosed = false;
         ClosePosition(POSITION_TYPE_BUY, i);
         Print("Compra cerrada nivel ", i, " | Precio = ", DoubleToString(currentPrice, 5),
               " | Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
               " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
         levelClosedBuy[i] = true;
         positionsClosed = true;

         // [FIX-4] MaxPositionsPerLevel controla el límite real de posiciones adicionales
         int positionsAtUpperLevel = CountPositionsAtLevel(POSITION_TYPE_BUY, i-1);
         if(positionsClosed &&
            positionsAtUpperLevel < MaxPositionsPerLevel &&
            additionalPositionsOpenedBuy[i-1] < MaxPositionsPerLevel - 1) {
            if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) {
               Print("ManageBuyPositions: Límite de posiciones alcanzado. No se abre adicional.");
               break;
            }
            if(!IsAtrWithinRange()) {
               Print("ManageBuyPositions: Filtro ATR no permite apertura adicional");
               break;
            }
            double slPrice = UseStopLoss ? gridLevelsBuy[i-1] - StopLossPointsGraphics * _Point : 0;
            if(trade.Buy(FixedContractSize, _Symbol, 0, slPrice, 0, "Buy Level " + IntegerToString(i-1))) {
               ulong dealTicket = trade.ResultDeal();
               Print("Compra adicional nivel ", i-1, " | Precio = ", DoubleToString(currentPrice, 5),
                     " | SL = ", DoubleToString(slPrice, 5), " | Deal = ", dealTicket);
               // [FIX-5]
               if(UseHedging && dealTicket > 0 && UseStopLoss) {
                  ulong posTicket = GetPositionTicketFromDeal(dealTicket);
                  if(posTicket > 0)
                     OpenHedgeOrder(POSITION_TYPE_BUY, posTicket, slPrice, i-1);
                  else
                     Print("Warning: No se pudo obtener position ticket para deal ", dealTicket);
               }
               levelClosedBuy[i-1] = false;
               additionalPositionsOpenedBuy[i-1]++;
            } else {
               Print("ManageBuyPositions: Fallo al abrir compra adicional: Error = ", GetLastError());
            }
         }
         break;
      }

      if(currentPrice >= centralPoint && PositionExists(POSITION_TYPE_BUY, 0)) {
         // [FIX-8] No cerrar si la posición está en pérdida
         double lp0b = GetLevelProfit(POSITION_TYPE_BUY, 0);
         if(lp0b < MinProfitToClose)
            Print("ManageBuyPositions: Nivel 0 (central) en pérdida (", DoubleToString(lp0b, 2), " USD) — esperando.");
         else {
            ClosePosition(POSITION_TYPE_BUY, 0);
            Print("Compra cerrada nivel 0 por centralPoint | Precio = ", DoubleToString(currentPrice, 5),
                  " | Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
                  " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
            levelClosedBuy[0] = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
void ManageSellPositions(double currentPrice)
{
   if(!botActive || !isInitialized || tradingDisabled) return;

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
         Print("ManageSellPositions: Precio cruza nivel ", i, " hacia arriba",
               " | gridLevelsSell = ", DoubleToString(gridLevelsSell[i], 5),
               " | positionsAtLevel = ", positionsAtLevel);

         if(positionsAtLevel > 0) {
            Print("ManageSellPositions: No se abre venta - Ya hay ", positionsAtLevel, " posiciones en nivel ", i);
            continue;
         }

         if(i == MaxGridLevels - 1 || highestSellLevel == -1 || highestSellLevel < i ||
            (i < MaxGridLevels - 1 && levelClosedSell[i+1])) {
            if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) {
               Print("ManageSellPositions: Límite de posiciones alcanzado (", MaxGridPositions, ")");
               continue;
            }
            if(!IsAtrWithinRange()) {
               Print("ManageSellPositions: Filtro ATR no permite apertura");
               continue;
            }
            double slPrice = UseStopLoss ? gridLevelsSell[i] + StopLossPointsGraphics * _Point : 0;
            if(trade.Sell(FixedContractSize, _Symbol, 0, slPrice, 0, "Sell Level " + IntegerToString(i))) {
               ulong dealTicket = trade.ResultDeal();
               Print("Venta abierta nivel ", i, " | Precio = ", DoubleToString(currentPrice, 5),
                     " | SL = ", DoubleToString(slPrice, 5), " | Deal = ", dealTicket);
               // [FIX-5]
               if(UseHedging && dealTicket > 0 && UseStopLoss) {
                  ulong posTicket = GetPositionTicketFromDeal(dealTicket);
                  if(posTicket > 0)
                     OpenHedgeOrder(POSITION_TYPE_SELL, posTicket, slPrice, i);
                  else
                     Print("Warning: No se pudo obtener position ticket para deal ", dealTicket);
               }
               levelClosedSell[i] = false;
               additionalPositionsOpenedSell[i] = 0;
            } else {
               Print("ManageSellPositions: Fallo al abrir venta: Error = ", GetLastError());
            }
            break;
         } else {
            Print("ManageSellPositions: Condición de nivel no cumplida: i = ", i,
                  " | highestSellLevel = ", highestSellLevel,
                  " | levelClosedSell[", i+1, "] = ", (i < MaxGridLevels-1 ? levelClosedSell[i+1] : false));
         }
      }

      // [FIX-1] Cierre INDIVIDUAL del nivel i (no cascada), + break simétrico con ManageBuyPositions
      if(i > 0 && currentPrice < gridLevelsSell[i-1] && PositionExists(POSITION_TYPE_SELL, i)) {
         // [FIX-8] No cerrar si la posición está en pérdida (spread en el momento del cruce)
         double levelProfitSell = GetLevelProfit(POSITION_TYPE_SELL, i);
         if(levelProfitSell < MinProfitToClose) {
            Print("ManageSellPositions: Nivel ", i, " en pérdida (", DoubleToString(levelProfitSell, 2),
                  " USD) — esperando beneficio mínimo de ", DoubleToString(MinProfitToClose, 2), " USD");
            break;
         }
         bool positionsClosed = false;
         ClosePosition(POSITION_TYPE_SELL, i);
         Print("Venta cerrada nivel ", i, " | Precio = ", DoubleToString(currentPrice, 5),
               " | Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
               " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
         levelClosedSell[i] = true;
         positionsClosed = true;

         // [FIX-4] MaxPositionsPerLevel controla el límite real de posiciones adicionales
         int positionsAtLowerLevel = CountPositionsAtLevel(POSITION_TYPE_SELL, i-1);
         if(positionsClosed &&
            positionsAtLowerLevel < MaxPositionsPerLevel &&
            additionalPositionsOpenedSell[i-1] < MaxPositionsPerLevel - 1) {
            if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) {
               Print("ManageSellPositions: Límite de posiciones alcanzado. No se abre adicional.");
               break;
            }
            if(!IsAtrWithinRange()) {
               Print("ManageSellPositions: Filtro ATR no permite apertura adicional");
               break;
            }
            double slPrice = UseStopLoss ? gridLevelsSell[i-1] + StopLossPointsGraphics * _Point : 0;
            if(trade.Sell(FixedContractSize, _Symbol, 0, slPrice, 0, "Sell Level " + IntegerToString(i-1))) {
               ulong dealTicket = trade.ResultDeal();
               Print("Venta adicional nivel ", i-1, " | Precio = ", DoubleToString(currentPrice, 5),
                     " | SL = ", DoubleToString(slPrice, 5), " | Deal = ", dealTicket);
               // [FIX-5]
               if(UseHedging && dealTicket > 0 && UseStopLoss) {
                  ulong posTicket = GetPositionTicketFromDeal(dealTicket);
                  if(posTicket > 0)
                     OpenHedgeOrder(POSITION_TYPE_SELL, posTicket, slPrice, i-1);
                  else
                     Print("Warning: No se pudo obtener position ticket para deal ", dealTicket);
               }
               levelClosedSell[i-1] = false;
               additionalPositionsOpenedSell[i-1]++;
            } else {
               Print("ManageSellPositions: Fallo al abrir venta adicional: Error = ", GetLastError());
            }
         }
         break; // [FIX-1] Break simétrico con ManageBuyPositions
      }

      if(currentPrice <= centralPoint && PositionExists(POSITION_TYPE_SELL, 0)) {
         // [FIX-8] No cerrar si la posición está en pérdida
         double lp0s = GetLevelProfit(POSITION_TYPE_SELL, 0);
         if(lp0s < MinProfitToClose)
            Print("ManageSellPositions: Nivel 0 (central) en pérdida (", DoubleToString(lp0s, 2), " USD) — esperando.");
         else {
            ClosePosition(POSITION_TYPE_SELL, 0);
            Print("Venta cerrada nivel 0 por centralPoint | Precio = ", DoubleToString(currentPrice, 5),
                  " | Balance = ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
                  " | Equity = ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
            levelClosedSell[0] = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
// [FIX-3] Comparación exacta usando CommentMatchesLevel
//+------------------------------------------------------------------+
bool PositionExists(ENUM_POSITION_TYPE type, int level)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&   // [FIX-11]
         PositionGetInteger(POSITION_TYPE) == type &&
         CommentMatchesLevel(PositionGetString(POSITION_COMMENT), type, level))
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
// [FIX-3] Comparación exacta usando CommentMatchesLevel
//+------------------------------------------------------------------+
void ClosePosition(ENUM_POSITION_TYPE type, int level)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&   // [FIX-11]
         PositionGetInteger(POSITION_TYPE) == type &&
         CommentMatchesLevel(PositionGetString(POSITION_COMMENT), type, level)) {
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
   if(PositionsTotal() > 0)
      Print("Error: No se cerraron todas las posiciones tras ", attempts, " intentos");
   else
      Print("Todas las posiciones cerradas correctamente");
}
//+------------------------------------------------------------------+