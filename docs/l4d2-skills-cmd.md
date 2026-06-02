# L4D2 Skills Commands

Este documento resume el comportamiento visible de los comandos principales de
`L4D2-Player-Skills`.

## Commands

### `sm_skills`

Uso:

- `sm_skills`
- `sm_skills <player>`
- `sm_skills all`

Comportamiento:

- imprime un resumen corto en chat para el actor objetivo cuando aplica
- imprime una tabla comparativa en consola
- si el objetivo pertenece a otro equipo, puede imprimir ambas tablas

### `sm_skills_stats`

Uso:

- `sm_skills_stats`
- `sm_skills_stats surv`
- `sm_skills_stats infect`
- `sm_skills_stats all`

Comportamiento:

- imprime tablas comparativas en consola por equipo
- hoy reutiliza el mismo renderer base de `sm_skills`
- la diferencia principal es el alcance explícito del comando

## Table Model

Las tablas siguen estas reglas:

- columnas:
  - jugadores humanos del equipo
  - `IA` al final si existe contribución bot
- filas:
  - métricas agregadas por familia
- layout:
  - tabla única por equipo
  - filas agrupadas por bloque semántico
  - separador completo entre grupos con datos
  - grupos vacíos no se imprimen

Contexto visible:

- header de equipo
- `Mode`
- `Context` cuando aplica a `Versus`

## Naming Rules

### Survivor table

- usa nombre del jugador como columna principal
- no usa personaje survivor como identidad primaria

### Infected table

- usa nombre del jugador humano como columna principal
- los bots se agregan en una sola columna `IA`

## Metric Families

Las tablas agrupan skills por familias legibles.

### Survivor

- `Hunter`
  - `Skeets`
  - `SkeetPerfect`
  - `SkeetMelees`
  - `Deadstops`
- `Jockey`
  - `JockeyJumpStops`
  - `JockeySkeetMelees`
  - `JockeySkeets`
- `Smoker`
  - `TongueCuts`
  - `SmokerClears`
  - `SpecialClears`
- `Boomer`
  - `BoomerPops`
- `Charger`
  - `ChargerLevels`
  - `LevelPerfect`
- `Bosses`
  - `WitchCrowns`
  - `TankRockSkeets`
- `Misc`
  - `BunnyHopStreaks`
  - `CarAlarms`
  - `SpecialInfectedKills`

### Infected

- `Hunter`
  - `HunterPounces`
  - `HunterPounceBest`
- `Jockey`
  - `JockeyPounces`
  - `JockeyPounceBest`
  - `JockeyLedgeHangs`
- `Smoker`
  - `SmokerLedgeHangs`
- `Boomer`
  - `BoomerVomit`
  - `BoomerVomitTargets`
  - `BoomerVomitPerfect`
  - `BoomerVomitBest`
- `Charger`
  - `ChargerInstaKills`
  - `ChargerDeathSetups`
  - `ChargerLedgeHangs`
  - `ChargerBowls`
  - `ChargerBowlTargets`
  - `ChargerBowlBest`
- `Tank`
  - `TankRockHits`
  - `TankLedgeHangs`

## Notes

- las familias respetan `Skills_IsSkillTypeEnabledInCurrentMode(...)`
- `BoomerVomitTargets` y `ChargerBowlTargets` son sumas de `amount`
- métricas `Best` usan el máximo observado
- `ChargerInstaKill` cuenta como una sola familia aunque el announce visible
  pueda mostrar propiedades como `Impacto`, `Caida`, `Estrellado` o `Altura`
