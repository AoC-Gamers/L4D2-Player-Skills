# Refactor interno de Player-Skills

Fecha de línea base: 2026-10-24. Revisión: `f117bfca4a1c82978a6546a3343935c9fbd265ef`.

## Entrega a develop — 1 de noviembre de 2026

El usuario autoriza publicar el refactor y su tooling en `develop` con las
pruebas runtime pendientes. Reporta funcionamiento sin problemas durante el uso
observado, pero no terminó las pruebas previstas; no se declara aceptación
completa ni equivalencia de métricas.

- Completar la [matriz baseline/refactor en SRCDS](l4d2-skills-srcds-smoke.md),
  incluidos cierres con Stats, reentradas, recargas y dependencias opcionales.
- Investigar el [Boomer con spawn desconocido](l4d2-skills-boomer-unknown-issue.md)
  y completar las capturas del observador, incluidos los escenarios Witch.
- Contrastar forwards, API, summaries y anuncios con ambos plugins y sus
  acompañantes. Compilar o pasar pruebas locales no cierra estas tareas.

Esta entrega publica fuentes; no instala plugins ni opera gameservers. Las notas
de ejecución siguientes describen los cortes anteriores y sus límites.

## Contrato y método

Un único `l4d2_player_skills.smx`; API y Series permanecen consumidores opcionales.
No se modifica Player-Stats, el include público, traducciones, comandos, ConVars,
enums, claves KeyValues ni nombres/firmas/orden de forwards. `Plugin_Handled`
suprime presentación, no deshace clasificación ni recupera una kill absorbida.
La propuesta de Stats se usó para inventario, ownership y fases, no para copiar
su árbol de dominios. Los límites se derivan de Skills.

`LifeKill` y `SkillWindow` conservan trackers distintos. `damage`, `actor_damage`,
`chip_damage`, assists contextuales, stats visibles de vida completa y prioridades
Hunter/Smoker/Boomer/Charger/Jockey/Witch mantienen sus fuentes actuales.

## Línea base comprobada

- Árbol Git inicialmente limpio. SourcePawn 1.12.0.7255; build core sin warnings.
- Código inicial: 19 792 líneas entre main y módulos privados.
- Manifiesto: un root; fuentes privadas e include público empaquetados.
- `make package-smx` y validador del artefacto: correctos.
- SMX SHA256: `731d81087eca0b346f4cc9875a9c8725e3c7d37e6e5708d3e3c26f1c5d9a3283`.
- Copia local recuperable: `.build/refactor/baseline/source`, `smx`, `compile.log`,
  `sha256.json`, `git.txt`, `inventory.json`. El inventario incluye callbacks,
  hooks, comandos, natives, forwards, ConVars, claves KV y sitios de escritura;
  los recuentos léxicos no equivalen a comprobación de comportamiento.
- `competitive_dev`: activo, healthy, imagen `l4d2-dev`; volumen
  `data_competitive_dev` y resources de Docker-L4D2-AoC. El usuario indicó mantenerlo
  reservado para Stats: no aplicar SMX, cambiar modo/plugins/cvars ni reiniciar.
- No se ejecutó baseline de gameplay. Todos los escenarios de SRCDS quedan pendientes.

## Fases y paquetes revisables

| Fase | Cambio y límite | Aceptación |
|---|---|---|
| 1 | Composición, estado global, método de sesión boss y lifecycle fuera del main. Entradas del juego permanecen visibles. Sin cambiar orden de operaciones. | Compilar y comparar cuerpos de funciones trasladados; deps/build/diff. |
| 2 | Extraer de detect la propiedad de estado, tracking LifeKill/asistencias, familias y adaptación de daño/eventos según funciones reales. Sin fusionar trackers ni cambiar prioridad. | Auditoría Luna, integración personal, deps/build/diff. |
| 3 | Separar consultas de presentación y construcción/publicación de summaries de serialización API. Sin modificar payload ni orden. | Auditoría Luna, consumidores API/Series, deps/build/diff. |
| 4 | Proteger trabajo diferido contra generaciones caducadas y reconciliar bibliotecas opcionales desde un punto seguro. Cambios de integridad explícitos, sin política nueva. | Revisar referencias, guards y descartes; deps/build/diff. |
| 5 | Arquitectura vigente, comparación estática, empaquetado y smoke detallado. | deps/build/package/validador/release; consumers; smoke pendiente por reserva. |

