#!/bin/bash

# ========================================
# SAMA CONAI - SCRIPT PRINCIPAL DE DÉVELOPPEMENT
# ========================================
# Script principal pour orchestrer tous les outils de développement
# Version: 1.0.0

set -e

# ========================================
# CONFIGURATION
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Scripts disponibles
MAIN_SCRIPT="$SCRIPT_DIR/launch_sama_conai_test.sh"
MOBILE_SCRIPT="$SCRIPT_DIR/mobile_app_web/launch_mobile.sh"
TEST_CYCLE_SCRIPT="$SCRIPT_DIR/scripts_temp/test_cycle.sh"
MONITOR_SCRIPT="$SCRIPT_DIR/scripts_temp/monitor.sh"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ========================================
# FONCTIONS UTILITAIRES
# ========================================

print_banner() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                SAMA CONAI - ENVIRONNEMENT DE DÉVELOPPEMENT   ║${NC}"
    echo -e "${PURPLE}║                     Script Principal v1.0                   ║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║  🇸🇳 République du Sénégal - Transparence Numérique         ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_header() {
    echo ""
    echo -e "${CYAN}🔧 $1${NC}"
    echo "=================================================="
}

print_success() {
    echo -e "${GREEN}🎉${NC} $1"
}

# ========================================
# FONCTIONS DE VÉRIFICATION
# ========================================

