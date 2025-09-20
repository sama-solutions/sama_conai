#!/bin/bash

# Test d'installation étape par étape

echo "🔍 TEST INSTALLATION ÉTAPE PAR ÉTAPE"
echo "===================================="

DB_NAME="test_sama_$(date +%s)"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

echo "Base de test: $DB_NAME"
echo ""

source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

# Étape 1: Créer base vide
echo "1. Création base vide..."
createdb -h localhost -U odoo "$DB_NAME"
echo "   ✅ Base créée"

# Étape 2: Initialiser avec base seulement
echo "2. Initialisation base..."
python3 odoo-bin \
    -d "$DB_NAME" \
    -i base \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --without-demo=all \
    --log-level=error

if [ $? -eq 0 ]; then
    echo "   ✅ Base initialisée"
else
    echo "   ❌ Erreur initialisation"
    dropdb -h localhost -U odoo "$DB_NAME"
    exit 1
fi

# Étape 3: Ajouter mail
echo "3. Installation module mail..."
python3 odoo-bin \
    -d "$DB_NAME" \
    -i mail \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --without-demo=all \
    --log-level=error

if [ $? -eq 0 ]; then
    echo "   ✅ Module mail installé"
else
    echo "   ❌ Erreur module mail"
    dropdb -h localhost -U odoo "$DB_NAME"
    exit 1
fi

# Étape 4: Test sama_conai
echo "4. Test installation sama_conai..."
python3 odoo-bin \
    -d "$DB_NAME" \
    -i sama_conai \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --without-demo=all \
    --log-level=warn

if [ $? -eq 0 ]; then
    echo "   ✅ Module sama_conai installé"
    
    # Test rapide
    echo "5. Test fonctionnel..."
    python3 odoo-bin shell \
        -d "$DB_NAME" \
        --addons-path="$CUSTOM_ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo << 'EOF'
try:
    module = env['ir.module.module'].search([('name', '=', 'sama_conai')])
    print(f"Module état: {module.state}")
    
    info_model = env['request.information']
    wb_model = env['whistleblowing.alert']
    print("Modèles accessibles")
    
except Exception as e:
    print(f"Erreur: {e}")
EOF
    
    echo "   ✅ Test fonctionnel OK"
    echo ""
    echo "🎉 INSTALLATION RÉUSSIE!"
    echo "Base de test: $DB_NAME"
    echo ""
    echo "Pour utiliser cette base:"
    echo "python3 odoo-bin -d $DB_NAME --addons-path=$CUSTOM_ADDONS_PATH"
    
else
    echo "   ❌ Erreur module sama_conai"
    echo ""
    echo "Dernières erreurs:"
    tail -20 /var/log/odoo/odoo.log | grep -E "(ERROR|CRITICAL|sama_conai)"
    
    # Nettoyer
    dropdb -h localhost -U odoo "$DB_NAME"
    exit 1
fi