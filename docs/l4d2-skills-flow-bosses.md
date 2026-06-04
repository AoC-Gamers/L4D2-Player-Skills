# Boss Flows

Este documento resume los flujos actuales de skills y sesiones relacionadas con `Tank` y, como índice, deriva `Witch` a su documento dedicado.

## Skills and Sessions

- `TankDead`
- `TankRockSkeet`
- `TankRockHit`
- boss damage sessions de `Tank`
- [Witch Flows](./l4d2-skills-flow-witch.md)

## Tank Damage Session

### Sources

- `tank_spawn`
- `SDKHook_OnTakeDamagePost`
- `player_death`
- `tank_killed`
- `L4D_OnReplaceTank`
- `L4D_OnTryOfferingTankBot`
- `L4D_OnTryOfferingTankBot_Post`
- `L4D_OnTryOfferingTankBot_PostHandled`
- `L4D_OnEnterStasis`
- `L4D_OnLeaveStasis`

### State

- `g_BossSessions`
- `g_BossDamage`
- `g_Runtime.hasTankControlEq`
- common session:
  - `maxHealth`
  - `lastHealth`
  - `totalDamage`
- `tank` substate:
  - `inStasis`
  - `endReason`
  - `controlCount`
  - `activeControlIndex`
  - `controls[]`

Cada entrada de `controls[]` guarda:

- identidad persistente del controller
- `controlTime`
- `rocksThrown`
- `rocksHit`
- `overflow`
- `mergedControls`

Regla de ownership:

- cada `Tank` vive en su propia boss session;
- el payload público ya no depende de un único `owner`;
- la identidad pública del `Tank` vive en `tank_control`;
- cualquier métrica nueva de `Tank` debe agregarse por sesión o por segmento de control, no como contador global;
- el diseño actual admite múltiples `Tank` simultáneos siempre que el tracking siga resolviendo por `victim`, `userid`, `entity` o `rock owner`.

Fuente de control:

- si `l4d_tank_control_eq` está cargado
  - `PlayerSkills` usa esa librería como fuente preferida de continuidad del `Tank`;
  - consume:
    - `TankControl_GetClientTankId(...)`
    - `TankControl_OnTankControlChanged(...)`
  - y reduce sus heurísticas locales de reasignación;
- si no está cargado
  - `PlayerSkills` cae a su lógica local de recuperación:
    - bot reclaim
    - human takeover
  - en este modo no intenta rehidratar al mismo humano por identidad persistente;
  - si el flujo no matchea por `userid`, `client`, reclaim bot o takeover humano, se abre una sesión nueva.

### Emit

`TankDead` se emite cuando:

- el `Tank` muere,
- la sesión del boss sigue siendo válida,
- y existe killer survivor para el evento.

La sesión de daño se finaliza aparte para el resumen de boss.

Regla de identidad pública:

- `TankDead` ya no expone `victim_*`;
- la identidad pública del `Tank` debe leerse desde `boss_session.tank_control`.

### Properties

`TankDead` no necesita `skill_properties` especiales.

Contexto adicional:

- `tank_session`
  - `in_stasis`
  - `end_reason`
- `boss_session`
  - se puede inspeccionar completo con `PlayerSkills_FillBossSessionKeyValues(...)`
  - incluye:
    - estado común
    - `damage_entries`
    - `tank_control_count`
    - `tank_control[]`

Regla de KV público:

- `rocks_thrown` y `rocks_hit`
  - ya no viven en `tank_session`;
- ahora viven en cada segmento de `tank_control`;
- el summary de announce del `Tank`
  - deriva el total sumando todos los segmentos.

Reglas de segmentación:

- si el control pasa de un humano a otro humano distinto
  - se abre un nuevo segmento;
- si el control pasa de humano a bot y luego vuelve el mismo humano
  - el tramo bot se absorbe en el segmento humano original;