check_scripts() {
    print_header "VÉRIFICATION DES SCRIPTS"
    
    local missing_scripts=()
    
    if [ ! -f "$MAIN_SCRIPT" ]; then
        missing_scripts+=("launch_sama_conai_test.sh")
    else
        print_status "Script principal trouvé"
    fi
    
    if [ ! -f "$MOBILE_SCRIPT" ]; then
        missing_scripts+=("mobile_app_web/launch_mobile.sh")
    else
        print_status "Script mobile trouvé"
    fi
    
    if [ ! -f "$TEST_CYCLE_SCRIPT" ]; then
        missing_scripts+=("scripts_temp/test_cycle.sh")
    else
        print_status "Script de test trouvé"
    fi
    
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        missing_scripts+=("scripts_temp/monitor.sh")
    else
        print_status "Script de monitoring trouvé"
    fi
    
    if [ ${#missing_scripts[@]} -ne 0 ]; then
        print_error "Scripts manquants: ${missing_scripts[*]}"
        return 1
    fi
    
    # Vérifier les permissions
    for script in "$MAIN_SCRIPT" "$MOBILE_SCRIPT" "$TEST_CYCLE_SCRIPT" "$MONITOR_SCRIPT"; do
        if [ ! -x "$script" ]; then
            print_warning "Correction des permissions pour $(basename $script)"
            chmod +x "$script"
        fi
    done
    
    print_success "Tous les scripts sont disponibles et exécutables"
}

show_menu() {
    echo ""
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                        MENU PRINCIPAL                        ║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║                                                              ║${NC}"
    echo -e "${WHITE}║  ${CYAN}1.${NC} 🚀 Démarrage complet (Odoo + Mobile)                  ║${NC}"
    echo -e "${WHITE}║  ${CYAN}2.${NC} 🔧 Démarrage Odoo seulement                           ║${NC}"
    echo -e "${WHITE}║  ${CYAN}3.${NC} 📱 Démarrage application mobile seulement             ║${NC}"
    echo -e "${WHITE}║  ${CYAN}4.${NC} 🔄 Cycle de tests automatisé                          ║${NC}"
    echo -e "${WHITE}║  ${CYAN}5.${NC} 📊 Monitoring en temps réel                           ║${NC}"
    echo -e "${WHITE}║  ${CYAN}6.${NC} 📋 Afficher les logs                                  ║${NC}"
    echo -e "${WHITE}║  ${CYAN}7.${NC} 📈 Statut des services                                ║${NC}"
    echo -e "${WHITE}║  ${CYAN}8.${NC} 🛑 Arrêter tous les services                          ║${NC}"
    echo -e "${WHITE}║  ${CYAN}9.${NC} 🧹 Nettoyer l'environnement                           ║${NC}"
    echo -e "${WHITE}║  ${CYAN}0.${NC} ❓ Aide et documentation                              ║${NC}"
    echo -e "${WHITE}║                                                              ║${NC}"
    echo -e "${WHITE}║  ${RED}q.${NC} Quitter                                               ║${NC}"
    echo -e "${WHITE}║                                                              ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -n "Choisissez une option: "
}

# ========================================
# FONCTIONS D'ACTION
# ========================================

start_full_environment() {
    print_header "DÉMARRAGE COMPLET DE L'ENVIRONNEMENT"
    
    print_info "Démarrage d'Odoo et de l'application mobile..."
    exec "$MAIN_SCRIPT" start
}

start_odoo_only() {
    print_header "DÉMARRAGE D'ODOO SEULEMENT"
    
    print_info "Démarrage d'Odoo en mode test..."
    # Démarrer Odoo puis revenir au menu
    "$MAIN_SCRIPT" start &
    local main_pid=$!
    
    print_info "Odoo démarré en arrière-plan (PID: $main_pid)"
    print_info "Utilisez le monitoring pour surveiller le statut"
    
    sleep 2
    return 0
}

start_mobile_only() {
    print_header "DÉMARRAGE APPLICATION MOBILE SEULEMENT"
    
    print_info "Démarrage de l'application mobile..."
    exec "$MOBILE_SCRIPT" start
}

run_test_cycle() {
    print_header "CYCLE DE TESTS AUTOMATISÉ"
    
    print_info "Démarrage du cycle de tests..."
    exec "$TEST_CYCLE_SCRIPT" full
}

start_monitoring() {
    print_header "MONITORING EN TEMPS RÉEL"
    
    print_info "Démarrage du monitoring..."
    exec "$MONITOR_SCRIPT" monitor
}

show_logs() {
    print_header "AFFICHAGE DES LOGS"
    
    local log_dir="$SCRIPT_DIR/scripts_temp/logs"
    
    if [ ! -d "$log_dir" ]; then
        print_warning "Répertoire de logs non trouvé: $log_dir"
        return 1
    fi
    
    echo ""
    echo "Logs disponibles:"
    ls -la "$log_dir/" 2>/dev/null || echo "Aucun fichier de log"
    
    echo ""
    echo "Choisissez un log à afficher:"
    echo "1. Odoo"
    echo "2. Application Mobile"
    echo "3. Monitoring"
    echo "4. Tous"
    echo "0. Retour"
    
    echo -n "Votre choix: "
    read choice
    
    case $choice in
        1)
            if [ -f "$log_dir/odoo_test.log" ]; then
                echo ""
                echo -e "${YELLOW}=== LOGS ODOO ===${NC}"
                tail -n 50 "$log_dir/odoo_test.log"
            else
                print_warning "Fichier de log Odoo non trouvé"
            fi
            ;;
        2)
            if [ -f "$log_dir/mobile_test.log" ]; then
                echo ""
                echo -e "${YELLOW}=== LOGS APPLICATION MOBILE ===${NC}"
                tail -n 50 "$log_dir/mobile_test.log"
            else
                print_warning "Fichier de log mobile non trouvé"
            fi
            ;;
        3)
            if [ -f "$log_dir/monitor.log" ]; then
                echo ""
                echo -e "${YELLOW}=== LOGS MONITORING ===${NC}"
                tail -n 50 "$log_dir/monitor.log"
            else
                print_warning "Fichier de log monitoring non trouvé"
            fi
            ;;
        4)
            for log_file in "$log_dir"/*.log; do
                if [ -f "$log_file" ]; then
                    echo ""
                    echo -e "${YELLOW}=== $(basename $log_file) ===${NC}"
                    tail -n 20 "$log_file"
                fi
            done
            ;;
        0)
            return 0
            ;;
        *)
            print_error "Choix invalide"
            ;;
    esac
    
    echo ""
    echo "Appuyez sur Entrée pour continuer..."
    read
}

show_status() {
    print_header "STATUT DES SERVICES"
    
    # Utiliser le script de monitoring pour un check unique
    "$MONITOR_SCRIPT" check
    
    echo ""
    echo "Appuyez sur Entrée pour continuer..."
    read
}

stop_all_services() {
    print_header "ARRÊT DE TOUS LES SERVICES"
    
    print_info "Arrêt des services..."
    
    # Arrêter via le script principal
    "$MAIN_SCRIPT" stop 2>/dev/null || true
    
    # Arrêter l'application mobile
    "$MOBILE_SCRIPT" stop 2>/dev/null || true
    
    # Arrêter les processus sur les ports de test
    local test_ports=(8075 3005)
    for port in "${test_ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pids=$(lsof -ti:$port)
            for pid in $pids; do
                print_info "Arrêt du processus PID $pid sur le port $port"
                kill -TERM $pid 2>/dev/null || true
            done
        fi
    done
    
    print_success "Services arrêtés"
    
    echo ""
    echo "Appuyez sur Entrée pour continuer..."
    read
}

clean_environment() {
    print_header "NETTOYAGE DE L'ENVIRONNEMENT"
    
    print_info "Nettoyage complet..."
    
    # Arrêter les services
    stop_all_services
    
    # Nettoyer via le script principal
    "$MAIN_SCRIPT" clean 2>/dev/null || true
    
    # Nettoyer les fichiers temporaires
    if [ -d "$SCRIPT_DIR/scripts_temp" ]; then
        print_info "Suppression des fichiers temporaires..."
        rm -rf "$SCRIPT_DIR/scripts_temp"
        print_status "Fichiers temporaires supprimés"
    fi
    
    print_success "Environnement nettoyé"
    
    echo ""
    echo "Appuyez sur Entrée pour continuer..."
    read
}

show_help() {
    print_header "AIDE ET DOCUMENTATION"
    
    echo ""
    echo -e "${WHITE}SAMA CONAI - Environnement de Développement${NC}"
    echo ""
    echo -e "${CYAN}Configuration:${NC}"
    echo "  • Odoo: /var/odoo/odoo18"
    echo "  • Virtual Env: /home/grand-as/odoo18-venv"
    echo "  • Custom Addons: /home/grand-as/psagsn/custom_addons"
    echo "  • Port Odoo Test: 8075"
    echo "  • Port Mobile Test: 3005"
    echo ""
    echo -e "${CYAN}Scripts disponibles:${NC}"
    echo "  • launch_sama_conai_test.sh - Script principal"
    echo "  • mobile_app_web/launch_mobile.sh - Application mobile"
    echo "  • scripts_temp/test_cycle.sh - Tests automatisés"
    echo "  • scripts_temp/monitor.sh - Monitoring"
    echo ""
    echo -e "${CYAN}Utilisation directe:${NC}"
    echo "  ./launch_sama_conai_test.sh start"
    echo "  ./launch_sama_conai_test.sh status"
    echo "  ./launch_sama_conai_test.sh logs"
    echo "  ./launch_sama_conai_test.sh clean"
    echo ""
    echo -e "${CYAN}URLs d'accès:${NC}"
    echo "  • Odoo: http://localhost:8075"
    echo "  • Mobile: http://localhost:3005"
    echo ""
    echo -e "${CYAN}Comptes de test:${NC}"
    echo "  • Admin: admin / admin"
    echo "  • Demo Mobile: demo@sama-conai.sn / demo123"
    echo ""
    echo -e "${CYAN}Fichiers temporaires:${NC}"
    echo "  • Logs: scripts_temp/logs/"
    echo "  • PIDs: scripts_temp/pids/"
    echo ""
    echo -e "${YELLOW}Note:${NC} Tous les scripts sont autonomes et peuvent être"
    echo "exécutés indépendamment pour les tests."
    echo ""
    echo "Appuyez sur Entrée pour continuer..."
    read
}

# ========================================
# FONCTION PRINCIPALE
# ========================================

main() {
    # Si des arguments sont passés, exécuter directement
    if [ $# -gt 0 ]; then
        case "$1" in
            "start")
                start_full_environment
                ;;
            "odoo")
                start_odoo_only
                ;;
            "mobile")
                start_mobile_only
                ;;
            "test")
                run_test_cycle
                ;;
            "monitor")
                start_monitoring
                ;;
            "logs")
                show_logs
                ;;
            "status")
                show_status
                ;;
            "stop")
                stop_all_services
                ;;
            "clean")
                clean_environment
                ;;
            "help")
                print_banner
                show_help
                ;;
            *)
                print_error "Commande inconnue: $1"
                echo "Utilisez '$0 help' pour voir les commandes disponibles"
                exit 1
                ;;
        esac
        return
    fi
    
    # Mode interactif
    print_banner
    check_scripts
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                start_full_environment
                ;;
            2)
                start_odoo_only
                ;;
            3)
                start_mobile_only
                ;;
            4)
                run_test_cycle
                ;;
            5)
                start_monitoring
                ;;
            6)
                show_logs
                ;;
            7)
                show_status
                ;;
            8)
                stop_all_services
                ;;
            9)
                clean_environment
                ;;
            0)
                show_help
                ;;
            q|Q)
                print_info "Au revoir !"
                exit 0
                ;;
            *)
                print_error "Choix invalide. Veuillez choisir une option valide."
                sleep 1
                ;;
        esac
    done
}

# ========================================
# EXÉCUTION
# ========================================

# Vérifier que le script est dans le bon répertoire
if [ ! -f "$SCRIPT_DIR/__manifest__.py" ]; then
    print_error "Ce script doit être exécuté depuis le répertoire du module SAMA CONAI"
    exit 1
fi

# Exécuter la fonction principale
main "$@"