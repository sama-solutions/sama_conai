#!/bin/bash

# ========================================= #
# SAMA CONAI - TESTS INTERFACE COMPLÈTE    #
# ========================================= #

echo "🧪 Tests de l'Interface SAMA CONAI Complète"
echo "==========================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteurs de tests
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Fonction pour afficher les messages colorés
print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    ((TESTS_TOTAL++))
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Test 1: Vérification des fichiers requis
print_test "Vérification des fichiers requis"

if [ -f "mobile_app_web/server_complete.js" ]; then
    print_pass "server_complete.js existe"
else
    print_fail "server_complete.js manquant"
fi

if [ -f "mobile_app_web/public/sama_conai_complete.html" ]; then
    print_pass "sama_conai_complete.html existe"
else
    print_fail "sama_conai_complete.html manquant"
fi

if [ -f "mobile_app_web/odoo-api.js" ]; then
    print_pass "odoo-api.js existe"
else
    print_fail "odoo-api.js manquant"
fi

if [ -f "launch_sama_conai_complete.sh" ]; then
    print_pass "Script de lancement existe"
else
    print_fail "Script de lancement manquant"
fi

# Test 2: Vérification des dépendances
print_test "Vérification des dépendances"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_pass "Node.js installé ($NODE_VERSION)"
else
    print_fail "Node.js non installé"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_pass "npm installé ($NPM_VERSION)"
else
    print_fail "npm non installé"
fi

if [ -d "mobile_app_web/node_modules" ]; then
    print_pass "Dépendances Node.js installées"
else
    print_fail "Dépendances Node.js manquantes"
fi

# Test 3: Vérification de la disponibilité des ports
print_test "Vérification des ports"

if lsof -i:3007 > /dev/null 2>&1; then
    print_info "Port 3007 occupé - tentative d'arrêt"
    ./stop_sama_conai_complete.sh > /dev/null 2>&1
    sleep 2
fi

if ! lsof -i:3007 > /dev/null 2>&1; then
    print_pass "Port 3007 disponible"
else
    print_fail "Port 3007 occupé"
fi

if curl -s http://localhost:8077 > /dev/null; then
    print_pass "Odoo accessible sur le port 8077"
else
    print_fail "Odoo non accessible sur le port 8077"
fi

# Test 4: Démarrage du serveur
print_test "Démarrage du serveur"

print_info "Lancement du serveur SAMA CONAI complet..."
cd mobile_app_web

# Démarrer le serveur en arrière-plan
nohup node server_complete.js > ../logs/test_$(date +%Y%m%d_%H%M%S).log 2>&1 &
SERVER_PID=$!

# Attendre que le serveur démarre
sleep 5

if ps -p $SERVER_PID > /dev/null; then
    print_pass "Serveur démarré (PID: $SERVER_PID)"
    echo $SERVER_PID > ../pids/test_server.pid
else
    print_fail "Échec du démarrage du serveur"
fi

cd ..

# Test 5: Connectivité HTTP
print_test "Tests de connectivité HTTP"

# Test de la page principale
if curl -s http://localhost:3007 > /dev/null; then
    print_pass "Page principale accessible"
else
    print_fail "Page principale inaccessible"
fi

# Test de l'interface avancée
if curl -s http://localhost:3007/advanced > /dev/null; then
    print_pass "Interface avancée accessible"
else
    print_fail "Interface avancée inaccessible"
fi

# Test de l'interface corrigée
if curl -s http://localhost:3007/correct > /dev/null; then
    print_pass "Interface corrigée accessible"
else
    print_fail "Interface corrigée inaccessible"
fi

# Test 6: API Endpoints
print_test "Tests des endpoints API"

# Test de l'endpoint de login (sans authentification)
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3007/api/mobile/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin","password":"admin"}')

if echo "$LOGIN_RESPONSE" | grep -q "success"; then
    print_pass "Endpoint de login répond"
    
    # Extraire le token si possible
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$TOKEN" ]; then
        print_pass "Token d'authentification reçu"
        
        # Test de l'endpoint dashboard avec token
        DASHBOARD_RESPONSE=$(curl -s http://localhost:3007/api/mobile/level1/dashboard \
            -H "Authorization: Bearer $TOKEN")
        
        if echo "$DASHBOARD_RESPONSE" | grep -q "success"; then
            print_pass "Endpoint dashboard répond avec authentification"
        else
            print_fail "Endpoint dashboard ne répond pas"
        fi
    else
        print_fail "Token d'authentification non reçu"
    fi
