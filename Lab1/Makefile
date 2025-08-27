# Makefile 
# venv: 'bdd' (prompt (bdd))
SHELL := /bin/bash
.DEFAULT_GOAL := help

# Variables (12-Factor)
APP_NAME ?= miapp
DOMAIN   ?= miapp.local
PORT     ?= 8080
MESSAGE  ?= Hola
RELEASE  ?= v0

# venv con nombre/prompt 'bdd'
VENV := bdd
VENV_PROMPT := bdd

# Detección de plataforma (Windows usa Scripts/, Linux/macOS usan bin/)
UNAME_S := $(shell uname -s 2>/dev/null)
ifeq ($(OS),Windows_NT)
  VENV_BIN := $(VENV)/Scripts
else ifneq (,$(findstring MINGW,$(UNAME_S)))
  VENV_BIN := $(VENV)/Scripts
else ifneq (,$(findstring MSYS,$(UNAME_S)))
  VENV_BIN := $(VENV)/Scripts
else ifneq (,$(findstring CYGWIN,$(UNAME_S)))
  VENV_BIN := $(VENV)/Scripts
else
  VENV_BIN := $(VENV)/bin
endif

# Bandera para flujos específicos de Windows
IS_WIN := $(or $(filter Windows_NT,$(OS)),$(findstring MINGW,$(UNAME_S)),$(findstring MSYS,$(UNAME_S)),$(findstring CYGWIN,$(UNAME_S)))

# Intérprete para crear la venv (py -3 | python3 | python)
PY_BOOT := $(shell if command -v py >/dev/null 2>&1; then echo "py -3"; \
              elif command -v python3 >/dev/null 2>&1; then echo "python3"; \
              else echo "python"; fi)

PY  := $(VENV_BIN)/python
PIP := $(PY) -m pip     # usar python -m pip es más portable

APP_DIR := $(shell pwd)

# Nginx/systemd (Linux)
NGINX_SITE_AVAIL   := /etc/nginx/sites-available/$(APP_NAME).conf
NGINX_SITE_ENABLED := /etc/nginx/sites-enabled/$(APP_NAME).conf

CERT_DIR  := certs
KEY_FILE  := $(CERT_DIR)/$(DOMAIN).key
CRT_FILE  := $(CERT_DIR)/$(DOMAIN).crt
NGINX_CERT_DIR := /etc/ssl/miapp

# Herramientas (pueden faltar en Windows)
CURL     := $(shell command -v curl 2>/dev/null)
DIG      := $(shell command -v dig 2>/dev/null)
SS       := $(shell command -v ss 2>/dev/null)
LSOF     := $(shell command -v lsof 2>/dev/null)
OPENSSL  := $(shell command -v openssl 2>/dev/null)
IP       := $(shell command -v ip 2>/dev/null)
GETENT   := $(shell command -v getent 2>/dev/null)
NGINX    := $(shell command -v nginx 2>/dev/null)
SYSTEMCTL:= $(shell command -v systemctl 2>/dev/null)
UFW      := $(shell command -v ufw 2>/dev/null)
SED      := $(shell command -v sed 2>/dev/null)
NETSTAT  := $(shell command -v netstat 2>/dev/null)

# Ayuda / Debug
.PHONY: help
help: ## Mostrar los targets disponibles
	@echo "Make targets:"
	@grep -E '^[a-zA-Z0-9_\-]+:.*?##' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?##"}{printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

.PHONY: debug-venv
debug-venv: ## Mostrar diagnóstico de venv (rutas detectadas)
	@echo "OS=$(OS)"
	@echo "uname -s => $(UNAME_S)"
	@echo "IS_WIN=$(IS_WIN)"
	@echo "VENV=$(VENV)"
	@echo "VENV_BIN=$(VENV_BIN)"
	@echo "PY_BOOT=$(PY_BOOT)"
	@echo "PY=$(PY)"

# Preparación / App
.PHONY: prepare
prepare: $(VENV) ## Crear venv 'bdd' e instalar dependencias de la app
	@echo "Actualizando pip e instalando Flask..."
	@$(PIP) --version
	@$(PIP) install --upgrade pip
	@$(PIP) install flask

# Crear venv con prompt 'bdd'
$(VENV):
	@echo "Creando venv con: $(PY_BOOT) -m venv --prompt $(VENV_PROMPT) $(VENV)"
	@$(PY_BOOT) -m venv --prompt "$(VENV_PROMPT)" $(VENV)

.PHONY: venv-recreate
venv-recreate: ## Recrear la venv 'bdd' desde cero
	@rm -rf $(VENV)
	@$(MAKE) prepare

.PHONY: shell
shell: ## Abrir una shell con la venv activada (verás (bdd) en el prompt)
	@. $(VENV_BIN)/activate && exec $$SHELL

.PHONY: run
run: ## Ejecutar la app Flask en primer plano. Detener con CTRL+C.
	@echo "Iniciando la aplicación en http://127.0.0.1:$(PORT) ..."
	@PORT=$(PORT) MESSAGE="$(MESSAGE)" RELEASE="$(RELEASE)" $(PY) app.py

