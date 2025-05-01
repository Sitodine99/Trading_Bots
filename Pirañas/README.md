# Pirañas

![Pirañas Logo](images/Piranhas_logo.png)

**Pirañas** es un **Expert Advisor (EA)** desarrollado para **MetaTrader 5**, diseñado para operar principalmente en el par de divisas **EUR/USD** en el marco temporal de **10 minutos (M10)**. Este bot automatiza operaciones basadas en una estrategia de **reversión al rango** utilizando indicadores técnicos como **RSI**, **EMA**, y **ADX**, con el objetivo de capturar beneficios pequeños y constantes ("bocaditos") en mercados de baja tendencia. Incorpora una gestión de riesgos robusta, alineada con los requisitos de desafíos de fondeo como **FTMO**, y utiliza un sistema de **martingala conservadora** para recuperar pérdidas de manera controlada.

El EA está optimizado para operar en condiciones de rango, con un enfoque en la consistencia y la protección del capital, ideal para traders que buscan cumplir con las reglas estrictas de los programas de fondeo mientras generan ganancias regulares.

---

## 📌 Características Principales

- **Par soportado**: Diseñado para **EUR/USD**, aunque puede adaptarse a otros pares de divisas como GBP/USD.
- **Estrategia de reversión**: Opera en niveles extremos de RSI, confirmados por la posición del precio respecto a la EMA y un filtro de ADX para mercados en rango.
- **Martingala conservadora**: Utiliza un multiplicador de lotes bajo para gestionar pérdidas, maximizando la seguridad.
- **Gestión de riesgos FTMO**: Incluye límites de pérdida diaria, capital mínimo operativo, y cierre por objetivos de balance.
- **Configuración flexible**: Parámetros ajustables para adaptarse a diferentes estilos de trading y condiciones de mercado.
- **Logs visuales**: Registros en español con emojis para un monitoreo claro de operaciones y eventos.

---

## 🚀 Estrategia de Trading

**Pirañas** implementa una estrategia de **reversión al rango** que busca capturar movimientos de precio tras condiciones de sobreventa o sobrecompra en EUR/USD. Utiliza indicadores técnicos para identificar oportunidades y un sistema de martingala conservadora para gestionar el riesgo, asegurando beneficios pequeños pero frecuentes.

### Condiciones de Entrada
- **RSI (Índice de Fuerza Relativa)**: 
  - Compra: RSI < `RSI_NIVEL_COMPRA` (por defecto 30) con un pico (mínimo local).
  - Venta: RSI > `RSI_NIVEL_VENTA` (por defecto 70) con un pico (máximo local).
- **EMA (Media Móvil Exponencial)**:
  - Compra: Precio por debajo de la EMA (`MA_PERIODO`, por defecto 200), indicando una posible reversión alcista.
  - Venta: Precio por encima de la EMA, indicando una posible reversión bajista.
- **ADX (Índice Direccional Promedio)**:
  - Solo opera si ADX < `ADX_NIVEL_MAX` (por defecto 25), confirmando un mercado en rango o con tendencia débil.
- **Distancia entre operaciones**: Nuevas posiciones solo se abren si el precio está a `DISTANCIA_OPERACIONES` puntos (por defecto 30) de la última operación, evitando acumulación excesiva.
- **Tipo de posiciones**: Solo permite posiciones del mismo tipo (todas compras o todas ventas) para mantener la coherencia de la estrategia.

### Lógica de Operación
- **Entradas**: 
  - Compra: RSI en sobreventa, precio bajo la EMA, ADX en rango, y solo posiciones de compra abiertas (o ninguna).
  - Venta: RSI en sobrecompra, precio sobre la EMA, ADX en rango, y solo posiciones de venta abiertas (o ninguna).
