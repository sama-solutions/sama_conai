#!/usr/bin/env bash
set -euo pipefail

# Démarrage local d'Odoo 18 pour le module sama_conai (sans Docker)
# - Arrête tout processus écoutant sur le port dédié (uniquement ce port)
# - Crée (si besoin) une base dédiée
# - Démarre Odoo sur un port dédié avec logs et conf isolés
# - Installe/Met à jour le module selon l'option choisie
#
# ENV SPECIFIQUES:
#   Odoo source  : /var/odoo/odoo18
#   venv Python  : /home/grand-as/odoo18-venv
#   Postgres     : user=odoo password=odoo host=localhost port=5432
#   custom_addons: /home/grand-as/psagsn/custom_addons
#
# Usage:
#   ./start_local_sama_conai.sh --init   -p 8079 -d sama_conai_8079
#   ./start_local_sama_conai.sh --update -p 8079 -d sama_conai_8079
#   ./start_local_sama_conai.sh --run    -p 8079 -d sama_conai_8079
#   Options: --with-demo  --dev  --dry-run

# chemins fixes donnés par le client
ODOO_HOME="/var/odoo/odoo18"
VENV_DIR="/home/grand-as/odoo18-venv"
OFFICIAL_ADDONS1="/var/odoo/odoo18/addons"
OFFICIAL_ADDONS2="/var/odoo/odoo18/odoo/addons"
CUSTOM_ADDONS="/home/grand-as/psagsn/custom_addons"

# dossiers temporaires pour cette exécution
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$MOD_DIR/.sama_conai_tmp"
LOG_DIR="$RUN_DIR/logs"
CONF_DIR="$RUN_DIR/conf"
PID_DIR="$RUN_DIR/pids"
mkdir -p "$LOG_DIR" "$CONF_DIR" "$PID_DIR"

# valeurs par défaut
PORT="8075"
DB_NAME="sama_conai_${PORT}"
ACTION="run"       # init | update | run
WITH_DEMO="false"
DEV_MODE="false"
DRY_RUN="false"
FOLLOW_LOGS="false"
LOG_LEVEL="info"

print_help() {
  cat <<EOF
Usage: $0 [--init|--update|--run] -p PORT -d DBNAME [--with-demo] [--dev] [--dry-run]

Exemples:
  $0 --init  -p 8079 -d sama_conai_8079
  $0 --update -p 8079 -d sama_conai_8079
  $0 --run   -p 8079 -d sama_conai_8079 --dev
EOF
}

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--port) PORT="$2"; shift 2;;
    -d|--db) DB_NAME="$2"; shift 2;;
    --init) ACTION="init"; shift 1;;
    --update) ACTION="update"; shift 1;;
    --run) ACTION="run"; shift 1;;
    --with-demo) WITH_DEMO="true"; shift 1;;
    --dev) DEV_MODE="true"; shift 1;;
    --dry-run) DRY_RUN="true"; shift 1;;
    --follow) FOLLOW_LOGS="true"; shift 1;;
    --debug) LOG_LEVEL="debug"; shift 1;;
    -h|--help) print_help; exit 0;;
    *) echo "Option inconnue: $1" >&2; print_help; exit 1;;
  esac
done

# ajuster DB par défaut si non fournie explicitement
if [[ -z "${DB_NAME:-}" ]]; then
  DB_NAME="sama_conai_${PORT}"
fi

CONF_FILE="$CONF_DIR/odoo-${PORT}.conf"
LOG_FILE="$LOG_DIR/odoo-${PORT}.log"

kill_port() {
  local port="$1"
  # tuer seulement les processus à l'écoute du port
  local pids
  pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN || true)
  if [[ -n "$pids" ]]; then
    echo "[INFO] Arrêt des processus sur le port $port: $pids"
    # SIGTERM puis SIGKILL si nécessaire
    kill $pids || true
    sleep 1
    pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN || true)
    if [[ -n "$pids" ]]; then
      echo "[WARN] Forçage de l'arrêt (SIGKILL) sur: $pids"
      kill -9 $pids || true
    fi
  fi
}

