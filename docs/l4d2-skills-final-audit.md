# Auditoría final del refactor de Skills

Fecha: 2026-10-24. Alcance: regresiones de contrato, Boomer y cierre de
ronda/mitad. Tres subagentes GPT-6 Luna con razonamiento alto hicieron revisiones
acotadas; el agente principal revisó sus hallazgos e integró las correcciones.
El estado previo a esta auditoría se preserva en
`.build/refactor/audit-final/before/`; el baseline original sigue en
`.build/refactor/baseline/`. No se descartaron los cambios locales del refactor.

No se consultó ni operó `competitive_dev`. No hubo deploy, commit, push ni
publicación. Los ZIP/SMX resultantes son artefactos locales.

## Conclusión y evidencia

La comparación y las revisiones no identificaron cambios accidentales de
firmas/enums públicos, claves KeyValues, comandos, ConVars, traducciones ni
registros de hooks/forwards/natives. Se conserva un SMX principal y acompañantes
API/Series opcionales. No se modificó Player-Stats.

Sí se reprodujeron fallos de control de flujo bajo transiciones simuladas en
una VM SourcePawn. Son rutas heredadas o condicionadas a reentrada; no son
incidentes observados dentro de L4D2 ni prueban que un consumidor real produzca
esas transiciones. Se corrigieron sin cambiar cantidades ni los scopes
`LifeKill`/`SkillWindow`.

## Hallazgos corregidos

| Área | Condición reproducida localmente | Corrección |
|---|---|---|
| Boomer Pop | El forward cambia la vida, userid o ronda; al retornar, el stack viejo marca supresión usando el slot de la vida nueva. | `Detect_EventBoomerExploded` captura userid, vida, generación de detección y epoch de lifecycle; revalida antes de anunciar o suprimir. `Continue` y `Plugin_Handled` normales conservan su semántica. |
| Cierre de ronda | Tras recibir el cierre, el proveedor deja de estar disponible y SafeArea todavía devuelve true; la reconciliación volvía a habilitar live. | `roundClosed` impide reabrir desde una consulta/fallback; solo un inicio aceptado o live explícito permite nueva ronda. `Lifecycle_CloseRound` cierra el gate antes de callbacks y es idempotente. |
| Boss finalizado | Un forward sustituye la sesión/epoch, o reentra en la finalización; la continuación vieja consolidaba, marcaba o anunciaba el slot nuevo. | Se fija `finalized` antes de los forwards y se valida ID de sesión/epoch después de cada uno. El loop de cierre detiene continuaciones caducadas. Orden normal TankClosed → BossFinalized → anuncio preservado. |
| Summaries | El forward de skills cambia el buffer de ronda antes de construir el snapshot de kills. | Se construyen ambos snapshots antes del primer forward. El orden público continúa Skills → Kills y ambas familias conservan el buffer del cierre anterior. |
| Boundary durante cierre | Un start/live solicitado desde un forward de boss podía resetear el buffer antes de finalizar sus resúmenes. | `closeInProgress` aplaza esos límites hasta completar Boss → summaries → detección. No se retiene un `Event`. Live→Start termina pre-live; Start→Live termina live. MapStart/MapEnd/unload limpian los límites pendientes. |

Fuentes principales: `lifecycle.sp`, `mode_context.sp`, `types.sp`, `boss.sp`,
`summaries.sp`, `detect/boomer.sp` y `detect/deferred.sp` bajo el directorio privado
`addons/sourcemod/scripting/l4d2_player_skills/`. Son los únicos siete archivos
de producto modificados por esta auditoría respecto de `before/`.

## Pruebas ejecutadas sin servidor

Los generadores extraen funciones reales de las fuentes anteriores y actuales;
no reimplementan esas funciones para lograr el resultado. Los fixtures
sustituyen natives, callbacks, entidades, buffers y anuncios por dependencias
controladas. Se compilaron y ejecutaron con SourcePawn 1.12 / `spshell` local;
no se cargó ningún plugin en SourceMod/SRCDS.

