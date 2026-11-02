# Arquitectura actual de L4D2 Player-Skills

Este documento describe la composición interna integrada, los propietarios de
escritura y los contratos que el refactor debe conservar. La ubicación de una
declaración global o de una función de reset no basta para atribuir propiedad:
el propietario indicado aquí es quien decide y escribe el dato de dominio.

## Límites de producto y compatibilidad

- `l4d2_player_skills.sp` sigue siendo el único plugin raíz y produce un solo
  `l4d2_player_skills.smx`.
- `l4d2_player_skills_api.sp` y `l4d2_player_skills_series.sp` son consumers
  opcionales; no son requisitos del core ni se empaquetan como plugins raíz.
- Se conservan el include público, enums, firmas y orden de forwards, natives,
  comandos, ConVars, traducciones, familias API y claves KeyValues existentes.
- La API de eventos clasifica en `skills`, `kills` y `bosses`. Los consumers
  reciben forwards por familia y pueden consultar/serializar eventos mediante
  natives que llenan `KeyValues`.
- Compilar o comparar cuerpos trasladados valida composición estática, no
  comportamiento de SRCDS. No se afirma que el runtime o la matriz de gameplay
  hayan sido probados.

## Composición

El main conserva la entrada del plugin, registro y delegación de callbacks. Los
includes privados están bajo `addons/sourcemod/scripting/l4d2_player_skills/`.

| Área | Módulos | Responsabilidad principal |
|---|---|---|
| Tipos y almacenamiento | `types.sp`, `state.sp`, `detect/state.sp`, `boss_session.sp` | Definir registros y reservar almacenamiento. Las declaraciones no asignan por sí solas ownership de escritura. |
| Modo y ciclo de vida | `mode_context.sp`, `lifecycle.sp` | Resolver el contexto/política de modo; coordinar transiciones, cierres, resets y hooks. |
| Identidad y eventos | `identity.sp`, `event_store.sp` | Cache de referencias persistentes de jugadores; allocation, reset y lookup del buffer de eventos. |
| Detección | `detect/{deferred,observations,life_kill,pin_assists,skeet_quality,damage,bunnyhop,hunter,boomer,jockey,charger,smoker,caralarm,rocks,si_death,shared,inputs,movement_dispatch}.sp` | Guards de timers, snapshots tipados de entradas, tracking común, reglas por familia y adaptación de callbacks/eventos del juego. |
| Bosses | `boss.sp`, `boss_session.sp`, `boss/{tank,witch,queries}.sp` | Coordinación y cierre común; reglas de Tank y Witch; lecturas/lookup de sesiones. |
| Consultas y presentación | `queries.sp`, `announce.sp` | Consultas/ranking separados del formato, routing y rendering de chat/console/tablas. |
| API | `api.sp`, `api_natives.sp`, `publication.sp`, `summaries.sp` | Mapping/serialización, recepción de natives, dispatch inmediato de forwards y construcción/finalización de snapshots. |

## Propiedad de escritura

La siguiente tabla identifica quién decide el valor y lo muta. Los coordinadores
de ciclo de vida pueden pedir resets; eso no los convierte en escritores de la
contabilidad de dominio.

