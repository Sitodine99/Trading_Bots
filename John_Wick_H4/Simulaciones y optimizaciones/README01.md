# 📈 Simulación Optimizada: 01-01-2025 a 30-04-2025

Esta simulación fue realizada para el Expert Advisor **John_Wick_H4** en MetaTrader 5, utilizando datos históricos del par de divisas **AUDCAD** desde el **1 de enero de 2025** hasta el **30 de abril de 2025**. Los parámetros fueron configurados para maximizar la rentabilidad mientras se controla el riesgo, utilizando una estrategia basada en Bandas de Bollinger y breakout, con un enfoque en limitar el número de posiciones abiertas y aplicar una gestión estricta de riesgos mediante stop loss y límites de pérdida diaria.

---

## ⚙️ Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: John_Wick_H4
- **Símbolo**: AUDCAD
- **Período**: H4 (2025.01.01 - 2025.04.30)
- **Empresa**: FTMO Global Markets Ltd
- **Divisa**: USD
- **Depósito inicial**: 10,000.00 USD
- **Apalancamiento**: 1:30

### Parámetros de Entrada

| Parámetro                   | Descripción                                               | Valor Utilizado   |
|-----------------------------|-----------------------------------------------------------|-------------------|
| `BB_Period`                 | Período de las Bandas de Bollinger                        | 46                |
| `BB_Deviation`              | Desviación de las Bandas de Bollinger                     | 1.8               |
| `LotSize`                   | Tamaño de lote inicial para las operaciones               | 0.8               |
| `MaxContractSize`           | Tamaño máximo de contrato permitido                       | 2.0               |
| `UseComboMultiplier`        | Activar/desactivar multiplicador para rachas ganadoras    | false             |
| `ComboMultiplier`           | Multiplicador para rachas ganadoras                       | 1.6               |
| `SL_Points`                 | Stop Loss en puntos gráficos                              | 550               |
| `UseTrailingStop`           | Activar/desactivar Trailing Stop                         | false             |
| `TrailingStopActivation`    | Puntos de beneficio para activar trailing stop            | 150               |
| `TrailingStopStep`          | Paso en puntos para ajustar el trailing stop              | 180               |
| `MaxPositions`              | Número máximo de posiciones abiertas simultáneamente     | 2                 |
| `CandleSeparation`          | Separación mínima entre velas para nuevas operaciones     | 6                 |
| `UseBreakoutDistance`       | Activar/desactivar distancia de breakout                  | true              |
| `BreakoutDistancePoints`    | Distancia en puntos para breakout                         | 150               |
| `MaxDailyLossFTMO`          | Pérdida diaria máxima permitida (USD)                     | 500.0             |
| `SafetyBeltFactor`          | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |
| `MinOperatingBalance`       | Saldo mínimo operativo (USD)                              | 9050.0            |
| `UseBalanceTarget`          | Activar/desactivar objetivo de saldo                      | false             |
| `BalanceTarget`             | Saldo objetivo para cerrar el bot (USD)                   | 11000.0           |

---

## 📊 Resultados de la Simulación

### Resumen General

| Métrica                          | Valor              |
|----------------------------------|--------------------|
| **Calidad del historial**        | 100%              |
| **Barras**                       | 504               |
| **Ticks**                        | 7,873,884         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 4,712.58 USD      |
| **Beneficio Bruto**              | 6,562.96 USD      |
| **Pérdidas Brutas**              | -1,850.38 USD     |
| **Factor de Beneficio**          | 3.55              |
| **Beneficio Esperado**           | 147.27 USD        |
| **Factor de Recuperación**       | 4.66              |
| **Ratio de Sharpe**              | 6.60              |
| **Z-Score**                      | -1.37 (82.93%)    |
| **AHPR**                         | 1.0125 (1.25%)    |
| **GHPR**                         | 1.0121 (1.21%)    |
| **Reducción absoluta del balance** | 1.20 USD        |
| **Reducción absoluta de la equidad** | 154.16 USD    |
| **Reducción máxima del balance** | 535.89 USD (4.84%) |
| **Reducción máxima de la equidad** | 1,012.26 USD (7.55%) |
| **Reducción relativa del balance** | 4.84% (535.89 USD) |
| **Reducción relativa de la equidad** | 7.55% (1,012.26 USD) |
| **Nivel de margen**              | 315.96%           |
| **LR Correlation**               | 0.95              |
| **LR Standard Error**            | 400.26            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 32                |
| **Total de transacciones**                | 64                |
| **Posiciones rentables (% del total)**    | 22 (68.75%)       |
| **Posiciones no rentables (% del total)** | 10 (31.25%)       |
| **Posiciones cortas (% rentables)**       | 16 (68.75%)       |
| **Posiciones largas (% rentables)**       | 16 (68.75%)       |
| **Transacción rentable promedio**         | 298.32 USD        |
| **Transacción no rentable promedio**      | -181.20 USD       |
| **Transacción rentable máxima**           | 1,499.00 USD      |
| **Transacción no rentable máxima**        | -269.14 USD       |
| **Máximo de ganancias consecutivas**      | 4 (2,095.06 USD)  |
| **Máximo de pérdidas consecutivas**       | 3 (-531.09 USD)   |
| **Máximo de beneficio continuo**          | 2,095.06 USD (4)  |
| **Máximo de pérdidas consecutivas**       | -531.09 USD (3)   |
| **Promedio de ganancias consecutivas**    | 4                 |
| **Promedio de pérdidas consecutivas**     | 2                 |

---

## 📉 Gráfico de Rendimiento

![Gráfico General](ReportTester-01.png)

---

## ⚠️ Notas y Advertencia

- Esta simulación utiliza una estrategia basada en Bandas de Bollinger (`BB_Period=46`, `BB_Deviation=1.8`) con una distancia de breakout (`BreakoutDistancePoints=150`) y un máximo de dos posiciones abiertas simultáneamente (`MaxPositions=2`). La desactivación del trailing stop (`UseTrailingStop=false`) y del multiplicador de lotes (`UseComboMultiplier=false`) mantuvo un enfoque conservador en la gestión de riesgos.
- **Advertencia**: Los resultados muestran un sólido beneficio neto de 4,712.58 USD con un factor de beneficio de 3.55, pero están basados en un período de cuatro meses (01-01-2025 a 30-04-2025). Esto podría limitar la generalización de los resultados debido a condiciones específicas del mercado, aumentando el riesgo de **sobreoptimización**. Se recomienda realizar pruebas adicionales en períodos más extensos o en condiciones de mercado en vivo para validar la robustez de la estrategia.
- **Gestión de riesgos**: Ajuste parámetros como `LotSize`, `MaxDailyLossFTMO`, `MinOperatingBalance`, y `SL_Points` según el tamaño de su cuenta y tolerancia al riesgo. La estrategia de breakout puede ser sensible a la volatilidad del par AUDCAD, por lo que es crucial monitorear las condiciones del mercado.