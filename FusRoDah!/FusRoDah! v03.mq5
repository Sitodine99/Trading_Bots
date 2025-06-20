//+------------------------------------------------------------------+
//|                                                FusRoDah! v03.mq5 |
//|                   Copyright 2025, Jose Antonio Montero Fernández |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Jose Antonio Montero Fernández"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| Class CMultiplierManager                                         |
//+------------------------------------------------------------------+
class CMultiplierManager {
private:
   double m_initial_lot;       // Tamaño de lote inicial
   double m_multiplier;        // Factor de multiplicación
   double m_max_lot;           // Tamaño máximo de lote
   double m_current_lot;       // Tamaño de lote actual
   int    m_winning_trades;    // Contador de operaciones ganadoras consecutivas
   bool   m_use_multiplier;    // Activar/desactivar multiplicador

public:
   // Constructor
   CMultiplierManager(double initial_lot, double multiplier, double max_lot, bool use_multiplier) {
      m_initial_lot = initial_lot;
      m_multiplier = multiplier;
      m_max_lot = max_lot;
      m_use_multiplier = use_multiplier;
      m_current_lot = initial_lot;
      m_winning_trades = 0;
   }

   // Obtener tamaño de lote actual
   double GetCurrentLot() const {
      return m_current_lot;
   }

   // Normalizar tamaño de lote según especificaciones del broker
   double NormalizeLotSize(double lot) {
      double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double normalized_lot = MathRound(lot / lot_step) * lot_step;
      normalized_lot = MathMax(min_lot, MathMin(max_lot, normalized_lot));
      int digits = (int)-MathLog10(lot_step);
      return NormalizeDouble(normalized_lot, digits);
   }

   // Actualizar tamaño de lote tras cerrar una posición
   void UpdateLotSize(bool was_winning) {
      if (!m_use_multiplier) {
         m_current_lot = m_initial_lot;
         return;
      }

      if (was_winning) {
         m_winning_trades++;
         m_current_lot = m_initial_lot * MathPow(m_multiplier, m_winning_trades);
         if (m_current_lot > m_max_lot) {
            m_current_lot = m_max_lot;
            Print("📈 Lotes Máximos Alcanzados: ", DoubleToString(m_current_lot, 2));
         } else {
            Print("📈 Operación Ganadora | Lotes Aumentados: ", DoubleToString(m_current_lot, 2));
         }
      } else {
         m_winning_trades = 0;
         m_current_lot = m_initial_lot;
         Print("📉 Operación Perdedora | Lotes Restablecidos: ", DoubleToString(m_current_lot, 2));
      }
      m_current_lot = NormalizeLotSize(m_current_lot);
   }
};

// Input parameters
input group "Riesgo"
input double LOTE_FIJO = 1.0; // Lote fijo inicial para las operaciones
input bool USAR_MULTIPLICADOR = false; // Activar/desactivar multiplicador de lotes para rachas ganadoras
input double MULTIPLICADOR_LOTES = 2.0; // Multiplicador de lotes para rachas ganadoras (2.0 = duplicar)
input double LOTE_MAXIMO = 4.8; // Lote máximo permitido con el multiplicador
input group "Configuración Gráfico"
input ENUM_TIMEFRAMES PERIODO = PERIOD_H1; // Periodo (Solo H1 o M30 permitido)
input color COLOR_RECTANGULO = clrBlue; // Color rectángulo
input group "Recogida de Datos (Horario Servidor)"
input double HORA_INICIAL_RANGO1 = 3.0;  // Hora inicial Rango 1 
input double HORA_FINAL_RANGO1 = 9.0;    // Hora final Rango 1 
input double HORA_INICIAL_RANGO2 = 14.0; // Hora inicial Rango 2 
input double HORA_FINAL_RANGO2 = 17.0;   // Hora final Rango 2 
input group "Configuración Operaciones"
input int PUNTOS_SL = 18000;      // Stop loss (puntos gráficos)
input int PUNTOS_TP = 16000;      // Take profit (puntos gráficos)
input int HORAS_EXPIRACION = 6;   // Horas expiración (órdenes pendientes expiran tras 6 horas)
input bool USAR_TRAILING_STOP = true; // Activar/desactivar Trailing Stop
input int PUNTOS_ACTIVACION_TRAILING = 6000; // Puntos de beneficio para activar trailing stop
input int PASO_TRAILING_STOP = 1500; // Paso en puntos para ajustar el trailing stop
input bool PERMITIR_OPERACIONES_MULTIPLES = false; // Permitir múltiples operaciones simultáneas
input int MAX_POSICIONES = 2; // Máximo número de posiciones abiertas simultáneamente
input group "Gestión de Cuenta (FTMO y Similares)"
input bool USAR_OBJETIVO_SALDO = true; // Activar/desactivar objetivo de saldo
input double OBJETIVO_SALDO = 11000.0; // Saldo objetivo para cerrar el bot (USD)
input double SALDO_MINIMO_OPERATIVO = 9000.0; // Saldo mínimo operativo (USD)
input double PERDIDA_DIARIA_MAXIMA = 500.0; // Pérdida diaria máxima permitida (USD)
input double FACTOR_CINTURON_SEGURIDAD = 0.95; // Factor de cinturón de seguridad (0.0 a 1.0)

