#!/bin/bash

# ============================================================================
# Script de lancement complet SAMA CONAI Mobile + Backend
# ============================================================================

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ODOO_PORT="8077"
MOBILE_PORT="3005"
PROXY_PORT="8078"
DB_NAME="sama_conai_test"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[ÉTAPE]${NC} $1"
}

print_banner() {
    echo -e "${CYAN}============================================================================${NC}"
    echo -e "${CYAN}                    🇸🇳 SAMA CONAI - LANCEMENT COMPLET 🇸🇳${NC}"
    echo -e "${CYAN}                     Application Mobile + Backend Odoo${NC}"
    echo -e "${CYAN}============================================================================${NC}"
    echo ""
}

check_dependencies() {
    log_step "Vérification des dépendances..."
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js n'est pas installé"
        exit 1
    fi
    log_info "Node.js: $(node --version)"
    
    # Vérifier Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 n'est pas installé"
        exit 1
    fi
    log_info "Python3: $(python3 --version)"
    
    # Vérifier PostgreSQL
    if ! command -v psql &> /dev/null; then
        log_error "PostgreSQL n'est pas installé"
        exit 1
    fi
    log_info "PostgreSQL: $(psql --version | head -n1)"
    
    log_success "Toutes les dépendances sont présentes"
}

check_ports() {
    log_step "Vérification des ports..."
    
    local ports=("$ODOO_PORT" "$MOBILE_PORT" "$PROXY_PORT")
    local port_names=("Odoo Backend" "Mobile App" "Proxy Odoo")
    
    for i in "${!ports[@]}"; do
        local port="${ports[$i]}"
        local name="${port_names[$i]}"
        
        if lsof -tiTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
            log_warning "Port $port ($name) est déjà utilisé"
            
            # Demander si on doit arrêter le processus
            read -p "Voulez-vous arrêter le processus sur le port $port ? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                local pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN)
                echo "$pids" | xargs -r kill -TERM
                sleep 2
                log_success "Processus arrêté sur le port $port"
            fi
        else
            log_info "Port $port ($name) disponible"
        fi
    done
}

start_odoo_backend() {
    log_step "Démarrage du backend Odoo..."
    
    # Vérifier si Odoo est déjà en cours
    if curl -s "http://localhost:$ODOO_PORT" >/dev/null 2>&1; then
        log_success "Backend Odoo déjà en cours sur le port $ODOO_PORT"
        return 0
    fi
    
    # Démarrer Odoo avec le script existant
    log_info "Lancement d'Odoo avec les API mobiles activées..."
    
    # Utiliser le script de lancement existant en arrière-plan
    nohup bash ./launch_sama_conai.sh --run -p "$ODOO_PORT" -d "$DB_NAME" >/dev/null 2>&1 &
    local odoo_pid=$!
    
    # Attendre que le serveur soit prêt
    log_info "Attente du démarrage d'Odoo..."
    local max_wait=60
    local count=0
    
    while [[ $count -lt $max_wait ]]; do
        if curl -s "http://localhost:$ODOO_PORT" >/dev/null 2>&1; then
            log_success "Backend Odoo prêt sur http://localhost:$ODOO_PORT"
            echo "$odoo_pid" > .odoo_backend.pid
            return 0
        fi
        
        sleep 2
        ((count += 2))
        
        if [[ $((count % 10)) -eq 0 ]]; then
            log_info "Attente... ($count/$max_wait secondes)"
        fi
    done
    
    log_error "Timeout: Backend Odoo n'a pas démarré dans les $max_wait secondes"
    return 1
}

