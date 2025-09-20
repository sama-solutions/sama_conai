#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Script de lancement SAMA CONAI - Module Odoo 18
# ============================================================================
# 
# Ce script permet de lancer le module SAMA CONAI de manière autonome pour
# les tests et le développement avec gestion complète du cycle de vie.
#
# Usage:
#   ./launch_sama_conai.sh --init -p 8075 -d sama_conai_test
#   ./launch_sama_conai.sh --update -p 8075 -d sama_conai_test  
#   ./launch_sama_conai.sh --run -p 8075 -d sama_conai_test
#
# Options:
#   --init      : Initialise et installe le module
#   --update    : Met à jour le module
#   --run       : Lance le serveur sans modification
#   -p, --port  : Port HTTP (défaut: 8075)
#   -d, --db    : Nom de la base de données (défaut: sama_conai_test)
#   --dev       : Mode développement avec rechargement automatique
#   --debug     : Logs en mode debug
#   --dry-run   : Affiche la commande sans l'exécuter
#   --follow    : Suit les logs en temps réel
#   -h, --help  : Affiche cette aide
#
# ============================================================================

# Configuration des chemins (selon spécifications utilisateur)
ODOO_HOME="/var/odoo/odoo18"
VENV_DIR="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS="/home/grand-as/psagsn/custom_addons"
OFFICIAL_ADDONS1="/var/odoo/odoo18/addons"
OFFICIAL_ADDONS2="/var/odoo/odoo18/odoo/addons"

# Configuration PostgreSQL
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="odoo"
DB_PASSWORD="odoo"

# Dossiers du module
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$MODULE_DIR/.sama_conai_temp"
LOG_DIR="$TEMP_DIR/logs"
CONF_DIR="$TEMP_DIR/conf"
PID_DIR="$TEMP_DIR/pids"

# Valeurs par défaut
PORT="8075"
DB_NAME="sama_conai_test"
ACTION="run"
DEV_MODE="false"
DEBUG_MODE="false"
DRY_RUN="false"
FOLLOW_LOGS="false"
LOG_LEVEL="info"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Actions:
  --init              Initialise et installe le module sama_conai
  --update            Met à jour le module sama_conai
  --run               Lance le serveur (défaut)

Options:
  -p, --port PORT     Port HTTP Odoo (défaut: $PORT)
  -d, --db NAME       Nom de la base de données (défaut: $DB_NAME)
  --dev               Active le mode développement
  --debug             Active les logs debug
  --dry-run           Affiche la commande sans l'exécuter
  --follow            Suit les logs en temps réel après démarrage
  -h, --help          Affiche cette aide

Exemples:
  # Première installation
  $0 --init -p 8075 -d sama_conai_test

  # Mise à jour après modifications
  $0 --update -p 8075 -d sama_conai_test --dev

  # Démarrage simple
  $0 --run -p 8075 -d sama_conai_test --follow

Configuration:
  Odoo Home    : $ODOO_HOME
  Virtual Env  : $VENV_DIR
  Custom Addons: $CUSTOM_ADDONS
  PostgreSQL   : $DB_USER@$DB_HOST:$DB_PORT
EOF
}

# ============================================================================
# GESTION DES PROCESSUS
# ============================================================================

kill_port_processes() {
    local port="$1"
    log_info "Vérification des processus sur le port $port..."
    
    # Trouver les PID des processus écoutant sur ce port
    local pids
    pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)
    
    if [[ -n "$pids" ]]; then
        log_warning "Arrêt des processus sur le port $port: $pids"
        
        # Tentative d'arrêt propre (SIGTERM)
        echo "$pids" | xargs -r kill -TERM 2>/dev/null || true
        sleep 2
        
        # Vérifier si les processus sont toujours actifs
        pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)
        if [[ -n "$pids" ]]; then
            log_warning "Forçage de l'arrêt (SIGKILL) pour: $pids"
            echo "$pids" | xargs -r kill -KILL 2>/dev/null || true
            sleep 1
        fi
        
        log_success "Port $port libéré"
    else
        log_info "Aucun processus trouvé sur le port $port"
    fi
}

# ============================================================================
# GESTION DE LA BASE DE DONNÉES
# ============================================================================

