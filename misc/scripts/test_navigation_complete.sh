#!/bin/bash

# ========================================= #
# SAMA CONAI - TEST NAVIGATION 3 NIVEAUX   #
# ========================================= #

echo "🇸🇳 SAMA CONAI - Test Navigation 3 Niveaux"
echo "==========================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}🧪 TEST:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ SUCCÈS:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️ ATTENTION:${NC} $1"
}

print_error() {
    echo -e "${RED}❌ ERREUR:${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ️ INFO:${NC} $1"
}

# Variables
BASE_URL="http://localhost:3007"
TOTAL_TESTS=0
PASSED_TESTS=0

# Fonction de test
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "$name"
    
    response=$(curl -s -w "%{http_code}" -o /dev/null "$url")
    
    if [ "$response" = "$expected_status" ]; then
        print_success "$name - Status: $response"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_error "$name - Status: $response (attendu: $expected_status)"
        return 1
    fi
}

# Fonction de test avec contenu
test_content() {
    local name="$1"
    local url="$2"
    local search_text="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "$name"
    
    response=$(curl -s "$url")
    
    if echo "$response" | grep -q "$search_text"; then
        print_success "$name - Contenu trouvé: '$search_text'"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_error "$name - Contenu manquant: '$search_text'"
        return 1
    fi
}

echo -e "${PURPLE}🚀 DÉBUT DES TESTS DE NAVIGATION${NC}"
echo ""

# ========================================= #
# TESTS INTERFACES PRINCIPALES             #
# ========================================= #

echo -e "${CYAN}📱 Tests des Interfaces Principales${NC}"
echo "-----------------------------------"

test_endpoint "Interface Enrichie" "$BASE_URL/enriched" "200"
test_endpoint "Interface Layers Corrigés" "$BASE_URL/fixed-layers" "200"
test_endpoint "Interface Complète" "$BASE_URL/" "200"
test_endpoint "Interface Avancée" "$BASE_URL/advanced" "200"

echo ""

# ========================================= #
# TESTS APIS NIVEAU 1                      #
# ========================================= #

echo -e "${CYAN}📊 Tests APIs Niveau 1 (Dashboard)${NC}"
echo "-----------------------------------"

test_endpoint "API Dashboard" "$BASE_URL/api/mobile/level1/dashboard" "200"
test_endpoint "API Analytics" "$BASE_URL/api/mobile/analytics" "200"
test_endpoint "API Notifications" "$BASE_URL/api/mobile/notifications" "200"

echo ""

# ========================================= #
# TESTS APIS NIVEAU 2                      #
# ========================================= #

echo -e "${CYAN}📋 Tests APIs Niveau 2 (Listes)${NC}"
echo "-------------------------------"

test_endpoint "API Demandes Niveau 2" "$BASE_URL/api/mobile/level2/requests" "200"
test_endpoint "API Alertes Niveau 2" "$BASE_URL/api/mobile/level2/alerts" "200"

# Test contenu niveau 2
test_content "Contenu Demandes Niveau 2" "$BASE_URL/api/mobile/level2/requests" "REQ-2024-001"
test_content "Contenu Alertes Niveau 2" "$BASE_URL/api/mobile/level2/alerts" "WB-2024-001"

echo ""

# ========================================= #
# TESTS APIS NIVEAU 3                      #
# ========================================= #

echo -e "${CYAN}🔍 Tests APIs Niveau 3 (Détails)${NC}"
echo "-------------------------------"

test_endpoint "API Détail Demande 1" "$BASE_URL/api/mobile/level3/request/1" "200"
test_endpoint "API Détail Demande 2" "$BASE_URL/api/mobile/level3/request/2" "200"
test_endpoint "API Détail Alerte 1" "$BASE_URL/api/mobile/level3/alert/1" "200"
test_endpoint "API Détail Alerte 2" "$BASE_URL/api/mobile/level3/alert/2" "200"

# Test contenu niveau 3
test_content "Contenu Détail Demande" "$BASE_URL/api/mobile/level3/request/1" "timeline"
test_content "Contenu Détail Alerte" "$BASE_URL/api/mobile/level3/alert/1" "timeline"

echo ""

# ========================================= #
# TESTS FONCTIONNALITÉS ENRICHIES          #
# ========================================= #

