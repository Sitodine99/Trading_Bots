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

**Tokyo Breakers** utiliza las **Bandas de Bollinger** para identificar momentos de alta volatilidad en el par USDJPY, implementando una estrategia de **seguimiento de tendencia** que desafía la teoría convencional de reversión al centro. En lugar de esperar retrocesos tras rupturas de las bandas, el EA busca capitalizar movimientos direccionales fuertes, entrando en la dirección de la ruptura. Tiene dos modos de operación según la configuración:

### 1. Modo Ruptura de Vela Anterior (Por defecto, `UseBreakoutDistance = false`)
- **Lógica**:
  - Si la **vela anterior cierra por encima** de la banda superior de Bollinger, el EA abre una **posición de compra**, anticipando la continuación del movimiento alcista.
  - Si la **vela anterior cierra por debajo** de la banda inferior, el EA abre una **posición de venta**, esperando un movimiento bajista sostenido.
- **Razonamiento**: Este modo aprovecha la tendencia tras expansiones de volatilidad, típicas en USDJPY durante sesiones de alta actividad (como la sesión asiática), asumiendo que las rupturas significan momentum direccional.
- **Filtros**:
  - Separación mínima entre operaciones (`CandleSeparation`) para evitar sobreoperar.
  - Máximo de posiciones abiertas por dirección (`MaxPositions`) para limitar la exposición.

### 2. Modo Ruptura en Vela Actual (`UseBreakoutDistance = true`)
- **Lógica**:
  - Si el precio actual supera la banda superior de Bollinger por una distancia definida (`BreakoutDistancePoints`), el EA abre una **posición de compra** a favor del movimiento alcista.
  - Si el precio cae por debajo de la banda inferior por la misma distancia, abre una **posición de venta** en dirección bajista.
- **Razonamiento**: Este modo captura rupturas de tendencia en tiempo real, ideal para movimientos explosivos tras noticias o en sesiones volátiles, confirmando el momentum con la distancia de ruptura.
- **Filtros**:
  - Similar a los del modo anterior, con énfasis en la distancia de ruptura para filtrar señales falsas.

### Gestión de Operaciones
- **Stop Loss y Take Profit**: Definidos en puntos (`SL_Points`, `TP_Points`) para cada operación, asegurando un riesgo controlado.
- **Trailing Stop**: Activable (`UseTrailingStop`) y configurable (`TrailingStopActivation`, `TrailingStopStep`) para proteger ganancias en tendencias prolongadas.
- **Multiplicador de Contratos**: Si está activado (`UseComboMultiplier`), el tamaño del lote aumenta (`ComboMultiplier`) tras una operación ganadora, hasta un máximo (`MaxContractSize`).
- **Espaciado Temporal**: Evita operar demasiado rápido al exigir un número mínimo de velas entre operaciones (`CandleSeparation`).
- **Límite de Posiciones**: Restringe el número de operaciones abiertas por dirección (`MaxPositions`) para evitar acumulación de riesgo.

---

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