#!/bin/bash

# ========================================= #
# SAMA CONAI - ARRÊT INTERFACE ENRICHIE    #
# ========================================= #

echo "🛑 Arrêt de SAMA CONAI - Interface Enrichie"
echo "==========================================="

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Arrêt du serveur enrichi via PID
if [ -f "pids/sama_conai_enriched.pid" ]; then
    PID=$(cat pids/sama_conai_enriched.pid)
    print_info "Arrêt du serveur SAMA CONAI enrichi (PID: $PID)..."
    
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        sleep 2
        
        if kill -0 $PID 2>/dev/null; then
            print_warning "Arrêt forcé du processus..."
            kill -9 $PID
        fi
        
        print_success "Serveur enrichi arrêté avec succès"
        rm -f pids/sama_conai_enriched.pid
    else
        print_warning "Le processus n'était pas actif"
        rm -f pids/sama_conai_enriched.pid
    fi
else
    print_info "Aucun fichier PID trouvé"
fi

# Arrêt de tous les processus server_enriched.js
print_info "Arrêt de tous les processus server_enriched.js..."
pkill -f "server_enriched.js" 2>/dev/null && print_success "Processus server_enriched.js arrêtés" || print_info "Aucun processus server_enriched.js trouvé"

# Libération du port 3007
print_info "Libération du port 3007..."
if lsof -Pi :3007 -sTCP:LISTEN -t >/dev/null ; then
    lsof -ti:3007 | xargs kill -9 2>/dev/null
    sleep 1
    print_success "Port 3007 libéré"
else
    print_info "Port 3007 déjà libre"
fi

# Nettoyage des fichiers temporaires
print_info "Nettoyage des fichiers temporaires..."
rm -f mobile_app_web/nohup.out
rm -f mobile_app_web/*.log

print_success "SAMA CONAI Interface Enrichie arrêtée"

echo ""
echo "==========================================="
echo "🇸🇳 SAMA CONAI - Arrêt Terminé"
echo "==========================================="