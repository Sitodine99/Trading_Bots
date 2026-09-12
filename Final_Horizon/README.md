# FinalHorizon

![FinalHorizon Logo](images/final_horizon_bot.png)

**FinalHorizon** es un **Expert Advisor (EA)** desarrollado para **MetaTrader 5**, diseñado para operar en **índices americanos** (probado sobre **US500**) en un marco temporal **configurable** (H1, H2, H3 o H4). Este bot automatiza operaciones basadas en una estrategia de **cruce de la banda media de Bollinger**, con una salida dinámica que persigue las bandas extremas en tiempo real en lugar de un Stop Loss o Take Profit fijado en el momento de la entrada. Incluye un escalado de lote por balance de cuenta, activable de forma opcional.

---

## 📌 Características Principales

- **Instrumento probado**: índices americanos (base de pruebas: **US500**).
- **Timeframe configurable**: H1, H2, H3 o H4, parametrizable sin tocar código. Configuracion validada: **H1**, periodo de Bollinger **27**, desviacion **2.0**.
- **Estrategia de cruce de banda media de Bollinger**, con entrada **confirmada al cierre de vela** (no en tiempo real — ver Notas de Uso).
- **Salida dinamica**: sin SL/TP fijo adjunto a la orden; se cierra al tocar la banda extrema vigente en cada momento.
- **Escalado de lote por balance** (opcional, activable con `InpUseLotScaling`): el lote crece proporcionalmente al balance de la cuenta, manteniendo el mismo nivel de riesgo relativo validado en backtest, con un suelo minimo configurable (`InpMinLots`).
- **Control de exposición**: límite configurable de posiciones simultáneas (por defecto 1) — se probo subirlo y no mejoro el resultado.
- **Sin gestión de riesgo FTMO**: no implementada en esta version.

---

## 🚀 Estrategia de Trading

### Lógica de Operación
- **Entradas**: cruce del cierre de la vela con la banda media de Bollinger (BUY de abajo a arriba, SELL de arriba a abajo), confirmado una vez por vela cerrada. Se probo tambien una version de entrada inmediata (en tiempo real, sin esperar al cierre) y dio resultado claramente peor (profit factor por debajo de 1, drawdown mucho mayor) por exceso de ruido intrabar — por eso la version de referencia sigue siendo la confirmada al cierre.
- **Salidas**: dinamicas, comprobadas en cada tick contra la banda superior/inferior vigente (de la ultima vela cerrada). Una compra se cierra al tocar la banda superior (a favor) o la inferior (en contra); una venta, al reves.
- **Escalado de lote**: `lote = InpBaseLots * (balance_actual / InpBaseBalance)`, redondeado al step de volumen del simbolo, con suelo en `InpMinLots`. Decision explicita del usuario: mantiene el riesgo relativo del lote base, no lo reduce en perdidas.

---

## 🛡️ Gestión de Riesgo

**FinalHorizon no está alineado con los requisitos de FTMO ni de ningún otro proveedor de fondeo en esta versión.** No hay límite de pérdida diaria, ni objetivo de saldo, ni saldo mínimo operativo. Es una decisión deliberada: el usuario ha optado por asumir un nivel de riesgo alto en esta cuenta de prueba a cambio de mayor velocidad de crecimiento, en vez de una gestion conservadora.

**Riesgo real conocido (ver Resultados de Simulación):** en el periodo completo 2020-2026 con escalado activo, el drawdown relativo real (pico a valle, no solo el maximo en dolares) alcanzo el **48,43%** de la cuenta, en un episodio entre mayo de 2023 y mayo de 2024 — ademas del crash de 2020, que por si solo ya produjo una caida de magnitud similar. Este nivel de riesgo es una decision explicita del usuario, no una recomendacion.

---

## 📊 Resultados de Simulación

**Configuración de referencia:** US500, H1, periodo de Bollinger 27, desviación 2.0, escalado de lote activo (`InpBaseLots=0.4`, `InpBaseBalance=500`, `InpMinLots=0.4`), límite de 1 posición simultánea, depósito inicial 500 USD, apalancamiento 1:30.

### Periodo 2025.01.01 – 2026.09.12 (modelo "cada tick real", calidad de historial 100%)

| Métrica | Valor |
|---|---|
| Beneficio neto | 1.048,61 $ |
| Beneficio bruto / Pérdidas brutas | 4.718,53 $ / -3.669,92 $ |
| Factor de beneficio | 1,286 |
| Factor de recuperación | 3,30 |
| Ratio de Sharpe | 3,08 |
| Reducción máxima del balance | 291,64 $ (27,35%) |
| Reducción máxima de la equidad | 317,42 $ (29,08%) |
| Operaciones ejecutadas | 458 |
| Tiempo medio de retención de posición | 6:08:34 |

