# Línea base y evidencia de validación de Skills

Fecha: 2026-10-24. Árbol inicialmente limpio; revisión `f117bfca4a1c82978a6546a3343935c9fbd265ef`. No se encontraron instrucciones `AGENTS.md` en el repositorio ni sus ancestros inspeccionados.

## Evidencia recuperable

`.build/refactor/baseline` contiene fuentes previas, SMX, SHA256 por archivo, estado Git, log y `inventory.json`. Este último registra 116 entradas de callbacks, 131 sitios de registro/consulta, 140 sitios KeyValues y 1199 coincidencias de escritura: son recuentos léxicos del core y acompañantes, no resultados de gameplay. El documento de arquitectura fija el dueño de escritura por dominio. No usar `make clean` antes de terminar la comparación runtime.

SMX baseline SHA256: `731d81087eca0b346f4cc9875a9c8725e3c7d37e6e5708d3e3c26f1c5d9a3283`. Toolchain real: SourcePawn `1.12.0.7255`. Baseline build/package/validador correctos, cero warnings. API y Series baseline también compilados; no se incluyen en el paquete principal.

## Superficie core congelada

### Natives

`PlayerSkills_IsSkillEventValid`, `PlayerSkills_FillSkillEventKeyValues`, `PlayerSkills_IsKillEventValid`, `PlayerSkills_FillKillEventKeyValues`, `PlayerSkills_IsBossEventValid`, `PlayerSkills_FillBossEventKeyValues`, `PlayerSkills_IsBossSessionValid`, `PlayerSkills_FillBossSessionKeyValues`, `PlayerSkills_IsSkillSummaryValid`, `PlayerSkills_FillSkillSummaryKeyValues`, `PlayerSkills_IsKillSummaryValid`, `PlayerSkills_FillKillSummaryKeyValues`.

### Forwards

`PlayerSkills_OnSkillDetected`, `PlayerSkills_OnKillDetected`, `PlayerSkills_OnBossEventDetected`, `PlayerSkills_OnBossSessionFinalized`, `PlayerSkills_OnTankSessionClosed`, `PlayerSkills_OnSkillSummaryFinalized`, `PlayerSkills_OnKillSummaryFinalized`.

### Comandos

`sm_skills`, `sm_skills_stats`.

### Eventos registrados

`round_start`, `round_end`, `scavenge_round_start`, `scavenge_round_finished`, `ability_use`, `weapon_fire`, `player_jump`, `player_jump_apex`, `jockey_ride`, `jockey_ride_end`, `jockey_punched`, `jockey_killed`, `tank_spawn`, `player_spawn`, `player_hurt`, `player_death`, `player_incapacitated_start`, `player_ledge_grab`, `player_shoved`, `player_now_it`, `boomer_exploded`, `charger_charge_start`, `charger_charge_end`, `charger_killed`, `charger_carry_start`, `charger_impact`, `charger_carry_end`, `charger_pummel_start`, `charger_pummel_end`, `triggered_car_alarm`, `witch_killed`, `choke_start`, `choke_stopped`, `drag_begin`, `drag_end`, `tongue_pull_stopped`, `pounce_stopped`, `pounce_end`.

### ConVars creadas y valores por defecto

| Nombre | Default |
|---|---|
| `sm_skills_debug` | `0` |
| `sm_skills_enable` | `1` |
| `sm_skills_announce_witch` | `7` |
| `sm_skills_announce_tank` | `15` |
| `sm_skills_announce_hunter` | `63` |
| `sm_skills_announce_smoker` | `31` |
| `sm_skills_announce_boomer` | `7` |
| `sm_skills_announce_spitter` | `1` |
| `sm_skills_announce_jockey` | `127` |
| `sm_skills_announce_charger` | `63` |
| `sm_skills_announce_other` | `3` |
| `sm_skills_announce_kill_mode` | `3` |
| `sm_skills_announce_specialclear_mode` | `3` |
| `sm_skills_announce_tongue_release_mode` | `2` |
| `sm_skills_shove_attempt` | `1` |
| `sm_skills_boomer_vomit_min_targets` | `3` |
| `sm_skills_witch_print_max_entries` | `4` |
| `sm_skills_hunter_pounce_height` | `400` |
| `sm_skills_hunter_skeet_interrupt` | `0` |
| `sm_skills_jockey_leap_height` | `300` |
| `sm_skills_charger_instakill_height` | `400` |
| `sm_skills_charger_death_setup_height` | `100` |
| `sm_skills_charger_claw_hits` | `4` |
| `sm_skills_bhop_streak_min` | `3` |
| `sm_skills_bhop_init_speed` | `150` |
| `sm_skills_bhop_keep_speed` | `300` |

### Hooks SDK

