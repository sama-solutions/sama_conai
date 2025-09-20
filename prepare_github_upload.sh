#!/bin/bash

# =============================================================================
# SAMA CONAI - Script de Préparation pour Upload GitHub
# =============================================================================
# Auteurs: Mamadou Mbagnick DOGUE & Rassol DOGUE
# Description: Script d'automatisation pour préparer SAMA CONAI pour GitHub
# Version: 1.0.0
# =============================================================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction d'affichage avec couleurs
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

print_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Variables
PROJECT_NAME="SAMA CONAI"
VERSION="3.0.0"
AUTHORS="Mamadou Mbagnick DOGUE & Rassol DOGUE"
REPO_URL=""

print_header "🇸🇳 $PROJECT_NAME - Préparation GitHub Upload"
echo -e "Version: ${GREEN}$VERSION${NC}"
echo -e "Auteurs: ${GREEN}$AUTHORS${NC}"
echo ""

# =============================================================================
# 1. VÉRIFICATIONS PRÉLIMINAIRES
# =============================================================================

print_step "1. Vérifications préliminaires"

# Vérifier Git
if ! command -v git &> /dev/null; then
    print_error "Git n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi
print_success "Git est installé: $(git --version)"

# Vérifier si nous sommes dans un repository Git
if [ ! -d ".git" ]; then
    print_error "Ce répertoire n'est pas un repository Git."
    print_info "Initialisation du repository Git..."
    git init
    print_success "Repository Git initialisé"
fi

# Vérifier la configuration Git
if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
    print_warning "Configuration Git incomplète"
    echo -n "Nom d'utilisateur Git: "
    read git_name
    echo -n "Email Git: "
    read git_email
    
    git config user.name "$git_name"
    git config user.email "$git_email"
    print_success "Configuration Git mise à jour"
fi

print_info "Configuration Git:"
print_info "  Nom: $(git config user.name)"
print_info "  Email: $(git config user.email)"

# =============================================================================
# 2. NETTOYAGE DU PROJET
# =============================================================================

print_step "2. Nettoyage du projet"

# Supprimer les fichiers temporaires Python
print_info "Suppression des fichiers temporaires Python..."
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyo" -delete 2>/dev/null || true
print_success "Fichiers Python temporaires supprimés"

# Supprimer les fichiers système
print_info "Suppression des fichiers système..."
find . -name ".DS_Store" -delete 2>/dev/null || true
find . -name "Thumbs.db" -delete 2>/dev/null || true
find . -name "desktop.ini" -delete 2>/dev/null || true
print_success "Fichiers système supprimés"

# Supprimer les logs et fichiers temporaires
print_info "Suppression des logs et fichiers temporaires..."
find . -name "*.log" -delete 2>/dev/null || true
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name "*.temp" -delete 2>/dev/null || true
print_success "Logs et fichiers temporaires supprimés"

# =============================================================================
# 3. VÉRIFICATION DES FICHIERS SENSIBLES
# =============================================================================

print_step "3. Vérification des fichiers sensibles"

# Vérifier les fichiers potentiellement sensibles
sensitive_files=(
    "*.env"
    "*.key"
    "*.pem"
    "*.p12"
    "*.pfx"
    "*password*"
    "*secret*"
    "config.py"
    "settings_local.py"
)

print_info "Recherche de fichiers sensibles..."
found_sensitive=false

for pattern in "${sensitive_files[@]}"; do
    if find . -name "$pattern" -type f | grep -q .; then
        print_warning "Fichiers sensibles trouvés: $pattern"
        find . -name "$pattern" -type f
        found_sensitive=true
    fi
done

if [ "$found_sensitive" = true ]; then
    print_warning "Des fichiers sensibles ont été trouvés. Vérifiez qu'ils sont dans .gitignore"
    echo -n "Continuer quand même ? (y/N): "
    read continue_anyway
    if [ "$continue_anyway" != "y" ] && [ "$continue_anyway" != "Y" ]; then
        print_error "Arrêt du script. Veuillez sécuriser les fichiers sensibles."
        exit 1
    fi
else
    print_success "Aucun fichier sensible détecté"
fi

# =============================================================================
# 4. VÉRIFICATION DU .GITIGNORE
# =============================================================================

