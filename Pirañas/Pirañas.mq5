//+------------------------------------------------------------------+
//|                                               Pirañas.mq5        |
//|                                             Jose Antonio Montero |
//|                        https://www.linkedin.com/in/joseamontero/ |
//+------------------------------------------------------------------+
//| Notas para activar el bot:                                       |
//|                                                                  |         
//| - RSI en H1/H4 en niveles extremos: RSI < 30 (compras) o         |
//|   RSI > 70 (ventas).                                             |
//| - Precio cerca de la EMA en H1: Indica rango o posible reversión.|
//| - Precio cerca de soporte/resistencia: Aumenta probabilidad de   |
//|   reversión.                                                     |
//| - Sin noticias de alto impacto: Evitar eventos en rojo en el     |
//|   calendario económico.                                          |
//+------------------------------------------------------------------+

#property copyright "Jose Antonio Montero"
#property link      "https://www.linkedin.com/in/joseamontero/"
#property version   "1.022"

#include <Trade\Trade.mqh>
CTrade trade;

//--- Configuración General ---//
input group "Configuración General"
input ENUM_TIMEFRAMES PERIODO = PERIOD_M10;         // Marco Temporal

//--- Indicadores Técnicos ---//
input group "Indicadores Técnicos"
input int RSI_PERIODO = 4;                         // Períodos RSI
input short RSI_NIVEL_COMPRA = 35;                // Nivel RSI Compra
input short RSI_NIVEL_VENTA = 65;                 // Nivel RSI Venta
input int MA_PERIODO = 200;                        // Períodos Media Móvil
input int ADX_PERIODO = 18;                        // Períodos ADX
input double ADX_NIVEL_MAX = 30.0;                 // Nivel Máximo ADX (mercado en rango)

//--- Gestión de Operaciones ---//
input group "Gestión de Operaciones"
input double LOTAJE_INICIAL = 0.1;                // Tamaño Lote Inicial
input double MULTIPLICADOR = 1.5;                 // Multiplicador Lote
input double OBJETIVO_PROFIT = 220.0;              // Objetivo Beneficio ($)
input int DISTANCIA_OPERACIONES = 105;             // Distancia Entre Operaciones (puntos)

//--- Gestión de Riesgos FTMO ---//
input group "Gestión de Riesgos FTMO"
input double MaxDailyLossFTMO = 500.0;            // Pérdida Diaria Máxima ($)
input double SafetyBeltFactor = 0.5;              // Factor de Seguridad (0.0 a 1.0)
input double InitialBalance = 10000.0;            // Balance Inicial ($)
input double MinOperatingBalance = 9100.0;        // Capital Operativo Mínimo ($)

//--- Cierre por Objetivos y Tiempo ---//
input group "Cierre por Objetivos y Tiempo"
input bool UseBalanceTarget = true;               // Usar Objetivo de Balance
input double BalanceTarget = 11000.0;             // Objetivo de Balance ($)
input int DiasCierreBeneficio = 0;                // Días para Cierre con Beneficio Mínimo
input double BeneficioMinimoCierre = 438.0;        // Beneficio Mínimo para Cierre ($)
input int DiasTopeMaximo = 2;                     // Días Máximos para Cierre

int rsi_h;
double rsi[];
int ma_h;
double ma[];
int adx_h;                                        // Handle para ADX
double adx[];
double ultima_compra_precio = 0;
double ultima_venta_precio = 0;
MqlRates velas[];
int bars = 0;
double dailyStartBalance = 0.0;
datetime lastDayReset = 0;
double realizedLoss = 0.0;
double effectiveMaxDailyLoss;
bool tradingDisabled = false;
bool botActive = true;
ulong m_magic = 200607121118;
double minEquity = InitialBalance;
double initialBalance = 0.0;
double peakBalance = 0.0;
double dailyLossThreshold = 0.0;
double dailyProfitThreshold = 0.0;
int atrHandle;
double atrValues[];

//+------------------------------------------------------------------+
//| Funciones Auxiliares                                            |
//+------------------------------------------------------------------+
bool nueva_vela() {
   int current_bars = Bars(_Symbol, PERIODO);
   if (bars != current_bars) {
      bars = current_bars;
      return true;
   }
   return false;
}

bool rsi_pico_compra() {
   return rsi[1] < rsi[2] && rsi[1] < rsi[0] && rsi[1] < RSI_NIVEL_COMPRA;
}

bool rsi_pico_venta() {
   return rsi[1] > rsi[2] && rsi[1] > rsi[0] && rsi[1] > RSI_NIVEL_VENTA;
}

bool tendencia_alcista() {
   return velas[0].close > ma[0];
}

bool tendencia_bajista() {
   return velas[0].close < ma[0];
}

