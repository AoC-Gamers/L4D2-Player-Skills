# Observador de fuentes para el smoke de Skills

Herramienta standalone de diagnóstico, excluida del producto y de su ZIP. No se
instala automáticamente. La suite continúa distribuyendo un único SMX de Skills;
este observador y el acompañante API se compilan e instalan aparte para el smoke.

## Preparación local

Desde la raíz del repositorio, con Python 3 y el toolchain local:

```sh
make deps-smx
python3 tools/smoke/generate_game_event_observer.py
python3 -m unittest discover -s tools/smoke -p 'test_*.py' -v
deps/sourcemod-linux/addons/sourcemod/scripting/spcomp \
  .build/smoke/game-events/l4d2_skills_game_event_observer.sp \
  -iaddons/sourcemod/scripting/include \
  -ideps/sourcemod-linux/addons/sourcemod/scripting/include \
  -o.build/smoke/game-events/l4d2_skills_game_event_observer.smx
deps/sourcemod-linux/addons/sourcemod/scripting/spcomp \
  addons/sourcemod/scripting/l4d2_player_skills_api.sp \
  -iaddons/sourcemod/scripting/include \
  -ideps/sourcemod-linux/addons/sourcemod/scripting/include \
  -o.build/smoke/game-events/l4d2_player_skills_api.smx
```

Se generan fuente, SMX y `catalog-manifest.json` en `.build/smoke/game-events/`.
Conservar sus hashes junto con el SHA del core baseline/refactor. El manifest
incluye el SHA-256 del JSON y el schema normalizado. En ese JSON `type` contiene
la clave del campo y `name` contiene su tipo: el generador verifica esa inversión.
`none`, `local` y `reliable` son metadatos, no getters de payload.

## Instalación futura y captura

**Pendiente de servidor autorizado.** competitive_dev sigue reservado. Antes de
instalar cualquier SMX, coordinar el gameserver y sus ventanas con el usuario,
respaldar los archivos reemplazados y registrar modo, plugins, versiones y cvars.
En ZoneMod aplicar los SMX descargando y cargando de nuevo el modo. Restaurar
solo los cambios temporales propios; conservar cambios explícitos del usuario.

Copiar explícitamente el SMX de este observador y, para payloads públicos, el
acompañante API compilado (`l4d2_player_skills_api.smx`). El observador no requiere
Skills para funcionar; sus listeners públicos registran los forwards si Skills
está presente y devuelven siempre `Plugin_Continue`. El acompañante API existente
exporta los KeyValues; correlacionarlos por familia, ID y mapa con los registros
`publication` de la traza. Ninguno prueba el resultado agregado de otros listeners
ni sustituye la captura de anuncios/chat.

El observador arranca sin escribir eventos. Desde consola del servidor o como
admin ROOT, durante una ventana corta y reproducible:

```text
sm_start
sm_skills_smoke_events_status
sm_mark "B1 INICIO: matare al Boomer con escopeta"
# reproducir la accion
sm_mark "B1 FIN: observe Pop y un anuncio"
sm_stop
sm_skills_smoke_events_status
```

Salida: tres archivos `run-<sesión>.engine.jsonl`, `.sdkhooks.jsonl` y
`.left4dhooks.jsonl` bajo `addons/sourcemod/logs/l4d2_skills_smoke/`. Recoger además
los KeyValues del probe API, logs debug de Skills, errores de SourceMod y la
captura de anuncios. Usar exactamente el mismo observador/catálogo en baseline y
refactor. Cada captura reserva tres archivos nuevos con un `run_id` compartido; cada
registro `catalog` identifica la sesión y reinicia la secuencia global. No comparar secuencias entre
sesiones ni entre servidores. El cierre normal incluye `capture_stop` y `health`;
la ausencia de esos registros exige tratar la captura como incompleta.

## Cobertura e interpretación

