#!/bin/bash

# =============================================================================
# SAMA CONAI - Script d'Upload Automatisé vers GitHub
# =============================================================================
# Auteurs: Mamadou Mbagnick DOGUE & Rassol DOGUE
# Description: Upload automatisé de SAMA CONAI vers GitHub
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

print_header "🇸🇳 $PROJECT_NAME - Upload vers GitHub"
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

# Vérifier le statut Git
if [ ! -z "$(git status --porcelain)" ]; then
    print_warning "Fichiers non commités détectés"
    git status --porcelain
    echo -n "Continuer quand même ? (y/N): "
    read continue_anyway
    if [ "$continue_anyway" != "y" ] && [ "$continue_anyway" != "Y" ]; then
        print_error "Upload annulé"
        exit 1
    fi
fi

# =============================================================================
# 2. AUTHENTIFICATION GITHUB
# =============================================================================

print_step "2. Vérification de l'authentification GitHub"

# Vérifier l'authentification
if ! gh auth status &> /dev/null; then
    print_warning "Non authentifié sur GitHub"
    print_info "Lancement de l'authentification..."
    
    if ! gh auth login; then
        print_error "Échec de l'authentification GitHub"
        exit 1
    fi
    
    print_success "Authentification GitHub réussie"
else
    print_success "Déjà authentifié sur GitHub"
    gh auth status
fi

# =============================================================================
# 3. UPLOAD DU CODE
# =============================================================================

print_step "3. Upload du code vers GitHub"

# Push du code principal
print_info "Push de la branche main..."
if git push origin main; then
    print_success "Code principal uploadé"
else
    print_error "Échec du push de la branche main"
    exit 1
fi

# Push du tag
print_info "Push du tag v$VERSION..."
if git push origin v$VERSION; then
    print_success "Tag v$VERSION uploadé"
else
    print_warning "Échec du push du tag (peut-être déjà existant)"
fi

# =============================================================================
# 4. CRÉATION DE LA RELEASE
# =============================================================================

print_step "4. Création de la release v$VERSION"

# Vérifier si la release existe déjà
if gh release view v$VERSION &> /dev/null; then
    print_warning "Release v$VERSION existe déjà"
    echo -n "Supprimer et recréer ? (y/N): "
    read recreate_release
    if [ "$recreate_release" = "y" ] || [ "$recreate_release" = "Y" ]; then
        gh release delete v$VERSION --yes
        print_info "Ancienne release supprimée"
    else
        print_info "Conservation de la release existante"
    fi
fi

# Créer la release si elle n'existe pas
if ! gh release view v$VERSION &> /dev/null; then
    print_info "Création de la release v$VERSION..."
    
    # Notes de release
    release_notes="# 🇸🇳 SAMA CONAI v$VERSION - Première Release Stable

## 🎉 Lancement Officiel

Première version stable de **SAMA CONAI**, le système d'accès moderne à l'information pour l'administration publique sénégalaise.

## ✨ Fonctionnalités Principales

### 🎓 Formation Complète
- **8 modules** de formation (27 leçons)
- **Certification par rôle** (Agent Public, Citoyen)
- **Contenu interactif** avec quiz et simulations
- **100% adapté** au contexte sénégalais

### 👥 Interface Multi-Utilisateurs
- **Portail Citoyen** : Soumission et suivi des demandes
- **Dashboard Agent** : Gestion professionnelle des dossiers
- **Interface Superviseur** : Analytics et reporting avancés
- **Application Mobile** : PWA complète

### 📊 Analytics Avancés
- **Tableaux de bord** en temps réel
- **Rapports automatisés** pour la transparence
- **Indicateurs de performance** personnalisables

### 🔒 Sécurité & Conformité
- **OAuth 2.0** et JWT
- **Chiffrement** des données sensibles
- **Audit trail** complet
- **Conformité RGPD**

## 🚀 Installation Rapide

