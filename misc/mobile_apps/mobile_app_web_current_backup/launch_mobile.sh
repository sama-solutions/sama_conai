#!/bin/bash

# ========================================
# SAMA CONAI - SCRIPT APPLICATION MOBILE
# ========================================
# Script autonome pour l'application mobile web
# Version: 1.0.0

set -e

# ========================================
# CONFIGURATION
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_PORT="${PORT:-3005}"
ODOO_URL="${ODOO_URL:-http://localhost:8077}"
ODOO_DB="${ODOO_DB:-sama_conai_analytics}"

# Répertoires temporaires
TEMP_DIR="$SCRIPT_DIR/../scripts_temp"
LOG_DIR="$TEMP_DIR/logs"
PID_DIR="$TEMP_DIR/pids"

# Fichiers
MOBILE_LOG="$LOG_DIR/mobile_standalone.log"
MOBILE_PID_FILE="$PID_DIR/mobile_standalone.pid"

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
    echo -e "${PURPLE}║              SAMA CONAI - APPLICATION MOBILE                 ║${NC}"
    echo -e "${PURPLE}║                  Mode Standalone                             ║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║  Port: $MOBILE_PORT | Backend: $ODOO_URL${NC}"
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
# FONCTIONS PRINCIPALES
# ========================================

setup_directories() {
    print_header "PRÉPARATION DE L'ENVIRONNEMENT"
    
    mkdir -p "$TEMP_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$PID_DIR"
    
    print_status "Répertoires créés"
}

check_prerequisites() {
    print_header "VÉRIFICATION DES PRÉREQUIS"
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js non trouvé"
        exit 1
    fi
    print_status "Node.js: $(node --version)"
    
    # Vérifier npm
    if ! command -v npm &> /dev/null; then
        print_error "npm non trouvé"
        exit 1
    fi
    print_status "npm: $(npm --version)"
    
    # Vérifier les fichiers de l'application
    if [ ! -f "$SCRIPT_DIR/package.json" ]; then
        print_error "package.json non trouvé"
        exit 1
    fi
    print_status "Application mobile trouvée"
}

stop_existing_mobile() {
    print_header "ARRÊT DES PROCESSUS EXISTANTS"
    
    # Arrêter les processus sur le port mobile
    if lsof -Pi :$MOBILE_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pids=$(lsof -ti:$MOBILE_PORT)
        for pid in $pids; do
            print_info "Arrêt du processus PID $pid sur le port $MOBILE_PORT"
            kill -TERM $pid 2>/dev/null || true
            sleep 2
            if kill -0 $pid 2>/dev/null; then
                kill -KILL $pid 2>/dev/null || true
            fi
        done
        print_status "Processus arrêtés"
    else
        print_status "Aucun processus sur le port $MOBILE_PORT"
    fi
    
    # Nettoyer l'ancien fichier PID
    rm -f "$MOBILE_PID_FILE"
}

install_dependencies() {
    print_header "INSTALLATION DES DÉPENDANCES"
    
    cd "$SCRIPT_DIR"
    
    if [ ! -d "node_modules" ] || [ "package.json" -nt "node_modules" ]; then
        print_info "Installation des dépendances npm..."
        npm install
        print_status "Dépendances installées"
    else
        print_status "Dépendances déjà à jour"
    fi
}

