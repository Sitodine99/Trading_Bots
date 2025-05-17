# Back to the Range

![Back to the Range Logo](images/Back_to_the_Range_logo.png)

**Back to the Range** es un **Expert Advisor (EA)** desarrollado para **MetaTrader 5**, diseñado para operar exclusivamente en **índices** como US500, US100, US30, entre otros, en el marco temporal configurado por el usuario. Este bot automatiza operaciones basadas en una estrategia de **retorno al rango**, identificando niveles de liquidez durante un periodo de recolección de datos y operando cuando el precio cruza estos niveles, buscando capturar movimientos de reversión hacia el rango. Incorpora una gestión de riesgo robusta alineada con los requisitos de desafíos de fondeo como **FTMO**, asegurando un equilibrio entre rentabilidad y protección de capital.

El EA utiliza un sistema de **recolección de liquidez** para determinar los niveles máximo y mínimo de un rango durante un horario específico (por defecto, 7:00-14:00 GMT). Luego, durante el horario de operaciones (por defecto, 16:00-21:00 GMT), abre posiciones de compra o venta cuando el precio cruza estos niveles, con salidas basadas en **Take Profit**, **Stop Loss**, **Trailing Stop** opcional, o **Break Even**. Incluye un **multiplicador de lotes** para aprovechar rachas ganadoras y límites estrictos de **pérdida diaria** y **saldo mínimo**.

---

## 📌 Características Principales

- **Índices soportados**: US500, US100, US30, US2000, SPX500, NAS100, DJI30.
- **Estrategia de retorno al rango**: Identifica niveles de liquidez y opera cruces de estos niveles.
- **Gestión de riesgo avanzada**: Cumple con los límites de pérdida diaria y objetivos de fondeo de FTMO.
- **Trailing Stop dinámico**: Ajusta el Stop Loss para proteger beneficios (opcional).
- **Break Even**: Mueve el Stop Loss al precio de entrada tras un movimiento favorable (opcional).
- **Multiplicador de lotes**: Aumenta el tamaño del lote tras operaciones ganadoras (opcional).
- **Protección de capital**: Cierre automático por pérdida diaria máxima, saldo mínimo o meta de balance alcanzada.
- **Visualización**: Dibuja rangos de liquidez y líneas de tiempo en el gráfico.

---

## 🚀 Estrategia de Trading

**Back to the Range** utiliza una estrategia de **retorno al rango** para operar en índices, identificando niveles de liquidez durante un periodo de recolección (7:00-14:00 GMT) y operando cruces de estos niveles durante un horario definido (16:00-21:00 GMT). La estrategia busca capturar movimientos de reversión hacia el rango, con un enfoque en la consistencia y el control de riesgo.

### Lógica de Operación
- **Formación del Rango**:
  - Durante el periodo de recolección (`HORA_INICIO_RECOGIDA` a `HORA_FINAL_RECOGIDA`), se calculan los niveles máximo y mínimo del precio (`Liquidez::get_max_min`).
  - Estos niveles definen un rango de liquidez visualizado como un rectángulo en el gráfico.
- **Entradas**:
  - **Compra**: Se abre una posición de compra si el precio de cierre de la vela anterior está por debajo del nivel mínimo del rango y el precio actual cruza por encima (`cruce_compra`).
  - **Venta**: Se abre una posición de venta si el precio de cierre de la vela anterior está por encima del nivel máximo del rango y el precio actual cruza por debajo (`cruce_venta`).
- **Salidas**:
  - Las posiciones se cierran al alcanzar el **Take Profit** (`PUNTOS_TP`) o el **Stop Loss** (`PUNTOS_SL`).
  - Si está activado, el **Trailing Stop** ajusta el Stop Loss dinámicamente (`PUNTOS_ACTIVACION_TRAILING`, `PASO_TRAILING_STOP`).
  - Si está activado, el **Break Even** mueve el Stop Loss al precio de entrada tras un movimiento favorable (`PUNTOS_ACTIVACION_BREAK_EVEN`).
- **Razonamiento**: La estrategia asume que los cruces de los niveles de liquidez en índices indican movimientos de impulso que tienden a revertir hacia el rango, especialmente en horarios de alta volatilidad.
- **Filtros**:
  - Una sola operación por dirección (`compra_abierta`, `venta_abierta`) para evitar sobreoperar.
  - Operaciones restringidas al horario definido (`HORA_INICIO_OPERACIONES` a `HORA_FINAL_OPERACIONES`).
  - Validación de márgenes y tamaño de lote para garantizar la viabilidad de las operaciones.

