#!/bin/bash

# Script de démarrage du serveur SAMA CONAI avec chemins corrigés

echo "🚀 DÉMARRAGE SERVEUR SAMA CONAI - CHEMINS CORRIGÉS"
echo "=================================================="

DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_ADDONS_PATH="/var/odoo/odoo18/addons"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

echo "Base de données: $DB_NAME"
echo "Port: 8069"
echo "URL: http://localhost:8069"
echo "Addons: $ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH"
echo ""

# Activation de l'environnement virtuel
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

echo "Démarrage du serveur..."
echo "Appuyez sur Ctrl+C pour arrêter"
echo ""

# Démarrage du serveur
python3 odoo-bin \
  -d "$DB_NAME" \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --http-port=8069