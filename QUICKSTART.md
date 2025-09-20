# 🚀 Guide de Démarrage Rapide - SAMA CONAI

Bienvenue dans **SAMA CONAI** ! Ce guide vous permettra de démarrer rapidement avec notre système d'accès moderne à l'information pour l'administration publique sénégalaise.

## 🎯 Aperçu Rapide

**SAMA CONAI** est une plateforme complète qui permet :
- 👥 **Aux citoyens** : Soumettre et suivre leurs demandes d'accès à l'information
- 🏛️ **Aux agents publics** : Gérer efficacement les demandes reçues
- 📊 **Aux superviseurs** : Analyser les performances et générer des rapports

## ⚡ Installation Express (5 minutes)

### Prérequis
- Python 3.8+ installé
- Git installé
- 4 GB RAM minimum
- 10 GB espace disque

### Installation en Une Commande
```bash
# Cloner et installer SAMA CONAI
curl -sSL https://raw.githubusercontent.com/votre-org/sama_conai/main/install.sh | bash
```

### Installation Manuelle
```bash
# 1. Cloner le repository
git clone https://github.com/votre-org/sama_conai.git
cd sama_conai

# 2. Installer les dépendances
pip install -r requirements.txt

# 3. Configurer la base de données
python manage.py migrate

# 4. Créer un superutilisateur
python manage.py createsuperuser

# 5. Lancer le serveur
python manage.py runserver
```

### Accès Rapide
- **Application** : http://localhost:8000
- **Administration** : http://localhost:8000/admin
- **Formation** : http://localhost:8000/formation

## 🎓 Premiers Pas

### 1. Interface Citoyen (2 minutes)
1. Aller sur http://localhost:8000
2. Cliquer sur "Nouvelle Demande"
3. Remplir le formulaire de demande
4. Suivre le statut en temps réel

### 2. Interface Agent (3 minutes)
1. Se connecter à l'administration
2. Aller dans "Gestion des Demandes"
3. Traiter une demande en attente
4. Générer une réponse

### 3. Formation Intégrée (10 minutes)
1. Accéder à http://localhost:8000/formation
2. Choisir votre rôle (Citoyen/Agent)
3. Commencer le Module 1
4. Suivre les leçons interactives

## 🔧 Configuration Rapide

### Variables d'Environnement
Créer un fichier `.env` :
```bash
# Base de données
DATABASE_URL=postgresql://user:password@localhost/sama_conai

# Sécurité
SECRET_KEY=votre-clé-secrète-très-longue-et-complexe
DEBUG=False

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=votre-email@gmail.com
EMAIL_HOST_PASSWORD=votre-mot-de-passe

# Sénégal spécifique
TIMEZONE=Africa/Dakar
LANGUAGE_CODE=fr-sn
```

### Configuration Odoo (Optionnel)
```bash
# Si vous utilisez Odoo
./odoo-bin -d sama_conai -i sama_conai --stop-after-init
./odoo-bin -d sama_conai
```

## 📱 Test Mobile

### PWA (Progressive Web App)
1. Ouvrir http://localhost:8000 sur mobile
2. Ajouter à l'écran d'accueil
3. Utiliser comme une app native

### Test Responsive
```bash
# Tester différentes tailles d'écran
# Mobile : 375x667
# Tablette : 768x1024
# Desktop : 1920x1080
```

## 🧪 Tests Rapides

### Tests Automatisés
```bash
# Tests complets
python manage.py test

# Tests spécifiques
python manage.py test apps.requests.tests
```

### Tests Manuels
1. **Soumission de demande** : Tester le workflow complet
2. **Notifications** : Vérifier les emails/SMS
3. **Rapports** : Générer des statistiques
4. **Mobile** : Tester sur smartphone

## 📊 Données de Démonstration

### Charger des Données d'Exemple
```bash
# Charger les données de démo
python manage.py loaddata demo_data.json

# Créer des utilisateurs de test
python manage.py create_demo_users
```

