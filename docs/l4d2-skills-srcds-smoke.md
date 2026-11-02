# SRCDS Smoke: baseline vs refactor

## Propósito y estado

Procedimiento reproducible para comparar el plugin baseline con el refactor en
SRCDS. No se ha ejecutado gameplay con baseline ni refactor: todos los casos
runtime de ambas variantes comienzan **Pendiente**. Completar evidencia por
build y por escenario; una compilación correcta no cuenta como validación runtime.

El usuario confirmó mantener `competitive_dev` reservado para PlayerStats; no
usar ese servidor para este smoke. No reiniciar servidores compartidos. Para
aplicar un SMX en ZoneMod, descargar y volver a cargar **el modo**; copiar el
archivo o descargar solo el plugin no aplica el cambio al modo cargado.

## Artefactos baseline ya identificados

| Evidencia | Valor |
|---|---|
| Commit baseline | `f117bfca4a1c82978a6546a3343935c9fbd265ef` |
| SHA-256 del SMX baseline | `731d81087eca0b346f4cc9875a9c8725e3c7d37e6e5708d3e3c26f1c5d9a3283` |
| Copia preservada | `.build/refactor/baseline` (fuentes, SMX, logs e inventario) |
| Ejecución baseline de gameplay | **Pendiente; no ejecutada** |

## Preparación y registro

1. Elegir y anotar dos artefactos: baseline identificado por commit/hash y SMX,
   y refactor identificado por commit/hash y SMX. Guardar copias separadas.
2. Usar el mismo mapa, modo base, configuración, roster, cvars, dependencias,
   orden de plugins y secuencia de acciones en ambas ejecuciones. Registrar
   versiones de SourceMod, Left4DHooks, ReadyUp y bibliotecas opcionales.
3. Capturar consola del servidor y cliente, chat/anuncios, estado de plugins,
   errores/warnings y resultado del probe API. El probe debe suscribirse a los
   forwards públicos de `skills`, `kills`, `bosses`, cierres de sesiones y
   summaries, y volcar inmediatamente los KeyValues de cada ID válido.
4. Restablecer mapa/ronda, jugadores y estado entre casos. Usar cuentas/slots
   identificables; anotar userid, slot, equipo, clase y bot/humano. Repetir cada
   caso en el orden baseline y refactor, alternando el orden en una segunda
   pasada si se necesita descartar efectos del orden.
5. Comparar primero la secuencia semántica y los datos; IDs, timestamps y
   valores dependientes del motor pueden variar. Para cada caso guardar una
   tabla con contador anterior/final, delta, tipos emitidos/suprimidos, payload,
   orden de forwards y anuncios, descartes esperados/observados y evidencia.

### Ficha por ejecución

| Campo | Valor |
|---|---|
| Variante / commit / hash SMX | Pendiente |
| Fecha, mapa, modo base y cvars | Pendiente |
| Versiones y plugins dependientes | Pendiente |
| Roster (slot, userid, equipo, bot/humano) | Pendiente |
| Contadores iniciales/finales por familia | Pendiente |
| Logs, captura y dump KeyValues | Pendiente |
| Estado / delta / observaciones | Pendiente |

## Oráculo común de comparación

- **API y orden:** para cada detección inmediata, el forward de su familia
  (`PlayerSkills_OnSkillDetected`, `...OnKillDetected` o
  `...OnBossEventDetected`) ocurre antes del announce builtin. El consumidor
  puede llenar el KeyValues durante ese forward mientras el ID sea válido.
  Comparar familia, tipo, orden relativo y validez; no exigir IDs idénticos.
