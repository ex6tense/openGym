#!/usr/bin/env bash
# Lista los usuarios registrados (id y nombre) para poner tu id en ADMIN_UIDS del .env.
# Uso (en el servidor):  bash /opt/elitefit-app/deploy/usuarios.sh
set -euo pipefail
node -e '
const db = JSON.parse(require("fs").readFileSync("/opt/elitefit-app/data/db.json", "utf8"));
for (const u of db.users) console.log(u.id + "  " + u.name + (u.disabled ? "  (desactivado)" : ""));
'
