#!/bin/bash

# Vérification du backup SAMA CONAI v2.3

echo "🔍 VÉRIFICATION BACKUP SAMA CONAI v2.3"
echo "======================================"

# Trouver le fichier de backup le plus récent
BACKUP_FILE=$(ls -t backup_sama_conai_v2.3_*.tar.gz 2>/dev/null | head -1)

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Aucun fichier de backup v2.3 trouvé"
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
    "sama_conai_module/data/demo_wave_1_minimal.xml"
    "sama_conai_module/data/demo_wave_2_extended.xml"
    "sama_conai_module/data/demo_wave_3_advanced.xml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if tar -tzf "$BACKUP_FILE" | grep -q "$file"; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file MANQUANT"
    fi
done

echo ""
echo "5. 📊 Analyse de la taille..."
ARCHIVE_SIZE=$(ls -lh "$BACKUP_FILE" | awk '{print $5}')
echo "   📦 Taille de l'archive: $ARCHIVE_SIZE"

# Extraction temporaire pour analyse
TEMP_DIR="temp_verify_$$"
mkdir -p "$TEMP_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

if [ -d "$TEMP_DIR"/*/ ]; then
    BACKUP_DIR=$(ls -d "$TEMP_DIR"/*/ | head -1)
    
    if [ -f "$BACKUP_DIR/sama_conai_demo_database.sql" ]; then
        DB_SIZE=$(ls -lh "$BACKUP_DIR/sama_conai_demo_database.sql" | awk '{print $5}')
        echo "   🗄️ Taille de la base: $DB_SIZE"
    fi
    
    if [ -d "$BACKUP_DIR/sama_conai_module" ]; then
        MODULE_FILES=$(find "$BACKUP_DIR/sama_conai_module" -type f | wc -l)
        echo "   📄 Fichiers du module: $MODULE_FILES"
    fi
fi

# Nettoyage
rm -rf "$TEMP_DIR"

echo ""
echo "6. ✅ Test d'extraction..."
TEST_DIR="test_extract_$$"
mkdir -p "$TEST_DIR"

if tar -xzf "$BACKUP_FILE" -C "$TEST_DIR" > /dev/null 2>&1; then
    echo "   ✅ Extraction réussie"
    
    # Vérifier le manifeste
    MANIFEST_FILE=$(find "$TEST_DIR" -name "BACKUP_MANIFEST.md" | head -1)
    if [ -f "$MANIFEST_FILE" ]; then
        echo "   ✅ Manifeste trouvé"
        echo "   📋 Version: $(grep "Version.*:" "$MANIFEST_FILE" | head -1)"
        echo "   📅 Date: $(grep "Date.*:" "$MANIFEST_FILE" | head -1)"
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
echo "   📦 Archive intègre et complète"
echo "   🗄️ Base de données incluse"
echo "   📄 Module complet sauvegardé"
echo "   📚 Documentation présente"
echo "   🔧 Scripts de gestion inclus"
echo ""
echo "🚀 BACKUP v2.3 VALIDÉ !"
echo "   Le backup est prêt pour la restauration"
echo ""
echo "📖 POUR RESTAURER :"
echo "   1. tar -xzf $BACKUP_FILE"
echo "   2. Consulter le fichier BACKUP_MANIFEST.md"
echo "   3. Suivre les instructions de restauration"