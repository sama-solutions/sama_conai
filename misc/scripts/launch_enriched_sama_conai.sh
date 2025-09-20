#!/bin/bash

# ========================================= #
# SAMA CONAI - LANCEMENT INTERFACE ENRICHIE #
# ========================================= #

echo "🇸🇳 SAMA CONAI - Interface Enrichie"
echo "===================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}➤${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

# Vérification des prérequis
print_step "Vérification des prérequis..."

if [ ! -f "mobile_app_web/server_enriched.js" ]; then
    print_error "Serveur enrichi non trouvé"
    exit 1
fi

if [ ! -f "mobile_app_web/public/sama_conai_enriched.html" ]; then
    print_error "Interface enrichie non trouvée"
    exit 1
fi

print_success "Fichiers enrichis présents"

# Vérification de Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js n'est pas installé"
    exit 1
fi

print_success "Node.js disponible"

# Vérification des dépendances
print_step "Vérification des dépendances..."
cd mobile_app_web

if [ ! -d "node_modules" ]; then
    print_warning "Installation des dépendances..."
    npm install
fi

print_success "Dépendances vérifiées"

# Vérification de la connexion Odoo
print_step "Vérification de la connexion Odoo..."
if curl -s http://localhost:8077 > /dev/null; then
    print_success "Odoo accessible sur le port 8077"
else
    print_warning "Backend Odoo non accessible - Mode dégradé"
fi

# Nettoyage des processus existants
print_step "Nettoyage des processus existants..."
pkill -f "server_enriched.js" 2>/dev/null || true
pkill -f "server_complete.js" 2>/dev/null || true

# Libération du port 3007
if lsof -Pi :3007 -sTCP:LISTEN -t >/dev/null ; then
    print_warning "Port 3007 occupé, libération..."
    lsof -ti:3007 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

print_success "Processus nettoyés"

# Création des répertoires de logs
mkdir -p ../logs
mkdir -p ../pids

# Démarrage du serveur enrichi
print_step "Démarrage du serveur SAMA CONAI enrichi..."

# Lancement en arrière-plan avec logs
nohup node server_enriched.js > ../logs/sama_conai_enriched_$(date +%Y%m%d_%H%M%S).log 2>&1 &
SERVER_PID=$!

# Sauvegarder le PID
echo $SERVER_PID > ../pids/sama_conai_enriched.pid

# Attendre que le serveur démarre
sleep 3

# Vérifier que le serveur fonctionne
if kill -0 $SERVER_PID 2>/dev/null; then
    print_success "Serveur enrichi démarré (PID: $SERVER_PID)"
else
    print_error "Échec du démarrage du serveur"
    exit 1
fi

# Test de connectivité
print_step "Test de connectivité..."
sleep 2

if curl -s http://localhost:3007/enriched > /dev/null; then
    print_success "Interface enrichie accessible"
else
    print_error "Interface enrichie non accessible"
    exit 1
fi

echo ""
echo -e "${PURPLE}🎉 SAMA CONAI Interface Enrichie Lancée !${NC}"
echo "========================================"
echo ""

echo -e "${CYAN}📱 Accès à l'interface enrichie :${NC}"
echo "   http://localhost:3007/enriched"
echo ""

echo -e "${CYAN}🔧 Interfaces alternatives :${NC}"
echo "   http://localhost:3007/fixed-layers (Layers corrigés)"
echo "   http://localhost:3007/ (Complète)"
echo "   http://localhost:3007/advanced (Avancée)"
echo "   http://localhost:3007/correct (Corrigée)"
echo ""

echo -e "${CYAN}📊 APIs enrichies :${NC}"
echo "   http://localhost:3007/api/mobile/analytics"
echo "   http://localhost:3007/api/mobile/notifications"
echo ""

echo -e "${CYAN}🔗 Backend Odoo :${NC}"
echo "   http://localhost:8077"
echo ""

echo -e "${CYAN}👤 Connexion :${NC}"
echo "   Utilisateur: admin"
echo "   Mot de passe: admin"
echo ""

echo -e "${CYAN}✨ Fonctionnalités enrichies :${NC}"
echo "   ✅ Dashboard avec KPIs avancés"
echo "   ✅ Graphiques interactifs (Chart.js)"
echo "   ✅ Notifications en temps réel"
echo "   ✅ Analytics détaillés"
echo "   ✅ Interface neumorphique enrichie"
echo "   ✅ 4 thèmes disponibles"
echo "   ✅ Contraintes layers corrigées"
echo ""

echo -e "${CYAN}🛑 Pour arrêter :${NC}"
echo "   ./stop_enriched_sama_conai.sh"
echo ""

echo -e "${CYAN}📊 Logs en temps réel :${NC}"
echo "   tail -f logs/sama_conai_enriched_*.log"
echo ""

# Ouverture automatique du navigateur
print_step "Ouverture du navigateur..."
if command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:3007/enriched &
elif command -v open &> /dev/null; then
    open http://localhost:3007/enriched &
else
    print_info "Ouvrez manuellement : http://localhost:3007/enriched"
fi

print_success "SAMA CONAI Interface Enrichie est prêt à l'utilisation !"

echo ""
echo "========================================"
echo "🇸🇳 SAMA CONAI - Interface Enrichie Active"
echo "========================================"