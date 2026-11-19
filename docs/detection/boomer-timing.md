# Resolución de BoomerKill y BoomerPop

`player_death` puede crear un `BoomerKill` provisional. Si llega una explosión
admisible, `BoomerPop` tiene prioridad. La espera mínima de 100 ms no decide
el resultado mientras Pop sigue siendo admisible. Para un spawn conocido, lo
resuelve la señal de explosión o el límite de 3 s. Una vida nueva, un cambio de
identidad o el cierre invalidan el candidato. El Kill conserva el alcance
`LifeKill` y el Pop conserva `SkillWindow`.

## Spawn desconocido

Si el plugin carga tarde o no observó el spawn, la edad se conserva como
desconocida. Un Pop tardío puede publicar `time_a=0`. Una prueba simulada
reprodujo una muerte sin explosión ni otra señal resolutiva. En ese caso, el
timer marca `killDelayElapsed` y el candidato sigue sin publicarse hasta que
una señal lo resuelva o el contexto quede invalidado.

La observación en SRCDS sigue pendiente. `boomer_exploded` entrega el
userid, el atacante y `splashedbile`. Los getters de spawn de Left4DHooks
consultados corresponden al próximo respawn como ghost. Para investigar el
orden de eventos, correlaciona por userid, vida, mapa y tick con el
[observador](../../tools/smoke/README.md).