\`\`\`bash
git clone $REPO_URL.git
cd conai
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
\`\`\`

## 📚 Documentation

- [Guide de Démarrage Rapide](QUICKSTART.md)
- [Guide d'Installation](INSTALLATION.md)
- [Guide de Contribution](CONTRIBUTING.md)
- [Politique de Sécurité](SECURITY.md)

## 👨‍💻 Auteurs

- **Mamadou Mbagnick DOGUE** - Architecte Principal & Lead Developer
- **Rassol DOGUE** - Co-Architecte & Innovation Lead

## 🙏 Remerciements

Merci à tous ceux qui ont contribué à faire de SAMA CONAI une réalité pour l'administration publique sénégalaise.

---

**🇸🇳 Fait avec ❤️ au Sénégal pour l'Afrique et le Monde**"

    if echo "$release_notes" | gh release create v$VERSION --title "SAMA CONAI v$VERSION - Complete Release 🎉" --notes-file -; then
        print_success "Release v$VERSION créée"
    else
        print_error "Échec de la création de la release"
    fi
fi

# =============================================================================
# 5. CONFIGURATION DU REPOSITORY
# =============================================================================

print_step "5. Configuration du repository"

# Activer les fonctionnalités
print_info "Activation des fonctionnalités du repository..."

# Issues
if gh repo edit --enable-issues; then
    print_success "Issues activées"
else
    print_warning "Échec activation Issues"
fi

# Wiki
if gh repo edit --enable-wiki; then
    print_success "Wiki activé"
else
    print_warning "Échec activation Wiki"
fi

# Projects
if gh repo edit --enable-projects; then
    print_success "Projects activés"
else
    print_warning "Échec activation Projects"
fi

# Discussions
if gh repo edit --enable-discussions; then
    print_success "Discussions activées"
else
    print_warning "Échec activation Discussions"
fi

# Ajouter les topics
print_info "Ajout des topics..."
topics="senegal,public-administration,information-access,transparency,odoo,python,government,africa,open-source,civic-tech,french,training,certification,pwa,mobile-first"

if gh repo edit --add-topic "$topics"; then
    print_success "Topics ajoutés"
else
    print_warning "Échec ajout des topics"
fi

# =============================================================================
# 6. VÉRIFICATIONS FINALES
# =============================================================================

print_step "6. Vérifications finales"

# Vérifier le repository
print_info "Vérification du repository..."
if gh repo view; then
    print_success "Repository accessible"
else
    print_error "Problème d'accès au repository"
fi

# Vérifier la release
print_info "Vérification de la release..."
if gh release view v$VERSION; then
    print_success "Release v$VERSION confirmée"
else
    print_warning "Problème avec la release"
fi

# Statistiques finales
print_info "Statistiques du repository:"
echo "  - URL: $REPO_URL"
echo "  - Version: v$VERSION"
echo "  - Fichiers uploadés: $(git ls-files | wc -l)"
echo "  - Commits: $(git rev-list --count HEAD)"

# =============================================================================
# 7. SUCCÈS ET PROCHAINES ÉTAPES
# =============================================================================

print_header "🎉 Upload Réussi !"

echo -e "${GREEN}✅ SAMA CONAI a été uploadé avec succès sur GitHub !${NC}\n"

echo -e "${YELLOW}🔗 Liens Importants:${NC}"
echo "  - Repository: $REPO_URL"
echo "  - Release: $REPO_URL/releases/tag/v$VERSION"
echo "  - Issues: $REPO_URL/issues"
echo "  - Wiki: $REPO_URL/wiki"

echo -e "\n${YELLOW}📢 Prochaines Étapes:${NC}"
echo "1. Vérifier l'affichage sur GitHub"
echo "2. Configurer la protection de branche"
echo "3. Ajouter une image de social preview"
echo "4. Créer une issue de bienvenue"
echo "5. Promouvoir sur les réseaux sociaux"

echo -e "\n${YELLOW}🚀 Promotion Suggérée:${NC}"
echo "LinkedIn: Partager l'annonce du lancement"
echo "Twitter: Thread sur les fonctionnalités"
echo "Dev.to: Article technique détaillé"
echo "Reddit: Partage dans r/opensource, r/Python, r/Senegal"

echo -e "\n${CYAN}💡 Commandes Utiles:${NC}"
echo "  - Ouvrir le repository: ${BLUE}gh repo view --web${NC}"
echo "  - Voir les issues: ${BLUE}gh issue list${NC}"
echo "  - Créer une issue: ${BLUE}gh issue create${NC}"
echo "  - Voir les releases: ${BLUE}gh release list${NC}"

print_header "🇸🇳 SAMA CONAI sur GitHub - Mission Accomplie !"

echo -e "${PURPLE}Merci d'avoir utilisé ce script d'upload !${NC}"
echo -e "${PURPLE}SAMA CONAI est maintenant prêt à conquérir la communauté open source ! 🚀${NC}"

exit 0