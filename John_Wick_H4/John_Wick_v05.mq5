//+------------------------------------------------------------------+
//|                                              John Wick H4 v3.mq5 |
//|                                             Jose Antonio Montero |
//|                        https://www.linkedin.com/in/joseamontero/ |
//+------------------------------------------------------------------+
#property copyright "Jose Antonio Montero"
#property link      "https://www.linkedin.com/in/joseamontero/"
#property version   "3.20"
//
// CHANGELOG v3.10 -> v3.20
// - El antiguo aviso unico PuntosAlertaAdversa (750) se sustituye por un sistema de 4 niveles,
//   pensado para uso en real con coberturas automaticas desactivadas (TipoCobertura=NINGUNA) y
//   gestion 100% manual:
//     Nivel 1 "Vigilar"  (AlertaVigilarPoints,  750 por defecto): SOLO registro en el log, SIN
//              popup ni push -- la mayoria de operaciones que llegan aqui acaban bien solas.
//     Nivel 2 "Revisar"  (AlertaRevisarPoints, 1200 por defecto): aviso real. Mirar regimen de
//              mercado y cuantas posiciones hay abiertas en la misma direccion.
//     Nivel 3 "Decidir"  (AlertaDecidirPoints, 2500 por defecto): aviso prioritario. Decidir ya:
//              cobertura manual, reducir exposicion, o esperar conscientemente.
//     Nivel 4 "Linea roja" (reutiliza PuntosCobertura, 3500 por defecto): si TipoCobertura=NINGUNA,
//              se lanza el aviso maximo en vez de abrir cobertura automatica.
//   El panel en pantalla muestra el nivel mas alto alcanzado por cada posicion.
// - Motivo: en backtest sobre 2020-2026 encontramos que, en los movimientos mas violentos
//   (marzo 2020), una posicion puede recorrer los 3500 puntos de "linea roja" en solo 3-6 dias,
//   con varias posiciones enganchandose casi a la vez -- un solo aviso a los 750 no distingue
//   "ruido normal" (la mayoria de casos) de "esto se esta poniendo serio de verdad".
//
// CHANGELOG v3.00 -> v3.10
// - Parametros de cobertura preestablecidos con los valores encontrados en el optimizador
//   (Pass 34, AUDCAD H4 2025.01-2026.10, PF 1.88, DD equity 24.98%): TipoCobertura pasa de
//   NINGUNA a CONTRARIA, PuntosCobertura de 750 a 3500. MultiplicadorCobertura se mantiene en 4.0
//   (no se ha optimizado todavia de forma independiente -- pendiente).
//   AVISO: en el barrido del optimizador, el resultado a 3500 esta rodeado de vecinos malos
//   (3250=bueno, 3500=bueno, 3750=muy malo) -- es un pico aislado, no una zona estable. Antes de
//   llevar esto a cuenta real hay que validar con walk-forward / distintos periodos.
// - Nuevo: al cerrar un par enganchada+cobertura con el neto combinado en beneficio, YA NO se
//   cierran ambas automaticamente. Si UseATRTrailingCobertura=true (por defecto), se cierra SOLO
//   la pata perdedora, se protege la pata ganadora a breakeven (SL = su propio precio de apertura)
//   y se deja correr con un trailing stop basado en ATR (ver grupo "Trailing ATR para
//   supervivientes de cobertura"). Si UseATRTrailingCobertura=false, se mantiene el
//   comportamiento v3.00 (cerrar ambas de inmediato).
// - Motivo del cambio de comportamiento del trailing: un trailing en puntos fijos no distingue
//   regimen de volatilidad; uno basado en ATR(H4) se adapta a si el mercado esta tranquilo o
//   revuelto en el momento en que la cobertura queda "liberada".
//
// CHANGELOG v2.00 -> v3.00
// - Nuevo sistema de salida en 3 fases (ver "Nuevo Sistema de Salida" mas abajo):
//     Fase 0: espera banda central. Si llega con beneficio neto (profit+swap+comision) > 0, cierra.
//             Si llega sin beneficio, NO cierra: pasa a Fase 1 y genera aviso de accion manual.
//     Fase 1: espera el extremo OPUESTO de Bollinger. Si llega con beneficio, cierra.
//             Si llega sin beneficio, NO cierra: genera un segundo aviso y, si
//             CierreConBeneficioMinimo=true, pasa a Fase 2.
//     Fase 2: monitoriza cada tick hasta que el beneficio neto cubra swap+comision+minimo
//             (ver CalculateMinProfitTarget), momento en el que cierra.
// - SinStops=true (por defecto): las operaciones se abren SIN Stop Loss. En su lugar, se usa el
//   sistema de avisos escalonados (ver CHANGELOG v3.10 -> v3.20 mas arriba; no se cierra nada).
// - MagicNumber: todas las aperturas, cierres y conteos de posiciones del bot filtran por
//   este numero. Las posiciones manuales (magic=0) y las de otros bots (otro magic) NO cuentan
//   para MaxPositions, NO se incluyen en el calculo de perdida diaria, y NUNCA se tocan desde
//   CloseAllPositions ni desde el resto del EA.
// - Panel en pantalla (Comment()) con el estado de cada posicion y los avisos pendientes.
// - MinOperatingBalance pasa a valor fijo 1.0 (decision explicita: ya no se corrige a
//   30-40% del capital).
// - Logging de MAE (Maxima Excursion Adversa en puntos): cada posicion registra en una variable
//   global el maximo que ha llegado a moverse en contra, y ese valor se imprime en el log al
//   cerrarse (cualquiera que sea el motivo del cierre). Objetivo: analizar, operacion a
//   operacion, hasta cuantos puntos llegan las que SI revierten frente a las que no, antes de
//   fijar con datos (no a ojo) el umbral de una futura cobertura automatica.
// - Cobertura automatica opcional (TipoCobertura): NINGUNA / CONTRARIA (hedge clasico, direccion
//   opuesta) / MARTINGALA (misma direccion), ambas con volumen = volumen de la posicion enganchada
//   x MultiplicadorCobertura. Se dispara al superar PuntosCobertura en contra. La posicion
//   enganchada y su cobertura se cierran SIEMPRE juntas, en el momento en que el neto combinado
//   (profit+swap+comision de ambas) cubra MinProfitCobertura por cada MinLotSize de volumen
//   conjunto. Pensado para optimizar TipoCobertura x PuntosCobertura x MultiplicadorCobertura en
//   el optimizador del Strategy Tester y comparar resultados con datos, no a ojo.
//
// LIMITACIONES Y SUPUESTOS CONOCIDOS (leer antes de operar en real):
// 1) MQL5 no expone la comision de una posicion ABIERTA via PositionGetDouble: la comision solo
//    viaja en los deals. Este EA lee la comision del deal de ENTRADA una sola vez, al abrir la
//    posicion (CacheEntryCommission), y asume que la comision de SALIDA sera igual (cuenta Raw
//    Spread, tarifa simetrica por lote en apertura y cierre) -- por eso el neto usa
//    entry_commission*2. Si algun dia cambias a una cuenta con tarifa de comision distinta entre
//    apertura y cierre, esta suposicion dejaria de ser correcta y habria que volver a leer la
//    comision real de salida tras el cierre.
// 2) El Strategy Tester NO simula intervencion manual: los avisos se registran y se notifican,
//    pero nadie actua sobre ellos en un backtest. Un backtest de esta version mide el escenario
//    "nunca reacciono a ningun aviso", no el comportamiento real con cobertura manual.
// 3) CalculateMinProfitTarget usa MinProfitPerBaseLot como propuesta de escalado (ver input);
//    revisar si el valor por defecto (0.50) es el que se quiere usar antes de simular.
//
//+------------------------------------------------------------------+

