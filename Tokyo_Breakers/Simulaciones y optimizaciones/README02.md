# ?? Simulaci��n Optimizada: 01-01-2023 a 30-04-2025

Esta simulaci��n fue realizada para el Expert Advisor **Tokyo_Breakers** en MetaTrader 5, utilizando datos hist��ricos del par **USDJPY** desde el **1 de enero de 2023** hasta el **30 de abril de 2025**. Los par��metros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, logrando un equilibrio entre rentabilidad y estabilidad.

---

## ?? Configuraci��n de la Simulaci��n

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: Tokyo_Breakers
- **S��mbolo**: USDJPY
- **Per��odo**: H1 (2023.01.01 - 2025.04.30)
- **Empresa**: FTMO Global Markets Ltd
- **Divisa**: USD
- **Dep��sito inicial**: 10,000.00 USD
- **Apalancamiento**: 1:30

### Par��metros de Entrada

| Par��metro                   | Descripci��n                                               | Valor Utilizado   |
|-----------------------------|-----------------------------------------------------------|-------------------|
| `BB_Period`                 | Periodo de las Bandas de Bollinger                        | 14                |
| `BB_Deviation`              | Desviaci��n est��ndar para las bandas                       | 1.0               |
| `LotSize`                   | Tama?o de lote inicial                                    | 0.3               |
| `SL_Points`                 | Stop Loss en puntos                                       | 390               |
| `TP_Points`                 | Take Profit en puntos                                     | 350               |
| `UseTrailingStop`           | Activar/desactivar trailing stop                          | true              |
| `TrailingStopActivation`    | Beneficio necesario para activar trailing stop            | 50                |
| `TrailingStopStep`          | Paso del trailing stop en puntos                          | 15                |
| `MaxPositions`              | M��ximo de operaciones abiertas por direcci��n              | 2                 |
| `CandleSeparation`          | Velas m��nimas entre operaciones nuevas                    | 2                 |
| `UseBalanceTarget`          | Activar objetivo de balance                               | false             |
| `BalanceTarget`             | Objetivo de balance para cerrar el bot                    | 11000.0           |
| `MinOperatingBalance`       | Balance m��nimo para operar                                | 9050.0            |
| `MaxDailyLossFTMO`          | P��rdida diaria m��xima permitida                           | 500.0             |
| `SafetyBeltFactor`          | Multiplicador de seguridad sobre la p��rdida m��xima diaria | 0.3               |
| `UseComboMultiplier`        | Activar multiplicador de lotes tras ganancia              | false             |
| `ComboMultiplier`           | Multiplicador en rachas ganadoras                         | 2.0               |
| `MaxContractSize`           | Tama?o m��ximo de lote                                     | 2.0               |
| `UseBreakoutDistance`       | Activar ruptura en la vela actual                         | true              |
| `BreakoutDistancePoints`    | Distancia m��nima para confirmar la ruptura                | 250               |

---

## ?? Resultados de la Simulaci��n

### Resumen General

| M��trica                          | Valor              |
|----------------------------------|--------------------|
| **Calidad del historial**        | 23%               |
| **Barras**                       | 9,673             |
| **Ticks**                        | 34,809,890        |
| **S��mbolos**                     | 1                 |
| **Beneficio Neto**               | 27,367.49 USD     |
| **Beneficio Bruto**              | 56,088.22 USD     |
| **P��rdidas Brutas**              | -28,720.73 USD    |
| **Factor de Beneficio**          | 1.95              |
| **Beneficio Esperado**           | 9.69 USD          |
| **Factor de Recuperaci��n**       | 34.57             |
| **Ratio de Sharpe**              | 13.79             |
| **Z-Score**                      | -2.94 (99.67%)    |
| **AHPR**                         | 1.0005 (0.05%)    |
| **GHPR**                         | 1.0005 (0.05%)    |
| **Reducci��n absoluta del balance** | 105.94 USD      |
| **Reducci��n absoluta de la equidad** | 100.43 USD    |
| **Reducci��n m��xima del balance** | 783.92 USD (2.11%) |
| **Reducci��n m��xima de la equidad** | 791.55 USD (2.13%) |
| **Reducci��n relativa del balance** | 2.66% (344.73 USD) |
| **Reducci��n relativa de la equidad** | 2.74% (355.74 USD) |
| **Nivel de margen**              | 249.36%           |
| **LR Correlation**               | 0.97              |
| **LR Standard Error**            | 2,300.60          |
| **Resultado de OnTester**        | 0                 |

### Estad��sticas de Operaciones

| M��trica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 2,825             |
| **Total de transacciones**                | 5,650             |
| **Posiciones rentables (% del total)**    | 2,465 (87.26%)    |
| **Posiciones no rentables (% del total)** | 360 (12.74%)      |
| **Posiciones cortas (% rentables)**       | 1,324 (87.24%)    |
| **Posiciones largas (% rentables)**       | 1,501 (87.28%)    |
| **Transacci��n rentable promedio**         | 22.75 USD         |
| **Transacci��n no rentable promedio**      | -76.25 USD        |
| **Transacci��n rentable m��xima**           | 95.20 USD         |
| **Transacci��n no rentable m��xima**        | -111.19 USD       |
| **M��ximo de ganancias consecutivas**      | 41 (846.91 USD)   |
| **M��ximo de p��rdidas consecutivas**       | 4 (-264.87 USD)   |
| **M��ximo de beneficio consecutivo**       | 1,349.36 USD (35) |
| **M��ximo de p��rdidas consecutivas**       | -264.87 USD (4)   |
| **Promedio de ganancias consecutivas**    | 8                 |
| **Promedio de p��rdidas consecutivas**     | 1                 |

---

## ?? Gr��fico de Rendimiento

![Gr��fico General](ReportTester-550097663.png)

---

## ?? Notas y Advertencia

- Esta simulaci��n se realiz�� despu��s de un proceso de optimizaci��n de par��metros.
- **Advertencia**: Aunque la optimizaci��n mejora el rendimiento, al estar concentrada en un per��odo de apenas dos a?os y medio (01-01-2023 a 30-04-2025), puede haber cierta **sobreoptimizaci��n**. Esto significa que los resultados podr��an no ser completamente representativos de condiciones futuras del mercado. Se recomienda realizar pruebas adicionales en per��odos m��s amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.
- Aseg��rate de que el archivo de la imagen est�� en esta carpeta para que se muestre correctamente.