#!/bin/bash

# Script de lancement SAMA CONAI UX Révolutionnaire v6.0
# Application mobile avec design inspiré des meilleurs UX

echo "🎨 LANCEMENT SAMA CONAI UX RÉVOLUTIONNAIRE v6.0"
echo "==============================================="

# Variables
APP_DIR="mobile_app_ux_inspired"
PORT=3004
NODE_MIN_VERSION="16.0.0"

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

print_ux() {
    echo -e "${MAGENTA}✨${NC} $1"
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
    
    if [ ! -f "$APP_DIR/package.json" ]; then
        print_error "Fichier package.json non trouvé dans $APP_DIR"
        exit 1
    fi
    
    if [ ! -f "$APP_DIR/server.js" ]; then
        print_error "Fichier server.js non trouvé dans $APP_DIR"
        exit 1
    fi
    
    print_status "Structure de l'application UX validée"
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

# Installation des dépendances
install_dependencies() {
    print_header "📦 INSTALLATION DES DÉPENDANCES UX"
    
    cd "$APP_DIR"
    
    if [ ! -d "node_modules" ]; then
        print_info "Installation des dépendances npm pour l'UX révolutionnaire..."
        npm install --production --silent
        
        if [ $? -eq 0 ]; then
            print_status "Dépendances UX installées avec succès"
        else
            print_error "Erreur lors de l'installation des dépendances"
            exit 1
        fi
    else
        print_status "Dépendances UX déjà installées"
    fi
    
    cd ..
}

# Nettoyage des processus existants
cleanup_processes() {
    print_info "Nettoyage des processus UX existants..."
    
    pkill -f "node.*server.js" 2>/dev/null || true
    pkill -f "sama.*ux" 2>/dev/null || true
    
    sleep 1
    print_status "Nettoyage terminé"
}

# Démarrage du serveur UX
start_server() {
    print_header "🎨 DÉMARRAGE DU SERVEUR UX RÉVOLUTIONNAIRE"
    
    cd "$APP_DIR"
    
    print_ux "Démarrage du serveur SAMA CONAI UX Révolutionnaire..."
    print_info "Port: $PORT"
    print_info "Mode: UX Inspiré des Meilleurs Designs"
    
    LOG_FILE="ux_inspired.log"
    
    # Démarrer le serveur en arrière-plan
    nohup node server.js > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    
    # Attendre le démarrage
    print_info "Attente du démarrage du serveur UX..."
    sleep 3
    
    # Vérifier que le serveur fonctionne
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        # Tester la connexion HTTP
        if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
            print_status "Serveur UX démarré avec succès !"
            print_info "PID du serveur: $SERVER_PID"
            
            # Sauvegarder le PID
            echo $SERVER_PID > ux_inspired.pid
        else
            print_error "Le serveur UX ne répond pas sur le port $PORT"
            print_info "Vérifiez les logs: tail -f $APP_DIR/$LOG_FILE"
            exit 1
        fi
    else
        print_error "Échec du démarrage du serveur UX"
        print_info "Vérifiez les logs: cat $APP_DIR/$LOG_FILE"
        exit 1
    fi
    
    cd ..
}

# Affichage des informations finales
show_final_info() {
    print_header ""
    print_header "🎨 SAMA CONAI UX RÉVOLUTIONNAIRE v6.0 LANCÉ !"
    print_header "=============================================="
    echo ""
    
    print_success "🌐 URL d'accès: ${WHITE}http://localhost:$PORT${NC}"
    print_success "🎨 Design: ${WHITE}UX Inspiré des Meilleurs Designs${NC}"
    print_success "📱 Interface: ${WHITE}Mobile-First Révolutionnaire${NC}"
    print_success "✨ Animations: ${WHITE}Micro-interactions Fluides${NC}"
    print_success "🎯 Performance: ${WHITE}Optimisée 60fps${NC}"
    print_success "🌙 Thème: ${WHITE}Mode sombre élégant${NC}"
    print_success "🚀 Navigation: ${WHITE}Gestuelle avancée${NC}"
    
    echo ""
    print_header "🎨 INNOVATIONS UX RÉVOLUTIONNAIRES:"
    echo -e "${MAGENTA}   ✨ Glassmorphism et Neumorphism${NC}"
    echo -e "${MAGENTA}   🎭 Micro-interactions avancées${NC}"
    echo -e "${MAGENTA}   🌊 Animations fluides 60fps${NC}"
    echo -e "${MAGENTA}   🎨 Design system sophistiqué${NC}"
    echo -e "${MAGENTA}   📱 Navigation gestuelle${NC}"
    echo -e "${MAGENTA}   🌙 Mode sombre élégant${NC}"
    echo -e "${MAGENTA}   🎯 Transitions seamless${NC}"
    echo -e "${MAGENTA}   🔮 Effets de profondeur${NC}"
    
    echo ""
    print_header "🔑 COMPTES DE TEST:"
    echo -e "${WHITE}   👑 Admin:${NC} admin@sama-conai.sn / admin123"
    echo -e "${WHITE}   🛡️ Agent:${NC} agent@sama-conai.sn / agent123"
    echo -e "${WHITE}   👤 Citoyen:${NC} citoyen@email.com / citoyen123"
    
    echo ""
    print_header "🎨 DESIGN SYSTEM MODERNE:"
    echo -e "${CYAN}   🎨 Palette de couleurs sophistiquée${NC}"
    echo -e "${CYAN}   📏 Système d'espacement harmonieux${NC}"
    echo -e "${CYAN}   🔤 Typographie Inter + Space Grotesk${NC}"
    echo -e "${CYAN}   🌈 Gradients et ombres avancées${NC}"
    echo -e "${CYAN}   📐 Rayons de bordure cohérents${NC}"
    echo -e "${CYAN}   ⚡ Transitions fluides optimisées${NC}"
    
    echo ""
    print_header "📱 EXPÉRIENCE MOBILE RÉVOLUTIONNAIRE:"
    echo -e "${PURPLE}   📱 Design Mobile-First${NC}"
    echo -e "${PURPLE}   👆 Gestes tactiles intuitifs${NC}"
    echo -e "${PURPLE}   🎯 Zones de touche optimisées${NC}"
    echo -e "${PURPLE}   📳 Feedback haptique${NC}"
    echo -e "${PURPLE}   🔄 Navigation par swipe${NC}"
    echo -e "${PURPLE}   ✨ Animations contextuelles${NC}"
    
    echo ""
    print_header "🔧 GESTION DU SERVEUR:"
    echo -e "${WHITE}   📋 Logs:${NC} tail -f $APP_DIR/ux_inspired.log"
    echo -e "${WHITE}   🛑 Arrêt:${NC} kill $(cat $APP_DIR/ux_inspired.pid 2>/dev/null || echo 'PID_INCONNU')"
    echo -e "${WHITE}   🔄 Redémarrage:${NC} ./launch_ux_inspired.sh"
    echo -e "${WHITE}   📊 Statut:${NC} ps -p $(cat $APP_DIR/ux_inspired.pid 2>/dev/null || echo '0')"
    
    echo ""
    print_header "🎯 FONCTIONNALITÉS AVANCÉES:"
    echo -e "${CYAN}   🎨 Thème adaptatif (clair/sombre)${NC}"
    echo -e "${CYAN}   📊 Dashboard avec statistiques animées${NC}"
    echo -e "${CYAN}   📄 Gestion des demandes d'information${NC}"
    echo -e "${CYAN}   🚨 Système d'alertes et signalements${NC}"
    echo -e "${CYAN}   👤 Profil utilisateur personnalisé${NC}"
    echo -e "${CYAN}   🔔 Notifications intelligentes${NC}"
    
    echo ""
    print_success "💡 ${WHITE}Ouvrez http://localhost:$PORT dans votre navigateur${NC}"
    print_success "🎨 ${WHITE}Découvrez l'UX révolutionnaire inspirée des meilleurs designs !${NC}"
    
    echo ""
    print_header "🌟 L'APPLICATION UX RÉVOLUTIONNAIRE EST PRÊTE !"
    echo ""
}

# Fonction principale
main() {
    # Bannière de démarrage
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║              SAMA CONAI UX RÉVOLUTIONNAIRE v6.0              ║${NC}"
    echo -e "${MAGENTA}║         Application Mobile avec Design Révolutionnaire       ║${NC}"
    echo -e "${MAGENTA}║                                                              ║${NC}"
    echo -e "${MAGENTA}║  🇸🇳 République du Sénégal - Innovation UX/UI 2025          ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Vérifications préliminaires
    print_header "🔍 VÉRIFICATIONS PRÉLIMINAIRES"
    check_node
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