Cada fase se registra en el informe con evidencia y archivos. La entrega a
`develop` conserva explícitamente los pendientes anteriores. Las extracciones
deben conservar cuerpos exactos salvo el cambio
identificado explícitamente. Cada dato tiene un dueño de escritura de dominio;
los coordinadores solicitan resets, no implementan contabilidad paralela.

## Riesgos y decisiones

Hecho: los timers Tank conservan slot e ID de sesión; Witch usa solo slot. La
posible reutilización antes de resolver es un riesgo estático, no un fallo
reproducido. Añadir comprobación de ID es protección de integridad.

Hecho: callbacks de biblioteca actuales consultan estado del proveedor. Separar
presencia y reconciliación evita consultas durante carga/descarga. Debe mantenerse
el fallback standalone y no reconstruir datos históricos al recargar Stats.

No se decide aquí ampliar soporte a modos, cambiar clasificación/daño/assists,
restaurar historial perdido tras reload ni agregar cierre público de match. Si
una corrección exige esas decisiones se consulta al usuario antes de aplicarla.

## Registro de ejecución

### Fase 1 — integrada

`state.sp` declara el almacenamiento común; `boss_session.sp` contiene el método
existente de sesión, y `lifecycle.sp` coordina transiciones. Las firmas externas
se mantienen como delegadores en el main. Se retiró de dos handlers internos el
parámetro `dontBroadcast`, que no consumían: los callbacks registrados conservan
su firma. Dos warnings iniciales quedaron corregidos.

`make deps-smx`, `make build-smx`, `git diff --check`: correctos, cero warnings.
Comparación léxica de 615 cuerpos de funciones (mapeando handlers de lifecycle a
sus nuevos nombres): todos preservados; registros HookEvent/SDKHook/SDKUnhook,
comandos, natives, forwards, ConVars y traducciones idénticos. No prueba runtime.
Evidencia local: `.build/refactor/phase1/{compile.log,comparison.json}`.
Los consumidores baseline API y Series también compilaron sin warnings.

### Fases 2 y 3 — integración estructural

La primera extracción de `detect.sp` conservó sus 121 funciones; después se
consolidaron las familias con los módulos legacy (231 funciones en ese conjunto).
Se pidió al subagente dividir el bloque inicialmente propuesto `families.sp` por
Hunter/Boomer/Jockey/Charger/Smoker y mantener el código compartido de calidad y
pins separado. No se aceptó una mera segunda agrupación monolítica.

Consultas/ranking salen de `announce.sp`; `summaries.sp` construye y publica
snapshots y `api_natives.sp` recibe llamadas de API. `identity.sp` y
`event_store.sp` contienen cache de identidad y buffer circular. Tank y Witch
quedan separados de las consultas de bosses y del cierre común. Los helpers
`static` de bosses que cruzan archivos se vuelven funciones internas sin `public`;
SourcePawn limita `static` al archivo. No se amplía la API pública.

Cada integración estructural compiló sin warnings. Se corrigieron en la revisión
un comentario incompleto, espacios finales y el alcance `static` entre archivos.
Evidencia: `.build/refactor/phase2`, `phase3`, `phase3-boss` y
`phase2-consolidated`. Las comparaciones de cuerpos, registros y archivos
públicos se repiten tras integrar cada paquete; no son pruebas de gameplay.

### Fase 3 — adaptación tipada completada

`player_hurt` y `player_death` se capturan una vez en `detect/inputs.sp` a
observaciones especializadas (`observations.sp`). `damage.sp`, `si_death.sp` y los
consumidores Hunter/Smoker/Jockey/Charger reciben esos datos. Se conservan buffers
de arma de 32/64 bytes y el orden de decisiones. No se incorporan campos de
muerte que el dominio no consuma. El gate pasó sin warnings; ocho cuerpos
adaptados y 607 preservados en la comparación previa a integridad.

