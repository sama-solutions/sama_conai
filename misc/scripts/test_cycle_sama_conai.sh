#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Script de cycle de test SAMA CONAI - Module Odoo 18
# ============================================================================
#
# Ce script automatise le cycle de test complet :
# 1. Démarrage du serveur
# 2. Tests de fonctionnement
# 3. Analyse des logs
# 4. Rapport de statut
# 5. Options de redémarrage/correction
#
# Usage:
#   ./test_cycle_sama_conai.sh -p 8075 -d sama_conai_test
#   ./test_cycle_sama_conai.sh --init -p 8075 -d sama_conai_test
#   ./test_cycle_sama_conai.sh --continuous -p 8075 -d sama_conai_test
#
# ============================================================================

# Dossiers du module
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$MODULE_DIR/.sama_conai_temp"
LOG_DIR="$TEMP_DIR/logs"

# Configuration par défaut
PORT="8075"
DB_NAME="sama_conai_test"
ACTION="run"
CONTINUOUS="false"
INTERACTIVE="true"
MAX_RETRIES="3"
WAIT_TIMEOUT="60"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1" >&2
}

print_separator() {
    echo -e "${BLUE}============================================================================${NC}"
}

print_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Actions:
  --init              Initialise et teste le module
  --update            Met à jour et teste le module
  --run               Lance et teste le serveur (défaut)

Options:
  -p, --port PORT     Port HTTP Odoo (défaut: $PORT)
  -d, --db NAME       Nom de la base de données (défaut: $DB_NAME)
  --continuous        Mode continu (redémarre automatiquement en cas d'erreur)
  --non-interactive   Mode non-interactif (pas de prompts)
  --max-retries N     Nombre maximum de tentatives (défaut: $MAX_RETRIES)
  --timeout N         Timeout d'attente en secondes (défaut: $WAIT_TIMEOUT)
  -h, --help          Affiche cette aide

Exemples:
  # Test simple
  $0 -p 8075 -d sama_conai_test

  # Initialisation et test
  $0 --init -p 8075 -d sama_conai_test

  # Mode continu pour développement
  $0 --continuous -p 8075 -d sama_conai_test

  # Mode non-interactif pour CI/CD
  $0 --non-interactive -p 8075 -d sama_conai_test
EOF
}

# ============================================================================
# FONCTIONS DE TEST
# ============================================================================

test_server_health() {
    local port="$1"
    local timeout="$2"
    
    log_test "Test de santé du serveur sur le port $port..."
    
    local count=0
    while [[ $count -lt $timeout ]]; do
        if curl -s -f "http://localhost:$port/web/health" >/dev/null 2>&1; then
            log_success "Serveur en bonne santé"
            return 0
        fi
        
        if curl -s "http://localhost:$port/web/database/selector" >/dev/null 2>&1; then
            log_success "Serveur accessible (sélecteur de base)"
            return 0
        fi
        
        sleep 1
        ((count++))
        
        if [[ $((count % 10)) -eq 0 ]]; then
            log_info "Attente... ($count/$timeout secondes)"
        fi
    done
    
    log_error "Timeout: serveur non accessible après $timeout secondes"
    return 1
}

test_database_connection() {
    local db="$1"
    local port="$2"
    
    log_test "Test de connexion à la base de données '$db'..."
    
    # Test via l'API Odoo
    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"call\",\"params\":{\"service\":\"db\",\"method\":\"list\"},\"id\":1}" \
        "http://localhost:$port/jsonrpc" 2>/dev/null || echo "")
    
    if echo "$response" | grep -q "\"$db\""; then
        log_success "Base de données '$db' accessible"
        return 0
    else
        log_error "Base de données '$db' non accessible"
        return 1
    fi
}

