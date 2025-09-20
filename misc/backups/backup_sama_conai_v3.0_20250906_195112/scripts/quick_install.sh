#!/bin/bash

# Installation rapide SAMA CONAI

echo "⚡ INSTALLATION RAPIDE SAMA CONAI"
echo "================================"

DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

echo "Base de données: $DB_NAME"
echo ""

# Activation environnement
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

# Commandes directes
echo "1. Suppression base existante..."
dropdb -h localhost -U odoo "$DB_NAME" 2>/dev/null || echo "   Aucune base à supprimer"

echo "2. Création nouvelle base..."
createdb -h localhost -U odoo "$DB_NAME"

echo "3. Installation module..."
python3 odoo-bin \
    -d "$DB_NAME" \
    -i sama_conai \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --without-demo=all

echo ""
echo "✅ Installation terminée!"
echo ""
echo "Pour démarrer:"
echo "cd $ODOO_PATH"
echo "python3 odoo-bin -d $DB_NAME --addons-path=$CUSTOM_ADDONS_PATH"