| Datos | Propietario de escritura | Coordinación/lectura |
|---|---|---|
| Contexto de modo: modo base, política de ronda, límites y máscara de SI habilitados | `mode_context.sp` | `lifecycle.sp` llama a la reconciliación; summaries serializan una instantánea. Player-Stats aporta el contexto cuando está disponible y sigue siendo la autoridad del lifecycle externo. |
| Flags de disponibilidad de Player-Stats, Left4DHooks y Tank Control; selección lifecycle externo/standalone; señal `roundLive` | `lifecycle.sp` y estado cacheado en `types.sp` | `OnLibraryAdded/Removed` solo actualizan disponibilidad/dirty flags; `OnConfigsExecuted` y `OnGameFrame` reconcilian cuando libraries/config están listos. Forwards directos de Player-Stats son autoritativos para lifecycle externo. |
| Identidad persistente/cache: account/user ID, nombre, equipo/clase y vínculo con el cliente | `identity.sp` | Callbacks de conexión/desconexión capturan o separan referencias; `lifecycle.sp` coordina reset de mapa. |
| Buffer circular, serial de evento, slot, flag interno `pendingPublication` y validación/lookup | `event_store.sp` | Lo consumen detectores, bosses, API, consultas, announces y summaries. `API_GetEventIndexOrFail` y el filtro común de visibilidad excluyen eventos provisionales. El buffer no decide el significado de campos semánticos. |
| Contenido de evento de cada familia SI | Módulo de la familia en `detect/` | `detect/inputs.sp` y `movement_dispatch.sp` enrutan entradas; `shared.sp` mantiene helpers comunes. Los módulos de dominio escriben tipo, actor/víctima, daño, propiedades y asistencia al construir el evento. |
| Contribución de vida completa y kills genéricas SI (`LifeKill`) | `detect/life_kill.sp` | Los detectores específicos pueden leerla al construir un evento. `si_death.sp` participa en fallback y ruta de muerte. |
| Captura de ventana técnica, calidad de skeet y mediciones temporales que alimentan skills | `detect/skeet_quality.sp` más el módulo de familia que clasifica el resultado | `pin_assists.sp` atribuye assists válidos a la ventana de pin/skill. `observations.sp` captura valores de los eventos de juego; `inputs.sp` los entrega a handlers. Estos datos no reemplazan `LifeKill`. |
| Tank: continuidad/control, métricas y eventos de sesión | `boss/tank.sp` y mutadores de `boss_session.sp` | `boss.sp` coordina lifecycle/cierre; `boss/queries.sp` lee/agrega. La mutación de sesión común se hace mediante los métodos de `boss_session.sp`. |
| Witch: sesión, crown, daño/cierre y eventos de dominio | `boss/witch.sp` y mutadores de `boss_session.sp` | `boss.sp` coordina cierre común; `boss/queries.sp` lee/agrega. Witch conserva su propio ciclo de entidad/sesión. |
| Daño compartido de boss y cierre/finalización de sesiones | Métodos comunes de `boss_session.sp` y coordinación de `boss.sp` | Tank/Witch deciden cuándo registrar su semántica específica; `boss.sp` consolida y cierra una sola sesión. |
| Snapshot de resumen de skills/kills | `summaries.sp` | `lifecycle.sp` fija el punto de cierre; `api.sp` serializa KeyValues de summaries; forwards de cierre se disparan después de construir cada snapshot. |
| Mapping de tipos/familias y serialización de evento/sesión a KeyValues | `api.sp` | `api_natives.sp` recibe natives y delega validación/llenado. No decide clasificación ni presenta texto. |
| Dispatch de forwards inmediatos | `publication.sp` | Cada clasificador lo invoca con un evento ya construido; el resultado puede gobernar el announce builtin. |
| Consultas, conteos, filtros y ordenación para ranking/tablas | `queries.sp` | `announce.sp` consume los resultados y posee el formato/routing/rendering. |
| Texto, colores, destinos y tablas de announce | `announce.sp` | No es propietario de clasificación, de contabilidad de vida ni de payload API. |

### Propiedad por familia de detección

- `detect/hunter.sp`: skeet, melee skeet, deadstop, high pounce y estado
  específico de Hunter.
- `detect/boomer.sp`: pop, vomit landed y estado de Boomer.
- `detect/jockey.sp`: leap, skeet, jump stop, ledge hang y estado de Jockey.
- `detect/charger.sp`: bowl, level, instakill, death setup, ledge hang y claw
  summary.
- `detect/smoker.sp`: tongue cut, self-clear y estado/clears asociados al pin.
- `detect/bunnyhop.sp` y `detect/caralarm.sp`: streak de salto y tracking de
  alarma de vehículo, respectivamente.
- `detect/rocks.sp`: observación de roca y eventos TankRockSkeet/TankRockHit;
  los acumulados de sesión Tank pertenecen al dominio Tank.
- `detect/shared.sp`, `pin_assists.sp` y `skeet_quality.sp` son recursos
  compartidos acotados; no son una contabilidad paralela de vida.

## Resets coordinados y escritores numéricos

Los resets son límites coordinados, no productores de una segunda fuente de
verdad:

- `Lifecycle_OnMapStart/End` coordina limpieza de identidad, resumen, eventos,
  bosses y tracking de detección según el ciclo correspondiente.
- inicio/cierre de ronda coordinado en `lifecycle.sp` fija el orden de cierre.
  Al terminar, `Lifecycle_CloseRound()` marca primero `roundClosed = true` y
  `roundLive = false`, bloqueando escrituras ordinarias y cierres reentrantes.
  Luego `Boss_OnRoundEnd()` cierra/consolida sesiones; se construyen ambos
  summaries antes del primer forward y se notifican Skills → Kills; finalmente
  `Detect_OnRoundEnd()` invalida tracking. El epoch se comprueba entre etapas
  para no continuar sobre una ronda nueva iniciada desde un callback.
