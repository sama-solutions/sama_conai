#!/bin/bash

# =============================================================================
# SAMA CONAI - Upload Manuel Étape par Étape
# =============================================================================
# Auteurs: Mamadou Mbagnick DOGUE & Rassol DOGUE
# Description: Guide d'upload manuel avec instructions claires
# =============================================================================

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
    echo -e "${BLUE}[ÉTAPE $1]${NC} $2"
}

print_command() {
    echo -e "${CYAN}Commande à exécuter:${NC}"
    echo -e "${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_header "🇸🇳 SAMA CONAI - Guide d'Upload Manuel"

echo -e "${GREEN}Ce script vous guide étape par étape pour uploader SAMA CONAI sur GitHub${NC}"
echo -e "${CYAN}Suivez les instructions et exécutez les commandes une par une${NC}"
echo ""

# =============================================================================
# ÉTAPE 1 : VÉRIFICATIONS
# =============================================================================

print_step "1" "Vérifications préliminaires"

echo "Vérifiez que vous êtes dans le bon répertoire :"
print_command "pwd"
echo ""

echo "Vérifiez le statut Git :"
print_command "git status"
echo ""

echo "Vérifiez les commits :"
print_command "git log --oneline -5"
echo ""

echo "Vérifiez les tags :"
print_command "git tag -l"
echo ""

# =============================================================================
# ÉTAPE 2 : AUTHENTIFICATION
# =============================================================================

print_step "2" "Authentification GitHub"

echo "Vérifiez si vous êtes authentifié :"
print_command "gh auth status"
echo ""

echo "Si pas authentifié, lancez :"
print_command "gh auth login"
echo ""
echo -e "${CYAN}Répondez aux questions :${NC}"
echo "  - What account? → GitHub.com"
echo "  - Protocol? → HTTPS"
echo "  - Authenticate Git? → Yes"
echo "  - How to authenticate? → Login with a web browser"
echo ""

# =============================================================================
# ÉTAPE 3 : UPLOAD
# =============================================================================

print_step "3" "Upload du code"

echo "Uploadez la branche principale :"
print_command "git push origin main"
echo ""

echo "Uploadez le tag de version :"
print_command "git push origin v3.0.0"
echo ""

# =============================================================================
# ÉTAPE 4 : VÉRIFICATION
# =============================================================================

print_step "4" "Vérification"

echo "Vérifiez que le repository est accessible :"
print_command "gh repo view sama-solutions/conai"
echo ""

echo "Ouvrez le repository dans le navigateur :"
print_command "gh repo view sama-solutions/conai --web"
echo ""

# =============================================================================
# ÉTAPE 5 : RELEASE
# =============================================================================

print_step "5" "Création de la release (optionnel)"

echo "Créez la première release :"
print_command "gh release create v3.0.0 --title 'SAMA CONAI v3.0.0 - Complete Release 🎉' --notes 'Première version stable de SAMA CONAI pour l'administration publique sénégalaise'"
echo ""

# =============================================================================
# ÉTAPE 6 : CONFIGURATION
# =============================================================================

print_step "6" "Configuration du repository (optionnel)"

echo "Activez les fonctionnalités :"
print_command "gh repo edit sama-solutions/conai --enable-issues --enable-wiki --enable-projects --enable-discussions"
echo ""

echo "Ajoutez les topics :"
print_command "gh repo edit sama-solutions/conai --add-topic senegal,public-administration,information-access,transparency,odoo,python,government,africa,open-source,civic-tech"
echo ""

# =============================================================================
# LIENS UTILES
# =============================================================================

print_header "🔗 Liens Utiles"

echo -e "${YELLOW}Repository GitHub:${NC}"
echo "https://github.com/sama-solutions/conai"
echo ""

echo -e "${YELLOW}Après l'upload, vérifiez :${NC}"
echo "  - README.md s'affiche correctement"
echo "  - Logo SAMA CONAI visible"
echo "  - Templates d'issues disponibles"
echo "  - Tag v3.0.0 présent"
echo ""

echo -e "${YELLOW}Commandes de vérification :${NC}"
echo "  - gh repo view sama-solutions/conai"
echo "  - gh release list"
echo "  - gh issue list"
echo ""

print_header "🎉 Bonne Chance avec l'Upload !"

echo -e "${GREEN}Suivez les étapes ci-dessus une par une${NC}"
echo -e "${GREEN}SAMA CONAI sera bientôt sur GitHub ! 🚀${NC}"

exit 0