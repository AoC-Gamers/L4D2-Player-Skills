# L4D2 Player Skills: API

Este documento describe el contrato actual para consumir eventos de `l4d2_player_skills` desde otros plugins.

## Forwards

El forward principal del sistema es:

```sourcepawn
forward Action PlayerSkills_OnSkillDetected(int eventId, L4D2SkillType type);
```

Uso:

- `eventId` identifica el evento detectado.
- `type` identifica la habilidad detectada.
- el consumidor decide si ignora, registra, anuncia o transforma el evento.

El payload se consulta con natives genéricos y con el volcado a `KeyValues`.

También existen:

```sourcepawn
forward void PlayerSkills_OnSkillAnnounced(int eventId, L4D2SkillType type);
forward Action PlayerSkills_OnBossDamageFinalized(int sessionId, L4D2BossType type);
forward void PlayerSkills_OnBossDamageAnnounced(int sessionId, L4D2BossType type);
forward void PlayerSkills_OnSummaryFinalized(int summaryId);
```

Uso:

- `OnSkillAnnounced`
  - notifica que el plugin ya imprimió el evento
- `OnBossDamageFinalized`
  - permite inspeccionar o suprimir el announce de `Tank/Witch`
- `OnBossDamageAnnounced`
  - notifica que el resumen de boss ya fue impreso
- `OnSummaryFinalized`
  - notifica que una mitad/ronda ya quedó congelada como snapshot compacto

## Round Summary

Al finalizar una ronda o mitad válida, el plugin ahora congela un snapshot compacto del estado de skills y dispara:

```sourcepawn
forward void PlayerSkills_OnSummaryFinalized(int summaryId);
```

Ese snapshot:

- se genera después de `Boss_OnRoundEnd()`
- se genera antes del reset del siguiente `round_start`
- conserva el contexto del modo
- agrega skills por actor
- agrupa infectados bot en una única entrada `IA` por equipo

Reglas:

- `Coop` y `Survival`
  - el summary se finaliza al cierre de ronda manejado por `round_end`
- `Versus`
  - el summary se finaliza al cierre de mitad por `L4D2_OnEndVersusModeRound_Post`
- `Scavenge`
  - el summary se finaliza al cierre de mitad/ronda canónica manejada por `scavenge_round_finished`

El summary no reemplaza:

- el stream de `eventId`
- los `boss sessions`

Es una vista compacta de cierre para consumo externo.

El payload se consulta con:

```sourcepawn
native bool PlayerSkills_IsSummaryValid(int summaryId);
native bool PlayerSkills_FillSummaryKeyValues(int summaryId, Handle kv);
```

## Summary Payload

Ejemplo base:

```text
summary
{
    "id"                "4"
    "map"               "c8m1_apartment"
    "total_events"      "18"
    "created_at"        "1234.50"

    "context"
    {
        "base_mode"             "2"
        "base_mode_name"        "Versus"
        "survivor_limit"        "4"
        "infected_limit"        "4"
        "si_pool_mask"          "63"
        "enabled_si_classes"    "6"
        "team_size"             "4"
        "versus_context"        "4"
        "versus_context_name"   "Versus4v4"
    }

    "entries_count"     "3"
    "entries"
    {
        "0"
        {
            "team"          "2"
            "team_name"     "survivor"
            "userid"        "41"
            "accountid"     "123456"
            "name"          "Lechuga"
            "bot"           "0"

            "counts"
            {
                "HunterSkeet"       "1"
                "BoomerPop"         "1"
                "SmokerKill"        "2"
            }
        }

        "1"
        {
            "team"          "3"
            "team_name"     "infected"
            "userid"        "0"
            "accountid"     "0"
            "name"          "IA"
            "bot"           "1"

            "counts"
            {
                "HunterHighPounce"  "1"
                "BoomerVomitLanded" "1"
            }
        }
    }
}
```

## KeyValues Native

```sourcepawn
native bool PlayerSkills_FillEventKeyValues(int eventId, Handle kv);
```

Este native escribe los datos útiles del evento:

- metadata del evento
- actor principal
- lista de asistencias
- contexto específico de la skill dentro de `skill_properties`

