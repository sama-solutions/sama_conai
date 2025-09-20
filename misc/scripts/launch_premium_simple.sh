#!/bin/bash

# Script de lancement simplifié SAMA CONAI Premium v4.0

echo "🚀 LANCEMENT SAMA CONAI PREMIUM v4.0 - VERSION SIMPLIFIÉE"
echo "=========================================================="

# Variables
APP_DIR="mobile_app_premium"
PORT=3002

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                    SAMA CONAI PREMIUM v4.0                   ║${NC}"
echo -e "${PURPLE}║              Transparence Gouvernementale Révolutionnaire    ║${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}║  🇸🇳 République du Sénégal - Innovation Numérique 2025      ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifications
echo -e "${BLUE}🔍 Vérifications...${NC}"

if [ ! -d "$APP_DIR" ]; then
    echo "❌ Répertoire $APP_DIR non trouvé"
    exit 1
fi

if [ ! -f "$APP_DIR/server_simple.js" ]; then
    echo "❌ Fichier server_simple.js non trouvé"
    exit 1
fi

echo -e "${GREEN}✅ Structure validée${NC}"

# Nettoyage
echo -e "${BLUE}🧹 Nettoyage des processus existants...${NC}"
pkill -f "node.*server" 2>/dev/null || true
sleep 1

# Démarrage
echo -e "${BLUE}🌐 Démarrage du serveur...${NC}"
cd "$APP_DIR"

# Démarrer en arrière-plan
nohup node server_simple.js > premium.log 2>&1 &
SERVER_PID=$!

# Attendre le démarrage
sleep 2

# Vérifier
if ps -p $SERVER_PID > /dev/null 2>&1; then
    echo $SERVER_PID > premium.pid
    
    echo ""
    echo -e "${GREEN}🎉 SAMA CONAI PREMIUM v4.0 LANCÉ AVEC SUCCÈS !${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo ""
    
    echo -e "${WHITE}🌐 URL d'accès: ${CYAN}http://localhost:$PORT${NC}"
    echo -e "${WHITE}📱 Interface: ${CYAN}Ultra-moderne avec glassmorphism${NC}"
    echo -e "${WHITE}🔐 Authentification: ${CYAN}Système sécurisé${NC}"
    echo -e "${WHITE}🎮 Gamification: ${CYAN}Niveaux, points, badges${NC}"
    echo -e "${WHITE}🤖 Assistant IA: ${CYAN}Conversationnel intégré${NC}"
    echo -e "${WHITE}🎨 Thèmes: ${CYAN}Clair/Sombre/Auto/Gouvernement${NC}"
    echo -e "${WHITE}👥 Rôles: ${CYAN}Admin/Agent/Citoyen${NC}"
    
    echo ""
    echo -e "${PURPLE}🔑 COMPTES DE DÉMONSTRATION:${NC}"
    echo -e "${WHITE}   👑 Admin:${NC} admin@sama-conai.sn / admin123"
    echo -e "${WHITE}   🛡️ Agent:${NC} agent@sama-conai.sn / agent123"
    echo -e "${WHITE}   👤 Citoyen:${NC} citoyen@email.com / citoyen123"
    
    echo ""
    echo -e "${PURPLE}🔧 GESTION:${NC}"
    echo -e "${WHITE}   📋 Logs:${NC} tail -f $APP_DIR/premium.log"
    echo -e "${WHITE}   🛑 Arrêt:${NC} kill $SERVER_PID"
    echo -e "${WHITE}   📊 PID:${NC} $SERVER_PID"
    
    echo ""
    echo -e "${CYAN}✨ FONCTIONNALITÉS RÉVOLUTIONNAIRES:${NC}"
    echo -e "${CYAN}   🔮 Design glassmorphism et neumorphism${NC}"
    echo -e "${CYAN}   ✨ Animations fluides et micro-interactions${NC}"
    echo -e "${CYAN}   🎯 Theme switcher avancé${NC}"
    echo -e "${CYAN}   🚀 Dashboards adaptatifs par rôle${NC}"
    echo -e "${CYAN}   🔔 Notifications intelligentes${NC}"
    echo -e "${CYAN}   🤖 Assistant IA conversationnel${NC}"
    echo -e "${CYAN}   🏆 Système de gamification complet${NC}"
    echo -e "${CYAN}   📱 Interface ultra-moderne${NC}"
    
    echo ""
    echo -e "${GREEN}💡 Ouvrez ${WHITE}http://localhost:$PORT${GREEN} dans votre navigateur${NC}"
    echo -e "${GREEN}🚀 Découvrez l'avenir de la transparence gouvernementale !${NC}"
    
    echo ""
    echo -e "${PURPLE}🎯 L'APPLICATION PREMIUM EST PRÊTE !${NC}"
    
else
    echo "❌ Échec du démarrage du serveur"
    echo "📋 Vérifiez les logs: cat $APP_DIR/premium.log"
    exit 1
fi

cd ..