bool mercado_en_rango() {
   return adx[1] < ADX_NIVEL_MAX;
}

double get_lotaje() {
   return NormalizeDouble(LOTAJE_INICIAL * MathPow(MULTIPLICADOR, PositionsTotal()), 2);
}

void cerrar_operaciones() {
   double profit_actual = AccountInfoDouble(ACCOUNT_EQUITY) - AccountInfoDouble(ACCOUNT_BALANCE);
   if (profit_actual < OBJETIVO_PROFIT) return;

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong trade_ticket = PositionGetTicket(i);
      trade.PositionClose(trade_ticket);
   }
   ultima_compra_precio = 0;
   ultima_venta_precio = 0;
   Print("[OPERACIÓN] ✅ Todas las posiciones cerradas por objetivo de beneficio: $", DoubleToString(profit_actual, 2));
}

bool distancia_entre_operaciones(double precio, bool es_compra) {
   if (es_compra) {
      return (ultima_compra_precio - precio) / _Point > DISTANCIA_OPERACIONES || ultima_compra_precio == 0;
   } else {
      return (precio - ultima_venta_precio) / _Point > DISTANCIA_OPERACIONES || ultima_venta_precio == 0;
   }
}

bool operaciones_de_solo_un_tipo(ENUM_POSITION_TYPE tipo) {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong trade_ticket = PositionGetTicket(i);
      ENUM_POSITION_TYPE tipo_operacion = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if (tipo_operacion != tipo) return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Funciones de Gestión de Riesgos FTMO                            |
//+------------------------------------------------------------------+
void CheckDailyReset() {
   datetime utcTime = TimeGMT();
   MqlDateTime utcStruct;
   TimeToStruct(utcTime, utcStruct);
   
   int hourOffset = (utcStruct.mon >= 3 && utcStruct.mon <= 10) ? 2 : 1;
   datetime spanishTime = utcTime + hourOffset * 3600;
   MqlDateTime spanishStruct;
   TimeToStruct(spanishTime, spanishStruct);

   if (utcStruct.hour == (22 + (hourOffset == 1 ? 1 : 0)) && utcStruct.min == 0 && utcTime > lastDayReset + 60) {
      dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      lastDayReset = utcTime;
      realizedLoss = 0.0;
      if (tradingDisabled) {
         tradingDisabled = false;
         Print("[INFO] 🔄 Reinicio diario tras pérdida máxima: Balance=$", DoubleToString(dailyStartBalance, 2), " | Hora=", spanishStruct.hour, ":", spanishStruct.min);
      } else {
         Print("[INFO] 🔄 Reinicio diario: Balance=$", DoubleToString(dailyStartBalance, 2), " | Hora=", spanishStruct.hour, ":", spanishStruct.min);
      }
   }
}

double CalculateTotalDailyLoss() {
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double floatingLoss = 0.0;
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionGetSymbol(i) == _Symbol) {
         floatingLoss += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   realizedLoss = currentBalance - dailyStartBalance;
   return realizedLoss + floatingLoss;
}

void CloseAllPositions() {
   int attempts = 0;
   while (PositionsTotal() > 0 && attempts < 10) {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionGetSymbol(i) == _Symbol) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
         }
      }
      Sleep(100);
      attempts++;
   }
   if (PositionsTotal() > 0) {
      Print("[ERROR] ⚠️ No se pudieron cerrar todas las posiciones tras ", attempts, " intentos");
   } else {
      Print("[OPERACIÓN] ✅ Todas las posiciones cerradas para ", _Symbol);
   }
   ultima_compra_precio = 0;
   ultima_venta_precio = 0;
}

//+------------------------------------------------------------------+
//| Funciones Adicionales                                           |
//+------------------------------------------------------------------+
void cerrar_por_tiempo_y_beneficio() {
   if (PositionsTotal() == 0) return;

   double profit_actual = AccountInfoDouble(ACCOUNT_EQUITY) - AccountInfoDouble(ACCOUNT_BALANCE);
   datetime ahora = TimeCurrent();
   datetime fecha_mas_antigua = ahora;

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         datetime apertura = (datetime)PositionGetInteger(POSITION_TIME);
         if (apertura < fecha_mas_antigua) fecha_mas_antigua = apertura;
      }
   }

   int dias_transcurridos = (int)((ahora - fecha_mas_antigua) / (60 * 60 * 24));

   if (dias_transcurridos >= DiasCierreBeneficio && profit_actual >= BeneficioMinimoCierre) {
      CloseAllPositionsAccountWide();
      Print("[OPERACIÓN] ✅ Cerrado por beneficio mínimo: Días=", dias_transcurridos, ", Beneficio=$", DoubleToString(profit_actual, 2));
      ultima_compra_precio = 0;
      ultima_venta_precio = 0;
      return;
   }

   if (dias_transcurridos >= DiasTopeMaximo) {
      CloseAllPositionsAccountWide();
      Print("[OPERACIÓN] ✅ Cerrado por límite de días: Días=", dias_transcurridos, ", Beneficio=$", DoubleToString(profit_actual, 2));
      ultima_compra_precio = 0;
      ultima_venta_precio = 0;
   }
}

