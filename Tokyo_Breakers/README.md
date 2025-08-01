# Tokyo Breakers 🤖 v2.02

![Tokyo Breakers Logo](images/Tokyo_Breakers_logo.png)

**Tokyo Breakers** es un **Expert Advisor (EA)** para **MetaTrader 5**, diseñado exclusivamente para operar en el par **USDJPY** en el marco temporal de **1 hora (H1)**. Automatiza operaciones basadas en **rupturas de Bandas de Bollinger** combinadas con un filtro de **Momentum**, optimizado para capturar la alta volatilidad de la sesión asiática y cumplir los requisitos de desafíos de fondeo como **FTMO**.

Al iniciarse, el EA cierra automáticamente cualquier posición preexistente en USDJPY para garantizar un entorno limpio. Su gestión de capital incluye **Stop Loss**, **Take Profit**, **Trailing Stop**, límites de **pérdida diaria**, **multiplicador de contratos** y un nuevo parámetro **MaxComboSteps** para controlar las rachas de ganancias.

---

## 📌 Características Principales

- **Versión**: 2.02  
- **Par exclusivo**: USDJPY (H1)  
- **Cierre inicial de posiciones**: Al iniciar, cierra todas las posiciones abiertas en USDJPY.  
- **Estrategia combinada**: Bandas de Bollinger para rupturas + Momentum como filtro de confirmación.  
- **Gestión de riesgo FTMO**: Límites de pérdida diaria, saldo mínimo y objetivo de balance.  
- **Trailing Stop dinámico**: Ajusta el SL tras “TrailingStopActivation” puntos de ganancia, en pasos de “TrailingStopStep”.  
- **Multiplicador de contratos**: Aumenta lote tras ganancia (hasta `MaxContractSize`), con límite de **MaxComboSteps**.  
- **Espera de cierre dentro de bandas**: No opera hasta que una vela cierre dentro de las Bandas tras una ruptura.  
- **Control de frecuencia**: Mínimo 60 s entre cierres y nueva operación.  
- **Configuración flexible**: Todos los parámetros son ajustables.

---

## 🚀 Estrategia de Trading

Opera en USDJPY H1 con lógica de seguimiento de tendencia:

1. **Condición de Compra**  
   - Vela anterior cierra por encima de la banda superior.  
   - Momentum > `Momentum_Buy_Level`.  
   - Abre compra anticipando continuación alcista.

2. **Condición de Venta**  
   - Vela anterior cierra por debajo de la banda inferior.  
   - Momentum < `Momentum_Sell_Level`.  
   - Abre venta anticipando continuación bajista.

3. **UseBreakoutDistance** (opcional)  
   - Permite abrir en la misma vela si el precio supera Banda ± `BreakoutDistancePoints`.

4. **Filtros y límites**  
   - Máximo `MaxPositions` por dirección.  
   - Espera de cierre dentro de bandas.  
   - Mínimo 60 s desde el último cierre.  

---

## 🔧 Gestión de Operaciones y Riesgo

- **Stop Loss** (`SL_Points`) y **Take Profit** (`TP_Points`) en puntos.  
- **Trailing Stop** opcional (`UseTrailingStop`) con activación y paso configurables.  
- **Multiplicador de Lotes** (`UseComboMultiplier`) tras ganancia, hasta `MaxComboSteps` veces.  
- **Límites de Posiciones**: `MaxPositions` abiertas por dirección.  
- **Gestión de Cuenta**  
  - **Objetivo de Balance**: cierra todo al llegar a `BalanceTarget`.  
  - **Saldo Mínimo**: detiene trading si equity < `MinOperatingBalance`.  
  - **Pérdida Diaria**: tope `MaxDailyLossFTMO`×`SafetyBeltFactor`; desactiva trading al alcanzarlo.  
- **Reseteo Diario**: a las 00:00 España reinicia contadores y reactiva trading.  
- **Validaciones**: sólo ejecuta en USDJPY; parámetros fuera de rango usan valores seguros.

---

## 📊 Resultados de Simulación

Simulado en MetaTrader 5 con datos reales y parámetros optimizados:  
– **[Resultados de Simulación](Simulaciones%20y%20optimizaciones/README.md)**

---

## ⚙ Instalación

1. Copia `TokyoBreakers.mq5` a `<MetaTrader5>\MQL5\Experts`.  
2. Abre MetaEditor y compílalo.  
3. Aplica el EA al gráfico USDJPY en H1.  
4. Ajusta parámetros o usa valores por defecto.  
5. Activa el trading automático.

---

## 🧾 Parámetros Configurables

## 🧾 Parámetros Configurables

| Parámetro                  | Descripción                                                 | Por defecto |
|----------------------------|-------------------------------------------------------------|-------------|
| `BB_Period`                | Periodo de las Bandas de Bollinger                          | 15          |
| `BB_Deviation`             | Desviación estándar para las Bandas de Bollinger            | 1.4         |
| `Momentum_Period`          | Período del indicador Momentum                              | 14          |
| `Momentum_Buy_Level`       | Umbral de Momentum para abrir compras                       | 101.5       |
| `Momentum_Sell_Level`      | Umbral de Momentum para abrir ventas                        | 99.5        |
| `LotSize`                  | Tamaño de lote inicial                                       | 0.3         |
| `SL_Points`                | Stop Loss en puntos                                          | 400         |
| `TP_Points`                | Take Profit en puntos                                        | 300         |
| `UseTrailingStop`          | Activar o desactivar Trailing Stop                           | true        |
| `TrailingStopActivation`   | Puntos de beneficio para activar Trailing Stop               | 200         |
| `TrailingStopStep`         | Paso del Trailing Stop en puntos                             | 200         |
| `MaxPositions`             | Máximo de posiciones abiertas por dirección                  | 2           |
| `UseComboMultiplier`       | Activar o desactivar multiplicador de contratos tras ganancia| true        |
| `ComboMultiplier`          | Factor de aumento de lote tras operación ganadora            | 1.6         |
| `MaxContractSize`          | Tamaño máximo de lote                                        | 1.5         |
| `MaxComboSteps`            | Máximo número de multiplicaciones consecutivas               | 2           |
| `UseBreakoutDistance`      | Activar entrada en la misma vela si hay ruptura              | false       |
| `BreakoutDistancePoints`   | Distancia mínima para confirmar ruptura (puntos)             | 167         |
| `MaxDailyLossFTMO`         | Pérdida diaria máxima permitida (USD)                        | 500.0       |
| `SafetyBeltFactor`         | Factor de seguridad sobre la pérdida diaria (0.0–1.0)        | 0.5         |
| `UseBalanceTarget`         | Activar objetivo de saldo                                    | false       |
| `BalanceTarget`            | Meta de balance para cerrar el EA (USD)                      | 11000.0     |
| `MinOperatingBalance`      | Saldo mínimo operativo (USD)                                 | 9050.0      |

---

## 📝 Notas de Uso

- Prueba en **cuenta demo** antes de real.  
- Parámetros alineados con reglas de fondeo (FTMO).  
- Ajusta con el **Strategy Tester** según tu bróker y condiciones de mercado.  
- El EA detecta cierres manuales y reajusta el multiplicador de lotes.

---

## 🪪 Licencia

© Jose Antonio Montero. Sujeto a los términos de la [MIT License](LICENSE.md).  
