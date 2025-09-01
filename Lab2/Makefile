SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-builtin-rules
.DELETE_ON_ERROR:
.DEFAULT_GOAL := help
export LC_ALL := C
export LANG   := C
export TZ     := UTC

.PHONY: all build test package clean help lint tools check benchmark format dist-clean verify-repro

PYTHON ?= python3
SHELLCHECK := shellcheck
SHFMT := shfmt
SRC_DIR := src
TEST_DIR := tests
OUT_DIR := out
DIST_DIR := dist

all: tools lint build test package ## Construir, testear y empaquetar todo

build: $(OUT_DIR)/hello.txt ## Generar out/hello.txt

$(OUT_DIR)/hello.txt: $(SRC_DIR)/hello.py
	mkdir -p $(@D)
	$(PYTHON) $< > $@

test: $(SRC_DIR)/hello.py $(TEST_DIR)/test_hello.py scripts/run_tests.sh ## Ejecutar tests
	scripts/run_tests.sh
	$(PYTHON) -m unittest discover -s $(TEST_DIR) -v

package: $(DIST_DIR)/app.tar.gz ## Crear dist/app.tar.gz

$(DIST_DIR)/app.tar.gz: $(OUT_DIR)/hello.txt
	mkdir -p $(@D)
	tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='UTC 1970-01-01' -czf $@ -C $(OUT_DIR) hello.txt

lint: ## Lint Bash y (opcional) Python
	$(SHELLCHECK) scripts/run_tests.sh
	$(SHFMT) -d scripts/run_tests.sh
	@command -v ruff >/dev/null 2>&1 && ruff check $(SRC_DIR) || echo "ruff no instalado; omitiendo lint Python"

tools: ## Verificar dependencias
	@command -v $(PYTHON) >/dev/null || { echo "Falta $(PYTHON)"; exit 1; }
	@command -v $(SHELLCHECK) >/dev/null || { echo "Falta shellcheck"; exit 1; }
	@command -v $(SHFMT) >/dev/null || { echo "Falta shfmt"; exit 1; }
	@command -v grep >/dev/null || { echo "Falta grep"; exit 1; }
	@command -v awk >/dev/null || { echo "Falta awk"; exit 1; }
	@command -v tar >/dev/null || { echo "Falta tar"; exit 1; }
	@tar --version 2>/dev/null | grep -q 'GNU tar' || { echo "Se requiere GNU tar"; exit 1; }
	@command -v sha256sum >/dev/null || { echo "Falta sha256sum"; exit 1; }

check: lint test ## Ejecutar lint y tests

benchmark: | $(OUT_DIR) ## Medir tiempo de ejecución
	@mkdir -p $(OUT_DIR)
	@echo "Benchmark: $(shell date '+%Y-%m-%d %H:%M:%S') / Commit: $(shell git rev-parse --short HEAD 2>/dev/null || echo 'N/A')" > $(OUT_DIR)/benchmark.txt
	@if command -v /usr/bin/time >/dev/null 2>&1; then \
	  /usr/bin/time -f "Tiempo: %E" make all >> $(OUT_DIR)/benchmark.txt 2>&1; \
	else \
	  time -p make all >> $(OUT_DIR)/benchmark.txt 2>&1; \
	fi

format: ## Formatear scripts con shfmt
	$(SHFMT) -w scripts/run_tests.sh

dist-clean: clean ## Limpiar todo (incluye caches opcionales)
	@find . -type d -name '__pycache__' -prune -exec rm -rf {} +
	@rm -rf .ruff_cache

verify-repro: ## Verificar que dist/app.tar.gz sea 100% reproducible
	@rm -rf $(OUT_DIR) $(DIST_DIR); $(MAKE) -s package
	@cp $(DIST_DIR)/app.tar.gz app1.tar.gz
	@rm -rf $(OUT_DIR) $(DIST_DIR); $(MAKE) -s package
	@cp $(DIST_DIR)/app.tar.gz app2.tar.gz
	@h1=$$(sha256sum app1.tar.gz | awk '{print $$1}'); \
	  h2=$$(sha256sum app2.tar.gz | awk '{print $$1}'); \
	  echo "SHA256_1=$$h1"; echo "SHA256_2=$$h2"; \
	  test "$$h1" = "$$h2" && echo "OK: reproducible" || { echo "ERROR: no reproducible"; exit 1; }
	@rm -f app1.tar.gz app2.tar.gz


clean: ## Limpiar archivos generados
	rm -rf $(OUT_DIR) $(DIST_DIR)

help: ## Mostrar ayuda
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | awk -F':|##' '{printf "  %-12s %s\n", $$1, $$3}'
