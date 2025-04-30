# Simulación Optimizada: 01-01-2023 a 30-04-2025

Esta simulación fue realizada para el Expert Advisor **Tokyo_Breakers** en MetaTrader 5, utilizando datos históricos del par **USDJPY** desde el 1 de enero de 2023 hasta el 30 de abril de 2025. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo.

## Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: Tokyo_Breakers
- **Símbolo**: USDJPY
- **Período**: H1 (2023.01.01 - 2025.04.30)
- **Parámetros de entrada**:
  - `BB_Period`: 14
  - `BB_Deviation`: 1.0
  - `LotSize`: 0.3
  - `SL_Points`: 390
  - `TP_Points`: 350
  - `UseTrailingStop`: true
  - `TrailingStopActivation`: 50
  - `TrailingStopStep`: 15
  - `MaxPositions`: 2
  - `CandleSeparation`: 2
  - `UseBalanceTarget`: false
  - `BalanceTarget`: 11000.0
  - `MinOperatingBalance`: 9050.0
  - `MaxDailyLossFTMO`: 500.0
  - `SafetyBeltFactor`: 0.3
  - `UseComboMultiplier`: false
  - `ComboMultiplier`: 2.0
  - `MaxContractSize`: 2.0
  - `UseBreakoutDistance`: true
  - `BreakoutDistancePoints`: 250
- **Empresa**: FTMO Global Markets Ltd
- **Divisa**: USD
- **Depósito inicial**: 10,000.00 USD
- **Apalancamiento**: 1:30

## Resultados de la Simulación

- **Calidad del historial**: 23%
- **Barras**: 9,673
- **Ticks**: 34,809,890
- **Símbolos**: 1
- **Beneficio Neto**: 27,367.49 USD
- **Beneficio Bruto**: 56,088.22 USD
- **Pérdidas Brutas**: -28,720.73 USD
- **Factor de Beneficio**: 1.95
- **Beneficio Esperado**: 9.69 USD
- **Factor de Recuperación**: 34.57
- **Ratio de Sharpe**: 13.79
- **Z-Score**: -2.94 (99.67%)
- **AHPR**: 1.0005 (0.05%)
- **GHPR**: 1.0005 (0.05%)
- **Reducción absoluta del balance**: 105.94 USD
- **Reducción absoluta de la equidad**: 100.43 USD
- **Reducción máxima del balance**: 783.92 USD (2.11%)
- **Reducción máxima de la equidad**: 791.55 USD (2.13%)
- **Reducción relativa del balance**: 2.66% (344.73 USD)
- **Reducción relativa de la equidad**: 2.74% (355.74 USD)
- **Nivel de margen**: 249.36%
- **LR Correlation**: 0.97
- **LR Standard Error**: 2,300.60
- **Resultado de OnTester**: 0

### Estadísticas de Operaciones
- **Total de operaciones ejecutadas**: 2,825
- **Total de transacciones**: 5,650
- **Posiciones rentables (% del total)**: 2,465 (87.26%)
- **Posiciones no rentables (% del total)**: 360 (12.74%)
- **Posiciones cortas (% rentables)**: 1,324 (87.24%)
- **Posiciones largas (% rentables)**: 1,501 (87.28%)
- **Transacción rentable promedio**: 22.75 USD
- **Transacción no rentable promedio**: -76.25 USD
- **Transacción rentable máxima**: 95.20 USD
- **Transacción no rentable máxima**: -111.19 USD
- **Máximo de ganancias consecutivas (número)**: 41 (846.91 USD)
- **Máximo de pérdidas consecutivas (número)**: 4 (-264.87 USD)
- **Máximo de beneficio consecutivo (número de ganancias)**: 1,349.36 USD (35)
- **Máximo de pérdidas consecutivas (número de pérdidas)**: -264.87 USD (4)
- **Promedio de ganancias consecutivas**: 8
- **Promedio de pérdidas consecutivas**: 1

## Gráfico de Rendimiento

- **Gráfico General**  
  ![Gráfico General](ReportTester-550097663.png)

## Notas
- Este gráfico y los datos fueron generados automáticamente por MetaTrader 5 durante las pruebas de backtesting.
- Asegúrate de que el archivo de la imagen esté en esta carpeta para que se muestre correctamente.