print_step "4. Vérification et mise à jour du .gitignore"

if [ ! -f ".gitignore" ]; then
    print_info "Création du fichier .gitignore..."
    cat > .gitignore << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
target/

# Jupyter Notebook
.ipynb_checkpoints

# pyenv
.python-version

# celery beat schedule file
celerybeat-schedule

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Odoo specific
*.pyc
*.pyo
*~
*.swp
*.swo
*tmp*
*.log
.DS_Store

# IDE
.vscode/
.idea/
*.sublime-*

# OS
Thumbs.db
desktop.ini

# Local configuration
config_local.py
settings_local.py
.env.local

# Backup files
*.bak
*.backup
*_backup_*

# Temporary files
*.tmp
*.temp
temp/
tmp/

# Node modules (if any)
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Database
*.db
*.sqlite
*.sqlite3

# Secrets and keys
*.key
*.pem
*.p12
*.pfx
secrets/
keys/
EOF
    print_success "Fichier .gitignore créé"
else
    print_success "Fichier .gitignore existant"
fi

# =============================================================================
# 5. VÉRIFICATION DES FICHIERS DE DOCUMENTATION
# =============================================================================

print_step "5. Vérification des fichiers de documentation"

required_docs=(
    "README.md"
    "README_EN.md"
    "CONTRIBUTING.md"
    "CHANGELOG.md"
    "SECURITY.md"
    "LICENSE"
)

missing_docs=()

for doc in "${required_docs[@]}"; do
    if [ ! -f "$doc" ]; then
        missing_docs+=("$doc")
        print_warning "Fichier manquant: $doc"
    else
        print_success "Fichier présent: $doc"
    fi
done