No incluye:

- víctima
- tablas completas de daño de boss
- strings ya formateados para chat

## Summary Native

```sourcepawn
native bool PlayerSkills_IsSummaryValid(int summaryId);
native bool PlayerSkills_FillSummaryKeyValues(int summaryId, Handle kv);
```

`PlayerSkills_FillSummaryKeyValues(...)` escribe:

- metadata del snapshot
- contexto del modo
- lista agregada de actores por equipo
- counts por `L4D2SkillType`

No incluye:

- strings renderizados para chat o consola
- payload crudo de cada `eventId`
- tablas completas de daño de `Tank/Witch`

## Payload Structure

Ejemplo base:

```text
event
{
    "id"                "18"
    "type_id"           "1"

    "actor_userid"      "41"
    "actor_accountid"   "123456"
    "actor_name"        "Lechuga"
    "actor_bot"         "0"

    "assists_count"     "1"

    "assists"
    {
        "0"
        {
            "userid"        "42"
            "accountid"     "654321"
            "name"          "Pasta"
            "bot"           "0"
        }
    }

    "skill_properties"
    {
        "damage"            "250"
        "chip_damage"       "40"
        "shots"             "2"
    }
}
```

## Contract Rules

- `type_id` es el valor numérico actual del enum.
- el nombre de la skill se resuelve externamente con la tabla pública `g_sL4D2SkillType`.
- `actor_*` incluye:
  - `userid`
  - `accountid`
  - `name`
  - `bot`
- `assists` siempre es una lista, incluso con `0` o `1` entradas.
- `skill_properties` contiene solo los campos relevantes de esa skill.
- `summary.entries[].counts` usa claves con el nombre canónico de `L4D2SkillType`.
- en summaries, infectados bot se compactan en una entrada `IA` por equipo.
- `WitchIncap` no entra al summary compacto.
- `WitchDead` solo entra al summary si `crown=1`.

## Current Skill Set

Skills implementadas hoy:

- `HunterSkeet`
- `HunterSkeetMelee`
- `HunterDeadstop`
- `BoomerPop`
- `ChargerLevel`
- `TankDead`
- `WitchDead`
- `WitchIncap`
- `SmokerTongueCut`
- `SmokerSelfClear`
- `TankRockSkeet`
- `TankRockHit`
- `HunterHighPounce`
- `JockeyHighPounce`
- `ChargerInstaKill`
- `ChargerDeathSetup`
- `SpecialPinClear`
- `BoomerVomitLanded`
- `BunnyHopStreak`
- `CarAlarmTriggered`
- `SmokerKill`
- `BoomerKill`
- `HunterKill`
- `SpitterKill`
- `JockeyKill`
- `ChargerKill`

## Event Examples

### HunterSkeet

```text
event
{
    "id"                    "18"
    "type_id"               "1"

    "actor_userid"          "41"
    "actor_accountid"       "123456"
    "actor_name"            "Lechuga"
    "actor_bot"             "0"

    "assists_count"         "1"

    "assists"
    {
        "0"
        {
            "userid"        "42"
            "accountid"     "654321"
            "name"          "Pasta"
            "bot"           "0"
        }
    }

    "skill_properties"
    {
        "damage"                "250"
        "chip_damage"           "40"
        "shots"                 "2"
        "would_qualify_at_baseline"   "1"
        "headshot"              "1"
        "sniper"                "1"
    }
}
```

### HunterSkeetMelee

```text
event
{
    "id"                    "19"
    "type_id"               "2"

    "actor_userid"          "41"
    "actor_accountid"       "123456"
    "actor_name"            "Lechuga"
    "actor_bot"             "0"

    "assists_count"         "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "damage"                    "250"
        "shots"                     "1"
        "would_qualify_at_baseline" "1"
        "perfect"                   "1"
    }
}
```

### Skeet con Grenade Launcher

```text
event
{
    "id"                    "20"
    "type_id"               "1"

    "actor_userid"          "41"
    "actor_accountid"       "123456"
    "actor_name"            "Lechuga"
    "actor_bot"             "0"

    "assists_count"         "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "damage"                    "250"
        "shots"                     "1"
        "would_qualify_at_baseline" "1"
        "grenade_launcher"          "1"
    }
}
```

