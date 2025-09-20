#!/bin/bash

# Installation simple du module Analytics

echo "📦 INSTALLATION SAMA CONAI ANALYTICS"
echo "===================================="

# Configuration
PORT=8077
DB_NAME="sama_conai_analytics"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_PATH="/var/odoo/odoo18"
ADDONS_PATH="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons"

# Arrêter les processus existants
echo "🛑 Nettoyage des processus..."
pkill -f "odoo.*$PORT" 2>/dev/null || true
sleep 3

# Supprimer la base si elle existe
echo "🗄️ Nettoyage de la base..."
export PGPASSWORD=odoo
dropdb -h localhost -U odoo $DB_NAME 2>/dev/null || true

# Créer une nouvelle base
echo "📝 Création de la base..."
createdb -h localhost -U odoo $DB_NAME

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de la création de la base"
    exit 1
fi

# Activer l'environnement virtuel
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    echo "✅ Environnement virtuel activé"
fi

# Aller dans le répertoire Odoo
cd "$ODOO_PATH"

# Installation du module
echo "📦 Installation du module SAMA CONAI..."
python3 odoo-bin \
    -d $DB_NAME \
    --addons-path="$ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --http-port=$PORT \
    --log-level=info \
    --logfile=/tmp/sama_conai_install.log \
    -i sama_conai \
    --stop-after-init

if [ $? -eq 0 ]; then
    echo "✅ Installation réussie"
    
    # Démarrer le serveur
    echo "🚀 Démarrage du serveur..."
    python3 odoo-bin \
        -d $DB_NAME \
        --addons-path="$ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --http-port=$PORT \
        --log-level=info \
        --logfile=/tmp/sama_conai_server.log \
        --pidfile=/tmp/sama_conai_server.pid &
    
    echo "⏳ Attente du démarrage..."
    sleep 10
    
    # Vérifier la connectivité
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ | grep -q "200\|303"; then
        echo "✅ Serveur accessible sur http://localhost:$PORT"
        echo "👤 Login: admin / admin"
        echo "📋 Logs: tail -f /tmp/sama_conai_server.log"
        echo "🛑 Arrêt: kill \$(cat /tmp/sama_conai_server.pid)"
    else
        echo "⚠️ Serveur en cours de démarrage..."
        echo "📋 Vérifiez les logs: tail -f /tmp/sama_conai_server.log"
    fi
else
    echo "❌ Erreur lors de l'installation"
    echo "📋 Vérifiez les logs: tail -f /tmp/sama_conai_install.log"
    exit 1
fi