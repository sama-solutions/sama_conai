#!/bin/bash

# Script de test SAMA CONAI

echo "🧪 TEST SAMA CONAI"
echo "=================="
echo ""

# Variables
DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
ODOO_BIN="$ODOO_PATH/odoo-bin"
VENV_PATH="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"
MODULE_PATH="$CUSTOM_ADDONS_PATH/sama_conai"
CONF_FILE="$MODULE_PATH/odoo_sama_conai.conf"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}📋 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }

# Activation de l'environnement virtuel
source "$VENV_PATH/bin/activate"

# Changement vers le répertoire Odoo
cd "$ODOO_PATH"

print_step "Test des données de démo..."

# Exécution du test
python3 "$ODOO_BIN" shell \
    -c "$CONF_FILE" \
    -d "$DB_NAME" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo << 'EOF'

# Test des données de démo
try:
    print("🧪 TEST DES DONNÉES DE DÉMO SAMA CONAI")
    print("=" * 50)
    
    # Test des modèles
    info_requests = env['request.information'].search([])
    wb_alerts = env['whistleblowing.alert'].search([])
    
    print(f"📊 Demandes d'information: {len(info_requests)}")
    print(f"🚨 Signalements d'alerte: {len(wb_alerts)}")
    
    if len(info_requests) > 0:
        print("\n📋 Demandes d'information:")
        for req in info_requests:
            print(f"   - {req.name}: {req.partner_name} ({req.state})")
    
    if len(wb_alerts) > 0:
        print("\n🚨 Signalements d'alerte:")
        for alert in wb_alerts:
            print(f"   - {alert.name}: {alert.category} ({alert.state})")
    
    # Test des vues
    views = env['ir.ui.view'].search([('model', 'in', ['request.information', 'whistleblowing.alert'])])
    print(f"\n🎨 Vues disponibles: {len(views)}")
    
    # Test des actions
    try:
        action = env.ref('sama_conai.action_information_request')
        print(f"✅ Action principale: {action.name}")
    except:
        print("❌ Action principale non trouvée")
    
    print("\n🎯 RÉSULTAT:")
    if len(info_requests) >= 4 and len(wb_alerts) >= 4:
        print("✅ Test réussi! Données de démo complètes")
    else:
        print("⚠️  Test partiel. Certaines données manquent")
        
except Exception as e:
    print(f"❌ Erreur lors du test: {e}")

EOF

print_success "Test terminé"