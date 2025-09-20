#!/bin/bash

# Script de lancement simple SAMA CONAI UX Révolutionnaire v6.0

echo "🎨 LANCEMENT SAMA CONAI UX RÉVOLUTIONNAIRE v6.0"
echo "==============================================="

# Variables
APP_DIR="mobile_app_ux_inspired"
PORT=3004

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
MAGENTA='\033[0;95m'
WHITE='\033[1;37m'
NC='\033[0m'

echo ""
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║              SAMA CONAI UX RÉVOLUTIONNAIRE v6.0              ║${NC}"
echo -e "${MAGENTA}║         Application Mobile avec Design Révolutionnaire       ║${NC}"
echo -e "${MAGENTA}║                                                              ║${NC}"
echo -e "${MAGENTA}║  🇸🇳 République du Sénégal - Innovation UX/UI 2025          ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js n'est pas installé${NC}"
    exit 1
fi

# Vérifier le répertoire
if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}❌ Répertoire $APP_DIR non trouvé${NC}"
    exit 1
fi

# Nettoyer les processus existants
echo -e "${BLUE}🧹 Nettoyage des processus existants...${NC}"
pkill -f "node.*server" 2>/dev/null || true
sleep 1

# Démarrer le serveur
echo -e "${PURPLE}🚀 Démarrage du serveur UX révolutionnaire...${NC}"
cd "$APP_DIR"

# Démarrer en arrière-plan
nohup node server_simple.js > ux_simple.log 2>&1 &
SERVER_PID=$!

# Sauvegarder le PID
echo $SERVER_PID > ux_simple.pid

# Attendre le démarrage
sleep 3

# Vérifier que le serveur fonctionne
if ps -p $SERVER_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Serveur démarré avec succès !${NC}"
    echo -e "${GREEN}📊 PID: $SERVER_PID${NC}"
    
    # Tester la connexion
    if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
        echo -e "${GREEN}🌐 Serveur accessible sur http://localhost:$PORT${NC}"
    else
        echo -e "${YELLOW}⚠️ Serveur démarré mais pas encore accessible${NC}"
    fi
else
    echo -e "${RED}❌ Échec du démarrage du serveur${NC}"
    echo "Vérifiez les logs: cat $APP_DIR/ux_simple.log"
    exit 1
fi

cd ..

echo ""
echo -e "${MAGENTA}🎨 SAMA CONAI UX RÉVOLUTIONNAIRE v6.0 LANCÉ !${NC}"
echo -e "${MAGENTA}=============================================${NC}"
echo ""
echo -e "${GREEN}🌐 URL d'accès: ${WHITE}http://localhost:$PORT${NC}"
echo -e "${GREEN}🎨 Design: ${WHITE}UX Inspiré des Meilleurs Designs${NC}"
echo -e "${GREEN}📱 Interface: ${WHITE}Mobile-First Révolutionnaire${NC}"
echo -e "${GREEN}✨ Animations: ${WHITE}Micro-interactions Fluides${NC}"
echo ""
echo -e "${PURPLE}🔑 COMPTES DE TEST:${NC}"
echo -e "${WHITE}   👑 Admin: admin@sama-conai.sn / admin123${NC}"
echo -e "${WHITE}   🛡️ Agent: agent@sama-conai.sn / agent123${NC}"
echo -e "${WHITE}   👤 Citoyen: citoyen@email.com / citoyen123${NC}"
echo ""
echo -e "${BLUE}🔧 GESTION:${NC}"
echo -e "${WHITE}   📋 Logs: tail -f $APP_DIR/ux_simple.log${NC}"
echo -e "${WHITE}   🛑 Arrêt: kill $SERVER_PID${NC}"
echo -e "${WHITE}   📊 Statut: ps -p $SERVER_PID${NC}"
echo ""
echo -e "${GREEN}🚀 PRÊT POUR UNE EXPÉRIENCE UX RÉVOLUTIONNAIRE !${NC}"
echo ""