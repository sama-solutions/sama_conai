#!/bin/bash

# Script de lancement final SAMA CONAI UX avec données Odoo
# Application mobile révolutionnaire avec intégration Odoo

echo "🚀 LANCEMENT FINAL SAMA CONAI UX AVEC DONNÉES ODOO"
echo "=================================================="

# Variables
APP_DIR="mobile_app_ux_inspired"
PORT=3004
ODOO_PORT=8077

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

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

# Vérification des prérequis
check_prerequisites() {
    print_info "Vérification des prérequis..."
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js n'est pas installé"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    print_status "Node.js détecté: $NODE_VERSION"
    
    # Vérifier le répertoire
    if [ ! -d "$APP_DIR" ]; then
        print_error "Répertoire $APP_DIR non trouvé"
        exit 1
    fi
    
    if [ ! -f "$APP_DIR/server_odoo_integrated.js" ]; then
        print_error "Fichier server_odoo_integrated.js non trouvé"
        exit 1
    fi
    
    print_status "Structure de l'application validée"
}

# Nettoyage des processus existants
cleanup_processes() {
    print_info "Nettoyage des processus existants..."
    
    # Arrêter les serveurs existants
    pkill -f "server_odoo_integrated.js" 2>/dev/null || true
    pkill -f "server_simple.js" 2>/dev/null || true
    
    # Attendre un peu
    sleep 2
    
    print_status "Nettoyage terminé"
}

# Vérification du port
check_port() {
    print_info "Vérification du port $PORT..."
    
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port $PORT déjà utilisé"
        PID=$(lsof -ti:$PORT)
        if [ ! -z "$PID" ]; then
            print_info "Arrêt du processus utilisant le port (PID: $PID)"
            kill $PID 2>/dev/null || true
            sleep 3
        fi
    fi
    
    if ! lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_status "Port $PORT disponible"
    else
        print_error "Impossible de libérer le port $PORT"
        exit 1
    fi
}

# Vérification d'Odoo
check_odoo() {
    print_info "Vérification d'Odoo sur le port $ODOO_PORT..."
    
    if curl -s --connect-timeout 5 "http://localhost:$ODOO_PORT" > /dev/null 2>&1; then
        print_status "Odoo accessible sur le port $ODOO_PORT"
        return 0
    else
        print_warning "Odoo non accessible sur le port $ODOO_PORT"
        print_info "L'application fonctionnera avec des données simulées enrichies"
        return 1
    fi
}

# Démarrage du serveur
start_server() {
    print_header "🚀 DÉMARRAGE DU SERVEUR SAMA CONAI UX"
    
    cd "$APP_DIR"
    
    # Configuration des variables d'environnement
    export ODOO_URL="http://localhost:$ODOO_PORT"
    export ODOO_DB="sama_conai_analytics"
    export ODOO_USER="admin"
    export ODOO_PASSWORD="admin"
    export PORT="$PORT"
    
    print_info "Démarrage du serveur avec intégration Odoo..."
    
    # Démarrer le serveur
    node server_odoo_integrated.js &
    SERVER_PID=$!
    
    # Sauvegarder le PID
    echo $SERVER_PID > server.pid
    
    print_info "Serveur démarré avec PID: $SERVER_PID"
    
    # Attendre le démarrage
    print_info "Attente du démarrage du serveur..."
    sleep 5
    
    # Vérifier que le serveur fonctionne
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        # Tester la connexion HTTP
        if curl -s --connect-timeout 5 "http://localhost:$PORT" > /dev/null 2>&1; then
            print_status "Serveur démarré avec succès !"
            return 0
        else
            print_error "Le serveur ne répond pas sur le port $PORT"
            return 1
        fi
    else
        print_error "Le serveur s'est arrêté de manière inattendue"
        return 1
    fi
    
    cd ..
}

# Test de l'application
test_application() {
    print_info "Test de l'application..."
    
    # Test de l'API
    if curl -s "http://localhost:$PORT/api/dashboard" > /dev/null; then
        print_status "API fonctionnelle"
    else
        print_warning "API non accessible"
    fi
    
    # Test de l'interface
    if curl -s "http://localhost:$PORT" | grep -q "SAMA CONAI"; then
        print_status "Interface accessible"
    else
        print_warning "Interface non accessible"
    fi
}