```text
SDKHook(client, SDKHook_OnTakeDamage, Boss_OnClientTakeDamage);
SDKHook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage_Client);
SDKHook(client, SDKHook_OnTakeDamagePost, Boss_OnTankTakeDamagePost);
SDKHook(client, SDKHook_OnTakeDamagePost, Detect_OnTakeDamagePost_Client);
SDKHook(entity, SDKHook_OnTakeDamage, Detect_OnTakeDamage_CarAlarm);
SDKHook(entity, SDKHook_OnTakeDamage, Detect_OnTakeDamage_CarGlass);
SDKHook(entity, SDKHook_Spawn, Detect_OnSpawn_CarAlarm);
SDKHook(entity, SDKHook_Spawn, Detect_OnSpawn_CarGlass);
SDKHook(entity, SDKHook_Touch, Detect_OnTouch_CarAlarm);
SDKHook(entity, SDKHook_Touch, Detect_OnTouch_CarGlass);
SDKHook(rock, SDKHook_TraceAttack, Detect_TraceAttack_Rock);
SDKHook(witch, SDKHook_OnTakeDamage, Boss_OnWitchTakeDamage);
SDKHook(witch, SDKHook_OnTakeDamagePost, Boss_OnWitchTakeDamagePost);
```

Callbacks externos, timers y escritores por archivo/línea están en el inventario baseline, junto a los sitios de serialización. Include público, traducciones, fuentes API/Series y manifiesto se comparan byte a byte al cerrar.

## Evidencia por fase

| Integración | Evidencia local | Resultado |
|---|---|---|
| 1: composición/lifecycle | `.build/refactor/phase1` | deps/build/diff; 615/615 cuerpos preservados |
| 2: extracción detect | `.build/refactor/phase2` | deps/build/diff; 615/615 cuerpos preservados |
| 3: consultas/API/identidad | `.build/refactor/phase3` | deps/build/diff; 615/615 cuerpos preservados |
| 3: Tank/Witch | `.build/refactor/phase3-boss` | deps/build/diff; 615/615 cuerpos preservados |
| 2: consolidación familias | `.build/refactor/phase2-consolidated` | deps/build/diff; 615/615 cuerpos preservados |
| 3: publicación/contexto | `.build/refactor/phase3-publication`, `phase3-context` | deps/build/diff; 615/615 cuerpos preservados |
| 3: observaciones tipadas hurt/death | `.build/refactor/phase3-inputs` | deps/build/diff; 8 cuerpos adaptados, 607 preservados |
| 4: integridad y Boomer | `.build/refactor/phase4` | Ver validación final y revisión de diferencias |

El comparador local `.build/refactor/tools/compare.py` compara cuerpos tokenizados con baseline (mapea callbacks a sus delegadores de lifecycle), registros y archivos públicos. No interpreta el VM ni prueba la correlación de eventos. Los errores intermedios de extracción/static y los dos warnings iniciales se corrigieron antes de cerrar sus gates.

## Diferencias funcionales explícitas

- Timers de detección capturan conexión, generación de vida y ronda, o entref y ronda. Las generaciones no se ponen a cero al resetear. Se descarta trabajo anterior a spawn/disconnect/reset/cierre, incluso si hay nueva ronda live. Witch usa ID monotónico de sesión.
- Los DataPack de timers usan cierre propiedad del timer, incluso al cancelar por mapa. Se retiraron los cierres manuales correspondientes de Tank para evitar doble cierre.
- Las altas/bajas de bibliotecas solo actualizan disponibilidad; el inventario inicial no consulta estado de juego. Configs/frame reconcilian. Los forwards directos de Stats siguen siendo autoritativos y no se pierden esperando un frame. La captura tardía de identidad/hooks permanece; no rehidrata historial.
- **Autorizado por el usuario:** BoomerKill difiere también su forward hasta la resolución de prioridad (espera mínima de 100 ms, completada por explosión o vencimiento semántico de Pop; ver el informe de Boomer tardío al final). El evento provisional no es público ni cuenta en consultas/summaries. BoomerPop lo descarta aun cuando su announce se maneje con Plugin_Handled. Sin Pop, la resolución noPop o el vencimiento estricto de la ventana permite publicar Kill y anunciar si el forward lo permite. Un cierre antes de resolver descarta el provisional, siguiendo hard-stop.

## Comportamiento real y pendientes

No se ejecutó ningún caso SRCDS baseline/refactor. `competitive_dev` se inspeccionó en solo lectura: activo y healthy; el usuario confirmó que debe seguir reservado para Player-Stats. No se cambió SMX, modo, plugins, cvars ni se reinició. No hay deltas, payloads ni anuncios observados que puedan atribuirse al refactor.

Todos los casos de [smoke](l4d2-skills-srcds-smoke.md) quedan pendientes. El riesgo heredado de pérdida por orden OnMapEnd/Stats se corrigió después de la auditoría mediante cierre antes de cleanup y pruebas locales de ambos órdenes; véase [MapEnd / Stats](l4d2-skills-mapend-close.md). La comprobación SRCDS sigue pendiente. Mitad/match conservan la frontera de resumen actual; no se añade un nuevo forward de match.

