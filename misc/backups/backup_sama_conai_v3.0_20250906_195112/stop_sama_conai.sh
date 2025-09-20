#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Script d'arrêt SAMA CONAI - Module Odoo 18
# ============================================================================
#
# Ce script arrête proprement les instances Odoo du module SAMA CONAI
# en se concentrant uniquement sur les processus de notre port spécifique.
#
# Usage:
#   ./stop_sama_conai.sh -p 8075
#   ./stop_sama_conai.sh --all
#   ./stop_sama_conai.sh --cleanup
#
# ============================================================================

# Dossiers du module
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$MODULE_DIR/.sama_conai_temp"
PID_DIR="$TEMP_DIR/pids"
LOG_DIR="$TEMP_DIR/logs"

# Valeurs par défaut
PORT=""
STOP_ALL="false"
CLEANUP="false"
FORCE="false"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -p, --port PORT     Arrête l'instance sur le port spécifié
  --all               Arrête toutes les instances SAMA CONAI
  --cleanup           Nettoie les fichiers temporaires après arrêt
  --force             Force l'arrêt (SIGKILL immédiat)
  -h, --help          Affiche cette aide

Exemples:
  # Arrêter l'instance sur le port 8075
  $0 -p 8075

  # Arrêter toutes les instances SAMA CONAI
  $0 --all

  # Arrêter et nettoyer les fichiers temporaires
  $0 -p 8075 --cleanup

  # Forcer l'arrêt immédiat
  $0 -p 8075 --force
EOF
}

# ============================================================================
# FONCTIONS D'ARRÊT
# ============================================================================

stop_by_port() {
    local port="$1"
    local force_kill="$2"
    
    log_info "Arrêt des processus sur le port $port..."
    
    # Chercher les processus par PID file d'abord
    local pid_file="$PID_DIR/odoo-$port.pid"
    local pids_from_file=""
    
    if [[ -f "$pid_file" ]]; then
        local saved_pid
        saved_pid=$(cat "$pid_file" 2>/dev/null || true)
        if [[ -n "$saved_pid" ]] && kill -0 "$saved_pid" 2>/dev/null; then
            pids_from_file="$saved_pid"
            log_info "PID trouvé dans le fichier: $saved_pid"
        else
            log_warning "PID dans le fichier ($saved_pid) n'est plus actif"
            rm -f "$pid_file"
        fi
    fi
    
    # Chercher les processus écoutant sur le port
    local pids_from_port
    pids_from_port=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)
    
    # Combiner les PIDs
    local all_pids
    all_pids=$(echo -e "$pids_from_file\n$pids_from_port" | grep -v '^$' | sort -u || true)
    
    if [[ -z "$all_pids" ]]; then
        log_info "Aucun processus trouvé sur le port $port"
        return 0
    fi
    
    log_info "Processus à arrêter: $all_pids"
    
    if [[ "$force_kill" == "true" ]]; then
        # Arrêt forcé immédiat
        log_warning "Arrêt forcé (SIGKILL) des processus: $all_pids"
        echo "$all_pids" | xargs -r kill -KILL 2>/dev/null || true
    else
        # Arrêt propre puis forcé si nécessaire
        log_info "Arrêt propre (SIGTERM) des processus: $all_pids"
        echo "$all_pids" | xargs -r kill -TERM 2>/dev/null || true
        
        # Attendre un peu
        sleep 3
        
        # Vérifier si des processus sont encore actifs
        local remaining_pids
        remaining_pids=$(echo "$all_pids" | xargs -r -I {} sh -c 'kill -0 {} 2>/dev/null && echo {}' || true)
        
        if [[ -n "$remaining_pids" ]]; then
            log_warning "Forçage de l'arrêt (SIGKILL) pour: $remaining_pids"
            echo "$remaining_pids" | xargs -r kill -KILL 2>/dev/null || true
            sleep 1
        fi
    fi
    
    # Nettoyer le fichier PID
    rm -f "$pid_file"
    
    # Vérification finale
    local final_check
    final_check=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)
    
    if [[ -z "$final_check" ]]; then
        log_success "Port $port libéré avec succès"
    else
        log_error "Échec de la libération du port $port"
        return 1
    fi
}

stop_all_instances() {
    log_info "Arrêt de toutes les instances SAMA CONAI..."
    
    local stopped_count=0
    
    # Arrêter par fichiers PID
    if [[ -d "$PID_DIR" ]]; then
        for pid_file in "$PID_DIR"/odoo-*.pid; do
            if [[ -f "$pid_file" ]]; then
                local port
                port=$(basename "$pid_file" .pid | sed 's/odoo-//')
                if [[ "$port" =~ ^[0-9]+$ ]]; then
                    log_info "Arrêt de l'instance sur le port $port..."
                    if stop_by_port "$port" "$FORCE"; then
                        ((stopped_count++))
                    fi
                fi
            fi
        done
    fi
    
    # Chercher d'autres processus Odoo avec sama_conai dans la ligne de commande
    local sama_pids
    sama_pids=$(pgrep -f "sama_conai" 2>/dev/null || true)
    
    if [[ -n "$sama_pids" ]]; then
        log_info "Processus SAMA CONAI supplémentaires trouvés: $sama_pids"
        
        if [[ "$FORCE" == "true" ]]; then
            echo "$sama_pids" | xargs -r kill -KILL 2>/dev/null || true
        else
            echo "$sama_pids" | xargs -r kill -TERM 2>/dev/null || true
            sleep 2
            # Vérifier et forcer si nécessaire
            local remaining
            remaining=$(echo "$sama_pids" | xargs -r -I {} sh -c 'kill -0 {} 2>/dev/null && echo {}' || true)
            if [[ -n "$remaining" ]]; then
                echo "$remaining" | xargs -r kill -KILL 2>/dev/null || true
            fi
        fi
        ((stopped_count++))
    fi
    
    if [[ $stopped_count -eq 0 ]]; then
        log_info "Aucune instance SAMA CONAI en cours d'exécution"
    else
        log_success "$stopped_count instance(s) arrêtée(s)"
    fi
}

