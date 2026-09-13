//+------------------------------------------------------------------+
//|                                        MECHA-GODZILLA 27.mq5     |
//|                                            Jose Antonio Montero  |
//|                       https://www.linkedin.com/in/joseamontero/  |
//+------------------------------------------------------------------+
//
//  MECHA-GODZILLA 27 — Periodo de gracia del kill switch para no matar
//  coberturas (unwind) recién abiertas antes de que puedan hacer su trabajo.
//
//  CAMBIOS RESPECTO A MECHA-GODZILLA 26:
//
//  [27-1] UseUnwindGraceBars / UnwindGraceBars:
//    Hallazgo en backtest: el 10/abril/2020 el fast-track abrió 12 coberturas
//    a las 06:00 y el kill switch de MaxDailyLoss las liquidó TODAS —junto con
//    el grid— a las 06:03, solo 3 minutos después, sin darles ninguna
//    oportunidad de compensar la pérdida. En cambio, el episodio del
//    3-5/junio/2020 (con más tiempo antes de que la pérdida diaria se
//    recalculara) sí completó el ciclo normalmente (GRID CERRADO → SL LOCK-IN
//    → COMPLETADO).
//    Con UseUnwindGraceBars activo: si `MaxDailyLoss` se dispara mientras hay
//    pares de unwind en FASE 1 (cobertura abierta, grid aún sin cerrar), el
//    kill switch NO liquida de inmediato — concede UnwindGraceBars barras
//    para que la cascada intente compensar por sí sola. Si al final del plazo
//    la pérdida diaria sigue superando el umbral, se liquida todo como antes;
//    si las coberturas ya compensaron (o la pérdida se recuperó) antes de que
//    expire el plazo, el kill switch se desactiva sin intervenir.
//    Es un plazo, no una suspensión indefinida: el respaldo de MaxDailyLoss
//    sigue existiendo si la cascada también fracasa.
//
//  CAMBIOS DE MECHA-GODZILLA 26 (mantenidos íntegros):
//
//  [26-1] Renombrado del EA: v3.91 → MECHA-GODZILLA 26.
//
//  [26-2] FIFO: Cierre escalonado por tiempo máximo abierto (UseFIFOTimeLimit):
//    Si una posición del grid lleva abierta más de FIFOMaxDaysOpen días,
//    se cierra la más antigua (FIFO — primera en entrar, primera en salir).
//    Tras cada cierre FIFO se respeta un enfriamiento de FIFOCloseIntervalDays
//    días antes de forzar el cierre de la siguiente más antigua.
//    Objetivo: evitar que el grid quede atrapado meses en rango sin poder
//    operar (encontrado en backtest: 190 días sin una sola operación,
//    sept-2025 a marzo-2026), liberando cupo para que el grid vuelva a
//    abrir en la posición actual del mercado.
//
//  [26-3] Filtro de volatilidad extrema (UseVolatilityFilter):
//    Compara el ATR de la barra actual contra la media de ATR de las
//    últimas VolatilityRefPeriod barras. Si el ATR actual supera
//    VolatilityATRMultiple veces esa referencia, se bloquean NUEVAS
//    aperturas de grid (no afecta a gestión de lo ya abierto).
//    Objetivo: reducir el apilamiento de posiciones nuevas durante un
//    movimiento violento de una sola vela (encontrado en backtest:
//    12/marzo/2020, stop-out real del bróker al 47.05% de margen, con
//    varias posiciones abiertas horas antes del colapso).
//    IMPORTANTE: no protege frente al golpe sobre posiciones YA abiertas
//    antes de que el ATR se dispare — solo evita añadir más leña al fuego.
//
//  TODOS LOS CAMBIOS DE v3.91 Y ANTERIORES SE MANTIENEN INTACTOS.
//+------------------------------------------------------------------+
//
//  HISTÓRICO — MECHA-GODZILLA v3.91 (Fixes del Algorithmic Unwinding)
//
//  [v3.91-1] UseUnwindFastTrack / UseUnwindNormalMode separados.
//  [v3.91-2] Grid unidireccional (GridDirection).
//  [v3.91-3] Filtro de Hurst (UseHurstFilter).
//  [v3.91-4] Trailing dinámico con swap de la TF.
//  [v3.91-5] NormalModeDistancePoints y NormalModeMaxBarsTrapped reducidos.
//  [BUG-2] Swap incluido en cálculo del lock-in SL.
//  [MEJORA-1] Time trigger en modo normal (NormalModeMaxBarsTrapped).
//  [MEJORA-2] UnwindFastTrackLossUSD proporcional al balance.
//  [MEJORA-3] Confirmación de tendencia en time trigger.
//+------------------------------------------------------------------+

#property copyright "Jose Antonio Montero"
#property link      "https://www.linkedin.com/in/joseamontero/"
#property version   "27.0"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//  PARÁMETROS
//+------------------------------------------------------------------+

input group "── Configuración General ──"
input ENUM_TIMEFRAMES Timeframe             = PERIOD_H1;
input double          InitialBalance        = 1000.0;

input group "── Centro Automático ──"
input int    CenterLookbackBars             = 500;
input int    CenterNumBuckets               = 50;
input double CenterMinQualityScore          = 1.2;

input group "── Recálculo Automático ──"
input int    RecalcIntervalDays             = 7;
input double RecalcATRDistance              = 3.0;

input group "── Grid Dinámico ──"
input int    AtrPeriod                      = 14;
input double AtrStepMultiplier              = 1.5;
input int    MaxGridLevels                  = 20;
input int    MaxPositionsPerLevel           = 2;
input bool   LimitGridPositions             = true;
input int    MaxGridPositions               = 12;

input group "── GridGuard ──"
input double PauseMultiplier                = 12.0;  // Grid pausa solo ante movimientos muy grandes
input double ResumeMultiplier               = 2.0;
input int    MinBarsInState                 = 24;

input group "── Grid Unidireccional ──"
input int    GridDirection                  = 0;      // 0=Bidireccional | 1=Solo BUYs | 2=Solo SELLs

input group "── Filtro de Hurst ──"
input bool   UseHurstFilter                 = false;  // Activar filtro de régimen por exponente de Hurst
input int    HurstPeriod                    = 100;    // Barras para calcular el exponente de Hurst
input double HurstThreshold                 = 0.65;   // H > umbral → tendencia → grid no abre posiciones

input group "── [26] FIFO: Cierre Escalonado por Tiempo ──"
input bool   UseFIFOTimeLimit               = false;  // Activa el cierre forzado de la posición más antigua
input int    FIFOMaxDaysOpen                = 30;     // Días abierta antes de ser candidata a cierre forzado
input int    FIFOCloseIntervalDays          = 2;       // Días mínimos entre dos cierres FIFO consecutivos

input group "── [26] Filtro de Volatilidad Extrema ──"
input bool   UseVolatilityFilter            = false;  // Bloquea nuevas aperturas si el ATR se dispara
input double VolatilityATRMultiple          = 3.0;    // ATR actual > X × ATR de referencia → bloqueo
input int    VolatilityRefPeriod            = 20;     // Barras usadas para el ATR de referencia

input group "── Algorithmic Unwinding ──"
input bool   UseUnwindFastTrack             = true;   // Modo cascada (crash rápido): batch de TFs
input bool   UseUnwindNormalMode            = false;  // Modo lento (tendencia): una TF por posición
input double UnwindLotSize                  = 0.04;
input int    UnwindDistancePoints           = 2000;
input int    UnwindConfirmCandles           = 3;
input double UnwindTrailATR                 = 8.0;
input double UnwindPhase2TrailATR           = 2.0;
input double UnwindPhase2TrailATRMax        = 5.0;
input double UnwindPhase2TrailScaleUSD      = 20.0;
input int    UnwindMinBarsBeforeActivation  = 48;
input int    MaxBarsTrapped                 = 0;
input int    UnwindCooldownBars             = 48;
input double UnwindMinPairProfit            = 0.10;
input double UnwindFastTrackLossUSD         = 80.0;
input double UnwindFastTrackPct             = 15.0;
input int    UnwindFastTrackMinBars         = 1;
input int    UnwindCrashMaxBars             = 12;
input int    NormalModeDistancePoints       = 500;
input int    NormalModeMaxBarsTrapped       = 36;
input int    NormalModeConfirmCandles       = 2;

input group "── Alertas de Gestión Manual ──"
input bool   UseManualAlert                 = true;   // Activar alerta push cuando se recomienda gestión manual
input int    AlertPausedBars                = 48;     // Barras pausado antes de alertar (0=desactivado)
input double AlertMinLossUSD                = 20.0;   // Pérdida flotante mínima para alertar (USD)
input int    AlertCooldownBars              = 96;     // Barras mínimas entre alertas repetidas

input group "── Gestión de Posiciones ──"
input double FixedContractSize              = 0.02;
input bool   UseStopLoss                    = false;
input double StopLossATRMultiplier          = 5.0;
input double MinProfitToClose               = 0.30;

input group "── Gestión de Cuenta ──"
input bool   UseBalanceTarget               = false;
input double BalanceTarget                  = 605.0;
input double MinOperatingBalance            = 1.0;
input double MaxDailyLoss                   = 350.0;
input double SafetyBeltFactor               = 1.0;

input group "── [27] Periodo de Gracia del Kill Switch ──"
input int    UnwindGraceBars                = 24;     // Barras de margen antes de liquidar si hay coberturas en fase 1
                                                        // (0 = comportamiento de v26, liquidación inmediata)

//+------------------------------------------------------------------+
//  CONSTANTES
//+------------------------------------------------------------------+
#define GRID_ACTIVE   0
#define GRID_PAUSED   1
#define UW_INACTIVE   0
#define UW_ACTIVE     1
#define UW_COMPLETED  2

//+------------------------------------------------------------------+
//  VARIABLES GLOBALES
//+------------------------------------------------------------------+

// Grid
double   gridLevelsBuy[];
double   gridLevelsSell[];
bool     levelClosedBuy[];
bool     levelClosedSell[];
int      additionalPositionsOpenedBuy[];
int      additionalPositionsOpenedSell[];

// Centro
double   centralPoint          = 0.0;
double   centerQualityScore    = 0.0;
bool     recalcPending         = false;
datetime lastRecalcTime        = 0;

// GridGuard
int      gridState             = GRID_ACTIVE;
int      barsInCurrentState    = 0;
datetime lastGuardBarTime      = 0;

// Algorithmic Unwinding
int      unwindState           = UW_INACTIVE;
ulong    unwindTicket          = 0;        // Mantenido por compatibilidad SaveState
int      unwindDirection       = 0;
double   unwindEntryPrice      = 0.0;
double   unwindTrailStop       = 0.0;      // Mantenido por compatibilidad SaveState
double   totalUnwoundLoss      = 0.0;
datetime unwindLastCloseTime   = 0;
double   lastUnwindLevel       = 0.0;
int      unwindPairCount       = 0;
int      nextPairId            = 1;        // Contador estable de IDs de pares
bool     fastTrackActive       = false;

// [26] FIFO por tiempo
datetime lastFIFOCloseTime     = 0;

// [26] Filtro de volatilidad extrema
bool     volatilityBlocked     = false;

// [27] Periodo de gracia del kill switch
bool     killSwitchPending     = false;   // true mientras la pérdida diaria está en periodo de gracia
datetime killSwitchGraceStart  = 0;       // instante en que se detectó la pérdida por primera vez

// Estado general
CTrade   trade;
bool     botActive             = true;
bool     isInitialized         = false;
bool     tradingDisabled       = false;
int      initialLevelBuy       = -1;
int      initialLevelSell      = -1;
double   lastPrice             = 0.0;
datetime lastCandleTime        = 0;
datetime lastDayReset          = 0;
double   dailyStartBalance     = 0.0;
double   realizedLoss          = 0.0;
double   effectiveMaxDailyLoss = 0.0;
datetime lastStateSave         = 0;