### Gestión de Operaciones
- **Stop Loss**: Configurable en puntos (`PUNTOS_SL`) para cada operación.
- **Take Profit**: Configurable en puntos (`PUNTOS_TP`) para definir objetivos de ganancia.
- **Trailing Stop**: Activable (`USAR_TRAILING_STOP`) y configurable (`PUNTOS_ACTIVACION_TRAILING`, `PASO_TRAILING_STOP`).
- **Break Even**: Activable (`USAR_BREAK_EVEN`) y configurable (`PUNTOS_ACTIVACION_BREAK_EVEN`).
- **Multiplicador de Lotes**: Si está activado (`USAR_MULTIPLICADOR`), el tamaño del lote aumenta (`MULTIPLICADOR_LOTES`) tras una operación ganadora, hasta un máximo (`LOTE_MAXIMO`).
- **Validaciones**: Verifica márgenes disponibles, tamaño de lote mínimo/máximo, y compatibilidad del símbolo.

---

## 🛡️ Gestión de Riesgo (Alineada con FTMO)

**Back to the Range** implementa un sistema de gestión de riesgo diseñado para cumplir con las reglas de los desafíos de fondeo como **FTMO**, que exigen límites de pérdida diaria, protección de capital y consistencia.

### 1. Límite de Pérdida Diaria
- **Parámetro**: `PERDIDA_DIARIA_MAXIMA` (USD) define la pérdida máxima permitida en un día.
- **Cinturón de Seguridad**: El parámetro `FACTOR_CINTURON_SEGURIDAD` (0.0 a 1.0) reduce el límite efectivo. Por ejemplo, si `PERDIDA_DIARIA_MAXIMA = 500` y `FACTOR_CINTURON_SEGURIDAD = 0.5`, el límite real es **250 USD**.
- **Cálculo**: Combina pérdidas realizadas y flotantes (`calcular_perdida_diaria_total`) para monitorear el riesgo en tiempo real.
- **Acción**: Si se alcanza el límite, el EA cierra todas las posiciones y desactiva el trading hasta el siguiente día (00:00 hora de España).

### 2. Saldo Mínimo Operativo
- **Parámetro**: `SALDO_MINIMO_OPERATIVO` (USD) establece el nivel mínimo de capital para operar.
- **Acción**: Si el **equity** o **balance** cae por debajo de este nivel, el EA cierra todas las posiciones y detiene el trading.

### 3. Objetivo de Saldo
- **Parámetro**: `OBJETIVO_SALDO` (USD) define una meta de ganancias. Si se activa (`USAR_OBJETIVO_SALDO = true`), el EA cierra todas las posiciones y se detiene al alcanzar este nivel.
- **Uso**: Ideal para desafíos de fondeo que requieren alcanzar un objetivo de rentabilidad.

### 4. Reseteo Diario
- **Lógica**: Reinicia los contadores de pérdida diaria y estado de trading a las **00:00 hora de España**, ajustado según el horario de verano/invierno (UTC+1 o UTC+2).
- **Beneficio**: Garantiza que las reglas de pérdida diaria se respeten según los ciclos de los proveedores de fondeo.

### 5. Multiplicador de Lotes
- **Lógica**: Tras una operación ganadora, el tamaño del lote puede aumentar (`MULTIPLICADOR_LOTES`) hasta un máximo (`LOTE_MAXIMO`). Tras una pérdida, se restablece al valor inicial (`LOTE_FIJO`).
- **Control de Riesgo**: Ajusta el lote según los márgenes disponibles para evitar problemas de ejecución.

### 6. Validaciones de Seguridad
- **Símbolo Soportado**: Verifica que el símbolo sea un índice soportado (US500, US100, etc.). Si no, el EA se detiene.
- **Parámetros Incorrectos**: Valida parámetros como `FACTOR_CINTURON_SEGURIDAD`, usando valores predeterminados seguros si son inválidos.
- **Margen**: Ajusta el tamaño del lote según el margen disponible (`AdjustLotToMargin`).

