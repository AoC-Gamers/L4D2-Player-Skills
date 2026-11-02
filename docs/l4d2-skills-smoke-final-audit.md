# Auditoría final del smoke de Skills

## Estado

Auditoría e integración locales completadas con tres subagentes GPT-6 Luna en
razonamiento alto. El agente principal revisó los hallazgos y las pruebas,
reprodujo defectos, integró las correcciones y ejecutó la validación final.
El observador standalone pasa a 1.1.1. No se instaló nada, no se consultó ni
modificó competitive_dev, no se tocó Player-Stats ni se publicó.
Las 60 fuentes de producto de Skills permanecen idénticas al snapshot de esta
iteración; la clasificación de Boomer con spawn desconocido sigue pendiente.

## Cobertura confirmada por inspección y gates locales

- Engine: los 38 registros usados por Skills están contenidos en los 301 nombres
  del JSON más `player_spawn` suplementario (302).
- SDKHooks: cinco tipos y 13 sitios del core, más los forwards globales
  OnEntityCreated/OnEntityDestroyed. Se conservan targets y fases.
- Left4DHooks: 26 callbacks. Una prueba nueva contrasta firma completa con los
  forwards del include: retorno, orden/tipo, const, byref y dimensiones de arrays;
  exige que cada argumento sea serializado. Las 18 consultas siguen clasificadas
  como tres natives y 15 stocks, con muestra manual o razón de omisión.

No se encontró una omisión actual en esas listas. El inventario de módulos
privados también admite `.inc`, para que un movimiento interno futuro no borre
silenciosamente sus sitios SDKHook. Estas verificaciones acreditan código y
schema, no la disponibilidad efectiva de un hook/detour en un gameserver.

## Hallazgos verificados y corregidos

### SDKHooks ausente o recargado durante captura

Antes solo se intentaba construir inventario al iniciar captura/mapa. Una alta
posterior no reconstruía entidades existentes; una retirada/alta podía dejar
flags de hooks de la instancia anterior. Los callbacks de biblioteca ahora
marcan sincronización/invalidación y la recepción de la señal; OnGameFrame
reconcilia después. Al retirar SDKHooks se descartan ledger y frames antiguos
sin hacer SDKUnhook a través de un proveedor nuevo. La reconstrucción vuelve a
escanear clientes y clases existentes. Los hooks nuevos se suspenden mientras
hay invalidación pendiente. Stop tampoco desmonta el ledger retirado mediante
el proveedor recién cargado.

La VM reproduce el fallo con los callbacks anteriores y pasa con los actuales,
incluidos ausencia→alta, retirada/alta en un mismo frame y captura parada.
Es una prueba de control de flujo con Start/SDK nativos simulados, no una recarga
real de la extensión dentro de SRCDS.

### Referencias de entidad negativas y no-edict

El helper resolvía como referencia solo números positivos grandes. SourceMod usa
el bit 31 como indicador de referencia (`core/HalfLife2.cpp`, ReferenceToIndex),
por lo que las referencias correctas son celdas negativas. El helper ahora usa
EntRefToEntIndex para indices y referencias; no restringe entidades válidas al
máximo de edicts. Conserva el raw y una referencia expirada sin reasociarla a un
slot reciclado. World/0 puede resolverse como entidad sin intentar consultar
userdata de cliente 0.

La función real extraída falla antes y pasa después con seis casos: referencia
negativa vigente, expirada, entidad no-networked, world, -1 inválido y jugador
con userid/serial/generación. Los resolvers y lecturas de contexto son stubs;
la semántica del bit se verificó en la implementación local de SourceMod.

### Health escrito antes del vaciado de datos

El cierre anterior escribía health antes de FlushTrace; una falla de ese flush
podía dejar health=0 en el archivo. Ahora se vacían primero los datos y luego se
escribe health con `scope=through_payload_flush`. Una prueba de la función real
StopTrace inyecta fallo de flush: el baseline no lo refleja y el actual sí.
La prueba comprueba también nulificación de handles y Stop repetido.

