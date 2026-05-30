# L4D2 Skills API

La API pública quedó separada en tres familias:

- `skills`
- `kills`
- `bosses`

El contrato ya no expone getters escalares ni un stream mixto de eventos.  
Todo el consumo externo pasa por:

- `forward` por familia
- `native` por familia que llena `KeyValues`

## Families

### Skills

Eventos semánticos competitivos que no son kills default ni bosses:

- `HunterSkeet`
- `HunterSkeetMelee`
- `HunterDeadstop`
- `BoomerPop`
- `ChargerLevel`
- `SmokerTongueCut`
- `SmokerSelfClear`
- `HunterHighPounce`
- `JockeyHighPounce`
- `SmokerLedgeHang`
- `JockeyLedgeHang`
- `ChargerInstaKill`
- `ChargerDeathSetup`
- `ChargerLedgeHang`
- `ChargerBowl`
- `SpecialPinClear`
- `BoomerVomitLanded`
- `BunnyHopStreak`
- `CarAlarmTriggered`
- `JockeyJumpStop`
- `JockeySkeetMelee`
- `JockeySkeet`

### Kills

Muertes default de SI no absorbidas por una skill de mayor jerarquía:

- `SmokerKill`
- `BoomerKill`
- `HunterKill`
- `SpitterKill`
- `JockeyKill`
- `ChargerKill`

### Bosses

Los bosses usan dos capas distintas:

- `boss events`
  - `TankDead`
  - `WitchDead`
  - `WitchIncap`
  - `TankRockSkeet`
  - `TankRockHit`
  - `TankLedgeHang`
  - `WitchCrown`
- `boss sessions`
  - `Tank`
  - `Witch`

## Immediate Forwards

```sourcepawn
forward Action PlayerSkills_OnSkillDetected(int eventId, L4D2ApiSkillType type);
forward void PlayerSkills_OnSkillAnnounced(int eventId, L4D2ApiSkillType type);

forward Action PlayerSkills_OnKillDetected(int eventId, L4D2ApiKillType type);
forward void PlayerSkills_OnKillAnnounced(int eventId, L4D2ApiKillType type);

forward Action PlayerSkills_OnBossEventDetected(int eventId, L4D2ApiBossEventType type);
forward void PlayerSkills_OnBossEventAnnounced(int eventId, L4D2ApiBossEventType type);
```

Reglas:

- `Detected`
  - ocurre antes del announce builtin
  - `Plugin_Handled` o mayor suprime el announce builtin de esa familia
- `Announced`
  - ocurre después de imprimir
  - es notificación solamente

## Boss Session Forwards

```sourcepawn
forward Action PlayerSkills_OnBossSessionFinalized(int sessionId, L4D2BossType type);
forward void PlayerSkills_OnBossSessionAnnounced(int sessionId, L4D2BossType type);
forward void PlayerSkills_OnTankSessionClosed(int sessionId, L4D2TankSessionEndReason reason);
```

`PlayerSkills_OnTankSessionClosed(...)` usa:

- `L4D2TankSessionEnd_Dead`
- `L4D2TankSessionEnd_Escaped`
- `L4D2TankSessionEnd_Wipe`

## Round/Half Summary Forwards

```sourcepawn
forward void PlayerSkills_OnSkillSummaryFinalized(int summaryId);
forward void PlayerSkills_OnKillSummaryFinalized(int summaryId);
```

Se disparan cuando el runtime congela el estado de la mitad/ronda y construye el snapshot agregado de cada familia.

## Event Natives

```sourcepawn
native bool PlayerSkills_IsSkillEventValid(int eventId);
native bool PlayerSkills_FillSkillEventKeyValues(int eventId, Handle kv);

native bool PlayerSkills_IsKillEventValid(int eventId);
native bool PlayerSkills_FillKillEventKeyValues(int eventId, Handle kv);

native bool PlayerSkills_IsBossEventValid(int eventId);
native bool PlayerSkills_FillBossEventKeyValues(int eventId, Handle kv);
```

Roots escritas:

- `skill_event`
- `kill_event`
- `boss_event`

Payload común:

- `id`
- `type_id`
- `type_name`
- `context`
- `actor_*`
- `victim_*` cuando aplica
- `pinvictim_*` cuando aplica
- `assists`
- `properties`

`boss_event` además puede adjuntar:

- `boss_session`

cuando el evento ya referencia una sesión válida de `Tank` o `Witch`.

## Summary Natives

```sourcepawn
native bool PlayerSkills_IsSkillSummaryValid(int summaryId);
native bool PlayerSkills_FillSkillSummaryKeyValues(int summaryId, Handle kv);

native bool PlayerSkills_IsKillSummaryValid(int summaryId);
native bool PlayerSkills_FillKillSummaryKeyValues(int summaryId, Handle kv);
```

Roots escritas:

- `skill_summary`
- `kill_summary`

Payload:

- `id`
- `map`
- `total_events`
- `created_at`
- `context`
- `entries`

Cada `entry` contiene:

- `team`
- `team_name`
- `userid`
- `accountid`
- `name`
- `bot`
- `counts`

`counts` usa keys por nombre público de tipo dentro de su familia.

## Boss Session Native

```sourcepawn
native bool PlayerSkills_IsBossSessionValid(int sessionId);
native bool PlayerSkills_FillBossSessionKeyValues(int sessionId, Handle kv);
```

Root escrita:

- `boss_session`

Payload común:

- `id`
- `type`
- `state`
- `max_health`
- `last_health`
- `total_damage`
- `started_at`
- `closed_at`
- `alive_time`
- `owner_*`
- `pending_owner_*`
- `damage_entries`

Subbloques:

- `tank_session`
  - `rocks_thrown`
  - `rocks_hit`
  - `in_stasis`
  - `end_reason`
- `witch_session`
  - `startled`
  - `crown_detected`

## Design Notes

- No existe ya una native pública equivalente a `FillEventKeyValues(...)` o `FillSummaryKeyValues(...)`.
- No existe ya una capa pública de getters escalares por campo.
- No existe ya un wrapper público `l4d2_skill_detect`.
- `skills`, `kills` y `bosses` se consumen por contratos distintos y no comparten enum público.
