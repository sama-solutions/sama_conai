#!/bin/bash

# ========================================
# SAMA CONAI - DIAGNOSTIC INTERFACE UX
# ========================================
# Script pour diagnostiquer pourquoi l'ancienne interface est affichée
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

echo -e "${PURPLE}${BOLD}🔍 SAMA CONAI - Diagnostic Interface UX${NC}"
echo "======================================="
echo ""

# Fonction pour vérifier un fichier
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$SCRIPT_DIR/$file" ]; then
        echo -e "${GREEN}✅ $description${NC}"
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

# Fonction pour vérifier une URL
check_url() {
    local url="$1"
    local description="$2"
    
    if curl -s --connect-timeout 5 "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $description${NC}"
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

echo -e "${BLUE}1. Vérification des fichiers neumorphiques...${NC}"
echo "=============================================="

# Vérifier les fichiers CSS
check_file "static/src/css/base_styles.css" "CSS de base neumorphique"
check_file "static/src/css/themes/theme_institutionnel.css" "Thème institutionnel"
check_file "static/src/css/themes/theme_terre.css" "Thème terre du Sénégal"
check_file "static/src/css/themes/theme_moderne.css" "Thème moderne"

# Vérifier les fichiers JavaScript
check_file "static/src/js/theme_switcher.js" "JavaScript changement de thème"
check_file "static/src/js/dashboard_client_action.js" "JavaScript dashboard client action"

# Vérifier les templates
check_file "templates/dashboard/sama_conai_dashboard_neumorphic.xml" "Template dashboard neumorphique"
check_file "views/dashboard_neumorphic_views.xml" "Vues dashboard neumorphique"

# Vérifier le contrôleur
check_file "controllers/dashboard_controller.py" "Contrôleur dashboard"

echo ""

echo -e "${BLUE}2. Vérification de la configuration du module...${NC}"
echo "================================================"

# Vérifier le manifest
if grep -q "dashboard_neumorphic_views.xml" "$SCRIPT_DIR/__manifest__.py"; then
    echo -e "${GREEN}✅ Vues neumorphiques activées dans __manifest__.py${NC}"
else
    echo -e "${RED}❌ Vues neumorphiques non activées dans __manifest__.py${NC}"
fi

if grep -q "sama_conai_dashboard_neumorphic.xml" "$SCRIPT_DIR/__manifest__.py"; then
    echo -e "${GREEN}✅ Templates neumorphiques activés dans __manifest__.py${NC}"
else
    echo -e "${RED}❌ Templates neumorphiques non activés dans __manifest__.py${NC}"
fi

# Vérifier les assets
if grep -q "dashboard_client_action.js" "$SCRIPT_DIR/views/assets.xml"; then
    echo -e "${GREEN}✅ JavaScript dashboard inclus dans assets.xml${NC}"
else
    echo -e "${RED}❌ JavaScript dashboard non inclus dans assets.xml${NC}"
fi

echo ""

echo -e "${BLUE}3. Vérification des services Odoo...${NC}"
echo "===================================="

# Vérifier si Odoo est en cours d'exécution
if pgrep -f "odoo-bin" > /dev/null; then
    local odoo_pid=$(pgrep -f "odoo-bin")
    echo -e "${GREEN}✅ Odoo en cours d'exécution (PID: $odoo_pid)${NC}"
    
    # Vérifier les ports
    if lsof -Pi :8077 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Odoo accessible sur le port 8077${NC}"
        ODOO_PORT="8077"
    elif lsof -Pi :8069 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Odoo accessible sur le port 8069${NC}"
        ODOO_PORT="8069"
    elif lsof -Pi :8075 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Odoo accessible sur le port 8075${NC}"
        ODOO_PORT="8075"
    else
        echo -e "${RED}❌ Odoo non accessible sur les ports standards${NC}"
        ODOO_PORT=""
    fi
else
    echo -e "${RED}❌ Odoo non en cours d'exécution${NC}"
    ODOO_PORT=""
fi

echo ""

echo -e "${BLUE}4. Test d'accès aux routes neumorphiques...${NC}"
echo "==========================================="

if [ ! -z "$ODOO_PORT" ]; then
    # Tester l'accès principal
    check_url "http://localhost:$ODOO_PORT" "Interface Odoo principale"
    
    # Tester les routes neumorphiques (sans authentification, donc 302 attendu)
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$ODOO_PORT/sama_conai/dashboard" | grep -q "302"; then
        echo -e "${GREEN}✅ Route dashboard neumorphique existe (redirection d'authentification)${NC}"
    else
        echo -e "${RED}❌ Route dashboard neumorphique non accessible${NC}"
    fi
    
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$ODOO_PORT/sama_conai/theme_selector" | grep -q "302"; then
        echo -e "${GREEN}✅ Route sélecteur de thème existe (redirection d'authentification)${NC}"
    else
        echo -e "${RED}❌ Route sélecteur de thème non accessible${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Impossible de tester les routes - Odoo non accessible${NC}"
fi

echo ""

echo -e "${BLUE}5. Vérification de la base de données...${NC}"
echo "========================================"

# Vérifier PostgreSQL
if pgrep -x "postgres" > /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL en cours d'exécution${NC}"
    
    # Vérifier la base de données sama_conai_test
    if PGPASSWORD="odoo" psql -h localhost -U odoo -lqt | cut -d \| -f 1 | grep -qw "sama_conai_test"; then
        echo -e "${GREEN}✅ Base de données sama_conai_test existe${NC}"
    else
        echo -e "${YELLOW}⚠️ Base de données sama_conai_test non trouvée${NC}"
    fi
else
    echo -e "${RED}❌ PostgreSQL non en cours d'exécution${NC}"
fi

echo ""

echo -e "${BLUE}6. Analyse des logs récents...${NC}"
echo "=============================="

# Vérifier les logs Odoo récents
if [ -f "$SCRIPT_DIR/logs/odoo.log" ]; then
    echo -e "${BLUE}📋 Logs Odoo récents:${NC}"
    tail -n 5 "$SCRIPT_DIR/logs/odoo.log" | while read line; do
        if echo "$line" | grep -q "ERROR"; then
            echo -e "${RED}   $line${NC}"
        elif echo "$line" | grep -q "WARNING"; then
            echo -e "${YELLOW}   $line${NC}"
        else
            echo -e "${WHITE}   $line${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️ Aucun log Odoo trouvé dans logs/odoo.log${NC}"
fi

echo ""

echo -e "${PURPLE}${BOLD}📋 RÉSUMÉ DU DIAGNOSTIC${NC}"
echo "========================"
echo ""

# Déterminer le problème principal
echo -e "${BLUE}${BOLD}Problèmes détectés:${NC}"

problems_found=false

# Vérifier si les fichiers neumorphiques existent
if [ ! -f "$SCRIPT_DIR/static/src/css/base_styles.css" ] || [ ! -f "$SCRIPT_DIR/static/src/js/dashboard_client_action.js" ]; then
    echo -e "${RED}❌ Fichiers neumorphiques manquants${NC}"
    problems_found=true
fi

# Vérifier si les vues sont activées
if ! grep -q "dashboard_neumorphic_views.xml" "$SCRIPT_DIR/__manifest__.py"; then
    echo -e "${RED}❌ Vues neumorphiques non activées dans le manifest${NC}"
    problems_found=true
fi

# Vérifier si Odoo fonctionne
if [ -z "$ODOO_PORT" ]; then
    echo -e "${RED}❌ Odoo non accessible${NC}"
    problems_found=true
fi

if [ "$problems_found" = false ]; then
    echo -e "${GREEN}✅ Aucun problème majeur détecté${NC}"
fi

echo ""

echo -e "${BLUE}${BOLD}🔧 SOLUTIONS RECOMMANDÉES:${NC}"
echo ""

echo -e "${WHITE}1. Pour activer l'interface neumorphique:${NC}"
echo -e "${CYAN}   ./activate_neumorphic_ui.sh${NC}"
echo ""

echo -e "${WHITE}2. Pour redémarrer complètement:${NC}"
echo -e "${CYAN}   ./startup_sama_conai_stack.sh stop${NC}"
echo -e "${CYAN}   ./startup_sama_conai_stack.sh start${NC}"
echo ""

echo -e "${WHITE}3. Pour mettre à jour manuellement le module:${NC}"
echo -e "${CYAN}   source /home/grand-as/odoo18-venv/bin/activate${NC}"
echo -e "${CYAN}   cd /var/odoo/odoo18${NC}"
echo -e "${CYAN}   python3 odoo-bin -d sama_conai_test -u sama_conai --stop-after-init${NC}"
echo ""

echo -e "${WHITE}4. Pour accéder au nouveau dashboard:${NC}"
if [ ! -z "$ODOO_PORT" ]; then
    echo -e "${CYAN}   http://localhost:$ODOO_PORT${NC}"
    echo -e "${WHITE}   Menu → Analytics & Rapports → Tableaux de Bord → Tableau de Bord Principal${NC}"
else
    echo -e "${YELLOW}   Démarrez d'abord Odoo${NC}"
fi
echo ""

echo -e "${GREEN}🇸🇳 Diagnostic terminé !${NC}"