//--- Include the trading library
#include <Trade\Trade.mqh>

//--- Tipos de cobertura para posiciones enganchadas (ver grupo de inputs correspondiente)
enum ENUM_TIPO_COBERTURA
{
   COBERTURA_NINGUNA    = 0, // Desactivada
   COBERTURA_CONTRARIA  = 1, // Dirección opuesta a la posición enganchada (hedge clásico)
   COBERTURA_MARTINGALA = 2  // Misma dirección que la posición enganchada (promediar)
};

//--- Input Parameters
input group "Identificación"
input long MagicNumber = 20261011;      // Identificador único de este bot (para convivir con otros EAs y operaciones manuales)

input group "Configuración Indicador (Bandas de Bollinger)"
input int BB_Period = 49;               // Periodo de las Bandas de Bollinger
input double BB_Deviation = 1.1;        // Desviación de las Bandas de Bollinger

input group "Gestión de Riesgo"
input double LotSize = 0.01;            // Tamaño de lote inicial (usado si UseAutoScaling=false)
input double MaxContractSize = 2.0;     // Tamaño máximo del contrato

input group "Escalado Automático de Lote"
input bool UseAutoScaling = true;           // Activar escalado automático de lote por equity
input double MinLotSize = 0.01;             // Lote mínimo / lote en el escalón base (también unidad de referencia para el beneficio mínimo)
input double ScalingBaseEquity = 300.0;     // Equity a partir de la cual aplica MinLotSize
input double ScalingEquityStep = 300.0;     // Incremento de equity por cada escalón de lote
input double ScalingLotStep = 0.01;         // Incremento de lote por escalón

input group "Nuevo Sistema de Salida"
input bool SinStops = true;                 // Quitar Stop Loss fijo (true = sin SL; gestión por avisos)
input int SL_Points = 1150;                 // Stop Loss en puntos (solo se usa si SinStops=false)
input bool CierreConBeneficioMinimo = true; // Si llega al extremo opuesto sin beneficio, cerrar al cubrir coste + beneficio mínimo
input double MinProfitPerBaseLot = 0.50;    // USD de beneficio mínimo objetivo por cada MinLotSize de volumen (propuesta, revisar antes de simular)
input bool EnviarNotificacionesPush = true; // Enviar también SendNotification() (push MT5) además de Alert()
input bool MostrarPanel = true;             // Mostrar panel en pantalla (Comment()). Ponlo a false en el Strategy Tester para aligerar la simulación

input bool UseTrailingStop = false;     // Activar/desactivar Trailing Stop (solo aplica si SinStops=false)
input int TrailingStopActivation = 150; // Puntos de beneficio para activar trailing stop
input int TrailingStopStep = 180;       // Paso en puntos para ajustar el trailing stop

input group "Avisos de intervención manual (escalonados, solo si SinStops=true)"
input int AlertaVigilarPoints = 750;    // Nivel 1 "Vigilar": solo registro en el log, SIN popup/push. La mayoría de operaciones que llegan aquí acaban bien.
input int AlertaRevisarPoints = 1200;   // Nivel 2 "Revisar": aviso (popup + push). Mirar régimen de mercado y nº de posiciones en la misma dirección.
input int AlertaDecidirPoints = 2500;   // Nivel 3 "Decidir": aviso prioritario. Decidir ya: cobertura manual, reducir exposición, o esperar.
// Nivel 4 "Línea roja" reutiliza PuntosCobertura (grupo de cobertura, más abajo): si se alcanza y TipoCobertura=NINGUNA
// (uso previsto en real), se lanza un aviso máximo en vez de abrir cobertura automática.

input group "Cobertura de posiciones enganchadas (opcional, para optimizar)"
input ENUM_TIPO_COBERTURA TipoCobertura = COBERTURA_CONTRARIA; // Ninguna / Dirección contraria / Martingala (misma dirección) -- preestablecido: Pass 34 del optimizador
input int PuntosCobertura = 3500;           // Puntos en contra para abrir la cobertura -- preestablecido: Pass 34 del optimizador
input double MultiplicadorCobertura = 4.0;  // Tamaño de la cobertura = volumen de la posición enganchada x este multiplicador
input double MinProfitCobertura = 0.50;     // USD mínimo (por cada MinLotSize de volumen combinado) para liberar/cerrar el par enganchada+cobertura