// ATR
int      atrHandle             = INVALID_HANDLE;
double   currentATR            = 0.0;

// [v3.91] Hurst
double   currentHurst          = 0.5;   // Último valor calculado del exponente de Hurst

// [v3.91] Alertas manuales
int      lastAlertBar           = -999;  // Última barra en la que se envió alerta

// Pre-existentes [FIX-11]
ulong    preExistingTickets[];
int      preExistingCount      = 0;

//+------------------------------------------------------------------+
//  [v3.91] EXPONENTE DE HURST (Método R/S)
//  Calcula H sobre las últimas HurstPeriod barras de cierre.
//  H > 0.65 → tendencia persistente → grid no abre posiciones
//  H < 0.35 → reversión → grid opera normalmente
//  H ≈ 0.50 → ruido aleatorio
//+------------------------------------------------------------------+
double CalculateHurst(int period)
{
   if(period < 20) return 0.5;

   double closes[];
   ArraySetAsSeries(closes, true);
   if(CopyClose(_Symbol, Timeframe, 1, period, closes) < period) return 0.5;

   // Calcular media
   double mean = 0.0;
   for(int i = 0; i < period; i++) mean += closes[i];
   mean /= period;

   // Calcular desviaciones acumuladas (perfil)
   double profile[];
   ArrayResize(profile, period);
   double cumDev = 0.0;
   for(int i = 0; i < period; i++)
   {
      cumDev += closes[i] - mean;
      profile[i] = cumDev;
   }

   // R = rango del perfil
   double maxP = profile[0], minP = profile[0];
   for(int i = 1; i < period; i++)
   {
      if(profile[i] > maxP) maxP = profile[i];
      if(profile[i] < minP) minP = profile[i];
   }
   double R = maxP - minP;
   if(R <= 0.0) return 0.5;

   // S = desviación estándar de los cierres
   double variance = 0.0;
   for(int i = 0; i < period; i++)
      variance += (closes[i] - mean) * (closes[i] - mean);
   double S = MathSqrt(variance / period);
   if(S <= 0.0) return 0.5;

   // H = log(R/S) / log(N)
   double H = MathLog(R / S) / MathLog((double)period);
   H = MathMax(0.0, MathMin(1.0, H));
   return H;
}

// [v3.91] Devuelve true si el grid puede abrir en la dirección indicada
// Considera: GridDirection, UseHurstFilter y [26] filtro de volatilidad
bool GridCanOpen(int direction) // 1=BUY, -1=SELL (interno)
{
   // [26] Filtro de volatilidad extrema — máxima prioridad, bloquea cualquier apertura nueva
   if(volatilityBlocked) return false;

   // Filtro de dirección: 0=bidireccional, 1=solo BUYs, 2=solo SELLs
   if(GridDirection == 1 && direction != 1)  return false;
   if(GridDirection == 2 && direction != -1) return false;

   // Filtro de Hurst
   if(UseHurstFilter && currentHurst > HurstThreshold)
   {
      if(barsInCurrentState % 24 == 0)
         Print("HURST FILTER: H=", DoubleToString(currentHurst, 3),
               " > ", DoubleToString(HurstThreshold, 2),
               " | Régimen tendencial → grid bloqueado");
      return false;
   }
   return true;
}

// [26] Compara el ATR actual contra la media de ATR de referencia reciente.
// Si el ATR actual la supera en VolatilityATRMultiple veces, se considera
// volatilidad extrema y se bloquean nuevas aperturas de grid.
// Solo actúa sobre APERTURAS nuevas — no cierra ni protege posiciones ya abiertas.
bool IsVolatilityExtreme()
{
   if(!UseVolatilityFilter) return false;
   if(currentATR <= 0.0) return false;
   if(VolatilityRefPeriod < 2) return false;

   double refBuf[];
   ArraySetAsSeries(refBuf, true);
   // Shift=1: excluye la barra actual, usa solo barras cerradas previas como referencia
   int copied = CopyBuffer(atrHandle, 0, 1, VolatilityRefPeriod, refBuf);
   if(copied < VolatilityRefPeriod) return false; // datos insuficientes: no bloquear por precaución

   double sum = 0.0;
   for(int i = 0; i < copied; i++) sum += refBuf[i];
   double refATR = sum / copied;
   if(refATR <= 0.0) return false;

   bool extreme = (currentATR > VolatilityATRMultiple * refATR);
   if(extreme && barsInCurrentState % 12 == 0)
      Print("FILTRO VOLATILIDAD: ATR actual=", DoubleToString(currentATR, 5),
            " > ", DoubleToString(VolatilityATRMultiple, 1), "x referencia (",
            DoubleToString(refATR, 5), ") | Ref=", VolatilityRefPeriod, " barras",
            " → nuevas aperturas bloqueadas");
   return extreme;
}

// [26] FIFO: cierra la posición del grid más antigua si supera FIFOMaxDaysOpen días,
// respetando un enfriamiento de FIFOCloseIntervalDays entre cierres consecutivos.
// No depende de gridState (actúa igual si el grid está activo o pausado) — el objetivo
// es liberar cupo de MaxGridPositions para que el grid pueda volver a operar cuanto antes.
void CheckFIFOTimeLimit()
{
   if(!UseFIFOTimeLimit) return;
   if(FIFOMaxDaysOpen <= 0) return;

   if(lastFIFOCloseTime > 0 && FIFOCloseIntervalDays > 0)
   {
      double daysSinceLastClose = (double)(TimeCurrent() - lastFIFOCloseTime) / 86400.0;
      if(daysSinceLastClose < FIFOCloseIntervalDays) return;
   }

   ulong    oldestTicket = 0;
   datetime oldestTime   = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(IsPreExisting(ticket) || IsUnwindPosition(ticket)) continue;
      if(StringFind(PositionGetString(POSITION_COMMENT), "Level") < 0) continue;

      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      if(oldestTicket == 0 || openTime < oldestTime)
      {
         oldestTicket = ticket;
         oldestTime   = openTime;
      }
   }

   if(oldestTicket == 0) return;

   double daysOpen = (double)(TimeCurrent() - oldestTime) / 86400.0;
   if(daysOpen < FIFOMaxDaysOpen) return;

   double profit = 0.0;
   if(PositionSelectByTicket(oldestTicket))
      profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

   if(trade.PositionClose(oldestTicket))
   {
      Print("FIFO: Posición #", oldestTicket, " cerrada tras ", DoubleToString(daysOpen, 1),
            " días abierta | P/L=", DoubleToString(profit, 2),
            " USD | Balance=", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
      lastFIFOCloseTime = TimeCurrent();

      // Liberar niveles para que el grid pueda reconstruir donde toca
      isInitialized = false;
      ArrayInitialize(levelClosedBuy,  false);
      ArrayInitialize(levelClosedSell, false);
   }
}

// [v3.91] Alerta push cuando el grid lleva mucho tiempo pausado con pérdida significativa
void CheckManualAlert()
{
   if(!UseManualAlert) return;
   if(AlertPausedBars <= 0) return;
   if(gridState != GRID_PAUSED) return;
   if(barsInCurrentState < AlertPausedBars) return;

   // Cooldown: no repetir alerta demasiado seguido
   int currentBar = iBars(_Symbol, Timeframe);
   if(currentBar - lastAlertBar < AlertCooldownBars) return;

   // Calcular pérdida flotante total del grid
   double floatingLoss = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tkt = PositionGetTicket(i);
      if(!PositionSelectByTicket(tkt)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(IsPreExisting(tkt)) continue;
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(profit < 0) floatingLoss += MathAbs(profit);
   }

   if(floatingLoss < AlertMinLossUSD) return;

   // Enviar alerta
   string msg = StringFormat(
      "⚠️ MECHA-GODZILLA 27 | %s\n"
      "Grid pausado: %d barras\n"
      "Pérdida flotante: -%.2f USD\n"
      "→ Considerar gestión manual",
      _Symbol, barsInCurrentState, floatingLoss);

   SendNotification(msg);
   Alert(msg);
   Print("ALERTA MANUAL: ", msg);
   lastAlertBar = currentBar;
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

string StateKey(string name)
{
   return "BotState_" + _Symbol + "_" + name;
}

bool IsPreExisting(ulong ticket)
{
   for(int i = 0; i < preExistingCount; i++)
      if(preExistingTickets[i] == ticket) return true;
   return false;
}

// [FIX-UW-1] Buscar en unwindPairs[].tfTicket, no en unwindTicket (siempre 0)
bool IsUnwindPosition(ulong ticket)
{
   for(int i = 0; i < unwindPairCount; i++)
      if(unwindPairs[i].active && unwindPairs[i].tfTicket == ticket)
         return true;
   return false;
}

void CapturePreExistingPositions()
{
   preExistingCount = 0;
   ArrayResize(preExistingTickets, PositionsTotal());
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetSymbol(i) == _Symbol)
      {
         preExistingTickets[preExistingCount] = PositionGetTicket(i);
         preExistingCount++;
      }
   }
   if(preExistingCount > 0)
      Print("[FIX-11] Posiciones pre-existentes ignoradas: ", preExistingCount);
}

//+------------------------------------------------------------------+
//  MÓDULO 1 — CENTRO AUTOMÁTICO
//+------------------------------------------------------------------+

double CalculateCenterFromHistogram(double &qualityScore)
{
   qualityScore = 0.0;

   double closes[];
   int copied = CopyClose(_Symbol, Timeframe, 0, CenterLookbackBars, closes);
   if(copied < 30) { Print("GridCenter: datos insuficientes"); return 0.0; }
   ArraySetAsSeries(closes, false);

   double priceHigh = closes[0], priceLow = closes[0];
   for(int i = 1; i < copied; i++)
   {
      if(closes[i] > priceHigh) priceHigh = closes[i];
      if(closes[i] < priceLow)  priceLow  = closes[i];
   }
   double rangeSize = priceHigh - priceLow;
   if(rangeSize <= 0.0) return 0.0;

   int histogram[];
   ArrayResize(histogram, CenterNumBuckets);
   ArrayInitialize(histogram, 0);
   double bucketSize = rangeSize / CenterNumBuckets;

   for(int i = 0; i < copied; i++)
   {
      int b = (int)((closes[i] - priceLow) / bucketSize);
      b = MathMax(0, MathMin(CenterNumBuckets - 1, b));
      histogram[b]++;
   }

   int maxCount = 0, modeBucket = 0;
   for(int i = 0; i < CenterNumBuckets; i++)
      if(histogram[i] > maxCount) { maxCount = histogram[i]; modeBucket = i; }

   double centerPrice = priceLow + (modeBucket + 0.5) * bucketSize;

   int secondMax = 0, secondBucket = -1;
   for(int i = 0; i < CenterNumBuckets; i++)
      if(i != modeBucket && histogram[i] > secondMax)
         { secondMax = histogram[i]; secondBucket = i; }

   if(secondBucket >= 0 && secondMax > maxCount * 0.80)
   {
      double c1 = priceLow + (modeBucket   + 0.5) * bucketSize;
      double c2 = priceLow + (secondBucket + 0.5) * bucketSize;
      centerPrice = (c1 + c2) / 2.0;
      if(MathAbs(secondBucket - CenterNumBuckets/2.0) <
         MathAbs(modeBucket   - CenterNumBuckets/2.0))
         modeBucket = secondBucket;
   }

   double expectedFreq       = (double)copied / CenterNumBuckets;
   double concentrationRatio = (expectedFreq > 0) ? (double)maxCount / expectedFreq : 0.0;
   double relativePos        = (modeBucket + 0.5) / CenterNumBuckets;
   double centralityScore    = 1.0 - 2.0 * MathAbs(relativePos - 0.5);
   qualityScore              = concentrationRatio * centralityScore;

   bool isBiased = (relativePos < 0.30 || relativePos > 0.70);
   string quality = isBiased ? "SESGADO"
                  : qualityScore >= 2.0 ? "APTO"
                  : qualityScore >= CenterMinQualityScore ? "CAUTELA"
                  : "INAPROPIADO";

   Print("GridCenter: ", DoubleToString(centerPrice, _Digits),
         " | Score=", DoubleToString(qualityScore, 2), " → ", quality);

   return NormalizeDouble(centerPrice, _Digits);
}

