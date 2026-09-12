//+------------------------------------------------------------------+
//|                                   Bollinger_MidCross_EA.mq5       |
//|  Estrategia: cruce de la banda media de Bollinger                 |
//|                                                                    |
//|  Reglas de entrada (CONFIRMADA AL CIERRE DE VELA):                |
//|   - SELL cuando el cierre de la vela cruza la banda MEDIA de      |
//|     arriba a abajo (comparando dos cierres consecutivos)          |
//|   - BUY  cuando el cierre de la vela cruza la banda MEDIA de      |
//|     abajo a arriba                                                |
//|     Se evalua UNA SOLA VEZ por vela nueva del timeframe operativo,|
//|     no en cada tick. Esto introduce un retraso hasta el cierre de |
//|     la vela de confirmacion, pero filtra el ruido de precio       |
//|     oscilando pegado a la banda media dentro de una misma vela.   |
//|     PROBADO EMPIRICAMENTE (2020-2024, US500, modelo OC 1 minuto): |
//|     esta version confirmada dio profit factor ~1.08-1.10; la      |
//|     variante de entrada inmediata (sin confirmar) dio profit      |
//|     factor 0.924 (perdedora) en el mismo periodo, por exceso de   |
//|     ruido. Por eso esta es la version de referencia actual.       |
//|                                                                    |
//|  Reglas de salida (DINAMICA, no es SL/TP fijo adjunto a la orden):|
//|   - La posicion se cierra cuando el precio TOCA la banda extrema  |
//|     vigente en ESE momento (no el valor que tenia la banda al     |
//|     entrar), comprobado en cada tick.                             |
//|       BUY  -> se cierra si toca la banda SUPERIOR (a favor)       |
//|               o si toca la banda INFERIOR (en contra)             |
//|       SELL -> se cierra si toca la banda INFERIOR (a favor)       |
//|               o si toca la banda SUPERIOR (en contra)             |
//|                                                                    |
//|  Gestion de tamano de posicion (v3.30 - ESCALADO POR BALANCE):    |
//|   - InpUseLotScaling = false: usa InpFixedLots tal cual, sin      |
//|     cual, sin escalar. Comportamiento identico a versiones         |
//|     anteriores.                                                    |
//|   - InpUseLotScaling = true: el lote de cada operacion se calcula |
//|     como InpBaseLots * (balance_actual / InpBaseBalance),         |
//|     redondeado al step de volumen del simbolo (para US500/IC      |
//|     Markets, 0.10). Esto mantiene el mismo NIVEL DE RIESGO         |
//|     RELATIVO que se valido empiricamente con InpBaseLots sobre    |
//|     InpBaseBalance (ver backtests: 0.4 lotes sobre 500 USD dio     |
//|     un drawdown maximo de 35-37% en el periodo 2020-2026), en vez  |
//|     de un lote fijo que se queda pequeno segun la cuenta crece,    |
//|     o de una escalada mas agresiva que la que ya se acepto.        |
//|   - Esto NO es conservador: mantiene, no reduce, el nivel de       |
//|     riesgo relativo aceptado. Es decision explicita del usuario,   |
//|     no una recomendacion de gestion de riesgo estandar.            |
//|   - InpMinLots establece un SUELO: el lote nunca baja de este     |
//|     valor (0.4 por defecto), ni siquiera si el balance cae por    |
//|     debajo de InpBaseBalance. Es decision explicita: no reducir   |
//|     la apuesta cuando la cuenta esta en perdidas, solo aumentarla |
//|     cuando crece. Si el balance se desploma, el lote se queda     |
//|     "quemando" al minimo aceptado, no se autoprotege.             |
//|                                                                    |
//|  Control de exposicion:                                          |
//|   - InpMaxOpenTrades limita cuantas posiciones de este bot pueden |
//|     estar abiertas a la vez.                                      |
//|                                                                    |
//|  Parametrizable: periodo de Bollinger, desviacion, timeframe      |
//|  (H1, H2, H3, H4, ...), lote base, escalado por balance,          |
//|  maximo de posiciones.                                            |
//+------------------------------------------------------------------+
#property copyright "Jose Antonio"
#property version   "3.30"
#property strict

