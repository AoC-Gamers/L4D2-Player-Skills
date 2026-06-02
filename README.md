# L4D2-Player-Skills

`L4D2-Player-Skills` es un proyecto SourceMod para Left 4 Dead 2 que centraliza la detección, el anuncio y la exposición por API de eventos de skill competitivos.

El proyecto consolida lógica que antes estaba repartida entre varios plugins y la reorganiza en:

- detección basada en eventos del motor y hooks de `left4dhooks`
- announcers de skills y bosses
- API pública con `forward` y `KeyValues`
- documentación de flujos, interpretación y build

## Command Surface

- `sm_skills`
  - imprime el resumen de skills detectadas en chat
  - además imprime una tabla comparativa en la consola del usuario
  - sin argumentos: jugador actual
  - `sm_skills <player>`: objetivo explícito
- `sm_skills_stats`
  - imprime la tabla comparativa de skills por equipo

## Announcement Routing

Los bitmasks `sm_skills_announce_*` siguen controlando qué tipos de announce están habilitados por clase.

Además, existen cvars de routing para decidir dónde se imprimen algunas familias ruidosas:

- `sm_skills_announce_kill_mode`
  - `1 = console`
  - `2 = chat`
  - `3 = chat_headshot`
- `sm_skills_announce_specialclear_mode`
  - `1 = console`
  - `2 = chat`
  - `3 = chat_headshot`

Semántica:

- `console`
  - imprime solo en la consola del actor del evento
- `chat`
  - imprime al chat global como announce normal
- `chat_headshot`
  - imprime al chat solo cuando `headshot = true`
  - en otro caso imprime solo en la consola del actor

## Documentation Index

### Product Documentation

- [Build System](./docs/build-system.md)
- [L4D2 Skills API](./docs/l4d2-skills-api.md)
- [Skill Interpretation](./docs/l4d2-skills-interpretation.md)
- [L4D2 Player Skills Series](./docs/l4d2-player-skills-series.md)

Flow documentation:

- [Charger Flows](./docs/l4d2-skills-flow-charger.md)
- [Hunter Flows](./docs/l4d2-skills-flow-hunter.md)
- [Jockey Flows](./docs/l4d2-skills-flow-jockey.md)
- [Smoker Flows](./docs/l4d2-skills-flow-smoker.md)
- [Boomer Flows](./docs/l4d2-skills-flow-boomer.md)
- [Boss Flows](./docs/l4d2-skills-flow-bosses.md)
- [Misc Flows](./docs/l4d2-skills-flow-misc.md)

### Construction References

- [SourceMod Translations](./docs/sourcemod-translations.md)
- [SourcePawn Style Guide](./docs/sourcepawn-style.md)
- [L4D2 Chat Colors](./docs/l4d2-chat-colors.md)

### Official Bibliography

- [L4D Game Events](./docs/l4d2_game_events.md)

## Local Build

```bash
make deps-smx
make build-smx
make package-smx
make release
```

El contenido publicado se describe en [plugin-package-map.json](./plugin-package-map.json).

## Libraries Used by the Project

El plugin se apoya principalmente en:

- `left4dhooks.inc`
- `left4dhooks_stocks.inc`
- `left4dhooks_silver.inc`
- `left4dhooks_lux_library.inc`

## Optional Companion Plugins

- `addons/sourcemod/scripting/l4d2_player_skills_series.sp`
  - `sm_skills_series`
  - `sm_skills_series_stats`
  - agrega histórico corto de `skill_summary` y `kill_summary`
  - no forma parte del artefacto principal
