#!/bin/bash

# ========================================
# SAMA CONAI - TEST RAPIDE DU STACK
# ========================================
# Script de test pour vérifier le bon fonctionnement
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

# Configuration (basée sur vos scripts existants)
ODOO_PORT="8077"
MOBILE_PORT="3005"
POSTGRES_PORT="5432"

echo -e "${PURPLE}${BOLD}🧪 SAMA CONAI - Test Rapide du Stack${NC}"
echo "====================================="
echo ""

# Test 1: Vérifier les prérequis
echo -e "${BLUE}1. Test des prérequis système...${NC}"

if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✅ Python3: $(python3 --version)${NC}"
else
    echo -e "${RED}❌ Python3 non trouvé${NC}"
fi

if command -v node &> /dev/null; then
    echo -e "${GREEN}✅ Node.js: $(node --version)${NC}"
else
    echo -e "${RED}❌ Node.js non trouvé${NC}"
fi

if command -v npm &> /dev/null; then
    echo -e "${GREEN}✅ npm: $(npm --version)${NC}"
else
    echo -e "${RED}❌ npm non trouvé${NC}"
fi

if command -v psql &> /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL: $(psql --version | head -n1)${NC}"
else
    echo -e "${RED}❌ PostgreSQL non trouvé${NC}"
fi

echo ""

# Test 2: Vérifier l'environnement
echo -e "${BLUE}2. Test de l'environnement...${NC}"

if [ -f "/home/grand-as/odoo18-venv/bin/activate" ]; then
    echo -e "${GREEN}✅ Environnement virtuel Python trouvé${NC}"
else
    echo -e "${RED}❌ Environnement virtuel Python non trouvé${NC}"
fi

if [ -f "/var/odoo/odoo18/odoo-bin" ]; then
    echo -e "${GREEN}✅ Installation Odoo trouvée${NC}"
else
    echo -e "${RED}❌ Installation Odoo non trouvée${NC}"
fi

if [ -f "$SCRIPT_DIR/__manifest__.py" ]; then
    echo -e "${GREEN}✅ Module SAMA CONAI trouvé${NC}"
else
    echo -e "${RED}❌ Module SAMA CONAI non trouvé${NC}"
fi

if [ -d "$SCRIPT_DIR/mobile_app_web" ] && [ -f "$SCRIPT_DIR/mobile_app_web/server.js" ]; then
    echo -e "${GREEN}✅ Application mobile web trouvée${NC}"
else
    echo -e "${RED}❌ Application mobile web non trouvée${NC}"
fi

echo ""

# Test 3: Vérifier les ports
echo -e "${BLUE}3. Test de disponibilité des ports...${NC}"

check_port() {
    local port=$1
    local service=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pid=$(lsof -ti:$port)
        local process=$(ps -p $pid -o comm= 2>/dev/null || echo "inconnu")
        echo -e "${YELLOW}⚠️ Port $port ($service): Occupé par $process (PID: $pid)${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Port $port ($service): Disponible${NC}"
        return 0
    fi
}

check_port $ODOO_PORT "Odoo"
check_port $MOBILE_PORT "Mobile"
check_port $POSTGRES_PORT "PostgreSQL"

echo ""

# Test 4: Vérifier les scripts
echo -e "${BLUE}4. Test des scripts...${NC}"

if [ -x "$SCRIPT_DIR/startup_sama_conai_stack.sh" ]; then
    echo -e "${GREEN}✅ Script principal exécutable${NC}"
else
    echo -e "${RED}❌ Script principal non exécutable${NC}"
fi

if [ -x "$SCRIPT_DIR/start_mobile_final.sh" ]; then
    echo -e "${GREEN}✅ Script mobile existant exécutable${NC}"
else
    echo -e "${YELLOW}⚠️ Script mobile existant non exécutable${NC}"
fi

if [ -x "$SCRIPT_DIR/setup_stack.sh" ]; then
    echo -e "${GREEN}✅ Script de configuration exécutable${NC}"
else
    echo -e "${RED}❌ Script de configuration non exécutable${NC}"
fi

echo ""

# Test 5: Vérifier les dépendances npm
echo -e "${BLUE}5. Test des dépendances npm...${NC}"

