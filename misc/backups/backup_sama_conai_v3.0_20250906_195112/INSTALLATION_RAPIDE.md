# Installation Rapide - SAMA CONAI

## 🚀 Installation en 3 étapes

### Étape 1 : Installation du module
```bash
cd /home/grand-as/psagsn/custom_addons/sama_conai
./scripts/install_sama_conai.sh sama_conai_demo
```

### Étape 2 : Test des données
```bash
./scripts/test_sama_conai.sh sama_conai_demo
```

### Étape 3 : Démarrage du serveur
```bash
./scripts/start_sama_conai.sh sama_conai_demo
```

## 🎯 Accès à l'application

1. **URL** : http://localhost:8069
2. **Base de données** : sama_conai_demo
3. **Utilisateur** : admin
4. **Mot de passe** : admin

## 📊 Navigation

### Menu principal
- **Accès à l'Information** > **Demandes d'Information**
- **Signalement d'Alerte** > **Signalements**

### Vues recommandées
1. **Vue Kanban** : Suivi visuel par étapes
2. **Vue Graph** : Analyses temporelles
3. **Vue Pivot** : Analyses croisées

## 🔧 Configuration système

### Chemins utilisés
- **Odoo** : `/var/odoo/odoo18`
- **Environnement virtuel** : `/home/grand-as/odoo18-venv`
- **Custom addons** : `/home/grand-as/psagsn/custom_addons`
- **PostgreSQL** : localhost (user: odoo, password: odoo)

### Fichiers de configuration
- `odoo_sama_conai.conf` : Configuration Odoo adaptée
- Scripts dans `scripts/` : Installation et tests automatisés

## 📚 Documentation

- `GUIDE_ANALYSE_DONNEES.md` : Guide complet d'utilisation
- `DEMO_DATA_SUMMARY.md` : Résumé des données de démo
- `scripts/` : Scripts d'installation et de test

## 🆘 Dépannage

### Problème : Module non trouvé
```bash
# Vérifier les chemins
ls -la /home/grand-as/psagsn/custom_addons/sama_conai
```

### Problème : Base de données
```bash
# Créer la base si nécessaire
sudo -u postgres createdb -O odoo sama_conai_demo
```

### Problème : Permissions
```bash
# Donner les permissions aux scripts
chmod +x scripts/*.sh
```

### Problème : Environnement virtuel
```bash
# Activer manuellement
source /home/grand-as/odoo18-venv/bin/activate
```

## ✅ Validation de l'installation

Après l'installation, vous devriez voir :
- ✅ 6 demandes d'information de démo
- ✅ 6 signalements d'alerte de démo
- ✅ Vues Kanban, Graph, Pivot fonctionnelles
- ✅ Filtres et recherches avancées
- ✅ Workflows complets

---

*Pour une installation complète avec tous les tests, utilisez `install_complete_demo.sh`*