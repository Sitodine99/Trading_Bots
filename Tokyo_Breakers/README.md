# Tokyo Breakers

![Tokyo Breakers Logo](images/Tokyo_Breakers_logo.png)

**Tokyo Breakers** es un **Expert Advisor (EA)** desarrollado para **MetaTrader 5**, diseñado exclusivamente para operar en el par **USDJPY** en el marco temporal de **1 hora (H1)**. Este bot automatiza operaciones basadas en **rupturas de Bandas de Bollinger**, con una estrategia optimizada para capturar movimientos de alta volatilidad y una gestión de riesgo robusta, especialmente alineada con los requisitos de desafíos de fondeo como **FTMO**.

El EA incorpora herramientas avanzadas de gestión de capital, incluyendo **Stop Loss**, **Take Profit**, **Trailing Stop**, límites de **pérdida diaria**, y un sistema de **multiplicador de contratos** para maximizar el rendimiento tras operaciones ganadoras. Su diseño busca equilibrar rentabilidad y control de riesgo, respetando las reglas estrictas de los programas de fondeo.

---

## 📌 Características Principales

- **Par exclusivo**: Opera únicamente en **USDJPY** (H1).
- **Estrategia basada en Bandas de Bollinger**: Detecta rupturas de volatilidad para entrar en el mercado.
- **Gestión de riesgo avanzada**: Cumple con los límites de pérdida diaria y objetivos de fondeo de FTMO.
- **Trailing Stop dinámico**: Ajusta el Stop Loss para proteger beneficios.
- **Multiplicador de contratos**: Aumenta el tamaño del lote tras operaciones ganadoras (opcional).
- **Protección de capital**: Cierre automático por pérdida diaria máxima, saldo mínimo o meta de balance alcanzada.
- **Configuración flexible**: Amplios parámetros ajustables para adaptarse a diferentes estilos de trading.

---

## 🚀 Estrategia de Trading

**Tokyo_Breakers** es un Expert Advisor (EA) diseñado para operar en el par **USDJPY** en MetaTrader 5, aprovechando movimientos direccionales fuertes mediante una estrategia de **seguimiento de tendencia** basada en las **Bandas de Bollinger**. A diferencia de las estrategias tradicionales que buscan retrocesos tras rupturas (reversión a la media), este EA capitaliza la volatilidad y el momentum del mercado, entrando en operaciones en la dirección de la ruptura. Esto lo hace ideal para capturar tendencias durante sesiones de alta actividad, como la sesión asiática (de ahí su nombre "Tokyo_Breakers").

### Lógica Principal
El EA utiliza las **Bandas de Bollinger** (con un período configurable `BB_Period` y una desviación `BB_Deviation`) en un timeframe de **H1** para identificar momentos de alta volatilidad en USDJPY. Las Bandas de Bollinger miden la volatilidad del mercado: cuando el precio cruza las bandas superior o inferior, indica un posible movimiento direccional fuerte. La estrategia principal del EA se basa en rupturas de la vela anterior:

#### Ruptura de Vela Anterior (Modo Principal)
- **Condición de Entrada**:
  - **Compra**: Si la vela anterior cierra **por encima** de la banda superior de Bollinger, el EA abre una posición de compra, anticipando que el movimiento alcista continuará.
  - **Venta**: Si la vela anterior cierra **por debajo** de la banda inferior de Bollinger, el EA abre una posición de venta, esperando una continuación bajista.
- **Razonamiento**: Este modo asume que una ruptura de las Bandas de Bollinger en USDJPY, especialmente durante la sesión asiática, indica un momentum direccional fuerte. En lugar de esperar un retroceso (como en estrategias de reversión), el EA busca capitalizar la tendencia inmediatamente después de la ruptura.
- **Filtros**:
  - **Separación entre operaciones**: El EA espera un número mínimo de velas (`CandleSeparation`) entre operaciones para evitar sobreoperar.
  - **Límite de posiciones**: Restringe el número máximo de posiciones abiertas por dirección (`MaxPositions`) para controlar la exposición al riesgo.

#### Condición Adicional: Ruptura en Tiempo Real (`UseBreakoutDistance = true`)
- **Funcionalidad Extra**: Si el parámetro `UseBreakoutDistance` está activado, el EA añade una condición adicional para operar en tiempo real, además de la lógica de ruptura de vela anterior.
- **Condición de Entrada**:
  - **Compra**: Si el precio actual (en tiempo real) supera la banda superior de Bollinger por una distancia definida (`BreakoutDistancePoints`), el EA abre una posición de compra.
  - **Venta**: Si el precio actual cae por debajo de la banda inferior de Bollinger por la misma distancia, el EA abre una posición de venta.