- Se intentan hooks PRE y POST de los **301 nombres del catálogo**, más
  `player_spawn` como suplemento con `userid`: **302 nombres**. Incluye
  `player_death` y `boomer_exploded`. El suplemento no pretende declarar el schema
  completo de `player_spawn`. Los 38 eventos actualmente usados por Skills quedan
  cubiertos por esos nombres.
- La cabecera registra `coverage` por nombre y éxito PRE/POST de `HookEventEx`.
  Un hook fallido es cobertura ausente, nunca “evento que no ocurrió”. Archivar
  los fallos y comparar luego con los resources de eventos de ese gameserver.
  El catálogo no es inventario exhaustivo demostrado del motor.
- Los callbacks leen datos; PRE siempre devuelve `Plugin_Continue`. No modifican
  eventos, cvars ni estado de gameplay. Un PRE observado sin POST puede deberse a
  otro hook que bloquee o altere el dispatch: la traza por sí sola no identifica
  al responsable. El orden de carga/registro de hooks también forma parte de la
  evidencia.
- Cada callback obtiene `seq`, tick, `game_time`, `engine_time`, mapa/epoch y fase.
  PRE y POST son dos observaciones distintas, no dos eventos del motor. Secuencia
  y reloj describen recepción del callback; no prueban hora original de emisión
  ni causalidad. El `event_end` permite detectar un registro incompleto.
- Los campos tipados declarados se registran por `seq`. SourceMod no enumera
  claves ni distingue ausencia de un campo de su default 0/false/vacío. Se
  conservan crudos `userid`, `entityid`, `attackerentid`, etc.; solo se resuelven
  campos identificados como userids. Nunca interpretar un entindex como userid.
- Las identidades incluyen userid, slot, serial, bot/account y equipo. El
  `observed_generation` es un contador local de conexión/spawn/desconexión desde
  la carga del observador; `spawn_observed=false` advierte que no se vio spawn
  para esa conexión/mapa. Ninguno recupera la fecha histórica del spawn.
- Las cadenas se dividen en chunks de 128 bytes, escapando también bytes no
  ASCII como `\u00XX`. Para reconstruir el UTF-8 original, concatenar chunks por
  offset, convertir cada carácter U+0000..U+00FF a su byte y después decodificar
  UTF-8. No interpretar esos escapes por byte como texto Unicode ya decodificado.
  `possible_truncation=1` señala el límite de lectura de 4095 bytes.
- `status` y `health` informan errores de escritura y líneas posiblemente
  truncadas; los errores también se escriben en el log de SourceMod. No declarar
  completa una captura con esos contadores distintos de cero. Registrar eventos
  de alta frecuencia en PRE+POST implica coste de CPU/E/S y puede perturbar el
  timing observado; no hay throttling ni descarte silencioso deliberado. Realizar
  capturas cortas y conservar esa limitación al analizar demoras del motor.

## Investigación de Boomer con spawn desconocido

Ver el [issue documentado](../../docs/l4d2-skills-boomer-unknown-issue.md). Capturar
el stream completo, no solo la pareja death/explosion: spawn, daño, disparos,
vomit/bile, muerte, explosión, desconexión, cambios de equipo y límites de ronda.
Registrar carga tardía, core SHA, disponibilidad de Player-Stats y si se observó
spawn. Medir death→explosion por userid/serial/mapa y contrastar fases y forwards;
no emparejar solo por slot. Anotar explícitamente ausencia de explosión o de
spawn durante la captura, sin afirmar que el evento nunca existió.

Las pruebas de Python y compilación son locales. Todos los casos de SRCDS y la
cobertura efectiva de hooks permanecen **Pendientes**.

## Captura de las tres fuentes

El observador ahora abre **tres archivos por sesión**, manteniendo el mismo SMX
standalone y los comandos existentes. Los nombres son:

```text
run-<sesión>.engine.jsonl
run-<sesión>.sdkhooks.jsonl
run-<sesión>.left4dhooks.jsonl
```