cleanup_temp_files() {
    log_info "Nettoyage des fichiers temporaires..."
    
    local cleaned_count=0
    
    # Nettoyer les fichiers PID orphelins
    if [[ -d "$PID_DIR" ]]; then
        for pid_file in "$PID_DIR"/*.pid; do
            if [[ -f "$pid_file" ]]; then
                local pid
                pid=$(cat "$pid_file" 2>/dev/null || true)
                if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
                    log_info "Suppression du fichier PID orphelin: $(basename "$pid_file")"
                    rm -f "$pid_file"
                    ((cleaned_count++))
                fi
            fi
        done
    fi
    
    # Nettoyer les anciens logs (plus de 7 jours)
    if [[ -d "$LOG_DIR" ]]; then
        local old_logs
        old_logs=$(find "$LOG_DIR" -name "*.log" -mtime +7 2>/dev/null || true)
        if [[ -n "$old_logs" ]]; then
            log_info "Suppression des anciens logs (>7 jours)..."
            echo "$old_logs" | xargs -r rm -f
            ((cleaned_count++))
        fi
    fi
    
    # Compresser les gros logs actuels
    if [[ -d "$LOG_DIR" ]]; then
        local big_logs
        big_logs=$(find "$LOG_DIR" -name "*.log" -size +10M 2>/dev/null || true)
        if [[ -n "$big_logs" ]]; then
            log_info "Compression des gros logs (>10MB)..."
            echo "$big_logs" | while read -r log_file; do
                if command -v gzip >/dev/null 2>&1; then
                    gzip "$log_file"
                    log_info "Compressé: $(basename "$log_file")"
                    ((cleaned_count++))
                fi
            done
        fi
    fi
    
    if [[ $cleaned_count -eq 0 ]]; then
        log_info "Aucun fichier temporaire à nettoyer"
    else
        log_success "$cleaned_count fichier(s) nettoyé(s)"
    fi
}

show_status() {
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}                    SAMA CONAI - Statut des instances${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo
    
    local found_instances=false
    
    # Vérifier les instances par fichiers PID
    if [[ -d "$PID_DIR" ]]; then
        for pid_file in "$PID_DIR"/odoo-*.pid; do
            if [[ -f "$pid_file" ]]; then
                local port
                port=$(basename "$pid_file" .pid | sed 's/odoo-//')
                local pid
                pid=$(cat "$pid_file" 2>/dev/null || true)
                
                if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} Port $port - PID $pid - ACTIF"
                    found_instances=true
                else
                    echo -e "${RED}✗${NC} Port $port - PID $pid - INACTIF (fichier orphelin)"
                fi
            fi
        done
    fi
    
    # Chercher d'autres processus
    local other_pids
    other_pids=$(pgrep -f "sama_conai" 2>/dev/null || true)
    if [[ -n "$other_pids" ]]; then
        echo -e "${YELLOW}!${NC} Autres processus SAMA CONAI: $other_pids"
        found_instances=true
    fi
    
    if [[ "$found_instances" == "false" ]]; then
        echo -e "${BLUE}Aucune instance SAMA CONAI en cours d'exécution${NC}"
    fi
    
    echo
}

# ============================================================================
# PARSING DES ARGUMENTS
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            --all)
                STOP_ALL="true"
                shift 1
                ;;
            --cleanup)
                CLEANUP="true"
                shift 1
                ;;
            --force)
                FORCE="true"
                shift 1
                ;;
            --status)
                show_status
                exit 0
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                log_error "Option inconnue: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# FONCTION PRINCIPALE
# ============================================================================

main() {
    # Afficher l'en-tête
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}                    SAMA CONAI - Arrêt Module Odoo 18${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo
    
    # Parser les arguments
    parse_arguments "$@"
    
    # Vérifier les paramètres
    if [[ "$STOP_ALL" == "false" ]] && [[ -z "$PORT" ]]; then
        log_error "Vous devez spécifier un port (-p) ou utiliser --all"
        print_help
        exit 1
    fi
    
    # Créer les dossiers si nécessaire
    mkdir -p "$PID_DIR" "$LOG_DIR"
    
    # Exécuter l'action demandée
    if [[ "$STOP_ALL" == "true" ]]; then
        stop_all_instances
    else
        stop_by_port "$PORT" "$FORCE"
    fi
    
    # Nettoyer si demandé
    if [[ "$CLEANUP" == "true" ]]; then
        cleanup_temp_files
    fi
    
    log_success "Arrêt terminé"
}

# ============================================================================
# EXÉCUTION
# ============================================================================

# Vérifier que le script est exécuté depuis le bon répertoire
if [[ ! -f "$MODULE_DIR/__manifest__.py" ]]; then
    log_error "Ce script doit être exécuté depuis le répertoire du module sama_conai"
    exit 1
fi

# Exécuter la fonction principale avec tous les arguments
main "$@"