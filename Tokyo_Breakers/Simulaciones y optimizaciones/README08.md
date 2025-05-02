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
| **Ticks**                        | 2,418,655         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 375.45 USD        |
| **Beneficio Bruto**              | 3,332.21 USD      |
| **Pérdidas Brutas**              | -2,956.76 USD     |
| **Factor de Beneficio**          | 1.13              |
| **Beneficio Esperado**           | 2.39 USD          |
| **Factor de Recuperación**       | 0.60              |
| **Ratio de Sharpe**              | 3.02              |
| **Z-Score**                      | -1.37 (82.93%)    |
| **AHPR**                         | 1.0002 (0.02%)    |
| **GHPR**                         | 1.0002 (0.02%)    |
| **Reducción absoluta del balance** | 0.45 USD        |
| **Reducción absoluta de la equidad** | 13.17 USD     |
| **Reducción máxima del balance** | 567.07 USD (5.21%) |
| **Reducción máxima de la equidad** | 630.34 USD (5.79%) |
| **Reducción relativa del balance** | 5.21% (567.07 USD) |
| **Reducción relativa de la equidad** | 5.79% (630.34 USD) |
| **Nivel de margen**              | 348.95%           |
| **LR Correlation**               | 0.72              |
| **LR Standard Error**            | 121.06            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 157               |
| **Total de transacciones**                | 314               |
| **Posiciones rentables (% del total)**    | 122 (77.71%)      |
| **Posiciones no rentables (% del total)** | 35 (22.29%)       |
| **Posiciones cortas (% rentables)**       | 97 (80.41%)       |
| **Posiciones largas (% rentables)**       | 60 (73.33%)       |
| **Transacción rentable promedio**         | 27.31 USD         |
| **Transacción no rentable promedio**      | -82.46 USD        |
| **Transacción rentable máxima**           | 72.47 USD         |
| **Transacción no rentable máxima**        | -111.19 USD       |
| **Máximo de ganancias consecutivas**      | 11 (282.69 USD)   |
| **Máximo de pérdidas consecutivas**       | 5 (-356.31 USD)   |
| **Máximo de beneficio consecutivo**       | 350.34 USD (10)   |
| **Máximo de pérdidas consecutivas**       | -356.31 USD (5)   |
| **Promedio de ganancias consecutivas**    | 5                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 🎲 Gráfico de Rendimiento

![Gráfico General](ReportTester-04.png)

---

## 🔍 Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros (`TrailingStopActivation`, `TrailingStopStep`, `ComboMultiplier`), aunque `UseComboMultiplier` estaba desactivado para esta simulación.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de 1 mes (01-04-2025 a 30-04-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.