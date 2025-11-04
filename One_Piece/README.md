# One Piece 🤖 v1.03

![One Piece Logo](images/One_Piece_logo.png)

**One Piece** es un **Expert Advisor (EA)** para **MetaTrader 5**, diseñado para operar en **XAUUSD** en **cualquier marco temporal**, aunque ideal en H1. Automatiza entradas basadas en **rupturas de swing highs/lows** y **Market Structure Shifts (MSS)**, con confirmación opcional por cierre de vela. Incorpora gestión de riesgo avanzada —Stop Loss, Take Profit, Trailing Stop dinámico, límite de pérdida diaria con “safety belt”, reinicio diario, objetivo de balance y máximo de posiciones— optimizado para desafíos de fondeo como **FTMO**.

---

## 📌 Características Principales

- **Versión**: 1.03  
- **Símbolo exclusivo**: XAUUSD  
- **Detección de Swing Points**: identifica swing highs/lows en un periodo configurable (length=10 barras por defecto).  
- **Rupturas & MSS**:  
  - Señales de compra/venta al superar el último swing high/low.  
  - Detección de Market Structure Shift para distinguir rupturas en tendencia.  
  - Opción `ConfirmBreakoutWithClose` para requerir cierre de vela.  
- **Gestión de riesgo FTMO**:  
  - **Stop Loss** y **Take Profit** en puntos gráficos.  
  - **Trailing Stop** dinámico: activa tras `TrailingStopActivation` puntos y ajusta en pasos de `TrailingStopStep`.  
  - **Límite de pérdida diaria**: `MaxDailyLossFTMO` × `SafetyBeltFactor`; desactiva trading al alcanzarlo.  
  - **Reinicio diario** automático a las 00:00 (hora España).  
  - **Objetivo de balance** (`BalanceTarget`): cierra todo al lograrse y detiene el EA.  
  - **Saldo mínimo operativo** (`MinOperatingBalance`): detiene trading si el equity cae por debajo.  
- **Control de posiciones**: hasta `MaxPositions` abiertas simultáneamente.  
- **Validaciones**:  
  - Solo funciona en XAUUSD (falla en OnInit si el símbolo es distinto).  
  - Normaliza lote según restricciones del bróker.  
  - Verifica distancia mínima de SL/TP.  

---

## 🚀 Estrategia de Trading

1. **Swing Detection**  
   - Calcula swing highs/lows revisando `length` barras a ambos lados.  
   - Almacena los dos valores más recientes para confirmar MSS.  

2. **Señales de Compra**  
   - `Ask` supera el último **swing high** (o vela cierra por encima si está activo).  
   - Calcula SL = Ask − `SL_Points`·_Point, TP = Ask + `TP_Points`·_Point.  
   - Abre orden `Buy` con lote normalizado.  

3. **Señales de Venta**  
   - `Bid` rompe el último **swing low** (o vela cierra por debajo si está activo).  
   - Calcula SL = Bid + `SL_Points`·_Point, TP = Bid − `TP_Points`·_Point.  
   - Abre orden `Sell` con lote normalizado.  

4. **Market Structure Shift**  
   - Compara los dos últimos swing highs/lows para detectar un cambio de estructura.  
   - Dibuja flechas y líneas diferenciadas para rupturas MSS.  

5. **Trailing Stop**  
   - Si `UseTrailingStop==true`, ajusta SL tras `TrailingStopActivation` puntos de ganancia.  

---

## 🔧 Gestión de Operaciones y Riesgo

- **Stop Loss** (`SL_Points`) y **Take Profit** (`TP_Points`).  
- **Trailing Stop** (`UseTrailingStop`, `TrailingStopActivation`, `TrailingStopStep`).  
- **Límite de Pérdida Diaria** (`MaxDailyLossFTMO`, `SafetyBeltFactor`).  
- **Reinicio Diario**: reset de balance y pérdida realizada a las 00:00 España.  
- **Objetivo de Balance** (`BalanceTarget`, `UseBalanceTarget`).  
- **Saldo Mínimo** (`MinOperatingBalance`).  
- **Máximo de Posiciones** (`MaxPositions`).  
- **Normalización de lote** según `SYMBOL_VOLUME_STEP`, mínimo/máximo del bróker.  
- **Validación de SL/TP** contra `SYMBOL_TRADE_STOPS_LEVEL`.  

---

## 📊 Resultados de Simulación

Simulado en MetaTrader 5 con datos históricos de XAUUSD y parámetros optimizados para FTMO:  
– [Ver resultados y optimizaciones](Simulaciones%20y%20optimizaciones/README.md)

---

## ⚙ Instalación

1. Copia `One_Piece_v01.mq5` a `<MetaTrader5>\MQL5\Experts`.
2. Dentro de `One_Piece/`, crea la carpeta `images` y coloca `One_Piece_logo.png`.  
3. Abre MetaEditor, compila `One_Piece_v01.mq5`.  
4. En MT5, arrastra **One Piece** al gráfico **XAUUSD** (cualquier timeframe).  
5. Ajusta parámetros o usa valores por defecto.  
6. Activa trading automático.

---

## 🧾 Parámetros Configurables

| Parámetro                  | Descripción                                             | Por defecto |
|----------------------------|---------------------------------------------------------|-------------|
| `LotSize`                  | Tamaño de lote inicial (lotes)                          | 0.06        |
| `SL_Points`                | Stop Loss en puntos gráficos                            | 2860        |
| `TP_Points`                | Take Profit en puntos gráficos                          | 1690        |
| `MaxPositions`             | Máximo de posiciones abiertas simultáneas               | 1           |
| `UseTrailingStop`          | Activar Trailing Stop                                   | true        |
| `TrailingStopActivation`   | Puntos para activar Trailing Stop                       | 1500        |
| `TrailingStopStep`         | Paso del Trailing Stop en puntos                        | 800         |
| `ConfirmBreakoutWithClose` | Confirmar ruptura con cierre de vela                    | false       |
| `MaxDailyLossFTMO`         | Pérdida diaria máxima permitida (USD)                   | 500.0       |
| `SafetyBeltFactor`         | Factor de seguridad sobre la pérdida diaria (0.0–1.0)   | 0.95        |
| `MinOperatingBalance`      | Saldo mínimo operativo (USD)                            | 9050.0      |
| `UseBalanceTarget`         | Activar objetivo de balance                             | true        |
| `BalanceTarget`            | Meta de balance para cerrar el EA (USD)                 | 11000.0     |

---

## 📝 Notas de Uso

- Prueba siempre en **cuenta demo** antes de operar en real.  
- Ajusta parámetros con el **Strategy Tester** según tu bróker y condiciones de mercado.  
- El EA detecta cierres manuales y reajusta su lógica de MSS y lotes.  
- Diseñado para cumplir requisitos FTMO; adapta límites según otros proveedores de fondeo.

---

## 🪪 Licencia

© Jose Antonio Montero. Sujeto a los términos de la [MIT License](LICENSE.md).

