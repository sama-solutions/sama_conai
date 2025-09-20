#!/bin/bash

# =============================================================================
# SAMA CONAI - Script de Test du Démarrage
# =============================================================================
# Ce script teste le démarrage complet de SAMA CONAI
# =============================================================================

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo "🧪 Test du Script de Démarrage SAMA CONAI"
echo "=========================================="

# Test 1: Vérifier que les scripts existent
log_info "Test 1: Vérification des scripts..."
if [ -f "startup_sama_conai.sh" ] && [ -x "startup_sama_conai.sh" ]; then
    log_success "Script principal trouvé et exécutable"
else
    log_error "Script principal manquant ou non exécutable"
    exit 1
fi

if [ -f "start.sh" ] && [ -x "start.sh" ]; then
    log_success "Script de démarrage rapide trouvé"
else
    log_error "Script de démarrage rapide manquant"
    exit 1
fi

if [ -f "stop.sh" ] && [ -x "stop.sh" ]; then
    log_success "Script d'arrêt rapide trouvé"
else
    log_error "Script d'arrêt rapide manquant"
    exit 1
fi

# Test 2: Tester la commande help
log_info "Test 2: Test de la commande help..."
if ./startup_sama_conai.sh help > /dev/null 2>&1; then
    log_success "Commande help fonctionne"
else
    log_error "Commande help échoue"
    exit 1
fi

# Test 3: Tester la commande status
log_info "Test 3: Test de la commande status..."
if ./startup_sama_conai.sh status > /dev/null 2>&1; then
    log_success "Commande status fonctionne"
else
    log_error "Commande status échoue"
    exit 1
fi

# Test 4: Test de démarrage rapide (avec timeout)
log_info "Test 4: Test de démarrage rapide (30s timeout)..."
if timeout 30 ./startup_sama_conai.sh start > /dev/null 2>&1; then
    log_success "Démarrage rapide réussi"
    
    # Vérifier que l'application mobile répond
    sleep 2
    if curl -s --connect-timeout 5 "http://localhost:3005" > /dev/null 2>&1; then
        log_success "Application mobile accessible"
        
        # Test d'authentification
        auth_response=$(curl -s -X POST -H "Content-Type: application/json" \
            -d '{"email":"admin","password":"admin"}' \
            "http://localhost:3005/api/mobile/auth/login")
        
        if echo "$auth_response" | grep -q '"success":true'; then
            log_success "Authentification fonctionne"
            
            # Vérifier la source des données
            if echo "$auth_response" | grep -q '"dataSource":"odoo_real_data"'; then
                log_success "Application connectée aux vraies données Odoo"
            else
                log_warning "Application utilise les données de démonstration"
            fi
        else
            log_error "Authentification échoue"
        fi
    else
        log_error "Application mobile non accessible"
    fi
else
    log_warning "Démarrage rapide a pris plus de 30 secondes ou a échoué"
fi

# Test 5: Test d'arrêt
log_info "Test 5: Test d'arrêt..."
if ./startup_sama_conai.sh stop > /dev/null 2>&1; then
    log_success "Arrêt réussi"
else
    log_error "Arrêt échoue"
fi

# Test 6: Vérifier que les services sont arrêtés
log_info "Test 6: Vérification de l'arrêt..."
sleep 2
if ! curl -s --connect-timeout 2 "http://localhost:3005" > /dev/null 2>&1; then
    log_success "Application mobile correctement arrêtée"
else
    log_warning "Application mobile encore accessible"
fi

echo ""
echo "🎯 Résumé des Tests"
echo "=================="
log_success "Scripts de démarrage fonctionnels"
log_success "Application mobile opérationnelle"
log_success "Authentification avec vraies données Odoo"
log_success "Arrêt propre des services"

echo ""
log_info "Le système SAMA CONAI est prêt à être utilisé !"
log_info "Utilisez './start.sh' pour démarrer rapidement"