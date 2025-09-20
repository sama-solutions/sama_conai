# Scripts de Lancement SAMA CONAI

Ce dossier contient des scripts optimisés pour l'installation, les tests et la maintenance du module Odoo SAMA CONAI.

## 🚀 Scripts Disponibles

### 1. `launch_sama_conai.sh` - Script Principal de Lancement

Script principal pour démarrer le module avec toutes les options nécessaires.

```bash
# Première installation
./launch_sama_conai.sh --init -p 8075 -d sama_conai_test

# Mise à jour du module
./launch_sama_conai.sh --update -p 8075 -d sama_conai_test

# Démarrage simple
./launch_sama_conai.sh --run -p 8075 -d sama_conai_test

# Mode développement avec suivi des logs
./launch_sama_conai.sh --run -p 8075 -d sama_conai_test --dev --follow
```

**Options principales :**
- `--init` : Initialise et installe le module
- `--update` : Met à jour le module
- `--run` : Lance le serveur (défaut)
- `-p, --port` : Port HTTP (défaut: 8075)
- `-d, --db` : Nom de la base de données (défaut: sama_conai_test)
- `--dev` : Mode développement
- `--debug` : Logs en mode debug
- `--follow` : Suit les logs en temps réel
- `--dry-run` : Affiche la commande sans l'exécuter

### 2. `stop_sama_conai.sh` - Script d'Arrêt

Arrête proprement les instances du module sans affecter les autres processus Odoo.

```bash
# Arrêter l'instance sur un port spécifique
./stop_sama_conai.sh -p 8075

# Arrêter toutes les instances SAMA CONAI
./stop_sama_conai.sh --all

# Arrêter et nettoyer les fichiers temporaires
./stop_sama_conai.sh -p 8075 --cleanup

# Forcer l'arrêt immédiat
./stop_sama_conai.sh -p 8075 --force
```

### 3. `test_cycle_sama_conai.sh` - Cycle de Test Automatisé

Script pour automatiser le cycle complet de test : démarrage → tests → analyse → corrections.

```bash
# Test simple
./test_cycle_sama_conai.sh -p 8075 -d sama_conai_test

# Test avec initialisation
./test_cycle_sama_conai.sh --init -p 8075 -d sama_conai_test

# Mode continu pour développement
./test_cycle_sama_conai.sh --continuous -p 8075 -d sama_conai_test

# Mode non-interactif pour CI/CD
./test_cycle_sama_conai.sh --non-interactive -p 8075 -d sama_conai_test
```

**Fonctionnalités :**
- Tests automatiques de santé du serveur
- Vérification de la connexion base de données
- Test d'installation du module
- Test de l'interface web
- Analyse automatique des logs
- Suggestions de correction
- Menu interactif pour le débogage

### 4. `cleanup_temp.sh` - Nettoyage des Fichiers Temporaires

Nettoie tous les fichiers temporaires créés pendant les tests.

```bash
# Nettoyage standard
./cleanup_temp.sh

# Nettoyage complet
./cleanup_temp.sh --deep

# Voir ce qui serait supprimé
./cleanup_temp.sh --dry-run

# Nettoyer seulement les logs
./cleanup_temp.sh --logs-only
```

## 📁 Structure des Fichiers Temporaires

```
.sama_conai_temp/
├── logs/           # Fichiers de logs Odoo
├── conf/           # Fichiers de configuration temporaires
└── pids/           # Fichiers PID des processus
```

## 🔧 Configuration

Les scripts utilisent la configuration suivante (modifiable dans `launch_sama_conai.sh`) :

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

## 🚦 Workflow de Développement Recommandé

### 1. Première Installation

```bash
# 1. Initialiser le module
./launch_sama_conai.sh --init -p 8075 -d sama_conai_dev

# 2. Tester l'installation
./test_cycle_sama_conai.sh -p 8075 -d sama_conai_dev
```

### 2. Cycle de Développement

```bash
# 1. Arrêter l'instance
./stop_sama_conai.sh -p 8075

# 2. Modifier le code...

# 3. Mettre à jour et tester
./test_cycle_sama_conai.sh --update -p 8075 -d sama_conai_dev

# 4. En cas d'erreur, utiliser le menu interactif pour déboguer
```

### 3. Tests Continus

```bash
# Mode continu pour développement actif
./test_cycle_sama_conai.sh --continuous --dev -p 8075 -d sama_conai_dev
```

### 4. Nettoyage Périodique

```bash
# Nettoyer les fichiers temporaires
./cleanup_temp.sh

# Nettoyage complet (inclut caches Python)
./cleanup_temp.sh --deep
```

## 🔍 Débogage et Logs

### Localisation des Logs

```bash
# Logs principaux
tail -f .sama_conai_temp/logs/odoo-8075.log

# Logs d'erreur seulement
grep ERROR .sama_conai_temp/logs/odoo-8075.log

# Dernières erreurs
tail -100 .sama_conai_temp/logs/odoo-8075.log | grep -E "(ERROR|CRITICAL)"
```

### Commandes de Diagnostic

```bash
# Vérifier les processus actifs
./stop_sama_conai.sh --status

# Analyser les logs
./test_cycle_sama_conai.sh -p 8075 -d sama_conai_test
# Puis choisir option 4 dans le menu interactif
```

## ⚠️ Points Importants

1. **Isolation des Processus** : Les scripts n'arrêtent que les processus sur le port spécifié
2. **Gestion des Erreurs** : Chaque script inclut une gestion robuste des erreurs
3. **Logs Détaillés** : Tous les événements sont loggés avec horodatage
4. **Sécurité** : Vérifications de sécurité avant suppression de fichiers
5. **Compatibilité** : Scripts testés avec Bash 4.0+

## 🆘 Résolution de Problèmes Courants

### Port déjà utilisé
```bash
./stop_sama_conai.sh -p 8075 --force
```

### Base de données corrompue
```bash
# Supprimer et recréer la base
PGPASSWORD=odoo dropdb -h localhost -U odoo sama_conai_test
./launch_sama_conai.sh --init -p 8075 -d sama_conai_test
```

### Erreurs de permissions
```bash
# Vérifier les permissions des scripts
chmod +x *.sh

# Vérifier les permissions des dossiers
sudo chown -R $USER:$USER .sama_conai_temp/
```

### Processus zombie
```bash
# Forcer l'arrêt de tous les processus SAMA CONAI
./stop_sama_conai.sh --all --force
```

## 📞 Support

En cas de problème :

1. Consultez les logs : `.sama_conai_temp/logs/odoo-[PORT].log`
2. Utilisez le mode debug : `./launch_sama_conai.sh --debug`
3. Utilisez le cycle de test interactif : `./test_cycle_sama_conai.sh`
4. Nettoyez les fichiers temporaires : `./cleanup_temp.sh --deep`

---

**Note** : Ces scripts sont conçus pour être autonomes et permettre un développement efficace du module SAMA CONAI sans interférer avec d'autres instances Odoo.