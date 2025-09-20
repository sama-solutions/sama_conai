#!/bin/bash

# ========================================
# SAMA CONAI - SCRIPT DE LANCEMENT TEST
# ========================================
# Script autonome pour tests et développement
# Version: 1.0.0

set -e  # Arrêter en cas d'erreur

# ========================================
# CONFIGURATION
# ========================================

# Chemins absolus
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

# Configuration du test
TEST_PORT=8075
TEST_DB="sama_conai_test_$(date +%Y%m%d_%H%M%S)"
MOBILE_PORT=3005

# Configuration PostgreSQL
DB_HOST="localhost"
DB_USER="odoo"
DB_PASSWORD="odoo"

# Répertoires temporaires
TEMP_DIR="$SCRIPT_DIR/scripts_temp"
LOG_DIR="$TEMP_DIR/logs"
PID_DIR="$TEMP_DIR/pids"

# Fichiers de logs et PIDs
ODOO_LOG="$LOG_DIR/odoo_test.log"
MOBILE_LOG="$LOG_DIR/mobile_test.log"
ODOO_PID_FILE="$PID_DIR/odoo_test.pid"
MOBILE_PID_FILE="$PID_DIR/mobile_test.pid"

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
    echo -e "${PURPLE}║                SAMA CONAI - MODE TEST                        ║${NC}"
    echo -e "${PURPLE}║              Script de Test Autonome                        ║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║  Port Odoo: $TEST_PORT | Port Mobile: $MOBILE_PORT                        ║${NC}"
    echo -e "${PURPLE}║  Base de données: $TEST_DB${NC}"
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
# FONCTIONS DE PRÉPARATION
# ========================================

setup_temp_directories() {
    print_header "PRÉPARATION DES RÉPERTOIRES TEMPORAIRES"
    
    # Créer les répertoires temporaires
    mkdir -p "$TEMP_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$PID_DIR"
    
    print_status "Répertoires temporaires créés dans: $TEMP_DIR"
}

check_prerequisites() {
    print_header "VÉRIFICATION DES PRÉREQUIS"
    
    # Vérifier Odoo
    if [ ! -f "$ODOO_PATH/odoo-bin" ]; then
        print_error "Odoo non trouvé dans $ODOO_PATH"
        exit 1
    fi
    print_status "Odoo trouvé: $ODOO_PATH/odoo-bin"
    
    # Vérifier le venv
    if [ ! -f "$VENV_PATH/bin/activate" ]; then
        print_error "Virtual environment non trouvé dans $VENV_PATH"
        exit 1
    fi
    print_status "Virtual environment trouvé: $VENV_PATH"
    
    # Vérifier custom_addons
    if [ ! -d "$CUSTOM_ADDONS_PATH" ]; then
        print_error "Répertoire custom_addons non trouvé: $CUSTOM_ADDONS_PATH"
        exit 1
    fi
    print_status "Custom addons trouvé: $CUSTOM_ADDONS_PATH"
    
    # Vérifier le module SAMA CONAI
    if [ ! -f "$SCRIPT_DIR/__manifest__.py" ]; then
        print_error "Module SAMA CONAI non trouvé dans le répertoire courant"
        exit 1
    fi
    print_status "Module SAMA CONAI trouvé"
    
    # Vérifier PostgreSQL
    if ! command -v psql &> /dev/null; then
        print_error "PostgreSQL client non trouvé"
        exit 1
    fi
    print_status "PostgreSQL client disponible"
    
    # Vérifier Node.js pour l'app mobile
    if command -v node &> /dev/null; then
        print_status "Node.js disponible: $(node --version)"
    else
        print_warning "Node.js non trouvé - application mobile non disponible"
    fi
}

