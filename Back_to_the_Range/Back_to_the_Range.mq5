//+------------------------------------------------------------------+
//|                                            Back to the Range.mq5 |
//|                    Copyright 2025, Jose Antonio Montero Fernández|
//|                         https://www.linkedin.com/in/joseamontero/|
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Object.mqh>

CTrade trade;

//+------------------------------------------------------------------+
//| Log Manager                                                      |
//+------------------------------------------------------------------+
class CLogManager {
private:
   string m_last_messages[];
   datetime m_last_times[];
   int m_max_logs;

public:
   CLogManager(int max_logs = 10) : m_max_logs(max_logs) {
      ArrayResize(m_last_messages, max_logs);
      ArrayResize(m_last_times, max_logs);
      // Inicialización manual de los arreglos
      for (int i = 0; i < max_logs; i++) {
         m_last_messages[i] = "";
         m_last_times[i] = 0;
      }
   }

   bool CanLog(string message) {
      datetime current_time = TimeCurrent();
      for (int i = 0; i < m_max_logs; i++) {
         if (m_last_messages[i] == message) {
            if (current_time - m_last_times[i] < 3600) { // 1 hora cooldown
               return false;
            }
            m_last_times[i] = current_time;
            return true;
         }
      }
      // Nuevo mensaje
      for (int i = m_max_logs - 1; i > 0; i--) {
         m_last_messages[i] = m_last_messages[i-1];
         m_last_times[i] = m_last_times[i-1];
      }
      m_last_messages[0] = message;
      m_last_times[0] = current_time;
      return true;
   }

   void Log(string message) {
      if (CanLog(message)) {
         Print("🌟 ", message);
      }
   }
};

CLogManager log_manager;

//+------------------------------------------------------------------+
//| Class CMultiplierManager                                         |
//+------------------------------------------------------------------+
class CMultiplierManager {
private:
   double m_initial_lot;
   double m_multiplier;
   double m_max_lot;
   double m_current_lot;
   int    m_winning_trades;
   bool   m_use_multiplier;

public:
   CMultiplierManager(double initial_lot, double multiplier, double max_lot, bool use_multiplier) {
      m_initial_lot = initial_lot;
      m_multiplier = multiplier;
      m_max_lot = max_lot;
      m_use_multiplier = use_multiplier;
      m_current_lot = initial_lot;
      m_winning_trades = 0;
   }

   double GetCurrentLot(double price, ENUM_ORDER_TYPE order_type) {
      if (m_current_lot <= 0 || m_current_lot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) {
         m_current_lot = m_initial_lot;
         log_manager.Log("⚠️ Lote inválido - Restablecido a: " + DoubleToString(m_current_lot, 2));
      }
      return AdjustLotToMargin(m_current_lot, price, order_type);
   }

   double NormalizeLotSize(double lot) {
      double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double normalized_lot = MathRound(lot / lot_step) * lot_step;
      normalized_lot = MathMax(min_lot, MathMin(max_lot, normalized_lot));
      int digits = (int)-MathLog10(lot_step);
      return NormalizeDouble(normalized_lot, digits);
   }

   void UpdateLotSize(bool was_winning) {
      if (!m_use_multiplier) {
         m_current_lot = m_initial_lot;
         log_manager.Log("📊 Multiplicador desactivado - Lote: " + DoubleToString(m_current_lot, 2));
         return;
      }
      if (was_winning) {
         m_winning_trades++;
         m_current_lot = m_initial_lot * MathPow(m_multiplier, m_winning_trades);
         if (m_current_lot > m_max_lot) {
            m_current_lot = m_max_lot;
            log_manager.Log("📈 Máximo Lote Alcanzado: " + DoubleToString(m_current_lot, 2));
         } else {
            log_manager.Log("📈 Ganancia - Lote Aumentado: " + DoubleToString(m_current_lot, 2));
         }
      } else {
         m_winning_trades = 0;
         m_current_lot = m_initial_lot;
         log_manager.Log("📉 Pérdida - Lote Restablecido: " + DoubleToString(m_current_lot, 2));
      }
      m_current_lot = NormalizeLotSize(m_current_lot);
   }

