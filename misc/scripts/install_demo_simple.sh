#!/bin/bash

# Installation simple avec données de démo

echo "📊 INSTALLATION SIMPLE AVEC DONNÉES DE DÉMO"
echo "==========================================="

DB_NAME="sama_conai_demo"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_ADDONS_PATH="/var/odoo/odoo18/addons"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

export PGPASSWORD=odoo

echo "Base de données: $DB_NAME"
echo ""

# Supprimer et recréer la base
echo "1. Préparation de la base de données..."
dropdb -h localhost -U odoo "$DB_NAME" 2>/dev/null || true
createdb -h localhost -U odoo "$DB_NAME"
echo "   ✅ Base créée"

# Activation environnement
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

# Installation directe avec démo
echo ""
echo "2. Installation avec données de démo..."
timeout 300s python3 odoo-bin \
  -d "$DB_NAME" \
  -i sama_conai \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --stop-after-init \
  --log-level=error

if [ $? -eq 0 ] || [ $? -eq 124 ]; then
    echo "   ✅ Installation terminée"
else
    echo "   ❌ Erreur d'installation"
    exit 1
fi

# Vérification
echo ""
echo "3. Vérification des données..."
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    'Demandes' as type, COUNT(*) as nombre 
FROM request_information
UNION ALL
SELECT 
    'Signalements' as type, COUNT(*) as nombre 
FROM whistleblowing_alert;" 2>/dev/null

echo ""
echo "🎉 Installation terminée !"
echo "🚀 Démarrer avec: ./start_sama_conai.sh"