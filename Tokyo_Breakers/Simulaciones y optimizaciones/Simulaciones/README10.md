# 🎱 Simulación Optimizada: 01-02-2025 a 28-02-2025

Esta simulación fue realizada para el Expert Advisor **Tokyo_Breakers** en MetaTrader 5, utilizando datos históricos del par **USDJPY** desde el **1 de febrero de 2025** hasta el **28 de febrero de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, logrando un equilibrio entre rentabilidad y estabilidad.

---

## 🔙 Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: Tokyo_Breakers
- **Símbolo**: USDJPY
- **Período**: H1 (2025.02.01 - 2025.02.28)
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
| **Calidad del historial**        | 100%              |
| **Barras**                       | 456               |
| **Ticks**                        | 1,697,563         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | -763.22 USD       |
| **Beneficio Bruto**              | 5,820.65 USD      |
| **Pérdidas Brutas**              | -6,583.87 USD     |
| **Factor de Beneficio**          | 0.88              |
| **Beneficio Esperado**           | -6.69 USD         |
| **Factor de Recuperación**       | -0.35             |
| **Ratio de Sharpe**              | -2.48             |
| **Z-Score**                      | -0.98 (67.29%)    |
| **AHPR**                         | 0.9994 (-0.06%)   |
| **GHPR**                         | 0.9993 (-0.07%)   |
| **Reducción absoluta del balance** | 763.22 USD      |
| **Reducción absoluta de la equidad** | 763.22 USD    |
| **Reducción máxima del balance** | 2,144.93 USD (18.85%) |
| **Reducción máxima de la equidad** | 2,185.56 USD (19.13%) |
| **Reducción relativa del balance** | 18.85% (2,144.93 USD) |
| **Reducción relativa de la equidad** | 19.13% (2,185.56 USD) |
| **Nivel de margen**              | 106.23%           |
| **LR Correlation**               | -0.21             |
| **LR Standard Error**            | 499.25            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 114               |
| **Total de transacciones**                | 228               |
| **Posiciones rentables (% del total)**    | 89 (78.07%)       |
| **Posiciones no rentables (% del total)** | 25 (21.93%)       |
| **Posiciones cortas (% rentables)**       | 71 (80.28%)       |
| **Posiciones largas (% rentables)**       | 43 (74.42%)       |
| **Transacción rentable promedio**         | 65.40 USD         |
| **Transacción no rentable promedio**      | -257.26 USD       |
| **Transacción rentable máxima**           | 312.80 USD        |
| **Transacción no rentable máxima**        | -529.09 USD       |
| **Máximo de ganancias consecutivas**      | 11 (1,253.54 USD) |
| **Máximo de pérdidas consecutivas**       | 4 (-275.10 USD)   |
| **Máximo de beneficio consecutivo**       | 1,253.54 USD (11) |
| **Máximo de pérdidas consecutivas**       | -546.23 USD (2)   |
| **Promedio de ganancias consecutivas**    | 5                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 🎲 Gráfico de Rendimiento

![Gráfico General](ReportTester-02M.png)

---

## 🔍 Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros (`TrailingStopActivation`, `TrailingStopStep`, `ComboMultiplier`), con `UseComboMultiplier` activado para esta simulación.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de 1 mes (01-02-2025 a 28-02-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.