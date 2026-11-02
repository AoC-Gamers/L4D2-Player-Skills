# Skills smoke standalone — instalación y captura

Paquete de diagnóstico listo para copiar manualmente. Observador **@OBSERVER_VERSION@**
y probe API **1.0.1-smoke**, compilados por separado del producto. Este paquete
no instala ni reemplaza el core `l4d2_player_skills.smx` y no incluye proveedores.
La aceptación real de SRCDS y del issue Boomer sigue **pendiente**.

## Contenido y requisitos

- `plugins/l4d2_skills_game_event_observer.smx`: tres trazas (engine, SDKHooks,
  Left4DHooks), inicialmente sin captura a archivo.
- `plugins/l4d2_player_skills_api_smoke.smx`: consumidor del include público;
  exporta KeyValues mientras esté cargado. Nombre, cvar y directorio propios.
- `tools/validate_smoke_trace.py`: validación estructural de los tres JSONL.
- `tools/verify_standalone.py`, `SHA256SUMS`, `manifest.json`: inventario, versiones,
  procedencia y hashes. SHA256SUMS también cubre manifest; no se auto-hashea.
- `catalog/`: los 301 eventos originales y el manifest normalizado con 302
  nombres (añade player_spawn), cobertura de fuentes usadas por Skills.
- `source/`: fuentes compiladas de ambos plugins y el include público de Skills.
- `validation/`: logs de compilación y pruebas locales; `runtime_srcds=pending`.
- `docs/`: matriz, API e informes de la investigación. Algunas referencias de
  esos documentos son del checkout original; esta guía contiene el procedimiento
  operativo independiente del repositorio.

El destino debe ser **Left 4 Dead 2** con SourceMod, SDKTools, DHooks y Actions. Se usó el toolchain
SourceMod 1.12 indicado en manifest. Para probar las tres fuentes hacen falta
SDKHooks y Left4DHooks con versiones/gamedata compatibles con ese gameserver;
el observador puede cargar sin esos proveedores y registra cobertura ausente.
El probe API necesita un core Skills compatible para obtener payloads. Player-Stats
y TankControl son opcionales: registrar si están disponibles y sus versiones.
Python 3.10+ (biblioteca estándar) permite verificar archivos/trazas fuera del
servidor; no requiere instalar Python dentro del gameserver.

Las fuentes incluidas permiten revisión. Recompilarlas requiere los includes
externos de SourceMod, Left4DHooks, l4d2util, Player-Stats y TankControl: esos
proveedores se mantienen externos. El binario original de referencia del core
solo se identifica por hash en manifest; no se entrega ni sustituye.

## 1. Verificar el paquete en la estación de trabajo

Conservar ZIP y su archivo hermano `.zip.sha256`. Desde su carpeta:

```sh
sha256sum -c NOMBRE_DEL_ZIP.zip.sha256
```

Extraerlo en una carpeta vacía. Desde la raíz extraída:

```sh
sha256sum -c SHA256SUMS
python3 -I tools/verify_standalone.py
```

El verificador debe devolver `valid: true` y exactamente los dos SMX de smoke.
Guardar el resultado fuera de la carpeta extraída; archivos añadidos dentro de
ella hacen fallar la comprobación de inventario. Un hash solo verifica integridad
frente a la copia de referencia conservada.

## 2. Coordinar el servidor y preservar su estado

**competitive_dev permanece reservado.** Elegir con el usuario otro gameserver
o una ventana autorizada antes de instalar, cambiar modo, plugins o cvars.
Preparar el caso, duración y criterio de cierre con el operador.

Antes de cambios temporales, guardar en una carpeta de evidencia separada:

1. Mapa, modo/variante, etapa de readyup/live, versiones de SRCDS/SourceMod,
   SDKHooks, Left4DHooks/gamedata y listado de plugins (`sm plugins list`,
   `sm exts list`, `sm version`).
2. SHA-256 del core realmente elegido (baseline o refactor), de los dos SMX del
   paquete y del catálogo; el hash de referencia del manifest no acredita qué
   core está instalado. Registrar presencia de Player-Stats y TankControl.
3. Cvars relevantes a Skills y al caso (incluido debug), pausas/readyup y cualquier
   ajuste temporal previsto, junto con su valor previo. No cambiar cvars compartidas
   sin coordinarlo. La captura no configura el modo ni habilita debug del core.
