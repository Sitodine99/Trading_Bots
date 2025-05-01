# John Wick H4

![John Wick H4 Logo](images/John_Wick_H4_logo.png)

**John Wick H4** es un **Expert Advisor (EA)** desarrollado para **MetaTrader 5**, diseñado específicamente para operar en el par de divisas **AUDCAD** en el marco temporal de **4 horas (H4)**. Este bot automatiza operaciones basadas en una estrategia de **ruptura de las Bandas de Bollinger**, optimizada para capturar movimientos direccionales tras expansiones de volatilidad. Incorpora una gestión de riesgo robusta alineada con los requisitos de desafíos de fondeo como **FTMO**, asegurando un equilibrio entre rentabilidad y protección de capital.

El EA utiliza **Bandas de Bollinger** para identificar puntos de entrada, con órdenes de compra o venta activadas al romper las bandas superior o inferior, y salidas basadas en el retorno del precio a la banda central. Incluye herramientas avanzadas como **Stop Loss**, **Trailing Stop** opcional, un **multiplicador de lotes** para aprovechar rachas ganadoras, y límites estrictos de **pérdida diaria** y **saldo mínimo**, ideales para pruebas de fondeo.

---

## 📌 Características Principales

- **Par soportado**: Exclusivamente **AUDCAD** en temporalidad **H4**.
- **Estrategia de Bandas de Bollinger**: Entradas basadas en rupturas de las bandas y salidas al alcanzar la banda central.
- **Gestión de riesgo avanzada**: Cumple con los límites de pérdida diaria y objetivos de fondeo de FTMO.
- **Trailing Stop dinámico**: Ajusta el Stop Loss para proteger beneficios (opcional).
- **Multiplicador de lotes**: Aumenta el tamaño del lote tras operaciones ganadoras (opcional).
- **Protección de capital**: Cierre automático por pérdida diaria máxima, saldo mínimo o meta de balance alcanzada.
- **Configuración flexible**: Parámetros ajustables para adaptarse a diferentes estilos de trading.

---

## 🚀 Estrategia de Trading

**John Wick H4** utiliza una estrategia basada en **Bandas de Bollinger** para identificar oportunidades en el par **AUDCAD**, entrando en el mercado tras rupturas significativas de las bandas y saliendo cuando el precio regresa a la banda central. La estrategia está diseñada para capturar movimientos de alta volatilidad en el marco temporal H4, con un enfoque en la consistencia y el control de riesgo.

### Lógica de Operación
- **Formación de las Bandas de Bollinger**: Calcula las bandas superior, inferior y central usando un periodo y desviación configurables (`BB_Period`, `BB_Deviation`).
- **Entradas**:
  - **Compra**: Se abre una posición de compra si el precio de cierre de la vela anterior está por debajo de la banda inferior o si el precio actual supera la banda inferior en una distancia definida (`BreakoutDistancePoints`).
  - **Venta**: Se abre una posición de venta si el precio de cierre de la vela anterior está por encima de la banda superior o si el precio actual cae por debajo de la banda superior en una distancia definida.
- **Salidas**:
  - Las posiciones se cierran cuando el precio alcanza la banda central (`bb_mid`), indicando un posible agotamiento del movimiento direccional.
  - También se cierran si se alcanza el **Stop Loss** (`SL_Points`) o mediante el **Trailing Stop**, si está activado.
- **Razonamiento**: La estrategia asume que las rupturas de las Bandas de Bollinger en H4 indican movimientos de impulso significativos en AUDCAD, mientras que el retorno a la banda central sugiere una reversión o estabilización del precio.
- **Filtros**:
  - Máximo de posiciones por dirección (`MaxPositions`) para evitar sobreoperar.
  - Separación mínima entre operaciones en la misma dirección (`CandleSeparation`) para reducir la exposición en mercados volátiles.
  - Validación de distancia de ruptura (`BreakoutDistancePoints`) para confirmar movimientos fuertes.

### Gestión de Operaciones
- **Stop Loss**: Configurable en puntos (`SL_Points`) para cada operación, asegurando un riesgo controlado.
- **Trailing Stop**: Activable (`UseTrailingStop`) y configurable (`TrailingStopActivation`, `TrailingStopStep`) para proteger ganancias en movimientos prolongados.
- **Multiplicador de Lotes**: Si está activado (`UseComboMultiplier`), el tamaño del lote aumenta (`ComboMultiplier`) tras una operación ganadora, hasta un máximo (`MaxContractSize`).
- **Validaciones**: El EA verifica que no se exceda el número máximo de posiciones abiertas y que las nuevas operaciones respeten la separación mínima en velas.

---

## 🛡️ Gestión de Riesgo (Alineada con FTMO)

**John Wick H4** implementa un sistema de gestión de riesgo diseñado para cumplir con las estrictas reglas de los desafíos de fondeo como **FTMO**, que exigen límites de pérdida diaria, protección de capital y consistencia. A continuación, se detalla cómo se logra:

### 1. Límite de Pérdida Diaria
- **Parámetro**: `MaxDailyLossFTMO` (USD) define la pérdida máxima permitida en un día.
- **Cinturón de Seguridad**: El parámetro `SafetyBeltFactor` (0.0 a 1.0) reduce el límite efectivo de pérdida diaria. Por ejemplo, si `MaxDailyLossFTMO = 500` y `SafetyBeltFactor = 0.5`, el límite real es **250 USD**.
- **Cálculo**: Combina pérdidas realizadas y flotantes (`CalculateTotalDailyLoss`) para monitorear el riesgo en tiempo real.
- **Acción**: Si se alcanza el límite, el EA cierra todas las posiciones y desactiva el trading hasta el siguiente día (00:00 hora de España).

