# Bueno, Feo y Malo (Patrón 3 Velas) - MTF SMA

![B3V Logo](images/B3V_logo.png)

**Bueno, Feo y Malo (B3V)** es un **Expert Advisor (EA)** para **MetaTrader 5**, diseñado para operar patrones de **3 velas consecutivas** con movimiento direccional, **a favor de la tendencia** definida por una **Media Móvil Simple (SMA)** en un marco temporal superior (**Multi-TimeFrame**).

El EA utiliza lógica de **órdenes pendientes** basadas en un patrón validado, integra gestión de riesgo avanzada compatible con retos de fondeo como **FTMO**, y ofrece opciones de **multiplicador de lotes**, **trailing stop**, y control de simultaneidad de órdenes.

---

## 📌 Características Principales

- **Patrón 3 Velas**: Señal de entrada basada en tres velas consecutivas con movimiento en la misma dirección y cuerpo mínimo configurable.
- **Filtro de Tendencia**: Requiere que el precio esté por encima o debajo de una **SMA MTF**, asegurando operar a favor de la tendencia principal.
- **Órdenes Pendientes Inteligentes**: Coloca órdenes Buy/Sell Stop o Limit según la ubicación del punto de entrada.
- **Control de Simultaneidad**: Permite limitar el número de órdenes pendientes y posiciones abiertas por símbolo.
- **SL y TP configurables**: Define distancia en puntos para Stop Loss y Take Profit.
- **Trailing Stop dinámico**: Activable y parametrizable para proteger beneficios tras cierto nivel de ganancia.
- **Multiplicador de Lotes (Combo)**: Aumenta el lote tras operaciones ganadoras, con número de pasos limitado o ilimitado.
- **Gestión de Riesgo FTMO-friendly**: Límite de pérdida diaria, balance mínimo operativo y objetivo de balance.
- **Persistencia de Estado**: Guarda el estado del multiplicador entre sesiones si se activa la opción.
- **Diagnóstico y Logs**: Control configurable de mensajes de diagnóstico por vela para facilitar depuración.

---

## 🚀 Estrategia de Trading

Este EA busca detectar un patrón de 3 velas con dirección unificada (alcista o bajista), confirmada con un **filtro de SMA** en un marco temporal superior. Solo coloca órdenes si se cumplen todas las condiciones:

### Requisitos de la Señal

1. **Tres velas consecutivas** con máximos, mínimos, aperturas y cierres ordenados (en la misma dirección).
2. **Cuerpo de la segunda vela** superior a un mínimo (`Body2MinPoints`).
3. Confirmación de tendencia: precio actual mayor o menor a la SMA (`TrendTF`, `TrendMAPeriod`).
4. Validación de distancia mínima al precio para cumplir con `stops_level` y `freeze_level`.

### Órdenes Pendientes

- Se colocan **BuyStop/BuyLimit** o **SellStop/SellLimit** según la posición relativa del precio.
- El precio de entrada es el promedio del **open + close** de la segunda vela.
- Las órdenes se cancelan automáticamente si pasan más de `MaxPendingBars` sin ejecutarse.

---

## 🛡️ Gestión de Riesgo (Estilo FTMO)

- **Pérdida diaria máxima (`MaxDailyLossFTMO`)**: Incluye cinturón de seguridad (`SafetyBeltFactor`), que ajusta el límite efectivo.
- **Saldo mínimo operativo (`MinOperatingBalance`)**: Detiene el trading si el equity cae por debajo de este valor.
- **Objetivo de balance (`BalanceTarget`)**: Si se activa (`UseBalanceTarget`), el EA se detiene automáticamente al alcanzar la meta.
- **Cierre global**: Al alcanzar los límites, el EA cierra todas las posiciones y cancela todas las órdenes pendientes.
- **Reseteo diario**: A las 00:00 hora España (UTC+1 / UTC+2), se reinician contadores y estado del día.

---

## 🔁 Multiplicador de Lotes ("Combo")