- **Manejo del announce:** realizar una pasada sin consumidor que maneje el
  evento: debe aparecer el announce builtin una vez cuando corresponda. En una
  segunda pasada, el probe devuelve `Plugin_Handled` para un tipo elegido: debe
  conservarse la detección/payload y suprimirse solo el announce builtin
  asociado. Esto aplica a `PlayerSkills_OnSkillDetected`,
  `PlayerSkills_OnKillDetected`, `PlayerSkills_OnBossEventDetected` y
  `PlayerSkills_OnBossSessionFinalized`, que devuelven `Action`. Los forwards
  `PlayerSkills_OnTankSessionClosed`, `PlayerSkills_OnSkillSummaryFinalized` y
  `PlayerSkills_OnKillSummaryFinalized` devuelven `void`; no pueden suprimir
  anuncios mediante `Plugin_Handled`. Registrar el resultado exacto; suprimir
  una presentación no invalida ni revierte la detección.
- **KeyValues:** verificar root (`skill_event`, `kill_event`, `boss_event`,
  `boss_session`, `skill_summary` o `kill_summary`), `id`, `type_id`,
  `base_mode`, snapshots de actor/victim/pinvictim cuando aplican, `assists`,
  `properties` y bloque `boss_session` cuando corresponde. En cada player ref
  comparar userid, accountid, name, bot, team, character y zombie_class. No
  exigir campos de víctima omitidos por contrato (por ejemplo WitchCrown,
  WitchDead y TankDead).
- **Daño y assists:** `*Kill` usa `LifeKill`; skills técnicas usan
  `SkillWindow`. `actor_damage` sigue el mismo `damage_scope`; `chip_damage`
  mide daño previo frente al baseline. `assists[]` debe usar el scope indicado,
  con identidad, damage, shots y weaponid. `PerfectSkeet` y `PerfectLevel` no
  deben incluir assists. Comparar valores según el escenario, no forzar igualdad
  con daño raw del motor.
- **Supresión de kill:** cuando una skill principal absorbe la muerte default,
  debe salir la skill; en los tipos cubiertos por la metadata API, con `properties.implies_si_death=1`,
  `suppressed_kill_type_id` y `suppressed_kill_type`; no debe duplicarse con el
  kill default. `SpecialPinClear` conserva la excepción de no serializar esa metadata aunque suprima el fallback. Si la condición técnica no se cumple, debe quedar la kill
  genérica apropiada.
- **Razones de descarte:** el probe API actual solo observa y registra eventos
  que llegaron a los forwards públicos; no ve ni puede explicar todos los
  descartes internos del detector. Para callbacks sin evento público, registrar
  la acción reproducida y el resultado observable como “sin forward”; no
  atribuirle una razón concreta. Solo asignar causa (clase/estado no elegible,
  umbral/ventana no cumplido, duplicado, actor/víctima inválido o contexto/
  lifecycle cerrado) cuando haya evidencia directa en logs o instrumentación
  específica ya disponible. Si no la hay, marcar “causa interna no observable”
  y contrastar únicamente el comportamiento público con el flujo documentado.

## Escenarios reproducibles

Las acciones marcadas como “preparar” requieren jugadores de prueba coordinados;
no manipular un servidor compartido. Guardar el estado inicial y final del
contador de cada tipo para ambos artefactos.

