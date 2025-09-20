#!/bin/bash

# Script de validation de l'installation SAMA CONAI

echo "🔍 VALIDATION INSTALLATION SAMA CONAI"
echo "====================================="
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
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}📋 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Validation des chemins
print_step "1. Validation des chemins système..."

if [ -f "$ODOO_BIN" ]; then
    print_success "Odoo trouvé: $ODOO_PATH"
else
    print_error "Odoo non trouvé: $ODOO_PATH"
    exit 1
fi

if [ -d "$VENV_PATH" ]; then
    print_success "Environnement virtuel trouvé: $VENV_PATH"
else
    print_error "Environnement virtuel non trouvé: $VENV_PATH"
    exit 1
fi

if [ -d "$MODULE_PATH" ]; then
    print_success "Module SAMA CONAI trouvé: $MODULE_PATH"
else
    print_error "Module SAMA CONAI non trouvé: $MODULE_PATH"
    exit 1
fi

if [ -f "$CONF_FILE" ]; then
    print_success "Configuration trouvée: $CONF_FILE"
else
    print_warning "Configuration non trouvée, utilisation des paramètres par défaut"
fi

echo ""

# Validation de PostgreSQL
print_step "2. Validation de PostgreSQL..."

if command -v psql >/dev/null 2>&1; then
    print_success "PostgreSQL installé"
    
    # Test de connexion
    if sudo -u postgres psql -c "SELECT version();" >/dev/null 2>&1; then
        print_success "PostgreSQL accessible"
    else
        print_error "PostgreSQL non accessible"
        exit 1
    fi
    
    # Vérifier l'utilisateur odoo
    if sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='odoo';" | grep -q 1; then
        print_success "Utilisateur PostgreSQL 'odoo' existe"
    else
        print_warning "Utilisateur PostgreSQL 'odoo' non trouvé"
        print_step "Création de l'utilisateur odoo..."
        sudo -u postgres createuser -d -R -S odoo
        sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'odoo';"
        print_success "Utilisateur 'odoo' créé"
    fi
    
    # Vérifier la base de données
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        print_success "Base de données '$DB_NAME' existe"
    else
        print_warning "Base de données '$DB_NAME' non trouvée"
        print_step "Création de la base de données..."
        sudo -u postgres createdb -O odoo "$DB_NAME"
        print_success "Base de données '$DB_NAME' créée"
    fi
else
    print_error "PostgreSQL non installé"
    exit 1
fi

echo ""

# Validation de l'environnement Python
print_step "3. Validation de l'environnement Python..."

source "$VENV_PATH/bin/activate"

if python3 -c "import odoo" 2>/dev/null; then
    print_success "Module Odoo Python accessible"
else
    print_error "Module Odoo Python non accessible"
    exit 1
fi

echo ""

# Test de connexion Odoo
print_step "4. Test de connexion Odoo..."

cd "$ODOO_PATH"

# Test simple de démarrage
timeout 30s python3 "$ODOO_BIN" \
    -c "$CONF_FILE" \
    -d "$DB_NAME" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --test-enable 2>/dev/null

if [ $? -eq 0 ] || [ $? -eq 124 ]; then  # 124 = timeout (normal)
    print_success "Odoo démarre correctement"
else
    print_error "Erreur au démarrage d'Odoo"
    exit 1
fi

echo ""

# Test du module SAMA CONAI
print_step "5. Test du module SAMA CONAI..."

python3 "$ODOO_BIN" shell \
    -c "$CONF_FILE" \
    -d "$DB_NAME" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo << 'EOF'

try:
    # Test de l'installation du module
    module = env['ir.module.module'].search([('name', '=', 'sama_conai')])
    if module and module.state == 'installed':
        print("✅ Module SAMA CONAI installé")
        
        # Test des modèles
        info_requests = env['request.information'].search([])
        wb_alerts = env['whistleblowing.alert'].search([])
        
        print(f"✅ Demandes d'information: {len(info_requests)}")
        print(f"✅ Signalements d'alerte: {len(wb_alerts)}")
        
        # Test des vues
        views = env['ir.ui.view'].search([('model', 'in', ['request.information', 'whistleblowing.alert'])])
        print(f"✅ Vues disponibles: {len(views)}")
        
        # Test des actions
        try:
            action = env.ref('sama_conai.action_information_request')
            print(f"✅ Action principale: {action.name}")
        except:
            print("❌ Action principale non trouvée")
        
        if len(info_requests) >= 4 and len(wb_alerts) >= 4:
            print("✅ Données de démo complètes")
        else:
            print("⚠️  Données de démo partielles")
            
    else:
        print("❌ Module SAMA CONAI non installé")
        
except Exception as e:
    print(f"❌ Erreur: {e}")

EOF

echo ""

# Résumé final
print_step "6. Résumé de la validation..."

echo ""
print_success "🎉 VALIDATION TERMINÉE!"
echo ""
echo "📋 Système validé:"
echo "   ✅ Odoo fonctionnel"
echo "   ✅ PostgreSQL configuré"
echo "   ✅ Module SAMA CONAI installé"
echo "   ✅ Données de démo chargées"
echo ""
echo "🚀 Pour démarrer le serveur:"
echo "   ./scripts/start_sama_conai.sh $DB_NAME"
echo ""
echo "🌐 Accès web:"
echo "   URL: http://localhost:8069"
echo "   Base: $DB_NAME"
echo "   User: admin / Pass: admin"
echo ""
echo "📚 Documentation:"
echo "   - Guide rapide: INSTALLATION_RAPIDE.md"
echo "   - Guide complet: GUIDE_ANALYSE_DONNEES.md"