if [ -d "$SCRIPT_DIR/mobile_app_web" ]; then
    cd "$SCRIPT_DIR/mobile_app_web"
    
    if [ -f "package.json" ]; then
        echo -e "${GREEN}✅ package.json trouvé${NC}"
        
        if [ -d "node_modules" ]; then
            echo -e "${GREEN}✅ Dépendances npm installées${NC}"
        else
            echo -e "${YELLOW}⚠️ Dépendances npm non installées${NC}"
            echo -e "${BLUE}   Exécutez: cd mobile_app_web && npm install${NC}"
        fi
    else
        echo -e "${RED}❌ package.json non trouvé${NC}"
    fi
    
    cd "$SCRIPT_DIR"
else
    echo -e "${RED}❌ Répertoire mobile_app_web non trouvé${NC}"
fi

echo ""

# Test 6: Test de connectivité PostgreSQL
echo -e "${BLUE}6. Test de connectivité PostgreSQL...${NC}"

if pgrep -x "postgres" > /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL en cours d'exécution${NC}"
    
    if pg_isready -h localhost -p $POSTGRES_PORT >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL accessible${NC}"
        
        # Test de connexion avec les credentials
        if PGPASSWORD="odoo" psql -h localhost -U odoo -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Connexion PostgreSQL avec credentials OK${NC}"
        else
            echo -e "${YELLOW}⚠️ Connexion PostgreSQL avec credentials échouée${NC}"
        fi
    else
        echo -e "${RED}❌ PostgreSQL non accessible${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ PostgreSQL non en cours d'exécution${NC}"
fi

echo ""

# Test 7: Vérifier les répertoires
echo -e "${BLUE}7. Test des répertoires...${NC}"

if [ -d "$SCRIPT_DIR/.pids" ]; then
    echo -e "${GREEN}✅ Répertoire .pids existe${NC}"
else
    echo -e "${YELLOW}⚠️ Répertoire .pids n'existe pas (sera créé)${NC}"
fi

if [ -d "$SCRIPT_DIR/logs" ]; then
    echo -e "${GREEN}✅ Répertoire logs existe${NC}"
else
    echo -e "${YELLOW}⚠️ Répertoire logs n'existe pas (sera créé)${NC}"
fi

if [ -w "$SCRIPT_DIR" ]; then
    echo -e "${GREEN}✅ Permissions d'écriture OK${NC}"
else
    echo -e "${RED}❌ Permissions d'écriture insuffisantes${NC}"
fi

echo ""

# Résumé et recommandations
echo -e "${PURPLE}${BOLD}📋 RÉSUMÉ ET RECOMMANDATIONS${NC}"
echo "================================"
echo ""

echo -e "${BLUE}${BOLD}Pour démarrer SAMA CONAI:${NC}"
echo ""

# Vérifier si la configuration est nécessaire
need_setup=false

if [ ! -d "$SCRIPT_DIR/.pids" ] || [ ! -d "$SCRIPT_DIR/logs" ]; then
    need_setup=true
fi

if [ -d "$SCRIPT_DIR/mobile_app_web" ] && [ ! -d "$SCRIPT_DIR/mobile_app_web/node_modules" ]; then
    need_setup=true
fi

if [ ! -x "$SCRIPT_DIR/startup_sama_conai_stack.sh" ]; then
    need_setup=true
fi

if $need_setup; then
    echo -e "${YELLOW}1. Exécutez d'abord la configuration:${NC}"
    echo -e "${WHITE}   ./setup_stack.sh${NC}"
    echo ""
fi

echo -e "${GREEN}${need_setup && echo "2." || echo "1."} Démarrez le stack complet:${NC}"
echo -e "${WHITE}   ./startup_sama_conai_stack.sh${NC}"
echo ""

echo -e "${BLUE}${BOLD}Ou utilisez vos scripts existants:${NC}"
echo -e "${WHITE}   ./start_mobile_final.sh              # Mobile uniquement${NC}"
echo -e "${WHITE}   ./launch_sama_conai.sh               # Odoo avancé${NC}"
echo -e "${WHITE}   ./start_sama_conai.sh                # Odoo simple${NC}"
echo ""

echo -e "${GREEN}🎉 Test terminé !${NC}"