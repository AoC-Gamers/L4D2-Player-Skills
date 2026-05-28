# Jockey Flows

Este documento resume los flujos actuales de skills relacionadas con `Jockey`.

## Skills

- `JockeyHighPounce`
- `JockeyJumpStop`
- `JockeySkeetMelee`

## Modelo

Las skills de `Jockey` ahora usan una ventana artesanal de salto ofensivo.

La idea no es depender de `ability_use` como fuente principal, porque ese evento
no es confiable para `Jockey` en todos los entornos.

El flujo actual usa:

- apertura principal por `player_jump_apex`
- cierre por `jockey_ride`
- cierre por shove exitoso
- cierre por muerte

Estado relevante:

- `g_bDetectJockeyLeaping`
- `g_fDetectJockeyLeapSeenAt`
- `g_DetectLeap`
- `g_fDetectJockeyLastShove`

## JockeyHighPounce

### Sources

- `player_jump_apex`
- `jockey_ride`

### State

- `g_bDetectLeapOriginSet`
- `g_fDetectLeapOrigin`
- `g_iDetectPinnedVictim`
- `g_iDetectPinnerByVictim`
- `g_iDetectPinnedClass`

### Emit

Se emite `JockeyHighPounce` cuando:

- el `Jockey` conecta el `ride`,
- existe origen de salto válido,
- y la altura supera el umbral configurado.

### Properties

- `height`
- `distance`
- `reported_high`
- `incapped`

### Flow

```mermaid
flowchart TD
    A[player_jump_apex] --> B[Store leap origin]
    B --> C[jockey_ride]
    C --> D[Calculate height and distance]
    D --> E{Height >= threshold}
    E -->|no| F[Stop]
    E -->|yes| G[Emit JockeyHighPounce]
```

## JockeyJumpStop

### Sources

- `player_jump_apex`
- `jockey_punched`
- `L4D2_OnEntityShoved_Post`

### Emit

Se emite `JockeyJumpStop` cuando:

- el `Jockey` sigue dentro de la ventana efectiva de leap,
- un survivor lo shovea,
- y no se trata de un doble registro dentro de la ventana anti-duplicado.

### Properties

- `with_shove`

### Flow

```mermaid
flowchart TD
    A[player_jump_apex] --> B[Open effective leap window]
    B --> C[jockey_punched / entity_shoved]
    C --> D{Still effectively leaping}
    D -->|no| E[Stop]
    D -->|yes| F[Emit JockeyJumpStop]
    F --> G[Close leap window]
```

## JockeySkeetMelee

### Sources

- `player_jump_apex`
- `player_death`
- `SDKHook_OnTakeDamage`
- `SDKHook_OnTakeDamagePost`

### Emit

Se emite `JockeySkeetMelee` cuando:

- el `Jockey` sigue dentro de la ventana efectiva de leap,
- la muerte final ocurre por `melee`,
- y la kill se resuelve antes de que la vida total del `Jockey` se anuncie como `JockeyKill`.

### Properties

- `damage`
- `shots`
- `perfect`

### Flow

```mermaid
flowchart TD
    A[player_jump_apex] --> B[Open effective leap window]
    B --> C[player_death on Jockey]
    C --> D{Weapon == melee}
    D -->|no| E[Fall back to JockeyKill]
    D -->|yes| F{Still effectively leaping}
    F -->|no| E
    F -->|yes| G[Emit JockeySkeetMelee]
    G --> H[Suppress JockeyKill]
```
