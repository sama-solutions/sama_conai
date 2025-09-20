#!/bin/bash

# ========================================= #
# SAMA CONAI - DÉMARRAGE RAPIDE            #
# ========================================= #

clear
echo "🇸🇳 SAMA CONAI - Démarrage Rapide"
echo "================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Étape 1: Vérification rapide
print_step "Vérification des prérequis..."

if [ ! -f "mobile_app_web/server_complete.js" ]; then
    print_error "Fichier server_complete.js manquant"
    exit 1
fi

if [ ! -f "mobile_app_web/public/sama_conai_complete.html" ]; then
    print_error "Fichier sama_conai_complete.html manquant"
    exit 1
fi

print_success "Fichiers présents"

# Étape 2: Vérification Odoo
print_step "Vérification de la connexion Odoo..."

if curl -s --connect-timeout 3 http://localhost:8077 > /dev/null; then
    print_success "Odoo accessible sur le port 8077"
else
    print_warning "Odoo non accessible - L'interface fonctionnera en mode dégradé"
fi

# Étape 3: Arrêt des processus existants
print_step "Nettoyage des processus existants..."

pkill -f "server_complete.js" 2>/dev/null || true
lsof -ti:3007 | xargs kill -9 2>/dev/null || true
sleep 1

print_success "Processus nettoyés"

# Étape 4: Démarrage du serveur
print_step "Démarrage du serveur SAMA CONAI..."

cd mobile_app_web

# Créer les répertoires de logs si nécessaire
mkdir -p ../logs ../pids

# Démarrer le serveur
nohup node server_complete.js > ../logs/sama_conai_$(date +%Y%m%d_%H%M%S).log 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > ../pids/sama_conai_complete.pid

cd ..

# Attendre le démarrage
sleep 3

# Vérifier que le serveur fonctionne
if ps -p $SERVER_PID > /dev/null; then
    print_success "Serveur démarré (PID: $SERVER_PID)"
else
    print_error "Échec du démarrage du serveur"
    exit 1
fi

# Étape 5: Test de connectivité
print_step "Test de connectivité..."

sleep 2

if curl -s http://localhost:3007 > /dev/null; then
    print_success "Interface accessible"
else
    print_error "Interface non accessible"
    exit 1
fi

# Affichage final
echo ""
echo "🎉 SAMA CONAI Interface Complète Lancée !"
echo "========================================"
echo ""
echo "📱 Accès à l'interface :"
echo "   http://localhost:3007/"
echo ""
echo "🔧 Interfaces alternatives :"
echo "   http://localhost:3007/advanced"
echo "   http://localhost:3007/correct"
echo ""
echo "🔗 Backend Odoo :"
echo "   http://localhost:8077"
echo ""
echo "👤 Connexion :"
echo "   Utilisateur: admin"
echo "   Mot de passe: admin"
echo ""
echo "✨ Fonctionnalités :"
echo "   ✅ Navigation 3 niveaux"
echo "   ✅ Theme switcher (8 thèmes)"
echo "   ✅ Données réelles Odoo"
echo "   ✅ Mode admin global"
echo "   ✅ Intégration backend"
echo ""
echo "🛑 Pour arrêter :"
echo "   ./stop_sama_conai_complete.sh"
echo ""

# Optionnel: ouvrir le navigateur
if command -v xdg-open &> /dev/null; then
    print_step "Ouverture du navigateur..."
    xdg-open http://localhost:3007 &
elif command -v open &> /dev/null; then
    print_step "Ouverture du navigateur..."
    open http://localhost:3007 &
fi

print_success "SAMA CONAI est prêt à l'utilisation !"