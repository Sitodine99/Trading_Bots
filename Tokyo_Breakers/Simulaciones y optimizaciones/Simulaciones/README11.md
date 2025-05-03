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
| `UseComboMultiplier`        | Activar multiplicador de lotes tras ganancia              | true              |
| `ComboMultiplier`           | Multiplicador en rachas ganadoras                         | 1.4               |
| `MaxContractSize`           | Tamaño máximo de lote                                     | 2.0               |
| `UseBreakoutDistance`       | Activar ruptura en la vela actual                         | true              |
| `BreakoutDistancePoints`    | Distancia mínima para confirmar la ruptura                | 250               |
| `MaxDailyLossFTMO`          | Pérdida diaria máxima permitida                           | 500.0             |
| `SafetyBeltFactor`          | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |
| `UseBalanceTarget`          | Activar objetivo de balance                               | true              |
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
| **Beneficio Neto**               | -951.09 USD       |
| **Beneficio Bruto**              | 953.36 USD        |
| **Pérdidas Brutas**              | -1,904.45 USD     |
| **Factor de Beneficio**          | 0.50              |
| **Beneficio Esperado**           | -29.72 USD        |
| **Factor de Recuperación**       | -0.76             |
| **Ratio de Sharpe**              | -5.00             |
| **Z-Score**                      | -0.64 (47.78%)    |
| **AHPR**                         | 0.9970 (-0.30%)   |
| **GHPR**                         | 0.9969 (-0.31%)   |
| **Reducción absoluta del balance** | 951.09 USD      |
| **Reducción absoluta de la equidad** | 951.09 USD    |
| **Reducción máxima del balance** | 1,191.42 USD (11.63%) |
| **Reducción máxima de la equidad** | 1,247.88 USD (12.12%) |
| **Reducción relativa del balance** | 11.63% (1,191.42 USD) |
| **Reducción relativa de la equidad** | 12.12% (1,247.88 USD) |
| **Nivel de margen**              | 181.79%           |
| **LR Correlation**               | -0.95             |
| **LR Standard Error**            | 107.50            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 32                |
| **Total de transacciones**                | 64                |
| **Posiciones rentables (% del total)**    | 23 (71.88%)       |
| **Posiciones no rentables (% del total)** | 9 (28.12%)        |
| **Posiciones cortas (% rentables)**       | 21 (80.95%)       |
| **Posiciones largas (% rentables)**       | 11 (54.55%)       |
| **Transacción rentable promedio**         | 41.45 USD         |
| **Transacción no rentable promedio**      | -208.27 USD       |
| **Transacción rentable máxima**           | 93.92 USD         |
| **Transacción no rentable máxima**        | -428.79 USD       |
| **Máximo de ganancias consecutivas**      | 5 (245.29 USD)    |
| **Máximo de pérdidas consecutivas**       | 3 (-355.45 USD)   |
| **Máximo de beneficio consecutivo**       | 245.29 USD (5)    |
| **Máximo de pérdidas consecutivas**       | -428.79 USD (1)   |
| **Promedio de ganancias consecutivas**    | 4                 |
| **Promedio de pérdidas consecutivas**     | 2                 |

---

## 🎲 Gráfico de Rendimiento

![Gráfico General](ReportTester-03M.png)

---

## 🔍 Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros (`TrailingStopActivation`, `TrailingStopStep`, `ComboMultiplier`), con `UseComboMultiplier` activado para esta simulación.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de 1 mes (01-03-2025 a 31-03-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.