Cada cabecera contiene `run_id`, nombre de fuente y SHA del catálogo. La secuencia
es **global y compartida** por los tres archivos; los headers de callback/evento
llevan tick, `game_time`, `engine_time` y mapa/epoch. Los valores se vinculan a ese
header por `seq`. Ordenar por sesión y `seq` para reconstruir recepción entre
fuentes; dos callbacks del mismo tick no son necesariamente simultáneos ni
representan la misma fase. Las secuencias reinician al abrir una nueva sesión;
los nombres se reservan sin reutilizar archivos anteriores, incluso tras reload.

| Log | Cobertura preparada | Valores observados |
|---|---|---|
| engine | 301 eventos del JSON + player_spawn; cubre los 38 nombres usados por Skills | PRE/POST y cada argumento tipado del catálogo, flags de broadcast, referencias crudas y resueltas |
| sdkhooks | Los cinco tipos usados por Skills: OnTakeDamage, OnTakeDamagePost, TraceAttack, Touch y Spawn | Argumentos de daño, atacantes/inflictor/weapon, force/position, hitbox/hitgroup/ammotype cuando la firma los ofrece; Action propio en callbacks Action |
| left4dhooks | Los 26 forwards actualmente consumidos por Skills | Todos los argumentos de sus firmas, incluidos vectores y bools; Action propio cuando existe y fases Post/PostHandled conservadas |

Los forwards SDKHooks `OnEntityCreated`/`OnEntityDestroyed` se registran en su
log, conservando el argumento crudo (index o referencia) y su resolución segura.
SDKHooks se aplica a clientes (incluidos Tanks), witches/brides, tank_rock,
prop_car_alarm y prop_car_glass según corresponda. Registra resultado de cada
SDKHookEx, reconstruye entidades existentes y atiende las nuevas. El pase diferido
usa entref y generación de captura: no puede instalar una operación de una
sesión anterior tras Stop/Start. Los hooks del observador se retiran al detener
captura o acabar mapa, sin desmontar hooks del core ni de otros plugins. El
Spawn inicial de una entidad que ya existía al iniciar no puede recuperarse.
`damagecustom` no se captura en esta versión: la firma de ocho argumentos cubre
los datos consumidos por Skills. SourceMod proporciona la capability
`SDKHook_DmgCustomInOTD`, pero este observador no la sondea ni fabrica ese campo.

Left4DHooks es opcional para el observador. Su log distingue presencia de la
biblioteca y listener declarado de detour comprobado: el manifest no demuestra
que cada detour esté activo. Para afirmar cobertura runtime hay que observar
cada callback esperado y conservar errores/gamedata/versiones. SDKHooks ausente
también se registra como falta de cobertura, no como cero eventos.

**Interpretación de retornos:** los Action de este observador devuelven siempre
`Plugin_Continue` y no cambian byrefs ni vectores. `listener_action` es su propio
resultado; no es la decisión agregada de otros listeners ni el retorno original
de la función de motor. Los callbacks `void` no tienen resultado Action. En
particular, daño PRE y POST son dos muestras distintas; el argumento `damage`
de POST no acredita por sí mismo daño neto aplicado ni equivalencia con PRE.

El log engine también admite registros auxiliares con callback explícito:
PlayerStats, TankControl, lifecycle, OnGameFrame y publicaciones de Skills. No
son game events del catálogo. Se mantienen etiquetados para distinguir la
recepción de una señal externa de la notificación producida por Skills.

### Consultas de estado y memoria

Durante captura activa, después de configs, se puede ejecutar:

```text
sm_skills_smoke_sources_sample
```

