# L4D2 Player Skills: Interpretation

Este documento fija la interpretación actual de `habilidad` dentro de `l4d2_player_skills`.

---

## 1. Pregunta base

Cuando una jugada especial ocurre, hay dos formas comunes de clasificarla:

1. Por el estado real e inmediato del target.
2. Por la capacidad real del golpe final respecto del target base o esperado.

`l4d2_player_skills` usa la segunda opción.

---

## 2. Regla del proyecto

Una habilidad principal se clasifica por la capacidad real del golpe final respecto del baseline del target, no solo por el estado degradado en el que llegó el target.

En otras palabras:

- el `skill type` describe la jugada principal;
- el daño previo, el startled, el carry previo o estados parecidos se guardan como contexto;
- un tipo distinto se usa cuando la jugada es mecánicamente distinta, no solo porque el target ya estaba alterado.

---

## 3. Qué significa "baseline del target"

Por `baseline del target` entendemos la referencia mecánica principal contra la que medimos la jugada.

Ejemplos:

- Hunter: la vida base relevante para decidir si un blast realmente califica como skeet.
- Witch: la vida base relevante para decidir si el blast final realmente califica como crown.
- Charger: la vida o condición base relevante para decidir si una melee kill realmente califica como level.

Esto no obliga a ignorar el daño previo. Obliga a no usar ese daño previo como única razón para cambiar de categoría una jugada.

---

## 4. Skill principal vs contexto

La semántica del sistema se separa así:

- `skill type`: qué jugada logró el jugador;
- `event fields`: en qué condiciones la logró.

Además, el tracking interno ya se separa en dos capas:

- `LifeKill`: daño y disparos totales de la vida completa del infectado;
- `skill window`: daño y disparos de la ventana técnica que define una jugada rica, como `HunterSkeet`, `JockeySkeetMelee` o `ChargerLevel`.

Regla práctica:

- las skills ricas leen su ventana técnica;
- las kills genéricas de SI leen el acumulado de vida total.

### 4.1. Separación obligatoria

Esta separación no es opcional.

`l4d2_player_skills` está obligado a mantener dos lecturas distintas del mismo
proceso:

- `LifeKill`
  - resume toda la vida del SI;
  - acumula todo el daño y todos los disparos que el sistema decide registrar
    para esa vida;
  - alimenta announces y payloads de:
    - `SmokerKill`
    - `BoomerKill`
    - `HunterKill`
    - `SpitterKill`
    - `JockeyKill`
    - `ChargerKill`
- `skill window`
  - resume solo la ventana técnica que define una jugada rica;
  - alimenta announces y payloads de:
    - `HunterSkeet`
    - `HunterSkeetMelee`
    - `BoomerPop`
    - `SmokerSelfClear`
    - `ChargerLevel`
    - `PerfectLevel`
    - `ChargerInstaKill`
    - `ChargerBowl`

Consecuencias:

- una `kill` simple debe resumir daño total de vida, no solo el tramo final;
- una `skill` rica no debe heredar automáticamente el daño o los assists de
  `LifeKill`;
- una `skill` rica puede coexistir con una lectura de `LifeKill`, pero no debe
  mezclar su semántica con ella;
- si una limpieza o filtro mejora la clasificación de una `skill`, no debe
  recortar por accidente el resumen total de una `kill`.

En corto:

- `Kill` = resumen total de vida.
- `Skill` = resumen técnico de la jugada.

Regla de daño actual:

- `*Kill`
  - usa daño efectivo/normalizado sobre la vida real del SI;
  - el tracking `raw` puede mantenerse internamente para debug y auditoría;
- skills técnicas con `damage_scope = SkillWindow`
  - usan daño efectivo/semántico de la jugada;
- el payload puede conservar contexto técnico adicional aunque el chat no lo
  imprima literalmente.

Ejemplos de contexto que deben vivir en el evento y no necesariamente en el enum:

- `chipDamage`
- `withShove`
- `wasCarried`
- `reportedHigh`
- `startled`
- `harasser`
- `perfect`
- `headshot`
- `sniper`
- `grenadeLauncher`

Nota de UX:

