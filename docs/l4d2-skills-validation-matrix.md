# L4D2 Player Skills: Validation Matrix

Esta matriz sirve para validar manualmente la semántica de payload de:

- `damage`
- `actor_damage`
- `chip_damage`
- `assist_scope`
- `damage_scope`

El objetivo es comprobar que:

- `*Kill` resume la vida completa del SI;
- las skills técnicas resumen solo su ventana técnica;
- `actor_damage` siga la misma semántica que `damage_scope`.

---

## 1. HunterSkeet con chip previo de otro survivor

### Escenario

- survivor `A` chipea al `Hunter` antes de la ventana relevante del pounce;
- survivor `B` hace el skeet final;
- opcionalmente otro survivor aporta daño dentro de la ventana de pounce.

### Expectativa

- skill emitida:
  - `HunterSkeet`
- payload:
  - `damage_scope = SkillWindow`
  - `damage = daño técnico del skeet`
  - `actor_damage = daño técnico del killer dentro del skeet`
  - `chip_damage = baseline - health_before`
- assists:
  - `assist_scope = SkillWindow` solo si hubo contribución contextual dentro del pounce
- no debe heredar assists de la vida completa

---

## 2. HunterKill simple con daño repartido

### Escenario

- varios survivors dañan al `Hunter`;
- no califica como `Skeet`, `SkeetMelee` ni skill más rica;
- uno de ellos hace el último hit.

### Expectativa

- skill emitida:
  - `HunterKill`
- payload:
  - `damage_scope = LifeKill`
  - `damage = daño efectivo/normalizado del killer sobre la vida del Hunter`
  - `actor_damage = daño efectivo/normalizado del killer sobre la vida del Hunter`
- assists:
  - `assist_scope = LifeKill`
  - refleja contribuidores de la vida completa
  - con daño visible normalizado dentro de la vida máxima del SI

---

## 3. SmokerSelfClear con daño contextual

### Escenario

- survivor pinneado logra self-clear;
- hubo daño previo sobre el `Smoker` dentro de la secuencia relevante.

### Expectativa

- skill emitida:
  - `SmokerSelfClear`
- payload:
  - `damage_scope = SkillWindow`
- assists:
  - `assist_scope = SkillWindow` si hubo contribuidores válidos
- no debe transformarse en resumen de vida completa del `Smoker`

---

## 4. BoomerPop con asistencia

### Escenario

- un survivor hace el pop final;
- otro contribuye dentro de la ventana contextual del pop.

### Expectativa

- skill emitida:
  - `BoomerPop`
- payload:
  - `damage_scope = SkillWindow`
- assists:
  - `assist_scope = SkillWindow`
- no debe usar contribuidores de `BoomerKill`

---

## 5. ChargerLevel con chip previo

### Escenario

- el `Charger` recibe chip antes del hit final;
- el kill técnico ocurre en charge y clasifica como `Level`.

### Expectativa

- skill emitida:
  - `ChargerLevel`
- payload:
  - `damage_scope = SkillWindow`
  - `damage = health_before_damage`
  - `actor_damage = health_before_damage`
  - `chip_damage = baseline - health_before_damage`
- assists:
  - `assist_scope = SkillWindow` solo si hubo contribuidores válidos de la ventana

---

## 6. ChargerKill simple con daño repartido

### Escenario

- varios survivors dañan al `Charger`;
- no califica como `Level`, `PerfectLevel` ni `InstaKill`;
- uno de ellos cierra la muerte.

### Expectativa

- skill emitida:
  - `ChargerKill`
- payload:
  - `damage_scope = LifeKill`
  - `damage = daño efectivo/normalizado del killer sobre la vida del Charger`
  - `actor_damage = daño efectivo/normalizado del killer sobre la vida del Charger`
- assists:
  - `assist_scope = LifeKill`

---

## 7. ChargerBowl

### Escenario

- el `Charger` lleva a un survivor;
- impacta a 2 o 3 adicionales;
- luego entra a pummel.

### Expectativa

- skill emitida:
  - `ChargerBowl`
- payload:
  - `damage_scope = SkillWindow`
  - `amount = 2` o `3`
  - `victim = survivor carried`
  - `pinVictim = survivor carried`
- no debe contaminar `ChargerKill`

---

## 8. HunterHighPounce

### Escenario

- el `Hunter` conecta un high pounce válido.

### Expectativa

- skill emitida:
  - `HunterHighPounce`
- payload:
  - `damage_scope = SkillWindow`
  - `damage = daño calculado del pounce`
  - `actor_damage = daño calculado del pounce`

---

## 9. JockeySkeetMelee

### Escenario

- el `Jockey` muere por melee mientras sigue en leap válido.

### Expectativa

- skill emitida:
  - `JockeySkeetMelee`
- payload:
  - `damage_scope = SkillWindow`
  - `damage = vida base del Jockey`
  - `actor_damage = vida base del Jockey`

---

## Criterio de aceptación

La validación se considera correcta si se cumplen simultáneamente estas reglas:

- `*Kill` usa `damage_scope = LifeKill`
- skills técnicas usan `damage_scope = SkillWindow`
- `actor_damage` sigue la misma semántica que `damage_scope`
- `assist_scope` no mezcla `LifeKill` con `SkillWindow`
- `chip_damage` representa daño previo respecto del baseline, no solo daño previo del killer
- `LifeKill` visible usa daño normalizado a la vida del SI
- `SkillWindow` usa daño efectivo/semántico de la jugada
- el `raw damage` puede quedar en tracking interno, no en el announce humano
