# 📈 Simulación Optimizada: 01-01-2025 a 30-04-2025

Esta simulación fue realizada para el Expert Advisor **Tokyo_Breakers** en MetaTrader 5, utilizando datos históricos del par **USDJPY** desde el **1 de enero de 2025** hasta el **30 de abril de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, logrando un equilibrio entre rentabilidad y estabilidad.

---

## ⚙️ Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: Tokyo_Breakers
- **Símbolo**: USDJPY
- **Período**: H1 (2025.01.01 - 2025.04.30)
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
| `TrailingStopActivation`    | Beneficio necesario para activar trailing stop            | 50                |
| `TrailingStopStep`          | Paso del trailing stop en puntos                          | 15                |
| `MaxPositions`              | Máximo de operaciones abiertas por dirección              | 2                 |
| `CandleSeparation`          | Velas mínimas entre operaciones nuevas                    | 2                 |
| `UseBalanceTarget`          | Activar objetivo de balance                               | true              |
| `BalanceTarget`             | Objetivo de balance para cerrar el bot                    | 11000.0           |
| `MinOperatingBalance`       | Balance mínimo para operar                                | 9050.0            |
| `MaxDailyLossFTMO`          | Pérdida diaria máxima permitida                           | 500.0             |
| `SafetyBeltFactor`          | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.3               |
| `UseComboMultiplier`        | Activar multiplicador de lotes tras ganancia              | false             |
| `ComboMultiplier`           | Multiplicador en rachas ganadoras                         | 2.0               |
| `MaxContractSize`           | Tamaño máximo de lote                                     | 2.0               |
| `UseBreakoutDistance`       | Activar ruptura en la vela actual                         | true              |
| `BreakoutDistancePoints`    | Distancia mínima para confirmar la ruptura                | 250               |

---

## 📊 Resultados de la Simulación

### Resumen General

| Métrica                          | Valor              |
|----------------------------------|--------------------|
| **Calidad del historial**        | 100%              |
| **Barras**                       | 2,016             |
| **Ticks**                        | 8,365,506         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 1,033.94 USD      |
| **Beneficio Bruto**              | 6,828.26 USD      |
| **Pérdidas Brutas**              | -5,794.32 USD     |
| **Factor de Beneficio**          | 1.18              |
| **Beneficio Esperado**           | 1.71 USD          |
| **Factor de Recuperación**       | 1.97              |
| **Ratio de Sharpe**              | 3.43              |
| **Z-Score**                      | 0.21 (16.63%)     |
| **AHPR**                         | 1.0002 (0.02%)    |
| **GHPR**                         | 1.0002 (0.02%)    |
| **Reducción absoluta del balance** | 355.00 USD      |
| **Reducción absoluta de la equidad** | 356.52 USD    |
| **Reducción máxima delVuelve a la derecha del balance** | 518.59 USD (4.87%) |
| **Reducción máxima de la equidad** | 525.26 USD (4.93%) |
| **Reducción relativa del balance** | 4.87% (518.59 USD) |
| **Reducción relativa de la equidad** | 4.93% (525.26 USD) |
| **Nivel de margen**              | 484.97%           |
| **LR Correlation**               | 0.83              |
| **LR Standard Error**            | 168.43            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 604               |
| **Total de transacciones**                | 1,208             |
| **Posiciones rentables (% del total)**    | 529 (87.58%)      |
| **Posiciones no rentables (% del total)** | 75 (12.42%)       |
| **Posiciones cortas (% rentables)**       | 329 (88.45%)      |
| **Posiciones largas (% rentables)**       | 275 (86.55%)      |
| **Transacción rentable promedio**         | 12.91 USD         |
| **Transacción no rentable promedio**      | -73.63 USD        |
| **Transacción rentable máxima**           | 70.17 USD         |
| **Transacción no rentable máxima**        | -111.19 USD       |
| **Máximo de ganancias consecutivas**      | 24 (333.84 USD)   |
| **Máximo de pérdidas consecutivas**       | 3 (-164.66 USD)   |
| **Máximo de beneficio consecutivo**       | 405.79 USD (20)   |
| **Máximo de pérdidas consecutivas**       | -195.27 USD (2)   |
| **Promedio de ganancias consecutivas**    | 8                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 📉 Gráfico de Rendimiento

![Gráfico General](ReportTester-550097664.png)

---

## ⚠️ Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de apenas cuatro meses (01-01-2025 a 30-04-2025), puede haber cierta **sobreoptimización**. Esto significa que los resultados podrían no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.