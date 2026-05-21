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

Ejemplos de contexto que deben vivir en el evento y no necesariamente en el enum:

- `chipDamage`
- `wouldQualifyAtBaseline`
- `withShove`
- `wasCarried`
- `reportedHigh`
- `startled`
- `harasser`
- `perfect`
- `headshot`
- `sniper`
- `grenadeLauncher`

---

## 5. Caso Hunter

Si un Hunter está pouncing y recibe un blast que lo habría matado aunque estuviera a vida completa, la jugada se interpreta como `HunterSkeet`, aunque el Hunter real estuviera chipeado.

Entonces:

- `HunterSkeet` sigue siendo la habilidad principal;
- `chipDamage` o `wouldQualifyAtBaseline` describen el contexto;
- `headshot`, `sniper` o `grenadeLauncher` describen la variante técnica del kill shot sin obligar a crear otro evento base;
- si una kill en pounce no califica como `HunterSkeet` ni siquiera contra baseline completo, no debe emitirse como skill principal separada.

Esto evita degradar automáticamente una jugada fuerte solo porque otro daño previo ya redujo la vida del Hunter.

### 5.1. Variantes mecánicamente distintas

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

---

## 6. Caso Witch

Si una Witch muere, el evento principal se interpreta como `WitchDead`.  
Si además el blast final supera el baseline de crown, esa condición vive como contexto del evento y del announce, no como skill type aparte.

Eso sigue siendo cierto aunque:

- la Witch ya estuviera chipeada;
- la Witch ya estuviera startled;
- la Witch ya hubiera fijado target o estuviera corriendo al survivor.

Entonces:

- el hecho principal es que la `Witch` murió;
- si hubo un blast de crown suficiente, eso debe marcarse como propiedad del evento;
- el startled o el chip se conservan como metadata;
- no se debe crear una skill principal aparte solo para ese caso.

---

## 6.1. Caso Charger

Si una melee kill sobre un Charger en charge habría calificado como `Level` contra el baseline del Charger, la jugada se interpreta como `ChargerLevel`, aunque el Charger real ya estuviera chipeado.

Entonces:

- `ChargerLevel` sigue siendo la habilidad principal;
- el daño previo debe conservarse como contexto;
- no se debe crear una skill principal aparte solo porque el Charger ya había recibido chip.

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
- refactor de enums;
- API pública;
- y copy visible al jugador.
