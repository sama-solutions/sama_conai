#!/bin/bash

# ========================================
# SAMA CONAI - DÉMARRAGE RAPIDE DU STACK
# ========================================
# Script de démarrage simplifié
# Version: 1.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Banner simplifié
echo ""
echo -e "${PURPLE}${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}${BOLD}║           SAMA CONAI STACK             ║${NC}"
echo -e "${PURPLE}${BOLD}║     Démarrage Rapide du Stack         ║${NC}"
echo -e "${PURPLE}${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

# Vérifier si le script principal existe
if [ ! -f "$SCRIPT_DIR/startup_sama_conai_complete.sh" ]; then
    echo -e "${RED}❌ Script principal non trouvé${NC}"
    echo "Exécutez d'abord: ./quick_setup.sh"
    exit 1
fi

# Vérifier si la configuration existe
if [ ! -f "$SCRIPT_DIR/config.env" ]; then
    echo -e "${YELLOW}⚠️ Configuration manquante${NC}"
    echo -e "${BLUE}🔧 Exécution de la configuration rapide...${NC}"
    "$SCRIPT_DIR/quick_setup.sh"
fi

# Démarrer le stack complet
echo -e "${GREEN}🚀 Démarrage du stack SAMA CONAI...${NC}"
echo ""

exec "$SCRIPT_DIR/startup_sama_conai_complete.sh" "$@"