# John Wick H4

![John Wick H4 Logo](images/John_Wick_H4_logo.png)

**John Wick H4** es un **Expert Advisor (EA)** desarrollado para **MetaTrader 5**, diseñado específicamente para operar en el par de divisas **AUDCAD** en el marco temporal de **4 horas (H4)**. Este bot automatiza operaciones basadas en una estrategia de **reversión a la media sobre Bandas de Bollinger**, entrando cuando el precio se aleja en exceso de las bandas y saliendo al retornar a la banda central. Incorpora una gestión de riesgo robusta alineada con los requisitos de desafíos de fondeo como **FTMO**, y un sistema de **escalado automático de lote** por balance para no depender de ajustes manuales conforme crece la cuenta.

---

## 📌 Características Principales

- **Par soportado**: Exclusivamente **AUDCAD** en temporalidad **H4**.
- **Estrategia de Bandas de Bollinger**: Entradas basadas en reversión desde los extremos de las bandas, salidas al alcanzar la banda central.
- **Gestión de riesgo avanzada**: Cumple con los límites de pérdida diaria y objetivos de fondeo de FTMO.
- **Trailing Stop dinámico**: Ajusta el Stop Loss para proteger beneficios (opcional, actualmente desactivado por defecto).
- **Escalado automático de lote**: Ajusta el tamaño de lote según el balance cerrado de la cuenta, sin intervención manual.
- **Protección de capital**: Cierre automático por pérdida diaria máxima, saldo mínimo o meta de balance alcanzada.
- **Configuración flexible**: Parámetros ajustables para adaptarse a diferentes estilos de trading.

---

## 🚀 Estrategia de Trading

**John Wick H4** utiliza una estrategia de **reversión a la media** sobre **Bandas de Bollinger** en el par **AUDCAD**, entrando en el mercado cuando el precio se ha desviado en exceso de las bandas y saliendo cuando regresa a la banda central. Es un sistema de tipo **grid**: puede acumular varias posiciones en la misma dirección si el precio no revierte de inmediato.

### Lógica de Operación
- **Formación de las Bandas de Bollinger**: Calcula las bandas superior, inferior y central usando un periodo y desviación configurables (`BB_Period`, `BB_Deviation`).
- **Entradas**:
  - **Compra**: Se abre una posición de compra si el precio de cierre de la vela anterior está por debajo de la banda inferior, o si el precio actual cae por debajo de la banda inferior en una distancia definida (`BreakoutDistancePoints`), apostando a una reversión al alza.
  - **Venta**: Se abre una posición de venta si el precio de cierre de la vela anterior está por encima de la banda superior, o si el precio actual supera la banda superior en esa misma distancia, apostando a una reversión a la baja.
- **Salidas**:
  - Las posiciones se cierran cuando el precio alcanza la banda central (`bb_mid`).
  - También se cierran si se alcanza el **Stop Loss** (`SL_Points`) o mediante el **Trailing Stop**, si está activado.
- **Filtros**:
  - Máximo de posiciones por dirección (`MaxPositions`) para evitar sobreoperar.
  - Separación mínima entre operaciones en la misma dirección (`CandleSeparation`) para reducir la exposición en mercados volátiles.
  - Validación de distancia de ruptura (`BreakoutDistancePoints`) para confirmar movimientos fuertes.

### Gestión de Operaciones
- **Stop Loss**: Configurable en puntos (`SL_Points`) para cada operación, asegurando un riesgo controlado.
- **Trailing Stop**: Activable (`UseTrailingStop`) y configurable (`TrailingStopActivation`, `TrailingStopStep`) para proteger ganancias en movimientos prolongados.
- **Validaciones**: El EA verifica que no se exceda el número máximo de posiciones abiertas y que las nuevas operaciones respeten la separación mínima en velas.

---

## 🛡️ Gestión de Riesgo (Alineada con FTMO)

