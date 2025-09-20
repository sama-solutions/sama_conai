# SAMA CONAI - Transparence Sénégal

[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)
[![Odoo Version](https://img.shields.io/badge/Odoo-18.0-purple.svg)](https://www.odoo.com/)
[![Python Version](https://img.shields.io/badge/Python-3.8+-green.svg)](https://www.python.org/)

## 📋 Description

SAMA CONAI est un module Odoo 18 CE conçu pour assurer la conformité avec les lois sénégalaises sur l'accès à l'information publique et la protection des lanceurs d'alerte.

## 🚀 Fonctionnalités Principales

### 📄 Accès à l'Information
- **Gestion des demandes** d'accès à l'information publique
- **Workflow de traitement** et validation
- **Respect des délais légaux** (30 jours)
- **Interface Kanban** pour le suivi des demandes
- **Portail web** pour les citoyens

### 🛡️ Signalement d'Alerte
- **Protection des lanceurs d'alerte**
- **Signalement anonyme** sécurisé
- **Gestion confidentielle** des alertes
- **Suivi anonyme** via token
- **Workflow de traitement** des signalements

### 📊 Tableau de Bord de Transparence
- **Données en temps réel** extraites du backend
- **Statistiques de performance** et conformité
- **Graphiques interactifs** avec Chart.js
- **Interface responsive** Bootstrap 5
- **Actions utilisateur intégrées**

### 📱 Applications Mobiles
- **Application mobile** React Native
- **Interface web mobile** Node.js
- **Authentification JWT** sécurisée
- **Synchronisation** avec Odoo
- **Mode hors ligne** disponible

## 🔧 Installation

### 📦 Simple Odoo Module (Recommended)

**Quick Installation:**
```bash
# 1. Download to your Odoo addons directory
cd /path/to/your/odoo/custom_addons/
git clone https://github.com/sama-solutions/conai.git sama_conai

# 2. Restart Odoo
sudo systemctl restart odoo

# 3. Install via Odoo interface
# Apps → Update Apps List → Search "SAMA CONAI" → Install
```

**Detailed Guide:** See [INSTALLATION.md](INSTALLATION.md) for complete instructions.

### 🐳 Docker Deployment (Advanced)

**For containerized deployment:**
```bash
# 1. Clone repository
git clone https://github.com/sama-solutions/conai.git
cd conai

# 2. Configure environment
cp deployment/.env.example .env
# Edit .env with your settings

# 3. Deploy with Docker
cd deployment/docker
docker-compose up -d
```

**Docker Guide:** See [deployment/docker/DOCKER_README.md](deployment/docker/DOCKER_README.md) for container deployment.

### Prérequis
- **Odoo 18.0** Community or Enterprise Edition
- **Python 3.8+**
- **PostgreSQL 12+**
- **Docker** (only for containerized deployment)

### Dependencies
- **Core module**: No additional packages required
- **Mobile features**: `requests>=2.25.1` (recommended)
- **Full features**: See [DEPENDENCIES.md](DEPENDENCIES.md) for complete guide

## 📖 Documentation

### Installation Guides
- **[Simple Installation](INSTALLATION.md)** - Standard Odoo module installation
- **[Dependencies Guide](DEPENDENCIES.md)** - Complete dependency management
- **[Docker Deployment](deployment/docker/DOCKER_README.md)** - Containerized deployment

### User Documentation
La documentation complète est disponible dans le dossier `misc/documentation/` :

- **[Guide Utilisateur](misc/documentation/GUIDE_FINAL_SAMA_CONAI.md)** - Utilisation du module
- **[Guide Mobile](misc/documentation/MOBILE_APP_GUIDE.md)** - Applications mobiles
- **[Guide API](misc/documentation/GUIDE_DONNEES_REELLES_ODOO.md)** - Intégration API
- **[Guide Analytics](misc/documentation/GUIDE_ANALYSE_DONNEES.md)** - Tableaux de bord et analyses

## 🌐 URLs Principales

Après installation, les URLs suivantes sont disponibles :

- `/transparence-dashboard` - Tableau de bord principal
- `/acces-information` - Formulaire de demande d'information
- `/signalement-anonyme` - Formulaire de signalement anonyme
- `/transparence-dashboard/help` - Aide et contact

## 🏗️ Structure du Projet

```
sama_conai/
├── controllers/          # Contrôleurs web et API
├── models/              # Modèles de données
├── views/               # Vues XML
├── templates/           # Templates web
├── data/                # Données de base et démo
├── security/            # Sécurité et permissions
├── static/              # Assets CSS/JS
└── misc/                # Documentation et utilitaires
    ├── documentation/   # Documentation complète
    ├── backups/         # Sauvegardes
    ├── scripts/         # Scripts utilitaires
    ├── mobile_apps/     # Applications mobiles
    ├── config/          # Fichiers de configuration
    └── temp/            # Fichiers temporaires
```

## 🔒 Sécurité et Conformité

- **Conformité RGPD** - Protection des données personnelles
- **Anonymisation** des signalements
- **Chiffrement** des données sensibles
- **Audit trail** complet
- **Respect des délais légaux** sénégalais

## 🤝 Contribution

Les contributions sont les bienvenues ! Veuillez :

1. **Fork** le projet
2. **Créer une branche** pour votre fonctionnalité
3. **Commiter** vos changements
4. **Pousser** vers la branche
5. **Ouvrir une Pull Request**

## 📄 Licence

Ce projet est sous licence **LGPL-3.0**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🏢 À Propos

**SAMA CONAI** est développé par [SAMA Solutions](https://www.sama-solutions.com) pour promouvoir la transparence et la bonne gouvernance au Sénégal.

### Contact
- **Site web** : [https://www.sama-conai.sn](https://www.sama-conai.sn)
- **Email** : contact@sama-solutions.com
- **GitHub** : [https://github.com/sama-solutions](https://github.com/sama-solutions)

## 🌟 Fonctionnalités Avancées

### Version 3.0 (Actuelle)
- ✅ **Navigation dashboard complète** avec breadcrumbs
- ✅ **Données backend 100% réelles** extraites de la base
- ✅ **Actions utilisateur intégrées** (auth + public)
- ✅ **Templates autonomes** sans dépendance website
- ✅ **Interface moderne** Bootstrap 5
- ✅ **Formulaires publics fonctionnels** (HTTP 200)
- ✅ **API JSON** pour données en temps réel

### Roadmap
- 🔄 **Intégration IA** pour analyse automatique
- 🔄 **API REST** complète
- 🔄 **Notifications push** mobiles
- 🔄 **Rapports avancés** avec BI
- 🔄 **Multi-langues** (Français, Wolof, Anglais)

---

**Développé avec ❤️ pour la transparence au Sénégal**