start_mobile() {
    print_header "DÉMARRAGE DE L'APPLICATION MOBILE"
    
    cd "$SCRIPT_DIR"
    
    # Configuration des variables d'environnement
    export PORT="$MOBILE_PORT"
    export ODOO_URL="$ODOO_URL"
    export ODOO_DB="$ODOO_DB"
    export ODOO_USER="admin"
    export ODOO_PASSWORD="admin"
    export NODE_ENV="development"
    
    print_info "Configuration:"
    print_info "  Port: $MOBILE_PORT"
    print_info "  Backend Odoo: $ODOO_URL"
    print_info "  Base de données: $ODOO_DB"
    
    # Démarrer l'application avec les bonnes variables d'environnement
    print_info "Démarrage de l'application mobile..."
    ODOO_URL="$ODOO_URL" ODOO_DB="$ODOO_DB" PORT="$MOBILE_PORT" npm start > "$MOBILE_LOG" 2>&1 &
    local mobile_pid=$!
    echo $mobile_pid > "$MOBILE_PID_FILE"
    
    print_info "Application démarrée avec PID: $mobile_pid"
    print_info "Logs: $MOBILE_LOG"
    
    # Attendre que l'application soit prête
    print_info "Attente du démarrage..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s --connect-timeout 2 "http://localhost:$MOBILE_PORT" >/dev/null 2>&1; then
            print_status "Application mobile prête !"
            return 0
        fi
        
        if ! kill -0 $mobile_pid 2>/dev/null; then
            print_error "L'application s'est arrêtée de manière inattendue"
            print_info "Vérifiez les logs: tail -f $MOBILE_LOG"
            return 1
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    print_error "Application non accessible après 1 minute"
    print_info "Vérifiez les logs: tail -f $MOBILE_LOG"
    return 1
}

