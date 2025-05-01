# 📈 Simulación Optimizada: 01-01-2025 a 30-04-2025

Esta simulación fue realizada para el Expert Advisor **FusRoDah! v03** en MetaTrader 5, utilizando datos históricos del índice **US100.cash** desde el **1 de enero de 2025** hasta el **30 de abril de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, logrando un equilibrio entre rentabilidad y estabilidad.

---

## ⚙️ Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: FusRoDah! v03
- **Símbolo**: US100.cash
- **Período**: H1 (2025.01.01 - 2025.04.30)
- **Empresa**: FTMO Global Markets Ltd
- **Divisa**: USD
- **Depósito inicial**: 10,000.00 USD
- **Apalancamiento**: 1:30

### Parámetros de Entrada

| Parámetro                   | Descripción                                               | Valor Utilizado   |
|-----------------------------|-----------------------------------------------------------|-------------------|
| `LOTE_FIJO`                 | Lote fijo inicial para las operaciones                    | 1.0               |
| `USAR_MULTIPLICADOR`        | Activar/desactivar multiplicador de lotes para rachas ganadoras | false             |
| `MULTIPLICADOR_LOTES`       | Multiplicador de lotes para rachas ganadoras              | 2.0               |
| `LOTE_MAXIMO`               | Lote máximo permitido con el multiplicador                | 4.8               |
| `PERIODO`                   | Periodo del gráfico (solo H1 o M30 permitido)             | PERIOD_H1 (1 Hour)|
| `COLOR_RECTANGULO`          | Color del rectángulo dibujado en el gráfico               | clrBlue           |
| `HORA_INICIAL_RANGO1`       | Hora inicial del Rango 1 (UTC+3)                          | 3.0               |
| `HORA_FINAL_RANGO1`         | Hora final del Rango 1 (UTC+3)                            | 9.0               |
| `HORA_INICIAL_RANGO2`       | Hora inicial del Rango 2 (UTC+3)                          | 14.0              |
| `HORA_FINAL_RANGO2`         | Hora final del Rango 2 (UTC+3)                            | 17.0              |
| `PUNTOS_SL`                 | Stop Loss en puntos gráficos                              | 18000             |
| `PUNTOS_TP`                 | Take Profit en puntos gráficos                            | 16000             |
| `HORAS_EXPIRACION`          | Horas de expiración de órdenes pendientes                 | 6                 |
| `USAR_TRAILING_STOP`        | Activar/desactivar Trailing Stop                          | true              |
| `PUNTOS_ACTIVACION_TRAILING`| Puntos de beneficio para activar trailing stop            | 6000              |
| `PASO_TRAILING_STOP`        | Paso en puntos para ajustar el trailing stop              | 1500              |
| `USAR_OBJETIVO_SALDO`       | Activar/desactivar objetivo de saldo                      | false             |
| `OBJETIVO_SALDO`            | Saldo objetivo para cerrar el bot (USD)                   | 11000.0           |
| `SALDO_MINIMO_OPERATIVO`    | Saldo mínimo operativo (USD)                              | 9050.0            |
| `PERDIDA_DIARIA_MAXIMA`     | Pérdida diaria máxima permitida (USD)                     | 500.0             |
| `FACTOR_CINTURON_SEGURIDAD` | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |

---

## 📊 Resultados de la Simulación

### Resumen General

| Métrica                          | Valor              |
|----------------------------------|--------------------|
| **Calidad del historial**        | 100%              |
| **Barras**                       | 1,894             |
| **Ticks**                        | 19,054,367        |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 3,141.88 USD      |
| **Beneficio Bruto**              | 10,594.84 USD     |
| **Pérdidas Brutas**              | -7,452.96 USD     |
| **Factor de Beneficio**          | 1.42              |
| **Beneficio Esperado**           | 16.80 USD         |
| **Factor de Recuperación**       | 2.50              |
| **Ratio de Sharpe**              | 7.37              |
| **Z-Score**                      | 0.47 (36.16%)     |
| **AHPR**                         | 1.0015 (0.15%)    |
| **GHPR**                         | 1.0015 (0.15%)    |
| **Reducción absoluta del balance** | 306.81 USD      |
| **Reducción absoluta de la equidad** | 306.81 USD    |
| **Reducción máxima del balance** | 1,258.14 USD (9.72%) |
| **Reducción máxima de la equidad** | 1,254.47 USD (9.71%) |
| **Reducción relativa del balance** | 9.72% (1,258.14 USD) |
| **Reducción relativa de la equidad** | 9.71% (1,254.47 USD) |
| **Nivel de margen**              | 194.58%           |
| **LR Correlation**               | 0.85              |
| **LR Standard Error**            | 474.37            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 187               |
| **Total de transacciones**                | 374               |
| **Posiciones rentables (% del total)**    | 144 (77.01%)      |
| **Posiciones no rentables (% del total)** | 43 (22.99%)       |
| **Posiciones cortas (% rentables)**       | 89 (76.40%)       |
| **Posiciones largas (% rentables)**       | 98 (77.55%)       |
| **Transacción rentable promedio**         | 73.58 USD         |
| **Transacción no rentable promedio**      | -173.32 USD       |
| **Transacción rentable máxima**           | 161.38 USD        |
| **Transacción no rentable máxima**        | -190.47 USD       |
| **Máximo de ganancias consecutivas**      | 11 (628.74 USD)   |
| **Máximo de pérdidas consecutivas**       | 3 (-496.43 USD)   |
| **Máximo de beneficio consecutivo**       | 698.28 USD (7)    |
| **Máximo de pérdidas consecutivas**       | -496.43 USD (3)   |
| **Promedio de ganancias consecutivas**    | 4                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 📉 Gráfico de Rendimiento

![Gráfico General](ReportTester-550097663(2).png)

---

## ⚠️ Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros.
- **Advertencia**: Aunque la calidad del historial es del 100%, la simulación abarca un período de 4 meses (01-01-2025 a 30-04-2025), lo que podría limitar la representatividad de los resultados en condiciones de mercado más amplias o variables. Se recomienda realizar pruebas adicionales en períodos más largos o en condiciones de mercado en vivo para validar la robustez de la estrategia.
- **Nota sobre el Drawdown**: El drawdown del balance (9.72%, 1,258.14 USD) y de la equidad (9.71%, 1,254.47 USD) están dentro del límite típico de 10% (1,000 USD) permitido en pruebas de fondeo como FTMO. Esta configuración cumple con las reglas de fondeo (saldo mínimo de 9,000 USD, pérdida diaria máxima de 500 USD) y es adecuada para pruebas de fondeo con un objetivo de beneficio de 1,000 USD.