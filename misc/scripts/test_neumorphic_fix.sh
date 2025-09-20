#!/bin/bash

# ========================================
# SAMA CONAI - TEST CORRECTION NEUMORPHIQUE
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 Test des corrections neumorphiques...${NC}"
echo ""

# Arrêter et redémarrer Odoo
echo -e "${YELLOW}🔄 Redémarrage d'Odoo...${NC}"
pkill -f "odoo-bin" || true
sleep 5

# Redémarrer avec mise à jour
nohup bash -c "
    source /home/grand-as/odoo18-venv/bin/activate 2>/dev/null || true
    cd /var/odoo/odoo18
    python3 odoo-bin \
        -d sama_conai_test \
        --addons-path='/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons' \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --http-port=8077 \
        --log-level=info \
        --workers=0 \
        -u sama_conai
" > "$SCRIPT_DIR/logs/test_fix.log" 2>&1 &

echo -e "${BLUE}⏳ Attente du démarrage (60 secondes)...${NC}"
sleep 60

# Tester les routes
echo -e "${BLUE}🔍 Test des routes...${NC}"

# Test route principale
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8077/sama_conai/dashboard")
if [ "$response" = "200" ] || [ "$response" = "302" ]; then
    echo -e "${GREEN}✅ Route dashboard: $response${NC}"
else
    echo -e "${RED}❌ Route dashboard: $response${NC}"
fi

# Test route thème
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8077/sama_conai/theme_selector")
if [ "$response" = "200" ] || [ "$response" = "302" ]; then
    echo -e "${GREEN}✅ Route thème: $response${NC}"
else
    echo -e "${RED}❌ Route thème: $response${NC}"
fi

# Test route mobile
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8077/sama_conai/dashboard/mobile")
if [ "$response" = "200" ] || [ "$response" = "302" ]; then
    echo -e "${GREEN}✅ Route mobile: $response${NC}"
else
    echo -e "${RED}❌ Route mobile: $response${NC}"
fi

echo ""
echo -e "${BLUE}📋 Logs récents:${NC}"
tail -n 10 "$SCRIPT_DIR/logs/test_fix.log"

echo ""
echo -e "${GREEN}🎯 Accès direct:${NC}"
echo -e "${BLUE}   http://localhost:8077/sama_conai/dashboard${NC}"
echo -e "${BLUE}   http://localhost:8077/sama_conai/theme_selector${NC}"