| ID / familia | Secuencia y resultado esperado | Contadores, payload y descarte a contrastar | Estado |
|---|---|---|---|
| H1 HunterSkeet | Un survivor A chipea al Hunter antes del pounce; durante la ventana técnica otro survivor B contribuye y un tercero cierra con blast válido. | `HunterSkeet` una vez; `SkillWindow`, `chip_damage` respecto al baseline, assists solo contextuales. Verificar `PerfectSkeet` sin assists cuando aplique. Si además implica muerte, metadata de kill suprimida y sin `HunterKill` duplicado. Descartar/explicar skeet fallido o duplicado. | Pendiente |
| H2 HunterSkeetMelee / Deadstop | Repetir el kill melee durante leap válido; por separado hacer deadstop válido y luego repetir el mismo callback/evento. | Tipo/contador una vez por acción válida, `SkillWindow` para skeet melee; sin assists para la variante que no los admite. Duplicado inmediato no vuelve a emitir. Registrar por qué una melee fuera del estado/ventana se descarta. | Pendiente |
| H3 HunterHighPounce / HunterKill | Hacer pounce que califique; luego matar Hunter con daño repartido sin skill rica. | Pounce: `HunterHighPounce` y daño de pounce. Kill genérico: `HunterKill`, `LifeKill`, daño de vida y assists de vida. Confirmar que la ventana técnica no recorta el kill. | Pendiente |
| S1 SmokerSelfClear | Pin válido; ejecutar primero self-clear por kill y después, en ronda limpia, por shove; incluir contribuyente dentro de la ventana contextual. | `SmokerSelfClear` una vez con `properties.clear_mode=kill`/`shove`; `SkillWindow`; assists solo contextuales. La vida total del Smoker no debe filtrarse en el payload de la skill. Registrar self-clear no válido descartado. | Pendiente |
| S2 SmokerTongueCut / LedgeHang / SpecialPinClear | Cortar lengua con evento válido; en rondas separadas crear ledge hang y clear de pin atribuible. | Conteos/tipos correctos, actores y víctimas según contrato; `SpecialPinClear` no debe duplicar el mismo clear de familia específica. Capturar forward, KV y anuncio; explicar estados incompletos descartados. | Pendiente |
| B1 BoomerPop / `player_death` primero | En una partida de prueba reproducible, matar un Boomer mediante un pop válido y confirmar en la captura el orden `player_death` → `boomer_exploded`. | Refactor: comprobar que el kill sigue provisional al vencer los primeros 100 ms si Pop aún puede calificar, no aparece aún en forwards/API, consultas ni summaries, y que Pop absorbe/cancela el kill pendiente. Debe quedar un solo `BoomerPop` publicado y contabilizado. Baseline: puede publicar y contar `BoomerKill` inmediatamente antes de Pop y luego contar también `BoomerPop`; registrar ese delta como diferencia funcional autorizada, no como fallo de equivalencia. Capturar ambos órdenes de forwards, KeyValues y anuncios. | Pendiente |
| B2 BoomerPop / `boomer_exploded` primero | Repetir un pop válido y documentar el orden `boomer_exploded` → `player_death`. | Refactor: `BoomerPop` debe marcar/suprimir la muerte simple posterior; no publicar ni contar `BoomerKill` provisional. Comparar con baseline sin exigir igualdad absoluta: el baseline puede contar ambas detecciones si publica el kill antes de reconocer Pop. Registrar delta de cada contador y la secuencia observada. | Pendiente |
| B3 `Plugin_Handled` del forward de Pop | Repetir B1 o B2 con el probe devolviendo `Plugin_Handled` solo desde `PlayerSkills_OnSkillDetected` para `BoomerPop`. | La detección/contabilización del Pop y su payload siguen presentes, se suprime únicamente el announce builtin de Pop. En refactor el kill provisional sigue cancelado/no visible. Separar forwards de anuncios en el registro. | Pendiente |
| B4 `Plugin_Handled` del forward de Kill | Matar un Boomer sin Pop clasificable; probe devuelve `Plugin_Handled` solo desde `PlayerSkills_OnKillDetected` para `BoomerKill`. | Refactor: registrar que `BoomerKill` se publica tras la espera mínima de 100 ms y la resolución noPop o el vencimiento estricto de la ventana de Pop, con payload/contador, pero su announce builtin queda suprimido. Baseline puede emitir forward/announce en el camino inmediato; anotar orden y delta sin tratar el tiempo como equivalencia estricta. Este caso no debe mezclarse con B3. | Pendiente |
| B5 Cancelación provisional / cierre de ronda | Crear una muerte Boomer que deje el kill provisional y finalizar la ronda antes de vencer el timer de 100 ms. | Refactor: no debe filtrarse después del cierre un forward, incremento consultable, inclusión en summary ni announce del evento cancelado; registrar log de descarte si está disponible. El baseline puede haberlo publicado ya de forma inmediata. | Pendiente |
| B6 Cancelación provisional / spawn y slot reutilizado | Dejar pendiente el timer y provocar el spawn/reset del Boomer; en una repetición, desconectar al cliente y reutilizar su slot antes del vencimiento. | No debe publicarse un kill atrasado ni heredarlo un cliente nuevo. Comparar userid/accountid además del slot; registrar timer, forward, anuncios, contadores y razón únicamente si es observable. | Pendiente |
| B7 BoomerVomitLanded | Aterrizar vomit válido; en una ronda limpia repetir con target ausente/acción fuera de contexto. | `BoomerVomitLanded` y contador apropiado una vez; comparar actor, `amount`, `perfect`, KeyValues y anuncio. Para descarte sin forward, el probe solo puede registrar el resultado “sin forward”; no atribuir una causa interna salvo log/instrumentación directa. | Pendiente |
| C1 ChargerLevel | Charger con chip previo; ejecutar carga y melee kill que califique como Level; repetir con variante PerfectLevel cuando sea posible. | `ChargerLevel`/variante correcta, `SkillWindow`; daño según health antes del hit, chip respecto a baseline, assists solo de ventana y ninguno para `PerfectLevel`. Si absorbe muerte, metadata y ausencia de `ChargerKill` duplicado. | Pendiente |
| C2 ChargerInstaKill | Preparar secuencia válida de carry/impacto/caída fatal o deadly slam; incluir apoyo SI y, si aplica, survivor que dañó a la víctima al inicio de secuencia. | Un `ChargerInstaKill`; verificar actor, víctima, assists contextuales (`zombie_class` del SI en `assists[]`), y propiedades `incapped`, `ledge_hang`, `fatal_fall`, `deadly_slam`, `height` solo cuando aplican. Confirmar exclusividad práctica fatal_fall/deadly_slam. Registrar secuencia truncada descartada. | Pendiente |
| C3 ChargerBowl / LedgeHang / DeathSetup | En pasadas separadas, bowling con 2/3 targets, ledge hang y setup de muerte válidos. | Conteo y `amount` de Bowl; victim/pinvictim; tipos/props y forward por caso. No contaminar `ChargerKill`. Distinguir eventos fuera de secuencia y candidatos descartados. | Pendiente |
| J1 JockeyHighLeap / JumpStop | Leap alto válido; en una ejecución independiente, jump-stop válido. | Tipo y contador una vez; etiqueta visible HighLeap no cambia el tipo público. Verificar campos de contexto y los descartes por altura/estado/ventana. | Pendiente |
| J2 JockeySkeetMelee / JockeySkeet | Matar por melee mientras leap válido; repetir con skeet válido no melee, incluyendo chip previo y contribución contextual si aplica. | No confundir ni duplicar los dos tipos; scope técnico, chip/assists de SkillWindow donde corresponda. Comparar headshot/perfect y descarte por leap inválido. | Pendiente |
| W1 WitchCrown | Witch en estado crownable; actor ejecuta crown válido y, en otra ronda, crown tras daño previo. | `WitchCrown` una vez; campos de actor/weapon, properties de crown, sin `victim_*`; crown skill distinta de WitchDead; `boss_session` si sesión válida. Descarte/no-crown no produce crown. | Pendiente |
| W2 WitchDead / WitchIncap / sesión | Witch muere sin crown y, separado, incapacita survivor/escapa; repetir cierre por muerte. | `WitchDead` summary usa daño/assists/shots de vida completa; comprobar anuncio suprimible con `Plugin_Handled` desde el boss-event forward cuando aplique, y desde `PlayerSkills_OnBossSessionFinalized` para el announce de sesión. `WitchIncap` y cierre de sesión en orden documentado; verificar harasser/incap victim/crowner cuando existan. Sin `victim_*` en WitchDead. | Pendiente |
| T1 TankDead / rock | Sesión Tank válida; lanzar rock que pega y otro que se skeetea; cerrar por muerte. | `TankRockHit`, `TankRockSkeet`, `TankDead` donde aplique; mismo boss_session ID referencial y payload válido. Verificar forward de cierre con razón TankDead y snapshot de sesión. | Pendiente |
| T2 Tank close por resultado | En sesiones separadas, cerrar por SurvivorsEscaped y SurvivorsWiped; usar takeover humano→bot→mismo humano si fixture lo permite. | `PlayerSkills_OnBossSessionFinalized` con `Action` antes del announce builtin; `Plugin_Handled` lo suprime. `PlayerSkills_OnTankSessionClosed` comunica la razón pero es `void` y no suprime anuncios. Sesión finalizada una vez; control timeline y merge según contrato, sin atribuir continuidad por accountid en fallback heurístico local. | Pendiente |