El último flush, que persiste el propio health, aún puede fallar: ningún registro
puede garantizar su propia persistencia futura. El status posterior y los errores
de SourceMod siguen siendo necesarios. El validador no ofrece esa garantía.

### Fixture que podía ocultar un fallo anterior

La nueva fixture de recarga inicialmente reseteaba su acumulador de fallos entre
escenarios y modelaba incorrectamente la disponibilidad al añadir el proveedor.
El principal reprodujo salida con dos `FAIL` y código final cero. Se corrigieron
ambas cosas, se rechaza cualquier `FAIL` en stdout y una prueba inyecta un fallo
en el primer escenario para exigir código distinto de cero al terminar los tres.
Las pruebas posteriores sí conservan fallos entre escenarios.

## Correlación y formato

Se añadió `tools/smoke/validate_smoke_trace.py`. Valida las tres sesiones por
run_id/hash, headers globales únicos y contiguos desde 1, ownership de seq por
archivo, límites start/stop, eventos completos, strings y health. Al unir los
headers por seq comprueba epochs y ticks; el test cruzado detecta una regresión
que pasa si cada archivo se mira solo. Un tick compartido no se interpreta como
misma causa o misma fase. Una regresión de reloj/contexto requiere diagnóstico y
no demuestra por sí sola un fallo del motor.

El serializador real TraceTextValue se ejecuta en VM con la frontera de salida
y FormatEx sustituidos por adaptadores. Pasan comillas, barras, controles, cadena
vacía, bytes UTF-8 cruzando el límite 128 y 4095 bytes. No se confirmó defecto en
la inicialización del contador de salida. Los campos float mantienen texto y
bits; JSON numérico no estándar se rechaza, sin rechazar el texto `nan`/`inf` de
un payload float. El validador devuelve errores para tipos malformados y archivos
parciales en lugar de tratarlos como capturas válidas.

`valid=true` significa integridad estructural. No prueba cobertura semántica de
todos los campos internos, callbacks que no ocurrieron, memoria/gamedata correcta,
causalidad, orden agregado de listeners ni equivalencia baseline/refactor.

## Hallazgo descartado

Se propuso que al fallar el segundo/tercer OpenFile, delete dejaba el elemento de
array distinto de null. Fue un falso positivo: la VM confirmó que el compilador
nulifica el lvalue, incluso en array. No se cambió ese comportamiento correcto.
Los archivos parciales se preservan y el validador los rechaza por falta de
cabeceras/cierre/health; no se borran evidencias para ocultar el fallo.

## Validación y evidencia

Se ejecutan **31 pruebas Python**, que incluyen compilación y funciones reales
de SourcePawn en spshell con stubs. Las 23 verificaciones de pasividad y cinco
casos diferidos previos siguen pasando; se añaden firmas, recarga, formato,
referencias, cierre y pruebas de fallo del propio harness.

Evidencia de esta iteración: `.build/refactor/smoke-final-audit/`:

- `before/`: snapshot de fuentes, docs, herramientas y binarios anteriores.
- `all-tests.log`: suite completa, sin SKIP en este entorno.
- `red-green.json` y `vm/`: fallos anteriores reproducidos y casos actuales verdes
  para recarga, referencias y cierre; logs de la fixture falsa verde preservados.
- `observer-compile.log`, build/consumer logs, comparación pública y validación de
  artefacto: core/API/Series y observador sin warnings nuevos; diff-check,
  empaquetado, validadores y release local. Un único SMX sigue en el producto.
- `product-unchanged.json` y `observer-validation.json`: alcance y hashes finales.

## Pendientes concretos

Todas las ejecuciones SRCDS siguen pendientes. Confirmar en servidor autorizado
hooks/detours efectivos, ausencia/recarga SDK real, referencias no-edict y slots,
orden de ticks y fases en cambios de mapa, layout de queued pummel, costes de E/S,
y las familias de la matriz. Archivar los tres logs, status final, errores de
SourceMod, KeyValues API, chat y hashes del binario/catálogo/dependencias. El
[issue de Boomer](l4d2-skills-boomer-unknown-issue.md) requiere esa evidencia antes
de adoptar otra política. competitive_dev permanece reservado.
