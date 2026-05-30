# L4D2 Player Skills: Print Hierarchy

Esta tabla documenta qué announce gana cuando varios flujos pueden describir la misma jugada.

La regla general es:

- priorizar la jugada más específica o rica;
- suprimir el announce default si ya existe una skill que explique la secuencia;
- permitir dos announces solo cuando describen momentos distintos y no compiten por la misma resolución.

---

## Propiedades compartidas

Las propiedades visibles no son skills separadas. Modifican cómo se interpreta o imprime una skill base.

### `Perfecto`

Filosofía:

- representa ejecución limpia y completa;
- describe que el ejecutor resolvió la jugada sobre vida completa del infectado;
- no debe convivir con chip previo relevante ni con asistencia de otros survivors.

Reglas generales:

- daño completo en un solo disparo o hit relevante;
- vida completa del infectado al inicio de la ventana de la skill;
- solo existe en skills que modelan una ejecución técnica cerrada;
- no permite asistencia de otros survivors;
- no permite chip previo de otros survivors;
- el propio historial del ejecutor dentro de la misma jugada no convierte la skill en `Perfecto`.

Ejemplos:

- `HunterSkeet Perfecto`
- `Skeet-Melee Perfecto`
- `WitchCrown Perfecta`
- `ChargerLevel Perfecto`

### `Headshot`

Filosofía:

- representa que el disparo fatal relevante fue a la cabeza;
- no exige vida completa del infectado;
- puede convivir con chip previo o asistencia.

Reglas generales:

- el hit fatal relevante debe ser `headshot`;
- puede permitir asistencia de otros survivors;
- puede permitir chip previo;
- su efecto visible depende de la familia de la skill:
  - a veces cambia solo el wording;
  - a veces también sube el rating.

Ejemplos:

- `HunterSkeet Headshot`
- `JockeySkeet Headshot`
- `SmokerSelfClear Headshot`
- `*Kill Headshot`

### Relación entre propiedades

- `Perfecto` y `Headshot` no significan lo mismo.
- `Perfecto` habla de limpieza estructural de la jugada.
- `Headshot` habla de la forma del remate fatal.
- cuando ambas pueden coexistir, la familia de la skill decide cuál se imprime primero.
- en la práctica actual:
  - `HunterSkeet` ranged prioriza `Headshot` en el wording;
  - `Perfecto` sigue siendo una propiedad semántica separada.

### `Asistido`

Filosofía:

- la jugada principal sigue perteneciendo al ejecutor;
- otro survivor aportó daño o contexto válido dentro de la ventana relevante;
- no toda asistencia tiene la misma semántica: depende del `assist_scope`.

Reglas generales:

- se imprime al final del announce;
- no convierte por sí sola una kill default en skill;
- puede coexistir con `Headshot`;
- no puede coexistir con `Perfecto` cuando la skill exige ejecución limpia sin ayuda.

### `con {arma}`

Filosofía:

- agrega contexto de ejecución;
- no cambia la skill base;
- se imprime cuando el arma aporta valor interpretativo real.

Reglas generales:

- se usa sobre todo en skills donde el arma vuelve especial la jugada;
- no toda arma debe imprimirse siempre;
- en varias familias la shotgun queda implícita y armas especiales se vuelven explícitas.

Ejemplos:

- `Skeet ... con Military Sniper`
- `Skeet ... con Grenade Launcher`
- `TongueCut ... con Katana`

### `liberando a X`

Filosofía:

- documenta que la skill no solo resolvió al infectado, sino que además rescató a un survivor dominado;
- es una propiedad contextual de announce, no una nueva skill.

Reglas generales:

- aparece cuando una skill base absorbe un clear que de otro modo competiría con `SpecialPinClear`;
- evita doble announce cuando una misma jugada puede describirse como kill/skill y como rescate.

Ejemplos:

- `ChargerLevel ..., liberando a X`
- `SpecialPinClearKill`

### `con empujón`

Filosofía:

- distingue clears resueltos por shove frente a clears resueltos por daño o muerte del pinner;
- describe mecanismo, no autoría distinta.

Reglas generales:

- se usa cuando el shove es la causa directa de la liberación;
- puede convivir con announce posterior de muerte si esa muerte ocurre después y no compite por la misma resolución.

Ejemplos:

- `SelfClear-Shove`
- `SpecialPinClearShove`

### `de impacto`

Filosofía:

- distingue submecanismo letal dentro de una misma familia;
- hoy se usa en `ChargerInstaKill`.

Reglas generales:

- no crea una skill nueva;
- modifica la lectura del announce dentro de la misma jerarquía de `InstaKill`.

### `de disparo` / `de corte`

Filosofía:

- distinguen cómo se resolvió una interacción, especialmente en cortes de lengua del `Smoker`;
- son propiedades causales del announce.

Reglas generales:

- no crean una familia nueva;
- enriquecen `TongueCut` y `SpecialPinClear` del `Smoker`;
- se usan solo cuando el juego entrega contexto suficientemente confiable.

---

## Reglas globales

