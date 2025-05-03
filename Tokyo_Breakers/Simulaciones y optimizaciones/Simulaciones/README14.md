# 🎱 Simulación Optimizada: 01-01-2025 a 30-04-2025

Esta simulación fue realizada para el Expert Advisor **Tokyo_Breakers** en MetaTrader 5, utilizando datos históricos del par **USDJPY** desde el **1 de enero de 2025** hasta el **30 de abril de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, logrando un equilibrio entre rentabilidad y estabilidad.

---

## 🔙 Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: Tokyo_Breakers
- **Símbolo**: USDJPY
- **Período**: H1 (2025.01.01 - 2025.04.30)
- **Empresa**: FTMO Global Markets Ltd
- **Divisa**: USD
- **Depósito inicial**: 9,346.00 USD
- **Apalancamiento**: 1:30

### Parámetros de Entrada

| Parámetro                   | Descripción                                               | Valor Utilizado   |
|-----------------------------|-----------------------------------------------------------|-------------------|
| `BB_Period`                 | Periodo de las Bandas de Bollinger                        | 40                |
| `BB_Deviation`              | Desviación estándar para las bandas                       | 1.0               |
| `LotSize`                   | Tamaño de lote inicial                                    | 0.3               |
| `SL_Points`                 | Stop Loss en puntos                                       | 390               |
| `TP_Points`                 | Take Profit en puntos                                     | 350               |
| `UseTrailingStop`           | Activar/desactivar trailing stop                          | true              |
| `TrailingStopActivation`    | Beneficio necesario para activar trailing stop            | 110               |
| `TrailingStopStep`          | Paso del trailing stop en puntos                          | 10                |
| `MaxPositions`              | Máximo de operaciones abiertas por dirección              | 2                 |
| `CandleSeparation`          | Velas mínimas entre operaciones nuevas                    | 8                 |
| `UseComboMultiplier`        | Activar multiplicador de lotes tras ganancia              | true              |
| `ComboMultiplier`           | Multiplicador en rachas ganadoras                         | 1.4               |
| `MaxContractSize`           | Tamaño máximo de lote                                     | 0.5               |
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
| **Barras**                       | 2,016             |
| **Ticks**                        | 8,365,506         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 2,379.55 USD      |
| **Beneficio Bruto**              | 6,214.42 USD      |
| **Pérdidas Brutas**              | -3,834.87 USD     |
| **Factor de Beneficio**          | 1.62              |
| **Beneficio Esperado**           | 12.59 USD         |
| **Factor de Recuperación**       | 7.23              |
| **Ratio de Sharpe**              | 10.81             |
| **Z-Score**                      | 1.81 (92.97%)     |
| **AHPR**                         | 1.0012 (0.12%)    |
| **GHPR**                         | 1.0012 (0.12%)    |
| **Reducción absoluta del balance** | 77.62 USD       |
| **Reducción absoluta de la equidad** | 88.85 USD     |
| **Reducción máxima del balance** | 238.97 USD (2.48%) |
| **Reducción máxima de la equidad** | 329.08 USD (3.40%) |
| **Reducción relativa del balance** | 2.48% (238.97 USD) |
| **Reducción relativa de la equidad** | 3.40% (329.08 USD) |
| **Nivel de margen**              | 280.27%           |
| **LR Correlation**               | 0.98              |
| **LR Standard Error**            | 168.83            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 189               |
| **Total de transacciones**                | 378               |
| **Posiciones rentables (% del total)**    | 160 (84.66%)      |
| **Posiciones no rentables (% del total)** | 29 (15.34%)       |
| **Posiciones cortas (% rentables)**       | 108 (86.11%)      |
| **Posiciones largas (% rentables)**       | 81 (82.72%)       |
| **Transacción rentable promedio**         | 38.84 USD         |
| **Transacción no rentable promedio**      | -127.77 USD       |
| **Transacción rentable máxima**           | 113.91 USD        |
| **Transacción no rentable máxima**        | -143.71 USD       |
| **Máximo de ganancias consecutivas**      | 18 (791.76 USD)   |
| **Máximo de pérdidas consecutivas**       | 2 (-209.17 USD)   |
| **Máximo de beneficio consecutivo**       | 791.76 USD (18)   |
| **Máximo de pérdidas consecutivas**       | -209.17 USD (2)   |
| **Promedio de ganancias consecutivas**    | 6                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 🎲 Gráfico de Rendimiento

![Gráfico General](ReportTester40.png)

---

## 🔍 Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros (`BB_Period`, `TrailingStopActivation`, `TrailingStopStep`, `ComboMultiplier`), con `UseComboMultiplier` activado para esta simulación.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de 4 meses (01-01-2025 a 30-04-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.