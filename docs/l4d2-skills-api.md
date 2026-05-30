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
forward void PlayerSkills_OnTankSessionClosed(int sessionId, L4D2TankSessionEndReason reason);
forward void PlayerSkills_OnSummaryFinalized(int summaryId);
```

Uso:

- `OnSkillAnnounced`
  - notifica que el plugin ya imprimió el evento
- `OnBossDamageFinalized`
  - permite inspeccionar o suprimir el announce de `Tank/Witch`
- `OnBossDamageAnnounced`
  - notifica que el resumen de boss ya fue impreso
- `OnTankSessionClosed`
  - notifica el cierre semántico de una sesión de `Tank`
  - reasons actuales:
    - `Dead`
    - `Escaped`
    - `Wipe`
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
native bool PlayerSkills_FillBossSessionKeyValues(int sessionId, Handle kv);
```

Este native escribe los datos útiles del evento:

- metadata del evento
- actor principal
- víctima cuando exista
- lista de asistencias
- contexto específico de la skill dentro de `skill_properties`

No incluye:

- tablas completas de daño de boss
- strings ya formateados para chat

## Boss Session Native

```sourcepawn
native bool PlayerSkills_FillBossSessionKeyValues(int sessionId, Handle kv);
```

Este native escribe los datos estructurados de una sesión de boss:

- metadata común de sesión
- `owner` y `pending_owner`
- subestado específico de `tank` o `witch`
- tabla almacenada de `damage_entries`

Sirve cuando el consumidor necesita el snapshot completo de una sesión de boss
sin depender del announce o del runtime vivo.

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

La API actual sigue siendo válida, pero el diseño nuevo de `skill assists`
requiere tratar la asistencia como dato de primer nivel también para consumidores
que no usan `KeyValues`.

## Assist Model

El payload de un evento puede contener asistencia de dos dominios distintos:

- `LifeKill`
  - contribución a la muerte total de la vida del target
- `SkillWindow`
  - contribución dentro de la ventana técnica de la skill

Ejemplos:

- `HunterKill`
  - usa assists de `LifeKill`
- `HunterSkeet`
  - debe usar assists de `SkillWindow`
- `BoomerPop`
  - puede usar assists de `SkillWindow`
- `SmokerSelfClear`
  - puede usar assists de `SkillWindow`
- `ChargerLevel`
  - puede usar assists de `SkillWindow`
- `ChargerInstaKill`
  - puede usar assists de `SkillWindow`

Reglas:

- el formato del payload no cambia;
- cambia la semántica del origen de esos assists;
- esa semántica debe poder consultarse desde API.

## LifeKill vs SkillWindow

La API debe preservar una separación obligatoria entre:

- `LifeKill`
  - resumen total de la vida del target;
  - usado por eventos `*Kill`;
- `SkillWindow`
  - resumen técnico de la jugada;
  - usado por skills ricas o contextuales.

Reglas de consumo:

- `SmokerKill`, `BoomerKill`, `HunterKill`, `SpitterKill`, `JockeyKill` y
  `ChargerKill` deben interpretarse como resumen de vida completa;
- `HunterSkeet`, `BoomerPop`, `SmokerSelfClear`, `ChargerLevel`,
  `ChargerInstaKill` y `ChargerBowl` deben interpretarse como lectura técnica de
  una ventana específica;
- un consumidor externo no debe asumir que `damage` significa lo mismo en un
  `*Kill` y en una skill rica;
- si ambos eventos existen para una misma secuencia, no deben fusionarse como si
  fueran duplicados semánticos: describen capas distintas.

En corto:

- `*Kill` = total life summary.
- `Skill` = technical window summary.
- `damage_scope` permite distinguirlo sin inferencia.

Regla actual de `damage`:

- `damage_scope = LifeKill`
  - `damage` y `actor_damage` representan daño efectivo/normalizado sobre la vida real del SI;
  - el tracking `raw` de la vida puede seguir existiendo internamente, pero no es el valor visible recomendado del payload;
