#!/usr/bin/env bash
# Descarga la última versión, compila y reinicia la Elite Fit App.
# Uso (como root, en el servidor):  bash /opt/elitefit-app/deploy/actualizar.sh
set -euo pipefail

APP=/opt/elitefit-app
cd "$APP"

if [ -d .git ]; then
  echo "→ Descargando cambios de GitHub…"
  git -c safe.directory="$APP" pull --ff-only
fi
chown -R elitefit:elitefit "$APP"

# Datos de usuarios: fuera del repo, para que un git pull nunca los toque
install -d -o elitefit -g elitefit -m 700 /var/lib/elitefit-app

# Servicio y Caddy siempre según la versión del repo
cp "$APP/deploy/elitefit-app.service" /etc/systemd/system/
cp "$APP/deploy/Caddyfile" /etc/caddy/Caddyfile
systemctl daemon-reload

echo "→ Instalando dependencias del API…"
sudo -u elitefit npm --prefix "$APP/api" ci --omit=dev --no-audit --no-fund

echo "→ Instalando dependencias de la app…"
sudo -u elitefit npm --prefix "$APP/frontend" ci --no-audit --no-fund

echo "→ Compilando la app…"
sudo -u elitefit npm --prefix "$APP/frontend" run build

echo "→ Reiniciando servicios…"
systemctl restart elitefit-app
systemctl reload caddy
sleep 2
systemctl --no-pager --lines=5 status elitefit-app
curl -fsS -o /dev/null -w "→ App:  HTTP %{http_code}\n" http://127.0.0.1/
curl -fsS -o /dev/null -w "→ API:  HTTP %{http_code}\n" http://127.0.0.1/api/config