- `Detect_ResetAll`, `Detect_OnRoundStart/End` y `Detect_Shutdown` resetean
  estructuras/hooks de detectores. El escritor de `LifeKill`, ventana técnica
  o familia sigue siendo su módulo de dominio.
- `Boss_ResetAll`, `Boss_OnRoundStart/End` y `Boss_Shutdown` coordinan el estado
  común y hooks de sesión; Tank/Witch siguen escribiendo sus valores específicos.
- `API_ResetRoundSummaryState` resetea la marca de snapshot y llama al reset del
  buffer de eventos. `summaries.sp` es dueño de los snapshots que se construyen;
  `event_store.sp` es dueño de la asignación/limpieza del buffer.
- Las observaciones `SkillsDamageObservation` y `SkillsDeathObservation` son
  snapshots de entrada: `inputs.sp` los captura desde `player_hurt` y
  `player_death`, y handlers tipados en `damage.sp`/familias los consumen. El
  snapshot no se convierte en otra fuente de tracking persistente.

Así se diferencia el escritor numérico (por ejemplo, quien suma daño/disparos o
asistencias) del componente que pide limpiar ese almacenamiento al cambiar de
ronda/mapa.

## `LifeKill` y `SkillWindow`

Son lecturas semánticas separadas y usan trackers de asistencia diferentes:

- `LifeKill` cubre la vida completa del SI: contribución/daño y disparos
  registrados durante esa vida; sus kills genéricas (`SmokerKill`,
  `BoomerKill`, `HunterKill`, `SpitterKill`, `JockeyKill`, `ChargerKill`) usan
  `damage_scope = LifeKill` y, cuando existen, `assist_scope = LifeKill`.
- `SkillWindow` cubre solo el tramo técnico que define una jugada rica. Skills
  como `HunterSkeet`, `BoomerPop`, `SmokerSelfClear` y `ChargerLevel` clasifican
  con `damage_scope = SkillWindow`; sus assists son contextuales a esa ventana.
- La ventana técnica decide si la skill califica, sus propiedades y assists.
  Ciertos announces pueden mostrar una contribución visible más amplia del
  actor, sin cambiar `damage_scope`, `chip_damage`, `perfect` o la semántica de
  assists del payload.
- No se copian assists de `LifeKill` a una skill, ni se recorta una kill genérica
  a la ventana técnica. `actor_damage` sigue el scope declarado; `chip_damage`
  conserva su significado contextual.

La tabla exhaustiva por escenario sigue en
[`l4d2-skills-validation-matrix.md`](l4d2-skills-validation-matrix.md) y la
interpretación está en [`l4d2-skills-interpretation.md`](l4d2-skills-interpretation.md).

## Prioridad de clasificación, forwards y anuncios

La prioridad de dominio descarta o absorbe un fallback genérico para que esa
kill no termine como un segundo evento. El punto exacto donde se registra la
supresión varía por flujo y, en varios emisores, es después del forward y del
intento de announce. Casos documentados:

| Candidato de mayor prioridad | Fallback absorbido |
|---|---|
| `HunterSkeet` / `HunterSkeetMelee` | `HunterKill` |
| `BoomerPop` | `BoomerKill` provisional, mientras Pop aún pueda calificar |
| `ChargerLevel` | `ChargerKill` |
| `JockeySkeet` / `JockeySkeetMelee` | `JockeyKill` |
| `SmokerSelfClear` resuelto por muerte | `SmokerKill` |
| `SpecialPinClear` por muerte del pinner | kill default correspondiente |
| `WitchCrown` | `WitchDead` summary de la misma resolución |

Un `SelfClear-Shove` seguido por una muerte posterior del Smoker, o el
`ChargerClawSummary` post-mortem, describe momentos distintos y puede coexistir.
La jerarquía completa por caso está en
[`l4d2-skills-print-hierarchy.md`](l4d2-skills-print-hierarchy.md).

Para un evento inmediato, el orden visible contractual es:

1. El detector/boss clasifica y construye el evento.
2. `publication.sp` mapea el tipo interno a una familia pública y ejecuta el
   forward correspondiente: `PlayerSkills_OnSkillDetected`,
   `PlayerSkills_OnKillDetected` o `PlayerSkills_OnBossEventDetected`.
3. Si el resultado es menor que `Plugin_Handled`, el announce builtin formatea
   y enruta la presentación; si es `Plugin_Handled` o mayor, el announce se
   omite. Ningún resultado revierte la clasificación.
4. En los flujos que absorben kill, el detector registra la supresión después
   del forward y del intento condicional de announce. El caller evita entonces
   el fallback, o cancela el evento provisional que ya lo representaba.

