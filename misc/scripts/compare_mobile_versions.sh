#!/bin/bash

# ========================================
# SAMA CONAI - COMPARAISON VERSIONS MOBILE
# ========================================
# Script pour comparer les versions mobile (ancienne vs neumorphique)
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

echo -e "${PURPLE}${BOLD}📊 SAMA CONAI - Comparaison Versions Mobile${NC}"
echo "============================================="
echo ""

# Vérifier les fichiers
echo -e "${BLUE}🔍 Vérification des fichiers...${NC}"

if [ -f "$SCRIPT_DIR/mobile_app_web/public/index.html" ]; then
    echo -e "${GREEN}✅ Version actuelle: index.html${NC}"
    CURRENT_SIZE=$(wc -c < "$SCRIPT_DIR/mobile_app_web/public/index.html")
    echo -e "${WHITE}   Taille: $CURRENT_SIZE octets${NC}"
    
    # Détecter la version
    if grep -q "Interface Neumorphique" "$SCRIPT_DIR/mobile_app_web/public/index.html"; then
        echo -e "${GREEN}   Type: Interface Neumorphique${NC}"
        CURRENT_TYPE="neumorphic"
    else
        echo -e "${BLUE}   Type: Interface Classique${NC}"
        CURRENT_TYPE="classic"
    fi
else
    echo -e "${RED}❌ Version actuelle non trouvée${NC}"
fi

if [ -f "$SCRIPT_DIR/mobile_app_web/public/index_old.html" ]; then
    echo -e "${GREEN}✅ Version sauvegardée: index_old.html${NC}"
    OLD_SIZE=$(wc -c < "$SCRIPT_DIR/mobile_app_web/public/index_old.html")
    echo -e "${WHITE}   Taille: $OLD_SIZE octets${NC}"
    
    # Détecter la version
    if grep -q "Interface Neumorphique" "$SCRIPT_DIR/mobile_app_web/public/index_old.html"; then
        echo -e "${GREEN}   Type: Interface Neumorphique${NC}"
        OLD_TYPE="neumorphic"
    else
        echo -e "${BLUE}   Type: Interface Classique${NC}"
        OLD_TYPE="classic"
    fi
else
    echo -e "${YELLOW}⚠️ Version sauvegardée non trouvée${NC}"
fi

if [ -f "$SCRIPT_DIR/mobile_app_web/public/index_neumorphic.html" ]; then
    echo -e "${GREEN}✅ Version neumorphique: index_neumorphic.html${NC}"
    NEURO_SIZE=$(wc -c < "$SCRIPT_DIR/mobile_app_web/public/index_neumorphic.html")
    echo -e "${WHITE}   Taille: $NEURO_SIZE octets${NC}"
    echo -e "${GREEN}   Type: Interface Neumorphique${NC}"
else
    echo -e "${RED}❌ Version neumorphique non trouvée${NC}"
fi

echo ""

# Comparaison des fonctionnalités
echo -e "${BLUE}📋 Comparaison des fonctionnalités...${NC}"
echo ""

echo -e "${BOLD}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}│                    COMPARAISON DES VERSIONS                 │${NC}"
echo -e "${BOLD}├─────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BOLD}│ Fonctionnalité              │ Classique │ Neumorphique     │${NC}"
echo -e "${BOLD}├─────────────────────────────────────────────────────────────┤${NC}"
echo -e "${WHITE}│ Design moderne               │    ✅     │       ✅         │${NC}"
echo -e "${WHITE}│ Effets neumorphiques         │    ❌     │       ✅         │${NC}"
echo -e "${WHITE}│ Sélecteur de thème           │    ❌     │       ✅         │${NC}"
echo -e "${WHITE}│ 3 thèmes disponibles         │    ❌     │       ✅         │${NC}"
echo -e "${WHITE}│ Animations fluides           │    ⚠️     │       ✅         │${NC}"
echo -e "${WHITE}│ Responsive mobile            │    ✅     │       ✅         │${NC}"
echo -e "${WHITE}│ Authentification             │    ✅     │       ✅         │${NC}"
echo -e "${WHITE}│ Dashboard interactif         │    ✅     │       ✅         │${NC}"
echo -e "${WHITE}│ Navigation par niveaux       │    ✅     │       ✅         │${NC}"
echo -e "${WHITE}│ Gestion des demandes         │    ✅     │       ✅         │${NC}"
echo -e "${WHITE}│ Polices Google Fonts         │    ❌     │       ✅         │${NC}"
echo -e "${WHITE}│ Icônes Font Awesome          │    ❌     │       ✅         │${NC}"
echo -e "${WHITE}│ Variables CSS                │    ❌     │       ✅         │${NC}"
echo -e "${WHITE}│ Persistance des thèmes       │    ❌     │       ✅         │${NC}"
echo -e "${BOLD}└─────────────────────────────────────────────────────────────┘${NC}"

