#!/bin/bash

# =============================================================================
# SAMA CONAI - Script de Diagnostic
# =============================================================================
# Ce script effectue un diagnostic complet du système SAMA CONAI
# =============================================================================

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_section() {
    echo -e "${PURPLE}🔍 $1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

echo "🩺 Diagnostic Complet SAMA CONAI"
echo "================================="
echo ""

# Section 1: Environnement système
log_section "Environnement Système"

# Vérifier Python
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version)
    log_success "Python installé: $python_version"
else
    log_error "Python3 non installé"
fi

# Vérifier Node.js
if command -v node &> /dev/null; then
    node_version=$(node --version)
    log_success "Node.js installé: $node_version"
else
    log_error "Node.js non installé"
fi

# Vérifier npm
if command -v npm &> /dev/null; then
    npm_version=$(npm --version)
    log_success "npm installé: $npm_version"
else
    log_warning "npm non installé"
fi

# Vérifier curl
if command -v curl &> /dev/null; then
    log_success "curl disponible"
else
    log_error "curl non installé"
fi

echo ""

# Section 2: Structure des fichiers
log_section "Structure des Fichiers"

# Vérifier Odoo
if [ -d "/var/odoo/odoo18" ]; then
    log_success "Répertoire Odoo trouvé"
    if [ -f "/var/odoo/odoo18/odoo-bin" ]; then
        log_success "Exécutable Odoo trouvé"
    else
        log_error "Exécutable Odoo manquant"
    fi
else
    log_error "Répertoire Odoo non trouvé"
fi

# Vérifier les addons
if [ -d "/home/grand-as/psagsn/custom_addons" ]; then
    log_success "Répertoire des addons trouvé"
    if [ -d "/home/grand-as/psagsn/custom_addons/sama_conai" ]; then
        log_success "Module SAMA CONAI trouvé"
    else
        log_error "Module SAMA CONAI manquant"
    fi
else
    log_error "Répertoire des addons non trouvé"
fi

# Vérifier l'application mobile
if [ -d "mobile_app_web" ]; then
    log_success "Répertoire application mobile trouvé"
    if [ -f "mobile_app_web/server.js" ]; then
        log_success "Serveur mobile trouvé"
    else
        log_error "Serveur mobile manquant"
    fi
    if [ -f "mobile_app_web/package.json" ]; then
        log_success "package.json trouvé"
    else
        log_error "package.json manquant"
    fi
else
    log_error "Répertoire application mobile non trouvé"
fi

echo ""

# Section 3: Scripts de démarrage
log_section "Scripts de Démarrage"

scripts=("startup_sama_conai.sh" "start.sh" "stop.sh" "test_startup.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            log_success "$script: Trouvé et exécutable"
        else
            log_warning "$script: Trouvé mais non exécutable"
        fi
    else
        log_error "$script: Manquant"
    fi
done

echo ""

# Section 4: Ports et processus
log_section "Ports et Processus"

# Vérifier les ports
ports=("8077" "3005")
for port in "${ports[@]}"; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        process=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | head -1)
        log_info "Port $port: Utilisé par $process"
    else
        log_success "Port $port: Libre"
    fi
done

# Vérifier les processus Odoo
odoo_processes=$(ps aux | grep -v grep | grep "odoo-bin" | wc -l)
if [ "$odoo_processes" -gt 0 ]; then
    log_info "Processus Odoo actifs: $odoo_processes"
    ps aux | grep -v grep | grep "odoo-bin" | while read line; do
        log_info "  $line"
    done
else
    log_success "Aucun processus Odoo en cours"
fi

# Vérifier les processus Node.js
node_processes=$(ps aux | grep -v grep | grep "node.*server.js" | wc -l)
if [ "$node_processes" -gt 0 ]; then
    log_info "Processus Node.js actifs: $node_processes"
    ps aux | grep -v grep | grep "node.*server.js" | while read line; do
        log_info "  $line"
    done
else
    log_success "Aucun processus Node.js en cours"
fi

echo ""

# Section 5: Connectivité
log_section "Tests de Connectivité"

# Test Odoo
if curl -s --connect-timeout 5 "http://localhost:8077" > /dev/null 2>&1; then
    log_success "Odoo accessible sur http://localhost:8077"
else
    log_warning "Odoo non accessible sur http://localhost:8077"
fi

# Test application mobile
if curl -s --connect-timeout 5 "http://localhost:3005" > /dev/null 2>&1; then
    log_success "Application mobile accessible sur http://localhost:3005"
    
    # Test d'authentification
    auth_response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"email":"admin","password":"admin"}' \
        "http://localhost:3005/api/mobile/auth/login" 2>/dev/null)
    
    if echo "$auth_response" | grep -q '"success":true' 2>/dev/null; then
        log_success "API d'authentification fonctionne"
        
        if echo "$auth_response" | grep -q '"dataSource":"odoo_real_data"' 2>/dev/null; then
            log_success "Application connectée aux vraies données Odoo"
        elif echo "$auth_response" | grep -q '"dataSource":"demo_data"' 2>/dev/null; then
            log_warning "Application utilise les données de démonstration"
        else
            log_warning "Source de données inconnue"
        fi
    else
        log_error "API d'authentification ne fonctionne pas"
    fi
else
    log_warning "Application mobile non accessible sur http://localhost:3005"
fi

echo ""

# Section 6: Fichiers de logs
log_section "Fichiers de Logs"

log_files=("logs/odoo.log" "logs/mobile.log" "logs/startup.log")
for log_file in "${log_files[@]}"; do
    if [ -f "$log_file" ]; then
        size=$(du -h "$log_file" | cut -f1)
        lines=$(wc -l < "$log_file")
        log_success "$log_file: $size ($lines lignes)"
        
        # Afficher les dernières erreurs
        if grep -i "error\|exception\|failed" "$log_file" | tail -3 | grep -q .; then
            log_warning "Dernières erreurs dans $log_file:"
            grep -i "error\|exception\|failed" "$log_file" | tail -3 | while read line; do
                echo "    $line"
            done
        fi
    else
        log_info "$log_file: Pas encore créé"
    fi
done

echo ""

# Section 7: Espace disque
log_section "Espace Disque"

df_output=$(df -h . | tail -1)
log_info "Espace disque: $df_output"

echo ""

# Section 8: Recommandations
log_section "Recommandations"

if ! command -v python3 &> /dev/null || ! command -v node &> /dev/null; then
    log_error "Installez Python3 et Node.js avant de continuer"
fi

if [ ! -d "/var/odoo/odoo18" ]; then
    log_error "Installez Odoo 18 dans /var/odoo/odoo18"
fi

if [ ! -d "mobile_app_web/node_modules" ]; then
    log_warning "Exécutez 'cd mobile_app_web && npm install' pour installer les dépendances"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8077 \|:3005 "; then
    log_warning "Arrêtez les services existants avant de redémarrer"
fi

echo ""
log_info "Diagnostic terminé. Utilisez './startup_sama_conai.sh start' pour démarrer les services."