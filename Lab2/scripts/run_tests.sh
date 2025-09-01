#!/usr/bin/env bash
# scripts/run_tests.sh

set -euo pipefail
IFS=$'\n\t'
umask 027
set -o noclobber

# Usa PYTHON del entorno si existe; si no, python3
PY="${PYTHON:-python3}"

# Directorio de código fuente
SRC_DIR="src"

# Archivo temporal
tmp="$(mktemp)"

# Limpieza segura + posible rollback de hello.py si existiera un .bak
cleanup() {
	rc="$1"
	rm -f "$tmp"
	if [ -f "${SRC_DIR}/hello.py.bak" ]; then
		mv -- "${SRC_DIR}/hello.py.bak" "${SRC_DIR}/hello.py"
	fi
	exit "$rc"
}
trap 'cleanup $?' EXIT INT TERM

# Verificación de dependencias
check_deps() {
	local -a deps=("$PY" grep)
	for dep in "${deps[@]}"; do
		if ! command -v "$dep" >/dev/null 2>&1; then
			echo "Error: $dep no está instalado" >&2
			exit 1
		fi
	done
}

# Ejecuta un "test" simple sobre src/hello.py
run_tests() {
	local script="$1"
	local output
	output="$("$PY" "$script")"
	if ! echo "$output" | grep -Fq "Hello, World!"; then
		echo "Test falló: salida inesperada" >&2
		mv -- "$script" "${script}.bak" || true
		exit 2
	fi
	echo "Test pasó: $output"
}

# Demostración de pipefail
echo "Demostrando pipefail:"
set +o pipefail
if false | true; then
	echo "Sin pipefail: el pipe se considera exitoso (status 0)."
fi
set -o pipefail
if false | true; then
	:
else
	echo "Con pipefail: se detecta el fallo (status != 0)."
fi

# Escribir en $tmp (ya existe); '>|' evita el bloqueo de 'noclobber'
cat <<'EOF' >|"$tmp"
Testeando script Python
EOF

# Ejecutar
check_deps
run_tests "${SRC_DIR}/hello.py"