## Lifecycle y resistencia a cambios de estado

### Contrato temporal de Boomer (diferencia autorizada)

El refactor retiene `BoomerKill` provisional al menos 100 ms y hasta que Pop
resuelva la clasificación o deje de ser admisible por su límite existente de
3 s desde spawn (`>` estricto). Antes de resolverse, el kill no es visible por
forwards, API, consultas ni summaries. Si Pop absorbe la muerte, solo se publica
y cuenta Pop. Si el spawn es desconocido, esperar señal o invalidación, sin
fabricar cutoff. El baseline puede contar ambos; registrar ese delta autorizado.

En el probe separar `player_death`, `boomer_exploded`, forward y announce. Añadir
casos con explosión a 150/500 ms después de death, siempre dentro de la ventana
de vida válida; en el borde exacto de 3 s debe ganar Pop. Después de 3 s Pop se
descarta por la regla previa y se publica únicamente Kill. Probar ambos órdenes
para una explosión noPop, kill sin explosión con spawn conocido y spawn desconocido
sin señal hasta cierre. Capturar scopes/assists completos y repetir con
`Plugin_Handled`, desconexión y reentrada. Todos esos casos de servidor siguen
**Pendientes**: la [VM local](l4d2-skills-boomer-late.md) no prueba el scheduler de SRCDS.
El probe solo observa forwards y resultados públicos: no puede explicar todos
los descartes internos del detector; usar “causa interna no observable” sin
logs directos.

