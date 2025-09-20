# SAMA CONAI - Résumé des Scripts de Lancement

## 📋 Scripts Créés

### 🎯 Scripts Principaux

| Script | Description | Usage |
|--------|-------------|-------|
| `sama_conai_dev.sh` | **Script principal avec menu interactif** | `./sama_conai_dev.sh` |
| `launch_sama_conai_test.sh` | **Script de lancement complet Odoo + Mobile** | `./launch_sama_conai_test.sh start` |
| `quick_test.sh` | **Démarrage rapide pour tests** | `./quick_test.sh` |

### 📱 Scripts Spécialisés

| Script | Description | Usage |
|--------|-------------|-------|
| `mobile_app_web/launch_mobile.sh` | **Application mobile standalone** | `./mobile_app_web/launch_mobile.sh start` |

### 🔧 Scripts Utilitaires (dans `scripts_temp/`)

| Script | Description | Usage |
|--------|-------------|-------|
| `test_cycle.sh` | **Cycle de tests automatisé** | `./scripts_temp/test_cycle.sh full` |
| `monitor.sh` | **Monitoring en temps réel** | `./scripts_temp/monitor.sh monitor` |
| `validate_setup.sh` | **Validation de l'environnement** | `./scripts_temp/validate_setup.sh` |

## 🚀 Démarrage Rapide

### Pour commencer immédiatement :
```bash
# Validation + Menu interactif
./quick_test.sh

# Ou directement le menu principal
./sama_conai_dev.sh

# Ou démarrage direct
./launch_sama_conai_test.sh start
```

## 🎯 Configuration Automatique

### ✅ Ce qui est géré automatiquement :
- **Ports dédiés** : 8075 (Odoo), 3005 (Mobile)
- **Base de données unique** : Création automatique avec timestamp
- **Arrêt des processus existants** : Sur les ports de test uniquement
- **Installation du module** : SAMA CONAI installé et activé automatiquement
- **Gestion des logs** : Dans `scripts_temp/logs/`
- **Fichiers PID** : Dans `scripts_temp/pids/`
- **Nettoyage automatique** : Suppression propre des ressources

### 🔧 Configuration requise :
- **Odoo** : `/var/odoo/odoo18`
- **Virtual Env** : `/home/grand-as/odoo18-venv`
- **Custom Addons** : `/home/grand-as/psagsn/custom_addons`
- **PostgreSQL** : User `odoo`, Password `odoo`

## 📊 Fonctionnalités Avancées

### 🔄 Cycle de Tests Automatisé
```bash
./scripts_temp/test_cycle.sh full
```
- Démarrage → Test → Analyse logs → Correction → Redémarrage
- Jusqu'à 5 cycles ou succès
- Corrections automatiques

### 📈 Monitoring en Temps Réel
```bash
./scripts_temp/monitor.sh monitor
```
- Statut des services en temps réel
- Utilisation CPU/RAM
- Surveillance des erreurs
- Interface interactive

### 🧪 Validation Complète
```bash
./scripts_temp/validate_setup.sh
```
- Vérification de tous les prérequis
- Tests de connectivité
- Validation des permissions
- Recommandations de correction

## 🎮 Commandes Principales

### Script Principal (`sama_conai_dev.sh`)
```bash
./sama_conai_dev.sh              # Menu interactif
./sama_conai_dev.sh start        # Démarrage complet
./sama_conai_dev.sh odoo         # Odoo seulement
./sama_conai_dev.sh mobile       # Mobile seulement
./sama_conai_dev.sh test         # Tests automatisés
./sama_conai_dev.sh monitor      # Monitoring
./sama_conai_dev.sh stop         # Arrêt
./sama_conai_dev.sh clean        # Nettoyage
```

### Script de Lancement (`launch_sama_conai_test.sh`)
```bash
./launch_sama_conai_test.sh start    # Démarrage
./launch_sama_conai_test.sh stop     # Arrêt
./launch_sama_conai_test.sh status   # Statut
./launch_sama_conai_test.sh test     # Tests
./launch_sama_conai_test.sh logs     # Logs
./launch_sama_conai_test.sh clean    # Nettoyage
./launch_sama_conai_test.sh restart  # Redémarrage
```

### Application Mobile (`mobile_app_web/launch_mobile.sh`)
```bash
./mobile_app_web/launch_mobile.sh start     # Démarrage
./mobile_app_web/launch_mobile.sh stop      # Arrêt
./mobile_app_web/launch_mobile.sh status    # Statut
./mobile_app_web/launch_mobile.sh test      # Tests
./mobile_app_web/launch_mobile.sh logs      # Logs
./mobile_app_web/launch_mobile.sh restart   # Redémarrage
```