4. Respaldo de cada archivo que se vaya a reemplazar y una lista exacta de cambios
   propios. Si existen versiones del observador/probe, conservar bytes y hashes.
   No eliminar ni desactivar plugins o cambios explícitos del usuario.

## 3. Copiar y cargar explícitamente los dos plugins

Los archivos del ZIP están bajo `plugins/`; no es un overlay de addons ni un
instalador. Copiar los dos SMX a la ruta que cargue el modo autorizado y
`gamedata/l4d2_skills_smoke_witch.txt` a `addons/sourcemod/gamedata/`.
Para dejarlos fuera del autoload normal puede usarse:

```text
addons/sourcemod/plugins/disabled/l4d2_skills_game_event_observer.smx
addons/sourcemod/plugins/disabled/l4d2_player_skills_api_smoke.smx
```

Verificar sus hashes tras la copia contra SHA256SUMS. En **ZoneMod**, aplicar los
SMX descargando y volviendo a cargar el modo mediante su procedimiento habitual,
con selección temporal de estos dos plugins; registrar orden y comandos reales.
No se especifica un nombre de modo ni se cambia su configuración automáticamente.

En una instalación SourceMod con carga manual ya autorizada, las rutas anteriores
pueden cargarse desde la consola del servidor:

```text
sm plugins load disabled/l4d2_skills_game_event_observer.smx
sm plugins load disabled/l4d2_player_skills_api_smoke.smx
sm plugins list
```

Comprobar que ambos aparecen en ejecución y que no hay errores de natives/includes,
SDKHooks o detours. El probe tiene nombre distinto del acompañante API original,
usa `sm_skills_smoke_api_debug` y escribe en `logs/l4d2_skills_smoke/api/`; no pisa
sus archivos ni su cvar. Si el acompañante original ya estaba activo, registrar
su presencia y preservar la decisión del usuario sobre su carga.

## 4. Ejecutar una captura corta y reproducible

El observador escribe al activar captura. El probe API escribe mientras está
cargado, incluso fuera de la ventana del observador: recoger sus payloads de la
ventana registrada, conservando el resto como evidencia sin contarlos dos veces.
No hace falta habilitar su cvar debug para exportar KeyValues.

Desde consola del servidor o como admin ROOT:

```text
sm_start
sm_skills_smoke_events_status
sm_mark "B1 INICIO: matare al Boomer con escopeta"
sm_skills_smoke_sources_sample
```

Registrar el stem/run_id que devuelve start, el tick de inicio y las acciones
reproducidas. Las muestras manuales requieren configs terminadas y registran
resultado u omisión; son lecturas en ese momento, no memoria histórica del core.
Identificar cada variante con marcadores de inicio y fin; se pueden ejecutar varias
pruebas dentro de la misma captura corta. Registrar actores, acciones y resultado.
Tomar otra muestra antes del cierre:

```text
sm_mark "B1 FIN: observe Pop y un anuncio"
sm_skills_smoke_sources_sample
sm_stop
sm_skills_smoke_events_status
```

Conservar ambas salidas de status y el status posterior al stop. Capturar todo
produce CPU/E/S y puede perturbar el timing: usar ventanas cortas y describir esa
condición. Los callbacks no cambian byrefs/vectores ni retornan Handled; las
acciones registradas son las del observador, no el agregado de otros plugins.

## 5. Recoger la evidencia completa

Bajo `addons/sourcemod/logs/l4d2_skills_smoke/`:

```text
run-<id>.engine.jsonl
run-<id>.sdkhooks.jsonl
run-<id>.left4dhooks.jsonl
api/<familia>/<subfamilia>/<unix>_<tick>_<serial>.cfg
```

Guardar juntos los tres archivos de un mismo run_id, los KeyValues API pertinentes,
logs debug/errores SourceMod y chat/anuncios o demo. El probe utiliza serial y
comprobación de existencia para conservar varios payloads del mismo tipo/tick,
incluso tras una recarga; no utiliza el tipo/mapa como clave de archivo. Los
KeyValues mantienen familia, tick, mapa e IDs de la API original.

Guardar el conjunto en una carpeta distinta del paquete, por ejemplo:

```text
evidencia/<servidor>/<baseline-o-refactor>/<caso>/<run_id>/
```