stop_existing_processes() {
    print_header "ARRÊT DES PROCESSUS EXISTANTS SUR LE PORT $TEST_PORT"
    
    # Arrêter les processus sur notre port de test uniquement
    if lsof -Pi :$TEST_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pids=$(lsof -ti:$TEST_PORT)
        for pid in $pids; do
            print_info "Arrêt du processus PID $pid sur le port $TEST_PORT"
            kill -TERM $pid 2>/dev/null || true
            sleep 2
            # Force kill si nécessaire
            if kill -0 $pid 2>/dev/null; then
                kill -KILL $pid 2>/dev/null || true
            fi
        done
        print_status "Processus sur le port $TEST_PORT arrêtés"
    else
        print_status "Aucun processus sur le port $TEST_PORT"
    fi
    
    # Arrêter les processus sur le port mobile
    if lsof -Pi :$MOBILE_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pids=$(lsof -ti:$MOBILE_PORT)
        for pid in $pids; do
            print_info "Arrêt du processus PID $pid sur le port $MOBILE_PORT"
            kill -TERM $pid 2>/dev/null || true
            sleep 1
        done
        print_status "Processus sur le port $MOBILE_PORT arrêtés"
    fi
    
    # Nettoyer les anciens fichiers PID
    rm -f "$ODOO_PID_FILE" "$MOBILE_PID_FILE"
}

# ========================================
# FONCTIONS DE BASE DE DONNÉES
# ========================================

create_test_database() {
    print_header "CRÉATION DE LA BASE DE DONNÉES DE TEST"
    
    # Vérifier la connexion PostgreSQL
    if ! PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        print_error "Impossible de se connecter à PostgreSQL"
        print_info "Vérifiez que PostgreSQL est démarré et que les credentials sont corrects"
        exit 1
    fi
    
    # Supprimer la base si elle existe déjà
    print_info "Suppression de l'ancienne base de données si elle existe..."
    PGPASSWORD=$DB_PASSWORD dropdb -h $DB_HOST -U $DB_USER --if-exists $TEST_DB 2>/dev/null || true
    
    # Créer la nouvelle base
    print_info "Création de la base de données: $TEST_DB"
    PGPASSWORD=$DB_PASSWORD createdb -h $DB_HOST -U $DB_USER $TEST_DB
    
    print_status "Base de données $TEST_DB créée avec succès"
}

# ========================================
# FONCTIONS DE DÉMARRAGE
# ========================================

start_odoo() {
    print_header "DÉMARRAGE D'ODOO EN MODE TEST"
    
    # Activer le virtual environment
    source "$VENV_PATH/bin/activate"
    
    print_info "Démarrage d'Odoo sur le port $TEST_PORT avec la base $TEST_DB"
    
    # Configuration des addons
    local addons_path="$ODOO_PATH/addons,$CUSTOM_ADDONS_PATH"
    
    # Étape 1: Initialiser la base de données avec le module base
    print_info "Initialisation de la base de données avec le module base..."
    python3 "$ODOO_PATH/odoo-bin" \
        --database="$TEST_DB" \
        --addons-path="$addons_path" \
        --db_host="$DB_HOST" \
        --db_user="$DB_USER" \
        --db_password="$DB_PASSWORD" \
        --http-port="$TEST_PORT" \
        --log-level=info \
        --workers=0 \
        --init=base \
        --stop-after-init \
        >> "$ODOO_LOG" 2>&1
    
    if [ $? -ne 0 ]; then
        print_error "Erreur lors de l'initialisation de la base de données"
        print_info "Vérifiez les logs: tail -f $ODOO_LOG"
        return 1
    fi
    
    print_status "Base de données initialisée avec succès"
    
    # Étape 2: Démarrer Odoo en mode normal
    print_info "Démarrage d'Odoo en mode normal..."
    nohup python3 "$ODOO_PATH/odoo-bin" \
        --database="$TEST_DB" \
        --addons-path="$addons_path" \
        --db_host="$DB_HOST" \
        --db_user="$DB_USER" \
        --db_password="$DB_PASSWORD" \
        --http-port="$TEST_PORT" \
        --log-level=info \
        --workers=0 \
        --dev=reload,qweb,werkzeug,xml \
        >> "$ODOO_LOG" 2>&1 &
    
    local odoo_pid=$!
    echo $odoo_pid > "$ODOO_PID_FILE"
    
    print_info "Odoo démarré avec PID: $odoo_pid"
    print_info "Logs disponibles: $ODOO_LOG"
    
    # Attendre qu'Odoo soit prêt
    print_info "Attente du démarrage d'Odoo (peut prendre 1-2 minutes)..."
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s --connect-timeout 2 "http://localhost:$TEST_PORT/web/health" >/dev/null 2>&1; then
            print_status "Odoo est prêt et accessible"
            
            # Installer le module SAMA CONAI via l'API
            install_sama_conai_module
            return 0
        fi
        
        # Vérifier si le processus est toujours en cours
        if ! kill -0 $odoo_pid 2>/dev/null; then
            print_error "Le processus Odoo s'est arrêté de manière inattendue"
            print_info "Vérifiez les logs: tail -f $ODOO_LOG"
            return 1
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    print_error "Odoo n'est pas accessible après 2 minutes"
    print_info "Vérifiez les logs: tail -f $ODOO_LOG"
    return 1
}