### HunterDeadstop

```text
event
{
    "id"                    "21"
    "type_id"               "3"

    "actor_userid"          "41"
    "actor_accountid"       "123456"
    "actor_name"            "Lechuga"
    "actor_bot"             "0"

    "assists_count"         "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "with_shove"        "1"
        "reported_high"     "1"
    }
}
```

### HunterHighPounce

```text
event
{
    "id"                    "22"
    "type_id"               "13"

    "actor_userid"          "13"
    "actor_accountid"       "0"
    "actor_name"            "Hunter"
    "actor_bot"             "1"

    "assists_count"         "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "damage"                "24"
        "calculated_damage"     "24.7"
        "height"                "463.0"
        "distance"              "887.0"
        "reported_high"         "1"
        "incapped"              "1"
    }
}
```

### JockeyHighPounce

```text
event
{
    "id"                    "23"
    "type_id"               "14"

    "actor_userid"          "14"
    "actor_accountid"       "0"
    "actor_name"            "Jockey"
    "actor_bot"             "1"

    "assists_count"         "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "height"                "352.0"
        "reported_high"         "1"
    }
}
```

### SpecialPinClear

```text
event
{
    "id"                    "24"
    "type_id"               "17"

    "actor_userid"          "41"
    "actor_accountid"       "123456"
    "actor_name"            "Lechuga"
    "actor_bot"             "0"

    "pinvictim_userid"      "42"
    "pinvictim_accountid"   "654321"
    "pinvictim_name"        "Pasta"
    "pinvictim_bot"         "0"

    "assists_count"         "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "zombie_class"          "1"
        "time_a"                "0.4"
        "time_b"                "0.9"
        "with_shove"            "1"
    }
}
```

### BoomerPop

```text
event
{
    "id"                "24"
    "type_id"           "4"

    "actor_userid"      "41"
    "actor_accountid"   "123456"
    "actor_name"        "Lechuga"
    "actor_bot"         "0"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "shove_count"    "1"
        "time_a"         "1.7"
    }
}
```

### BoomerVomitLanded

```text
event
{
    "id"                "25"
    "type_id"           "18"

    "actor_userid"      "12"
    "actor_accountid"   "0"
    "actor_name"        "Boomer"
    "actor_bot"         "1"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "amount"         "3"
    }
}
```

### ChargerLevel

```text
event
{
    "id"                "27"
    "type_id"           "5"

    "actor_userid"      "41"
    "actor_accountid"   "123456"
    "actor_name"        "Lechuga"
    "actor_bot"         "0"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "damage"        "410"
        "chip_damage"   "190"
        "would_qualify_at_baseline" "1"
    }
}
```

### ChargerInstaKill

```text
event
{
    "id"                "28"
    "type_id"           "15"

    "actor_userid"      "15"
    "actor_accountid"   "0"
    "actor_name"        "Charger"
    "actor_bot"         "1"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "zombie_class"      "6"
        "height"            "428.0"
        "distance"          "610.0"
        "was_carried"       "1"
        "damage"            "150"
        "incapped"          "1"
        "ledge_hang"        "1"
        "fatal_fall"        "1"
        "deadly_slam"       "1"
    }
}
```

### ChargerDeathSetup

```text
event
{
    "id"                "29"
    "type_id"           "16"

    "actor_userid"      "15"
    "actor_accountid"   "0"
    "actor_name"        "Charger"
    "actor_bot"         "1"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "zombie_class"      "6"
        "was_carried"       "1"
        "incapped"          "1"
        "ledge_hang"        "0"
    }
}
```

### WitchDead

```text
event
{
    "id"                "31"
    "type_id"           "7"

    "actor_userid"      "41"
    "actor_accountid"   "123456"
    "actor_name"        "Lechuga"
    "actor_bot"         "0"

    "assists_count"     "1"

    "assists"
    {
        "0"
        {
            "userid"        "42"
            "accountid"     "654321"
            "name"          "Pasta"
            "bot"           "0"
        }
    }

    "skill_properties"
    {
        "damage"        "1000"
        "chip_damage"   "300"
        "shots"         "1"
        "crown"         "1"
        "startled"      "1"
    }

    "witch_session"
    {
        "alive_time"    "18.4"
        "startled"      "1"
        "total_damage"  "1000"
    }
}
```

