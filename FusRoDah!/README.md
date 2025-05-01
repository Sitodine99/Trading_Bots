# FusRoDah!

![FusRoDah! Logo](images/FusRoDah!_logo.png)

**FusRoDah!** es un **Expert Advisor (EA)** desarrollado para **MetaTrader 5**, diseñado para operar en **índices americanos** (US100, US500, US30, etc.) en el marco temporal de **1 hora (H1)**. Este bot automatiza operaciones basadas en **rupturas de rangos** definidos en ventanas horarias configurables, con una estrategia optimizada para capturar movimientos direccionales y una gestión de riesgo robusta, especialmente alineada con los requisitos de desafíos de fondeo como **FTMO**.

El EA incorpora herramientas avanzadas de gestión de capital, incluyendo **Stop Loss**, **Take Profit**, **Trailing Stop** opcional, límites de **pérdida diaria**, y un sistema de **multiplicador de lotes** para maximizar el rendimiento tras operaciones ganadoras. Su diseño busca equilibrar rentabilidad y control de riesgo, respetando las reglas estrictas de los programas de fondeo.

---

## 📌 Características Principales

- **Índices soportados**: Opera en índices americanos como US100, US500, US30, US2000, SPX500, NAS100, DJI30.
- **Estrategia de ruptura de rangos**: Coloca órdenes pendientes **BuyStop** y **SellStop** en los máximos y mínimos de rangos horarios.
- **Operaciones múltiples**: Permite activar o desactivar la posibilidad de abrir varias operaciones simultáneamente, aumentando la agresividad de la estrategia si se desea.
- **Gestión de riesgo avanzada**: Cumple con los límites de pérdida diaria y objetivos de fondeo de FTMO.
- **Trailing Stop dinámico**: Ajusta el Stop Loss para proteger beneficios (opcional).
- **Multiplicador de lotes**: Aumenta el tamaño del lote tras operaciones ganadoras (opcional).
- **Protección de capital**: Cierre automático por pérdida diaria máxima, saldo mínimo o meta de balance alcanzada.
- **Configuración flexible**: Amplios parámetros ajustables para adaptarse a diferentes estilos de trading.

---

## 🚀 Estrategia de Trading

**FusRoDah!** utiliza una estrategia de **ruptura de rangos** para identificar oportunidades en índices americanos, implementando órdenes pendientes que capitalizan movimientos direccionales tras la consolidación del precio en rangos horarios definidos por el usuario. El EA permite configurar hasta dos ventanas horarias diarias (en el horario del servidor, típicamente UTC+3) para adaptarse a las preferencias del trader.

### Ventanas de Formación de Rangos
- Las ventanas horarias son completamente configurables mediante los parámetros `HORA_INICIAL_RANGO1`, `HORA_FINAL_RANGO1`, `HORA_INICIAL_RANGO2`, y `HORA_FINAL_RANGO2`. 
- El usuario define los periodos de análisis (por ejemplo, sesiones de alta volatilidad o consolidación) según el índice y las condiciones del mercado.

### Lógica de Operación
- **Formación del rango**: El EA calcula el máximo y mínimo del precio dentro de cada ventana horaria configurada, utilizando datos de velas en el marco temporal elegido (por defecto, H1, ajustable con `PERIODO`).
- **Órdenes pendientes**:
  - Una orden **BuyStop** se coloca en el **máximo del rango**, esperando una ruptura alcista.
  - Una orden **SellStop** se coloca en el **mínimo del rango**, esperando una ruptura bajista.
- **Expiración**: Las órdenes pendientes expiran tras un tiempo definido por el usuario (`HORAS_EXPIRACION`), permitiendo flexibilidad para ajustar la duración según la estrategia.
- **Operaciones múltiples**: Si `PERMITIR_OPERACIONES_MULTIPLES` está activado (`true`), el EA puede colocar nuevas órdenes incluso si ya existen posiciones abiertas u órdenes pendientes, aumentando la exposición al mercado. Si está desactivado (`false`), solo se coloca una orden por rango si no hay órdenes o posiciones activas, evitando sobreoperar.
- **Razonamiento**: La estrategia aprovecha movimientos de ruptura tras periodos de consolidación, comunes en índices americanos, asumiendo que las rupturas indican momentum direccional. Los rangos horarios personalizables permiten al usuario alinear la operativa con sesiones específicas del mercado.
- **Filtros**:
  - Validaciones de Stop Loss y Take Profit para cumplir con los niveles mínimos del broker.

