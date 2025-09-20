#!/bin/bash

# =============================================================================
# SAMA CONAI - Script de Démarrage Complet
# =============================================================================
# Ce script démarre Odoo et l'application mobile SAMA CONAI simultanément
# 
# Usage: ./startup_sama_conai.sh [start|stop|restart|status]
# =============================================================================

set -e  # Arrêter le script en cas d'erreur

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ODOO_PATH="/var/odoo/odoo18"
ADDONS_PATH="/home/grand-as/psagsn/custom_addons"
DB_NAME="sama_conai_analytics"
ODOO_PORT="8077"
MOBILE_PORT="3005"

# Fichiers de logs
LOG_DIR="$SCRIPT_DIR/logs"
ODOO_LOG="$LOG_DIR/odoo.log"
MOBILE_LOG="$LOG_DIR/mobile.log"
STARTUP_LOG="$LOG_DIR/startup.log"

# Fichiers PID
PID_DIR="$SCRIPT_DIR/pids"
ODOO_PID="$PID_DIR/odoo.pid"
MOBILE_PID="$PID_DIR/mobile.pid"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonctions utilitaires
log() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$STARTUP_LOG"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$STARTUP_LOG"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$STARTUP_LOG"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$STARTUP_LOG"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$STARTUP_LOG"
}

# Créer les répertoires nécessaires
create_directories() {
    mkdir -p "$LOG_DIR" "$PID_DIR"
}

# Vérifier les prérequis
check_prerequisites() {
    log "🔍 Vérification des prérequis..."
    
    # Vérifier que Python3 est installé
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 n'est pas installé"
        exit 1
    fi
    
    # Vérifier que Node.js est installé
    if ! command -v node &> /dev/null; then
        log_error "Node.js n'est pas installé"
        exit 1
    fi
    
    # Vérifier que le répertoire Odoo existe
    if [ ! -d "$ODOO_PATH" ]; then
        log_error "Répertoire Odoo non trouvé: $ODOO_PATH"
        exit 1
    fi
    
    # Vérifier que le répertoire des addons existe
    if [ ! -d "$ADDONS_PATH" ]; then
        log_error "Répertoire des addons non trouvé: $ADDONS_PATH"
        exit 1
    fi
    
    # Vérifier que le module SAMA CONAI existe
    if [ ! -d "$SCRIPT_DIR" ]; then
        log_error "Module SAMA CONAI non trouvé: $SCRIPT_DIR"
        exit 1
    fi
    
    # Vérifier que l'application mobile existe
    if [ ! -d "$SCRIPT_DIR/mobile_app_web" ]; then
        log_error "Application mobile non trouvée: $SCRIPT_DIR/mobile_app_web"
        exit 1
    fi
    
    log_success "Tous les prérequis sont satisfaits"
}

# Vérifier si un processus est en cours d'exécution
is_process_running() {
    local pid_file="$1"
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # Le processus est en cours d'exécution
        else
            rm -f "$pid_file"  # Nettoyer le fichier PID obsolète
            return 1  # Le processus n'est pas en cours d'exécution
        fi
    else
        return 1  # Pas de fichier PID
    fi
}

# Attendre qu'un port soit disponible
wait_for_port() {
    local port="$1"
    local service_name="$2"
    local max_attempts=30
    local attempt=1
    
    log "⏳ Attente que $service_name soit disponible sur le port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s --connect-timeout 2 "http://localhost:$port" > /dev/null 2>&1; then
            log_success "$service_name est maintenant disponible sur le port $port"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "$service_name n'est pas disponible après $((max_attempts * 2)) secondes"
    return 1
}

# Démarrer Odoo
start_odoo() {
    log "🚀 Démarrage d'Odoo..."
    
    if is_process_running "$ODOO_PID"; then
        log_warning "Odoo est déjà en cours d'exécution (PID: $(cat "$ODOO_PID"))"
        return 0
    fi
    
    # Commande de démarrage d'Odoo avec configuration iframe
    cd "$ODOO_PATH"
    nohup python3 odoo-bin \
        -c "$SCRIPT_DIR/odoo_iframe_config.conf" \
        -d "$DB_NAME" \
        --addons-path="$ODOO_PATH/addons,$ADDONS_PATH" \
        --http-port="$ODOO_PORT" \
        --log-level=info \
        --logfile="$ODOO_LOG" \
        --pidfile="$ODOO_PID" \
        > "$ODOO_LOG" 2>&1 &
    
    local odoo_pid=$!
    echo $odoo_pid > "$ODOO_PID"
    
    log_info "Odoo démarré avec le PID: $odoo_pid"
    log_info "Logs Odoo: $ODOO_LOG"
    
    # Attendre qu'Odoo soit prêt
    if wait_for_port "$ODOO_PORT" "Odoo"; then
        log_success "Odoo est opérationnel sur http://localhost:$ODOO_PORT"
        return 0
    else
        log_error "Échec du démarrage d'Odoo"
        return 1
    fi
}

# Démarrer l'application mobile
start_mobile() {
    log "📱 Démarrage de l'application mobile..."
    
    if is_process_running "$MOBILE_PID"; then
        log_warning "Application mobile déjà en cours d'exécution (PID: $(cat "$MOBILE_PID"))"
        return 0
    fi
    
    # Démarrer l'application mobile
    cd "$SCRIPT_DIR/mobile_app_web"
    nohup node server.js > "$MOBILE_LOG" 2>&1 &
    
    local mobile_pid=$!
    echo $mobile_pid > "$MOBILE_PID"
    
    log_info "Application mobile démarrée avec le PID: $mobile_pid"
    log_info "Logs mobile: $MOBILE_LOG"
    
    # Attendre que l'application mobile soit prête
    if wait_for_port "$MOBILE_PORT" "Application mobile"; then
        log_success "Application mobile opérationnelle sur http://localhost:$MOBILE_PORT"
        return 0
    else
        log_error "Échec du démarrage de l'application mobile"
        return 1
    fi
}