- `damage_scope = SkillWindow`
  - `damage` y `actor_damage` representan daño efectivo/semántico de la jugada,
    no necesariamente el `raw damage` reportado por el motor.

## Current Limitation

Hoy `PlayerSkills_FillEventKeyValues(...)` ya expone:

- `assists_count`
- `assists[].userid`
- `assists[].accountid`
- `assists[].name`
- `assists[].bot`
- `assists[].damage`
- `assists[].shots`
- `assists[].weaponid`
- `damage_scope`

Pero la capa de natives genéricos no expone bien:

- la lista completa de assists por índice;
- el `assists_count`;
- ni el alcance semántico del assist.

Eso obliga a usar `KeyValues` incluso cuando el consumidor solo quiere inspección
estructurada simple.

## Proposed Additive API

La propuesta es ampliar la API sin romper contratos existentes.

### New Enum

```sourcepawn
enum L4D2SkillAssistScope
{
    L4D2SkillAssistScope_None = 0,
    L4D2SkillAssistScope_LifeKill,
    L4D2SkillAssistScope_SkillWindow
}
```

Semántica:

- `None`
  - el evento no usa assists o no aplica
- `LifeKill`
  - los assists representan la muerte total de la vida
- `SkillWindow`
  - los assists representan solo la ventana técnica de la skill

### New Natives

```sourcepawn
native int PlayerSkills_GetEventAssistsCount(int eventId);
native int PlayerSkills_GetEventAssistScope(int eventId);

native int PlayerSkills_GetEventAssistUserId(int eventId, int assistIndex);
native int PlayerSkills_GetEventAssistAccountId(int eventId, int assistIndex);
native bool PlayerSkills_IsEventAssistBot(int eventId, int assistIndex);
native void PlayerSkills_GetEventAssistName(int eventId, int assistIndex, char[] buffer, int maxlen);
native int PlayerSkills_GetEventAssistDamage(int eventId, int assistIndex);
native int PlayerSkills_GetEventAssistShots(int eventId, int assistIndex);
native int PlayerSkills_GetEventAssistWeaponId(int eventId, int assistIndex);
```

Objetivo:

- hacer que la lista de assists sea first-class sin obligar a parsear `KeyValues`;
- mantener `assister` como shortcut del primer assist cuando exista;
- permitir a plugins externos distinguir si el assist es de `LifeKill` o de `SkillWindow`.

## KeyValues Compatibility

`PlayerSkills_FillEventKeyValues(...)` no requiere un cambio rompiente.

La propuesta compatible es:

- mantener `assists_count` y `assists[]` como están hoy;
- agregar dentro de `skill_properties`:

```text
"assist_scope"          "1|2"
"damage_scope"          "1|2"
```

donde:

- `1` = `LifeKill`
- `2` = `SkillWindow`

Para `damage_scope`:

- `1` = `LifeKill`
- `2` = `SkillWindow`

Esto preserva consumidores actuales y permite a consumidores nuevos interpretar
correctamente el origen semántico del assist.

## Technical Context Fields

Hay campos que siguen siendo tecnicos aunque el chat no los use siempre de forma
literal.

Hoy eso aplica especialmente a:

- `chip_damage`
  - representa daño previo respecto del baseline relevante del evento;
  - puede incluir contribución propia del actor y/o de otros jugadores según la skill;
  - sigue siendo util para `perfect`, analytics y consumidores externos;
  - no implica que el announce de chat deba imprimir la palabra `chip`.

Reglas practicas:

- `HunterSkeet`
  - el chat usa `damage/shots`, `perfect` y `assists`;
  - el nombre visible recomendado es:
    - `Skeet`
    - `Skeet Perfecto`
    - `Skeet-Melee`
  - `chip_damage` sigue existiendo en payload.
