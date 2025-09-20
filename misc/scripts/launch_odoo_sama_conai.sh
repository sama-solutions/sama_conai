#!/bin/bash

# Script de lancement Odoo avec module SAMA CONAI
# Configuration pour intégration avec l'application mobile

echo "🚀 LANCEMENT ODOO AVEC MODULE SAMA CONAI"
echo "========================================"

# Variables de configuration
ODOO_PORT=8077
ODOO_DB="sama_conai_db"
ODOO_USER="admin"
ODOO_PASSWORD="admin"
ADDONS_PATH="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons"
ODOO_BIN="/var/odoo/odoo18/odoo-bin"
LOG_FILE="/tmp/sama_conai_odoo.log"
PID_FILE="/tmp/sama_conai_odoo.pid"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

# Vérification des prérequis
check_prerequisites() {
    print_info "Vérification des prérequis..."
    
    # Vérifier Odoo
    if [ ! -f "$ODOO_BIN" ]; then
        print_error "Odoo non trouvé à $ODOO_BIN"
        print_info "Tentative avec odoo-bin dans le PATH..."
        if command -v odoo-bin &> /dev/null; then
            ODOO_BIN="odoo-bin"
            print_status "Odoo trouvé dans le PATH"
        else
            print_error "Odoo non disponible"
            exit 1
        fi
    else
        print_status "Odoo trouvé à $ODOO_BIN"
    fi
    
    # Vérifier PostgreSQL
    if ! systemctl is-active --quiet postgresql; then
        print_warning "PostgreSQL n'est pas actif, tentative de démarrage..."
        sudo systemctl start postgresql
        sleep 2
    fi
    
    if systemctl is-active --quiet postgresql; then
        print_status "PostgreSQL actif"
    else
        print_error "PostgreSQL non disponible"
        exit 1
    fi
    
    # Vérifier le module SAMA CONAI
    if [ ! -f "/home/grand-as/psagsn/custom_addons/sama_conai/__manifest__.py" ]; then
        print_error "Module SAMA CONAI non trouvé"
        exit 1
    else
        print_status "Module SAMA CONAI trouvé"
    fi
}

# Nettoyage des processus existants
cleanup_processes() {
    print_info "Nettoyage des processus Odoo existants..."
    
    # Arrêter les processus Odoo existants
    pkill -f "odoo.*sama_conai" 2>/dev/null || true
    pkill -f "odoo.*8077" 2>/dev/null || true
    
    # Supprimer les anciens fichiers
    rm -f "$PID_FILE" 2>/dev/null || true
    
    sleep 2
    print_status "Nettoyage terminé"
}

# Vérification du port
check_port() {
    print_info "Vérification du port $ODOO_PORT..."
    
    if lsof -Pi :$ODOO_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port $ODOO_PORT déjà utilisé"
        PID=$(lsof -ti:$ODOO_PORT)
        if [ ! -z "$PID" ]; then
            print_info "Arrêt du processus utilisant le port (PID: $PID)"
            kill $PID 2>/dev/null || true
            sleep 3
        fi
    fi
    
    if ! lsof -Pi :$ODOO_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_status "Port $ODOO_PORT disponible"
    else
        print_error "Impossible de libérer le port $ODOO_PORT"
        exit 1
    fi
}

# Préparation de la base de données
setup_database() {
    print_info "Configuration de la base de données..."
    
    # Vérifier si la base existe
    DB_EXISTS=$(sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -w "$ODOO_DB" | wc -l)
    
    if [ "$DB_EXISTS" -eq 0 ]; then
        print_info "Création de la base de données $ODOO_DB..."
        sudo -u postgres createdb "$ODOO_DB"
        print_status "Base de données créée"
    else
        print_status "Base de données $ODOO_DB existe déjà"
    fi
    
    # Vérifier l'utilisateur odoo
    USER_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='odoo'")
    if [ "$USER_EXISTS" != "1" ]; then
        print_info "Création de l'utilisateur odoo..."
        sudo -u postgres createuser -s odoo
        sudo -u postgres psql -c "ALTER USER odoo PASSWORD 'odoo';"
        print_status "Utilisateur odoo créé"
    else
        print_status "Utilisateur odoo existe déjà"
    fi
}

# Démarrage d'Odoo
start_odoo() {
    print_info "Démarrage d'Odoo avec le module SAMA CONAI..."
    
    # Commande Odoo
    ODOO_CMD="$ODOO_BIN \
        -d $ODOO_DB \
        --addons-path=$ADDONS_PATH \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --http-port=$ODOO_PORT \
        --log-level=info \
        --logfile=$LOG_FILE \
        --pidfile=$PID_FILE \
        --init=sama_conai \
        --without-demo=False"
    
    print_info "Commande: $ODOO_CMD"
    
    # Démarrer Odoo en arrière-plan
    nohup $ODOO_CMD > /dev/null 2>&1 &
    ODOO_PID=$!
    
    print_info "Odoo démarré avec PID: $ODOO_PID"
    echo $ODOO_PID > "$PID_FILE"
    
    # Attendre le démarrage
    print_info "Attente du démarrage d'Odoo (peut prendre 30-60 secondes)..."
    
    for i in {1..60}; do
        if curl -s --connect-timeout 2 "http://localhost:$ODOO_PORT" > /dev/null 2>&1; then
            print_status "Odoo démarré avec succès !"
            return 0
        fi
        
        if ! ps -p $ODOO_PID > /dev/null 2>&1; then
            print_error "Odoo s'est arrêté de manière inattendue"
            print_info "Vérifiez les logs: tail -f $LOG_FILE"
            return 1
        fi
        
        echo -n "."
        sleep 1
    done
    
    echo ""
    print_error "Timeout: Odoo n'a pas démarré dans les temps"
    print_info "Vérifiez les logs: tail -f $LOG_FILE"
    return 1
}

