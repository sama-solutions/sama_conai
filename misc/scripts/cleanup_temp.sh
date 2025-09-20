#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Script de nettoyage SAMA CONAI - Module Odoo 18
# ============================================================================
#
# Ce script nettoie tous les fichiers temporaires créés pendant les tests
# et le développement du module SAMA CONAI.
#
# Usage:
#   ./cleanup_temp.sh
#   ./cleanup_temp.sh --deep
#   ./cleanup_temp.sh --logs-only
#   ./cleanup_temp.sh --dry-run
#
# ============================================================================

# Dossiers du module
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$MODULE_DIR/.sama_conai_temp"
OLD_TEMP_DIR="$MODULE_DIR/.sama_conai_tmp"  # Ancien nom

# Options
DEEP_CLEAN="false"
LOGS_ONLY="false"
DRY_RUN="false"
FORCE="false"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
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
  --deep              Nettoyage complet (inclut les sauvegardes et caches)
  --logs-only         Nettoie seulement les fichiers de logs
  --dry-run           Affiche ce qui serait supprimé sans le faire
  --force             Force la suppression sans confirmation
  -h, --help          Affiche cette aide

Exemples:
  # Nettoyage standard
  $0

  # Nettoyage complet
  $0 --deep

  # Voir ce qui serait supprimé
  $0 --dry-run

  # Nettoyer seulement les logs
  $0 --logs-only
EOF
}

# ============================================================================
# FONCTIONS DE NETTOYAGE
# ============================================================================

get_file_size() {
    local path="$1"
    if [[ -f "$path" ]]; then
        du -h "$path" | cut -f1
    elif [[ -d "$path" ]]; then
        du -sh "$path" | cut -f1
    else
        echo "0"
    fi
}