- `chipDamage` sigue siendo un dato tecnico valido;
- no obliga a que el announce visible use la palabra `chip`;
- en `HunterSkeet`, el chat actual prioriza `damage/shots`, `perfect` y `assists`;
- en `ChargerLevel`, el chat actual prioriza:
  - `Level Perfecto`
  - `Level`
  - `Level (dmg/shots)` si hubo daño previo propio del actor
  - `Level ..., asistido por ...` si hubo contribución ajena

### 4.2. Naming visual de announces

El nombre visible de chat debe separar:

- habilidad base
- propiedades
- contexto

Reglas:

- las habilidades compuestas usan guion
  - `Skeet-Melee`
  - `Skeet-Rock`
- las propiedades no forman parte del nombre base
  - `Skeet Perfecto`
  - `Skeet Headshot`
  - `Level Perfecto`
  - `SelfClear Headshot`
- el nombre interno del enum no debe imprimirse directo en chat
  - evitar `PerfectSkeet`, `PerfectLevel`, `SkeetMelee`, `RockSkeet`
- el nombre base va primero y el modificador técnico después
  - `Skeet-Rock`, no `Rock-Skeet`
- el contexto visible debe ir al final del announce
  - `(.../...)`
  - `asistido por ...`

---

## 5. Caso Hunter

Si un Hunter está pouncing y recibe un blast que lo habría matado aunque estuviera a vida completa, la jugada se interpreta como `HunterSkeet`, aunque el Hunter real estuviera chipeado.

Entonces:

- `HunterSkeet` sigue siendo la habilidad principal;
- `chipDamage` y `perfect` describen el contexto;
- `headshot`, `sniper` o `grenadeLauncher` describen la variante técnica del kill shot sin obligar a crear otro evento base;
- si una kill en pounce no califica como `HunterSkeet` ni siquiera contra baseline completo, no debe emitirse como skill principal separada.

Regla visual actual para ranged skeets:

- `Headshot` y `Perfecto` se tratan como propiedades;
- si ambas aplican, `Headshot` tiene prioridad visual;
- el arma va al final como contexto:
  - `Skeet Headshot ... con Military Sniper`
  - `Skeet Perfecto ... con Grenade Launcher`

Esto evita degradar automáticamente una jugada fuerte solo porque otro daño previo ya redujo la vida del Hunter.

### 5.1. Restricción de PerfectSkeet

`PerfectSkeet` requiere autoría exclusiva dentro de la ventana técnica del pounce.

Entonces:

- debe ser `HunterSkeet`;
- debe resolverse de un solo disparo;
- el `Hunter` debe llegar con vida completa;
- no debe existir contribución de otro survivor dentro de la ventana de pounce relevante.

Por lo tanto:

- `PerfectSkeet` no puede tener assists;
- si hubo contribución contextual de otro survivor, la jugada puede seguir siendo
  `HunterSkeet`, pero ya no `PerfectSkeet`.

### 5.2. Variantes mecánicamente distintas

Cuando la jugada cambia de forma mecánica real, sí se justifica una skill separada.

Ejemplo actual:

- `HunterSkeetMelee` vive como skill propia, porque matar un Hunter en pounce con melee es una jugada distinta al `HunterSkeet` de disparo.
- `HunterDeadstop` vive como skill propia, porque cortar un pounce con shove es una jugada mecánicamente distinta a matar al Hunter.
- `HunterHighPounce` vive como skill propia, porque el valor de la jugada está en la geometría del ataque y no solo en el daño final.
- `JockeyHighPounce` vive como skill propia por la misma razón.
- `BoomerVomitLanded` vive como skill propia, porque mide el resultado efectivo del vomit stream del Boomer.
- `ChargerInstaKill` vive como skill propia, porque la jugada se define por desplazar al survivor hacia una muerte ambiental o de caída.
- `ChargerDeathSetup` vive como skill propia, porque representa el resultado no letal pero determinante del Charger cuando deja a un survivor colgando o incapacitado.
- `SpecialPinClear` vive como skill propia, porque salvar a un teammate de un pin es una interacción cooperativa distinta al self-clear o a matar al infectado fuera de control.
- `BunnyHopStreak` vive como skill propia, porque la jugada no depende de daño ni de un infectado especial, sino de una secuencia técnica de movimiento con continuidad medible.

En ese caso, el contexto adicional sigue siendo útil:

- `perfect` marca que el Hunter murió en pounce y con vida completa;
- `headshot` existe como metadata cuando aplica a la jugada detectada.
- `reportedHigh` marca que el deadstop ocurrió sobre un high pounce detectado por el juego.