//+------------------------------------------------------------------+
//  MÓDULO 2 — RECÁLCULO
//+------------------------------------------------------------------+

bool ShouldRecalculate()
{
   bool timeOk = (lastRecalcTime == 0 ||
                  (TimeCurrent() - lastRecalcTime) >= RecalcIntervalDays * 86400);
   bool distOk = false;
   if(centralPoint > 0 && currentATR > 0)
   {
      double dist = MathAbs(SymbolInfoDouble(_Symbol, SYMBOL_BID) - centralPoint);
      distOk = (dist > RecalcATRDistance * currentATR);
   }
   return (timeOk || distOk);
}

bool HasOpenGridPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&
         !IsUnwindPosition(PositionGetTicket(i)))
         return true;
   }
   return false;
}

void TryRecalculateCenter()
{
   if(HasOpenGridPositions())
   {
      if(!recalcPending)
      {
         recalcPending = true;
         Print("Recálculo pendiente: hay posiciones del grid abiertas.");
      }
      return;
   }

   double qs = 0.0;
   double cp = CalculateCenterFromHistogram(qs);
   if(cp <= 0.0) { Print("Recálculo fallido. Manteniendo centro anterior."); return; }

   centralPoint       = cp;
   centerQualityScore = qs;
   lastRecalcTime     = TimeCurrent();
   recalcPending      = false;

   BuildGrid();
   isInitialized = false;

   Print("Centro recalculado → ", DoubleToString(centralPoint, _Digits),
         " | Score=", DoubleToString(centerQualityScore, 2));
}

//+------------------------------------------------------------------+
//  MÓDULO 3 — GRID DINÁMICO
//+------------------------------------------------------------------+

void BuildGrid()
{
   if(currentATR <= 0.0) { Print("BuildGrid: ATR no disponible."); return; }

   double step = AtrStepMultiplier * currentATR;
   for(int i = 0; i < MaxGridLevels; i++)
   {
      gridLevelsBuy[i]  = NormalizeDouble(centralPoint - (i + 1) * step, _Digits);
      gridLevelsSell[i] = NormalizeDouble(centralPoint + (i + 1) * step, _Digits);
   }
   DrawGridLines();
   Print("Grid: paso=", DoubleToString(step / _Point, 0), "pts | ATR=",
         DoubleToString(currentATR, _Digits));
}

//+------------------------------------------------------------------+
//  MÓDULO 4 — GRIDGUARD
//+------------------------------------------------------------------+

void UpdateGridGuard()
{
   if(currentATR <= 0.0 || centralPoint <= 0.0) return;

   datetime currentBar = iTime(_Symbol, Timeframe, 0);
   if(currentBar == lastGuardBarTime) return;
   lastGuardBarTime = currentBar;
   barsInCurrentState++;

   double price       = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double distance    = MathAbs(price - centralPoint);
   double pauseRange  = PauseMultiplier  * currentATR;
   double resumeRange = ResumeMultiplier * currentATR;

   bool canTransition = (barsInCurrentState >= MinBarsInState);

   if(canTransition)
   {
      if(gridState == GRID_ACTIVE && distance > pauseRange)
      {
         gridState          = GRID_PAUSED;
         barsInCurrentState = 0;
         string dir = (price > centralPoint) ? "ALCISTA" : "BAJISTA";
         Print("GRID PAUSADO | ", DoubleToString(distance / currentATR, 2), "x ATR | ", dir);
      }
      else if(gridState == GRID_PAUSED && distance < resumeRange)
      {
         gridState          = GRID_ACTIVE;
         barsInCurrentState = 0;
         Print("GRID ACTIVO | ", DoubleToString(distance / currentATR, 2), "x ATR");

         if(unwindPairCount > 0)
            StopUnwinding("Precio volvió al rango del grid");
      }
   }
}

//+------------------------------------------------------------------+
//  MÓDULO 5 — ALGORITHMIC UNWINDING UNO A UNO
//+------------------------------------------------------------------+

struct UnwindPair
{
   int    pairId;
   ulong  gridTicket;
   ulong  tfTicket;
   double gridOpenPrice;
   double tfOpenPrice;
   bool   active;
   bool   gridClosed;
   double gridRealizedLoss;
   double phase2StartATR;   // ATR congelado en el momento de transición a fase 2
                            // Evita que el trailing se paralice cuando el ATR explota durante crashes
};

UnwindPair unwindPairs[];

ulong FindMostLossUnpairedGridPosition()
{
   ulong paired[];
   int   pairedCount = 0;
   ArrayResize(paired, unwindPairCount);
   for(int i = 0; i < unwindPairCount; i++)
      if(unwindPairs[i].active)
         paired[pairedCount++] = unwindPairs[i].gridTicket;

   ulong  worstTicket = 0;
   double worstProfit = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) != _Symbol) continue;
      ulong ticket = PositionGetTicket(i);
      if(IsPreExisting(ticket)) continue;
      if(IsUnwindPosition(ticket)) continue;  // [FIX-UW-1] ahora funciona correctamente

      bool alreadyPaired = false;
      for(int j = 0; j < pairedCount; j++)
         if(paired[j] == ticket) { alreadyPaired = true; break; }
      if(alreadyPaired) continue;

      double profit = PositionGetDouble(POSITION_PROFIT);
      if(profit < worstProfit)
      {
         worstProfit = profit;
         worstTicket = ticket;
      }
   }
   return worstTicket;
}

int CountUnpairedTrappedPositions()
{
   ulong paired[];
   int   pairedCount = 0;
   ArrayResize(paired, unwindPairCount);
   for(int i = 0; i < unwindPairCount; i++)
      if(unwindPairs[i].active)
         paired[pairedCount++] = unwindPairs[i].gridTicket;

   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) != _Symbol) continue;
      ulong ticket = PositionGetTicket(i);
      if(IsPreExisting(ticket) || IsUnwindPosition(ticket)) continue;  // [FIX-UW-1]

      bool alreadyPaired = false;
      for(int j = 0; j < pairedCount; j++)
         if(paired[j] == ticket) { alreadyPaired = true; break; }
      if(!alreadyPaired) count++;
   }
   return count;
}

// [MEJORA-4] ELIMINADA: lote dinámico proporcional al balance.
// Razón: el lock-in SL se calcula como gridLoss / (lotSize × pointValue).
// Si la TF abre con lote menor que el usado al calcular gridRealizedLoss,
// la distancia de breakeven se incrementa proporcionalmente y la TF
// puede cerrar por trailing antes de cubrir la pérdida del grid.
// El lote de la TF debe ser siempre consistente con el cálculo del lock-in.
// Si el balance cae por debajo del mínimo operativo, MinOperatingBalance
// detiene el bot limpiamente — ese es el mecanismo correcto.
double GetEffectiveLotSize()
{
   return UnwindLotSize;
}

bool OpenUnwindTF(int direction)
{
   if(!UseUnwindFastTrack && !UseUnwindNormalMode) return false;
   if(currentATR <= 0.0) return false;

   double effectiveLot = GetEffectiveLotSize();

   // [FIX-UW-3] Fast-track: sin cooldown entre TFs — se abren todas de golpe
   int effectiveCooldown = fastTrackActive ? 0 : UnwindCooldownBars;
   if(unwindLastCloseTime > 0 && effectiveCooldown > 0)
   {
      int barsSince = (int)((TimeCurrent() - unwindLastCloseTime) / PeriodSeconds(Timeframe));
      if(barsSince < effectiveCooldown) return false;
   }

   if(unwindPairCount >= CountGridPositions()) return false;  // [FIX-UW-1] ahora CountGridPositions() es correcto

   long   stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist    = MathMax((stopsLevel + 2) * _Point, currentATR * 0.5);

   double price   = 0.0;
   double sl      = 0.0;
   bool   success = false;
   string comment = "";

   if(direction == 1)
   {
      price        = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double rawSL = price - UnwindTrailATR * currentATR;
      if(price - rawSL < minDist) rawSL = price - minDist;
      sl      = NormalizeDouble(rawSL, _Digits);
      comment = "Unwind_TF_Buy";
      success = trade.Buy(effectiveLot, _Symbol, 0, sl, 0, comment);
   }
   else
   {
      price        = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double rawSL = price + UnwindTrailATR * currentATR;
      if(rawSL - price < minDist) rawSL = price + minDist;
      sl      = NormalizeDouble(rawSL, _Digits);
      comment = "Unwind_TF_Sell";
      success = trade.Sell(effectiveLot, _Symbol, 0, sl, 0, comment);
   }

   if(!success)
   {
      Print("UNWIND TF: Fallo al abrir. Error=", GetLastError());
      return false;
   }

   ulong  tfTicket    = 0;
   double tfOpenPrice = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetString(POSITION_COMMENT) == comment)
      {
         ulong t = PositionGetTicket(i);
         bool alreadyKnown = false;
         for(int j = 0; j < unwindPairCount; j++)
            if(unwindPairs[j].tfTicket == t) { alreadyKnown = true; break; }
         if(!alreadyKnown)
         {
            tfTicket    = t;
            tfOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            break;
         }
      }
   }

   if(tfTicket == 0)
   {
      Print("UNWIND TF: No se pudo obtener ticket. Error=", GetLastError());
      return false;
   }

   ulong gridTicket = FindMostLossUnpairedGridPosition();
   if(gridTicket == 0)
   {
      Print("UNWIND TF: Sin posiciones del grid para emparejar. Cerrando TF.");
      trade.PositionClose(tfTicket);
      return false;
   }

   ArrayResize(unwindPairs, unwindPairCount + 1);
   unwindPairs[unwindPairCount].pairId           = nextPairId++;
   unwindPairs[unwindPairCount].gridTicket       = gridTicket;
   unwindPairs[unwindPairCount].tfTicket         = tfTicket;
   unwindPairs[unwindPairCount].tfOpenPrice      = tfOpenPrice;
   unwindPairs[unwindPairCount].active           = true;
   unwindPairs[unwindPairCount].gridClosed       = false;
   unwindPairs[unwindPairCount].gridRealizedLoss = 0.0;
   unwindPairs[unwindPairCount].phase2StartATR   = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetTicket(i) == gridTicket)
      {
         unwindPairs[unwindPairCount].gridOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         break;
      }

   unwindPairCount++;
   lastUnwindLevel = price;
   unwindState     = 1;

   string mode = fastTrackActive ? " [FAST-TRACK]" : "";
   Print("UNWIND PAR #", unwindPairCount, mode,
         " | TF=", tfTicket, " @ ", DoubleToString(tfOpenPrice, _Digits),
         " ↔ GRID=", gridTicket,
         " | Dir=", (direction == 1 ? "BUY" : "SELL"));

   return true;
}