   double AdjustLotToMargin(double desired_lot, double price, ENUM_ORDER_TYPE order_type) {
      double free_margin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
      MqlTradeRequest request;
      ZeroMemory(request);
      MqlTradeCheckResult check_result;
      ZeroMemory(check_result);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = _Symbol;
      request.volume = desired_lot;
      request.type = order_type;
      request.price = price;
      if (OrderCheck(request, check_result) && check_result.margin <= free_margin) {
         return NormalizeLotSize(desired_lot);
      }
      double max_lot = desired_lot;
      while (max_lot >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) {
         request.volume = NormalizeLotSize(max_lot);
         if (OrderCheck(request, check_result) && check_result.margin <= free_margin) {
            if (desired_lot != max_lot) {
               log_manager.Log("⚠️ Margen bajo - Lote ajustado de " + DoubleToString(desired_lot, 2) + " a " + DoubleToString(max_lot, 2));
            }
            return request.volume;
         }
         max_lot -= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      }
      log_manager.Log("❌ Margen insuficiente para lote mínimo: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), 2));
      return 0.0;
   }
};

//+------------------------------------------------------------------+
//| Class Liquidez                                                   |
//+------------------------------------------------------------------+
class Liquidez {
public:
   double max;
   double min;
   void get_max_min(int hora_inicio, int hora_final);
   void pintar(int hora_inicio, int hora_final);
};

void Liquidez::get_max_min(int hora_inicio, int hora_final) {
   datetime d_inicio = get_datetime_by_hour(hora_inicio);
   datetime d_final = get_datetime_by_hour(hora_final);
   double highs[], lows[];
   if (CopyHigh(_Symbol, _Period, d_inicio, d_final, highs) <= 0 ||
       CopyLow(_Symbol, _Period, d_inicio, d_final, lows) <= 0) {
      log_manager.Log("❌ Error: No se obtuvieron datos de velas");
      this.max = 0;
      this.min = 0;
      return;
   }
   this.max = get_max(highs);
   this.min = get_min(lows);
   if (this.max <= this.min || this.max == 0 || this.min == 0) {
      log_manager.Log("❌ Error: Rango inválido");
      this.max = 0;
      this.min = 0;
      return;
   }
   log_manager.Log("📊 Rango Formado - Máximo: " + DoubleToString(this.max, _Digits) + " Mínimo: " + DoubleToString(this.min, _Digits));
}

void Liquidez::pintar(int hora_inicio, int hora_final) {
   if (this.max == 0 || this.min == 0) return;
   datetime d_inicio = get_datetime_by_hour(hora_inicio);
   datetime d_final = get_datetime_by_hour(hora_final);
   string liquidez_name = "liquidez-" + IntegerToString(TimeGMT());
   ObjectDelete(0, liquidez_name);
   ObjectCreate(0, liquidez_name, OBJ_RECTANGLE, 0, d_inicio, this.min, d_final, this.max);
   ObjectSetInteger(0, liquidez_name, OBJPROP_COLOR, COLOR_RECTANGULO);
   ObjectSetInteger(0, liquidez_name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, liquidez_name, OBJPROP_FILL, true);
}

//+------------------------------------------------------------------+
//| Class ReentradaRango                                             |
//+------------------------------------------------------------------+
class ReentradaRango {
public:
   bool compra_abierta;
   bool venta_abierta;
   bool break_even_compra;
   bool break_even_venta;
   bool operacion_abierta;
   void operar(int hora_inicio, int hora_final, int puntos_sl, int puntos_tp, Liquidez &liquidez);
   void pintar(int hora_inicio, int hora_final);
   void reset();
};

bool cruce_compra(Liquidez &liquidez, MqlRates &velas[]) {
   return velas[1].close < liquidez.min && velas[0].close > liquidez.min;
}

bool cruce_venta(Liquidez &liquidez, MqlRates &velas[]) {
   return velas[1].close > liquidez.max && velas[0].close < liquidez.max;
}

void ReentradaRango::operar(int hora_inicio, int hora_final, int puntos_sl, int puntos_tp, Liquidez &liquidez) {
   if (trading_desactivado || this.operacion_abierta) {
      if (this.operacion_abierta) log_manager.Log("🚫 Operación bloqueada - Límite diario alcanzado");
      return;
   }
   datetime d_inicio = get_datetime_by_hour(hora_inicio);
   datetime d_final = get_datetime_by_hour(hora_final);
   datetime d_actual = TimeGMT();
   if (d_actual < d_inicio || d_actual > d_final || liquidez.max == 0 || liquidez.min == 0) return;
   MqlRates velas[];
   ArraySetAsSeries(velas, true);
   if (CopyRates(_Symbol, _Period, 0, 2, velas) < 2) {
      log_manager.Log("❌ Error: No se obtuvieron velas");
      return;
   }
   double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if (cruce_compra(liquidez, velas) && !this.compra_abierta) {
      double lotes = lot_multiplier.GetCurrentLot(ask, ORDER_TYPE_BUY);
      if (lotes == 0.0) {
         log_manager.Log("❌ Error: Lote inválido para compra - Margen: " + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2));
         return;
      }
      if (trade.Buy(lotes, _Symbol, ask, puntos_sl == 0 ? 0 : ask - puntos_sl * _Point, puntos_tp == 0 ? 0 : ask + puntos_tp * _Point)) {
         log_manager.Log("📈 Compra Abierta - Precio: " + DoubleToString(ask, _Digits) + " Lotes: " + DoubleToString(lotes, 2));
         this.compra_abierta = true;
         this.operacion_abierta = true;
      } else {
         log_manager.Log("❌ Error: Fallo al abrir compra - Margen: " + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2));
      }
   } else if (cruce_venta(liquidez, velas) && !this.venta_abierta) {
      double lotes = lot_multiplier.GetCurrentLot(bid, ORDER_TYPE_SELL);
      if (lotes == 0.0) {
         log_manager.Log("❌ Error: Lote inválido para venta - Margen: " + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2));
         return;
      }
      if (trade.Sell(lotes, _Symbol, bid, puntos_sl == 0 ? 0 : bid + puntos_sl * _Point, puntos_tp == 0 ? 0 : bid - puntos_tp * _Point)) {
         log_manager.Log("📉 Venta Abierta - Precio: " + DoubleToString(bid, _Digits) + " Lotes: " + DoubleToString(lotes, 2));
         this.venta_abierta = true;
         this.operacion_abierta = true;
      } else {
         log_manager.Log("❌ Error: Fallo al abrir venta - Margen: " + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2));
      }
   }
}

void ReentradaRango::reset() {
   this.compra_abierta = false;
   this.venta_abierta = false;
   this.break_even_compra = false;
   this.break_even_venta = false;
   this.operacion_abierta = false;
}

void ReentradaRango::pintar(int hora_inicio, int hora_final) {
   datetime d_inicio = get_datetime_by_hour(hora_inicio);
   datetime d_final = get_datetime_by_hour(hora_final);
   string inicio_name = "inicio-time-" + IntegerToString(TimeGMT());
   ObjectDelete(0, inicio_name);
   ObjectCreate(0, inicio_name, OBJ_VLINE, 0, d_inicio, 0);
   ObjectSetInteger(0, inicio_name, OBJPROP_COLOR, COLOR_LINEAS);
   ObjectSetInteger(0, inicio_name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, inicio_name, OBJPROP_FILL, true);
   string final_name = "final-time-" + IntegerToString(TimeGMT());
   ObjectDelete(0, final_name);
   ObjectCreate(0, final_name, OBJ_VLINE, 0, d_final, 0);
   ObjectSetInteger(0, final_name, OBJPROP_COLOR, COLOR_LINEAS);
   ObjectSetInteger(0, final_name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, final_name, OBJPROP_FILL, true);
}

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "Recogida de Datos (Horario GMT)"
input int HORA_INICIO_RECOGIDA = 7;  // Hora inicio (GMT)
input int HORA_FINAL_RECOGIDA = 14;  // Hora final (GMT)
input group "Horario Operaciones (GMT)"
input int HORA_INICIO_OPERACIONES = 16; // Hora inicio (GMT)
input int HORA_FINAL_OPERACIONES = 21;  // Hora final (GMT)
input group "Riesgo"
input double LOTE_FIJO = 2.0;          // Lote inicial fijo
input bool USAR_MULTIPLICADOR = true; // Activar/desactivar multiplicador
input double MULTIPLICADOR_LOTES = 1.7;// Multiplicador de lotes
input double LOTE_MAXIMO = 3.4;        // Lote máximo
input int PUNTOS_SL = 8000;            // Stop loss (puntos gráficos)
input int PUNTOS_TP = 15000;           // Take profit (puntos gráficos)
input group "Trailing Stop"
input bool USAR_TRAILING_STOP = true;  // Activar/desactivar trailing stop
input int PUNTOS_ACTIVACION_TRAILING = 4000; // Puntos para activar trailing stop
input int PASO_TRAILING_STOP = 4000;   // Paso para ajustar trailing stop
input group "Break Even"
input bool USAR_BREAK_EVEN = false;     // Activar/desactivar break even
input int PUNTOS_ACTIVACION_BREAK_EVEN = 8000; // Puntos para activar break even
input group "Gestión de Cuenta (FTMO)"
input bool USAR_OBJETIVO_SALDO = false; // Activar/desactivar objetivo de saldo
input double OBJETIVO_SALDO = 11000.0; // Saldo objetivo (USD)
input double SALDO_MINIMO_OPERATIVO = 9050.0; // Saldo mínimo (USD)
input double PERDIDA_DIARIA_MAXIMA = 500.0;   // Pérdida diaria máxima (USD)
input double FACTOR_CINTURON_SEGURIDAD = 0.50;// Factor de seguridad (0.0 a 1.0)
input group "Visualización"
input color COLOR_RECTANGULO = clrWhite;// Color del rectángulo de rango
input color COLOR_LINEAS = clrRed;      // Color de las líneas de tiempo

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
bool timer_set = false;
bool trading_desactivado = false;
double saldo_inicio_dia;
datetime ultimo_reset_diario = 0;
double perdida_realizada = 0.0;
double limite_perdida_diaria_efectiva;
bool objetivo_alcanzado_mostrado = false;