## 5.3. Caso Smoker SelfClear

`SmokerSelfClear` sigue siendo una sola habilidad base:

- `SelfClear`

Sus variantes visibles viven como propiedades o forma mecánica:

- `SelfClear Headshot`
  - propiedad de ejecución sobre la ruta kill;
- `SelfClear-Shove`
  - variante mecánica distinta dentro del mismo evento base `SmokerSelfClear`.

Entonces:

- `TongueCut` sigue siendo una skill separada;
- `SelfClear` cubre la liberación propia cuando el `Smoker` ya llegó;
- `Headshot` no crea otro skill type;
- `Shove` se expresa como naming visual compuesto.

---

## 6. Caso Witch

Si una Witch muere sin crown, el evento principal se interpreta como `WitchDead`.  
Si la muerte clasifica como crown, la skill real es `WitchCrown`.  
Si además el blast final supera el baseline de crown, esa condición vive como contexto del evento y del announce, no como skill type aparte.

Eso sigue siendo cierto aunque:

- la Witch ya estuviera chipeada;
- la Witch ya estuviera startled;
- la Witch ya hubiera fijado target o estuviera corriendo al survivor.

Entonces:

- el hecho principal es que la `Witch` murió;
- si el kill final fue un blast de shotgun del killer, eso debe marcarse como contexto `crown`;
- el startled o el chip se conservan como metadata;
- no se debe crear una skill principal aparte solo para ese caso.

Regla de daño:

- el resumen de boss de `Witch` usa daño efectivo acumulado sobre su vida real;
- `WitchCrown` expone daño efectivo del killer en `damage`;
- `shots` en `WitchCrown` representa los tiros totales del killer sobre esa `Witch`;
- los contributors previos de otros survivors se exponen como assists con
  `damage/shots` acumulado;
- el `raw` del blast final puede conservarse internamente, pero no debe filtrarse
  como daño visible del evento.

---

## 6.1. Caso Charger

Si una melee kill sobre un Charger en charge habría calificado como `Level` contra el baseline del Charger, la jugada se interpreta como `ChargerLevel`, aunque el Charger real ya estuviera chipeado.

Entonces:

- `ChargerLevel` sigue siendo la habilidad principal;
- el daño previo debe conservarse como contexto;
- no se debe crear una skill principal aparte solo porque el Charger ya había recibido chip.

### 6.1.1. Restricción de PerfectLevel

`PerfectLevel` requiere autoría exclusiva sobre el kill técnico del `Charger`.

Entonces:

- debe ser `ChargerLevel`;
- debe resolverse con una sola melee;
- el `Charger` debe llegar con vida completa;
- no debe existir contribución válida de otro survivor en la lectura contextual de la jugada.

Por lo tanto:

- `PerfectLevel` no puede tener assists;
- si hubo contribución contextual ajena, la jugada puede seguir siendo `Level`,
  pero ya no `PerfectLevel`.

Consecuencia de producto:

- `PerfectLevel` ocupa el lugar del `Level` limpio;
- `Level` se interpreta como la variante no perfect, es decir, con daño previo propio,
  asistencia previa o cualquier otra condición que invalide el perfect.

---

## 6.2. Caso Jockey

Las jugadas nuevas del `Jockey` viven en una ventana artesanal de leap, no en una lectura directa de un evento único del juego.

Entonces:

- `JockeyJumpStop` representa un shove exitoso mientras el `Jockey` seguía en leap y todavía no montaba;
- `JockeySkeetMelee` representa una melee kill mientras el `Jockey` seguía en esa misma ventana;
- `JockeyKill` sigue siendo la muerte genérica de la vida total del `Jockey`, y no debe reemplazar a una de esas dos jugadas más ricas.

Esto implica:

- la ventana de leap debe usarse como contexto para clasificar la jugada;
- la kill genérica del `Jockey` debe seguir existiendo como fallback;
- pero el announce visible debe preferir `JockeyJumpStop` o `JockeySkeetMelee` cuando correspondan.

Restricción adicional:

- `JockeySkeetMelee` no necesita assists, porque la melee ya supera la vida máxima del `Jockey` y la jugada queda definida por un solo hit letal.
- `JockeyJumpStop` tampoco necesita assists, porque la autoría del shove exitoso es unívoca.

