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
forward Action PlayerSkills_OnKillDetected(int eventId, L4D2ApiKillType type);
forward Action PlayerSkills_OnBossEventDetected(int eventId, L4D2ApiBossEventType type);
```

Reglas:

- `Detected`
  - ocurre antes del announce builtin
  - `Plugin_Handled` o mayor suprime el announce builtin de esa familia

## Boss Session Forwards

```sourcepawn
forward Action PlayerSkills_OnBossSessionFinalized(int sessionId, L4D2BossType type);
forward void PlayerSkills_OnTankSessionClosed(int sessionId, L4D2TankSessionEndReason reason);
```

`PlayerSkills_OnTankSessionClosed(...)` usa:

- `L4D2TankSessionEnd_TankDead`
- `L4D2TankSessionEnd_SurvivorsEscaped`
- `L4D2TankSessionEnd_SurvivorsWiped`

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
- `base_mode`
- `actor_*`
- `victim_*` cuando aplica
- `pinvictim_*` cuando aplica
- `assists`
- `properties`

Notas para `skill_event.properties`:

- `implies_si_death`
  - `1` cuando la skill principal absorbió una muerte default de SI
- `suppressed_kill_type_id`
  - enum público `L4D2ApiKillType` de la muerte default suprimida
- `suppressed_kill_type`
  - nombre estable del kill type suprimido
- `clear_mode`
  - hoy solo aplica a `SmokerSelfClear`
  - valores:
    - `kill`
    - `shove`
- algunos skills publican contexto adicional de resolución:
  - `incapped`
  - `ledge_hang`
  - `fatal_fall`
  - `deadly_slam`
  - `height`
- `ChargerInstaKill`
  - usa esas propiedades para describir el tipo de muerte y la altura del desenlace
  - `fatal_fall` y `deadly_slam` son mutuamente excluyentes en la práctica
  - `height` se expone solo cuando el runtime tiene una caída/altura útil para reportar

`boss_event` además puede adjuntar:

- `boss_session`

cuando el evento ya referencia una sesión válida de `Tank` o `Witch`.

Notas de shaping:

- `WitchCrown`
  - omite `victim_*`
  - mantiene `actor_weaponid`
- `WitchDead`
  - omite `victim_*`
  - omite `actor_weaponid`
- `boss_session` de `Tank`
  - usa `tank_control` como identidad pública del boss a lo largo de la sesión
  - si `l4d_tank_control_eq` está cargado, `PlayerSkills` usa esa librería como fuente preferida para `tankId` y control changes del `Tank`
  - si no está cargada, `PlayerSkills` cae a su tracking heurístico local
  - en ese fallback local no intenta recuperar al mismo humano por identidad persistente; solo usa continuidad por `userid`, `client`, reclaim bot y takeover humano
  - `TankDead` no expone `victim_*`

### Event Examples

`kill_event` (`SmokerKill`)

```text
"kill_event"
{
	"id"		"18"
	"type_id"		"1"
	"base_mode"		"2"

	"actor_userid"		"2"
	"actor_accountid"		"87654321"
	"actor_name"		">lechuga"
	"actor_bot"		"0"

	"victim_userid"		"4"
	"victim_accountid"		"0"
	"victim_name"		"Smoker"
	"victim_bot"		"1"

	"assists_count"		"1"
	"assists"
	{
		"0"
		{
			"userid"		"7"
			"accountid"		"12345678"
			"name"		"el jugo"
			"bot"		"0"
			"damage"		"90"
			"shots"		"1"
			"weaponid"		"8"
		}
	}

	"properties"
	{
		"actor_damage"		"160"
		"actor_weaponid"		"8"
		"chip_damage"		"90"
		"shots"		"2"
		"headshot"		"1"
		"rating"		"1"
	}
}
```

`skill_event` (`HunterSkeet`)

```text
"skill_event"
{
	"id"		"42"
	"type_id"		"1"
	"base_mode"		"2"

	"actor_userid"		"7"
	"actor_accountid"		"12345678"
	"actor_name"		"el jugo"
	"actor_bot"		"0"

	"victim_userid"		"3"
	"victim_accountid"		"0"
	"victim_name"		"Hunter"
	"victim_bot"		"1"

	"assists_count"		"1"
	"assists"
	{
		"0"
		{
			"userid"		"2"
			"accountid"		"87654321"
			"name"		">lechuga"
			"bot"		"0"
			"damage"		"91"
			"shots"		"1"
			"weaponid"		"8"
		}
	}

	"properties"
	{
		"actor_damage"		"159"
		"actor_weaponid"		"8"
		"chip_damage"		"91"
		"shots"		"1"
		"headshot"		"1"
		"rating"		"3"
		"implies_si_death"		"1"
		"suppressed_kill_type_id"		"3"
		"suppressed_kill_type"		"HunterKill"
	}
}
```

`skill_event` (`SmokerSelfClear` por shove)

```text
"skill_event"
{
	"id"		"57"
	"type_id"		"7"
	"base_mode"		"2"

	"actor_userid"		"9"
	"actor_accountid"		"11223344"
	"actor_name"		"survivor"
	"actor_bot"		"0"

	"victim_userid"		"11"
	"victim_accountid"		"0"
	"victim_name"		"Smoker"
	"victim_bot"		"1"

	"properties"
	{
		"clear_mode"		"shove"
	}
}
```

`skill_event` (`ChargerInstaKill`)

```text
"skill_event"
{
	"id"		"91"
	"type_id"		"12"
	"base_mode"		"2"

	"actor_userid"		"14"
	"actor_accountid"		"99887766"
	"actor_name"		"Charger"
	"actor_bot"		"1"

	"victim_userid"		"5"
	"victim_accountid"		"12345678"
	"victim_name"		"Rochelle"
	"victim_bot"		"0"

	"properties"
	{
		"rating"		"3"
		"fatal_fall"		"1"
		"height"		"89.0"
	}
}
```

`boss_event` (`WitchCrown`)

```text
"boss_event"
{
	"id"		"7"
	"type_id"		"6"
	"base_mode"		"2"

	"actor_userid"		"2"
	"actor_accountid"		"87654321"
	"actor_name"		">lechuga"
	"actor_bot"		"0"

	"properties"
	{
		"actor_damage"		"1000"
		"actor_weaponid"		"11"
		"shots"		"1"
		"headshot"		"1"
		"rating"		"3"
	}

	"boss_session"
	{
		"id"		"4"
		"type"		"2"
	}
}
```

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
- `total_events`
- `created_at`
- `base_mode`
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

### Summary Examples

`skill_summary`

```text
"skill_summary"
{
	"id"		"3"
	"total_events"		"5"
	"created_at"		"1717054800"
	"base_mode"		"2"

	"entries"
	{
		"0"
		{
			"team"		"2"
			"team_name"		"Survivor"
			"userid"		"2"
			"accountid"		"87654321"
			"name"		">lechuga"
			"bot"		"0"

			"counts"
			{
				"HunterSkeet"		"2"
				"SmokerTongueCut"		"1"
			}
		}
	}
}
```

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
- `total_damage`
- `alive_time`
- `damage_entries`

Subbloques:

- `tank_session`
  - `in_stasis`
  - `end_reason`
- `tank_control_count`
- `tank_control`
  - `userid`
  - `accountid`
  - `name`
  - `bot`
  - `control_time`
  - `overflow` cuando aplica
  - `merged_controls` cuando aplica
  - `rocks_thrown`
  - `rocks_hit`
	- `witch_session`
	  - `startled`
	  - `crown_detected`
	  - `harasser_*` cuando aplica
	  - `incap_victim_*` cuando aplica
	  - `crowner_*` cuando aplica

### Boss Session Example

```text
"boss_session"
{
	"id"		"11"
	"type"		"1"
	"state"		"2"
	"total_damage"		"6000"
	"alive_time"		"42.752"

	"damage_entries"
	{
		"0"
		{
			"userid"		"2"
			"accountid"		"87654321"
			"name"		">lechuga"
			"bot"		"0"
			"damage"		"4200"
			"shots"		"14"
		}
	}

	"tank_session"
	{
		"in_stasis"		"0"
		"end_reason"		"1"
	}

		"tank_control_count"		"2"
		"tank_control"
		{
			"0"
			{
				"userid"		"7"
				"accountid"		"12345678"
				"name"		"el jugo"
				"bot"		"0"
				"control_time"		"27.8"
				"rocks_thrown"		"3"
				"rocks_hit"		"1"
			}
			"1"
			{
				"userid"		"2"
				"accountid"		"87654321"
				"name"		">lechuga"
				"bot"		"0"
				"control_time"		"14.9"
				"rocks_thrown"		"2"
				"rocks_hit"		"1"
			}
		}
	}
	```

Notas de `tank_control`:

- el patrón competitivo `humano -> bot -> mismo humano`
  - se fusiona como una sola posesión del humano original;
- el bot intermedio no queda expuesto como segmento separado;
- si el historial real excede el máximo de segmentos
  - el último slot se marca con `overflow = 1`;
  - `merged_controls` indica cuántos controles fueron compactados ahí.

`witch_session` de ejemplo:

```text
"boss_session"
{
	"id"		"12"
	"type"		"2"
	"state"		"2"
	"total_damage"		"1000"
	"alive_time"		"11.2"

	"damage_entries"
	{
		"0"
		{
			"userid"		"2"
			"accountid"		"87654321"
			"name"		">lechuga"
			"bot"		"0"
			"damage"		"700"
			"shots"		"2"
		}
		"1"
		{
			"userid"		"7"
			"accountid"		"12345678"
			"name"		"el jugo"
			"bot"		"0"
			"damage"		"300"
			"shots"		"2"
		}
	}

	"witch_session"
	{
		"startled"		"1"
		"crown_detected"		"1"

		"harasser_userid"		"7"
		"harasser_accountid"		"12345678"
		"harasser_name"		"el jugo"
		"harasser_bot"		"0"

		"incap_victim_userid"		"4"
		"incap_victim_accountid"		"11223344"
		"incap_victim_name"		"francis"
		"incap_victim_bot"		"0"

		"crowner_userid"		"2"
		"crowner_accountid"		"87654321"
		"crowner_name"		">lechuga"
		"crowner_bot"		"0"
	}
}
```

## Design Notes

- No existe ya una native pública equivalente a `FillEventKeyValues(...)` o `FillSummaryKeyValues(...)`.
- No existe ya una capa pública de getters escalares por campo.
- No existe ya un wrapper público `l4d2_skill_detect`.
- `skills`, `kills` y `bosses` se consumen por contratos distintos y no comparten enum público.
