# MECHA-GODZILLA

![MECHA-GODZILLA Logo](images/MECHA-GODZILLA_logo.png)

**MECHA-GODZILLA** es un **Expert Advisor (EA)** desarrollado para **MetaTrader 5**. Este bot automatiza operaciones basadas en una **estrategia de grid trading**, que utiliza niveles de precios predefinidos para abrir posiciones de compra y venta, con un enfoque en capturar movimientos del mercado y una gestión de riesgo robusta, especialmente alineada con los requisitos de desafíos de fondeo como **FTMO**.

El EA incorpora herramientas avanzadas de gestión de capital, incluyendo **Stop Loss**, **Take Profit**, **Trailing Stop** opcional, **coberturas (hedging)**, un filtro basado en el **ATR**, y un sistema de **multiplicador de lotes** para maximizar el rendimiento tras operaciones ganadoras. Su diseño busca equilibrar rentabilidad y control de riesgo, respetando las reglas estrictas de los programas de fondeo.

---

## 📌 Características Principales

- **Pares soportados**: Opera en cualquier activo ya que posee configuraciones ajustables que se adaptan a cada uno de ellos.
- **Estrategia de grid trading**: Crea un grid de niveles de precios (basado en un punto central fijo o calculado con velas) para abrir posiciones de compra y venta de forma sistemática.
- **Filtro ATR**: Permite filtrar operaciones según la volatilidad del mercado, usando el indicador ATR para evitar condiciones extremas.
- **Operaciones múltiples por nivel**: Permite abrir varias posiciones por nivel del grid, hasta un máximo configurable (`MaxPositionsPerLevel`).
- **Límite de posiciones en el grid**: Controla el número máximo de posiciones abiertas en el grid (`MaxGridPositions`), excluyendo coberturas.
- **Coberturas (Hedging)**: Activable para abrir posiciones de cobertura en niveles específicos, con Stop Loss y Take Profit independientes.
- **Gestión de riesgo avanzada**: Cumple con los límites de pérdida diaria y objetivos de fondeo de FTMO.
- **Protección de capital**: Cierre automático por pérdida diaria máxima, saldo mínimo o meta de balance alcanzada.
- **Configuración flexible**: Amplios parámetros ajustables para adaptarse a diferentes estilos de trading.

---

## 🚀 Estrategia de Trading

**MECHA-GODZILLA** utiliza una estrategia de **grid trading**, implementando un sistema de niveles de precios (grid) donde se abren posiciones de compra y venta según el movimiento del precio. El punto central del grid puede ser fijo (`FixedCentralPoint`) o calculado dinámicamente con base al número de velas (`UseCandleBasedCentralPoint`).

### Formación del Grid
- **Punto central**: Puede ser un valor fijo (`FixedCentralPoint`) o calculado como el promedio entre el máximo y el mínimo de un número definido de velas (`CandlesToConsider`).
- **Niveles del grid**: Se crean niveles de compra (`gridLevelsBuy`) y venta (`gridLevelsSell`) a partir del punto central, con una distancia configurable (`GridDistancePointsGraphics`).
- **Máximo de niveles**: Limitado por `MaxGridLevels` para controlar la exposición.
- **Visualización**: Dibuja líneas horizontales en el gráfico para cada nivel del grid, con colores distintos para niveles de compra (verde), venta (rojo), y el punto central (amarillo).

### Lógica de Operación
- **Apertura de posiciones**:
  - **Compra**: Se abre una posición de compra cuando el precio cruza un nivel de compra hacia abajo (`gridLevelsBuy`). Si no hay posiciones abiertas en ese nivel, se abre una nueva posición.
  - **Venta**: Se abre una posición de venta cuando el precio cruza un nivel de venta hacia arriba (`gridLevelsSell`). Si no hay posiciones abiertas en ese nivel, se abre una nueva posición.
  - **Múltiples posiciones por nivel**: Permite abrir hasta `MaxPositionsPerLevel` posiciones por nivel. Además, siempre que se liquida una posición en el nivel inferior (para compras) o superior (para ventas), el bot puede abrir una operación adicional en el nivel inmediatamente superior (para compras) o inferior (para ventas), si ya existe una posición en ese nivel y no se ha abierto una adicional (`additionalPositionsOpenedBuy/Sell`).
  - **Límite total de posiciones**: Restringe el número total de posiciones abiertas en el grid (`MaxGridPositions`), excluyendo coberturas.
- **Filtro ATR**: Si `UseAtrFilter` está activado, el bot solo abre posiciones si el valor del ATR está dentro del rango definido (`AtrLow` a `AtrHigh`), evitando operar en condiciones de volatilidad extrema.
- **Coberturas (Hedging)**: Si `UseHedging` está activado, el bot puede abrir posiciones de cobertura (`HedgeContractSize`) cuando una posición principal se acerca a su Stop Loss, a una distancia definida (`HedgePointsBeforeSL`).
- **Cierre de posiciones**:
  - Las posiciones se cierran al alcanzar el nivel inmediatamente superior (para compras) o inferior (para ventas) en el grid, o al tocar el punto central.
  - Las coberturas tienen Stop Loss y Take Profit independientes (`HedgeStopLossPoints`, `HedgeTakeProfitPoints`).
