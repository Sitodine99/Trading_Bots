# 📈 Simulación Optimizada: 01-04-2025 a 30-04-2025

Esta simulación fue realizada para el Expert Advisor **FusRoDah! v03** en MetaTrader 5, utilizando datos históricos del índice **US100.cash** desde el **1 de abril de 2025** hasta el **30 de abril de 2025**. Los parámetros fueron configurados para equilibrar rentabilidad y control de riesgo, permitiendo múltiples operaciones simultáneas para una estrategia dinámica, con un enfoque en la estabilidad mediante trailing stop y límites estrictos de pérdida diaria.

---

## ⚙️ Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: FusRoDah! v03
- **Símbolo**: US100.cash
- **Período**: H1 (2025.04.01 - 2025.04.30)
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
| **Barras**                       | 460               |
| **Ticks**                        | 5,528,619         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 871.23 USD        |
| **Beneficio Bruto**              | 2,670.11 USD      |
| **Pérdidas Brutas**              | -1,798.88 USD     |
| **Factor de Beneficio**          | 1.48              |
| **Beneficio Esperado**           | 18.94 USD         |
| **Factor de Recuperación**       | 1.76              |
| **Ratio de Sharpe**              | 10.12             |
| **Z-Score**                      | 1.26 (79.23%)     |
| **AHPR**                         | 1.0019 (0.19%)    |
| **GHPR**                         | 1.0018 (0.18%)    |
| **Reducción absoluta del balance** | 121.25 USD      |
| **Reducción absoluta de la equidad** | 108.75 USD    |
| **Reducción máxima del balance** | 432.49 USD (4.16%) |
| **Reducción máxima de la equidad** | 495.14 USD (4.75%) |
| **Reducción relativa del balance** | 4.16% (432.49 USD) |
| **Reducción relativa de la equidad** | 4.75% (495.14 USD) |
| **Nivel de margen**              | 386.90%           |
| **LR Correlation**               | 0.79              |
| **LR Standard Error**            | 140.55            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 46                |
| **Total de transacciones**                | 92                |
| **Posiciones rentables (% del total)**    | 36 (78.26%)       |
| **Posiciones no rentables (% del total)** | 10 (21.74%)       |
| **Posiciones cortas (% rentables)**       | 20 (80.00%)       |
| **Posiciones largas (% rentables)**       | 26 (76.92%)       |
| **Transacción rentable promedio**         | 74.17 USD         |
| **Transacción no rentable promedio**      | -179.89 USD       |
| **Transacción rentable máxima**           | 160.27 USD        |
| **Transacción no rentable máxima**        | -181.35 USD       |
| **Máximo de ganancias consecutivas**      | 9 (633.52 USD)    |
| **Máximo de pérdidas consecutivas**       | 2 (-354.04 USD)   |
| **Máximo de beneficio consecutivo**       | 633.52 USD (9)    |
| **Máximo de pérdidas consecutivas**       | -354.04 USD (2)   |
| **Promedio de ganancias consecutivas**    | 4                 |
| **Promedio de pérdidas consecutivas**     | 1                 |

---

## 📉 Gráfico de Rendimiento

![Gráfico General](ReportTester-11.png)

---

## ⚠️ Notas y Advertencia

- Esta simulación utiliza `PERMITIR_OPERACIONES_MULTIPLES=true` y `MAX_POSICIONES=4`, permitiendo hasta cuatro operaciones simultáneas para una estrategia más agresiva. La desactivación del multiplicador de lotes (`USAR_MULTIPLICADOR=false`) mantuvo un tamaño de lote fijo, lo que ayudó a limitar la exposición al riesgo en términos de volumen.
- **Advertencia**: Aunque la simulación muestra un beneficio neto de 871.23 USD, los resultados están basados en un período de un mes (01-04-2025 a 30-04-2025), lo que podría limitar su representatividad debido a condiciones específicas del mercado. Esto aumenta el riesgo de **sobreoptimización**. Se recomienda realizar pruebas en períodos más extensos o en condiciones de mercado en vivo para validar la robustez de la estrategia.
- **Gestión de riesgos**: Ajuste parámetros como `LOTE_FIJO`, `PERDIDA_DIARIA_MAXIMA`, `SALDO_MINIMO_OPERATIVO`, y `MAX_POSICIONES` según el tamaño de su cuenta y tolerancia al riesgo. La configuración de múltiples operaciones simultáneas incrementa la exposición, especialmente en mercados volátiles.