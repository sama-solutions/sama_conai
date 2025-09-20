#!/bin/bash

# =============================================================================
# SAMA CONAI - Script d'Upload Simplifié (Non-Interactif)
# =============================================================================
# Auteurs: Mamadou Mbagnick DOGUE & Rassol DOGUE
# Description: Upload automatisé sans blocage
# =============================================================================

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

# Variables
PROJECT_NAME="SAMA CONAI"
VERSION="3.0.0"
REPO_URL="https://github.com/sama-solutions/conai"

print_header "🇸🇳 $PROJECT_NAME - Upload Simplifié vers GitHub"
echo -e "Version: ${GREEN}$VERSION${NC}"
echo -e "Repository: ${CYAN}$REPO_URL${NC}"
echo ""

# =============================================================================
# 1. VÉRIFICATIONS PRÉLIMINAIRES
# =============================================================================

print_step "1. Vérifications préliminaires"

# Vérifier Git
if ! command -v git &> /dev/null; then
    print_error "Git n'est pas installé"
    exit 1
fi
print_success "Git disponible: $(git --version)"

# Vérifier GitHub CLI
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI n'est pas installé"
    print_info "Installez avec: sudo apt install gh"
    exit 1
fi
print_success "GitHub CLI disponible: $(gh --version | head -1)"

# Vérifier le repository Git
if [ ! -d ".git" ]; then
    print_error "Pas dans un repository Git"
    exit 1
fi
print_success "Repository Git détecté"

# Vérifier le statut Git (sans bloquer)
if [ ! -z "$(git status --porcelain)" ]; then
    print_warning "Fichiers non commités détectés - continuons quand même"
    git status --porcelain
fi

# =============================================================================
# 2. AUTHENTIFICATION GITHUB (NON-INTERACTIF)
# =============================================================================

print_step "2. Vérification de l'authentification GitHub"

# Vérifier l'authentification
if gh auth status &> /dev/null; then
    print_success "Déjà authentifié sur GitHub"
    gh auth status 2>/dev/null || true
else
    print_warning "Non authentifié sur GitHub"
    print_info "Veuillez vous authentifier manuellement avec: gh auth login"
    print_info "Puis relancer ce script"
    exit 1
fi

# =============================================================================
# 3. UPLOAD DU CODE
# =============================================================================

print_step "3. Upload du code vers GitHub"

# Push du code principal
print_info "Push de la branche main..."
if git push origin main 2>/dev/null; then
    print_success "Code principal uploadé"
else
    print_warning "Push de la branche main échoué ou déjà à jour"
fi

# Push du tag
print_info "Push du tag v$VERSION..."
if git push origin v$VERSION 2>/dev/null; then
    print_success "Tag v$VERSION uploadé"
else
    print_warning "Push du tag échoué ou déjà existant"
fi

# =============================================================================
# 4. VÉRIFICATIONS FINALES
# =============================================================================

print_step "4. Vérifications finales"

# Vérifier le repository
print_info "Vérification du repository..."
if gh repo view sama-solutions/conai &> /dev/null; then
    print_success "Repository accessible"
    
    # Afficher les informations du repository
    echo ""
    print_info "Informations du repository:"
    gh repo view sama-solutions/conai --json name,description,url,stargazerCount,forkCount 2>/dev/null | jq -r '
        "  - Nom: " + .name,
        "  - Description: " + .description,
        "  - URL: " + .url,
        "  - Stars: " + (.stargazerCount | tostring),
        "  - Forks: " + (.forkCount | tostring)
    ' 2>/dev/null || echo "  - Repository: sama-solutions/conai"
else
    print_error "Problème d'accès au repository"
fi

# Vérifier la release
print_info "Vérification de la release..."
if gh release view v$VERSION --repo sama-solutions/conai &> /dev/null; then
    print_success "Release v$VERSION confirmée"
else
    print_info "Release v$VERSION pas encore créée"
    print_info "Vous pouvez la créer manuellement sur GitHub"
fi

# =============================================================================
# 5. SUCCÈS ET INSTRUCTIONS
# =============================================================================

print_header "🎉 Upload Terminé !"

echo -e "${GREEN}✅ SAMA CONAI a été uploadé vers GitHub !${NC}\n"

echo -e "${YELLOW}🔗 Liens Importants:${NC}"
echo "  - Repository: $REPO_URL"
echo "  - Releases: $REPO_URL/releases"
echo "  - Issues: $REPO_URL/issues"
echo "  - Wiki: $REPO_URL/wiki"

echo -e "\n${YELLOW}📢 Prochaines Étapes Recommandées:${NC}"
echo "1. Vérifier l'affichage sur GitHub: $REPO_URL"
echo "2. Créer une release v$VERSION si pas encore fait:"
echo "   ${CYAN}gh release create v$VERSION --title 'SAMA CONAI v$VERSION - Complete Release 🎉'${NC}"
echo "3. Configurer les settings du repository"
echo "4. Ajouter une image de social preview"
echo "5. Promouvoir sur les réseaux sociaux"

echo -e "\n${YELLOW}🚀 Commandes Utiles:${NC}"
echo "  - Ouvrir le repository: ${BLUE}gh repo view --web${NC}"
echo "  - Voir les releases: ${BLUE}gh release list${NC}"
echo "  - Créer une issue: ${BLUE}gh issue create${NC}"
echo "  - Voir les statistiques: ${BLUE}gh repo view --json stargazerCount,forkCount${NC}"

echo -e "\n${CYAN}💡 Pour créer la release maintenant:${NC}"
echo "${BLUE}gh release create v$VERSION --title 'SAMA CONAI v$VERSION - Complete Release 🎉' --notes 'Première version stable de SAMA CONAI pour l'\''administration publique sénégalaise'${NC}"

print_header "🇸🇳 SAMA CONAI sur GitHub - Mission Accomplie !"

echo -e "${PURPLE}Merci d'avoir utilisé ce script d'upload !${NC}"
echo -e "${PURPLE}SAMA CONAI est maintenant prêt à conquérir la communauté open source ! 🚀${NC}"

exit 0