### Comptes de Test
- **Citoyen** : citoyen@test.sn / password123
- **Agent** : agent@test.sn / password123
- **Superviseur** : superviseur@test.sn / password123

## 🎯 Cas d'Usage Rapides

### Scénario 1 : Demande Simple (5 min)
1. Citoyen soumet une demande d'acte de naissance
2. Agent reçoit la notification
3. Agent traite et répond
4. Citoyen reçoit la réponse

### Scénario 2 : Demande Complexe (10 min)
1. Demande nécessitant plusieurs services
2. Workflow de validation hiérarchique
3. Coordination inter-services
4. Réponse consolidée

### Scénario 3 : Formation (15 min)
1. Nouvel agent suit la formation
2. Complète les 8 modules
3. Passe les quiz d'évaluation
4. Obtient la certification

## 🔍 Dépannage Express

### Problèmes Courants

#### Erreur de Base de Données
```bash
# Réinitialiser la DB
python manage.py flush
python manage.py migrate
```

#### Problème de Permissions
```bash
# Corriger les permissions
chmod +x manage.py
chown -R $USER:$USER .
```

#### Port Déjà Utilisé
```bash
# Utiliser un autre port
python manage.py runserver 8001
```

#### Problème de Dépendances
```bash
# Réinstaller les dépendances
pip install --upgrade -r requirements.txt
```

### Logs Utiles
```bash
# Voir les logs en temps réel
tail -f logs/sama_conai.log

# Logs Django
python manage.py shell
>>> import logging
>>> logging.getLogger('django').setLevel(logging.DEBUG)
```

## 📚 Ressources Rapides

### Documentation
- **Guide Utilisateur** : [docs/user-guide.md](docs/user-guide.md)
- **API Documentation** : http://localhost:8000/api/docs
- **Formation** : http://localhost:8000/formation

### Support
- **Issues GitHub** : [github.com/votre-org/sama_conai/issues](https://github.com/votre-org/sama_conai/issues)
- **Email** : support@sama-conai.sn
- **Discord** : [discord.gg/sama-conai](https://discord.gg/sama-conai)

### Communauté
- **Forum** : [forum.sama-conai.sn](https://forum.sama-conai.sn)
- **LinkedIn** : [SAMA CONAI Official](https://linkedin.com/company/sama-conai)
- **Twitter** : [@SamaConai](https://twitter.com/SamaConai)

## 🚀 Prochaines Étapes

### Déploiement Production
1. Lire le [Guide de Déploiement](DEPLOYMENT.md)
2. Configurer HTTPS et domaine
3. Mettre en place la sauvegarde
4. Configurer le monitoring

### Personnalisation
1. Adapter les couleurs et logos
2. Configurer les notifications
3. Personnaliser les workflows
4. Ajouter des intégrations

### Formation Équipe
1. Former les agents publics
2. Sensibiliser les citoyens
3. Organiser des ateliers
4. Créer des guides locaux

## 🎉 Félicitations !

Vous avez maintenant **SAMA CONAI** opérationnel ! 

### Prochains Objectifs
- [ ] Traiter votre première demande
- [ ] Compléter un module de formation
- [ ] Générer votre premier rapport
- [ ] Inviter votre équipe
- [ ] Personnaliser l'interface

### Partager Votre Expérience
- ⭐ **Star** le projet sur GitHub
- 📝 **Partager** vos retours
- 🤝 **Contribuer** au développement
- 📢 **Recommander** à d'autres administrations

---

## 📞 Besoin d'Aide ?

### Support Technique
- **Email** : support@sama-conai.sn
- **Téléphone** : +221 33 XXX XX XX
- **Chat** : Disponible sur le site web

### Formation et Accompagnement
- **Webinaires** : Tous les mardis à 14h
- **Ateliers** : Sur demande
- **Consulting** : Accompagnement personnalisé

---

**🇸🇳 Bienvenue dans l'écosystème SAMA CONAI !**

*Ensemble, nous modernisons l'administration publique sénégalaise*

**Mamadou Mbagnick DOGUE** & **Rassol DOGUE**  
*Créateurs de SAMA CONAI*