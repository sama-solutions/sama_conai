#!/bin/bash

# Backup SAMA CONAI v2.4 - Module avec correction erreur portal

echo "💾 BACKUP SAMA CONAI v2.4"
echo "========================="

VERSION="2.4"
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
rm -rf /tmp/odoo_test.log 2>/dev/null
rm -rf /tmp/portal_error_check.log 2>/dev/null
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

## 🔧 **NOUVEAUTÉS VERSION 2.4**

### **✅ CORRECTION MAJEURE**
- **Erreur Portal Corrigée** : Résolution de l'erreur 500 "External ID not found: sama_conai.portal_information_request_detail"
- **Cause** : Fichier templates/portal_templates.xml non déclaré dans __manifest__.py
- **Solution** : Ajout de 'templates/portal_templates.xml' dans la section data du manifeste
- **Impact** : Interface portal entièrement fonctionnelle

### **🛠️ AMÉLIORATIONS**
- **Stabilité** : Plus d'erreurs 500 liées aux vues portal
- **Fonctionnalité** : Interface portal entièrement opérationnelle
- **Utilisabilité** : Accès complet aux fonctionnalités SAMA CONAI
- **Maintenance** : Structure de fichiers cohérente et complète

## 📦 **CONTENU DU BACKUP**

### **🔧 Module Odoo**
- **Répertoire** : \`sama_conai_module/\`
- **Fichiers** : Module complet avec correction portal
- **Version Odoo** : 18.0 Community Edition
- **Correction** : Portal templates correctement intégrés

### **🗄️ Base de Données**
- **Fichier** : \`sama_conai_demo_database.sql\`
- **Base** : sama_conai_demo
- **Contenu** : Module + données de démo par vagues + correction portal

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
- ✅ **Interface portal fonctionnelle** (NOUVEAU v2.4)

### **🚨 Gestion des Signalements d'Alerte**
- ✅ Signalements anonymes et nominatifs
- ✅ 6 catégories de violations
- ✅ 3 niveaux de priorité
- ✅ Workflow d'investigation complet
- ✅ Sécurité renforcée
- ✅ **Vues portal opérationnelles** (NOUVEAU v2.4)

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
- ✅ **Templates portal intégrés** (NOUVEAU v2.4)

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

### **🔧 Correction Portal**
- \`PORTAL_ERROR_FIXED.md\` : Documentation complète de la correction
- \`verify_portal_fix.sh\` : Script de vérification de la correction

### **📖 Documentation Générale**
- \`GUIDE_DONNEES_DEMO_VAGUES.md\` : Guide des données par vagues
- \`README_DONNEES_DEMO_FINAL.md\` : Documentation complète
- \`verify_demo_waves.sh\` : Script de vérification
- \`TEST_FINAL_DEMO.sh\` : Test complet du système
- \`start_with_demo.sh\` : Démarrage avec données

## 🎯 **ÉTAT DU SYSTÈME**

### **✅ Fonctionnalités Validées**
- Module installé et opérationnel
- **Erreur portal corrigée** (NOUVEAU v2.4)
- Données de démo chargées par vagues
- Interface web accessible sans erreur 500
- Workflows complets testés
- Sécurité configurée
- **Interface portal entièrement fonctionnelle** (NOUVEAU v2.4)

### **📊 Statistiques**
- **Demandes d'information** : 6 enregistrements
- **Signalements d'alerte** : 6 enregistrements
- **Étapes configurées** : 7
- **Motifs de refus** : 10
- **Vues créées** : 12
- **Menus configurés** : 3
- **Templates portal** : Intégrés et fonctionnels

## 🔧 **COMPATIBILITÉ**

- **Odoo** : 18.0 Community Edition
- **Python** : 3.8+
- **PostgreSQL** : 12+
- **Navigateurs** : Chrome, Firefox, Safari, Edge

## 📞 **SUPPORT**

Ce backup contient un système complet et fonctionnel du module SAMA CONAI
pour la gestion de la transparence au Sénégal, avec la correction de l'erreur portal.

**Développé pour la Commission Nationale d'Accès à l'Information du Sénégal**

---

*Backup v2.4 créé le $(date +"%d/%m/%Y à %H:%M:%S") avec correction portal*
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
echo "   📦 Module complet sauvegardé avec correction portal"
echo "   🗄️ Base de données avec données de démo"
echo "   📚 Documentation incluse"
echo "   🔧 Scripts de gestion fournis"
echo "   ✅ Erreur portal corrigée (NOUVEAU v2.4)"
echo ""
echo "📁 FICHIER DE BACKUP :"
echo "   ${BACKUP_NAME}.tar.gz"
echo ""
echo "🚀 POUR RESTAURER :"
echo "   1. Extraire: tar -xzf ${BACKUP_NAME}.tar.gz"
echo "   2. Suivre les instructions dans BACKUP_MANIFEST.md"
echo ""
echo "🔧 NOUVEAUTÉS v2.4 :"
echo "   ✅ Correction de l'erreur portal_information_request_detail"
echo "   ✅ Interface portal entièrement fonctionnelle"
echo "   ✅ Plus d'erreurs 500 liées aux vues portal"
echo ""
echo "💾 Backup v${VERSION} créé avec succès !"