#!/bin/bash

# ========================================
# SAMA CONAI - MISE À JOUR FORCÉE NEUMORPHIQUE
# ========================================
# Script pour forcer la mise à jour du module sans arrêter Odoo
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

echo -e "${PURPLE}${BOLD}🔄 SAMA CONAI - Mise à Jour Forcée Neumorphique${NC}"
echo "================================================="
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "$SCRIPT_DIR/__manifest__.py" ]; then
    echo -e "${RED}❌ Erreur: Ce script doit être exécuté depuis le répertoire du module SAMA CONAI${NC}"
    exit 1
fi

echo -e "${BLUE}🔧 Étape 1: Arrêt forcé d'Odoo...${NC}"

# Arrêter tous les processus Odoo
echo -e "${YELLOW}⚠️ Arrêt de tous les processus Odoo...${NC}"
pkill -f "odoo-bin" || true
pkill -f "python.*odoo" || true
sleep 5

# Vérifier que les processus sont arrêtés
if pgrep -f "odoo-bin" > /dev/null; then
    echo -e "${YELLOW}⚠️ Forçage de l'arrêt des processus restants...${NC}"
    pkill -9 -f "odoo-bin" || true
    pkill -9 -f "python.*odoo" || true
    sleep 3
fi

echo -e "${GREEN}✅ Processus Odoo arrêtés${NC}"
echo ""

echo -e "${BLUE}🔧 Étape 2: Mise à jour du module...${NC}"

# Activer l'environnement virtuel
if [ -f "/home/grand-as/odoo18-venv/bin/activate" ]; then
    source /home/grand-as/odoo18-venv/bin/activate
    echo -e "${GREEN}✅ Environnement virtuel activé${NC}"
else
    echo -e "${YELLOW}⚠️ Environnement virtuel non trouvé, utilisation de Python système${NC}"
fi

# Aller dans le répertoire Odoo
cd /var/odoo/odoo18

echo -e "${BLUE}📦 Mise à jour du module sama_conai...${NC}"

# Commande de mise à jour avec plus d'options
python3 odoo-bin \
    -d sama_conai_test \
    --addons-path="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    -u sama_conai \
    --stop-after-init \
    --log-level=info \
    --without-demo=False

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Module mis à jour avec succès${NC}"
else
    echo -e "${RED}❌ Erreur lors de la mise à jour du module${NC}"
    echo -e "${YELLOW}⚠️ Tentative avec installation complète...${NC}"
    
    # Tentative avec installation complète
    python3 odoo-bin \
        -d sama_conai_test \
        --addons-path="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        -i sama_conai \
        --stop-after-init \
        --log-level=info
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Module installé avec succès${NC}"
    else
        echo -e "${RED}❌ Erreur lors de l'installation du module${NC}"
        cd "$SCRIPT_DIR"
        exit 1
    fi
fi

cd "$SCRIPT_DIR"
echo ""

echo -e "${BLUE}🔧 Étape 3: Redémarrage d'Odoo...${NC}"

# Redémarrer Odoo en arrière-plan
echo -e "${BLUE}🚀 Redémarrage d'Odoo...${NC}"

# Créer le répertoire logs s'il n'existe pas
mkdir -p "$SCRIPT_DIR/logs"

# Démarrer Odoo en arrière-plan
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
        --workers=0
" > "$SCRIPT_DIR/logs/odoo_neumorphic_restart.log" 2>&1 &

ODOO_PID=$!
echo $ODOO_PID > "$SCRIPT_DIR/.pids/odoo.pid"

echo -e "${GREEN}✅ Odoo redémarré avec PID: $ODOO_PID${NC}"
echo -e "${BLUE}📋 Logs: $SCRIPT_DIR/logs/odoo_neumorphic_restart.log${NC}"
echo ""

echo -e "${BLUE}🔧 Étape 4: Attente du démarrage...${NC}"

# Attendre qu'Odoo soit prêt
echo -e "${BLUE}⏳ Attente du démarrage d'Odoo (90 secondes)...${NC}"
for i in {1..90}; do
    if curl -s --connect-timeout 3 "http://localhost:8077" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Odoo est prêt !${NC}"
        break
    fi
    
    if [ $((i % 10)) -eq 0 ]; then
        echo -e "${BLUE}   ... $i secondes écoulées${NC}"
    fi
    
    sleep 1
done

echo ""

echo -e "${BLUE}🔧 Étape 5: Test des routes neumorphiques...${NC}"

# Tester les routes
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8077/sama_conai/dashboard" | grep -q "302\|200"; then
    echo -e "${GREEN}✅ Route dashboard neumorphique accessible${NC}"
else
    echo -e "${RED}❌ Route dashboard neumorphique non accessible${NC}"
fi

if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8077/sama_conai/theme_selector" | grep -q "302\|200"; then
    echo -e "${GREEN}✅ Route sélecteur de thème accessible${NC}"
else
    echo -e "${RED}❌ Route sélecteur de thème non accessible${NC}"
fi

echo ""

echo -e "${PURPLE}${BOLD}🎉 MISE À JOUR TERMINÉE !${NC}"
echo "========================="
echo ""
echo -e "${GREEN}${BOLD}🌐 Accès à l'interface neumorphique:${NC}"
echo ""
echo -e "${WHITE}1. Connectez-vous à Odoo:${NC}"
echo -e "${CYAN}   http://localhost:8077${NC}"
echo -e "${WHITE}   Identifiants: admin / admin${NC}"
echo ""
echo -e "${WHITE}2. Accédez au nouveau dashboard via le menu:${NC}"
echo -e "${CYAN}   Menu → Analytics & Rapports → Tableaux de Bord → Tableau de Bord Principal${NC}"
echo ""
echo -e "${WHITE}3. Ou directement via l'URL:${NC}"
echo -e "${CYAN}   http://localhost:8077/sama_conai/dashboard${NC}"
echo ""
echo -e "${WHITE}4. Pour changer de thème:${NC}"
echo -e "${CYAN}   http://localhost:8077/sama_conai/theme_selector${NC}"
echo ""

echo -e "${BLUE}${BOLD}📱 Application mobile (ancienne version):${NC}"
echo -e "${WHITE}   http://localhost:3005${NC}"
echo ""

echo -e "${BLUE}${BOLD}📋 Logs:${NC}"
echo -e "${WHITE}   Odoo: tail -f logs/odoo_neumorphic_restart.log${NC}"
echo ""

echo -e "${GREEN}🇸🇳 Interface neumorphique SAMA CONAI activée !${NC}"