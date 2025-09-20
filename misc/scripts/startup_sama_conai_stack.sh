#!/bin/bash

# ========================================
# SAMA CONAI - SCRIPT DE DÉMARRAGE STACK COMPLET
# ========================================
# Script de démarrage unifié pour tout le stack SAMA CONAI
# Compatible avec votre configuration existante
# Version: 1.0.0

set -e

# ========================================
# CONFIGURATION
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="SAMA CONAI"
VERSION="1.0.0"

# Configuration par défaut (basée sur vos scripts existants)
ODOO_PATH="/var/odoo/odoo18"
VENV_DIR="/home/grand-as/odoo18-venv"
ADDONS_PATH="/home/grand-as/psagsn/custom_addons"
DB_NAME="sama_conai_test"
ODOO_PORT="8077"  # Port utilisé dans votre start_mobile_final.sh
MOBILE_PORT="3005"  # Port utilisé dans votre start_mobile_final.sh
POSTGRES_PORT="5432"
DB_USER="odoo"
DB_PASSWORD="odoo"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Fichiers PID et logs
PIDS_DIR="$SCRIPT_DIR/.pids"
LOGS_DIR="$SCRIPT_DIR/logs"
ODOO_PID_FILE="$PIDS_DIR/odoo.pid"
MOBILE_PID_FILE="$PIDS_DIR/mobile.pid"
ODOO_LOG="$LOGS_DIR/odoo.log"
MOBILE_LOG="$LOGS_DIR/mobile.log"

# ========================================
# FONCTIONS UTILITAIRES
# ========================================

print_banner() {
    clear
    echo ""
    echo -e "${PURPLE}${BOLD}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║                        SAMA CONAI STACK                              ║${NC}"
    echo -e "${PURPLE}${BOLD}║              Plateforme de Transparence du Sénégal                  ║${NC}"
    echo -e "${PURPLE}${BOLD}║                                                                      ║${NC}"
    echo -e "${PURPLE}${BOLD}║  🇸🇳 République du Sénégal - Transparence et Gouvernance Numérique  ║${NC}"
    echo -e "${PURPLE}${BOLD}║                           Version $VERSION                            ║${NC}"
    echo -e "${PURPLE}${BOLD}╚══════════════════════════════════════════════════════════════════════╝${NC}"
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
    echo -e "${CYAN}${BOLD}🔧 $1${NC}"
    echo "=================================================================="
}

print_success() {
    echo -e "${GREEN}${BOLD}🎉 $1${NC}"
}

# ========================================
# FONCTIONS DE VÉRIFICATION
# ========================================

check_prerequisites() {
    print_header "VÉRIFICATION DES PRÉREQUIS"
    
    local missing_deps=()
    
    # Vérifier Python3
    if command -v python3 &> /dev/null; then
        print_status "Python3 détecté: $(python3 --version)"
    else
        missing_deps+=("python3")
    fi
    
    # Vérifier Node.js
    if command -v node &> /dev/null; then
        print_status "Node.js détecté: $(node --version)"
    else
        missing_deps+=("nodejs")
    fi
    
    # Vérifier npm
    if command -v npm &> /dev/null; then
        print_status "npm détecté: $(npm --version)"
    else
        missing_deps+=("npm")
    fi
    
    # Vérifier PostgreSQL
    if command -v psql &> /dev/null; then
        print_status "PostgreSQL détecté: $(psql --version | head -n1)"
    else
        missing_deps+=("postgresql")
    fi
    
    # Vérifier curl
    if command -v curl &> /dev/null; then
        print_status "curl détecté"
    else
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Dépendances manquantes: ${missing_deps[*]}"
        echo ""
        echo "Pour installer sur Ubuntu/Debian:"
        echo "sudo apt update && sudo apt install ${missing_deps[*]}"
        return 1
    fi
    
    print_status "Tous les prérequis sont satisfaits"
    return 0
}