test_mobile() {
    print_header "TESTS DE L'APPLICATION MOBILE"
    
    # Test de base
    print_info "Test de l'accès HTTP..."
    if curl -s --max-time 10 "http://localhost:$MOBILE_PORT" >/dev/null 2>&1; then
        print_status "✓ Application accessible"
    else
        print_error "✗ Application non accessible"
        return 1
    fi
    
    # Test de l'API
    print_info "Test de l'API mobile..."
    local api_response=$(curl -s --max-time 10 "http://localhost:$MOBILE_PORT/api/mobile/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"demo@sama-conai.sn","password":"demo123"}' 2>/dev/null)
    
    if echo "$api_response" | grep -q "success" 2>/dev/null; then
        print_status "✓ API mobile fonctionnelle"
    else
        print_warning "? API mobile non testable"
    fi
    
    # Test de connexion au backend Odoo
    print_info "Test de connexion au backend Odoo..."
    if curl -s --max-time 5 "$ODOO_URL" >/dev/null 2>&1; then
        print_status "✓ Backend Odoo accessible"
    else
        print_warning "? Backend Odoo non accessible - mode fallback"
    fi
    
    print_success "Tests terminés"
}

show_status() {
    print_header "STATUT DE L'APPLICATION MOBILE"
    
    if [ -f "$MOBILE_PID_FILE" ] && kill -0 $(cat "$MOBILE_PID_FILE") 2>/dev/null; then
        print_status "Application Mobile: EN COURS (PID: $(cat $MOBILE_PID_FILE), Port: $MOBILE_PORT)"
        
        # Test de connectivité
        if curl -s --connect-timeout 2 "http://localhost:$MOBILE_PORT" >/dev/null 2>&1; then
            print_status "Statut HTTP: ACCESSIBLE"
        else
            print_warning "Statut HTTP: NON ACCESSIBLE"
        fi
    else
        print_error "Application Mobile: ARRÊTÉE"
    fi
}

show_logs() {
    print_header "LOGS DE L'APPLICATION MOBILE"
    
    if [ -f "$MOBILE_LOG" ]; then
        echo ""
        echo -e "${YELLOW}=== LOGS APPLICATION MOBILE (30 dernières lignes) ===${NC}"
        tail -n 30 "$MOBILE_LOG"
    else
        print_warning "Aucun fichier de log trouvé"
    fi
}

stop_mobile() {
    print_header "ARRÊT DE L'APPLICATION MOBILE"
    
    if [ -f "$MOBILE_PID_FILE" ]; then
        local mobile_pid=$(cat "$MOBILE_PID_FILE")
        if kill -0 $mobile_pid 2>/dev/null; then
            print_info "Arrêt de l'application (PID: $mobile_pid)"
            kill -TERM $mobile_pid 2>/dev/null || true
            sleep 2
            if kill -0 $mobile_pid 2>/dev/null; then
                kill -KILL $mobile_pid 2>/dev/null || true
            fi
            print_status "Application arrêtée"
        fi
        rm -f "$MOBILE_PID_FILE"
    else
        print_warning "Aucun processus à arrêter"
    fi
}

show_final_info() {
    echo ""
    print_header "🎉 APPLICATION MOBILE SAMA CONAI PRÊTE !"
    echo ""
    
    print_success "📱 Application Mobile: ${WHITE}http://localhost:$MOBILE_PORT${NC}"
    print_success "🔗 Backend Odoo: ${WHITE}$ODOO_URL${NC}"
    print_success "🗄️ Base de données: ${WHITE}$ODOO_DB${NC}"
    
    echo ""
    print_header "🔑 COMPTES DE TEST:"
    echo -e "${WHITE}   📱 Demo:${NC} demo@sama-conai.sn / demo123"
    echo -e "${WHITE}   👑 Admin:${NC} admin / admin"
    
    echo ""
    print_header "📁 FICHIERS:"
    echo -e "${WHITE}   📋 Logs:${NC} $MOBILE_LOG"
    echo -e "${WHITE}   🔧 PID:${NC} $MOBILE_PID_FILE"
    
    echo ""
    print_header "🛠️ COMMANDES:"
    echo -e "${WHITE}   📊 Statut:${NC} $0 status"
    echo -e "${WHITE}   📋 Logs:${NC} $0 logs"
    echo -e "${WHITE}   🔄 Test:${NC} $0 test"
    echo -e "${WHITE}   🛑 Arrêt:${NC} $0 stop"
    
    echo ""
    print_success "💡 ${WHITE}Application mobile prête pour les tests !${NC}"
    echo ""
}

cleanup_on_exit() {
    echo ""
    print_warning "Signal d'arrêt reçu..."
    stop_mobile
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
            setup_directories
            check_prerequisites
            stop_existing_mobile
            install_dependencies
            start_mobile
            test_mobile
            show_final_info
            
            # Mode interactif
            print_info "Mode interactif - Appuyez sur Ctrl+C pour arrêter"
            trap cleanup_on_exit INT TERM
            
            # Monitoring
            while true; do
                sleep 30
                if [ -f "$MOBILE_PID_FILE" ] && ! kill -0 $(cat "$MOBILE_PID_FILE") 2>/dev/null; then
                    print_error "L'application s'est arrêtée de manière inattendue"
                    show_logs
                    break
                fi
            done
            ;;
        "stop")
            print_banner
            stop_mobile
            ;;
        "status")
            print_banner
            show_status
            ;;
        "test")
            print_banner
            test_mobile
            ;;
        "logs")
            print_banner
            show_logs
            ;;
        "restart")
            print_banner
            stop_mobile
            sleep 2
            exec "$0" start
            ;;
        "help")
            print_banner
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  start     Démarrer l'application mobile (défaut)"
            echo "  stop      Arrêter l'application"
            echo "  status    Afficher le statut"
            echo "  test      Exécuter les tests"
            echo "  logs      Afficher les logs"
            echo "  restart   Redémarrer l'application"
            echo "  help      Afficher cette aide"
            echo ""
            echo "Variables d'environnement:"
            echo "  PORT      Port de l'application (défaut: 3005)"
            echo "  ODOO_URL  URL du backend Odoo (défaut: http://localhost:8075)"
            echo "  ODOO_DB   Base de données Odoo (défaut: sama_conai_test)"
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

# Vérifier que le script est dans le bon répertoire
if [ ! -f "$SCRIPT_DIR/package.json" ]; then
    print_error "Ce script doit être exécuté depuis le répertoire mobile_app_web"
    exit 1
fi

# Exécuter la fonction principale
main "$@"