CMultiplierManager lot_multiplier(LOTE_FIJO, MULTIPLICADOR_LOTES, LOTE_MAXIMO, USAR_MULTIPLICADOR);
Liquidez l;
ReentradaRango r;

//+------------------------------------------------------------------+
//| Utility Functions                                                |
//+------------------------------------------------------------------+
int segundos_hasta_inicio_operaciones() {
   MqlDateTime time;
   TimeGMT(time);
   time.hour = HORA_INICIO_OPERACIONES;
   time.min = 0; time.sec = 0;
   datetime time_inicio = StructToTime(time);
   datetime current_time = TimeGMT();
   return (int)(time_inicio + (current_time < time_inicio ? 0 : 24*3600) - current_time);
}

double get_max(double &values[]) {
   double result = -1;
   for (int i = 0; i < ArraySize(values); i++) {
      if (values[i] > result) result = values[i];
   }
   return result;
}

double get_min(double &values[]) {
   double result = INT_MAX;
   for (int i = 0; i < ArraySize(values); i++) {
      if (values[i] < result) result = values[i];
   }
   return result;
}

datetime get_datetime_by_hour(int hour) {
   MqlDateTime time;
   TimeGMT(time);
   time.hour = hour;
   time.min = 0; time.sec = 0;
   return StructToTime(time);
}

void verificar_reset_diario() {
   datetime utc_time = TimeGMT();
   MqlDateTime utc_struct;
   TimeToStruct(utc_time, utc_struct);
   int hour_offset = (utc_struct.mon >= 3 && utc_struct.mon <= 10) ? 2 : 1;
   datetime hora_espanola = utc_time + hour_offset * 3600;
   MqlDateTime hora_espanola_struct;
   TimeToStruct(hora_espanola, hora_espanola_struct);
   if (hora_espanola_struct.hour == 0 && hora_espanola_struct.min == 0 && utc_time > ultimo_reset_diario + 60) {
      saldo_inicio_dia = AccountInfoDouble(ACCOUNT_BALANCE);
      ultimo_reset_diario = utc_time;
      perdida_realizada = 0.0;
      trading_desactivado = false;
      objetivo_alcanzado_mostrado = false;
      r.reset();
      log_manager.Log("🔄 Reset Diario - Saldo: " + DoubleToString(saldo_inicio_dia, 2) + " USD");
   }
}

double calcular_perdida_diaria_total() {
   double saldo_actual = AccountInfoDouble(ACCOUNT_BALANCE);
   double perdida_flotante = 0.0;
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         perdida_flotante += PositionGetDouble(POSITION_PROFIT);
      }
   }
   perdida_realizada = saldo_actual - saldo_inicio_dia;
   return perdida_realizada + perdida_flotante;
}

