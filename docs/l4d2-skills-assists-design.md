# L4D2 Player Skills: Assist Design

Este documento propone cómo modelar la asistencia en `l4d2_player_skills`
después de la separación entre:

- flujo de detección de `skills`
- flujo de tracking de `LifeKill`

El objetivo es permitir que skills como `HunterSkeet` también impriman
asistencia sin volver a acoplar la semántica de skill con la semántica de muerte.

---

## 1. Problema

Hoy existen dos lecturas válidas de contribución:

1. contribución a la muerte total de la vida del infectado;
2. contribución dentro de la ventana técnica de una skill.

Ejemplo:

- un survivor hace el disparo final perfecto a un `Hunter`;
- otro survivor había aportado daño durante la misma ventana de pounce;
- además puede existir chip previo fuera de esa ventana.

Si usamos un solo sistema de asistencia:

- `HunterKill` puede verse correcto;
- pero `HunterSkeet` termina heredando assists que pertenecen a la vida total y no
  a la ventana técnica del skeet.

Entonces, el mismo dato de asistencia no sirve igual para ambos flujos.

---

## 2. Principio de diseño

La asistencia debe separarse por dominio semántico:

- `LifeKill assists`
  - responden a: "quién contribuyó a la muerte total de esta vida"
- `Skill assists`
  - responden a: "quién contribuyó dentro de la ventana técnica de esta skill"

Esta separación es obligatoria, no una optimización futura.

Si el sistema mezcla ambos dominios:

- una `kill` termina subreportando el daño real de la vida;
- una `skill` rica termina heredando contribuciones ajenas a su ventana técnica;
- el payload deja de tener semántica estable para plugins externos.

La idea no es crear un sistema único y rígido para todas las skills.
La idea es:

- mantener trackers distintos por dominio;
- unificar solo la proyección al payload final del evento.

---

## 3. Modelo propuesto

### 3.1. LifeKill assists

Se mantienen como están hoy:

- agregan daño total de la vida;
- aplican ventana temporal de asistencia;
- ordenan contribuidores por daño;
- alimentan eventos como:
  - `SmokerKill`
  - `BoomerKill`
  - `HunterKill`
  - `SpitterKill`
  - `JockeyKill`
  - `ChargerKill`

Semántica:

- el killer principal es quien mata;
- los assists son quienes ayudaron a esa muerte de vida total.
- el daño y los assists de `LifeKill` deben seguir describiendo la vida completa
  del SI, aunque una skill rica de la misma secuencia use una lectura más
  estricta.

### 3.2. Skill assists

Se agregan como familia separada.

No representan la vida total del infectado.
Representan solo la contribución dentro de una ventana técnica definida por la
skill.

Ejemplos iniciales:

- `HunterSkeet`
  - ventana: `Hunter pouncing`
  - contribución: daño de shotgun/pounce-window relevante al skeet
- `BoomerPop`
  - ventana: secuencia válida del pop antes de que se invalide como kill genérica
  - contribución: daño contextual previo que participa del pop
- `SmokerSelfClear`
  - ventana: secuencia válida del self-clear del survivor pinneado
  - contribución: daño contextual previo sobre el `Smoker` antes del golpe final del self-clear

Posibles futuros:

- otras skills cooperativas que dependan de una ventana técnica real

Otro caso claro:

- `ChargerLevel`
  - ventana: `Charger charging`
  - contribución: daño contextual previo dentro de la lectura válida del level
  - el melee final sigue definiendo la skill principal
- `ChargerInstaKill`
  - ventana: secuencia de carry/impact que termina en muerte ambiental, fatal fall o slam
  - contribución: control o pin previo de otros SI sobre la víctima dentro de la misma jugada

---

## 4. Regla central

Las skills ricas no deben leer assists desde `LifeKill`.

Deben leerlos desde su propio tracker contextual.

Eso evita:

- mezclar chip previo con contribución técnica real;
- que un announce de `Skeet` muestre assists que no participaron del skeet;
- reintroducir acoplamiento entre los dos flujos.

Regla equivalente:

- `Kill` y `LifeKill assists` responden a "qué pasó en toda la vida".
- `Skill` y `Skill assists` responden a "qué pasó en la jugada técnica".
- ambos payloads pueden coexistir, pero no deben contaminarse entre sí.

---

## 5. Arquitectura recomendada

La arquitectura se separa en tres capas.

### 5.1. Tracking

Captura cruda por dominio.

Ejemplos:

- `LifeKillContributorTrack`
- `HunterPounceContributorTrack`
- futuro:
  - `JockeyLeapContributorTrack`
  - `ChargerChargeContributorTrack`

Responsabilidad:

- registrar daño, disparos, arma y tiempo en el dominio correcto

