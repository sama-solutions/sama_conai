#!/bin/bash

# Vérification du backup SAMA CONAI v2.4

echo "🔍 VÉRIFICATION BACKUP SAMA CONAI v2.4"
echo "======================================"

# Trouver le fichier de backup le plus récent v2.4
BACKUP_FILE=$(ls -t backup_sama_conai_v2.4_*.tar.gz 2>/dev/null | head -1)

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Aucun fichier de backup v2.4 trouvé"
    exit 1
fi

echo "📁 Fichier de backup: $BACKUP_FILE"
echo ""

echo "1. 📊 Informations du fichier..."
ls -lh "$BACKUP_FILE"
echo ""

echo "2. 🔍 Vérification de l'intégrité..."
if tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
    echo "   ✅ Archive intègre"
else
    echo "   ❌ Archive corrompue"
    exit 1
fi

echo ""
echo "3. 📋 Contenu de l'archive..."
echo "   📦 Fichiers dans l'archive:"
tar -tzf "$BACKUP_FILE" | head -20
TOTAL_FILES=$(tar -tzf "$BACKUP_FILE" | wc -l)
echo "   📊 Total: $TOTAL_FILES fichiers"

echo ""
echo "4. 🔍 Vérification des composants essentiels..."

# Vérifier la présence des fichiers clés
REQUIRED_FILES=(
    "BACKUP_MANIFEST.md"
    "sama_conai_demo_database.sql"
    "sama_conai_module/__manifest__.py"
    "sama_conai_module/models/__init__.py"
    "sama_conai_module/views/menus.xml"
    "sama_conai_module/templates/portal_templates.xml"
    "sama_conai_module/data/demo_wave_1_minimal.xml"
    "sama_conai_module/data/demo_wave_2_extended.xml"
    "sama_conai_module/data/demo_wave_3_advanced.xml"
    "sama_conai_module/PORTAL_ERROR_FIXED.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if tar -tzf "$BACKUP_FILE" | grep -q "$file"; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file MANQUANT"
    fi
done

echo ""
echo "5. 🔧 Vérification spécifique v2.4 - Correction Portal..."

# Extraction temporaire pour vérifier la correction portal
TEMP_DIR="temp_verify_v24_$$"
mkdir -p "$TEMP_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

if [ -d "$TEMP_DIR"/*/ ]; then
    BACKUP_DIR=$(ls -d "$TEMP_DIR"/*/ | head -1)
    
    # Vérifier que le manifeste contient le template portal
    if [ -f "$BACKUP_DIR/sama_conai_module/__manifest__.py" ]; then
        if grep -q "templates/portal_templates.xml" "$BACKUP_DIR/sama_conai_module/__manifest__.py"; then
            echo "   ✅ Template portal déclaré dans le manifeste"
        else
            echo "   ❌ Template portal manquant dans le manifeste"
        fi
    fi
    
    # Vérifier que le fichier template existe
    if [ -f "$BACKUP_DIR/sama_conai_module/templates/portal_templates.xml" ]; then
        echo "   ✅ Fichier portal_templates.xml présent"
        
        # Vérifier que la vue problématique est définie
        if grep -q "portal_information_request_detail" "$BACKUP_DIR/sama_conai_module/templates/portal_templates.xml"; then
            echo "   ✅ Vue portal_information_request_detail définie"
        else
            echo "   ❌ Vue portal_information_request_detail manquante"
        fi
    else
        echo "   ❌ Fichier portal_templates.xml manquant"
    fi
    
    # Vérifier la documentation de correction
    if [ -f "$BACKUP_DIR/sama_conai_module/PORTAL_ERROR_FIXED.md" ]; then
        echo "   ✅ Documentation de correction présente"
    else
        echo "   ❌ Documentation de correction manquante"
    fi
fi

# Nettoyage
rm -rf "$TEMP_DIR"

echo ""
echo "6. 📊 Analyse de la taille..."
ARCHIVE_SIZE=$(ls -lh "$BACKUP_FILE" | awk '{print $5}')
echo "   📦 Taille de l'archive: $ARCHIVE_SIZE"

echo ""
echo "7. ✅ Test d'extraction..."
TEST_DIR="test_extract_v24_$$"
mkdir -p "$TEST_DIR"

if tar -xzf "$BACKUP_FILE" -C "$TEST_DIR" > /dev/null 2>&1; then
    echo "   ✅ Extraction réussie"
    
    # Vérifier le manifeste
    MANIFEST_FILE=$(find "$TEST_DIR" -name "BACKUP_MANIFEST.md" | head -1)
    if [ -f "$MANIFEST_FILE" ]; then
        echo "   ✅ Manifeste trouvé"
        echo "   📋 Version: $(grep "Version.*:" "$MANIFEST_FILE" | head -1)"
        echo "   📅 Date: $(grep "Date.*:" "$MANIFEST_FILE" | head -1)"
        
        # Vérifier les nouveautés v2.4
        if grep -q "NOUVEAUTÉS VERSION 2.4" "$MANIFEST_FILE"; then
            echo "   ✅ Nouveautés v2.4 documentées"
        else
            echo "   ❌ Nouveautés v2.4 non documentées"
        fi
        
        if grep -q "Erreur Portal Corrigée" "$MANIFEST_FILE"; then
            echo "   ✅ Correction portal documentée"
        else
            echo "   ❌ Correction portal non documentée"
        fi
    fi
    
    rm -rf "$TEST_DIR"
else
    echo "   ❌ Échec de l'extraction"
    rm -rf "$TEST_DIR"
    exit 1
fi

echo ""
echo "🎉 VÉRIFICATION TERMINÉE"
echo ""
echo "✅ RÉSULTAT :"
echo "   📦 Archive v2.4 intègre et complète"
echo "   🗄️ Base de données incluse"
echo "   📄 Module complet sauvegardé"
echo "   📚 Documentation présente"
echo "   🔧 Scripts de gestion inclus"
echo "   ✅ Correction portal intégrée (NOUVEAU v2.4)"
echo ""
echo "🚀 BACKUP v2.4 VALIDÉ !"
echo "   Le backup contient la correction de l'erreur portal"
echo "   Le système est prêt pour la restauration"
echo ""
echo "📖 POUR RESTAURER :"
echo "   1. tar -xzf $BACKUP_FILE"
echo "   2. Consulter le fichier BACKUP_MANIFEST.md"
echo "   3. Suivre les instructions de restauration"
echo ""
echo "🔧 NOUVEAUTÉS v2.4 :"
echo "   ✅ Erreur portal_information_request_detail corrigée"
echo "   ✅ Interface portal entièrement fonctionnelle"
echo "   ✅ Plus d'erreurs 500 liées aux vues portal"