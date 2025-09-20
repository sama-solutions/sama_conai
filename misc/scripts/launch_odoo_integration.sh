#!/bin/bash

# Script de lancement SAMA CONAI Odoo Integration v5.0
# Application mobile avec intégration Odoo seamless - 3 niveaux de navigation

echo "🚀 LANCEMENT SAMA CONAI ODOO INTEGRATION v5.0"
echo "=============================================="

# Variables
APP_DIR="mobile_app_odoo_integration"
PORT=3003
NODE_MIN_VERSION="16.0.0"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Fonction d'affichage coloré
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
    echo -e "${PURPLE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}🎉${NC} $1"
}

# Vérification de Node.js
check_node() {
    print_info "Vérification de Node.js..."
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js n'est pas installé"
        print_info "Veuillez installer Node.js version $NODE_MIN_VERSION ou supérieure"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | sed 's/v//')
    print_status "Node.js détecté: v$NODE_VERSION"
}

# Vérification de npm
check_npm() {
    print_info "Vérification de npm..."
    
    if ! command -v npm &> /dev/null; then
        print_error "npm n'est pas installé"
        exit 1
    fi
    
    NPM_VERSION=$(npm --version)
    print_status "npm détecté: v$NPM_VERSION"
}

# Vérification du répertoire
check_directory() {
    print_info "Vérification du répertoire de l'application..."
    
    if [ ! -d "$APP_DIR" ]; then
        print_error "Répertoire $APP_DIR non trouvé"
        exit 1
    fi
    
    if [ ! -f "$APP_DIR/package.json" ]; then
        print_error "Fichier package.json non trouvé dans $APP_DIR"
        exit 1
    fi
    
    if [ ! -f "$APP_DIR/server.js" ]; then
        print_error "Fichier server.js non trouvé dans $APP_DIR"
        exit 1
    fi
    
    print_status "Structure de l'application validée"
}

# Vérification du port
check_port() {
    print_info "Vérification de la disponibilité du port $PORT..."
    
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Le port $PORT est déjà utilisé"
        
        PID=$(lsof -ti:$PORT)
        if [ ! -z "$PID" ]; then
            PROCESS_NAME=$(ps -p $PID -o comm= 2>/dev/null || echo "inconnu")
            print_info "Processus utilisant le port: $PROCESS_NAME (PID: $PID)"
            
            read -p "Voulez-vous arrêter ce processus ? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                kill $PID 2>/dev/null
                sleep 2
                if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
                    print_error "Impossible d'arrêter le processus"
                    exit 1
                else
                    print_status "Processus arrêté avec succès"
                fi
            else
                print_error "Impossible de continuer avec le port $PORT occupé"
                exit 1
            fi
        fi
    else
        print_status "Port $PORT disponible"
    fi
}

# Vérification de la connexion Odoo
check_odoo() {
    print_info "Vérification de la connexion Odoo..."
    
    ODOO_URL=${ODOO_URL:-"http://localhost:8069"}
    
    if curl -s --connect-timeout 5 "$ODOO_URL" > /dev/null 2>&1; then
        print_status "Odoo accessible sur $ODOO_URL"
    else
        print_warning "Odoo non accessible sur $ODOO_URL"
        print_info "L'application fonctionnera en mode dégradé"
        print_info "Pour une intégration complète, assurez-vous qu'Odoo est démarré"
    fi
}

# Installation des dépendances
install_dependencies() {
    print_header "📦 INSTALLATION DES DÉPENDANCES"
    
    cd "$APP_DIR"
    
    if [ ! -d "node_modules" ]; then
        print_info "Installation des dépendances npm..."
        npm install --production
        
        if [ $? -eq 0 ]; then
            print_status "Dépendances installées avec succès"
        else
            print_error "Erreur lors de l'installation des dépendances"
            exit 1
        fi
    else
        print_info "Vérification des dépendances..."
        npm ci --only=production --silent
        print_status "Dépendances vérifiées"
    fi
    
    cd ..
}

