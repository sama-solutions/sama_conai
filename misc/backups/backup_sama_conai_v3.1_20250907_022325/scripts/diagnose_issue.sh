#!/bin/bash

# Script de diagnostic des problèmes d'installation

echo "🔍 DIAGNOSTIC DES PROBLÈMES SAMA CONAI"
echo "======================================"
echo ""

# Variables
DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
ODOO_BIN="$ODOO_PATH/odoo-bin"
VENV_PATH="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"
MODULE_PATH="$CUSTOM_ADDONS_PATH/sama_conai"

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

# 1. Vérification des chemins
print_step "1. Vérification des chemins..."

if [ -f "$ODOO_BIN" ]; then
    print_success "Odoo trouvé: $ODOO_BIN"
else
    print_error "Odoo non trouvé: $ODOO_BIN"
fi

if [ -d "$VENV_PATH" ]; then
    print_success "Environnement virtuel trouvé: $VENV_PATH"
else
    print_error "Environnement virtuel non trouvé: $VENV_PATH"
fi

if [ -d "$MODULE_PATH" ]; then
    print_success "Module SAMA CONAI trouvé: $MODULE_PATH"
else
    print_error "Module SAMA CONAI non trouvé: $MODULE_PATH"
fi

echo ""

# 2. Vérification de PostgreSQL
print_step "2. Vérification de PostgreSQL..."

if systemctl is-active --quiet postgresql; then
    print_success "PostgreSQL est actif"
else
    print_warning "PostgreSQL n'est pas actif"
    echo "   Tentative de démarrage..."
    sudo systemctl start postgresql
fi

# Test de connexion PostgreSQL
if pg_isready -h localhost -p 5432; then
    print_success "PostgreSQL répond sur le port 5432"
else
    print_error "PostgreSQL ne répond pas"
fi

echo ""

# 3. Vérification de l'environnement Python
print_step "3. Vérification de l'environnement Python..."

source "$VENV_PATH/bin/activate"

if python3 -c "import odoo" 2>/dev/null; then
    print_success "Module Odoo Python accessible"
    python3 -c "import odoo; print(f'Version Odoo: {odoo.release.version}')"
else
    print_error "Module Odoo Python non accessible"
fi

echo ""

# 4. Test de connexion Odoo simple
print_step "4. Test de connexion Odoo simple..."

cd "$ODOO_PATH"

# Test avec une base de données temporaire
echo "Test de démarrage Odoo..."
timeout 10s python3 "$ODOO_BIN" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init \
    --test-enable \
    --log-level=error 2>/dev/null

if [ $? -eq 0 ] || [ $? -eq 124 ]; then
    print_success "Odoo peut démarrer"
else
    print_error "Odoo ne peut pas démarrer"
fi

echo ""

# 5. Vérification du module SAMA CONAI
print_step "5. Vérification du module SAMA CONAI..."

if [ -f "$MODULE_PATH/__manifest__.py" ]; then
    print_success "Manifeste trouvé"
    
    # Vérifier la syntaxe Python
    if python3 -m py_compile "$MODULE_PATH/__manifest__.py" 2>/dev/null; then
        print_success "Manifeste syntaxiquement correct"
    else
        print_error "Erreur de syntaxe dans le manifeste"
    fi
    
    # Vérifier les dépendances
    echo "Dépendances du module:"
    python3 -c "
import sys
sys.path.append('$MODULE_PATH')
try:
    exec(open('$MODULE_PATH/__manifest__.py').read())
    depends = locals().get('depends', [])
    print(f'   Dépendances: {depends}')
except Exception as e:
    print(f'   Erreur: {e}')
"
else
    print_error "Manifeste non trouvé"
fi

echo ""

# 6. Test de création de base de données
print_step "6. Test de création de base de données..."

# Essayer de créer une base de test
TEST_DB="test_sama_conai_$(date +%s)"

echo "Création de base de test: $TEST_DB"
timeout 30s python3 "$ODOO_BIN" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    -d "$TEST_DB" \
    --stop-after-init \
    --without-demo=all \
    --log-level=error 2>/dev/null

if [ $? -eq 0 ] || [ $? -eq 124 ]; then
    print_success "Base de données de test créée"
    
    # Nettoyer
    echo "Suppression de la base de test..."
    dropdb -h localhost -U odoo "$TEST_DB" 2>/dev/null || true
else
    print_error "Impossible de créer une base de données"
fi

echo ""

# 7. Recommandations
print_step "7. Recommandations..."

echo "Solutions possibles:"
echo ""
echo "1. 🔧 Réinitialiser PostgreSQL:"
echo "   sudo systemctl restart postgresql"
echo ""
echo "2. 🗄️ Créer manuellement la base:"
echo "   createdb -h localhost -U odoo $DB_NAME"
echo ""
echo "3. 🐍 Réinstaller l'environnement virtuel:"
echo "   python3 -m venv $VENV_PATH --clear"
echo "   source $VENV_PATH/bin/activate"
echo "   pip install -r /var/odoo/odoo18/requirements.txt"
echo ""
echo "4. 📦 Installation simple du module:"
echo "   cd $ODOO_PATH"
echo "   python3 $ODOO_BIN -d $DB_NAME -i base --addons-path=$CUSTOM_ADDONS_PATH --stop-after-init"
echo "   python3 $ODOO_BIN -d $DB_NAME -i sama_conai --addons-path=$CUSTOM_ADDONS_PATH --stop-after-init"
echo ""
echo "5. 🔍 Vérifier les logs détaillés:"
echo "   tail -f /var/log/odoo/odoo.log"

echo ""
print_step "Diagnostic terminé"