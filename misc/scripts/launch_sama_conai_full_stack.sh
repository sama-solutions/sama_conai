#!/bin/bash

# ========================================
# SAMA CONAI - SCRIPT DE LANCEMENT COMPLET
# ========================================
# Lancement de tout le stack : Odoo + Applications mobiles + Services
# Version: 1.0.0
# Auteur: SAMA CONAI Team

set -e  # Arrêter le script en cas d'erreur

# Variables de configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="SAMA CONAI"
VERSION="1.0.0"

# Ports par défaut
ODOO_PORT=8069
MOBILE_WEB_PORT=3001
MOBILE_APP_PORT=3000
POSTGRES_PORT=5432

# Base de données
DB_NAME="sama_conai_production"
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
NC='\033[0m' # No Color

# Fichiers PID pour le suivi des processus
ODOO_PID_FILE="$SCRIPT_DIR/.pids/odoo.pid"
MOBILE_WEB_PID_FILE="$SCRIPT_DIR/.pids/mobile_web.pid"
POSTGRES_PID_FILE="$SCRIPT_DIR/.pids/postgres.pid"

# Logs
LOG_DIR="$SCRIPT_DIR/logs"
ODOO_LOG="$LOG_DIR/odoo.log"
MOBILE_WEB_LOG="$LOG_DIR/mobile_web.log"
POSTGRES_LOG="$LOG_DIR/postgres.log"

# ========================================
# FONCTIONS UTILITAIRES
# ========================================

print_banner() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    SAMA CONAI FULL STACK                     ║${NC}"
    echo -e "${PURPLE}║              Plateforme de Transparence Sénégal             ║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║  🇸🇳 République du Sénégal - Transparence Numérique         ║${NC}"
    echo -e "${PURPLE}║                     Version $VERSION                          ║${NC}"
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

check_prerequisites() {
    print_header "VÉRIFICATION DES PRÉREQUIS"
    
    local missing_deps=()
    
    # Vérifier Python3
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    else
        print_status "Python3 détecté: $(python3 --version)"
    fi
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        missing_deps+=("nodejs")
    else
        print_status "Node.js détecté: $(node --version)"
    fi
    
    # Vérifier npm
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    else
        print_status "npm détecté: $(npm --version)"
    fi
    
    # Vérifier PostgreSQL
    if ! command -v psql &> /dev/null; then
        missing_deps+=("postgresql")
    else
        print_status "PostgreSQL détecté: $(psql --version | head -n1)"
    fi
    
    # Vérifier Docker (optionnel)
    if command -v docker &> /dev/null; then
        print_status "Docker détecté: $(docker --version)"
    else
        print_warning "Docker non détecté (optionnel)"
    fi
    
    # Vérifier les dépendances manquantes
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Dépendances manquantes: ${missing_deps[*]}"
        echo ""
        echo "Pour installer sur Ubuntu/Debian:"
        echo "sudo apt update"
        echo "sudo apt install python3 python3-pip nodejs npm postgresql postgresql-contrib"
        echo ""
        exit 1
    fi
    
    print_status "Tous les prérequis sont satisfaits"
}