// Calcula y aplica el SL de cobertura garantizada para una TF en fase 2.
// El SL se coloca en el precio exacto donde el beneficio de la TF = gridRealizedLoss.
// Esto garantiza que si el precio revierte hasta ese nivel, la TF cubre exactamente
// la pérdida realizada del grid emparejado. El trailing stop continuará tightening
// desde ese punto si el precio sigue a favor.
void SetTFLockInSL(int pairIndex)
{
   ulong  tfTkt     = unwindPairs[pairIndex].tfTicket;
   double tfOpen    = unwindPairs[pairIndex].tfOpenPrice;
   double totalLoss = unwindPairs[pairIndex].gridRealizedLoss; // mercado + swap, ya calculado correctamente

   if(!PositionSelectByTicket(tfTkt)) return;
   int posType = (int)PositionGetInteger(POSITION_TYPE);

   // Valor monetario de 1 punto de movimiento para el tamaño de la TF
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0.0 || tickSize <= 0.0) return;

   double effectiveLot = GetEffectiveLotSize();
   double pointValue = effectiveLot * tickVal / tickSize * _Point;
   if(pointValue <= 0.0) return;

   // Distancia en precio desde tfOpen para que beneficio de la TF = totalLoss
   double lockInDistance = (totalLoss * _Point) / pointValue;

   double lockInSL = 0.0;
   long   stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist    = MathMax((stopsLevel + 2) * _Point, currentATR * 0.3);

   if(posType == POSITION_TYPE_SELL)
   {
      // Para SELL: lock-in SL está por debajo del precio de apertura (en zona de beneficio)
      lockInSL = NormalizeDouble(tfOpen - lockInDistance, _Digits);
      double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      // El SL debe estar por encima del precio actual (Ask) + distancia mínima
      if(lockInSL < curAsk + minDist) lockInSL = NormalizeDouble(curAsk + minDist, _Digits);
   }
   else // BUY
   {
      // Para BUY: lock-in SL está por encima del precio de apertura
      lockInSL = NormalizeDouble(tfOpen + lockInDistance, _Digits);
      double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(lockInSL > curBid - minDist) lockInSL = NormalizeDouble(curBid - minDist, _Digits);
   }

   double curSL = PositionGetDouble(POSITION_SL);

   // Solo aplicar si el nuevo SL es MEJOR (más protegido) que el actual
   bool apply = false;
   if(posType == POSITION_TYPE_SELL && (curSL == 0.0 || lockInSL < curSL - _Point)) apply = true;
   if(posType == POSITION_TYPE_BUY  && (curSL == 0.0 || lockInSL > curSL + _Point)) apply = true;

   if(apply)
   {
      trade.PositionModify(tfTkt, lockInSL, 0);
      Print("UNWIND PAR #", unwindPairs[pairIndex].pairId, " — SL LOCK-IN @ ", DoubleToString(lockInSL, _Digits),
            " | Cobertura garantizada: ", DoubleToString(totalLoss, 2), " USD");
   }
}

void ManageUnwindPairs()
{
   if(unwindPairCount == 0) return;

   for(int i = unwindPairCount - 1; i >= 0; i--)
   {
      if(!unwindPairs[i].active) continue;

      ulong  gridTkt   = unwindPairs[i].gridTicket;
      ulong  tfTkt     = unwindPairs[i].tfTicket;
      double tfProfit  = 0.0;
      bool   tfExists  = false;

      // Buscar la TF
      for(int j = PositionsTotal() - 1; j >= 0; j--)
         if(PositionGetTicket(j) == tfTkt)
            { tfProfit = PositionGetDouble(POSITION_PROFIT); tfExists = true; break; }

      // ── FASE 1: Grid aún abierto ──────────────────────────────────────────
      if(!unwindPairs[i].gridClosed)
      {
         double gridProfit = 0.0;
         bool   gridExists = false;
         for(int j = PositionsTotal() - 1; j >= 0; j--)
            if(PositionGetTicket(j) == gridTkt)
               { gridProfit = PositionGetDouble(POSITION_PROFIT); gridExists = true; break; }

         // TF desapareció antes de compensar el grid (cerrada por SL)
         if(!tfExists)
         {
            Print("UNWIND PAR #", unwindPairs[i].pairId, ": TF cerrada por SL antes de compensar grid. ",
                  "Grid sigue abierto. Desregistrando par.");
            unwindPairs[i].active = false;
            unwindLastCloseTime   = TimeCurrent();
            continue;
         }

         // Grid desapareció externamente (otro mecanismo lo cerró)
         if(!gridExists)
         {
            Print("UNWIND PAR #", unwindPairs[i].pairId, ": Grid cerrado externamente. TF #", tfTkt, " sigue corriendo.");
            unwindPairs[i].gridClosed = true;
            // No cerramos la TF — la dejamos correr con trailing stop
            continue;
         }

         // ¿La TF ha compensado la pérdida del grid?
         double pairTotal = gridProfit + tfProfit;
         if(pairTotal >= UnwindMinPairProfit)
         {
            // [BUG-2 FIX DEFINITIVO] Leer swap mientras la posición grid está aún abierta.
            // POSITION_SWAP está disponible en este momento exacto — es el método más fiable.
            // gridProfit = solo mercado (POSITION_PROFIT no incluye swap en MT5)
            // gridSwap   = swap acumulado real de la posición
            double gridSwap = PositionGetDouble(POSITION_SWAP);
            // gridRealizedLoss = mercado + swap (pérdida total real que la TF debe cubrir)
            double totalGridLoss = MathAbs(gridProfit) + MathAbs(gridSwap);

            // Guardar pérdida total realizada y ATR congelado antes de cerrar el grid
            unwindPairs[i].gridRealizedLoss = totalGridLoss;
            unwindPairs[i].phase2StartATR   = currentATR;  // ATR congelado: no crece con el crash

            // Cerrar SOLO el grid — la TF sigue corriendo
            trade.PositionClose(gridTkt);
            unwindPairs[i].gridClosed = true;
            totalUnwoundLoss         += gridProfit;

            Print("UNWIND PAR #", unwindPairs[i].pairId, " — GRID CERRADO | Grid=",
                  DoubleToString(gridProfit, 2), " Swap=", DoubleToString(gridSwap, 2),
                  " TotalLoss=", DoubleToString(totalGridLoss, 2),
                  " TF=", DoubleToString(tfProfit, 2),
                  " | TF pasa a fase 2 con SL lock-in.");

            // Mover inmediatamente el SL de la TF al precio de cobertura garantizada
            SetTFLockInSL(i);

            ArrayInitialize(levelClosedBuy,               false);
            ArrayInitialize(levelClosedSell,              false);
            ArrayInitialize(additionalPositionsOpenedBuy, 0);
            ArrayInitialize(additionalPositionsOpenedSell,0);
            isInitialized = false;
         }
      }
      // ── FASE 2: Grid cerrado, TF corriendo libre con trailing stop ────────
      else
      {
         if(!tfExists)
         {
            // TF cerrada por trailing stop → par completado
            Print("UNWIND PAR #", unwindPairs[i].pairId, " COMPLETADO — TF cerrada por trailing stop.");
            unwindPairs[i].active = false;
            unwindLastCloseTime   = TimeCurrent();
         }
         // Si TF sigue abierta: no hacemos nada aquí,
         // UpdateAllUnwindTrailingStops() gestiona el SL en cada vela.
      }
   }

   // Compactar array eliminando pares inactivos
   int activeCount = 0;
   for(int i = 0; i < unwindPairCount; i++)
      if(unwindPairs[i].active) activeCount++;

   if(activeCount < unwindPairCount)
   {
      UnwindPair temp[];
      ArrayResize(temp, activeCount);
      int idx = 0;
      for(int i = 0; i < unwindPairCount; i++)
         if(unwindPairs[i].active) temp[idx++] = unwindPairs[i];
      ArrayCopy(unwindPairs, temp);
      unwindPairCount = activeCount;
      if(unwindPairCount == 0) unwindState = 0;
   }
}

void UpdateAllUnwindTrailingStops()
{
   if(unwindPairCount == 0 || currentATR <= 0.0) return;

   long   stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist    = MathMax((stopsLevel + 2) * _Point, currentATR * 0.3);

   for(int i = 0; i < unwindPairCount; i++)
   {
      if(!unwindPairs[i].active) continue;
      ulong tfTkt = unwindPairs[i].tfTicket;

      if(!PositionSelectByTicket(tfTkt)) continue;

      int    posType  = (int)PositionGetInteger(POSITION_TYPE);
      double curPrice = (posType == POSITION_TYPE_BUY)
                        ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                        : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double curSL    = PositionGetDouble(POSITION_SL);
      double newSL    = 0.0;
      bool   doModify = false;

      bool inPhase2 = unwindPairs[i].gridClosed;
      double trailMult;
      double atrToUse;

      if(!inPhase2)
      {
         // FASE 1: grid aún abierto → trailing ancho con ATR actual
         trailMult = UnwindTrailATR;
         atrToUse  = currentATR;
      }
      else
      {
         // FASE 2: ATR CONGELADO del momento de transición
         // Si usáramos currentATR (que explota en crashes), el trailing se paraliza.
         // Con el ATR congelado, la distancia base permanece estable y el SL
         // sigue al precio correctamente aunque el mercado sea muy volátil.
         atrToUse = (unwindPairs[i].phase2StartATR > 0.0)
                    ? unwindPairs[i].phase2StartATR
                    : currentATR;

         // Trailing adaptativo: escala según beneficio extra acumulado
         double tfProfit    = PositionGetDouble(POSITION_PROFIT);
         double extraProfit = tfProfit - unwindPairs[i].gridRealizedLoss;
         double scaleRange  = UnwindPhase2TrailATRMax - UnwindPhase2TrailATR;

         if(UnwindPhase2TrailScaleUSD > 0.0 && scaleRange > 0.0 && extraProfit > 0.0)
         {
            double ratio = MathMin(1.0, extraProfit / UnwindPhase2TrailScaleUSD);
            trailMult = UnwindPhase2TrailATR + ratio * scaleRange;
         }
         else
            trailMult = UnwindPhase2TrailATR;

         if(barsInCurrentState % 12 == 0 && extraProfit > 0.0)
            Print("UNWIND TF #", unwindPairs[i].tfTicket, " [ADAPT] Trail=",
                  DoubleToString(trailMult, 2), "×ATR(frozen=",
                  DoubleToString(atrToUse, 5), ") | Extra=",
                  DoubleToString(extraProfit, 2), " USD");
      }

      if(posType == POSITION_TYPE_BUY)
      {
         // BUY: precio sube → SL sube siguiendo
         newSL = NormalizeDouble(curPrice - trailMult * atrToUse, _Digits);
         if(curPrice - newSL < minDist) newSL = NormalizeDouble(curPrice - minDist, _Digits);
         if(newSL > curSL + _Point) doModify = true;
         if(inPhase2 && unwindPairs[i].gridRealizedLoss > 0.0)
         {
            double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            if(tickVal > 0.0 && tickSize > 0.0)
            {
               double pv       = GetEffectiveLotSize() * tickVal / tickSize * _Point;
               // [v3.91-4] Sumar swap acumulado de la TF al suelo mínimo
               double tfSwap   = 0.0;
               if(PositionSelectByTicket(unwindPairs[i].tfTicket))
                  tfSwap = MathAbs(PositionGetDouble(POSITION_SWAP));
               double floorLoss = unwindPairs[i].gridRealizedLoss + tfSwap;
               double lockIn = NormalizeDouble(
                  unwindPairs[i].tfOpenPrice + floorLoss * _Point / pv, _Digits);
               if(newSL < lockIn) { newSL = lockIn; doModify = (newSL > curSL + _Point); }
            }
         }
      }
      else // SELL
      {
         newSL = NormalizeDouble(curPrice + trailMult * atrToUse, _Digits);
         if(newSL - curPrice < minDist) newSL = NormalizeDouble(curPrice + minDist, _Digits);
         if(curSL == 0.0 || newSL < curSL - _Point) doModify = true;
         if(inPhase2 && unwindPairs[i].gridRealizedLoss > 0.0)
         {
            double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            if(tickVal > 0.0 && tickSize > 0.0)
            {
               double pv       = GetEffectiveLotSize() * tickVal / tickSize * _Point;
               // [v3.91-4] Sumar swap acumulado de la TF al suelo mínimo
               double tfSwap   = 0.0;
               if(PositionSelectByTicket(unwindPairs[i].tfTicket))
                  tfSwap = MathAbs(PositionGetDouble(POSITION_SWAP));
               double floorLoss = unwindPairs[i].gridRealizedLoss + tfSwap;
               double lockIn = NormalizeDouble(
                  unwindPairs[i].tfOpenPrice - floorLoss * _Point / pv, _Digits);
               if(newSL > lockIn) { newSL = lockIn; doModify = (curSL == 0.0 || newSL < curSL - _Point); }
            }
         }
      }

      if(doModify)
      {
         trade.PositionModify(tfTkt, newSL, 0);
         if(inPhase2)
            Print("UNWIND TF #", tfTkt, " [FASE2] SL → ", DoubleToString(newSL, _Digits),
                  " | Precio=", DoubleToString(curPrice, _Digits),
                  " | Trail=", DoubleToString(trailMult, 2), "×ATR(", DoubleToString(atrToUse,5), ")");
      }
   }
}

