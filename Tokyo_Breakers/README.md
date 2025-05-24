# Tokyo Breakers

![Tokyo Breakers Logo](images/Tokyo_Breakers_logo.png)

**Tokyo Breakers** es un **Expert Advisor (EA)** desarrollado para **MetaTrader 5**, diseñado exclusivamente para operar en el par **USDJPY** en el marco temporal de **1 hora (H1)**. Este bot automatiza operaciones basadas en **rupturas de Bandas de Bollinger** combinadas con un filtro de **Momentum**, optimizado para capturar movimientos de alta volatilidad durante la sesión asiática, alineado con los requisitos de desafíos de fondeo como **FTMO**.

El EA incluye herramientas avanzadas de gestión de capital, como **Stop Loss**, **Take Profit**, **Trailing Stop**, límites de **pérdida diaria**, y un sistema de **multiplicador de contratos** para maximizar el rendimiento tras operaciones ganadoras. Su diseño equilibra rentabilidad y control de riesgo, respetando las reglas estrictas de los programas de fondeo.

---

## 📌 Características Principales

- **Par exclusivo**: Opera únicamente en **USDJPY** (H1).
- **Estrategia combinada**: Usa **Bandas de Bollinger** para detectar rupturas y **Momentum** como filtro de confirmación.
- **Gestión de riesgo avanzada**: Cumple con los límites de pérdida diaria y objetivos de fondeo de FTMO.
- **Trailing Stop dinámico**: Ajusta el Stop Loss para proteger beneficios.
- **Multiplicador de contratos**: Aumenta el tamaño del lote tras operaciones ganadoras (opcional).
- **Protección de capital**: Cierre automático por pérdida diaria máxima, saldo mínimo o meta de balance alcanzada.
- **Configuración flexible**: Amplios parámetros ajustables para adaptarse a diferentes estilos de trading.
- **Espera de cierre dentro de bandas**: Evita operar tras rupturas hasta que el precio cierre dentro de las Bandas de Bollinger, reduciendo entradas en mercados extremos.

---

## 🚀 Estrategia de Trading

**Tokyo Breakers** opera en el par **USDJPY** en el timeframe H1, utilizando una estrategia de seguimiento de tendencia que combina **Bandas de Bollinger** y **Momentum** para capturar movimientos direccionales fuertes durante sesiones de alta volatilidad, como la asiática. A diferencia de estrategias de reversión a la media, este EA entra en la dirección de la ruptura para aprovechar el momentum.

### Lógica Principal
El EA emplea **Bandas de Bollinger** (período y desviación configurables) y **Momentum** (período y umbrales configurables) en H1 para detectar condiciones de alta volatilidad y confirmar la fuerza del movimiento:
- **Compra**: 
  - La vela anterior cierra por encima de la banda superior de Bollinger.
  - El indicador Momentum supera el umbral de compra (`Momentum_Buy_Level`).
  - El EA abre una posición de compra, anticipando continuación alcista.
- **Venta**: 
  - La vela anterior cierra por debajo de la banda inferior de Bollinger.
  - El indicador Momentum cae por debajo del umbral de venta (`Momentum_Sell_Level`).
  - El EA abre una posición de venta, esperando un movimiento bajista.
- **Razonamiento**: La ruptura de las Bandas de Bollinger en USDJPY, especialmente en la sesión asiática, señala momentum fuerte. El filtro de Momentum confirma la fuerza del movimiento, reduciendo falsas entradas.
- **Filtros**:
  - **Espera de cierre dentro de bandas**: Tras una operación, el EA espera a que una vela cierre dentro de las bandas antes de permitir nuevas operaciones, evitando entradas en mercados sobreextendidos.
  - **Máximo de posiciones por dirección** (`MaxPositions`) para controlar el riesgo.
  - **Tiempo mínimo entre operaciones** (60 segundos desde el último cierre) para evitar sobreoperar.

### Opción Adicional (UseBreakoutDistance)
Si se activa (`UseBreakoutDistance`), el EA abre operaciones en la vela actual sin esperar al cierre, siempre que el precio supere la banda superior o inferior por una distancia definida (`BreakoutDistancePoints`):
- **Compra**: Precio actual > Banda superior + `BreakoutDistancePoints`.
- **Venta**: Precio actual < Banda inferior - `BreakoutDistancePoints`.
- **Razonamiento**: Captura rupturas explosivas (ej., por noticias), usando `BreakoutDistancePoints` como filtro para evitar falsas rupturas.
- **Filtros**: Aplica las mismas restricciones de posiciones máximas y tiempo mínimo entre operaciones.