El log Left4DHooks registra muestras manuales para las **18 funciones L4D*** que
usa Skills, distinguiendo natives del proveedor de stocks del include (muchos
stocks leen sendprops directamente). Las lecturas por cliente recorren todos los
clientes presentes y validan equipo, props y clase cuando hace falta; las lecturas
por offset de queued pummel requieren un Charger y el offset resoluble. Cada
muestra tiene tick/secuencia, argumentos y resultado, o una omisión con razón.
Las tres natives se protegen por biblioteca, disponibilidad y configs; no se
consultan desde callbacks de carga/retirada de bibliotecas.

El mismo comando añade al log engine muestras auxiliares de PlayerStats,
TankControl y estado de clientes (salud, alive, origen, velocidad, ground entity
y personaje cuando existen), con sus propios headers. La disponibilidad opcional
queda registrada. Los flotantes incluyen representación textual y bits crudos;
así no se pierde precisión ni se emite JSON inválido ante un valor no finito.

Estas lecturas se realizan **en el instante del comando**; no interceptan las
consultas internas ejecutadas por Skills ni recuperan memoria histórica. El
manifest generado `skills_sources` inventaría callbacks, SDKHook sites, lecturas
L4D*, entradas auxiliares y propiedades literales del core. Las lecturas por
nombre dinámico, ConVars, tablas de configuración, timers y resultados de
consultas agregadas requieren la evidencia debug/API y el estado guardado del
servidor; no se presentan como cobertura exhaustiva de cada lectura interna.

### Matriz runtime por fuente (todo pendiente)

Repetir cada caso en baseline y refactor con los mismos hashes del observador,
catálogo y dependencias, y guardar los tres logs junto con API/KeyValues y chat.

| Caso | Contraste preparado | Estado |
|---|---|---|
| Hunter | pounce/daño/death en engine; SDK daño PRE/POST; LH PouncedOnSurvivor; muestra de víctima/dominador | Pendiente SRCDS |
| Smoker | choke/drag/tongue y daño; SDK daño; LH GrabWithTongue; lecturas atacante/reached/dominador | Pendiente SRCDS |
| Boomer | spawn/now_it/death/explosion completos; SDK daño; muestras y callbacks de lifecycle; ordenar ticks y comprobar spawn observado | Pendiente SRCDS |
| Charger | charge/carry/pummel/death; SDK daño; LH Carry/Slam/Pummel; muestra queued pummel con Charger presente | Pendiente SRCDS |
| Jockey | ride/end/jump/death; SDK daño; LH JockeyRide; estado de víctima y atacante | Pendiente SRCDS |
| Witch | spawn/harasser LH, witch_killed engine, SDK daño en entidad válida y refs conservadas | Pendiente SRCDS |
| Tank/rock | tank_spawn/death engine, SDK daño y TraceAttack de rock, LH release/bounce/detonate/replace/offer/stasis; TankControl y muestras | Pendiente SRCDS |
| Autos | triggered_car_alarm y contexto engine; SDK Spawn/Touch/daño en ambos props; identidad y entrefs | Pendiente SRCDS |
| Reloads/boundaries | falta/recarga de biblioteca, desconexión/slot, entidad destruida, Stop/Start, round/map/mitad/match | Pendiente SRCDS |

La compilación y VM local validan cobertura declarada, tipos y pasividad; no
sustituyen la matriz. Una discrepancia se analiza por fase, tick, orden de hooks,
byrefs de otros listeners y contexto. Estas APIs comparten el mismo motor; tres
registros distintos no son tres pruebas independientes de su estado.

Las referencias de jugadores añaden `context_sample=1`: equipo, clase, estado
alive y salud cuando la entidad es un cliente válido (según el tipo de registro).
Son lecturas del observador al recibir el callback, separadas de los argumentos
crudos de la señal; un -1 en esos campos indica contexto no muestreado. Ayudan a
interpretar daño PRE/POST y la vida observada, sin atribuir ese estado al instante
original de emisión del motor.

## Auditoría final e integridad de las tres trazas

