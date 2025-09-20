#!/bin/bash

# Script de sauvegarde SAMA CONAI v3.1
# Version complète avec application mobile et authentification

echo "🚀 SAUVEGARDE SAMA CONAI v3.1"
echo "============================="

# Variables
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_sama_conai_v3.1_${TIMESTAMP}"
BACKUP_DIR="${BACKUP_NAME}"
ARCHIVE_NAME="${BACKUP_NAME}.tar.gz"

echo "📅 Timestamp: $TIMESTAMP"
echo "📁 Nom de sauvegarde: $BACKUP_NAME"

# Créer le répertoire de sauvegarde
echo "📂 Création du répertoire de sauvegarde..."
mkdir -p "$BACKUP_DIR"

# Fonction pour copier avec exclusions
copy_with_exclusions() {
    local source="$1"
    local dest="$2"
    local name="$3"
    
    echo "📋 Copie de $name..."
    
    if [ -d "$source" ]; then
        cp -r "$source" "$dest/" 2>/dev/null || echo "⚠️ Erreur copie $name"
    elif [ -f "$source" ]; then
        cp "$source" "$dest/" 2>/dev/null || echo "⚠️ Erreur copie $name"
    else
        echo "⚠️ $source n'existe pas"
    fi
}

# 1. MODULE ODOO PRINCIPAL
echo ""
echo "🔧 SAUVEGARDE MODULE ODOO PRINCIPAL"
echo "==================================="

# Fichiers principaux du module
copy_with_exclusions "__init__.py" "$BACKUP_DIR" "Init principal"
copy_with_exclusions "__manifest__.py" "$BACKUP_DIR" "Manifeste principal"

# Dossiers principaux du module
copy_with_exclusions "models" "$BACKUP_DIR" "Modèles Odoo"
copy_with_exclusions "views" "$BACKUP_DIR" "Vues Odoo"
copy_with_exclusions "controllers" "$BACKUP_DIR" "Contrôleurs Odoo"
copy_with_exclusions "security" "$BACKUP_DIR" "Sécurité Odoo"
copy_with_exclusions "data" "$BACKUP_DIR" "Données Odoo"
copy_with_exclusions "static" "$BACKUP_DIR" "Ressources statiques"
copy_with_exclusions "templates" "$BACKUP_DIR" "Templates Odoo"

# 2. APPLICATION MOBILE WEB
echo ""
echo "📱 SAUVEGARDE APPLICATION MOBILE WEB"
echo "===================================="

# Créer le dossier mobile_app_web dans la sauvegarde
mkdir -p "$BACKUP_DIR/mobile_app_web"

# Copier les fichiers essentiels de l'app mobile web (sans node_modules)
if [ -d "mobile_app_web" ]; then
    echo "📋 Copie des fichiers de l'application mobile web..."
    
    # Fichiers principaux
    [ -f "mobile_app_web/package.json" ] && cp "mobile_app_web/package.json" "$BACKUP_DIR/mobile_app_web/"
    [ -f "mobile_app_web/server.js" ] && cp "mobile_app_web/server.js" "$BACKUP_DIR/mobile_app_web/"
    [ -f "mobile_app_web/odoo-api.js" ] && cp "mobile_app_web/odoo-api.js" "$BACKUP_DIR/mobile_app_web/"
    
    # Dossier public
    [ -d "mobile_app_web/public" ] && cp -r "mobile_app_web/public" "$BACKUP_DIR/mobile_app_web/"
    
    # Logs s'ils existent
    [ -f "mobile_app_web/mobile_app.log" ] && cp "mobile_app_web/mobile_app.log" "$BACKUP_DIR/mobile_app_web/"
    
    echo "✅ Application mobile web sauvegardée (sans node_modules)"
else
    echo "⚠️ Dossier mobile_app_web non trouvé"
fi

