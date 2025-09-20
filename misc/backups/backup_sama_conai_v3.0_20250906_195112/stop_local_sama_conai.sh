#!/usr/bin/env bash
set -euo pipefail

# Stoppe les processus Odoo écoutant sur un port spécifique (sans toucher aux autres)
# Usage: ./stop_local_sama_conai.sh -p 8079

PORT=8079
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--port) PORT="$2"; shift 2;;
    -h|--help) echo "Usage: $0 -p PORT"; exit 0;;
    *) echo "Option inconnue: $1" >&2; exit 1;;
  esac
done

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$MOD_DIR/.sama_conai_tmp/pids/odoo-${PORT}.pid"

# Tuer par PID si présent
if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE" || true)
  if [[ -n "${PID:-}" ]] && ps -p "$PID" >/dev/null 2>&1; then
    echo "[INFO] Arrêt PID=$PID (port $PORT)"
    kill "$PID" || true
    sleep 1
  fi
  rm -f "$PID_FILE"
fi

# Tuer tout process à l'écoute du port en dernier recours
PIDS=$(lsof -tiTCP:"$PORT" -sTCP:LISTEN || true)
if [[ -n "$PIDS" ]]; then
  echo "[INFO] Arrêt des processus sur le port $PORT: $PIDS"
  kill $PIDS || true
  sleep 1
  PIDS=$(lsof -tiTCP:"$PORT" -sTCP:LISTEN || true)
  if [[ -n "$PIDS" ]]; then
    echo "[WARN] Forçage SIGKILL: $PIDS"
    kill -9 $PIDS || true
  fi
fi

echo "[OK] Port $PORT libéré."