| Caso | Procedimiento | Resultado / evidencia requerida | Estado |
|---|---|---|---|
| Round start/pre-live/live | En Versus con ReadyUp, empezar ronda, producir eventos antes de live y después de liberarlo. | Contexto base correcto; los eventos pre-live se descartan si el flujo lo requiere. Capturar causa observable, contadores y primer evento live. | Pendiente |
| Half-time / cambio de lado | Completar primera mitad y dejar iniciar la segunda con equipos invertidos. | Boundary de mitad no tratado como restart; snapshots/contadores corresponden a su unidad documentada y los actores cambian de equipo correctamente. | Pendiente |
| Match/serie y finalización | Completar cierre de match o mapa según modo disponible. | Summary finalizado una sola vez; `PlayerSkills_OnSkillSummaryFinalized` y `...OnKillSummaryFinalized` después de congelar snapshot. Validar counts por team/accountid y base_mode. | Pendiente |
| Restart/retry | Reiniciar la misma mitad mediante el mecanismo de prueba acordado, sin confundirlo con halftime. | No mezclar contadores/sesiones del intento anterior; anotar qué señal canónica cerró/resetió el contexto. | Pendiente |
| Disconnect | Desconectar actor, víctima o assister entre inicio de secuencia y resolución/callback diferido. | Ningún acceso a cliente inválido; evento puede descartarse o conservar snapshot según flujo, con identidad consistente y causa registrada. | Pendiente |
| Slot reutilizado | Tras desconexión, conectar otra cuenta en el mismo slot antes de resolver una secuencia pendiente. | El nuevo jugador no hereda contribuciones, identidad, timers ni evento del anterior. Comparar slot/userid/accountid y descartes. | Pendiente |
| Reload plugin | En entorno de prueba aislado, descargar y recargar el SMX durante estado controlado; repetir después de limpiar ronda. | Sin callbacks dobles/hooks duplicados ni handles/timers vivos; dependencias opcionales se vuelven a sincronizar; no se hereda estado volátil salvo contrato explícito. El archivo nuevo solo se considera activo tras descarga/recarga. En ZoneMod se descarga y recarga **el modo** para aplicar el SMX; no reiniciar el servidor compartido. | Pendiente |
| Boomer: cierre/spawn/disconnect antes del timer | Ejecutar B5 y B6 con captura que confirme el evento provisional antes del límite de 100 ms. | Contrastar cancelación/no-publicación por cierre de ronda, spawn/reset, desconexión y reutilización de slot; no aparece kill atrasado ni datos del cliente anterior. Cada variante debe quedar como evidencia independiente y **Pendiente** hasta correrla. | Pendiente |
| PlayerStats opcional | Si está instalado en un entorno de prueba coordinado, subscribir consumidor compatible y repetir eventos elegidos. | Comparar contadores/consumo y verificar que la ausencia del plugin opcional no rompe Player-Skills. `competitive_dev` permanece reservado para PlayerStats y no es el entorno de este smoke. | Pendiente |

