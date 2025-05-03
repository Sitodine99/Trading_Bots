# 📈 Simulación Optimizada: 01-03-2025 a 31-03-2025

Esta simulación fue realizada para el Expert Advisor **FusRoDah! v03** en MetaTrader 5, utilizando datos históricos del índice **US100.cash** desde el **1 de marzo de 2025** hasta el **31 de marzo de 2025**. Los parámetros fueron optimizados para maximizar el rendimiento mientras se controla el riesgo, con un enfoque en permitir múltiples operaciones simultáneas para una estrategia más agresiva, manteniendo un equilibrio entre rentabilidad y estabilidad.

---

## ⚙️ Configuración de la Simulación

- **Informe del Probador de Estrategias**: FTMO-Server5 (Build 4755)
- **Experto**: FusRoDah! v03
- **Símbolo**: US100.cash
- **Período**: H1 (2025.03.01 - 2025.03.31)
- **Empresa**: FTMO Global Markets Ltd
- **Divisa**: USD
- **Depósito inicial**: 10,000.00 USD
- **Apalancamiento**: 1:30

### Parámetros de Entrada

| Parámetro                   | Descripción                                               | Valor Utilizado   |
|-----------------------------|-----------------------------------------------------------|-------------------|
| `LOTE_FIJO`                 | Lote fijo inicial para las operaciones                    | 1.0               |
| `USAR_MULTIPLICADOR`        | Activar/desactivar multiplicador de lotes para rachas ganadoras | true              |
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
| `SALDO_MINIMO_OPERATIVO`    | Saldo mínimo operativo (USD)                              | 9050.0            |
| `PERDIDA_DIARIA_MAXIMA`     | Pérdida diaria máxima permitida (USD)                     | 500.0             |
| `FACTOR_CINTURON_SEGURIDAD` | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.5               |

---

## 📊 Resultados de la Simulación

### Resumen General

| Métrica                          | Valor              |
|----------------------------------|--------------------|
| **Calidad del historial**        | 100%              |
| **Barras**                       | 460               |
| **Ticks**                        | 4,821,679         |
| **Símbolos**                     | 1                 |
| **Beneficio Neto**               | 1,181.99 USD      |
| **Beneficio Bruto**              | 5,016.68 USD      |
| **Pérdidas Brutas**              | -3,834.69 USD     |
| **Factor de Beneficio**          | 1.31              |
| **Beneficio Esperado**           | 27.49 USD         |
| **Factor de Recuperación**       | 0.97              |
| **Ratio de Sharpe**              | 6.43              |
| **Z-Score**                      | -1.19 (76.60%)    |
| **AHPR**                         | 1.0029 (0.29%)    |
| **GHPR**                         | 1.0026 (0.26%)    |
| **Reducción absoluta del balance** | 259.81 USD      |
| **Reducción absoluta de la equidad** | 397.18 USD    |
| **Reducción máxima del balance** | 1,155.21 USD (10.08%) |
| **Reducción máxima de la equidad** | 1,222.69 USD (10.66%) |
| **Reducción relativa del balance** | 10.08% (1,155.21 USD) |
| **Reducción relativa de la equidad** | 10.66% (1,222.69 USD) |
| **Nivel de margen**              | 138.14%           |
| **LR Correlation**               | 0.72              |
| **LR Standard Error**            | 383.24            |
| **Resultado de OnTester**        | 0                 |

### Estadísticas de Operaciones

| Métrica                                   | Valor              |
|-------------------------------------------|--------------------|
| **Total de operaciones ejecutadas**       | 43                |
| **Total de transacciones**                | 86                |
| **Posiciones rentables (% del total)**    | 29 (67.44%)       |
| **Posiciones no rentables (% del total)** | 14 (32.56%)       |
| **Posiciones cortas (% rentables)**       | 21 (57.14%)       |
| **Posiciones largas (% rentables)**       | 22 (77.27%)       |
| **Transacción rentable promedio**         | 172.99 USD        |
| **Transacción no rentable promedio**      | -273.91 USD       |
| **Transacción rentable máxima**           | 480.90 USD        |
| **Transacción no rentable máxima**        | -530.76 USD       |
| **Máximo de ganancias consecutivas**      | 8 (1,358.86 USD)  |
| **Máximo de pérdidas consecutivas**       | 4 (-911.75 USD)   |
| **Máximo de beneficio consecutivo**       | 1,358.86 USD (8)  |
| **Máximo de pérdidas consecutivas**       | -911.75 USD (4)   |
| **Promedio de ganancias consecutivas**    | 4                 |
| **Promedio de pérdidas consecutivas**     | 2                 |

---

## 📉 Gráfico de Rendimiento

![Gráfico General](ReportTester-04.png)

---

## ⚠️ Notas y Advertencia

- Esta simulación se realizó después de un proceso de optimización de parámetros, incluyendo la activación de `PERMITIR_OPERACIONES_MULTIPLES=true` y `MAX_POSICIONES=4`, lo que permite una estrategia más agresiva al abrir múltiples operaciones simultáneas.
- **Advertencia**: Aunque la optimización mejora el rendimiento, al estar concentrada en un período de apenas un mes (01-03-2025 a 31-03-2025), puede haber cierta **sobreoptimización**. La estrategia con múltiples operaciones simultáneas aumenta el riesgo de exposición, especialmente en mercados volátiles. Se recomienda realizar pruebas adicionales en períodos más amplios o en condiciones de mercado en vivo para validar la robustez de la estrategia.
- **Gestión de riesgos**: Asegúrese de ajustar parámetros como `LOTE_FIJO`, `PERDIDA_DIARIA_MAXIMA`, `SALDO_MINIMO_OPERATIVO`, y `MAX_POSICIONES` según el tamaño de su cuenta y tolerancia al riesgo, especialmente con múltiples operaciones activas.