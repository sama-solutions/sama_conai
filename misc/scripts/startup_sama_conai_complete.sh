#!/bin/bash

# ========================================
# SAMA CONAI - SCRIPT DE DÉMARRAGE COMPLET
# ========================================
# Script de démarrage unifié pour tout le stack SAMA CONAI
# Version: 2.0.0
# Auteur: SAMA CONAI Team
# Date: $(date +%Y-%m-%d)

set -e  # Arrêter le script en cas d'erreur

# ========================================
# CONFIGURATION GLOBALE
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="SAMA CONAI"
VERSION="2.0.0"

# Chargement de la configuration depuis config.env
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
    echo "✅ Configuration chargée depuis config.env"
else
    echo "⚠️ Fichier config.env non trouvé, utilisation des valeurs par défaut"
fi

# Variables par défaut (peuvent être surchargées par config.env)
ODOO_PATH="${ODOO_PATH:-/var/odoo/odoo18}"
ADDONS_PATH="${ADDONS_PATH:-/home/grand-as/psagsn/custom_addons}"
DB_NAME="${DB_NAME:-sama_conai_production}"
ODOO_PORT="${ODOO_PORT:-8069}"
MOBILE_WEB_PORT="${MOBILE_WEB_PORT:-3001}"
MOBILE_APP_PORT="${MOBILE_APP_PORT:-3000}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
LOG_LEVEL="${LOG_LEVEL:-info}"
STARTUP_TIMEOUT="${STARTUP_TIMEOUT:-120}"
SHUTDOWN_TIMEOUT="${SHUTDOWN_TIMEOUT:-15}"

# Utilisateur et mot de passe de la base de données
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
NC='\033[0m' # No Color

# Fichiers PID et logs
PIDS_DIR="$SCRIPT_DIR/.pids"
LOGS_DIR="$SCRIPT_DIR/logs"
ODOO_PID_FILE="$PIDS_DIR/odoo.pid"
MOBILE_WEB_PID_FILE="$PIDS_DIR/mobile_web.pid"
POSTGRES_PID_FILE="$PIDS_DIR/postgres.pid"
ODOO_LOG="$LOGS_DIR/odoo.log"
MOBILE_WEB_LOG="$LOGS_DIR/mobile_web.log"
STARTUP_LOG="$LOGS_DIR/startup.log"

# ========================================
# FONCTIONS UTILITAIRES
# ========================================

print_banner() {
    clear
    echo ""
    echo -e "${PURPLE}${BOLD}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║                        SAMA CONAI FULL STACK                         ║${NC}"
    echo -e "${PURPLE}${BOLD}║              Plateforme de Transparence du Sénégal                  ║${NC}"
    echo -e "${PURPLE}${BOLD}║                                                                      ║${NC}"
    echo -e "${PURPLE}${BOLD}║  🇸🇳 République du Sénégal - Transparence et Gouvernance Numérique  ║${NC}"
    echo -e "${PURPLE}${BOLD}║                           Version $VERSION                            ║${NC}"
    echo -e "${PURPLE}${BOLD}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$STARTUP_LOG"
}

print_status() {
    echo -e "${GREEN}✅${NC} $1"
    log_message "INFO" "$1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
    log_message "INFO" "$1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
    log_message "WARN" "$1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
    log_message "ERROR" "$1"
}

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}🔧 $1${NC}"
    echo "=================================================================="
    log_message "INFO" "=== $1 ==="
}

print_success() {
    echo -e "${GREEN}${BOLD}🎉 $1${NC}"
    log_message "SUCCESS" "$1"
}

print_step() {
    echo -e "${WHITE}${BOLD}📋 Étape: $1${NC}"
    log_message "STEP" "$1"
}

# ========================================
# FONCTIONS DE VÉRIFICATION
# ========================================

check_prerequisites() {
    print_header "VÉRIFICATION DES PRÉREQUIS SYSTÈME"
    
    local missing_deps=()
    local warnings=()
    
    # Vérifier Python3
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version 2>&1)
        print_status "Python3 détecté: $python_version"
        
        # Vérifier la version minimale (3.8+)
        local python_major=$(python3 -c "import sys; print(sys.version_info.major)")
        local python_minor=$(python3 -c "import sys; print(sys.version_info.minor)")
        if [ "$python_major" -lt 3 ] || ([ "$python_major" -eq 3 ] && [ "$python_minor" -lt 8 ]); then
            warnings+=("Python 3.8+ recommandé (version actuelle: $python_version)")
        fi
    else
        missing_deps+=("python3")
    fi
    
    # Vérifier pip3
    if command -v pip3 &> /dev/null; then
        print_status "pip3 détecté: $(pip3 --version | cut -d' ' -f2)"
    else
        missing_deps+=("python3-pip")
    fi
    
    # Vérifier Node.js
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        print_status "Node.js détecté: $node_version"
        
        # Vérifier la version minimale (16+)
        local node_major=$(node --version | cut -d'.' -f1 | sed 's/v//')
        if [ "$node_major" -lt 16 ]; then
            warnings+=("Node.js 16+ recommandé (version actuelle: $node_version)")
        fi
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
        local pg_version=$(psql --version | head -n1)
        print_status "PostgreSQL détecté: $pg_version"
    else
        missing_deps+=("postgresql postgresql-contrib")
    fi
    
    # Vérifier les outils système
    local system_tools=("curl" "wget" "git" "lsof")
    for tool in "${system_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_status "$tool détecté"
        else
            missing_deps+=("$tool")
        fi
    done
    
    # Vérifier Docker (optionnel)
    if command -v docker &> /dev/null; then
        print_status "Docker détecté: $(docker --version | cut -d' ' -f3 | sed 's/,//')"
        if command -v docker-compose &> /dev/null; then
            print_status "Docker Compose détecté: $(docker-compose --version | cut -d' ' -f3 | sed 's/,//')"
        fi
    else
        print_warning "Docker non détecté (optionnel pour le développement)"
    fi
    
    # Afficher les avertissements
    for warning in "${warnings[@]}"; do
        print_warning "$warning"
    done
    
    # Vérifier les dépendances manquantes
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Dépendances manquantes: ${missing_deps[*]}"
        echo ""
        echo -e "${YELLOW}Pour installer sur Ubuntu/Debian:${NC}"
        echo "sudo apt update"
        echo "sudo apt install ${missing_deps[*]}"
        echo ""
        echo -e "${YELLOW}Pour installer sur CentOS/RHEL:${NC}"
        echo "sudo yum install ${missing_deps[*]}"
        echo ""
        return 1
    fi
    
    print_status "Tous les prérequis système sont satisfaits"
    return 0
}

