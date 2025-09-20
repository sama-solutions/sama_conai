#!/usr/bin/env bash

# ============================================================================
# Affichage des scripts disponibles pour SAMA CONAI
# ============================================================================

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}                    SAMA CONAI - Scripts Disponibles${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo

echo -e "${BOLD}🚀 SCRIPTS PRINCIPAUX${NC}"
echo
echo -e "${GREEN}./quick_start.sh${NC}                 ${CYAN}Script de démarrage rapide${NC}"
echo "  ./quick_start.sh init              # Première installation"
echo "  ./quick_start.sh update            # Mise à jour"
echo "  ./quick_start.sh test              # Tests complets"
echo "  ./quick_start.sh stop              # Arrêt"
echo

echo -e "${GREEN}./launch_sama_conai.sh${NC}          ${CYAN}Lancement détaillé avec options${NC}"
echo "  ./launch_sama_conai.sh --init -p 8075 -d sama_conai_test"
echo "  ./launch_sama_conai.sh --update -p 8075 --dev --follow"
echo "  ./launch_sama_conai.sh --run -p 8075 --debug"
echo

echo -e "${GREEN}./test_cycle_sama_conai.sh${NC}      ${CYAN}Cycle de test automatisé${NC}"
echo "  ./test_cycle_sama_conai.sh -p 8075"
echo "  ./test_cycle_sama_conai.sh --continuous --dev"
echo "  ./test_cycle_sama_conai.sh --non-interactive"
echo

echo -e "${BOLD}🛠️ SCRIPTS UTILITAIRES${NC}"
echo
echo -e "${GREEN}./stop_sama_conai.sh${NC}            ${CYAN}Arrêt propre des instances${NC}"
echo "  ./stop_sama_conai.sh -p 8075"
echo "  ./stop_sama_conai.sh --all"
echo "  ./stop_sama_conai.sh --status"
echo

echo -e "${GREEN}./cleanup_temp.sh${NC}               ${CYAN}Nettoyage des fichiers temporaires${NC}"
echo "  ./cleanup_temp.sh"
echo "  ./cleanup_temp.sh --deep"
echo "  ./cleanup_temp.sh --dry-run"
echo

echo -e "${GREEN}./validate_environment.sh${NC}       ${CYAN}Validation de l'environnement${NC}"
echo "  ./validate_environment.sh"
echo

echo -e "${BOLD}📚 DOCUMENTATION${NC}"
echo
echo -e "${YELLOW}INSTALLATION_GUIDE.md${NC}          ${CYAN}Guide d'installation complet${NC}"
echo -e "${YELLOW}SCRIPTS_README.md${NC}              ${CYAN}Documentation détaillée des scripts${NC}"
echo

echo -e "${BOLD}🎯 DÉMARRAGE RAPIDE${NC}"
echo
echo -e "${CYAN}1. Validation (optionnel) :${NC}     ./validate_environment.sh"
echo -e "${CYAN}2. Première installation :${NC}      ./quick_start.sh init"
echo -e "${CYAN}3. Tests :${NC}                      ./quick_start.sh test"
echo -e "${CYAN}4. Accès web :${NC}                  http://localhost:8075"
echo

echo -e "${BOLD}🔧 DÉVELOPPEMENT${NC}"
echo
echo -e "${CYAN}Mode développement :${NC}            ./launch_sama_conai.sh --run --dev --follow"
echo -e "${CYAN}Tests continus :${NC}                ./test_cycle_sama_conai.sh --continuous"
echo -e "${CYAN}Mise à jour :${NC}                   ./quick_start.sh update"
echo

echo -e "${BOLD}🆘 DÉPANNAGE${NC}"
echo
echo -e "${CYAN}Arrêt forcé :${NC}                   ./stop_sama_conai.sh --all --force"
echo -e "${CYAN}Nettoyage complet :${NC}             ./cleanup_temp.sh --deep"
echo -e "${CYAN}Logs d'erreur :${NC}                 tail -f .sama_conai_temp/logs/odoo-8075.log"
echo

echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}Pour plus d'informations, consultez INSTALLATION_GUIDE.md${NC}"
echo -e "${BLUE}============================================================================${NC}"