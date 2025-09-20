# 🚀 Guide de Démarrage - Application Mobile SAMA CONAI

## 📱 Démarrage Rapide

### 🎯 Commande Unique
```bash
./launch_mobile_complete.sh
```

Cette commande lance automatiquement :
- ✅ **Backend Odoo** (port 8077)
- ✅ **Application Mobile** (port 3005) 
- ✅ **Serveur Proxy** (port 8078)

### 🌐 Accès à l'Application

**URL principale :** http://localhost:3005

**Identifiants de test :**
- 👤 **Login :** admin
- 🔐 **Mot de passe :** admin

## 📱 Fonctionnalités de l'Application Mobile

### 🎨 Interface Neumorphique
- **4 thèmes disponibles :**
  - 🏛️ Institutionnel (par défaut)
  - 🌍 Terre du Sénégal
  - 🚀 Moderne
  - 🌙 Dark Mode

### 🔐 Authentification
- **Connexion sécurisée** avec le backend Odoo
- **Sessions persistantes** avec tokens JWT
- **Déconnexion propre**

### 📊 Tableau de Bord
- **Statistiques personnelles** en temps réel
- **Demandes récentes** avec statuts
- **Transparence publique** (statistiques globales)
- **Navigation intuitive** par niveaux

### 📋 Gestion des Demandes
- **Liste complète** de vos demandes
- **Détails complets** avec chronologie
- **Filtrage par statut** (Toutes, En cours, Répondues)
- **Création de nouvelles demandes**

### 🏠 Mon Espace
- **Vue d'ensemble** de votre activité
- **Accès rapide** aux fonctionnalités
- **Statistiques détaillées**

### 📊 Backend Intégré
- **Accès direct** au backend Odoo depuis l'app
- **Interface iframe** ou nouvel onglet
- **Réservé aux administrateurs**

## 🔧 Architecture Technique

### Frontend Mobile (Port 3005)
```
mobile_app_web/
├── server.js              # Serveur Express principal
├── odoo-api.js            # Client API Odoo
├── proxy_server.js        # Proxy pour iframe
├── public/index.html       # Interface neumorphique
└── package.json           # Dépendances Node.js
```

### Backend Odoo (Port 8077)
```
sama_conai/
├── controllers/mobile_api/     # API REST mobile
│   ├── mobile_auth_controller.py
│   ├── mobile_citizen_controller.py
│   └── mobile_notification_controller.py
├── models/                     # Modèles de données
└── views/                      # Vues administration
```

### API REST Disponibles
```
POST /api/mobile/auth/login           # Connexion
POST /api/mobile/auth/logout          # Déconnexion
GET  /api/mobile/citizen/dashboard    # Tableau de bord
GET  /api/mobile/citizen/requests     # Liste demandes
POST /api/mobile/citizen/requests     # Créer demande
GET  /api/mobile/citizen/requests/:id # Détail demande
```

## 🛠️ Gestion des Services

### ▶️ Démarrage
```bash
./launch_mobile_complete.sh
```

### 🛑 Arrêt
```bash
./stop_sama_conai_complete.sh
```

### 📋 Surveillance des Logs
```bash
# Logs application mobile
tail -f mobile_app_web/mobile_app.log

# Logs backend Odoo
tail -f .sama_conai_temp/logs/odoo-8077.log

# Logs proxy
tail -f mobile_app_web/proxy.log
```

### 🔄 Redémarrage
```bash
./stop_sama_conai_complete.sh
./launch_mobile_complete.sh
```

## 🌐 URLs d'Accès

| Service | URL | Description |
|---------|-----|-------------|
| **Application Mobile** | http://localhost:3005 | Interface principale |
| **Backend Odoo** | http://localhost:8077 | Administration complète |
| **Proxy Odoo** | http://localhost:8078 | Backend via proxy |

## 🔍 Dépannage

### ❌ Problème de Démarrage

1. **Vérifier les ports :**
```bash
netstat -tlnp | grep -E "(3005|8077|8078)"
```

2. **Arrêter les processus conflictuels :**
```bash
./stop_sama_conai_complete.sh
```

3. **Relancer :**
```bash
./launch_mobile_complete.sh
```