check_environment() {
    print_header "VÉRIFICATION DE L'ENVIRONNEMENT"
    
    # Vérifier l'environnement virtuel Python
    if [ -f "$VENV_DIR/bin/activate" ]; then
        print_status "Environnement virtuel Python trouvé: $VENV_DIR"
    else
        print_error "Environnement virtuel Python non trouvé: $VENV_DIR"
        return 1
    fi
    
    # Vérifier Odoo
    if [ -f "$ODOO_PATH/odoo-bin" ]; then
        print_status "Installation Odoo trouvée: $ODOO_PATH"
    else
        print_error "Installation Odoo non trouvée: $ODOO_PATH"
        return 1
    fi
    
    # Vérifier le module SAMA CONAI
    if [ -f "$SCRIPT_DIR/__manifest__.py" ]; then
        print_status "Module SAMA CONAI trouvé"
    else
        print_error "Module SAMA CONAI non trouvé dans: $SCRIPT_DIR"
        return 1
    fi
    
    # Vérifier l'application mobile
    if [ -d "$SCRIPT_DIR/mobile_app_web" ] && [ -f "$SCRIPT_DIR/mobile_app_web/server.js" ]; then
        print_status "Application mobile web trouvée"
    else
        print_error "Application mobile web non trouvée"
        return 1
    fi
    
    return 0
}

