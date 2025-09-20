#!/bin/bash

# ========================================
# SAMA CONAI - DÉMARRAGE RAPIDE TOUT
# ========================================
# Script simple qui utilise vos scripts existants
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

echo -e "${PURPLE}${BOLD}🚀 SAMA CONAI - Démarrage Rapide${NC}"
echo "================================="
echo ""

# Fonction pour vérifier si un port est occupé
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port occupé
    else
        return 1  # Port libre
    fi
}

# Vérifier si Odoo est déjà en cours d'exécution
if check_port 8077; then
    echo -e "${GREEN}✅ Odoo déjà en cours d'exécution sur le port 8077${NC}"
    ODOO_RUNNING=true
else
    echo -e "${BLUE}🔧 Démarrage d'Odoo...${NC}"
    ODOO_RUNNING=false
fi

# Vérifier si l'application mobile est déjà en cours d'exécution
if check_port 3005; then
    echo -e "${GREEN}✅ Application mobile déjà en cours d'exécution sur le port 3005${NC}"
    MOBILE_RUNNING=true
else
    echo -e "${BLUE}📱 Démarrage de l'application mobile...${NC}"
    MOBILE_RUNNING=false
fi

echo ""

# Démarrer Odoo si nécessaire
if [ "$ODOO_RUNNING" = false ]; then
    if [ -f "$SCRIPT_DIR/start_sama_conai.sh" ]; then
        echo -e "${BLUE}🔧 Lancement d'Odoo avec start_sama_conai.sh...${NC}"
        
        # Démarrer Odoo en arrière-plan
        nohup "$SCRIPT_DIR/start_sama_conai.sh" > "$SCRIPT_DIR/logs/odoo_startup.log" 2>&1 &
        ODOO_PID=$!
        
        echo -e "${GREEN}✅ Odoo démarré en arrière-plan (PID: $ODOO_PID)${NC}"
        echo -e "${BLUE}   Logs: $SCRIPT_DIR/logs/odoo_startup.log${NC}"
        
        # Attendre un peu qu'Odoo démarre
        echo -e "${BLUE}⏳ Attente du démarrage d'Odoo (30 secondes)...${NC}"
        sleep 30
        
    else
        echo -e "${RED}❌ Script start_sama_conai.sh non trouvé${NC}"
        echo -e "${YELLOW}   Utilisez: ./startup_sama_conai_stack.sh${NC}"
        exit 1
    fi
fi

# Démarrer l'application mobile si nécessaire
if [ "$MOBILE_RUNNING" = false ]; then
    if [ -f "$SCRIPT_DIR/start_mobile_final.sh" ]; then
        echo -e "${BLUE}📱 Lancement de l'application mobile avec start_mobile_final.sh...${NC}"
        
        # Créer le répertoire logs s'il n'existe pas
        mkdir -p "$SCRIPT_DIR/logs"
        
        # Démarrer l'application mobile en arrière-plan
        nohup "$SCRIPT_DIR/start_mobile_final.sh" > "$SCRIPT_DIR/logs/mobile_startup.log" 2>&1 &
        MOBILE_PID=$!
        
        echo -e "${GREEN}✅ Application mobile démarrée en arrière-plan (PID: $MOBILE_PID)${NC}"
        echo -e "${BLUE}   Logs: $SCRIPT_DIR/logs/mobile_startup.log${NC}"
        
    else
        echo -e "${RED}❌ Script start_mobile_final.sh non trouvé${NC}"
        echo -e "${YELLOW}   Utilisez: ./startup_sama_conai_stack.sh${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}🎉 SAMA CONAI DÉMARRÉ !${NC}"
echo ""
echo -e "${BLUE}${BOLD}🌐 Accès aux services:${NC}"
echo -e "${WHITE}   📊 Odoo:${NC} ${CYAN}http://localhost:8077${NC}"
echo -e "${WHITE}   📱 Mobile:${NC} ${CYAN}http://localhost:3005${NC}"
echo ""
echo -e "${BLUE}${BOLD}🔑 Identifiants:${NC}"
echo -e "${WHITE}   👤 Odoo:${NC} admin / admin"
echo -e "${WHITE}   📱 Mobile:${NC} admin / admin ou demo@sama-conai.sn / demo123"
echo ""
echo -e "${BLUE}${BOLD}📋 Logs:${NC}"
if [ "$ODOO_RUNNING" = false ]; then
    echo -e "${WHITE}   🔧 Odoo:${NC} tail -f $SCRIPT_DIR/logs/odoo_startup.log"
fi
if [ "$MOBILE_RUNNING" = false ]; then
    echo -e "${WHITE}   📱 Mobile:${NC} tail -f $SCRIPT_DIR/logs/mobile_startup.log"
fi
echo ""
echo -e "${BLUE}${BOLD}🛑 Pour arrêter:${NC}"
echo -e "${WHITE}   Utilisez Ctrl+C dans les terminaux des services${NC}"
echo -e "${WHITE}   Ou: pkill -f 'odoo-bin' && pkill -f 'node.*server.js'${NC}"
echo ""
echo -e "${GREEN}🇸🇳 Plateforme de transparence du Sénégal opérationnelle !${NC}"