test_module_installation() {
    local db="$1"
    local port="$2"
    
    log_test "Test d'installation du module sama_conai..."
    
    # Vérifier que le module est installé via l'API
    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"call\",\"params\":{\"service\":\"object\",\"method\":\"execute\",\"args\":[\"$db\",1,\"admin\",\"ir.module.module\",\"search_read\",[[\"name\",\"=\",\"sama_conai\"]],[\"state\"]]},\"id\":1}" \
        "http://localhost:$port/jsonrpc" 2>/dev/null || echo "")
    
    if echo "$response" | grep -q "\"installed\""; then
        log_success "Module sama_conai installé et actif"
        return 0
    elif echo "$response" | grep -q "\"to upgrade\""; then
        log_warning "Module sama_conai nécessite une mise à jour"
        return 1
    else
        log_error "Module sama_conai non installé ou erreur"
        return 1
    fi
}

test_web_interface() {
    local port="$1"
    
    log_test "Test de l'interface web..."
    
    # Test de la page de login
    if curl -s -f "http://localhost:$port/web/login" >/dev/null 2>&1; then
        log_success "Interface web accessible"
    else
        log_error "Interface web non accessible"
        return 1
    fi
    
    # Test du portail (si disponible)
    if curl -s "http://localhost:$port/my" | grep -q "portal" 2>/dev/null; then
        log_success "Portail web accessible"
    else
        log_warning "Portail web non accessible (normal si pas configuré)"
    fi
    
    return 0
}

# ============================================================================
# ANALYSE DES LOGS
# ============================================================================

analyze_logs() {
    local log_file="$LOG_DIR/odoo-$PORT.log"
    
    if [[ ! -f "$log_file" ]]; then
        log_warning "Fichier de log non trouvé: $log_file"
        return 1
    fi
    
    log_info "Analyse des logs: $log_file"
    
    # Compter les erreurs récentes (dernières 100 lignes)
    local errors
    errors=$(tail -100 "$log_file" | grep -c "ERROR" || echo "0")
    
    local warnings
    warnings=$(tail -100 "$log_file" | grep -c "WARNING" || echo "0")
    
    local criticals
    criticals=$(tail -100 "$log_file" | grep -c "CRITICAL" || echo "0")
    
    echo
    echo -e "${BOLD}=== ANALYSE DES LOGS (100 dernières lignes) ===${NC}"
    echo -e "${RED}Erreurs critiques:${NC} $criticals"
    echo -e "${RED}Erreurs:${NC} $errors"
    echo -e "${YELLOW}Avertissements:${NC} $warnings"
    
    # Afficher les erreurs récentes
    if [[ $errors -gt 0 ]] || [[ $criticals -gt 0 ]]; then
        echo
        echo -e "${RED}=== ERREURS RÉCENTES ===${NC}"
        tail -100 "$log_file" | grep -E "(ERROR|CRITICAL)" | tail -10
    fi
    
    # Afficher les avertissements importants
    if [[ $warnings -gt 0 ]]; then
        echo
        echo -e "${YELLOW}=== AVERTISSEMENTS RÉCENTS ===${NC}"
        tail -100 "$log_file" | grep "WARNING" | tail -5
    fi
    
    echo
    
    # Retourner le statut basé sur les erreurs
    if [[ $criticals -gt 0 ]]; then
        return 2  # Erreurs critiques
    elif [[ $errors -gt 5 ]]; then
        return 1  # Trop d'erreurs
    else
        return 0  # OK
    fi
}

show_log_tail() {
    local log_file="$LOG_DIR/odoo-$PORT.log"
    local lines="${1:-20}"
    
    if [[ -f "$log_file" ]]; then
        echo -e "${BLUE}=== DERNIÈRES LIGNES DU LOG ($lines) ===${NC}"
        tail -"$lines" "$log_file"
        echo
    else
        log_warning "Fichier de log non trouvé"
    fi
}

# ============================================================================
# GESTION DES ERREURS ET CORRECTIONS
# ============================================================================