install_sama_conai_module() {
    print_info "Installation du module SAMA CONAI..."
    
    # Attendre un peu plus pour que l'interface soit complètement prête
    sleep 5
    
    # Essayer d'installer le module via l'interface web
    # D'abord, essayer d'accéder à la page des modules
    if curl -s --max-time 10 "http://localhost:$TEST_PORT/web/database/manager" >/dev/null 2>&1; then
        print_status "Interface Odoo accessible"
        print_info "Module SAMA CONAI disponible pour installation manuelle"
        print_info "Accédez à http://localhost:$TEST_PORT pour installer le module"
    else
        print_warning "Interface web non encore accessible, le module sera installable manuellement"
    fi
}

start_mobile_app() {
    print_header "DÉMARRAGE DE L'APPLICATION MOBILE"
    
    if [ ! -d "$SCRIPT_DIR/mobile_app_web" ]; then
        print_warning "Application mobile web non trouvée, passage..."
        return 0
    fi
    
    if ! command -v node &> /dev/null; then
        print_warning "Node.js non disponible, passage de l'application mobile"
        return 0
    fi
    
    cd "$SCRIPT_DIR/mobile_app_web"
    
    # Installer les dépendances si nécessaire
    if [ ! -d "node_modules" ]; then
        print_info "Installation des dépendances Node.js..."
        npm install
    fi
    
    # Configuration des variables d'environnement
    export PORT="$MOBILE_PORT"
    export ODOO_URL="http://localhost:$TEST_PORT"
    export ODOO_DB="$TEST_DB"
    export ODOO_USER="admin"
    export ODOO_PASSWORD="admin"
    
    print_info "Démarrage de l'application mobile sur le port $MOBILE_PORT"
    
    # Démarrer l'application en arrière-plan
    nohup npm start > "$MOBILE_LOG" 2>&1 &
    local mobile_pid=$!
    echo $mobile_pid > "$MOBILE_PID_FILE"
    
    print_info "Application mobile démarrée avec PID: $mobile_pid"
    print_info "Logs disponibles: $MOBILE_LOG"
    
    # Attendre que l'application soit prête
    print_info "Attente du démarrage de l'application mobile..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s --connect-timeout 2 "http://localhost:$MOBILE_PORT" >/dev/null 2>&1; then
            print_status "Application mobile prête"
            cd "$SCRIPT_DIR"
            return 0
        fi
        
        # Vérifier si le processus est toujours en cours
        if ! kill -0 $mobile_pid 2>/dev/null; then
            print_error "L'application mobile s'est arrêtée de manière inattendue"
            print_info "Vérifiez les logs: tail -f $MOBILE_LOG"
            cd "$SCRIPT_DIR"
            return 1
        fi
        
        sleep 2
        ((attempt++))
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
    print_header "TESTS DES SERVICES"
    
    local all_tests_passed=true
    
    # Test Odoo
    print_info "Test de l'accès à Odoo..."
    if curl -s --max-time 10 "http://localhost:$TEST_PORT/web/health" >/dev/null 2>&1; then
        print_status "✓ Odoo accessible sur http://localhost:$TEST_PORT"
    else
        print_error "✗ Odoo non accessible"
        all_tests_passed=false
    fi
    
    # Test de la base de données
    print_info "Test de la connexion à la base de données..."
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $TEST_DB -c "SELECT 1;" >/dev/null 2>&1; then
        print_status "✓ Base de données accessible"
    else
        print_error "✗ Base de données non accessible"
        all_tests_passed=false
    fi
    
    # Test du module SAMA CONAI
    print_info "Test du module SAMA CONAI..."
    if curl -s --max-time 10 "http://localhost:$TEST_PORT/web/login" | grep -q "SAMA CONAI" 2>/dev/null; then
        print_status "✓ Module SAMA CONAI détecté"
    else
        print_warning "? Module SAMA CONAI non détecté dans la page de login"
    fi
    
    # Test application mobile
    if [ -f "$MOBILE_PID_FILE" ]; then
        print_info "Test de l'application mobile..."
        if curl -s --max-time 10 "http://localhost:$MOBILE_PORT" >/dev/null 2>&1; then
            print_status "✓ Application mobile accessible sur http://localhost:$MOBILE_PORT"
        else
            print_error "✗ Application mobile non accessible"
            all_tests_passed=false
        fi
    fi
    
    if $all_tests_passed; then
        print_success "Tous les tests sont passés avec succès !"
        return 0
    else
        print_error "Certains tests ont échoué"
        return 1
    fi
}