### Gestión de Operaciones y Riesgo
**Tokyo Breakers** incluye herramientas robustas para gestionar operaciones y controlar el riesgo, asegurando un trading disciplinado:

- **Stop Loss y Take Profit**: Cada operación tiene un **Stop Loss** (`SL_Points`) y un **Take Profit** (`TP_Points`) definidos en puntos.
- **Trailing Stop**: Activable con `UseTrailingStop`. Una vez que la operación alcanza un beneficio mínimo (`TrailingStopActivation`), el EA ajusta el Stop Loss (`TrailingStopStep`) para proteger ganancias en tendencias prolongadas.
- **Multiplicador de Lotes**: Si `UseComboMultiplier` está activado, el EA aumenta el tamaño del lote (`ComboMultiplier`) tras una operación ganadora, hasta un máximo (`MaxContractSize`). Tras una pérdida, el lote vuelve al tamaño inicial (`LotSize`).
- **Límites de Posiciones**: Restringe el número máximo de posiciones abiertas por dirección (`MaxPositions`).
- **Gestión de Capital**:
  - **Objetivo de Saldo**: Si `UseBalanceTarget` está activado, el EA cierra todas las posiciones y se desactiva al alcanzar un saldo objetivo (`BalanceTarget`).
  - **Saldo Mínimo**: Si el equity cae por debajo de `MinOperatingBalance`, el EA cierra todas las posiciones y se detiene.
  - **Límite de Pérdida Diaria**: Limita las pérdidas diarias (`MaxDailyLossFTMO`), ajustado por un factor de seguridad (`SafetyBeltFactor`). Si se alcanza, el EA cierra todas las posiciones y se desactiva hasta el próximo día.
- **Cierre Masivo**: Cierra posiciones preexistentes en USDJPY al iniciar el EA para garantizar un entorno limpio.

### Por qué USDJPY y la Sesión de Tokio
El par **USDJPY** exhibe alta volatilidad durante la sesión asiática, especialmente en Tokio, debido a noticias económicas o ajustes de mercado. Las **Bandas de Bollinger** identifican expansiones de volatilidad, mientras que el **Momentum** confirma la fuerza del movimiento. **Tokyo Breakers** está optimizado para estas condiciones, entrando cuando el mercado muestra un momentum claro.

## 🛡️ Gestión de Riesgo (Alineada con FTMO)

**Tokyo Breakers** implementa un sistema de gestión de riesgo diseñado para cumplir con las reglas de desafíos de fondeo como **FTMO**, que exigen límites de pérdida diaria, protección de capital y consistencia:

### 1. Límite de Pérdida Diaria
- **Parámetro**: `MaxDailyLossFTMO` (USD) define la pérdida máxima permitida en un día.
- **Cinturón de Seguridad**: `SafetyBeltFactor` (0.0 a 1.0) reduce el límite efectivo de pérdida diaria. Ejemplo: Si `MaxDailyLossFTMO = 500` y `SafetyBeltFactor = 0.5`, el límite real es **250 USD**.
- **Cálculo**: Combina pérdidas realizadas y flotantes (`CalculateTotalDailyLoss`) en tiempo real.
- **Acción**: Si se alcanza el límite, el EA cierra todas las posiciones y desactiva el trading hasta las 00:00 (hora de España).

### 2. Saldo Mínimo Operativo
- **Parámetro**: `MinOperatingBalance` (USD) establece el nivel mínimo de capital.
- **Acción**: Si el **equity** cae por debajo, el EA cierra todas las posiciones y detiene el trading.

### 3. Objetivo de Saldo
- **Parámetro**: `BalanceTarget` (USD) define una meta de ganancias. Si `UseBalanceTarget = true`, el EA cierra todas las posiciones y se detiene al alcanzarla.
- **Uso**: Ideal para desafíos de fondeo con objetivos de rentabilidad.

### 4. Reseteo Diario
- **Lógica**: Reinicia contadores de pérdida diaria y estado de trading a las **00:00 hora de España** (UTC+1 o UTC+2 según horario de verano/invierno).
- **Beneficio**: Asegura cumplimiento con ciclos de fondeo.

### 5. Multiplicador de Contratos
- **Lógica**: Tras una operación ganadora, el lote puede aumentar (`ComboMultiplier`), limitado por `MaxContractSize`. Tras una pérdida, vuelve a `LotSize`.
- **Control de Riesgo**: Evita exposición excesiva tras rachas perdedoras.

