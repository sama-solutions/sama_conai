#!/bin/bash

# ========================================
# SAMA CONAI - DÉMARRAGE RAPIDE POUR TESTS
# ========================================
# Script de démarrage rapide pour validation
# Version: 1.0.0

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

print_banner() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║              SAMA CONAI - DÉMARRAGE RAPIDE                   ║${NC}"
    echo -e "${PURPLE}║                  Tests et Validation                        ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

print_success() {
    echo -e "${GREEN}🎉${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

main() {
    print_banner
    
    print_info "Démarrage de la validation de l'environnement SAMA CONAI..."
    echo ""
    
    # Étape 1: Validation de l'environnement
    print_info "Étape 1: Validation de l'environnement"
    if [ -f "scripts_temp/validate_setup.sh" ]; then
        if ./scripts_temp/validate_setup.sh; then
            print_success "Validation réussie !"
        else
            print_error "Validation échouée - consultez les recommandations ci-dessus"
            echo ""
            print_info "Voulez-vous continuer malgré les erreurs ? (y/N)"
            read -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Arrêt du test. Corrigez les problèmes et relancez."
                exit 1
            fi
        fi
    else
        print_warning "Script de validation non trouvé, passage à l'étape suivante"
    fi
    
    echo ""
    print_info "Étape 2: Choix du mode de test"
    echo ""
    echo "Choisissez le mode de test:"
    echo "1. 🚀 Test complet (recommandé)"
    echo "2. 🔧 Test Odoo seulement"
    echo "3. 📱 Test application mobile seulement"
    echo "4. 🔄 Cycle de tests automatisé"
    echo "5. 📊 Monitoring seulement"
    echo "0. ❌ Annuler"
    echo ""
    echo -n "Votre choix (1-5): "
    read choice
    
    case $choice in
        1)
            print_info "Démarrage du test complet..."
            exec ./launch_sama_conai_test.sh start
            ;;
        2)
            print_info "Démarrage d'Odoo seulement..."
            exec ./launch_sama_conai_test.sh start
            ;;
        3)
            print_info "Démarrage de l'application mobile..."
            if [ -f "mobile_app_web/launch_mobile.sh" ]; then
                exec ./mobile_app_web/launch_mobile.sh start
            else
                print_error "Script mobile non trouvé"
                exit 1
            fi
            ;;
        4)
            print_info "Démarrage du cycle de tests automatisé..."
            if [ -f "scripts_temp/test_cycle.sh" ]; then
                exec ./scripts_temp/test_cycle.sh full
            else
                print_error "Script de test non trouvé"
                exit 1
            fi
            ;;
        5)
            print_info "Démarrage du monitoring..."
            if [ -f "scripts_temp/monitor.sh" ]; then
                exec ./scripts_temp/monitor.sh monitor
            else
                print_error "Script de monitoring non trouvé"
                exit 1
            fi
            ;;
        0)
            print_info "Test annulé"
            exit 0
            ;;
        *)
            print_error "Choix invalide"
            exit 1
            ;;
    esac
}

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "__manifest__.py" ]; then
    print_error "Ce script doit être exécuté depuis le répertoire du module SAMA CONAI"
    exit 1
fi

main "$@"