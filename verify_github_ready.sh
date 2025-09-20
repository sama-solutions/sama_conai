#!/bin/bash

# =============================================================================
# SAMA CONAI - Vérification Finale pour GitHub
# =============================================================================
# Auteurs: Mamadou Mbagnick DOGUE & Rassol DOGUE
# Description: Script de vérification finale avant upload GitHub
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

print_check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_header "🇸🇳 SAMA CONAI - Vérification Finale GitHub"

# =============================================================================
# 1. VÉRIFICATION GIT
# =============================================================================
echo -e "\n${BLUE}1. Vérification Git${NC}"

# Vérifier que nous sommes dans un repo Git
if [ -d ".git" ]; then
    print_check 0 "Repository Git initialisé"
else
    print_check 1 "Repository Git manquant"
    exit 1
fi

# Vérifier le commit initial
commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
if [ "$commit_count" -gt 0 ]; then
    print_check 0 "Commit initial présent ($commit_count commits)"
else
    print_check 1 "Aucun commit trouvé"
fi

# Vérifier le tag
if git tag | grep -q "v3.0.0"; then
    print_check 0 "Tag v3.0.0 créé"
else
    print_check 1 "Tag v3.0.0 manquant"
fi

# Vérifier le statut Git
if [ -z "$(git status --porcelain)" ]; then
    print_check 0 "Working directory propre"
else
    print_warning "Fichiers non commités détectés"
    git status --porcelain
fi

# =============================================================================
# 2. VÉRIFICATION DOCUMENTATION
# =============================================================================
echo -e "\n${BLUE}2. Vérification Documentation${NC}"

required_docs=(
    "README.md"
    "README_EN.md"
    "CONTRIBUTING.md"
    "CHANGELOG.md"
    "SECURITY.md"
    "LICENSE"
    "QUICKSTART.md"
)

for doc in "${required_docs[@]}"; do
    if [ -f "$doc" ]; then
        size=$(wc -c < "$doc")
        if [ "$size" -gt 1000 ]; then
            print_check 0 "$doc présent (${size} bytes)"
        else
            print_warning "$doc présent mais petit (${size} bytes)"
        fi
    else
        print_check 1 "$doc manquant"
    fi
done

# =============================================================================
# 3. VÉRIFICATION TEMPLATES GITHUB
# =============================================================================
echo -e "\n${BLUE}3. Vérification Templates GitHub${NC}"

if [ -d ".github" ]; then
    print_check 0 "Dossier .github présent"
    
    # Templates d'issues
    if [ -d ".github/ISSUE_TEMPLATE" ]; then
        issue_count=$(find .github/ISSUE_TEMPLATE -name "*.md" | wc -l)
        print_check 0 "Templates d'issues présents ($issue_count templates)"
    else
        print_check 1 "Templates d'issues manquants"
    fi
    
    # Template PR
    if [ -f ".github/pull_request_template.md" ]; then
        print_check 0 "Template Pull Request présent"
    else
        print_check 1 "Template Pull Request manquant"
    fi
    
    # Workflow CI/CD
    if [ -f ".github/workflows/ci.yml" ]; then
        print_check 0 "Workflow CI/CD présent"
    else
        print_check 1 "Workflow CI/CD manquant"
    fi
else
    print_check 1 "Dossier .github manquant"
fi

# =============================================================================
# 4. VÉRIFICATION LOGO ET ASSETS
# =============================================================================
echo -e "\n${BLUE}4. Vérification Logo et Assets${NC}"

if [ -f "logo.png" ]; then
    print_check 0 "Logo PNG présent"
else
    print_check 1 "Logo PNG manquant"
fi

if [ -f "logo.svg" ]; then
    print_check 0 "Logo SVG présent"
else
    print_warning "Logo SVG manquant (optionnel)"
fi

# =============================================================================
# 5. VÉRIFICATION CONFIGURATION
# =============================================================================
echo -e "\n${BLUE}5. Vérification Configuration${NC}"

if [ -f ".gitignore" ]; then
    gitignore_size=$(wc -l < ".gitignore")
    print_check 0 ".gitignore présent ($gitignore_size lignes)"
else
    print_check 1 ".gitignore manquant"
fi

