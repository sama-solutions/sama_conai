#!/bin/bash

# Script d'installation simple et robuste pour SAMA CONAI

echo "🚀 INSTALLATION SIMPLE SAMA CONAI"
echo "================================="
echo ""

# Variables
DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
ODOO_BIN="$ODOO_PATH/odoo-bin"
VENV_PATH="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_step() { echo -e "${BLUE}📋 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

print_step "Configuration:"
echo "   Base de données: $DB_NAME"
echo "   Odoo: $ODOO_PATH"
echo "   Custom addons: $CUSTOM_ADDONS_PATH"
echo ""

# Activation de l'environnement virtuel
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

# Étape 1: Créer/initialiser la base de données avec les modules de base
print_step "Étape 1: Initialisation de la base de données..."

python3 "$ODOO_BIN" \
    -d "$DB_NAME" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --without-demo=all \
    --log-level=warn

if [ $? -eq 0 ]; then
    print_success "Base de données initialisée"
else
    print_error "Erreur lors de l'initialisation"
    echo ""
    echo "Tentative de suppression et recréation de la base..."
    
    # Supprimer la base existante
    dropdb -h localhost -U odoo "$DB_NAME" 2>/dev/null || true
    
    # Recréer la base
    createdb -h localhost -U odoo "$DB_NAME" 2>/dev/null
    
    # Réessayer l'initialisation
    python3 "$ODOO_BIN" \
        -d "$DB_NAME" \
        --addons-path="$CUSTOM_ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --stop-after-init \
        --without-demo=all \
        --log-level=warn
    
    if [ $? -eq 0 ]; then
        print_success "Base de données recréée et initialisée"
    else
        print_error "Impossible d'initialiser la base de données"
        exit 1
    fi
fi

echo ""

# Étape 2: Installation du module SAMA CONAI
print_step "Étape 2: Installation du module SAMA CONAI..."

python3 "$ODOO_BIN" \
    -d "$DB_NAME" \
    -i sama_conai \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --log-level=warn

if [ $? -eq 0 ]; then
    print_success "Module SAMA CONAI installé avec succès"
else
    print_error "Erreur lors de l'installation du module"
    echo ""
    echo "Vérification des logs..."
    echo "Dernières lignes du log Odoo:"
    tail -20 /var/log/odoo/odoo.log | grep -E "(ERROR|CRITICAL|sama_conai)"
    exit 1
fi

echo ""

# Étape 3: Test rapide
print_step "Étape 3: Test rapide du module..."

python3 "$ODOO_BIN" shell \
    -d "$DB_NAME" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo << 'EOF'

try:
    # Test de base
    module = env['ir.module.module'].search([('name', '=', 'sama_conai')])
    if module and module.state == 'installed':
        print("✅ Module SAMA CONAI installé et actif")
        
        # Test des modèles
        info_model = env['request.information']
        wb_model = env['whistleblowing.alert']
        
        print(f"✅ Modèle demandes d'information: {info_model}")
        print(f"✅ Modèle signalements d'alerte: {wb_model}")
        
        # Compter les enregistrements
        info_count = info_model.search_count([])
        wb_count = wb_model.search_count([])
        
        print(f"📊 Demandes d'information: {info_count}")
        print(f"🚨 Signalements d'alerte: {wb_count}")
        
        if info_count > 0 or wb_count > 0:
            print("✅ Données de démo chargées")
        else:
            print("⚠️  Aucune donnée de démo trouvée")
            
    else:
        print("❌ Module SAMA CONAI non installé correctement")
        
except Exception as e:
    print(f"❌ Erreur lors du test: {e}")

EOF

echo ""

# Résumé
print_success "🎉 Installation terminée!"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Démarrer le serveur:"
echo "      cd $ODOO_PATH"
echo "      python3 $ODOO_BIN -d $DB_NAME --addons-path=$CUSTOM_ADDONS_PATH"
echo ""
echo "   2. Se connecter à Odoo:"
echo "      URL: http://localhost:8069"
echo "      Base: $DB_NAME"
echo "      User: admin / Pass: admin"
echo ""
echo "   3. Aller dans le menu 'Accès à l'Information'"
echo ""
echo "🔧 En cas de problème:"
echo "   - Vérifier les logs: tail -f /var/log/odoo/odoo.log"
echo "   - Relancer ce script: ./scripts/install_simple.sh $DB_NAME"