# Affichage des informations finales
show_final_info() {
    echo ""
    print_header "🎉 SAMA CONAI UX RÉVOLUTIONNAIRE LANCÉ AVEC SUCCÈS !"
    print_header "====================================================="
    echo ""
    
    print_success "🌐 URL d'accès: ${WHITE}http://localhost:$PORT${NC}"
    print_success "🎨 Design: ${WHITE}UX Révolutionnaire avec Drilldown${NC}"
    print_success "📱 Interface: ${WHITE}Mobile-First Optimisée${NC}"
    print_success "✨ Animations: ${WHITE}Micro-interactions Fluides${NC}"
    print_success "📊 Données: ${WHITE}Simulées Enrichies (Structure Odoo)${NC}"
    
    echo ""
    print_header "🔧 GESTION DU SERVEUR:"
    echo -e "${WHITE}   📊 Statut:${NC} ps -p $(cat $APP_DIR/server.pid 2>/dev/null || echo '0')"
    echo -e "${WHITE}   🛑 Arrêt:${NC} kill $(cat $APP_DIR/server.pid 2>/dev/null || echo 'PID_INCONNU')"
    echo -e "${WHITE}   🔄 Redémarrage:${NC} ./launch_final_sama_conai.sh"
    
    echo ""
    print_header "🎯 FONCTIONNALITÉS DISPONIBLES:"
    echo -e "${CYAN}   📊 Dashboard avec statistiques en temps réel${NC}"
    echo -e "${CYAN}   📄 Gestion des demandes d'information${NC}"
    echo -e "${CYAN}   🚨 Système d'alertes et signalements${NC}"
    echo -e "${CYAN}   🔍 Navigation avec drilldown complet${NC}"
    echo -e "${CYAN}   📱 Interface mobile révolutionnaire${NC}"
    echo -e "${CYAN}   🎨 Design system moderne${NC}"
    
    echo ""
    print_header "🔑 COMPTES DE TEST:"
    echo -e "${WHITE}   👑 Admin:${NC} admin@sama-conai.sn / admin123"
    echo -e "${WHITE}   🛡️ Agent:${NC} agent@sama-conai.sn / agent123"
    echo -e "${WHITE}   👤 Citoyen:${NC} citoyen@email.com / citoyen123"
    
    echo ""
    print_success "💡 ${WHITE}Ouvrez http://localhost:$PORT dans votre navigateur${NC}"
    print_success "🇸🇳 ${WHITE}Découvrez l'application de transparence la plus avancée du Sénégal !${NC}"
    
    echo ""
    print_header "🌟 APPLICATION SAMA CONAI UX RÉVOLUTIONNAIRE OPÉRATIONNELLE !"
    echo ""
}

# Fonction principale
main() {
    # Bannière de démarrage
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         SAMA CONAI UX RÉVOLUTIONNAIRE v6.0 FINAL            ║${NC}"
    echo -e "${PURPLE}║      Application Mobile avec Données Simulées Enrichies     ║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║  🇸🇳 République du Sénégal - Innovation UX/UI Avancée       ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Vérifications
    check_prerequisites
    cleanup_processes
    check_port
    
    # Vérifier Odoo (optionnel)
    check_odoo
    
    # Démarrage
    if start_server; then
        test_application
        show_final_info
        
        # Garder le script actif
        print_info "Appuyez sur Ctrl+C pour arrêter le serveur"
        wait
    else
        print_error "Échec du démarrage du serveur"
        exit 1
    fi
}

# Gestion des signaux
cleanup_on_exit() {
    echo ""
    print_warning "Arrêt du serveur en cours..."
    
    if [ -f "$APP_DIR/server.pid" ]; then
        PID=$(cat "$APP_DIR/server.pid")
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID 2>/dev/null || true
            print_status "Serveur arrêté (PID: $PID)"
        fi
        rm -f "$APP_DIR/server.pid"
    fi
    
    print_success "Arrêt terminé"
    exit 0
}

trap cleanup_on_exit INT TERM

# Exécution
main "$@"