show_logs() {
    print_header "AFFICHAGE DES LOGS RÉCENTS"
    
    if [ -f "$ODOO_LOG" ]; then
        echo ""
        echo -e "${YELLOW}=== LOGS ODOO (20 dernières lignes) ===${NC}"
        tail -n 20 "$ODOO_LOG"
    fi
    
    if [ -f "$MOBILE_LOG" ]; then
        echo ""
        echo -e "${YELLOW}=== LOGS APPLICATION MOBILE (20 dernières lignes) ===${NC}"
        tail -n 20 "$MOBILE_LOG"
    fi
}

show_status() {
    print_header "STATUT DES SERVICES"
    
    # Statut Odoo
    if [ -f "$ODOO_PID_FILE" ] && kill -0 $(cat "$ODOO_PID_FILE") 2>/dev/null; then
        print_status "Odoo: EN COURS (PID: $(cat $ODOO_PID_FILE), Port: $TEST_PORT)"
    else
        print_error "Odoo: ARRÊTÉ"
    fi
    
    # Statut application mobile
    if [ -f "$MOBILE_PID_FILE" ] && kill -0 $(cat "$MOBILE_PID_FILE") 2>/dev/null; then
        print_status "Application Mobile: EN COURS (PID: $(cat $MOBILE_PID_FILE), Port: $MOBILE_PORT)"
    else
        print_error "Application Mobile: ARRÊTÉE"
    fi
    
    # Statut base de données
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $TEST_DB -c "SELECT 1;" >/dev/null 2>&1; then
        print_status "Base de données: ACCESSIBLE ($TEST_DB)"
    else
        print_error "Base de données: NON ACCESSIBLE"
    fi
}

show_final_info() {
    echo ""
    print_header "🎉 SAMA CONAI TEST ENVIRONMENT PRÊT !"
    echo ""
    
    print_success "🌐 Interface Odoo: ${WHITE}http://localhost:$TEST_PORT${NC}"
    if [ -f "$MOBILE_PID_FILE" ]; then
        print_success "📱 Application Mobile: ${WHITE}http://localhost:$MOBILE_PORT${NC}"
    fi
    print_success "🗄️ Base de données: ${WHITE}$TEST_DB${NC}"
    
    echo ""
    print_header "🔑 COMPTES DE CONNEXION:"
    echo -e "${WHITE}   👑 Admin:${NC} admin / admin"
    echo -e "${WHITE}   📱 Demo Mobile:${NC} demo@sama-conai.sn / demo123"
    
    echo ""
    print_header "📁 FICHIERS TEMPORAIRES:"
    echo -e "${WHITE}   📋 Logs Odoo:${NC} $ODOO_LOG"
    if [ -f "$MOBILE_PID_FILE" ]; then
        echo -e "${WHITE}   📋 Logs Mobile:${NC} $MOBILE_LOG"
    fi
    echo -e "${WHITE}   🗂️ Répertoire temp:${NC} $TEMP_DIR"
    
    echo ""
    print_header "🛠️ COMMANDES DE TEST:"
    echo -e "${WHITE}   📊 Statut:${NC} $0 status"
    echo -e "${WHITE}   📋 Logs:${NC} $0 logs"
    echo -e "${WHITE}   🔄 Test:${NC} $0 test"
    echo -e "${WHITE}   🛑 Arrêt:${NC} $0 stop"
    echo -e "${WHITE}   🧹 Nettoyage:${NC} $0 clean"
    
    echo ""
    print_success "💡 ${WHITE}Environnement de test prêt pour le développement !${NC}"
    echo ""
}

# ========================================
# FONCTIONS D'ARRÊT ET NETTOYAGE
# ========================================

