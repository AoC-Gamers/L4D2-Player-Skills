# L4D2 Player Skills: `sm_skills` y `sm_skills_stats`

Este documento define el comportamiento esperado de `sm_skills` y `sm_skills_stats`, su modelo de salida y las reglas de render para `Survivor Skills` e `Infected Skills`.

## Objetivo

`sm_skills` y `sm_skills_stats` deben dejar de ser tablas comparativas centradas en abreviaturas y pasar a ser vistas legibles por equipo:

- si el usuario pertenece a `Survivor`, imprime `Survivor Skills`
- si el usuario pertenece a `Infected`, imprime `Infected Skills`
- si el usuario usa un argumento de otro equipo o el argumento `all`, imprime ambas tablas

La salida sigue siendo:

- resumen corto en chat
- tabla detallada en consola

Diferencia de responsabilidad:

- `sm_skills`
  - resumen corto del actor objetivo
  - tabla comparativa compacta por familias
- `sm_skills_stats`
  - tabla comparativa más analítica
  - puede incluir métricas derivadas como `Perfect`, `Targets` y `Best`

## Estado Actual

Hoy `sm_skills`:

- requiere estar in-game
- acepta un target opcional
- imprime un resumen de skills del `actor` objetivo en chat
- renderiza una tabla comparativa en consola usando el equipo del `target`
- usa abreviaturas de métricas:
  - survivor: `Sk`, `SM`, `DS`, `BP`, `Lv`, `Cr`, `TC`, `SC`, `RS`
  - infected: `HP`, `JP`, `BV`, `IK`, `DS`, `CA`, `RH`
- renderiza filas por jugador, no filas por métrica
- en infected puede mezclar nombres efímeros como `Smoker (lechuga)` o `Hunter (IA)`

Ese formato actual funciona, pero tiene dos problemas de producto:

- la tabla de infected depende de personajes efímeros
- la lectura por abreviaturas y filas por jugador es menos clara que una tabla por métricas

## Comportamiento Objetivo

### Uso del comando

`sm_skills`

- detecta el equipo del `client`
- imprime la tabla correspondiente a su equipo

`sm_skills <target>`

- si `target` pertenece al mismo equipo que `client`, imprime solo la tabla de ese equipo
- si `target` pertenece a un equipo distinto, imprime ambas tablas

`sm_skills all`

- imprime ambas tablas sin depender del equipo del usuario

`sm_skills_stats`

- sin argumento:
  - usa el equipo actual del cliente
  - si el cliente está en un team no comparable, imprime ambas tablas

`sm_skills_stats surv`

- imprime la tabla survivor

`sm_skills_stats infect`

- imprime la tabla infected

`sm_skills_stats all`

- imprime ambas tablas

### Regla de contexto

El comando debe tomar el equipo real del usuario o del target y no un contexto forzado por personaje.

- `Survivor`:
  - tabla `Survivor Skills`
- `Infected`:
  - tabla `Infected Skills`
- otros equipos o estados no comparables:
  - siguen usando el mensaje actual de indisponibilidad

## Modelo de Tablas

Las tablas deben invertir el renderer actual:

- columnas = actores visibles
- filas = métricas

No se muestran abreviaturas como headers principales. Se usan nombres completos.

### Regla de nombres

#### Survivor

- usar solo nombre del jugador
- no usar nombre del personaje survivor como identidad principal

Ejemplo:

- `lechuga`
- `Zoey`
- `Francis`

#### Infected

- usar solo nombre del jugador humano
- no usar el nombre del personaje infectado como columna principal
- cualquier infectado bot se resume en una sola columna `IA`

Ejemplo:

- `lechuga`
- `Test-Subject`
- `IA`

### Regla para IA

En tablas infected:

- ningún bot se imprime individualmente
- todas las contribuciones bot se agregan en una sola columna `IA`

Esto aplica a:

- `Hunter`
- `Smoker`
- `Boomer`
- `Spitter`
- `Jockey`
- `Charger`
- `Tank`

siempre que sean controlados por IA al momento del evento.

## Survivor Skills

La tabla survivor no debe mapear una phrase por columna. Debe agrupar por familia útil.

### Families

#### Skeets

Incluye:

- `HunterSkeet`
  - variantes de shotgun
  - variantes con arma visible como:
    - `Skeet ... con Military Sniper`
    - `Skeet ... con AWP`
    - `Skeet ... con Scout`
    - `Skeet ... con Magnum`
    - `Skeet ... con Grenade Launcher`
  - variantes con propiedad:
    - `Skeet Headshot`
    - `Skeet Perfecto`

#### SkeetPerfect

Incluye:

- eventos `HunterSkeet` cuyo flag `perfect = true`
- representa skeets perfectos de autoría exclusiva

#### SkeetMelees

Incluye:

- `SkeetMelee`
- `SkeetMeleePerfect`
- `JockeySkeetMelee`

#### Deadstops

Incluye:

- `HunterDeadstop`

#### JockeyJumpStops

Incluye:

- `JockeyJumpStop`

#### SpecialClears

Incluye:

