# L4D2 Player Skills Rating

## Proposito

Este documento define una capa ligera de rating publico para las skills detectadas.

La idea no es reemplazar la semantica de deteccion de skills. La idea es sumar
una capa chica de prestigio o visibilidad que pueda reutilizarse en:

- announces de chat
- consumidores de la API
- futuros consumidores de stats

## Tag Publico

El formato visible propuesto para el tag es:

- `[★]`
- `[★★]`
- `[★★★]`

Cuando el modo de estrellas este habilitado, no deberia mostrarse el texto
`Skill`.

## Escala de Rating

El sistema deberia usar solo 3 niveles visibles de rating:

- `0`
  sin estrellas
- `1`
  `[★]`
- `2`
  `[★★]`
- `3`
  `[★★★]`

`0` significa que el evento existe y aun puede anunciarse, pero no se considera
parte del set de skills rankeadas con estrellas.

## Interpretacion

El rating busca reflejar una mezcla pragmatica de:

- dificultad de ejecucion
- impacto competitivo
- rareza o prestigio

No busca ser una medida matematicamente pura de dificultad.

## Contexto de Modo y Cvars

Las reglas dinamicas no deben tratar todas las cvars como si fueran globales.

Regla actual del proyecto:

- la deteccion del modo de juego se hace con `left4dhooks`:
  - `L4D_GetGameModeType()`
  - `GAMEMODE_COOP`
  - `GAMEMODE_VERSUS`
  - `GAMEMODE_SURVIVAL`
  - `GAMEMODE_SCAVENGE`
- `versus` y `scavenge` deben tratarse como contextos distintos
- las cvars de vida maxima (`z_*_health`) pueden usarse como baseline global
- las cvars `z_versus_*_limit` solo describen limites del contexto `versus`
- esas cvars no deben usarse como verdad universal de disponibilidad de clase
- si mas adelante aparecen cvars especificas de `scavenge`, deben modelarse
  como contexto propio de `scavenge`, no mezclarse dentro del helper de
  `versus`

Consecuencia practica:

- una regla de rating o gating basada en `z_versus_*_limit` solo es valida en
  `versus`
- fuera de `versus`, esa cvar no debe influir en la interpretacion general de
  una skill

## Ratings Propuestos Actuales

### Ratings Fijos

| Skill | Rating |
|---|---:|
| `SmokerTongueCut` | `2` |
| `SmokerSelfClear` | `1` |
| `SpecialPinClear` | `1` |
| `HunterDeadstop` | `1` |
| `ChargerInstaKill` | `3` |
| `ChargerDeathSetup` | `2` |
| `WitchDead` con `crown` | `2` |
| `TankRockSkeet` | `2` |
| `TankRockHit` | `0` |
| `WitchIncap` | `0` |
| `TankDead` | `0` |

### Ratings Dinamicos

| Skill | Rating | Regla actual |
|---|---:|---|
| `BoomerPop` | `1-3` | depende del tiempo de pop |
| `CarAlarmTriggered` | `0-1` | depende de influencia de SI |
| `HunterSkeet` | `2-3` | `2` estandar, `3` si es `headshot` o disparo perfecto |
| `HunterSkeetMelee` | `2-3` | `2` estandar, `3` en contexto mas fuerte |
| `ChargerLevel` | `2-3` | `2` si el Charger estaba chipeado, `3` si es `PerfectLevel` |
| `HunterHighPounce` | `1-3` | depende del daño real del pounce |
| `JockeyHighPounce` | `1-3` | depende de la altura real del ride |
| `BoomerVomitLanded` | `0-2` | depende de la cantidad de vomitados |
| `BunnyHopStreak` | `1` | fija |

## Casos Dinamicos Acordados

### BoomerPop

`BoomerPop` deberia ser dinamico segun el tiempo del pop.

Regla acordada actual, tomando como referencia `l4d2_stats.sp` de
`L4D2-Competitive-Rework`:

- `<= 0.5s` => `3`
- `> 0.5s` y `<= 1.4s` => `2`
- `> 1.4s` => `1`

### CarAlarmTriggered

