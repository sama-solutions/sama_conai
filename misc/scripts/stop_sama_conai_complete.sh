#!/bin/bash

# ========================================= #
# SAMA CONAI - ARRÊT INTERFACE COMPLÈTE    #
# ========================================= #

echo "🛑 Arrêt de SAMA CONAI - Interface Mobile Complète"
echo "=================================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
print_status() {
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

# Arrêter le serveur via PID si disponible
if [ -f "pids/sama_conai_complete.pid" ]; then
    PID=$(cat pids/sama_conai_complete.pid)
    print_status "Arrêt du serveur SAMA CONAI complet (PID: $PID)..."
    
    if ps -p $PID > /dev/null; then
        kill $PID
        sleep 2
        
        # Vérifier si le processus est toujours en cours
        if ps -p $PID > /dev/null; then
            print_warning "Arrêt forcé du processus..."
            kill -9 $PID
        fi
        
        print_success "Serveur arrêté avec succès"
        rm -f pids/sama_conai_complete.pid
    else
        print_warning "Le processus avec PID $PID n'est plus en cours d'exécution"
        rm -f pids/sama_conai_complete.pid
    fi
else
    print_warning "Fichier PID non trouvé"
fi

# Arrêter tous les processus Node.js liés au serveur complet
print_status "Arrêt de tous les processus server_complete.js..."
pkill -f "node.*server_complete.js" 2>/dev/null || true

# Arrêter tous les processus sur le port 3007
print_status "Libération du port 3007..."
lsof -ti:3007 | xargs kill -9 2>/dev/null || true

# Attendre un peu pour que les processus se terminent
sleep 2

# Vérifier si le port est libre
if lsof -i:3007 > /dev/null 2>&1; then
    print_warning "Le port 3007 est encore occupé"
else
    print_success "Port 3007 libéré"
fi

print_success "SAMA CONAI Interface Complète arrêtée"