### Gestión de Operaciones
- **Stop Loss y Take Profit**: Configurables en puntos (`PUNTOS_SL`, `PUNTOS_TP`) para cada operación, asegurando un riesgo controlado.
- **Trailing Stop**: Activable (`USAR_TRAILING_STOP`) y configurable (`PUNTOS_ACTIVACION_TRAILING`, `PASO_TRAILING_STOP`) para proteger ganancias en tendencias prolongadas.
- **Multiplicador de Lotes**: Si está activado (`USAR_MULTIPLICADOR`), el tamaño del lote aumenta (`MULTIPLICADOR_LOTES`) tras una operación ganadora, hasta un máximo (`LOTE_MAXIMO`).
- **Visualización**: Dibuja un rectángulo en el gráfico (`COLOR_RECTANGULO`) para mostrar el rango formado, con un color personalizable.

---

## 🛡️ Gestión de Riesgo (Alineada con FTMO)

**FusRoDah!** implementa un sistema de gestión de riesgo diseñado para cumplir con las estrictas reglas de los desafíos de fondeo como **FTMO**, que exigen límites de pérdida diaria, protección de capital y consistencia. A continuación, se detalla cómo se logra:

### 1. Límite de Pérdida Diaria
- **Parámetro**: `PERDIDA_DIARIA_MAXIMA` (USD) define la pérdida máxima permitida en un día.
- **Cinturón de Seguridad**: El parámetro `FACTOR_CINTURON_SEGURIDAD` (0.0 a 1.0) reduce el límite efectivo de pérdida diaria. Por ejemplo, si `PERDIDA_DIARIA_MAXIMA = 500` y `FACTOR_CINTURON_SEGURIDAD = 0.95`, el límite real es **475 USD**.
- **Cálculo**: Combina pérdidas realizadas y flotantes (`calcular_perdida_diaria_total`) para monitorear el riesgo en tiempo real.
- **Acción**: Si se alcanza el límite, el EA cierra todas las posiciones y desactiva el trading hasta el siguiente día (00:00 hora de España).

### 2. Saldo Mínimo Operativo
- **Parámetro**: `SALDO_MINIMO_OPERATIVO` (USD) establece el nivel mínimo de capital para operar.
- **Acción**: Si el **equity** cae por debajo de este nivel, el EA cierra todas las posiciones y detiene el trading para proteger la cuenta.

### 3. Objetivo de Saldo
- **Parámetro**: `OBJETIVO_SALDO` (USD) define una meta de ganancias. Si se activa (`USAR_OBJETIVO_SALDO = true`), el EA cierra todas las posiciones y se detiene al alcanzar este nivel.
- **Uso**: Ideal para desafíos de fondeo que requieren alcanzar un objetivo de rentabilidad sin violar reglas de riesgo.

### 4. Reseteo Diario
- **Lógica**: El EA reinicia los contadores de pérdida diaria y estado de trading a las **00:00 hora de España**, ajustado según el horario de verano/invierno (UTC+1 o UTC+2).
- **Beneficio**: Garantiza que las reglas de pérdida diaria se respeten según los ciclos de los proveedores de fondeo.

### 5. Multiplicador de Lotes
- **Lógica**: Tras una operación ganadora, el tamaño del lote puede aumentar (`MULTIPLICADOR_LOTES`) para aprovechar rachas positivas, pero siempre limitado por `LOTE_MAXIMO`.
- **Control de Riesgo**: Si la operación es perdedora, el tamaño del lote vuelve al valor inicial (`LOTE_FIJO`), evitando una exposición excesiva tras pérdidas.

### 6. Validaciones de Seguridad
- **Símbolos Soportados**: El EA verifica que se ejecute en índices americanos (US100, US500, etc.). Si se usa en otro símbolo, se detiene automáticamente.
- **Parámetros Incorrectos**: Incluye validaciones para parámetros como `PUNTOS_ACTIVACION_TRAILING` o `FACTOR_CINTURON_SEGURIDAD`, usando valores predeterminados seguros si son inválidos.