input group "Trailing ATR para supervivientes de cobertura"
input bool UseATRTrailingCobertura = true;      // Al liberar el par (neto combinado en beneficio): cerrar solo la perdedora y dejar correr la ganadora con trailing ATR. Si false: cerrar ambas (comportamiento v3.00)
input int ATR_PeriodCobertura = 14;             // Periodo del indicador ATR (en H4) usado para el trailing de la pata superviviente
input double ATR_MultiplicadorCobertura = 2.5;  // Distancia del trailing = ATR(H4) x este multiplicador

input group "Configuración Operaciones"
input int MaxPositions = 4;             // Máximo número de posiciones (propias, por MagicNumber) abiertas por dirección
input int CandleSeparation = 2;         // Separación mínima en velas entre operaciones en la misma dirección
input bool UseBreakoutDistance = true;  // Activar/desactivar apertura por rotura en la misma vela
input int BreakoutDistancePoints = 150; // Distancia en puntos gráficos para rotura en la misma vela

input group "Gestión de Cuenta (FTMO y Similares)"
input double MaxDailyLossFTMO = 500.0;  // Pérdida diaria máxima permitida (USD) — solo posiciones propias
input double SafetyBeltFactor = 0.8;    // Factor de cinturón de seguridad (0.0 a 1.0)
input double MinOperatingBalance = 1.0; // Saldo mínimo operativo (USD) — fijo, decisión explícita
input bool UseBalanceTarget = false;    // Activar/desactivar objetivo de saldo
input double BalanceTarget = 11000.0;   // Saldo objetivo para cerrar el bot (USD)

//--- Global Variables
int bb_handle;                          // Handle para Bandas de Bollinger
int atr_cobertura_handle;               // Handle para ATR (trailing de supervivientes de cobertura)
double bb_upper[], bb_lower[], bb_mid[]; // Buffers para Bandas de Bollinger
datetime last_bar;                       // Control de nueva vela
datetime last_buy_time;                 // Hora de la última compra abierta
datetime last_sell_time;                // Hora de la última venta abierta
bool trading_disabled = false;          // Indica si el trading está deshabilitado por pérdida diaria
double daily_start_balance;             // Balance al inicio del día
datetime last_day_reset;                // Último reseteo diario
double realized_loss = 0.0;             // Pérdida realizada del día
double effective_max_daily_loss;        // Límite de pérdida diaria con cinturón de seguridad
int trailing_stop_step;                 // Variable global para el paso del trailing stop
double base_lot_size;                   // Lote base vigente (fijo, o calculado por escalado automático)

string gv_prefix;                       // Prefijo de las variables globales de terminal de este bot (incluye MagicNumber)

//+------------------------------------------------------------------+
//| Prefijo único de variables globales para esta instancia del EA    |
//+------------------------------------------------------------------+
string GVPrefix()
{
   return "JW_" + IntegerToString(MagicNumber) + "_" + _Symbol + "_";
}

double GVGetOrZero(string name)
{
   if(GlobalVariableCheck(name))
      return GlobalVariableGet(name);
   return 0.0;
}

//+------------------------------------------------------------------+
//| Normalizar el tamaño del lote según las especificaciones del bróker |
//+------------------------------------------------------------------+
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
//| Calcular el lote base según el escalado automático                |
//+------------------------------------------------------------------+
double CalculateScaledLot(double equity_or_balance)
{
   if(!UseAutoScaling)
      return NormalizeLotSize(LotSize);

   if(equity_or_balance < ScalingBaseEquity)
      return NormalizeLotSize(MinLotSize);

   int steps = (int)MathFloor((equity_or_balance - ScalingBaseEquity) / ScalingEquityStep);
   double lot = MinLotSize + steps * ScalingLotStep;
   lot = MathMin(lot, MaxContractSize);
   return NormalizeLotSize(lot);
}

//+------------------------------------------------------------------+
//| Revisar y aplicar el escalado de lote                             |
//+------------------------------------------------------------------+
void CheckAutoScaling(bool force_init = false)
{
   if(force_init)
   {
      base_lot_size = CalculateScaledLot(AccountInfoDouble(ACCOUNT_BALANCE));
      Print("📊 ESCALADO INICIAL: Balance = $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
            " | UseAutoScaling = ", UseAutoScaling, " | Lote base = ", DoubleToString(base_lot_size, 2));
      return;
   }

   if(!UseAutoScaling)
      return;

   double new_base = CalculateScaledLot(AccountInfoDouble(ACCOUNT_BALANCE));

   if(MathAbs(new_base - base_lot_size) > 0.0000001)
   {
      Print("📊 ESCALADO: Balance = $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
            " | Lote base anterior = ", DoubleToString(base_lot_size, 2),
            " | Lote base nuevo = ", DoubleToString(new_base, 2));
      base_lot_size = new_base;
   }
}

//+------------------------------------------------------------------+
//| Beneficio mínimo objetivo, escalado por tamaño de posición         |
//+------------------------------------------------------------------+
double CalculateMinProfitTargetCustom(double position_lot, double usd_per_base_lot)
{
   double unit = (MinLotSize > 0) ? MinLotSize : 0.01;
   double lot_units = position_lot / unit;
   if(lot_units < 1.0) lot_units = 1.0;
   return usd_per_base_lot * lot_units;
}

double CalculateMinProfitTarget(double position_lot)
{
   return CalculateMinProfitTargetCustom(position_lot, MinProfitPerBaseLot);
}

//+------------------------------------------------------------------+
//| Guardar la comisión de ENTRADA de una posición recién abierta, una |
//| sola vez (no se vuelve a consultar el historial en cada tick).     |
//| Se asume comisión de salida = comisión de entrada (cuenta Raw      |
//| Spread, comisión simétrica por lote en apertura y cierre).         |
//+------------------------------------------------------------------+
void CacheEntryCommission(ulong position_ticket, ulong deal_ticket)
{
   double commission = 0.0;
   if(HistoryDealSelect(deal_ticket))
      commission = HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
   GlobalVariableSet(GVPrefix() + IntegerToString(position_ticket) + "_EntryCommission", commission);
}

