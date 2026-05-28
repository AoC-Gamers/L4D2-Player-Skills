# L4D2 Player Skills: `sm_skills`

Este documento define el comportamiento esperado de `sm_skills`, su modelo de salida y las reglas de render para `Survivor Skills` e `Infected Skills`.

## Objetivo

`sm_skills` debe dejar de ser una tabla comparativa centrada en abreviaturas y pasar a ser una vista legible por equipo:

- si el usuario pertenece a `Survivor`, imprime `Survivor Skills`
- si el usuario pertenece a `Infected`, imprime `Infected Skills`
- si el usuario usa un argumento de otro equipo o el argumento `all`, imprime ambas tablas

La salida sigue siendo:

- resumen corto en chat
- tabla detallada en consola

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

- `SkeetAssisted`
- `SkeetSingleShot`
- `SkeetMultiShot`
- `SkeetSingleShotFullHp`
- `SkeetMultiShotFullHp`
- `HunterSkeetSniper`
- `HunterSkeetSniperFullHp`
- `HunterSkeetGL`
- `HunterSkeetGLFullHp`

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

- `SmokerSelfClearKill`
- `SmokerSelfClearShove`

#### BoomerPops

Incluye:

- `BoomerPopBot`
- `BoomerPopPlayer`

#### ChargerLevels

Incluye:

- `ChargerLevel`
- `ChargerLevelPerfect`

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

### Ejemplo

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

#### JockeyPounces

Incluye:

- `JockeyHighPounce`

#### BoomerVomit

Incluye:

- `BoomerVomitLandedSingle`
- `BoomerVomitLandedMulti`

#### ChargerInstaKills

Incluye:

- `ChargerInstaKillCarry`
- `ChargerInstaKillCarryLedge`
- `ChargerInstaKillCarryDeadly`
- `ChargerInstaKillCarryFatalFall`
- `ChargerInstaKillCarryIncap`
- `ChargerInstaKillImpact`
- `ChargerInstaKillImpactLedge`
- `ChargerInstaKillImpactDeadly`
- `ChargerInstaKillImpactFatalFall`
- `ChargerInstaKillImpactIncap`

#### ChargerDeathSetups

Incluye:

- `ChargerDeathSetupLedge`
- `ChargerDeathSetupIncap`

#### TankRockHits

Incluye:

- `TankRockHit`

### Ejemplo

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

## Reglas de Render

### Orden de columnas

- primero jugadores humanos
- `IA` siempre al final

### Orden de filas

Orden recomendado:

#### Survivor

1. `Skeets`
2. `SkeetMelees`
3. `Deadstops`
4. `JockeyJumpStops`
5. `SpecialClears`
6. `TongueCuts`
7. `SmokerClears`
8. `BoomerPops`
9. `ChargerLevels`
10. `CarAlarms`
11. `BunnyHopStreaks`
12. `WitchCrowns`
13. `TankRockSkeets`
14. `SpecialInfectedKills`

#### Infected

1. `HunterPounces`
2. `JockeyPounces`
3. `BoomerVomit`
4. `ChargerInstaKills`
5. `ChargerDeathSetups`
6. `TankRockHits`

### Filtros por modo

Las filas deben respetar la lógica actual de `Skills_IsSkillTypeEnabledInCurrentMode(...)`.

Eso implica:

- si una familia no aplica al modo activo, no se imprime
- si ninguna métrica aplicable existe, se mantiene el flujo actual de unavailable/empty

## Resumen de Chat

El resumen corto de chat se mantiene orientado al actor objetivo.

No cambia con esta refactor.

La refactor solo afecta la tabla detallada de consola.

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

## Alcance

Este documento solo redefine `sm_skills`.

No cambia:

- announce de skills en chat
- payload de la API
- detección de skills
- reglas de precedencia entre skill rica y kill simple
