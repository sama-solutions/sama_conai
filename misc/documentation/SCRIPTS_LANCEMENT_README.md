# SAMA CONAI - Scripts de Lancement et Test

## Vue d'ensemble

Ce document décrit l'ensemble des scripts de lancement créés pour le développement et les tests du module SAMA CONAI. Ces scripts sont conçus pour être autonomes et permettre un cycle de développement efficace.

## Architecture des Scripts

```
sama_conai/
├── sama_conai_dev.sh                    # Script principal (menu interactif)
├── launch_sama_conai_test.sh           # Script de lancement complet
├── mobile_app_web/
│   └── launch_mobile.sh                # Script application mobile
└── scripts_temp/                       # Scripts temporaires (supprimables)
    ├── test_cycle.sh                   # Cycle de tests automatisé
    ├── monitor.sh                      # Monitoring en temps réel
    ├── logs/                           # Logs des services
    └── pids/                           # Fichiers PID
```

## Configuration

### Prérequis
- **Odoo**: `/var/odoo/odoo18`
- **Virtual Environment**: `/home/grand-as/odoo18-venv`
- **Custom Addons**: `/home/grand-as/psagsn/custom_addons`
- **PostgreSQL**: User `odoo`, Password `odoo`

### Ports Utilisés
- **Odoo Test**: `8075`
- **Application Mobile**: `3005`
- **PostgreSQL**: `5432`

## Scripts Disponibles

### 1. Script Principal - `sama_conai_dev.sh`

**Menu interactif** pour orchestrer tous les outils de développement.

```bash
# Mode interactif
./sama_conai_dev.sh

# Mode direct
./sama_conai_dev.sh start     # Démarrage complet
./sama_conai_dev.sh odoo      # Odoo seulement
./sama_conai_dev.sh mobile    # Mobile seulement
./sama_conai_dev.sh test      # Tests automatisés
./sama_conai_dev.sh monitor   # Monitoring
./sama_conai_dev.sh stop      # Arrêt
./sama_conai_dev.sh clean     # Nettoyage
```

### 2. Script de Lancement - `launch_sama_conai_test.sh`

**Script autonome** pour démarrer l'environnement de test complet.

```bash
# Démarrage complet
./launch_sama_conai_test.sh start

# Autres commandes
./launch_sama_conai_test.sh stop      # Arrêter les services
./launch_sama_conai_test.sh status    # Statut des services
./launch_sama_conai_test.sh test      # Exécuter les tests
./launch_sama_conai_test.sh logs      # Afficher les logs
./launch_sama_conai_test.sh clean     # Nettoyer l'environnement
./launch_sama_conai_test.sh restart   # Redémarrer
```

**Fonctionnalités:**
- ✅ Création automatique de base de données unique
- ✅ Installation et activation du module SAMA CONAI
- ✅ Démarrage d'Odoo avec configuration de test
- ✅ Démarrage de l'application mobile web
- ✅ Tests automatiques de connectivité
- ✅ Gestion des logs et PIDs
- ✅ Nettoyage automatique

### 3. Script Application Mobile - `mobile_app_web/launch_mobile.sh`

**Script spécialisé** pour l'application mobile web.

```bash
cd mobile_app_web

# Démarrage
./launch_mobile.sh start

# Autres commandes
./launch_mobile.sh stop       # Arrêter
./launch_mobile.sh status     # Statut
./launch_mobile.sh test       # Tests
./launch_mobile.sh logs       # Logs
./launch_mobile.sh restart    # Redémarrer
```

**Variables d'environnement:**
```bash
PORT=3005 ./launch_mobile.sh start
ODOO_URL=http://localhost:8075 ./launch_mobile.sh start
ODOO_DB=ma_base_test ./launch_mobile.sh start
```

### 4. Cycle de Tests - `scripts_temp/test_cycle.sh`

**Tests automatisés** avec cycle d'itération.

```bash
# Suite complète de tests
./scripts_temp/test_cycle.sh full

# Test unique
./scripts_temp/test_cycle.sh single

# Analyse des logs
./scripts_temp/test_cycle.sh logs

# Correction automatique
./scripts_temp/test_cycle.sh fix
```

**Processus:**
1. 🧹 Nettoyage de l'environnement
2. 🚀 Démarrage des services
3. 🧪 Exécution des tests
4. 📋 Analyse des logs
5. 🔧 Correction automatique si nécessaire
6. 🔄 Répétition jusqu'à succès

### 5. Monitoring - `scripts_temp/monitor.sh`

**Surveillance en temps réel** des services.

```bash
# Monitoring interactif
./scripts_temp/monitor.sh monitor

# Vérification unique
./scripts_temp/monitor.sh check

# Logs récents
./scripts_temp/monitor.sh logs

# Statut détaillé
./scripts_temp/monitor.sh status
```

**Interface de monitoring:**
- 📊 Statut des services en temps réel
- 💻 Utilisation des ressources (CPU, RAM)
- 🚨 Surveillance des erreurs
- 🌐 URLs d'accès
- ⌨️ Commandes interactives

## Cycle de Développement Recommandé

### 1. Démarrage Initial
```bash
# Démarrage complet avec menu
./sama_conai_dev.sh

# Ou démarrage direct
./launch_sama_conai_test.sh start
```