# 3. APPLICATION MOBILE REACT NATIVE
echo ""
echo "📱 SAUVEGARDE APPLICATION MOBILE REACT NATIVE"
echo "============================================="

copy_with_exclusions "mobile_app" "$BACKUP_DIR" "Application mobile React Native"

# 4. SCRIPTS ET UTILITAIRES
echo ""
echo "🔧 SAUVEGARDE SCRIPTS ET UTILITAIRES"
echo "===================================="

# Scripts de lancement
echo "📋 Scripts de lancement..."
copy_with_exclusions "launch_mobile_app.sh" "$BACKUP_DIR" "Script lancement mobile"
copy_with_exclusions "launch_sama_conai.sh" "$BACKUP_DIR" "Script lancement SAMA CONAI"
copy_with_exclusions "start_sama_conai.sh" "$BACKUP_DIR" "Script démarrage"
copy_with_exclusions "restart_sama_conai.sh" "$BACKUP_DIR" "Script redémarrage"
copy_with_exclusions "stop_sama_conai.sh" "$BACKUP_DIR" "Script arrêt"

# Scripts de test
echo "📋 Scripts de test..."
copy_with_exclusions "test_admin_data.sh" "$BACKUP_DIR" "Test données admin"
copy_with_exclusions "test_mobile_app.sh" "$BACKUP_DIR" "Test app mobile"
copy_with_exclusions "test_mobile_login.sh" "$BACKUP_DIR" "Test login mobile"
copy_with_exclusions "test_final.sh" "$BACKUP_DIR" "Test final"
copy_with_exclusions "TEST_FINAL_DEMO.sh" "$BACKUP_DIR" "Test démo final"

# Scripts d'installation
echo "📋 Scripts d'installation..."
copy_with_exclusions "install_demo_data.sh" "$BACKUP_DIR" "Installation données démo"
copy_with_exclusions "quick_start.sh" "$BACKUP_DIR" "Démarrage rapide"
copy_with_exclusions "install_simple_final.sh" "$BACKUP_DIR" "Installation simple"

# Scripts de données
echo "📋 Scripts de données..."
copy_with_exclusions "create_admin_data.js" "$BACKUP_DIR" "Création données admin"

# Fichiers de configuration
echo "📋 Fichiers de configuration..."
copy_with_exclusions "docker-compose.yml" "$BACKUP_DIR" "Configuration Docker"
copy_with_exclusions "odoo_sama_conai.conf" "$BACKUP_DIR" "Configuration Odoo"

# Dossier scripts
copy_with_exclusions "scripts" "$BACKUP_DIR" "Dossier scripts"

# 5. DOCUMENTATION ET GUIDES
echo ""
echo "📚 SAUVEGARDE DOCUMENTATION"
echo "==========================="

# Guides principaux
echo "📋 Guides principaux..."
copy_with_exclusions "README_FINAL.md" "$BACKUP_DIR" "README final"
copy_with_exclusions "INSTALLATION_GUIDE.md" "$BACKUP_DIR" "Guide installation"
copy_with_exclusions "GUIDE_INSTALLATION_FINALE.md" "$BACKUP_DIR" "Guide installation finale"
copy_with_exclusions "GUIDE_ACCES_FINAL.md" "$BACKUP_DIR" "Guide accès final"

# Guides application mobile
echo "📋 Guides application mobile..."
copy_with_exclusions "MOBILE_APP_GUIDE.md" "$BACKUP_DIR" "Guide app mobile"
copy_with_exclusions "MOBILE_APP_LOGIN_GUIDE.md" "$BACKUP_DIR" "Guide login mobile"
copy_with_exclusions "MOBILE_APP_REAL_DATA_GUIDE.md" "$BACKUP_DIR" "Guide données réelles mobile"
copy_with_exclusions "ADMIN_DATA_GUIDE.md" "$BACKUP_DIR" "Guide données admin"