- `ChargerLevel`
  - el chat usa `Level Perfecto`, `Level`, `Level (dmg/shots)` y `assists`;
  - `chip_damage` sigue existiendo en payload.

Eso implica:

- `HunterSkeet` y `ChargerLevel` ya no deben usar `raw damage` inflado del motor
  para el announce visible;
- `*Kill` simples ya no deben mostrar overkill `raw` en el announce visible;
- el announce humano de `*Kill` debe usar daño normalizado a la vida del SI.

## Perfect Variants

Las variantes `perfect` no deben exponer assists.

Casos ya definidos:

- `PerfectSkeet`
  - no admite assists
- `PerfectLevel`
  - no admite assists

Entonces:

- `assists_count = 0`
- `assist_scope = 0`

en esas variantes.

## Backward Compatibility

La estrategia recomendada es:

1. mantener todos los natives actuales;
2. mantener el formato actual de `FillEventKeyValues(...)`;
3. agregar nuevos natives y `assist_scope`;
4. no reinterpretar en silencio los campos viejos.

Así:

- plugins existentes siguen funcionando;
- plugins nuevos pueden consumir `skill assists` correctamente;
- la semántica del sistema queda explícita.

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
- `WitchDead` no entra al summary compacto.
- `WitchCrown` entra al summary como skill de crown.
- para integraciones de gameplay:
  - consumir `WitchCrown` como skill real,
  - consumir `WitchDead` solo como cierre default de la sesión de `Witch`.

## Current Skill Set

Skills implementadas hoy:

- `HunterSkeet`
- `HunterSkeetMelee`
- `HunterDeadstop`
- `BoomerPop`
- `ChargerLevel`
- `TankDead`
- `WitchDead`
- `WitchCrown`
- `WitchIncap`
- `SmokerTongueCut`
- `SmokerSelfClear`
- `TankRockSkeet`
- `TankRockHit`
- `HunterHighPounce`
- `JockeyHighPounce`
- `SmokerLedgeHang`
- `JockeyLedgeHang`
- `JockeyJumpStop`
- `JockeySkeetMelee`
- `ChargerInstaKill`
- `ChargerDeathSetup`
- `ChargerLedgeHang`
- `ChargerBowl`
- `TankLedgeHang`
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

    "victim_userid"         "17"
    "victim_accountid"      "0"
    "victim_name"           "Hunter (IA)"
    "victim_bot"            "1"

    "assists_count"         "1"

    "assists"
    {
        "0"
        {
            "userid"        "42"
            "accountid"     "654321"
            "name"          "Pasta"
            "bot"           "0"
            "damage"        "84"
            "shots"         "1"
            "weaponid"      "5"
        }
    }

    "skill_properties"
    {
        "damage"                    "166"
        "actor_damage"              "166"
        "assist_scope"              "2"
        "damage_scope"              "2"
        "chip_damage"               "84"
        "shots"                     "1"
        "rating"                    "3"
    }
}
```

Notas:

- `HunterSkeet` sigue siendo el evento base;
- `headshot`, `perfect`, `sniper` y `grenade_launcher` viven como propiedades;
- en chat, `Headshot` tiene prioridad visual sobre `Perfecto` cuando ambas
  aplican;
- el arma visible se deriva de `actor_weaponid`.

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
        "perfect"                   "1"
    }
}
```

### ChargerKill