clean_logs() {
    local cleaned_count=0
    local total_size=0
    
    log_info "Nettoyage des fichiers de logs..."
    
    # Nettoyer les logs dans le nouveau dossier temp
    if [[ -d "$TEMP_DIR/logs" ]]; then
        for log_file in "$TEMP_DIR/logs"/*.log "$TEMP_DIR/logs"/*.log.gz; do
            if [[ -f "$log_file" ]]; then
                local size
                size=$(get_file_size "$log_file")
                
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "  Supprimerait: $(basename "$log_file") ($size)"
                else
                    rm -f "$log_file"
                    log_info "Supprimé: $(basename "$log_file") ($size)"
                fi
                ((cleaned_count++))
            fi
        done
    fi
    
    # Nettoyer les logs dans l'ancien dossier temp
    if [[ -d "$OLD_TEMP_DIR/logs" ]]; then
        for log_file in "$OLD_TEMP_DIR/logs"/*.log "$OLD_TEMP_DIR/logs"/*.log.gz; do
            if [[ -f "$log_file" ]]; then
                local size
                size=$(get_file_size "$log_file")
                
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "  Supprimerait: $(basename "$log_file") ($size)"
                else
                    rm -f "$log_file"
                    log_info "Supprimé: $(basename "$log_file") ($size)"
                fi
                ((cleaned_count++))
            fi
        done
    fi
    
    # Nettoyer nohup.out
    if [[ -f "$MODULE_DIR/nohup.out" ]]; then
        local size
        size=$(get_file_size "$MODULE_DIR/nohup.out")
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  Supprimerait: nohup.out ($size)"
        else
            rm -f "$MODULE_DIR/nohup.out"
            log_info "Supprimé: nohup.out ($size)"
        fi
        ((cleaned_count++))
    fi
    
    if [[ $cleaned_count -eq 0 ]]; then
        log_info "Aucun fichier de log à nettoyer"
    else
        log_success "$cleaned_count fichier(s) de log nettoyé(s)"
    fi
}

clean_pids() {
    local cleaned_count=0
    
    log_info "Nettoyage des fichiers PID..."
    
    # Nettoyer les PIDs dans le nouveau dossier temp
    if [[ -d "$TEMP_DIR/pids" ]]; then
        for pid_file in "$TEMP_DIR/pids"/*.pid; do
            if [[ -f "$pid_file" ]]; then
                local pid
                pid=$(cat "$pid_file" 2>/dev/null || echo "")
                
                # Vérifier si le processus est encore actif
                if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                    log_warning "Processus actif trouvé (PID: $pid) - fichier conservé: $(basename "$pid_file")"
                else
                    if [[ "$DRY_RUN" == "true" ]]; then
                        echo "  Supprimerait: $(basename "$pid_file")"
                    else
                        rm -f "$pid_file"
                        log_info "Supprimé: $(basename "$pid_file")"
                    fi
                    ((cleaned_count++))
                fi
            fi
        done
    fi
    
    # Nettoyer les PIDs dans l'ancien dossier temp
    if [[ -d "$OLD_TEMP_DIR/pids" ]]; then
        for pid_file in "$OLD_TEMP_DIR/pids"/*.pid; do
            if [[ -f "$pid_file" ]]; then
                local pid
                pid=$(cat "$pid_file" 2>/dev/null || echo "")
                
                if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                    log_warning "Processus actif trouvé (PID: $pid) - fichier conservé: $(basename "$pid_file")"
                else
                    if [[ "$DRY_RUN" == "true" ]]; then
                        echo "  Supprimerait: $(basename "$pid_file")"
                    else
                        rm -f "$pid_file"
                        log_info "Supprimé: $(basename "$pid_file")"
                    fi
                    ((cleaned_count++))
                fi
            fi
        done
    fi
    
    if [[ $cleaned_count -eq 0 ]]; then
        log_info "Aucun fichier PID à nettoyer"
    else
        log_success "$cleaned_count fichier(s) PID nettoyé(s)"
    fi
}

clean_configs() {
    local cleaned_count=0
    
    log_info "Nettoyage des fichiers de configuration temporaires..."
    
    # Nettoyer les configs dans le nouveau dossier temp
    if [[ -d "$TEMP_DIR/conf" ]]; then
        for conf_file in "$TEMP_DIR/conf"/*.conf; do
            if [[ -f "$conf_file" ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "  Supprimerait: $(basename "$conf_file")"
                else
                    rm -f "$conf_file"
                    log_info "Supprimé: $(basename "$conf_file")"
                fi
                ((cleaned_count++))
            fi
        done
    fi
    
    # Nettoyer les configs dans l'ancien dossier temp
    if [[ -d "$OLD_TEMP_DIR/conf" ]]; then
        for conf_file in "$OLD_TEMP_DIR/conf"/*.conf; do
            if [[ -f "$conf_file" ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "  Supprimerait: $(basename "$conf_file")"
                else
                    rm -f "$conf_file"
                    log_info "Supprimé: $(basename "$conf_file")"
                fi
                ((cleaned_count++))
            fi
        done
    fi
    
    if [[ $cleaned_count -eq 0 ]]; then
        log_info "Aucun fichier de configuration à nettoyer"
    else
        log_success "$cleaned_count fichier(s) de configuration nettoyé(s)"
    fi
}

clean_python_cache() {
    local cleaned_count=0
    
    log_info "Nettoyage des caches Python..."
    
    # Nettoyer __pycache__
    find "$MODULE_DIR" -type d -name "__pycache__" | while read -r cache_dir; do
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  Supprimerait: $cache_dir"
        else
            rm -rf "$cache_dir"
            log_info "Supprimé: $cache_dir"
        fi
        ((cleaned_count++))
    done
    
    # Nettoyer les fichiers .pyc
    find "$MODULE_DIR" -name "*.pyc" -type f | while read -r pyc_file; do
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  Supprimerait: $pyc_file"
        else
            rm -f "$pyc_file"
            log_info "Supprimé: $pyc_file"
        fi
        ((cleaned_count++))
    done
    
    if [[ $cleaned_count -eq 0 ]]; then
        log_info "Aucun cache Python à nettoyer"
    else
        log_success "$cleaned_count élément(s) de cache Python nettoyé(s)"
    fi
}

clean_temp_directories() {
    log_info "Nettoyage des dossiers temporaires..."
    
    # Nettoyer le nouveau dossier temp
    if [[ -d "$TEMP_DIR" ]]; then
        local size
        size=$(get_file_size "$TEMP_DIR")
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  Supprimerait: .sama_conai_temp/ ($size)"
        else
            rm -rf "$TEMP_DIR"
            log_success "Supprimé: .sama_conai_temp/ ($size)"
        fi
    fi
    
    # Nettoyer l'ancien dossier temp
    if [[ -d "$OLD_TEMP_DIR" ]]; then
        local size
        size=$(get_file_size "$OLD_TEMP_DIR")
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  Supprimerait: .sama_conai_tmp/ ($size)"
        else
            rm -rf "$OLD_TEMP_DIR"
            log_success "Supprimé: .sama_conai_tmp/ ($size)"
        fi
    fi
}

clean_odoo_local() {
    if [[ "$DEEP_CLEAN" != "true" ]]; then
        return 0
    fi
    
    log_info "Nettoyage du dossier .odoo_local..."
    
    if [[ -d "$MODULE_DIR/.odoo_local" ]]; then
        local size
        size=$(get_file_size "$MODULE_DIR/.odoo_local")
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  Supprimerait: .odoo_local/ ($size)"
        else
            rm -rf "$MODULE_DIR/.odoo_local"
            log_success "Supprimé: .odoo_local/ ($size)"
        fi
    else
        log_info "Dossier .odoo_local non trouvé"
    fi
}

# ============================================================================
# FONCTIONS DE RAPPORT
# ============================================================================

show_cleanup_summary() {
    echo
    echo -e "${BOLD}=== RÉSUMÉ DU NETTOYAGE ===${NC}"
    
    local total_size=0
    local file_count=0
    
    # Calculer la taille totale des fichiers temporaires
    for dir in "$TEMP_DIR" "$OLD_TEMP_DIR" "$MODULE_DIR/.odoo_local"; do
        if [[ -d "$dir" ]]; then
            local size
            size=$(du -sb "$dir" 2>/dev/null | cut -f1 || echo "0")
            total_size=$((total_size + size))
        fi
    done
    
    # Compter les fichiers
    for pattern in "*.log" "*.log.gz" "*.pid" "*.conf" "*.pyc"; do
        local count
        count=$(find "$MODULE_DIR" -name "$pattern" -type f 2>/dev/null | wc -l)
        file_count=$((file_count + count))
    done
    
    # Convertir la taille en format lisible
    local human_size
    if [[ $total_size -gt 1073741824 ]]; then
        human_size="$(echo "scale=1; $total_size / 1073741824" | bc)G"
    elif [[ $total_size -gt 1048576 ]]; then
        human_size="$(echo "scale=1; $total_size / 1048576" | bc)M"
    elif [[ $total_size -gt 1024 ]]; then
        human_size="$(echo "scale=1; $total_size / 1024" | bc)K"
    else
        human_size="${total_size}B"
    fi
    
    echo "Fichiers temporaires trouvés: $file_count"
    echo "Espace disque utilisé: $human_size"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}Mode dry-run: aucun fichier n'a été supprimé${NC}"
    fi
    
    echo
}

# ============================================================================
# PARSING DES ARGUMENTS
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --deep)
                DEEP_CLEAN="true"
                shift 1
                ;;
            --logs-only)
                LOGS_ONLY="true"
                shift 1
                ;;
            --dry-run)
                DRY_RUN="true"
                shift 1
                ;;
            --force)
                FORCE="true"
                shift 1
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
    echo -e "${BLUE}                    SAMA CONAI - Nettoyage des fichiers temporaires${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo
    
    # Parser les arguments
    parse_arguments "$@"
    
    # Afficher le résumé avant nettoyage
    show_cleanup_summary
    
    # Demander confirmation si pas en mode force ou dry-run
    if [[ "$FORCE" != "true" ]] && [[ "$DRY_RUN" != "true" ]]; then
        echo -e "${YELLOW}Attention: Cette opération va supprimer des fichiers de manière permanente.${NC}"
        read -p "Voulez-vous continuer ? (y/N): " confirm
        if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
            log_info "Nettoyage annulé"
            exit 0
        fi
        echo
    fi
    
    # Exécuter le nettoyage selon les options
    if [[ "$LOGS_ONLY" == "true" ]]; then
        clean_logs
    else
        clean_logs
        clean_pids
        clean_configs
        
        if [[ "$DEEP_CLEAN" == "true" ]]; then
            clean_python_cache
            clean_odoo_local
            clean_temp_directories
        fi
    fi
    
    echo
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Mode dry-run terminé - aucun fichier supprimé"
    else
        log_success "Nettoyage terminé avec succès"
    fi
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