Añadir notas de acciones, valores previos/posteriores, versiones, hashes y cambios
propios. Correlacionar por run_id, seq, tick, mapa/epoch y userid/serial; nunca por
slot o ID aislados. Una recarga del core puede reiniciar IDs: usar los markers de
biblioteca/cambio de instancia y los hashes de cada pasada.

## 6. Validar fuera del gameserver

Usar los tres archivos exactos, sin mezclar servidores o sesiones:

```sh
python3 -I tools/validate_smoke_trace.py \
  /ruta/evidencia/run-ID.engine.jsonl \
  /ruta/evidencia/run-ID.sdkhooks.jsonl \
  /ruta/evidencia/run-ID.left4dhooks.jsonl \
  > /ruta/evidencia/validacion.json
```

Código 0 y `valid: true` acreditan integridad estructural: cabeceras/hash/sesión,
seq global contigua, ticks/epochs, ownership, eventos completos, chunks y health.
Código 1 exige revisar el informe y conservar los archivos originales. Un fallo
no se soluciona borrando líneas o mezclando capturas.

Revisar además cobertura efectiva (HookEventEx/SDKHookEx, presencia de bibliotecas,
callbacks realmente observados), status final y errores del servidor. Health
cubre hasta el flush de payload; el flush del propio health puede fallar después.
`valid=true` no prueba detours activos, memoria/gamedata correcta, causalidad ni
comportamiento equivalente. PRE y POST son observaciones distintas. Los floats
conservan bits; los chunks string escapan bytes y pueden señalar posible truncación.

Los tests locales del paquete no prueban SRCDS. Marcar cada caso no ejecutado
como **Pendiente**, con la razón concreta.

## 7. Comparar baseline y refactor

Usar los mismos dos SMX de smoke y catálogo, mismo escenario y configuración
acordada. Cambiar solo el core elegido mediante el procedimiento del modo y
registrar sus hashes; no reutilizar datos de una instancia como si fuera otra.
Conservar ambos juegos de logs y registrar diferencias de orden, demora,
argumentos, forwards, KeyValues y anuncios sin presuponer que una fuente sea
verdad absoluta. Distinguir dato recibido, lectura de contexto y decisión de Skills.

| Casos mínimos | Evidencia esperada | Estado inicial |
|---|---|---|
| Hunter, Smoker, Boomer, Charger, Jockey | Eventos engine, daño SDK PRE/POST, callbacks LH pertinentes, consultas, forwards/KV/anuncios | Pendiente |
| Witch y Tank/rock | Spawn/harasser/muerte, daño/TraceAttack donde corresponde, sesiones/control y cierres | Pendiente |
| Boomer sin spawn observado | Stream completo con death/explosion, demoras, identidad y carga tardía; no aplicar la cota experimental | Pendiente |
| Asistencias, kills absorbidas y Handled | Scopes LifeKill/SkillWindow, actor_damage/chip_damage, contribuyentes y supresión sin duplicación | Pendiente |
| Autos | Spawn/Touch/daño y triggered_car_alarm | Pendiente |
| Round/mitad/match/map end | Orden, payloads y cierres, sin callbacks filtrados de otra vida | Pendiente |
| Ausencia/recarga de SDKHooks y bibliotecas opcionales | Inventario nuevo, flags, frames viejos descartados y falta de cobertura explícita | Pendiente |
| Desconexión/slot, referencias expiradas y no-edict | Raw/ref/serial/generación y ausencia de reasociación falsa | Pendiente |

El observador cubre 302 nombres, cinco tipos SDKHook más dos forwards globales,
26 forwards LH y 18 consultas inventariadas; eso no representa todos los eventos
posibles ni cada lectura interna de Skills. El JSON original omite player_spawn:
se añade su userid como suplemento, sin inventar el resto de su schema.

## 8. Cerrar y restaurar únicamente los cambios propios

Detener captura y recoger todo antes de descargar herramientas. En ZoneMod,
descargar el modo, retirar la selección temporal del smoke/restaurar sus archivos
y volver a cargarlo según lo acordado. En carga manual autorizada, descargar
únicamente los dos plugins del paquete por su ruta/identificador registrado.

Restaurar solo archivos/cvars modificados por esta prueba con sus respaldos y
valores previos; conservar cambios explícitos del usuario. No borrar logs de
investigación ni restaurar un directorio completo que incluya trabajo ajeno.
Verificar hashes, plugins, modo y valores finales y anexar el cierre a la evidencia.
No se publica ni se despliega nada al ejecutar los validadores locales.

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