check_python_dependencies() {
    print_header "VÉRIFICATION DES DÉPENDANCES PYTHON"
    
    local python_deps=("psycopg2-binary" "requests" "lxml" "pillow")
    local missing_python_deps=()
    
    for dep in "${python_deps[@]}"; do
        if python3 -c "import ${dep//-/_}" 2>/dev/null; then
            print_status "Module Python $dep disponible"
        else
            missing_python_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_python_deps[@]} -ne 0 ]; then
        print_warning "Dépendances Python manquantes: ${missing_python_deps[*]}"
        print_info "Installation automatique des dépendances Python..."
        
        for dep in "${missing_python_deps[@]}"; do
            print_info "Installation de $dep..."
            if pip3 install "$dep" --user; then
                print_status "$dep installé avec succès"
            else
                print_error "Échec de l'installation de $dep"
                return 1
            fi
        done
    fi
    
    print_status "Toutes les dépendances Python sont disponibles"
    return 0
}

check_ports() {
    print_header "VÉRIFICATION DE LA DISPONIBILITÉ DES PORTS"
    
    local ports_to_check=($ODOO_PORT $MOBILE_WEB_PORT $POSTGRES_PORT)
    local occupied_ports=()
    
    for port in "${ports_to_check[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -ti:$port)
            local process=$(ps -p $pid -o comm= 2>/dev/null || echo "inconnu")
            occupied_ports+=("$port:$pid:$process")
            print_warning "Port $port utilisé par le processus $process (PID: $pid)"
        else
            print_status "Port $port disponible"
        fi
    done
    
    if [ ${#occupied_ports[@]} -ne 0 ]; then
        echo ""
        echo -e "${YELLOW}Options pour libérer les ports:${NC}"
        echo "1. Arrêter automatiquement les processus (recommandé)"
        echo "2. Continuer avec des ports alternatifs"
        echo "3. Annuler et arrêter manuellement"
        echo ""
        read -p "Choisissez une option (1-3): " choice
        
        case $choice in
            1)
                print_info "Arrêt automatique des processus..."
                for port_info in "${occupied_ports[@]}"; do
                    local port=$(echo $port_info | cut -d: -f1)
                    local pid=$(echo $port_info | cut -d: -f2)
                    local process=$(echo $port_info | cut -d: -f3)
                    
                    print_info "Arrêt du processus $process (PID: $pid) sur le port $port"
                    if kill $pid 2>/dev/null; then
                        print_status "Processus $pid arrêté"
                        sleep 2
                    else
                        print_warning "Impossible d'arrêter le processus $pid"
                    fi
                done
                ;;
            2)
                print_info "Utilisation de ports alternatifs..."
                ODOO_PORT=$((ODOO_PORT + 10))
                MOBILE_WEB_PORT=$((MOBILE_WEB_PORT + 10))
                print_info "Nouveaux ports: Odoo=$ODOO_PORT, Mobile Web=$MOBILE_WEB_PORT"
                ;;
            3)
                print_error "Opération annulée par l'utilisateur"
                return 1
                ;;
            *)
                print_error "Option invalide"
                return 1
                ;;
        esac
    fi
    
    return 0
}

check_directories() {
    print_header "VÉRIFICATION DE LA STRUCTURE DU PROJET"
    
    # Créer les répertoires nécessaires
    mkdir -p "$PIDS_DIR" "$LOGS_DIR" "$SCRIPT_DIR/backups"
    
    # Vérifier les répertoires critiques du module Odoo
    local required_dirs=("models" "views" "controllers" "static" "templates" "security" "data")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            print_status "Répertoire $dir trouvé"
        else
            missing_dirs+=("$dir")
            print_warning "Répertoire $dir manquant"
        fi
    done
    
    # Vérifier les fichiers critiques
    local required_files=("__manifest__.py" "__init__.py")
    for file in "${required_files[@]}"; do
        if [ -f "$SCRIPT_DIR/$file" ]; then
            print_status "Fichier $file trouvé"
        else
            print_error "Fichier critique $file manquant"
            return 1
        fi
    done
    
    # Vérifier les applications mobiles
    if [ -d "$SCRIPT_DIR/mobile_app_web" ]; then
        print_status "Application mobile web trouvée"
        if [ -f "$SCRIPT_DIR/mobile_app_web/package.json" ]; then
            print_status "Configuration mobile web valide"
        else
            print_warning "Configuration mobile web incomplète"
        fi
    else
        print_warning "Application mobile web non trouvée"
    fi
    
    if [ -d "$SCRIPT_DIR/mobile_app" ]; then
        print_status "Application mobile React Native trouvée"
        if [ -f "$SCRIPT_DIR/mobile_app/package.json" ]; then
            print_status "Configuration React Native valide"
        else
            print_warning "Configuration React Native incomplète"
        fi
    else
        print_warning "Application mobile React Native non trouvée"
    fi
    
    # Vérifier les permissions
    if [ -w "$SCRIPT_DIR" ]; then
        print_status "Permissions d'écriture dans le répertoire du projet"
    else
        print_error "Permissions d'écriture insuffisantes"
        return 1
    fi
    
    return 0
}