//+------------------------------------------------------------------+
//| Beneficio neto de una posición abierta: profit + swap +            |
//| comisión de entrada*2 (entrada + salida estimada, simétrica)       |
//+------------------------------------------------------------------+
double GetNetResult(ulong ticket)
{
   double profit = PositionGetDouble(POSITION_PROFIT);
   double swap = PositionGetDouble(POSITION_SWAP);
   double entry_commission = GVGetOrZero(GVPrefix() + IntegerToString(ticket) + "_EntryCommission");
   double round_trip_commission = entry_commission * 2.0; // entrada + salida (misma tarifa)
   return profit + swap + round_trip_commission;
}

//+------------------------------------------------------------------+
//| Generar un aviso de acción manual (popup + log + push opcional)    |
//+------------------------------------------------------------------+
void RaiseManualAlert(string message)
{
   Print("⚠️ AVISO ACCIÓN MANUAL: ", message);
   Alert(message);
   if(EnviarNotificacionesPush)
      SendNotification(message);
}

//+------------------------------------------------------------------+
//| Limpiar el estado (variables globales) de un ticket cerrado        |
//+------------------------------------------------------------------+
void CleanupTicketState(ulong ticket)
{
   string base = GVPrefix() + IntegerToString(ticket) + "_";
   GlobalVariableDel(base + "Phase");
   GlobalVariableDel(base + "AlertCenter");
   GlobalVariableDel(base + "AlertOpposite");
   GlobalVariableDel(base + "AlertAdverse");
   GlobalVariableDel(base + "AlertRevisar");
   GlobalVariableDel(base + "AlertDecidir");
   GlobalVariableDel(base + "AlertLineaRoja");
   GlobalVariableDel(base + "EntryCommission");
   GlobalVariableDel(base + "MaxAdverse");
   GlobalVariableDel(base + "HedgeOpened");
   GlobalVariableDel(base + "HedgeTicket");
   GlobalVariableDel(base + "HedgePair");
   GlobalVariableDel(base + "CoberturaSurvivor");
}