### 2. Tests et Validation
```bash
# Tests automatisés
./scripts_temp/test_cycle.sh full

# Monitoring en continu
./scripts_temp/monitor.sh monitor
```

### 3. Développement Itératif
```bash
# Après modification du code
./launch_sama_conai_test.sh restart

# Vérification rapide
./launch_sama_conai_test.sh test
```

### 4. Débogage
```bash
# Afficher les logs
./launch_sama_conai_test.sh logs

# Statut détaillé
./launch_sama_conai_test.sh status

# Monitoring en temps réel
./scripts_temp/monitor.sh monitor
```

### 5. Nettoyage
```bash
# Nettoyage complet
./launch_sama_conai_test.sh clean

# Ou via le menu principal
./sama_conai_dev.sh clean
```

## Gestion des Erreurs

### Erreurs Communes

**1. Port déjà utilisé**
```bash
# Les scripts arrêtent automatiquement les processus sur leurs ports
# Vérification manuelle:
lsof -i :8075
lsof -i :3005
```

**2. Base de données inaccessible**
```bash
# Vérifier PostgreSQL
sudo systemctl status postgresql
PGPASSWORD=odoo psql -h localhost -U odoo -d postgres -c "SELECT 1;"
```

**3. Module non installé**
```bash
# Le script réinstalle automatiquement le module
# Vérification manuelle dans les logs:
tail -f scripts_temp/logs/odoo_test.log | grep sama_conai
```

### Correction Automatique

Le script `test_cycle.sh` inclut des corrections automatiques:
- 🧹 Nettoyage des processus zombies
- 🔧 Correction des permissions
- 🗂️ Nettoyage des fichiers temporaires
- 🗄️ Vérification de la base de données

## Fichiers Temporaires

### Structure
```
scripts_temp/
├── logs/
│   ├── odoo_test.log           # Logs Odoo
│   ├── mobile_test.log         # Logs application mobile
│   └── monitor.log             # Logs monitoring
├── pids/
│   ├── odoo_test.pid           # PID Odoo
│   └── mobile_test.pid         # PID application mobile
└── .odoo_last_check            # Timestamp dernière vérification
```

### Nettoyage
```bash
# Suppression automatique
./launch_sama_conai_test.sh clean

# Suppression manuelle
rm -rf scripts_temp/
```

## URLs d'Accès

### Services
- **Odoo**: http://localhost:8075
- **Application Mobile**: http://localhost:3005

### Comptes de Test
- **Admin Odoo**: `admin` / `admin`
- **Demo Mobile**: `demo@sama-conai.sn` / `demo123`

## Monitoring et Logs

### Logs en Temps Réel
```bash
# Odoo
tail -f scripts_temp/logs/odoo_test.log

# Application Mobile
tail -f scripts_temp/logs/mobile_test.log

# Tous les logs
./scripts_temp/monitor.sh logs
```

### Surveillance des Ressources
```bash
# Monitoring interactif
./scripts_temp/monitor.sh monitor

# Vérification ponctuelle
./scripts_temp/monitor.sh check
```

## Personnalisation

### Variables d'Environnement
```bash
# Port Odoo personnalisé
TEST_PORT=8080 ./launch_sama_conai_test.sh start

# Port mobile personnalisé
PORT=3010 ./mobile_app_web/launch_mobile.sh start

# Base de données personnalisée
TEST_DB=ma_base ./launch_sama_conai_test.sh start
```

### Configuration Avancée
Modifiez les variables en début de chaque script:
- `TEST_PORT` - Port Odoo
- `MOBILE_PORT` - Port application mobile
- `DB_NAME` - Nom de la base de données
- `LOG_DIR` - Répertoire des logs

## Dépannage

### Problèmes Fréquents

**1. Script non exécutable**
```bash
chmod +x *.sh
chmod +x mobile_app_web/*.sh
chmod +x scripts_temp/*.sh
```

**2. Dépendances manquantes**
```bash
# Node.js pour l'application mobile
sudo apt install nodejs npm

# PostgreSQL
sudo apt install postgresql postgresql-contrib

# Outils système
sudo apt install curl lsof
```

**3. Permissions PostgreSQL**
```bash
# Créer l'utilisateur odoo si nécessaire
sudo -u postgres createuser -s odoo
sudo -u postgres psql -c "ALTER USER odoo PASSWORD 'odoo';"
```

### Support et Logs

En cas de problème:
1. Exécutez `./scripts_temp/test_cycle.sh full` pour un diagnostic complet
2. Consultez les logs dans `scripts_temp/logs/`
3. Utilisez le monitoring pour surveiller en temps réel
4. Nettoyez l'environnement avec `clean` et redémarrez

## Conclusion

Ces scripts offrent un environnement de développement complet et autonome pour SAMA CONAI:

- ✅ **Autonomie**: Chaque script peut fonctionner indépendamment
- ✅ **Isolation**: Utilisation de ports dédiés pour éviter les conflits
- ✅ **Automatisation**: Tests et corrections automatiques
- ✅ **Monitoring**: Surveillance en temps réel
- ✅ **Nettoyage**: Gestion propre des ressources temporaires

L'environnement est prêt pour un développement efficace et des tests itératifs du module SAMA CONAI.