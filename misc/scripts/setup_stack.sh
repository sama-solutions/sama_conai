#!/bin/bash

# ========================================
# SAMA CONAI - CONFIGURATION DU STACK
# ========================================
# Script de configuration pour votre environnement existant
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

echo -e "${PURPLE}${BOLD}🔧 SAMA CONAI - Configuration du Stack${NC}"
echo "========================================"
echo ""

# Créer les répertoires nécessaires
echo -e "${BLUE}📁 Création des répertoires...${NC}"
mkdir -p "$SCRIPT_DIR/.pids"
mkdir -p "$SCRIPT_DIR/logs"
mkdir -p "$SCRIPT_DIR/backups"
echo -e "${GREEN}✅ Répertoires créés${NC}"

# Vérifier les permissions
echo -e "${BLUE}🔐 Vérification des permissions...${NC}"
if [ -w "$SCRIPT_DIR" ]; then
    echo -e "${GREEN}✅ Permissions OK${NC}"
else
    echo -e "${RED}❌ Permissions insuffisantes${NC}"
    echo "Exécutez: chmod +w $SCRIPT_DIR"
    exit 1
fi

# Rendre les scripts exécutables
echo -e "${BLUE}⚙️ Configuration des scripts...${NC}"
chmod +x "$SCRIPT_DIR/startup_sama_conai_stack.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/start_mobile_final.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/launch_sama_conai.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/start_sama_conai.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
echo -e "${GREEN}✅ Scripts configurés${NC}"

# Vérifier l'environnement
echo -e "${BLUE}🔍 Vérification de l'environnement...${NC}"

# Vérifier l'environnement virtuel Python
if [ -f "/home/grand-as/odoo18-venv/bin/activate" ]; then
    echo -e "${GREEN}✅ Environnement virtuel Python trouvé${NC}"
else
    echo -e "${YELLOW}⚠️ Environnement virtuel Python non trouvé à l'emplacement standard${NC}"
fi

# Vérifier Odoo
if [ -f "/var/odoo/odoo18/odoo-bin" ]; then
    echo -e "${GREEN}✅ Installation Odoo trouvée${NC}"
else
    echo -e "${YELLOW}⚠️ Installation Odoo non trouvée à l'emplacement standard${NC}"
fi

# Vérifier l'application mobile
if [ -d "$SCRIPT_DIR/mobile_app_web" ] && [ -f "$SCRIPT_DIR/mobile_app_web/server.js" ]; then
    echo -e "${GREEN}✅ Application mobile web trouvée${NC}"
else
    echo -e "${YELLOW}⚠️ Application mobile web non trouvée${NC}"
fi

# Vérifier Node.js et npm
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    echo -e "${GREEN}✅ Node.js et npm disponibles${NC}"
    
    # Vérifier les dépendances de l'application mobile
    if [ -d "$SCRIPT_DIR/mobile_app_web" ]; then
        cd "$SCRIPT_DIR/mobile_app_web"
        if [ ! -d "node_modules" ]; then
            echo -e "${BLUE}📦 Installation des dépendances npm...${NC}"
            npm install
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Dépendances npm installées${NC}"
            else
                echo -e "${RED}❌ Erreur lors de l'installation des dépendances${NC}"
            fi
        else
            echo -e "${GREEN}✅ Dépendances npm déjà installées${NC}"
        fi
        cd "$SCRIPT_DIR"
    fi
else
    echo -e "${YELLOW}⚠️ Node.js ou npm non disponible${NC}"
fi

# Vérifier PostgreSQL
if command -v psql &> /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL disponible${NC}"
else
    echo -e "${YELLOW}⚠️ PostgreSQL non disponible${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Configuration terminée !${NC}"
echo ""
echo -e "${BLUE}${BOLD}Scripts disponibles:${NC}"
echo -e "${YELLOW}  ./startup_sama_conai_stack.sh${NC}        # Démarrer tout le stack (NOUVEAU)"
echo -e "${YELLOW}  ./startup_sama_conai_stack.sh stop${NC}   # Arrêter les services"
echo -e "${YELLOW}  ./startup_sama_conai_stack.sh status${NC} # Voir le statut"
echo -e "${YELLOW}  ./startup_sama_conai_stack.sh help${NC}   # Aide complète"
echo ""
echo -e "${BLUE}${BOLD}Scripts existants (compatibles):${NC}"
echo -e "${YELLOW}  ./start_mobile_final.sh${NC}              # Application mobile uniquement"
echo -e "${YELLOW}  ./launch_sama_conai.sh${NC}               # Odoo avec options avancées"
echo -e "${YELLOW}  ./start_sama_conai.sh${NC}                # Odoo simple"
echo ""
echo -e "${GREEN}🚀 Prêt à démarrer SAMA CONAI !${NC}"
echo ""
echo -e "${BLUE}${BOLD}Recommandation:${NC}"
echo -e "${WHITE}Utilisez ${YELLOW}./startup_sama_conai_stack.sh${WHITE} pour démarrer tout le stack automatiquement${NC}"