### Fase 4 — integrada y revisada

Generaciones monotónicas de ronda/vida y userid/entref protegen timers de
cliente/entidad. Spawn invalida vida incluso con plugin deshabilitado. Witch
transporta ID de sesión y resuelve el slot al ejecutar; los timers Tank conservan
su comparación de sesión y ahora el timer posee el cierre de DataPack incluso
al cancelar por mapa. El incremento de generaciones se declara antes de los
mutadores que lo usan (corregido durante compilación).

Disponibilidad y carga tardía residen en un runtime único. Add/remove solo marca
presencia/sincronización; inventario en OnAllPluginsLoaded; consultas desde
OnConfigsExecuted o un frame con configs listas. Los forwards Stats directos
procesan live/end sin depender de la caché anterior. No se altera la política de
cierre map-end para resolver por intuición el orden entre dos plugins.

**Excepción funcional consultada y autorizada:** BoomerKill difiere también el
forward (no solo announce), manteniéndose provisional durante la decisión de Pop.
El evento provisional queda fuera de natives/consultas/summaries; Pop o lifecycle
lo descartan. Plugin_Handled sigue afectando solo al anuncio del resultado final.
El timer guarda el ID exacto para no consumir una operación posterior y verifica
vida/ronda/identidad después del forward antes de completar su trabajo.

Revisiones Luna adicionales detectaron y permitieron corregir la invalidación de
spawn deshabilitado, sincronización accidental desde cambio de modo, propiedad de
DataPack en Tank y token del evento Boomer. Evidencia final:
`.build/refactor/phase4/{compile.log,comparison.json}`. Ningún cambio se instaló en
SRCDS; la diferencia autorizada de Boomer y las protecciones siguen pendientes de
smoke real.

### Fase 5 — cierre local completado

Arquitectura, inventario, evidencia y smoke documentados y enlazados desde README.
Core y acompañantes API/Series sin warnings; deps/build/diff y
package/validador/release/validador correctos. Se mantiene un solo SMX en el ZIP.
El informe de [validación](l4d2-skills-refactor-validation.md) identifica hashes,
logs, comparación y diferencias autorizadas. Queda pendiente ejecutar toda la
matriz SRCDS en un entorno coordinado: competitive_dev continúa reservado por
instrucción del usuario. No hubo commit, push, publicación ni cambios de servidor.

## Auditoría final posterior al refactor

Tres auditorías GPT-6 Luna con razonamiento alto revisaron Boomer, cierres y
regresiones de contrato; el agente principal integró y revisó las correcciones.
Se reprodujeron localmente cuatro fallos condicionados de control de flujo:
continuación de Pop sobre una vida nueva, reapertura por SafeArea tras cierre,
finalización sobre una sesión boss sustituida y construcción de Kill summary
sobre el buffer de una ronda nueva. Se añadieron vallas de vida/sesión/epoch,
cierre común idempotente y congelación de ambos snapshots antes de forwards.
No se alteran cantidades/scopes ni contratos públicos; el orden de notificación
normal se conserva. El live gate se cierra ahora antes de los callbacks externos.

La [auditoría final](l4d2-skills-final-audit.md) registra pruebas de VM, build y
paquete actualizados. El smoke SRCDS completo permanece pendiente. No se consultó
ni operó competitive_dev durante esta auditoría, ni se publicó nada.

## Pendiente MapEnd / Player-Stats — resuelto localmente

Por autorización explícita posterior se añadió cierre común antes de cleanup de
mapa, con limpieza diferida si MapEnd es reentrante. Se preservan exactamente una
finalización y el orden de las familias, sin nuevas firmas/keys ni unidad de
summary. Se protegen IDs conocidos y reinicio de instancia del proveedor. Tres
subagentes Luna de razonamiento alto auditaron contrato, integridad y pruebas;
el agente principal integró y revisó el resultado. El [informe](l4d2-skills-mapend-close.md)
detalla reproducción previa, 18 casos verdes, regresiones y aceptación SRCDS aún
pendiente. Solo cambiaron lifecycle/types de Skills; no se operó competitive_dev.

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
