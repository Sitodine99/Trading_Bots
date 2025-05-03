# 🎱 Simulación Optimizada: 01-01-2024 a 01-05-2025

Esta simulación fue realizada para el Expert Advisor **Tokyo_Breakers** en MetaTrader 5, utilizando datos históricos del par **USDJPY** desde el **1 de enero de 2024** hasta el **1 de mayo de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, logrando un equilibrio entre rentabilidad y estabilidad.

---

## 🔙 Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: Tokyo_Breakers
- **Símbolo**: USDJPY
- **Período**: H1 (2024.01.01 - 2025.05.01)
- **Empresa**: FTMO Global Markets Ltd
- **Divisa**: USD
- **Depósito inicial**: 10,000.00 USD
- **Apalancamiento**: 1:30

### Parámetros de Entrada

| Parámetro                   | Descripción                                               | Valor Utilizado   |
|-----------------------------|-----------------------------------------------------------|-------------------|
| `BB_Period`                 | Periodo de las Bandas de Bollinger                        | 14                |
| `BB_Deviation`              | Desviación estándar para las bandas                       | 1.0               |
| `LotSize`                   | Tamaño de lote inicial                                    | 0.3               |
| `SL_Points`                 | Stop Loss en puntos                                       | 390               |
| `TP_Points`                 | Take Profit en puntos                                     | 350               |
| `UseTrailingStop`           | Activar/desactivar trailing stop                          | true              |
| `TrailingStopActivation`    | Beneficio necesario para activar trailing stop            | 110               |
| `TrailingStopStep`          | Paso del trailing stop en puntos                          | 10                |
| `MaxPositions`              | Máximo de operaciones abiertas por dirección              | 3                 |
| `CandleSeparation`          | Velas mínimas entre operaciones nuevas                    | 2                 |
| `UseComboMultiplier`        | Activar multiplicador de lotes tras ganancia              | true              |
| `ComboMultiplier`           | Multiplicador en rachas ganadoras                         | 1.4               |
| `MaxContractSize`           | Tamaño máximo de lote                                     | 2.0               |
| `UseBreakoutDistance`       | Activar ruptura en la vela actual                         | true              |
| `BreakoutDistancePoints`    | Distancia mínima para confirmar la ruptura                | 250               |
| `MaxDailyLossFTMO`          | Pérdida diaria máxima permitida                           | 500.0             |
| `SafetyBeltFactor`          | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |
| `UseBalanceTarget`          | Activar objetivo de balance                               | false             |
| `BalanceTarget`             | Objetivo de balance para cerrar el bot                    | 11000.0           |
| `MinOperatingBalance`       | Balance mínimo para operar                                | 9050.0            |

---

## 🎳 Resultados de la Simulación

### Resumen General

| Métrica                          | Valor              |
|----------------------------------|--------------------|
| **Calidad del historial**        | 41%               |
| **Barras**                       | 8,280             |
| **Ticks**                        | 30,722,778        |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 45,226.07 USD     |
| **Beneficio Bruto**              | 147,460.15 USD    |
| **Pérdidas Brutas**              | -102,234.08 USD   |
| **Factor de Beneficio**          | 1.44              |
| **Beneficio Esperado**           | 23.31 USD         |
| **Factor de Recuperación**       | 12.24             |
| **Ratio de Sharpe**              | 6.52              |
| **Z-Score**                      | -7.87 (99.74%)    |
| **AHPR**                         | 1.0009 (0.09%)    |
| **GHPR**                         | 1.0009 (0.09%)    |
| **Reducción absoluta del balance** | 263.42 USD      |
| **Reducción absoluta de la equidad** | 330.64 USD    |
| **Reducción máxima del balance** | 3,414.26 USD (5.96%) |
| **Reducción máxima de la equidad** | 3,694.37 USD (6.43%) |
| **Reducción relativa del balance** | 8.41% (1,921.51 USD) |
| **Reducción relativa de la equidad** | 9.71% (2,236.72 USD) |
| **Nivel de margen**              | 101.02%           |
| **LR Correlation**               | 0.94              |
| **LR Standard Error**            | 5,611.12          |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 1940              |
| **Total de transacciones**                | 3880              |
| **Posiciones rentables (% del total)**    | 1434 (73.92%)     |
| **Posiciones no rentables (% del total)** | 506 (26.08%)      |
| **Posiciones cortas (% rentables)**       | 883 (74.18%)      |
| **Posiciones largas (% rentables)**       | 1057 (73.70%)     |
| **Transacción rentable promedio**         | 102.83 USD        |
| **Transacción no rentable promedio**      | -196.71 USD       |
| **Transacción rentable máxima**           | 1,186.70 USD      |
| **Transacción no rentable máxima**        | -661.03 USD       |
| **Máximo de ganancias consecutivas**      | 16 (3,483.93 USD) |
| **Máximo de pérdidas consecutivas**       | 6 (-505.21 USD)   |
| **Máximo de beneficio consecutivo**       | 3,813.76 USD (13) |
| **Máximo de pérdidas consecutivas**       | -1,603.99 USD (3) |
| **Promedio de ganancias consecutivas**    | 5                 |
| **Promedio de pérdidas consecutivas**     | 2                 |

---

## 🎲 Gráfico de Rendimiento

![Gráfico General](ReportTester-550097668.png)

---

## 🔍 Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros (`TrailingStopActivation`, `TrailingStopStep`, `ComboMultiplier`).
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de 16 meses (01-01-2024 a 01-05-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.