// Global variables
datetime ultima_barra;                // Control de nueva barra
bool trading_desactivado = false;     // Indica si el trading está desactivado por pérdida diaria
double saldo_inicio_dia;              // Saldo al inicio del día
datetime ultimo_reset_diario;         // Último reseteo diario
double perdida_realizada = 0.0;       // Pérdida realizada del día
double limite_perdida_diaria_efectiva;// Límite de pérdida diaria con cinturón de seguridad
int paso_trailing_stop;               // Variable global para el paso del trailing stop
datetime ultimo_rango_formado = 0;    // Último momento en que se formó un rango
bool objetivo_alcanzado_mostrado = false; // Control para mensajes críticos
bool inicializado = false;            // Control para evitar logs duplicados en OnInit
bool rango_formado_rango1 = false;    // Control para Rango 1
bool rango_formado_rango2 = false;    // Control para Rango 2
CMultiplierManager lot_multiplier(LOTE_FIJO, MULTIPLICADOR_LOTES, LOTE_MAXIMO, USAR_MULTIPLICADOR); // Gestor de multiplicador

// Structure for max/min values
struct MaxMin {
   double max;
   double min;
   datetime tiempo_inicio;
   datetime tiempo_final;
};

//+------------------------------------------------------------------+
//| Class RangeBreakout                                              |
//+------------------------------------------------------------------+
class RangeBreakout {
private:
   void operativa(double hora_inicial, double hora_final, bool &rango_formado);
   // Detectar si estamos en modo backtest
   bool es_backtest() {
      return MQLInfoInteger(MQL_TESTER) > 0;
   }
   // Convertir hora decimal (p. ej., 10.5) en horas y minutos
   void convertir_hora_decimal(double hora_decimal, int &horas, int &minutos) {
      horas = (int)hora_decimal;
      double fraccion = hora_decimal - horas;
      if (fraccion == 0.0) {
         minutos = 0; // Hora redonda (ej. 10.0 -> 10:00)
      } else if (fraccion == 0.5) {
         minutos = 30; // Media hora (ej. 10.5 -> 10:30)
      } else {
         Print("❌ Error: Hora inválida. Solo se permiten horas redondas (ej. 10.0) o medias horas (ej. 10.5).");
         minutos = 0; // Por defecto, para evitar errores
      }
   }
   int segundos_hasta_hora_servidor(double hora, int sec = 0) {
      int horas, minutos;
      convertir_hora_decimal(hora, horas, minutos);
      MqlDateTime mqldt;
      TimeCurrent(mqldt);
      mqldt.hour = horas;
      mqldt.min = minutos;
      mqldt.sec = sec;
      datetime dt = StructToTime(mqldt);
      datetime dt_actual = TimeCurrent();
      int seconds = (int)(dt - dt_actual);
      if (seconds < 0) {
         seconds += 24 * 3600;
      }
      return seconds;
   }
   double get_max(double &valores[]) {
      double resultado = 0;
      for (int i = 0; i < ArraySize(valores); i++) {
         if (resultado < valores[i]) {
            resultado = valores[i];
         }
      }
      return resultado;
   }
   double get_min(double &valores[]) {
      double resultado = INT_MAX;
      for (int i = 0; i < ArraySize(valores); i++) {
         if (resultado > valores[i]) {
            resultado = valores[i];
         }
      }
      return resultado;
   }
   MaxMin obtener_maxmin(string simbolo, ENUM_TIMEFRAMES periodo, double hora_inicial, double hora_final) {
      MaxMin resultado;
      MqlDateTime mqldt_i, mqldt_f;
      TimeCurrent(mqldt_i);
      TimeCurrent(mqldt_f);
      int horas_i, minutos_i, horas_f, minutos_f;
      convertir_hora_decimal(hora_inicial, horas_i, minutos_i);
      convertir_hora_decimal(hora_final, horas_f, minutos_f);
      mqldt_i.hour = horas_i;
      mqldt_i.min = minutos_i;
      mqldt_i.sec = 0;
      mqldt_f.hour = horas_f;
      mqldt_f.min = minutos_f;
      mqldt_f.sec = 0;
      datetime dt_i = StructToTime(mqldt_i);
      datetime dt_f = StructToTime(mqldt_f);
      if (hora_inicial >= hora_final) {
         dt_i -= 24 * 3600;
      }
      resultado.tiempo_inicio = dt_i;
      resultado.tiempo_final = dt_f;
      MqlRates rates[];
      int copied = CopyRates(simbolo, periodo, dt_i, dt_f, rates);
      if (copied <= 0) {
         Print("❌ Error: No se pudieron obtener datos de velas para ", simbolo, " entre ", TimeToString(dt_i), " y ", TimeToString(dt_f));
         resultado.max = 0;
         resultado.min = 0;
         return resultado;
      }
      double highs[], lows[];
      ArrayResize(highs, copied);
      ArrayResize(lows, copied);
      for (int i = 0; i < copied; i++) {
         highs[i] = rates[i].high;
         lows[i] = rates[i].low;
      }
      resultado.max = get_max(highs);
      resultado.min = get_min(lows);
      if (resultado.max <= resultado.min || resultado.max == 0 || resultado.min == 0) {
         Print("❌ Error: Rango inválido para ", simbolo, ": Máximo = ", DoubleToString(resultado.max, _Digits), ", Mínimo = ", DoubleToString(resultado.min, _Digits));
         resultado.max = 0;
         resultado.min = 0;
         return resultado;
      }
      Print("📊 Rango formado | Símbolo: ", simbolo, " | Máximo: ", DoubleToString(resultado.max, _Digits), " | Mínimo: ", DoubleToString(resultado.min, _Digits), " | Desde: ", TimeToString(dt_i), " | Hasta: ", TimeToString(dt_f));
      return resultado;
   }
   bool existen_ordenes_pendientes() {
      for (int i = OrdersTotal() - 1; i >= 0; i--) {
         ulong ticket = OrderGetTicket(i);
         if (OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL) == _Symbol) {
            return true;
         }
      }
      return false;
   }
   bool existen_posiciones_abiertas(int max_posiciones = 1) {
      int count = 0;
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            count++;
         }
      }
      return count >= max_posiciones;
   }
   bool validar_parametros_orden(double precio, double sl, double tp, double lotes, datetime expiration) {
      double min_stop_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if (MathAbs(precio - sl) < min_stop_level || MathAbs(precio - tp) < min_stop_level) {
         Print("❌ Error: SL/TP demasiado cerca. Nivel mínimo: ", DoubleToString(min_stop_level, _Digits));
         return false;
      }
      if (lotes < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) || lotes > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)) {
         Print("❌ Error: Volumen inválido: ", DoubleToString(lotes, 2));
         return false;
      }
      if (expiration <= TimeCurrent()) {
         Print("❌ Error: Tiempo de expiración inválido: ", TimeToString(expiration));
         return false;
      }
      return true;
   }
   void establecer_operaciones_pendientes(MaxMin &mm, double lotes, string simbolo, int puntos_sl, int puntos_tp, int horas_expiracion) {
      if (trading_desactivado) {
         Print("ℹ️ Info: Trading desactivado. No se colocan nuevas órdenes para ", simbolo);
         return;
      }
      if (lotes == 0) {
         Print("❌ Error: Volumen calculado es 0. No se pueden abrir operaciones.");
         return;
      }
      if (mm.max == 0 || mm.min == 0) {
         Print("❌ Error: Rango inválido, no se abren operaciones.");
         return;
      }
      // Verificar órdenes/posiciones según configuración
      if (!PERMITIR_OPERACIONES_MULTIPLES) {
         if (existen_ordenes_pendientes()) {
            Print("ℹ️ Info: Ya existen órdenes pendientes para ", simbolo, ". No se colocan nuevas.");
            return;
         }
         if (existen_posiciones_abiertas(1)) {
            Print("ℹ️ Info: Ya existen posiciones abiertas para ", simbolo, ". No se colocan nuevas órdenes.");
            return;
         }
      } else if (existen_posiciones_abiertas(MAX_POSICIONES)) {
         Print("ℹ️ Info: Límite de posiciones alcanzado para ", simbolo, ". No se colocan nuevas órdenes.");
         return;
      }
      datetime expiration = TimeCurrent() + horas_expiracion * 3600;
      // Usar BuyStop en el máximo y SellStop en el mínimo (estrategia de breakout)
      if (validar_parametros_orden(mm.max, mm.max - puntos_sl * _Point, mm.max + puntos_tp * _Point, lotes, expiration)) {
         if (!trade.BuyStop(
               lotes,
               mm.max,
               simbolo,
               mm.max - puntos_sl * _Point,
               mm.max + puntos_tp * _Point,
               ORDER_TIME_SPECIFIED,
               expiration,
               "BuyStop: Rango breakout"
            )) {
            Print("❌ Error: BuyStop falló para ", simbolo, " | Código: ", GetLastError());
         } else {
            Print("📈 BuyStop colocada | Símbolo: ", simbolo, " | Precio: ", DoubleToString(mm.max, _Digits), " | Volumen: ", DoubleToString(lotes, 2), " | Expira: ", TimeToString(expiration));
         }
      }
      if (validar_parametros_orden(mm.min, mm.min + puntos_sl * _Point, mm.min - puntos_tp * _Point, lotes, expiration)) {
         if (!trade.SellStop(
               lotes,
               mm.min,
               simbolo,
               mm.min + puntos_sl * _Point,
               mm.min - puntos_tp * _Point,
               ORDER_TIME_SPECIFIED,
               expiration,
               "SellStop: Rango breakout"
            )) {
            Print("❌ Error: SellStop falló para ", simbolo, " | Código: ", GetLastError());
         } else {
            Print("📉 SellStop colocada | Símbolo: ", simbolo, " | Precio: ", DoubleToString(mm.min, _Digits), " | Volumen: ", DoubleToString(lotes, 2), " | Expira: ", TimeToString(expiration));
         }
      }
   }
   void dibujar_maxmin(MaxMin &mm, color clr) {
      if (mm.max == 0 || mm.min == 0 || mm.tiempo_inicio == 0 || mm.tiempo_final == 0) {
         Print("❌ Error: No se puede dibujar rectángulo: Rango o fechas inválidas.");
         return;
      }
      string name = "rango-" + IntegerToString(TimeGMT());
      if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, mm.tiempo_inicio, mm.min, mm.tiempo_final, mm.max)) {
         Print("❌ Error: Fallo al crear rectángulo | Código: ", GetLastError());
         return;
      }
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
   }
   void verificar_reset_diario() {
      datetime utc_time = TimeGMT();
      MqlDateTime utc_struct;
      TimeToStruct(utc_time, utc_struct);
      int hour_offset = (utc_struct.mon >= 3 && utc_struct.mon <= 10) ? 2 : 1;
      datetime hora_espanola = utc_time + hour_offset * 3600;
      MqlDateTime hora_espanola_struct;
      TimeToStruct(hora_espanola, hora_espanola_struct);
      bool es_hora_reset = (hora_espanola_struct.hour == 0 && hora_espanola_struct.min == 0 && utc_time > ultimo_reset_diario + 60);
      if (es_hora_reset) {
         saldo_inicio_dia = AccountInfoDouble(ACCOUNT_BALANCE);
         ultimo_reset_diario = utc_time;
         perdida_realizada = 0.0;
         rango_formado_rango1 = false;
         rango_formado_rango2 = false;
         Print("🔄 Reset Diario Completado | Saldo: ", DoubleToString(saldo_inicio_dia, 2), " USD | Próximos rangos: Rango 1 a las 09:00, Rango 2 a las 17:00 (UTC+3)");
         if (trading_desactivado) {
            trading_desactivado = false;
            Print("✅ Trading Reactivado | Saldo: ", DoubleToString(saldo_inicio_dia, 2), " USD");
         }
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
      double perdida_total = perdida_realizada + perdida_flotante;
      return perdida_total;
   }
   void cerrar_todas_posiciones() {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double beneficio = PositionGetDouble(POSITION_PROFIT);
            if (trade.PositionClose(ticket, -1)) {
               Print("🛑 Posición Cerrada | Ticket: ", ticket, " | Motivo: Cierre masivo | Beneficio: ", DoubleToString(beneficio, 2), " USD");
               lot_multiplier.UpdateLotSize(beneficio > 0);
            } else {
               Print("❌ Error: No se pudo cerrar la posición ", ticket, " | Código: ", trade.ResultRetcodeDescription());
            }
         }
      }
   }
   void cerrar_todas_ordenes_pendientes() {
      int total_ordenes = OrdersTotal();
      int ordenes_eliminadas = 0;
      for (int i = total_ordenes - 1; i >= 0; i--) {
         ulong ticket = OrderGetTicket(i);
         if (OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL) == _Symbol) {
            if (trade.OrderDelete(ticket)) {
               ordenes_eliminadas++;
               Print("🗑️ Orden Pendiente Eliminada | Ticket: ", ticket, " | Motivo: Cierre masivo");
            } else {
               Print("❌ Error: No se pudo eliminar la orden pendiente ", ticket, " | Código: ", trade.ResultRetcodeDescription());
            }
         }
      }
      Print("📋 Resumen: ", ordenes_eliminadas, " de ", total_ordenes, " órdenes pendientes eliminadas.");
   }
   void gestionar_trailing_stop(ulong ticket, ENUM_POSITION_TYPE tipo_posicion, double precio_apertura, double precio_actual) {
      if (!USAR_TRAILING_STOP) return;
      double sl_actual = PositionGetDouble(POSITION_SL);
      double puntos_beneficio = 0.0;
      if (tipo_posicion == POSITION_TYPE_BUY) {
         puntos_beneficio = (precio_actual - precio_apertura) / _Point;
         if (puntos_beneficio >= PUNTOS_ACTIVACION_TRAILING) {
            double nuevo_sl = precio_actual - PASO_TRAILING_STOP * _Point;
            if (sl_actual < nuevo_sl) {
               if (trade.PositionModify(ticket, nuevo_sl, PositionGetDouble(POSITION_TP))) {
                  Print("🔄 Trailing Stop Ajustado | Ticket: ", ticket, " | Nuevo SL: ", DoubleToString(nuevo_sl, _Digits));
               }
            }
         }
      } else if (tipo_posicion == POSITION_TYPE_SELL) {
         puntos_beneficio = (precio_apertura - precio_actual) / _Point;
         if (puntos_beneficio >= PUNTOS_ACTIVACION_TRAILING) {
            double nuevo_sl = precio_actual + PASO_TRAILING_STOP * _Point;
            if (sl_actual == 0 || sl_actual > nuevo_sl) {
               if (trade.PositionModify(ticket, nuevo_sl, PositionGetDouble(POSITION_TP))) {
                  Print("🔄 Trailing Stop Ajustado | Ticket: ", ticket, " | Nuevo SL: ", DoubleToString(nuevo_sl, _Digits));
               }
            }
         }
      }
   }
   void verificar_condiciones_salida() {
      double precio_actual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            ENUM_POSITION_TYPE tipo_posicion = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double precio_apertura = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl_actual = PositionGetDouble(POSITION_SL);
            double tp_actual = PositionGetDouble(POSITION_TP);
            bool golpeo_sl = (tipo_posicion == POSITION_TYPE_BUY && precio_actual <= sl_actual) ||
                             (tipo_posicion == POSITION_TYPE_SELL && precio_actual >= sl_actual);
            bool golpeo_tp = (tipo_posicion == POSITION_TYPE_BUY && precio_actual >= tp_actual) ||
                             (tipo_posicion == POSITION_TYPE_SELL && precio_actual <= tp_actual);
            if (golpeo_sl || golpeo_tp) {
               double beneficio = PositionGetDouble(POSITION_PROFIT);
               string motivo = golpeo_sl ? "Stop Loss" : "Take Profit";
               if (trade.PositionClose(ticket, -1)) {
                  Print("🛑 Posición Cerrada | Ticket: ", ticket, " | Motivo: ", motivo, " | Beneficio: ", DoubleToString(beneficio, 2), " USD");
                  lot_multiplier.UpdateLotSize(beneficio > 0);
               } else {
                  Print("❌ Error: No se pudo cerrar la posición ", ticket, " | Código: ", trade.ResultRetcodeDescription());
               }
               continue;
            }
            if (USAR_TRAILING_STOP) {
               gestionar_trailing_stop(ticket, tipo_posicion, precio_apertura, precio_actual);
            }
         }
      }
   }