## 🌐 URLs d'Accès

| Service | URL | Credentials |
|---------|-----|-------------|
| **Odoo** | http://localhost:8075 | admin / admin |
| **Mobile** | http://localhost:3005 | demo@sama-conai.sn / demo123 |

## 📁 Structure des Fichiers

```
sama_conai/
├── sama_conai_dev.sh                    # 🎯 Script principal
├── launch_sama_conai_test.sh           # 🚀 Lancement complet
├── quick_test.sh                       # ⚡ Démarrage rapide
├── mobile_app_web/
│   └── launch_mobile.sh                # 📱 Application mobile
├── scripts_temp/                       # 🗂️ Scripts temporaires
│   ├── test_cycle.sh                   # 🔄 Tests automatisés
│   ├── monitor.sh                      # 📊 Monitoring
│   ├── validate_setup.sh               # ✅ Validation
│   ├── logs/                           # 📋 Logs des services
│   └── pids/                           # 🔧 Fichiers PID
├── SCRIPTS_LANCEMENT_README.md         # 📖 Documentation complète
└── SCRIPTS_SUMMARY.md                  # 📋 Ce résumé
```

## 🔧 Cycle de Développement

### 1. **Validation Initiale**
```bash
./quick_test.sh
# ou
./scripts_temp/validate_setup.sh
```

### 2. **Démarrage pour Tests**
```bash
./sama_conai_dev.sh start
# ou
./launch_sama_conai_test.sh start
```

### 3. **Monitoring Continu**
```bash
./scripts_temp/monitor.sh monitor
```

### 4. **Tests Automatisés**
```bash
./scripts_temp/test_cycle.sh full
```

### 5. **Nettoyage**
```bash
./launch_sama_conai_test.sh clean
```

## 🛠️ Personnalisation

### Variables d'Environnement
```bash
# Port Odoo personnalisé
TEST_PORT=8080 ./launch_sama_conai_test.sh start

# Port mobile personnalisé  
PORT=3010 ./mobile_app_web/launch_mobile.sh start

# Base de données personnalisée
TEST_DB=ma_base ./launch_sama_conai_test.sh start
```

### Modification des Scripts
Les scripts sont conçus pour être modifiés facilement :
- Variables de configuration en début de fichier
- Fonctions modulaires
- Commentaires détaillés
- Gestion d'erreurs robuste

## 🎯 Avantages

### ✅ **Autonomie Complète**
- Chaque script fonctionne indépendamment
- Pas de dépendances externes complexes
- Configuration automatique

### ✅ **Isolation des Tests**
- Ports dédiés (8075, 3005)
- Base de données unique par test
- Pas d'interférence avec autres instances Odoo

### ✅ **Gestion Intelligente**
- Arrêt sélectif des processus (uniquement sur les ports de test)
- Nettoyage automatique des ressources
- Récupération d'erreurs

### ✅ **Monitoring Avancé**
- Surveillance en temps réel
- Détection automatique des erreurs
- Interface interactive

### ✅ **Tests Automatisés**
- Cycle complet de validation
- Corrections automatiques
- Rapports détaillés

## 🚨 Points d'Attention

### ⚠️ **Fichiers Temporaires**
- Le dossier `scripts_temp/` peut être supprimé après les tests
- Contient logs, PIDs et scripts utilitaires
- Recréé automatiquement si nécessaire

### ⚠️ **Bases de Données**
- Chaque test crée une nouvelle base avec timestamp
- Nettoyage automatique avec `clean`
- Vérifiez l'espace disque si nombreux tests

### ⚠️ **Processus**
- Les scripts arrêtent uniquement les processus sur leurs ports
- Autres instances Odoo non affectées
- Vérification des PIDs avant arrêt

## 🎉 Prêt pour les Tests !

L'environnement SAMA CONAI est maintenant équipé d'un système complet de scripts de lancement et de test. Vous pouvez :

1. **Commencer immédiatement** avec `./quick_test.sh`
2. **Développer de manière autonome** avec les scripts individuels
3. **Surveiller en temps réel** avec le monitoring
4. **Tester automatiquement** avec les cycles de validation
5. **Nettoyer proprement** après chaque session

**Bonne chance pour vos tests et développements ! 🇸🇳**