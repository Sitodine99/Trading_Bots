# One Piece 🤖 v1.03

![One Piece Logo](images/One_Piece_logo.png)

**One Piece** es un **Expert Advisor (EA)** para **MetaTrader 5**, diseñado para operar en **XAUUSD** en **cualquier marco temporal**, aunque ideal en H1. Automatiza entradas basadas en **rupturas de swing highs/lows** y **Market Structure Shifts (MSS)**, con confirmación opcional por cierre de vela. Incorpora gestión de riesgo avanzada —Stop Loss, Take Profit, Trailing Stop dinámico, límite de pérdida diaria con “safety belt”, reinicio diario, objetivo de balance, máximo de posiciones y **escalado automático de lote por equity**— optimizado para desafíos de fondeo como **FTMO**.

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
- **Escalado automático de lote**: incrementa el lote base en pasos fijos según la equity de la cuenta (ver tabla de parámetros).  
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
   - Abre orden `Buy` con lote normalizado (según escalado automático vigente).  

3. **Señales de Venta**  
   - `Bid` rompe el último **swing low** (o vela cierra por debajo si está activo).  
   - Calcula SL = Bid + `SL_Points`·_Point, TP = Bid − `TP_Points`·_Point.  
   - Abre orden `Sell` con lote normalizado (según escalado automático vigente).  

4. **Market Structure Shift**  
   - Compara los dos últimos swing highs/lows para detectar un cambio de estructura.  
   - Dibuja flechas y líneas diferenciadas para rupturas MSS.  

5. **Trailing Stop**  
   - Si `UseTrailingStop==true`, ajusta SL tras `TrailingStopActivation` puntos de ganancia.  

6. **Escalado de Lote**  
   - Tras cada cierre de posición, recalcula el lote base según la equity actual: `MinLotSize` desde `ScalingBaseEquity`, +`ScalingLotStep` por cada `ScalingEquityStep` adicional de equity, hasta el tope `MaxContractSize`.  

---

## 🔧 Gestión de Operaciones y Riesgo

- **Stop Loss** (`SL_Points`) y **Take Profit** (`TP_Points`).  
- **Trailing Stop** (`UseTrailingStop`, `TrailingStopActivation`, `TrailingStopStep`).  
- **Límite de Pérdida Diaria** (`MaxDailyLossFTMO`, `SafetyBeltFactor`).  
- **Reinicio Diario**: reset de balance y pérdida realizada a las 00:00 España.  
- **Objetivo de Balance** (`BalanceTarget`, `UseBalanceTarget`).  
- **Saldo Mínimo** (`MinOperatingBalance`).  
- **Máximo de Posiciones** (`MaxPositions`).  
- **Escalado Automático de Lote** (`UseAutoScaling`, `MinLotSize`, `ScalingBaseEquity`, `ScalingEquityStep`, `ScalingLotStep`, `MaxContractSize`).  
- **Normalización de lote** según `SYMBOL_VOLUME_STEP`, mínimo/máximo del bróker.  
- **Validación de SL/TP** contra `SYMBOL_TRADE_STOPS_LEVEL`.  

---

## 📊 Resultados de Simulación

Backtest de referencia sobre la configuración actualmente operada en real (auto-escalado incluido), MetaTrader 5, IC Markets (EU) Ltd, cuenta USD, apalancamiento 1:30.

**Periodo:** XAUUSD H1, 2024.01.01 – 2026.09.12 · **Calidad del histórico:** 100% ticks reales · **Depósito inicial:** $500

| Métrica | Valor |
|---|---|
| Operaciones cerradas | 401 |
| Beneficio neto | +$1.890,87 |
| Profit factor | 1,29 |
| Win rate | 59,35% |
| Beneficio esperado/operación | $4,72 (≈0,16R) |
| Drawdown máximo (balance) | −27,51% ($860,53) |
| Drawdown relativo máximo | −30,84% |
| Ratio de Sharpe | 3,31 |
| Factor de recuperación | 1,93 |

