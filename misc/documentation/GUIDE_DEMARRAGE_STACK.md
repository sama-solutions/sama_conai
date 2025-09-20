# 🚀 SAMA CONAI - Guide de Démarrage du Stack Complet

## 📋 Résumé Rapide

Vous avez maintenant **4 options** pour démarrer SAMA CONAI :

### 🎯 Option 1 : Démarrage Unifié (RECOMMANDÉ)
```bash
./startup_sama_conai_stack.sh
```
**Le plus complet** - Démarre tout automatiquement avec surveillance

### 🎯 Option 2 : Démarrage Rapide
```bash
./start_all.sh
```
**Le plus simple** - Utilise vos scripts existants en arrière-plan

### 🎯 Option 3 : Scripts Séparés (EXISTANT)
```bash
# Terminal 1
./start_sama_conai.sh

# Terminal 2  
./start_mobile_final.sh
```
**Vos scripts actuels** - Contrôle manuel de chaque service

### 🎯 Option 4 : Test et Configuration
```bash
./test_stack.sh        # Tester l'environnement
./setup_stack.sh       # Configurer l'environnement
```

## 🚀 Démarrage en 3 Étapes

### Étape 1 : Configuration (première fois seulement)
```bash
./setup_stack.sh
```

### Étape 2 : Test (optionnel)
```bash
./test_stack.sh
```

### Étape 3 : Démarrage
```bash
# Option recommandée
./startup_sama_conai_stack.sh

# OU option simple
./start_all.sh
```

## 🌐 Accès aux Services

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Odoo** | http://localhost:8077 | admin / admin |
| **Mobile** | http://localhost:3005 | admin / admin |
| **Mobile Demo** | http://localhost:3005 | demo@sama-conai.sn / demo123 |

## 📊 Gestion des Services

### Voir le statut
```bash
./startup_sama_conai_stack.sh status
```

### Voir les logs
```bash
./startup_sama_conai_stack.sh logs
```

### Arrêter tout
```bash
./startup_sama_conai_stack.sh stop
```

### Redémarrer
```bash
./startup_sama_conai_stack.sh restart
```

## 🔧 Scripts Créés

| Script | Description | Usage |
|--------|-------------|-------|
| `startup_sama_conai_stack.sh` | **Principal** - Démarrage complet avec surveillance | `./startup_sama_conai_stack.sh` |
| `start_all.sh` | **Simple** - Utilise vos scripts existants | `./start_all.sh` |
| `setup_stack.sh` | **Configuration** - Prépare l'environnement | `./setup_stack.sh` |
| `test_stack.sh` | **Test** - Vérifie l'environnement | `./test_stack.sh` |

## 🛠️ Scripts Existants (Préservés)

| Script | Description | Usage |
|--------|-------------|-------|
| `start_mobile_final.sh` | Application mobile uniquement | `./start_mobile_final.sh` |
| `launch_sama_conai.sh` | Odoo avec options avancées | `./launch_sama_conai.sh --dev` |
| `start_sama_conai.sh` | Odoo simple | `./start_sama_conai.sh` |

## 🎯 Recommandations par Cas d'Usage

### 👨‍💻 Développement Quotidien
```bash
./startup_sama_conai_stack.sh
```
- Démarrage automatique
- Surveillance des services
- Logs centralisés
- Arrêt propre

### 🚀 Démarrage Rapide
```bash
./start_all.sh
```
- Utilise vos scripts existants
- Démarrage en arrière-plan
- Simple et efficace

### 🔧 Tests et Développement Spécialisé
```bash
./launch_sama_conai.sh --dev    # Odoo en mode développement
./start_mobile_final.sh         # Mobile uniquement
```

### 🧪 Diagnostic et Test
```bash
./test_stack.sh                 # Vérifier l'environnement
./setup_stack.sh                # Configurer si nécessaire
```

## 📁 Nouvelle Structure

```
sama_conai/
├── 🆕 startup_sama_conai_stack.sh    # Script principal unifié
├── 🆕 start_all.sh                   # Démarrage rapide
├── 🆕 setup_stack.sh                 # Configuration
├── 🆕 test_stack.sh                  # Tests
├── 🆕 .pids/                         # Fichiers PID
├── 🆕 logs/                          # Logs centralisés
├── ✅ start_mobile_final.sh          # Vos scripts existants
├── ✅ launch_sama_conai.sh           # (préservés)
├── ✅ start_sama_conai.sh            # 
└── ✅ mobile_app_web/                # Application mobile
```

## 🔄 Migration depuis vos Scripts Actuels

### Avant
```bash
# Terminal 1
./start_sama_conai.sh

# Terminal 2
./start_mobile_final.sh
```

### Maintenant
```bash
# Une seule commande
./startup_sama_conai_stack.sh

# OU
./start_all.sh
```

## 🆘 Dépannage Rapide

### Problème : Ports occupés
```bash
# Le script détecte et propose des solutions automatiquement
./startup_sama_conai_stack.sh
```

### Problème : Dépendances manquantes
```bash
./setup_stack.sh
```

### Problème : Services ne démarrent pas
```bash
./test_stack.sh
./startup_sama_conai_stack.sh logs
```

### Problème : Revenir à l'ancien système
```bash
# Vos scripts existants fonctionnent toujours
./start_sama_conai.sh
./start_mobile_final.sh
```

## 🎉 Avantages des Nouveaux Scripts

✅ **Compatibilité** : Vos scripts existants fonctionnent toujours  
✅ **Simplicité** : Une commande pour tout démarrer  
✅ **Surveillance** : Détection automatique des problèmes  
✅ **Logs** : Centralisation et facilité de consultation  
✅ **Flexibilité** : Plusieurs options selon vos besoins  
✅ **Robustesse** : Gestion des erreurs et récupération  

## 🇸🇳 SAMA CONAI - Transparence Numérique du Sénégal

**Votre plateforme de transparence est maintenant plus facile à démarrer et à gérer !**

---

### 💡 Conseil Final

**Pour commencer immédiatement :**
```bash
./setup_stack.sh && ./startup_sama_conai_stack.sh
```

**Pour un démarrage simple :**
```bash
./start_all.sh
```

**Pour continuer comme avant :**
```bash
./start_sama_conai.sh    # Terminal 1
./start_mobile_final.sh  # Terminal 2
```