- `SpecialPinClear`
- `SpecialPinClearShove`

#### TongueCuts

Incluye:

- `SmokerTongueCut`

#### SmokerClears

Incluye:

- `SmokerSelfClear`
  - `SelfClear`
  - `SelfClear Headshot`
  - `SelfClear-Shove`

#### BoomerPops

Incluye:

- `BoomerPopBot`
- `BoomerPopPlayer`

#### ChargerLevels

Incluye:

- eventos `ChargerLevel` cuyo flag `perfect = false`
- representa solo `Level` no perfect

#### LevelPerfect

Incluye:

- eventos `ChargerLevel` cuyo flag `perfect = true`

#### CarAlarms

Incluye:

- `CarAlarm*`

#### BunnyHopStreaks

Incluye:

- `BunnyHopStreakSingle`
- `BunnyHopStreakMulti`

#### WitchCrowns

Incluye:

- `WitchCrown`

#### TankRockSkeets

Incluye:

- `TankRockSkeet`

#### SpecialInfectedKills

Incluye:

- `SpecialInfectedKill`
- `SpecialInfectedKillAssist`
- `SpecialInfectedKillAssistMulti`
- `SpecialInfectedKillLead`
- `SpecialInfectedKillAssistHead`
- `SpecialInfectedKillAssistTail`

### Ejemplo `sm_skills`

```text
|------------------------------------------------------------------------------------------------------------|
| Skills -- Survivors -- Round 1                                                                             |
|------------------------------------------------------------------------------------------------------------|
| Metrica              | lechuga | Zoey | Francis | Louis                                                   |
|------------------------------------------------------------------------------------------------------------|
| Skeets               |       2 |    1 |       0 |     0                                                   |
| SkeetMelees          |       1 |    0 |       0 |     0                                                   |
| Deadstops            |       0 |    0 |       1 |     0                                                   |
| JockeyJumpStops      |       0 |    1 |       0 |     0                                                   |
| SpecialClears        |       1 |    2 |       0 |     1                                                   |
| TongueCuts           |       1 |    0 |       0 |     0                                                   |
| SmokerClears         |       0 |    1 |       0 |     0                                                   |
| BoomerPops           |       1 |    0 |       0 |     0                                                   |
| ChargerLevels        |       0 |    0 |       1 |     0                                                   |
| CarAlarms            |       0 |    0 |       0 |     0                                                   |
| BunnyHopStreaks      |       0 |    0 |       0 |     0                                                   |
| WitchCrowns          |       1 |    0 |       0 |     0                                                   |
| TankRockSkeets       |       0 |    0 |       0 |     0                                                   |
| SpecialInfectedKills |       4 |    2 |       1 |     3                                                   |
|------------------------------------------------------------------------------------------------------------|
```

## Infected Skills

La tabla infected también agrupa por familia útil.

### Families

#### HunterPounces

Incluye:

- `HunterHighPounce`

#### HunterPounceBest

Incluye:

- mejor altura (`height`) alcanzada por `HunterHighPounce`

#### JockeyPounces

Incluye:

- `JockeyHighLeap`

#### JockeyPounceBest

Incluye:

- mejor altura (`height`) alcanzada por `JockeyHighLeap`

#### BoomerVomit

Incluye:

- `BoomerVomitLandedSingle`
- `BoomerVomitLandedMulti`

`BoomerVomit` cuenta eventos.

#### BoomerVomitTargets

Incluye:

- suma de `amount` de todos los eventos `BoomerVomitLanded`

#### BoomerVomitPerfect

Incluye:

- eventos `BoomerVomitLanded` cuyo flag `perfect = true`
- `perfect` significa `amount >= survivor_limit`

#### BoomerVomitBest

Incluye:

- mejor `amount` alcanzado por un `BoomerVomitLanded`

#### ChargerInstaKills

Incluye:

- `ChargerInstaKill`

La salida visible puede variar por propiedades:

- `Impacto`
- `Caida`
- `Estrellado`
- `Altura`

pero la skill contada sigue siendo una sola: `ChargerInstaKill`.

#### ChargerDeathSetups

Incluye:

- `ChargerDeathSetup`

#### ChargerLedgeHangs

Incluye:

- `ChargerLedgeHang`

#### TankRockHits

Incluye:

- `TankRockHit`

#### ChargerBowls

Incluye:

- `ChargerBowl`

#### ChargerBowlTargets

Incluye:

- suma de `amount` de todos los eventos `ChargerBowl`

#### ChargerBowlBest

Incluye:

- mejor `amount` alcanzado por un `ChargerBowl`

### Ejemplo `sm_skills`

```text
|------------------------------------------------------------------------------------------------------------|
| Skills -- Infected -- Round 1                                                                              |
|------------------------------------------------------------------------------------------------------------|
| Metrica              | lechuga | Test-Subject | IA                                                        |
|------------------------------------------------------------------------------------------------------------|
| HunterPounces        |       0 |            1 | 1                                                         |
| JockeyPounces        |       0 |            0 | 0                                                         |
| BoomerVomit          |       0 |            0 | 1                                                         |
| ChargerInstaKills    |       0 |            0 | 1                                                         |
| ChargerDeathSetups   |       0 |            0 | 1                                                         |
| TankRockHits         |       0 |            0 | 1                                                         |
|------------------------------------------------------------------------------------------------------------|
```

