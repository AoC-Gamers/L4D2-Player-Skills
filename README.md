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

## Documentation Index

### Product Documentation

- [Build System](./docs/build-system.md)
- [L4D2 Skills API](./docs/l4d2-skills-api.md)
- [Skill Interpretation](./docs/l4d2-skills-interpretation.md)

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
