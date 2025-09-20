#!/bin/bash

# Script de lancement SAMA CONAI Premium v4.0
# Application mobile révolutionnaire avec design high-end

echo "🚀 LANCEMENT SAMA CONAI PREMIUM v4.0"
echo "====================================="

# Variables
APP_DIR="mobile_app_premium"
PORT=3002
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
        print_info "Téléchargement: https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | sed 's/v//')
    print_status "Node.js détecté: v$NODE_VERSION"
    
    # Vérification de la version minimale (simplifiée)
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1)
    if [ "$MAJOR_VERSION" -lt 16 ]; then
        print_warning "Version Node.js recommandée: $NODE_MIN_VERSION ou supérieure"
        print_info "Version actuelle: v$NODE_VERSION"
    fi
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
        print_info "Assurez-vous d'être dans le bon répertoire"
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
        
        # Trouver le processus
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

# Installation des dépendances
install_dependencies() {
    print_header "📦 INSTALLATION DES DÉPENDANCES"
    
    cd "$APP_DIR"
    
    if [ ! -d "node_modules" ]; then
        print_info "Installation des dépendances npm..."
        npm install
        
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
    
    # Arrêter les processus Node.js sur le port
    pkill -f "node.*server.js" 2>/dev/null || true
    pkill -f "sama.*premium" 2>/dev/null || true
    
    # Attendre un peu
    sleep 1
    
    print_status "Nettoyage terminé"
}

# Démarrage du serveur
start_server() {
    print_header "🌐 DÉMARRAGE DU SERVEUR"
    
    cd "$APP_DIR"
    
    print_info "Démarrage du serveur SAMA CONAI Premium..."
    print_info "Port: $PORT"
    print_info "Mode: Production"
    
    # Créer le fichier de log
    LOG_FILE="sama_premium.log"
    
    # Démarrer le serveur en arrière-plan
    nohup node server.js > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    
    # Attendre le démarrage
    print_info "Attente du démarrage du serveur..."
    sleep 3
    
    # Vérifier que le serveur fonctionne
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        # Tester la connexion HTTP
        if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
            print_status "Serveur démarré avec succès !"
            print_info "PID du serveur: $SERVER_PID"
            
            # Sauvegarder le PID
            echo $SERVER_PID > sama_premium.pid
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
    print_header "🎉 SAMA CONAI PREMIUM v4.0 LANCÉ AVEC SUCCÈS !"
    print_header "=============================================="
    echo ""
    
    print_success "🌐 URL d'accès: ${WHITE}http://localhost:$PORT${NC}"
    print_success "📱 Interface: ${WHITE}Ultra-moderne avec glassmorphism${NC}"
    print_success "🔐 Authentification: ${WHITE}JWT + WebSockets temps réel${NC}"
    print_success "🎮 Gamification: ${WHITE}Niveaux, points, badges${NC}"
    print_success "🤖 Assistant IA: ${WHITE}Conversationnel intégré${NC}"
    print_success "🔔 Notifications: ${WHITE}Push temps réel${NC}"
    print_success "🎨 Thèmes: ${WHITE}Clair/Sombre/Auto/Gouvernement${NC}"
    print_success "👥 Rôles: ${WHITE}Admin/Agent/Citoyen différenciés${NC}"
    print_success "📊 Analytics: ${WHITE}Métriques en temps réel${NC}"
    
    echo ""
    print_header "📋 FONCTIONNALITÉS RÉVOLUTIONNAIRES:"
    echo -e "${CYAN}   🔮 Design glassmorphism et neumorphism${NC}"
    echo -e "${CYAN}   ✨ Animations fluides et micro-interactions${NC}"
    echo -e "${CYAN}   🎯 Theme switcher avancé${NC}"
    echo -e "${CYAN}   🚀 Dashboards adaptatifs par rôle${NC}"
    echo -e "${CYAN}   🔔 Notifications intelligentes${NC}"
    echo -e "${CYAN}   🤖 Assistant IA conversationnel${NC}"
    echo -e "${CYAN}   🏆 Système de gamification complet${NC}"
    echo -e "${CYAN}   📱 PWA avec mode offline${NC}"
    echo -e "${CYAN}   🌐 WebSockets pour temps réel${NC}"
    echo -e "${CYAN}   🎨 Interface ultra-moderne${NC}"
    
    echo ""
    print_header "🔑 COMPTES DE DÉMONSTRATION:"
    echo -e "${WHITE}   👑 Admin:${NC} admin@sama-conai.sn / admin123"
    echo -e "${WHITE}   🛡️ Agent:${NC} agent@sama-conai.sn / agent123"
    echo -e "${WHITE}   👤 Citoyen:${NC} citoyen@email.com / citoyen123"
    
    echo ""
    print_header "🔧 GESTION DU SERVEUR:"
    echo -e "${WHITE}   📋 Logs:${NC} tail -f $APP_DIR/sama_premium.log"
    echo -e "${WHITE}   🛑 Arrêt:${NC} kill $(cat $APP_DIR/sama_premium.pid 2>/dev/null || echo 'PID_INCONNU')"
    echo -e "${WHITE}   🔄 Redémarrage:${NC} ./launch_sama_conai_premium.sh"
    echo -e "${WHITE}   📊 Statut:${NC} ps -p $(cat $APP_DIR/sama_premium.pid 2>/dev/null || echo '0')"
    
    echo ""
    print_header "🌟 INNOVATIONS TECHNIQUES:"
    echo -e "${PURPLE}   • Glassmorphism avec backdrop-filter${NC}"
    echo -e "${PURPLE}   • Animations CSS avancées avec keyframes${NC}"
    echo -e "${PURPLE}   • WebSockets pour notifications temps réel${NC}"
    echo -e "${PURPLE}   • Système de gamification avec badges${NC}"
    echo -e "${PURPLE}   • Assistant IA avec suggestions contextuelles${NC}"
    echo -e "${PURPLE}   • Theme switcher avec transitions fluides${NC}"
    echo -e "${PURPLE}   • Dashboards adaptatifs selon les rôles${NC}"
    echo -e "${PURPLE}   • Micro-interactions et feedback haptique${NC}"
    echo -e "${PURPLE}   • Progressive Web App (PWA)${NC}"
    echo -e "${PURPLE}   • Architecture modulaire et extensible${NC}"
    
    echo ""
    print_success "💡 ${WHITE}Ouvrez http://localhost:$PORT dans votre navigateur${NC}"
    print_success "🚀 ${WHITE}Découvrez l'avenir de la transparence gouvernementale !${NC}"
    
    echo ""
    print_header "🎯 L'APPLICATION PREMIUM EST PRÊTE !"
    echo ""
}

# Fonction principale
main() {
    # Bannière de démarrage
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    SAMA CONAI PREMIUM v4.0                   ║${NC}"
    echo -e "${PURPLE}║              Transparence Gouvernementale Révolutionnaire    ║${NC}"
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
    
    echo ""
    
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