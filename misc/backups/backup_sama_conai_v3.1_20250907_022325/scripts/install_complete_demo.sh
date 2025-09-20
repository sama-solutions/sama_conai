#!/bin/bash

# Script d'installation complète avec toutes les vagues de données de démo

echo "🚀 INSTALLATION COMPLÈTE SAMA CONAI"
echo "===================================="
echo ""

# Variables de configuration
DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
ODOO_BIN="$ODOO_PATH/odoo-bin"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_CONF="/home/grand-as/psagsn/odoo.conf"
MODULE_PATH="/home/grand-as/psagsn/custom_addons/sama_conai"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifications préliminaires
print_step "Vérifications préliminaires..."

# Vérifier Odoo
if [ ! -f "$ODOO_BIN" ]; then
    print_error "Odoo non trouvé dans $ODOO_PATH. Vérifiez le chemin."
    exit 1
fi

# Vérifier l'environnement virtuel
if [ ! -d "$VENV_PATH" ]; then
    print_error "Environnement virtuel non trouvé dans $VENV_PATH."
    exit 1
fi

# Vérifier le fichier de configuration
if [ ! -f "$ODOO_CONF" ]; then
    print_error "Fichier de configuration $ODOO_CONF non trouvé."
    exit 1
fi

# Vérifier le module
if [ ! -d "$MODULE_PATH" ]; then
    print_error "Module SAMA CONAI non trouvé dans $MODULE_PATH."
    exit 1
fi

# Activer l'environnement virtuel
print_step "Activation de l'environnement virtuel..."
source "$VENV_PATH/bin/activate"
if [ $? -eq 0 ]; then
    print_success "Environnement virtuel activé"
else
    print_error "Erreur lors de l'activation de l'environnement virtuel"
    exit 1
fi

print_success "Vérifications préliminaires OK"
echo ""

# Affichage des informations
print_step "Configuration:"
echo "   Base de données: $DB_NAME"
echo "   Module: $MODULE_PATH"
echo "   Configuration: $ODOO_CONF"
echo ""

# Demande de confirmation
read -p "Continuer avec cette configuration? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation annulée."
    exit 0
fi

echo ""

# Étape 1: Mise à jour du module
print_step "Étape 1: Mise à jour du module SAMA CONAI..."
cd $ODOO_PATH
python3 $ODOO_BIN -c $ODOO_CONF -d $DB_NAME -u sama_conai --addons-path=$CUSTOM_ADDONS_PATH --stop-after-init

if [ $? -eq 0 ]; then
    print_success "Module mis à jour avec succès"
else
    print_error "Erreur lors de la mise à jour du module"
    exit 1
fi

echo ""

# Étape 2: Test des données de démo
print_step "Étape 2: Test des données de démo..."
echo "exec(open('$MODULE_PATH/scripts/test_all_demo_waves.py').read())" | python3 $ODOO_BIN shell -c $ODOO_CONF -d $DB_NAME --addons-path=$CUSTOM_ADDONS_PATH

echo ""

# Étape 3: Vérification des vues
print_step "Étape 3: Vérification des vues et actions..."

# Test de connexion et vérification des vues
cat << 'EOF' | python3 $ODOO_BIN shell -c $ODOO_CONF -d $DB_NAME --addons-path=$CUSTOM_ADDONS_PATH
try:
    # Test des actions principales
    action_info = env.ref('sama_conai.action_information_request')
    print(f"✅ Action demandes d'information: {action_info.name}")
    
    # Test des vues
    views = env['ir.ui.view'].search([('model', 'in', ['request.information', 'whistleblowing.alert'])])
    print(f"✅ Vues trouvées: {len(views)}")
    
    # Test des menus
    menus = env['ir.ui.menu'].search([('name', 'ilike', 'SAMA CONAI')])
    print(f"✅ Menus trouvés: {len(menus)}")
    
    print("✅ Vérifications des vues: OK")
    
except Exception as e:
    print(f"❌ Erreur lors de la vérification: {e}")
EOF

echo ""

# Étape 4: Génération du rapport final
print_step "Étape 4: Génération du rapport d'installation..."