El observador 1.1.1 reconcilia altas/bajas de `sdkhooks` desde OnGameFrame. Los
callbacks de biblioteca solo anotan disponibilidad/invalidación y su recepción;
la reconstrucción de entidades ocurre después. Una retirada invalida frames y
ledger de la instancia anterior sin llamar SDKUnhook a través del proveedor nuevo.
También se recupera la cobertura si SDKHooks no estaba presente al iniciar.

Al cerrar se vacían primero los datos de las tres fuentes y después se escribe
`health` con `scope=through_payload_flush`. Ese scope incluye los fallos del
vaciado de payload; persistir el propio health aún puede fallar. Recoger siempre
el status posterior y errores de SourceMod. No interpretar health como garantía
de flush posterior ni cobertura efectiva de todos los hooks.

Una captura cerrada puede verificarse localmente con:

```sh
python3 tools/smoke/validate_smoke_trace.py \
  /ruta/run-ID.engine.jsonl \
  /ruta/run-ID.sdkhooks.jsonl \
  /ruta/run-ID.left4dhooks.jsonl
```

El resultado JSON verifica sesión/hash comunes, secuencia global contigua,
propiedad de registros por fuente, ticks/epochs al unir archivos, cierre de
eventos, chunks reversibles, truncación y health. Sale con código 1 ante errores;
conserva los archivos originales para investigar el motivo. Un tick regresivo
es una discrepancia del modelo de reloj/contexto que exige revisión, no prueba
por sí solo un defecto del motor. `valid=true` acredita estructura, no que se
hayan disparado todos los callbacks ni equivalencia causal o de comportamiento.

La suite ahora contrasta las 26 firmas completas con los includes y prueba el
escape real en VM (incluido UTF-8 entre chunks), recargas SDK con stubs y cierre
con fallo de flush. Para esas pruebas VM se utiliza el spshell local de
`../SteamIDTools/deps/sourcepawn/objdir`; si no está disponible, los SKIP no deben
reportarse como casos ejecutados. Ver el [informe de auditoría](../../docs/l4d2-skills-smoke-final-audit.md).

## ZIP standalone para un gameserver

Para generar un paquete de diagnóstico independiente del release de producto:

```sh
python3 tools/smoke/package_standalone.py
```

Produce una carpeta única bajo `.build/smoke/` y un ZIP con hash en `dist/smoke/`.
Incluye el observador 1.1.1, un probe API aislado `l4d2_player_skills_api_smoke`
(log/cvar propios y filenames sin colisiones de mismo tipo/tick), validador,
verificador de inventario, manifest, SHA256SUMS, fuentes, catálogo y guía operativa.
El core y el acompañante API originales no se modifican ni se incluyen como SMX.
El empaquetador compila los dos binarios y ejecuta tests; no instala ni publica.
La guía del paquete proviene de `tools/smoke/standalone-guide.md`.

### Marcadores manuales de prueba

Durante una captura activa, desde consola del servidor/RCON o como admin ROOT:

```text
sm_mark "H1 INICIO: Hunter bot salta; intentare skeet"
sm_mark "H1 FIN: skeet realizado; revisar anuncio"
sm_mark "B1 INICIO: siguiente prueba con Boomer bot"
```

Cada comando añade un callback `manual_marker` a **los tres logs**, con el mismo
`marker_id` dentro del `run_id`, tick, relojes y mapa/epoch. Cada copia conserva
su `seq` global propio; los valores `text`, `issuer_userid` y la referencia del
emisor cuando es un cliente cuelgan de ese `seq`. Consola/RCON usa userid 0.
El texto usa el mismo escape/chunks reversible que los demás strings. Buscar
`manual_marker` y unir sus valores por `seq`; correlacionar las copias por
`run_id` + `marker_id`. No son eventos de las bibliotecas ni evidencia de que
la acción descrita haya ocurrido: son notas del operador.