Por tanto `Plugin_Handled` controla la presentación, no si se conserva la
clasificación ni si se aplica la supresión de dominio. En particular, los
emisores de `HunterSkeet*`, `BoomerPop`, `ChargerLevel`, `JockeySkeet*`,
`SmokerSelfClear` y `SpecialPinClear` por kill llaman al forward antes de
`Detect_MarkSiLifeKillSuppressed`; para `SpecialPinClear` el caller marca tras
retornar de `Detect_EmitSpecialClear`.

El serializador API solo adjunta `implies_si_death`,
`suppressed_kill_type_id` y `suppressed_kill_type` para los mappings explícitos de
`HunterSkeet`/`HunterSkeetMelee`, `BoomerPop`, `ChargerLevel`,
`JockeySkeet`/`JockeySkeetMelee` y `SmokerSelfClear` sin shove. `SpecialPinClear`
por kill sí suprime el fallback en el flujo de dominio, pero no está incluido
en ese mapping y su evento no recibe esos metadatos. No generalizar las claves a
cualquier evento que haya absorbido una kill.

### Excepción Boomer autorizada: publicación diferida de `BoomerKill`

La recepción de `player_death` construye el candidato con payload `LifeKill` y
`pendingPublication`; el detector Boomer es dueño de su resolución. Los 100 ms
son una espera mínima. El timer no publica mientras Pop aún sea admisible según
el límite ya existente de 3 s desde spawn. Se reprograma y comprueba `>` estricto;
una explosión noPop permite terminar la espera. Un spawn desconocido espera señal
o invalidación de contexto. No se cambia el criterio de aceptación de Pop.

`DetectBoomerState` posee `explosionResolved`, `deathCommitted` y
`killDelayElapsed`. Su reset ocurre en nueva conexión, desconexión, spawn y reset
de ronda/mapa. Resolver noPop limpia las observaciones conservando la decisión y
la espera vencida. La publicación y la supresión de Pop se reservan **antes** de
invocar consumers, evitando reentradas y duplicados. `Plugin_Handled` solo
suprime el announce builtin; no evita absorber el kill.

El provisional sigue oculto a API, consultas y summaries; su cancelación descarta
el registro. Userid, vida, ronda e ID exacto vinculan cada timer. El publisher
valida también el epoch de lifecycle tras el forward. El payload no se reconstruye
con slots de asistentes reciclados ni se mezclan los ámbitos `LifeKill` y
`SkillWindow`. La [evidencia local](l4d2-skills-boomer-late.md) cubre la antigua
coexistencia cuando Pop llegaba después de 100 ms. La entrega real de eventos
sigue pendiente de SRCDS.

El forward de finalización de sesión boss es otro punto que puede preceder y
suprimir un announce de sesión. `PlayerSkills_OnTankSessionClosed` es `void` y
solo comunica la razón de cierre; no devuelve `Plugin_Handled`. Los forwards de
summary también son `void`: se construye el snapshot y luego se llama primero
`PlayerSkills_OnSkillSummaryFinalized` y después
`PlayerSkills_OnKillSummaryFinalized`; no controlan announces inmediatos.

## Contrato KeyValues

Las raíces públicas de evento continúan siendo `skill_event`, `kill_event` y
`boss_event`. Se mantienen IDs/tipo/modo, refs de actor y, cuando aplican,
víctima/pin victim, assists y properties. Cada player ref conserva los campos
documentados (`userid`, `accountid`, `name`, `bot`, `team`, `character` y
`zombie_class`); cada assist conserva además `damage`, `shots` y `weaponid`.
`boss_event` puede incluir `boss_session` cuando referencia una sesión válida.

El ownership interno no cambia estas claves. El contrato completo de campos,
familias, natives y forwards está en
[`l4d2-skills-api.md`](l4d2-skills-api.md).

## Fase 4: integrada y revisada estáticamente

Las protecciones de integridad están integradas y revisadas estáticamente;
la validación de comportamiento en servidor permanece pendiente:

- `detect/deferred.sp` captura round generation, userid y client-life generation
  para timers de cliente; descarta trabajo si cambió la ronda, la conexión o la
  vida. `Detect_ResetAll`/`Detect_OnRoundEnd` avanzan la generación de ronda;
  put-in-server, disconnect y spawn avanzan la generación de vida.
- Los timers Boomer añaden el event ID esperado al pack, comparan contra el
  pending actual y evitan que una cola vieja consuma otra. Al volver del forward
  validan el epoch de ronda, userid y vida; no limpian tracking si un callback
  reentrante creó otro pending. Los resets/cierres cancelan el evento provisional
  con una razón y borran el ID pendiente.