- **Razonamiento**: Esta funcionalidad permite capturar rupturas explosivas en tiempo real, como las que ocurren tras eventos de noticias o durante sesiones de alta volatilidad. La distancia de ruptura (`BreakoutDistancePoints`) actúa como un filtro para confirmar que el movimiento es significativo y no una falsa ruptura. Esto complementa el modo principal, permitiendo al EA reaccionar más rápido a movimientos fuertes.
- **Filtros**:
  - Igual que en el modo principal: separación mínima entre operaciones (`CandleSeparation`) y límite de posiciones por dirección (`MaxPositions`).

### Gestión de Operaciones y Riesgo
**Tokyo_Breakers** incluye varias herramientas para gestionar las operaciones y controlar el riesgo, asegurando un trading disciplinado:

- **Stop Loss y Take Profit**:
  - Cada operación tiene un **Stop Loss** (`SL_Points`) y un **Take Profit** (`TP_Points`) definidos en puntos, lo que limita las pérdidas y asegura las ganancias.
- **Trailing Stop**:
  - Activable con el parámetro `UseTrailingStop`. Una vez que la operación alcanza un beneficio mínimo (`TrailingStopActivation`), el EA ajusta dinámicamente el Stop Loss (`TrailingStopStep`) para proteger las ganancias en tendencias prolongadas.
- **Multiplicador de Lotes**:
  - Si `UseComboMultiplier` está activado, el EA aumenta el tamaño del lote (`ComboMultiplier`) después de una operación ganadora, hasta un máximo (`MaxContractSize`). Si la operación es perdedora, el lote vuelve al tamaño inicial (`LotSize`).
- **Límites de Posiciones**:
  - El EA restringe el número máximo de posiciones abiertas por dirección (`MaxPositions`), evitando acumulación excesiva de riesgo.
- **Separación Temporal**:
  - Exige un número mínimo de velas entre operaciones (`CandleSeparation`) para evitar operar en exceso durante movimientos rápidos.
- **Gestión de Capital**:
  - **Objetivo de Saldo**: Si `UseBalanceTarget` está activado, el EA cierra todas las posiciones y se desactiva al alcanzar un saldo objetivo (`BalanceTarget`).
  - **Saldo Mínimo**: Si el capital cae por debajo de un mínimo (`MinOperatingBalance`), el EA cierra todas las posiciones y se detiene.
  - **Límite de Pérdida Diaria**: Limita las pérdidas diarias (`MaxDailyLossFTMO`), ajustado por un factor de seguridad (`SafetyBeltFactor`). Si se alcanza este límite, el EA cierra todas las posiciones y se desactiva hasta el próximo día.

### Por qué USDJPY y la Sesión de Tokio
El par **USDJPY** es conocido por su alta volatilidad durante la sesión asiática (especialmente en Tokio), donde los movimientos direccionales pueden ser significativos debido a noticias económicas o ajustes de mercado. Las Bandas de Bollinger son ideales para identificar estas expansiones de volatilidad, y **Tokyo_Breakers** está optimizado para aprovechar estas condiciones, entrando en operaciones cuando el mercado muestra un momentum claro.

## 🛡️ Gestión de Riesgo (Alineada con FTMO)

**Tokyo Breakers** implementa un sistema de gestión de riesgo diseñado para cumplir con las estrictas reglas de los desafíos de fondeo como **FTMO**, que exigen límites de pérdida diaria, protección de capital y consistencia. A continuación, se detalla cómo se logra:

### 1. Límite de Pérdida Diaria
- **Parámetro**: `MaxDailyLossFTMO` (USD) define la pérdida máxima permitida en un día.
- **Cinturón de Seguridad**: El parámetro `SafetyBeltFactor` (0.0 a 1.0) reduce el límite efectivo de pérdida diaria para mayor protección. Por ejemplo, si `MaxDailyLossFTMO = 500` y `SafetyBeltFactor = 0.5`, el límite real es **250 USD**.
- **Cálculo**: Combina pérdidas realizadas y flotantes (`CalculateTotalDailyLoss`) para monitorear el riesgo en tiempo real.
- **Acción**: Si se alcanza el límite, el EA cierra todas las posiciones y desactiva el trading hasta el siguiente día (00:00 hora de España).

### 2. Saldo Mínimo Operativo
- **Parámetro**: `MinOperatingBalance` (USD) establece el nivel mínimo de capital para operar.
- **Acción**: Si el **equity** cae por debajo de este nivel, el EA cierra todas las posiciones y detiene el trading para proteger la cuenta.