#include <Trade\Trade.mqh>

input group "=== Bollinger Bands ==="
input ENUM_TIMEFRAMES InpTimeframe   = PERIOD_H1;  // Timeframe de operativa (H1, H2, H3, H4...)
input int              InpBBPeriod   = 27;         // Periodo de la banda de Bollinger
input double           InpBBDeviation= 2.0;        // Desviacion estandar de la banda

input group "=== Gestion de tamano de posicion ==="
input double InpFixedLots    = 0.4;     // Lote fijo (usado solo si InpUseLotScaling = false)
input bool   InpUseLotScaling = true;   // Activar escalado de lote segun balance de la cuenta
input double InpBaseLots     = 0.4;     // Lote base de referencia (el ya validado en backtest)
input double InpBaseBalance  = 500.0;   // Balance de referencia para ese lote base (USD)
input double InpMinLots      = 0.4;     // Suelo: el lote nunca baja de este valor, aunque el balance caiga

input group "=== Control de exposicion ==="
input int InpMaxOpenTrades = 1;     // Maximo de posiciones simultaneas de este bot

input group "=== Otros ==="
input ulong  InpMagicNumber  = 20260911; // Magic number
input string InpTradeComment = "BollMidCross";

//--- Handle e indicador
int    handleBB;
double bufMiddle[];

CTrade trade;

//--- Control de barra nueva (en el timeframe operativo, no necesariamente el del grafico)
datetime lastBarTime = 0;

//--- Senal pendiente de ENTRADA (reintento si el mercado esta cerrado en el instante de la senal)
bool     pendingEntry    = false;
bool     pendingIsBuy    = false;
datetime pendingBarTime  = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   handleBB = iBands(_Symbol, InpTimeframe, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   if(handleBB == INVALID_HANDLE)
     {
      Print("Error creando el handle de Bollinger Bands");
      return(INIT_FAILED);
     }

   ArraySetAsSeries(bufMiddle, true);

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(handleBB);
  }