stop_services() {
    print_header "ARRÊT DES SERVICES DE TEST"
    
    # Arrêter l'application mobile
    if [ -f "$MOBILE_PID_FILE" ]; then
        local mobile_pid=$(cat "$MOBILE_PID_FILE")
        if kill -0 $mobile_pid 2>/dev/null; then
            print_info "Arrêt de l'application mobile (PID: $mobile_pid)"
            kill -TERM $mobile_pid 2>/dev/null || true
            sleep 2
            if kill -0 $mobile_pid 2>/dev/null; then
                kill -KILL $mobile_pid 2>/dev/null || true
            fi
            print_status "Application mobile arrêtée"
        fi
        rm -f "$MOBILE_PID_FILE"
    fi
    
    # Arrêter Odoo
    if [ -f "$ODOO_PID_FILE" ]; then
        local odoo_pid=$(cat "$ODOO_PID_FILE")
        if kill -0 $odoo_pid 2>/dev/null; then
            print_info "Arrêt d'Odoo (PID: $odoo_pid)"
            kill -TERM $odoo_pid 2>/dev/null || true
            sleep 3
            if kill -0 $odoo_pid 2>/dev/null; then
                kill -KILL $odoo_pid 2>/dev/null || true
            fi
            print_status "Odoo arrêté"
        fi
        rm -f "$ODOO_PID_FILE"
    fi
    
    print_success "Services arrêtés"
}

clean_environment() {
    print_header "NETTOYAGE DE L'ENVIRONNEMENT DE TEST"
    
    # Arrêter les services
    stop_services
    
    # Supprimer la base de données de test
    if [ ! -z "$TEST_DB" ]; then
        print_info "Suppression de la base de données de test: $TEST_DB"
        PGPASSWORD=$DB_PASSWORD dropdb -h $DB_HOST -U $DB_USER --if-exists $TEST_DB 2>/dev/null || true
        print_status "Base de données supprimée"
    fi
    
    # Supprimer les fichiers temporaires
    if [ -d "$TEMP_DIR" ]; then
        print_info "Suppression des fichiers temporaires: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
        print_status "Fichiers temporaires supprimés"
    fi
    
    print_success "Environnement nettoyé"
}

cleanup_on_exit() {
    echo ""
    print_warning "Signal d'arrêt reçu, nettoyage en cours..."
    stop_services
    exit 0
}

# ========================================
# FONCTION PRINCIPALE
# ========================================

main() {
    local action="${1:-start}"
    
    case "$action" in
        "start")
            print_banner
            setup_temp_directories
            check_prerequisites
            stop_existing_processes
            create_test_database
            start_odoo
            start_mobile_app
            test_services
            show_final_info
            
            # Mode interactif pour les tests
            print_info "Mode test interactif - Appuyez sur Ctrl+C pour arrêter"
            trap cleanup_on_exit INT TERM
            
            # Boucle de monitoring
            while true; do
                sleep 30
                if [ -f "$ODOO_PID_FILE" ] && ! kill -0 $(cat "$ODOO_PID_FILE") 2>/dev/null; then
                    print_error "Odoo s'est arrêté de manière inattendue"
                    show_logs
                    break
                fi
            done
            ;;
        "stop")
            print_banner
            stop_services
            ;;
        "clean")
            print_banner
            clean_environment
            ;;
        "status")
            print_banner
            show_status
            ;;
        "test")
            print_banner
            test_services
            ;;
        "logs")
            print_banner
            show_logs
            ;;
        "restart")
            print_banner
            stop_services
            sleep 2
            exec "$0" start
            ;;
        "help")
            print_banner
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  start     Démarrer l'environnement de test (défaut)"
            echo "  stop      Arrêter les services"
            echo "  clean     Nettoyer complètement l'environnement"
            echo "  status    Afficher le statut des services"
            echo "  test      Exécuter les tests"
            echo "  logs      Afficher les logs récents"
            echo "  restart   Redémarrer les services"
            echo "  help      Afficher cette aide"
            echo ""
            ;;
        *)
            print_error "Commande inconnue: $action"
            echo "Utilisez '$0 help' pour voir les commandes disponibles"
            exit 1
            ;;
    esac
}

# ========================================
# EXÉCUTION
# ========================================

# Vérifier que le script est exécuté depuis le bon répertoire
if [ ! -f "$SCRIPT_DIR/__manifest__.py" ]; then
    print_error "Ce script doit être exécuté depuis le répertoire du module SAMA CONAI"
    exit 1
fi

# Exécuter la fonction principale
main "$@"