check_postgres_connection() {
    log_info "Vérification de la connexion PostgreSQL..."
    
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c '\q' 2>/dev/null; then
        log_error "Impossible de se connecter à PostgreSQL"
        log_error "Vérifiez que PostgreSQL est démarré et que l'utilisateur '$DB_USER' existe"
        exit 1
    fi
    
    log_success "Connexion PostgreSQL OK"
}

ensure_database() {
    local db="$1"
    log_info "Vérification de la base de données '$db'..."
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db'" | grep -q 1; then
        log_info "Base de données '$db' existe déjà"
    else
        log_info "Création de la base de données '$db'..."
        PGPASSWORD="$DB_PASSWORD" createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$db"
        log_success "Base de données '$db' créée"
    fi
}

# ============================================================================
# CONFIGURATION ODOO
# ============================================================================

create_odoo_config() {
    local conf_file="$1"
    log_info "Création du fichier de configuration: $conf_file"
    
    cat > "$conf_file" <<EOF
[options]
# Configuration SAMA CONAI - $(date)

# Authentification admin
admin_passwd = admin

# Configuration base de données
list_db = True
db_host = $DB_HOST
db_port = $DB_PORT
db_user = $DB_USER
db_password = $DB_PASSWORD

# Configuration serveur
http_port = $PORT
proxy_mode = True
server_wide_modules = web,base

# Chemins des addons
addons_path = $CUSTOM_ADDONS,$OFFICIAL_ADDONS1,$OFFICIAL_ADDONS2

# Configuration des logs
logfile = $LOG_DIR/odoo-$PORT.log
log_level = $LOG_LEVEL
log_db = False
log_db_level = warning

# Performance et sécurité
workers = 0
max_cron_threads = 1
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200

# Développement
EOF

    if [[ "$DEV_MODE" == "true" ]]; then
        cat >> "$conf_file" <<EOF

# Mode développement activé
dev_mode = reload,qweb,werkzeug,xml
EOF
    fi
    
    log_success "Configuration créée: $conf_file"
}

# ============================================================================
# VALIDATION DE L'ENVIRONNEMENT
# ============================================================================

validate_environment() {
    log_info "Validation de l'environnement..."
    
    # Vérifier le virtual environment
    if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
        log_error "Virtual environment introuvable: $VENV_DIR"
        exit 1
    fi
    
    # Vérifier Odoo
    local odoo_bin="$ODOO_HOME/odoo-bin"
    if [[ ! -x "$odoo_bin" ]]; then
        log_error "Binaire Odoo introuvable: $odoo_bin"
        exit 1
    fi
    
    # Vérifier les dossiers d'addons
    if [[ ! -d "$CUSTOM_ADDONS" ]]; then
        log_error "Dossier custom_addons introuvable: $CUSTOM_ADDONS"
        exit 1
    fi
    
    if [[ ! -d "$OFFICIAL_ADDONS1" ]] && [[ ! -d "$OFFICIAL_ADDONS2" ]]; then
        log_error "Aucun dossier d'addons officiels trouvé"
        exit 1
    fi
    
    # Vérifier le module sama_conai
    if [[ ! -f "$MODULE_DIR/__manifest__.py" ]]; then
        log_error "Module sama_conai introuvable dans: $MODULE_DIR"
        exit 1
    fi
    
    log_success "Environnement validé"
}

# ============================================================================
# DÉMARRAGE ODOO
# ============================================================================