| Suite | Antes | Resultado actual y límite |
|---|---|---|
| `harness-boomer` | Las expectativas de integridad fallaban en vida nueva, userid reemplazado y cierre; `Handled` ya conservaba la supresión. | 7/7 casos pasan: tres reentradas, Continue, Handled y dos órdenes Pop/Death. Estos dos últimos modelan la cola/cancelación con stubs; no ejecutan el callback real de `player_death`. |
| `harness-rounds` | Reproduce la reapertura por SafeArea con funciones baseline. | Pasa cierre/reconciliación, nuevos inicios, cierre doble/reentrante y nuevos start/live desde Boss. Comprueba que Summary y DetectEnd ocurren antes de reset/live nuevo y conserva ambos órdenes de boundaries. Boss y summary son stubs en esta suite. |
| `harness-summary` | Assert rojo: kills lee el buffer nuevo `22` en vez del congelado `11`. | Ambas familias capturan `11`, con IDs correctos y orden Skills → Kills; cierre repetido produce una sola secuencia. Builders son stubs, no prueba de payloads KV. |
| `harness-boss` | Reproduce escritura/continuación obsoleta tras sustitución de slot y cambio de epoch. | Pasa guards tras ambos forwards, reentrada, orden normal y Handled. Estructuras y efectos externos son stubs; se ejecuta el finalizador real extraído. |

Repetición desde la raíz del repositorio, conservando `.build/`:

```sh
python3 .build/refactor/audit-final/harness-boomer/run.py --expect fixed
bash .build/refactor/audit-final/harness-rounds/run.sh
bash .build/refactor/audit-final/harness-summary/run.sh
bash .build/refactor/audit-final/harness-boss/run.sh
```

Logs: `.build/refactor/audit-final/{boomer,rounds,summary,boss}-run.log`,
`harness-boomer/red-before-fix.log`, `harness-summary/red-before-fix.log` y
`logs/{rounds-final,boss-final}.log`. Los README y generadores de cada suite
explican las dependencias simuladas; `harness-boss/provenance.json` registra
fuentes, líneas y hashes extraídos. Los fixtures quedan fuera del manifiesto y
no forman parte del ZIP de producto.

## Pendientes concretos

- Todo el [smoke SRCDS](l4d2-skills-srcds-smoke.md), incluidos payloads KeyValues,
  deltas reales, anuncios y disponibilidad opcional de Player-Stats.
- El pendiente lógico de pérdida de summaries por orden MapEnd/Stats se resolvió
  posteriormente con cierre común antes de cleanup y pruebas locales G1–G18.
  Véase [MapEnd / Stats](l4d2-skills-mapend-close.md). Sigue pendiente observar
  esos casos en SRCDS; no se añadió una nueva unidad de estadísticas.
- Llegada de `boomer_exploded` después de los 100 ms: el forward de kill ya
  publicado no puede retirarse. La ventana autorizada no cambió en esta auditoría.
- Confirmar en servidor que los consumidores y el scheduler permiten/rechazan
  las secuencias simuladas; los resultados de VM no acreditan gameplay.

## Construcción y comprobación del paquete

- Core: `make deps-smx`, `make build-smx`, `git diff --check`, correctos;
  SourcePawn `1.12.0.7255`, sin warnings.
- Consumidores API y Series compilados directamente con el include público y
  el mismo toolchain de producto, sin warnings. Siguen fuera del ZIP principal.
- Comparación actual con el baseline original: 615 funciones top-level, 547 cuerpos preservados, 68 adaptados y ninguno perdido. Todos los registros comparados y los cinco archivos públicos/manifiesto/acompañantes permanecen idénticos.
- SHA256 SMX auditado: `02a4ea031918f5314c191872db63f8acdfc45502541a3db38a152ea63909d006`.
- Evidencia de construcción: `.build/refactor/audit-final/compile.log`,
  `consumers/` y `comparison.json`. La validación recursiva de fuentes, docs y
  binario contra dist/ZIP queda en `artifact_validation.json` del mismo directorio.
- Artefacto local actualizado: `dist/release/l4d2-skills-local.zip`.
  `package-smx`, el validador de manifiesto y `release` se ejecutan al cerrar;
  su resultado queda registrado junto con el hash del ZIP en esa evidencia.

La retirada de Player-Stats también invalida el live pendiente de ese proveedor;
una carga posterior no reaplica una señal de la instancia retirada. Esta
invalidación de flags se revisó en código y en el build de producto; no se
presenta como un caso de reload observado en SRCDS.

## Evidencia posterior de MapEnd

Los hashes y recuentos de construcción anteriores son históricos de esta
auditoría. La corrección posterior de MapEnd, su SMX vigente y pruebas locales
están en [l4d2-skills-mapend-close.md](l4d2-skills-mapend-close.md).
