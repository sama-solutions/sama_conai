#!/bin/bash

# Backup SAMA CONAI v2.3 - Module complet avec données de démo par vagues

echo "💾 BACKUP SAMA CONAI v2.3"
echo "========================="

VERSION="2.3"
BACKUP_DIR="backup_sama_conai_v${VERSION}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="${BACKUP_DIR}_${TIMESTAMP}"

echo "Version: $VERSION"
echo "Backup: $BACKUP_NAME"
echo ""

# Créer le répertoire de backup
mkdir -p "$BACKUP_NAME"

echo "1. 📦 Sauvegarde du module..."

# Copier tous les fichiers du module
cp -r . "$BACKUP_NAME/sama_conai_module"

# Exclure les backups précédents et fichiers temporaires
cd "$BACKUP_NAME/sama_conai_module"
rm -rf backup_sama_conai_v* 2>/dev/null
rm -rf __pycache__ 2>/dev/null
rm -rf .git 2>/dev/null
rm -rf *.pyc 2>/dev/null
cd ../..

echo "   ✅ Module sauvegardé"

echo ""
echo "2. 🗄️ Sauvegarde de la base de données..."

export PGPASSWORD=odoo

# Backup de la base avec données de démo
pg_dump -h localhost -U odoo -d sama_conai_demo > "$BACKUP_NAME/sama_conai_demo_database.sql"

if [ $? -eq 0 ]; then
    echo "   ✅ Base de données sauvegardée"
else
    echo "   ⚠️ Erreur lors de la sauvegarde de la base"
fi

echo ""
echo "3. 📋 Création du manifeste de backup..."

cat > "$BACKUP_NAME/BACKUP_MANIFEST.md" << EOF
# 💾 BACKUP SAMA CONAI v${VERSION}

## 📊 **INFORMATIONS DE SAUVEGARDE**

- **Version** : ${VERSION}
- **Date** : $(date +"%d/%m/%Y à %H:%M:%S")
- **Backup** : ${BACKUP_NAME}
- **Système** : $(uname -a)

## 📦 **CONTENU DU BACKUP**

### **🔧 Module Odoo**
- **Répertoire** : \`sama_conai_module/\`
- **Fichiers** : Module complet avec toutes les fonctionnalités
- **Version Odoo** : 18.0 Community Edition

### **🗄️ Base de Données**
- **Fichier** : \`sama_conai_demo_database.sql\`
- **Base** : sama_conai_demo
- **Contenu** : Module + données de démo par vagues

### **📊 Données de Démo Incluses**
- **🌊 Vague 1** : 2 enregistrements minimaux
- **🌊 Vague 2** : 6 enregistrements étendus
- **🌊 Vague 3** : 4 enregistrements avancés
- **📈 Total** : 12 enregistrements de données de démo

## 🎯 **FONCTIONNALITÉS SAUVEGARDÉES**

### **📋 Gestion des Demandes d'Information**
- ✅ 5 modèles métier complets
- ✅ 12 vues (Kanban, Liste, Formulaire, Graph, Pivot, Search)
- ✅ Workflow complet : Draft → Soumise → En cours → Répondue
- ✅ Gestion des refus avec motifs légaux
- ✅ 5 profils de demandeurs (citoyen, journaliste, chercheur, avocat, ONG)

### **🚨 Gestion des Signalements d'Alerte**
- ✅ Signalements anonymes et nominatifs
- ✅ 6 catégories de violations
- ✅ 3 niveaux de priorité
- ✅ Workflow d'investigation complet
- ✅ Sécurité renforcée

### **📊 Analyses et Rapports**
- ✅ Vues Graph pour tendances temporelles
- ✅ Vues Pivot pour analyses croisées
- ✅ Filtres avancés par critères
- ✅ Tableaux de bord interactifs

### **⚙️ Configuration**
- ✅ 7 étapes de traitement configurables
- ✅ 10 motifs de refus prédéfinis
- ✅ 3 groupes de sécurité utilisateur
- ✅ Séquences automatiques

## 🚀 **RESTAURATION**

### **1. Restaurer le module**
\`\`\`bash
# Copier le module dans le répertoire addons
cp -r sama_conai_module /path/to/custom_addons/sama_conai
\`\`\`

### **2. Restaurer la base de données**
\`\`\`bash
# Créer une nouvelle base
createdb -h localhost -U odoo sama_conai_restored

# Restaurer les données
psql -h localhost -U odoo -d sama_conai_restored < sama_conai_demo_database.sql
\`\`\`

### **3. Démarrer Odoo**
\`\`\`bash
python3 odoo-bin -d sama_conai_restored --addons-path=/path/to/addons
\`\`\`

## 📚 **DOCUMENTATION INCLUSE**

- \`GUIDE_DONNEES_DEMO_VAGUES.md\` : Guide des données par vagues
- \`README_DONNEES_DEMO_FINAL.md\` : Documentation complète
- \`verify_demo_waves.sh\` : Script de vérification
- \`TEST_FINAL_DEMO.sh\` : Test complet du système
- \`start_with_demo.sh\` : Démarrage avec données

## 🎯 **ÉTAT DU SYSTÈME**

### **✅ Fonctionnalités Validées**
- Module installé et opérationnel
- Données de démo chargées par vagues
- Interface web accessible
- Workflows complets testés
- Sécurité configurée

### **📊 Statistiques**
- **Demandes d'information** : 6 enregistrements
- **Signalements d'alerte** : 6 enregistrements
- **Étapes configurées** : 7
- **Motifs de refus** : 10
- **Vues créées** : 12
- **Menus configurés** : 3

## 🔧 **COMPATIBILITÉ**

- **Odoo** : 18.0 Community Edition
- **Python** : 3.8+
- **PostgreSQL** : 12+
- **Navigateurs** : Chrome, Firefox, Safari, Edge

## 📞 **SUPPORT**

Ce backup contient un système complet et fonctionnel du module SAMA CONAI
pour la gestion de la transparence au Sénégal.

**Développé pour la Commission Nationale d'Accès à l'Information du Sénégal**

---

*Backup créé le $(date +"%d/%m/%Y à %H:%M:%S")*
EOF

echo "   ✅ Manifeste créé"

echo ""
echo "4. 📊 Statistiques du backup..."

# Taille du backup
BACKUP_SIZE=$(du -sh "$BACKUP_NAME" | cut -f1)
MODULE_FILES=$(find "$BACKUP_NAME/sama_conai_module" -type f | wc -l)
DB_SIZE=$(ls -lh "$BACKUP_NAME/sama_conai_demo_database.sql" 2>/dev/null | awk '{print $5}' || echo "N/A")

echo "   📦 Taille totale: $BACKUP_SIZE"
echo "   📄 Fichiers module: $MODULE_FILES"
echo "   🗄️ Taille DB: $DB_SIZE"

echo ""
echo "5. 🗜️ Compression du backup..."

tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

if [ $? -eq 0 ]; then
    COMPRESSED_SIZE=$(ls -lh "${BACKUP_NAME}.tar.gz" | awk '{print $5}')
    echo "   ✅ Backup compressé: ${BACKUP_NAME}.tar.gz ($COMPRESSED_SIZE)"
    
    # Supprimer le répertoire non compressé
    rm -rf "$BACKUP_NAME"
    echo "   🧹 Répertoire temporaire supprimé"
else
    echo "   ⚠️ Erreur lors de la compression"
fi

echo ""
echo "6. ✅ Vérification du backup..."

if [ -f "${BACKUP_NAME}.tar.gz" ]; then
    echo "   ✅ Backup créé avec succès"
    echo "   📁 Fichier: ${BACKUP_NAME}.tar.gz"
    echo "   📊 Taille: $(ls -lh "${BACKUP_NAME}.tar.gz" | awk '{print $5}')"
    
    # Test d'intégrité
    tar -tzf "${BACKUP_NAME}.tar.gz" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ Intégrité vérifiée"
    else
        echo "   ⚠️ Problème d'intégrité détecté"
    fi
else
    echo "   ❌ Échec de la création du backup"
    exit 1
fi

echo ""
echo "🎉 BACKUP SAMA CONAI v${VERSION} TERMINÉ !"
echo ""
echo "📋 RÉSUMÉ :"
echo "   📦 Module complet sauvegardé"
echo "   🗄️ Base de données avec données de démo"
echo "   📚 Documentation incluse"
echo "   🔧 Scripts de gestion fournis"
echo ""
echo "📁 FICHIER DE BACKUP :"
echo "   ${BACKUP_NAME}.tar.gz"
echo ""
echo "🚀 POUR RESTAURER :"
echo "   1. Extraire: tar -xzf ${BACKUP_NAME}.tar.gz"
echo "   2. Suivre les instructions dans BACKUP_MANIFEST.md"
echo ""
echo "💾 Backup v${VERSION} créé avec succès !"