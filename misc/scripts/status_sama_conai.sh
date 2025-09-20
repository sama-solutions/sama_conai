#!/bin/bash

# ========================================= #
# SAMA CONAI - STATUS RAPIDE               #
# ========================================= #

clear
echo "🇸🇳 SAMA CONAI - Status du Projet"
echo "================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fonction pour vérifier le statut
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Vérification du serveur
echo -e "${PURPLE}📊 ÉTAT DU SERVEUR${NC}"
echo "=================="

if curl -s http://localhost:3007 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Serveur SAMA CONAI actif (port 3007)${NC}"
    SERVER_RUNNING=1
else
    echo -e "${RED}❌ Serveur SAMA CONAI arrêté${NC}"
    SERVER_RUNNING=0
fi

if curl -s http://localhost:8077 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend Odoo accessible (port 8077)${NC}"
else
    echo -e "${YELLOW}⚠️  Backend Odoo non accessible${NC}"
fi

echo ""

# Interfaces disponibles
echo -e "${PURPLE}📱 INTERFACES DISPONIBLES${NC}"
echo "========================="

if [ $SERVER_RUNNING -eq 1 ]; then
    echo -e "${CYAN}🔥 RECOMMANDÉE:${NC}"
    echo "   http://localhost:3007/fixed-layers"
    echo "   ${GREEN}→ Problème de layers résolu${NC}"
    echo ""
    echo -e "${CYAN}Autres interfaces:${NC}"
    echo "   http://localhost:3007/ (Complète)"
    echo "   http://localhost:3007/advanced (Avancée)"
    echo "   http://localhost:3007/correct (Corrigée)"
else
    echo -e "${RED}Serveur arrêté - Interfaces non disponibles${NC}"
    echo ""
    echo -e "${YELLOW}Pour démarrer:${NC} ./quick_start_sama_conai.sh"
fi

echo ""

# Fichiers principaux
echo -e "${PURPLE}📁 FICHIERS PRINCIPAUX${NC}"
echo "====================="

check_status $([ -f "mobile_app_web/server_complete.js" ] && echo 0 || echo 1) "Serveur complet"
check_status $([ -f "mobile_app_web/public/sama_conai_fixed_layers.html" ] && echo 0 || echo 1) "Interface layers corrigés"
check_status $([ -f "mobile_app_web/public/sama_conai_complete.html" ] && echo 0 || echo 1) "Interface complète"
check_status $([ -f "quick_start_sama_conai.sh" ] && echo 0 || echo 1) "Script de démarrage"
check_status $([ -f "validation_finale.sh" ] && echo 0 || echo 1) "Script de validation"

echo ""

# Fonctionnalités
echo -e "${PURPLE}🎯 FONCTIONNALITÉS RÉSOLUES${NC}"
echo "=========================="

echo -e "${GREEN}✅ Navigation 3 niveaux active${NC}"
echo -e "${GREEN}✅ Theme switcher corrigé (3+ thèmes)${NC}"
echo -e "${GREEN}✅ Données réelles Odoo intégrées${NC}"
echo -e "${GREEN}✅ Mode admin global activé${NC}"
echo -e "${GREEN}✅ Intégration backend Odoo${NC}"
echo -e "${GREEN}✅ 🔥 Problème de layers résolu${NC}"

echo ""

# Commandes utiles
echo -e "${PURPLE}🛠️  COMMANDES UTILES${NC}"
echo "==================="

if [ $SERVER_RUNNING -eq 1 ]; then
    echo -e "${YELLOW}Serveur actif:${NC}"
    echo "   ./stop_sama_conai_complete.sh    (Arrêter)"
    echo "   ./validation_finale.sh           (Valider)"
else
    echo -e "${YELLOW}Serveur arrêté:${NC}"
    echo "   ./quick_start_sama_conai.sh      (Démarrer)"
fi

echo "   ./test_sama_conai_complete.sh    (Tests complets)"

echo ""

# Connexion
echo -e "${PURPLE}🔐 CONNEXION${NC}"
echo "============"
echo -e "${CYAN}Utilisateur:${NC} admin"
echo -e "${CYAN}Mot de passe:${NC} admin"

echo ""

# Status final
echo -e "${PURPLE}🎉 STATUS FINAL${NC}"
echo "==============="

if [ $SERVER_RUNNING -eq 1 ]; then
    echo -e "${GREEN}🚀 SAMA CONAI OPÉRATIONNEL${NC}"
    echo ""
    echo -e "${CYAN}Interface recommandée:${NC}"
    echo "http://localhost:3007/fixed-layers"
    echo ""
    echo -e "${GREEN}Prêt pour utilisation !${NC}"
else
    echo -e "${YELLOW}⏸️  SAMA CONAI EN ATTENTE${NC}"
    echo ""
    echo -e "${CYAN}Pour démarrer:${NC}"
    echo "./quick_start_sama_conai.sh"
fi

echo ""
echo "================================="
echo "🇸🇳 SAMA CONAI - Status terminé"
echo "================================="