start_mobile_app() {
    log_step "Démarrage de l'application mobile..."
    
    # Vérifier si l'app mobile est déjà en cours
    if curl -s "http://localhost:$MOBILE_PORT" >/dev/null 2>&1; then
        log_success "Application mobile déjà en cours sur le port $MOBILE_PORT"
        return 0
    fi
    
    # Aller dans le dossier mobile_app_web
    if [[ ! -d "mobile_app_web" ]]; then
        log_error "Dossier mobile_app_web introuvable"
        return 1
    fi
    
    cd mobile_app_web
    
    # Installer les dépendances si nécessaire
    if [[ ! -d "node_modules" ]]; then
        log_info "Installation des dépendances Node.js..."
        npm install
    fi
    
    # Configurer les variables d'environnement
    export ODOO_URL="http://localhost:$ODOO_PORT"
    export ODOO_DB="$DB_NAME"
    export PORT="$MOBILE_PORT"
    
    # Démarrer l'application mobile
    log_info "Lancement de l'application mobile..."
    nohup node server.js > mobile_app.log 2>&1 &
    local mobile_pid=$!
    
    cd ..
    
    # Attendre que l'application soit prête
    log_info "Attente du démarrage de l'application mobile..."
    local max_wait=30
    local count=0
    
    while [[ $count -lt $max_wait ]]; do
        if curl -s "http://localhost:$MOBILE_PORT" >/dev/null 2>&1; then
            log_success "Application mobile prête sur http://localhost:$MOBILE_PORT"
            echo "$mobile_pid" > .mobile_app.pid
            return 0
        fi
        
        sleep 1
        ((count++))
        
        if [[ $((count % 5)) -eq 0 ]]; then
            log_info "Attente... ($count/$max_wait secondes)"
        fi
    done
    
    log_error "Timeout: Application mobile n'a pas démarré dans les $max_wait secondes"
    return 1
}

start_proxy_server() {
    log_step "Démarrage du serveur proxy..."
    
    # Vérifier si le proxy est déjà en cours
    if curl -s "http://localhost:$PROXY_PORT" >/dev/null 2>&1; then
        log_success "Serveur proxy déjà en cours sur le port $PROXY_PORT"
        return 0
    fi
    
    # Aller dans le dossier mobile_app_web
    cd mobile_app_web
    
    # Démarrer le serveur proxy
    log_info "Lancement du serveur proxy Odoo..."
    nohup node proxy_server.js > proxy.log 2>&1 &
    local proxy_pid=$!
    
    cd ..
    
    # Attendre que le proxy soit prêt
    sleep 3
    
    if curl -s "http://localhost:$PROXY_PORT" >/dev/null 2>&1; then
        log_success "Serveur proxy prêt sur http://localhost:$PROXY_PORT"
        echo "$proxy_pid" > .proxy_server.pid
        return 0
    else
        log_warning "Le serveur proxy pourrait ne pas être complètement prêt"
        return 0
    fi
}

test_connectivity() {
    log_step "Test de connectivité..."
    
    # Test backend Odoo
    if curl -s "http://localhost:$ODOO_PORT/web/database/selector" >/dev/null 2>&1; then
        log_success "✅ Backend Odoo accessible"
    else
        log_error "❌ Backend Odoo non accessible"
    fi
    
    # Test application mobile
    if curl -s "http://localhost:$MOBILE_PORT" >/dev/null 2>&1; then
        log_success "✅ Application mobile accessible"
    else
        log_error "❌ Application mobile non accessible"
    fi
    
    # Test API mobile
    local api_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:$MOBILE_PORT/api/mobile/auth/login" -X POST -H "Content-Type: application/json" -d '{}')
    if [[ "$api_response" == "200" ]]; then
        log_success "✅ API mobile accessible"
    else
        log_warning "⚠️  API mobile répond avec le code: $api_response"
    fi
    
    # Test proxy
    if curl -s "http://localhost:$PROXY_PORT" >/dev/null 2>&1; then
        log_success "✅ Serveur proxy accessible"
    else
        log_warning "⚠️  Serveur proxy non accessible"
    fi
}

