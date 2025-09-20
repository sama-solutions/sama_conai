# 📱 SAMA CONAI Mobile App

## 🎯 Vue d'ensemble

Application mobile React Native pour SAMA CONAI permettant aux citoyens et agents publics d'interagir avec le système de transparence sénégalais.

## 🚀 Fonctionnalités

### 👥 Pour les Citoyens
- **Authentification** : Inscription et connexion sécurisées
- **Demandes d'information** : Créer et suivre les demandes d'accès à l'information
- **Signalements anonymes** : Créer des signalements d'alerte anonymes
- **Suivi en temps réel** : Suivre l'état des demandes et signalements
- **Notifications push** : Recevoir des mises à jour importantes
- **Tableau de bord** : Vue d'ensemble des activités personnelles

### 🏛️ Pour les Agents Publics
- **Gestion des tâches** : Voir et traiter les demandes assignées
- **Workflow mobile** : Traiter les demandes d'information en mobilité
- **Gestion des alertes** : Traiter les signalements d'alerte
- **Notifications intelligentes** : Recevoir des alertes pour les tâches urgentes
- **Rapports mobiles** : Accéder aux statistiques et rapports
- **Collaboration** : Communiquer avec l'équipe

## 🏗️ Architecture

```
mobile_app/
├── src/
│   ├── components/          # Composants réutilisables
│   ├── screens/            # Écrans de l'application
│   │   ├── auth/           # Authentification
│   │   ├── citizen/        # Interface citoyen
│   │   └── agent/          # Interface agent
│   ├── services/           # Services API
│   ├── navigation/         # Navigation
│   ├── utils/             # Utilitaires
│   └── assets/            # Ressources
├── android/               # Code Android natif
├── ios/                   # Code iOS natif
└── package.json          # Dépendances
```

## 🛠️ Technologies

- **React Native** : Framework mobile cross-platform
- **TypeScript** : Typage statique
- **React Navigation** : Navigation
- **Redux Toolkit** : Gestion d'état
- **React Query** : Gestion des données
- **Firebase** : Notifications push
- **AsyncStorage** : Stockage local
- **React Hook Form** : Gestion des formulaires

## 📋 Prérequis

- Node.js 16+
- React Native CLI
- Android Studio (pour Android)
- Xcode (pour iOS)
- Java 11+

## 🚀 Installation

```bash
# Cloner le projet
cd mobile_app

# Installer les dépendances
npm install

# iOS uniquement
cd ios && pod install && cd ..

# Lancer sur Android
npx react-native run-android

# Lancer sur iOS
npx react-native run-ios
```

## 🔧 Configuration

### Variables d'environnement

Créer un fichier `.env` :

```env
# API Backend
API_BASE_URL=http://localhost:8077
API_TIMEOUT=30000

# Firebase
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_PROJECT_ID=sama-conai-mobile
FIREBASE_MESSAGING_SENDER_ID=your_sender_id

# App Configuration
APP_NAME=SAMA CONAI
APP_VERSION=1.0.0
ENVIRONMENT=development
```

### Configuration Firebase

1. Créer un projet Firebase
2. Ajouter les applications Android et iOS
3. Télécharger les fichiers de configuration :
   - `google-services.json` pour Android
   - `GoogleService-Info.plist` pour iOS
4. Configurer les notifications push

## 📱 Écrans Principaux

### Authentification
- **Login** : Connexion utilisateur
- **Register** : Inscription citoyen
- **ForgotPassword** : Réinitialisation mot de passe

### Interface Citoyen
- **CitizenDashboard** : Tableau de bord personnel
- **CreateRequest** : Créer une demande d'information
- **MyRequests** : Mes demandes
- **RequestDetail** : Détail d'une demande
- **CreateAlert** : Créer un signalement
- **TrackAlert** : Suivre un signalement anonyme
- **Notifications** : Notifications personnelles

### Interface Agent
- **AgentDashboard** : Tableau de bord agent
- **TaskList** : Liste des tâches
- **ProcessRequest** : Traiter une demande
- **ManageAlert** : Gérer une alerte
- **Reports** : Rapports et statistiques
- **Settings** : Paramètres

## 🔔 Notifications Push

### Types de notifications
- **Demandes d'information** : Nouvelles assignations, mises à jour
- **Alertes** : Nouveaux signalements, changements de priorité
- **Échéances** : Rappels avant expiration
- **Système** : Mises à jour importantes

### Configuration
- Préférences par type de notification
- Heures silencieuses
- Priorités personnalisées

## 🔐 Sécurité

- **Authentification JWT** : Tokens sécurisés
- **Chiffrement** : Communications HTTPS
- **Stockage sécurisé** : Keychain/Keystore
- **Anonymat** : Protection des lanceurs d'alerte
- **Permissions** : Contrôle d'accès granulaire

## 🧪 Tests

```bash
# Tests unitaires
npm test

# Tests d'intégration
npm run test:integration

# Tests E2E
npm run test:e2e
```

## 📦 Build et Déploiement

### Android
```bash
# Build debug
npx react-native run-android

# Build release
cd android
./gradlew assembleRelease
```

### iOS
```bash
# Build debug
npx react-native run-ios

# Build release
# Utiliser Xcode pour l'archive et la distribution
```

## 🔄 Intégration API

L'application communique avec le module Odoo via les endpoints :

- `/api/mobile/auth/*` - Authentification
- `/api/mobile/citizen/*` - Fonctionnalités citoyen
- `/api/mobile/agent/*` - Fonctionnalités agent
- `/api/mobile/notifications/*` - Notifications

## 📊 Monitoring

- **Crashlytics** : Suivi des crashes
- **Analytics** : Utilisation de l'app
- **Performance** : Métriques de performance
- **Logs** : Journalisation centralisée

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature
3. Commiter les changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence LGPL-3 - voir le fichier LICENSE pour plus de détails.

## 📞 Support

- **Email** : support@sama-conai.sn
- **Documentation** : [docs.sama-conai.sn](https://docs.sama-conai.sn)
- **Issues** : GitHub Issues