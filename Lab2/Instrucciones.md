## Laboratorio: Pipeline DevOps con Make y Bash

Este laboratorio muestra cómo orquestar **lint, tests, build y empaquetado** con un Makefile y Bash "robusto". Está pensado para usarse en **Ubuntu sobre WSL2** (Windows), pero también funciona en Linux nativo.

#### Requisitos

- **Sistema**: Ubuntu (WSL2 o Linux)
- **Herramientas**: `make`, `bash`, `python3`, `grep`, `awk`, `tar` (GNU), `sha256sum` (GNU coreutils)
- **Lint/format**: `shellcheck`, `shfmt`
- **Opcional**: `ruff`, `git`

> Si estás en WSL2 (Windows 10/11), usa **Ubuntu** y abre el repo con **VS Code-Remote WSL** para mejor rendimiento.

#### Instalación rápida en WSL2 (Ubuntu)

1) Actualiza e instala dependencias base:
```bash
sudo apt update
sudo apt install -y make python3-venv python3-pip shellcheck shfmt
````

2. Crea y activa un entorno virtual:

```bash
python3 -m venv cc3s2
source cc3s2/bin/activate
```

3. Instala utilidades de Python:

```bash
pip install -U pip pytest ruff
```

> **Sugerencia WSL2**: Trabaja en `/home/<tu_usuario>/...` en lugar de `/mnt/c/...` para evitar IO lento.

#### Comandos clave del Makefile

```bash
make tools        # verifica dependencias
make all          # lint + build + test + package
make check        # lint + test
make benchmark    # mide tiempos y deja out/benchmark.txt
make verify-repro # construye dos veces y compara SHA256
make format       # formatea scripts con shfmt
make clean        # borra out/ y dist/
make dist-clean   # clean + caches (ruff, __pycache__)
make help         # ayuda autodocumentada
```

Estos objetivos permiten integrar el flujo en CI/CD y garantizar ejecuciones reproducibles.

#### ¿Para qué sirven ShellCheck, Pytest y Ruff aquí?

* **ShellCheck**: *linter* para scripts de shell. Detecta errores de quoting, uso inseguro de variables, tests frágiles, etc. En este proyecto se usa dentro de `make check`/`make tools` para validar scripts de Bash antes de ejecutarlos en el pipeline.
* **shfmt**: formateador para shell. Estándar de estilo consistente vía `make format`.
* **Pytest**: **runner** de pruebas de Python. Aunque el ejemplo usa `unittest`, Pytest ejecuta esas pruebas sin cambios y ofrece reporter/timing muy útiles en CI. Se activa con `make check` o `pytest`.
* **Ruff** (opcional): *linter* y formateador ultrarrápido de Python. Ayuda a mantener calidad estática; si está instalado, el Makefile puede integrarlo en `make check` (lint) y `make dist-clean` (limpieza de cachés).

#### Estructura básica y conceptos

* **Lógica de ejemplo**: una función `greet(name)` devuelve `"Hello, {name}!"` y, si se ejecuta como script, imprime un saludo por consola. Esto sirve como unidad mínima para demostrar **lint, test y empaquetado**.
* **Pruebas**: un test con `unittest` verifica que `greet("Paulette") == "Hello, Paulette!"`. Este test es ejecutable tanto con `python -m unittest` como con `pytest`.
* **Makefile**: orquesta tareas:

  * `make all` encadena lint + build + test + package.
  * `make verify-repro` ejecuta dos construcciones y compara **SHA256** para demostrar **reproducibilidad** (mismo hash → mismo artefacto).
  * `make benchmark` mide tiempos y deja evidencia en `out/`.
  * `make help` auto-documenta objetivos.


#### Flujo sugerido de uso

1. **Preparar entorno** (WSL2 + venv)-ver sección de instalación.
2. **Inspección inicial**:

```bash
make help
make tools
```

3. **Ciclo de desarrollo**:

```bash
make check      # lint + tests
make all        # pipeline completo
make benchmark  # medir tiempos
```

4. **Reproducibilidad**:

```bash
make verify-repro
```

Si los hashes coinciden, el build es determinista (importante para trazabilidad y seguridad de la cadena de suministro).

5. **Limpieza**:

```bash
make clean       # borra artefactos (out/, dist/)
make dist-clean  # además borra cachés (__pycache__, .ruff_cache)
```

#### Ejecución de pruebas

* Con `pytest`:

```bash
pytest -q
```

* Con `unittest`:

```bash
python -m unittest -v
```

El test de ejemplo sobre `greet` valida la salida exacta y sirve como base para añadir más casos (errores, entradas vacías, internacionalización, etc.).

#### Lint y formato

* **Shell**:

  * Lint: `shellcheck` sobre scripts del repo.
  * Formato: `shfmt -w` vía `make format`.
* **Python** (opcional con Ruff):

  * Lint/format: reglas rápidas para estilo, imports, complejidad, etc.

Integrar estos pasos en `make check` previene que código con estilo inconsistente o errores triviales llegue a main.

#### Empaquetado y evidencias

* El pipeline genera artefactos en `dist/` y salidas en `out/` (por ejemplo, tiempos de `benchmark`).
* `verify-repro` compara **SHA256** de artefactos para evidenciar builds **reproducibles**; útil en auditorías y DevSecOps.

#### Solución de problemas

* **WSL2 lento**: evita trabajar en `/mnt/c/...`; clona el repo en `/home/<usuario>/...`.
* **Faltan binarios**: ejecuta `make tools` y sigue las sugerencias; instala lo necesario con `apt`/`pip`.
* **Virtualenv no activo**: `source cc3s2/bin/activate` antes de `pytest`/`make`.

#### Referencias internas del ejemplo

* Implementación de `greet(...)` y ejecución directa del script.
* Prueba unitaria con `unittest` para `greet("Paulette")`.
* Lista de comandos documentados del Makefile en el README original.