# ========================================
# FONCTIONS DE DÉMARRAGE DES SERVICES
# ========================================

start_postgresql() {
    print_header "DÉMARRAGE DE POSTGRESQL"
    
    # Vérifier si PostgreSQL est déjà en cours d'exécution
    if pgrep -x "postgres" > /dev/null; then
        print_status "PostgreSQL déjà en cours d'exécution"
    else
        print_info "Démarrage de PostgreSQL..."
        
        # Essayer différentes méthodes de démarrage
        if command -v systemctl &> /dev/null && systemctl is-enabled postgresql &> /dev/null; then
            sudo systemctl start postgresql
            print_status "PostgreSQL démarré via systemctl"
        elif command -v service &> /dev/null; then
            sudo service postgresql start
            print_status "PostgreSQL démarré via service"
        elif command -v pg_ctl &> /dev/null; then
            # Démarrage direct avec pg_ctl (pour les installations locales)
            local pg_data_dir="/var/lib/postgresql/data"
            if [ -d "$pg_data_dir" ]; then
                sudo -u postgres pg_ctl -D "$pg_data_dir" start
                print_status "PostgreSQL démarré via pg_ctl"
            else
                print_error "Répertoire de données PostgreSQL non trouvé"
                return 1
            fi
        else
            print_error "Impossible de démarrer PostgreSQL automatiquement"
            print_info "Veuillez démarrer PostgreSQL manuellement"
            return 1
        fi
    fi
    
    # Attendre que PostgreSQL soit prêt
    print_info "Attente de la disponibilité de PostgreSQL..."
    local timeout=$STARTUP_TIMEOUT
    while [ $timeout -gt 0 ]; do
        if pg_isready -h localhost -p $POSTGRES_PORT >/dev/null 2>&1; then
            print_status "PostgreSQL est prêt et accessible"
            return 0
        fi
        sleep 2
        timeout=$((timeout - 2))
        echo -n "."
    done
    
    print_error "PostgreSQL n'est pas disponible après $STARTUP_TIMEOUT secondes"
    return 1
}

setup_database() {
    print_header "CONFIGURATION DE LA BASE DE DONNÉES"
    
    # Vérifier la connexion à PostgreSQL
    if ! psql -h localhost -U $DB_USER -c "SELECT 1;" >/dev/null 2>&1; then
        print_error "Impossible de se connecter à PostgreSQL avec l'utilisateur $DB_USER"
        print_info "Création de l'utilisateur PostgreSQL..."
        
        # Créer l'utilisateur s'il n'existe pas
        sudo -u postgres createuser -s $DB_USER 2>/dev/null || true
        sudo -u postgres psql -c "ALTER USER $DB_USER PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
        print_status "Utilisateur PostgreSQL configuré"
    fi
    
    # Vérifier si la base de données existe
    if psql -h localhost -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        print_status "Base de données $DB_NAME existe déjà"
    else
        print_info "Création de la base de données $DB_NAME..."
        createdb -h localhost -U $DB_USER $DB_NAME
        print_status "Base de données $DB_NAME créée avec succès"
    fi
    
    # Test de connexion à la base de données
    if psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1;" >/dev/null 2>&1; then
        print_status "Connexion à la base de données $DB_NAME réussie"
    else
        print_error "Impossible de se connecter à la base de données $DB_NAME"
        return 1
    fi
    
    return 0
}