---

## 7. Legacy Categories

Las categorías heredadas se reducen cuando solo describen contexto y no una jugada distinta.

Ejemplos:

- variantes tipo `Hurt` se expresan mejor como contexto;
- variantes tipo `Chip` o `Hurt` se expresan primero como flags o metadata.

---

## 8. Design Rule

Cuando aparezca una duda sobre una jugada, la pregunta guía es:

> ¿el golpe final demuestra la habilidad principal por sí mismo respecto del baseline del target?

Si la respuesta es sí:

- conservar la skill principal;
- guardar el resto como contexto.

Si la respuesta es no:

- usar otra skill principal;
- o tratarlo como kill/evento no especial.

---

## 9. Current Use

Esta interpretación se usa como referencia para:

- diseño de nuevas detecciones;
- organización interna del detector;
- API pública;
- y copy visible al jugador.

---

## 10. Announce Precedence

Además de interpretar qué `skill type` representa una jugada, el proyecto necesita limitar announces redundantes cuando una misma secuencia podría producir:

- una `skill` rica o principal;
- una `kill` simple de SI;
- o un resumen de sesión o boss.

La regla general es:

- si una secuencia ya produjo una jugada más rica y específica, no se debe anunciar además la variante genérica;
- el evento puede seguir existiendo como dato interno o de API, pero el announce visible debe preferir una sola lectura principal de la jugada.

### 10.1. Orden de precedencia

El orden actual de precedencia es:

1. `skill` rica o principal
2. `kill` simple resumida
3. resumen de sesión o boss

En otras palabras:

- una `skill` rica gana sobre una `kill` simple;
- una `kill` rica de boss gana sobre el resumen general del mismo lifecycle;
- un resumen de sesión solo debe salir cuando la secuencia no quedó ya representada por un announce más fuerte del mismo lifecycle.

### 10.2. Matriz actual

| Secuencia | Announce permitido | Announce suprimido |
|---|---|---|
| `HunterSkeet` | `HunterSkeet` | `HunterKill` |
| `HunterSkeetMelee` | `HunterSkeetMelee` | `HunterKill` |
| `JockeyJumpStop` | `JockeyJumpStop` | `JockeyKill` |
| `JockeySkeetMelee` | `JockeySkeetMelee` | `JockeyKill` |
| `SmokerSelfClear` con kill | `SmokerSelfClear` | `SmokerKill` |
| `BoomerPop` | `BoomerPop` | `BoomerKill` |
| `ChargerLevel` | `ChargerLevel` | `ChargerKill` |
| `WitchIncap` con resumen de vida restante | resumen de `Witch` en incap | `WitchDead` o resumen posterior de la misma sesión |
| `WitchCrown` | `WitchCrown` | resumen completo de daño de la misma `Witch` |

### 10.3. Casos que sí pueden coexistir

No toda secuencia múltiple implica duplicado.

Ejemplos aceptables:

- `BoomerVomitLanded` no representa la misma jugada que `BoomerKill`
  - por eso puede coexistir con la muerte del Boomer si no hubo `BoomerPop`
- `TankRockHit` o `TankRockSkeet` no representan lo mismo que el resumen final de daño del `Tank`
  - por eso pueden coexistir con el cierre de sesión del boss
- `SpecialPinClear` no representa lo mismo que una simple kill del infectado fuera de control
  - pero si el mismo kill ya quedó representado por una jugada más específica, la versión genérica no debe volver a imprimirse

### 10.4. Regla de implementación

Cuando se agregue una nueva detección, se debe responder primero:

> ¿esta jugada describe mejor la misma secuencia que otra salida ya existente?

Si la respuesta es sí:

- definir precedencia explícita;
- elegir qué announce sobrevive;
- suprimir el announce genérico o resumido.

Si la respuesta es no:

- ambas salidas pueden coexistir;
- pero deben describir capas distintas del gameplay y no repetir la misma lectura del evento.

### 10.5. Skills que sí admiten assists contextuales

No toda skill necesita assists.

Hoy, las que sí pueden admitirlos de forma útil son:

- `HunterSkeet`
- `BoomerPop`
- `SmokerSelfClear`
- `ChargerLevel`
- `ChargerInstaKill`

Regla:

- esos assists deben venir de la ventana técnica de la skill;
- no del acumulado total de `LifeKill`.