Esta gestión de riesgo asegura que **FusRoDah!** sea compatible con las reglas de FTMO, protegiendo la cuenta mientras maximiza las oportunidades de pasar los desafíos de fondeo.

---

## 📊 Resultados de Simulación

**FusRoDah!** ha sido evaluado con datos reales en MetaTrader 5 usando una simulación con parámetros optimizados.
- **[Resultados de Simulación](Simulaciones%20y%20optimizaciones/README.md)**

---

## ⚙ Instalación

1. Guarda el archivo como `FusRoDah!.mq5` en tu carpeta de expertos: `<MetaTrader5>\MQL5\Experts`.
2. Abre MetaEditor y compílalo.
3. Aplica el EA al gráfico de un **índice americano** (por ejemplo, US100) en temporalidad **H1**.
4. Ajusta los parámetros si lo deseas, o usa los predeterminados para replicar la estrategia base.
5. Activa el **trading automático**.

---

## 🧾 Parámetros Configurables

| Parámetro                       | Descripción                                               | Valor por defecto |
|---------------------------------|-----------------------------------------------------------|-------------------|
| `LOTE_FIJO`                     | Tamaño de lote inicial                                    | 1.0               |
| `USAR_MULTIPLICADOR`            | Activar multiplicador de lotes tras ganancia              | false             |
| `MULTIPLICADOR_LOTES`           | Multiplicador en rachas ganadoras                         | 2.0               |
| `LOTE_MAXIMO`                   | Tamaño máximo de lote                                     | 4.8               |
| `PERIODO`                       | Marco temporal del gráfico                                | PERIOD_H1         |
| `COLOR_RECTANGULO`              | Color del rectángulo del rango en el gráfico              | clrBlue           |
| `HORA_INICIAL_RANGO1`           | Hora inicial del primer rango (UTC+3)                     | 3.0               |
| `HORA_FINAL_RANGO1`             | Hora final del primer rango (UTC+3)                       | 9.0               |
| `HORA_INICIAL_RANGO2`           | Hora inicial del segundo rango (UTC+3)                    | 14.0              |
| `HORA_FINAL_RANGO2`             | Hora final del segundo rango (UTC+ educate
| `PUNTOS_SL`                     | Stop Loss en puntos                                       | 18000             |
| `PUNTOS_TP`                     | Take Profit en puntos                                     | 16000             |
| `HORAS_EXPIRACION`              | Expiración de órdenes pendientes (horas)                  | 6                 |
| `USAR_TRAILING_STOP`            | Activar/desactivar trailing stop                          | true              |
| `PUNTOS_ACTIVACION_TRAILING`    | Beneficio necesario para activar trailing stop            | 6000              |
| `PASO_TRAILING_STOP`            | Paso del trailing stop en puntos                          | 1500              |
| `PERMITIR_OPERACIONES_MULTIPLES`| Permitir múltiples operaciones simultáneas                | false             |
| `USAR_OBJETIVO_SALDO`           | Activar objetivo de saldo                                 | true              |
| `OBJETIVO_SALDO`                | Objetivo de saldo para cerrar el bot                      | 11000.0           |
| `SALDO_MINIMO_OPERATIVO`        | Saldo mínimo para operar                                  | 9000.0            |
| `PERDIDA_DIARIA_MAXIMA`         | Pérdida diaria máxima permitida                           | 500.0             |
| `FACTOR_CINTURON_SEGURIDAD`     | Multiplicador de seguridad sobre la pérdida máxima diaria | 0.95              |

---

## 📝 Notas de Uso

- **Cuenta demo primero**: Siempre prueba el EA en entorno demo antes de aplicarlo en real.
- **FTMO-Friendly**: Los límites de pérdida y el control de saldo están alineados con requisitos típicos de pruebas de fondeo.
- **Optimizable**: El rendimiento puede mejorar según mercado, spread, y broker. Se recomienda evaluar la estrategia con el optimizador de MetaTrader para configurar los parámetros.
- **Horario del broker**: Asegúrate de que el broker usa el horario UTC+3 para alinear las ventanas de trading.

---

## 🪪 Licencia

© Jose Antonio Montero. Distribución sujeta a los términos de la licencia [MIT License](LICENSE.md).