- si el historial supera el máximo de segmentos
  - el último slot se reutiliza como `overflow`;
  - ese slot expone `overflow = 1`;
  - y `merged_controls` indica cuántos controles quedaron compactados ahí.

### Tank Session Close

Forward disponible:

```sourcepawn
forward void PlayerSkills_OnTankSessionClosed(int sessionId, L4D2TankSessionEndReason reason);
```

Reasons actuales:

- `TankDead`
- `SurvivorsEscaped`
- `SurvivorsWiped`

### Flow

```mermaid
flowchart TD
    A[tank_spawn] --> B[Start Tank session]
    B --> C[OnTakeDamagePost / player_death]
    C --> D[Track damage, owner, stasis and transfers]
    D --> E[tank_killed or Tank death]
    E --> F[Emit TankDead]
    F --> G[Finalize boss damage session]
```

## TankRockSkeet

### Sources

- `L4D_TankRock_OnRelease_Post`
- `SDKHook_TraceAttack` on rock
- `L4D_TankRock_OnDetonate`
- `OnEntityDestroyed`

### State

- `g_DetectRocks`

Por roca:

- owner `Tank`
- `totalDamage`
- `lastShooter`
- `touched`
- `hit`
- `finalizeQueued`
- `releasedAt`

### Emit

Se emite `TankRockSkeet` cuando:

- una roca activa recibe daño de survivor,
- no llegó a tocar survivor antes de resolverse,
- y el cierre diferido confirma que no fue realmente un hit.

Nombre visible:

- `Skeet-Rock`

### Properties

No agrega `skill_properties` especiales hoy.

### Flow

```mermaid
flowchart TD
    A[Rock released] --> B[Track rock entity and owner]
    B --> C[TraceAttack on rock]
    C --> D[Rock detonate / destroy]
    D --> E[Finalize after short delay]
    E --> F{Rock hit survivor first}
    F -->|yes| G[Stop]
    F -->|no| H[Emit TankRockSkeet]
```

## TankRockHit

### Sources

- `L4D_TankRock_BounceTouch_Post`
- `player_hurt` with `tank_rock`

### State

Comparte el tracking de roca con `TankRockSkeet`.

### Emit

Se emite `TankRockHit` cuando:

- la roca conecta survivor,
- o el daño `tank_rock` confirma el impacto dentro del flujo activo de esa roca.

### Properties

No agrega `skill_properties` especiales hoy.

### Flow

```mermaid
flowchart TD
    A[Rock released] --> B[Track rock]
    B --> C[Bounce touch or player_hurt tank_rock]
    C --> D{Valid survivor hit}
    D -->|no| E[Stop]
    D -->|yes| F[Emit TankRockHit]
```

## Witch

Los flujos específicos de `Witch` ahora viven en:

- [Witch Flows](./l4d2-skills-flow-witch.md)
- incluye:
  - `WitchDead`
  - `WitchCrown`
  - `WitchIncap`
  - la separación entre ventana de `crown` y vida total de la `Witch`
  - la semántica actual de `damage/shots` visible

### Emit

`WitchCrown` se emite cuando la muerte de la `Witch` clasifica como crown.

### Properties

- `damage`
- `actor_damage`
- `chip_damage`
- `shots`
- `crown`
- `perfect`
- `startled`

Contexto adicional:

- `witch_session`

## WitchIncap

### Sources

- `player_incapacitated_start`

### State

Comparte la sesión activa de `Witch`.

### Emit

Se emite `WitchIncap` cuando:

- una `Witch` activa incapacita a un survivor,
- y la sesión del boss sigue abierta.

### Properties

- `amount`
- `startled`

Contexto adicional:

- `witch_session`

### Flow

```mermaid
flowchart TD
    A[Witch session active] --> B[player_incapacitated_start]
    B --> C{Victim was incapped by Witch}
    C -->|no| D[Stop]
    C -->|yes| E[Emit WitchIncap]
```