# Arrêter un processus
stop_process() {
    local pid_file="$1"
    local service_name="$2"
    
    if is_process_running "$pid_file"; then
        local pid=$(cat "$pid_file")
        log "🛑 Arrêt de $service_name (PID: $pid)..."
        
        # Essayer d'abord un arrêt propre
        kill -TERM "$pid" 2>/dev/null || true
        
        # Attendre jusqu'à 10 secondes pour un arrêt propre
        local count=0
        while [ $count -lt 10 ] && ps -p "$pid" > /dev/null 2>&1; do
            sleep 1
            count=$((count + 1))
        done
        
        # Si le processus est toujours en cours, forcer l'arrêt
        if ps -p "$pid" > /dev/null 2>&1; then
            log_warning "Arrêt forcé de $service_name..."
            kill -KILL "$pid" 2>/dev/null || true
        fi
        
        rm -f "$pid_file"
        log_success "$service_name arrêté"
    else
        log_info "$service_name n'était pas en cours d'exécution"
    fi
}

# Arrêter tous les services
stop_all() {
    log "🛑 Arrêt de tous les services SAMA CONAI..."
    
    stop_process "$MOBILE_PID" "Application mobile"
    stop_process "$ODOO_PID" "Odoo"
    
    log_success "Tous les services ont été arrêtés"
}

# Afficher le statut des services
show_status() {
    log "📊 Statut des services SAMA CONAI"
    echo "=================================="
    
    # Statut Odoo
    if is_process_running "$ODOO_PID"; then
        local odoo_pid=$(cat "$ODOO_PID")
        log_success "Odoo: En cours d'exécution (PID: $odoo_pid, Port: $ODOO_PORT)"
        
        # Tester la connectivité
        if curl -s --connect-timeout 2 "http://localhost:$ODOO_PORT/web/health" > /dev/null 2>&1; then
            log_success "  └─ Odoo répond correctement"
        else
            log_warning "  └─ Odoo ne répond pas sur le port $ODOO_PORT"
        fi
    else
        log_error "Odoo: Arrêté"
    fi
    
    # Statut Application mobile
    if is_process_running "$MOBILE_PID"; then
        local mobile_pid=$(cat "$MOBILE_PID")
        log_success "Application mobile: En cours d'exécution (PID: $mobile_pid, Port: $MOBILE_PORT)"
        
        # Tester la connectivité
        if curl -s --connect-timeout 2 "http://localhost:$MOBILE_PORT" > /dev/null 2>&1; then
            log_success "  └─ Application mobile répond correctement"
        else
            log_warning "  └─ Application mobile ne répond pas sur le port $MOBILE_PORT"
        fi
    else
        log_error "Application mobile: Arrêtée"
    fi
    
    echo ""
    log_info "URLs d'accès:"
    log_info "  • Odoo Backend: http://localhost:$ODOO_PORT"
    log_info "  • Application Mobile: http://localhost:$MOBILE_PORT"
    log_info "  • Base de données: $DB_NAME"
    
    echo ""
    log_info "Fichiers de logs:"
    log_info "  • Odoo: $ODOO_LOG"
    log_info "  • Mobile: $MOBILE_LOG"
    log_info "  • Startup: $STARTUP_LOG"
}

# Démarrer tous les services
start_all() {
    log "🚀 Démarrage complet de SAMA CONAI"
    echo "=================================="
    
    create_directories
    check_prerequisites
    
    # Démarrer Odoo en premier
    if start_odoo; then
        log_success "Odoo démarré avec succès"
    else
        log_error "Échec du démarrage d'Odoo"
        exit 1
    fi
    
    # Attendre un peu avant de démarrer l'application mobile
    sleep 3
    
    # Démarrer l'application mobile
    if start_mobile; then
        log_success "Application mobile démarrée avec succès"
    else
        log_error "Échec du démarrage de l'application mobile"
        stop_process "$ODOO_PID" "Odoo"  # Arrêter Odoo en cas d'échec
        exit 1
    fi
    
    echo ""
    log_success "🎉 SAMA CONAI est maintenant opérationnel !"
    echo ""
    show_status
}

# Redémarrer tous les services
restart_all() {
    log "🔄 Redémarrage de SAMA CONAI..."
    stop_all
    sleep 2
    start_all
}

# Afficher l'aide
show_help() {
    echo "SAMA CONAI - Script de Démarrage"
    echo "================================"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Démarrer Odoo et l'application mobile"
    echo "  stop      Arrêter tous les services"
    echo "  restart   Redémarrer tous les services"
    echo "  status    Afficher le statut des services"
    echo "  help      Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 start    # Démarrer tous les services"
    echo "  $0 status   # Vérifier le statut"
    echo "  $0 stop     # Arrêter tous les services"
    echo ""
    echo "Configuration:"
    echo "  • Odoo Port: $ODOO_PORT"
    echo "  • Mobile Port: $MOBILE_PORT"
    echo "  • Database: $DB_NAME"
    echo "  • Logs: $LOG_DIR/"
}

# Fonction principale
main() {
    local command="${1:-help}"
    
    case "$command" in
        "start")
            start_all
            ;;
        "stop")
            create_directories
            stop_all
            ;;
        "restart")
            restart_all
            ;;
        "status")
            create_directories
            show_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Commande inconnue: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Point d'entrée du script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi