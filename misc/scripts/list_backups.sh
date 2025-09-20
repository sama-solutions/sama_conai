#!/bin/bash

# Liste tous les backups SAMA CONAI disponibles

echo "📁 LISTE DES BACKUPS SAMA CONAI"
echo "==============================="

echo ""
echo "🔍 Recherche des fichiers de backup..."

# Chercher tous les fichiers de backup
BACKUP_FILES=($(ls backup_sama_conai_v*.tar.gz 2>/dev/null))

if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
    echo "❌ Aucun fichier de backup trouvé"
    exit 1
fi

echo "📦 ${#BACKUP_FILES[@]} backup(s) trouvé(s) :"
echo ""

# Afficher les détails de chaque backup
for backup_file in "${BACKUP_FILES[@]}"; do
    echo "📁 $backup_file"
    
    # Extraire les informations du nom de fichier
    if [[ $backup_file =~ backup_sama_conai_v([0-9.]+)_([0-9]{8})_([0-9]{6})\.tar\.gz ]]; then
        VERSION="${BASH_REMATCH[1]}"
        DATE="${BASH_REMATCH[2]}"
        TIME="${BASH_REMATCH[3]}"
        
        # Formater la date et l'heure
        FORMATTED_DATE="${DATE:6:2}/${DATE:4:2}/${DATE:0:4}"
        FORMATTED_TIME="${TIME:0:2}:${TIME:2:2}:${TIME:4:2}"
        
        echo "   🏷️  Version: v$VERSION"
        echo "   📅 Date: $FORMATTED_DATE à $FORMATTED_TIME"
    fi
    
    # Taille du fichier
    SIZE=$(ls -lh "$backup_file" | awk '{print $5}')
    echo "   📊 Taille: $SIZE"
    
    # Test d'intégrité
    if tar -tzf "$backup_file" > /dev/null 2>&1; then
        echo "   ✅ Intégrité: OK"
    else
        echo "   ❌ Intégrité: CORROMPUE"
    fi
    
    # Date de modification
    MOD_DATE=$(ls -l "$backup_file" | awk '{print $6, $7, $8}')
    echo "   🕒 Modifié: $MOD_DATE"
    
    echo ""
done

echo "🔧 OUTILS DISPONIBLES :"
echo ""

# Lister les scripts de gestion des backups
BACKUP_SCRIPTS=(
    "backup_v2.3.sh:Créer un nouveau backup v2.3"
    "verify_backup_v2.3.sh:Vérifier l'intégrité d'un backup"
    "test_restore_v2.3.sh:Tester la restauration d'un backup"
    "RESTORE_GUIDE_v2.3.md:Guide de restauration détaillé"
    "BACKUP_v2.3_SUMMARY.md:Résumé complet du backup v2.3"
)

for script_info in "${BACKUP_SCRIPTS[@]}"; do
    IFS=':' read -r script_name script_desc <<< "$script_info"
    if [ -f "$script_name" ]; then
        echo "   ✅ $script_name - $script_desc"
    else
        echo "   ❌ $script_name - $script_desc (manquant)"
    fi
done

echo ""
echo "📖 UTILISATION :"
echo ""
echo "🔍 Vérifier un backup :"
echo "   ./verify_backup_v2.3.sh"
echo ""
echo "🧪 Tester la restauration :"
echo "   ./test_restore_v2.3.sh"
echo ""
echo "📦 Extraire un backup :"
echo "   tar -xzf backup_sama_conai_v2.3_YYYYMMDD_HHMMSS.tar.gz"
echo ""
echo "📚 Guide de restauration :"
echo "   cat RESTORE_GUIDE_v2.3.md"
echo ""
echo "📊 Résumé du backup :"
echo "   cat BACKUP_v2.3_SUMMARY.md"

echo ""
echo "💾 BACKUPS SAMA CONAI LISTÉS AVEC SUCCÈS !"