//+------------------------------------------------------------------+
bool IsNewBar()
  {
   datetime currentBarTime = iTime(_Symbol, InpTimeframe, 0);
   if(currentBarTime != lastBarTime)
     {
      lastBarTime = currentBarTime;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Cuenta cuantas posiciones de este bot (mismo simbolo y magic)     |
//| estan abiertas ahora mismo.                                       |
//+------------------------------------------------------------------+
int CountOpenPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Calcula el lote a usar en la siguiente entrada. Si el escalado    |
//| esta desactivado, devuelve InpFixedLots tal cual. Si esta         |
//| activado, escala InpBaseLots proporcionalmente al balance actual  |
//| respecto a InpBaseBalance, y redondea al step de volumen valido   |
//| del simbolo (para no repetir el error de "Invalid volume" que ya  |
//| tuvimos con pasos no permitidos por el broker).                   |
//+------------------------------------------------------------------+
double CalcLots()
  {
   double lots;

   if(!InpUseLotScaling)
      lots = InpFixedLots;
   else
     {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      lots = InpBaseLots * (balance / InpBaseBalance);
     }

   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   lots = MathRound(lots / lotStep) * lotStep;
   lots = MathMax(lots, InpMinLots); // suelo propio: nunca por debajo de InpMinLots (0.4 por defecto)
   lots = MathMax(lots, minLot);     // suelo del broker (por si InpMinLots quedara por debajo)
   lots = MathMin(lots, maxLot);

   return lots;
  }

//+------------------------------------------------------------------+
//| Comprueba en cada tick si ALGUNA posicion abierta de este bot     |
//| debe cerrarse porque el precio ha tocado la banda extrema         |
//| VIGENTE (superior o inferior, segun el lado de cada posicion).    |
//+------------------------------------------------------------------+
void CheckDynamicExit()
  {
   double upperArr[1], lowerArr[1];
   if(CopyBuffer(handleBB, UPPER_BAND, 1, 1, upperArr) <= 0) return;
   if(CopyBuffer(handleBB, LOWER_BAND, 1, 1, lowerArr) <= 0) return;

   double upperNow = upperArr[0];
   double lowerNow = lowerArr[0];

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)InpMagicNumber) continue;

      long posType = PositionGetInteger(POSITION_TYPE);
      bool shouldClose = false;

      if(posType == POSITION_TYPE_BUY)
        {
         if(bid >= upperNow || bid <= lowerNow)
            shouldClose = true;
        }
      else if(posType == POSITION_TYPE_SELL)
        {
         if(ask <= lowerNow || ask >= upperNow)
            shouldClose = true;
        }

      if(shouldClose)
         trade.PositionClose(ticket);
     }
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   //--- 1) Gestionar la salida dinamica de posiciones ya abiertas, en cada tick
   CheckDynamicExit();

   //--- 2) Reintentar senal de ENTRADA pendiente en cada tick (por si el mercado estaba cerrado)
   if(pendingEntry)
     {
      if(iTime(_Symbol, InpTimeframe, 0) != pendingBarTime)
        {
         Print("Senal de entrada pendiente descartada: no se pudo ejecutar dentro de su vela.");
         pendingEntry = false;
        }
      else if(CountOpenPositions() < InpMaxOpenTrades)
        {
         double lots = CalcLots();
         bool sent;
         if(pendingIsBuy)
            sent = trade.Buy(lots, _Symbol, 0.0, 0.0, 0.0, InpTradeComment);
         else
            sent = trade.Sell(lots, _Symbol, 0.0, 0.0, 0.0, InpTradeComment);

         if(sent)
            pendingEntry = false;
         // si falla, se reintenta en el siguiente tick
        }
      else
        {
         pendingEntry = false; // ya se alcanzo el limite de posiciones por otra via
        }
     }

   //--- 3) Deteccion de senales de entrada: solo una vez por vela nueva del timeframe operativo
   if(!IsNewBar())
      return;

   if(Bars(_Symbol, InpTimeframe) < InpBBPeriod + 3)
      return;

   if(CopyBuffer(handleBB, BASE_LINE, 0, 3, bufMiddle) <= 0) return;

   // Cierres de las dos ultimas barras completadas: shift 1 = ultima cerrada, shift 2 = la anterior
   double close1 = iClose(_Symbol, InpTimeframe, 1);
   double close2 = iClose(_Symbol, InpTimeframe, 2);

   double mid1 = bufMiddle[1];
   double mid2 = bufMiddle[2];

   datetime currentBarTime = iTime(_Symbol, InpTimeframe, 0);

   // Ya se alcanzo el limite de posiciones simultaneas: no evaluamos nuevas entradas
   if(CountOpenPositions() >= InpMaxOpenTrades)
      return;

   bool crossUp   = (close2 < mid2) && (close1 > mid1); // cruce de abajo a arriba -> BUY
   bool crossDown = (close2 > mid2) && (close1 < mid1); // cruce de arriba a abajo -> SELL

   if(!crossUp && !crossDown)
      return;

   bool isBuy = crossUp;

   pendingEntry   = true;
   pendingIsBuy   = isBuy;
   pendingBarTime = currentBarTime;

   double lots = CalcLots();
   bool sent;
   if(isBuy)
      sent = trade.Buy(lots, _Symbol, 0.0, 0.0, 0.0, InpTradeComment);
   else
      sent = trade.Sell(lots, _Symbol, 0.0, 0.0, 0.0, InpTradeComment);

   if(sent)
      pendingEntry = false;
   // si falla, se reintenta en los siguientes ticks
  }
//+------------------------------------------------------------------+