`CarAlarmTriggered` solo deberia recibir estrellas cuando la activacion ocurra
bajo influencia significativa de un special infected.

Regla acordada actual:

- activacion normal del propio survivor: `0`
- activacion bajo influencia de SI: `1`

Direccion de implementacion actual:

- para `Boomer`, `1` solo si existe infected valido asociado al evento
- para `Hit`, `Touched` y `Explosion`, `1` solo si:
  - `forced`
  - y existe infected valido asociado al evento
- cualquier otro caso queda en `0`

### HunterSkeetMelee

`HunterSkeetMelee` deberia ser:

- `2` en el caso estandar
- `3` si es `perfect`

Regla acordada actual:

- `2` en el caso estandar
- `3` si `perfect`

Direccion de implementacion actual:

- `HunterSkeetMelee` ya nace solo en contexto de Hunter pouncing
- la señal fuerte real para subir rating es `perfect`

### HunterSkeet

`HunterSkeet` deberia ser:

- `2` en el caso estandar
- `3` si el skeet fue `headshot`
- `3` si el disparo fue perfecto

Regla acordada actual:

- `2` en el caso estandar
- `3` si `headshot`
- `3` si `perfect`

Direccion de implementacion actual:

- `perfect` en ranged se interpreta como:
  - `shots == 1`
  - `chip_damage == 0`
  - sin team skeet
- `sniper` y `grenade_launcher` no cambian el rating por si solos

### ChargerLevel

`ChargerLevel` deberia ser:

- `2` cuando el melee final mata a un Charger ya chipeado
- `3` cuando el melee final baja toda la vida del Charger y produce un `PerfectLevel`

Regla actual sugerida:

- `PerfectLevel` si `chip_damage == 0`
- `Level` estandar en cualquier otro caso que siga calificando como `ChargerLevel`

### HunterHighPounce

`HunterHighPounce` deberia depender del daño real del pounce.

La referencia base es:

- `z_hunter_max_pounce_bonus_damage`

El bonus configurado se suma a un punto base del juego.

Ejemplo:

- bonus maximo `24`
- daño total maximo `25`

Regla acordada actual:

- `1-14` => `1`
- `15-21` => `2`
- `22-25` => `3`

Direccion de implementacion actual:

- usar el `damage` real guardado en el evento
- usar `z_hunter_max_pounce_bonus_damage` como baseline del maximo total

### JockeyHighPounce

`JockeyHighPounce` deberia depender de la altura real del ride.

La referencia base es:

- `l4d2_player_skills_jockey_high_pounce_height`

Regla acordada actual:

- desde `threshold` hasta `< threshold + 150` => `1`
- desde `threshold + 150` hasta `< threshold + 350` => `2`
- desde `threshold + 350` en adelante => `3`

Con el threshold default actual `300`, eso queda:

- `300-449` => `1`
- `450-649` => `2`
- `650+` => `3`

### BoomerVomitLanded

`BoomerVomitLanded` deberia depender de la cantidad de survivors vomitados.

Regla acordada actual:

- `1-2` vomitados => `0`
- `3` vomitados => `1`
- `4` vomitados => `2`

Direccion de implementacion actual:

- usar `amount` como cantidad total de vomitados del evento

### BunnyHopStreak

`BunnyHopStreak` queda con una sola estrella.

Regla acordada actual:

- cualquier `BunnyHopStreak` valido => `1`

## Nota sobre Charger

`ChargerDeathSetup` no fue reemplazada por `ChargerInstaKill`.

Siguen siendo skills distintas:

- `ChargerInstaKill`
  muerte confirmada dentro del flujo del charger
- `ChargerDeathSetup`
  setup letal no instantaneo, normalmente incap o ledge hang

Por eso ambas pueden permanecer dentro del modelo de rating.

## Direccion de Implementacion

La capa de rating deberia implementarse como metadata, no solo como texto de
announce.

Direccion recomendada:

1. rating base por `L4D2SkillType`
2. override opcional por evento para skills dinamicas
3. campo publico `rating` expuesto en `skill_properties`
4. modo de tag configurable para renderizar:
   - tag estandar
   - tag con estrellas
   - o ambos
