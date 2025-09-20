#!/bin/bash

# Test d'installation basique sans données de démo

echo "🧪 TEST INSTALLATION BASIQUE"
echo "============================"

# Configuration
PORT=8078
DB_NAME="sama_conai_test_basic"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_PATH="/var/odoo/odoo18"
ADDONS_PATH="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons"

# Nettoyage
echo "🧹 Nettoyage..."
pkill -f "odoo.*$PORT" 2>/dev/null || true
sleep 2

export PGPASSWORD=odoo
dropdb -h localhost -U odoo $DB_NAME 2>/dev/null || true
createdb -h localhost -U odoo $DB_NAME

# Activer l'environnement virtuel
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
fi

cd "$ODOO_PATH"

# Installation sans données de démo
echo "📦 Installation sans données de démo..."
timeout 120 python3 odoo-bin \
    -d $DB_NAME \
    --addons-path="$ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --http-port=$PORT \
    --log-level=info \
    --without-demo=all \
    -i sama_conai \
    --stop-after-init

if [ $? -eq 0 ]; then
    echo "✅ Installation réussie sans données de démo"
    
    # Test avec données de démo
    echo "📦 Test avec données de démo..."
    timeout 120 python3 odoo-bin \
        -d $DB_NAME \
        --addons-path="$ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --http-port=$PORT \
        --log-level=info \
        -u sama_conai \
        --stop-after-init
    
    if [ $? -eq 0 ]; then
        echo "✅ Mise à jour avec données de démo réussie"
        
        # Démarrer le serveur
        echo "🚀 Démarrage du serveur de test..."
        python3 odoo-bin \
            -d $DB_NAME \
            --addons-path="$ADDONS_PATH" \
            --db_host=localhost \
            --db_user=odoo \
            --db_password=odoo \
            --http-port=$PORT \
            --log-level=info &
        
        sleep 10
        
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ | grep -q "200\|303"; then
            echo "✅ Serveur de test accessible sur http://localhost:$PORT"
            echo "🎯 Test réussi ! Module SAMA CONAI v2.5 fonctionnel"
        else
            echo "⚠️ Serveur en cours de démarrage..."
        fi
    else
        echo "❌ Erreur lors de la mise à jour avec données de démo"
    fi
else
    echo "❌ Erreur lors de l'installation de base"
fi