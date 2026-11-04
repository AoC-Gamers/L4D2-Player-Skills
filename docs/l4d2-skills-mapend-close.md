# Cierre de MapEnd y Player-Stats

Fecha: 2026-10-24. Pendiente de orden de callbacks resuelto en Skills, con tres
subagentes GPT-6 Luna en razonamiento alto y revisión/integración del agente
principal. Player-Stats se inspeccionó solo como proveedor; no se modificó.
No se consultó ni operó `competitive_dev`, ni hubo publicación, commit o push.

## Problema reproducido

Antes del cambio, `Lifecycle_OnMapEnd` borraba eventos y sesiones sin solicitar
el cierre común. Si corría antes de `PlayerStats_OnRoundEnded`, este último
recibía `roundClosed=true` y el buffer vacío. Con el orden contrario, sí se
publicaban los resúmenes. La fixture anterior reproduce ambos resultados: con
cuatro entradas y dos eventos de boss simulados, el orden MapEnd→StatsEnded
perdía ambos payloads; StatsEnded→MapEnd conservaba el valor agregado 6.

Snapshot recuperable: `.build/refactor/mapend-close/before/`, con fuentes,
documentos, estado Git y SMX previo. Se conserva también el baseline original.

## Cambio integrado

Solo cambiaron dos archivos de producto en esta fase: `lifecycle.sp` y
`types.sp`, dentro de `addons/sourcemod/scripting/l4d2_player_skills/`.

1. `OnMapEnd` fija `mapEnding` y desactiva reconciliación de configs. Conserva
   epoch, eventos e identidades hasta publicar el cierre.
2. Solicita `Lifecycle_CloseRound`: cierra el gate, finaliza bosses, congela ambos
   summaries, notifica Skills→Kills e invalida los detectores. Es el mismo cierre
   existente; no hay un resumen agregado de mapa ni un nuevo forward.
3. `Lifecycle_FinishMapEnd` limpia identidad/eventos/sesiones/tracking y avanza
   el epoch únicamente después. Los snapshots de summaries ya construidos
   permanecen disponibles por las natives existentes hasta su reemplazo normal.
4. Si MapEnd llega dentro de un forward de cierre, solo marca teardown; el stack
   externo termina el cierre y después limpia. No se truncan el summary de kills
   ni el descarte de Boomer provisional. Inicios/live durante teardown se descartan.
5. Stats primero: su cierre es el único y MapEnd solo limpia. Skills primero:
   MapEnd hace el fallback y el cierre posterior de Stats no duplica salidas.
   El fallback no exige que Stats exista, esté habilitado o haya emitido live.
6. Si un MapStart reentrante cambia el epoch, el stack del mapa anterior deja de
   continuar y no ejecuta su cleanup sobre el estado nuevo.

## Identidad de ronda del proveedor

Se conserva el ID live conocido y un límite de IDs cerrados por instancia de
Player-Stats. El proveedor actual asigna `++g_iRoundSerial` y no reinicia ese
contador al cambiar de mapa. Los IDs menores o iguales al último cerrado y los
cierres que no coinciden con un ID activo conocido se descartan. MapEnd incluye
el live pendiente al fijar ese límite; los Ended tardíos en teardown lo avanzan.

MapStart reinicia la asociación activa, pero conserva el límite. Retirar la
biblioteca limpia ambos IDs y el live pendiente, permitiendo que una instancia
recargada empiece de nuevo por ID 1. Cuando el ID activo es desconocido —por
carga tardía, por ejemplo— se conserva el camino compatible de cierre; no se
adivina un ID ni se añade una consulta native obligatoria al proveedor.

## Contrato conservado

- Un `l4d2_player_skills.smx`; API/Series siguen siendo acompañantes opcionales.
- Include público, enums, firmas, registros, comandos, ConVars y traducciones
  permanecen iguales. Tampoco cambian las raíces ni claves KeyValues.
- Orden normal: cierre de bosses antes de snapshots; ambos snapshots antes de
  forwards; notificación Skills→Kills. `Plugin_Handled` conserva su efecto sobre
  anuncios. `LifeKill`, `SkillWindow` y cantidades no se modifican.
- El cambio funcional es conservar y publicar el cierre que antes se perdía si
  Skills recibía MapEnd primero; no se vuelve a publicar una ronda ya cerrada.