**Aviso importante sobre este resultado:** este periodo (2025-2026) es la misma ventana que se usó para optimizar el periodo y la desviación de Bollinger. Por lo tanto, este resultado por sí solo **no es una validación fuera de muestra** — es esperable que rinda bien aquí precisamente porque los parámetros se eligieron para que lo hiciera. La validación honesta de esta estrategia está en el periodo 2020-2024 (no usado en la optimización), donde el profit factor fuera de muestra ronda 1,05-1,10 sin escalado, y el drawdown real (pico a valle) llega al 48% con el escalado activo sobre el periodo completo 2020-2026.

**Comisión:** en todos los backtests realizados hasta ahora, la comisión registrada por el Tester es 0,0 en el 100% de las transacciones. Pendiente de confirmar si esto es correcto para el tipo de cuenta real (Standard vs Raw/ECN) o si falta modelar un coste real que el resultado no está reflejando.

---

## ⚙ Instalación

1. Guarda el archivo como `FinalHorizon.mq5` en tu carpeta de expertos: `<MetaTrader5>\MQL5\Experts`.
2. Abre MetaEditor y compílalo (F7) — **recompila siempre tras cualquier cambio en el código**, MetaTrader no detecta cambios en el `.mq5` si no se recompila a `.ex5`.
3. Aplica el EA al gráfico del índice que quieras probar (recomendado: US500, H1).
4. Configura los inputs según tu prueba (ver tabla de parámetros).
5. Activa el **trading automático**.

---

## 🧾 Parámetros Configurables

| Parámetro            | Descripción                                                          | Valor por defecto |
|-----------------------|-----------------------------------------------------------------------|-------------------|
| `InpTimeframe`        | Timeframe de operativa (H1, H2, H3, H4...)                            | H1                |
| `InpBBPeriod`         | Periodo de la banda de Bollinger                                      | 27                |
| `InpBBDeviation`      | Desviación estándar de la banda                                       | 2.0               |
| `InpFixedLots`        | Lote fijo (usado solo si `InpUseLotScaling = false`)                  | 0.4               |
| `InpUseLotScaling`    | Activar escalado de lote según balance de la cuenta                   | true              |
| `InpBaseLots`         | Lote base de referencia (el ya validado en backtest)                  | 0.4               |
| `InpBaseBalance`      | Balance de referencia para ese lote base (USD)                        | 500.0             |
| `InpMinLots`          | Suelo: el lote nunca baja de este valor, aunque el balance caiga      | 0.4               |
| `InpMaxOpenTrades`    | Máximo de posiciones simultáneas de este bot                          | 1                 |
| `InpMagicNumber`      | Magic number para identificar las operaciones del EA                  | 20260911          |
| `InpTradeComment`     | Comentario adjunto a las órdenes                                      | BollMidCross      |

---

## 📝 Notas de Uso

- **Cuenta demo primero**: prueba siempre el EA en entorno demo antes de aplicarlo en real.
- **No apto para retos de fondeo**: sin gestión de riesgo FTMO, este bot no cumple los requisitos típicos de límite de pérdida diaria ni protección de saldo.
- **Riesgo alto aceptado deliberadamente**: con el escalado activo y `InpBaseLots=0.4` sobre `InpBaseBalance=500`, el drawdown real observado en backtest llega al 48% en el peor tramo (2023-2024). Esta es una decisión explícita del usuario para maximizar velocidad de crecimiento en una cuenta que puede permitirse perder, no una recomendación de gestión de riesgo estándar.
- **Entrada confirmada al cierre de vela, no en tiempo real**: se probó una versión de entrada inmediata y rindió peor (profit factor por debajo de 1). No cambiar esto sin volver a validar.
- **Sin filtro de tendencia**: se probó (SMA de periodo largo) en una version anterior, no mejoro el resultado en una prueba rapida sin optimizar, y se retiro del codigo por completo. No forma parte de esta version.
- **Modelo de ejecución en backtest**: usar "OC 1 minuto" para periodos anteriores a 2025 (calidad ~98% en este broker/símbolo, frente a 21-41% con "cada tick real" para años antiguos). Para 2025-2026 "cada tick real" ya da 100% de calidad.
- **Comisión no modelada**: verificar en MetaTrader (Especificación del contrato de US500) si la cuenta real tiene comisión aparte del spread; los backtests actuales no la incluyen.
- **En fase de optimización**: los resultados de 2025-2026 corresponden a la ventana de optimización, no a una validación fuera de muestra. Antes de operar en real, revisar el resultado sobre 2020-2024 para una imagen más honesta del edge real.

---

## 🪪 Licencia

© Jose Antonio Montero. Distribución sujeta a los términos de la licencia [MIT License](LICENSE.md).