No inicia captura automáticamente. Rechaza texto vacío o una entrada que llene
el buffer de 1024 bytes (máximo aceptado: 1022 bytes de argumentos, incluidas
comillas exteriores). El límite efectivo de consola/chat puede ser menor.
Hace flush tras cada marcador; comprobar `sm_skills_smoke_events_status` para
detectar fallos de escritura. Usar etiquetas de caso e INICIO/FIN permite varias
pruebas por captura sin mezclar sus observaciones.


### Seguimiento del objetivo efectivo de Witch (observador 1.3.0)

Requiere DHooks y `gamedata/l4d2_skills_smoke_witch.txt`, que se copia a
`addons/sourcemod/gamedata/l4d2_skills_smoke_witch.txt`. El paquete incluye este
archivo; conservar/restaurar respaldos igual que con el SMX. La implementación
actual admite el binario Linux x86 comprobado. Otras plataformas/layouts quedan
sin esta cobertura, con razón explícita; los demás registros siguen disponibles.

Durante captura activa, un detour **POST** de `WitchAttack::GetVictim` observa
únicamente las llamadas que realiza el motor. No invoca el método por su cuenta,
no cambia retornos, parámetros, memoria ni objetivos. Sus registros van al log
**engine** y llevan `method=engine_detour:WitchAttack::GetVictim:post`; no son
forwards Left4DHooks ni game events del catálogo.

Buscar los callbacks:

- `witch_target_tracking_coverage`: método, `detour_enabled`, layout comprobado,
  o `unavailable_reason`. Un detour habilitado no demuestra que haya sido llamado.
- `witch_target_observation`: cambios con tick, relojes, mapa/epoch, Witch/entref,
  dirección de acción, objetivo retornado y userid/serial. `transition` distingue
  `initial_observation`, `target_acquired`, `target_changed`, `target_lost`,
  `target_unresolved` y `action_changed`. Una observación inicial vacía **no** es
  una pérdida. Una pérdida exige objetivo previo válido y retorno vacío posterior.
- `witch_target_owner_unresolved`: llamada observada sin Witch viva asociable;
  no atribuirla a un índice supuesto ni considerarla cobertura completa.
- `witch_target_tracking_end`: retirada por destrucción de la entidad; no se
  convierte artificialmente en pérdida. Stop/map end desactivan el detour y
  eliminan el inventario; un nuevo inicio vuelve a observar desde cero.

Se emite solo la primera observación y los cambios, no una línea por cada consulta
estable. La identidad anterior queda guardada como entref/userid/serial; nunca se
resuelve de nuevo un slot antiguo para atribuirle el jugador actual. La asignación
de `Action::m_actor` se comprueba contra instrucciones del binario antes de leerla;
un fallo deja `actor_layout_guard_failed` y evita activar el detour.

Correlacionar con el harasser y los eventos existentes, sin equiparar harasser
histórico con objetivo efectivo. Si el motor deja de llamar al método o abandona
la acción sin devolver vacío, no puede asegurarse una pérdida ni su instante.
Los cambios transitorios entre llamadas tampoco quedan demostrados. Para probar:
marcar inicio, provocar adquisición, pérdida/cambio/AFK o desconexión, marcar fin,
y detener captura. Repetir con bot/humano y dos objetivos; conservar los tres logs.
La ejecución de este seguimiento en SRCDS permanece pendiente tras reinstalación.

Referencia de contexto de Action/actor: [NextBotBehavior.h de Valve](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/server/NextBot/NextBotBehavior.h).
La verificación concreta usa el binario instalado, no offsets asumidos del header.

### Corrección de activación 1.3.1

En las capturas 1.3.0, `unsupported_binary_or_platform` no significaba que las
firmas faltaran: SourceMod resolvía ambas, pero devolvía **-1** para
`ActorAssignmentInstruction` con la definición de offset en una sola línea.
Se cambió a la forma multilínea; una consulta dentro del mismo SRCDS confirmó
**106** y los bytes **89 5f 1c** (campo actor a **28** bytes). No se relajó el
control del layout ni se sustituyeron firmas por direcciones absolutas.

