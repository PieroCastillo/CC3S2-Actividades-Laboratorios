curl -fsS http://127.0.0.1:$PORT/ | jq -e '.status==\"ok\"'
openssl s_client -connect miapp.local:443 -servername miapp.local -brief
X-Forwarded-Proto: https

openssl s_client -brief ->miapp.local:443 -> curl -k https://miapp.local/


idempotency-http: ## Verifica que GET / es idempotente (mismas respuestas en reintentos)
	@set -euo pipefail; \
	URL="http://127.0.0.1:$${PORT:-8080}/"; \
	R1="$$(curl -fsS "$$URL")"; \
	R2="$$(curl -fsS "$$URL")"; \
	R3="$$(curl -fsS "$$URL")"; \
	test "$$R1" = "$$R2" && test "$$R2" = "$$R3" && echo "OK: GET / idempotente"


4
a.

# miapp.service  (ajusta solo estas líneas)
[Service]
Environment=PORT=9090
Environment=MESSAGE=Hola desde prod
Environment=RELEASE=v1.2.3


sudo systemctl daemon-reload
sudo systemctl restart miapp
journalctl -u miapp -n 20 -f      # ver logs (única fuente de verdad)


export PORT=9090 MESSAGE="Hola dev" RELEASE="v1.2.3"
python app.py


b.

mkdir -p dist
git archive --format=tar.gz -o dist/miapp-${RELEASE:-v0}.tar.gz HEAD
sha256sum dist/miapp-${RELEASE:-v0}.tar.gz > dist/miapp-${RELEASE:-v0}.sha256


c.

curl -fsS "http://127.0.0.1:${PORT:-8080}/" | jq -r '.release,.message,.port'


curl -kfsS "https://miapp.local/" | jq -r '.release,.message,.port'

e.
# miapp.conf
location / {
  proxy_pass http://127.0.0.1:9999;  # <-- PUERTO ERRÓNEO para simular fallo
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-For $remote_addr;
  proxy_set_header X-Forwarded-Proto https;
}


sudo nginx -t && sudo systemctl reload nginx
curl -k https://miapp.local/   # debería FALLAR



5.

a.

from flask import Flask, jsonify, make_response
# ... (resto igual)

@app.route("/healthz")   # liveness: el proceso está vivo
def healthz():
    return jsonify(status="ok")

@app.route("/readyz")    # readiness: listo para tráfico
def readyz():
    # Si hubiera dependencias, aquí se validarían (BD, cola, etc.)
    return jsonify(ready=True)

# ETag sencillo para "/" (contrato de cache y reintentos seguros)
@app.after_request
def add_etag(resp):
    # Sólo como demo: Flask puede gestionar ETag automáticamente si set_etag
    if resp.direct_passthrough or resp.status_code != 200:
        return resp
    body = resp.get_data(as_text=True)
    import hashlib
    etag = hashlib.sha256(body.encode("utf-8")).hexdigest()[:16]
    resp.set_etag(etag)
    return resp

curl -fsS http://127.0.0.1:${PORT:-8080}/healthz
curl -fsS http://127.0.0.1:${PORT:-8080}/readyz
curl -i    http://127.0.0.1:${PORT:-8080}/ | grep -i etag

b.

miapp.conf
server {
  listen 443 ssl;
  server_name miapp.local;
  # ...
  add_header Strict-Transport-Security "max-age=31536000" always;
}

curl -kI https://miapp.local/ | grep -i strict-transport-security


d.
curl -o /dev/null -s -w 'time_total=%{time_total}\n' http://127.0.0.1:${PORT:-8080}/
curl -o /dev/null -s -w 'time_total=%{time_total}\n' -k https://miapp.local/


6.
a.
01-miapp.yaml

network:
  version: 2
  ethernets:
    enp0s3:
      addresses: [192.168.1.50/24]
      gateway4: 192.168.1.1
      nameservers:
        search: [localdomain]
        addresses: [1.1.1.1,8.8.8.8]

sudo netplan try   # o sudo netplan apply
ip a s enp0s3


b.
Con /etc/hosts
dig +noall +answer example.com
sleep 2
dig +noall +answer example.com   # observa que el TTL disminuye

c.
getent hosts miapp.local   # debería mostrar 127.0.0.1