.PHONY: check-http
check-http: ## Verificar HTTP, puertos y sockets (curl/ss/lsof o netstat)
	@echo "curl HEAD"
	@[ -n "$(CURL)" ] && $(CURL) -sS -I http://127.0.0.1:$(PORT) || echo "curl no disponible"
	@echo "curl GET"
	@[ -n "$(CURL)" ] && $(CURL) -sS http://127.0.0.1:$(PORT) || echo "curl no disponible"
	@echo "Sockets escuchando (ss/netstat)"
	@{ [ -n "$(SS)" ] && $(SS) -ltnp | grep :$(PORT) || \
	   { [ -n "$(NETSTAT)" ] && $(NETSTAT) -ano | grep ":$(PORT) " || echo "ni ss ni netstat disponibles"; }; }
	@echo "Puertos abiertos (lsof)"
	@[ -n "$(LSOF)" ] && $(LSOF) -i :$(PORT) -sTCP:LISTEN || echo "lsof no disponible"

# Resolución / DNS
.PHONY: hosts-setup
hosts-setup: ## Añadir '127.0.0.1 $(DOMAIN)' a hosts (Linux/macOS) o mostrar comando para Windows
ifeq ($(IS_WIN),)
	@if [ -f /etc/hosts ]; then \
		if ! grep -qE "127\.0\.0\.1\s+$(DOMAIN)" /etc/hosts; then \
			echo "Agregando $(DOMAIN) a /etc/hosts"; \
			echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts; \
		else echo "$(DOMAIN) ya está presente en /etc/hosts"; fi; \
	else echo "/etc/hosts no encontrado."; fi