### 1. Límite de Pérdida Diaria
- **Parámetro**: `MaxDailyLossFTMO` (USD) define la pérdida máxima permitida en un día.
- **Cinturón de Seguridad**: El parámetro `SafetyBeltFactor` (0.0 a 1.0) reduce el límite efectivo de pérdida diaria. Por ejemplo, si `MaxDailyLossFTMO = 500` y `SafetyBeltFactor = 0.8`, el límite real es **400 USD**.
- **Cálculo**: Combina pérdidas realizadas y flotantes (`CalculateTotalDailyLoss`) para monitorear el riesgo en tiempo real.
- **Acción**: Si se alcanza el límite, el EA cierra todas las posiciones y desactiva el trading hasta el siguiente día (00:00 hora de España).

### 2. Saldo Mínimo Operativo
- **Parámetro**: `MinOperatingBalance` (USD) establece el nivel mínimo de equity para operar.
- **Acción**: Si el **equity** cae por debajo de este nivel, el EA cierra todas las posiciones y detiene el trading para proteger la cuenta.

### 3. Objetivo de Saldo
- **Parámetro**: `BalanceTarget` (USD) define una meta de ganancias. Si se activa (`UseBalanceTarget = true`), el EA cierra todas las posiciones y se detiene al alcanzar este nivel. Desactivado por defecto.

### 4. Reseteo Diario
- **Lógica**: El EA reinicia los contadores de pérdida diaria y estado de trading a las **00:00 hora de España**, ajustado según el horario de verano/invierno (UTC+1 o UTC+2).

### 5. Escalado Automático de Lote
- **Lógica**: Si `UseAutoScaling = true`, el EA calcula el lote base en función del **balance cerrado** de la cuenta (no de la equity flotante), justo después de cada cierre de posición. Por cada `ScalingEquityStep` de balance por encima de `ScalingBaseEquity`, el lote sube `ScalingLotStep`, sin superar nunca `MaxContractSize`. Por debajo de `ScalingBaseEquity`, el lote se queda en `MinLotSize`, que actúa como suelo absoluto.
- **Si `UseAutoScaling = false`**, el EA usa el lote fijo `LotSize` en todas las operaciones.
- **Nota**: el recálculo no ocurre en cada tick ni con la equity flotante — solo se dispara al cerrarse una operación, para no reaccionar a rachas intramensuales de ganancia/pérdida no realizada.

### 6. Validaciones de Seguridad
- **Símbolo Soportado**: El EA verifica que se ejecute en **AUDCAD**. Si se usa en otro símbolo, se detiene automáticamente.
- **Parámetros Incorrectos**: Incluye validaciones para parámetros como `TrailingStopActivation` o `SafetyBeltFactor`, usando valores predeterminados seguros si son inválidos.

---

## 📊 Resultados de Simulación

Último backtest (IC Markets EU, MT5, AUDCAD H4, **calidad de historial 100%**, con el escalado automático de lote activo dentro del propio test — no aplicado a posteriori):

| Dato | Valor |
|---|---|
| Periodo | 2020.01.01 – 2026.09.12 (~6,7 años) |
| Depósito inicial | $500, apalancamiento 1:30 |
| Beneficio neto | $6.009,68 |
| Beneficio bruto / Pérdidas brutas | $14.722,24 / −$8.712,56 |
| Profit factor | 1,69 |
| Beneficio esperado por operación | $3,97 |
| Reducción máxima de balance | $1.181,95 (29,23%) |
| Reducción máxima de equidad | $1.376,17 (33,51%) |
| Recovery factor / Sharpe | 4,37 / 1,10 |
| Total operaciones | 1.515 (72,74% ganadoras) |
| Racha máx. ganancias / pérdidas consecutivas | 57 ($1.273,77) / 14 (−$115,51) |
| Años con P&L negativo | Ninguno (7 de 7 años en positivo) |