if [ -f ".pre-commit-config.yaml" ]; then
    print_check 0 "Configuration pre-commit présente"
else
    print_warning "Configuration pre-commit manquante (optionnel)"
fi

if [ -f "requirements.txt" ]; then
    print_check 0 "requirements.txt présent"
else
    print_check 1 "requirements.txt manquant"
fi

if [ -f "requirements-dev.txt" ]; then
    print_check 0 "requirements-dev.txt présent"
else
    print_warning "requirements-dev.txt manquant (optionnel)"
fi

# =============================================================================
# 6. VÉRIFICATION CONTENU WEBSITE
# =============================================================================
echo -e "\n${BLUE}6. Vérification Contenu Website${NC}"

if [ -d "website" ]; then
    print_check 0 "Dossier website présent"
    
    # Vérifier les fichiers principaux
    if [ -f "website/index.html" ]; then
        print_check 0 "Page d'accueil présente"
    else
        print_check 1 "Page d'accueil manquante"
    fi
    
    # Vérifier les formations
    if [ -d "website/formation" ]; then
        formation_count=$(find website/formation -name "*.html" | wc -l)
        print_check 0 "Pages de formation présentes ($formation_count pages)"
    else
        print_check 1 "Pages de formation manquantes"
    fi
    
    # Vérifier les assets
    if [ -d "website/assets" ]; then
        css_count=$(find website/assets -name "*.css" | wc -l)
        js_count=$(find website/assets -name "*.js" | wc -l)
        print_check 0 "Assets présents ($css_count CSS, $js_count JS)"
    else
        print_check 1 "Assets manquants"
    fi
else
    print_check 1 "Dossier website manquant"
fi

# =============================================================================
# 7. VÉRIFICATION SÉCURITÉ
# =============================================================================
echo -e "\n${BLUE}7. Vérification Sécurité${NC}"

# Vérifier les fichiers sensibles
sensitive_found=false
if find . -name "*.env" -not -path "./.git/*" | grep -q .; then
    print_warning "Fichiers .env trouvés (vérifiez .gitignore)"
    sensitive_found=true
fi

if find . -name "*.key" -not -path "./.git/*" -not -path "./node_modules/*" | grep -q .; then
    print_warning "Fichiers .key trouvés (vérifiez .gitignore)"
    sensitive_found=true
fi

if [ "$sensitive_found" = false ]; then
    print_check 0 "Aucun fichier sensible détecté"
fi

# =============================================================================
# 8. STATISTIQUES FINALES
# =============================================================================
echo -e "\n${BLUE}8. Statistiques du Projet${NC}"

total_files=$(find . -type f -not -path "./.git/*" | wc -l)
print_info "Total fichiers: $total_files"

total_lines=$(find . -name "*.py" -o -name "*.js" -o -name "*.html" -o -name "*.css" -o -name "*.md" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
print_info "Total lignes de code: $total_lines"

repo_size=$(du -sh . | cut -f1)
print_info "Taille du repository: $repo_size"

# =============================================================================
# 9. INSTRUCTIONS FINALES
# =============================================================================
print_header "🚀 Prêt pour GitHub !"

echo -e "${GREEN}✅ SAMA CONAI est prêt pour l'upload GitHub !${NC}\n"

echo -e "${YELLOW}Prochaines étapes:${NC}"
echo "1. Créer un repository sur GitHub:"
echo "   - Nom: sama_conai"
echo "   - Description: 🇸🇳 SAMA CONAI - Système d'Accès Moderne à l'Information"
echo "   - Visibilité: Public"
echo ""
echo "2. Ajouter le remote:"
echo "   ${BLUE}git remote add origin https://github.com/VOTRE-USERNAME/sama_conai.git${NC}"
echo ""
echo "3. Push vers GitHub:"
echo "   ${BLUE}git push -u origin main${NC}"
echo "   ${BLUE}git push origin v3.0.0${NC}"
echo ""
echo "4. Créer la première release sur GitHub"
echo ""
echo "5. Configurer les settings du repository"
echo ""

print_info "Consultez UPLOAD_INSTRUCTIONS_FINAL.md pour les détails complets"

echo -e "\n${PURPLE}🇸🇳 Bon lancement sur GitHub ! 🚀${NC}"

exit 0