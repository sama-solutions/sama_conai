#!/bin/bash

# Installation SAMA CONAI avec chemins corrigés

echo "🔧 INSTALLATION SAMA CONAI - CHEMINS CORRIGÉS"
echo "============================================="

DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_ADDONS_PATH="/var/odoo/odoo18/addons"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

export PGPASSWORD=odoo

echo "Base de données: $DB_NAME"
echo "Addons Odoo: $ODOO_ADDONS_PATH"
echo "Custom addons: $CUSTOM_ADDONS_PATH"
echo ""

# Suppression complète de la base
echo "1. Suppression de la base existante..."
dropdb -h localhost -U odoo "$DB_NAME" 2>/dev/null || echo "   Aucune base à supprimer"

# Création nouvelle base
echo "2. Création nouvelle base..."
createdb -h localhost -U odoo "$DB_NAME"

# Activation environnement
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

# Installation avec les bons chemins d'addons
echo "3. Installation avec base et web..."
python3 odoo-bin \
  -d "$DB_NAME" \
  -i base,web,mail \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --stop-after-init \
  --without-demo=all

if [ $? -eq 0 ]; then
    echo "✅ Base et modules essentiels installés"
else
    echo "❌ Erreur installation base"
    exit 1
fi

# Installation du module SAMA CONAI
echo "4. Installation module SAMA CONAI..."
python3 odoo-bin \
  -d "$DB_NAME" \
  -i sama_conai \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --stop-after-init

if [ $? -eq 0 ]; then
    echo "✅ Module SAMA CONAI installé"
else
    echo "❌ Erreur installation module"
    exit 1
fi

echo ""
echo "🎉 Installation terminée!"
echo ""
echo "Pour tester:"
echo "   ./test_module_fixed.sh $DB_NAME"
echo ""
echo "Pour démarrer le serveur:"
echo "   ./start_server_fixed.sh $DB_NAME"