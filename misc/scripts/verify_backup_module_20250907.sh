#!/bin/bash

# Script de vérification du backup module Odoo SAMA CONAI
# Date: 07/09/2025

echo "🔍 Vérification du Backup Module Odoo SAMA CONAI - 07/09/2025"
echo "================================================================"

# Couleurs pour l'affichage
GREEN='\\033[0;32m'
RED='\\033[0;31m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

# Fonction pour afficher les messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️]${NC} $1"
}

# Variables
MODULE_BACKUP="sama_conai_module_backup_20250907.tar.gz"
SCRIPTS_BACKUP="sama_conai_scripts_backup_20250907.tar.gz"
BACKUP_INFO="BACKUP_MODULE_ODOO_INFO.md"

print_status "Vérification des fichiers de backup..."

# 1. Vérifier l'existence des fichiers de backup
if [ -f "$MODULE_BACKUP" ]; then
    MODULE_SIZE=$(ls -lh "$MODULE_BACKUP" | awk '{print $5}')
    print_success "Backup module trouvé: $MODULE_BACKUP ($MODULE_SIZE)"
else
    print_error "Backup module manquant: $MODULE_BACKUP"
    exit 1
fi

if [ -f "$SCRIPTS_BACKUP" ]; then
    SCRIPTS_SIZE=$(ls -lh "$SCRIPTS_BACKUP" | awk '{print $5}')
    print_success "Backup scripts trouvé: $SCRIPTS_BACKUP ($SCRIPTS_SIZE)"
else
    print_error "Backup scripts manquant: $SCRIPTS_BACKUP"
    exit 1
fi

if [ -f "$BACKUP_INFO" ]; then
    print_success "Documentation backup trouvée: $BACKUP_INFO"
else
    print_warning "Documentation backup manquante: $BACKUP_INFO"
fi

# 2. Vérifier l'intégrité des archives
print_status "Vérification de l'intégrité des archives..."

if tar -tzf "$MODULE_BACKUP" > /dev/null 2>&1; then
    print_success "Archive module valide"
else
    print_error "Archive module corrompue"
    exit 1
fi

if tar -tzf "$SCRIPTS_BACKUP" > /dev/null 2>&1; then
    print_success "Archive scripts valide"
else
    print_error "Archive scripts corrompue"
    exit 1
fi

# 3. Compter les fichiers dans les backups
print_status "Statistiques des backups..."

MODULE_FILES=$(tar -tzf "$MODULE_BACKUP" | wc -l)
SCRIPTS_FILES=$(tar -tzf "$SCRIPTS_BACKUP" | wc -l)

print_success "Backup module: $MODULE_FILES fichiers/dossiers"
print_success "Backup scripts: $SCRIPTS_FILES fichiers"

# 4. Afficher les informations de backup
echo ""
echo "📊 RÉSUMÉ DU BACKUP"
echo "=================="
echo "📅 Date de création: $(date +'%d/%m/%Y %H:%M:%S')"
echo "📦 Backup module: $MODULE_BACKUP ($MODULE_SIZE)"
echo "🔧 Backup scripts: $SCRIPTS_BACKUP ($SCRIPTS_SIZE)"
echo "📄 Documentation: $BACKUP_INFO"
echo "📁 Total fichiers module: $MODULE_FILES"
echo "🔧 Total fichiers scripts: $SCRIPTS_FILES"

# 5. Instructions de restauration
echo ""
echo "🔄 INSTRUCTIONS DE RESTAURATION"
echo "==============================="
echo ""
echo "Pour restaurer le module complet:"
echo "  1. Sauvegarder l'existant:"
echo "     mv sama_conai sama_conai_old_\$(date +%Y%m%d)"
echo ""
echo "  2. Créer le dossier de destination:"
echo "     mkdir sama_conai"
echo ""
echo "  3. Extraire le backup module:"
echo "     tar -xzf $MODULE_BACKUP -C sama_conai/"
echo ""
echo "  4. Extraire les scripts:"
echo "     tar -xzf $SCRIPTS_BACKUP -C sama_conai/"
echo ""
echo "  5. Rendre les scripts exécutables:"
echo "     chmod +x sama_conai/*.sh"
echo ""
echo "  6. Redémarrer les services:"
echo "     cd sama_conai && ./startup_sama_conai.sh restart"

echo ""
print_success "✅ Vérification du backup terminée avec succès !"
print_status "Le backup du module Odoo SAMA CONAI est prêt pour la restauration."

echo ""
echo "🎯 PROCHAINES ÉTAPES"
echo "=================="
echo "• Le backup est maintenant sécurisé"
echo "• Vous pouvez continuer à travailler sur les petits soucis"
echo "• En cas de problème, utilisez ce backup pour restaurer"
echo "• Gardez ce backup en lieu sûr"

exit 0