- Timers de entidad capturan round generation y entity reference. El timer de
  Witch ya envía el session ID y lo vuelve a buscar por ID antes de evaluar el
  cierre, en vez de confiar en un slot de sesión reutilizable.
- Los dos timers de transición/control Tank llevan índices e IDs de sesión y
  ahora usan DataPack con `TIMER_DATA_HNDL_CLOSE`; el callback valida estado,
  tipo, userid/control pendiente o el pending de transición antes de mutar.
- Callbacks de add/remove libraries solo cachean disponibilidad y marcan
  reconciliación pendiente. `OnGameFrame` aplica el sync tras estar listas las
  libraries y configs; `OnConfigsExecuted` también sincroniza. Player-Stats
  continúa siendo autoridad del lifecycle cuando se recibe su callback y está
  disponible; se conserva el fallback standalone.
- `mode_context.sp` compone y aplica el snapshot/política de modo (modo base,
  contexto Versus, límites, pool SI y señales de ronda). Usa propiedades de
  Player-Stats para el lifecycle externo y datos locales como fallback, sin
  escribir score ni clasificar skills.
- `observations.sp` contiene snapshots tipados de daño y muerte; `inputs.sp`
  captura los campos del evento antes de pasarlos a handlers. Esto formaliza la
  frontera de entrada, sin cambiar ownership de los contadores de dominio.
- La excepción Boomer de publicación diferida descrita arriba está integrada;
  es un cambio explícitamente autorizado para arbitrar Pop vs kill.

Pendiente en SRCDS: observar rutas de descarte/reentrada, cada timer frente
a reset/slot reuse/vida nueva, guards y hooks, y los órdenes
Boomer dentro y fuera del retardo. No se ha ejecutado el smoke de SRCDS/gameplay
ni se afirma comportamiento probado. No reconstruir historial al cargar Stats.

## Auditoría final: vallas de cierre y reentrada

`roundClosed` impide que una reconciliación de Player-Stats o el fallback de
SafeArea reabran una ronda cuyo cierre ya fue recibido. Solo un inicio de ronda
aceptado o `PlayerStats_OnRoundLive` explícito levantan esa valla. `lifecycleEpoch`
avanza al cambiar mapa o aceptar una nueva frontera de ronda; no es un nuevo ID
público ni redefine mitad/match. Los timers de detección también rechazan trabajo
mientras la ronda está cerrada.

Los finalizadores de boss fijan `finalized` antes de invocar consumidores y
revalidan ID de sesión/epoch después de cada forward. El loop de cierre deja de
procesar sesiones cuando cambia el epoch. El finalizador de summaries congela
ambas familias antes del primer forward, conservando Skills → Kills. El Pop
revalida userid, vida, ronda y epoch antes de anunciar o marcar supresión después
de su forward. Esto protege una vida nueva en el mismo slot.

Estos defectos de control de flujo se reprodujeron y se corrigieron con funciones
reales extraídas en una VM SourcePawn aislada y dependencias simuladas. No es
validación del scheduler del juego ni de payloads/anuncios reales. Véase la
[auditoría final](l4d2-skills-final-audit.md) para evidencia y pendientes. El
[cierre de MapEnd](l4d2-skills-mapend-close.md) ahora finaliza antes de limpiar,
independientemente del orden con Stats; su aceptación SRCDS sigue pendiente.

Un inicio o live reentrante recibido durante `closeInProgress` se conserva como
límite pendiente y se aplica al terminar ambos resúmenes y la invalidación de
detección. Así no se pierde el snapshot viejo al proteger la ronda nueva. El
orden se conserva: live seguido de start descarta ese live anterior y queda
pre-live; start seguido de live abre el nuevo estado live. No se usa un timer ni
se conserva el handle Event para aplicar esos límites.

## Cierre terminal de mapa

`mapEnding` impide perder el cierre cuando MapEnd precede al forward de Stats:
se solicita el cierre común antes de destruir el buffer, y el cleanup se aplica
al terminar. Si el cierre ya está en curso, se aplaza únicamente la limpieza.
`mapEnded` bloquea señales tardías hasta MapStart; los IDs de ronda conocidos
rechazan cierres viejos sin cerrar una ronda nueva. Los IDs de una instancia
retirada se invalidan al retirar su biblioteca. El orden público y la retención
normal de summaries no cambian. Las pruebas locales de ambos órdenes y sus
límites se documentan en [MapEnd / Stats](l4d2-skills-mapend-close.md).
