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
| **Barras**                       | 456               |
| **Ticks**                        | 1,697,563         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 996.09 USD        |
| **Beneficio Bruto**              | 3,124.11 USD      |
| **Pérdidas Brutas**              | -2,128.02 USD     |
| **Factor de Beneficio**          | 1.47              |
| **Beneficio Esperado**           | 6.43 USD          |
| **Factor de Recuperación**       | 2.54              |
| **Ratio de Sharpe**              | 7.50              |
| **Z-Score**                      | -1.39 (83.55%)    |
| **AHPR**                         | 1.0006 (0.06%)    |
| **GHPR**                         | 1.0006 (0.06%)    |
| **Reducción absoluta del balance** | 44.60 USD       |
| **Reducción absoluta de la equidad** | 53.68 USD     |
| **Reducción máxima del balance** | 294.93 USD (2.66%) |
| **Reducción máxima de la equidad** | 391.57 USD (3.58%) |
| **Reducción relativa del balance** | 2.66% (294.93 USD) |
| **Reducción relativa de la equidad** | 3.58% (391.57 USD) |
| **Nivel de margen**              | 351.79%           |
| **LR Correlation**               | 0.95              |
| **LR Standard Error**            | 111.02            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 155               |
| **Total de transacciones**                | 310               |
| **Posiciones rentables (% del total)**    | 129 (83.23%)      |
| **Posiciones no rentables (% del total)** | 26 (16.77%)       |
| **Posiciones cortas (% rentables)**       | 92 (83.70%)       |
| **Posiciones largas (% rentables)**       | 63 (82.54%)       |
| **Transacción rentable promedio**         | 24.22 USD         |
| **Transacción no rentable promedio**      | -79.16 USD        |
| **Transacción rentable máxima**           | 68.75 USD         |
| **Transacción no rentable máxima**        | -83.64 USD        |
| **Máximo de ganancias consecutivas**      | 14 (379.06 USD)   |
| **Máximo de pérdidas consecutivas**       | 3 (-238.38 USD)   |
| **Máximo de beneficio consecutivo**       | 379.06 USD (14)   |
| **Máximo de pérdidas consecutivas**       | -238.38 USD (3)   |
| **Promedio de ganancias consecutivas**    | 6                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 🎲 Gráfico de Rendimiento

![Gráfico General](ReportTester-02.png)

---

## 🔍 Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros (`TrailingStopActivation`, `TrailingStopStep`, `ComboMultiplier`), aunque `UseComboMultiplier` estaba desactivado para esta simulación.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de 1 mes (01-02-2025 a 28-02-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.