### 3. Objetivo de Saldo
- **Parámetro**: `BalanceTarget` (USD) define una meta de gains. Si se activa (`UseBalanceTarget = true`), el EA cierra todas las posiciones y se detiene al alcanzar este nivel.
- **Uso**: Ideal para desafíos de fondeo que requieren alcanzar un objetivo de rentabilidad sin violar reglas de riesgo.

### 4. Reseteo Diario
- **Lógica**: El EA reinicia los contadores de pérdida diaria y estado de trading a las **00:00 hora de España**, ajustado según el horario de verano/invierno (UTC+1 o UTC+2).
- **Beneficio**: Garantiza que las reglas de pérdida diaria se respeten según los ciclos de los proveedores de fondeo.

### 5. Multiplicador de Contratos
- **Lógica**: Tras una operación ganadora, el tamaño del lote puede aumentar (`ComboMultiplier`) para aprovechar rachas positivas, pero siempre limitado por `MaxContractSize`.
- **Control de Riesgo**: Si la operación es perdedora, el tamaño del lote vuelve al valor inicial (`LotSize`), evitando una exposición excesiva tras pérdidas.

### 6. Validaciones de Seguridad
- **Símbolo Exclusivo**: El EA verifica que se ejecute en **USDJPY**. Si se usa en otro par, se detiene automáticamente.
- **Parámetros Incorrectos**: Incluye validaciones para parámetros como `TrailingStopActivation` o `SafetyBeltFactor`, usando valores predeterminados seguros si son inválidos.

Esta gestión de riesgo asegura que **Tokyo Breakers** sea compatible con las reglas de FTMO, protegiendo la cuenta mientras maximiza las oportunidades de pasar los desafíos de fondeo.

---

## 📊 Resultados de Simulación

**Tokyo Breakers** ha sido evaluado con datos reales en MetaTrader 5 usando una simulación con parámetros optimizados:

## ⚙ Instalación

1. Guarda el archivo como `TokyoBreakers.mq5` en tu carpeta de expertos: `<MetaTrader5>\MQL5\Experts`.
2. Abre MetaEditor y compílalo.
3. Aplica el EA al gráfico **USDJPY** en temporalidad **H1**.
4. Ajusta los parámetros si lo deseas, o usa los de la simulación para replicar los resultados.
5. Activa el **trading automático**.

## 🧾 Parámetros Configurables

| Parámetro                   | Descripción                                               | Valor por defecto |
|-----------------------------|-----------------------------------------------------------|-------------------|
| `BB_Period`                 | Periodo de las Bandas de Bollinger                        | 36                |
| `BB_Deviation`              | Desviación estándar para las bandas                       | 2.0               |
| `LotSize`                   | Tamaño de lote inicial                                    | 1.0               |
| `SL_Points`                 | Stop Loss en puntos                                       | 350               |
| `TP_Points`                 | Take Profit en puntos                                     | 350               |
| `UseTrailingStop`           | Activar/desactivar trailing stop                          | true              |
| `TrailingStopActivation`    | Beneficio necesario para activar trailing stop            | 150               |
| `TrailingStopStep`          | Paso del trailing stop en puntos                          | 10                |
| `MaxPositions`              | Máximo de operaciones abiertas por dirección              | 2                 |
| `CandleSeparation`          | Velas mínimas entre operaciones nuevas                    | 7                 |
| `UseBalanceTarget`          | Activar objetivo de balance                               | true              |
| `BalanceTarget`             | Objetivo de balance para cerrar el bot                    | 11000.0           |
| `MinOperatingBalance`       | Balance mínimo para operar                                | 9050.0            |
| `MaxDailyLossFTMO`          | Pérdida diaria máxima permitida                           | 500.0             |
| `SafetyBeltFactor`          | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |
| `UseComboMultiplier`        | Activar multiplicador de lotes tras ganancia              | true              |
| `ComboMultiplier`           | Multiplicador en rachas ganadoras                         | 2.0               |
| `MaxContractSize`           | Tamaño máximo de lote                                     | 1.0               |
| `UseBreakoutDistance`       | Activar ruptura en la vela actual                         | false             |
| `BreakoutDistancePoints`    | Distancia mínima para confirmar la ruptura                | 150               |

## 📝 Notas de Uso

- **Cuenta demo primero**: Siempre prueba el EA en entorno demo antes de aplicarlo en real.
- **FTMO-Friendly**: Los límites de pérdida y el control de balance están alineados con requisitos típicos de pruebas de fondeo.
- **Optimizable**: El rendimiento puede mejorar según mercado, spread, y broker. Se recomienda evaluar la estrategia con el optimizador de MetaTrader para configurar los parámetros.

## 🪪 Licencia

© Jose Antonio Montero. Distribución sujeta a los términos de la licencia [MIT License](LICENSE.md).