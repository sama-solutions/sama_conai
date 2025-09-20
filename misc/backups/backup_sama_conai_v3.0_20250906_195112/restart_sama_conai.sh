#!/bin/bash

# Script pour redémarrer le serveur SAMA CONAI

echo "🔄 REDÉMARRAGE SERVEUR SAMA CONAI"
echo "================================="

DB_NAME="sama_conai_test"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_ADDONS_PATH="/var/odoo/odoo18/addons"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

echo "Base de données: $DB_NAME"
echo ""

# Arrêter le serveur existant
echo "1. Arrêt du serveur existant..."
PID=$(ps aux | grep "sama_conai_test" | grep -v grep | awk '{print $2}')
if [ ! -z "$PID" ]; then
    echo "   Arrêt du processus $PID"
    kill $PID
    sleep 3
    
    # Vérifier si le processus est toujours actif
    if ps -p $PID > /dev/null; then
        echo "   Force l'arrêt..."
        kill -9 $PID
        sleep 2
    fi
    echo "   ✅ Serveur arrêté"
else
    echo "   ℹ️  Aucun serveur en cours"
fi

# Vérifier que le port est libre
echo ""
echo "2. Vérification du port 8075..."
if netstat -tlnp | grep ":8075" > /dev/null; then
    echo "   ⚠️  Port 8075 encore occupé, attente..."
    sleep 5
fi

# Activation environnement
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

# Démarrage du serveur
echo ""
echo "3. Démarrage du serveur SAMA CONAI..."
echo "   URL: http://localhost:8075"
echo "   Base: $DB_NAME"
echo "   Connexion: admin / admin"
echo ""
echo "   Appuyez sur Ctrl+C pour arrêter le serveur"
echo ""

python3 odoo-bin \
  -d "$DB_NAME" \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --http-port=8075 \
  --log-level=info