check_ports() {
    print_header "VÉRIFICATION DES PORTS"
    
    local ports_to_check=($ODOO_PORT $MOBILE_PORT $POSTGRES_PORT)
    local occupied_ports=()
    
    for port in "${ports_to_check[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -ti:$port)
            local process=$(ps -p $pid -o comm= 2>/dev/null || echo "inconnu")
            occupied_ports+=("$port:$pid:$process")
            print_warning "Port $port utilisé par $process (PID: $pid)"
        else
            print_status "Port $port disponible"
        fi
    done
    
    if [ ${#occupied_ports[@]} -ne 0 ]; then
        echo ""
        read -p "Voulez-vous arrêter les processus existants ? (y/N): " choice
        if [[ $choice == [yY] ]]; then
            for port_info in "${occupied_ports[@]}"; do
                local port=$(echo $port_info | cut -d: -f1)
                local pid=$(echo $port_info | cut -d: -f2)
                local process=$(echo $port_info | cut -d: -f3)
                
                print_info "Arrêt du processus $process (PID: $pid) sur le port $port"
                kill $pid 2>/dev/null || true
                sleep 2
            done
        fi
    fi
    
    return 0
}

# ========================================
# FONCTIONS DE DÉMARRAGE
# ========================================

start_postgresql() {
    print_header "DÉMARRAGE DE POSTGRESQL"
    
    if pgrep -x "postgres" > /dev/null; then
        print_status "PostgreSQL déjà en cours d'exécution"
        return 0
    fi
    
    print_info "Démarrage de PostgreSQL..."
    
    if command -v systemctl &> /dev/null; then
        sudo systemctl start postgresql
        print_status "PostgreSQL démarré via systemctl"
    elif command -v service &> /dev/null; then
        sudo service postgresql start
        print_status "PostgreSQL démarré via service"
    else
        print_error "Impossible de démarrer PostgreSQL automatiquement"
        return 1
    fi
    
    # Attendre que PostgreSQL soit prêt
    print_info "Attente de la disponibilité de PostgreSQL..."
    for i in {1..30}; do
        if pg_isready -h localhost -p $POSTGRES_PORT >/dev/null 2>&1; then
            print_status "PostgreSQL est prêt"
            return 0
        fi
        sleep 1
    done
    
    print_error "PostgreSQL n'est pas disponible après 30 secondes"
    return 1
}

setup_database() {
    print_header "CONFIGURATION DE LA BASE DE DONNÉES"
    
    # Vérifier si la base de données existe
    if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        print_status "Base de données $DB_NAME existe déjà"
    else
        print_info "Création de la base de données $DB_NAME..."
        PGPASSWORD="$DB_PASSWORD" createdb -h localhost -U $DB_USER $DB_NAME
        print_status "Base de données $DB_NAME créée"
    fi
    
    return 0
}

start_odoo() {
    print_header "DÉMARRAGE D'ODOO"
    
    # Vérifier si Odoo est déjà en cours d'exécution
    if [ -f "$ODOO_PID_FILE" ] && kill -0 $(cat "$ODOO_PID_FILE") 2>/dev/null; then
        print_status "Odoo déjà en cours d'exécution (PID: $(cat $ODOO_PID_FILE))"
        return 0
    fi
    
    # Créer les répertoires nécessaires
    mkdir -p "$PIDS_DIR" "$LOGS_DIR"
    
    print_info "Démarrage d'Odoo sur le port $ODOO_PORT..."
    
    # Activer l'environnement virtuel et démarrer Odoo
    cd "$ODOO_PATH"
    
    nohup bash -c "
        source $VENV_DIR/bin/activate
        python3 odoo-bin \\
            -d $DB_NAME \\
            --addons-path=\"$ODOO_PATH/addons,$ADDONS_PATH\" \\
            --db_host=localhost \\
            --db_user=$DB_USER \\
            --db_password=$DB_PASSWORD \\
            --http-port=$ODOO_PORT \\
            --log-level=info \\
            --workers=0
    " > "$ODOO_LOG" 2>&1 &
    
    local odoo_pid=$!
    echo $odoo_pid > "$ODOO_PID_FILE"
    
    print_info "Odoo démarré avec PID: $odoo_pid"
    print_info "Logs disponibles dans: $ODOO_LOG"
    
    # Attendre qu'Odoo soit prêt
    print_info "Attente du démarrage d'Odoo (peut prendre 1-2 minutes)..."
    for i in {1..60}; do
        if curl -s --connect-timeout 2 "http://localhost:$ODOO_PORT" > /dev/null 2>&1; then
            print_status "Odoo est prêt et accessible sur http://localhost:$ODOO_PORT"
            cd "$SCRIPT_DIR"
            return 0
        fi
        
        # Vérifier si le processus est toujours en cours
        if ! kill -0 $odoo_pid 2>/dev/null; then
            print_error "Le processus Odoo s'est arrêté de manière inattendue"
            print_info "Vérifiez les logs: tail -f $ODOO_LOG"
            cd "$SCRIPT_DIR"
            return 1
        fi
        
        echo -n "."
        sleep 2
    done
    
    print_error "Odoo n'est pas accessible après 2 minutes"
    print_info "Vérifiez les logs: tail -f $ODOO_LOG"
    cd "$SCRIPT_DIR"
    return 1
}

start_mobile_app() {
    print_header "DÉMARRAGE DE L'APPLICATION MOBILE"
    
    # Vérifier si l'application mobile est déjà en cours d'exécution
    if [ -f "$MOBILE_PID_FILE" ] && kill -0 $(cat "$MOBILE_PID_FILE") 2>/dev/null; then
        print_status "Application mobile déjà en cours d'exécution (PID: $(cat $MOBILE_PID_FILE))"
        return 0
    fi
    
    # Vérifier que le répertoire existe
    if [ ! -d "mobile_app_web" ]; then
        print_error "Le répertoire mobile_app_web n'existe pas"
        return 1
    fi
    
    cd mobile_app_web
    
    # Vérifier et installer les dépendances si nécessaire
    if [ ! -d "node_modules" ]; then
        print_info "Installation des dépendances npm..."
        npm install
        if [ $? -ne 0 ]; then
            print_error "Erreur lors de l'installation des dépendances"
            cd "$SCRIPT_DIR"
            return 1
        fi
    fi
    
    # Arrêter les processus existants
    print_info "Arrêt des processus mobile existants..."
    pkill -f "node.*server.js" 2>/dev/null || true
    sleep 2
    
    # Vérifier que le backend Odoo fonctionne
    print_info "Vérification du backend Odoo..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$ODOO_PORT | grep -q "200"; then
        print_status "Backend Odoo accessible sur http://localhost:$ODOO_PORT"
    else
        print_warning "Backend Odoo non accessible - l'application fonctionnera en mode démonstration"
    fi
    
    # Démarrer l'application mobile
    print_info "Démarrage du serveur mobile sur le port $MOBILE_PORT..."
    
    nohup node server.js > "$MOBILE_LOG" 2>&1 &
    local mobile_pid=$!
    echo $mobile_pid > "$MOBILE_PID_FILE"
    
    print_info "Application mobile démarrée avec PID: $mobile_pid"
    print_info "Logs disponibles dans: $MOBILE_LOG"
    
    # Attendre que l'application soit prête
    print_info "Attente du démarrage de l'application mobile..."
    for i in {1..30}; do
        if curl -s --connect-timeout 2 "http://localhost:$MOBILE_PORT" > /dev/null 2>&1; then
            print_status "Application mobile prête sur http://localhost:$MOBILE_PORT"
            cd "$SCRIPT_DIR"
            return 0
        fi
        
        # Vérifier si le processus est toujours en cours
        if ! kill -0 $mobile_pid 2>/dev/null; then
            print_error "Le processus de l'application mobile s'est arrêté"
            print_info "Vérifiez les logs: tail -f $MOBILE_LOG"
            cd "$SCRIPT_DIR"
            return 1
        fi
        
        sleep 2
    done
    
    print_error "Application mobile non accessible après 1 minute"
    print_info "Vérifiez les logs: tail -f $MOBILE_LOG"
    cd "$SCRIPT_DIR"
    return 1
}

# ========================================
# FONCTIONS DE TEST
# ========================================

test_services() {
    print_header "TEST DES SERVICES"
    
    # Test Odoo
    print_info "Test de l'accès à Odoo..."
    if curl -s "http://localhost:$ODOO_PORT" > /dev/null; then
        print_status "✅ Odoo accessible sur http://localhost:$ODOO_PORT"
    else
        print_error "❌ Odoo non accessible"
    fi
    
    # Test application mobile
    print_info "Test de l'application mobile..."
    if curl -s "http://localhost:$MOBILE_PORT" > /dev/null; then
        print_status "✅ Application mobile accessible sur http://localhost:$MOBILE_PORT"
    else
        print_error "❌ Application mobile non accessible"
    fi
    
    # Test de la base de données
    print_info "Test de la connexion à la base de données..."
    if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        print_status "✅ Base de données accessible"
    else
        print_error "❌ Base de données non accessible"
    fi
}

# ========================================
# FONCTIONS D'ARRÊT
# ========================================

stop_services() {
    print_header "ARRÊT DES SERVICES"
    
    local services_stopped=0
    
    # Arrêter l'application mobile
    if [ -f "$MOBILE_PID_FILE" ]; then
        local mobile_pid=$(cat "$MOBILE_PID_FILE")
        if kill -0 $mobile_pid 2>/dev/null; then
            print_info "Arrêt de l'application mobile (PID: $mobile_pid)..."
            kill $mobile_pid
            sleep 2
            
            # Forcer l'arrêt si nécessaire
            if kill -0 $mobile_pid 2>/dev/null; then
                kill -9 $mobile_pid 2>/dev/null
            fi
            
            rm -f "$MOBILE_PID_FILE"
            print_status "Application mobile arrêtée"
            services_stopped=$((services_stopped + 1))
        fi
    fi
    
    # Arrêter Odoo
    if [ -f "$ODOO_PID_FILE" ]; then
        local odoo_pid=$(cat "$ODOO_PID_FILE")
        if kill -0 $odoo_pid 2>/dev/null; then
            print_info "Arrêt d'Odoo (PID: $odoo_pid)..."
            kill $odoo_pid
            sleep 3
            
            # Forcer l'arrêt si nécessaire
            if kill -0 $odoo_pid 2>/dev/null; then
                kill -9 $odoo_pid 2>/dev/null
            fi
            
            rm -f "$ODOO_PID_FILE"
            print_status "Odoo arrêté"
            services_stopped=$((services_stopped + 1))
        fi
    fi
    
    # Arrêter les processus restants
    pkill -f "node.*server.js" 2>/dev/null || true
    
    if [ $services_stopped -gt 0 ]; then
        print_success "✅ $services_stopped service(s) arrêté(s) avec succès"
    else
        print_info "ℹ️ Aucun service en cours d'exécution"
    fi
    
    return 0
}

cleanup_on_exit() {
    echo ""
    print_warning "Signal d'arrêt reçu, nettoyage en cours..."
    stop_services
    exit 0
}

# ========================================
# FONCTIONS D'AFFICHAGE
# ========================================

show_final_info() {
    echo ""
    print_header "🎉 SAMA CONAI STACK DÉMARRÉ AVEC SUCCÈS !"
    echo ""
    
    echo -e "${GREEN}${BOLD}🌐 ACCÈS AUX SERVICES:${NC}"
    echo -e "${WHITE}   📊 Interface Odoo:${NC} ${CYAN}http://localhost:$ODOO_PORT${NC}"
    echo -e "${WHITE}   📱 Application Mobile:${NC} ${CYAN}http://localhost:$MOBILE_PORT${NC}"
    echo -e "${WHITE}   🗄️ Base de données:${NC} ${CYAN}$DB_NAME${NC} (PostgreSQL:$POSTGRES_PORT)"
    echo ""
    
    echo -e "${GREEN}${BOLD}🔑 COMPTES DE CONNEXION:${NC}"
    echo -e "${WHITE}   👑 Administrateur Odoo:${NC} admin / admin"
    echo -e "${WHITE}   📱 Application Mobile:${NC} admin / admin"
    echo -e "${WHITE}   📱 Compte de démonstration:${NC} demo@sama-conai.sn / demo123"
    echo ""
    
    echo -e "${GREEN}${BOLD}📊 SERVICES ACTIFS:${NC}"
    if [ -f "$ODOO_PID_FILE" ]; then
        echo -e "${WHITE}   🔧 Odoo:${NC} PID $(cat $ODOO_PID_FILE) - Port $ODOO_PORT"
    fi
    if [ -f "$MOBILE_PID_FILE" ]; then
        echo -e "${WHITE}   📱 Mobile:${NC} PID $(cat $MOBILE_PID_FILE) - Port $MOBILE_PORT"
    fi
    echo -e "${WHITE}   🗄️ PostgreSQL:${NC} Port $POSTGRES_PORT"
    echo ""
    
    echo -e "${GREEN}${BOLD}📁 LOGS:${NC}"
    echo -e "${WHITE}   📋 Logs Odoo:${NC} $ODOO_LOG"
    echo -e "${WHITE}   📋 Logs Mobile:${NC} $MOBILE_LOG"
    echo ""
    
    echo -e "${GREEN}${BOLD}🛠️ COMMANDES UTILES:${NC}"
    echo -e "${WHITE}   🔄 Redémarrer:${NC} $0 restart"
    echo -e "${WHITE}   🛑 Arrêter:${NC} $0 stop"
    echo -e "${WHITE}   📊 Statut:${NC} $0 status"
    echo -e "${WHITE}   📋 Logs Odoo:${NC} tail -f $ODOO_LOG"
    echo -e "${WHITE}   📋 Logs Mobile:${NC} tail -f $MOBILE_LOG"
    echo ""
    
    print_success "💡 ${WHITE}Ouvrez http://localhost:$MOBILE_PORT dans votre navigateur${NC}"
    print_success "🇸🇳 ${WHITE}Plateforme de transparence du Sénégal opérationnelle !${NC}"
    echo ""
}

show_status() {
    print_header "STATUT DES SERVICES SAMA CONAI"
    
    # Statut Odoo
    if [ -f "$ODOO_PID_FILE" ] && kill -0 $(cat "$ODOO_PID_FILE") 2>/dev/null; then
        print_status "Odoo: EN COURS (PID: $(cat $ODOO_PID_FILE), Port: $ODOO_PORT)"
    else
        print_error "Odoo: ARRÊTÉ"
    fi
    
    # Statut application mobile
    if [ -f "$MOBILE_PID_FILE" ] && kill -0 $(cat "$MOBILE_PID_FILE") 2>/dev/null; then
        print_status "Application Mobile: EN COURS (PID: $(cat $MOBILE_PID_FILE), Port: $MOBILE_PORT)"
    else
        print_error "Application Mobile: ARRÊTÉE"
    fi
    
    # Statut PostgreSQL
    if pgrep -x "postgres" > /dev/null; then
        print_status "PostgreSQL: EN COURS (Port: $POSTGRES_PORT)"
    else
        print_error "PostgreSQL: ARRÊTÉ"
    fi
    
    echo ""
}

show_logs() {
    print_header "AFFICHAGE DES LOGS RÉCENTS"
    
    if [ -f "$ODOO_LOG" ]; then
        echo -e "${CYAN}${BOLD}=== LOGS ODOO (20 dernières lignes) ===${NC}"
        tail -n 20 "$ODOO_LOG"
        echo ""
    fi
    
    if [ -f "$MOBILE_LOG" ]; then
        echo -e "${CYAN}${BOLD}=== LOGS MOBILE (20 dernières lignes) ===${NC}"
        tail -n 20 "$MOBILE_LOG"
        echo ""
    fi
}

show_help() {
    print_banner
    echo -e "${CYAN}${BOLD}USAGE:${NC} $0 [COMMAND]"
    echo ""
    echo -e "${CYAN}${BOLD}COMMANDS:${NC}"
    echo -e "${WHITE}  start${NC}     Démarrer tous les services (défaut)"
    echo -e "${WHITE}  stop${NC}      Arrêter tous les services"
    echo -e "${WHITE}  restart${NC}   Redémarrer tous les services"
    echo -e "${WHITE}  status${NC}    Afficher le statut des services"
    echo -e "${WHITE}  logs${NC}      Afficher les logs récents"
    echo -e "${WHITE}  test${NC}      Tester la connectivité des services"
    echo -e "${WHITE}  help${NC}      Afficher cette aide"
    echo ""
    echo -e "${CYAN}${BOLD}CONFIGURATION ACTUELLE:${NC}"
    echo -e "${WHITE}  Odoo:${NC} $ODOO_PATH (Port: $ODOO_PORT)"
    echo -e "${WHITE}  Mobile:${NC} $SCRIPT_DIR/mobile_app_web (Port: $MOBILE_PORT)"
    echo -e "${WHITE}  Base de données:${NC} $DB_NAME"
    echo -e "${WHITE}  Environnement virtuel:${NC} $VENV_DIR"
    echo ""
}

# ========================================
# FONCTION PRINCIPALE
# ========================================

main() {
    local action="${1:-start}"
    
    case "$action" in
        "start")
            print_banner
            check_prerequisites || exit 1
            check_environment || exit 1
            check_ports || exit 1
            start_postgresql || exit 1
            setup_database || exit 1
            start_odoo || exit 1
            start_mobile_app || exit 1
            test_services
            show_final_info
            
            # Garder le script actif
            print_info "Appuyez sur Ctrl+C pour arrêter tous les services"
            trap cleanup_on_exit INT TERM
            wait
            ;;
        "stop")
            print_banner
            stop_services
            ;;
        "restart")
            print_banner
            stop_services
            sleep 3
            exec "$0" start
            ;;
        "status")
            print_banner
            show_status
            ;;
        "logs")
            print_banner
            show_logs
            ;;
        "test")
            print_banner
            test_services
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Commande inconnue: $action"
            echo ""
            echo "Utilisez '$0 help' pour voir les commandes disponibles"
            exit 1
            ;;
    esac
}

# ========================================
# VÉRIFICATIONS ET EXÉCUTION
# ========================================

# Vérifier que le script est exécuté depuis le bon répertoire
if [ ! -f "$SCRIPT_DIR/__manifest__.py" ]; then
    print_error "Ce script doit être exécuté depuis le répertoire du module SAMA CONAI"
    exit 1
fi

# Créer les répertoires nécessaires
mkdir -p "$PIDS_DIR" "$LOGS_DIR"

# Exécuter la fonction principale
main "$@"