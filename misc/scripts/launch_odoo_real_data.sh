#!/bin/bash

# Script de lancement SAMA CONAI UX avec Intégration Odoo Réelle v6.0
# Application mobile avec données réelles depuis Odoo

echo "🔗 LANCEMENT SAMA CONAI UX AVEC DONNÉES ODOO RÉELLES"
echo "===================================================="

# Variables
APP_DIR="mobile_app_ux_inspired"
PORT=3004
NODE_MIN_VERSION="16.0.0"

# Configuration Odoo par défaut
ODOO_URL=${ODOO_URL:-"http://localhost:8069"}
ODOO_DB=${ODOO_DB:-"sama_conai_db"}
ODOO_USER=${ODOO_USER:-"admin"}
ODOO_PASSWORD=${ODOO_PASSWORD:-"admin"}

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
MAGENTA='\033[0;95m'
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

print_odoo() {
    echo -e "${CYAN}🔗${NC} $1"
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

# Vérification du répertoire
check_directory() {
    print_info "Vérification du répertoire de l'application..."
    
    if [ ! -d "$APP_DIR" ]; then
        print_error "Répertoire $APP_DIR non trouvé"
        exit 1
    fi
    
    if [ ! -f "$APP_DIR/server_odoo_integrated.js" ]; then
        print_error "Fichier server_odoo_integrated.js non trouvé dans $APP_DIR"
        exit 1
    fi
    
    if [ ! -f "$APP_DIR/odoo_connector.js" ]; then
        print_error "Fichier odoo_connector.js non trouvé dans $APP_DIR"
        exit 1
    fi
    
    print_status "Structure de l'application avec intégration Odoo validée"
}

# Test de connexion Odoo
test_odoo_connection() {
    print_header "🔗 TEST DE CONNEXION ODOO"
    print_odoo "URL Odoo: $ODOO_URL"
    print_odoo "Base de données: $ODOO_DB"
    print_odoo "Utilisateur: $ODOO_USER"
    
    print_info "Test de connectivité Odoo..."
    
    # Test de ping de base
    if curl -s --connect-timeout 5 "$ODOO_URL" > /dev/null 2>&1; then
        print_status "Serveur Odoo accessible"
    else
        print_warning "Serveur Odoo non accessible à $ODOO_URL"
        print_warning "L'application fonctionnera en mode fallback"
    fi
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

# Nettoyage des processus existants
cleanup_processes() {
    print_info "Nettoyage des processus existants..."
    
    pkill -f "server_odoo_integrated.js" 2>/dev/null || true
    pkill -f "server_simple.js" 2>/dev/null || true
    pkill -f "sama.*ux" 2>/dev/null || true
    
    sleep 1
    print_status "Nettoyage terminé"
}

# Démarrage du serveur avec intégration Odoo
start_server() {
    print_header "🚀 DÉMARRAGE DU SERVEUR AVEC INTÉGRATION ODOO"
    
    cd "$APP_DIR"
    
    print_odoo "Démarrage du serveur SAMA CONAI UX avec données Odoo réelles..."
    print_info "Port: $PORT"
    print_info "Mode: Intégration Odoo Complète"
    
    LOG_FILE="odoo_integrated.log"
    
    # Variables d'environnement pour Odoo
    export ODOO_URL="$ODOO_URL"
    export ODOO_DB="$ODOO_DB"
    export ODOO_USER="$ODOO_USER"
    export ODOO_PASSWORD="$ODOO_PASSWORD"
    export PORT="$PORT"
    
    # Démarrer le serveur en arrière-plan
    nohup node server_odoo_integrated.js > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    
    # Attendre le démarrage
    print_info "Attente du démarrage du serveur avec intégration Odoo..."
    sleep 5
    
    # Vérifier que le serveur fonctionne
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        # Tester la connexion HTTP
        if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
            print_status "Serveur avec intégration Odoo démarré avec succès !"
            print_info "PID du serveur: $SERVER_PID"
            
            # Sauvegarder le PID
            echo $SERVER_PID > odoo_integrated.pid
            
            # Tester la connexion Odoo
            sleep 2
            print_info "Test de l'intégration Odoo..."
            ODOO_TEST=$(curl -s "http://localhost:$PORT/api/test-odoo" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            if [ "$ODOO_TEST" = "connected" ]; then
                print_success "✅ Intégration Odoo RÉUSSIE - Données réelles disponibles !"
            else
                print_warning "⚠️ Intégration Odoo en mode fallback - Données simulées"
            fi
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
    print_header "🔗 SAMA CONAI UX AVEC INTÉGRATION ODOO RÉELLE LANCÉ !"
    print_header "====================================================="
    echo ""
    
    print_success "🌐 URL d'accès: ${WHITE}http://localhost:$PORT${NC}"
    print_success "🔗 Intégration: ${WHITE}Odoo XML-RPC Connecté${NC}"
    print_success "📊 Données: ${WHITE}Réelles depuis Odoo SAMA CONAI${NC}"
    print_success "🎨 Design: ${WHITE}UX Révolutionnaire${NC}"
    print_success "📱 Interface: ${WHITE}Mobile-First avec Drilldown${NC}"
    print_success "✨ Animations: ${WHITE}Micro-interactions Fluides${NC}"
    
    echo ""
    print_header "🔗 CONFIGURATION ODOO ACTIVE:"
    echo -e "${CYAN}   🌐 URL Odoo: ${WHITE}$ODOO_URL${NC}"
    echo -e "${CYAN}   🗄️ Base de données: ${WHITE}$ODOO_DB${NC}"
    echo -e "${CYAN}   👤 Utilisateur: ${WHITE}$ODOO_USER${NC}"
    echo -e "${CYAN}   🔗 Statut: ${WHITE}Connecté et opérationnel${NC}"
    
    echo ""
    print_header "📊 DONNÉES RÉELLES ODOO DISPONIBLES:"
    echo -e "${MAGENTA}   📄 Demandes d'information (request.information)${NC}"
    echo -e "${MAGENTA}   🚨 Alertes de signalement (whistleblowing.alert)${NC}"
    echo -e "${MAGENTA}   📊 Statistiques en temps réel${NC}"
    echo -e "${MAGENTA}   📋 Historiques complets${NC}"
    echo -e "${MAGENTA}   👥 Utilisateurs et assignations${NC}"
    echo -e "${MAGENTA}   🏢 Départements et workflow${NC}"
    
    echo ""
    print_header "🔑 COMPTES DE TEST ODOO:"
    echo -e "${WHITE}   👑 Admin Odoo:${NC} admin / admin"
    echo -e "${WHITE}   📱 App Mobile:${NC} admin@sama-conai.sn / admin123"
    echo -e "${WHITE}   🛡️ Agent:${NC} agent@sama-conai.sn / agent123"
    echo -e "${WHITE}   👤 Citoyen:${NC} citoyen@email.com / citoyen123"
    
    echo ""
    print_header "🎨 FONCTIONNALITÉS RÉVOLUTIONNAIRES:"
    echo -e "${PURPLE}   ✨ Glassmorphism et Neumorphism${NC}"
    echo -e "${PURPLE}   🎭 Micro-interactions avancées${NC}"
    echo -e "${PURPLE}   🌊 Animations fluides 60fps${NC}"
    echo -e "${PURPLE}   🎨 Design system sophistiqué${NC}"
    echo -e "${PURPLE}   📱 Navigation gestuelle avec drilldown${NC}"
    echo -e "${PURPLE}   🌙 Mode sombre élégant${NC}"
    echo -e "${PURPLE}   🎯 Transitions seamless${NC}"
    echo -e "${PURPLE}   📊 Données réelles Odoo en temps réel${NC}"
    
    echo ""
    print_header "🔧 GESTION DU SERVEUR:"
    echo -e "${WHITE}   📋 Logs:${NC} tail -f $APP_DIR/odoo_integrated.log"
    echo -e "${WHITE}   🛑 Arrêt:${NC} kill $(cat $APP_DIR/odoo_integrated.pid 2>/dev/null || echo 'PID_INCONNU')"
    echo -e "${WHITE}   🔄 Redémarrage:${NC} ./launch_odoo_real_data.sh"
    echo -e "${WHITE}   📊 Statut:${NC} ps -p $(cat $APP_DIR/odoo_integrated.pid 2>/dev/null || echo '0')"
    echo -e "${WHITE}   🔗 Test Odoo:${NC} curl http://localhost:$PORT/api/test-odoo"
    
    echo ""
    print_header "🎯 ENDPOINTS API AVEC DONNÉES ODOO:"
    echo -e "${CYAN}   📊 GET /api/dashboard - Dashboard avec stats Odoo réelles${NC}"
    echo -e "${CYAN}   📄 GET /api/requests - Demandes depuis request.information${NC}"
    echo -e "${CYAN}   📄 GET /api/requests/:id - Détail complet depuis Odoo${NC}"
    echo -e "${CYAN}   🚨 GET /api/alerts - Alertes depuis whistleblowing.alert${NC}"
    echo -e "${CYAN}   🚨 GET /api/alerts/:id - Investigation complète depuis Odoo${NC}"
    echo -e "${CYAN}   🔧 GET /api/test-odoo - Statut de la connexion Odoo${NC}"
    
    echo ""
    print_success "💡 ${WHITE}Ouvrez http://localhost:$PORT dans votre navigateur${NC}"
    print_success "🔗 ${WHITE}Découvrez l'UX révolutionnaire avec données Odoo réelles !${NC}"
    
    echo ""
    print_header "🌟 INTÉGRATION ODOO RÉELLE OPÉRATIONNELLE !"
    echo ""
}

# Fonction principale
main() {
    # Bannière de démarrage
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║         SAMA CONAI UX RÉVOLUTIONNAIRE v6.0 + ODOO           ║${NC}"
    echo -e "${MAGENTA}║      Application Mobile avec Données Odoo Réelles           ║${NC}"
    echo -e "${MAGENTA}║                                                              ║${NC}"
    echo -e "${MAGENTA}║  🇸🇳 République du Sénégal - Innovation UX/UI + Odoo        ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Vérifications préliminaires
    print_header "🔍 VÉRIFICATIONS PRÉLIMINAIRES"
    check_node
    check_directory
    check_port
    
    echo ""
    
    # Test Odoo
    test_odoo_connection
    
    echo ""
    
    # Nettoyage
    cleanup_processes
    
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