# Guides techniques
echo "📋 Guides techniques..."
copy_with_exclusions "BACKUP_v3.0_README.md" "$BACKUP_DIR" "README backup v3.0"
copy_with_exclusions "AMELIORATIONS_IMPLEMENTEES_v2.5.md" "$BACKUP_DIR" "Améliorations v2.5"
copy_with_exclusions "INTEGRATION_NOUVELLES_FONCTIONNALITES_REPORT.md" "$BACKUP_DIR" "Rapport nouvelles fonctionnalités"

# Guides de menu et navigation
echo "📋 Guides de menu..."
copy_with_exclusions "FINAL_MENU_CLEANUP_REPORT.md" "$BACKUP_DIR" "Rapport nettoyage menu final"
copy_with_exclusions "MENU_REORGANIZATION_SUMMARY.md" "$BACKUP_DIR" "Résumé réorganisation menu"

# Guides de données
echo "📋 Guides de données..."
copy_with_exclusions "DEMO_DATA_SUMMARY.md" "$BACKUP_DIR" "Résumé données démo"
copy_with_exclusions "README_DONNEES_DEMO_FINAL.md" "$BACKUP_DIR" "README données démo final"

# 6. FICHIERS DE VALIDATION ET TESTS
echo ""
echo "🧪 SAUVEGARDE FICHIERS DE VALIDATION"
echo "===================================="

# Scripts Python de validation
echo "📋 Scripts de validation..."
copy_with_exclusions "validate_backup_v3.0.py" "$BACKUP_DIR" "Validation backup v3.0"
copy_with_exclusions "validate_final_menu_structure.py" "$BACKUP_DIR" "Validation structure menu"
copy_with_exclusions "validate_new_features.py" "$BACKUP_DIR" "Validation nouvelles fonctionnalités"

# Scripts d'analyse
copy_with_exclusions "analyze_menu_duplicates.py" "$BACKUP_DIR" "Analyse doublons menu"
copy_with_exclusions "final_summary.py" "$BACKUP_DIR" "Résumé final"

# 7. CRÉATION DE L'ARCHIVE
echo ""
echo "📦 CRÉATION DE L'ARCHIVE"
echo "========================"

echo "📋 Compression en cours..."
tar -czf "$ARCHIVE_NAME" "$BACKUP_DIR" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Archive créée: $ARCHIVE_NAME"
    
    # Taille de l'archive
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)
    echo "📊 Taille de l'archive: $ARCHIVE_SIZE"
    
    # Supprimer le dossier temporaire
    rm -rf "$BACKUP_DIR"
    echo "🧹 Dossier temporaire supprimé"
    
else
    echo "❌ Erreur lors de la création de l'archive"
    exit 1
fi

# 8. CRÉATION DU FICHIER DE MÉTADONNÉES
echo ""
echo "📋 CRÉATION DES MÉTADONNÉES"
echo "==========================="

METADATA_FILE="${BACKUP_NAME}_metadata.txt"

cat > "$METADATA_FILE" << EOF
SAUVEGARDE SAMA CONAI v3.1
==========================

📅 Date de création: $(date)
📦 Nom de l'archive: $ARCHIVE_NAME
📊 Taille: $ARCHIVE_SIZE
🏷️ Version: 3.1
🔧 Type: Sauvegarde complète

📋 CONTENU DE LA SAUVEGARDE:
============================

🔧 MODULE ODOO PRINCIPAL:
- Modèles, vues, contrôleurs
- Sécurité et données
- Templates et ressources statiques

📱 APPLICATION MOBILE WEB:
- Serveur Node.js avec authentification
- Interface moderne avec Material Design
- API Odoo intégrée
- Données de démonstration enrichies

📱 APPLICATION MOBILE REACT NATIVE:
- Structure complète React Native
- Écrans et services
- Thème et navigation

🔧 SCRIPTS ET UTILITAIRES:
- Scripts de lancement et test
- Scripts d'installation
- Utilitaires de validation

