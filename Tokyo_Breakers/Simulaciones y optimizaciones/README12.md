# 🎱 Simulación Optimizada: 01-04-2025 a 30-04-2025

Esta simulación fue realizada para el Expert Advisor **Tokyo_Breakers** en MetaTrader 5, utilizando datos históricos del par **USDJPY** desde el **1 de abril de 2025** hasta el **30 de abril de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, logrando un equilibrio entre rentabilidad y estabilidad.

---

## 🔙 Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: Tokyo_Breakers
- **Símbolo**: USDJPY
- **Período**: H1 (2025.04.01 - 2025.04.30)
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
| `MaxPositions`              | Máximo de operaciones abiertas por dirección              | 2                 |
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
| **Calidad del historial**        | 100%              |
| **Barras**                       | 504               |
| **Ticks**                        | 2,418,655         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 1,100.46 USD      |
| **Beneficio Bruto**              | 6,862.52 USD      |
| **Pérdidas Brutas**              | -5,762.06 USD     |
| **Factor de Beneficio**          | 1.19              |
| **Beneficio Esperado**           | 10.00 USD         |
| **Factor de Recuperación**       | 0.88              |
| **Ratio de Sharpe**              | 3.77              |
| **Z-Score**                      | -0.59 (44.48%)    |
| **AHPR**                         | 1.0011 (0.11%)    |
| **GHPR**                         | 1.0009 (0.09%)    |
| **Reducción absoluta del balance** | 34.91 USD       |
| **Reducción absoluta de la equidad** | 116.73 USD    |
| **Reducción máxima del balance** | 1,141.52 USD (10.28%) |
| **Reducción máxima de la equidad** | 1,254.76 USD (10.37%) |
| **Reducción relativa del balance** | 10.28% (1,141.52 USD) |
| **Reducción relativa de la equidad** | 11.22% (1,249.64 USD) |
| **Nivel de margen**              | 148.25%           |
| **LR Correlation**               | 0.71              |
| **LR Standard Error**            | 330.98            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 110               |
| **Total de transacciones**                | 220               |
| **Posiciones rentables (% del total)**    | 84 (76.36%)       |
| **Posiciones no rentables (% del total)** | 26 (23.64%)       |
| **Posiciones cortas (% rentables)**       | 62 (77.42%)       |
| **Posiciones largas (% rentables)**       | 48 (75.00%)       |
| **Transacción rentable promedio**         | 81.70 USD         |
| **Transacción no rentable promedio**      | -215.82 USD       |
| **Transacción rentable máxima**           | 483.11 USD        |
| **Transacción no rentable máxima**        | -570.49 USD       |
| **Máximo de ganancias consecutivas**      | 11 (1,128.51 USD) |
| **Máximo de pérdidas consecutivas**       | 4 (-822.33 USD)   |
| **Máximo de beneficio consecutivo**       | 1,413.24 USD (8)  |
| **Máximo de pérdidas consecutivas**       | -822.33 USD (4)   |
| **Promedio de ganancias consecutivas**    | 4                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 🎲 Gráfico de Rendimiento

![Gráfico General](ReportTester-04M.png)

---

## 🔍 Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros (`TrailingStopActivation`, `TrailingStopStep`, `ComboMultiplier`), con `UseComboMultiplier` activado para esta simulación.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de 1 mes (01-04-2025 a 30-04-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.