//+------------------------------------------------------------------+
//| Limpieza periódica de variables globales huérfanas (posiciones     |
//| que ya no existen, p.ej. cerradas por el bróker o manualmente)     |
//+------------------------------------------------------------------+
void CleanupOrphanGlobals()
{
   string prefix = GVPrefix();
   int total = GlobalVariablesTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      string name = GlobalVariableName(i);
      if(StringFind(name, prefix) != 0)
         continue;

      // Extraer el ticket del nombre: prefix + ticket + "_" + campo
      string rest = StringSubstr(name, StringLen(prefix));
      int sep = StringFind(rest, "_");
      if(sep <= 0)
         continue;
      string ticket_str = StringSubstr(rest, 0, sep);
      ulong ticket = (ulong)StringToInteger(ticket_str);
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         GlobalVariableDel(name);
   }
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

   atr_cobertura_handle = iATR(_Symbol, PERIOD_H4, ATR_PeriodCobertura);
   if(atr_cobertura_handle == INVALID_HANDLE)
   {
      Print("🚨 ERROR: No se pudo crear el indicador ATR (trailing de coberturas)");
      return(INIT_FAILED);
   }

   ArraySetAsSeries(bb_upper, true);
   ArraySetAsSeries(bb_lower, true);
   ArraySetAsSeries(bb_mid, true);

   last_buy_time = 0;
   last_sell_time = 0;

   CheckAutoScaling(true);

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

   Print("🔖 MagicNumber activo: ", MagicNumber, " | SinStops: ", SinStops,
         " | CierreConBeneficioMinimo: ", CierreConBeneficioMinimo);

   CleanupOrphanGlobals();

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(bb_handle != INVALID_HANDLE) IndicatorRelease(bb_handle);
   if(atr_cobertura_handle != INVALID_HANDLE) IndicatorRelease(atr_cobertura_handle);
   Comment("");
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
      UpdatePanel();
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
   ManageCoberturas();
   ManageCoberturaSurvivorTrailing();
   UpdatePanel();
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
            HistoryDealGetInteger(trans.deal, DEAL_MAGIC) == MagicNumber &&
            HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
            CheckAutoScaling(); // balance ya refleja este cierre
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
//| Contar posiciones PROPIAS (este MagicNumber) abiertas por tipo    |
//| Las operaciones manuales, las de otros bots, y las coberturas      |
//| (comentario "HEDGE_...") NO cuentan para el límite de la grid.     |
//+------------------------------------------------------------------+
int CountOpenPositions(ENUM_POSITION_TYPE type)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         StringFind(PositionGetString(POSITION_COMMENT), "HEDGE_") != 0)
      {
         if(PositionGetInteger(POSITION_TYPE) == type)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Abrir la cobertura de una posición enganchada (una sola vez por    |
//| posición -- se marca con HedgeOpened para no repetir).             |
//+------------------------------------------------------------------+
void OpenCobertura(ulong stuck_ticket, ENUM_POSITION_TYPE stuck_type, double stuck_volume)
{
   ENUM_POSITION_TYPE hedge_type;
   if(TipoCobertura == COBERTURA_CONTRARIA)
      hedge_type = (stuck_type == POSITION_TYPE_BUY) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   else // COBERTURA_MARTINGALA
      hedge_type = stuck_type;

   double hedge_lot = NormalizeLotSize(MathMin(stuck_volume * MultiplicadorCobertura, MaxContractSize));
   if(hedge_lot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) ||
      hedge_lot > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX))
   {
      Print("🚨 ERROR: Volumen de cobertura inválido (", DoubleToString(hedge_lot, 2), ") para posición #", stuck_ticket);
      return;
   }

   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   string comment = "HEDGE_" + IntegerToString(stuck_ticket);
   bool opened = false;
   ulong hedge_ticket = 0;

   if(hedge_type == POSITION_TYPE_BUY)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      opened = trade.Buy(hedge_lot, _Symbol, bid, 0.0, 0.0, comment);
   }
   else
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      opened = trade.Sell(hedge_lot, _Symbol, ask, 0.0, 0.0, comment);
   }

   if(opened)
   {
      hedge_ticket = trade.ResultOrder();
      CacheEntryCommission(hedge_ticket, trade.ResultDeal());
      string prefix = GVPrefix();
      GlobalVariableSet(prefix + IntegerToString(stuck_ticket) + "_HedgeOpened", 1);
      GlobalVariableSet(prefix + IntegerToString(stuck_ticket) + "_HedgeTicket", (double)hedge_ticket);
      GlobalVariableSet(prefix + IntegerToString(hedge_ticket) + "_HedgePair", (double)stuck_ticket);
      Print("🛡️ COBERTURA ABIERTA: #", hedge_ticket, " (", (hedge_type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " ", DoubleToString(hedge_lot, 2), ") para posición enganchada #", stuck_ticket,
            " | Tipo: ", EnumToString(TipoCobertura));
   }
   else
   {
      Print("🚨 ERROR: No se pudo abrir cobertura para #", stuck_ticket, ": ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Gestionar pares enganchada+cobertura: cerrar ambas en cuanto el    |
//| neto combinado cubra costes + beneficio mínimo. "Limpiar la mesa". |
//+------------------------------------------------------------------+
void ManageCoberturas()
{
   if(TipoCobertura == COBERTURA_NINGUNA)
      return;

   string prefix = GVPrefix();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong hedge_ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(hedge_ticket) ||
         PositionGetString(POSITION_SYMBOL) != _Symbol ||
         PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      string comment = PositionGetString(POSITION_COMMENT);
      if(StringFind(comment, "HEDGE_") != 0)
         continue;

      ulong stuck_ticket = (ulong)StringToInteger(StringSubstr(comment, 6));
      if(stuck_ticket == 0 || !PositionSelectByTicket(stuck_ticket))
      {
         // La posición enganchada ya no existe (se cerró por otra vía) -- cerrar la cobertura suelta,
         // SALVO que sea una pata superviviente protegida (ya se dejó correr a propósito: ver más abajo).
         // Reseleccionamos explícitamente la cobertura, porque la comprobación anterior puede
         // haber dejado seleccionada otra posición (o ninguna).
         if(!PositionSelectByTicket(hedge_ticket))
            continue;
         if(GVGetOrZero(prefix + IntegerToString(hedge_ticket) + "_CoberturaSurvivor") >= 1)
            continue; // superviviente protegida -- la gestiona ManageCoberturaSurvivorTrailing()
         double orphan_net = GetNetResult(hedge_ticket);
         ClosePosition(hedge_ticket, "Cobertura huérfana (pareja ya cerrada)", orphan_net);
         CleanupTicketState(hedge_ticket);
         continue;
      }

      // Cada lectura reselecciona explícitamente su ticket -- PositionGetDouble/PositionGetString
      // operan sobre "la última posición seleccionada", así que no podemos asumir cuál quedó
      // seleccionada tras la comprobación anterior.
      PositionSelectByTicket(hedge_ticket);
      double hedge_net = GetNetResult(hedge_ticket);
      double hedge_volume = PositionGetDouble(POSITION_VOLUME);

      PositionSelectByTicket(stuck_ticket);
      double stuck_net = GetNetResult(stuck_ticket);
      double stuck_volume = PositionGetDouble(POSITION_VOLUME);

      double combined_net = hedge_net + stuck_net;
      double combined_volume = hedge_volume + stuck_volume;
      double min_target = CalculateMinProfitTargetCustom(combined_volume, MinProfitCobertura);

      if(combined_net >= min_target)
      {
         // Decidir quién es la pata "ganadora" (mayor neto individual) y quién la "perdedora".
         ulong winner_ticket, loser_ticket;
         double winner_net, loser_net;
         if(hedge_net >= stuck_net)
         {
            winner_ticket = hedge_ticket; winner_net = hedge_net;
            loser_ticket  = stuck_ticket; loser_net  = stuck_net;
         }
         else
         {
            winner_ticket = stuck_ticket; winner_net = stuck_net;
            loser_ticket  = hedge_ticket; loser_net  = hedge_net;
         }

         PositionSelectByTicket(loser_ticket);
         ClosePosition(loser_ticket, "Cobertura: pata perdedora cerrada (par neto en beneficio)", loser_net);
         CleanupTicketState(loser_ticket);

         if(!UseATRTrailingCobertura)
         {
            // Comportamiento v3.00: cerrar también la ganadora de inmediato.
            PositionSelectByTicket(winner_ticket);
            double final_net = GetNetResult(winner_ticket);
            ClosePosition(winner_ticket, "Cobertura: par cerrado con beneficio", final_net);
            CleanupTicketState(winner_ticket);
            Print("🧹 MESA LIMPIADA: #", stuck_ticket, " + cobertura #", hedge_ticket,
                  " | Neto combinado: $", DoubleToString(combined_net, 2), " (objetivo $", DoubleToString(min_target, 2), ")");
         }
         else
         {
            // Proteger la ganadora a breakeven (SL = su propio precio de apertura) y dejarla
            // correr con trailing ATR (ver ManageCoberturaSurvivorTrailing).
            PositionSelectByTicket(winner_ticket);
            double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            CTrade trade;
            trade.SetExpertMagicNumber(MagicNumber);
            if(!trade.PositionModify(winner_ticket, open_price, PositionGetDouble(POSITION_TP)))
            {
               Print("🚨 ERROR: No se pudo proteger a breakeven la pata ganadora #", winner_ticket,
                     ": ", trade.ResultRetcodeDescription());
            }
            GlobalVariableSet(prefix + IntegerToString(winner_ticket) + "_CoberturaSurvivor", 1);
            Print("🏃 COBERTURA LIBERADA: #", stuck_ticket, " + cobertura #", hedge_ticket,
                  " | Neto combinado: $", DoubleToString(combined_net, 2),
                  " | Perdedora #", loser_ticket, " cerrada ($", DoubleToString(loser_net, 2), ")",
                  " | Ganadora #", winner_ticket, " protegida a breakeven ($", DoubleToString(open_price, _Digits),
                  ") y dejada correr con trailing ATR");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trailing ATR para la pata superviviente de una cobertura: tras    |
//| liberar el par (neto combinado en beneficio, perdedora cerrada),  |
//| esta ganadora queda sola, protegida a breakeven, y se deja correr  |
//| con un stop que sigue al precio a una distancia de ATR(H4) x       |
//| ATR_MultiplicadorCobertura puntos.                                 |
//+------------------------------------------------------------------+
void ManageCoberturaSurvivorTrailing()
{
   if(!UseATRTrailingCobertura)
      return;

   double atr_buf[];
   if(CopyBuffer(atr_cobertura_handle, 0, 0, 1, atr_buf) < 1)
      return;
   double atr_distance_points = (atr_buf[0] / _Point) * ATR_MultiplicadorCobertura;
   if(atr_distance_points <= 0)
      return;

   string prefix = GVPrefix();
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket) ||
         PositionGetString(POSITION_SYMBOL) != _Symbol ||
         PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      string base = prefix + IntegerToString(ticket) + "_";
      if(GVGetOrZero(base + "CoberturaSurvivor") < 1)
         continue;

      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double current_sl = PositionGetDouble(POSITION_SL);

      if(pos_type == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double new_sl = bid - atr_distance_points * _Point;
         if(new_sl > current_sl) // solo se tensa a favor, nunca se afloja por debajo del breakeven ya fijado
         {
            if(trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP)))
               Print("🏃 TRAILING ATR COBERTURA: #", ticket, " | Nuevo SL: ", DoubleToString(new_sl, _Digits),
                     " | Distancia ATR: ", DoubleToString(atr_distance_points, 0), " puntos");
         }
      }
      else if(pos_type == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double new_sl = ask + atr_distance_points * _Point;
         if(current_sl == 0 || new_sl < current_sl)
         {
            if(trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP)))
               Print("🏃 TRAILING ATR COBERTURA: #", ticket, " | Nuevo SL: ", DoubleToString(new_sl, _Digits),
                     " | Distancia ATR: ", DoubleToString(atr_distance_points, 0), " puntos");
         }
      }
   }
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
   trade.SetExpertMagicNumber(MagicNumber);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = SinStops ? 0.0 : (ask + SL_Points * _Point);
   double tp = 0;

   double lot_size = NormalizeLotSize(MathMin(base_lot_size, MaxContractSize));

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
      CacheEntryCommission(trade.ResultOrder(), trade.ResultDeal());
      Print("📉 VENTA ABIERTA: Ticket #", trade.ResultOrder(),
            " | Lote: ", DoubleToString(lot_size, 2),
            " | Precio: ", DoubleToString(ask, _Digits),
            " | SL: ", (SinStops ? "SIN STOP" : DoubleToString(sl, _Digits)));
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
   trade.SetExpertMagicNumber(MagicNumber);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = SinStops ? 0.0 : (bid - SL_Points * _Point);
   double tp = 0;

   double lot_size = NormalizeLotSize(MathMin(base_lot_size, MaxContractSize));

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
      CacheEntryCommission(trade.ResultOrder(), trade.ResultDeal());
      Print("📈 COMPRA ABIERTA: Ticket #", trade.ResultOrder(),
            " | Lote: ", DoubleToString(lot_size, 2),
            " | Precio: ", DoubleToString(bid, _Digits),
            " | SL: ", (SinStops ? "SIN STOP" : DoubleToString(sl, _Digits)));
   }
   else
   {
      Print("🚨 ERROR: No se pudo abrir compra: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Verificar condiciones de salida (sistema de 3 fases) y gestionar   |
//| avisos de acción manual                                            |
//+------------------------------------------------------------------+
void CheckExitConditions()
{
   if(CopyBuffer(bb_handle, 0, 0, 1, bb_mid) < 1 ||
      CopyBuffer(bb_handle, 1, 0, 1, bb_upper) < 1 ||
      CopyBuffer(bb_handle, 2, 0, 1, bb_lower) < 1)
   {
      return;
   }

   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   string prefix = GVPrefix();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket) ||
         PositionGetString(POSITION_SYMBOL) != _Symbol ||
         PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      // Las coberturas no pasan por el sistema de 3 fases: las gestiona ManageCoberturas().
      if(StringFind(PositionGetString(POSITION_COMMENT), "HEDGE_") == 0)
         continue;

      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl_price = PositionGetDouble(POSITION_SL);
      double lot_size = PositionGetDouble(POSITION_VOLUME);

      string base = prefix + IntegerToString(ticket) + "_";

      // Si ya tiene cobertura abierta, el cierre pasa a depender del par (ManageCoberturas()),
      // no del sistema de 3 fases de esta posición individual.
      if(GVGetOrZero(base + "HedgeOpened") >= 1)
         continue;
      long phase = (long)GVGetOrZero(base + "Phase");
      double net = GetNetResult(ticket);

      // --- MAE (Máxima Excursión Adversa en puntos): se mide siempre, haya o no stops,        ---
      // --- para poder analizar después hasta cuántos puntos llegan las operaciones que         ---
      // --- finalmente revierten, frente a las que no, y fijar el umbral de cobertura con datos. ---
      double adverse_points = (pos_type == POSITION_TYPE_BUY)
                                ? (open_price - current_price) / _Point
                                : (current_price - open_price) / _Point;
      double mae_so_far = GVGetOrZero(base + "MaxAdverse");
      if(adverse_points > mae_so_far)
      {
         GlobalVariableSet(base + "MaxAdverse", adverse_points);
         mae_so_far = adverse_points;
      }

      // --- Stop Loss clásico, solo si SinStops=false (seguridad adicional, el bróker ya lo ejecuta) ---
      if(!SinStops)
      {
         bool hit_sl = false;
         if(pos_type == POSITION_TYPE_BUY && sl_price > 0 && current_price <= sl_price)
            hit_sl = true;
         else if(pos_type == POSITION_TYPE_SELL && sl_price > 0 && current_price >= sl_price)
            hit_sl = true;

         if(hit_sl)
         {
            ClosePosition(ticket, "Stop Loss", net, mae_so_far);
            CleanupTicketState(ticket);
            continue;
         }

         if(UseTrailingStop)
            ManageTrailingStop(ticket, pos_type, open_price, current_price);
      }

      // --- Avisos escalonados de intervención manual (solo si SinStops=true) ---
      // Nivel 1 "Vigilar": solo log, sin popup -- evita habituarte a un aviso que casi
      // siempre resulta ser ruido (la mayoría de operaciones que llegan aquí acaban bien).
      if(SinStops)
      {
         if(adverse_points >= AlertaVigilarPoints && GVGetOrZero(base + "AlertAdverse") < 1)
         {
            Print("👀 VIGILAR #", ticket, " (", (pos_type == POSITION_TYPE_BUY ? "BUY" : "SELL"), "): ",
                  DoubleToString(adverse_points, 0), " puntos en contra (umbral ", AlertaVigilarPoints, "). Sin acción -- solo registro.");
            GlobalVariableSet(base + "AlertAdverse", 1);
         }

         // Nivel 2 "Revisar": aviso real (popup + push).
         if(adverse_points >= AlertaRevisarPoints && GVGetOrZero(base + "AlertRevisar") < 1)
         {
            string msg_revisar = StringFormat(
               "JOHN WICK H4 #%I64u (%s): %.0f puntos en contra (nivel 2/4 - REVISAR). Mira el régimen de mercado y cuántas posiciones tienes en esta misma dirección.",
               ticket, (pos_type == POSITION_TYPE_BUY ? "BUY" : "SELL"), adverse_points);
            RaiseManualAlert(msg_revisar);
            GlobalVariableSet(base + "AlertRevisar", 1);
         }

         // Nivel 3 "Decidir": aviso prioritario.
         if(adverse_points >= AlertaDecidirPoints && GVGetOrZero(base + "AlertDecidir") < 1)
         {
            string msg_decidir = StringFormat(
               "JOHN WICK H4 #%I64u (%s): %.0f puntos en contra (nivel 3/4 - DECIDIR). Decide ya: cobertura manual, reducir exposición en esta dirección, o esperar conscientemente.",
               ticket, (pos_type == POSITION_TYPE_BUY ? "BUY" : "SELL"), adverse_points);
            RaiseManualAlert(msg_decidir);
            GlobalVariableSet(base + "AlertDecidir", 1);
         }

         // Nivel 4 "Línea roja" (umbral = PuntosCobertura): si la cobertura automática está
         // desactivada (uso previsto en real), lanza el aviso máximo en su lugar.
         if(TipoCobertura == COBERTURA_NINGUNA &&
            adverse_points >= PuntosCobertura &&
            GVGetOrZero(base + "AlertLineaRoja") < 1)
         {
            string msg_rojo = StringFormat(
               "JOHN WICK H4 #%I64u (%s): %.0f puntos en contra (nivel 4/4 - LÍNEA ROJA, %d). Sin margen de espera: actúa ahora.",
               ticket, (pos_type == POSITION_TYPE_BUY ? "BUY" : "SELL"), adverse_points, PuntosCobertura);
            RaiseManualAlert(msg_rojo);
            GlobalVariableSet(base + "AlertLineaRoja", 1);
         }
      }

      // --- Apertura de cobertura automática (si está activada) ---
      if(TipoCobertura != COBERTURA_NINGUNA &&
         adverse_points >= PuntosCobertura &&
         GVGetOrZero(base + "HedgeOpened") < 1)
      {
         OpenCobertura(ticket, pos_type, lot_size);
         continue; // a partir de ahora la gestiona ManageCoberturas()
      }

      // --- Fase 0: esperando banda central ---
      if(phase == 0)
      {
         bool reached_center = (pos_type == POSITION_TYPE_BUY && current_price >= bb_mid[0]) ||
                                (pos_type == POSITION_TYPE_SELL && current_price <= bb_mid[0]);
         if(reached_center)
         {
            if(net > 0)
            {
               ClosePosition(ticket, "Banda central (beneficio)", net, mae_so_far);
               CleanupTicketState(ticket);
               continue;
            }
            else
            {
               if(GVGetOrZero(base + "AlertCenter") < 1)
               {
                  string msg = StringFormat(
                     "JOHN WICK H4 #%I64u (%s): banda central alcanzada SIN beneficio ($%.2f). Objetivo ahora: %s. Revisar cobertura/apoyo manual.",
                     ticket, (pos_type == POSITION_TYPE_BUY ? "BUY" : "SELL"), net,
                     (pos_type == POSITION_TYPE_BUY ? "banda SUPERIOR" : "banda INFERIOR"));
                  RaiseManualAlert(msg);
                  GlobalVariableSet(base + "AlertCenter", 1);
               }
               GlobalVariableSet(base + "Phase", 1);
            }
         }
         continue;
      }

      // --- Fase 1: esperando el extremo opuesto de Bollinger ---
      if(phase == 1)
      {
         bool reached_opposite = (pos_type == POSITION_TYPE_BUY && current_price >= bb_upper[0]) ||
                                  (pos_type == POSITION_TYPE_SELL && current_price <= bb_lower[0]);
         if(reached_opposite)
         {
            if(net > 0)
            {
               ClosePosition(ticket, "Extremo opuesto (beneficio)", net, mae_so_far);
               CleanupTicketState(ticket);
               continue;
            }

            if(GVGetOrZero(base + "AlertOpposite") < 1)
            {
               string msg = StringFormat(
                  "JOHN WICK H4 #%I64u (%s): extremo opuesto alcanzado SIN beneficio ($%.2f). %s Revisar cobertura/apoyo manual.",
                  ticket, (pos_type == POSITION_TYPE_BUY ? "BUY" : "SELL"), net,
                  (CierreConBeneficioMinimo
                     ? "Se cerrará automáticamente al cubrir coste + beneficio mínimo."
                     : "Cierre automático desactivado (CierreConBeneficioMinimo=false): requiere acción manual."));
               RaiseManualAlert(msg);
               GlobalVariableSet(base + "AlertOpposite", 1);
            }

            if(CierreConBeneficioMinimo)
               GlobalVariableSet(base + "Phase", 2);
         }
         continue;
      }

      // --- Fase 2: esperando beneficio mínimo (se revisa cada tick) ---
      if(phase == 2)
      {
         double min_target = CalculateMinProfitTarget(lot_size);
         if(net >= min_target)
         {
            ClosePosition(ticket, StringFormat("Beneficio mínimo alcanzado (objetivo $%.2f)", min_target), net, mae_so_far);
            CleanupTicketState(ticket);
         }
         continue;
      }
   }
}