else
	@echo "Windows detectado. Abre *PowerShell como Administrador* y ejecuta (una sola línea):"
	@echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$$h='$$env:WinDir\\System32\\drivers\\etc\\hosts'; $$line='127.0.0.1 $(DOMAIN)'; if (-not (Select-String -Path $$h -Pattern '^[ ]*127\\.0\\.0\\.1[ ]+$(DOMAIN)$$' -Quiet)) { Add-Content -Path $$h -Value \"``r``n$$line\"; 'Agregado.' } else { 'Ya existía.' }"
endif

.PHONY: resolv-show
resolv-show: ## Mostrar resolv.conf y resolución con getent (NSS vs DNS)
	@echo "/etc/resolv.conf"
	@if [ -f /etc/resolv.conf ]; then cat /etc/resolv.conf; else echo "resolv.conf no disponible (p.ej., Windows)"; fi
	@echo "getent hosts $(DOMAIN) (NSS incluye /etc/hosts)"
	@[ -n "$(GETENT)" ] && $(GETENT) hosts $(DOMAIN) || echo "getent no disponible (usa nslookup/ping en Windows)"

.PHONY: dns-demo
dns-demo: ## Consultas DNS: A/AAAA/CNAME/TXT/MX/SRV + demo de TTL
	@[ -n "$(DIG)" ] || { echo "dig no disponible. Instala dnsutils/bind-utils o usa WSL."; exit 0; }
	@echo "A/AAAA para example.com"
	@$(DIG) +noall +answer A example.com @1.1.1.1 || true
	@$(DIG) +noall +answer AAAA example.com @1.1.1.1 || true
	@echo "CNAME para www.wikipedia.org"
	@$(DIG) +noall +answer CNAME www.wikipedia.org @1.1.1.1 || true
	@echo "TXT para example.com (SPF/notas)"
	@$(DIG) +noall +answer TXT example.com @1.1.1.1 || true
	@echo "MX para gmail.com"
	@$(DIG) +noall +answer MX gmail.com @1.1.1.1 || true
	@echo "SRV _sip._tcp.sipdir.online.lync.com"
	@$(DIG) +noall +answer SRV _sip._tcp.sipdir.online.lync.com @1.1.1.1 || true
	@echo "TTL (misma consulta dos veces; el TTL debería disminuir)"
	@$(DIG) +noall +answer example.com @1.1.1.1 || true
	@sleep 2
	@$(DIG) +noall +answer example.com @1.1.1.1 || true
	@echo "Nota: 'dig' usa solo DNS; 'getent hosts' resuelve vía NSS (/etc/hosts)."

# Probar sin editar hosts (curl --resolve)
.PHONY: curl-http-local
curl-http-local: ## Probar HTTP sin tocar hosts
	@[ -n "$(CURL)" ] && $(CURL) -sS --resolve $(DOMAIN):$(PORT):127.0.0.1 http://$(DOMAIN):$(PORT) || echo "curl no disponible"

.PHONY: curl-https-local
curl-https-local: ## Probar HTTPS sin tocar hosts
	@[ -n "$(CURL)" ] && $(CURL) -sk --resolve $(DOMAIN):443:127.0.0.1 https://$(DOMAIN) || echo "curl no disponible"

# TLS / Nginx (Linux)
.PHONY: tls-cert
tls-cert: ## Generar certificado TLS autofirmado para $(DOMAIN) (365 días)
	@[ -n "$(OPENSSL)" ] || { echo "openssl no disponible"; exit 1; }
	@mkdir -p $(CERT_DIR)
	@if [ ! -f "$(KEY_FILE)" ]; then \
	  $(OPENSSL) req -x509 -nodes -newkey rsa:2048 \
	    -keyout $(KEY_FILE) -out $(CRT_FILE) -days 365 \
	    -subj "/CN=$(DOMAIN)"; \
	  echo "Certificado creado en $(CERT_DIR)/"; \
	else echo "Certificado ya existe en $(CERT_DIR)/"; fi

.PHONY: nginx
nginx: ## Instalar vhost de Nginx y recargar (Linux)
	@if [ -z "$(NGINX)" ]; then echo "nginx no encontrado (omitiendo)"; exit 1; fi
	@sudo mkdir -p $(NGINX_CERT_DIR)
	@if [ -f "$(CRT_FILE)" ] && [ -f "$(KEY_FILE)" ]; then \
	  sudo cp $(CRT_FILE) $(NGINX_CERT_DIR)/$(DOMAIN).crt; \
	  sudo cp $(KEY_FILE) $(NGINX_CERT_DIR)/$(DOMAIN).key; \
	else echo "Faltan certificados. Ejecuta 'make tls-cert' primero."; exit 1; fi
	@sudo cp nginx/miapp.conf $(NGINX_SITE_AVAIL)
	@sudo ln -sf $(NGINX_SITE_AVAIL) $(NGINX_SITE_ENABLED)
	@sudo nginx -t
	@sudo systemctl reload nginx
	@echo "Nginx recargado. Prueba: https://$(DOMAIN)"

.PHONY: ufw-open
ufw-open: ## Abrir 80/443 en UFW (Linux)
	@if [ -n "$(UFW)" ]; then \
	  sudo ufw allow 80/tcp || true; \
	  sudo ufw allow 443/tcp || true; \
	else echo "UFW no está instalado (omitiendo)"; fi

.PHONY: check-tls
check-tls: ## Validar handshake TLS y cabeceras con openssl/curl
	@echo "openssl s_client"
	@[ -n "$(OPENSSL)" ] && $(OPENSSL) s_client -connect $(DOMAIN):443 -servername $(DOMAIN) -brief -showcerts </dev/null || echo "openssl no disponible"
	@echo "curl sobre TLS (-k por cert autofirmado)"
	@[ -n "$(CURL)" ] && $(CURL) -sk https://$(DOMAIN) || echo "curl no disponible"
	@echo "Encabezados HTTP"
	@[ -n "$(CURL)" ] && $(CURL) -skI https://$(DOMAIN) || echo "curl no disponible"

# systemd /Netplan / Limpieza (Linux) 
.PHONY: systemd-install
systemd-install: ## Instalar/habilitar/iniciar el unit de systemd para la app
	@if [ -z "$(SYSTEMCTL)" ]; then echo "systemctl no encontrado (omitiendo)"; exit 1; fi
	@if [ -z "$(SED)" ]; then echo "sed no encontrado"; exit 1; fi
	@echo "Renderizando unit con APP_DIR=$(APP_DIR) y USER=$$USER ..."
	@$(SED) -e "s#{{APP_DIR}}#$(APP_DIR)#g" -e "s#{{USER}}#$$USER#g" systemd/miapp.service > /tmp/$(APP_NAME).service
	@sudo cp /tmp/$(APP_NAME).service /etc/systemd/system/$(APP_NAME).service
	@sudo systemctl daemon-reload
	@sudo systemctl enable $(APP_NAME).service
	@sudo systemctl restart $(APP_NAME).service
	@sudo systemctl --no-pager status $(APP_NAME).service || true

.PHONY: static-ip-preview
static-ip-preview: ## Mostrar ejemplo de Netplan para IP estática
	@echo "Revisa netplan/01-miapp.yaml y luego:"
	@echo "  sudo cp netplan/01-miapp.yaml /etc/netplan/01-miapp.yaml"
	@echo "  sudo netplan try   # o sudo netplan apply"

.PHONY: cleanup
cleanup: ## Remover vhost, detener unit y conservar certs/logs
	@echo "Deteniendo servicio systemd (si existe)..."
	@[ -n "$(SYSTEMCTL)" ] && sudo systemctl stop $(APP_NAME).service 2>/dev/null || true
	@[ -n "$(SYSTEMCTL)" ] && sudo systemctl disable $(APP_NAME).service 2>/dev/null || true
	@[ -n "$(SYSTEMCTL)" ] && sudo rm -f /etc/systemd/system/$(APP_NAME).service 2>/dev/null || true
	@[ -n "$(SYSTEMCTL)" ] && sudo systemctl daemon-reload 2>/dev/null || true
	@echo "Eliminando sitio Nginx (si existe)..."
	@sudo rm -f $(NGINX_SITE_ENABLED) 2>/dev/null || true
	@sudo rm -f $(NGINX_SITE_AVAIL) 2>/dev/null || true
	@{ [ -n "$(NGINX)" ] && sudo nginx -t >/dev/null 2>&1 && sudo systemctl reload nginx || true; }
	@echo "Limpieza completada. Certificados conservados en $(CERT_DIR)/."