- Si `UseComboMultiplier` está activado, tras cada operación ganadora el lote se incrementa por `ComboMultiplier`.
- El ciclo se limita con `ComboMaxSteps`, o es ilimitado si se define como `0`.
- Tras una pérdida, se reinicia al lote base (`LotSize`).
- Si `PersistComboState` está activado, el estado se guarda entre sesiones usando **Global Variables**.

---

## 📊 Requisitos y Compatibilidad

- **Símbolos soportados**: Cualquiera con datos válidos y spreads razonables.
- **Broker con soporte para `SYMBOL_TRADE_*` y `SYMBOL_VOLUME_*`**.
- Compatible con **cuentas demo** y reales, incluyendo plataformas de fondeo tipo FTMO.

---

## ⚙ Instalación

1. Copia el archivo como `B3V_ThreeCandleEA.mq5` en la carpeta de expertos: `<MetaTrader 5>\MQL5\Experts\`.
2. Abre MetaEditor y compílalo.
3. En MetaTrader 5, aplica el EA al gráfico de tu símbolo deseado.
4. Ajusta los parámetros según tu estrategia y broker.
5. Activa el **Trading Automático**.

---

## 🧾 Parámetros Configurables

| Parámetro                 | Descripción                                                  | Valor por defecto |
|--------------------------|--------------------------------------------------------------|-------------------|
| `TradeTF`                | Marco temporal para detectar el patrón                       | H1                |
| `TrendTF`                | TF para calcular la SMA de tendencia                         | H3                |
| `TrendMAPeriod`          | Periodo de la SMA                                            | 12                |
| `Body2MinPoints`         | Tamaño mínimo del cuerpo de la vela 2 (puntos)               | 315               |
| `LotSize`                | Tamaño inicial del lote                                      | 5.0               |
| `MaxContractSize`        | Lote máximo permitido                                        | 5.0               |
| `StopLossPoints`         | Stop Loss en puntos                                          | 2800              |
| `TakeProfitPoints`       | Take Profit en puntos                                        | 2500              |
| `UseTrailingStop`        | Activar trailing stop                                        | false             |
| `TrailingStopActivation` | Activación del trailing (puntos)                             | 150               |
| `TrailingStopStep`       | Paso del trailing (puntos)                                   | 10                |
| `MaxSimultaneousOrders`  | Máximo de órdenes abiertas/pendientes por símbolo            | 1                 |
| `MaxPendingBars`         | Máx. velas sin ejecutar antes de cancelar la orden           | 3                 |
| `UseComboMultiplier`     | Activar multiplicador de lote tras ganadora                  | false             |
| `ComboMultiplier`        | Multiplicador aplicado tras ganancia                         | 1.6               |
| `ComboMaxSteps`          | Número máximo de pasos del combo                             | 2                 |
| `PersistComboState`      | Guardar estado del combo entre sesiones                      | true              |
| `MaxDailyLossFTMO`       | Pérdida diaria máxima en USD                                 | 500.0             |
| `SafetyBeltFactor`       | Factor de seguridad sobre pérdida diaria (0.0 a 1.0)         | 0.9               |
| `MinOperatingBalance`    | Balance mínimo para permitir operaciones                     | 9050.0            |
| `UseBalanceTarget`       | Activar objetivo de balance para detener el EA               | false             |
| `BalanceTarget`          | Valor objetivo de balance para detener el EA                 | 11000.0           |
| `DebugLogs`              | Activar logs de diagnóstico                                  | true              |
| `DebugMaxLogsPerBar`     | Número máximo de mensajes de log por vela                    | 2                 |

---

## 📝 Notas de Uso

- Se recomienda **probar siempre en demo** antes de usar en cuenta real.
- Asegúrate de que los **niveles de SL/TP** cumplen con el `stops_level` y `freeze_level` de tu broker.
- Utiliza `MaxSimultaneousOrders` para evitar sobreexposición en mercados volátiles.
- El horario de reseteo de riesgo está adaptado al horario de **España (UTC+1/UTC+2)**.
- Este EA no dibuja indicadores visuales, pero puedes añadir la SMA MTF manualmente en el gráfico si deseas ver la tendencia.

---

## 🪪 Licencia

© Jose Antonio Montero. Distribuido bajo la [MIT License](LICENSE.md). Uso libre con atribución.