### Ejemplo `sm_skills_stats`

```text
|------------------------------------------------------------------------------------------------------------|
| Skills -- Infected -- Round 1                                                                              |
|------------------------------------------------------------------------------------------------------------|
| Metrica              | lechuga | Test-Subject | IA                                                        |
|------------------------------------------------------------------------------------------------------------|
| HunterPounces        |       1 |            0 | 1                                                         |
| HunterPounceBest     |     814 |            0 | 633                                                       |
| JockeyPounces        |       0 |            1 | 0                                                         |
| JockeyPounceBest     |       0 |          538 | 0                                                         |
| BoomerVomit          |       2 |            0 | 1                                                         |
| BoomerVomitTargets   |       7 |            0 | 4                                                         |
| BoomerVomitPerfect   |       1 |            0 | 1                                                         |
| BoomerVomitBest      |       4 |            0 | 4                                                         |
| ChargerInstaKills    |       0 |            0 | 1                                                         |
| ChargerDeathSetups   |       0 |            0 | 1                                                         |
| TankRockHits         |       0 |            0 | 1                                                         |
| ChargerBowls         |       1 |            0 | 0                                                         |
| ChargerBowlTargets   |       3 |            0 | 0                                                         |
| ChargerBowlBest      |       3 |            0 | 0                                                         |
|------------------------------------------------------------------------------------------------------------|
```

## Reglas de Render

### Orden de columnas

- primero jugadores humanos
- `IA` siempre al final

### Orden de filas

Orden recomendado:

#### Survivor

1. `Skeets`
2. `SkeetPerfect` en `sm_skills_stats`
3. `SkeetMelees`
4. `Deadstops`
5. `JockeyJumpStops`
6. `SpecialClears`
7. `TongueCuts`
8. `SmokerClears`
9. `BoomerPops`
10. `ChargerLevels`
11. `LevelPerfect` en `sm_skills_stats`
12. `CarAlarms`
13. `BunnyHopStreaks`
14. `WitchCrowns`
15. `TankRockSkeets`
16. `SpecialInfectedKills`

#### Infected

1. `HunterPounces`
2. `HunterPounceBest` en `sm_skills_stats`
3. `JockeyPounces`
4. `JockeyPounceBest` en `sm_skills_stats`
5. `BoomerVomit`
6. `BoomerVomitTargets` en `sm_skills_stats`
7. `BoomerVomitPerfect` en `sm_skills_stats`
8. `BoomerVomitBest` en `sm_skills_stats`
9. `ChargerInstaKills`
10. `ChargerDeathSetups`
11. `TankRockHits`
12. `ChargerBowls`
13. `ChargerBowlTargets` en `sm_skills_stats`
14. `ChargerBowlBest` en `sm_skills_stats`

### Filtros por modo

Las filas deben respetar la lógica actual de `Skills_IsSkillTypeEnabledInCurrentMode(...)`.

Eso implica:

- si una familia no aplica al modo activo, no se imprime
- si ninguna métrica aplicable existe, se mantiene el flujo actual de unavailable/empty

## Resumen de Chat

El resumen corto de chat se mantiene orientado al actor objetivo.

No cambia con esta limpieza interna.

La limpieza interna solo afecta la tabla detallada de consola.

## Impacto en Código

La implementación requiere cambiar principalmente:

- `Command_Skills(...)`
- `Announce_RenderSkillsTable(...)`

### Ajustes en `Command_Skills(...)`

Debe dejar de asumir un único `target` como driver de toda la tabla.

Necesita resolver:

- `scope = survivor`
- `scope = infected`
- `scope = all`

según:

- equipo del `client`
- equipo del `target`, si existe
- argumento literal `all`

### Ajustes en `Announce_RenderSkillsTable(...)`

Debe dejar de:

- construir tabla por filas de jugador
- usar abreviaturas como columnas visibles
- imprimir infectados IA por personaje

Debe pasar a:

- construir una o dos tablas por scope
- agregar columnas dinámicas por jugador humano
- agregar una columna `IA` si existe contribución bot
- renderizar filas por familia de skill

## Notas de Semantica

- `BoomerVomitLanded` siempre debe registrarse como evento válido cuando la ventana de vómito conectó al menos a un survivor.
- `l4d2_player_skills_boomer_vomit_min_targets` solo controla el `announce`, no el tracking.
- `BoomerVomitPerfect` se define por `amount >= survivor_limit`.
- `BoomerVomitTargets` y `ChargerBowlTargets` son sumas de `amount`.
- `HunterPounceBest`, `JockeyPounceBest` y otros `Best` usan el máximo observado, no el promedio.

## Alcance

Este documento redefine la salida de consola de `sm_skills` y `sm_skills_stats`.

No cambia:

- announce de skills en chat
- payload de la API
- detección de skills
- reglas de precedencia entre skill rica y kill simple
