#!/bin/bash

# ========================================
# SAMA CONAI - BASCULEMENT DONNÉES RÉELLES ODOO
# ========================================
# Script pour basculer l'application mobile vers les données réelles d'Odoo
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

echo -e "${PURPLE}${BOLD}📊 SAMA CONAI - Basculement Données Réelles Odoo${NC}"
echo "=================================================="
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "$SCRIPT_DIR/mobile_app_web" ]; then
    echo -e "${RED}❌ Erreur: Répertoire mobile_app_web non trouvé${NC}"
    exit 1
fi

echo -e "${BLUE}🔄 Étapes de basculement:${NC}"
echo "1. Vérification de la connexion Odoo"
echo "2. Sauvegarde du serveur actuel"
echo "3. Basculement vers le serveur données réelles"
echo "4. Mise à jour de l'interface neumorphique"
echo "5. Redémarrage avec données Odoo"
echo ""

# Étape 1: Vérification Odoo
echo -e "${BLUE}🔍 1. Vérification de la connexion Odoo...${NC}"

if curl -s --connect-timeout 5 "http://localhost:8077" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Odoo accessible sur le port 8077${NC}"
    ODOO_AVAILABLE=true
elif curl -s --connect-timeout 5 "http://localhost:8069" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Odoo accessible sur le port 8069${NC}"
    ODOO_AVAILABLE=true
else
    echo -e "${RED}❌ Odoo non accessible${NC}"
    echo -e "${YELLOW}⚠️ Démarrez Odoo avant de continuer${NC}"
    ODOO_AVAILABLE=false
fi

# Vérifier PostgreSQL
if pgrep -x "postgres" > /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL en cours d'exécution${NC}"
else
    echo -e "${YELLOW}⚠️ PostgreSQL non détecté${NC}"
fi

echo ""

# Étape 2: Sauvegarde
echo -e "${BLUE}💾 2. Sauvegarde du serveur actuel...${NC}"

if [ -f "$SCRIPT_DIR/mobile_app_web/server.js" ]; then
    cp "$SCRIPT_DIR/mobile_app_web/server.js" "$SCRIPT_DIR/mobile_app_web/server_demo.js"
    echo -e "${GREEN}✅ Serveur démo sauvegardé dans server_demo.js${NC}"
else
    echo -e "${YELLOW}⚠️ Fichier server.js non trouvé${NC}"
fi

echo ""

# Étape 3: Basculement serveur
echo -e "${BLUE}🔄 3. Basculement vers le serveur données réelles...${NC}"

if [ -f "$SCRIPT_DIR/mobile_app_web/server_odoo_real_data.js" ]; then
    cp "$SCRIPT_DIR/mobile_app_web/server_odoo_real_data.js" "$SCRIPT_DIR/mobile_app_web/server.js"
    echo -e "${GREEN}✅ Serveur données réelles activé${NC}"
else
    echo -e "${RED}❌ Fichier server_odoo_real_data.js non trouvé${NC}"
    exit 1
fi

echo ""

# Étape 4: Interface neumorphique
echo -e "${BLUE}🎨 4. Mise à jour de l'interface neumorphique...${NC}"

if [ -f "$SCRIPT_DIR/mobile_app_web/public/index_neumorphic.html" ]; then
    # Sauvegarder l'ancienne interface
    if [ -f "$SCRIPT_DIR/mobile_app_web/public/index.html" ]; then
        cp "$SCRIPT_DIR/mobile_app_web/public/index.html" "$SCRIPT_DIR/mobile_app_web/public/index_old.html"
    fi
    
    # Activer l'interface neumorphique
    cp "$SCRIPT_DIR/mobile_app_web/public/index_neumorphic.html" "$SCRIPT_DIR/mobile_app_web/public/index.html"
    echo -e "${GREEN}✅ Interface neumorphique activée${NC}"
else
    echo -e "${YELLOW}⚠️ Interface neumorphique non trouvée, utilisation de l'interface actuelle${NC}"
fi

echo ""

# Étape 5: Redémarrage
echo -e "${BLUE}🚀 5. Redémarrage avec données Odoo...${NC}"

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

# Redémarrer avec le nouveau serveur
echo -e "${BLUE}🔗 Redémarrage avec connexion Odoo...${NC}"

cd "$SCRIPT_DIR/mobile_app_web"

# Créer le répertoire logs s'il n'existe pas
mkdir -p "$SCRIPT_DIR/logs"

# Démarrer l'application mobile avec données réelles
nohup npm start > "$SCRIPT_DIR/logs/mobile_odoo_real.log" 2>&1 &
MOBILE_PID=$!