suggest_corrections() {
    local log_file="$LOG_DIR/odoo-$PORT.log"
    
    if [[ ! -f "$log_file" ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}=== SUGGESTIONS DE CORRECTION ===${NC}"
    
    # Analyser les erreurs communes
    local recent_logs
    recent_logs=$(tail -100 "$log_file")
    
    if echo "$recent_logs" | grep -q "database.*does not exist"; then
        echo "• La base de données n'existe pas - utilisez --init pour la créer"
    fi
    
    if echo "$recent_logs" | grep -q "module.*not found"; then
        echo "• Module non trouvé - vérifiez le chemin des addons"
    fi
    
    if echo "$recent_logs" | grep -q "permission denied"; then
        echo "• Problème de permissions - vérifiez les droits d'accès"
    fi
    
    if echo "$recent_logs" | grep -q "port.*already in use"; then
        echo "• Port déjà utilisé - utilisez ./stop_sama_conai.sh -p $PORT"
    fi
    
    if echo "$recent_logs" | grep -q "connection.*refused"; then
        echo "• Connexion refusée - vérifiez que PostgreSQL est démarré"
    fi
    
    if echo "$recent_logs" | grep -q "syntax error"; then
        echo "• Erreur de syntaxe - vérifiez le code Python récemment modifié"
    fi
    
    echo
}

# ============================================================================
# INTERFACE INTERACTIVE
# ============================================================================

interactive_menu() {
    while true; do
        echo -e "${BOLD}=== MENU INTERACTIF ===${NC}"
        echo "1. Redémarrer le serveur"
        echo "2. Voir les logs (20 dernières lignes)"
        echo "3. Voir les logs (100 dernières lignes)"
        echo "4. Analyser les logs"
        echo "5. Arrêter le serveur"
        echo "6. Relancer les tests"
        echo "7. Quitter"
        echo
        read -p "Votre choix (1-7): " choice
        
        case "$choice" in
            1)
                log_info "Redémarrage du serveur..."
                ./stop_sama_conai.sh -p "$PORT" >/dev/null 2>&1 || true
                sleep 2
                ./launch_sama_conai.sh --"$ACTION" -p "$PORT" -d "$DB_NAME" &
                sleep 5
                ;;
            2)
                show_log_tail 20
                ;;
            3)
                show_log_tail 100
                ;;
            4)
                analyze_logs
                suggest_corrections
                ;;
            5)
                log_info "Arrêt du serveur..."
                ./stop_sama_conai.sh -p "$PORT"
                return 0
                ;;
            6)
                log_info "Relance des tests..."
                run_all_tests
                ;;
            7)
                log_info "Au revoir !"
                return 0
                ;;
            *)
                log_error "Choix invalide"
                ;;
        esac
        
        echo
        read -p "Appuyez sur Entrée pour continuer..."
        echo
    done
}

# ============================================================================
# EXÉCUTION DES TESTS
# ============================================================================

run_all_tests() {
    local success=true
    
    print_separator
    echo -e "${BOLD}                    SAMA CONAI - Tests de fonctionnement${NC}"
    print_separator
    echo
    
    # Test 1: Santé du serveur
    if ! test_server_health "$PORT" "$WAIT_TIMEOUT"; then
        success=false
    fi
    
    # Test 2: Connexion base de données
    if [[ "$success" == "true" ]]; then
        if ! test_database_connection "$DB_NAME" "$PORT"; then
            success=false
        fi
    fi
    
    # Test 3: Installation du module
    if [[ "$success" == "true" ]]; then
        if ! test_module_installation "$DB_NAME" "$PORT"; then
            success=false
        fi
    fi
    
    # Test 4: Interface web
    if [[ "$success" == "true" ]]; then
        if ! test_web_interface "$PORT"; then
            success=false
        fi
    fi
    
    echo
    print_separator
    
    if [[ "$success" == "true" ]]; then
        echo -e "${GREEN}${BOLD}✓ TOUS LES TESTS RÉUSSIS${NC}"
        echo -e "${GREEN}URL d'accès: http://localhost:$PORT${NC}"
        echo -e "${GREEN}Base de données: $DB_NAME${NC}"
    else
        echo -e "${RED}${BOLD}✗ ÉCHEC DES TESTS${NC}"
        analyze_logs
        suggest_corrections
    fi
    
    print_separator
    
    return $([[ "$success" == "true" ]] && echo 0 || echo 1)
}

