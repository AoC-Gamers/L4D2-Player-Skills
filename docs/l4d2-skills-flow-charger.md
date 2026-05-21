# Charger Flows

Este documento resume los flujos actuales de skills relacionadas con `Charger`.

## Skills

- `ChargerLevel`
- `ChargerInstaKill`
- `ChargerDeathSetup`
- `SpecialPinClear` en el contexto de `Charger`

## ChargerLevel

### Sources

- `player_hurt`
- `player_death`
- `SDKHook_OnTakeDamage`
- `SDKHook_OnTakeDamagePost`

### State

- `g_iDetectChargerLastHealth`
- `g_iDetectChargerLastAttacker`
- `g_iDetectChargerLastDamageType`
- `g_iDetectChargerLastHealthBeforeDamage`
- `g_fDetectChargerLastRawDamage`

### Emit

Se emite `ChargerLevel` cuando:

- el `Charger` muere por melee,
- seguía en `charge`,
- y el golpe final cumple el umbral de `level` contra el baseline del `Charger`.

### Properties

- `damage`
- `chip_damage`
- `would_qualify_at_baseline`

### Flow

```mermaid
flowchart TD
    A[player_hurt on Charger] --> B[Track last melee raw damage]
    B --> C[player_death on Charger]
    C --> D{Was charging and killed by melee}
    D -->|no| E[Stop]
    D -->|yes| F{Meets level threshold at baseline}
    F -->|yes| G[Emit ChargerLevel]
    F -->|no| E
```

## ChargerInstaKill

### Sources

- `L4D2_OnStartCarryingVictim_Post`
- `charger_impact`
- `L4D2_OnSlammedSurvivor_Post`
- `L4D_OnFatalFalling`
- `L4D_OnFalling`
- `L4D_OnIncapacitated_Post`
- `player_incapacitated_start`
- `L4D_OnLedgeGrabbed_Post`
- `player_hurt`
- `player_death`

### State

- `g_iDetectChargeOwner`
- `g_bDetectChargeWasCarried`
- `g_fDetectChargeStartTime`
- `g_fDetectChargeOrigin`
- `g_iDetectChargeFlags`
- `g_iDetectChargeMapDamage`
- `g_fDetectChargeLastMapDamageTime`
- `g_fDetectChargeIncapTime`

Flags relevantes:

- `DCFLAG_FALL`
- `DCFLAG_DROWN`
- `DCFLAG_TRIGGER`
- `DCFLAG_HURTLOTS`
- `DCFLAG_AIRDEATH`
- `DCFLAG_KILLEDBYOTHER`
- `DCFLAG_DEADLY`
- `DCFLAG_INCAP`
- `DCFLAG_LEDGE`

### Emit

Se emite `ChargerInstaKill` cuando:

- un survivor queda asociado al flujo de `charge`,
- la muerte final ocurre dentro de la ventana atribuible,
- la muerte viene del desplazamiento, caída, trigger, drown o daño de mapa del flujo,
- y el último infectado responsable sigue siendo el `Charger`.

No se emite si otro SI se vuelve el causante principal de la muerte.

### Properties

- `zombie_class`
- `height`
- `distance`
- `was_carried`
- `damage`
- `incapped`
- `ledge_hang`
- `fatal_fall`
- `deadly_slam`

### Flow

```mermaid
flowchart TD
    A[Charge carry or impact starts] --> B[Bind victim to Charger flow]
    B --> C[Track fall, ledge, incap and map damage]
    C --> D[player_death on victim]
    D --> E{Still attributable to Charger}
    E -->|no| F[Stop]
    E -->|yes| G{Environmental / fatal resolution confirmed}
    G -->|no| F
    G -->|yes| H[Emit ChargerInstaKill]
```

## ChargerDeathSetup

### Sources

- `L4D_OnLedgeGrabbed_Post`
- `L4D_OnIncapacitated_Post`
- `player_incapacitated_start`

### State

Comparte el tracking de víctima de `ChargerInstaKill` y además usa:

- `g_bDetectChargeSetupEmitted`

### Emit

Se emite `ChargerDeathSetup` cuando el `Charger` deja a un survivor:

- colgando de una ledge, o
- incapacitado,

sin mezclar ese resultado con una muerte confirmada.

### Properties

- `zombie_class`
- `was_carried`
- `incapped`
- `ledge_hang`

### Flow

```mermaid
flowchart TD
    A[Charge flow active on survivor] --> B{Ledge grab or incap}
    B -->|no| C[Stop]
    B -->|yes| D{Already emitted for this victim}
    D -->|yes| C
    D -->|no| E[Emit ChargerDeathSetup]
```

## SpecialPinClear with Charger

### Sources

- `L4D2_OnStartCarryingVictim_Post`
- `L4D2_OnPummelVictim_Post`
- `charger_carry_end`
- `player_shoved`
- `player_death`

### State

- `g_iDetectPinnedVictim`
- `g_iDetectPinnerByVictim`
- `g_iDetectPinnedClass`
- `g_fDetectSpecialClearTimeA`
- `g_fDetectSpecialClearTimeB`

Validación adicional actual:

- `L4D2_GetSurvivorVictim`
- `L4D2_IsInQueuedPummel`
- `L4D2_GetQueuedPummelVictim`

### Emit

Se emite `SpecialPinClear` cuando un teammate:

- shovea o mata al `Charger`,
- el `Charger` seguía pinneando de forma válida,
- y el survivor salvado no es el mismo `clearer`.

### Properties

- `zombie_class`
- `time_a`
- `time_b`
- `with_shove`
- `pinvictim_*`

### Flow

```mermaid
flowchart TD
    A[Charger pins survivor] --> B[Track pinner, victim and pin times]
    B --> C[Teammate shoves or kills Charger]
    C --> D{Pin still valid}
    D -->|no| E[Clear stale state]
    D -->|yes| F[Emit SpecialPinClear]
```