void CheckBalanceTarget() {
   if (!UseBalanceTarget) return;
   
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   if (currentBalance >= BalanceTarget) {
      CloseAllPositionsAccountWide();
      Print("[INFO] 🎯 Objetivo de balance alcanzado: Balance=$", DoubleToString(currentBalance, 2), " >= Objetivo=$", DoubleToString(BalanceTarget, 2), ". Bot detenido.");
      ExpertRemove();
   }
}

bool CheckFTMOLimits() {
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyLoss = dailyStartBalance - currentEquity;

   double dailyProfit = currentEquity - dailyStartBalance;
   if (dailyProfit > dailyProfitThreshold) dailyProfitThreshold = dailyProfit;

   double effectiveDailyLossLimit = MathMin(effectiveMaxDailyLoss + MathMax(0, dailyProfitThreshold), effectiveMaxDailyLoss);
   if (dailyLoss >= effectiveDailyLossLimit && !tradingDisabled) {
      CloseAllPositionsAccountWide();
      tradingDisabled = true;
      Print("[ERROR] ⚠️ Límite de pérdida diaria alcanzado: Pérdida=$", DoubleToString(dailyLoss, 2), " >= $", DoubleToString(effectiveDailyLossLimit, 2));
      return false;
   }

   return !tradingDisabled;
}

void CloseAllPositionsAccountWide() {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket)) {
         trade.PositionClose(ticket);
      }
   }
   Print("[OPERACIÓN] ✅ Todas las posiciones cerradas en la cuenta");
}

//+------------------------------------------------------------------+
//| Inicialización                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   rsi_h = iRSI(_Symbol, PERIODO, RSI_PERIODO, PRICE_CLOSE);
   ma_h = iMA(_Symbol, PERIODO, MA_PERIODO, 0, MODE_EMA, PRICE_CLOSE);
   adx_h = iADX(_Symbol, PERIODO, ADX_PERIODO);    // Inicializar ADX
   atrHandle = iATR(_Symbol, PERIODO, 14);
   if (rsi_h == INVALID_HANDLE || ma_h == INVALID_HANDLE || adx_h == INVALID_HANDLE || atrHandle == INVALID_HANDLE) {
      Print("[ERROR] ⚠️ Error al cargar indicadores");
      return INIT_FAILED;
   }

   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(ma, true);
   ArraySetAsSeries(adx, true);
   ArraySetAsSeries(atrValues, true);
   trade.SetAsyncMode(false);
   trade.SetExpertMagicNumber(m_magic);

   dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   lastDayReset = TimeCurrent();
   realizedLoss = 0.0;
   if (SafetyBeltFactor <= 0.0 || SafetyBeltFactor > 1.0) {
      Print("[ERROR] ⚠️ Factor de seguridad inválido. Usando valor por defecto: 0.5");
      effectiveMaxDailyLoss = MaxDailyLossFTMO * 0.5;
   } else {
      effectiveMaxDailyLoss = MaxDailyLossFTMO * SafetyBeltFactor;
   }
   bars = Bars(_Symbol, PERIODO);
   minEquity = InitialBalance;
   initialBalance = InitialBalance;
   peakBalance = initialBalance;
   dailyLossThreshold = MaxDailyLossFTMO;
   dailyProfitThreshold = 0.0;

   Print("[INFO] 🚀 Bot inicializado: Balance=$", DoubleToString(dailyStartBalance, 2), ", Límite Pérdida Diaria=$", DoubleToString(effectiveMaxDailyLoss, 2));
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Finalización                                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if (rsi_h != INVALID_HANDLE) IndicatorRelease(rsi_h);
   if (ma_h != INVALID_HANDLE) IndicatorRelease(ma_h);
   if (adx_h != INVALID_HANDLE) IndicatorRelease(adx_h);
   if (atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);

   int totalBars = Bars(_Symbol, PERIODO);
   double atr[];
   ArraySetAsSeries(atr, true);
   int copied = CopyBuffer(atrHandle, 0, 0, totalBars, atr);
   if (copied > 0) {
      double atrMax = 0.0, atrMin = 0.0, atrSum = 0.0;
      int atrCount = 0;
      
      for (int i = 0; i < copied; i++) {
         if (atr[i] > 0.0) {
            atrMax = atr[i];
            atrMin = atr[i];
            atrSum = atr[i];
            atrCount = 1;
            break;
         }
      }
      
      for (int i = atrCount; i < copied; i++) {
         double currentAtr = atr[i];
         if (currentAtr > 0.0 && currentAtr < 1.0) {
            if (currentAtr > atrMax) atrMax = currentAtr;
            if (currentAtr < atrMin) atrMin = currentAtr;
            atrSum += currentAtr;
            atrCount++;
         }
      }
      
      if (atrCount > 0) {
         double atrAverage = atrSum / atrCount;
         Print("[INFO] 📊 Estadísticas ATR (Precio): Máx=", DoubleToString(atrMax, 5), ", Mín=", DoubleToString(atrMin, 5), ", Promedio=", DoubleToString(atrAverage, 5));
         Print("[INFO] 📊 Estadísticas ATR (Puntos): Máx=", DoubleToString(atrMax / _Point, 2), ", Mín=", DoubleToString(atrMin / _Point, 2), ", Promedio=", DoubleToString(atrAverage / _Point, 2));
      } else {
         Print("[ERROR] ⚠️ No se encontraron valores ATR válidos");
      }
   } else {
      Print("[ERROR] ⚠️ Error al recuperar valores ATR: Error=", GetLastError());
   }

   Print("[INFO] 🛑 Bot finalizado: Razón=", reason, ", Capital Mínimo=$", DoubleToString(minEquity, 2));
}

