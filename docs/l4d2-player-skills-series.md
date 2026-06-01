# L4D2-Player-Skills-Series

`l4d2_player_skills_series` es un consumidor interno de `L4D2-Player-Skills`.

Su responsabilidad es agregar en memoria los snapshots finalizados de:

- `skill_summary`
- `kill_summary`

No consume eventos live de skills.

## Goal

El objetivo es dar histórico corto multi-ronda para la familia `skills`
sin mover esa responsabilidad a `PlayerStats`.

La autoridad semántica sigue viviendo en `L4D2-Player-Skills`.

## Boundary Rules

El plugin usa boundaries alineados con el lifecycle del modo:

- `Coop`
  - serie por `mission`
- `Versus`
  - serie por `mission`
- `Scavenge`
  - serie por `map`
- `Survival`
  - serie por `map`

## Inputs

La fuente de datos es:

- snapshots finalizados de `skills`
- snapshots finalizados de `kills`
- el payload público de summary que expone `L4D2-Player-Skills`

La unidad real de almacenamiento no es el evento live.

La unidad real es el snapshot finalizado de:

- ronda en `Coop`
- mitad survivor en `Versus`
- mapa en `Scavenge` y `Survival` según el summary que publique `skills`

## Commands

- `sm_skills_series`
  - imprime el buffer actual de series en memoria
- `sm_skills_series <id>`
  - imprime las entradas agregadas de una serie
- `sm_skills_series_stats <surv|infect|all> [id]`
  - imprime tablas agregadas por jugador para:
    - `skills`
    - `kills`
  - usa el mismo lenguaje visual base de `sm_skills_stats`:
    - tablas separadas por equipo
    - humanos primero
    - `IA` al final cuando aplica

Si no se entrega `id`, el comando usa la serie activa o la más reciente.

## Current Aggregation Model

La versión actual agrega solo contadores públicos ya presentes en:

- `skill_summary.counts`
- `kill_summary.counts`

Eso significa que `skill_series` hoy conserva bien:

- cantidad acumulada de skills survivor
- cantidad acumulada de skills infected
- cantidad acumulada de kills SI default
- separación por jugador humano o `IA`

## Current Limits

La versión actual no reconstruye métricas derivadas avanzadas de `sm_skills_stats`.

Todavía no agrega por serie cosas como:

- `HunterPounceBest`
- `JockeyPounceBest`
- `BoomerVomitTargets`
- `BoomerVomitPerfect`
- `BoomerVomitBest`
- `ChargerBowlTargets`
- `ChargerBowlBest`
- otras métricas `Best`, `Targets` o `Perfect` derivadas de propiedades del evento

La razón es deliberada:

- `skill_series` consume snapshots finalizados públicos
- no vuelve a procesar el stream completo de eventos técnicos
- así evita duplicar lógica semántica o de scoring fuera de `L4D2-Player-Skills`

## Product Position

La responsabilidad actual queda separada así:

- `sm_skills`
  - foco en la ronda o mitad actual
- `sm_skills_stats`
  - tabla comparativa actual de skills
- `sm_skills_series`
  - buffer corto de series
- `sm_skills_series_stats`
  - histórico corto agregado por serie

## Product Rule

Este plugin es intencionalmente interno a la familia `skills`.

También es opcional. No forma parte del artefacto principal de
`L4D2-Player-Skills`.

No publica:

- librería SourceMod propia
- natives públicos
- forwards públicos

## Build

```powershell
& 'C:\sourcemodAPI\addons\sourcemod\scripting\spcomp.exe' `
  'C:\GitHub\L4D2-Player-Skills\addons\sourcemod\scripting\l4d2_player_skills_series.sp' `
  '-oC:\SourcemodCompiled\l4d2_player_skills_series.smx' `
  '-iC:\GitHub\L4D2-Player-Skills\addons\sourcemod\scripting\include' `
  '-iC:\GitHub\L4D2-Player-Skills\addons\sourcemod\scripting' `
  '-iC:\sourcemodAPI\addons\sourcemod\scripting\include'
```
