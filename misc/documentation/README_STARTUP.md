# SAMA CONAI - Scripts de Démarrage

Ce répertoire contient les scripts de démarrage pour lancer l'écosystème complet SAMA CONAI.

## 🚀 Démarrage Rapide

### Démarrer SAMA CONAI
```bash
./start.sh
```

### Arrêter SAMA CONAI
```bash
./stop.sh
```

### Vérifier le statut
```bash
./startup_sama_conai.sh status
```

## 📋 Scripts Disponibles

### `startup_sama_conai.sh` - Script Principal
Script complet avec toutes les fonctionnalités :

```bash
# Démarrer tous les services
./startup_sama_conai.sh start

# Arrêter tous les services
./startup_sama_conai.sh stop

# Redémarrer tous les services
./startup_sama_conai.sh restart

# Afficher le statut des services
./startup_sama_conai.sh status

# Afficher l'aide
./startup_sama_conai.sh help
```

### `start.sh` - Démarrage Rapide
Script simplifié pour démarrer rapidement SAMA CONAI.

### `stop.sh` - Arrêt Rapide
Script simplifié pour arrêter rapidement SAMA CONAI.

## 🔧 Configuration

### Ports par Défaut
- **Odoo Backend** : `8077`
- **Application Mobile** : `3005`
- **Base de données** : `sama_conai_analytics`

### Répertoires
- **Logs** : `./logs/`
- **PIDs** : `./pids/`
- **Odoo** : `/var/odoo/odoo18`
- **Addons** : `/home/grand-as/psagsn/custom_addons`

## 📊 Monitoring

### Fichiers de Logs
- **Odoo** : `./logs/odoo.log`
- **Application Mobile** : `./logs/mobile.log`
- **Script de démarrage** : `./logs/startup.log`

### Vérification de Santé
```bash
# Vérifier qu'Odoo répond
curl http://localhost:8077/web/health

# Vérifier que l'application mobile répond
curl http://localhost:3005/
```

## 🌐 URLs d'Accès

Une fois démarré, SAMA CONAI est accessible via :

- **Backend Odoo** : http://localhost:8077
  - Utilisateur : `admin`
  - Mot de passe : `admin`

- **Application Mobile** : http://localhost:3005
  - Interface neumorphique avec vraies données
  - Authentification unifiée avec Odoo

## 🔍 Dépannage

### Vérifier les Processus
```bash
# Voir tous les processus SAMA CONAI
ps aux | grep -E "(odoo|node.*server.js)"

# Vérifier les ports utilisés
netstat -tlnp | grep -E "(8077|3005)"
```

### Logs en Temps Réel
```bash
# Suivre les logs Odoo
tail -f ./logs/odoo.log

# Suivre les logs de l'application mobile
tail -f ./logs/mobile.log

# Suivre les logs de démarrage
tail -f ./logs/startup.log
```

### Redémarrage Forcé
```bash
# Arrêter tous les processus liés
pkill -f "odoo-bin"
pkill -f "node.*server.js"

# Nettoyer les fichiers PID
rm -f ./pids/*.pid

# Redémarrer
./start.sh
```

## ⚠️ Prérequis

Avant d'utiliser les scripts, assurez-vous que :

1. **Python 3** est installé
2. **Node.js** est installé
3. **Odoo 18** est installé dans `/var/odoo/odoo18`
4. **Module SAMA CONAI** est présent dans `/home/grand-as/psagsn/custom_addons/sama_conai`
5. **Base de données** `sama_conai_analytics` existe et est configurée
6. **Permissions** d'exécution sur les scripts

## 🎯 Utilisation Typique

### Démarrage du Matin
```bash
cd /home/grand-as/psagsn/custom_addons/sama_conai
./start.sh
```

### Vérification Périodique
```bash
./startup_sama_conai.sh status
```

### Arrêt en Fin de Journée
```bash
./stop.sh
```

## 🔄 Mise à Jour

Après une mise à jour du code :
```bash
./startup_sama_conai.sh restart
```

## 📞 Support

En cas de problème :
1. Vérifiez les logs dans `./logs/`
2. Utilisez `./startup_sama_conai.sh status` pour diagnostiquer
3. Consultez la section dépannage ci-dessus