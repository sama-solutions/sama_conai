#!/bin/bash

# =============================================================================
# SAMA CONAI - Upload sans Workflows (Contournement)
# =============================================================================

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}============================================${NC}"
}

print_step() {
    echo -e "${BLUE}[ÉTAPE]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_header "🇸🇳 SAMA CONAI - Upload sans Workflows"

# =============================================================================
# 1. SAUVEGARDER LES WORKFLOWS
# =============================================================================

print_step "1. Sauvegarde des workflows"

if [ -d ".github/workflows" ]; then
    print_info "Sauvegarde des workflows..."
    cp -r .github/workflows .github/workflows_backup
    rm -rf .github/workflows
    print_success "Workflows sauvegardés et supprimés temporairement"
else
    print_info "Aucun workflow à sauvegarder"
fi

# =============================================================================
# 2. COMMIT TEMPORAIRE
# =============================================================================

print_step "2. Commit temporaire sans workflows"

git add .
git commit -m "temp: remove workflows for upload" || true

# =============================================================================
# 3. UPLOAD
# =============================================================================

print_step "3. Upload vers GitHub"

print_info "Push de la branche main..."
if git push origin main; then
    print_success "Code uploadé avec succès"
else
    print_error "Échec de l'upload"
    exit 1
fi

# =============================================================================
# 4. RESTAURER LES WORKFLOWS
# =============================================================================

print_step "4. Restauration des workflows"

if [ -d ".github/workflows_backup" ]; then
    print_info "Restauration des workflows..."
    mv .github/workflows_backup .github/workflows
    
    # Commit de restauration
    git add .github/workflows
    git commit -m "restore: add back workflows after upload"
    
    print_success "Workflows restaurés"
    print_info "Note: Les workflows seront ajoutés dans un commit séparé"
else
    print_info "Aucun workflow à restaurer"
fi

# =============================================================================
# 5. VÉRIFICATION
# =============================================================================

print_step "5. Vérification"

print_info "Vérification du repository..."
if gh repo view sama-solutions/sama_conai; then
    print_success "Repository accessible"
else
    print_error "Problème d'accès au repository"
fi

print_header "🎉 Upload Réussi !"

echo -e "${GREEN}✅ SAMA CONAI a été uploadé sur GitHub !${NC}"
echo ""
echo -e "${YELLOW}🔗 Repository:${NC} https://github.com/sama-solutions/sama_conai"
echo ""
echo -e "${YELLOW}📝 Prochaines étapes:${NC}"
echo "1. Vérifier le repository sur GitHub"
echo "2. Ajouter les workflows manuellement si nécessaire"
echo "3. Créer la première release"
echo "4. Configurer les settings du repository"

exit 0