//+------------------------------------------------------------------+
//| Lógica Principal                                                |
//+------------------------------------------------------------------+
void OnTick() {
   if (!botActive) return;

   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   if (currentEquity < minEquity) {
      minEquity = currentEquity;
      Print("[INFO] 📉 Nuevo capital mínimo: $", DoubleToString(minEquity, 2), " en ", TimeToString(TimeCurrent()));
   }

   if (UseBalanceTarget && currentBalance >= BalanceTarget && currentEquity >= BalanceTarget - 10.0) {
      CloseAllPositions();
      botActive = false;
      Print("[INFO] 🎯 Objetivo alcanzado: Balance=$", DoubleToString(currentBalance, 2), ", Capital=$", DoubleToString(currentEquity, 2));
      return;
   }

   if (currentEquity < MinOperatingBalance) {
      CloseAllPositions();
      botActive = false;
      Print("[ERROR] ⚠️ Detenido: Capital=$", DoubleToString(currentEquity, 2), " < Mínimo=$", DoubleToString(MinOperatingBalance, 2));
      return;
   }

   CheckDailyReset();
   double totalDailyLoss = CalculateTotalDailyLoss();

   if (totalDailyLoss <= -effectiveMaxDailyLoss) {
      CloseAllPositions();
      tradingDisabled = true;
      Print("[ERROR] ⚠️ Límite de pérdida diaria alcanzado: Pérdida=$", DoubleToString(totalDailyLoss, 2));
      return;
   }

   if (tradingDisabled) return;

   CheckBalanceTarget();
   if (!CheckFTMOLimits()) return;

   CopyBuffer(rsi_h, 0, 1, 3, rsi);
   CopyBuffer(ma_h, 0, 0, 1, ma);
   CopyBuffer(adx_h, 0, 1, 3, adx);               // Copiar datos del ADX
   CopyRates(_Symbol, PERIODO, 0, 1, velas);

   cerrar_por_tiempo_y_beneficio();
   cerrar_operaciones();

   if (nueva_vela() && !tradingDisabled) {
      if (rsi_pico_compra() && tendencia_bajista() && operaciones_de_solo_un_tipo(POSITION_TYPE_BUY) && mercado_en_rango()) {
         double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
         if (!distancia_entre_operaciones(ask, true)) return;
         trade.Buy(get_lotaje(), _Symbol, ask, 0, 0);
         Print("[OPERACIÓN] 📈 Compra abierta: Lote=", DoubleToString(get_lotaje(), 2), ", Precio=", DoubleToString(ask, _Digits), ", ADX=", DoubleToString(adx[1], 2), ", Capital=$", DoubleToString(currentEquity, 2));
         ultima_compra_precio = ask;
      } else if (rsi_pico_venta() && tendencia_alcista() && operaciones_de_solo_un_tipo(POSITION_TYPE_SELL) && mercado_en_rango()) {
         double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         if (!distancia_entre_operaciones(bid, false)) return;
         trade.Sell(get_lotaje(), _Symbol, bid, 0, 0);
         Print("[OPERACIÓN] 📉 Venta abierta: Lote=", DoubleToString(get_lotaje(), 2), ", Precio=", DoubleToString(bid, _Digits), ", ADX=", DoubleToString(adx[1], 2), ", Capital=$", DoubleToString(currentEquity, 2));
         ultima_venta_precio = bid;
      }
   }
}