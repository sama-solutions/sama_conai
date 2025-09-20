# 🚀 SAMA CONAI - Scripts de Démarrage du Stack (Sans Docker)

Ce document explique comment utiliser les nouveaux scripts de démarrage pour lancer tout le stack SAMA CONAI avec votre configuration existante.

## 📋 Vue d'ensemble

Votre stack SAMA CONAI comprend :
- **PostgreSQL** : Base de données
- **Odoo 18** : ERP et backend principal (port 8077)
- **Application Mobile Web** : Interface web mobile Node.js (port 3005)

## 🎯 Scripts Disponibles

### 1. Configuration Initiale (Une seule fois)
```bash
./setup_stack.sh
```
- Configure l'environnement automatiquement
- Crée les répertoires nécessaires (.pids, logs, backups)
- Installe les dépendances npm si nécessaire
- Rend tous les scripts exécutables

### 2. Démarrage Complet du Stack (NOUVEAU - Recommandé)
```bash
./startup_sama_conai_stack.sh
```
**Script principal qui démarre tout automatiquement :**
- Vérifie tous les prérequis
- Démarre PostgreSQL si nécessaire
- Démarre Odoo sur le port 8077
- Démarre l'application mobile sur le port 3005
- Surveille les services et affiche les statuts

**Commandes disponibles :**
```bash
./startup_sama_conai_stack.sh start    # Démarrer tout (défaut)
./startup_sama_conai_stack.sh stop     # Arrêter tous les services
./startup_sama_conai_stack.sh restart  # Redémarrer tout
./startup_sama_conai_stack.sh status   # Voir le statut de tous les services
./startup_sama_conai_stack.sh logs     # Voir les logs récents
./startup_sama_conai_stack.sh test     # Tester la connectivité
./startup_sama_conai_stack.sh help     # Aide complète
```

### 3. Scripts Existants (Toujours Fonctionnels)
```bash
./start_mobile_final.sh              # Application mobile uniquement
./launch_sama_conai.sh               # Odoo avec options avancées
./start_sama_conai.sh                # Odoo simple
```

## 🚀 Démarrage Rapide

### Première utilisation
```bash
# 1. Configuration (une seule fois)
./setup_stack.sh

# 2. Démarrage du stack complet
./startup_sama_conai_stack.sh
```

### Utilisation quotidienne
```bash
# Démarrer tout le stack
./startup_sama_conai_stack.sh

# Arrêter tout (dans un autre terminal)
./startup_sama_conai_stack.sh stop

# Voir le statut
./startup_sama_conai_stack.sh status
```

## 🌐 Accès aux Services

Une fois démarré, les services sont accessibles :

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Odoo** | http://localhost:8077 | admin / admin |
| **Mobile Web** | http://localhost:3005 | admin / admin ou demo@sama-conai.sn / demo123 |
| **PostgreSQL** | localhost:5432 | odoo / odoo |

## 📊 Surveillance et Logs

### Logs en temps réel
```bash
# Tous les logs récents
./startup_sama_conai_stack.sh logs

# Logs Odoo uniquement
tail -f logs/odoo.log

# Logs Mobile uniquement
tail -f logs/mobile.log
```

### Statut des services
```bash
./startup_sama_conai_stack.sh status
```

### Tests de connectivité
```bash
./startup_sama_conai_stack.sh test
```

## 🔧 Configuration

Le script utilise votre configuration existante :

```bash
# Chemins (détectés automatiquement)
ODOO_PATH="/var/odoo/odoo18"
VENV_DIR="/home/grand-as/odoo18-venv"
ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

# Base de données
DB_NAME="sama_conai_test"
DB_USER="odoo"
DB_PASSWORD="odoo"

# Ports (compatibles avec vos scripts existants)
ODOO_PORT="8077"    # Comme dans start_mobile_final.sh
MOBILE_PORT="3005"  # Comme dans start_mobile_final.sh
POSTGRES_PORT="5432"
```

## 🔄 Comparaison avec vos Scripts Existants

### Avant (Scripts séparés)
```bash
# Démarrer Odoo
./start_sama_conai.sh

# Dans un autre terminal, démarrer l'application mobile
./start_mobile_final.sh
```

### Maintenant (Script unifié)
```bash
# Démarrer tout en une commande
./startup_sama_conai_stack.sh
```

## 🛠️ Avantages du Nouveau Script

1. **Démarrage automatique** : Tout se lance en une commande
2. **Vérifications intelligentes** : Détecte les problèmes avant le démarrage
3. **Gestion des dépendances** : Vérifie et installe automatiquement
4. **Surveillance** : Surveille les services et redémarre si nécessaire
5. **Logs centralisés** : Tous les logs dans un endroit
6. **Arrêt propre** : Arrête tous les services correctement
7. **Compatible** : Utilise votre configuration existante

## 🔧 Dépannage

### Problèmes courants

#### 1. Ports occupés
Le script détecte automatiquement les ports occupés et propose de les libérer.

#### 2. PostgreSQL ne démarre pas
```bash
# Vérifier le statut
sudo systemctl status postgresql

# Démarrer manuellement
sudo systemctl start postgresql
```

#### 3. Environnement virtuel non trouvé
Vérifiez que l'environnement virtuel existe :
```bash
ls -la /home/grand-as/odoo18-venv/bin/activate
```

#### 4. Dépendances npm manquantes
```bash
cd mobile_app_web
npm install
```

### Nettoyage complet
```bash
# Arrêter tous les services
./startup_sama_conai_stack.sh stop

# Nettoyer les fichiers temporaires
rm -rf .pids/* logs/*
```

## 📁 Structure des Fichiers

```
sama_conai/
├── startup_sama_conai_stack.sh       # NOUVEAU: Script principal
├── setup_stack.sh                    # NOUVEAU: Configuration
├── start_mobile_final.sh             # EXISTANT: Mobile uniquement
├── launch_sama_conai.sh              # EXISTANT: Odoo avancé
├── start_sama_conai.sh               # EXISTANT: Odoo simple
├── .pids/                            # NOUVEAU: Fichiers PID
│   ├── odoo.pid
│   └── mobile.pid
├── logs/                             # NOUVEAU: Logs centralisés
│   ├── odoo.log
│   └── mobile.log
└── mobile_app_web/                   # EXISTANT: Application mobile
    ├── server.js
    ├── package.json
    └── ...
```

## 🎯 Recommandations

### Pour le développement quotidien
```bash
# Utilisez le nouveau script unifié
./startup_sama_conai_stack.sh
```

### Pour des tests spécifiques
```bash
# Utilisez vos scripts existants si nécessaire
./start_mobile_final.sh              # Mobile uniquement
./launch_sama_conai.sh --dev         # Odoo en mode développement
```

### Pour la production
```bash
# Le script unifié avec surveillance
./startup_sama_conai_stack.sh
```

## 🆘 Support

En cas de problème :

1. **Vérifiez les logs** : `./startup_sama_conai_stack.sh logs`
2. **Testez les services** : `./startup_sama_conai_stack.sh test`
3. **Vérifiez le statut** : `./startup_sama_conai_stack.sh status`
4. **Consultez l'aide** : `./startup_sama_conai_stack.sh help`
5. **Revenez aux scripts existants** si nécessaire

---

## 🇸🇳 SAMA CONAI - Transparence Numérique du Sénégal

**Le nouveau script unifié simplifie le démarrage tout en préservant la compatibilité avec vos scripts existants.**

Pour plus d'informations, consultez la documentation complète dans le répertoire `docs/`.