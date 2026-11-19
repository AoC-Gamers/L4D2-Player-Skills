# Validación de detección y ciclo de vida

Se verificaron compilación, empaquetado y compatibilidad de la superficie
pública. Las pruebas de comportamiento documentadas se ejecutaron con
SourcePawn 1.12 y dependencias simuladas.

| Área | Resultado local |
|---|---|
| Boomer | Pasaron 7 casos de reentrada, supresión y orden Pop/Death. Pruebas posteriores cubrieron Pop después de 100 ms y resolución dentro de la ventana de 3 s para spawn conocido. La muerte con spawn desconocido y sin señal resolutiva sigue bajo diagnóstico. |
| Cierre, bosses y resúmenes | Pasaron las pruebas de reapertura, cierre doble o reentrante, reemplazo de sesión y publicación Skills → Kills desde el buffer congelado. Los builders de KeyValues se simularon. |
| MapEnd y Player-Stats | Pasaron 18 escenarios de cierre, entre ellos ambos órdenes de callbacks, el cierre repetido, los IDs antiguos y la reentrada. Una prueba adicional verificó retirada y recarga del proveedor. |
| Observador de eventos | Pasaron 31 pruebas Python, incluidas pruebas con compilación y VM, para pasividad, firmas, recarga, serialización, referencias y cierre. |

## Pendiente en SRCDS

- Validar que los eventos del motor y los hooks efectivos producen los
  anuncios, forwards, cantidades y KeyValues esperados para las [familias de skills](scenarios.md).
- Confirmar el orden real de Pop/Death, efectos de la planificación de
  timers, impactos, desconexión, slot reutilizado y el Boomer cuyo spawn
  no se observó.
- Repetir cierres por modo, readyup, halftime, restart, MapEnd, carga y
  retirada de Player-Stats y recarga del plugin.
- Comparar captura del motor, SDKHooks y Left4DHooks, incluidos cambios
  de mapa, referencias sin edict y callbacks diferidos del observador.

Usa la [guía del observador](../../tools/smoke/README.md) para verificar
la integridad de la captura y correlacionar los tres streams por sesión,
tick y fase. Estas pruebas de VM usan entradas controladas. La aceptación
de gameplay requiere evidencia de SRCDS.