void ManageUnwinding()
{
   if(gridState != GRID_PAUSED) return;
   if(!HasOpenGridPositions()) return;

   ManageUnwindPairs();
   // UpdateAllUnwindTrailingStops se llama en OnTick independientemente del gridState

   if(!UseUnwindFastTrack && !UseUnwindNormalMode) return;

   int unpairedCount = CountUnpairedTrappedPositions();
   if(unpairedCount == 0) return;

   // [MEJORA-2] Fast-track threshold dinámico proporcional al balance
   fastTrackActive = false;
   double effectiveFastTrackUSD = (UnwindFastTrackPct > 0.0)
      ? AccountInfoDouble(ACCOUNT_BALANCE) * UnwindFastTrackPct / 100.0
      : UnwindFastTrackLossUSD;

   if(effectiveFastTrackUSD > 0.0)
   {
      double totalFloating = 0.0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(PositionGetSymbol(i) != _Symbol) continue;
         ulong t = PositionGetTicket(i);
         if(IsPreExisting(t) || IsUnwindPosition(t)) continue;
         totalFloating += PositionGetDouble(POSITION_PROFIT);
      }

      if(totalFloating <= -effectiveFastTrackUSD &&
         barsInCurrentState >= UnwindFastTrackMinBars)
      {
         bool isCrash = (UnwindCrashMaxBars <= 0 || barsInCurrentState <= UnwindCrashMaxBars);

         if(isCrash)
         {
            fastTrackActive = true;
            if(barsInCurrentState % 12 == 0)
               Print("UNWIND FAST-TRACK [CRASH] | Flotante=",
                     DoubleToString(totalFloating, 2), " USD | Barras=",
                     barsInCurrentState, " ≤ ", UnwindCrashMaxBars,
                     " | Umbral=", DoubleToString(effectiveFastTrackUSD, 2), " USD",
                     " | Sin cubrir=", unpairedCount);
         }
         else
         {
            if(barsInCurrentState % 24 == 0)
               Print("UNWIND TENDENCIA LENTA | Flotante=",
                     DoubleToString(totalFloating, 2), " USD | Barras=",
                     barsInCurrentState, " > ", UnwindCrashMaxBars,
                     " | Modo normal activo | Sin cubrir=", unpairedCount);
         }
      }
   }

   // [FIX-UW-2] Fast-track bypassa la espera de MinBarsBeforeActivation
   if(!fastTrackActive && barsInCurrentState < UnwindMinBarsBeforeActivation) return;

   // [FIX-UW-3] Cooldown dinámico (se aplica en OpenUnwindTF via fastTrackActive)
   if(!fastTrackActive && unwindLastCloseTime > 0 && UnwindCooldownBars > 0)
   {
      int barsSince = (int)((TimeCurrent() - unwindLastCloseTime) / PeriodSeconds(Timeframe));
      if(barsSince < UnwindCooldownBars) return;
   }

   double price    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(currentATR <= 0.0) return;

   double distance       = MathAbs(price - centralPoint);
   double distancePoints = distance / _Point;

   // [BUG-1 FIX] UnwindDistancePoints solo aplica al fast-track.
   // El modo normal usa NormalModeDistancePoints por posición individual.
   // Antes este check bloqueaba ambos modos, dejando posiciones sin cobertura semanas.

   // Determinar dirección
   int trappedBuys = 0, trappedSells = 0;
   ulong paired[];
   ArrayResize(paired, unwindPairCount);
   for(int i = 0; i < unwindPairCount; i++)
      paired[i] = unwindPairs[i].gridTicket;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) != _Symbol) continue;
      ulong t = PositionGetTicket(i);
      if(IsPreExisting(t) || IsUnwindPosition(t)) continue;
      bool alreadyPaired = false;
      for(int j = 0; j < unwindPairCount; j++)
         if(paired[j] == t) { alreadyPaired = true; break; }
      if(alreadyPaired) continue;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)  trappedBuys++;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) trappedSells++;
   }

   int direction = 0;
   if(trappedSells > trappedBuys)      direction =  1;
   else if(trappedBuys > trappedSells) direction = -1;
   else direction = (price > centralPoint) ? 1 : -1;
   if(direction == 0) return;

   // Confirmación de tendencia (menos restrictivo en fast-track)
   int confirmRequired = fastTrackActive ? MathMax(1, UnwindConfirmCandles - 1)
                                         : UnwindConfirmCandles;
   if(confirmRequired > 0)
   {
      int confirmed = 0;
      for(int c = 1; c <= confirmRequired + 2; c++)
      {
         double o  = iOpen(_Symbol, Timeframe, c);
         double cl = iClose(_Symbol, Timeframe, c);
         if(direction == 1  && cl > o) confirmed++;
         if(direction == -1 && cl < o) confirmed++;
      }
      if(confirmed < confirmRequired)
      {
         if(barsInCurrentState % 12 == 0)
            Print("UNWIND: Tendencia no confirmada. ",
                  confirmed, "/", confirmRequired, " velas.");
         return;
      }
   }

   if(distance < ResumeMultiplier * currentATR) return;

   // ── Apertura: batch en fast-track, por distancia-por-posición en normal ────
   if(fastTrackActive && UseUnwindFastTrack)
   {
      // [BUG-1 FIX] Check de distancia del centro solo en fast-track
      if(distancePoints < UnwindDistancePoints)
      {
         if(barsInCurrentState % 24 == 0)
            Print("UNWIND: Distancia insuficiente para fast-track. ",
                  DoubleToString(distancePoints, 0), " < ",
                  IntegerToString(UnwindDistancePoints), " puntos.");
         return;
      }

      // FAST-TRACK: una TF por cada posición atrapada sin pareja, todas de golpe.
      // Sin cooldown entre ellas, sin requisito de distancia.
      int unpairedNow = CountUnpairedTrappedPositions();
      if(unpairedNow == 0) return;

      int opened = 0;
      for(int p = 0; p < unpairedNow; p++)
      {
         if(CountUnpairedTrappedPositions() == 0) break;
         if(!OpenUnwindTF(direction)) break;
         opened++;
      }
      if(opened > 0)
         Print("UNWIND FAST-TRACK BATCH: ", opened, "/", unpairedNow,
               " TFs abiertas | Aún sin cubrir: ", CountUnpairedTrappedPositions());
   }
   else if(UseUnwindNormalMode)
   {
      // MODO NORMAL: una TF por posición cuando el precio está a
      // NormalModeDistancePoints desde la apertura de ESA posición.
      // [MEJORA-1] O cuando lleva NormalModeMaxBarsTrapped barras pausada (time trigger).
      // La primera que supera cualquiera de los dos umbrales y tiene mayor pérdida → abre su TF.

      // Recopilar tickets ya emparejados
      ulong paired[];
      int   pairedCount = 0;
      ArrayResize(paired, unwindPairCount);
      for(int k = 0; k < unwindPairCount; k++)
         if(unwindPairs[k].active) paired[pairedCount++] = unwindPairs[k].gridTicket;

      ulong  bestTicket    = 0;
      double worstProfit   = 0.0;
      double bestOpenPrice = 0.0;
      bool   bestIsTimeTrigger = false;

      for(int k = PositionsTotal() - 1; k >= 0; k--)
      {
         if(PositionGetSymbol(k) != _Symbol) continue;
         ulong t = PositionGetTicket(k);
         if(IsPreExisting(t) || IsUnwindPosition(t)) continue;

         bool alreadyPaired = false;
         for(int j = 0; j < pairedCount; j++)
            if(paired[j] == t) { alreadyPaired = true; break; }
         if(alreadyPaired) continue;

         double openPrice   = PositionGetDouble(POSITION_PRICE_OPEN);
         double distFromPos = MathAbs(price - openPrice) / _Point;
         double profit      = PositionGetDouble(POSITION_PROFIT);

         // Elegible por distancia (trigger normal)
         bool distOk = (distFromPos >= (double)NormalModeDistancePoints);

         // [MEJORA-1] Elegible por tiempo (time trigger)
         // Solo si la posición tiene pérdida real (no tiene sentido cubrir una posición ganadora)
         bool timeOk = (NormalModeMaxBarsTrapped > 0 &&
                        barsInCurrentState >= NormalModeMaxBarsTrapped &&
                        profit < -0.5);

         if(!distOk && !timeOk) continue;

         if(profit < worstProfit)
         {
            worstProfit      = profit;
            bestTicket       = t;
            bestOpenPrice    = openPrice;
            bestIsTimeTrigger = !distOk && timeOk;
         }
      }

      if(bestTicket > 0)
      {
         // [MEJORA-3] Si es time trigger, verificar confirmación de tendencia.
         // Si el precio está revirtiendo al centro, no tiene sentido abrir TF ahora —
         // esperar a que el precio confirme que sigue en la dirección incorrecta.
         if(bestIsTimeTrigger && NormalModeConfirmCandles > 0)
         {
            int confirmed = 0;
            for(int c = 1; c <= NormalModeConfirmCandles + 2; c++)
            {
               double o  = iOpen(_Symbol, Timeframe, c);
               double cl = iClose(_Symbol, Timeframe, c);
               if(direction == 1  && cl > o) confirmed++;
               if(direction == -1 && cl < o) confirmed++;
            }
            if(confirmed < NormalModeConfirmCandles)
            {
               if(barsInCurrentState % 12 == 0)
                  Print("UNWIND TIME-TRIGGER: Tendencia no confirmada (",
                        confirmed, "/", NormalModeConfirmCandles,
                        " velas). Esperando confirmación.");
               return;
            }
         }

         string triggerType = bestIsTimeTrigger ? " [TIME-TRIGGER]" : "";
         Print("UNWIND NORMAL", triggerType, ": Abriendo TF | Posición @ ",
               DoubleToString(bestOpenPrice, _Digits),
               " → dist=", DoubleToString(MathAbs(price - bestOpenPrice) / _Point, 0),
               " pts | Barras pausado=", barsInCurrentState,
               " | Pérdida=", DoubleToString(worstProfit, 2),
               " | Dir=", (direction == 1 ? "BUY" : "SELL"));
         OpenUnwindTF(direction);
      }
   }
}

