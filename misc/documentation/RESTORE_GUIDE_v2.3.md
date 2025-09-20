# 🔄 GUIDE DE RESTAURATION SAMA CONAI v2.3

## 📋 **INFORMATIONS DE RESTAURATION**

Ce guide vous permet de restaurer complètement le module SAMA CONAI v2.3 avec toutes ses données de démo par vagues.

### **📦 Contenu du Backup**
- **Module Odoo complet** avec toutes les fonctionnalités
- **Base de données** avec 12 enregistrements de données de démo
- **Documentation complète** et scripts de gestion
- **Configuration** prête à l'emploi

---

## 🚀 **PROCÉDURE DE RESTAURATION**

### **ÉTAPE 1 : Préparation**

#### **1.1 Vérifier les prérequis**
```bash
# Vérifier Odoo 18
python3 /var/odoo/odoo18/odoo-bin --version

# Vérifier PostgreSQL
psql --version

# Vérifier l'environnement virtuel
source /home/grand-as/odoo18-venv/bin/activate
```

#### **1.2 Localiser le backup**
```bash
# Lister les backups disponibles
ls -la backup_sama_conai_v2.3_*.tar.gz

# Vérifier l'intégrité (optionnel)
./verify_backup_v2.3.sh
```

### **ÉTAPE 2 : Extraction du Backup**

#### **2.1 Extraire l'archive**
```bash
# Extraire le backup
tar -xzf backup_sama_conai_v2.3_YYYYMMDD_HHMMSS.tar.gz

# Aller dans le répertoire extrait
cd backup_sama_conai_v2.3_YYYYMMDD_HHMMSS
```

#### **2.2 Vérifier le contenu**
```bash
# Lister le contenu
ls -la

# Consulter le manifeste
cat BACKUP_MANIFEST.md
```

### **ÉTAPE 3 : Restauration du Module**

#### **3.1 Copier le module**
```bash
# Sauvegarder l'ancien module (si existant)
mv /home/grand-as/psagsn/custom_addons/sama_conai /home/grand-as/psagsn/custom_addons/sama_conai_backup_$(date +%Y%m%d) 2>/dev/null

# Copier le nouveau module
cp -r sama_conai_module /home/grand-as/psagsn/custom_addons/sama_conai

# Vérifier la copie
ls -la /home/grand-as/psagsn/custom_addons/sama_conai/
```

#### **3.2 Définir les permissions**
```bash
# Aller dans le répertoire du module
cd /home/grand-as/psagsn/custom_addons/sama_conai

# Rendre les scripts exécutables
chmod +x *.sh

# Vérifier les permissions
ls -la *.sh
```

### **ÉTAPE 4 : Restauration de la Base de Données**

#### **4.1 Préparer la base de données**
```bash
# Définir le mot de passe PostgreSQL
export PGPASSWORD=odoo

# Supprimer l'ancienne base (si existante)
dropdb -h localhost -U odoo sama_conai_demo 2>/dev/null

# Créer une nouvelle base
createdb -h localhost -U odoo sama_conai_demo
```

#### **4.2 Restaurer les données**
```bash
# Retourner dans le répertoire du backup
cd /path/to/backup_sama_conai_v2.3_YYYYMMDD_HHMMSS

# Restaurer la base de données
psql -h localhost -U odoo -d sama_conai_demo < sama_conai_demo_database.sql

# Vérifier la restauration
psql -h localhost -U odoo -d sama_conai_demo -c "SELECT COUNT(*) FROM request_information;"
```

### **ÉTAPE 5 : Vérification de la Restauration**

#### **5.1 Tester le module**
```bash
# Aller dans le répertoire du module
cd /home/grand-as/psagsn/custom_addons/sama_conai

# Vérifier les données de démo
./verify_demo_waves.sh

# Test complet
./TEST_FINAL_DEMO.sh
```

#### **5.2 Démarrer le serveur**
```bash
# Démarrer avec les données de démo
./start_with_demo.sh
```

### **ÉTAPE 6 : Validation Finale**

#### **6.1 Accès à l'interface**
- **URL** : http://localhost:8075
- **Login** : admin
- **Mot de passe** : admin

#### **6.2 Vérifications à effectuer**
1. **Connexion réussie** à l'interface
2. **Menus visibles** : "Accès à l'Information" et "Signalement d'Alerte"
3. **Données présentes** : 6 demandes + 6 signalements
4. **Vues fonctionnelles** : Kanban, Liste, Graph, Pivot
5. **Workflows opérationnels** : Création, modification, validation

---

## 🔧 **RESTAURATION AVANCÉE**

### **Restauration sur un Autre Serveur**