*Nota: el drawdown de esta configuración es mayor que el de una versión con lote fijo (referencia histórica: −20,42% con 0.01 lotes fijos), porque el escalado automático amplifica el riesgo en dólares y en % relativo durante las rachas de pérdidas que llegan después de que la cuenta haya crecido. Es un efecto esperado del escalado, no un fallo de la estrategia.*

---

## ⚙ Instalación

1. Copia `One_Piece_v01.mq5` a `<MetaTrader5>\MQL5\Experts`.
2. Dentro de `One_Piece/`, crea la carpeta `images` y coloca `One_Piece_logo.png`.  
3. Abre MetaEditor, compila `One_Piece_v01.mq5`.  
4. En MT5, arrastra **One Piece** al gráfico **XAUUSD** (cualquier timeframe).  
5. Ajusta parámetros o usa valores por defecto.  
6. Activa trading automático.

---

## 🧾 Parámetros Configurables (configuración real operada actualmente)

| Parámetro                  | Descripción                                             | Valor real |
|-----------------------------|---------------------------------------------------------|-------------|
| `LotSize`                  | Lote fijo de respaldo (solo si `UseAutoScaling=false`)  | 0.01        |
| `SL_Points`                | Stop Loss en puntos gráficos                            | 1920        |
| `TP_Points`                | Take Profit en puntos gráficos                          | 1850        |
| `MaxPositions`             | Máximo de posiciones abiertas simultáneas               | 1           |
| `UseTrailingStop`          | Activar Trailing Stop                                   | false       |
| `TrailingStopActivation`   | Puntos para activar Trailing Stop                       | 1920        |
| `TrailingStopStep`         | Paso del Trailing Stop en puntos                        | 1850        |
| `ConfirmBreakoutWithClose` | Confirmar ruptura con cierre de vela                    | false       |
| `UseAutoScaling`           | Activar escalado automático de lote por equity          | true        |
| `MinLotSize`               | Lote mínimo / lote en el escalón base                   | 0.01        |
| `ScalingBaseEquity`        | Equity a partir de la cual aplica `MinLotSize`          | 570.0       |
| `ScalingEquityStep`        | Incremento de equity por cada escalón de lote           | 570.0       |
| `ScalingLotStep`           | Incremento de lote por escalón                          | 0.01        |
| `MaxContractSize`          | Tope de seguridad al lote escalado                      | 2.0         |
| `MaxDailyLossFTMO`         | Pérdida diaria máxima permitida (USD)                   | 5000.0      |
| `SafetyBeltFactor`         | Factor de seguridad sobre la pérdida diaria (0.0–1.0)   | 0.95        |
| `MinOperatingBalance`      | Saldo mínimo operativo (USD)                            | 1.0         |
| `UseBalanceTarget`         | Activar objetivo de balance                             | false       |
| `BalanceTarget`            | Meta de balance para cerrar el EA (USD)                 | 110001.0    |
| `SwingLength`              | Nº de velas para detectar swings                        | 10          |
| `MaxScanBars`              | Máximo de barras para el scan histórico al iniciar      | 1500        |

⚠️ **Aviso conocido:** el escalado automático de lote sube o baja el lote solo en función de la equity, en cada cierre de operación. No comprueba win rate, profit factor ni si hay un drawdown activo en curso antes de subir de escalón — a diferencia de la política de escalado manual documentada para este bot, que exige esas tres condiciones. En el backtest de referencia esto llegó a producir al menos una subida de lote con un drawdown activo del −25,7% desde máximos. Tenlo en cuenta al leer el rendimiento en real.

---

## 📝 Notas de Uso

- Prueba siempre en **cuenta demo** antes de operar en real.  
- Ajusta parámetros con el **Strategy Tester** según tu bróker y condiciones de mercado.  
- El EA detecta cierres manuales y reajusta su lógica de MSS y lotes.  
- Diseñado para cumplir requisitos FTMO; adapta límites según otros proveedores de fondeo.

---

## 🪪 Licencia

© Jose Antonio Montero. Sujeto a los términos de la [MIT License](LICENSE.md).