void cerrar_todas_posiciones() {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         double beneficio = PositionGetDouble(POSITION_PROFIT);
         if (trade.PositionClose(ticket, -1)) {
            log_manager.Log("🛑 Posición Cerrada - Ticket: " + IntegerToString(ticket) + " Beneficio: " + DoubleToString(beneficio, 2) + " USD");
            lot_multiplier.UpdateLotSize(beneficio > 0);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trailing Stop and Break Even                                     |
//+------------------------------------------------------------------+
void gestionar_trailing_stop() {
   if (!USAR_BREAK_EVEN && !USAR_TRAILING_STOP) return;
   double precio_actual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         ENUM_POSITION_TYPE tipo_posicion = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double precio_apertura = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl_actual = PositionGetDouble(POSITION_SL);
         double puntos_beneficio = 0.0;
         if (tipo_posicion == POSITION_TYPE_BUY) {
            puntos_beneficio = (precio_actual - precio_apertura) / _Point;
            if (USAR_BREAK_EVEN && !r.break_even_compra && puntos_beneficio >= PUNTOS_ACTIVACION_BREAK_EVEN) {
               double nuevo_sl = precio_apertura;
               if (sl_actual < nuevo_sl) {
                  if (trade.PositionModify(ticket, nuevo_sl, PositionGetDouble(POSITION_TP))) {
                     log_manager.Log("🔄 Break Even Activado - Ticket: " + IntegerToString(ticket) + " SL: " + DoubleToString(nuevo_sl, _Digits));
                     r.break_even_compra = true;
                  }
               }
            }
            if (USAR_TRAILING_STOP && puntos_beneficio >= PUNTOS_ACTIVACION_TRAILING) {
               double nuevo_sl = precio_actual - PASO_TRAILING_STOP * _Point;
               if (sl_actual < nuevo_sl) {
                  if (trade.PositionModify(ticket, nuevo_sl, PositionGetDouble(POSITION_TP))) {
                     log_manager.Log("🔄 Trailing Stop Ajustado - Ticket: " + IntegerToString(ticket) + " SL: " + DoubleToString(nuevo_sl, _Digits));
                  }
               }
            }
         } else if (tipo_posicion == POSITION_TYPE_SELL) {
            puntos_beneficio = (precio_apertura - precio_actual) / _Point;
            if (USAR_BREAK_EVEN && !r.break_even_venta && puntos_beneficio >= PUNTOS_ACTIVACION_BREAK_EVEN) {
               double nuevo_sl = precio_apertura;
               if (sl_actual == 0 || sl_actual > nuevo_sl) {
                  if (trade.PositionModify(ticket, nuevo_sl, PositionGetDouble(POSITION_TP))) {
                     log_manager.Log("🔄 Break Even Activado - Ticket: " + IntegerToString(ticket) + " SL: " + DoubleToString(nuevo_sl, _Digits));
                     r.break_even_venta = true;
                  }
               }
            }
            if (USAR_TRAILING_STOP && puntos_beneficio >= PUNTOS_ACTIVACION_TRAILING) {
               double nuevo_sl = precio_actual + PASO_TRAILING_STOP * _Point;
               if (sl_actual == 0 || sl_actual > nuevo_sl) {
                  if (trade.PositionModify(ticket, nuevo_sl, PositionGetDouble(POSITION_TP))) {
                     log_manager.Log("🔄 Trailing Stop Ajustado - Ticket: " + IntegerToString(ticket) + " SL: " + DoubleToString(nuevo_sl, _Digits));
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert Advisor Functions                                         |
//+------------------------------------------------------------------+
int OnInit() {
   log_manager.Log("🚀 Iniciando EA - Símbolo: " + _Symbol);
   string simbolo = _Symbol;
   StringToLower(simbolo);
   if (StringFind(simbolo, "us500") < 0 && StringFind(simbolo, "us100") < 0 &&
       StringFind(simbolo, "us2000") < 0 && StringFind(simbolo, "us30") < 0 &&
       StringFind(simbolo, "spx500") < 0 && StringFind(simbolo, "nas100") < 0 &&
       StringFind(simbolo, "dji30") < 0) {
      log_manager.Log("❌ Error: Solo índices soportados (US500, US100, US30, etc.)");
      return INIT_PARAMETERS_INCORRECT;
   }
   if (FACTOR_CINTURON_SEGURIDAD <= 0.0 || FACTOR_CINTURON_SEGURIDAD > 1.0) {
      log_manager.Log("⚠️ Factor de seguridad inválido - Usando 0.5");
      limite_perdida_diaria_efectiva = PERDIDA_DIARIA_MAXIMA * 0.5;
   } else {
      limite_perdida_diaria_efectiva = PERDIDA_DIARIA_MAXIMA * FACTOR_CINTURON_SEGURIDAD;
   }
   saldo_inicio_dia = AccountInfoDouble(ACCOUNT_BALANCE);
   ultimo_reset_diario = TimeGMT();
   perdida_realizada = 0.0;
   trading_desactivado = false;
   EventSetTimer(segundos_hasta_inicio_operaciones());
   r.reset();
   log_manager.Log("✅ Inicio Completado - Saldo: " + DoubleToString(saldo_inicio_dia, 2) + " USD");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   log_manager.Log("🏁 EA Finalizado");
}

void OnTimer() {
   if (!timer_set) {
      EventKillTimer();
      EventSetTimer(60);
      timer_set = true;
   }
   verificar_reset_diario();
   if (trading_desactivado) {
      if (!objetivo_alcanzado_mostrado) {
         log_manager.Log("🚫 Trading Desactivado hasta 00:00 (España)");
         objetivo_alcanzado_mostrado = true;
      }
      cerrar_todas_posiciones();
      return;
   }
   double equity_actual = AccountInfoDouble(ACCOUNT_EQUITY);
   double saldo_actual = AccountInfoDouble(ACCOUNT_BALANCE);
   if (USAR_OBJETIVO_SALDO && OBJETIVO_SALDO > 0 && equity_actual >= OBJETIVO_SALDO) {
      cerrar_todas_posiciones();
      trading_desactivado = true;
      log_manager.Log("🎯 Objetivo Alcanzado - Equidad: " + DoubleToString(equity_actual, 2) + " USD");
      return;
   }
   if (equity_actual < SALDO_MINIMO_OPERATIVO || saldo_actual < SALDO_MINIMO_OPERATIVO) {
      cerrar_todas_posiciones();
      trading_desactivado = true;
      log_manager.Log("🚫 Saldo Mínimo Alcanzado - Equidad: " + DoubleToString(equity_actual, 2) + " USD");
      return;
   }
   double perdida_diaria_total = calcular_perdida_diaria_total();
   if (perdida_diaria_total <= -limite_perdida_diaria_efectiva) {
      cerrar_todas_posiciones();
      trading_desactivado = true;
      log_manager.Log("🚫 Pérdida Diaria Máxima - Pérdida: " + DoubleToString(perdida_diaria_total, 2) + " USD");
      return;
   }
   MqlDateTime time;
   TimeGMT(time);
   if (time.day_of_week == 0 || time.day_of_week == 6) {
      log_manager.Log("📅 Fin de Semana - No Operativo");
      return;
   }
   if (time.hour == HORA_FINAL_RECOGIDA && time.min == 0) {
      r.reset();
      l.get_max_min(HORA_INICIO_RECOGIDA, HORA_FINAL_RECOGIDA);
      l.pintar(HORA_INICIO_RECOGIDA, HORA_FINAL_RECOGIDA);
      r.pintar(HORA_INICIO_OPERACIONES, HORA_FINAL_OPERACIONES);
   }
}

void OnTick() {
   if (!trading_desactivado) {
      r.operar(HORA_INICIO_OPERACIONES, HORA_FINAL_OPERACIONES, PUNTOS_SL, PUNTOS_TP, l);
      gestionar_trailing_stop();
   }
}

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result) {
   if (trans.symbol != _Symbol) return;
   if (trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      if (HistoryDealSelect(trans.deal)) {
         if (HistoryDealGetString(trans.deal, DEAL_SYMBOL) == _Symbol &&
             HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
            double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
            lot_multiplier.UpdateLotSize(profit > 0);
            log_manager.Log("🛑 Posición Cerrada - Beneficio: " + DoubleToString(profit, 2) + " USD");
            if (HistoryDealGetInteger(trans.deal, DEAL_TYPE) == DEAL_TYPE_BUY) {
               r.compra_abierta = false;
            } else if (HistoryDealGetInteger(trans.deal, DEAL_TYPE) == DEAL_TYPE_SELL) {
               r.venta_abierta = false;
            }
         }
      }
   }
}
//+------------------------------------------------------------------+