📚 DOCUMENTATION COMPLÈTE:
- Guides d'installation et utilisation
- Documentation technique
- Guides de l'application mobile

🧪 FICHIERS DE VALIDATION:
- Scripts de test et validation
- Outils d'analyse

✨ FONCTIONNALITÉS v3.1:
========================

🔐 AUTHENTIFICATION MOBILE:
- Système de login sécurisé
- Sessions JWT
- Protection des routes

📊 DONNÉES ENRICHIES:
- 8 demandes d'information assignées à l'admin
- 5 alertes de signalement
- Statistiques vivantes

🎨 INTERFACE MODERNE:
- Design Material Design
- Animations fluides
- Navigation 3 niveaux

📱 APPLICATION COMPLÈTE:
- Dashboard personnalisé
- Listes détaillées
- Chronologies complètes

🔧 INTÉGRATION ODOO:
- API REST complète
- Filtrage par utilisateur
- Données temps réel

📈 ANALYTICS AVANCÉS:
- Tableaux de bord interactifs
- Métriques de performance
- Rapports détaillés

🛡️ SÉCURITÉ RENFORCÉE:
- Contrôle d'accès granulaire
- Protection des données
- Audit des actions

🌐 PORTAIL PUBLIC:
- Interface citoyens
- Transparence gouvernementale
- Accès facilité

📋 INSTRUCTIONS DE RESTAURATION:
================================

1. Extraire l'archive:
   tar -xzf $ARCHIVE_NAME

2. Copier dans le répertoire Odoo addons:
   cp -r $BACKUP_DIR/* /path/to/odoo/addons/sama_conai/

3. Installer les dépendances mobile:
   cd mobile_app_web && npm install

4. Lancer l'application:
   ./launch_sama_conai.sh
   ./launch_mobile_app.sh

5. Accéder aux interfaces:
   - Odoo: http://localhost:8069
   - Mobile: http://localhost:3001

📞 SUPPORT:
===========
- Version: SAMA CONAI v3.1
- Date: $(date)
- Statut: Production Ready
EOF

echo "✅ Métadonnées créées: $METADATA_FILE"

# 9. RÉSUMÉ FINAL
echo ""
echo "🎉 SAUVEGARDE TERMINÉE"
echo "======================"

echo "✅ Sauvegarde SAMA CONAI v3.1 créée avec succès !"
echo ""
echo "📦 FICHIERS CRÉÉS:"
echo "   📁 Archive: $ARCHIVE_NAME ($ARCHIVE_SIZE)"
echo "   📋 Métadonnées: $METADATA_FILE"
echo ""
echo "📋 CONTENU SAUVEGARDÉ:"
echo "   🔧 Module Odoo complet"
echo "   📱 Application mobile web avec authentification"
echo "   📱 Application mobile React Native"
echo "   🔧 Scripts et utilitaires"
echo "   📚 Documentation complète"
echo "   🧪 Fichiers de validation"
echo ""
echo "✨ FONCTIONNALITÉS v3.1 INCLUSES:"
echo "   🔐 Authentification sécurisée"
echo "   📊 Données enrichies (8 demandes + 5 alertes)"
echo "   🎨 Interface moderne Material Design"
echo "   📱 Navigation 3 niveaux complète"
echo "   📈 Analytics et métriques"
echo ""
echo "🚀 PRÊT POUR DÉPLOIEMENT !"
echo ""
echo "💡 Pour restaurer:"
echo "   tar -xzf $ARCHIVE_NAME"
echo "   Suivre les instructions dans $METADATA_FILE"

# Afficher la liste des fichiers dans l'archive
echo ""
echo "📋 CONTENU DE L'ARCHIVE:"
echo "========================"
tar -tzf "$ARCHIVE_NAME" | head -20
echo "   ... (et plus)"

echo ""
echo "🎯 SAUVEGARDE v3.1 TERMINÉE AVEC SUCCÈS !"