### ❌ Erreur de Connexion Odoo

1. **Vérifier le statut d'Odoo :**
```bash
curl -s http://localhost:8077/web/database/selector
```

2. **Vérifier les logs :**
```bash
tail -f .sama_conai_temp/logs/odoo-8077.log
```

3. **Redémarrer Odoo :**
```bash
./launch_sama_conai.sh --run -p 8077 -d sama_conai_test
```

### ❌ Application Mobile Non Accessible

1. **Vérifier Node.js :**
```bash
node --version
npm --version
```

2. **Réinstaller les dépendances :**
```bash
cd mobile_app_web
rm -rf node_modules
npm install
cd ..
```

3. **Redémarrer l'application :**
```bash
cd mobile_app_web
node server.js
```

## 📱 Utilisation de l'Application

### 1️⃣ Première Connexion
1. Ouvrir http://localhost:3005
2. Saisir : **admin** / **admin**
3. Cliquer sur "Se connecter"

### 2️⃣ Navigation
- **Dashboard** : Vue d'ensemble
- **Mon Espace** : Portail personnel
- **Mes Demandes** : Gestion des demandes
- **Nouvelle Demande** : Créer une demande

### 3️⃣ Changement de Thème
1. Cliquer sur l'icône 🎨 en bas à droite
2. Choisir un thème :
   - 🏛️ Institutionnel
   - 🌍 Terre du Sénégal
   - 🚀 Moderne
   - 🌙 Dark Mode

### 4️⃣ Accès Backend (Administrateurs)
1. Cliquer sur "📊 Backend" dans l'en-tête
2. L'interface Odoo s'ouvre dans l'application
3. Utiliser "✕ Fermer" pour revenir à l'app mobile

## 🔐 Sécurité

### 🛡️ Authentification
- **Tokens JWT** pour les sessions
- **Stockage sécurisé** des identifiants
- **Expiration automatique** des sessions

### 🔒 API
- **Authentification requise** pour toutes les API
- **Validation des permissions** côté serveur
- **Protection CORS** configurée

### 🚫 Restrictions
- **Backend accessible** aux administrateurs uniquement
- **Données utilisateur** isolées par session
- **Logs sécurisés** sans mots de passe

## 📊 Monitoring

### 📈 Métriques Disponibles
- **Connexions actives** par utilisateur
- **Demandes créées** via l'app mobile
- **Temps de réponse** des API
- **Erreurs de connexion** Odoo

### 📋 Logs Structurés
- **Authentifications** avec timestamps
- **Requêtes API** avec détails
- **Erreurs** avec stack traces
- **Performance** avec durées

## 🚀 Évolutions Futures

### 📱 Application Native
- **React Native** (code déjà préparé)
- **Notifications push** Firebase
- **Mode hors ligne** avec synchronisation
- **Géolocalisation** pour signalements

### 🔧 Fonctionnalités Avancées
- **Reconnaissance vocale** pour dictée
- **Upload de fichiers** pour preuves
- **Signature électronique** pour documents
- **Chat en temps réel** avec agents

### 🌍 Expansion
- **Multi-langues** (Français, Wolof, Anglais)
- **Multi-pays** adaptation
- **API publique** pour développeurs
- **Widgets** intégration sites web

## 📞 Support

### 🆘 En cas de problème
1. **Consulter les logs** (voir section Gestion)
2. **Vérifier la connectivité** réseau
3. **Redémarrer les services** si nécessaire
4. **Contacter l'équipe** technique

### 📧 Contact
- **Email :** support@sama-conai.sn
- **Documentation :** Voir les fichiers README_*.md
- **Issues :** Utiliser le système de tickets

---

## 🎉 Félicitations !

Vous avez maintenant une **application mobile SAMA CONAI** complètement fonctionnelle avec :

✅ **Interface neumorphique moderne**  
✅ **Authentification sécurisée avec Odoo**  
✅ **API REST complète**  
✅ **Gestion des demandes en temps réel**  
✅ **Accès backend intégré**  
✅ **Architecture évolutive**  

**🌐 Accédez maintenant à http://localhost:3005 pour découvrir l'application !**

---

*Guide créé le 2025-09-07 - SAMA CONAI Mobile v1.0*