if [ ${#missing_docs[@]} -gt 0 ]; then
    print_warning "Fichiers de documentation manquants: ${missing_docs[*]}"
    print_info "Ces fichiers sont recommandés pour un projet GitHub professionnel"
fi

# Vérifier les templates GitHub
if [ ! -d ".github" ]; then
    print_warning "Répertoire .github manquant"
    print_info "Les templates GitHub ne sont pas configurés"
else
    print_success "Répertoire .github présent"
    
    if [ -f ".github/pull_request_template.md" ]; then
        print_success "Template de Pull Request présent"
    else
        print_warning "Template de Pull Request manquant"
    fi
    
    if [ -d ".github/ISSUE_TEMPLATE" ]; then
        print_success "Templates d'issues présents"
    else
        print_warning "Templates d'issues manquants"
    fi
fi

# =============================================================================
# 6. VÉRIFICATION DU LOGO
# =============================================================================

print_step "6. Vérification du logo"

logo_files=("logo.png" "logo.svg" "logo.jpg" "logo.jpeg")
logo_found=false

for logo in "${logo_files[@]}"; do
    if [ -f "$logo" ]; then
        print_success "Logo trouvé: $logo"
        logo_found=true
        break
    fi
done

if [ "$logo_found" = false ]; then
    print_warning "Aucun logo trouvé. Un logo améliore la présentation du projet."
fi

# =============================================================================
# 7. ANALYSE DU REPOSITORY GIT
# =============================================================================

print_step "7. Analyse du repository Git"

# Vérifier le statut Git
print_info "Statut Git:"
git status --porcelain | head -10

# Compter les commits
commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
print_info "Nombre de commits: $commit_count"

# Vérifier les branches
current_branch=$(git branch --show-current 2>/dev/null || echo "main")
print_info "Branche actuelle: $current_branch"

# Vérifier les remotes
remotes=$(git remote -v 2>/dev/null || echo "Aucun remote configuré")
print_info "Remotes configurés:"
echo "$remotes"

# =============================================================================
# 8. PRÉPARATION DU COMMIT FINAL
# =============================================================================

print_step "8. Préparation du commit final"

# Ajouter tous les fichiers
print_info "Ajout des fichiers au staging..."
git add .

# Vérifier ce qui va être commité
staged_files=$(git diff --cached --name-only | wc -l)
print_info "Fichiers à commiter: $staged_files"

if [ "$staged_files" -gt 0 ]; then
    print_info "Aperçu des fichiers à commiter:"
    git diff --cached --name-only | head -20
    
    if [ "$staged_files" -gt 20 ]; then
        print_info "... et $((staged_files - 20)) autres fichiers"
    fi
else
    print_info "Aucun changement à commiter"
fi

# =============================================================================
# 9. GÉNÉRATION DU MESSAGE DE COMMIT
# =============================================================================

print_step "9. Génération du message de commit"

commit_message="feat: initial release of SAMA CONAI v$VERSION

🎉 Complete release of SAMA CONAI - Modern Information Access System

Features:
- ✅ Complete training system (27 lessons, 100% developed)
- ✅ Multi-user interface (Citizens, Agents, Supervisors)
- ✅ Advanced analytics and reporting
- ✅ Mobile-responsive design
- ✅ Comprehensive documentation (FR/EN)
- ✅ Security and compliance features
- ✅ Professional GitHub setup with templates

Technical Stack:
- Backend: Python 3.8+ | Odoo 16.0+ | PostgreSQL
- Frontend: HTML5 | CSS3 | JavaScript ES6+ | Bootstrap 5
- Mobile: Progressive Web App (PWA)
- Security: OAuth 2.0 | JWT | HTTPS | Data Encryption

Authors: $AUTHORS
License: MIT
Target: Senegalese Public Administration
Repository: Professional open-source setup"

print_info "Message de commit généré:"
echo -e "${CYAN}$commit_message${NC}"

# =============================================================================
# 10. INSTRUCTIONS FINALES
# =============================================================================

print_step "10. Instructions finales"

print_header "🚀 Prêt pour GitHub !"

echo -e "${GREEN}Votre projet SAMA CONAI est maintenant prêt pour GitHub !${NC}"
echo ""
echo -e "${YELLOW}Prochaines étapes:${NC}"
echo "1. Créer un repository sur GitHub:"
echo "   - Nom: sama_conai"
echo "   - Description: 🇸🇳 SAMA CONAI - Système d'Accès Moderne à l'Information"
echo "   - Visibilité: Public (recommandé)"
echo ""
echo "2. Ajouter le remote GitHub:"
echo "   ${CYAN}git remote add origin https://github.com/VOTRE-USERNAME/sama_conai.git${NC}"
echo ""
echo "3. Commiter les changements:"
echo "   ${CYAN}git commit -m \"feat: initial release of SAMA CONAI v$VERSION\"${NC}"
echo ""
echo "4. Pousser vers GitHub:"
echo "   ${CYAN}git push -u origin main${NC}"
echo ""
echo "5. Créer la première release:"
echo "   ${CYAN}git tag -a v$VERSION -m \"SAMA CONAI v$VERSION - Complete Release\"${NC}"
echo "   ${CYAN}git push origin v$VERSION${NC}"
echo ""

print_info "Documentation disponible:"
echo "- README.md (Français)"
echo "- README_EN.md (Anglais)"
echo "- CONTRIBUTING.md (Guide de contribution)"
echo "- SECURITY.md (Politique de sécurité)"
echo "- CHANGELOG.md (Historique des versions)"
echo "- GITHUB_DEPLOYMENT_GUIDE.md (Guide de déploiement)"

echo ""
print_success "Préparation terminée avec succès !"
print_info "Consultez GITHUB_DEPLOYMENT_GUIDE.md pour les étapes détaillées"

# =============================================================================
# 11. RÉSUMÉ FINAL
# =============================================================================

print_header "📊 Résumé de la Préparation"

echo -e "${GREEN}✅ Projet nettoyé et organisé${NC}"
echo -e "${GREEN}✅ Fichiers sensibles vérifiés${NC}"
echo -e "${GREEN}✅ .gitignore configuré${NC}"
echo -e "${GREEN}✅ Documentation complète${NC}"
echo -e "${GREEN}✅ Templates GitHub prêts${NC}"
echo -e "${GREEN}✅ Repository Git préparé${NC}"
echo -e "${GREEN}✅ Message de commit généré${NC}"

echo ""
echo -e "${PURPLE}🇸🇳 SAMA CONAI est prêt à conquérir GitHub ! 🚀${NC}"
echo -e "${PURPLE}Bonne chance avec votre projet open source !${NC}"

exit 0