void StopUnwinding(string reason)
{
   if(unwindPairCount == 0) return;

   for(int i = 0; i < unwindPairCount; i++)
   {
      if(!unwindPairs[i].active) continue;

      // Cerrar TF si sigue abierta (fase 1 o fase 2)
      if(PositionSelectByTicket(unwindPairs[i].tfTicket))
      {
         trade.PositionClose(unwindPairs[i].tfTicket);
         Print("UNWINDING DETENIDO (", reason, "): TF #", unwindPairs[i].tfTicket,
               (unwindPairs[i].gridClosed ? " [grid ya cerrado]" : ""), " cerrada.");
      }
      // Cerrar grid solo si aún está abierto (fase 1)
      if(!unwindPairs[i].gridClosed && PositionSelectByTicket(unwindPairs[i].gridTicket))
      {
         trade.PositionClose(unwindPairs[i].gridTicket);
         Print("UNWINDING DETENIDO (", reason, "): Grid #", unwindPairs[i].gridTicket, " cerrado.");
      }
   }
   ArrayResize(unwindPairs, 0);
   unwindPairCount     = 0;
   unwindState         = 0;
   fastTrackActive     = false;
   unwindLastCloseTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//  MÓDULO 6 — GESTIÓN DE CUENTA
//+------------------------------------------------------------------+

void CheckDailyReset()
{
   datetime utcTime = TimeGMT();
   MqlDateTime utcStruct;
   TimeToStruct(utcTime, utcStruct);
   int hourOffset = (utcStruct.mon >= 3 && utcStruct.mon <= 10) ? 2 : 1;

   datetime spanishNow  = utcTime + hourOffset * 3600;
   datetime spanishLast = lastDayReset + hourOffset * 3600;

   MqlDateTime snStruct, slStruct;
   TimeToStruct(spanishNow,  snStruct);
   TimeToStruct(spanishLast, slStruct);

   bool newDay = (snStruct.day  != slStruct.day  ||
                  snStruct.mon  != slStruct.mon  ||
                  snStruct.year != slStruct.year);

   if(newDay)
   {
      dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      lastDayReset      = utcTime;
      realizedLoss      = 0.0;

      if(tradingDisabled)
      {
         tradingDisabled = false;
         isInitialized   = false;
         ArrayInitialize(levelClosedBuy,               false);
         ArrayInitialize(levelClosedSell,              false);
         ArrayInitialize(additionalPositionsOpenedBuy, 0);
         ArrayInitialize(additionalPositionsOpenedSell,0);
         Print("Reset tras pérdida máxima | Balance=", DoubleToString(dailyStartBalance, 2));
      }
      else
         Print("Reset diario | Balance=", DoubleToString(dailyStartBalance, 2));
   }
}

double CalculateTotalDailyLoss()
{
   double floatingPL = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetSymbol(i) == _Symbol)
         floatingPL += PositionGetDouble(POSITION_PROFIT);

   realizedLoss = AccountInfoDouble(ACCOUNT_BALANCE) - dailyStartBalance;
   return realizedLoss + floatingPL;
}

//+------------------------------------------------------------------+
//  MÓDULO 7 — GESTIÓN DE POSICIONES DEL GRID
//+------------------------------------------------------------------+

bool CommentMatchesLevel(string comment, ENUM_POSITION_TYPE type, int level)
{
   string expected = (type == POSITION_TYPE_BUY ? "Buy" : "Sell")
                     + " Level " + IntegerToString(level);
   return (comment == expected);
}

bool PositionExists(ENUM_POSITION_TYPE type, int level)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&
         !IsUnwindPosition(PositionGetTicket(i)) &&
         PositionGetInteger(POSITION_TYPE) == type &&
         CommentMatchesLevel(PositionGetString(POSITION_COMMENT), type, level))
         return true;
   }
   return false;
}

int CountPositionsAtLevel(ENUM_POSITION_TYPE type, int level)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&
         !IsUnwindPosition(PositionGetTicket(i)) &&
         PositionGetInteger(POSITION_TYPE) == type &&
         CommentMatchesLevel(PositionGetString(POSITION_COMMENT), type, level))
         count++;
   }
   return count;
}

void ClosePosition(ENUM_POSITION_TYPE type, int level)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&
         !IsUnwindPosition(PositionGetTicket(i)) &&
         PositionGetInteger(POSITION_TYPE) == type &&
         CommentMatchesLevel(PositionGetString(POSITION_COMMENT), type, level))
         trade.PositionClose(PositionGetTicket(i));
   }
}

double GetLevelProfit(ENUM_POSITION_TYPE type, int level)
{
   double total = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&
         !IsUnwindPosition(PositionGetTicket(i)) &&
         PositionGetInteger(POSITION_TYPE) == type &&
         CommentMatchesLevel(PositionGetString(POSITION_COMMENT), type, level))
         total += PositionGetDouble(POSITION_PROFIT);
   }
   return total;
}

int CountGridPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         !IsPreExisting(PositionGetTicket(i)) &&
         !IsUnwindPosition(PositionGetTicket(i)))  // [FIX-UW-1] TFs ya no se cuentan
      {
         if(StringFind(PositionGetString(POSITION_COMMENT), "Level") >= 0)
            count++;
      }
   }
   return count;
}

void CloseAllGridPositions()
{
   int attempts = 0;
   while(CountGridPositions() > 0 && attempts < 10)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(PositionGetSymbol(i) == _Symbol &&
            !IsPreExisting(PositionGetTicket(i)) &&
            !IsUnwindPosition(PositionGetTicket(i)))
            trade.PositionClose(PositionGetTicket(i));
      }
      Sleep(100);
      attempts++;
   }
}

void CloseAllPositions()
{
   StopUnwinding("Cierre total de posiciones");
   CloseAllGridPositions();
}

double CalcSL(ENUM_POSITION_TYPE type, int level)
{
   if(!UseStopLoss || currentATR <= 0.0) return 0.0;
   double slDist = StopLossATRMultiplier * currentATR;
   if(type == POSITION_TYPE_BUY)
      return NormalizeDouble(gridLevelsBuy[level]  - slDist, _Digits);
   else
      return NormalizeDouble(gridLevelsSell[level] + slDist, _Digits);
}

//+------------------------------------------------------------------+
//  MANAGE BUY / SELL
//+------------------------------------------------------------------+

void ManageBuyPositions(double currentPrice)
{
   if(!botActive || !isInitialized || tradingDisabled) return;
   if(centerQualityScore < CenterMinQualityScore) return;
   if(!GridCanOpen(1)) return;  // [v3.91] Filtro unidireccional + Hurst; [26] Filtro volatilidad

   int highestBuyLevel = -1;
   for(int i = MaxGridLevels - 1; i >= 0; i--)
      if(PositionExists(POSITION_TYPE_BUY, i)) { highestBuyLevel = i; break; }

   for(int i = 0; i < MaxGridLevels; i++)
   {
      if(gridLevelsBuy[i] <= 0.0) continue;
      int posAtLevel = CountPositionsAtLevel(POSITION_TYPE_BUY, i);

      if(gridState == GRID_ACTIVE &&
         lastPrice > gridLevelsBuy[i] && currentPrice <= gridLevelsBuy[i])
      {
         if(posAtLevel >= MaxPositionsPerLevel) continue;
         bool canOpen = (i == MaxGridLevels - 1 || highestBuyLevel == -1 ||
                         highestBuyLevel < i    || highestBuyLevel == i + 1 ||
                         (i < MaxGridLevels - 1 && levelClosedBuy[i+1]));
         if(!canOpen) continue;
         if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) continue;

         double sl = CalcSL(POSITION_TYPE_BUY, i);
         if(trade.Buy(FixedContractSize, _Symbol, 0, sl, 0,
                      "Buy Level " + IntegerToString(i)))
         {
            levelClosedBuy[i] = false;
            additionalPositionsOpenedBuy[i] = 0;
            Print("BUY L", i, " @ ", DoubleToString(currentPrice, _Digits));
         }
         break;
      }

      if(i > 0 && currentPrice >= gridLevelsBuy[i-1] &&
         PositionExists(POSITION_TYPE_BUY, i))
      {
         double lp = GetLevelProfit(POSITION_TYPE_BUY, i);
         if(lp < MinProfitToClose) { break; }

         ClosePosition(POSITION_TYPE_BUY, i);
         Print("BUY CERRADO L", i, " | Balance=",
               DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
         levelClosedBuy[i] = true;

         if(gridState == GRID_ACTIVE)
         {
            int posUpper = CountPositionsAtLevel(POSITION_TYPE_BUY, i-1);
            if(posUpper < MaxPositionsPerLevel &&
               additionalPositionsOpenedBuy[i-1] < MaxPositionsPerLevel - 1)
            {
               if(!LimitGridPositions || CountGridPositions() < MaxGridPositions)
               {
                  double sl2 = CalcSL(POSITION_TYPE_BUY, i-1);
                  if(trade.Buy(FixedContractSize, _Symbol, 0, sl2, 0,
                               "Buy Level " + IntegerToString(i-1)))
                  {
                     levelClosedBuy[i-1] = false;
                     additionalPositionsOpenedBuy[i-1]++;
                  }
               }
            }
         }
         break;
      }

      if(currentPrice >= centralPoint && PositionExists(POSITION_TYPE_BUY, 0))
      {
         if(GetLevelProfit(POSITION_TYPE_BUY, 0) >= MinProfitToClose)
         {
            ClosePosition(POSITION_TYPE_BUY, 0);
            levelClosedBuy[0] = true;
         }
      }
   }
}