Player-Stats tiene trabajo local ajeno en su checkout. No se escribieron archivos allí ni se invocaron sus builds/despliegues. No hubo commit, push ni publicación.

## Resultado local previo a la auditoría final

- `make deps-smx`, `make build-smx` y `git diff --check`: correctos.
- SourcePawn `1.12.0.7255`, cero warnings en core, API y Series. El build ordinario
  excluye los acompañantes por manifiesto; se compilaron además directamente con
  el mismo include público y toolchain a `.build/refactor/final/consumers`.
- `make package-smx`, validador del paquete, `make release` y validador de dist:
  correctos (`ARTIFACT_VALIDATION_OK`). El ZIP es una salida local; no se publicó.
- SHA256 SMX refactor: `dc76f82b2d050fdde4a979d25698a1479a55c395a44ee8fc7e80754cc5ca92da`.
- Comparación final: 615 funciones top-level baseline, 556 cuerpos preservados, 59 adaptados y ninguna función perdida. El informe enumera los cambios de inputs, timers, lifecycle y publicación Boomer; no cuenta métodos de structs como funciones top-level.
- Todos los registros externos comparados son iguales. Include público,
  traducciones, manifiesto y fuentes de acompañantes iguales byte a byte.
- Evidencia final: `.build/refactor/final/compile.log`, `comparison.json`, logs
  `consumers/` y `artifact_validation.json`. El checker recursivo adicional exige
  un único SMX y comprueba fuentes privadas/include/traducciones/docs frente al
  ZIP y dist, además del validador de manifiesto del repositorio.

Artefacto: `dist/release/l4d2-skills-local.zip`.
No hay pruebas de servidor ejecutadas ni equivalencia de gameplay demostrada.

## Auditoría final y evidencia vigente

Los hashes y recuentos de la sección anterior identifican el punto previo a la
auditoría final. Tras corregir las continuaciones reentrantes y la reapertura de
ronda, el informe vigente es [l4d2-skills-final-audit.md](l4d2-skills-final-audit.md).
Su evidencia está en `.build/refactor/audit-final/`: copia previa `before/`,
comparación, logs de compilación, fixtures con funciones extraídas, logs de VM y
validación del ZIP. No mezclar esos resultados locales con el smoke SRCDS, que
continúa sin ejecutarse.

SMX vigente después de la auditoría: `02a4ea031918f5314c191872db63f8acdfc45502541a3db38a152ea63909d006`.

## Resolución posterior de MapEnd / Player-Stats

La evidencia vigente de esta fase está en `.build/refactor/mapend-close/` y en
[su informe](l4d2-skills-mapend-close.md). Los hashes previos se conservan como
historial; el informe nuevo identifica el SMX y ZIP local actualizados. El cierre
común conserva ambos summaries antes de limpiar en cualquiera de los dos órdenes.

## BoomerPop posterior a 100 ms — resolución local

El timer ya no decide antes de que Pop deje de ser admisible: la explosión o el
límite semántico existente de 3 s resuelven el provisional. Se conserva el payload,
la supresión y el contrato público; nueva vida y cierres invalidan el candidato.
El [informe local](l4d2-skills-boomer-late.md) registra reproducción previa,
pruebas de VM, revisión con tres Luna de razonamiento alto, compilación y paquete.
El smoke SRCDS sigue pendiente; no se operó competitive_dev ni se publicó.

## Spawn Boomer desconocido: issue y observador preparados

El usuario dirigió la resolución a documentar el issue y recopilar el stream
completo del catálogo de eventos antes de cambiar la política de clasificación.
Se añadió una herramienta standalone (301 nombres JSON + player_spawn, PRE/POST,
payloads declarados, identidad y clocks) fuera del producto. El
[issue](l4d2-skills-boomer-unknown-issue.md) conserva la reproducción roja y
explicita pendientes de servidor. El core permanece idéntico; no se aplica la
cota temporal experimental ni se opera competitive_dev.

## Smoke ampliado a tres fuentes

Por petición del usuario se separó la instrumentación en logs engine, SDKHooks
y Left4DHooks, con run_id compartido, tick, relojes, secuencia y argumentos.
El [informe](l4d2-skills-smoke-sources.md) documenta cobertura declarada,
lecturas manuales, validaciones y matriz SRCDS pendiente. Es tooling standalone
excluido del ZIP; el contrato y las fuentes de Skills permanecen iguales.

## Auditoría final del observador

El [informe final](l4d2-skills-smoke-final-audit.md) registra la resincronización
SDKHooks tras ausencia/recarga, resolución de referencias negativas y health
posterior al flush de datos. Se amplían firmas, pasividad, serialización y
validación global de sesiones/ticks con evidencia local. El observador 1.1.1 y
su validador continúan separados del producto; la matriz SRCDS sigue pendiente.
