# 📈 Simulación: 01-04-2025 a 30-04-2025

Esta simulación fue realizada para el Expert Advisor **John_Wick_H4** en MetaTrader 5, utilizando datos históricos del par de divisas **AUDCAD** desde el **1 de abril de 2025** hasta el **30 de abril de 2025**. Los parámetros fueron configurados para equilibrar rentabilidad y control de riesgo, utilizando una estrategia basada en Bandas de Bollinger y breakout, con un enfoque conservador que limita el número de posiciones abiertas y aplica una gestión estricta de riesgos mediante stop loss y límites de pérdida diaria.

---

## ⚙️ Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: John_Wick_H4
- **Símbolo**: AUDCAD
- **Período**: H4 (2025.04.01 - 2025.04.30)
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
| **Barras**                       | 126               |
| **Ticks**                        | 2,527,570         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 1,740.41 USD      |
| **Beneficio Bruto**              | 2,253.64 USD      |
| **Pérdidas Brutas**              | -513.23 USD       |
| **Factor de Beneficio**          | 4.39              |
| **Beneficio Esperado**           | 248.63 USD        |
| **Factor de Recuperación**       | 1.72              |
| **Ratio de Sharpe**              | 0.54              |
| **Z-Score**                      | -0.38 (29.61%)    |
| **AHPR**                         | 1.0247 (2.47%)    |
| **GHPR**                         | 1.0232 (2.32%)    |
| **Reducción absoluta del balance** | 351.05 USD      |
| **Reducción absoluta de la equidad** | 582.42 USD    |
| **Reducción máxima del balance** | 508.43 USD (5.01%) |
| **Reducción máxima de la equidad** | 1,012.26 USD (9.71%) |
| **Reducción relativa del balance** | 5.01% (508.43 USD) |
| **Reducción relativa de la equidad** | 9.71% (1,012.26 USD) |
| **Nivel de margen**              | 584.30%           |
| **LR Correlation**               | 0.89              |
| **LR Standard Error**            | 453.08            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 7                 |
| **Total de transacciones**                | 14                |
| **Posiciones rentables (% del total)**    | 5 (71.43%)        |
| **Posiciones no rentables (% del total)** | 2 (28.57%)        |
| **Posiciones cortas (% rentables)**       | 4 (100.00%)       |
| **Posiciones largas (% rentables)**       | 3 (33.33%)        |
| **Transacción rentable promedio**         | 450.73 USD        |
| **Transacción no rentable promedio**      | -252.42 USD       |
| **Transacción rentable máxima**           | 1,499.00 USD      |
| **Transacción no rentable máxima**        | -253.21 USD       |
| **Máximo de ganancias consecutivas**      | 4 (2,095.06 USD)  |
| **Máximo de pérdidas consecutivas**       | 2 (-504.83 USD)   |
| **Máximo de beneficio consecutivo**       | 2,095.06 USD (4)  |
| **Máximo de pérdidas consecutivas**       | -504.83 USD (2)   |
| **Promedio de ganancias consecutivas**    | 3                 |
| **Promedio de pérdidas consecutivas**     | 2                 |

---

## 📉 Gráfico de Rendimiento

![Gráfico General](ReportTester-05.png)

---

## ⚠️ Notas y Advertencia

- Esta simulación utiliza una estrategia basada en Bandas de Bollinger (`BB_Period=46`, `BB_Deviation=1.8`) con una distancia de breakout (`BreakoutDistancePoints=150`) y un máximo de dos posiciones abiertas simultáneamente (`MaxPositions=2`). La desactivación del trailing stop (`UseTrailingStop=false`) y del multiplicador de lotes (`UseComboMultiplier=false`) mantuvo un enfoque conservador en la gestión de riesgos.
- **Advertencia**: Los resultados muestran un beneficio neto sólido de 1,740.41 USD con un factor de beneficio elevado de 4.39, pero el número limitado de operaciones (7) y el ratio de Sharpe bajo (0.54) sugieren que la estrategia es altamente selectiva y puede no ser consistente en períodos cortos. Los resultados están basados en un período de un mes (01-04-2025 a 30-04-2025), lo que aumenta el riesgo de **sobreoptimización** debido a condiciones específicas del mercado. Se recomienda realizar pruebas en períodos más extensos o en condiciones de mercado en vivo para validar la robustez de la estrategia.
- **Gestión de riesgos**: Ajuste parámetros como `LotSize`, `MaxDailyLossFTMO`, `MinOperatingBalance`, y `SL_Points` según el tamaño de su cuenta y tolerancia al riesgo. La estrategia de breakout puede ser sensible a la volatilidad del par AUDCAD, especialmente en períodos cortos. La rentabilidad perfecta de las posiciones cortas (100%) contrasta con el bajo rendimiento de las posiciones largas (33.33%), lo que sugiere que la estrategia podría beneficiarse de ajustes en las señales de compra.