echo ""

# Détails des thèmes
echo -e "${BLUE}🎨 Thèmes disponibles (Version Neumorphique):${NC}"
echo ""
echo -e "${WHITE}1. ${BOLD}Thème Institutionnel${NC} (par défaut)"
echo -e "${WHITE}   • Couleurs: Bleu institutionnel, orange, rouge${NC}"
echo -e "${WHITE}   • Style: Professionnel et officiel${NC}"
echo ""
echo -e "${WHITE}2. ${BOLD}Thème Terre du Sénégal${NC}"
echo -e "${WHITE}   • Couleurs: Marron, beige, terre de Sienne${NC}"
echo -e "${WHITE}   • Style: Inspiré des couleurs chaudes du Sénégal${NC}"
echo ""
echo -e "${WHITE}3. ${BOLD}Thème Moderne${NC}"
echo -e "${WHITE}   • Couleurs: Violet, jaune, orange moderne${NC}"
echo -e "${WHITE}   • Style: Design contemporain et élégant${NC}"

echo ""

# Statut actuel
echo -e "${BLUE}📱 Statut actuel de l'application mobile...${NC}"

if pgrep -f "node.*server.js" > /dev/null; then
    MOBILE_PID=$(pgrep -f "node.*server.js")
    echo -e "${GREEN}✅ Application mobile en cours d'exécution (PID: $MOBILE_PID)${NC}"
    
    # Tester l'accès
    if curl -s --connect-timeout 5 "http://localhost:3005" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Accessible sur http://localhost:3005${NC}"
        
        # Détecter la version en cours
        if curl -s "http://localhost:3005" | grep -q "Interface Neumorphique"; then
            echo -e "${GREEN}✅ Version neumorphique active${NC}"
        else
            echo -e "${BLUE}ℹ️ Version classique active${NC}"
        fi
    else
        echo -e "${RED}❌ Non accessible${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Application mobile non en cours d'exécution${NC}"
fi

echo ""

# Actions disponibles
echo -e "${PURPLE}${BOLD}🔧 Actions disponibles:${NC}"
echo ""

if [ "$CURRENT_TYPE" = "neumorphic" ]; then
    echo -e "${BLUE}Version neumorphique actuellement active${NC}"
    echo ""
    echo -e "${WHITE}Pour revenir à la version classique:${NC}"
    echo -e "${YELLOW}   ./switch_to_classic_mobile.sh${NC}"
    echo ""
    echo -e "${WHITE}Pour redémarrer la version neumorphique:${NC}"
    echo -e "${YELLOW}   pkill -f 'node.*server.js' && cd mobile_app_web && npm start${NC}"
else
    echo -e "${BLUE}Version classique actuellement active${NC}"
    echo ""
    echo -e "${WHITE}Pour basculer vers la version neumorphique:${NC}"
    echo -e "${YELLOW}   ./update_mobile_to_neumorphic.sh${NC}"
    echo ""
    echo -e "${WHITE}Pour redémarrer la version classique:${NC}"
    echo -e "${YELLOW}   pkill -f 'node.*server.js' && cd mobile_app_web && npm start${NC}"
fi

echo ""
echo -e "${GREEN}🇸🇳 SAMA CONAI - Comparaison terminée !${NC}"