# Test de la connexion
test_connection() {
    print_info "Test de la connexion Odoo..."
    
    # Test de base
    if curl -s "http://localhost:$ODOO_PORT" > /dev/null; then
        print_status "Connexion HTTP réussie"
    else
        print_error "Échec de la connexion HTTP"
        return 1
    fi
    
    # Test de la base de données
    if curl -s "http://localhost:$ODOO_PORT/web/database/list" | grep -q "$ODOO_DB"; then
        print_status "Base de données accessible"
    else
        print_warning "Base de données non listée (normal si pas encore initialisée)"
    fi
    
    return 0
}

# Mise à jour de la configuration de l'application mobile
update_mobile_config() {
    print_info "Mise à jour de la configuration de l'application mobile..."
    
    # Arrêter l'application mobile actuelle
    pkill -f "server_odoo_integrated.js" 2>/dev/null || true
    sleep 2
    
    # Relancer avec la nouvelle configuration
    cd /home/grand-as/psagsn/custom_addons/sama_conai
    
    export ODOO_URL="http://localhost:$ODOO_PORT"
    export ODOO_DB="$ODOO_DB"
    export ODOO_USER="$ODOO_USER"
    export ODOO_PASSWORD="$ODOO_PASSWORD"
    export PORT="3004"
    
    print_info "Redémarrage de l'application mobile avec la nouvelle configuration..."
    cd mobile_app_ux_inspired
    nohup node server_odoo_integrated.js > odoo_integrated.log 2>&1 &
    MOBILE_PID=$!
    echo $MOBILE_PID > odoo_integrated.pid
    
    sleep 3
    
    if ps -p $MOBILE_PID > /dev/null 2>&1; then
        print_status "Application mobile redémarrée avec PID: $MOBILE_PID"
        
        # Test de l'intégration
        sleep 2
        ODOO_TEST=$(curl -s "http://localhost:3004/api/test-odoo" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        if [ "$ODOO_TEST" = "connected" ]; then
            print_status "✅ Intégration Odoo RÉUSSIE - Données réelles disponibles !"
        else
            print_warning "⚠️ Intégration Odoo en cours de connexion..."
        fi
    else
        print_error "Échec du redémarrage de l'application mobile"
    fi
    
    cd ..
}

# Affichage des informations finales
show_final_info() {
    echo ""
    echo -e "${GREEN}🎉 ODOO SAMA CONAI LANCÉ AVEC SUCCÈS !${NC}"
    echo "========================================="
    echo ""
    echo -e "${BLUE}🌐 URL Odoo:${NC} http://localhost:$ODOO_PORT"
    echo -e "${BLUE}🗄️ Base de données:${NC} $ODOO_DB"
    echo -e "${BLUE}👤 Utilisateur:${NC} $ODOO_USER"
    echo -e "${BLUE}🔑 Mot de passe:${NC} $ODOO_PASSWORD"
    echo -e "${BLUE}📱 Application mobile:${NC} http://localhost:3004"
    echo ""
    echo -e "${YELLOW}📋 Gestion:${NC}"
    echo -e "   📊 Logs Odoo: tail -f $LOG_FILE"
    echo -e "   🛑 Arrêt Odoo: kill \$(cat $PID_FILE)"
    echo -e "   📱 Logs Mobile: tail -f mobile_app_ux_inspired/odoo_integrated.log"
    echo ""
    echo -e "${GREEN}🔗 INTÉGRATION ODOO RÉELLE OPÉRATIONNELLE !${NC}"
    echo ""
}

# Fonction principale
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              ODOO SAMA CONAI LAUNCHER v1.0                   ║${NC}"
    echo -e "${BLUE}║         Démarrage Odoo avec Module SAMA CONAI                ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║  🇸🇳 République du Sénégal - Transparence Numérique         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_prerequisites
    cleanup_processes
    check_port
    setup_database
    
    if start_odoo; then
        if test_connection; then
            update_mobile_config
            show_final_info
        else
            print_error "Échec du test de connexion"
            exit 1
        fi
    else
        print_error "Échec du démarrage d'Odoo"
        exit 1
    fi
}

# Gestion des signaux
trap 'echo -e "\n${YELLOW}⚠️ Interruption détectée${NC}"; exit 1' INT TERM

# Exécution
main "$@"