La cobertura 1.3.1 registra `victim_signature_found`, `actor_signature_found`,
`actor_assignment_instruction` y los tres `actor_layout_byte_*`. Los descartes
separan `missing_victim_signature`, `missing_actor_signature`,
`invalid_actor_assignment_offset` y `actor_layout_guard_failed`.

El validador adicional permite comprobar el ELF real sin ejecutarlo:

```sh
python3 tools/validate_witch_tracking_binary.py /ruta/server_srv.so \
  --gamedata gamedata/l4d2_skills_smoke_witch.txt
```

En el checkout usar `tools/smoke/validate_witch_tracking_binary.py` y la ruta
`tools/smoke/gamedata/l4d2_skills_smoke_witch.txt`. Comprueba arquitectura,
símbolos, entrada de GetVictim y bytes del offset; no sustituye observar
`detour_enabled=1` y callbacks en una captura real.

### Consultas estables y acciones de Witch (1.4.0)

Esta versión requiere también la extensión **Actions**, ya instalada en el servidor
local de prueba. No incluye ni instala el proveedor. El observador usa únicamente
su API de lectura y listeners POST; el subconjunto de ABI consumido está declarado
en la fuente generada, contrastado con los includes instalados. No se necesitan
esos includes para compilar el observador generado. Si el proveedor no está
instalado o su API es incompatible, SourceMod rechaza la carga del observador;
no interpretar esa ausencia como cobertura completa. No se aplican los parches
`witch_prevent_target_loss`, `witch_target_patch` ni cambios de gameplay.

El log **engine** incorpora observaciones auxiliares claramente etiquetadas:

- `witch_target_query_status`: conteos acumulados de GetVictim por Witch y por
  dirección de acción observada, primer/último tick consultado y último objetivo
  con entref/userid/serial. Sale aproximadamente cada segundo de engine time y al
  cerrar captura/mapa o destruir la entidad. Los conteos incluyen consultas cuyo
  resultado no cambió. Un contador inmóvil indica que no hubo nuevas consultas
  observadas, no que se conservara el objetivo. `action_address` es la acción de
  la última consulta; no afirma cuál acción está activa en ese momento.
- `witch_actions_coverage` y `witch_actions_listener_coverage`: proveedor, método,
  registro por acción y resultado de cada listener. Los flags 1/2/4/8/16/32 son
  Start/Update/End/Suspend/Resume/MoveToFailure; `registered=0` significa cobertura
  ausente para ese listener. Se inventarían las acciones de witches existentes al
  iniciar, y las nuevas mediante OnActionCreated. Una creación todavía sin actor
  asignado conserva el índice observado; cada listener valida después su actor.
- `witch_action_start_post`, `witch_action_end_post`,
  `witch_action_suspend_post`, `witch_action_resume_post`: acción, Witch/entref y
  acción anterior, siguiente o interruptora. Cubren también WitchRetreat y otras
  acciones de la familia. Creación/destrucción se registran por separado como
  `witch_action_seen` / `witch_action_destroyed` y no equivalen a activación/final.
- `witch_action_update_result`: resultado no-CONTINUE, acción propuesta y razón.
  Los Update que continúan normalmente no generan una línea por frame.
- `witch_action_move_failure_post`: path como dirección cruda (no se dereferencia),
  motivo numérico crudo, prioridad y resultado con razón cuando está disponible.

Los resultados de handlers van etiquetados
`handler_result_not_committed_transition`: una solicitud de cambio no demuestra
que el manager la haya aplicado. Correlacionar con End/Start y suspensión/reanudación.
No se lee un ActionResult de OnEnd porque es void. Los callbacks con retorno
siempre devuelven Plugin_Continue; no escriben resultados, razones ni memoria.
Stop retira únicamente nuestros callbacks POST, identificados por función; la
notificación de destrucción elimina el ledger sin llamar métodos del destructor.

