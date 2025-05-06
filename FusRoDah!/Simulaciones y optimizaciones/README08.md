# 📈 Simulación Optimizada: 01-01-2025 a 31-01-2025

Esta simulación fue realizada para el Expert Advisor **FusRoDah! v03** en MetaTrader 5, utilizando datos históricos del índice **US100.cash** desde el **1 de enero de 2025** hasta el **31 de enero de 2025**. Los parámetros fueron configurados para equilibrar rentabilidad y control de riesgo, permitiendo múltiples operaciones simultáneas para una estrategia más dinámica, mientras se mantiene una gestión estricta del riesgo mediante trailing stop y límites de pérdida diaria.

---

## ⚙️ Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: FusRoDah! v03
- **Símbolo**: US100.cash
- **Período**: H1 (2025.01.01 - 2025.01.31)
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
| `LOTE_MAXIMO`               | Lote máximo permitido con el multiplicador                | 3.0               |
| `PERIODO`                   | Periodo del gráfico (solo H1 o M30 permitido)             | PERIOD_H1 (1 Hour)|
| `COLOR_RECTANGULO`          | Color del rectángulo dibujado en el gráfico               | clrBlue (16711680)|
| `HORA_INICIAL_RANGO1`       | Hora inicial del Rango 1 (UTC+3)                          | 3.0               |
| `HORA_FINAL_RANGO1`         | Hora final del Rango 1 (UTC+3)                            | 9.0               |
| `HORA_INICIAL_RANGO2`       | Hora inicial del Rango 2 (UTC+3)                          | 14.0              |
| `HORA_FINAL_RANGO2`         | Hora final del Rango 2 (UTC+3)                            | 17.0              |
| `PUNTOS_SL`                 | Stop Loss en puntos gráficos                              | 18000             |
| `PUNTOS_TP`                 | Take Profit en puntos gráficos                            | 16000             |
| `HORAS_EXPIRACION`          | Horas de expiración de órdenes pendientes                 | 6                 |
| `USAR_TRAILING_STOP`        | Activar/desactivar Trailing Stop                         | true              |
| `PUNTOS_ACTIVACION_TRAILING`| Puntos de beneficio para activar trailing stop            | 6000              |
| `PASO_TRAILING_STOP`        | Paso en puntos para ajustar el trailing stop              | 1500              |
| `PERMITIR_OPERACIONES_MULTIPLES` | Permitir múltiples operaciones simultáneas           | true              |
| `MAX_POSICIONES`            | Número máximo de posiciones abiertas simultáneamente     | 4                 |
| `USAR_OBJETIVO_SALDO`       | Activar/desactivar objetivo de saldo                      | false             |
| `OBJETIVO_SALDO`            | Saldo objetivo para cerrar el bot (USD)                   | 11000.0           |
| `SALDO_MINIMO_OPERATIVO`    | Saldo mínimo operativo (USD)                              | 9200.0            |
| `PERDIDA_DIARIA_MAXIMA`     | Pérdida diaria máxima permitida (USD)                     | 500.0             |
| `FACTOR_CINTURON_SEGURIDAD` | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |

---

## 📊 Resultados de la Simulación

### Resumen General

| Métrica                          | Valor              |
|----------------------------------|--------------------|
| **Calidad del historial**        | 100%              |
| **Barras**                       | 472               |
| **Ticks**                        | 4,264,869         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 1,420.55 USD      |
| **Beneficio Bruto**              | 2,638.38 USD      |
| **Pérdidas Brutas**              | -1,217.83 USD     |
| **Factor de Beneficio**          | 2.17              |
| **Beneficio Esperado**           | 33.04 USD         |
| **Factor de Recuperación**       | 2.49              |
| **Ratio de Sharpe**              | 14.16             |
| **Z-Score**                      | 0.45 (34.73%)     |
| **AHPR**                         | 1.0031 (0.31%)    |
| **GHPR**                         | 1.0031 (0.31%)    |
| **Reducción absoluta del balance** | 126.79 USD      |
| **Reducción absoluta de la equidad** | 126.79 USD    |
| **Reducción máxima del balance** | 518.65 USD (4.99%) |
| **Reducción máxima de la equidad** | 569.64 USD (5.45%) |
| **Reducción relativa del balance** | 4.99% (518.65 USD) |
| **Reducción relativa de la equidad** | 5.45% (569.64 USD) |
| **Nivel de margen**              | 360.96%           |
| **LR Correlation**               | 0.92              |
| **LR Standard Error**            | 184.90            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 43                |
| **Total de transacciones**                | 86                |
| **Posiciones rentables (% del total)**    | 36 (83.72%)       |
| **Posiciones no rentables (% del total)** | 7 (16.28%)        |
| **Posiciones cortas (% rentables)**       | 18 (88.89%)       |
| **Posiciones largas (% rentables)**       | 25 (80.00%)       |
| **Transacción rentable promedio**         | 73.29 USD         |
| **Transacción no rentable promedio**      | -173.98 USD       |
| **Transacción rentable máxima**           | 161.24 USD        |
| **Transacción no rentable máxima**        | -180.52 USD       |
| **Máximo de ganancias consecutivas**      | 11 (628.74 USD)   |
| **Máximo de pérdidas consecutivas**       | 2 (-316.41 USD)   |
| **Máximo de beneficio consecutivo**       | 698.28 USD (7)    |
| **Máximo de pérdidas consecutivas**       | -316.41 USD (2)   |
| **Promedio de ganancias consecutivas**    | 5                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 📉 Gráfico de Rendimiento

![Gráfico General](ReportTester-06.png)

---

## ⚠️ Notas y Advertencia

- Esta simulación se realizó con `PERMITIR_OPERACIONES_MULTIPLES=true` y `MAX_POSICIONES=4`, lo que permite una estrategia más agresiva al abrir múltiples operaciones simultáneas. Sin embargo, el multiplicador de lotes (`USAR_MULTIPLICADOR=false`) fue desactivado para mantener un enfoque conservador en el tamaño de las operaciones.
- **Advertencia**: Los resultados están basados en un período de un mes (01-01-2025 a 31-01-2025), lo que podría limitar la generalización de los resultados. La estrategia podría estar influenciada por las condiciones específicas del mercado en este período, lo que aumenta el riesgo de **sobreoptimización**. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.
- **Gestión de riesgos**: Ajuste parámetros como `LOTE_FIJO`, `PERDIDA_DIARIA_MAXIMA`, `SALDO_MINIMO_OPERATIVO`, y `MAX_POSICIONES` según el tamaño de su cuenta y tolerancia al riesgo. La activación de múltiples operaciones simultáneas incrementa la exposición al riesgo, especialmente en mercados volátiles.