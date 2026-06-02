# Build System

## Objetivo

Este repositorio usa un flujo unico para:

- compilacion local
- compilacion en CI
- Windows
- Linux
- WSL

La compilacion real vive en scripts Python compartidos, y `make` actua como orquestador.

## Targets

- `make deps-smx`
- `make build-smx`
- `make package-smx`
- `make release`
- `make clean`
- `make clean-all`

## Flujo

1. `deps-smx` descarga el compilador de SourceMod para la plataforma actual.
2. `build-smx` compila los plugins mapeados en `build.plugins`.
3. `build-smx` tambien genera `build-smx-compile.log`.
4. `package-smx` arma el paquete intermedio en `.build/package-smx`.
5. `stage-artifact.py` copia ese build a `dist/sourcemod/artifact` y agrega:
   - `README.md`
   - `docs/`
   - `compile.log`
6. `release` empaqueta `dist/sourcemod/artifact` en un ZIP final.

## Manifiesto

`plugin-package-map.json` define:

- `build.plugins`
- `artifact.addons.sourcemod`

El manifiesto controla:

- que plugins se compilan
- que archivos se copian al artifact publico
- que directorios adicionales se publican

En el arbol de artifact, cada nodo puede usar:

- `files`
- `dirs`
- `all`

Los includes auxiliares locales, como `colors.inc` o `left4dhooks*.inc`, pueden usarse para compilar aunque no formen parte del artifact publico.

## Build Inputs

`build-local.py` compila todos los `*.sp` bajo `addons/sourcemod/scripting/`, pero solo publica los plugins clasificados en `build.plugins`.

Los `include` usados por `spcomp` son:

- `addons/sourcemod/scripting/include`
- `addons/sourcemod/scripting`
- `deps/sourcemod-<platform>/addons/sourcemod/scripting/include`

## Platform Resolution

`fetch-sourcemod.py` detecta la plataforma local y descarga:

- `windows`
- `linux`

Si el repo corre bajo `/mnt/...` en WSL, `build-local.py` usa un workspace temporal en `/tmp/l4d2-player-skills-build` para evitar el costo de I/O sobre el filesystem montado.

## WSL

La optimizacion de workspace temporal se aplica automaticamente cuando el repo vive bajo `/mnt/...`.

## Validation And CI

Workflow principal:

- `.github/workflows/sourcemod-build.yml`

Jobs:

- `deps-smx`
- `build-smx`
- `release`

`ci-validate-artifact.sh` verifica:

- los `.smx` declarados en `build.plugins`
- el arbol publicado por `artifact.addons.sourcemod`
- `README.md`
- `compile.log`
