#!/usr/bin/env bash
# Instalación inicial de la Elite Fit App en un LXC Debian 13 limpio.
# Uso (como root):
#   apt-get update && apt-get install -y git
#   git clone https://github.com/ex6tense/openGym.git /opt/elitefit-app
#   bash /opt/elitefit-app/deploy/instalar.sh
set -euo pipefail

APP=/opt/elitefit-app

echo "→ Instalando paquetes (Node, Caddy)…"
apt-get update
apt-get install -y nodejs npm caddy git curl sudo ca-certificates
node --version

echo "→ Creando usuario del servicio…"
id elitefit >/dev/null 2>&1 || useradd --system --home "$APP" --shell /usr/sbin/nologin elitefit

if [ ! -f "$APP/.env" ]; then
  echo "→ Creando $APP/.env desde la plantilla…"
  cp "$APP/deploy/env.example" "$APP/.env"
fi
chmod 600 "$APP/.env"

echo "→ Instalando servicio y Caddy…"
cp "$APP/deploy/elitefit-app.service" /etc/systemd/system/
cp "$APP/deploy/Caddyfile" /etc/caddy/Caddyfile
systemctl daemon-reload
systemctl enable elitefit-app caddy

bash "$APP/deploy/actualizar.sh"

echo
echo "✓ Listo. Prueba en la red local:  http://$(hostname -I | awk '{print $1}')/"
echo "  (las passkeys solo funcionan por https://app.elitefit.ec, después de configurar el túnel)"