echo -e "${CYAN}✨ Tests Fonctionnalités Enrichies${NC}"
echo "--------------------------------"

# Test contenu interface enrichie
test_content "Interface Enrichie - KPIs" "$BASE_URL/enriched" "kpi-grid"
test_content "Interface Enrichie - Charts" "$BASE_URL/enriched" "chart.js"
test_content "Interface Enrichie - Thèmes" "$BASE_URL/enriched" "theme-selector"
test_content "Interface Enrichie - Navigation" "$BASE_URL/enriched" "navigateTo"

# Test données analytics
test_content "Analytics - Tendances" "$BASE_URL/api/mobile/analytics" "trends"
test_content "Analytics - Statistiques" "$BASE_URL/api/mobile/analytics" "global_stats"

echo ""

# ========================================= #
# TESTS DONNÉES RÉALISTES                  #
# ========================================= #

echo -e "${CYAN}📊 Tests Données Réalistes${NC}"
echo "----------------------------"

# Test données sénégalaises
test_content "Données Sénégalaises - Noms" "$BASE_URL/api/mobile/level2/requests" "Amadou Diallo"
test_content "Données Sénégalaises - Emails" "$BASE_URL/api/mobile/level2/requests" ".sn"
test_content "Données Sénégalaises - Contexte" "$BASE_URL/api/mobile/level2/requests" "Kaolack"

# Test timeline enrichie
test_content "Timeline Enrichie" "$BASE_URL/api/mobile/level3/request/1" "Demande soumise par"
test_content "Statuts Français" "$BASE_URL/api/mobile/level2/requests" "En Traitement"

echo ""

# ========================================= #
# RÉSULTATS FINAUX                         #
# ========================================= #

echo -e "${PURPLE}📊 RÉSULTATS DES TESTS${NC}"
echo "======================"
echo ""

PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo -e "${CYAN}Tests réussis:${NC} $PASSED_TESTS/$TOTAL_TESTS ($PERCENTAGE%)"

if [ $PERCENTAGE -eq 100 ]; then
    echo -e "${GREEN}🎉 TOUS LES TESTS RÉUSSIS !${NC}"
    echo ""
    echo -e "${GREEN}✅ Navigation 3 niveaux 100% fonctionnelle${NC}"
    echo -e "${GREEN}✅ APIs complètes et opérationnelles${NC}"
    echo -e "${GREEN}✅ Données réalistes intégrées${NC}"
    echo -e "${GREEN}✅ Interface enrichie prête${NC}"
    echo ""
    echo -e "${PURPLE}🚀 SAMA CONAI PRÊT POUR DÉMONSTRATION${NC}"
elif [ $PERCENTAGE -ge 90 ]; then
    echo -e "${YELLOW}⚠️ Tests majoritairement réussis${NC}"
    echo -e "${YELLOW}Quelques ajustements mineurs nécessaires${NC}"
elif [ $PERCENTAGE -ge 75 ]; then
    echo -e "${YELLOW}⚠️ Tests partiellement réussis${NC}"
    echo -e "${YELLOW}Corrections nécessaires${NC}"
else
    echo -e "${RED}❌ Tests majoritairement échoués${NC}"
    echo -e "${RED}Révision complète nécessaire${NC}"
fi

echo ""
echo -e "${CYAN}🔗 URLs de Test Principales:${NC}"
echo "   🔥 Interface Enrichie: $BASE_URL/enriched"
echo "   📱 Layers Corrigés: $BASE_URL/fixed-layers"
echo "   🌐 Interface Complète: $BASE_URL/"
echo ""
echo -e "${CYAN}👤 Connexion:${NC} admin / admin"
echo ""

# Affichage des commandes utiles
echo -e "${CYAN}🛠️ Commandes Utiles:${NC}"
echo "   ./launch_enriched_sama_conai.sh    # Interface enrichie"
echo "   ./quick_start_sama_conai.sh        # Interface production"
echo "   ./stop_enriched_sama_conai.sh      # Arrêt enrichie"
echo "   ./status_sama_conai.sh             # Status en temps réel"
echo ""

echo "==========================================="
echo "🇸🇳 SAMA CONAI - Test Navigation Terminé"
echo "==========================================="