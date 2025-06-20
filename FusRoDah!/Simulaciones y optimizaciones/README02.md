# 📈 Simulación Optimizada: 01-01-2023 a 30-04-2025

Esta simulación fue realizada para el Expert Advisor **FusRoDah! v03** en MetaTrader 5, utilizando datos históricos del índice **US100.cash** desde el **1 de enero de 2023** hasta el **30 de abril de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, con un enfoque en permitir múltiples operaciones simultáneas para una estrategia más agresiva, manteniendo un equilibrio entre rentabilidad y estabilidad.

---

## ⚙️ Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: FusRoDah! v03
- **Símbolo**: US100.cash
- **Período**: H1 (2023.01.01 - 2025.04.30)
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
| `PERMITIR_OPERACIONES_MULTIPLES` | Permitir múltiples operaciones simultáneas            | true              |
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
| **Calidad del historial**        | 22%               |
| **Barras**                       | 9,428             |
| **Ticks**                        | 48,287,127        |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 8,896.55 USD      |
| **Beneficio Bruto**              | 54,040.15 USD     |
| **Pérdidas Brutas**              | -45,143.60 USD    |
| **Factor de Beneficio**          | 1.20              |
| **Beneficio Esperado**           | 9.35 USD          |
| **Factor de Recuperación**       | 5.26              |
| **Ratio de Sharpe**              | 2.95              |
| **Z-Score**                      | -1.44 (85.01%)    |
| **AHPR**                         | 1.0007 (0.07%)    |
| **GHPR**                         | 1.0007 (0.07%)    |
| **Reducción absoluta del balance** | 941.98 USD      |
| **Reducción absoluta de la equidad** | 800.49 USD    |
| **Reducción máxima del balance** | 1,569.40 USD (11.36%) |
| **Reducción máxima de la equidad** | 1,690.98 USD (12.03%) |
| **Reducción relativa del balance** | 11.81% (1,213.46 USD) |
| **Reducción relativa de la equidad** | 12.03% (1,690.98 USD) |
| **Nivel de margen**              | 118.00%           |
| **LR Correlation**               | 0.94              |
| **LR Standard Error**            | 913.53            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 952               |
| **Total de transacciones**                | 1,904             |
| **Posiciones rentables (% del total)**    | 662 (69.54%)      |
| **Posiciones no rentables (% del total)** | 290 (30.46%)      |
| **Posiciones cortas (% rentables)**       | 450 (65.78%)      |
| **Posiciones largas (% rentables)**       | 502 (72.91%)      |
| **Transacción rentable promedio**         | 81.63 USD         |
| **Transacción no rentable promedio**      | -155.67 USD       |
| **Transacción rentable máxima**           | 163.75 USD        |
| **Transacción no rentable máxima**        | -197.43 USD       |
| **Máximo de ganancias consecutivas**      | 17 (1,073.28 USD) |
| **Máximo de pérdidas consecutivas**       | 6 (-837.28 USD)   |
| **Máximo de beneficio consecutivo**       | 1,412.17 USD (12) |
| **Máximo de pérdidas consecutivas**       | -837.28 USD (6)   |
| **Promedio de ganancias consecutivas**    | 3                 |
| **Promedio de pérdidas consecutivas**     | 2                 |

---

## 📉 Gráfico de Rendimiento

![Gráfico General](ReportTester-01.png)

---

## ⚠️ Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros, incluyendo la activación de `PERMITIR_OPERACIONES_MULTIPLES=true`, lo que permite una estrategia más agresiva al abrir múltiples operaciones simultáneas.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de apenas dos años y cuatro meses (01-01-2023 a 30-04-2025), puede haber cierta **sobreoptimización**. La estrategia con múltiples operaciones simultáneas aumenta el riesgo de exposición, especialmente en mercados volátiles. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.
- **Gestión de riesgos**: Asegúrese de ajustar parámetros como `LOTE_FIJO`, `PERDIDA_DIARIA_MAXIMA` y `SALDO_MINIMO_OPERATIVO` según el tamaño de su cuenta y tolerancia al riesgo, especialmente con múltiples operaciones activas.