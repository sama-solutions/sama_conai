#!/bin/bash

# ========================================
# SAMA CONAI - MISE À JOUR MOBILE NEUMORPHIQUE
# ========================================
# Script pour basculer l'application mobile vers l'interface neumorphique
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

echo -e "${PURPLE}${BOLD}📱 SAMA CONAI - Mise à Jour Mobile Neumorphique${NC}"
echo "================================================="
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "$SCRIPT_DIR/mobile_app_web" ]; then
    echo -e "${RED}❌ Erreur: Répertoire mobile_app_web non trouvé${NC}"
    exit 1
fi

echo -e "${BLUE}🔄 Étapes de mise à jour:${NC}"
echo "1. Sauvegarde de l'ancienne version"
echo "2. Basculement vers l'interface neumorphique"
echo "3. Redémarrage de l'application mobile"
echo "4. Test de la nouvelle interface"
echo ""

# Étape 1: Sauvegarde
echo -e "${BLUE}💾 1. Sauvegarde de l'ancienne version...${NC}"

if [ -f "$SCRIPT_DIR/mobile_app_web/public/index.html" ]; then
    cp "$SCRIPT_DIR/mobile_app_web/public/index.html" "$SCRIPT_DIR/mobile_app_web/public/index_old.html"
    echo -e "${GREEN}✅ Ancienne version sauvegardée dans index_old.html${NC}"
else
    echo -e "${YELLOW}⚠️ Fichier index.html non trouvé${NC}"
fi

echo ""

# Étape 2: Basculement
echo -e "${BLUE}🎨 2. Basculement vers l'interface neumorphique...${NC}"

if [ -f "$SCRIPT_DIR/mobile_app_web/public/index_neumorphic.html" ]; then
    cp "$SCRIPT_DIR/mobile_app_web/public/index_neumorphic.html" "$SCRIPT_DIR/mobile_app_web/public/index.html"
    echo -e "${GREEN}✅ Interface neumorphique activée${NC}"
else
    echo -e "${RED}❌ Fichier index_neumorphic.html non trouvé${NC}"
    exit 1
fi

echo ""

# Étape 3: Redémarrage
echo -e "${BLUE}🔄 3. Redémarrage de l'application mobile...${NC}"

# Arrêter l'application mobile
echo -e "${YELLOW}🛑 Arrêt de l'application mobile...${NC}"
pkill -f "node.*server.js" || true
pkill -f "npm.*start" || true
sleep 3

# Vérifier que l'application est arrêtée
if pgrep -f "node.*server.js" > /dev/null; then
    echo -e "${YELLOW}⚠️ Forçage de l'arrêt...${NC}"
    pkill -9 -f "node.*server.js" || true
    sleep 2
fi

echo -e "${GREEN}✅ Application mobile arrêtée${NC}"

# Redémarrer l'application mobile
echo -e "${BLUE}🚀 Redémarrage avec l'interface neumorphique...${NC}"

cd "$SCRIPT_DIR/mobile_app_web"

# Créer le répertoire logs s'il n'existe pas
mkdir -p "$SCRIPT_DIR/logs"

# Démarrer l'application mobile en arrière-plan
nohup npm start > "$SCRIPT_DIR/logs/mobile_neumorphic.log" 2>&1 &
MOBILE_PID=$!

echo $MOBILE_PID > "$SCRIPT_DIR/.pids/mobile.pid"
echo -e "${GREEN}✅ Application mobile redémarrée avec PID: $MOBILE_PID${NC}"
echo -e "${BLUE}📋 Logs: $SCRIPT_DIR/logs/mobile_neumorphic.log${NC}"

cd "$SCRIPT_DIR"
echo ""

# Étape 4: Test
echo -e "${BLUE}🧪 4. Test de la nouvelle interface...${NC}"

echo -e "${BLUE}⏳ Attente du démarrage (30 secondes)...${NC}"
sleep 30

# Tester l'accès à l'application mobile
if curl -s --connect-timeout 10 "http://localhost:3005" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Application mobile accessible sur http://localhost:3005${NC}"
    
    # Vérifier que c'est bien la version neumorphique
    if curl -s "http://localhost:3005" | grep -q "Interface Neumorphique"; then
        echo -e "${GREEN}✅ Interface neumorphique détectée${NC}"
    else
        echo -e "${YELLOW}⚠️ Interface neumorphique non détectée (cache navigateur?)${NC}"
    fi
else
    echo -e "${RED}❌ Application mobile non accessible${NC}"
fi

echo ""

# Résumé final
echo -e "${PURPLE}${BOLD}🎉 MISE À JOUR TERMINÉE !${NC}"
echo "========================="
echo ""
echo -e "${GREEN}${BOLD}📱 Nouvelle Interface Mobile Neumorphique:${NC}"
echo ""
echo -e "${WHITE}🌐 URL:${NC} ${CYAN}http://localhost:3005${NC}"
echo ""
echo -e "${WHITE}🎨 Fonctionnalités neumorphiques:${NC}"
echo -e "${WHITE}   ✅ Design neumorphique complet${NC}"
echo -e "${WHITE}   ✅ 3 thèmes sélectionnables (Institutionnel, Terre, Moderne)${NC}"
echo -e "${WHITE}   ✅ Animations fluides et transitions${NC}"
echo -e "${WHITE}   ✅ Interface mobile-first optimisée${NC}"
echo -e "${WHITE}   ✅ Sélecteur de thème en temps réel${NC}"
echo ""
echo -e "${WHITE}🔑 Identifiants:${NC}"
echo -e "${WHITE}   👤 Admin: admin / admin${NC}"
echo -e "${WHITE}   👤 Démo: demo@sama-conai.sn / demo123${NC}"
echo ""
echo -e "${BLUE}${BOLD}🔄 Pour revenir à l'ancienne version:${NC}"
echo -e "${WHITE}   cp mobile_app_web/public/index_old.html mobile_app_web/public/index.html${NC}"
echo -e "${WHITE}   pkill -f 'node.*server.js' && cd mobile_app_web && npm start${NC}"
echo ""
echo -e "${BLUE}${BOLD}📋 Logs:${NC}"
echo -e "${WHITE}   Mobile: tail -f logs/mobile_neumorphic.log${NC}"
echo ""
echo -e "${GREEN}🇸🇳 Interface mobile neumorphique SAMA CONAI activée !${NC}"
echo ""
echo -e "${YELLOW}💡 Conseil: Videz le cache de votre navigateur (Ctrl+F5) pour voir les changements${NC}"