**Notas honestas sobre este resultado:**
- El 88% del beneficio total se concentra en 2025-2026, el tramo final del test — no está repartido de forma uniforme a lo largo de los 6,7 años.
- El peor drawdown en dólares absolutos ($1.167,83) ocurre en 2026, con el lote ya escalado — no en los años iniciales.
- El test arrancó con $500 de depósito, no con los $300 reales del plan de despliegue; el primer escalón de lote puede comportarse distinto partiendo de $300.
- Esto es un backtest, no un resultado en cuenta real ni en demo todavía.

---

## ⚙ Instalación

1. Guarda el archivo como `John_Wick_H4.mq5` en tu carpeta de expertos: `<MetaTrader5>\MQL5\Experts`.
2. Abre MetaEditor y compílalo.
3. Aplica el EA al gráfico de **AUDCAD** en temporalidad **H4**.
4. Ajusta los parámetros si lo deseas, o usa los predeterminados para replicar la configuración base.
5. Activa el **trading automático**.

---

## 🧾 Parámetros Configurables

| Parámetro | Descripción | Valor por defecto |
|---|---|---|
| `BB_Period` | Periodo de las Bandas de Bollinger | 49 |
| `BB_Deviation` | Desviación de las Bandas de Bollinger | 1.1 |
| `LotSize` | Lote fijo, usado solo si `UseAutoScaling = false` | 0.01 |
| `MaxContractSize` | Tamaño máximo del contrato (techo del escalado también) | 2.0 |
| `UseAutoScaling` | Activar escalado automático de lote por balance | true |
| `MinLotSize` | Lote mínimo / suelo del escalado | 0.01 |
| `ScalingBaseEquity` | Balance a partir del cual aplica `MinLotSize` | 300.0 |
| `ScalingEquityStep` | Incremento de balance por cada escalón de lote | 300.0 |
| `ScalingLotStep` | Incremento de lote por escalón | 0.01 |
| `SL_Points` | Stop Loss en puntos | 1150 |
| `UseTrailingStop` | Activar/desactivar trailing stop | false |
| `TrailingStopActivation` | Beneficio necesario para activar trailing stop | 150 |
| `TrailingStopStep` | Paso del trailing stop en puntos | 180 |
| `MaxDailyLossFTMO` | Pérdida diaria máxima permitida (USD) | 500.0 |
| `SafetyBeltFactor` | Factor de seguridad sobre la pérdida máxima diaria | 0.8 |
| `MinOperatingBalance` | Equity mínimo para operar (USD), freno de ruina | 100.0 |
| `UseBalanceTarget` | Activar objetivo de saldo | false |
| `BalanceTarget` | Objetivo de saldo para cerrar el bot (USD) | 11000.0 |
| `MaxPositions` | Máximo número de posiciones abiertas por dirección | 4 |
| `CandleSeparation` | Separación mínima en velas entre operaciones | 2 |
| `UseBreakoutDistance` | Activar apertura por rotura en la misma vela | true |
| `BreakoutDistancePoints` | Distancia en puntos para rotura en la misma vela | 150 |

---

## 📝 Notas de Uso

- **Cuenta demo primero**: Prueba el EA en entorno demo antes de aplicarlo en real.
- **Aún no compilado ni probado en real/demo**: los valores por defecto de esta tabla están fijados a la configuración de referencia, pero el `.mq5` no ha pasado todavía por MetaEditor ni por una prueba en cuenta demo.
- **FTMO-Friendly**: Los límites de pérdida y el control de saldo están alineados con requisitos típicos de pruebas de fondeo, aunque el plan actual es operarlo con capital propio, no en un desafío de fondeo.
- **Escalado por balance cerrado, no por equity flotante**: el lote solo cambia al cerrar una operación, nunca en mitad de una posición abierta.
- **Horario del broker**: Asegúrate de que el broker usa el horario adecuado para alinear las operaciones con el reseteo diario.

---

## 🪪 Licencia

© Jose Antonio Montero. Distribución sujeta a los términos de la licencia [MIT License](LICENSE.md).