#### **1. Adapter les chemins**
```bash
# Modifier les chemins dans les scripts
sed -i 's|/home/grand-as|/votre/chemin|g' *.sh
sed -i 's|/var/odoo/odoo18|/votre/odoo/path|g' *.sh
```

#### **2. Adapter la configuration**
```bash
# Modifier la configuration de base de données
# Éditer les fichiers de configuration selon votre environnement
```

### **Restauration Partielle**

#### **Module seulement (sans données)**
```bash
# Copier uniquement le module
cp -r sama_conai_module /path/to/addons/sama_conai

# Installer sans données de démo
python3 odoo-bin -d nouvelle_base -i sama_conai --without-demo=all
```

#### **Données seulement (sur module existant)**
```bash
# Restaurer uniquement les données
psql -h localhost -U odoo -d base_existante < sama_conai_demo_database.sql
```

---

## 🚨 **DÉPANNAGE**

### **Problèmes Courants**

#### **Erreur de permissions**
```bash
# Corriger les permissions
sudo chown -R $USER:$USER /home/grand-as/psagsn/custom_addons/sama_conai
chmod +x /home/grand-as/psagsn/custom_addons/sama_conai/*.sh
```

#### **Base de données inaccessible**
```bash
# Vérifier PostgreSQL
sudo systemctl status postgresql
sudo systemctl start postgresql

# Vérifier les connexions
psql -h localhost -U odoo -l
```

#### **Module non trouvé**
```bash
# Vérifier le chemin des addons
python3 odoo-bin --addons-path=/home/grand-as/psagsn/custom_addons --list

# Redémarrer Odoo
sudo systemctl restart odoo
```

#### **Données manquantes**
```bash
# Vérifier l'installation des données
cd /home/grand-as/psagsn/custom_addons/sama_conai
./verify_demo_waves.sh

# Réinstaller si nécessaire
./install_demo_simple.sh
```

### **Logs de Débogage**
```bash
# Démarrer Odoo en mode debug
python3 odoo-bin -d sama_conai_demo --log-level=debug

# Consulter les logs
tail -f /var/log/odoo/odoo.log
```

---

## 📊 **VALIDATION POST-RESTAURATION**

### **Checklist de Validation**

#### **✅ Module**
- [ ] Module visible dans la liste des modules
- [ ] État "Installé" confirmé
- [ ] Version 18.0.1.0.0 affichée

#### **✅ Base de Données**
- [ ] 6 demandes d'information présentes
- [ ] 6 signalements d'alerte présents
- [ ] 7 étapes configurées
- [ ] 10 motifs de refus configurés

#### **✅ Interface**
- [ ] Connexion admin/admin réussie
- [ ] Menu "Accès à l'Information" visible
- [ ] Menu "Signalement d'Alerte" visible
- [ ] Vues Kanban fonctionnelles

#### **✅ Fonctionnalités**
- [ ] Création de nouvelle demande
- [ ] Modification d'un signalement
- [ ] Filtres et recherches opérationnels
- [ ] Rapports et analyses accessibles

### **Tests Recommandés**
1. **Créer une nouvelle demande** d'information
2. **Modifier un signalement** existant
3. **Tester les filtres** par état et priorité
4. **Générer un rapport** Graph ou Pivot
5. **Valider le workflow** complet

---

## 🎯 **RÉSULTAT ATTENDU**

Après une restauration réussie, vous devriez avoir :

### **✅ Système Opérationnel**
- Module SAMA CONAI v2.3 installé et fonctionnel
- Interface web accessible sur http://localhost:8075
- 12 enregistrements de données de démo par vagues
- Tous les workflows et fonctionnalités opérationnels

### **📊 Données de Démo Disponibles**
- **🌊 Vague 1** : 2 enregistrements minimaux
- **🌊 Vague 2** : 6 enregistrements étendus
- **🌊 Vague 3** : 4 enregistrements avancés

### **🎨 Fonctionnalités Testables**
- Gestion complète des demandes d'information
- Signalements d'alerte sécurisés
- Analyses et rapports avancés
- Configuration flexible

---

## 📞 **SUPPORT**

En cas de problème lors de la restauration :

1. **Consulter les logs** d'Odoo et PostgreSQL
2. **Vérifier les prérequis** système
3. **Tester étape par étape** la procédure
4. **Utiliser les scripts** de vérification fournis

**Le backup v2.3 contient un système complet et testé du module SAMA CONAI pour la gestion de la transparence au Sénégal.**

---

*Guide de restauration pour SAMA CONAI v2.3*
*Développé pour la Commission Nationale d'Accès à l'Information du Sénégal*