## Hoja de diferencias por escenario

| ID | Baseline: delta y evidencia | Refactor: delta y evidencia | Diferencia semántica | Descartes / explicación | Estado |
|---|---|---|---|---|---|
| H1–T2 / completar una fila por escenario | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| Lifecycle / completar una fila por caso | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |

## Criterio de cierre

Marcar cada escenario **Aprobado**, **Fallido**, **No reproducible** o
**Bloqueado**, citando artefactos y evidencia. No cerrar como equivalente si
solo compila: deben coincidir los tipos/orden semánticos, deltas de contadores,
contratos KeyValues, scopes de daño/assists, reglas de supresión, anuncios y
lifecycle; toda diferencia debe tener explicación documentada y estar aceptada.
Mantener como desconocidos los casos que no se ejecutaron.

## Casos adicionales de la auditoría final

Las pruebas de VM aislada ya comprobaron estas transiciones con funciones reales
y dependencias simuladas. Cada observación dentro de SRCDS sigue **Pendiente**:

| Caso | Secuencia / expectativa en SRCDS | Estado |
|---|---|---|
| Pop reentrante | Consumer provoca nueva vida, nuevo userid, cierre o nueva frontera de ronda dentro del forward Pop: no debe anunciar ni suprimir una vida posterior. Con Continue normal anuncia y suprime; Handled solo suprime anuncio. | Pendiente |
| Reconciliación tras cierre | Cerrar ronda, retirar Player-Stats y reconciliar con SafeArea todavía true: la ronda queda cerrada; una nueva señal explícita start/live permite abrir la siguiente. | Pendiente |
| Cierre repetido/reentrante | Dos señales de cierre o una señal emitida durante el forward de boss: una sola secuencia de finalización por ronda, sin repetir summaries ni invalidar tracking de una ronda nueva. | Pendiente |
| Boss reemplazado | Reemplazar sesión o iniciar ronda desde TankSessionClosed/BossSessionFinalized: el stack anterior no marca/anuncia el slot nuevo. Sin reentrada se conserva TankClosed → BossFinalized → anuncio; Handled suprime solo anuncio. | Pendiente |
| Resúmenes estables | Un consumer de SkillSummary inicia otra ronda: ambos snapshots pertenecen al buffer anterior y se notifican Skills → Kills; el cierre antiguo no invalida detección de la ronda nueva. | Pendiente |
| MapEnd frente a cierre Stats | Probar ambos órdenes de carga/notificación. El cierre común debe conservar ambas familias antes de limpiar y notificar una sola vez. El defecto de orden se corrigió y pasó G1–G18 en VM local; falta observar payloads/anuncios reales, bosses y timing en SRCDS. | Pendiente SRCDS |