Esta gestión de riesgo asegura que **Back to the Range** sea compatible con las reglas de FTMO, protegiendo la cuenta mientras maximiza las oportunidades de pasar los desafíos de fondeo.

---

## 📊 Resultados de Simulación

**Back to the Range** ha sido evaluado con datos reales en MetaTrader 5 usando una simulación con parámetros optimizados.
- **[Resultados de Simulación](Simulaciones%20y%20optimizaciones/README.md)**

---

## ⚙ Instalación

1. Guarda el archivo como `Back_to_the_Range.mq5` en tu carpeta de expertos: `<MetaTrader5>\MQL5\Experts`.
2. Abre MetaEditor y compílalo.
3. Aplica el EA al gráfico de un **índice soportado** (ej. US500) en la temporalidad deseada.
4. Ajusta los parámetros si lo deseas, o usa los predeterminados para replicar la estrategia base.
5. Activa el **trading automático**.

---

## 🧾 Parámetros Configurables

| Parámetro                         | Descripción                                                  | Valor por defecto |
|-----------------------------------|--------------------------------------------------------------|-------------------|
| `HORA_INICIO_RECOGIDA`            | Hora de inicio para recolección de datos (GMT)               | 7                 |
| `HORA_FINAL_RECOGIDA`             | Hora de fin para recolección de datos (GMT)                  | 14                |
| `HORA_INICIO_OPERACIONES`         | Hora de inicio para operaciones (GMT)                        | 16                |
| `HORA_FINAL_OPERACIONES`          | Hora de fin para operaciones (GMT)                           | 21                |
| `LOTE_FIJO`                       | Tamaño de lote inicial                                       | 2.0               |
| `USAR_MULTIPLICADOR`              | Activar multiplicador de lotes tras ganancia                 | true              |
| `MULTIPLICADOR_LOTES`             | Multiplicador en rachas ganadoras                            | 1.7               |
| `LOTE_MAXIMO`                     | Tamaño máximo del contrato                                   | 3.4               |
| `PUNTOS_SL`                       | Stop Loss en puntos                                          | 8000              |
| `PUNTOS_TP`                       | Take Profit en puntos                                        | 15000             |
| `USAR_TRAILING_STOP`              | Activar/desactivar trailing stop                             | true              |
| `PUNTOS_ACTIVACION_TRAILING`      | Puntos para activar trailing stop                            | 4000              |
| `PASO_TRAILING_STOP`              | Paso del trailing stop en puntos                             | 4000              |
| `USAR_BREAK_EVEN`                 | Activar/desactivar break even                                | false             |
| `PUNTOS_ACTIVACION_BREAK_EVEN`    | Puntos para activar break even                               | 8000              |
| `USAR_OBJETIVO_SALDO`             | Activar objetivo de saldo                                    | false             |
| `OBJETIVO_SALDO`                  | Objetivo de saldo para cerrar el bot (USD)                   | 11000.0           |
| `SALDO_MINIMO_OPERATIVO`          | Saldo mínimo para operar (USD)                               | 9050.0            |
| `PERDIDA_DIARIA_MAXIMA`           | Pérdida diaria máxima permitida (USD)                        | 500.0             |
| `FACTOR_CINTURON_SEGURIDAD`       | Multiplicador de seguridad sobre la pérdida máxima diaria    | 0.5               |
| `COLOR_RECTANGULO`                | Color del rectángulo de rango                                | clrWhite          |
| `COLOR_LINEAS`                    | Color de las líneas de tiempo                                | clrRed            |

---

## 📝 Notas de Uso

- **Cuenta demo primero**: Prueba el EA en entorno demo antes de aplicarlo en real.
- **FTMO-Friendly**: Los límites de pérdida y el control de saldo están alineados con requisitos típicos de pruebas de fondeo.
- **Optimizable**: El rendimiento puede variar según el índice, spread, y broker. Usa el optimizador de MetaTrader para ajustar parámetros.
- **Horario del broker**: Asegúrate de que el broker usa el horario adecuado para alinear las operaciones con el reseteo diario.
- **Índices soportados**: El EA solo funciona en índices como US500, US100, US30, etc. Verifica el símbolo antes de aplicarlo.

---

## 🪪 Licencia

© Jose Antonio Montero. Distribución sujeta a los términos de la licencia [MIT License](LICENSE.md).