Para analizar pérdida de objetivo, combinar el último tick de GetVictim, el
resultado de navegación, el fin/suspensión de WitchAttack, el inicio de otra acción
(por ejemplo WitchRetreat) y la destrucción de entidad. No clasificar automáticamente
ninguna salida de WitchAttack como pérdida: puede responder a muerte, incap,
fuego u otra interrupción. Registrar adquisición, objetivo realmente vacío y
abandono de persecución como hechos distintos.

La VM local verifica pasividad y conteos con consultas estables/detenidas; la
compatibilidad de natives se consulta en el servidor sin cambiar modo/cvars.
Los callbacks reales de navegación y las transiciones de esta versión quedan
pendientes de una nueva reproducción, no se deducen de compilación o del probe.

### Cierre por episodio de persecución (1.5.0)

El observador mantiene un ledger propio de **episodios de WitchAttack**, separado
por completo de los eventos públicos y las sesiones de boss de Skills. No cierra
la vida de una Witch porque termine una persecución, ni aplica parches al motor.

- `witch_attack_episode_open` asigna un `episode_id` dentro del run. Un OnStart
  observado abre el episodio; una primera consulta GetVictim permite abrirlo al
  incorporarse tarde, con `start_observed=0`. Si después se recibe OnStart para
  esa misma acción, `witch_attack_episode_start_confirmed` completa la evidencia
  sin crear otro episodio. La duración parte del primer instante observado.
- `witch_attack_episode_closed` se emite **una sola vez**. `end_observed=1`,
  `closed_by=OnEnd` y `context_closed=0` acreditan el final del ataque, aunque su
  causa permanezca desconocida. Se conservan ticks, duración observada, dirección
  y generación de acción, consultas y último objetivo con entref/userid/serial.
- Destrucción de entidad/acción, cambio de mapa y Stop cierran episodios abiertos
  con `end_observed=0` y `context_closed=1`. Son cierres de contexto, no prueba de
  que se haya observado el final de la persecución. La sustitución de una dirección
  por un constructor nuevo usa `action_lifetime_replaced`.
- Un fallo de navegación previo conserva tick, tipo crudo y acción/generación de
  origen con `navigation_context_only=1`. No se convierte en causa demostrada.
  Las razones de handlers se guardan como `observed_handler_reason`; el campo
  `cause=unknown` sigue admitido y esperado. Suspender no finaliza el episodio;
  reanudar tampoco inicia otro. No se usa el silencio de consultas como cierre.

Las referencias de acciones se imprimen **solo con nombres conservados** durante
OnActionCreated o la enumeración válida del proveedor. Se retiran al destruirse
la acción; cada vida recibe una generación. Las referencias relacionadas nunca
se pasan a BehaviorAction.GetName: una desconocida conserva su dirección con
`*_name_known=0`. La cache recoge también nombres de acciones ajenas a la familia
para poder identificar destinos; solo las acciones Witch reciben listeners.

Esto corrige las excepciones de OnEnd/OnResume por la dirección `0xCBE7400` de la
captura 1.4.0. No se intenta rescatar o dereferenciar la acción caducada. La única
consulta GetName restante se realiza dentro del Iterator válido de Actions al
inventariar entidades existentes.

Aceptación práctica: reproducir el caso entre `sm_mark`, detener la captura y
comprobar exactamente un cierre por episodio, `end_observed`, contexto de
navegación y ausencia de excepciones del observador. No exigir una razón del motor
que no fue emitida. Dos persecuciones de la misma Witch deben formar dos episodios
sin finalizar artificialmente su sesión de vida. Los tests VM cubren duplicados,
late attach, suspensión, identidades, múltiples witches y cierres de contexto.
Una prueba sintética dentro de SourceMod comprueba el ledger con ArrayList real
sin generar eventos de gameplay; no sustituye la nueva reproducción real.