### 2. Saldo Mínimo Operativo
- **Parámetro**: `MinOperatingBalance` (USD) establece el nivel mínimo de capital para operar.
- **Acción**: Si el **equity** cae por debajo de este nivel, el EA cierra todas las posiciones y detiene el trading para proteger la cuenta.

### 3. Objetivo de Saldo
- **Parámetro**: `BalanceTarget` (USD) define una meta de ganancias. Si se activa (`UseBalanceTarget = true`), el EA cierra todas las posiciones y se detiene al alcanzar este nivel.
- **Uso**: Ideal para desafíos de fondeo que requieren alcanzar un objetivo de rentabilidad sin violar reglas de riesgo.

### 4. Reseteo Diario
- **Lógica**: El EA reinicia los contadores de pérdida diaria y estado de trading a las **00:00 hora de España**, ajustado según el horario de verano/invierno (UTC+1 o UTC+2).
- **Beneficio**: Garantiza que las reglas de pérdida diaria se respeten según los ciclos de los proveedores de fondeo.

### 5. Multiplicador de Lotes
- **Lógica**: Tras una operación ganadora, el tamaño del lote puede aumentar (`ComboMultiplier`) para aprovechar rachas positivas, pero siempre limitado por `MaxContractSize`.
- **Control de Riesgo**: Si la operación es perdedora, el tamaño del lote vuelve al valor inicial (`LotSize`), evitando una exposición excesiva tras pérdidas.

### 6. Validaciones de Seguridad
- **Símbolo Soportado**: El EA verifica que se ejecute en **AUDCAD**. Si se usa en otro símbolo, se detiene automáticamente.
- **Parámetros Incorrectos**: Incluye validaciones para parámetros como `TrailingStopActivation` o `SafetyBeltFactor`, usando valores predeterminados seguros si son inválidos.

Esta gestión de riesgo asegura que **John Wick H4** sea compatible con las reglas de FTMO, protegiendo la cuenta mientras maximiza las oportunidades de pasar los desafíos de fondeo.

---

## 📊 Resultados de Simulación

**John Wick H4** ha sido evaluado con datos reales en MetaTrader 5 usando una simulación con parámetros optimizados.
- **[Resultados de Simulación](Simulaciones%20y%20optimizaciones/README.md)**

---

## ⚙ Instalación

1. Guarda el archivo como `John_Wick_H4.mq5` en tu carpeta de expertos: `<MetaTrader5>\MQL5\Experts`.
2. Abre MetaEditor y compílalo.
3. Aplica el EA al gráfico de **AUDCAD** en temporalidad **H4**.
4. Ajusta los parámetros si lo deseas, o usa los predeterminados para replicar la estrategia base.
5. Activa el **trading automático**.

---

## 🧾 Parámetros Configurables

| Parámetro                     | Descripción                                               | Valor por defecto |
|-------------------------------|-----------------------------------------------------------|-------------------|
| `BB_Period`                   | Periodo de las Bandas de Bollinger                        | 36                |
| `BB_Deviation`                | Desviación de las Bandas de Bollinger                     | 2.0               |
| `LotSize`                     | Tamaño de lote inicial                                    | 0.5               |
| `MaxContractSize`             | Tamaño máximo del contrato                                | 0.5               |
| `UseComboMultiplier`          | Activar multiplicador de lotes tras ganancia              | true              |
| `ComboMultiplier`             | Multiplicador en rachas ganadoras                         | 2.0               |
| `SL_Points`                   | Stop Loss en puntos                                       | 700               |
| `UseTrailingStop`             | Activar/desactivar trailing stop                          | true              |
| `TrailingStopActivation`      | Beneficio necesario para activar trailing stop            | 150               |
| `TrailingStopStep`            | Paso del trailing stop en puntos                          | 10                |
| `MaxDailyLossFTMO`            | Pérdida diaria máxima permitida (USD)                     | 500.0             |
| `SafetyBeltFactor`            | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |
| `MinOperatingBalance`         | Saldo mínimo para operar (USD)                            | 9050.0            |
| `UseBalanceTarget`            | Activar objetivo de saldo                                 | true              |
| `BalanceTarget`               | Objetivo de saldo para cerrar el bot (USD)                | 11000.0           |
| `MaxPositions`                | Máximo número de posiciones abiertas por dirección        | 2                 |
| `CandleSeparation`            | Separación mínima en velas entre operaciones              | 7                 |
| `UseBreakoutDistance`         | Activar apertura por rotura en la misma vela              | true              |
| `BreakoutDistancePoints`      | Distancia en puntos para rotura en la misma vela          | 150               |

---

## 📝 Notas de Uso

- **Cuenta demo primero**: Siempre prueba el EA en entorno demo antes de aplicarlo en real.
- **FTMO-Friendly**: Los límites de pérdida y el control de saldo están alineados con requisitos típicos de pruebas de fondeo.
- **Optimizable**: El rendimiento puede mejorar según mercado, spread, y broker. Se recomienda evaluar la estrategia con el optimizador de MetaTrader para configurar los parámetros.
- **Horario del broker**: Asegúrate de que el broker usa el horario adecuado para alinear las operaciones con el reseteo diario.

---

## 🪪 Licencia

© Jose Antonio Montero. Distribución sujeta a los términos de la licencia [MIT License](LICENSE.md).