- **Razonamiento**: La estrategia busca capturar movimientos del mercado mediante un enfoque sistemático de grid trading, aprovechando oscilaciones del precio alrededor de un punto central, mientras gestiona el riesgo con coberturas y filtros de volatilidad.

### Gestión de Operaciones
- **Stop Loss y Take Profit**: Configurables en puntos (`StopLossPointsGraphics`, `HedgeStopLossPoints`, `HedgeTakeProfitPoints`) para posiciones principales y coberturas.
- **Límite de posiciones**: Controla el número máximo de posiciones abiertas por nivel (`MaxPositionsPerLevel`) y en todo el grid (`MaxGridPositions`).
- **Visualización**: Dibuja líneas en el gráfico para visualizar los niveles del grid y el punto central.

---

## 🛡️ Gestión de Riesgo (Alineada con FTMO)

**MECHA-GODZILLA** implementa un sistema de gestión de riesgo diseñado para cumplir con las estrictas reglas de los desafíos de fondeo como **FTMO**, que exigen límites de pérdida diaria, protección de capital y consistencia. A continuación, se detalla cómo se logra:

### 1. Límite de Pérdida Diaria
- **Parámetro**: `MaxDailyLossFTMO` (USD) define la pérdida máxima permitida en un día.
- **Cinturón de Seguridad**: El parámetro `SafetyBeltFactor` (0.0 a 1.0) reduce el límite efectivo de pérdida diaria. Por ejemplo, si `MaxDailyLossFTMO = 500` y `SafetyBeltFactor = 0.5`, el límite real es **250 USD**.
- **Cálculo**: Combina pérdidas realizadas y flotantes (`CalculateTotalDailyLoss`) para monitorear el riesgo en tiempo real.
- **Acción**: Si se alcanza el límite, el EA cierra todas las posiciones y desactiva el trading hasta el siguiente día (00:00 hora de España).

### 2. Saldo Mínimo Operativo
- **Parámetro**: `MinOperatingBalance` (USD) establece el nivel mínimo de capital para operar.
- **Acción**: Si el **equity** cae por debajo de este nivel, el EA cierra todas las posiciones y detiene el trading para proteger la cuenta.

### 3. Objetivo de Saldo
- **Parámetro**: `BalanceTarget` (USD) define una meta de ganancias. Si se activa (`UseBalanceTarget = true`), el EA cierra todas las posiciones y se detiene cuando tanto el saldo como la equidad alcanzan o superan este nivel.
- **Uso**: Ideal para desafíos de fondeo que requieren alcanzar un objetivo de rentabilidad sin violar reglas de riesgo.

### 4. Reseteo Diario
- **Lógica**: El EA reinicia los contadores de pérdida diaria y estado de trading a las **00:00 hora de España**, ajustado según el horario de verano/invierno (UTC+1 o UTC+2).
- **Beneficio**: Garantiza que las reglas de pérdida diaria se respeten según los ciclos de los proveedores de fondeo.

### 5. Filtro ATR
- **Lógica**: Si `UseAtrFilter` está activado, el EA solo abre posiciones si el valor del ATR está dentro del rango definido (`AtrLow` a `AtrHigh`), evitando operar en condiciones de volatilidad extrema.
- **Beneficio**: Reduce el riesgo de operar en mercados muy volátiles o demasiado quietos.

### 6. Coberturas (Hedging)
- **Lógica**: Si `UseHedging` está activado, el EA abre posiciones de cobertura (`HedgeContractSize`) cuando una posición principal se acerca a su Stop Loss, a una distancia definida (`HedgePointsBeforeSL`).
- **Control de Riesgo**: Las coberturas tienen Stop Loss y Take Profit independientes, limitando las pérdidas potenciales.

### 7. Validaciones de Seguridad
- **Parámetros Incorrectos**: Incluye validaciones para parámetros como `SafetyBeltFactor`, usando valores predeterminados seguros si son inválidos.

Esta gestión de riesgo asegura que **MECHA-GODZILLA** sea compatible con las reglas de FTMO, protegiendo la cuenta mientras maximiza las oportunidades de pasar los desafíos de fondeo.

---

## 📊 Resultados de Simulación

**MECHA-GODZILLA** no incluye resultados de simulación específicos en este repositorio. Sin embargo, ha sido probado en cuentas demo, donde ha demostrado ser capaz de maximizar ganancias significativas cuando el precio permanece dentro de estos rangos, cerrando objetivos de ganancias en muy poco tiempo con **0 operaciones perdedoras** en condiciones ideales. Esto lo hace un bot con un potencial de alta rentabilidad en mercados estables o de rango.

## 🕒 Prueba en un free trial de FTMO durante 6 días en AUDUSD:

- **[24-03-2025 a 28-03-2025 - Balance inicial 10,000 USD - Beneficio neto 507.18 USD](README02.md)**

