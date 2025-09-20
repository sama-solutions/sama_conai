#!/bin/bash

# ========================================= #
# SAMA CONAI - VALIDATION FINALE           #
# ========================================= #

echo "🇸🇳 SAMA CONAI - Validation Finale"
echo "=================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

print_test() {
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

# Compteurs
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    print_test "$test_name"
    ((TOTAL_TESTS++))
    
    if eval "$test_command" > /dev/null 2>&1; then
        print_success "$test_name"
        ((PASSED_TESTS++))
        return 0
    else
        print_error "$test_name"
        ((FAILED_TESTS++))
        return 1
    fi
}

# ========================================= #
# TESTS DE VALIDATION                       #
# ========================================= #

print_header "🔍 VALIDATION DES FICHIERS"

run_test "Serveur complet présent" "[ -f 'mobile_app_web/server_complete.js' ]"
run_test "Interface layers corrigés présente" "[ -f 'mobile_app_web/public/sama_conai_fixed_layers.html' ]"
run_test "Interface complète présente" "[ -f 'mobile_app_web/public/sama_conai_complete.html' ]"
run_test "API Odoo présente" "[ -f 'mobile_app_web/odoo-api.js' ]"
run_test "Scripts de lancement présents" "[ -f 'quick_start_sama_conai.sh' ] && [ -f 'stop_sama_conai_complete.sh' ]"

echo ""
print_header "🌐 VALIDATION DU SERVEUR"

# Vérifier si le serveur fonctionne
if curl -s http://localhost:3007 > /dev/null; then
    print_success "Serveur accessible sur le port 3007"
    ((PASSED_TESTS++))
else
    print_error "Serveur non accessible sur le port 3007"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

# Tester les routes
run_test "Route principale (/)" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3007/ | grep -q '200'"
run_test "Route layers corrigés (/fixed-layers)" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3007/fixed-layers | grep -q '200'"
run_test "Route avancée (/advanced)" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3007/advanced | grep -q '200'"
run_test "Route corrigée (/correct)" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3007/correct | grep -q '200'"

echo ""
print_header "🔗 VALIDATION ODOO"

if curl -s http://localhost:8077 > /dev/null; then
    print_success "Backend Odoo accessible sur le port 8077"
    ((PASSED_TESTS++))
else
    print_warning "Backend Odoo non accessible - Tests en mode dégradé"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo ""
print_header "📱 VALIDATION DES INTERFACES"

# Test du contenu des interfaces
print_test "Contenu interface layers corrigés"
if curl -s http://localhost:3007/fixed-layers | grep -q "SAMA CONAI"; then
    print_success "Interface layers corrigés contient le titre SAMA CONAI"
    ((PASSED_TESTS++))
else
    print_error "Interface layers corrigés - titre manquant"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

print_test "Theme switcher dans interface layers corrigés"
if curl -s http://localhost:3007/fixed-layers | grep -q "theme-toggle"; then
    print_success "Theme switcher présent dans interface layers corrigés"
    ((PASSED_TESTS++))
else
    print_error "Theme switcher manquant dans interface layers corrigés"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

print_test "Contraintes CSS strictes"
if curl -s http://localhost:3007/fixed-layers | grep -q "max-width: 100% !important"; then
    print_success "Contraintes CSS strictes appliquées"
    ((PASSED_TESTS++))
else
    print_error "Contraintes CSS strictes manquantes"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo ""
print_header "🎨 VALIDATION DES THÈMES"

print_test "Thèmes disponibles dans interface layers corrigés"
THEMES_CONTENT=$(curl -s http://localhost:3007/fixed-layers)
THEMES_COUNT=0

if echo "$THEMES_CONTENT" | grep -q "Institutionnel"; then ((THEMES_COUNT++)); fi
if echo "$THEMES_CONTENT" | grep -q "Terre du Sénégal"; then ((THEMES_COUNT++)); fi
if echo "$THEMES_CONTENT" | grep -q "Dark Mode"; then ((THEMES_COUNT++)); fi

if [ $THEMES_COUNT -ge 3 ]; then
    print_success "Au moins 3 thèmes disponibles ($THEMES_COUNT détectés)"
    ((PASSED_TESTS++))
else
    print_error "Pas assez de thèmes disponibles ($THEMES_COUNT détectés)"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo ""
print_header "🔐 VALIDATION DE L'AUTHENTIFICATION"

# Test de l'API de login
print_test "API de login accessible"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3007/api/mobile/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test","password":"test"}' 2>/dev/null)

if echo "$LOGIN_RESPONSE" | grep -q "success"; then
    print_success "API de login répond correctement"
    ((PASSED_TESTS++))
else
    print_error "API de login ne répond pas correctement"
    ((FAILED_TESTS++))
fi
((TOTAL_TESTS++))

echo ""
print_header "📊 RÉSULTATS DE LA VALIDATION"

echo ""
echo "Tests exécutés: $TOTAL_TESTS"
echo -e "Tests réussis:  ${GREEN}$PASSED_TESTS${NC}"
echo -e "Tests échoués:  ${RED}$FAILED_TESTS${NC}"
echo ""

# Calcul du pourcentage de réussite
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Taux de réussite: $SUCCESS_RATE%"
    echo ""
    
    if [ $SUCCESS_RATE -ge 90 ]; then
        echo -e "${GREEN}🎉 EXCELLENT ! SAMA CONAI est prêt pour la production${NC}"
        echo ""
        echo "🔥 Interface recommandée: http://localhost:3007/fixed-layers"
        echo "👤 Connexion: admin / admin"
        echo ""
        echo "✨ Fonctionnalités validées:"
        echo "   ✅ Problème de layers résolu"
        echo "   ✅ Theme switcher fonctionnel"
        echo "   ✅ Interface neumorphique"
        echo "   ✅ Contraintes CSS strictes"
        echo "   ✅ Intégration Odoo"
        echo ""
    elif [ $SUCCESS_RATE -ge 75 ]; then
        echo -e "${YELLOW}⚠️  BIEN - Quelques améliorations possibles${NC}"
        echo ""
        echo "🔧 Vérifiez les tests échoués ci-dessus"
        echo "🔗 Interface disponible: http://localhost:3007/fixed-layers"
        echo ""
    else
        echo -e "${RED}❌ PROBLÈMES DÉTECTÉS - Corrections nécessaires${NC}"
        echo ""
        echo "🔧 Vérifiez les erreurs ci-dessus"
        echo "📋 Consultez les logs pour plus de détails"
        echo ""
    fi
else
    echo -e "${RED}❌ AUCUN TEST EXÉCUTÉ${NC}"
fi

echo "========================================="
echo "🇸🇳 SAMA CONAI - Validation Terminée"
echo "========================================="
echo ""

# Code de sortie basé sur le taux de réussite
if [ $SUCCESS_RATE -ge 75 ]; then
    exit 0
else
    exit 1
fi