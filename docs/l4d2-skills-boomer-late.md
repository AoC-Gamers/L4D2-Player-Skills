# BoomerPop posterior a 100 ms

## Alcance y resultado

Se corrigió el borde de prioridad entre `player_death` y `boomer_exploded`.
El timer de 100 ms ya no publica un `BoomerKill` cuando todavía es posible un
Pop válido para esa misma vida. Tres subagentes GPT-6 Luna con razonamiento alto
revisaron contrato, integridad y pruebas locales; el agente principal diseñó,
integró y revisó los cambios. No se operó competitive_dev, no se modificó
Player-Stats y no se hizo commit, push ni publicación. El ZIP se genera localmente.

## Hechos comprobados y criterio

El snapshot `.build/refactor/boomer-late/before/` conserva las fuentes, docs,
estado Git y SMX anteriores a esta corrección. La fixture reproduce la secuencia
`death → timer a 100 ms → Pop a 150 ms`: antes el timer ya había publicado Kill;
con la corrección conserva el candidato y Pop lo absorbe antes de su forward.

El detector existente acepta Pop si `timeAlive <= 3 s`; no acepta `> 3 s`.
La nueva espera usa ese mismo límite funcional, sin ampliar la aceptación de Pop.
El catálogo local de eventos (`docs/l4d2_game_events.json`, `boomer_exploded`)
indica que la explosión ocurre después de death; no establece un máximo de 100 ms.
La latencia y el orden efectivos del motor siguen sin observarse en SRCDS.

## Implementación y ownership

- `DetectBoomerState` posee la resolución de explosión, el compromiso de la muerte
  y si venció la espera mínima (`explosionResolved`, `deathCommitted`,
  `killDelayElapsed`). Nueva conexión, desconexión, spawn y reset de ronda/mapa
  reinician esos datos; el spawn también lo hace cuando Skills está desactivado.
- `Detect_EmitSiLifeKill` construye una sola vez el payload original `LifeKill`.
  Duplicados de death no sustituyen un candidato pendiente ni crean otro después
  del compromiso de esa vida. El candidato sigue oculto a API/consultas/summaries.
- El timer conserva candidato y tracks si Pop aún califica. Reprograma al final
  de la ventana desde spawn, con margen de scheduling de 100 ms, y vuelve a
  comprobar el límite estricto. En el empate exacto de 3 s aún puede ganar Pop.
- Una explosión noPop (bile/impacto previo, atacante inválido o tiempo excedido)
  resuelve la espera. Si vencieron los primeros 100 ms, publica el kill pendiente;
  si no, lo publica el timer. El flush de vomit conserva su lugar antes de esa
  publicación, incluso si Kill ya estaba comprometido por impactos previos.
- Pop válido cancela el provisional y reserva la supresión antes del forward,
  incluso si el consumidor devuelve `Plugin_Handled`. Su payload y asistencia
  siguen siendo `SkillWindow`; no se reconstruyen desde el payload de Kill.
- Publicación y reentrada se protegen con ID, userid, generación de vida/ronda y
  epoch de lifecycle. Una cola vieja no publica un reemplazo. El cierre descarta
  candidatos pendientes; una explosión posterior al cierre no crea un Pop nuevo.

Si `spawnTime <= 0`, la regla previa calcula `timeAlive=0`. Para conservarla,
no se inventa un plazo finito: el kill espera una explosión o una invalidación
de contexto. Si ninguna llega, puede permanecer provisional sin publicarse.
Esa limitación está explícita; no se convierte silenciosamente en una kill
cuando aún podría llegar un Pop válido. Un overwrite del ring también puede
invalidar el candidato, como antes.

## Contrato público

No cambian include, nombres, firmas, enums, natives, forwards, claves KeyValues,
comandos, ConVars ni traducciones. `Plugin_Handled` conserva su efecto sobre el
announce builtin. Los scopes y cantidades no cambian: Kill usa `LifeKill`; Pop
usa `SkillWindow`; los builders de damage/actor_damage/chip_damage/assists no se
reescriben. Cambia intencionalmente el momento de publicar Kill: puede esperar
hasta que Pop deje de ser admisible, en lugar de comprometerse a los 100 ms.
No se retractan forwards publicados ni se agregan eventos de cancelación públicos.

El comparador contra baseline confirma los registros y los cinco archivos de
contrato sin cambios: `.build/refactor/boomer-late/comparison.json`.

## Validación local

Las fixtures de SourcePawn VM extraen funciones de producción y sustituyen las
operaciones del framework/engine, almacén de eventos, builders de payload,
proyección de asistencia y reset/supresión SI por stubs. Ejecutan control de flujo real;
no equivalen a ejecutar el plugin completo ni a observar el scheduler del motor,
la serialización KeyValues real o el chat traducido. Los payloads sintéticos
permiten detectar pérdida/mutación en el camino diferido, no probar daño real.

Pasan 19 secuencias Boomer y siete regresiones adicionales de reentrada de Pop.
Cubren Pop a 150 ms, empate y exceso de 3 s, fallback reprogramado sin explosión,
noPop antes/después del timer y antes de death, Pop antes de death, spawn
desconocido, cierre, duplicados, ID de timer obsoleto y Handled en ambas familias.
El control previo también ejecuta ambos forwards (`Kill=1`, `Pop=1`); el actual
ejecuta solo Pop para la llegada tardía válida.

Evidencia de Boomer: `.build/refactor/boomer-late/harness/`. El README de ese
directorio documenta comandos, casos y límites. Evidencia de regresiones:
`.build/refactor/boomer-late/regressions/results.json`; pasan MapEnd (18 casos),
reinicio de biblioteca opcional, cierre de ronda, congelación de summaries y
finalización boss. Los casos rojos históricos se reproducen antes de los verdes.

Build de core y consumidores opcionales API/Series: éxito, sin warnings nuevos.
Se ejecutaron `make deps-smx`, `make build-smx` y `git diff --check`.
Logs y binarios de consumidores: `.build/refactor/boomer-late/compile.log`,
`deps.log` y `consumers/`. Se completan `make package-smx`, ambos validadores del
artefacto y `make release`; la verificación byte a byte y los hashes quedan en
`.build/refactor/boomer-late/artifact-validation.json`.

SMX de core validado: `a2433ca4b4da2d9db9ce4308cf365d23fa51e3e1f05112c908f37037d9a2f383` (SHA-256).

## Pendientes de servidor

Todos los casos SRCDS permanecen **Pendientes**. Ejecutar el
[smoke](l4d2-skills-srcds-smoke.md) en un entorno autorizado: Pop a más de 100 ms,
empate y exceso de 3 s, noPop en ambos órdenes, ausencia de explosión con spawn
conocido/desconocido, Handled, asistentes desconectados, duplicados y reentradas,
cierre de ronda/mitad/match/mapa y disponibilidad opcional de Player-Stats.
Capturar eventos, forwards, payloads KeyValues, anuncios y razones de descarte.
No usar competitive_dev mientras siga reservado por el usuario.