La [resolución de MapEnd / Stats](l4d2-skills-mapend-close.md) incluye ambas
órdenes, cleanup reentrante, IDs caducados, proveedor ausente/recargado y descarte
de Boomer pendiente. Su validación local está ejecutada; estos casos siguen
pendientes de gameplay y no autorizan utilizar competitive_dev.

## Captura completa del catálogo para investigar Boomer

El [issue de spawn desconocido](l4d2-skills-boomer-unknown-issue.md) permanece
abierto: antes de decidir una expiración nueva, recoger el stream del motor.
La herramienta standalone y sus comandos están en `tools/smoke/README.md` del
checkout. Su SMX se genera aparte; no está incluido en el ZIP del core.

El observador intenta PRE y POST para 301 eventos del JSON más `player_spawn`
(302 nombres), incluidos `player_death` y `boomer_exploded`, con payloads tipados,
relojes y referencias. Registra cada fallo de hook y markers de forwards de
Skills. Acompañarlo con el probe API para los KeyValues y con captura de chat.
No afirmar que cubre todo el motor: falta inventariar los resources del servidor,
verificar hooks efectivos y documentar campos fuera del schema del catálogo.

La captura arranca desactivada. Preparar una ventana corta, guardar hashes y
estado del servidor, arrancar con `sm_start`, recoger
`sm_skills_smoke_events_status` antes/después y cerrar con
`sm_stop`. Los logs JSONL van a
`addons/sourcemod/logs/l4d2_skills_smoke/`; verificar coverage, health y cierre.
La ampliación de tres fuentes usa `run-<sesión>.engine.jsonl`,
`.sdkhooks.jsonl` y `.left4dhooks.jsonl` (misma sesión y secuencia global).
PRE/POST representan dos observaciones del mismo dispatch; no contarlos como dos
eventos independientes. Correlacionar por userid/serial/mapa, no solo por slot.
Todas las capturas SRCDS siguen **Pendientes**. competitive_dev no se utiliza.

## Tres fuentes: engine, SDKHooks y Left4DHooks

La [cobertura preparada](l4d2-skills-smoke-sources.md) separa game events del
catálogo, los cinco tipos SDKHook usados y los 26 forwards Left4DHooks. Cada
callback tiene tick/relojes y valores por secuencia compartida entre tres logs.
Los resultados Action registrados son los del observador; no equivalen al
resultado agregado de otros hooks. Daño PRE/POST conserva cada muestra por
separado. Las muestras manuales (`sm_skills_smoke_sources_sample`) explicitan su
momento, consulta y output/omisión; no interceptan lecturas del core.

Antes de declarar una familia cubierta, completar la matriz por fuente de
`tools/smoke/README.md`: instalar/registrar los hooks efectivos, ejecutar los
casos y guardar los tres archivos, KeyValues y chat. También se etiquetan las
entradas auxiliares PlayerStats/TankControl/lifecycle. La lista de properties y
consultas del manifest delimita lecturas directas y dependencias de estado que
no deben confundirse con un evento de la biblioteca. Todos los casos reales
siguen **Pendientes**; no se operó competitive_dev ni se cambió el core.

## Gate de integridad antes de interpretar las capturas

Usar el observador 1.1.1 y `tools/smoke/validate_smoke_trace.py` con los tres
archivos de una misma sesión. Rechazar como evidencia completa los archivos
parciales, secuencias/epochs/ticks incompatibles, chunks incompletos o health
no conforme; preservar los archivos para diagnóstico. `valid=true` solo prueba
integridad estructural. Recoger también status posterior y errores SourceMod,
porque el flush del propio health puede fallar después de escribirlo.
La [auditoría final](l4d2-skills-smoke-final-audit.md) detalla pruebas y límites.
Añadir en la pasada de recargas SDK: ausencia al arrancar→alta, retirada→alta
entre dos frames y cierre mientras se retira la biblioteca; registrar nuevo
inventario y que las operaciones diferidas anteriores no instalen hooks. Estos
casos y la resolución real de referencias negativas/no-edict siguen **Pendientes
SRCDS**; no se operó competitive_dev.