- **Martingala**: El tamaño del lote aumenta con un multiplicador (`MULTIPLICADOR`, por defecto 1.5) para cada nueva posición, permitiendo recuperar pérdidas de manera controlada.
- **Cierre de posiciones**:
  - Por beneficio: Cierra todas las posiciones si el beneficio flotante alcanza `OBJETIVO_PROFIT` (por defecto 50 USD).
  - Por tiempo: Cierra posiciones si han pasado `DiasCierreBeneficio` días con un beneficio mínimo (`BeneficioMinimoCierre`) o `DiasTopeMaximo` días.
- **Razonamiento**: La estrategia aprovecha reversiones en mercados en rango, comunes en EUR/USD durante el solapamiento de sesiones Londres-Nueva York. El ADX filtra tendencias fuertes, aumentando la probabilidad de éxito de las reversiones.

### Gestión de Operaciones
- **Tamaño de lote**: Comienza con `LOTAJE_INICIAL` (por defecto 0.01) y crece con `MULTIPLICADOR` según el número de posiciones abiertas.
- **Beneficio objetivo**: Configurable mediante `OBJETIVO_PROFIT` para cerrar posiciones rápidamente, capturando beneficios pequeños.
- **Distancia mínima**: `DISTANCIA_OPERACIONES` asegura que las nuevas posiciones estén separadas, reduciendo el riesgo de sobreoperar.
- **ATR**: Calcula estadísticas de volatilidad al cerrar el bot, proporcionando información útil para optimización futura.

---

## 🛡️ Gestión de Riesgo (Alineada con FTMO)

**Pirañas** incorpora un sistema de gestión de riesgos diseñado para cumplir con las reglas estrictas de desafíos de fondeo como **FTMO**, garantizando la protección del capital y la consistencia operativa.

### 1. Límite de Pérdida Diaria
- **Parámetro**: `MaxDailyLossFTMO` (por defecto 500 USD) establece la pérdida máxima diaria permitida.
- **Cinturón de Seguridad**: `SafetyBeltFactor` (por defecto 0.5) reduce el límite efectivo (e.g., 250 USD con los valores por defecto).
- **Cálculo**: Combina pérdidas realizadas y flotantes (`CalculateTotalDailyLoss`) para monitorear el riesgo en tiempo real.
- **Acción**: Si se alcanza el límite, el EA cierra todas las posiciones y desactiva el trading hasta el siguiente reinicio diario.

### 2. Capital Mínimo Operativo
- **Parámetro**: `MinOperatingBalance` (por defecto 9200 USD) define el nivel mínimo de capital para operar.
- **Acción**: Si el **equity** cae por debajo de este nivel, el EA cierra todas las posiciones y se detiene.

### 3. Objetivo de Balance
- **Parámetro**: `BalanceTarget` (por defecto 11000 USD) establece una meta de ganancias. Si `UseBalanceTarget` es true, el EA cierra todas las posiciones y se detiene al alcanzarla.
- **Uso**: Ideal para cumplir objetivos de rentabilidad en desafíos de fondeo.

### 4. Reinicio Diario
- **Lógica**: Reinicia los contadores de pérdida diaria a las 22:00 UTC (ajustado por horario de verano/invierno en España).
- **Beneficio**: Asegura que los límites de pérdida diaria se respeten según los ciclos de FTMO.

### 5. Martingala Controlada
- **Lógica**: El tamaño del lote crece con `MULTIPLICADOR` (por defecto 1.5) para recuperar pérdidas, pero el bajo valor asegura una exposición moderada.
- **Control**: El EA limita las posiciones al mismo tipo (compra o venta), evitando acumulaciones arriesgadas.

### 6. Validaciones de Seguridad
- **Parámetros incorrectos**: Si `SafetyBeltFactor` no está entre 0.0 y 1.0, usa un valor por defecto (0.5).
- **Monitoreo**: Registra el capital mínimo alcanzado (`minEquity`) y eventos clave en logs claros.

Esta gestión de riesgos hace que **Pirañas** sea ideal para desafíos de fondeo, protegiendo la cuenta mientras busca beneficios constantes.

---

