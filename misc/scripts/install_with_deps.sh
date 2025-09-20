#!/bin/bash

# Installation SAMA CONAI avec dépendances

echo "📦 INSTALLATION SAMA CONAI AVEC DÉPENDANCES"
echo "==========================================="

DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_ADDONS_PATH="/var/odoo/odoo18/addons"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

export PGPASSWORD=odoo

echo "Base: $DB_NAME"
echo ""

# Nettoyage
echo "1. Nettoyage..."
dropdb -h localhost -U odoo "$DB_NAME" 2>/dev/null || true
createdb -h localhost -U odoo "$DB_NAME"

# Activation environnement
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

# Installation des dépendances
echo "2. Installation des dépendances..."
timeout 180s python3 odoo-bin \
  -d "$DB_NAME" \
  -i base,mail,portal,hr \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --stop-after-init \
  --without-demo=all \
  --log-level=error

if [ $? -eq 0 ] || [ $? -eq 124 ]; then
    echo "✅ Dépendances installées"
else
    echo "❌ Erreur dépendances"
    exit 1
fi

# Installation du module SAMA CONAI
echo "3. Installation SAMA CONAI..."
timeout 120s python3 odoo-bin \
  -d "$DB_NAME" \
  -i sama_conai \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --stop-after-init \
  --log-level=error

if [ $? -eq 0 ] || [ $? -eq 124 ]; then
    echo "✅ SAMA CONAI installé"
else
    echo "❌ Erreur SAMA CONAI"
    exit 1
fi

echo ""
echo "🧪 Test rapide..."
timeout 30s python3 odoo-bin shell \
  -d "$DB_NAME" \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo << 'EOF'

try:
    module = env['ir.module.module'].search([('name', '=', 'sama_conai')])
    if module:
        print(f"✅ Module: {module.state}")
        
        info_count = env['request.information'].search_count([])
        wb_count = env['whistleblowing.alert'].search_count([])
        print(f"📊 Données: {info_count} demandes, {wb_count} signalements")
        
        views = env['ir.ui.view'].search([('model', 'in', ['request.information', 'whistleblowing.alert'])])
        print(f"🎨 Vues: {len(views)}")
        
        menus = env['ir.ui.menu'].search([('name', 'ilike', 'SAMA CONAI')])
        print(f"📋 Menus: {len(menus)}")
        
        print("✅ Module fonctionnel!")
    else:
        print("❌ Module non trouvé")
except Exception as e:
    print(f"❌ Erreur: {e}")

EOF

echo ""
echo "🎉 Installation terminée!"
echo ""
echo "🚀 Pour démarrer le serveur:"
echo "   ./start_server_fixed.sh $DB_NAME"
echo ""
echo "🌐 Puis aller sur: http://localhost:8069"
echo "   User: admin / Pass: admin"
echo "   Menu: Accès à l'Information"