### 5.2. Selection

Decide qué contribuidores entran en un evento concreto.

Ejemplos:

- killer principal
- top assister
- top N assists
- solo contribuidores de la ventana válida

Responsabilidad:

- convertir tracking crudo en una vista semántica de contribución

### 5.3. Projection

Escribe la contribución seleccionada al `L4D2SkillEventData`.

Campos:

- `assister`
- `assisterDamage`
- `assisterShots`
- `assisterWeaponId`
- `assists[]`
- `assistDamage[]`
- `assistShots[]`
- `assistWeaponId[]`
- `assistsCount`

Responsabilidad:

- poblar el payload final de forma uniforme para announce, API y summary

---

## 6. Qué se comparte y qué no

### Compartir

Sí conviene compartir:

- structs neutrales de snapshot de contribuidores;
- helpers para ordenar y truncar assists;
- helpers para poblar `L4D2SkillEventData`;
- reglas de límites (`max assists`, survivor limit, etc.).

### No compartir

No conviene compartir:

- el tracker interno de `LifeKill` con el tracker de `Skill`;
- la lógica de expiración temporal de `LifeKill` con la ventana técnica de una skill;
- la noción de killer/assist de vida total con la noción de contribución contextual.

---

## 7. Caso HunterSkeet

`HunterSkeet` es el caso que justifica esta separación.

Necesidad:

- imprimir el killer principal del skeet;
- imprimir assists del skeet;
- ignorar daño fuera de la ventana relevante del pounce.

Lectura correcta:

- killer: quien cerró el skeet;
- assists: otros survivors con daño dentro de la ventana de pounce relevante;
- no incluir chip previo ajeno a la ventana técnica.

Entonces:

- `HunterKill` debe seguir leyendo `LifeKill`;
- `HunterSkeet` debe leer `HunterPounceContributorTrack`.

### 7.1. Restricción de PerfectSkeet

`PerfectSkeet` es un subconjunto más estricto de `HunterSkeet`.

Debe cumplir simultáneamente:

- el usuario hace `HunterSkeet`;
- lo hace de un solo disparo;
- el `Hunter` llega con vida completa;
- no existe contribución de otro survivor dentro de la ventana técnica del pounce.

Entonces:

- `PerfectSkeet` no puede tener assists;
- `PerfectSkeet` no puede ser `team skeet`;
- `PerfectSkeet` no debe construirse solo mirando `shots == 1`;
- también debe validarse que la contribución contextual ajena sea `0`.

Implicación práctica:

- si otro survivor aportó daño dentro de la ventana de pounce, la jugada puede
  seguir siendo `HunterSkeet`;
- pero ya no puede anunciarse como `PerfectSkeet`.

---

## 8. Fase 1 recomendada

La primera fase debe ser mínima y concreta.

### Alcance

- mantener intacto `LifeKill`
- diseñar `Skill assists` solo para `HunterSkeet`
- compartir únicamente la capa de `projection`

### Componentes sugeridos

- `DetectSkillAssistEntry`
- `DetectSkillAssistSnapshot`
- `Detect_BuildHunterPounceAssistSnapshot(...)`
- `Detect_WriteAssistSnapshotToEvent(eventIndex, snapshot, actorClient)`

### Beneficios

- se valida el diseño con el caso más importante;
- no se sobre-generaliza antes de tiempo;
- se evita tocar skills que todavía no necesitan assists contextuales.

---

## 9. Fase 2 opcional

Una vez estabilizado `HunterSkeet`, se puede evaluar si otras skills realmente
necesitan assists contextuales.

Criterio:

- solo si la skill tiene una ventana técnica clara;
- solo si el assist visible aporta información real al jugador;
- solo si no degrada claridad del announce.

### Caso BoomerPop

`BoomerPop` sí puede tener assists.

Razón:

- el `Boomer` puede recibir contribución contextual válida antes del pop final;
- esa contribución puede seguir perteneciendo a la misma secuencia técnica del pop;
- el announce puede beneficiarse de mostrar quién ayudó a cerrar la jugada.

Entonces:

- `BoomerPop` puede imprimir assists;
- esos assists deben venir de la ventana contextual del pop, no del `LifeKill` completo.

### Caso SmokerSelfClear

`SmokerSelfClear` también puede tener assists.

Razón:

- la secuencia técnica principal sigue siendo que la víctima se libera;
- pero otro survivor puede haber contribuido daño real al `Smoker` dentro de esa misma secuencia;
- esa contribución puede ser útil de mostrar sin convertir la jugada en otra skill.

Entonces:

- `SmokerSelfClear` puede imprimir assists;
- esos assists deben pertenecer a la ventana contextual del self-clear.

