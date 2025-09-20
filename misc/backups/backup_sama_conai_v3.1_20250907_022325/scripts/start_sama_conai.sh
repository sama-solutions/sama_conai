#!/bin/bash

# Script de démarrage SAMA CONAI

echo "🚀 DÉMARRAGE SAMA CONAI"
echo "======================"
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

print_step "Configuration:"
echo "   Base de données: $DB_NAME"
echo "   Port: 8069"
echo "   URL: http://localhost:8069"
echo ""

# Activation de l'environnement virtuel
print_step "Activation de l'environnement virtuel..."
source "$VENV_PATH/bin/activate"
print_success "Environnement virtuel activé"

# Changement vers le répertoire Odoo
cd "$ODOO_PATH"

print_step "Démarrage du serveur Odoo..."
echo "Appuyez sur Ctrl+C pour arrêter le serveur"
echo ""

# Démarrage du serveur
python3 "$ODOO_BIN" \
    -c "$CONF_FILE" \
    -d "$DB_NAME" \
    --addons-path="$CUSTOM_ADDONS_PATH" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --http-port=8069