void ManageSellPositions(double currentPrice)
{
   if(!botActive || !isInitialized || tradingDisabled) return;
   if(centerQualityScore < CenterMinQualityScore) return;
   if(!GridCanOpen(-1)) return;  // [v3.91] Filtro unidireccional + Hurst; [26] Filtro volatilidad

   int highestSellLevel = -1;
   for(int i = MaxGridLevels - 1; i >= 0; i--)
      if(PositionExists(POSITION_TYPE_SELL, i)) { highestSellLevel = i; break; }

   for(int i = 0; i < MaxGridLevels; i++)
   {
      if(gridLevelsSell[i] <= 0.0) continue;
      int posAtLevel = CountPositionsAtLevel(POSITION_TYPE_SELL, i);

      if(gridState == GRID_ACTIVE &&
         lastPrice < gridLevelsSell[i] && currentPrice >= gridLevelsSell[i])
      {
         if(posAtLevel >= MaxPositionsPerLevel) continue;
         bool canOpen = (i == MaxGridLevels - 1 || highestSellLevel == -1 ||
                         highestSellLevel < i    || highestSellLevel == i + 1 ||
                         (i < MaxGridLevels - 1 && levelClosedSell[i+1]));
         if(!canOpen) continue;
         if(LimitGridPositions && CountGridPositions() >= MaxGridPositions) continue;

         double sl = CalcSL(POSITION_TYPE_SELL, i);
         if(trade.Sell(FixedContractSize, _Symbol, 0, sl, 0,
                       "Sell Level " + IntegerToString(i)))
         {
            levelClosedSell[i] = false;
            additionalPositionsOpenedSell[i] = 0;
            Print("SELL L", i, " @ ", DoubleToString(currentPrice, _Digits));
         }
         break;
      }

      if(i > 0 && currentPrice < gridLevelsSell[i-1] &&
         PositionExists(POSITION_TYPE_SELL, i))
      {
         double lp = GetLevelProfit(POSITION_TYPE_SELL, i);
         if(lp < MinProfitToClose) { break; }

         ClosePosition(POSITION_TYPE_SELL, i);
         Print("SELL CERRADO L", i, " | Balance=",
               DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
         levelClosedSell[i] = true;

         if(gridState == GRID_ACTIVE)
         {
            int posLower = CountPositionsAtLevel(POSITION_TYPE_SELL, i-1);
            if(posLower < MaxPositionsPerLevel &&
               additionalPositionsOpenedSell[i-1] < MaxPositionsPerLevel - 1)
            {
               if(!LimitGridPositions || CountGridPositions() < MaxGridPositions)
               {
                  double sl2 = CalcSL(POSITION_TYPE_SELL, i-1);
                  if(trade.Sell(FixedContractSize, _Symbol, 0, sl2, 0,
                                "Sell Level " + IntegerToString(i-1)))
                  {
                     levelClosedSell[i-1] = false;
                     additionalPositionsOpenedSell[i-1]++;
                  }
               }
            }
         }
         break;
      }

      if(currentPrice <= centralPoint && PositionExists(POSITION_TYPE_SELL, 0))
      {
         if(GetLevelProfit(POSITION_TYPE_SELL, 0) >= MinProfitToClose)
         {
            ClosePosition(POSITION_TYPE_SELL, 0);
            levelClosedSell[0] = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
//  DIBUJAR GRID
//+------------------------------------------------------------------+
void DrawGridLines()
{
   ObjectsDeleteAll(0, "GridLine_");
   ObjectsDeleteAll(0, "GridBand_");

   // ── Niveles del grid ──────────────────────────────────────────────
   for(int i = 0; i < MaxGridLevels; i++)
   {
      if(gridLevelsBuy[i] > 0.0)
      {
         string name = "GridLine_Buy_" + IntegerToString(i);
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, gridLevelsBuy[i]);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrDodgerBlue);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      }
      if(gridLevelsSell[i] > 0.0)
      {
         string name = "GridLine_Sell_" + IntegerToString(i);
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, gridLevelsSell[i]);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrOrangeRed);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      }
   }

   // ── Centro ───────────────────────────────────────────────────────
   ObjectCreate(0, "GridLine_Center", OBJ_HLINE, 0, 0, centralPoint);
   ObjectSetInteger(0, "GridLine_Center", OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, "GridLine_Center", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "GridLine_Center", OBJPROP_STYLE, STYLE_SOLID);

   // ── Bandas GridGuard (pausa / reanudación) ────────────────────────
   if(currentATR > 0.0 && centralPoint > 0.0)
   {
      double pauseRange  = PauseMultiplier  * currentATR;
      double resumeRange = ResumeMultiplier * currentATR;

      // Banda de pausa superior
      ObjectCreate(0, "GridBand_PauseUp", OBJ_HLINE, 0, 0, centralPoint + pauseRange);
      ObjectSetInteger(0, "GridBand_PauseUp", OBJPROP_COLOR, clrCrimson);
      ObjectSetInteger(0, "GridBand_PauseUp", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, "GridBand_PauseUp", OBJPROP_STYLE, STYLE_SOLID);

      // Banda de pausa inferior
      ObjectCreate(0, "GridBand_PauseDown", OBJ_HLINE, 0, 0, centralPoint - pauseRange);
      ObjectSetInteger(0, "GridBand_PauseDown", OBJPROP_COLOR, clrCrimson);
      ObjectSetInteger(0, "GridBand_PauseDown", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, "GridBand_PauseDown", OBJPROP_STYLE, STYLE_SOLID);

      // Banda de reanudación superior
      ObjectCreate(0, "GridBand_ResumeUp", OBJ_HLINE, 0, 0, centralPoint + resumeRange);
      ObjectSetInteger(0, "GridBand_ResumeUp", OBJPROP_COLOR, clrMediumSeaGreen);
      ObjectSetInteger(0, "GridBand_ResumeUp", OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, "GridBand_ResumeUp", OBJPROP_STYLE, STYLE_DASH);

      // Banda de reanudación inferior
      ObjectCreate(0, "GridBand_ResumeDown", OBJ_HLINE, 0, 0, centralPoint - resumeRange);
      ObjectSetInteger(0, "GridBand_ResumeDown", OBJPROP_COLOR, clrMediumSeaGreen);
      ObjectSetInteger(0, "GridBand_ResumeDown", OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, "GridBand_ResumeDown", OBJPROP_STYLE, STYLE_DASH);

      // Color de fondo: verde claro si activo, rojo claro si pausado
      if(gridState == GRID_PAUSED)
         ChartSetInteger(0, CHART_COLOR_BACKGROUND, 0xFFE8E8); // rojo muy suave
      else
         ChartSetInteger(0, CHART_COLOR_BACKGROUND, 0xF0FFF0); // verde muy suave
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//  SAVE / RESTORE
//+------------------------------------------------------------------+
void SaveState()
{
   GlobalVariableSet(StateKey("Active"),            botActive ? 1.0 : 0.0);
   GlobalVariableSet(StateKey("Initialized"),       isInitialized ? 1.0 : 0.0);
   GlobalVariableSet(StateKey("TradingDisabled"),   tradingDisabled ? 1.0 : 0.0);
   GlobalVariableSet(StateKey("CentralPoint"),      centralPoint);
   GlobalVariableSet(StateKey("QualityScore"),      centerQualityScore);
   GlobalVariableSet(StateKey("LastRecalcTime"),    (double)lastRecalcTime);
   GlobalVariableSet(StateKey("RecalcPending"),     recalcPending ? 1.0 : 0.0);
   GlobalVariableSet(StateKey("GridState"),         (double)gridState);
   GlobalVariableSet(StateKey("BarsInState"),       (double)barsInCurrentState);
   GlobalVariableSet(StateKey("UnwindState"),       (double)unwindState);
   GlobalVariableSet(StateKey("UnwindTicket"),      (double)unwindTicket);
   GlobalVariableSet(StateKey("UnwindDir"),         (double)unwindDirection);
   GlobalVariableSet(StateKey("UnwindTrail"),       unwindTrailStop);
   GlobalVariableSet(StateKey("UnwindLastClose"),   (double)unwindLastCloseTime);
   GlobalVariableSet(StateKey("DailyStartBalance"), dailyStartBalance);
   GlobalVariableSet(StateKey("LastDayReset"),      (double)lastDayReset);
   GlobalVariableSet(StateKey("RealizedLoss"),      realizedLoss);
   GlobalVariableSet(StateKey("LastCandleTime"),    (double)lastCandleTime);
   GlobalVariableSet(StateKey("LastPrice"),         lastPrice);
   GlobalVariableSet(StateKey("InitLevelBuy"),      (double)initialLevelBuy);
   GlobalVariableSet(StateKey("InitLevelSell"),     (double)initialLevelSell);
   GlobalVariableSet(StateKey("FIFOLastClose"),     (double)lastFIFOCloseTime); // [26]
   GlobalVariableSet(StateKey("KSPending"),         killSwitchPending ? 1.0 : 0.0);      // [27]
   GlobalVariableSet(StateKey("KSGraceStart"),      (double)killSwitchGraceStart);        // [27]

   for(int i = 0; i < MaxGridLevels; i++)
   {
      GlobalVariableSet(StateKey("GB_")  + IntegerToString(i), gridLevelsBuy[i]);
      GlobalVariableSet(StateKey("GS_")  + IntegerToString(i), gridLevelsSell[i]);
      GlobalVariableSet(StateKey("CLB_") + IntegerToString(i), levelClosedBuy[i]  ? 1.0 : 0.0);
      GlobalVariableSet(StateKey("CLS_") + IntegerToString(i), levelClosedSell[i] ? 1.0 : 0.0);
      GlobalVariableSet(StateKey("APB_") + IntegerToString(i), (double)additionalPositionsOpenedBuy[i]);
      GlobalVariableSet(StateKey("APS_") + IntegerToString(i), (double)additionalPositionsOpenedSell[i]);
   }
}

void RestoreState()
{
   botActive          = GlobalVariableGet(StateKey("Active"))          == 1.0;
   isInitialized      = GlobalVariableGet(StateKey("Initialized"))     == 1.0;
   tradingDisabled    = GlobalVariableGet(StateKey("TradingDisabled")) == 1.0;
   centralPoint       = GlobalVariableGet(StateKey("CentralPoint"));
   centerQualityScore = GlobalVariableGet(StateKey("QualityScore"));
   lastRecalcTime     = (datetime)GlobalVariableGet(StateKey("LastRecalcTime"));
   recalcPending      = GlobalVariableGet(StateKey("RecalcPending"))   == 1.0;
   gridState          = (int)GlobalVariableGet(StateKey("GridState"));
   barsInCurrentState = (int)GlobalVariableGet(StateKey("BarsInState"));
   unwindState        = (int)GlobalVariableGet(StateKey("UnwindState"));
   unwindTicket       = (ulong)GlobalVariableGet(StateKey("UnwindTicket"));
   unwindDirection    = (int)GlobalVariableGet(StateKey("UnwindDir"));
   unwindTrailStop    = GlobalVariableGet(StateKey("UnwindTrail"));
   unwindLastCloseTime= (datetime)GlobalVariableGet(StateKey("UnwindLastClose"));
   dailyStartBalance  = GlobalVariableGet(StateKey("DailyStartBalance"));
   lastDayReset       = (datetime)GlobalVariableGet(StateKey("LastDayReset"));
   realizedLoss       = GlobalVariableGet(StateKey("RealizedLoss"));
   lastCandleTime     = (datetime)GlobalVariableGet(StateKey("LastCandleTime"));
   lastPrice          = GlobalVariableGet(StateKey("LastPrice"));
   initialLevelBuy    = (int)GlobalVariableGet(StateKey("InitLevelBuy"));
   initialLevelSell   = (int)GlobalVariableGet(StateKey("InitLevelSell"));
   lastFIFOCloseTime  = (datetime)GlobalVariableGet(StateKey("FIFOLastClose")); // [26]
   killSwitchPending  = GlobalVariableGet(StateKey("KSPending")) == 1.0;             // [27]
   killSwitchGraceStart = (datetime)GlobalVariableGet(StateKey("KSGraceStart"));     // [27]

   for(int i = 0; i < MaxGridLevels; i++)
   {
      gridLevelsBuy[i]                 = GlobalVariableGet(StateKey("GB_")  + IntegerToString(i));
      gridLevelsSell[i]                = GlobalVariableGet(StateKey("GS_")  + IntegerToString(i));
      levelClosedBuy[i]                = GlobalVariableGet(StateKey("CLB_") + IntegerToString(i)) == 1.0;
      levelClosedSell[i]               = GlobalVariableGet(StateKey("CLS_") + IntegerToString(i)) == 1.0;
      additionalPositionsOpenedBuy[i]  = (int)GlobalVariableGet(StateKey("APB_") + IntegerToString(i));
      additionalPositionsOpenedSell[i] = (int)GlobalVariableGet(StateKey("APS_") + IntegerToString(i));
   }
}

//+------------------------------------------------------------------+
//  OnInit
//+------------------------------------------------------------------+
int OnInit()
{
   ArrayResize(gridLevelsBuy,                MaxGridLevels);
   ArrayResize(gridLevelsSell,               MaxGridLevels);
   ArrayResize(levelClosedBuy,               MaxGridLevels);
   ArrayResize(levelClosedSell,              MaxGridLevels);
   ArrayResize(additionalPositionsOpenedBuy, MaxGridLevels);
   ArrayResize(additionalPositionsOpenedSell,MaxGridLevels);
   ArrayInitialize(gridLevelsBuy,                0.0);
   ArrayInitialize(gridLevelsSell,               0.0);
   ArrayInitialize(levelClosedBuy,               false);
   ArrayInitialize(levelClosedSell,              false);
   ArrayInitialize(additionalPositionsOpenedBuy, 0);
   ArrayInitialize(additionalPositionsOpenedSell,0);

   if(PauseMultiplier <= ResumeMultiplier)
   {
      Print("Error: PauseMultiplier debe ser > ResumeMultiplier");
      return INIT_PARAMETERS_INCORRECT;
   }
   if((UseUnwindFastTrack || UseUnwindNormalMode) && UnwindLotSize < FixedContractSize)
      Print("Aviso: UnwindLotSize < FixedContractSize. El unwinding puede ser lento.");
   if(UnwindFastTrackLossUSD > 0.0 && UnwindFastTrackLossUSD >= MaxDailyLoss)
      Print("Aviso: UnwindFastTrackLossUSD >= MaxDailyLoss. El fast-track nunca se activará antes del kill switch.");
   if(UseFIFOTimeLimit && FIFOMaxDaysOpen <= 0)
      Print("Aviso: FIFOMaxDaysOpen <= 0 con UseFIFOTimeLimit=true. El FIFO no hará nada.");
   if(UseVolatilityFilter && VolatilityRefPeriod < 5)
      Print("Aviso: VolatilityRefPeriod muy bajo — la referencia de ATR puede ser inestable.");
   if(UnwindGraceBars <= 0)
      Print("Aviso: UnwindGraceBars <= 0 → comportamiento idéntico a v26 (kill switch inmediato, sin margen para coberturas).");

   effectiveMaxDailyLoss = (SafetyBeltFactor > 0.0 && SafetyBeltFactor <= 1.0)
                           ? MaxDailyLoss * SafetyBeltFactor
                           : MaxDailyLoss * 0.95;

   atrHandle = iATR(_Symbol, Timeframe, AtrPeriod);
   if(atrHandle == INVALID_HANDLE)
   {
      Print("Error handle ATR: ", GetLastError());
      return INIT_FAILED;
   }

   CapturePreExistingPositions();

   if(GlobalVariableCheck(StateKey("Initialized")))
   {
      RestoreState();
      Print("Estado restaurado | Centro=", DoubleToString(centralPoint, _Digits),
            " | Score=", DoubleToString(centerQualityScore, 2),
            " | Unwinding=", unwindState);
   }
   else
   {
      GlobalVariablesDeleteAll("BotState_" + _Symbol + "_");
      dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      lastDayReset      = TimeCurrent();
      lastCandleTime    = iTime(_Symbol, Timeframe, 0);

      double atrBuf[];
      ArraySetAsSeries(atrBuf, true);
      if(CopyBuffer(atrHandle, 0, 0, 1, atrBuf) > 0)
         currentATR = atrBuf[0];

      double qs = 0.0;
      double cp = CalculateCenterFromHistogram(qs);
      if(cp <= 0.0)
      {
         cp = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         qs = 0.0;
         Print("Fallback: usando precio actual como centro.");
      }
      centralPoint       = cp;
      centerQualityScore = qs;
      lastRecalcTime     = TimeCurrent();

      BuildGrid();
      Print("Bot iniciado | Centro=", DoubleToString(centralPoint, _Digits),
            " | Score=", DoubleToString(centerQualityScore, 2),
            " | Unwinding=", (UseUnwindFastTrack || UseUnwindNormalMode ? "ON" : "OFF"),
            " | FIFO=", (UseFIFOTimeLimit ? IntegerToString(FIFOMaxDaysOpen) + "d/" + IntegerToString(FIFOCloseIntervalDays) + "d" : "OFF"),
            " | FiltroVol=", (UseVolatilityFilter ? DoubleToString(VolatilityATRMultiple,1) + "x" : "OFF"),
            " | GraciaKillSwitch=", (UnwindGraceBars > 0 ? IntegerToString(UnwindGraceBars) + " barras" : "OFF"),
            " | FastTrack=", (UnwindFastTrackLossUSD > 0 ?
               DoubleToString(UnwindFastTrackLossUSD, 0) + " USD → batch inmediato" : "OFF"));

      // Intentar dibujar el grid inmediatamente aunque BuildGrid haya fallado por ATR
      // Calculamos ATR directamente desde el buffer si el handle ya tiene datos
      if(currentATR <= 0.0 && atrHandle != INVALID_HANDLE)
      {
         double atrBuf[];
         ArraySetAsSeries(atrBuf, true);
         if(CopyBuffer(atrHandle, 0, 0, 3, atrBuf) > 0)
            currentATR = atrBuf[0];
      }
      // Si aún no hay ATR, usar estimación basada en precio actual
      if(currentATR <= 0.0)
         currentATR = SymbolInfoDouble(_Symbol, SYMBOL_BID) * 0.002; // ~0.2% precio

      if(centralPoint > 0.0)
      {
         BuildGrid(); // Reintentar ahora que puede haber ATR
         DrawGridLines();
      }
   }

   lastStateSave = TimeCurrent();
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//  OnDeinit
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(reason != REASON_CHARTCLOSE && reason != REASON_REMOVE)
      SaveState();
   else
      GlobalVariablesDeleteAll("BotState_" + _Symbol + "_");

   ObjectsDeleteAll(0, "GridLine_");
   ObjectsDeleteAll(0, "GridBand_");
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, 0xFFFFFF);
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);

   Print("Bot detenido. Unwound total: ", DoubleToString(totalUnwoundLoss, 2), " USD");
}

//+------------------------------------------------------------------+
//  OnTick
//+------------------------------------------------------------------+
void OnTick()
{
   if(!botActive) return;

   double price   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);

   datetime barTime = iTime(_Symbol, Timeframe, 0);
   bool isNewBar    = (barTime != lastCandleTime);

   if(isNewBar)
   {
      lastCandleTime = barTime;

      double atrBuf[];
      ArraySetAsSeries(atrBuf, true);
      if(CopyBuffer(atrHandle, 0, 0, 1, atrBuf) > 0)
         currentATR = atrBuf[0];

      // [v3.91] Actualizar Hurst cada barra nueva
      if(UseHurstFilter)
         currentHurst = CalculateHurst(HurstPeriod);

      // [26] Actualizar el flag de volatilidad extrema una vez por barra
      volatilityBlocked = UseVolatilityFilter ? IsVolatilityExtreme() : false;

      UpdateGridGuard();
      ManageUnwinding();
      CheckManualAlert();

      // [26] FIFO: comprobar cada barra si toca cerrar la posición más antigua
      // Se ejecuta independientemente del gridState — el objetivo es liberar
      // cupo cuanto antes, esté el grid activo o pausado.
      CheckFIFOTimeLimit();

      // Redibujar líneas del grid en cada barra nueva (fix para live trading)
      if(isInitialized && centralPoint > 0.0)
         DrawGridLines();

      // Trailing stop de TFs: se ejecuta SIEMPRE que haya pares activos,
      // independientemente de si el grid está activo o pausado.
      // Cubre fase 1 (grid abierto) y fase 2 (TF corriendo libre).
      if(unwindPairCount > 0)
         UpdateAllUnwindTrailingStops();

      if(ShouldRecalculate() || recalcPending)
         TryRecalculateCenter();
   }

   if(TimeCurrent() - lastStateSave >= 3600)
   {
      SaveState();
      lastStateSave = TimeCurrent();
   }

   if(UseBalanceTarget && balance >= BalanceTarget && equity >= BalanceTarget)
   {
      CloseAllPositions();
      botActive = false;
      Print("OBJETIVO ALCANZADO | Balance=", DoubleToString(balance, 2));
      return;
   }
   if(equity < MinOperatingBalance)
   {
      CloseAllPositions();
      botActive = false;
      Print("EQUITY MÍNIMO | Equity=", DoubleToString(equity, 2));
      return;
   }
   CheckDailyReset();

   bool dailyLossBreached = (CalculateTotalDailyLoss() <= -effectiveMaxDailyLoss);

   if(dailyLossBreached)
   {
      // [27] ¿Hay pares de cobertura en FASE 1 (cobertura abierta, grid aún sin cerrar)?
      // Si es así, merecen un margen de reacción antes de liquidarlos sin darles ninguna oportunidad.
      bool hasPhase1Pairs = false;
      for(int i = 0; i < unwindPairCount; i++)
         if(unwindPairs[i].active && !unwindPairs[i].gridClosed) { hasPhase1Pairs = true; break; }

      bool graceActive = false;

      if(hasPhase1Pairs && UnwindGraceBars > 0)
      {
         if(!killSwitchPending)
         {
            killSwitchPending    = true;
            killSwitchGraceStart = TimeCurrent();
            Print("[27] PÉRDIDA DIARIA con coberturas en fase 1 activas → concediendo ",
                  UnwindGraceBars, " barras de margen antes de liquidar | Balance=",
                  DoubleToString(balance, 2));
         }

         int barsSinceTrigger = (int)((TimeCurrent() - killSwitchGraceStart) / PeriodSeconds(Timeframe));
         graceActive = (barsSinceTrigger < UnwindGraceBars);
      }

      if(!graceActive)
      {
         // Se acabó el margen (o no había coberturas que lo justifiquen): liquidar como en v26.
         CloseAllPositions();
         tradingDisabled   = true;
         killSwitchPending = false;
         Print("PÉRDIDA DIARIA | Balance=", DoubleToString(balance, 2));
         return;
      }
      // graceActive == true: NO liquidamos. El resto de OnTick sigue con normalidad
      // para que ManageUnwindPairs/trailing puedan seguir gestionando la cascada.
   }
   else if(killSwitchPending)
   {
      // La pérdida se despejó dentro del plazo de gracia: las coberturas hicieron su trabajo a tiempo.
      killSwitchPending = false;
      Print("[27] PÉRDIDA DIARIA despejada dentro del periodo de gracia — coberturas compensaron a tiempo.");
   }

   if(tradingDisabled) return;

   if(unwindPairCount > 0)
      ManageUnwindPairs();

   if(!isInitialized)
   {
      initialLevelBuy = initialLevelSell = -1;
      for(int i = 0; i < MaxGridLevels; i++)
      {
         if(gridLevelsBuy[i]  > 0.0 && price <= gridLevelsBuy[i])
            { initialLevelBuy  = i; break; }
         if(gridLevelsSell[i] > 0.0 && price >= gridLevelsSell[i])
            { initialLevelSell = i; break; }
      }
      isInitialized = true;
      lastPrice     = price;
      Print("Grid inicializado | BuyL=", initialLevelBuy,
            " SellL=", initialLevelSell,
            " Centro=", DoubleToString(centralPoint, _Digits),
            " Estado=", (gridState == GRID_ACTIVE ? "ACTIVO" : "PAUSADO"));
      return;
   }

   ManageBuyPositions(price);
   ManageSellPositions(price);

   if(MathAbs(price - centralPoint) <= _Point * 2)
   {
      bool allOk = true;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(PositionGetSymbol(i) == _Symbol &&
            !IsPreExisting(PositionGetTicket(i)) &&
            !IsUnwindPosition(PositionGetTicket(i)))
            if(PositionGetDouble(POSITION_PROFIT) < MinProfitToClose)
               { allOk = false; break; }
      }
      if(allOk && CountGridPositions() > 0)
      {
         CloseAllGridPositions();
         ArrayInitialize(levelClosedBuy,               false);
         ArrayInitialize(levelClosedSell,              false);
         ArrayInitialize(additionalPositionsOpenedBuy, 0);
         ArrayInitialize(additionalPositionsOpenedSell,0);
         isInitialized = false;
         Print("CIERRE TOTAL centralPoint | Balance=",
               DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
      }
   }

   if(recalcPending && !HasOpenGridPositions() && unwindPairCount == 0)
      TryRecalculateCenter();

   lastPrice = price;
}