| Caso | Gana | Suprime | Nota |
| --- | --- | --- | --- |
| skill técnica vs `*Kill` default | skill técnica | `*Kill` | aplica a `Skeet`, `Level`, `Crown`, etc. |
| clear válido vs `*Kill` default del pinner | clear | `*Kill` | aplica a rescates por shove o por muerte del pinner |
| default boss summary vs skill boss | skill boss | summary | `WitchCrown` gana sobre `WitchDead` |
| summary post-mortem independiente | ambos | ninguno | `ChargerClawSummary` sale después del cierre del `Charger` |

---

## Smoker

| Escenario | Candidatos | Gana | Nota |
| --- | --- | --- | --- |
| la propia víctima corta la lengua antes del pin y no convierte la jugada | `TongueCut`, `SmokerKill` | `TongueCut` | `TongueCut` usa confirm timer de `0.3s` |
| la propia víctima se libera con shove durante arrastre o pin | `TongueCut`, `SelfClear-Shove` | `SelfClear-Shove` | tiene prioridad sobre `TongueCut` |
| la propia víctima mata al `Smoker` y se libera | `TongueCut`, `SelfClear`, `SmokerKill` | `SelfClear` | suprime `SmokerKill` |
| otro survivor rompe la lengua o shovea y salva a la víctima | `SpecialPinClear`, `SmokerKill` | `SpecialPinClear` | si no mata al `Smoker`, el kill puede no existir |
| otro survivor mata al `Smoker` mientras la víctima sigue agarrada/pinneada | `SpecialPinClear`, `SmokerKill` | `SpecialPinClear` | announce expandido como muerte del pinner |
| `SelfClear-Shove` y luego el `Smoker` muere más tarde | `SelfClear-Shove`, `SmokerKill` | ambos | no compiten; son momentos distintos |

---

## Hunter

| Escenario | Candidatos | Gana | Nota |
| --- | --- | --- | --- |
| muerte en ventana de pounce por shotgun/sniper/GL/magnum/melee | `HunterSkeet` o `HunterSkeetMelee`, `HunterKill` | `HunterSkeet*` | skill técnica prioritaria |
| shove en aire | `HunterDeadstop`, `HunterKill` | `HunterDeadstop` | no debe caer a kill |
| otro survivor mata al `Hunter` mientras está pinneando a alguien | `SpecialPinClear`, `HunterKill` | `SpecialPinClear` | kill de rescate suprime `HunterKill` |
| kill normal sin skill ni clear | `HunterKill` | `HunterKill` | fallback |

---

## Jockey

| Escenario | Candidatos | Gana | Nota |
| --- | --- | --- | --- |
| kill en aire con arma válida | `JockeySkeet` o `JockeySkeetMelee`, `JockeyKill` | `JockeySkeet*` | `JockeySkeet` no tiene variante perfecta |
| otro survivor mata al `Jockey` mientras está montando a alguien | `SpecialPinClear`, `JockeyKill` | `SpecialPinClear` | rescue by kill |
| kill normal sin skill ni clear | `JockeyKill` | `JockeyKill` | fallback |

---

## Charger

| Escenario | Candidatos | Gana | Nota |
| --- | --- | --- | --- |
| muerte del `Charger` cumple condiciones de `Level` | `ChargerLevel`, `SpecialPinClear`, `ChargerKill` | `ChargerLevel` | si había víctima pinneada, el announce agrega `liberando a X` |
| otro survivor mata al `Charger` durante carry/pummel, pero no califica como `Level` | `SpecialPinClear`, `ChargerKill` | `SpecialPinClear` | rescue by kill |
| kill normal del `Charger` sin `Level` ni clear | `ChargerKill` | `ChargerKill` | fallback |
| `Charger` conectó claws válidos durante su vida | `ChargerClawSummary` | coexistente | sale después del announce principal de muerte |

---

## Boomer

| Escenario | Candidatos | Gana | Nota |
| --- | --- | --- | --- |
| pop dentro de la ventana válida | `BoomerPop`, `BoomerKill` | `BoomerPop` | `BoomerKill` diferido se aborta |
| kill fuera de la ventana de pop | `BoomerKill` | `BoomerKill` | fallback |

---

## Witch

| Escenario | Candidatos | Gana | Nota |
| --- | --- | --- | --- |
| muerte clasifica como `WitchCrown` | `WitchCrown`, `WitchDead` | `WitchCrown` | incluye `Crown Perfecta` cuando corresponde |
| muerte normal sin crown | `WitchDead` | `WitchDead` | imprime summary de daño a la Witch |

---

## Casos coexistentes

Estos no se consideran conflicto y pueden imprimir dos announces:

| Secuencia | Announces |
| --- | --- |
| `SelfClear-Shove` y luego muerte posterior del `Smoker` | `SmokerSelfClearShove` + `SmokerKill` |
| cierre principal del `Charger` y luego resumen de claws | `ChargerLevel` o `ChargerKill` + `ChargerClawSummary` |

---

## Mantenimiento

Si se agrega una nueva skill o una nueva propiedad visible:

1. identificar contra qué default compite;
2. decidir si suprime, absorbe o convive;
3. reflejar la decisión aquí antes de tocar translations o API docs.