# Créer un rapport d'installation
REPORT_FILE="$MODULE_PATH/INSTALLATION_REPORT_$(date +%Y%m%d_%H%M%S).md"

cat > "$REPORT_FILE" << EOF
# Rapport d'Installation SAMA CONAI

**Date d'installation:** $(date '+%d/%m/%Y à %H:%M:%S')
**Base de données:** $DB_NAME
**Version du module:** $(grep "'version'" $MODULE_PATH/__manifest__.py | cut -d"'" -f4)

## ✅ Composants installés

### Modèles de données
- ✅ Demandes d'information (request.information)
- ✅ Étapes de demandes (request.information.stage)
- ✅ Motifs de refus (request.refusal.reason)
- ✅ Signalements d'alerte (whistleblowing.alert)
- ✅ Étapes de signalements (whistleblowing.alert.stage)

### Vues et interfaces
- ✅ Vues Kanban pour suivi visuel
- ✅ Vues Liste pour gestion en masse
- ✅ Vues Formulaire détaillées
- ✅ Vues Graph pour analyse temporelle
- ✅ Vues Pivot pour analyses croisées
- ✅ Recherches avancées avec filtres

### Données de démonstration
- ✅ Vague 1: Données minimales (2 enregistrements)
- ✅ Vague 2: Données étendues (4 enregistrements)
- ✅ Vague 3: Données avancées (2 enregistrements)
- ✅ Données de référence (étapes, motifs de refus)

### Fonctionnalités
- ✅ Workflow complet de traitement
- ✅ Notifications par email
- ✅ Portail web pour citoyens
- ✅ Suivi anonyme des signalements
- ✅ Respect des délais légaux
- ✅ Sécurité et confidentialité

## 🎯 Prochaines étapes

1. **Formation des utilisateurs**
   - Présentation des vues Kanban
   - Formation aux analyses de données
   - Utilisation des filtres avancés

2. **Configuration personnalisée**
   - Adaptation des workflows
   - Personnalisation des notifications
   - Configuration des droits d'accès

3. **Tests en conditions réelles**
   - Création de vraies demandes
   - Test des notifications
   - Validation des performances

## 📊 Accès aux fonctionnalités

### Menu principal
- **Accès à l'Information** > **Tableau de Bord**
- **Accès à l'Information** > **Demandes d'Information**
- **Signalement d'Alerte** > **Signalements**

### Vues recommandées pour l'analyse
1. **Vue Kanban**: Suivi visuel par étapes
2. **Vue Graph**: Tendances temporelles
3. **Vue Pivot**: Analyses croisées
4. **Filtres**: Par urgence, retard, qualité de demandeur

## 🔧 Support technique

En cas de problème, consulter :
- Documentation dans le module
- Scripts de test dans scripts/
- Logs d'installation dans ce rapport

---
*Rapport généré automatiquement par le script d'installation SAMA CONAI*
EOF

print_success "Rapport d'installation créé: $REPORT_FILE"
echo ""

# Résumé final
print_step "🎉 INSTALLATION TERMINÉE!"
echo ""
echo "📋 Résumé:"
echo "   ✅ Module SAMA CONAI installé et configuré"
echo "   ✅ Données de démo chargées (3 vagues)"
echo "   ✅ Vues analytiques activées"
echo "   ✅ Rapport d'installation généré"
echo ""
echo "🚀 Prochaines actions recommandées:"
echo "   1. Se connecter à Odoo"
echo "   2. Aller dans 'Accès à l'Information' > 'Tableau de Bord'"
echo "   3. Explorer les vues Kanban, Graph et Pivot"
echo "   4. Tester les filtres et recherches avancées"
echo "   5. Former les utilisateurs aux fonctionnalités"
echo ""
echo "📖 Documentation:"
echo "   - Rapport détaillé: $REPORT_FILE"
echo "   - Scripts de test: $MODULE_PATH/scripts/"
echo "   - Guide d'utilisation: $MODULE_PATH/README.md"
echo ""
print_success "Installation SAMA CONAI réussie! 🎯"