## Pruebas locales ejecutadas

La suite extrae funciones reales actuales y previas de `lifecycle.sp` y
`summaries.sp`, las compila y ejecuta en SourcePawn 1.12/spshell. Los clientes,
subsistemas Boss/Detect, builders de summary y efectos del motor son stubs.
Los valores de payload son agregados sintéticos para comprobar retención y
orden; no son dumps KeyValues ni anuncios capturados en L4D2.

- R1 reproduce la pérdida anterior y R2 verifica el orden de control.
- G1–G18 pasan: ambos órdenes, duplicados, Stats ausente, mapa vacío pre-live,
  ID activo conocido o desconocido, señales antiguas, MapEnd dentro de Boss o
  SkillSummary, orden de familias, Boomer pendiente, start/live rechazados en
  teardown, MapStart reentrante, limpieza única y límites monotónicos de IDs.
- Fixture adicional extrae el método real `SetLibraryAvailability` y el handler
  de live: retirar el proveedor borra IDs/pending y recargar acepta ID 1.
- Las cuatro suites previas de Boomer, cierres, summaries y bosses se copiaron a
  un laboratorio nuevo y pasan sus casos anteriores. Estas suites no ejercitan
  MapEnd; el camino MapEnd real extraído se verifica en G1–G18.

Repetición desde la raíz, conservando `.build/`:

```sh
bash .build/refactor/mapend-close/harness/run.sh
bash .build/refactor/mapend-close/provider-reset/run.sh
bash .build/refactor/mapend-close/regressions/harness-rounds/run.sh
bash .build/refactor/mapend-close/regressions/harness-summary/run.sh
bash .build/refactor/mapend-close/regressions/harness-boss/run.sh
python3 .build/refactor/mapend-close/regressions/harness-boomer/run.py --expect fixed
```

Evidencia bajo `.build/refactor/mapend-close/`: `summary-tests.md`, `logs/`,
`provider-reset/`, `regressions/RESULTS.md`, fuentes generadas y binarios de
fixture. Las pruebas quedan fuera del artefacto de producto.

## Límites de la evidencia

El orden de destrucción del motor no fue ejecutado en SRCDS. Se inspeccionó la
fuente local de SourceMod: `OnMapEnd` se emite en `LevelShutdown` antes de quitar
los timers de mapa y antes de marcarlo no iniciado; PlayerManager puede haber
desconectado clientes previamente. El cierre existente valida clientes y entrefs
antes de leer salud/propiedades, conserva snapshots disponibles y utiliza las
mismas fuentes que el cierre normal. `GetGameTime`/`GetCurrentMap` leen los globals
del mapa en ese punto. No se añade un modo teardown con payloads distintos.

También se verificó que Player-Stats finaliza sincrónicamente desde su
`Bootstrap_OnMapEnd` antes de resetear el snapshot. Esa inspección explica el
contrato, pero no demuestra el comportamiento de una instalación concreta.

El pendiente lógico de pérdida de summary por orden MapEnd/Stats queda resuelto
con evidencia local. La aceptación de gameplay, timing del motor, salud/razones
de cierre de bosses y payloads/anuncios reales sigue en el smoke SRCDS. La
ventana de Pop de 100 ms tampoco se cambió en esta tarea.

## Construcción y evidencia vigente

- `make deps-smx`, `make build-smx` y `git diff --check`: correctos.
- Core, API y Series compilados con SourcePawn `1.12.0.7255`, cero warnings.
- Registros externos comparados idénticos; include público, traducciones,
  manifiesto y fuentes API/Series permanecen iguales byte a byte al baseline.
- Comparación original: 615 funciones top-level, 547 cuerpos conservados, 68 adaptados, ninguno perdido.
- SMX actual SHA256: `c11edc8f2b2f2d6b9da1fb42499019e19298d73015b9ee44a9658d99cbc7baa2`.
- Logs y comparación: `.build/refactor/mapend-close/compile.log`,
  `consumers/`, `comparison.json`. Hashes de fuentes y fixtures en
  `provenance.json`; resultado de paquete/ZIP en `artifact_validation.json`.
- ZIP local: `dist/release/l4d2-skills-local.zip`; se exige un solo SMX y
  comparación recursiva de fuentes/documentos/binario frente a dist y ZIP.
