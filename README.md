# Trading_Bots 🤖

Bots de trading automatizados en MQL5 para MetaTrader 5 (MT5). Contiene expertos asesores (EAs) y herramientas enfocadas en estrategias de trading algorítmico para mercados financieros.

---

## Bots Disponibles

<table style="table-layout:fixed; width:100%;">
  <tr>
    <td colspan="2" style="text-align:center; background-color:#f0f0f0; padding:10px; font-weight:bold;">
      Bandas de Bollinger
    </td>
  </tr>
  <tr>
    <td style="text-align:left; width:220px; min-width:220px; max-width:220px;">
      <a href="Tokyo_Breakers/README.md"><b>Tokyo_Breakers</b></a>
    </td>
    <td style="text-align:left;">
      EA para USDJPY en H1 que combina rupturas de Bandas de Bollinger con un filtro de Momentum para capturar la alta volatilidad de la sesión asiática. Incluye gestión de riesgo avanzada —Stop Loss, Take Profit, Trailing Stop dinámico, límite de pérdida diaria— y un multiplicador de contratos opcional, todo optimizado para cumplir con los requisitos de fondeo FTMO.
    </td>
  </tr>
  <tr>
    <td style="text-align:left;">
      <a href="John_Wick_H4/README.md"><b>John_Wick_H4</b></a>
    </td>
    <td style="text-align:left;">
      EA para AUDCAD en H4 que ejecuta rupturas de Bandas de Bollinger con salidas en la banda media, e integra gestión de riesgo avanzada —Stop Loss, Trailing Stop dinámico, multiplicador de lotes y límites de pérdida diaria— optimizada para cumplir con los requisitos de fondeo FTMO.
    </td>
  </tr>

  <tr>
    <td colspan="2" style="text-align:center; background-color:#f0f0f0; padding:10px; font-weight:bold;">
      Estrategias de Rango
    </td>
  </tr>
  <tr>
    <td style="text-align:left;">
      <a href="FusRoDah!/README.md"><b>FusRoDah!</b></a>
    </td>
    <td style="text-align:left;">
      EA para índices americanos (US100, US500, US30, etc.) en H1 que coloca órdenes BuyStop y SellStop en los máximos y mínimos de rangos horarios definidos, con gestión de riesgo avanzada —Stop Loss, Take Profit, Trailing Stop dinámico, multiplicador de lotes y límites de pérdida diaria— optimizada para cumplir los requisitos de fondeo FTMO.
    </td>
  </tr>
  <tr>
    <td style="text-align:left;">
      <a href="Back_to_the_Range/README.md"><b>Back to the Range</b></a>
    </td>
    <td style="text-align:left;">
      EA para índices americanos (US500, US100, US30, etc.) en marco temporal configurable que detecta niveles de liquidez, opera cruces de estos rangos para capturar reversiones al rango y ofrece gestión de riesgo avanzada —Stop Loss, Take Profit, Trailing Stop, Break Even, multiplicador de lotes y límites de pérdida diaria— optimizada para cumplir los requisitos de fondeo FTMO.
    </td>
  </tr>

  <tr>
    <td colspan="2" style="text-align:center; background-color:#f0f0f0; padding:10px; font-weight:bold;">
      Reversión
    </td>
  </tr>
  <tr>
    <td style="text-align:left;">
      <a href="Pirañas/README.md"><b>Pirañas</b></a>
    </td>
    <td style="text-align:left;">
      EA para EUR/USD en H1 que aplica una estrategia de reversión al rango con RSI, EMA y ADX, incluye una martingala conservadora para recuperar pérdidas y gestión de riesgo FTMO (Stop Loss, Take Profit, límites diarios).
    </td>
  </tr>

  <tr>
    <td colspan="2" style="text-align:center; background-color:#f0f0f0; padding:10px; font-weight:bold;">
      Grid Trading
    </td>
  </tr>
  <tr>
    <td style="text-align:left;">
      <a href="Mecha_Godzilla/README.md"><b>Mecha-Godzilla</b></a>
    </td>
    <td style="text-align:left;">
      EA para cualquier activo en MT5 que implementa una estrategia de grid trading con niveles de precio configurables, filtro ATR y coberturas opcionales; incluye gestión de riesgo avanzada —Stop Loss, Take Profit, Trailing Stop, hedging y límites de pérdida diaria— optimizada para desafíos de fondeo FTMO. ADVERTENCIA: FTMO no suele aprobar bots de grid trading, por lo que se requiere supervisión continua y ajustes cuidadosos.
    </td>
  </tr>
</table>

---

## Cómo Usar Este Repositorio

1. Cada bot está en su propio subdirectorio con un `README.md` detallado.  
2. Haz clic en el nombre del bot para ver su documentación completa y configuraciones.  
3. Asegúrate de tener MetaTrader 5 y el MetaEditor para compilar los archivos `.mq5`.  

## Notas

- Este es un repositorio privado para desarrollo interno.  
- Cada bot incluye su propia licencia en su subdirectorio.  