7.
a.
openssl s_client -connect miapp.local:443 -servername miapp.local -brief </dev/null
curl -kI https://miapp.local/ | grep -iE 'strict-transport-security|x-forwarded-proto'

b.
ssl_protocols TLSv1.3;   # endurecer: solo TLS 1.3

tls13-gate: ## Falla si el endpoint no negocia TLSv1.3
	@set -euo pipefail; \
	OUT="$$(openssl s_client -connect miapp.local:443 -servername miapp.local -brief </dev/null)"; \
	echo "$$OUT" | grep -q 'Protocol  : TLSv1.3' && echo "OK TLSv1.3" || { echo "ERROR: No TLSv1.3"; exit 1; }


8.

a.
ss -lntp | sed '1,1d'         # puertos en LISTEN + PID/comm
lsof -i :8080 -sTCP:LISTEN
lsof -i :443  -sTCP:LISTEN

c.

sudo cp miapp.service /etc/systemd/system/miapp.service
sudo sed -i "s|{{APP_DIR}}|$PWD|g" /etc/systemd/system/miapp.service
sudo sed -i "s|{{USER}}|$USER|g" /etc/systemd/system/miapp.service
sudo systemctl daemon-reload
sudo systemctl enable --now miapp


pidof python | xargs -I{} sudo kill -9 {}   # mata el backend (ojo: demo)
journalctl -u miapp -n 50 -f                # ver que systemd lo reinicia (Restart=always)

sudo ufw allow 443/tcp
sudo ufw deny  8080/tcp
sudo ufw status numbered


9.
a.(predeploy_check.sh)
#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-miapp.local}"
PORT="${PORT:-8080}"
LAT_MS_MAX="${LAT_MS_MAX:-500}"   # umbral 0.5s

# HTTP readiness y liveness
curl -fsS "http://127.0.0.1:${PORT}/healthz" >/dev/null
curl -fsS "http://127.0.0.1:${PORT}/readyz"  >/dev/null

# DNS local
getent hosts "${HOST}" | grep -qE '(^127\.0\.0\.1\s+)'

# TLS y headers
OUT_TLS="$(openssl s_client -connect ${HOST}:443 -servername ${HOST} -brief </dev/null || true)"
grep -q 'Protocol  : TLSv1.3' <<<"$OUT_TLS" || { echo "No TLSv1.3"; exit 1; }
curl -kI "https://${HOST}/" | grep -qi 'strict-transport-security' || { echo "Sin HSTS"; exit 1; }

# Latencia
LAT_S="$(curl -kso /dev/null -w '%{time_total}\n' "https://${HOST}/")"
LAT_MS="$(awk -v s="$LAT_S" 'BEGIN{printf("%.0f", s*1000)}')"
echo "latency_ms=$LAT_MS"
test "$LAT_MS" -le "$LAT_MS_MAX" || { echo "Latencia > ${LAT_MS_MAX}ms"; exit 1; }

echo "PREDEPLOY CHECKS: OK"


chmod +x scripts/predeploy_check.sh
scripts/predeploy_check.sh


Github actions

# .github/workflows/predeploy.yml
name: predeploy
on: [push]
jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get update && sudo apt-get install -y nginx openssl jq
      - run: scripts/predeploy_check.sh


10.

a. Modificar app.py
counter = {"value": 0}

@app.route("/non-idempotent")
def non_idempotent():
    # ¡ANTI-PATRÓN! Sólo para demo: GET muta estado
    counter["value"] += 1
    print(f"[WARN] GET /non-idempotent increments counter={counter['value']}", file=sys.stdout, flush=True)
    return jsonify(counter=counter["value"])


curl -fsS http://127.0.0.1:${PORT:-8080}/non-idempotent
curl -fsS http://127.0.0.1:${PORT:-8080}/non-idempotent   # cambia la salida → NO idempotente


b.
Modificar miapp.conf

# Define dos instancias (Blue y Green)
upstream backend_pool {
  server 127.0.0.1:8080;  # Blue (estable)
  # server 127.0.0.1:8081;  # Green (nueva) -> habilita al conmutar
}

server {
  listen 443 ssl;
  server_name miapp.local;
  # ...
  location / {
    proxy_pass http://backend_pool;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto https;
  }
}

