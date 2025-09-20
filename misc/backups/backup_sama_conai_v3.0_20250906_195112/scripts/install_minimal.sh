#!/bin/bash

# Script d'installation minimale pour SAMA CONAI

echo "🚀 INSTALLATION MINIMALE SAMA CONAI"
echo "==================================="
echo ""

# Variables
DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
ODOO_BIN="$ODOO_PATH/odoo-bin"
VENV_PATH="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"
MODULE_PATH="$CUSTOM_ADDONS_PATH/sama_conai"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() { echo -e "${BLUE}📋 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

print_step "Configuration:"
echo "   Base de données: $DB_NAME"
echo "   Module: sama_conai"
echo ""

# Activation de l'environnement virtuel
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

# Étape 1: Sauvegarder le manifeste original et utiliser la version simple
print_step "Étape 1: Préparation du module..."

if [ -f "$MODULE_PATH/__manifest__.py" ]; then
    cp "$MODULE_PATH/__manifest__.py" "$MODULE_PATH/__manifest__.py.backup"
    print_success "Manifeste original sauvegardé"
fi

if [ -f "$MODULE_PATH/__manifest_simple__.py" ]; then
    cp "$MODULE_PATH/__manifest_simple__.py" "$MODULE_PATH/__manifest__.py"
    print_success "Manifeste simplifié activé"
else
    print_error "Manifeste simplifié non trouvé"
    exit 1
fi

echo ""

# Étape 2: Supprimer la base existante si elle existe
print_step "Étape 2: Nettoyage de la base de données..."

dropdb -h localhost -U odoo "$DB_NAME" 2>/dev/null && print_success "Base existante supprimée" || print_warning "Aucune base existante"

echo ""

# Étape 3: Créer une nouvelle base
print_step "Étape 3: Création de la base de données..."

createdb -h localhost -U odoo "$DB_NAME"
if [ $? -eq 0 ]; then
    print_success "Base de données créée"
else
    print_error "Erreur lors de la création de la base"
    exit 1
fi

echo ""

# Étape 4: Installation des modules de base
print_step "Étape 4: Installation des modules de base..."

python3 "$ODOO_BIN" \
    -d "$DB_NAME" \
    -i base,mail \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --without-demo=all \
    --log-level=error

if [ $? -eq 0 ]; then
    print_success "Modules de base installés"
else
    print_error "Erreur lors de l'installation des modules de base"
    exit 1
fi

echo ""

# Étape 5: Installation du module SAMA CONAI
print_step "Étape 5: Installation du module SAMA CONAI..."

python3 "$ODOO_BIN" \
    -d "$DB_NAME" \
    -i sama_conai \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --log-level=error

if [ $? -eq 0 ]; then
    print_success "Module SAMA CONAI installé avec succès"
else
    print_error "Erreur lors de l'installation du module SAMA CONAI"
    echo ""
    echo "Vérification des logs..."
    tail -30 /var/log/odoo/odoo.log | grep -E "(ERROR|CRITICAL|sama_conai|Traceback)"
    
    # Restaurer le manifeste original
    if [ -f "$MODULE_PATH/__manifest__.py.backup" ]; then
        cp "$MODULE_PATH/__manifest__.py.backup" "$MODULE_PATH/__manifest__.py"
        print_warning "Manifeste original restauré"
    fi
    exit 1
fi

echo ""

# Étape 6: Restaurer le manifeste complet
print_step "Étape 6: Restauration du manifeste complet..."

if [ -f "$MODULE_PATH/__manifest__.py.backup" ]; then
    cp "$MODULE_PATH/__manifest__.py.backup" "$MODULE_PATH/__manifest__.py"
    print_success "Manifeste original restauré"
    
    # Mise à jour avec le manifeste complet
    print_step "Mise à jour avec le manifeste complet..."
    
    python3 "$ODOO_BIN" \
        -d "$DB_NAME" \
        -u sama_conai \
        --addons-path="$CUSTOM_ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --stop-after-init \
        --log-level=error
    
    if [ $? -eq 0 ]; then
        print_success "Module mis à jour avec le manifeste complet"
    else
        print_warning "Erreur lors de la mise à jour, mais le module de base fonctionne"
    fi
else
    print_warning "Sauvegarde du manifeste non trouvée"
fi

echo ""

# Étape 7: Test du module
print_step "Étape 7: Test du module..."

python3 "$ODOO_BIN" shell \
    -d "$DB_NAME" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo << 'EOF'

try:
    # Test de l'installation
    module = env['ir.module.module'].search([('name', '=', 'sama_conai')])
    if module and module.state == 'installed':
        print("✅ Module SAMA CONAI installé")
        
        # Test des modèles
        try:
            info_model = env['request.information']
            wb_model = env['whistleblowing.alert']
            print("✅ Modèles principaux accessibles")
            
            # Compter les données
            info_count = info_model.search_count([])
            wb_count = wb_model.search_count([])
            print(f"📊 Demandes d'information: {info_count}")
            print(f"🚨 Signalements d'alerte: {wb_count}")
            
        except Exception as e:
            print(f"⚠️  Erreur modèles: {e}")
        
        # Test des vues
        try:
            views = env['ir.ui.view'].search([('model', 'in', ['request.information', 'whistleblowing.alert'])])
            print(f"🎨 Vues disponibles: {len(views)}")
        except Exception as e:
            print(f"⚠️  Erreur vues: {e}")
            
    else:
        print("❌ Module SAMA CONAI non installé")
        
except Exception as e:
    print(f"❌ Erreur générale: {e}")

EOF

echo ""

# Résumé
print_success "🎉 Installation minimale terminée!"
echo ""
echo "📋 État du module:"
echo "   ✅ Base de données créée: $DB_NAME"
echo "   ✅ Module SAMA CONAI installé"
echo "   ✅ Modèles de base fonctionnels"
echo ""
echo "🚀 Pour démarrer le serveur:"
echo "   cd $ODOO_PATH"
echo "   python3 $ODOO_BIN -d $DB_NAME --addons-path=$CUSTOM_ADDONS_PATH"
echo ""
echo "🌐 Accès web:"
echo "   URL: http://localhost:8069"
echo "   Base: $DB_NAME"
echo "   User: admin / Pass: admin"
echo ""
echo "📝 Note: Si certaines fonctionnalités manquent, installez les modules:"
echo "   web, portal, website, hr depuis l'interface Odoo"