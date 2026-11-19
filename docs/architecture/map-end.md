# Cierre de ronda al terminar el mapa

`OnMapEnd` usa el cierre común antes de limpiar identidades, eventos y
sesiones. El cierre detiene la detección, finaliza los bosses, congela ambos
snapshots y publica los resúmenes Skills → Kills. Las natives conservan
los últimos snapshots hasta su sustitución normal.

Si Player-Stats cierra primero, MapEnd limpia la ronda ya finalizada. Si
MapEnd llega primero, el cierre posterior de Player-Stats se descarta. Si
MapEnd llega durante un forward, el cierre en curso conserva ambos
resúmenes antes de limpiar. Durante el desmontaje se descartan inicios y
señales live. Un cambio de generación por MapStart impide que el mapa
anterior limpie el estado nuevo.

Skills guarda el ID de ronda live y el último ID cerrado del proveedor.
Al retirar Player-Stats se limpian ambos y se invalida el live pendiente.
Una instancia nueva puede volver a empezar por el ID 1. La carga tardía
conserva el camino de cierre cuando falta el ID activo.

Las pruebas locales cubrieron ambos órdenes de notificación y la
reentrada. Consulta los [resultados y sus límites](../validation/README.md).