else
    print_fail "Endpoint de login ne répond pas"
fi

# Test 7: Validation du contenu HTML
print_test "Validation du contenu HTML"

HTML_CONTENT=$(curl -s http://localhost:3007)

if echo "$HTML_CONTENT" | grep -q "SAMA CONAI"; then
    print_pass "Titre SAMA CONAI présent"
else
    print_fail "Titre SAMA CONAI manquant"
fi

if echo "$HTML_CONTENT" | grep -q "theme-toggle"; then
    print_pass "Theme switcher présent"
else
    print_fail "Theme switcher manquant"
fi

if echo "$HTML_CONTENT" | grep -q "navigation"; then
    print_pass "Éléments de navigation présents"
else
    print_fail "Éléments de navigation manquants"
fi

# Test 8: Validation JavaScript
print_test "Validation JavaScript"

if echo "$HTML_CONTENT" | grep -q "toggleThemeMenu"; then
    print_pass "Fonction toggleThemeMenu présente"
else
    print_fail "Fonction toggleThemeMenu manquante"
fi

if echo "$HTML_CONTENT" | grep -q "loadLevel1Dashboard"; then
    print_pass "Fonction loadLevel1Dashboard présente"
else
    print_fail "Fonction loadLevel1Dashboard manquante"
fi

if echo "$HTML_CONTENT" | grep -q "navigateTo"; then
    print_pass "Fonction navigateTo présente"
else
    print_fail "Fonction navigateTo manquante"
fi

# Test 9: Validation CSS
print_test "Validation CSS"

if echo "$HTML_CONTENT" | grep -q "neumorphic"; then
    print_pass "Styles neumorphiques présents"
else
    print_fail "Styles neumorphiques manquants"
fi

if echo "$HTML_CONTENT" | grep -q "data-theme"; then
    print_pass "Support des thèmes présent"
else
    print_fail "Support des thèmes manquant"
fi

# Test 10: Nettoyage
print_test "Nettoyage des ressources de test"

if [ -f "pids/test_server.pid" ]; then
    TEST_PID=$(cat pids/test_server.pid)
    if ps -p $TEST_PID > /dev/null; then
        kill $TEST_PID
        print_pass "Serveur de test arrêté"
    fi
    rm -f pids/test_server.pid
fi

# Résumé des tests
echo ""
echo "========================================="
echo "📊 RÉSUMÉ DES TESTS"
echo "========================================="
echo ""
echo "Tests exécutés: $TESTS_TOTAL"
echo -e "Tests réussis:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests échoués:  ${RED}$TESTS_FAILED${NC}"
echo ""

# Calcul du pourcentage de réussite
if [ $TESTS_TOTAL -gt 0 ]; then
    SUCCESS_RATE=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    echo "Taux de réussite: $SUCCESS_RATE%"
    echo ""
    
    if [ $SUCCESS_RATE -ge 90 ]; then
        echo -e "${GREEN}🎉 EXCELLENT ! L'interface SAMA CONAI complète est prête${NC}"
    elif [ $SUCCESS_RATE -ge 75 ]; then
        echo -e "${YELLOW}⚠️  BIEN - Quelques améliorations possibles${NC}"
    else
        echo -e "${RED}❌ PROBLÈMES DÉTECTÉS - Vérifiez les erreurs${NC}"
    fi
else
    echo -e "${RED}❌ AUCUN TEST EXÉCUTÉ${NC}"
fi

echo ""
echo "📝 Logs détaillés disponibles dans le répertoire logs/"
echo "🚀 Pour lancer l'interface: ./launch_sama_conai_complete.sh"
echo "🛑 Pour arrêter l'interface: ./stop_sama_conai_complete.sh"
echo ""

# Code de sortie basé sur le taux de réussite
if [ $SUCCESS_RATE -ge 75 ]; then
    exit 0
else
    exit 1
fi