# ============================================================================
# CYCLE PRINCIPAL
# ============================================================================

run_test_cycle() {
    local retry_count=0
    
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        log_info "Cycle de test #$((retry_count + 1))/$MAX_RETRIES"
        
        # Arrêter les instances existantes
        ./stop_sama_conai.sh -p "$PORT" >/dev/null 2>&1 || true
        sleep 2
        
        # Démarrer le serveur
        log_info "Démarrage du serveur..."
        ./launch_sama_conai.sh --"$ACTION" -p "$PORT" -d "$DB_NAME" &
        
        # Attendre un peu pour le démarrage
        sleep 5
        
        # Exécuter les tests
        if run_all_tests; then
            log_success "Cycle de test réussi !"
            
            if [[ "$INTERACTIVE" == "true" ]]; then
                interactive_menu
            fi
            
            return 0
        else
            log_error "Cycle de test échoué"
            ((retry_count++))
            
            if [[ $retry_count -lt $MAX_RETRIES ]]; then
                if [[ "$INTERACTIVE" == "true" ]]; then
                    echo
                    read -p "Voulez-vous réessayer ? (y/N): " retry
                    if [[ "$retry" != "y" ]] && [[ "$retry" != "Y" ]]; then
                        break
                    fi
                else
                    log_info "Nouvelle tentative dans 10 secondes..."
                    sleep 10
                fi
            fi
        fi
    done
    
    log_error "Échec après $MAX_RETRIES tentatives"
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo
        read -p "Voulez-vous accéder au menu interactif ? (y/N): " menu
        if [[ "$menu" == "y" ]] || [[ "$menu" == "Y" ]]; then
            interactive_menu
        fi
    fi
    
    return 1
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
            -d|--db)
                DB_NAME="$2"
                shift 2
                ;;
            --init)
                ACTION="init"
                shift 1
                ;;
            --update)
                ACTION="update"
                shift 1
                ;;
            --run)
                ACTION="run"
                shift 1
                ;;
            --continuous)
                CONTINUOUS="true"
                MAX_RETRIES=999
                shift 1
                ;;
            --non-interactive)
                INTERACTIVE="false"
                shift 1
                ;;
            --max-retries)
                MAX_RETRIES="$2"
                shift 2
                ;;
            --timeout)
                WAIT_TIMEOUT="$2"
                shift 2
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
    print_separator
    echo -e "${BOLD}                    SAMA CONAI - Cycle de Test Automatisé${NC}"
    print_separator
    echo
    
    # Parser les arguments
    parse_arguments "$@"
    
    # Vérifier que les scripts nécessaires existent
    if [[ ! -f "./launch_sama_conai.sh" ]]; then
        log_error "Script launch_sama_conai.sh non trouvé"
        exit 1
    fi
    
    if [[ ! -f "./stop_sama_conai.sh" ]]; then
        log_error "Script stop_sama_conai.sh non trouvé"
        exit 1
    fi
    
    # Rendre les scripts exécutables
    chmod +x ./launch_sama_conai.sh ./stop_sama_conai.sh
    
    # Créer les dossiers temporaires
    mkdir -p "$LOG_DIR"
    
    # Afficher la configuration
    log_info "Configuration du test:"
    echo "  Port: $PORT"
    echo "  Base de données: $DB_NAME"
    echo "  Action: $ACTION"
    echo "  Mode continu: $CONTINUOUS"
    echo "  Interactif: $INTERACTIVE"
    echo "  Max tentatives: $MAX_RETRIES"
    echo "  Timeout: $WAIT_TIMEOUT secondes"
    echo
    
    # Exécuter le cycle de test
    if [[ "$CONTINUOUS" == "true" ]]; then
        log_info "Mode continu activé - Ctrl+C pour arrêter"
        while true; do
            run_test_cycle
            if [[ "$INTERACTIVE" == "false" ]]; then
                sleep 30
            fi
        done
    else
        run_test_cycle
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