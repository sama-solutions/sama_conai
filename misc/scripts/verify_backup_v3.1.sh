#!/bin/bash

# Script de vérification de la sauvegarde SAMA CONAI v3.1

echo "🔍 VÉRIFICATION SAUVEGARDE SAMA CONAI v3.1"
echo "=========================================="

# Rechercher le fichier de sauvegarde v3.1
BACKUP_FILE=$(ls backup_sama_conai_v3.1_*.tar.gz 2>/dev/null | head -1)
METADATA_FILE=$(ls backup_sama_conai_v3.1_*_metadata.txt 2>/dev/null | head -1)

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Aucun fichier de sauvegarde v3.1 trouvé"
    echo "   Recherche de: backup_sama_conai_v3.1_*.tar.gz"
    exit 1
fi

echo "✅ Fichier de sauvegarde trouvé: $BACKUP_FILE"

# Vérifier la taille du fichier
if [ -f "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "📊 Taille de l'archive: $BACKUP_SIZE"
else
    echo "❌ Fichier de sauvegarde non accessible"
    exit 1
fi

# Vérifier le fichier de métadonnées
if [ -f "$METADATA_FILE" ]; then
    echo "✅ Fichier de métadonnées trouvé: $METADATA_FILE"
else
    echo "⚠️ Fichier de métadonnées non trouvé"
fi

echo ""
echo "📋 VÉRIFICATION DU CONTENU DE L'ARCHIVE"
echo "======================================="

# Vérifier que l'archive peut être lue
if tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
    echo "✅ Archive lisible et valide"
else
    echo "❌ Archive corrompue ou illisible"
    exit 1
fi

# Compter les fichiers dans l'archive
FILE_COUNT=$(tar -tzf "$BACKUP_FILE" | wc -l)
echo "📁 Nombre de fichiers dans l'archive: $FILE_COUNT"

echo ""
echo "🔧 VÉRIFICATION DES COMPOSANTS PRINCIPAUX"
echo "========================================="

# Fonction pour vérifier la présence d'un fichier/dossier
check_component() {
    local component="$1"
    local description="$2"
    
    if tar -tzf "$BACKUP_FILE" | grep -q "$component"; then
        echo "✅ $description"
        return 0
    else
        echo "❌ $description - MANQUANT"
        return 1
    fi
}

# Vérifier les composants principaux
MISSING_COUNT=0

# Module Odoo principal
check_component "__init__.py" "Module Odoo - Init principal" || ((MISSING_COUNT++))
check_component "__manifest__.py" "Module Odoo - Manifeste" || ((MISSING_COUNT++))
check_component "models/" "Module Odoo - Modèles" || ((MISSING_COUNT++))
check_component "views/" "Module Odoo - Vues" || ((MISSING_COUNT++))
check_component "controllers/" "Module Odoo - Contrôleurs" || ((MISSING_COUNT++))
check_component "security/" "Module Odoo - Sécurité" || ((MISSING_COUNT++))

# Application mobile web
check_component "mobile_app_web/" "Application mobile web" || ((MISSING_COUNT++))
check_component "mobile_app_web/server.js" "Serveur Node.js" || ((MISSING_COUNT++))
check_component "mobile_app_web/odoo-api.js" "API Odoo" || ((MISSING_COUNT++))
check_component "mobile_app_web/public/" "Interface web" || ((MISSING_COUNT++))

# Application mobile React Native
check_component "mobile_app/" "Application mobile React Native" || ((MISSING_COUNT++))

# Scripts principaux
check_component "launch_mobile_app.sh" "Script lancement mobile" || ((MISSING_COUNT++))
check_component "launch_sama_conai.sh" "Script lancement SAMA CONAI" || ((MISSING_COUNT++))
check_component "test_admin_data.sh" "Script test données admin" || ((MISSING_COUNT++))
check_component "create_admin_data.js" "Script création données" || ((MISSING_COUNT++))

# Documentation
check_component "README_FINAL.md" "README principal" || ((MISSING_COUNT++))
check_component "MOBILE_APP_LOGIN_GUIDE.md" "Guide login mobile" || ((MISSING_COUNT++))
check_component "ADMIN_DATA_GUIDE.md" "Guide données admin" || ((MISSING_COUNT++))

echo ""
echo "📊 ANALYSE DÉTAILLÉE DU CONTENU"
echo "==============================="

# Analyser le contenu par catégorie
echo "📋 Fichiers Python (.py):"
PYTHON_COUNT=$(tar -tzf "$BACKUP_FILE" | grep "\.py$" | wc -l)
echo "   Nombre: $PYTHON_COUNT fichiers"

echo "📋 Fichiers JavaScript (.js):"
JS_COUNT=$(tar -tzf "$BACKUP_FILE" | grep "\.js$" | wc -l)
echo "   Nombre: $JS_COUNT fichiers"

echo "📋 Fichiers Markdown (.md):"
MD_COUNT=$(tar -tzf "$BACKUP_FILE" | grep "\.md$" | wc -l)
echo "   Nombre: $MD_COUNT fichiers"

echo "📋 Scripts shell (.sh):"
SH_COUNT=$(tar -tzf "$BACKUP_FILE" | grep "\.sh$" | wc -l)
echo "   Nombre: $SH_COUNT fichiers"

echo "📋 Fichiers XML (.xml):"
XML_COUNT=$(tar -tzf "$BACKUP_FILE" | grep "\.xml$" | wc -l)
echo "   Nombre: $XML_COUNT fichiers"

echo ""
echo "🔍 VÉRIFICATION DES FONCTIONNALITÉS v3.1"
echo "========================================"

# Vérifier les fonctionnalités spécifiques v3.1
echo "🔐 Authentification mobile:"
if tar -tzf "$BACKUP_FILE" | grep -q "mobile_app_web/server.js"; then
    echo "   ✅ Serveur avec authentification inclus"
else
    echo "   ❌ Serveur d'authentification manquant"
    ((MISSING_COUNT++))
fi

echo "📊 Données enrichies:"
if tar -tzf "$BACKUP_FILE" | grep -q "create_admin_data.js"; then
    echo "   ✅ Script de création de données inclus"
else
    echo "   ❌ Script de données manquant"
    ((MISSING_COUNT++))
fi

echo "🎨 Interface moderne:"
if tar -tzf "$BACKUP_FILE" | grep -q "mobile_app_web/public/"; then
    echo "   ✅ Interface web moderne incluse"
else
    echo "   ❌ Interface web manquante"
    ((MISSING_COUNT++))
fi

echo "📱 Navigation 3 niveaux:"
if tar -tzf "$BACKUP_FILE" | grep -q "mobile_app/src/screens/"; then
    echo "   ✅ Écrans de navigation inclus"
else
    echo "   ❌ Écrans de navigation manquants"
    ((MISSING_COUNT++))
fi

echo ""
echo "🧪 TEST D'EXTRACTION"
echo "==================="

# Créer un dossier de test temporaire
TEST_DIR="test_extraction_$$"
mkdir -p "$TEST_DIR"

echo "📂 Extraction de test dans: $TEST_DIR"

# Tester l'extraction
if tar -xzf "$BACKUP_FILE" -C "$TEST_DIR" > /dev/null 2>&1; then
    echo "✅ Extraction réussie"
    
    # Vérifier quelques fichiers clés
    EXTRACTED_DIR=$(ls "$TEST_DIR" | head -1)
    
    if [ -f "$TEST_DIR/$EXTRACTED_DIR/__manifest__.py" ]; then
        echo "✅ Manifeste Odoo extrait correctement"
    else
        echo "❌ Problème avec l'extraction du manifeste"
        ((MISSING_COUNT++))
    fi
    
    if [ -f "$TEST_DIR/$EXTRACTED_DIR/mobile_app_web/server.js" ]; then
        echo "✅ Serveur mobile extrait correctement"
    else
        echo "❌ Problème avec l'extraction du serveur mobile"
        ((MISSING_COUNT++))
    fi
    
else
    echo "❌ Échec de l'extraction"
    ((MISSING_COUNT++))
fi

# Nettoyer le dossier de test
rm -rf "$TEST_DIR"
echo "🧹 Dossier de test nettoyé"

echo ""
echo "📋 RÉSUMÉ DE LA VÉRIFICATION"
echo "============================"

if [ $MISSING_COUNT -eq 0 ]; then
    echo "🎉 SAUVEGARDE v3.1 VALIDÉE AVEC SUCCÈS !"
    echo ""
    echo "✅ Tous les composants sont présents"
    echo "✅ Archive valide et extractible"
    echo "✅ Fonctionnalités v3.1 incluses"
    echo ""
    echo "📦 DÉTAILS DE LA SAUVEGARDE:"
    echo "   📁 Fichier: $BACKUP_FILE"
    echo "   📊 Taille: $BACKUP_SIZE"
    echo "   📋 Fichiers: $FILE_COUNT"
    echo "   🐍 Python: $PYTHON_COUNT fichiers"
    echo "   📱 JavaScript: $JS_COUNT fichiers"
    echo "   📚 Documentation: $MD_COUNT fichiers"
    echo "   🔧 Scripts: $SH_COUNT fichiers"
    echo ""
    echo "🚀 PRÊTE POUR DÉPLOIEMENT !"
    
else
    echo "⚠️ PROBLÈMES DÉTECTÉS DANS LA SAUVEGARDE"
    echo ""
    echo "❌ Composants manquants: $MISSING_COUNT"
    echo ""
    echo "🔧 ACTIONS RECOMMANDÉES:"
    echo "   1. Vérifier l'intégrité du fichier source"
    echo "   2. Recréer la sauvegarde si nécessaire"
    echo "   3. Vérifier les permissions de fichiers"
    echo ""
    echo "💡 Pour recréer la sauvegarde:"
    echo "   ./backup_sama_conai_v3.1.sh"
fi

echo ""
echo "📞 INFORMATIONS SUPPLÉMENTAIRES"
echo "==============================="

if [ -f "$METADATA_FILE" ]; then
    echo "📋 Métadonnées disponibles dans: $METADATA_FILE"
    echo "📖 Instructions de restauration incluses"
else
    echo "⚠️ Métadonnées manquantes - créer manuellement si nécessaire"
fi

echo ""
echo "🔍 VÉRIFICATION TERMINÉE"
echo "========================"

if [ $MISSING_COUNT -eq 0 ]; then
    echo "✅ Statut: SUCCÈS - Sauvegarde v3.1 complète et valide"
    exit 0
else
    echo "❌ Statut: ÉCHEC - $MISSING_COUNT problème(s) détecté(s)"
    exit 1
fi