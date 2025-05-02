# 🎱 Simulación Optimizada: 01-01-2025 a 31-01-2025

Esta simulación fue realizada para el Expert Advisor **Tokyo_Breakers** en MetaTrader 5, utilizando datos históricos del par **USDJPY** desde el **1 de enero de 2025** hasta el **31 de enero de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, logrando un equilibrio entre rentabilidad y estabilidad.

---

## 🔙 Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: Tokyo_Breakers
- **Símbolo**: USDJPY
- **Período**: H1 (2025.01.01 - 2025.01.31)
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
| `UseComboMultiplier`        | Activar multiplicador de lotes tras ganancia              | false             |
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
| **Calidad del historial**        | 100%              |
| **Barras**                       | 504               |
| **Ticks**                        | 1,961,797         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | -316.25 USD       |
| **Beneficio Bruto**              | 2,561.36 USD      |
| **Pérdidas Brutas**              | -2,877.61 USD     |
| **Factor de Beneficio**          | 0.89              |
| **Beneficio Esperado**           | -2.15 USD         |
| **Factor de Recuperación**       | -0.51             |
| **Ratio de Sharpe**              | -2.42             |
| **Z-Score**                      | -1.07 (71.54%)    |
| **AHPR**                         | 0.9998 (-0.02%)   |
| **GHPR**                         | 0.9998 (-0.02%)   |
| **Reducción absoluta del balance** | 595.29 USD      |
| **Reducción absoluta de la equidad** | 600.50 USD    |
| **Reducción máxima del balance** | 613.98 USD (6.13%) |
| **Reducción máxima de la equidad** | 621.54 USD (6.20%) |
| **Reducción relativa del balance** | 6.13% (613.98 USD) |
| **Reducción relativa de la equidad** | 6.20% (621.54 USD) |
| **Nivel de margen**              | 315.75%           |
| **LR Correlation**               | -0.15             |
| **LR Standard Error**            | 115.19            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 147               |
| **Total de transacciones**                | 294               |
| **Posiciones rentables (% del total)**    | 110 (74.83%)      |
| **Posiciones no rentables (% del total)** | 37 (25.17%)       |
| **Posiciones cortas (% rentables)**       | 76 (82.89%)       |
| **Posiciones largas (% rentables)**       | 71 (66.20%)       |
| **Transacción rentable promedio**         | 23.29 USD         |
| **Transacción no rentable promedio**      | -75.99 USD        |
| **Transacción rentable máxima**           | 62.63 USD         |
| **Transacción no rentable máxima**        | -82.13 USD        |
| **Máximo de ganancias consecutivas**      | 11 (222.17 USD)   |
| **Máximo de pérdidas consecutivas**       | 4 (-309.10 USD)   |
| **Máximo de beneficio consecutivo**       | 282.65 USD (9)    |
| **Máximo de pérdidas consecutivas**       | -309.10 USD (4)   |
| **Promedio de ganancias consecutivas**    | 4                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 🎲 Gráfico de Rendimiento

![Gráfico General](ReportTester-01.png)

---

## 🔍 Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros (`TrailingStopActivation`, `TrailingStopStep`, `ComboMultiplier`), aunque `UseComboMultiplier` estaba desactivado para esta simulación.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de 1 mes (01-01-2025 a 31-01-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.