# Nettoyage des processus existants
cleanup_processes() {
    print_info "Nettoyage des processus existants..."
    
    pkill -f "node.*server.js" 2>/dev/null || true
    pkill -f "sama.*odoo" 2>/dev/null || true
    
    sleep 1
    print_status "Nettoyage terminé"
}

# Configuration des variables d'environnement
setup_environment() {
    print_info "Configuration de l'environnement..."
    
    cd "$APP_DIR"
    
    # Créer le fichier .env s'il n'existe pas
    if [ ! -f ".env" ]; then
        cat > .env << EOF
# Configuration Odoo
ODOO_URL=http://localhost:8069
ODOO_DB=sama_conai_db
ODOO_USERNAME=admin
ODOO_PASSWORD=admin

# Configuration serveur
PORT=3003
JWT_SECRET=sama_conai_odoo_integration_secret_2025

# Mode de développement
NODE_ENV=production
EOF
        print_status "Fichier .env créé avec la configuration par défaut"
    else
        print_status "Fichier .env existant utilisé"
    fi
    
    cd ..
}

# Démarrage du serveur
start_server() {
    print_header "🌐 DÉMARRAGE DU SERVEUR"
    
    cd "$APP_DIR"
    
    print_info "Démarrage du serveur SAMA CONAI Odoo Integration..."
    print_info "Port: $PORT"
    print_info "Mode: Production avec intégration Odoo"
    
    LOG_FILE="odoo_integration.log"
    
    # Démarrer le serveur en arrière-plan
    nohup node server.js > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    
    # Attendre le démarrage
    print_info "Attente du démarrage du serveur..."
    sleep 5
    
    # Vérifier que le serveur fonctionne
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        # Tester la connexion HTTP
        if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
            print_status "Serveur démarré avec succès !"
            print_info "PID du serveur: $SERVER_PID"
            
            # Sauvegarder le PID
            echo $SERVER_PID > odoo_integration.pid
        else
            print_error "Le serveur ne répond pas sur le port $PORT"
            print_info "Vérifiez les logs: tail -f $APP_DIR/$LOG_FILE"
            exit 1
        fi
    else
        print_error "Échec du démarrage du serveur"
        print_info "Vérifiez les logs: cat $APP_DIR/$LOG_FILE"
        exit 1
    fi
    
    cd ..
}

