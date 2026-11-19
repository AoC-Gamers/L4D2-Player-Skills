# Desarrollo SourcePawn

## Traducciones y colores

Coloca las frases visibles en `addons/sourcemod/translations/` y cárgalas
con `LoadTranslations`. Las traducciones comparten claves y tipos de
argumentos definidos en `#format`. Usa `%T` con el destinatario explícito y
`%t` cuando la salida ya tiene un destinatario de traducción. En anuncios a
todos los jugadores, formatea por cliente para respetar su idioma.

En chat, usa `{olive}` para el prefijo y vuelve a `{default}` antes del
mensaje. `{green}`, `{lightgreen}` y `{olive}` sirven para énfasis neutro.
Reserva `{red}`, `{blue}` o `{teamcolor}` para mensajes que necesitan
representar un equipo. `colors.inc` admite un solo color de equipo por
mensaje. Usa `{olive}` como acento neutro en L4D2.

## Estilo

Usa nombres que indiquen el propósito de cada variable y función, y conserva
la convención del módulo al modificar código existente. Los enums y constantes
deben representar estados o decisiones del dominio. Mantén nombres, firmas y
valores de los enums públicos compatibles con sus consumidores.

Consulta la [guía de compilación](../build/README.md).

Consulta también la [limpieza al descargar un plugin](unload.md).