ensure_db() {
  local db="$1"
  # vérifier si la DB existe
  if PGPASSWORD=odoo psql -h localhost -p 5432 -U odoo -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db'" | grep -q 1; then
    echo "[INFO] DB existe déjà: $db"
  else
    echo "[INFO] Création DB: $db"
    PGPASSWORD=odoo createdb -h localhost -p 5432 -U odoo "$db"
  fi
}

write_conf() {
  cat > "$CONF_FILE" <<CFG
[options]
; admin password d'Odoo (changer si besoin)
admin_passwd = admin

; Connexion DB
list_db = True
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo

; modules serveur
server_wide_modules = web,base

; chemins addons
addons_path = ${CUSTOM_ADDONS},${OFFICIAL_ADDONS1},${OFFICIAL_ADDONS2}
http_port = ${PORT}
logfile = ${LOG_FILE}
log_level = info
proxy_mode = True
CFG
}

build_cmd() {
  local args=("$ODOO_BIN" -c "$CONF_FILE" -d "$DB_NAME" "--log-level=${LOG_LEVEL}")
  if [[ "$WITH_DEMO" == "false" ]]; then
    args+=("--without-demo=all")
  fi
  if [[ "$DEV_MODE" == "true" ]]; then
    args+=("--dev=all")
  fi
  case "$ACTION" in
    init) args+=("-i" "sama_conai");;
    update) args+=("-u" "sama_conai");;
    run) :;;
    *) echo "[ERREUR] ACTION invalide: $ACTION" >&2; exit 2;;
  esac
  printf '%q ' "${args[@]}"
}

# 1) stopper les processus sur NOTRE port
kill_port "$PORT"

# 2) activer le venv
if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
  echo "[ERREUR] venv introuvable: $VENV_DIR" >&2; exit 2
fi
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

# 3) binaire odoo
ODOO_BIN="$ODOO_HOME/odoo-bin"
if [[ ! -x "$ODOO_BIN" ]]; then
  echo "[ERREUR] odoo-bin introuvable: $ODOO_BIN" >&2; exit 2
fi

# 4) écrire conf & assurer la DB
write_conf
ensure_db "$DB_NAME"

# 5) construire la commande
CMD_STR=$(build_cmd)

# 6) afficher le contexte & exécuter
{
  echo "[INFO] Module dir       : $MOD_DIR"
  echo "[INFO] Temp run dir     : $RUN_DIR"
  echo "[INFO] Config file      : $CONF_FILE"
  echo "[INFO] Log file         : $LOG_FILE"
  echo "[INFO] Port             : $PORT"
  echo "[INFO] Database         : $DB_NAME"
  echo "[INFO] venv             : $VENV_DIR"
  echo "[INFO] odoo-bin         : $ODOO_BIN"
  echo "[INFO] addons_path      : ${CUSTOM_ADDONS},${OFFICIAL_ADDONS1},${OFFICIAL_ADDONS2}"
  echo "[INFO] action           : $ACTION"
  echo "[INFO] demo             : $WITH_DEMO"
  echo "[INFO] dev              : $DEV_MODE"
  echo "[INFO] Commande         : $CMD_STR"
} >&2

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY-RUN] Aucune exécution."
  exit 0
fi

# Exécuter Odoo en arrière-plan avec redirection vers le log
nohup bash -lc "$CMD_STR >> '$LOG_FILE' 2>&1" &
PID=$!
echo $PID > "$PID_DIR/odoo-${PORT}.pid"
echo "[INFO] Démarré PID=$PID (port $PORT), log: $LOG_FILE"

# Optionnel: suivi du log
if [[ "$FOLLOW_LOGS" == "true" ]]; then
  echo "[INFO] Suivi des logs (Ctrl+C pour quitter le suivi, Odoo continue en arrière-plan)"
  tail -f -n 50 "$LOG_FILE"
fi

exit 0