# Affichage des informations finales
show_final_info() {
    print_header ""
    print_header "🎉 SAMA CONAI ODOO INTEGRATION v5.0 LANCÉ !"
    print_header "============================================="
    echo ""
    
    print_success "🌐 URL d'accès: ${WHITE}http://localhost:$PORT${NC}"
    print_success "🔗 Intégration: ${WHITE}Odoo seamless avec données réelles${NC}"
    print_success "📱 Navigation: ${WHITE}3 niveaux comme iframe Odoo${NC}"
    print_success "🔐 Authentification: ${WHITE}JWT + Sessions Odoo${NC}"
    print_success "📊 Données: ${WHITE}Temps réel depuis Odoo backend${NC}"
    print_success "🎨 Interface: ${WHITE}Style Odoo optimisé mobile${NC}"
    print_success "⚡ Performance: ${WHITE}API REST + Cache intelligent${NC}"
    
    echo ""
    print_header "📋 FONCTIONNALITÉS D'INTÉGRATION:"
    echo -e "${CYAN}   🔄 Synchronisation temps réel avec Odoo${NC}"
    echo -e "${CYAN}   📊 Dashboard avec données réelles${NC}"
    echo -e "${CYAN}   📄 CRUD complet sur demandes d'information${NC}"
    echo -e "${CYAN}   🚨 Gestion des alertes de signalement${NC}"
    echo -e "${CYAN}   👥 Gestion des rôles et permissions${NC}"
    echo -e "${CYAN}   🔍 Recherche et filtrage avancés${NC}"
    echo -e "${CYAN}   📱 Navigation 3 niveaux seamless${NC}"
    echo -e "${CYAN}   🎯 Interface style Odoo mobile${NC}"
    
    echo ""
    print_header "🔑 COMPTES DE TEST:"
    echo -e "${WHITE}   👑 Admin:${NC} admin@sama-conai.sn / admin123"
    echo -e "${WHITE}   🛡️ Agent:${NC} agent@sama-conai.sn / agent123"
    echo -e "${WHITE}   👤 Citoyen:${NC} citoyen@email.com / citoyen123"
    
    echo ""
    print_header "🔧 GESTION DU SERVEUR:"
    echo -e "${WHITE}   📋 Logs:${NC} tail -f $APP_DIR/odoo_integration.log"
    echo -e "${WHITE}   🛑 Arrêt:${NC} kill $(cat $APP_DIR/odoo_integration.pid 2>/dev/null || echo 'PID_INCONNU')"
    echo -e "${WHITE}   🔄 Redémarrage:${NC} ./launch_odoo_integration.sh"
    echo -e "${WHITE}   📊 Statut:${NC} ps -p $(cat $APP_DIR/odoo_integration.pid 2>/dev/null || echo '0')"
    echo -e "${WHITE}   🔗 Test Odoo:${NC} curl http://localhost:$PORT/api/test-odoo"
    
    echo ""
    print_header "🌟 NAVIGATION 3 NIVEAUX:"
    echo -e "${PURPLE}   📊 NIVEAU 1: Dashboard + Listes (Demandes, Alertes)${NC}"
    echo -e "${PURPLE}   📄 NIVEAU 2: Détails avec données complètes Odoo${NC}"
    echo -e "${PURPLE}   ✏️ NIVEAU 3: Formulaires d'édition et actions${NC}"
    echo -e "${PURPLE}   🔄 Navigation seamless avec breadcrumb${NC}"
    echo -e "${PURPLE}   📱 Interface optimisée mobile style Odoo${NC}"
    
    echo ""
    print_header "🔗 INTÉGRATION ODOO:"
    echo -e "${CYAN}   📡 API XML-RPC pour communication${NC}"
    echo -e "${CYAN}   🔐 Authentification automatique${NC}"
    echo -e "${CYAN}   📊 Données en temps réel${NC}"
    echo -e "${CYAN}   🔄 Synchronisation bidirectionnelle${NC}"
    echo -e "${CYAN}   ⚡ Cache intelligent pour performance${NC}"
    
    echo ""
    print_success "💡 ${WHITE}Ouvrez http://localhost:$PORT dans votre navigateur${NC}"
    print_success "🚀 ${WHITE}Découvrez l'intégration Odoo seamless !${NC}"
    
    echo ""
    print_header "🎯 L'APPLICATION ODOO INTEGRATION EST PRÊTE !"
    echo ""
}

# Fonction principale
main() {
    # Bannière de démarrage
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                SAMA CONAI ODOO INTEGRATION v5.0              ║${NC}"
    echo -e "${PURPLE}║           Application Mobile avec Intégration Seamless       ║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║  🇸🇳 République du Sénégal - Innovation Numérique 2025      ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Vérifications préliminaires
    print_header "🔍 VÉRIFICATIONS PRÉLIMINAIRES"
    check_node
    check_npm
    check_directory
    check_port
    check_odoo
    
    echo ""
    
    # Configuration
    setup_environment
    
    # Nettoyage
    cleanup_processes
    
    # Installation
    install_dependencies
    
    echo ""
    
    # Démarrage
    start_server
    
    echo ""
    
    # Informations finales
    show_final_info
}

# Gestion des signaux
trap 'echo -e "\n${YELLOW}⚠️ Interruption détectée${NC}"; exit 1' INT TERM

# Exécution
main "$@"