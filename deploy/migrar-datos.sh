#!/usr/bin/env bash
# Una sola vez: pasa los datos de /opt/elitefit-app/data a /var/lib/elitefit-app.
# - Copia usuarios (db.json) y estados (state-*.json)
# - Borra el usuario "Arvids" que venía en el repo original, con su passkey y su estado
# - NO copia secret ni vapid.json (eran públicos en GitHub): la app genera unos nuevos
# Uso (como root):  bash /opt/elitefit-app/deploy/migrar-datos.sh /root/data-backup
set -euo pipefail

SRC=${1:?Uso: migrar-datos.sh /ruta/al/backup-de-data}
DST=/var/lib/elitefit-app
BAD=piYdx5GveQarq8u9   # id del usuario "Arvids" incluido en el repo original

systemctl stop elitefit-app || true
install -d -o elitefit -g elitefit -m 700 "$DST"

cp "$SRC"/db.json "$DST"/ 2>/dev/null || true
cp "$SRC"/state-*.json "$DST"/ 2>/dev/null || true
rm -f "$DST/state-$BAD.json" "$DST/secret" "$DST/vapid.json"

if [ -f "$DST/db.json" ]; then
  BAD="$BAD" node -e '
    const fs = require("fs"), f = "/var/lib/elitefit-app/db.json", bad = process.env.BAD;
    const db = JSON.parse(fs.readFileSync(f, "utf8"));
    db.users = db.users.filter(u => u.id !== bad);
    db.creds = (db.creds || []).filter(c => c.uid !== bad && c.userId !== bad);
    db.subs = (db.subs || []).filter(s => s.uid !== bad && s.userId !== bad);
    fs.writeFileSync(f, JSON.stringify(db));
    console.log("→ Usuarios que quedan: " + db.users.map(u => u.name).join(", "));
  '
fi
chown -R elitefit:elitefit "$DST"
chmod 600 "$DST"/*

bash /opt/elitefit-app/deploy/actualizar.sh
echo "✓ Datos migrados. Claves nuevas generadas: vuelve a iniciar sesión en la app."