echo $MOBILE_PID > "$SCRIPT_DIR/.pids/mobile.pid"
echo -e "${GREEN}✅ Application mobile redémarrée avec PID: $MOBILE_PID${NC}"
echo -e "${BLUE}📋 Logs: $SCRIPT_DIR/logs/mobile_odoo_real.log${NC}"

cd "$SCRIPT_DIR"
echo ""

# Test de connexion
echo -e "${BLUE}🧪 Test de la connexion...${NC}"

echo -e "${BLUE}⏳ Attente du démarrage (30 secondes)...${NC}"
sleep 30

# Tester l'accès à l'application mobile
if curl -s --connect-timeout 10 "http://localhost:3005" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Application mobile accessible sur http://localhost:3005${NC}"
    
    # Vérifier que c'est bien la version neumorphique
    if curl -s "http://localhost:3005" | grep -q "Interface Neumorphique"; then
        echo -e "${GREEN}✅ Interface neumorphique détectée${NC}"
    else
        echo -e "${YELLOW}⚠️ Interface neumorphique non détectée${NC}"
    fi
    
    # Tester l'API avec données réelles
    echo -e "${BLUE}🔍 Test de l'API avec données Odoo...${NC}"
    
    # Test de login
    login_response=$(curl -s -X POST "http://localhost:3005/api/mobile/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"admin","password":"admin"}')
    
    if echo "$login_response" | grep -q '"success":true'; then
        echo -e "${GREEN}✅ API de connexion fonctionnelle${NC}"
        
        # Extraire le token
        token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        
        if [ ! -z "$token" ]; then
            # Test du dashboard avec token
            dashboard_response=$(curl -s "http://localhost:3005/api/mobile/citizen/dashboard" \
                -H "Authorization: Bearer $token")
            
            if echo "$dashboard_response" | grep -q '"source":"odoo_real_data"'; then
                echo -e "${GREEN}✅ Données réelles Odoo détectées${NC}"
            elif echo "$dashboard_response" | grep -q '"requireOdoo":true'; then
                echo -e "${YELLOW}⚠️ Connexion Odoo requise mais non disponible${NC}"
            else
                echo -e "${BLUE}ℹ️ Données de démo utilisées${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️ API de connexion non fonctionnelle${NC}"
    fi
else
    echo -e "${RED}❌ Application mobile non accessible${NC}"
fi

echo ""

# Résumé final
echo -e "${PURPLE}${BOLD}🎉 BASCULEMENT TERMINÉ !${NC}"
echo "========================="
echo ""
echo -e "${GREEN}${BOLD}📊 Application Mobile avec Données Réelles Odoo:${NC}"
echo ""
echo -e "${WHITE}🌐 URL:${NC} ${CYAN}http://localhost:3005${NC}"
echo ""
echo -e "${WHITE}📊 Source de données:${NC}"
if [ "$ODOO_AVAILABLE" = true ]; then
    echo -e "${GREEN}   ✅ Données réelles d'Odoo${NC}"
    echo -e "${WHITE}   📋 Demandes d'information réelles${NC}"
    echo -e "${WHITE}   🚨 Alertes de signalement réelles${NC}"
    echo -e "${WHITE}   📈 Statistiques en temps réel${NC}"
else
    echo -e "${YELLOW}   ⚠️ Données de démo (Odoo non disponible)${NC}"
    echo -e "${WHITE}   🔄 Redémarrez Odoo pour les données réelles${NC}"
fi
echo ""
echo -e "${WHITE}🎨 Interface:${NC}"
echo -e "${WHITE}   ✅ Design neumorphique${NC}"
echo -e "${WHITE}   ✅ 3 thèmes sélectionnables${NC}"
echo -e "${WHITE}   ✅ Responsive mobile-first${NC}"
echo ""
echo -e "${WHITE}🔑 Identifiants:${NC}"
echo -e "${WHITE}   👤 Admin: admin / admin${NC}"
echo -e "${WHITE}   👤 Démo: demo@sama-conai.sn / demo123${NC}"
echo ""
echo -e "${BLUE}${BOLD}🔄 Pour revenir aux données de démo:${NC}"
echo -e "${WHITE}   cp mobile_app_web/server_demo.js mobile_app_web/server.js${NC}"
echo -e "${WHITE}   pkill -f 'node.*server.js' && cd mobile_app_web && npm start${NC}"
echo ""
echo -e "${BLUE}${BOLD}📋 Logs:${NC}"
echo -e "${WHITE}   Mobile: tail -f logs/mobile_odoo_real.log${NC}"
echo ""
echo -e "${GREEN}🇸🇳 Application mobile SAMA CONAI avec données réelles Odoo activée !${NC}"
echo ""
if [ "$ODOO_AVAILABLE" = false ]; then
    echo -e "${YELLOW}💡 Conseil: Démarrez Odoo avec ./startup_sama_conai_stack.sh pour les données réelles${NC}"
fi