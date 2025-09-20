#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Script de validation de l'environnement SAMA CONAI
# ============================================================================
#
# Ce script vérifie que tous les prérequis sont en place pour faire
# fonctionner le module SAMA CONAI
#
# ============================================================================

# Configuration (même que dans launch_sama_conai.sh)
ODOO_HOME="/var/odoo/odoo18"
VENV_DIR="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS="/home/grand-as/psagsn/custom_addons"
OFFICIAL_ADDONS1="/var/odoo/odoo18/addons"
OFFICIAL_ADDONS2="/var/odoo/odoo18/odoo/addons"

# PostgreSQL
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="odoo"
DB_PASSWORD="odoo"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Compteurs
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((CHECKS_PASSED++))
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    ((CHECKS_WARNING++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((CHECKS_FAILED++))
}

check_item() {
    ((CHECKS_TOTAL++))
}

# ============================================================================
# VÉRIFICATIONS
# ============================================================================

check_odoo_installation() {
    log_info "Vérification de l'installation Odoo..."
    
    check_item
    if [[ -d "$ODOO_HOME" ]]; then
        log_success "Dossier Odoo trouvé: $ODOO_HOME"
    else
        log_error "Dossier Odoo non trouvé: $ODOO_HOME"
        return 1
    fi
    
    check_item
    local odoo_bin="$ODOO_HOME/odoo-bin"
    if [[ -x "$odoo_bin" ]]; then
        log_success "Binaire Odoo exécutable: $odoo_bin"
        
        # Vérifier la version
        local version
        version=$("$odoo_bin" --version 2>/dev/null | head -1 || echo "Version inconnue")
        log_info "Version: $version"
    else
        log_error "Binaire Odoo non exécutable: $odoo_bin"
    fi
    
    check_item
    if [[ -d "$OFFICIAL_ADDONS1" ]]; then
        log_success "Addons officiels trouvés: $OFFICIAL_ADDONS1"
    else
        log_warning "Addons officiels non trouvés: $OFFICIAL_ADDONS1"
    fi
    
    check_item
    if [[ -d "$OFFICIAL_ADDONS2" ]]; then
        log_success "Addons officiels trouvés: $OFFICIAL_ADDONS2"
    else
        log_warning "Addons officiels non trouvés: $OFFICIAL_ADDONS2"
    fi
}

check_python_environment() {
    log_info "Vérification de l'environnement Python..."
    
    check_item
    if [[ -d "$VENV_DIR" ]]; then
        log_success "Virtual environment trouvé: $VENV_DIR"
    else
        log_error "Virtual environment non trouvé: $VENV_DIR"
        return 1
    fi
    
    check_item
    if [[ -f "$VENV_DIR/bin/activate" ]]; then
        log_success "Script d'activation trouvé"
    else
        log_error "Script d'activation non trouvé: $VENV_DIR/bin/activate"
    fi
    
    check_item
    if [[ -x "$VENV_DIR/bin/python" ]]; then
        log_success "Python exécutable trouvé"
        
        # Vérifier la version Python
        local python_version
        python_version=$("$VENV_DIR/bin/python" --version 2>&1 || echo "Version inconnue")
        log_info "Version Python: $python_version"
    else
        log_error "Python non exécutable: $VENV_DIR/bin/python"
    fi
    
    # Vérifier quelques packages critiques
    check_item
    if "$VENV_DIR/bin/python" -c "import psycopg2" 2>/dev/null; then
        log_success "Package psycopg2 installé"
    else
        log_error "Package psycopg2 manquant (requis pour PostgreSQL)"
    fi
    
    check_item
    if "$VENV_DIR/bin/python" -c "import werkzeug" 2>/dev/null; then
        log_success "Package werkzeug installé"
    else
        log_error "Package werkzeug manquant (requis pour Odoo)"
    fi
}

check_postgresql() {
    log_info "Vérification de PostgreSQL..."
    
    check_item
    if command -v psql >/dev/null 2>&1; then
        log_success "Client PostgreSQL (psql) trouvé"
    else
        log_error "Client PostgreSQL (psql) non trouvé"
        return 1
    fi
    
    check_item
    if systemctl is-active postgresql >/dev/null 2>&1 || service postgresql status >/dev/null 2>&1; then
        log_success "Service PostgreSQL actif"
    else
        log_warning "Service PostgreSQL non actif ou non détectable"
    fi
    
    check_item
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c '\q' 2>/dev/null; then
        log_success "Connexion PostgreSQL réussie ($DB_USER@$DB_HOST:$DB_PORT)"
    else
        log_error "Échec de connexion PostgreSQL ($DB_USER@$DB_HOST:$DB_PORT)"
        log_info "Vérifiez que l'utilisateur '$DB_USER' existe avec le mot de passe '$DB_PASSWORD'"
    fi
    
    check_item
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT version();" 2>/dev/null | grep -q "PostgreSQL"; then
        local pg_version
        pg_version=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT version();" 2>/dev/null | head -1)
        log_success "Version PostgreSQL: $pg_version"
    else
        log_warning "Impossible de récupérer la version PostgreSQL"
    fi
}

check_custom_addons() {
    log_info "Vérification des addons personnalisés..."
    
    check_item
    if [[ -d "$CUSTOM_ADDONS" ]]; then
        log_success "Dossier custom_addons trouvé: $CUSTOM_ADDONS"
    else
        log_error "Dossier custom_addons non trouvé: $CUSTOM_ADDONS"
        return 1
    fi
    
    check_item
    if [[ -f "$CUSTOM_ADDONS/sama_conai/__manifest__.py" ]]; then
        log_success "Module sama_conai trouvé"
        
        # Vérifier la version du module
        local module_version
        module_version=$(grep -E "^\s*['\"]version['\"]" "$CUSTOM_ADDONS/sama_conai/__manifest__.py" | sed -E "s/.*['\"]([^'\"]+)['\"].*/\1/" || echo "Version inconnue")
        log_info "Version du module: $module_version"
    else
        log_error "Module sama_conai non trouvé dans: $CUSTOM_ADDONS"
    fi
    
    check_item
    if [[ -f "$CUSTOM_ADDONS/sama_conai/__init__.py" ]]; then
        log_success "Fichier __init__.py trouvé"
    else
        log_error "Fichier __init__.py manquant dans sama_conai"
    fi
}

check_system_requirements() {
    log_info "Vérification des prérequis système..."
    
    check_item
    if command -v curl >/dev/null 2>&1; then
        log_success "curl installé"
    else
        log_error "curl manquant (requis pour les tests)"
    fi
    
    check_item
    if command -v lsof >/dev/null 2>&1; then
        log_success "lsof installé"
    else
        log_error "lsof manquant (requis pour la gestion des ports)"
    fi
    
    check_item
    if command -v pgrep >/dev/null 2>&1; then
        log_success "pgrep installé"
    else
        log_error "pgrep manquant (requis pour la gestion des processus)"
    fi
    
    check_item
    local available_memory
    available_memory=$(free -m | awk '/^Mem:/{print $7}' 2>/dev/null || echo "0")
    if [[ $available_memory -gt 1000 ]]; then
        log_success "Mémoire disponible suffisante: ${available_memory}MB"
    else
        log_warning "Mémoire disponible faible: ${available_memory}MB (recommandé: >1GB)"
    fi
    
    check_item
    local disk_space
    disk_space=$(df -BM . | awk 'NR==2{print $4}' | sed 's/M//' 2>/dev/null || echo "0")
    if [[ $disk_space -gt 1000 ]]; then
        log_success "Espace disque suffisant: ${disk_space}MB"
    else
        log_warning "Espace disque faible: ${disk_space}MB (recommandé: >1GB)"
    fi
}

check_network_ports() {
    log_info "Vérification des ports réseau..."
    
    local test_ports=(8075 8076 8077 8078 8079)
    
    for port in "${test_ports[@]}"; do
        check_item
        if lsof -tiTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
            log_warning "Port $port déjà utilisé"
        else
            log_success "Port $port disponible"
        fi
    done
}

check_scripts() {
    log_info "Vérification des scripts de lancement..."
    
    local scripts=(
        "launch_sama_conai.sh"
        "stop_sama_conai.sh"
        "test_cycle_sama_conai.sh"
        "cleanup_temp.sh"
        "quick_start.sh"
    )
    
    for script in "${scripts[@]}"; do
        check_item
        if [[ -f "./$script" ]]; then
            if [[ -x "./$script" ]]; then
                log_success "Script $script présent et exécutable"
            else
                log_warning "Script $script présent mais non exécutable"
            fi
        else
            log_error "Script $script manquant"
        fi
    done
}

# ============================================================================
# RAPPORT FINAL
# ============================================================================

print_summary() {
    echo
    echo -e "${BOLD}============================================================================${NC}"
    echo -e "${BOLD}                    RÉSUMÉ DE LA VALIDATION${NC}"
    echo -e "${BOLD}============================================================================${NC}"
    echo
    
    echo -e "${BLUE}Total des vérifications:${NC} $CHECKS_TOTAL"
    echo -e "${GREEN}Réussies:${NC} $CHECKS_PASSED"
    echo -e "${YELLOW}Avertissements:${NC} $CHECKS_WARNING"
    echo -e "${RED}Échecs:${NC} $CHECKS_FAILED"
    echo
    
    local success_rate
    success_rate=$((CHECKS_PASSED * 100 / CHECKS_TOTAL))
    
    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ ENVIRONNEMENT PRÊT${NC}"
        echo -e "${GREEN}Vous pouvez lancer le module avec: ./quick_start.sh init${NC}"
    elif [[ $CHECKS_FAILED -le 2 ]]; then
        echo -e "${YELLOW}${BOLD}! ENVIRONNEMENT PARTIELLEMENT PRÊT${NC}"
        echo -e "${YELLOW}Corrigez les erreurs critiques avant de continuer${NC}"
    else
        echo -e "${RED}${BOLD}✗ ENVIRONNEMENT NON PRÊT${NC}"
        echo -e "${RED}Plusieurs problèmes doivent être résolus${NC}"
    fi
    
    echo -e "${BLUE}Taux de réussite: ${success_rate}%${NC}"
    echo
}

# ============================================================================
# FONCTION PRINCIPALE
# ============================================================================

main() {
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}                    SAMA CONAI - Validation de l'environnement${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo
    
    check_odoo_installation
    echo
    
    check_python_environment
    echo
    
    check_postgresql
    echo
    
    check_custom_addons
    echo
    
    check_system_requirements
    echo
    
    check_network_ports
    echo
    
    check_scripts
    
    print_summary
    
    # Code de sortie basé sur les résultats
    if [[ $CHECKS_FAILED -eq 0 ]]; then
        exit 0
    elif [[ $CHECKS_FAILED -le 2 ]]; then
        exit 1
    else
        exit 2
    fi
}

# ============================================================================
# EXÉCUTION
# ============================================================================

main "$@"