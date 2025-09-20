# 🚀 SAMA CONAI - Scripts de Démarrage du Stack Complet

Ce document explique comment utiliser les scripts de démarrage pour lancer tout le stack SAMA CONAI.

## 📋 Vue d'ensemble

Le stack SAMA CONAI comprend :
- **PostgreSQL** : Base de données
- **Odoo 18** : ERP et backend principal
- **Application Mobile Web** : Interface web mobile (Node.js/Express)
- **Application React Native** : Application mobile native (préparation)

## 🎯 Scripts Disponibles

### 1. Configuration Rapide
```bash
./quick_setup.sh
```
- Configure l'environnement automatiquement
- Crée les répertoires nécessaires
- Génère le fichier `config.env`
- Rend les scripts exécutables

### 2. Démarrage Complet (Recommandé)
```bash
./startup_sama_conai_complete.sh
```
**Script principal avec toutes les fonctionnalités :**
- Vérification complète des prérequis
- Démarrage intelligent des services
- Surveillance et monitoring
- Gestion des erreurs avancée
- Tests de connectivité

**Commandes disponibles :**
```bash
./startup_sama_conai_complete.sh start    # Démarrer (défaut)
./startup_sama_conai_complete.sh stop     # Arrêter
./startup_sama_conai_complete.sh restart  # Redémarrer
./startup_sama_conai_complete.sh status   # Statut
./startup_sama_conai_complete.sh logs     # Logs
./startup_sama_conai_complete.sh test     # Tests
./startup_sama_conai_complete.sh help     # Aide
```

### 3. Démarrage Rapide
```bash
./start_stack.sh
```
- Script simplifié pour démarrage rapide
- Exécute automatiquement la configuration si nécessaire
- Redirige vers le script principal

### 4. Démarrage Docker
```bash
./start_docker_stack.sh
```
**Pour les utilisateurs Docker :**
- Utilise Docker Compose
- Isolation complète des services
- Configuration automatique
- Gestion des volumes et réseaux

**Commandes Docker :**
```bash
./start_docker_stack.sh up       # Démarrer
./start_docker_stack.sh down     # Arrêter
./start_docker_stack.sh restart  # Redémarrer
./start_docker_stack.sh logs     # Logs temps réel
./start_docker_stack.sh status   # Statut conteneurs
./start_docker_stack.sh clean    # Nettoyage complet
```

## ⚙️ Configuration

### Fichier config.env
Le fichier `config.env` contient toute la configuration :

```bash
# Chemins
ODOO_PATH="/var/odoo/odoo18"
ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

# Base de données
DB_NAME="sama_conai_production"

# Ports
ODOO_PORT="8069"
MOBILE_WEB_PORT="3001"

# Logs et timeouts
LOG_LEVEL="info"
STARTUP_TIMEOUT="120"
SHUTDOWN_TIMEOUT="15"
```

### Personnalisation
Modifiez `config.env` selon vos besoins :
- Changez les ports si nécessaire
- Ajustez les chemins selon votre installation
- Modifiez les timeouts selon votre matériel

## 🚀 Démarrage Rapide

### Première utilisation
```bash
# 1. Configuration automatique
./quick_setup.sh

# 2. Démarrage du stack
./start_stack.sh
```

### Utilisation quotidienne
```bash
# Démarrer
./startup_sama_conai_complete.sh

# Arrêter (dans un autre terminal)
./startup_sama_conai_complete.sh stop

# Voir le statut
./startup_sama_conai_complete.sh status
```

### Avec Docker
```bash
# Démarrer avec Docker
./start_docker_stack.sh

# Arrêter
./start_docker_stack.sh down

# Voir les logs
./start_docker_stack.sh logs
```

## 🌐 Accès aux Services

Une fois démarré, les services sont accessibles :

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Odoo** | http://localhost:8069 | admin / admin |
| **Mobile Web** | http://localhost:3001 | demo@sama-conai.sn / demo123 |
| **PostgreSQL** | localhost:5432 | odoo / odoo |

## 📊 Surveillance et Logs

### Logs en temps réel
```bash
# Tous les logs
./startup_sama_conai_complete.sh logs

# Logs Odoo uniquement
tail -f logs/odoo.log

# Logs Mobile Web
tail -f logs/mobile_web.log
```

### Statut des services
```bash
./startup_sama_conai_complete.sh status
```

### Tests de connectivité
```bash
./startup_sama_conai_complete.sh test
```

## 🔧 Dépannage

### Problèmes courants

#### 1. Ports occupés
```bash
# Vérifier les ports utilisés
lsof -i :8069
lsof -i :3001

# Le script propose automatiquement des solutions
```

#### 2. PostgreSQL ne démarre pas
```bash
# Vérifier le statut
sudo systemctl status postgresql

# Démarrer manuellement
sudo systemctl start postgresql
```

#### 3. Odoo ne démarre pas
```bash
# Vérifier les logs
tail -f logs/odoo.log

# Vérifier les dépendances Python
pip3 install -r requirements.txt
```

#### 4. Permissions insuffisantes
```bash
# Donner les permissions
chmod +w /home/grand-as/psagsn/custom_addons/sama_conai
chmod +x *.sh
```

### Nettoyage complet
```bash
# Arrêter tous les services
./startup_sama_conai_complete.sh stop

# Nettoyer les fichiers temporaires
rm -rf .pids/* logs/*

# Avec Docker
./start_docker_stack.sh clean
```

## 📁 Structure des Fichiers

```
sama_conai/
├── startup_sama_conai_complete.sh    # Script principal
├── start_stack.sh                    # Démarrage rapide
├── start_docker_stack.sh             # Version Docker
├── quick_setup.sh                    # Configuration
├── config.env                        # Configuration
├── docker-compose-complete.yml       # Docker Compose
├── .pids/                            # Fichiers PID
├── logs/                             # Logs des services
│   ├── odoo.log
│   ├── mobile_web.log
│   └── startup.log
└── backups/                          # Sauvegardes
```

## 🔄 Mise à jour

Pour mettre à jour les scripts :
```bash
# Sauvegarder la configuration
cp config.env config.env.backup

# Récupérer les nouveaux scripts
git pull

# Restaurer la configuration
cp config.env.backup config.env

# Reconfigurer si nécessaire
./quick_setup.sh
```

## 🆘 Support

En cas de problème :

1. **Vérifiez les logs** : `./startup_sama_conai_complete.sh logs`
2. **Testez les services** : `./startup_sama_conai_complete.sh test`
3. **Vérifiez le statut** : `./startup_sama_conai_complete.sh status`
4. **Consultez l'aide** : `./startup_sama_conai_complete.sh help`

## 🎯 Fonctionnalités Avancées

### Surveillance automatique
Le script principal surveille automatiquement les services et redémarre en cas de problème.

### Configuration flexible
Tous les paramètres sont configurables via `config.env`.

### Support multi-environnement
- Développement local
- Production avec Docker
- Déploiement cloud

### Sécurité
- Vérification des permissions
- Validation des prérequis
- Gestion sécurisée des processus

---

## 🇸🇳 SAMA CONAI - Transparence Numérique du Sénégal

**Plateforme de transparence et de gouvernance numérique pour la République du Sénégal**

Pour plus d'informations, consultez la documentation complète dans le répertoire `docs/`.