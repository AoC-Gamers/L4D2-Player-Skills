# Issue: Boomer con spawn desconocido y sin explosión observada

## Estado y decisión de esta iteración

**Abierto para diagnóstico en gameserver.** El usuario pidió documentar el issue
y que el smoke registre todos los eventos del catálogo, incluido `player_death`,
para investigar la entrega irregular de señales del motor. Se preparó un
observador standalone; no se aplicó una nueva política de clasificación ni se
instaló nada. competitive_dev sigue reservado; no hubo publicación.

## Reproducción comprobada localmente

Tras late-load o si no se observó spawn, `DetectBoomerState.spawnTime` vale 0.
`player_death` puede crear un `BoomerKill` provisional. Su timer de 100 ms marca
`killDelayElapsed`, pero si no hubo impacto/explosión y spawn sigue desconocido,
retorna sin publicar ni programar otro timer. El candidato queda oculto a API,
consultas y summaries hasta una señal resolutiva o invalidación del contexto.

El harness extrae productor y timer reales del snapshot de esta iteración. Su
log rojo confirma `queue_calls=1`, candidato retenido, cero forwards de Kill y
`pending_publication=true`; falla la condición deseada de requeue/resolución.
Evidencia: `.build/refactor/boomer-unknown/harness/generated/before/`.
Snapshot: `.build/refactor/boomer-unknown/before/`. Se preservó el refactor previo.

Este resultado demuestra un camino del código bajo entradas simuladas; **no
prueba un fallo del motor**. No se observó en un servidor ni se midió la demora
real de `boomer_exploded`. Ausencia de explosión en una captura finita tampoco
prueba que el motor jamás la haya emitido.

## Contrato y límites de la información disponible

La clasificación vigente trata spawn desconocido como `timeAlive=0`; un Pop
posterior puede ser aceptado y publicar `time_a=0`. La corrección anterior para
Pop posterior a 100 ms conserva esa excepción y no fabrica un spawn histórico.
Kill mantiene `LifeKill`; Pop mantiene `SkillWindow` y su proyección de assists.
No cambian firmas, enums, claves, forwards, reglas de Handled, comandos del core
ni traducciones en esta iteración.

El JSON `docs/l4d2_game_events.json` incluye 301 nombres únicos. `player_death`
es el evento ID 1; `boomer_exploded`, ID 188, solo ofrece userid, attacker y
splashedbile. Su nota indica que ocurre después de death, sin timestamp histórico
ni cota máxima de entrega. `player_spawn` falta en ese catálogo y se añade al
observador explícitamente. El catálogo no acredita una lista exhaustiva de todo
el motor ni qué eventos acepta un servidor concreto.

Las dos auditorías de contrato y fuentes locales no encontraron un getter fiable
para reconstruir la hora real de spawn. `L4D_GetPlayerSpawnTime` mide el tiempo
hasta el próximo spawn como ghost; su implementación usa `m_flBecomeGhostAt`.
`L4D2Direct_GetSpawnTimer` tiene ese mismo propósito. Usarlos como edad de un
Boomer vivo introduciría información falsa.

## Propuesta evaluada, sin integrar

Una hora observada de death puede servir como cota inferior interna: más de 3 s
después de esa observación, la edad real debe superar el límite de Pop. El
prototipo exploratorio conserva `spawnTime`/`time_a` desconocidos y separa el
reloj de decisión mediante bool y timestamp, incluyendo el instante válido 0.
Se guardó solo en `.build/refactor/boomer-unknown/prototype/`; sus ocho casos de
VM son experimentales y no describen el producto instalado ni el actual.

Aplicar esa cota reemplazaría la espera indefinida documentada y rechazaría un
Pop desconocido recibido después del plazo. Se consultó esa decisión y el
usuario dirigió el trabajo a registrar evidencia del motor. La política queda
pendiente de esa investigación; no se incorpora silenciosamente al refactor.

## Observador preparado y evidencia requerida

Fuente de la herramienta: `tools/smoke/README.md`, generador, plantilla y tests en
el mismo directorio. Genera un SMX separado en `.build/smoke/game-events/`; no
forma parte del ZIP de producto. Intenta PRE/POST para los 301 nombres del JSON
más `player_spawn` (302) y registra por nombre el éxito o fallo de HookEventEx.
Incluye todos los 38 nombres actualmente hookeados por Skills.

Registra campos tipados declarados, secuencia por callback, tick, game/engine
time, mapa/epoch y referencias de jugadores con userid/serial. Los entindices
se conservan como datos crudos y no se reinterpretan como userids. El contador
relativo de observación y `spawn_observed` evitan atribuir una fecha de spawn
que no se vio. Los forwards de Skills añaden markers con la misma secuencia y
los IDs que permiten cruzar los KeyValues del acompañante API.

La cobertura es del catálogo y sus campos declarados; no enumera claves extra
que SourceMod no expone. Defaults de getters no prueban presencia del campo.
Los límites de cadenas, escritura, buffering, orden de hooks y coste de E/S se
documentan en la guía; una captura con errores o truncación no es completa.

Para cada baseline/refactor, recoger:

1. Hashes de core, observador y catálogo; mapa/modo, plugins y orden de carga,
   cvars pertinentes y disponibilidad opcional de Player-Stats.
2. Stream completo durante una ventana corta: spawn, daño/disparos, bile/vomit,
   death, explosion, desconexiones y límites de ronda. Conservar PRE y POST y los
   hooks no disponibles, sin convertir “sin registro” en “evento no emitido”.
3. Emparejamiento por userid/serial/mapa y contador de observación; separar vidas
   y slots reutilizados. Medir death→explosion y spawn→death cuando se observó
   spawn; marcar explícitamente los pares incompletos.
4. Forwards con sus IDs, payloads KeyValues, anuncios/chat, logs debug del
   detector y razones de descarte solo cuando se observen directamente.
5. Casos de carga tardía, spawn en tiempo 0, sin spawn visto, explosión tardía,
   ausencia de explosión durante la ventana, Handled, round/map end, recargas y
   desconexión. Toda ejecución SRCDS sigue **Pendiente**.

## Validación de esta iteración

Tres subagentes GPT-6 Luna con razonamiento alto auditaron contrato, fuentes del
motor y pruebas. El agente principal integró el observador y revisó sus resultados.
Las pruebas de generador comprueban schema, metadata, cobertura de nombres,
getters, rechazo de entradas inválidas, clasificación de referencias y compilación.
La revisión detectó y corrigió una heurística que confundía entindex y userid por
una mención incidental en las descripciones del JSON.

Logs de compilación/tests y verificación de que las fuentes y el bytecode del core siguen
iguales al snapshot (el SMX recompilado cambia solo su hora de compilación): `.build/refactor/boomer-unknown/`. Compilación local y
fixtures no constituyen aceptación de comportamiento en SRCDS. No se tocó
Player-Stats, competitive_dev ni configuración compartida.