```text
event
{
    "id"                    "41"
    "type_id"               "28"

    "actor_userid"          "43"
    "actor_accountid"       "222333"
    "actor_name"            "Ellis"
    "actor_bot"             "0"

    "victim_userid"         "19"
    "victim_accountid"      "0"
    "victim_name"           "Charger (IA)"
    "victim_bot"            "1"

    "assists_count"         "1"

    "assists"
    {
        "0"
        {
            "userid"        "44"
            "accountid"     "444555"
            "name"          "Rochelle"
            "bot"           "0"
            "damage"        "201"
            "shots"         "5"
            "weaponid"      "6"
        }
    }

    "skill_properties"
    {
        "damage"            "436"
        "actor_damage"      "436"
        "assister_damage"   "201"
        "assister_shots"    "5"
        "assist_scope"      "1"
        "damage_scope"      "1"
        "shots"             "9"
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

### JockeyJumpStop

```text
event
{
    "id"                    "24"
    "type_id"               "27"

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
    }
}
```

### JockeySkeetMelee

```text
event
{
    "id"                    "25"
    "type_id"               "28"

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
        "damage"                    "325"
        "shots"                     "1"
        "perfect"                   "1"
    }
}
```

### SpecialPinClear

```text
event
{
    "id"                    "24"
    "type_id"               "18"

    "actor_userid"          "41"
    "actor_accountid"       "123456"
    "actor_name"            "Lechuga"
    "actor_bot"             "0"

    "victim_userid"         "16"
    "victim_accountid"      "0"
    "victim_name"           "Smoker (IA)"
    "victim_bot"            "1"

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
        "rating"                "2"
        "time_a"                "0.4"
        "time_b"                "0.9"
        "with_shove"            "1"
    }
}
```

### SmokerKill

```text
event
{
    "id"                    "24"
    "type_id"               "22"

    "actor_userid"          "41"
    "actor_accountid"       "123456"
    "actor_name"            "Lechuga"
    "actor_bot"             "0"

    "victim_userid"         "16"
    "victim_accountid"      "0"
    "victim_name"           "Smoker (IA)"
    "victim_bot"            "1"

    "assists_count"         "1"

    "assists"
    {
        "0"
        {
            "userid"        "42"
            "accountid"     "654321"
            "name"          "Pasta"
            "bot"           "0"
            "damage"        "33"
            "shots"         "2"
            "weaponid"      "5"
        }
    }

    "skill_properties"
    {
        "damage"            "270"
        "actor_damage"      "270"
        "assister_damage"   "33"
        "assister_shots"    "2"
        "assist_scope"      "1"
        "damage_scope"      "1"
        "shots"             "3"
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

    "victim_userid"     "0"
    "victim_accountid"  "0"
    "victim_name"       "Boomer (IA)"
    "victim_bot"        "1"

    "assists_count"     "1"

    "assists"
    {
        "0"
        {
            "userid"        "42"
            "accountid"     "654321"
            "name"          "Pasta"
            "bot"           "0"
            "damage"        "19"
            "shots"         "1"
            "weaponid"      "5"
        }
    }

    "skill_properties"
    {
        "assist_scope"      "2"
        "damage_scope"      "2"
        "assister_damage"   "19"
        "assister_shots"    "1"
        "rating"            "2"
        "shove_count"       "1"
        "time_a"            "1.7"
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

    "victim_userid"     "15"
    "victim_accountid"  "0"
    "victim_name"       "Charger (IA)"
    "victim_bot"        "1"

    "assists_count"     "1"

    "assists"
    {
        "0"
        {
            "userid"        "42"
            "accountid"     "654321"
            "name"          "Pasta"
            "bot"           "0"
            "damage"        "184"
            "shots"         "1"
            "weaponid"      "19"
        }
    }

    "skill_properties"
    {
        "assist_scope"                "2"
        "damage_scope"                "2"
        "damage"                      "600"
        "actor_damage"                "600"
        "assister_damage"             "184"
        "assister_shots"              "1"
        "rating"                      "2"
        "shots"                       "1"
        "chip_damage"                 "184"
    }
}
```

Notas:

- si `perfect = 1`, el evento representa `PerfectLevel`;
- si `perfect` no existe y `chip_damage > 0` o hay assists, representa la variante
  no perfect de `Level`;
- el announce visible no necesita imprimir la palabra `chip`.

### ChargerBowl

```text
event
{
    "id"                "28"
    "type_id"           "17"

    "actor_userid"      "15"
    "actor_accountid"   "0"
    "actor_name"        "Charger (IA)"
    "actor_bot"         "1"

    "victim_userid"     "41"
    "victim_accountid"  "123456"
    "victim_name"       "Lechuga"
    "victim_bot"        "0"

    "pinvictim_userid"  "41"
    "pinvictim_accountid" "123456"
    "pinvictim_name"    "Lechuga"
    "pinvictim_bot"     "0"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "amount"        "3"
        "rating"        "3"
        "zombie_class"  "6"
    }
}
```

Announce esperado:

- si `amount = 2`

```text
[★★] Charger (IA) hizo Ariete impactando a patitas y lechuga.
```

- si `amount = 3`

```text
[★★★] Charger (IA) hizo Ariete impactando a todo el equipo.
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
        "fatal_fall"        "1"
        "deadly_slam"       "1"
    }
}
```

### ChargerLedgeHang

```text
event
{
    "id"                "29"
    "type_id"           "19"

    "actor_userid"      "15"
    "actor_accountid"   "0"
    "actor_name"        "Charger"
    "actor_bot"         "1"

    "victim_userid"     "41"
    "victim_accountid"  "123456"
    "victim_name"       "Lechuga"
    "victim_bot"        "0"

    "assists_count"     "0"

    "assists"
    {
    }

    "skill_properties"
    {
        "zombie_class"      "6"
        "was_carried"       "1"
        "ledge_hang"        "1"
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
            "damage"        "500"
            "shots"         "1"
        }
    }

    "skill_properties"
    {
        "damage"        "500"
        "actor_damage"  "500"
        "chip_damage"   "500"
        "damage_scope"  "2"
        "shots"         "1"
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

Notas:

- `WitchDead` es el cierre default de la sesión de `Witch`.
- cuando no hubo `WitchCrown`, el announce visible asociado es el resumen
  tradicional de daño hecho a la `Witch`.
- `WitchDead` no debe interpretarse como skill de crown.
- para gameplay y analytics de skills, preferir `WitchCrown`.

### WitchCrown

```text
event
{
    "id"                "31"
    "type_id"           "30"

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
            "damage"        "500"
            "shots"         "1"
        }
    }

    "skill_properties"
    {
        "damage"        "500"
        "actor_damage"  "500"
        "chip_damage"   "500"
        "damage_scope"  "2"
        "shots"         "1"
        "crown"         "1"
        "perfect"       "0"
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

Notas:

- `WitchCrown` usa `damage_scope = SkillWindow`.
- `damage` y `actor_damage` representan daño efectivo sobre la vida real de la
  `Witch`, no overkill `raw`.
- `assists[]` para `WitchCrown` usa contributors reales de la sesión de daño de
  la `Witch`, con su `damage/shots` acumulado.
- `perfect=1` implica `Crown Perfecta`.
- `WitchCrown` es el evento canónico para integrar crowns desde la API.

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
        "alive_time"    "42.8"
    }
}
```

### Boss Session

```text
boss_session
{
    "id"                "12"
    "type"              "1"
    "state"             "2"
    "max_health"        "4000"
    "last_health"       "0"
    "total_damage"      "4000"
    "started_at"        "1200.50"
    "closed_at"         "1243.30"
    "alive_time"        "42.8"

    "owner_userid"      "7"
    "owner_accountid"   "123456"
    "owner_name"        "Test-Subject"
    "owner_bot"         "0"

    "pending_owner_userid"      "0"
    "pending_owner_accountid"   "0"
    "pending_owner_name"        ""
    "pending_owner_bot"         "0"

    "tank_session"
    {
        "rocks_thrown"  "5"
        "rocks_hit"     "2"
        "in_stasis"     "0"
        "end_reason"    "1"
    }

    "damage_entries_count" "3"
    "damage_entries"
    {
        "0"
        {
            "userid"        "41"
            "accountid"     "123456"
            "name"          "Lechuga"
            "bot"           "0"
            "damage"        "4200"
            "shots"         "14"
        }
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

El ownership interno de boss session ahora está separado por subtipo:

- estado común de sesión
- subestado `tank`
- subestado `witch`

Eso permite que múltiples `Tank` o múltiples `Witch` convivan sin compartir estado fino entre sesiones.

Los summaries de cierre tampoco duplican esas tablas completas.  
Si un consumidor necesita detalle de boss:

- usa `PlayerSkills_OnBossDamageFinalized`
- consulta los natives de boss por `sessionId`

### Optional Fields

No todas las skills necesitan los mismos campos.

Ejemplos:

- `Skeet` necesita `damage`, `chip_damage`, `shots` y `perfect` cuando aplique
- `BoomerPop` necesita `shove_count`, `time_a`
- `ChargerLevel` usa `damage`, `chip_damage` y `perfect` cuando aplique
- `TankDead` usa `tank_session`
- `WitchDead` usa contexto de cierre y `witch_session`
- `WitchCrown` usa `damage`, `chip_damage`, `shots`, `crown`, `perfect`, `startled` y `witch_session`
- `WitchIncap` usa `amount`, `startled` y `witch_session`
- `TankRockSkeet` y `TankRockHit` no agregan propiedades especiales hoy
- `CarAlarmTriggered` usa `reason`, `indirect` y `forced`; además puede incluir el infectado responsable en `victim`
- `BunnyHopStreak` necesita `streak` y `max_velocity`
- `SmokerSelfClear`
  - puede incluir `with_shove` y `headshot`;
  - `with_shove` identifica la variante mecánica `SelfClear-Shove`;
  - `headshot` identifica la propiedad visual `SelfClear Headshot` en la ruta kill

Notas prácticas:

- `victim_*` aparece cuando el evento tiene una víctima semántica útil
- `pinvictim_*` aparece cuando el evento además necesita identificar al survivor dominado o cargado
- `assist_scope`
  - `1` = `LifeKill`
  - `2` = `SkillWindow`
- `damage_scope`
  - `1` = `LifeKill`
  - `2` = `SkillWindow`

La regla actual es agregar contexto solo cuando ayude a reconstruir el significado real del evento.

Notas de session payload:

- `tank_session`
  - expone hoy solo los datos que `PlayerSkills` considera propios del dominio de skills de boss:
    - `rocks_thrown`
    - `rocks_hit`
    - `alive_time`
- `boss_session`
  - expone el snapshot completo de la sesión de boss:
    - estado común
    - `owner`
    - `pending_owner`
    - `damage_entries`
    - subestado `tank` o `witch`
- `witch_session`
  - expone el contexto de cierre relevante para `Witch`:
    - `alive_time`
    - `startled`
    - `total_damage`

Contadores más ricos de performance de `Tank` como `punches`, `hittables`, `incaps` o `kills`
deben vivir en `PlayerStats`, no en `PlayerSkills`.

## Chat vs Payload

El payload API y el announce de chat no tienen por qué usar exactamente el mismo
lenguaje.

Regla actual:

- el payload conserva contexto tecnico como `chip_damage`, `damage_scope` y
  `assist_scope`;
- el chat prioriza lectura corta y semantica de jugada.

Ejemplos:

- `HunterSkeet`
  - payload puede incluir `chip_damage`;
  - chat puede omitir la palabra `chip` y mostrar solo `(damage/shots)` y assists;
  - el chat puede preferir `Skeet Headshot` o `Skeet Perfecto` segun la prioridad visual actual.
- `ChargerLevel`
  - payload puede incluir `chip_damage`;
  - chat puede mostrar `Level (dmg/shots)` en vez de wording explicito de chip.
- `SmokerSelfClear`
  - payload puede incluir `with_shove` y `headshot`;
  - chat puede mostrar `SelfClear`, `SelfClear Headshot` o `SelfClear-Shove`
    sin cambiar el `skill type` base.