check_ports() {
    print_header "VÉRIFICATION DES PORTS"
    
    local ports_to_check=($ODOO_PORT $MOBILE_WEB_PORT $POSTGRES_PORT)
    local occupied_ports=()
    
    for port in "${ports_to_check[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            occupied_ports+=($port)
            print_warning "Port $port déjà utilisé"
        else
            print_status "Port $port disponible"
        fi
    done
    
    if [ ${#occupied_ports[@]} -ne 0 ]; then
        print_warning "Certains ports sont occupés. Tentative de libération..."
        for port in "${occupied_ports[@]}"; do
            local pid=$(lsof -ti:$port)
            if [ ! -z "$pid" ]; then
                print_info "Arrêt du processus utilisant le port $port (PID: $pid)"
                kill $pid 2>/dev/null || true
                sleep 2
            fi
        done
    fi
}

check_directories() {
    print_header "VÉRIFICATION DE LA STRUCTURE DU PROJET"
    
    # Créer les répertoires nécessaires
    mkdir -p "$SCRIPT_DIR/.pids"
    mkdir -p "$LOG_DIR"
    mkdir -p "$SCRIPT_DIR/backups"
    
    # Vérifier les répertoires critiques
    local required_dirs=("models" "views" "controllers" "static" "templates")
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            print_status "Répertoire $dir trouvé"
        else
            print_error "Répertoire $dir manquant"
            exit 1
        fi
    done
    
    # Vérifier les applications mobiles
    if [ -d "$SCRIPT_DIR/mobile_app_web" ]; then
        print_status "Application mobile web trouvée"
    else
        print_warning "Application mobile web non trouvée"
    fi
    
    if [ -d "$SCRIPT_DIR/mobile_app" ]; then
        print_status "Application mobile React Native trouvée"
    else
        print_warning "Application mobile React Native non trouvée"
    fi
}

# ========================================
# FONCTIONS DE DÉMARRAGE DES SERVICES
# ========================================

start_postgresql() {
    print_header "DÉMARRAGE DE POSTGRESQL"
    
    # Vérifier si PostgreSQL est déjà en cours d'exécution
    if pgrep -x "postgres" > /dev/null; then
        print_status "PostgreSQL déjà en cours d'exécution"
        return 0
    fi
    
    # Démarrer PostgreSQL selon le système
    if systemctl is-active --quiet postgresql; then
        print_status "PostgreSQL déjà actif via systemctl"
    else
        print_info "Démarrage de PostgreSQL..."
        if command -v systemctl &> /dev/null; then
            sudo systemctl start postgresql
            print_status "PostgreSQL démarré via systemctl"
        elif command -v service &> /dev/null; then
            sudo service postgresql start
            print_status "PostgreSQL démarré via service"
        else
            print_warning "Impossible de démarrer PostgreSQL automatiquement"
            print_info "Veuillez démarrer PostgreSQL manuellement"
        fi
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
    if psql -h localhost -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        print_status "Base de données $DB_NAME existe déjà"
    else
        print_info "Création de la base de données $DB_NAME..."
        createdb -h localhost -U $DB_USER $DB_NAME
        print_status "Base de données $DB_NAME créée"
    fi
}

start_odoo() {
    print_header "DÉMARRAGE D'ODOO"
    
    # Vérifier si Odoo est déjà en cours d'exécution
    if [ -f "$ODOO_PID_FILE" ] && kill -0 $(cat "$ODOO_PID_FILE") 2>/dev/null; then
        print_status "Odoo déjà en cours d'exécution (PID: $(cat $ODOO_PID_FILE))"
        return 0
    fi
    
    # Trouver l'exécutable Odoo
    local odoo_bin=""
    local possible_paths=(\n        \"/var/odoo/odoo18/odoo-bin\"\n        \"/opt/odoo/odoo-bin\"\n        \"/usr/bin/odoo\"\n        \"$(which odoo 2>/dev/null)\"\n        \"$(which odoo-bin 2>/dev/null)\"\n    )\n    \n    for path in \"${possible_paths[@]}\"; do\n        if [ -f \"$path\" ] && [ -x \"$path\" ]; then\n            odoo_bin=\"$path\"\n            break\n        fi\n    done\n    \n    if [ -z \"$odoo_bin\" ]; then\n        print_error \"Exécutable Odoo non trouvé\"\n        print_info \"Veuillez installer Odoo ou ajuster le chemin dans le script\"\n        return 1\n    fi\n    \n    print_info \"Utilisation d'Odoo: $odoo_bin\"\n    \n    # Configuration Odoo\n    local addons_path=\"/var/odoo/odoo18/addons,$SCRIPT_DIR\"\n    \n    print_info \"Démarrage d'Odoo sur le port $ODOO_PORT...\"\n    \n    # Démarrer Odoo en arrière-plan\n    nohup python3 \"$odoo_bin\" \\\n        --database=\"$DB_NAME\" \\\n        --addons-path=\"$addons_path\" \\\n        --db_host=localhost \\\n        --db_port=$POSTGRES_PORT \\\n        --db_user=\"$DB_USER\" \\\n        --db_password=\"$DB_PASSWORD\" \\\n        --http-port=$ODOO_PORT \\\n        --log-level=info \\\n        --workers=0 \\\n        --dev=reload,qweb,werkzeug,xml \\\n        > \"$ODOO_LOG\" 2>&1 &\n    \n    local odoo_pid=$!\n    echo $odoo_pid > \"$ODOO_PID_FILE\"\n    \n    print_info \"Odoo démarré avec PID: $odoo_pid\"\n    print_info \"Logs disponibles dans: $ODOO_LOG\"\n    \n    # Attendre qu'Odoo soit prêt\n    print_info \"Attente du démarrage d'Odoo (peut prendre 1-2 minutes)...\"\n    for i in {1..60}; do\n        if curl -s --connect-timeout 2 \"http://localhost:$ODOO_PORT\" > /dev/null 2>&1; then\n            print_status \"Odoo est prêt et accessible\"\n            return 0\n        fi\n        echo -n \".\"\n        sleep 2\n    done\n    \n    print_error \"Odoo n'est pas accessible après 2 minutes\"\n    print_info \"Vérifiez les logs: tail -f $ODOO_LOG\"\n    return 1\n}\n\ninstall_mobile_dependencies() {\n    print_header \"INSTALLATION DES DÉPENDANCES MOBILES\"\n    \n    # Application mobile web\n    if [ -d \"$SCRIPT_DIR/mobile_app_web\" ]; then\n        print_info \"Installation des dépendances pour l'application mobile web...\"\n        cd \"$SCRIPT_DIR/mobile_app_web\"\n        \n        if [ ! -d \"node_modules\" ]; then\n            npm install\n            print_status \"Dépendances installées pour l'application mobile web\"\n        else\n            print_status \"Dépendances déjà installées pour l'application mobile web\"\n        fi\n        \n        cd \"$SCRIPT_DIR\"\n    fi\n    \n    # Application mobile React Native\n    if [ -d \"$SCRIPT_DIR/mobile_app\" ]; then\n        print_info \"Installation des dépendances pour l'application mobile React Native...\"\n        cd \"$SCRIPT_DIR/mobile_app\"\n        \n        if [ ! -d \"node_modules\" ]; then\n            npm install\n            print_status \"Dépendances installées pour l'application mobile React Native\"\n        else\n            print_status \"Dépendances déjà installées pour l'application mobile React Native\"\n        fi\n        \n        cd \"$SCRIPT_DIR\"\n    fi\n}\n\nstart_mobile_web() {\n    print_header \"DÉMARRAGE DE L'APPLICATION MOBILE WEB\"\n    \n    if [ ! -d \"$SCRIPT_DIR/mobile_app_web\" ]; then\n        print_warning \"Application mobile web non trouvée, passage...\"\n        return 0\n    fi\n    \n    # Vérifier si l'application est déjà en cours d'exécution\n    if [ -f \"$MOBILE_WEB_PID_FILE\" ] && kill -0 $(cat \"$MOBILE_WEB_PID_FILE\") 2>/dev/null; then\n        print_status \"Application mobile web déjà en cours d'exécution (PID: $(cat $MOBILE_WEB_PID_FILE))\"\n        return 0\n    fi\n    \n    cd \"$SCRIPT_DIR/mobile_app_web\"\n    \n    # Configuration des variables d'environnement\n    export PORT=\"$MOBILE_WEB_PORT\"\n    export ODOO_URL=\"http://localhost:$ODOO_PORT\"\n    export ODOO_DB=\"$DB_NAME\"\n    export ODOO_USER=\"admin\"\n    export ODOO_PASSWORD=\"admin\"\n    \n    print_info \"Démarrage de l'application mobile web sur le port $MOBILE_WEB_PORT...\"\n    \n    # Démarrer l'application en arrière-plan\n    nohup npm start > \"$MOBILE_WEB_LOG\" 2>&1 &\n    local mobile_pid=$!\n    echo $mobile_pid > \"$MOBILE_WEB_PID_FILE\"\n    \n    print_info \"Application mobile web démarrée avec PID: $mobile_pid\"\n    print_info \"Logs disponibles dans: $MOBILE_WEB_LOG\"\n    \n    # Attendre que l'application soit prête\n    print_info \"Attente du démarrage de l'application mobile web...\"\n    for i in {1..30}; do\n        if curl -s --connect-timeout 2 \"http://localhost:$MOBILE_WEB_PORT\" > /dev/null 2>&1; then\n            print_status \"Application mobile web prête\"\n            cd \"$SCRIPT_DIR\"\n            return 0\n        fi\n        sleep 2\n    done\n    \n    print_error \"Application mobile web non accessible après 1 minute\"\n    print_info \"Vérifiez les logs: tail -f $MOBILE_WEB_LOG\"\n    cd \"$SCRIPT_DIR\"\n    return 1\n}\n\nstart_mobile_app() {\n    print_header \"PRÉPARATION DE L'APPLICATION MOBILE REACT NATIVE\"\n    \n    if [ ! -d \"$SCRIPT_DIR/mobile_app\" ]; then\n        print_warning \"Application mobile React Native non trouvée, passage...\"\n        return 0\n    fi\n    \n    cd \"$SCRIPT_DIR/mobile_app\"\n    \n    # Vérifier le fichier .env\n    if [ ! -f \".env\" ]; then\n        if [ -f \".env.example\" ]; then\n            print_info \"Création du fichier .env à partir de .env.example...\"\n            cp .env.example .env\n            \n            # Mettre à jour les variables d'environnement\n            sed -i \"s|API_BASE_URL=.*|API_BASE_URL=http://localhost:$ODOO_PORT|g\" .env\n            print_status \"Fichier .env configuré\"\n        else\n            print_warning \"Fichier .env.example non trouvé\"\n        fi\n    else\n        print_status \"Fichier .env existe déjà\"\n    fi\n    \n    print_info \"Application React Native prête pour le développement\"\n    print_info \"Pour démarrer: cd mobile_app && npm start\"\n    print_info \"Pour Android: cd mobile_app && npm run android\"\n    print_info \"Pour iOS: cd mobile_app && npm run ios\"\n    \n    cd \"$SCRIPT_DIR\"\n}\n\n# ========================================\n# FONCTIONS DE TEST ET VALIDATION\n# ========================================\n\ntest_services() {\n    print_header \"TEST DES SERVICES\"\n    \n    # Test Odoo\n    print_info \"Test de l'accès à Odoo...\"\n    if curl -s \"http://localhost:$ODOO_PORT\" > /dev/null; then\n        print_status \"Odoo accessible sur http://localhost:$ODOO_PORT\"\n    else\n        print_error \"Odoo non accessible\"\n    fi\n    \n    # Test application mobile web\n    if [ -f \"$MOBILE_WEB_PID_FILE\" ]; then\n        print_info \"Test de l'application mobile web...\"\n        if curl -s \"http://localhost:$MOBILE_WEB_PORT\" > /dev/null; then\n            print_status \"Application mobile web accessible sur http://localhost:$MOBILE_WEB_PORT\"\n        else\n            print_error \"Application mobile web non accessible\"\n        fi\n    fi\n    \n    # Test de la base de données\n    print_info \"Test de la connexion à la base de données...\"\n    if psql -h localhost -U $DB_USER -d $DB_NAME -c \"SELECT 1;\" > /dev/null 2>&1; then\n        print_status \"Base de données accessible\"\n    else\n        print_error \"Base de données non accessible\"\n    fi\n}\n\n# ========================================\n# FONCTIONS D'ARRÊT\n# ========================================\n\nstop_services() {\n    print_header \"ARRÊT DES SERVICES\"\n    \n    # Arrêter l'application mobile web\n    if [ -f \"$MOBILE_WEB_PID_FILE\" ]; then\n        local mobile_pid=$(cat \"$MOBILE_WEB_PID_FILE\")\n        if kill -0 $mobile_pid 2>/dev/null; then\n            print_info \"Arrêt de l'application mobile web (PID: $mobile_pid)...\"\n            kill $mobile_pid\n            rm -f \"$MOBILE_WEB_PID_FILE\"\n            print_status \"Application mobile web arrêtée\"\n        fi\n    fi\n    \n    # Arrêter Odoo\n    if [ -f \"$ODOO_PID_FILE\" ]; then\n        local odoo_pid=$(cat \"$ODOO_PID_FILE\")\n        if kill -0 $odoo_pid 2>/dev/null; then\n            print_info \"Arrêt d'Odoo (PID: $odoo_pid)...\"\n            kill $odoo_pid\n            rm -f \"$ODOO_PID_FILE\"\n            print_status \"Odoo arrêté\"\n        fi\n    fi\n    \n    print_success \"Tous les services ont été arrêtés\"\n}\n\ncleanup_on_exit() {\n    echo \"\"\n    print_warning \"Signal d'arrêt reçu, nettoyage en cours...\"\n    stop_services\n    exit 0\n}\n\n# ========================================\n# FONCTION D'AFFICHAGE DES INFORMATIONS\n# ========================================\n\nshow_final_info() {\n    echo \"\"\n    print_header \"🎉 SAMA CONAI FULL STACK DÉMARRÉ AVEC SUCCÈS !\"\n    echo \"\"\n    \n    print_success \"🌐 Interface Odoo: ${WHITE}http://localhost:$ODOO_PORT${NC}\"\n    if [ -f \"$MOBILE_WEB_PID_FILE\" ]; then\n        print_success \"📱 Application Mobile Web: ${WHITE}http://localhost:$MOBILE_WEB_PORT${NC}\"\n    fi\n    print_success \"🗄️ Base de données: ${WHITE}$DB_NAME${NC}\"\n    \n    echo \"\"\n    print_header \"🔑 COMPTES DE CONNEXION:\"\n    echo -e \"${WHITE}   👑 Admin Odoo:${NC} admin / admin\"\n    echo -e \"${WHITE}   📱 Mobile Demo:${NC} demo@sama-conai.sn / demo123\"\n    \n    echo \"\"\n    print_header \"📊 SERVICES ACTIFS:\"\n    if [ -f \"$ODOO_PID_FILE\" ]; then\n        echo -e \"${WHITE}   🔧 Odoo:${NC} PID $(cat $ODOO_PID_FILE) - Port $ODOO_PORT\"\n    fi\n    if [ -f \"$MOBILE_WEB_PID_FILE\" ]; then\n        echo -e \"${WHITE}   📱 Mobile Web:${NC} PID $(cat $MOBILE_WEB_PID_FILE) - Port $MOBILE_WEB_PORT\"\n    fi\n    echo -e \"${WHITE}   🗄️ PostgreSQL:${NC} Port $POSTGRES_PORT\"\n    \n    echo \"\"\n    print_header \"📁 LOGS ET FICHIERS:\"\n    echo -e \"${WHITE}   📋 Logs Odoo:${NC} $ODOO_LOG\"\n    if [ -f \"$MOBILE_WEB_PID_FILE\" ]; then\n        echo -e \"${WHITE}   📋 Logs Mobile:${NC} $MOBILE_WEB_LOG\"\n    fi\n    echo -e \"${WHITE}   🔧 PIDs:${NC} $SCRIPT_DIR/.pids/\"\n    \n    echo \"\"\n    print_header \"🛠️ COMMANDES UTILES:\"\n    echo -e \"${WHITE}   🔄 Redémarrer:${NC} $0 restart\"\n    echo -e \"${WHITE}   🛑 Arrêter:${NC} $0 stop\"\n    echo -e \"${WHITE}   📊 Statut:${NC} $0 status\"\n    echo -e \"${WHITE}   📋 Logs Odoo:${NC} tail -f $ODOO_LOG\"\n    if [ -f \"$MOBILE_WEB_PID_FILE\" ]; then\n        echo -e \"${WHITE}   📋 Logs Mobile:${NC} tail -f $MOBILE_WEB_LOG\"\n    fi\n    \n    if [ -d \"$SCRIPT_DIR/mobile_app\" ]; then\n        echo \"\"\n        print_header \"📱 APPLICATION MOBILE REACT NATIVE:\"\n        echo -e \"${WHITE}   🚀 Démarrer Metro:${NC} cd mobile_app && npm start\"\n        echo -e \"${WHITE}   🤖 Android:${NC} cd mobile_app && npm run android\"\n        echo -e \"${WHITE}   🍎 iOS:${NC} cd mobile_app && npm run ios\"\n    fi\n    \n    echo \"\"\n    print_success \"💡 ${WHITE}Ouvrez http://localhost:$ODOO_PORT dans votre navigateur${NC}\"\n    print_success \"🇸🇳 ${WHITE}Plateforme de transparence du Sénégal opérationnelle !${NC}\"\n    \n    echo \"\"\n    print_header \"🌟 SAMA CONAI FULL STACK OPÉRATIONNEL !\"\n    echo \"\"\n}\n\nshow_status() {\n    print_header \"STATUT DES SERVICES SAMA CONAI\"\n    \n    # Statut Odoo\n    if [ -f \"$ODOO_PID_FILE\" ] && kill -0 $(cat \"$ODOO_PID_FILE\") 2>/dev/null; then\n        print_status \"Odoo: EN COURS (PID: $(cat $ODOO_PID_FILE), Port: $ODOO_PORT)\"\n    else\n        print_error \"Odoo: ARRÊTÉ\"\n    fi\n    \n    # Statut application mobile web\n    if [ -f \"$MOBILE_WEB_PID_FILE\" ] && kill -0 $(cat \"$MOBILE_WEB_PID_FILE\") 2>/dev/null; then\n        print_status \"Application Mobile Web: EN COURS (PID: $(cat $MOBILE_WEB_PID_FILE), Port: $MOBILE_WEB_PORT)\"\n    else\n        print_error \"Application Mobile Web: ARRÊTÉE\"\n    fi\n    \n    # Statut PostgreSQL\n    if pgrep -x \"postgres\" > /dev/null; then\n        print_status \"PostgreSQL: EN COURS (Port: $POSTGRES_PORT)\"\n    else\n        print_error \"PostgreSQL: ARRÊTÉ\"\n    fi\n    \n    echo \"\"\n}\n\n# ========================================\n# FONCTION PRINCIPALE\n# ========================================\n\nmain() {\n    local action=\"${1:-start}\"\n    \n    case \"$action\" in\n        \"start\")\n            print_banner\n            check_prerequisites\n            check_directories\n            check_ports\n            start_postgresql\n            setup_database\n            install_mobile_dependencies\n            start_odoo\n            start_mobile_web\n            start_mobile_app\n            test_services\n            show_final_info\n            \n            # Garder le script actif\n            print_info \"Appuyez sur Ctrl+C pour arrêter tous les services\"\n            trap cleanup_on_exit INT TERM\n            wait\n            ;;\n        \"stop\")\n            print_banner\n            stop_services\n            ;;\n        \"restart\")\n            print_banner\n            stop_services\n            sleep 3\n            exec \"$0\" start\n            ;;\n        \"status\")\n            print_banner\n            show_status\n            ;;\n        \"logs\")\n            print_header \"AFFICHAGE DES LOGS\"\n            if [ -f \"$ODOO_LOG\" ]; then\n                echo \"=== LOGS ODOO ===\"\n                tail -n 50 \"$ODOO_LOG\"\n            fi\n            if [ -f \"$MOBILE_WEB_LOG\" ]; then\n                echo \"\"\n                echo \"=== LOGS MOBILE WEB ===\"\n                tail -n 50 \"$MOBILE_WEB_LOG\"\n            fi\n            ;;\n        \"help\")\n            print_banner\n            echo \"Usage: $0 [COMMAND]\"\n            echo \"\"\n            echo \"Commands:\"\n            echo \"  start     Démarrer tous les services (défaut)\"\n            echo \"  stop      Arrêter tous les services\"\n            echo \"  restart   Redémarrer tous les services\"\n            echo \"  status    Afficher le statut des services\"\n            echo \"  logs      Afficher les logs récents\"\n            echo \"  help      Afficher cette aide\"\n            echo \"\"\n            ;;\n        *)\n            print_error \"Commande inconnue: $action\"\n            echo \"Utilisez '$0 help' pour voir les commandes disponibles\"\n            exit 1\n            ;;\n    esac\n}\n\n# ========================================\n# EXÉCUTION\n# ========================================\n\n# Vérifier que le script est exécuté depuis le bon répertoire\nif [ ! -f \"$SCRIPT_DIR/__manifest__.py\" ]; then\n    print_error \"Ce script doit être exécuté depuis le répertoire du module SAMA CONAI\"\n    exit 1\nfi\n\n# Exécuter la fonction principale\nmain \"$@\""