### Caso JockeySkeetMelee

`JockeySkeetMelee` no necesita assists.

Razón:

- la melee supera la vida máxima del `Jockey`;
- la jugada se define por un único hit letal dentro de la ventana de leap;
- una asistencia no aporta una lectura más útil del skill.

Entonces:

- `JockeySkeetMelee` debe anunciarse sin assists;
- no necesita `Skill assists` propios;
- sigue siendo una skill de autor único.

### Caso JockeyJumpStop

`JockeyJumpStop` tampoco necesita assists.

Razón:

- es una interacción de control puntual;
- la autoría del shove exitoso es clara;
- no existe una contribución cooperativa útil de imprimir para esta jugada.

Entonces:

- `JockeyJumpStop` debe anunciarse sin assists;
- no necesita `Skill assists` propios.

### Caso ChargerLevel

`ChargerLevel` debe separarse en dos lecturas semánticas:

- `PerfectLevel`
  - el usuario mata al `Charger` mientras carga;
  - con una sola melee;
  - a vida máxima;
  - sin asistencia.
- `Level`
  - el usuario mata al `Charger` mientras carga;
  - con melee;
  - puede contener asistencia contextual;
  - no exige vida máxima.

Entonces:

- `PerfectLevel` no puede tener assists;
- `Level` sí puede imprimir assists;
- la existencia de contribución ajena válida invalida `PerfectLevel`, pero no invalida `Level`.

### Caso ChargerInstaKill

`ChargerInstaKill` sí puede tener assists.

Razón:

- la jugada puede construirse sobre una secuencia cooperativa entre SI;
- otro infectado puede dejar al survivor sujeto, controlado o vulnerable antes
  del carry o del impacto final del `Charger`;
- esa contribución sí pertenece a la misma lectura táctica de la kill.

Entonces:

- `ChargerInstaKill` puede imprimir assists;
- esos assists deben representar apoyo contextual real a la secuencia del
  instakill;
- no deben salir de un `LifeKill` genérico del survivor, sino de la ventana de
  jugada relevante.

No asumir desde ya que toda skill necesita assists.

---

## 10. Decisión propuesta

La decisión recomendada es:

1. mantener dos familias de asistencia:
   - `LifeKill assists`
   - `Skill assists`
2. no compartir el tracking interno entre ambas;
3. compartir únicamente:
   - snapshots neutrales
   - selección común cuando aplique
   - proyección al `L4D2SkillEventData`
4. implementar primero el caso `HunterSkeet`

Esta opción preserva la semántica del sistema y reduce el riesgo de volver a
mezclar vida total con ventana técnica.

---

## 12. Impacto en API

El contrato público actual ya resolvió esa tensión moviendo el consumo a `KeyValues`
por familia.

Dirección vigente:

- `PlayerSkills_FillSkillEventKeyValues(...)`
- `PlayerSkills_FillKillEventKeyValues(...)`
- `PlayerSkills_FillBossEventKeyValues(...)`

Cada payload expone:

- `assists_count`
- bloque `assists`
- `assist_scope`

Sin volver a introducir getters escalares legacy.

---

## 13. Matriz actual

Estado operativo recomendado del sistema:

| Skill | Puede tener assists | Scope esperado | Variante perfect invalida assists | Estado |
|---|---|---|---|---|
| `HunterSkeet` | sí | `SkillWindow` | sí, `PerfectSkeet` | implementado |
| `HunterSkeetMelee` | no definido todavía | n/a | n/a | pendiente de decisión |
| `HunterDeadstop` | no | `None` | n/a | no requiere cambio |
| `BoomerPop` | sí | `SkillWindow` | n/a | implementado |
| `SmokerSelfClear` | sí | `SkillWindow` | n/a | implementado |
| `JockeyJumpStop` | no | `None` | n/a | no requiere cambio |
| `JockeySkeetMelee` | no | `None` | n/a | no requiere cambio |
| `ChargerLevel` | sí | `SkillWindow` | sí, `PerfectLevel` | implementado |
| `ChargerInstaKill` | sí | `SkillWindow` | n/a | implementado |

Lectura rápida:

- `LifeKill` genéricos siguen usando `LifeKill`.
- las skills listadas como `SkillWindow` no deben tomar assists desde el acumulado
  de vida total.
- las variantes `PerfectSkeet` y `PerfectLevel` requieren autoría exclusiva.

---

## 11. Resumen corto

- `LifeKill` y `Skill` no deben compartir el mismo tracker de asistencia.
- Sí deben compartir el mismo formato final de evento.
- `HunterSkeet` debe inaugurar el sistema de `Skill assists`.
- La abstracción correcta está en la proyección, no en fusionar los backends.