### WitchIncap

```text
event
{
    "id"                "32"
    "type_id"           "8"

    "actor_userid"      "0"
    "actor_accountid"   "0"
    "actor_name"        "Witch"
    "actor_bot"         "1"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "amount"        "220"
        "startled"      "1"
    }

    "witch_session"
    {
        "alive_time"    "12.6"
        "startled"      "1"
        "total_damage"  "780"
    }
}
```

### TankDead

```text
event
{
    "id"                "34"
    "type_id"           "6"

    "actor_userid"      "41"
    "actor_accountid"   "123456"
    "actor_name"        "Lechuga"
    "actor_bot"         "0"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
    }

    "tank_session"
    {
        "rocks_thrown"  "5"
        "rocks_hit"     "2"
        "incaps"        "3"
        "kills"         "1"
        "wipe"          "0"
        "alive_time"    "42.8"
    }
}
```

### TankRockSkeet

```text
event
{
    "id"                "37"
    "type_id"           "11"

    "actor_userid"      "41"
    "actor_accountid"   "123456"
    "actor_name"        "Lechuga"
    "actor_bot"         "0"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
    }
}
```

### TankRockHit

```text
event
{
    "id"                "38"
    "type_id"           "12"

    "actor_userid"      "7"
    "actor_accountid"   "0"
    "actor_name"        "Tank"
    "actor_bot"         "1"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
    }
}
```

### CarAlarmTriggered

```text
event
{
    "id"                "39"
    "type_id"           "20"

    "actor_userid"      "41"
    "actor_accountid"   "123456"
    "actor_name"        "Lechuga"
    "actor_bot"         "0"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "reason"            "2"
        "indirect"          "1"
        "forced"            "1"
    }
}
```

### BunnyHopStreak

```text
event
{
    "id"                "40"
    "type_id"           "19"

    "actor_userid"      "41"
    "actor_accountid"   "123456"
    "actor_name"        "Lechuga"
    "actor_bot"         "0"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "streak"            "4"
        "max_velocity"      "412.6"
    }
}
```

## Notes

### Assists

`assists` no representa necesariamente la tabla completa de daño de una entidad.  
Representa solo los jugadores que el evento considera asistentes relevantes para esa skill.

En `simple kills`:

- `assists` puede crecer hasta el límite interno del evento
- el announce visible además se limita por `survivor_limit - 1`

### Bosses

Las tablas de daño de `Tank` y `Witch` siguen siendo responsabilidad del sistema de tracking y announcer de bosses.  
No es necesario incluir esas tablas dentro del KV del evento para que la API siga siendo práctica y replicable.

Los summaries de cierre tampoco duplican esas tablas completas.  
Si un consumidor necesita detalle de boss:

- usa `PlayerSkills_OnBossDamageFinalized`
- consulta los natives de boss por `sessionId`

### Optional Fields

No todas las skills necesitan los mismos campos.

Ejemplos:

- `Skeet` necesita `damage`, `chip_damage`, `shots`, `would_qualify_at_baseline`
- `BoomerPop` necesita `shove_count`, `time_a`
- `ChargerLevel` usa `damage`, `chip_damage` y `would_qualify_at_baseline`
- `TankDead` usa `tank_session`
- `WitchDead` usa `damage`, `chip_damage`, `shots`, `crown`, `startled` y `witch_session` según el caso
- `WitchIncap` usa `amount`, `startled` y `witch_session`
- `TankRockSkeet` y `TankRockHit` no agregan propiedades especiales hoy
- `CarAlarmTriggered` usa `reason`, `indirect` y `forced`; además puede incluir el infectado responsable en `victim`
- `BunnyHopStreak` necesita `streak` y `max_velocity`

La regla actual es agregar contexto solo cuando ayude a reconstruir el significado real del evento.