public:
   int OnInit() {
      Print("🚀 Iniciando FusRoDah!...");
      Print("ℹ️ Nota: El bot solo opera en H1 o M30. Las horas de los rangos deben ser redondas (ej. 10.0) o medias horas (ej. 10.5).");
      // Validar periodo
      if (PERIODO != PERIOD_H1 && PERIODO != PERIOD_M30) {
         Print("❌ Error: Periodo inválido. Solo se permiten H1 o M30.");
         return INIT_PARAMETERS_INCORRECT;
      }
      // Validar horas de los rangos
      double horas[] = {HORA_INICIAL_RANGO1, HORA_FINAL_RANGO1, HORA_INICIAL_RANGO2, HORA_FINAL_RANGO2};
      for (int i = 0; i < ArraySize(horas); i++) {
         double fraccion = horas[i] - (int)horas[i];
         if (fraccion != 0.0 && fraccion != 0.5) {
            Print("❌ Error: Hora inválida en rango ", i + 1, ". Solo se permiten horas redondas (ej. 10.0) o medias horas (ej. 10.5).");
            return INIT_PARAMETERS_INCORRECT;
         }
         if (horas[i] < 0 || horas[i] >= 24) {
            Print("❌ Error: Hora inválida en rango ", i + 1, ". Deben estar entre 0 y 23.999.");
            return INIT_PARAMETERS_INCORRECT;
         }
      }
      if (FACTOR_CINTURON_SEGURIDAD <= 0.0 || FACTOR_CINTURON_SEGURIDAD > 1.0) {
         Print("❌ Error: Factor de cinturón de seguridad inválido. Usando 0.95 por defecto");
         limite_perdida_diaria_efectiva = PERDIDA_DIARIA_MAXIMA * 0.95;
      } else {
         limite_perdida_diaria_efectiva = PERDIDA_DIARIA_MAXIMA * FACTOR_CINTURON_SEGURIDAD;
      }
      Print("⚙️ Inicialización Completa | Límite de Pérdida Diaria: ", DoubleToString(limite_perdida_diaria_efectiva, 2), " USD");
      if (PUNTOS_ACTIVACION_TRAILING <= 0) {
         Print("❌ Error: Puntos de activación del trailing stop deben ser mayores que 0");
         return INIT_PARAMETERS_INCORRECT;
      }
      if (PASO_TRAILING_STOP <= 0) {
         Print("❌ Error: Paso del trailing stop debe ser mayor que 0. Usando 10 por defecto");
         paso_trailing_stop = 10;
      } else {
         paso_trailing_stop = PASO_TRAILING_STOP;
      }
      string simbolo = _Symbol;
      StringToLower(simbolo);
      if (StringFind(simbolo, "us500") < 0 && StringFind(simbolo, "us100") < 0 &&
          StringFind(simbolo, "us2000") < 0 && StringFind(simbolo, "us30") < 0 &&
          StringFind(simbolo, "spx500") < 0 && StringFind(simbolo, "nas100") < 0 &&
          StringFind(simbolo, "dji30") < 0) {
         Print("❌ Error: Símbolo no soportado. Solo índices: US500, US100, US2000, US30");
         return INIT_PARAMETERS_INCORRECT;
      }
      Print("📊 Símbolo: ", _Symbol, " | Spread: ", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), " puntos");
      saldo_inicio_dia = AccountInfoDouble(ACCOUNT_BALANCE);
      ultimo_reset_diario = TimeCurrent();
      perdida_realizada = 0.0;
      trading_desactivado = false;
      rango_formado_rango1 = false;
      rango_formado_rango2 = false;
      ultimo_rango_formado = 0;

      Print("✅ Bot Inicializado | Esperando próximo rango...");
      EventSetTimer(60);
      inicializado = true;
      return INIT_SUCCEEDED;
   }
   void OnDeinit(const int reason) {
      Print("🏁 Bot Finalizado | ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS));
      inicializado = false;
   }
   void OnTimer() {
      verificar_reset_diario();
      if (trading_desactivado) {
         cerrar_todas_ordenes_pendientes();
         if (!objetivo_alcanzado_mostrado) {
            Print("🚫 Trading Desactivado | Reanudará a las 00:00 (España)");
            objetivo_alcanzado_mostrado = true;
         }
         return;
      }
      double equity_actual = AccountInfoDouble(ACCOUNT_EQUITY);
      double saldo_actual = AccountInfoDouble(ACCOUNT_BALANCE);
      if (USAR_OBJETIVO_SALDO && OBJETIVO_SALDO > 0 && equity_actual >= OBJETIVO_SALDO) {
         cerrar_todas_posiciones();
         cerrar_todas_ordenes_pendientes();
         trading_desactivado = true;
         Print("🎯 Objetivo Alcanzado | Equidad: ", DoubleToString(equity_actual, 2), " USD");
         return;
      }
      if (equity_actual < SALDO_MINIMO_OPERATIVO || saldo_actual < SALDO_MINIMO_OPERATIVO) {
         cerrar_todas_posiciones();
         cerrar_todas_ordenes_pendientes();
         trading_desactivado = true;
         Print("🚫 Parada por Equidad/Saldo Baja | Equidad: ", DoubleToString(equity_actual, 2), " | Saldo: ", DoubleToString(saldo_actual, 2), " | Mínimo: ", DoubleToString(SALDO_MINIMO_OPERATIVO, 2));
         return;
      }
      double perdida_diaria_total = calcular_perdida_diaria_total();
      if (perdida_diaria_total <= -limite_perdida_diaria_efectiva) {
         cerrar_todas_posiciones();
         cerrar_todas_ordenes_pendientes();
         trading_desactivado = true;
         Print("🚫 Límite de Pérdida Diaria Alcanzado | Pérdida: ", DoubleToString(perdida_diaria_total, 2), " USD");
         return;
      }
      verificar_condiciones_salida();
      MqlDateTime hora_actual;
      TimeCurrent(hora_actual);
      datetime hora_actual_dt = TimeCurrent();
      // Rango 1
      int horas_f1, minutos_f1;
      convertir_hora_decimal(HORA_FINAL_RANGO1, horas_f1, minutos_f1);
      if (hora_actual.hour == horas_f1 && hora_actual.min == minutos_f1 && !rango_formado_rango1) {
         if (hora_actual_dt > ultimo_rango_formado + 60) {
            ultimo_rango_formado = hora_actual_dt;
            rango_formado_rango1 = true;
            Print("🌅 Iniciando Rango 1 | Hora: ", horas_f1, ":", minutos_f1 < 10 ? "0" : "", minutos_f1);
            operativa(HORA_INICIAL_RANGO1, HORA_FINAL_RANGO1, rango_formado_rango1);
         }
      }
      // Rango 2
      int horas_f2, minutos_f2;
      convertir_hora_decimal(HORA_FINAL_RANGO2, horas_f2, minutos_f2);
      if (hora_actual.hour == horas_f2 && hora_actual.min == minutos_f2 && !rango_formado_rango2) {
         if (hora_actual_dt > ultimo_rango_formado + 60) {
            ultimo_rango_formado = hora_actual_dt;
            rango_formado_rango2 = true;
            Print("🌇 Iniciando Rango 2 | Hora: ", horas_f2, ":", minutos_f2 < 10 ? "0" : "", minutos_f2);
            operativa(HORA_INICIAL_RANGO2, HORA_FINAL_RANGO2, rango_formado_rango2);
         }
      }
   }
   void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result) {
      if (trans.symbol != _Symbol) return;

      if (trans.type == TRADE_TRANSACTION_ORDER_DELETE) {
         string motivo = "";
         bool log_eliminacion = true;
         if (HistoryOrderSelect(trans.order)) {
            ENUM_ORDER_STATE order_state = (ENUM_ORDER_STATE)HistoryOrderGetInteger(trans.order, ORDER_STATE);
            switch (order_state) {
               case ORDER_STATE_FILLED:
                  {
                     motivo = "Orden ejecutada (convertida en posición)";
                     log_eliminacion = false;
                  }
                  break;
               case ORDER_STATE_CANCELED:
                  {
                     motivo = "Cancelada";
                     long reason_code = HistoryOrderGetInteger(trans.order, ORDER_REASON);
                     motivo += " (Razón: " + EnumToString((ENUM_ORDER_REASON)reason_code) + ")";
                  }
                  break;
               case ORDER_STATE_REJECTED:
                  {
                     motivo = "Rechazada";
                     long reason_code = HistoryOrderGetInteger(trans.order, ORDER_REASON);
                     motivo += " (Razón: " + EnumToString((ENUM_ORDER_REASON)reason_code) + ")";
                  }
                  break;
               case ORDER_STATE_EXPIRED:
                  {
                     motivo = "Expirada";
                  }
                  break;
               default:
                  {
                     motivo = EnumToString(order_state);
                  }
                  break;
            }
         } else {
            motivo = "Motivo desconocido (no se pudo seleccionar la orden)";
         }
         if (log_eliminacion) {
            Print("⚠️ Orden Eliminada | Orden: ", trans.order, " | Motivo: ", motivo);
         }
      }
      else if (trans.type == TRADE_TRANSACTION_DEAL_ADD) {
         if (HistoryDealSelect(trans.deal)) {
            if (HistoryDealGetString(trans.deal, DEAL_SYMBOL) == _Symbol &&
                HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
               double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
               lot_multiplier.UpdateLotSize(profit > 0);
            }
         }
      }
   }
};

// Global instance
RangeBreakout rb;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
   return rb.OnInit();
}

//+------------------------------------------------------------------+
//| Deinitialization function                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   rb.OnDeinit(reason);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
   rb.OnTimer();
}

//+------------------------------------------------------------------+
//| Trade transaction function                                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result) {
   rb.OnTradeTransaction(trans, request, result);
}

//+------------------------------------------------------------------+
//| Main operative function                                          |
//+------------------------------------------------------------------+
void RangeBreakout::operativa(double hora_inicial, double hora_final, bool &rango_formado) {
   MaxMin mm = obtener_maxmin(_Symbol, PERIODO, hora_inicial, hora_final);
   if (mm.max != 0 && mm.min != 0) {
      dibujar_maxmin(mm, COLOR_RECTANGULO);
      double lotes = lot_multiplier.GetCurrentLot();
      establecer_operaciones_pendientes(mm, lotes, _Symbol, PUNTOS_SL, PUNTOS_TP, HORAS_EXPIRACION);
   } else {
      Print("❌ Error: No se pudo formar rango válido para ", _Symbol, ", operativa cancelada");
      rango_formado = false; // Permitir reintentos si falla la formación del rango
   }
}
//+------------------------------------------------------------------+