start_odoo() {
    local conf_file="$CONF_DIR/odoo-$PORT.conf"
    local log_file="$LOG_DIR/odoo-$PORT.log"
    local pid_file="$PID_DIR/odoo-$PORT.pid"
    
    # Activer le virtual environment
    log_info "Activation du virtual environment..."
    # shellcheck disable=SC1091
    source "$VENV_DIR/bin/activate"
    
    # Construire la commande Odoo
    local odoo_bin="$ODOO_HOME/odoo-bin"
    local cmd=("$odoo_bin" -c "$conf_file" -d "$DB_NAME")
    
    # Ajouter les options selon l'action
    case "$ACTION" in
        init)
            cmd+=("-i" "sama_conai" "--without-demo=all")
            ;;
        update)
            cmd+=("-u" "sama_conai")
            ;;
        run)
            # Pas d'options supplémentaires pour run
            ;;
        *)
            log_error "Action inconnue: $ACTION"
            exit 1
            ;;
    esac
    
    # Mode debug
    if [[ "$DEBUG_MODE" == "true" ]]; then
        cmd+=("--log-level=debug")
    fi
    
    # Afficher la commande
    log_info "Commande Odoo: ${cmd[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Mode dry-run - aucune exécution"
        return 0
    fi
    
    # Démarrer Odoo en arrière-plan
    log_info "Démarrage d'Odoo sur le port $PORT..."
    nohup "${cmd[@]}" >> "$log_file" 2>&1 &
    local pid=$!
    
    # Sauvegarder le PID
    echo "$pid" > "$pid_file"
    log_success "Odoo démarré avec PID=$pid"
    log_info "Logs: $log_file"
    log_info "PID file: $pid_file"
    
    # Attendre que le serveur soit prêt
    log_info "Attente du démarrage du serveur..."
    local max_wait=60
    local count=0
    
    while [[ $count -lt $max_wait ]]; do
        if curl -s "http://localhost:$PORT/web/database/selector" >/dev/null 2>&1; then
            log_success "Serveur Odoo prêt sur http://localhost:$PORT"
            break
        fi
        
        if ! kill -0 "$pid" 2>/dev/null; then
            log_error "Le processus Odoo s'est arrêté de manière inattendue"
            log_error "Consultez les logs: $log_file"
            exit 1
        fi
        
        sleep 1
        ((count++))
        
        if [[ $((count % 10)) -eq 0 ]]; then
            log_info "Attente... ($count/$max_wait secondes)"
        fi
    done
    
    if [[ $count -eq $max_wait ]]; then
        log_error "Timeout: le serveur n'a pas démarré dans les $max_wait secondes"
        log_error "Consultez les logs: $log_file"
        exit 1
    fi
    
    # Afficher les informations de connexion
    echo
    log_success "=== SAMA CONAI DÉMARRÉ AVEC SUCCÈS ==="
    echo -e "${GREEN}URL d'accès:${NC} http://localhost:$PORT"
    echo -e "${GREEN}Base de données:${NC} $DB_NAME"
    echo -e "${GREEN}Action effectuée:${NC} $ACTION"
    echo -e "${GREEN}Logs:${NC} $log_file"
    echo -e "${GREEN}PID:${NC} $pid"
    echo
    
    # Suivre les logs si demandé
    if [[ "$FOLLOW_LOGS" == "true" ]]; then
        log_info "Suivi des logs (Ctrl+C pour quitter, Odoo continue en arrière-plan)"
        tail -f "$log_file"
    fi
}

# ============================================================================
# PARSING DES ARGUMENTS
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -d|--db)
                DB_NAME="$2"
                shift 2
                ;;
            --init)
                ACTION="init"
                shift 1
                ;;
            --update)
                ACTION="update"
                shift 1
                ;;
            --run)
                ACTION="run"
                shift 1
                ;;
            --dev)
                DEV_MODE="true"
                shift 1
                ;;
            --debug)
                DEBUG_MODE="true"
                LOG_LEVEL="debug"
                shift 1
                ;;
            --dry-run)
                DRY_RUN="true"
                shift 1
                ;;
            --follow)
                FOLLOW_LOGS="true"
                shift 1
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                log_error "Option inconnue: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# FONCTION PRINCIPALE
# ============================================================================

main() {
    # Créer les dossiers temporaires
    mkdir -p "$LOG_DIR" "$CONF_DIR" "$PID_DIR"
    
    # Afficher l'en-tête
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}                    SAMA CONAI - Lancement Module Odoo 18${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo
    
    # Parser les arguments
    parse_arguments "$@"
    
    # Valider l'environnement
    validate_environment
    
    # Vérifier PostgreSQL
    check_postgres_connection
    
    # Arrêter les processus sur notre port
    kill_port_processes "$PORT"
    
    # Créer/vérifier la base de données
    ensure_database "$DB_NAME"
    
    # Créer la configuration Odoo
    create_odoo_config "$CONF_DIR/odoo-$PORT.conf"
    
    # Démarrer Odoo
    start_odoo
}

# ============================================================================
# EXÉCUTION
# ============================================================================

# Vérifier que le script est exécuté depuis le bon répertoire
if [[ ! -f "$MODULE_DIR/__manifest__.py" ]]; then
    log_error "Ce script doit être exécuté depuis le répertoire du module sama_conai"
    exit 1
fi

# Exécuter la fonction principale avec tous les arguments
main "$@"