find_odoo_executable() {
    local odoo_paths=(
        "$ODOO_PATH/odoo-bin"
        "/var/odoo/odoo18/odoo-bin"
        "/opt/odoo/odoo-bin"
        "/usr/bin/odoo"
        "$(which odoo 2>/dev/null)"
        "$(which odoo-bin 2>/dev/null)"
        "/home/grand-as/odoo18-venv/bin/odoo"
    )
    
    for path in "${odoo_paths[@]}"; do
        if [ -f "$path" ] && [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

start_odoo() {
    print_header "DÉMARRAGE D'ODOO"
    
    # Vérifier si Odoo est déjà en cours d'exécution
    if [ -f "$ODOO_PID_FILE" ] && kill -0 $(cat "$ODOO_PID_FILE") 2>/dev/null; then
        print_status "Odoo déjà en cours d'exécution (PID: $(cat $ODOO_PID_FILE))"
        return 0
    fi
    
    # Trouver l'exécutable Odoo
    local odoo_bin
    if odoo_bin=$(find_odoo_executable); then
        print_info "Exécutable Odoo trouvé: $odoo_bin"
    else
        print_error "Exécutable Odoo non trouvé"
        print_info "Chemins vérifiés:"
        echo "  - $ODOO_PATH/odoo-bin"
        echo "  - /var/odoo/odoo18/odoo-bin"
        echo "  - /opt/odoo/odoo-bin"
        echo "  - /usr/bin/odoo"
        return 1
    fi
    
    # Configuration des chemins d'addons
    local addons_path="$ODOO_PATH/addons,$ADDONS_PATH"
    if [ -d "/var/odoo/odoo18/addons" ]; then
        addons_path="/var/odoo/odoo18/addons,$ADDONS_PATH"
    fi
    
    print_info "Chemins d'addons: $addons_path"
    print_info "Démarrage d'Odoo sur le port $ODOO_PORT..."
    
    # Activer l'environnement virtuel si disponible
    if [ -f "/home/grand-as/odoo18-venv/bin/activate" ]; then
        print_info "Activation de l'environnement virtuel Odoo..."
        source /home/grand-as/odoo18-venv/bin/activate
    fi
    
    # Démarrer Odoo en arrière-plan
    nohup python3 "$odoo_bin" \
        --database="$DB_NAME" \
        --addons-path="$addons_path" \
        --db_host=localhost \
        --db_port=$POSTGRES_PORT \
        --db_user="$DB_USER" \
        --db_password="$DB_PASSWORD" \
        --http-port=$ODOO_PORT \
        --log-level=$LOG_LEVEL \
        --workers=0 \
        --dev=reload,qweb,werkzeug,xml \
        --limit-memory-hard=2684354560 \
        --limit-memory-soft=2147483648 \
        --limit-request=8192 \
        --limit-time-cpu=600 \
        --limit-time-real=1200 \
        > "$ODOO_LOG" 2>&1 &
    
    local odoo_pid=$!
    echo $odoo_pid > "$ODOO_PID_FILE"
    
    print_info "Odoo démarré avec PID: $odoo_pid"
    print_info "Logs disponibles dans: $ODOO_LOG"
    
    # Attendre qu'Odoo soit prêt
    print_info "Attente du démarrage d'Odoo (peut prendre 2-3 minutes)..."
    local timeout=$STARTUP_TIMEOUT
    while [ $timeout -gt 0 ]; do
        if curl -s --connect-timeout 5 "http://localhost:$ODOO_PORT" > /dev/null 2>&1; then
            print_status "Odoo est prêt et accessible sur http://localhost:$ODOO_PORT"
            return 0
        fi
        
        # Vérifier si le processus est toujours en cours
        if ! kill -0 $odoo_pid 2>/dev/null; then
            print_error "Le processus Odoo s'est arrêté de manière inattendue"
            print_info "Dernières lignes du log:"
            tail -n 20 "$ODOO_LOG"
            return 1
        fi
        
        echo -n "."
        sleep 3
        timeout=$((timeout - 3))
    done
    
    print_error "Odoo n'est pas accessible après $STARTUP_TIMEOUT secondes"
    print_info "Vérifiez les logs: tail -f $ODOO_LOG"
    return 1
}

install_mobile_dependencies() {
    print_header "INSTALLATION DES DÉPENDANCES MOBILES"
    
    # Application mobile web
    if [ -d "$SCRIPT_DIR/mobile_app_web" ]; then
        print_step "Installation des dépendances pour l'application mobile web"
        cd "$SCRIPT_DIR/mobile_app_web"
        
        if [ ! -d "node_modules" ] || [ ! -f "node_modules/.package-lock.json" ]; then
            print_info "Installation des dépendances npm..."
            if npm install --production; then
                print_status "Dépendances installées pour l'application mobile web"
            else
                print_error "Échec de l'installation des dépendances mobile web"
                cd "$SCRIPT_DIR"
                return 1
            fi
        else
            print_status "Dépendances déjà installées pour l'application mobile web"
        fi
        
        cd "$SCRIPT_DIR"
    fi
    
    # Application mobile React Native
    if [ -d "$SCRIPT_DIR/mobile_app" ]; then
        print_step "Vérification des dépendances pour l'application mobile React Native"
        cd "$SCRIPT_DIR/mobile_app"
        
        if [ ! -d "node_modules" ]; then
            print_info "Installation des dépendances React Native..."
            if npm install; then
                print_status "Dépendances installées pour l'application mobile React Native"
            else
                print_warning "Échec de l'installation des dépendances React Native (non critique)"
            fi
        else
            print_status "Dépendances déjà installées pour l'application mobile React Native"
        fi
        
        # Vérifier le fichier .env
        if [ ! -f ".env" ] && [ -f ".env.example" ]; then
            print_info "Création du fichier .env à partir de .env.example..."
            cp .env.example .env
            
            # Mettre à jour les variables d'environnement
            sed -i "s|API_BASE_URL=.*|API_BASE_URL=http://localhost:$ODOO_PORT|g" .env
            sed -i "s|ODOO_DB=.*|ODOO_DB=$DB_NAME|g" .env
            print_status "Fichier .env configuré"
        fi
        
        cd "$SCRIPT_DIR"
    fi
    
    return 0
}

start_mobile_web() {
    print_header "DÉMARRAGE DE L'APPLICATION MOBILE WEB"
    
    if [ ! -d "$SCRIPT_DIR/mobile_app_web" ]; then
        print_warning "Application mobile web non trouvée, passage..."
        return 0
    fi
    
    # Vérifier si l'application est déjà en cours d'exécution
    if [ -f "$MOBILE_WEB_PID_FILE" ] && kill -0 $(cat "$MOBILE_WEB_PID_FILE") 2>/dev/null; then
        print_status "Application mobile web déjà en cours d'exécution (PID: $(cat $MOBILE_WEB_PID_FILE))"
        return 0
    fi
    
    cd "$SCRIPT_DIR/mobile_app_web"
    
    # Configuration des variables d'environnement
    export PORT="$MOBILE_WEB_PORT"
    export ODOO_URL="http://localhost:$ODOO_PORT"
    export ODOO_DB="$DB_NAME"
    export ODOO_USER="admin"
    export ODOO_PASSWORD="admin"
    export NODE_ENV="production"
    
    print_info "Démarrage de l'application mobile web sur le port $MOBILE_WEB_PORT..."
    
    # Démarrer l'application en arrière-plan
    nohup npm start > "$MOBILE_WEB_LOG" 2>&1 &
    local mobile_pid=$!
    echo $mobile_pid > "$MOBILE_WEB_PID_FILE"
    
    print_info "Application mobile web démarrée avec PID: $mobile_pid"
    print_info "Logs disponibles dans: $MOBILE_WEB_LOG"
    
    # Attendre que l'application soit prête
    print_info "Attente du démarrage de l'application mobile web..."
    local timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -s --connect-timeout 3 "http://localhost:$MOBILE_WEB_PORT" > /dev/null 2>&1; then
            print_status "Application mobile web prête sur http://localhost:$MOBILE_WEB_PORT"
            cd "$SCRIPT_DIR"
            return 0
        fi
        
        # Vérifier si le processus est toujours en cours
        if ! kill -0 $mobile_pid 2>/dev/null; then
            print_error "Le processus de l'application mobile web s'est arrêté"
            print_info "Dernières lignes du log:"
            tail -n 10 "$MOBILE_WEB_LOG"
            cd "$SCRIPT_DIR"
            return 1
        fi
        
        sleep 2
        timeout=$((timeout - 2))
    done
    
    print_error "Application mobile web non accessible après 60 secondes"
    print_info "Vérifiez les logs: tail -f $MOBILE_WEB_LOG"
    cd "$SCRIPT_DIR"
    return 1
}

prepare_mobile_app() {
    print_header "PRÉPARATION DE L'APPLICATION MOBILE REACT NATIVE"
    
    if [ ! -d "$SCRIPT_DIR/mobile_app" ]; then
        print_warning "Application mobile React Native non trouvée, passage..."
        return 0
    fi
    
    cd "$SCRIPT_DIR/mobile_app"
    
    # Vérifier et configurer l'environnement
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            print_info "Création du fichier .env à partir de .env.example..."
            cp .env.example .env
            
            # Mettre à jour les variables d'environnement
            sed -i "s|API_BASE_URL=.*|API_BASE_URL=http://localhost:$ODOO_PORT|g" .env
            sed -i "s|ODOO_DB=.*|ODOO_DB=$DB_NAME|g" .env
            print_status "Fichier .env configuré"
        else
            print_warning "Fichier .env.example non trouvé"
        fi
    else
        print_status "Fichier .env existe déjà"
    fi
    
    # Vérifier la configuration Metro
    if [ -f "metro.config.js" ]; then
        print_status "Configuration Metro trouvée"
    else
        print_warning "Configuration Metro non trouvée"
    fi
    
    print_success "Application React Native prête pour le développement"
    print_info "Commandes disponibles:"
    echo "  - Démarrer Metro: cd mobile_app && npm start"
    echo "  - Build Android: cd mobile_app && npm run android"
    echo "  - Build iOS: cd mobile_app && npm run ios"
    echo "  - Tests: cd mobile_app && npm test"
    
    cd "$SCRIPT_DIR"
    return 0
}

# ========================================
# FONCTIONS DE TEST ET VALIDATION
# ========================================

test_services() {
    print_header "TEST ET VALIDATION DES SERVICES"
    
    local all_tests_passed=true
    
    # Test Odoo
    print_step "Test de l'accès à Odoo"
    if curl -s --connect-timeout 10 "http://localhost:$ODOO_PORT" > /dev/null; then
        print_status "✅ Odoo accessible sur http://localhost:$ODOO_PORT"
        
        # Test plus approfondi de l'API Odoo
        if curl -s --connect-timeout 10 "http://localhost:$ODOO_PORT/web/database/selector" > /dev/null; then
            print_status "✅ Interface web Odoo fonctionnelle"
        else
            print_warning "⚠️ Interface web Odoo partiellement accessible"
        fi
    else
        print_error "❌ Odoo non accessible"
        all_tests_passed=false
    fi
    
    # Test application mobile web
    if [ -f "$MOBILE_WEB_PID_FILE" ]; then
        print_step "Test de l'application mobile web"
        if curl -s --connect-timeout 10 "http://localhost:$MOBILE_WEB_PORT" > /dev/null; then
            print_status "✅ Application mobile web accessible sur http://localhost:$MOBILE_WEB_PORT"
        else
            print_error "❌ Application mobile web non accessible"
            all_tests_passed=false
        fi
    fi
    
    # Test de la base de données
    print_step "Test de la connexion à la base de données"
    if psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        print_status "✅ Base de données $DB_NAME accessible"
        
        # Test des tables Odoo
        local table_count=$(psql -h localhost -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ')
        if [ "$table_count" -gt 0 ]; then
            print_status "✅ Base de données initialisée ($table_count tables)"
        else
            print_warning "⚠️ Base de données vide (première installation)"
        fi
    else
        print_error "❌ Base de données non accessible"
        all_tests_passed=false
    fi
    
    # Test des processus
    print_step "Vérification des processus actifs"
    if [ -f "$ODOO_PID_FILE" ] && kill -0 $(cat "$ODOO_PID_FILE") 2>/dev/null; then
        print_status "✅ Processus Odoo actif (PID: $(cat $ODOO_PID_FILE))"
    else
        print_error "❌ Processus Odoo non actif"
        all_tests_passed=false
    fi
    
    if [ -f "$MOBILE_WEB_PID_FILE" ] && kill -0 $(cat "$MOBILE_WEB_PID_FILE") 2>/dev/null; then
        print_status "✅ Processus mobile web actif (PID: $(cat $MOBILE_WEB_PID_FILE))"
    fi
    
    # Test des logs
    print_step "Vérification des logs"
    if [ -f "$ODOO_LOG" ] && [ -s "$ODOO_LOG" ]; then
        local error_count=$(grep -c "ERROR" "$ODOO_LOG" 2>/dev/null || echo "0")
        if [ "$error_count" -eq 0 ]; then
            print_status "✅ Logs Odoo sans erreurs"
        else
            print_warning "⚠️ $error_count erreurs trouvées dans les logs Odoo"
        fi
    fi
    
    if $all_tests_passed; then
        print_success "🎉 Tous les tests sont passés avec succès !"
        return 0
    else
        print_error "❌ Certains tests ont échoué"
        return 1
    fi
}

# ========================================
# FONCTIONS D'ARRÊT ET NETTOYAGE
# ========================================

stop_services() {
    print_header "ARRÊT DES SERVICES SAMA CONAI"
    
    local services_stopped=0
    
    # Arrêter l'application mobile web
    if [ -f "$MOBILE_WEB_PID_FILE" ]; then
        local mobile_pid=$(cat "$MOBILE_WEB_PID_FILE")
        if kill -0 $mobile_pid 2>/dev/null; then
            print_info "Arrêt de l'application mobile web (PID: $mobile_pid)..."
            kill $mobile_pid
            
            # Attendre l'arrêt gracieux
            local timeout=10
            while [ $timeout -gt 0 ] && kill -0 $mobile_pid 2>/dev/null; do
                sleep 1
                timeout=$((timeout - 1))
            done
            
            # Forcer l'arrêt si nécessaire
            if kill -0 $mobile_pid 2>/dev/null; then
                print_warning "Arrêt forcé de l'application mobile web"
                kill -9 $mobile_pid 2>/dev/null
            fi
            
            rm -f "$MOBILE_WEB_PID_FILE"
            print_status "Application mobile web arrêtée"
            services_stopped=$((services_stopped + 1))
        fi
    fi
    
    # Arrêter Odoo
    if [ -f "$ODOO_PID_FILE" ]; then
        local odoo_pid=$(cat "$ODOO_PID_FILE")
        if kill -0 $odoo_pid 2>/dev/null; then
            print_info "Arrêt d'Odoo (PID: $odoo_pid)..."
            kill $odoo_pid
            
            # Attendre l'arrêt gracieux
            local timeout=$SHUTDOWN_TIMEOUT
            while [ $timeout -gt 0 ] && kill -0 $odoo_pid 2>/dev/null; do
                sleep 1
                timeout=$((timeout - 1))
            done
            
            # Forcer l'arrêt si nécessaire
            if kill -0 $odoo_pid 2>/dev/null; then
                print_warning "Arrêt forcé d'Odoo"
                kill -9 $odoo_pid 2>/dev/null
            fi
            
            rm -f "$ODOO_PID_FILE"
            print_status "Odoo arrêté"
            services_stopped=$((services_stopped + 1))
        fi
    fi
    
    # Nettoyer les fichiers temporaires
    print_info "Nettoyage des fichiers temporaires..."
    rm -f "$PIDS_DIR"/*.pid 2>/dev/null || true
    
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
    print_info "Nettoyage terminé"
    exit 0
}

# ========================================
# FONCTIONS D'AFFICHAGE ET INFORMATION
# ========================================

show_final_info() {
    echo ""
    print_header "🎉 SAMA CONAI FULL STACK DÉMARRÉ AVEC SUCCÈS !"
    echo ""
    
    # URLs d'accès
    echo -e "${GREEN}${BOLD}🌐 ACCÈS AUX SERVICES:${NC}"
    echo -e "${WHITE}   📊 Interface Odoo:${NC} ${CYAN}http://localhost:$ODOO_PORT${NC}"
    if [ -f "$MOBILE_WEB_PID_FILE" ]; then
        echo -e "${WHITE}   📱 Application Mobile Web:${NC} ${CYAN}http://localhost:$MOBILE_WEB_PORT${NC}"
    fi
    echo -e "${WHITE}   🗄️ Base de données:${NC} ${CYAN}$DB_NAME${NC} (PostgreSQL:$POSTGRES_PORT)"
    echo ""
    
    # Comptes de connexion
    echo -e "${GREEN}${BOLD}🔑 COMPTES DE CONNEXION:${NC}"
    echo -e "${WHITE}   👑 Administrateur Odoo:${NC} admin / admin"
    echo -e "${WHITE}   📱 Compte de démonstration:${NC} demo@sama-conai.sn / demo123"
    echo -e "${WHITE}   🗄️ Base de données:${NC} $DB_USER / $DB_PASSWORD"
    echo ""
    
    # Services actifs
    echo -e "${GREEN}${BOLD}📊 SERVICES ACTIFS:${NC}"
    if [ -f "$ODOO_PID_FILE" ]; then
        echo -e "${WHITE}   🔧 Odoo:${NC} PID $(cat $ODOO_PID_FILE) - Port $ODOO_PORT"
    fi
    if [ -f "$MOBILE_WEB_PID_FILE" ]; then
        echo -e "${WHITE}   📱 Mobile Web:${NC} PID $(cat $MOBILE_WEB_PID_FILE) - Port $MOBILE_WEB_PORT"
    fi
    echo -e "${WHITE}   🗄️ PostgreSQL:${NC} Port $POSTGRES_PORT"
    echo ""
    
    # Fichiers et logs
    echo -e "${GREEN}${BOLD}📁 LOGS ET FICHIERS:${NC}"
    echo -e "${WHITE}   📋 Logs Odoo:${NC} $ODOO_LOG"
    if [ -f "$MOBILE_WEB_PID_FILE" ]; then
        echo -e "${WHITE}   📋 Logs Mobile:${NC} $MOBILE_WEB_LOG"
    fi
    echo -e "${WHITE}   📋 Logs Startup:${NC} $STARTUP_LOG"
    echo -e "${WHITE}   🔧 Fichiers PID:${NC} $PIDS_DIR/"
    echo ""
    
    # Commandes utiles
    echo -e "${GREEN}${BOLD}🛠️ COMMANDES UTILES:${NC}"
    echo -e "${WHITE}   🔄 Redémarrer:${NC} $0 restart"
    echo -e "${WHITE}   🛑 Arrêter:${NC} $0 stop"
    echo -e "${WHITE}   📊 Statut:${NC} $0 status"
    echo -e "${WHITE}   📋 Logs en temps réel:${NC} $0 logs"
    echo -e "${WHITE}   🔍 Logs Odoo:${NC} tail -f $ODOO_LOG"
    if [ -f "$MOBILE_WEB_PID_FILE" ]; then
        echo -e "${WHITE}   🔍 Logs Mobile:${NC} tail -f $MOBILE_WEB_LOG"
    fi
    echo ""
    
    # Application mobile React Native
    if [ -d "$SCRIPT_DIR/mobile_app" ]; then
        echo -e "${GREEN}${BOLD}📱 APPLICATION MOBILE REACT NATIVE:${NC}"
        echo -e "${WHITE}   🚀 Démarrer Metro:${NC} cd mobile_app && npm start"
        echo -e "${WHITE}   🤖 Build Android:${NC} cd mobile_app && npm run android"
        echo -e "${WHITE}   🍎 Build iOS:${NC} cd mobile_app && npm run ios"
        echo -e "${WHITE}   🧪 Tests:${NC} cd mobile_app && npm test"
        echo ""
    fi
    
    # Informations de performance
    echo -e "${GREEN}${BOLD}⚡ INFORMATIONS SYSTÈME:${NC}"
    echo -e "${WHITE}   💾 Utilisation mémoire:${NC} $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo -e "${WHITE}   💽 Espace disque:${NC} $(df -h . | awk 'NR==2 {print $3 "/" $2 " (" $5 " utilisé)"}')"
    echo -e "${WHITE}   🖥️ Charge système:${NC} $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    
    # Message final
    print_success "💡 ${WHITE}Ouvrez http://localhost:$ODOO_PORT dans votre navigateur${NC}"
    print_success "🇸🇳 ${WHITE}Plateforme de transparence du Sénégal opérationnelle !${NC}"
    echo ""
    print_header "🌟 SAMA CONAI FULL STACK OPÉRATIONNEL !"
    echo ""
    
    # Conseils d'utilisation
    echo -e "${YELLOW}${BOLD}💡 CONSEILS D'UTILISATION:${NC}"
    echo -e "${WHITE}   • Première connexion: Utilisez admin/admin pour configurer le système${NC}"
    echo -e "${WHITE}   • Installation de modules: Allez dans Apps > Update Apps List${NC}"
    echo -e "${WHITE}   • Données de démonstration: Disponibles après installation du module${NC}"
    echo -e "${WHITE}   • Support: Consultez la documentation dans le répertoire docs/${NC}"
    echo ""
}

show_status() {
    print_header "STATUT DES SERVICES SAMA CONAI"
    
    local all_running=true
    
    # Statut Odoo
    if [ -f "$ODOO_PID_FILE" ] && kill -0 $(cat "$ODOO_PID_FILE") 2>/dev/null; then
        local odoo_pid=$(cat "$ODOO_PID_FILE")
        local odoo_memory=$(ps -p $odoo_pid -o rss= 2>/dev/null | awk '{print int($1/1024)"MB"}' || echo "N/A")
        print_status "Odoo: ${GREEN}EN COURS${NC} (PID: $odoo_pid, Mémoire: $odoo_memory, Port: $ODOO_PORT)"
        
        # Test de connectivité
        if curl -s --connect-timeout 5 "http://localhost:$ODOO_PORT" > /dev/null; then
            echo -e "        ${GREEN}✅ Service accessible${NC}"
        else
            echo -e "        ${YELLOW}⚠️ Service non accessible${NC}"
        fi
    else
        print_error "Odoo: ${RED}ARRÊTÉ${NC}"
        all_running=false
    fi
    
    # Statut application mobile web
    if [ -f "$MOBILE_WEB_PID_FILE" ] && kill -0 $(cat "$MOBILE_WEB_PID_FILE") 2>/dev/null; then
        local mobile_pid=$(cat "$MOBILE_WEB_PID_FILE")
        local mobile_memory=$(ps -p $mobile_pid -o rss= 2>/dev/null | awk '{print int($1/1024)"MB"}' || echo "N/A")
        print_status "Application Mobile Web: ${GREEN}EN COURS${NC} (PID: $mobile_pid, Mémoire: $mobile_memory, Port: $MOBILE_WEB_PORT)"
        
        # Test de connectivité
        if curl -s --connect-timeout 5 "http://localhost:$MOBILE_WEB_PORT" > /dev/null; then
            echo -e "        ${GREEN}✅ Service accessible${NC}"
        else
            echo -e "        ${YELLOW}⚠️ Service non accessible${NC}"
        fi
    else
        print_error "Application Mobile Web: ${RED}ARRÊTÉE${NC}"
    fi
    
    # Statut PostgreSQL
    if pgrep -x "postgres" > /dev/null; then
        print_status "PostgreSQL: ${GREEN}EN COURS${NC} (Port: $POSTGRES_PORT)"
        
        # Test de connectivité
        if pg_isready -h localhost -p $POSTGRES_PORT >/dev/null 2>&1; then
            echo -e "        ${GREEN}✅ Service accessible${NC}"
            
            # Informations sur la base de données
            if psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
                local db_size=$(psql -h localhost -U $DB_USER -d $DB_NAME -t -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));" 2>/dev/null | tr -d ' ' || echo "N/A")
                echo -e "        ${GREEN}✅ Base de données $DB_NAME accessible (Taille: $db_size)${NC}"
            else
                echo -e "        ${YELLOW}⚠️ Base de données $DB_NAME non accessible${NC}"
            fi
        else
            echo -e "        ${YELLOW}⚠️ Service non accessible${NC}"
        fi
    else
        print_error "PostgreSQL: ${RED}ARRÊTÉ${NC}"
        all_running=false
    fi
    
    # Statut des logs
    echo ""
    echo -e "${CYAN}${BOLD}📋 INFORMATIONS SUR LES LOGS:${NC}"
    if [ -f "$ODOO_LOG" ]; then
        local odoo_log_size=$(du -h "$ODOO_LOG" | cut -f1)
        local odoo_log_lines=$(wc -l < "$ODOO_LOG")
        echo -e "${WHITE}   📄 Log Odoo:${NC} $odoo_log_size ($odoo_log_lines lignes)"
        
        # Dernières erreurs
        local recent_errors=$(grep "ERROR" "$ODOO_LOG" | tail -n 3 | wc -l)
        if [ "$recent_errors" -gt 0 ]; then
            echo -e "${WHITE}   ⚠️ Erreurs récentes:${NC} $recent_errors"
        fi
    fi
    
    if [ -f "$MOBILE_WEB_LOG" ]; then
        local mobile_log_size=$(du -h "$MOBILE_WEB_LOG" | cut -f1)
        local mobile_log_lines=$(wc -l < "$MOBILE_WEB_LOG")
        echo -e "${WHITE}   📄 Log Mobile Web:${NC} $mobile_log_size ($mobile_log_lines lignes)"
    fi
    
    # Résumé global
    echo ""
    if $all_running; then
        print_success "🎉 Tous les services critiques sont opérationnels"
    else
        print_warning "⚠️ Certains services ne sont pas en cours d'exécution"
    fi
    
    echo ""
}

show_logs() {
    print_header "AFFICHAGE DES LOGS RÉCENTS"
    
    if [ -f "$ODOO_LOG" ]; then
        echo -e "${CYAN}${BOLD}=== LOGS ODOO (50 dernières lignes) ===${NC}"
        tail -n 50 "$ODOO_LOG"
        echo ""
    else
        print_warning "Fichier de log Odoo non trouvé: $ODOO_LOG"
    fi
    
    if [ -f "$MOBILE_WEB_LOG" ]; then
        echo -e "${CYAN}${BOLD}=== LOGS MOBILE WEB (50 dernières lignes) ===${NC}"
        tail -n 50 "$MOBILE_WEB_LOG"
        echo ""
    else
        print_warning "Fichier de log Mobile Web non trouvé: $MOBILE_WEB_LOG"
    fi
    
    if [ -f "$STARTUP_LOG" ]; then
        echo -e "${CYAN}${BOLD}=== LOGS STARTUP (20 dernières lignes) ===${NC}"
        tail -n 20 "$STARTUP_LOG"
        echo ""
    fi
}

show_help() {
    print_banner
    echo -e "${CYAN}${BOLD}USAGE:${NC} $0 [COMMAND] [OPTIONS]"
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
    echo -e "${CYAN}${BOLD}EXEMPLES:${NC}"
    echo -e "${WHITE}  $0${NC}              # Démarrer tous les services"
    echo -e "${WHITE}  $0 start${NC}        # Démarrer tous les services"
    echo -e "${WHITE}  $0 stop${NC}         # Arrêter tous les services"
    echo -e "${WHITE}  $0 restart${NC}      # Redémarrer tous les services"
    echo -e "${WHITE}  $0 status${NC}       # Voir le statut"
    echo -e "${WHITE}  $0 logs${NC}         # Voir les logs"
    echo ""
    echo -e "${CYAN}${BOLD}CONFIGURATION:${NC}"
    echo -e "${WHITE}  Fichier de config:${NC} $SCRIPT_DIR/config.env"
    echo -e "${WHITE}  Logs:${NC} $LOGS_DIR/"
    echo -e "${WHITE}  PIDs:${NC} $PIDS_DIR/"
    echo ""
    echo -e "${CYAN}${BOLD}SERVICES GÉRÉS:${NC}"
    echo -e "${WHITE}  • PostgreSQL${NC} (Base de données)"
    echo -e "${WHITE}  • Odoo 18${NC} (ERP et backend)"
    echo -e "${WHITE}  • Application Mobile Web${NC} (Interface web mobile)"
    echo -e "${WHITE}  • Application React Native${NC} (Préparation pour mobile natif)"
    echo ""
}

# ========================================
# FONCTION PRINCIPALE
# ========================================

main() {
    local action="${1:-start}"
    
    # Créer les répertoires de logs et PIDs
    mkdir -p "$LOGS_DIR" "$PIDS_DIR"
    
    # Initialiser le log de startup
    echo "=== SAMA CONAI Startup Log - $(date) ===" > "$STARTUP_LOG"
    
    case "$action" in
        "start")
            print_banner
            log_message "INFO" "Démarrage du stack SAMA CONAI"
            
            # Vérifications préliminaires
            check_prerequisites || exit 1
            check_python_dependencies || exit 1
            check_directories || exit 1
            check_ports || exit 1
            
            # Démarrage des services
            start_postgresql || exit 1
            setup_database || exit 1
            install_mobile_dependencies || exit 1
            start_odoo || exit 1
            start_mobile_web
            prepare_mobile_app
            
            # Tests et validation
            test_services
            show_final_info
            
            # Garder le script actif
            print_info "Appuyez sur Ctrl+C pour arrêter tous les services"
            print_info "Ou utilisez '$0 stop' dans un autre terminal"
            trap cleanup_on_exit INT TERM
            
            # Boucle de surveillance
            while true; do
                sleep 30
                
                # Vérifier que les services critiques sont toujours actifs
                if [ -f "$ODOO_PID_FILE" ] && ! kill -0 $(cat "$ODOO_PID_FILE") 2>/dev/null; then
                    print_error "Odoo s'est arrêté de manière inattendue"
                    log_message "ERROR" "Odoo process died unexpectedly"
                    break
                fi
            done
            ;;
        "stop")
            print_banner
            log_message "INFO" "Arrêt du stack SAMA CONAI"
            stop_services
            ;;
        "restart")
            print_banner
            log_message "INFO" "Redémarrage du stack SAMA CONAI"
            stop_services
            sleep 5
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
    print_info "Répertoire actuel: $SCRIPT_DIR"
    print_info "Fichier attendu: $SCRIPT_DIR/__manifest__.py"
    exit 1
fi

# Vérifier les permissions
if [ ! -w "$SCRIPT_DIR" ]; then
    print_error "Permissions d'écriture insuffisantes dans le répertoire du projet"
    print_info "Exécutez: chmod +w $SCRIPT_DIR"
    exit 1
fi

# Exécuter la fonction principale avec tous les arguments
main "$@"