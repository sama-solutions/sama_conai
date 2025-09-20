# Guide d'Installation SAMA CONAI

## 🎯 Objectif

Ce guide vous permet d'installer et de tester le module Odoo SAMA CONAI de manière autonome avec des scripts optimisés pour le développement et les tests.

## 📋 Prérequis

Avant de commencer, assurez-vous que votre environnement dispose de :

- **Odoo 18** installé dans `/var/odoo/odoo18`
- **Virtual Environment Python** dans `/home/grand-as/odoo18-venv`
- **PostgreSQL** avec utilisateur `odoo` / mot de passe `odoo`
- **Custom addons** dans `/home/grand-as/psagsn/custom_addons`

## 🚀 Installation Rapide

### 1. Validation de l'environnement (optionnel)

```bash
# Vérifier que tout est en place
./validate_environment.sh
```

### 2. Première installation

```bash
# Installation complète avec tests
./quick_start.sh init
```

### 3. Accès au module

Une fois l'installation terminée, accédez à :
- **URL** : http://localhost:8075
- **Base de données** : sama_conai_test
- **Utilisateur** : admin
- **Mot de passe** : admin

## 📚 Scripts Disponibles

### Scripts Principaux

| Script | Description | Usage |
|--------|-------------|-------|
| `quick_start.sh` | **Script principal** - Démarrage rapide | `./quick_start.sh init` |
| `launch_sama_conai.sh` | Lancement détaillé avec options | `./launch_sama_conai.sh --init -p 8075` |
| `test_cycle_sama_conai.sh` | Cycle de test automatisé | `./test_cycle_sama_conai.sh -p 8075` |
| `stop_sama_conai.sh` | Arrêt propre des instances | `./stop_sama_conai.sh -p 8075` |
| `cleanup_temp.sh` | Nettoyage des fichiers temporaires | `./cleanup_temp.sh` |
| `validate_environment.sh` | Validation de l'environnement | `./validate_environment.sh` |

### Commandes Rapides

```bash
# Démarrage rapide
./quick_start.sh                    # Démarrage simple
./quick_start.sh init               # Première installation
./quick_start.sh update             # Mise à jour
./quick_start.sh test               # Tests complets
./quick_start.sh stop               # Arrêt
./quick_start.sh clean              # Nettoyage

# Avec options
./quick_start.sh init -p 8076 -d my_database
```

## 🔄 Workflow de Développement

### Cycle de Développement Standard

```bash
# 1. Première installation
./quick_start.sh init

# 2. Développement...
# Modifier le code du module

# 3. Test des modifications
./quick_start.sh update

# 4. Tests automatisés
./quick_start.sh test

# 5. En cas de problème
./quick_start.sh stop
./quick_start.sh clean
```

### Mode Développement Continu

```bash
# Lancement en mode continu avec rechargement automatique
./test_cycle_sama_conai.sh --continuous --dev -p 8075
```

## 🛠️ Configuration

### Ports par Défaut

- **Port principal** : 8075
- **Base de données** : sama_conai_test
- **Ports alternatifs** : 8076, 8077, 8078, 8079

### Personnalisation

Pour modifier la configuration, éditez les variables dans `launch_sama_conai.sh` :

```bash
# Chemins système
ODOO_HOME="/var/odoo/odoo18"
VENV_DIR="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS="/home/grand-as/psagsn/custom_addons"

# PostgreSQL
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="odoo"
DB_PASSWORD="odoo"
```

## 📁 Structure des Fichiers

```
sama_conai/
├── launch_sama_conai.sh          # Script principal de lancement
├── stop_sama_conai.sh            # Script d'arrêt
├── test_cycle_sama_conai.sh      # Cycle de test automatisé
├── cleanup_temp.sh               # Nettoyage
├── quick_start.sh                # Démarrage rapide
├── validate_environment.sh       # Validation environnement
├── .sama_conai_temp/             # Fichiers temporaires
│   ├── logs/                     # Logs Odoo
│   ├── conf/                     # Configurations
│   └── pids/                     # Fichiers PID
├── SCRIPTS_README.md             # Documentation détaillée
└── INSTALLATION_GUIDE.md         # Ce guide
```

## 🔍 Débogage et Logs

### Localisation des Logs

```bash
# Logs principaux
tail -f .sama_conai_temp/logs/odoo-8075.log

# Erreurs seulement
grep ERROR .sama_conai_temp/logs/odoo-8075.log

# Suivi en temps réel
./launch_sama_conai.sh --run -p 8075 --follow
```

### Tests et Diagnostics

```bash
# Tests complets avec menu interactif
./test_cycle_sama_conai.sh -p 8075

# Validation de l'environnement
./validate_environment.sh

# Statut des instances
./stop_sama_conai.sh --status
```

## ⚠️ Résolution de Problèmes

### Problèmes Courants

#### Port déjà utilisé
```bash
./stop_sama_conai.sh -p 8075 --force
```

#### Base de données corrompue
```bash
# Supprimer et recréer
PGPASSWORD=odoo dropdb -h localhost -U odoo sama_conai_test
./quick_start.sh init
```

#### Erreurs de permissions
```bash
chmod +x *.sh
sudo chown -R $USER:$USER .sama_conai_temp/
```

#### Processus zombie
```bash
./stop_sama_conai.sh --all --force
./cleanup_temp.sh --deep
```

### Logs d'Erreur

Les erreurs courantes et leurs solutions :

| Erreur | Solution |
|--------|----------|
| `database does not exist` | Utilisez `./quick_start.sh init` |
| `module not found` | Vérifiez le chemin des addons |
| `permission denied` | Vérifiez les droits d'accès |
| `port already in use` | Utilisez `./stop_sama_conai.sh -p PORT` |
| `connection refused` | Vérifiez que PostgreSQL est démarré |

## 🎯 Tests de Validation

### Test Complet

```bash
# 1. Validation environnement
./validate_environment.sh

# 2. Installation
./quick_start.sh init

# 3. Tests automatisés
./quick_start.sh test

# 4. Vérification manuelle
# Ouvrir http://localhost:8075
# Se connecter avec admin/admin
# Vérifier que le module SAMA CONAI est installé
```

### Tests Spécifiques

```bash
# Test de santé du serveur
curl -s http://localhost:8075/web/health

# Test de l'interface
curl -s http://localhost:8075/web/login

# Test du module
curl -s http://localhost:8075/web/database/selector
```

## 📞 Support

### En cas de problème :

1. **Consultez les logs** : `.sama_conai_temp/logs/odoo-[PORT].log`
2. **Utilisez le mode debug** : `./launch_sama_conai.sh --debug`
3. **Cycle de test interactif** : `./test_cycle_sama_conai.sh`
4. **Nettoyage complet** : `./cleanup_temp.sh --deep`
5. **Validation environnement** : `./validate_environment.sh`

### Informations Utiles

- **Version Odoo** : 18.0
- **Version Module** : 18.0.1.0.0
- **Python** : 3.8+
- **PostgreSQL** : 12+

---

## ✅ Checklist de Validation

- [ ] Environnement validé avec `./validate_environment.sh`
- [ ] Installation réussie avec `./quick_start.sh init`
- [ ] Tests passés avec `./quick_start.sh test`
- [ ] Accès web fonctionnel sur http://localhost:8075
- [ ] Module SAMA CONAI visible dans la liste des applications
- [ ] Logs sans erreurs critiques

**🎉 Félicitations ! Votre module SAMA CONAI est prêt à être utilisé !**