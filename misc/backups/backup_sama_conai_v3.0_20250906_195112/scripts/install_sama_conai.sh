#!/bin/bash

# Script d'installation SAMA CONAI adapté à la configuration système

echo "🚀 INSTALLATION SAMA CONAI"
echo "=========================="
echo ""

# Variables de configuration
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

# Vérifications
print_step "Vérifications préliminaires..."

if [ ! -f "$ODOO_BIN" ]; then
    print_error "Odoo non trouvé dans $ODOO_PATH"
    exit 1
fi

if [ ! -d "$VENV_PATH" ]; then
    print_error "Environnement virtuel non trouvé dans $VENV_PATH"
    exit 1
fi

if [ ! -d "$MODULE_PATH" ]; then
    print_error "Module SAMA CONAI non trouvé dans $MODULE_PATH"
    exit 1
fi

print_success "Vérifications OK"

# Activation de l'environnement virtuel
print_step "Activation de l'environnement virtuel..."
source "$VENV_PATH/bin/activate"
print_success "Environnement virtuel activé"

# Affichage de la configuration
print_step "Configuration:"
echo "   Base de données: $DB_NAME"
echo "   Odoo: $ODOO_PATH"
echo "   Custom addons: $CUSTOM_ADDONS_PATH"
echo "   Module: sama_conai"
echo ""

# Confirmation
read -p "Continuer avec cette configuration? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation annulée."
    exit 0
fi

echo ""

# Changement vers le répertoire Odoo
cd "$ODOO_PATH"

# Installation/Mise à jour du module
print_step "Installation du module SAMA CONAI..."

python3 "$ODOO_BIN" \
    -c "$CONF_FILE" \
    -d "$DB_NAME" \
    -i sama_conai \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --stop-after-init \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo

if [ $? -eq 0 ]; then
    print_success "Module installé avec succès"
else
    print_error "Erreur lors de l'installation du module"
    print_warning "Tentative de mise à jour..."
    
    python3 "$ODOO_BIN" \
        -c "$CONF_FILE" \
        -d "$DB_NAME" \
        -u sama_conai \
        --addons-path="$CUSTOM_ADDONS_PATH" \
        --stop-after-init \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo
    
    if [ $? -eq 0 ]; then
        print_success "Module mis à jour avec succès"
    else
        print_error "Erreur lors de la mise à jour du module"
        exit 1
    fi
fi

echo ""

# Test des données
print_step "Test des données de démo..."
echo "exec(open('$MODULE_PATH/scripts/test_all_demo_waves.py').read())" | \
python3 "$ODOO_BIN" shell \
    -c "$CONF_FILE" \
    -d "$DB_NAME" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo

echo ""

# Démarrage du serveur (optionnel)
print_step "Démarrage du serveur Odoo..."
echo "Pour démarrer le serveur, utilisez:"
echo ""
echo "cd $ODOO_PATH"
echo "source $VENV_PATH/bin/activate"
echo "python3 $ODOO_BIN -c $CONF_FILE -d $DB_NAME --addons-path=$CUSTOM_ADDONS_PATH --db_host=localhost --db_user=odoo --db_password=odoo"
echo ""

read -p "Démarrer le serveur maintenant? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Démarrage du serveur Odoo..."
    python3 "$ODOO_BIN" \
        -c "$CONF_FILE" \
        -d "$DB_NAME" \
        --addons-path="$CUSTOM_ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo
else
    print_success "Installation terminée!"
    echo ""
    echo "🎯 Prochaines étapes:"
    echo "   1. Démarrer le serveur avec la commande ci-dessus"
    echo "   2. Se connecter à http://localhost:8069"
    echo "   3. Aller dans 'Accès à l'Information' > 'Demandes d'Information'"
    echo "   4. Explorer les vues Kanban, Graph et Pivot"
    echo ""
    echo "📚 Documentation:"
    echo "   - Guide d'analyse: $MODULE_PATH/GUIDE_ANALYSE_DONNEES.md"
    echo "   - Résumé des données: $MODULE_PATH/DEMO_DATA_SUMMARY.md"
fi