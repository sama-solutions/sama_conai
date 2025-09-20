#!/bin/bash

# ========================================= #
# SAMA CONAI - LANCEMENT INTERFACE COMPLÈTE #
# ========================================= #

echo "🚀 Lancement de SAMA CONAI - Interface Mobile Complète"
echo "======================================================="

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

# Vérification des prérequis
print_status "Vérification des prérequis..."

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    print_error "Node.js n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier si npm est installé
if ! command -v npm &> /dev/null; then
    print_error "npm n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier si Python est installé
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

print_success "Tous les prérequis sont installés"

# Vérifier si le répertoire mobile_app_web existe
if [ ! -d "mobile_app_web" ]; then
    print_error "Le répertoire mobile_app_web n'existe pas"
    exit 1
fi

# Aller dans le répertoire mobile_app_web
cd mobile_app_web

# Vérifier si les dépendances Node.js sont installées
if [ ! -d "node_modules" ]; then
    print_status "Installation des dépendances Node.js..."
    npm install
    if [ $? -eq 0 ]; then
        print_success "Dépendances Node.js installées"
    else
        print_error "Erreur lors de l'installation des dépendances"
        exit 1
    fi
else
    print_success "Dépendances Node.js déjà installées"
fi

# Vérifier si le serveur complet existe
if [ ! -f "server_complete.js" ]; then
    print_error "Le fichier server_complete.js n'existe pas"
    exit 1
fi

# Vérifier si l'interface complète existe
if [ ! -f "public/sama_conai_complete.html" ]; then
    print_error "Le fichier sama_conai_complete.html n'existe pas"
    exit 1
fi

print_success "Tous les fichiers nécessaires sont présents"

# Arrêter les processus existants sur le port 3007
print_status "Arrêt des processus existants sur le port 3007..."
pkill -f "node.*server_complete.js" 2>/dev/null || true
lsof -ti:3007 | xargs kill -9 2>/dev/null || true

# Attendre un peu pour que les processus se terminent
sleep 2

# Démarrer le serveur complet
print_status "Démarrage du serveur SAMA CONAI complet..."

# Créer un fichier de log
LOG_FILE="../logs/sama_conai_complete_$(date +%Y%m%d_%H%M%S).log"
mkdir -p ../logs

# Démarrer le serveur en arrière-plan
nohup node server_complete.js > "$LOG_FILE" 2>&1 &
SERVER_PID=$!

# Sauvegarder le PID
echo $SERVER_PID > ../pids/sama_conai_complete.pid

# Attendre que le serveur démarre
print_status "Attente du démarrage du serveur..."
sleep 5

# Vérifier si le serveur fonctionne
if ps -p $SERVER_PID > /dev/null; then
    print_success "Serveur SAMA CONAI complet démarré avec succès (PID: $SERVER_PID)"
else
    print_error "Échec du démarrage du serveur"
    cat "$LOG_FILE"
    exit 1
fi

# Vérifier la connectivité
print_status "Vérification de la connectivité..."
sleep 2

if curl -s http://localhost:3007 > /dev/null; then
    print_success "Serveur accessible sur http://localhost:3007"
else
    print_warning "Le serveur ne répond pas encore, vérifiez les logs"
fi

# Afficher les informations de connexion
echo ""
echo "========================================="
echo "🎉 SAMA CONAI Interface Complète Lancée"
echo "========================================="
echo ""
echo "📱 Interface Mobile Complète:"
echo "   http://localhost:3007/"
echo ""
echo "🔧 Interfaces Alternatives:"
echo "   http://localhost:3007/advanced (Interface avancée)"
echo "   http://localhost:3007/correct (Interface corrigée)"
echo ""
echo "🔗 Backend Odoo:"
echo "   http://localhost:8077"
echo ""
echo "👤 Connexion:"
echo "   Utilisateur: admin"
echo "   Mot de passe: admin"
echo ""
echo "📊 Fonctionnalités:"
echo "   ✅ Navigation 3 niveaux ACTIVE"
echo "   ✅ Theme switcher CORRIGÉ"
echo "   ✅ Données réelles Odoo (Admin Global)"
echo "   ✅ Intégration backend Odoo"
echo "   ✅ Interface neumorphique"
echo ""
echo "📝 Logs: $LOG_FILE"
echo "🔧 PID: $SERVER_PID"
echo ""
echo "🛑 Pour arrêter le serveur:"
echo "   kill $SERVER_PID"
echo "   ou utilisez: ./stop_sama_conai_complete.sh"
echo ""

# Optionnel: ouvrir automatiquement le navigateur
if command -v xdg-open &> /dev/null; then
    print_status "Ouverture automatique du navigateur..."
    xdg-open http://localhost:3007 &
elif command -v open &> /dev/null; then
    print_status "Ouverture automatique du navigateur..."
    open http://localhost:3007 &
fi

print_success "SAMA CONAI Interface Complète est maintenant opérationnelle !"