show_summary() {
    echo ""
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}                    🎉 SAMA CONAI LANCÉ AVEC SUCCÈS ! 🎉${NC}"
    echo -e "${GREEN}============================================================================${NC}"
    echo ""
    echo -e "${CYAN}📱 APPLICATION MOBILE:${NC}"
    echo -e "   🌐 URL: ${GREEN}http://localhost:$MOBILE_PORT${NC}"
    echo -e "   📱 Interface: Simulation mobile dans le navigateur"
    echo -e "   🔐 Login: admin / admin"
    echo ""
    echo -e "${CYAN}🏛️  BACKEND ODOO:${NC}"
    echo -e "   🌐 URL: ${GREEN}http://localhost:$ODOO_PORT${NC}"
    echo -e "   📊 Interface: Administration complète"
    echo -e "   🔐 Login: admin / admin"
    echo ""
    echo -e "${CYAN}🔗 PROXY ODOO:${NC}"
    echo -e "   🌐 URL: ${GREEN}http://localhost:$PROXY_PORT${NC}"
    echo -e "   📊 Interface: Backend via proxy (pour iframe)"
    echo ""
    echo -e "${CYAN}🚀 FONCTIONNALITÉS DISPONIBLES:${NC}"
    echo -e "   ✅ Interface mobile neumorphique"
    echo -e "   ✅ Authentification avec backend Odoo"
    echo -e "   ✅ API REST complète"
    echo -e "   ✅ Gestion des demandes d'information"
    echo -e "   ✅ Tableau de bord en temps réel"
    echo -e "   ✅ Accès backend depuis l'app mobile"
    echo ""
    echo -e "${CYAN}📋 GESTION:${NC}"
    echo -e "   🛑 Arrêt: ${YELLOW}./stop_sama_conai_complete.sh${NC}"
    echo -e "   📋 Logs mobile: ${YELLOW}tail -f mobile_app_web/mobile_app.log${NC}"
    echo -e "   📋 Logs Odoo: ${YELLOW}tail -f .sama_conai_temp/logs/odoo-$ODOO_PORT.log${NC}"
    echo -e "   🔄 Redémarrage: ${YELLOW}./launch_mobile_complete.sh${NC}"
    echo ""
    echo -e "${GREEN}🎯 COMMENCEZ PAR OUVRIR: http://localhost:$MOBILE_PORT${NC}"
    echo ""
}

create_stop_script() {
    log_step "Création du script d'arrêt..."
    
    cat > stop_sama_conai_complete.sh << 'EOF'
#!/bin/bash

# Script d'arrêt complet SAMA CONAI

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo -e "${YELLOW}🛑 ARRÊT SAMA CONAI COMPLET${NC}"
echo "================================"

# Arrêter l'application mobile
if [[ -f ".mobile_app.pid" ]]; then
    local mobile_pid=$(cat .mobile_app.pid)
    if kill -0 "$mobile_pid" 2>/dev/null; then
        kill -TERM "$mobile_pid"
        log_success "Application mobile arrêtée (PID: $mobile_pid)"
    fi
    rm -f .mobile_app.pid
fi

# Arrêter le serveur proxy
if [[ -f ".proxy_server.pid" ]]; then
    local proxy_pid=$(cat .proxy_server.pid)
    if kill -0 "$proxy_pid" 2>/dev/null; then
        kill -TERM "$proxy_pid"
        log_success "Serveur proxy arrêté (PID: $proxy_pid)"
    fi
    rm -f .proxy_server.pid
fi

# Arrêter le backend Odoo
if [[ -f ".odoo_backend.pid" ]]; then
    local odoo_pid=$(cat .odoo_backend.pid)
    if kill -0 "$odoo_pid" 2>/dev/null; then
        kill -TERM "$odoo_pid"
        log_success "Backend Odoo arrêté (PID: $odoo_pid)"
    fi
    rm -f .odoo_backend.pid
fi

# Arrêter tous les processus sur les ports
for port in 8077 3005 8078; do
    local pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs -r kill -TERM
        log_info "Processus arrêtés sur le port $port"
    fi
done

log_success "🎯 SAMA CONAI complètement arrêté"
EOF

    chmod +x stop_sama_conai_complete.sh
    log_success "Script d'arrêt créé: stop_sama_conai_complete.sh"
}

# ============================================================================
# FONCTION PRINCIPALE
# ============================================================================

main() {
    print_banner
    
    # Vérifications préliminaires
    check_dependencies
    check_ports
    
    # Démarrage des services
    if start_odoo_backend; then
        log_success "✅ Backend Odoo démarré"
    else
        log_error "❌ Échec du démarrage du backend Odoo"
        exit 1
    fi
    
    if start_mobile_app; then
        log_success "✅ Application mobile démarrée"
    else
        log_error "❌ Échec du démarrage de l'application mobile"
        exit 1
    fi
    
    if start_proxy_server; then
        log_success "✅ Serveur proxy démarré"
    else
        log_warning "⚠️  Serveur proxy non démarré (optionnel)"
    fi
    
    # Tests de connectivité
    test_connectivity
    
    # Créer le script d'arrêt
    create_stop_script
    
    # Afficher le résumé
    show_summary
}

# Gestion des signaux pour arrêt propre
trap 'echo -e "\n${YELLOW}Arrêt en cours...${NC}"; exit 0' INT TERM

# Exécution
main "$@"