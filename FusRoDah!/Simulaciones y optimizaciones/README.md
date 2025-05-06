## 📊 Simulaciones y Optimizaciones de FusRoDah! (Pruebas con distintas simulaciones):

- **[Simulación optimizada - 01-01-2023 a 30-04-2025 - Balance inicial 10,000 USD - Beneficio neto 8,896.55 USD](README02.md)**
- **[Simulación optimizada - 01-01-2025 a 30-04-2025 - Balance inicial 10,000 USD - Beneficio neto 3,141.88 USD](README01.md)**

## ⚡ Set de configuración agresivo para el challenge FTMO:

- **[Simulación optimizada - 01-01-2025 a 30-04-2025 - Balance inicial 10,000 USD - Beneficio neto 7,718.57 USD](README03.md)**

## 🕒 Simulaciones previas antes del Challenge:

- **[Simulación optimizada - ENERO - 2025 - Balance inicial 10,000 USD - Beneficio neto 3,040.96 USD](README04.md)**
- **[Simulación optimizada - FEBRERO - 2025 - Balance inicial 10,000 USD - Beneficio neto 1,141.16 USD](README05.md)**
- **[Simulación optimizada - MARZO - 2025 - Balance inicial 10,000 USD - Beneficio neto 1,181.99 USD](README06.md)**
- **[Simulación optimizada - ABRIL - 2025 - Balance inicial 10,000 USD - Beneficio neto 2,381.08 USD](README07.md)**

NOTA: Se detecto un error en el bot durante el periodo de Challenge. Al activarse un stop por máxima perdida diaria, las órdenes pendientes no se eliminaban.

Se implementa la solución, ahora el bot incluye una función cerrar_todas_ordenes_pendientes() que se llama en los siguientes casos dentro de OnTimer():

 - Cuando trading_desactivado es true.

 - Cuando se alcanza el OBJETIVO_SALDO.

 - Cuando el saldo/equidad cae por debajo de SALDO_MINIMO_OPERATIVO.

 - Cuando se alcanza el limite_perdida_diaria_efectiva.

Esto asegura que todas las órdenes pendientes se cancelen activamente en estas condiciones, evitando que queden órdenes residuales.

## 🕒 Simulaciones *tras solucionar el problema de órdenes pendientes sin cancelarse* y multiplicador desactivado:


- **[Simulación optimizada - ENERO - 2025 - Balance inicial 10,000 USD - Beneficio neto 1,420.55 USD](README08.md)**
- **[Simulación optimizada - FEBRERO - 2025 - Balance inicial 10,000 USD - Beneficio neto 1,170.89 USD](README09.md)**
- **[Simulación optimizada - MARZO - 2025 - Balance inicial 10,000 USD - Beneficio neto -163.25 USD](README10.md)**
- **[Simulación optimizada - ABRIL - 2025 - Balance inicial 10,000 USD - Beneficio neto 871.23 USD](README11.md)**


## 🚀 Lanzamiento del bot al Challenge:

- **[Inicio 05 de MAYO - 2025 - Balance inicial 10,000 USD - Objetivo 11,000 USD](Datos próximamente)**