## 📊 Resultados de Simulación

**Pirañas** no incluye resultados de simulación específicos en este repositorio. Se recomienda realizar pruebas en el **Strategy Tester** de MetaTrader 5 con datos históricos de EUR/USD en M10 para evaluar su rendimiento según las condiciones de tu broker.

---

## ⚙ Instalación

1. Guarda el archivo como `Pirañas.mq5` en tu carpeta de expertos: `<MetaTrader5>\MQL5\Experts`.
2. Abre MetaEditor y compílalo.
3. Aplica el EA al gráfico de **EUR/USD** en temporalidad **M10**.
4. Ajusta los parámetros si lo deseas, o usa los predeterminados optimizados para EUR/USD.
5. Activa el **trading automático**.

---

## 🧾 Parámetros Configurables

| Parámetro                       | Descripción                                               | Valor por defecto |
|---------------------------------|-----------------------------------------------------------|-------------------|
| `PERIODO`                       | Marco temporal del gráfico                                | PERIOD_M10        |
| `RSI_PERIODO`                   | Períodos del RSI                                          | 3                 |
| `RSI_NIVEL_COMPRA`              | Nivel de RSI para compras (sobreventa)                    | 30                |
| `RSI_NIVEL_VENTA`               | Nivel de RSI para ventas (sobrecompra)                    | 70                |
| `MA_PERIODO`                    | Períodos de la EMA                                        | 200               |
| `ADX_PERIODO`                   | Períodos del ADX                                          | 14                |
| `ADX_NIVEL_MAX`                 | Nivel máximo de ADX (mercado en rango)                    | 25.0              |
| `LOTAJE_INICIAL`                | Tamaño de lote inicial                                    | 0.01              |
| `MULTIPLICADOR`                 | Multiplicador de lotes para martingala                    | 1.5               |
| `OBJETIVO_PROFIT`               | Beneficio objetivo para cerrar posiciones (USD)           | 50.0              |
| `DISTANCIA_OPERACIONES`         | Distancia mínima entre operaciones (puntos)               | 30                |
| `MaxDailyLossFTMO`              | Pérdida diaria máxima permitida (USD)                     | 500.0             |
| `SafetyBeltFactor`              | Factor de seguridad para pérdida diaria (0.0 a 1.0)       | 0.5               |
| `InitialBalance`                | Balance inicial de referencia (USD)                       | 10000.0           |
| `MinOperatingBalance`           | Capital mínimo para operar (USD)                          | 9200.0            |
| `UseBalanceTarget`              | Activar objetivo de balance                               | true              |
| `BalanceTarget`                 | Objetivo de balance para detener el bot (USD)             | 11000.0           |
| `DiasCierreBeneficio`           | Días mínimos para cerrar con beneficio                    | 1                 |
| `BeneficioMinimoCierre`         | Beneficio mínimo para cierre por tiempo (USD)             | 25.0              |
| `DiasTopeMaximo`                | Días máximos para cerrar posiciones                       | 2                 |

---

## 📝 Notas de Uso

- **Cuenta demo primero**: Prueba el EA en un entorno demo antes de usarlo en una cuenta real.
- **FTMO-Friendly**: Los límites de pérdida diaria y capital mínimo están diseñados para cumplir con las reglas de FTMO.
- **Evitar noticias**: Pausa el bot durante eventos de alto impacto (e.g., NFP, decisiones del BCE), ya que no incluye un filtro automático de noticias.
- **Horario recomendado**: Opera preferiblemente durante el solapamiento de sesiones Londres-Nueva York (13:00-17:00 GMT) para maximizar las oportunidades de reversión.
- **Optimización**: Aunque los parámetros por defecto son adecuados para EUR/USD en M10, puedes optimizarlos usando el Strategy Tester para adaptarlos a tu broker o estilo de trading.

---

## 🪪 Licencia

© Jose Antonio Montero. Distribución sujeta a los términos de la licencia [MIT License](LICENSE.md).