//+------------------------------------------------------------------+
//| Gestionar Trailing Stop (solo relevante si SinStops=false)        |
//+------------------------------------------------------------------+
void ManageTrailingStop(ulong ticket, ENUM_POSITION_TYPE pos_type, double open_price, double current_price)
{
   if(!UseTrailingStop || SinStops)
      return;

   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);

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
//| Cerrar posición propia                                            |
//| mae_points: máxima excursión adversa alcanzada (en puntos) antes   |
//| de cerrar -- se registra en el log para poder analizar después     |
//| hasta dónde llegan las operaciones que sí revierten.                |
//+------------------------------------------------------------------+
void ClosePosition(ulong ticket, string reason, double net_result, double mae_points = 0.0)
{
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);

   if(trade.PositionClose(ticket))
   {
      Print("🔒 POSICIÓN CERRADA: Ticket #", ticket, " | Razón: ", reason,
            " | Resultado neto: ", DoubleToString(net_result, 2),
            " | MAE: ", DoubleToString(mae_points, 0), " puntos");
      CheckAutoScaling(); // balance ya refleja este cierre
   }
   else
   {
      Print("🚨 ERROR: No se pudo cerrar posición #", ticket, ": ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Cerrar TODAS las posiciones PROPIAS (este MagicNumber).            |
//| Nunca toca posiciones manuales ni de otros bots.                   |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         double net = GetNetResult(ticket);
         double mae = GVGetOrZero(GVPrefix() + IntegerToString(ticket) + "_MaxAdverse");
         ClosePosition(ticket, "Cierre masivo", net, mae);
         CleanupTicketState(ticket);
      }
   }
   Print("🔄 LOTE VIGENTE TRAS CIERRE MASIVO: ", DoubleToString(base_lot_size, 2));
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
      CleanupOrphanGlobals();
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
//| Calcular pérdida diaria total — SOLO posiciones propias            |
//+------------------------------------------------------------------+
double CalculateTotalDailyLoss()
{
   double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double floating_loss = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         floating_loss += PositionGetDouble(POSITION_PROFIT);
      }
   }

   realized_loss = current_balance - daily_start_balance;
   double total_loss = realized_loss + floating_loss;
   return total_loss;
}

