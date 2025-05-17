# Trading_Bots 🤖

Bots de trading automatizados en MQL5 para MetaTrader 5 (MT5). Contiene expertos asesores (EAs) y herramientas enfocadas en estrategias de trading algorítmico para mercados financieros.

---

## Bots Disponibles

<div style="margin-bottom: 20px;">
  <img src="Tokyo_Breakers/images/Tokyo_Breakers_logo.png" style="float: left; width: 200px; margin-right: 20px;" />
  <p>
    El bot <a href="Tokyo_Breakers/README.md"><b>Tokyo_Breakers</b></a> es un Expert Advisor para MetaTrader 5 que opera en <b>USDJPY</b> en temporalidad H1, diseñado para ejecutar operaciones automáticas basadas en <b>rupturas de Bandas de Bollinger</b> a favor de la tendencia.
  </p>
  <div style="clear: both;"></div>
</div>

<div style="margin-bottom: 20px;">
  <img src="FusRoDah!/images/FusRoDah!_logo.png" style="float: left; width: 200px; margin-right: 20px;" />
  <p>
    El bot <a href="FusRoDah!/README.md"><b>FusRoDah!</b></a> es un Expert Advisor para MetaTrader 5 que opera en <b>índices americanos</b>. Implementa una estrategia de <b>ruptura de rangos</b>, colocando órdenes pendientes BuyStop y SellStop en los máximos y mínimos de rangos definidos en dos ventanas horarias diarias.
  </p>
  <div style="clear: both;"></div>
</div>

<div style="margin-bottom: 20px;">
  <img src="John_Wick_H4/images/John_Wick_H4_logo.png" style="float: left; width: 200px; margin-right: 20px;" />
  <p>
    El bot <a href="John_Wick_H4/README.md"><b>John_Wick_H4</b></a> es un Expert Advisor para MetaTrader 5 que opera en <b>AUDCAD</b> en temporalidad H4. Utiliza una estrategia de <b>ruptura de Bandas de Bollinger</b>, entrando al romper las bandas y saliendo al alcanzar la banda central.
  </p>
  <div style="clear: both;"></div>
</div>

<div style="margin-bottom: 20px;">
  <img src="Pirañas/images/Pirañas_logo.png" style="float: left; width: 200px; margin-right: 20px;" />
  <p>
    El bot <a href="Pirañas/README.md"><b>Pirañas</b></a> es un Expert Advisor para MetaTrader 5 que implementa una estrategia de <b>reversión</b> basada en niveles extremos de RSI, tendencia bajista/alcista según EMA, y mercado en rango confirmado por ADX, con gestión de lotes progresiva.
  </p>
  <div style="clear: both;"></div>
</div>

<div style="margin-bottom: 20px;">
  <img src="Mecha_Godzilla/images/MECHA-GODZILLA_logo.png" style="float: left; width: 200px; margin-right: 20px;" />
  <p>
    El bot <a href="Mecha_Godzilla/README.md"><b>Mecha-Godzilla</b></a> es un Expert Advisor para MetaTrader 5 que utiliza una estrategia de <b>grid trading</b> con niveles de precios predefinidos, filtro ATR, y coberturas (hedging) para gestionar el riesgo, ideal para mercados estables o de rango.
  </p>
  <div style="clear: both;"></div>
</div>

<div style="margin-bottom: 20px;">
  <img src="Back_to_the_Range/images/Back_to_the_Range_logo.png" style="float: left; width: 200px; margin-right: 20px;" />
  <p>
    El bot <a href="Back_to_the_Range/README.md"><b>Back to the Range</b></a> es un Expert Advisor para MetaTrader 5 que opera en <b>índices americanos</b> (e.g., US30, US500) en temporalidad H1. Implementa una estrategia de <b>retorno al rango</b>, identificando niveles de liquidez en un horario específico y operando cruces de estos niveles, con gestión de riesgo alineada a FTMO.
  </p>
  <div style="clear: both;"></div>
</div>

---

## Cómo Usar Este Repositorio
1. Cada bot está en su propio subdirectorio con un `README.md` detallado.
2. Haz clic en el nombre del bot en la descripción para ver su documentación completa.
3. Asegúrate de tener MetaTrader 5 y el MetaEditor para compilar los archivos `.mq5`.

## Notas
- Este es un repositorio privado para desarrollo interno.
- Cada bot incluye su propia licencia en su subdirectorio.