### 6. Validaciones de Seguridad
- **Símbolo Exclusivo**: Verifica que se ejecute en **USDJPY**, deteniéndose si se usa en otro par.
- **Parámetros Incorrectos**: Usa valores predeterminados seguros para parámetros como `SafetyBeltFactor` o `TrailingStopStep` si son inválidos.
- **Gestión de Cierres Manuales**: Detecta cierres manuales y ajusta el multiplicador de lotes en consecuencia.

Esta gestión asegura compatibilidad con FTMO, protegiendo la cuenta mientras maximiza las oportunidades de pasar desafíos de fondeo.

---

## 📊 Resultados de Simulación

**Tokyo Breakers** ha sido evaluado con datos reales en MetaTrader 5 usando parámetros optimizados. Consulta los resultados en:  
- **[Resultados de Simulación](Simulaciones%20y%20optimizaciones/README.md)**

## ⚙ Instalación

1. Guarda el archivo como `TokyoBreakers.mq5` en `<MetaTrader5>\MQL5\Experts`.
2. Abre MetaEditor y compila el archivo.
3. Aplica el EA al gráfico **USDJPY** en temporalidad **H1**.
4. Ajusta los parámetros o usa los valores por defecto para replicar los resultados de la simulación.
5. Activa el **trading automático**.

## 🧾 Parámetros Configurables

| Parámetro                   | Descripción                                               | Valor por defecto |
|-----------------------------|-----------------------------------------------------------|-------------------|
| **Configuración Indicador (Bandas de Bollinger)** | | |
| `BB_Period`                 | Periodo de las Bandas de Bollinger                        | 15                |
| `BB_Deviation`              | Desviación estándar para las bandas                       | 1.4               |
| **Configuración Indicador Momentum** | | |
| `Momentum_Period`           | Período del indicador Momentum                            | 14                |
| `Momentum_Buy_Level`        | Umbral de Momentum para compras                           | 101.5             |
| `Momentum_Sell_Level`       | Umbral de Momentum para ventas                            | 99.5              |
| **Gestión de Riesgo**       | | |
| `LotSize`                   | Tamaño de lote inicial                                    | 0.3               |
| `SL_Points`                 | Stop Loss en puntos                                       | 400               |
| `TP_Points`                 | Take Profit en puntos                                     | 300               |
| `UseTrailingStop`           | Activar/desactivar trailing stop                          | true              |
| `TrailingStopActivation`    | Beneficio necesario para activar trailing stop (puntos)   | 200               |
| `TrailingStopStep`          | Paso del trailing stop en puntos                          | 200               |
| `MaxPositions`              | Máximo de operaciones abiertas por dirección              | 2                 |
| **Configuración Operaciones** | | |
| `UseComboMultiplier`        | Activar multiplicador de lotes tras ganancia              | true              |
| `ComboMultiplier`           | Multiplicador en rachas ganadoras                         | 1.6               |
| `MaxContractSize`           | Tamaño máximo de lote                                     | 1.5               |
| `UseBreakoutDistance`       | Activar ruptura en la vela actual                         | false             |
| `BreakoutDistancePoints`    | Distancia mínima para confirmar la ruptura (puntos)       | 167               |
| **Gestión de Cuenta (FTMO y Similares)** | | |
| `MaxDailyLossFTMO`          | Pérdida diaria máxima permitida (USD)                     | 500.0             |
| `SafetyBeltFactor`          | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |
| `UseBalanceTarget`          | Activar objetivo de saldo                                 | false             |
| `BalanceTarget`             | Objetivo de saldo para cerrar el bot (USD)                | 11000.0           |
| `MinOperatingBalance`       | Saldo mínimo operativo (USD)                              | 9050.0            |

## 📝 Notas de Uso

- **Cuenta demo primero**: Prueba el EA en un entorno demo antes de usarlo en real.
- **FTMO-Friendly**: Los límites de pérdida y el control de balance están alineados con requisitos de pruebas de fondeo.
- **Optimizable**: El rendimiento puede variar según mercado, spread y broker. Usa el optimizador de MetaTrader para ajustar parámetros.
- **Gestión de cierres manuales**: El EA detecta cierres manuales y ajusta el multiplicador de lotes, asegurando consistencia en la gestión de capital.

## 🪪 Licencia

© Jose Antonio Montero. Distribución sujeta a los términos de la licencia [MIT License](LICENSE.md).