//+------------------------------------------------------------------+
//| Panel en pantalla: estado de cada posición propia y avisos        |
//+------------------------------------------------------------------+
void UpdatePanel()
{
   if(!MostrarPanel)
      return;

   string prefix = GVPrefix();
   string panel = "=== JOHN WICK H4 v3.20 (Magic " + IntegerToString(MagicNumber) + ") ===\n";
   panel += "Trading: " + (trading_disabled ? "DETENIDO" : "ACTIVO") +
            " | Lote base: " + DoubleToString(base_lot_size, 2) +
            " | SinStops: " + (SinStops ? "SI" : "NO") + "\n";
   panel += "----------------------------------------\n";

   int shown = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket) ||
         PositionGetString(POSITION_SYMBOL) != _Symbol ||
         PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      shown++;
      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      string base = prefix + IntegerToString(ticket) + "_";
      long phase = (long)GVGetOrZero(base + "Phase");
      double net = GetNetResult(ticket);

      string phase_txt;
      if(phase == 0) phase_txt = "Esperando banda central";
      else if(phase == 1) phase_txt = "Esperando extremo opuesto";
      else phase_txt = "Esperando beneficio mínimo";

      panel += StringFormat("#%I64u %s | Neto: $%.2f | %s", ticket,
                             (pos_type == POSITION_TYPE_BUY ? "BUY " : "SELL"),
                             net, phase_txt);

      if(GVGetOrZero(base + "AlertLineaRoja") >= 1)
         panel += " | 🔴 LÍNEA ROJA (" + IntegerToString(PuntosCobertura) + "+)";
      else if(GVGetOrZero(base + "AlertDecidir") >= 1)
         panel += " | 🟠 DECIDIR (" + IntegerToString(AlertaDecidirPoints) + "+)";
      else if(GVGetOrZero(base + "AlertRevisar") >= 1)
         panel += " | 🟡 REVISAR (" + IntegerToString(AlertaRevisarPoints) + "+)";
      else if(GVGetOrZero(base + "AlertAdverse") >= 1)
         panel += " | 🟢 vigilar (" + IntegerToString(AlertaVigilarPoints) + "+)";

      string own_comment = PositionGetString(POSITION_COMMENT);
      if(GVGetOrZero(base + "CoberturaSurvivor") >= 1)
         panel += " | 🏃 SUPERVIVIENTE (trailing ATR)";
      else if(StringFind(own_comment, "HEDGE_") == 0)
         panel += " | 🛡 COBERTURA de #" + StringSubstr(own_comment, 6);
      else if(GVGetOrZero(base + "HedgeOpened") >= 1)
         panel += " | 🛡 con cobertura abierta";

      panel += "\n";
   }

   if(shown == 0)
      panel += "(sin posiciones propias abiertas)\n";

   Comment(panel);
}