# SAMA CONAI - Installation et Configuration

## 🚀 Installation Rapide (Recommandée)

```bash
# Configuration complète automatique
./scripts/setup_complete.sh sama_conai_demo
```

Cette commande fait tout automatiquement :
- ✅ Validation du système
- ✅ Installation du module
- ✅ Chargement des données de démo
- ✅ Tests fonctionnels
- ✅ Démarrage optionnel du serveur

## 📋 Installation Manuelle

### 1. Validation du système
```bash
./scripts/validate_installation.sh sama_conai_demo
```

### 2. Installation du module
```bash
./scripts/install_sama_conai.sh sama_conai_demo
```

### 3. Test des données
```bash
./scripts/test_sama_conai.sh sama_conai_demo
```

### 4. Démarrage du serveur
```bash
./scripts/start_sama_conai.sh sama_conai_demo
```

## 🔧 Configuration Système

### Prérequis
- **Odoo 18** installé dans `/var/odoo/odoo18`
- **Environnement virtuel** dans `/home/grand-as/odoo18-venv`
- **PostgreSQL** avec utilisateur `odoo` / mot de passe `odoo`
- **Custom addons** dans `/home/grand-as/psagsn/custom_addons`

### Fichiers de configuration
- `odoo_sama_conai.conf` : Configuration Odoo adaptée
- `scripts/` : Scripts d'installation et de test

## 🎯 Accès à l'Application

### Connexion Web
- **URL** : http://localhost:8069
- **Base de données** : sama_conai_demo
- **Utilisateur** : admin
- **Mot de passe** : admin

### Navigation
1. **Menu principal** : Accès à l'Information
2. **Sous-menus** :
   - Demandes d'Information
   - Signalements d'Alerte
   - Tableau de Bord

## 📊 Fonctionnalités Disponibles

### Données de Démo
- ✅ **6 demandes d'information** (variées par état et qualité)
- ✅ **6 signalements d'alerte** (variés par catégorie et priorité)
- ✅ **Contenu riche** avec HTML, tableaux, analyses
- ✅ **Cas d'usage réalistes** pour formation

### Vues Analytiques
- 🎨 **Vue Kanban** : Suivi visuel par étapes
- 📊 **Vue Graph** : Analyses temporelles et répartitions
- 📈 **Vue Pivot** : Analyses croisées multidimensionnelles
- 🔍 **Filtres avancés** : Recherches sophistiquées

### Workflows Complets
- ⚙️ **Traitement des demandes** : Draft → Soumise → En cours → Validation → Répondue
- 🚨 **Gestion des alertes** : Nouveau → Évaluation → Investigation → Résolution
- 📧 **Notifications automatiques** par email
- 🔒 **Sécurité et confidentialité** renforcées

## 📚 Documentation

### Guides Utilisateur
- `INSTALLATION_RAPIDE.md` : Guide d'installation express
- `GUIDE_ANALYSE_DONNEES.md` : Guide complet d'utilisation
- `DEMO_DATA_SUMMARY.md` : Résumé des données de démo

### Documentation Technique
- `HTML_TRACKING_FIX_README.md` : Corrections techniques
- `MENU_TROUBLESHOOTING.md` : Dépannage interface
- Scripts documentés dans `scripts/`

## 🛠️ Scripts Disponibles

### Installation
- `setup_complete.sh` : Configuration complète automatique
- `install_sama_conai.sh` : Installation du module
- `validate_installation.sh` : Validation système

### Tests
- `test_sama_conai.sh` : Test rapide
- `test_all_demo_waves.py` : Test complet des données
- `validate_complete_system.py` : Validation système complète

### Utilisation
- `start_sama_conai.sh` : Démarrage du serveur
- Tous les scripts sont exécutables (`chmod +x`)

## 🆘 Dépannage

### Problèmes Courants

#### Module non trouvé
```bash
# Vérifier les chemins
ls -la /home/grand-as/psagsn/custom_addons/sama_conai
```

#### Base de données inaccessible
```bash
# Vérifier PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"
```

#### Environnement virtuel
```bash
# Activer manuellement
source /home/grand-as/odoo18-venv/bin/activate
```

#### Permissions
```bash
# Donner les permissions
chmod +x scripts/*.sh
```

### Support
- Consulter les logs dans `/var/log/odoo/`
- Utiliser les scripts de validation
- Vérifier la documentation technique

## ✅ Validation de l'Installation

Après installation, vous devriez avoir :
- ✅ Serveur Odoo accessible sur http://localhost:8069
- ✅ Module SAMA CONAI installé et fonctionnel
- ✅ 12 enregistrements de données de démo
- ✅ Toutes les vues (Kanban, Graph, Pivot) accessibles
- ✅ Workflows complets opérationnels

## 🎯 Prochaines Étapes

1. **Formation** : Utiliser le guide d'analyse de données
2. **Personnalisation** : Adapter les workflows aux besoins
3. **Configuration** : Paramétrer les notifications email
4. **Production** : Migrer vers des données réelles

---

**🎉 SAMA CONAI est maintenant prêt pour la démonstration et l'utilisation !**

*Pour toute question, consulter la documentation ou les scripts de validation.*