**⚠️ Advertencia**: A pesar de su capacidad para generar ganancias rápidas, **MECHA-GODZILLA** puede ser **poco adecuado para cuentas de fondeo** como FTMO si el precio se sale de los rangos identificados. Su estrategia de grid trading lo hace **arriesgado** en mercados volátiles o en tendencias fuertes, ya que el bot puede acumular posiciones rápidamente, aumentando el riesgo de drawdown significativo. El éxito del bot depende en gran medida del buen criterio del usuario a la hora de elegir el activo específico en el que operará, el período de tiempo durante el cual se utilizará, y el objetivo de ganancias que se busca alcanzar. **MECHA-GODZILLA no es un bot que pueda dejarse operando en una cuenta sin supervisión continua**, ya que requiere monitoreo constante para evitar pérdidas significativas en condiciones de mercado desfavorables. Se recomienda realizar pruebas exhaustivas en el **Strategy Tester** de MetaTrader 5 con datos históricos en H1 para evaluar su rendimiento según las condiciones de tu broker y mercado.

---

## ⚙ Instalación

1. Guarda el archivo como `MECHA-GODZILLA.mq5` en tu carpeta de expertos: `<MetaTrader5>\MQL5\Experts`.
2. Abre MetaEditor y compílalo.
3. Aplica el EA al gráfico de un **par de divisas** (por ejemplo, USDJPY) en temporalidad **H1**.
4. Ajusta los parámetros si lo deseas, o usa los predeterminados para replicar la estrategia base.
5. Activa el **trading automático**.

---

## 🧾 Parámetros Configurables

| Parámetro                       | Descripción                                               | Valor por defecto |
|---------------------------------|-----------------------------------------------------------|-------------------|
| `Timeframe`                     | Marco temporal del gráfico                                | PERIOD_H1         |
| `InitialBalance`                | Saldo inicial de la cuenta en USD                         | 10000.0           |
| `FixedContractSize`             | Tamaño fijo del contrato                                  | 0.25              |
| `CandlesToConsider`             | Velas para calcular el punto central (si dinámico)        | 500               |
| `UseCandleBasedCentralPoint`    | Usar cálculo del punto central basado en velas            | false             |
| `FixedCentralPoint`             | Punto central fijo (si UseCandleBasedCentralPoint = false)| 5355.0            |
| `GridDistancePointsGraphics`    | Distancia entre niveles del grid (puntos)                 | 1500.0            |
| `MaxGridLevels`                 | Máximo número de niveles en el grid                      | 50                |
| `UseStopLoss`                   | Activar/desactivar Stop Loss                              | false             |
| `StopLossPointsGraphics`        | Stop Loss en puntos (posiciones normales)                 | 1500.0            |
| `UseHedging`                    | Activar/desactivar coberturas                             | false             |
| `HedgeContractSize`             | Tamaño del contrato para coberturas                       | 0.1               |
| `HedgePointsBeforeSL`           | Puntos antes del SL para la cobertura                     | 50.0              |
| `UseHedgeStopLoss`              | Activar/desactivar Stop Loss para coberturas              | false             |
| `HedgeStopLossPoints`           | Stop Loss en puntos para coberturas                       | 200.0             |
| `HedgeTakeProfitPoints`         | Take Profit en puntos para coberturas                     | 200.0             |
| `UseBalanceTarget`              | Activar objetivo de saldo                                 | true              |
| `BalanceTarget`                 | Objetivo de saldo para cerrar el bot                      | 9565.68           |
| `MinOperatingBalance`           | Saldo mínimo para operar                                  | 9050.0            |
| `MaxDailyLossFTMO`              | Pérdida diaria máxima permitida                           | 500.0             |
| `SafetyBeltFactor`              | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |
| `MaxPositionsPerLevel`          | Máximo número de posiciones por nivel del grid            | 2                 |
| `LimitGridPositions`            | Activar/desactivar límite de posiciones abiertas en el grid | true             |
| `MaxGridPositions`              | Máximo número de posiciones abiertas en el grid          | 6                 |
| `UseAtrFilter`                  | Activar/desactivar filtro de ATR                          | false             |
| `AtrPeriod`                     | Período del ATR                                           | 14                |
| `AtrHigh`                       | Límite superior del ATR (valor absoluto)                  | 0.0020            |
| `AtrLow`                        | Límite inferior del ATR (valor absoluto)                  | 0.0005            |

---

## 📝 Notas de Uso

- **Cuenta demo primero**: Siempre prueba el EA en entorno demo antes de aplicarlo en real.
- **FTMO-Friendly**: Los límites de pérdida y el control de saldo están alineados con requisitos típicos de pruebas de fondeo.
- **Optimizable**: El rendimiento puede mejorar según mercado, spread, y broker. Se recomienda evaluar la estrategia con el optimizador de MetaTrader para configurar los parámetros.
- **Filtro ATR**: Si `UseAtrFilter` está activado, ajusta `AtrHigh` y `AtrLow` según la volatilidad del instrumento para optimizar las entradas.

---

## 🪪 Licencia

© Jose Antonio Montero. Distribución sujeta a los términos de la licencia [MIT License](LICENSE.md).