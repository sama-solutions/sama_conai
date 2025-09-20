#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Script de démarrage rapide SAMA CONAI
# ============================================================================
#
# Ce script simplifie le démarrage pour les tests courants
#
# Usage:
#   ./quick_start.sh                    # Démarrage simple
#   ./quick_start.sh init               # Première installation
#   ./quick_start.sh update             # Mise à jour
#   ./quick_start.sh test               # Cycle de test complet
#   ./quick_start.sh stop               # Arrêt
#   ./quick_start.sh clean              # Nettoyage
#
# ============================================================================

# Configuration par défaut
DEFAULT_PORT="8075"
DEFAULT_DB="sama_conai_test"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_help() {
    cat <<EOF
Usage: $0 [ACTION] [OPTIONS]

Actions:
  init        Première installation du module
  update      Mise à jour du module
  run         Démarrage simple (défaut)
  test        Cycle de test complet
  stop        Arrêt du serveur
  clean       Nettoyage des fichiers temporaires
  status      Affichage du statut

Options:
  -p PORT     Port (défaut: $DEFAULT_PORT)
  -d DB       Base de données (défaut: $DEFAULT_DB)
  -h          Affiche cette aide

Exemples:
  $0                      # Démarrage simple
  $0 init                 # Première installation
  $0 test -p 8076         # Test sur port 8076
  $0 update -d my_db      # Mise à jour sur base my_db
EOF
}

# Parse arguments
ACTION="run"
PORT="$DEFAULT_PORT"
DB="$DEFAULT_DB"

while [[ $# -gt 0 ]]; do
    case "$1" in
        init|update|run|test|stop|clean|status)
            ACTION="$1"
            shift
            ;;
        -p)
            PORT="$2"
            shift 2
            ;;
        -d)
            DB="$2"
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            print_help
            exit 1
            ;;
    esac
done

# Vérifier que les scripts existent
for script in launch_sama_conai.sh stop_sama_conai.sh test_cycle_sama_conai.sh cleanup_temp.sh; do
    if [[ ! -f "./$script" ]]; then
        echo "Erreur: Script $script non trouvé"
        exit 1
    fi
done

# Exécuter l'action
case "$ACTION" in
    init)
        log_info "Initialisation du module SAMA CONAI..."
        log_info "Port: $PORT, Base: $DB"
        ./launch_sama_conai.sh --init -p "$PORT" -d "$DB" --follow
        ;;
    update)
        log_info "Mise à jour du module SAMA CONAI..."
        log_info "Port: $PORT, Base: $DB"
        ./launch_sama_conai.sh --update -p "$PORT" -d "$DB" --follow
        ;;
    run)
        log_info "Démarrage du module SAMA CONAI..."
        log_info "Port: $PORT, Base: $DB"
        ./launch_sama_conai.sh --run -p "$PORT" -d "$DB" --follow
        ;;
    test)
        log_info "Cycle de test complet..."
        log_info "Port: $PORT, Base: $DB"
        ./test_cycle_sama_conai.sh -p "$PORT" -d "$DB"
        ;;
    stop)
        log_info "Arrêt du serveur sur le port $PORT..."
        ./stop_sama_conai.sh -p "$PORT"
        ;;
    clean)
        log_info "Nettoyage des fichiers temporaires..."
        ./cleanup_temp.sh
        ;;
    status)
        log_info "Statut des instances SAMA CONAI..."
        ./stop_sama_conai.sh --status
        ;;
    *)
        echo "Action inconnue: $ACTION"
        print_help
        exit 1
        ;;
esac