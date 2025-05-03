# 🎱 Simulación Optimizada: 01-03-2025 a 31-03-2025

Esta simulación fue realizada para el Expert Advisor **Tokyo_Breakers** en MetaTrader 5, utilizando datos históricos del par **USDJPY** desde el **1 de marzo de 2025** hasta el **31 de marzo de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, logrando un equilibrio entre rentabilidad y estabilidad.

---

## 🔙 Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: Tokyo_Breakers
- **Símbolo**: USDJPY
- **Período**: H1 (2025.03.01 - 2025.03.31)
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
| **Barras**                       | 480               |
| **Ticks**                        | 1,972,676         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | -711.01 USD       |
| **Beneficio Bruto**              | 2,662.76 USD      |
| **Pérdidas Brutas**              | -3,373.77 USD     |
| **Factor de Beneficio**          | 0.79              |
| **Beneficio Esperado**           | -4.53 USD         |
| **Factor de Recuperación**       | -0.72             |
| **Ratio de Sharpe**              | -5.00             |
| **Z-Score**                      | -1.64 (89.90%)    |
| **AHPR**                         | 0.9995 (-0.05%)   |
| **GHPR**                         | 0.9995 (-0.05%)   |
| **Reducción absoluta del balance** | 771.02 USD      |
| **Reducción absoluta de la equidad** | 838.01 USD    |
| **Reducción máxima del balance** | 899.66 USD (8.88%) |
| **Reducción máxima de la equidad** | 983.94 USD (9.70%) |
| **Reducción relativa del balance** | 8.88% (899.66 USD) |
| **Reducción relativa de la equidad** | 9.70% (983.94 USD) |
| **Nivel de margen**              | 306.56%           |
| **LR Correlation**               | -0.80             |
| **LR Standard Error**            | 142.86            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 157               |
| **Total de transacciones**                | 314               |
| **Posiciones rentables (% del total)**    | 115 (73.25%)      |
| **Posiciones no rentables (% del total)** | 42 (26.75%)       |
| **Posiciones cortas (% rentables)**       | 76 (72.37%)       |
| **Posiciones largas (% rentables)**       | 81 (74.07%)       |
| **Transacción rentable promedio**         | 23.15 USD         |
| **Transacción no rentable promedio**      | -78.65 USD        |
| **Transacción rentable máxima**           | 41.24 USD         |
| **Transacción no rentable máxima**        | -98.35 USD        |
| **Máximo de ganancias consecutivas**      | 16 (377.79 USD)   |
| **Máximo de pérdidas consecutivas**       | 4 (-248.70 USD)   |
| **Máximo de beneficio consecutivo**       | 377.79 USD (16)   |
| **Máximo de pérdidas consecutivas**       | -259.70 USD (3)   |
| **Promedio de ganancias consecutivas**    | 4                 |
| **Promedio de pérdidas consecutivas**     | 2                 |

---

## 🎲 Gráfico de Rendimiento

![Gráfico General](ReportTester-03.png)

---

## 🔍 Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros (`TrailingStopActivation`, `TrailingStopStep`, `ComboMultiplier`), aunque `UseComboMultiplier` estaba desactivado para esta simulación.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de 1 mes (01-03-2025 a 31-03-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.