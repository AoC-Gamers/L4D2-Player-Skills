# Smoke: cobertura de fuentes de Skills

## Resultado preparado

Se amplió el observador standalone para recopilar tres flujos separados:

- `run-<id>.engine.jsonl`: 301 eventos del catálogo más `player_spawn` (302),
  incluidos `player_death` y `boomer_exploded`; además entradas auxiliares
  etiquetadas y markers de forwards públicos de Skills.
- `run-<id>.sdkhooks.jsonl`: OnTakeDamage PRE, OnTakeDamagePost, TraceAttack,
  Touch y Spawn, más los forwards globales de creación/destrucción de entidades,
  para los targets usados por Skills.
- `run-<id>.left4dhooks.jsonl`: los 26 forwards consumidos y muestras manuales
  de las 18 funciones L4D* usadas por Skills, distinguiendo native y stock.

Un `run_id` une los tres archivos, y una secuencia global ordena callbacks entre
fuentes. Headers de evento/callback aportan tick, game/engine time, mapa y epoch;
los valores se vinculan por `seq`. Las referencias guardan valor crudo, entref y,
si es un jugador válido, userid/serial/generación observada. El observador
continúa excluido del producto; Skills conserva un solo SMX en su artefacto.

Fuente y operación: `tools/smoke/README.md` del checkout. Los módulos se integran
con el generador; fuente/SMX/manifest se generan bajo `.build/smoke/game-events/`.
No se instaló nada, no se tocaron competitive_dev, Player-Stats ni cvars
compartidas, y no se publicó.

## Cobertura derivada del código

La auditoría del entrypoint y módulos privados confirmó:

| Entrada utilizada por Skills | Preparación del observador | Aceptación real |
|---|---|---|
| 38 registros HookEvent | Sus 38 nombres están dentro del catálogo + suplemento; logger PRE/POST tipado | Pendiente SRCDS |
| 5 tipos SDKHook | Registro por target existente/nuevo, resultado SDKHookEx y datos recibidos | Pendiente SRCDS |
| 26 callbacks Left4DHooks | Firmas cotejadas, todos sus argumentos y fases | Pendiente SRCDS |
| 18 funciones L4D* (3 natives y 15 stocks) | Sampler manual con resultado o razón de omisión | Pendiente SRCDS |
| PlayerStats/TankControl/lifecycle | Callbacks auxiliares etiquetados y consultas manuales pertinentes | Pendiente SRCDS |
| Lecturas directas de props, ConVars y estados derivados | Inventario de propiedades literales; muestras de cliente y evidencia debug/API/configuración | No se intercepta cada lectura interna |

El manifest `skills_sources` contiene el inventario actual, sitios SDKHook,
callbacks, consultas y propiedades literales. Su cobertura declarada no prueba
que todos los hooks o detours estén activos en un servidor. Los fallos de hook,
biblioteca/natives ausentes y omisiones de muestras se registran explícitamente.
No se presenta el JSON de 301 eventos como inventario exhaustivo del motor.

Los targets SDKHooks son clientes/Tanks, witches/brides, tank_rock y los props
`prop_car_alarm`/`prop_car_glass`. Se intenta hook inmediato cuando la entidad es
válida y un pase diferido por entref reintenta lo pendiente. Stop, map end y
reinicio de captura invalidan esos frames por generación; se retiran solo los
callbacks del observador. No se reconstruye un Spawn anterior al inicio.

## Semántica de comparación

Las tres APIs exponen el mismo motor por caminos y fases diferentes. Los valores
se conservan con contexto: no se normalizan en una única supuesta verdad. Los
callbacks Action del observador devuelven `Plugin_Continue` sin cambiar refs o
vectores; `listener_action` es solo ese resultado, no el agregado de terceros ni
el retorno original de la función de motor. Un callback void no ofrece Action.
Daño POST no demuestra daño neto aplicado ni igualdad con el parámetro PRE.

Los stocks del include Left4DHooks pueden leer sendprops o memoria directamente;
no todos son llamadas a un proveedor ni un evento independiente. El comando
`sm_skills_smoke_sources_sample` obtiene muestras en el instante del comando,
después de configs y con guards de cliente/prop/clase y disponibilidad. No
intercepta los reads ejecutados por Skills ni recupera memoria histórica.
Los valores float incluyen texto y bits crudos, también ante valores no finitos.

Los callbacks del motor y bibliotecas permanecen pasivos. Capturar todo implica
E/S y coste que puede modificar el timing observado: limitar cada pasada a una
ventana controlada y registrar esa condición. Los contadores de health/status,
truncación de cadenas y cobertura deben acompañar cualquier conclusión.

## Pruebas locales y límites

Tres subagentes GPT-6 Luna con razonamiento alto dividieron SDKHooks, Left4DHooks
y auditoría/pruebas. El agente principal integró, corrigió y revisó los módulos.

- `test_game_event_observer.py`: schema del catálogo, tipos, metadata, duplicados,
  clasificación userid frente a entindex, cobertura de nombres y compilación.
- `test_source_observer.py`: inventario 38/5/26, inlining y compilación del
  observador; ejecución de callbacks reales extraídos en SourcePawn VM, con
  sentinels para refs/vectores, Action, argumentos y PRE/POST separados (23
  verificaciones); cinco casos de frame diferido por sesión/entref/validez.
- Compilación del observer, core y consumidores API/Series, sin warnings nuevos;
  diff-check, empaquetado/validadores y release local. Evidencia bajo
  `.build/refactor/smoke-sources/`.

La VM sustituye helpers de SourceMod/SDKHooks y reloj por stubs; no ejecuta los
hooks reales del motor, los detours, las consultas a memoria ni los archivos de
un gameserver. Esas coberturas, el orden efectivo y las discrepancias de valores
quedan **Pendientes** en la matriz por familia/fuente de la guía. Conservar los
KeyValues del acompañante API y la captura de anuncios/chat junto con los tres
logs para baseline/refactor.

## Pendiente Boomer y siguiente ejecución

El [issue de spawn desconocido](l4d2-skills-boomer-unknown-issue.md) permanece
abierto para evidencia real. Recopilar el stream completo y contrastar spawn,
now_it, daño, death y explosion con cada fase SDK y estado observado. No se
aplicó la cota experimental de tiempo desde death. Antes de instalar, coordinar
un gameserver autorizado; en ZoneMod descargar/cargar el modo para aplicar los
SMX, conservar respaldos y restaurar únicamente cambios temporales propios.

## Auditoría final del observador

El [informe final](l4d2-skills-smoke-final-audit.md) registra la resincronización
SDKHooks tras ausencia/recarga, resolución de referencias negativas y health
posterior al flush de datos. Se amplían firmas, pasividad, serialización y
validación global de sesiones/ticks con evidencia local. El observador 1.1.1 y
su validador continúan separados del producto; la matriz SRCDS sigue pendiente.
