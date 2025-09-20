# 📊 SAMA CONAI - Guide Données Réelles Odoo

## 🎯 Objectif

Basculer l'application mobile neumorphique pour qu'elle utilise les **vraies données d'Odoo** au lieu des données de démonstration.

## 🔍 Problème Résolu

✅ **Avant** : Application mobile avec données de démo statiques  
✅ **Maintenant** : Application mobile connectée aux vraies données d'Odoo en temps réel

## 🚀 Solution en 3 Étapes

### **Étape 1 : Vérifier la Connexion Odoo**
```bash
./test_odoo_connection.sh
```

Ce script vérifie :
- ✅ Odoo est accessible (port 8077 ou 8069)
- ✅ PostgreSQL fonctionne
- ✅ Base de données `sama_conai_test` existe
- ✅ Modèles SAMA CONAI sont accessibles
- ✅ API Odoo répond correctement

### **Étape 2 : Basculer vers les Données Réelles**
```bash
./switch_to_odoo_real_data.sh
```

Ce script :
- 💾 Sauvegarde le serveur actuel
- 🔄 Active le serveur avec données réelles Odoo
- 🎨 Active l'interface neumorphique
- 🚀 Redémarre l'application mobile
- 🧪 Teste la connexion aux données réelles

### **Étape 3 : Vérifier le Résultat**
```bash
# Accéder à l'application
http://localhost:3005

# Identifiants
admin / admin
```

## 📊 Différences Clés

### **Données de Démo (Avant)**
- 📋 Données statiques codées en dur
- 🔄 Pas de synchronisation avec Odoo
- 📈 Statistiques fictives
- 🚫 Pas de persistance des changements

### **Données Réelles Odoo (Maintenant)**
- 📋 Vraies demandes d'information d'Odoo
- 🔄 Synchronisation en temps réel
- 📈 Statistiques calculées dynamiquement
- ✅ Persistance complète des données

## 🔧 Fonctionnalités avec Données Réelles

### **Dashboard**
- **Statistiques utilisateur** : Calculées depuis Odoo
- **Demandes récentes** : Les 5 dernières demandes réelles
- **Statistiques publiques** : Temps de réponse moyen réel
- **Alertes** : Vraies alertes de signalement

### **Liste des Demandes**
- **Toutes les demandes** : Récupérées depuis `request.information`
- **Filtrage par statut** : Basé sur les vrais états Odoo
- **Pagination** : Gestion des grandes listes
- **Permissions** : Respect des droits utilisateur

### **Détail des Demandes**
- **Informations complètes** : Tous les champs Odoo
- **Timeline** : Historique des activités réelles
- **Réponses** : Vraies réponses et refus motivés
- **Assignation** : Vrais utilisateurs et départements

## 🔗 Architecture Technique

### **Connexion Odoo**
```javascript
// Configuration dans mobile_app_web/odoo-api.js
const ODOO_BASE_URL = 'http://localhost:8077';
const ODOO_DB = 'sama_conai_test';
```

### **Authentification**
- ✅ Authentification via API Odoo
- ✅ Sessions sécurisées
- ✅ Fallback vers comptes démo si Odoo indisponible

### **API Endpoints**
- `GET /api/mobile/citizen/dashboard` → Données réelles
- `GET /api/mobile/citizen/requests` → Liste réelle
- `GET /api/mobile/citizen/requests/:id` → Détail réel

## 📱 Interface Neumorphique

L'interface neumorphique est maintenant alimentée par les vraies données :

### **Thèmes Disponibles**
1. **Institutionnel** (par défaut) - Couleurs officielles
2. **Terre du Sénégal** - Couleurs chaudes du terroir
3. **Moderne** - Design contemporain

### **Fonctionnalités**
- ✅ Sélecteur de thème en temps réel
- ✅ Animations fluides
- ✅ Design neumorphique complet
- ✅ Responsive mobile-first

## 🔄 Gestion des Erreurs

### **Si Odoo n'est pas disponible**
- 🔄 Fallback automatique vers données démo
- ⚠️ Message d'avertissement affiché
- 🔁 Reconnexion automatique quand Odoo revient

### **Si la base de données est vide**
- 📊 Statistiques à zéro
- 💡 Messages informatifs
- 🎯 Invitation à créer des données

## 🧪 Tests et Validation

### **Test de Connexion**
```bash
./test_odoo_connection.sh
```

### **Test de l'API Mobile**
```bash
# Test de login
curl -X POST http://localhost:3005/api/mobile/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin","password":"admin"}'

# Test du dashboard (avec token)
curl http://localhost:3005/api/mobile/citizen/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### **Vérification des Données**
- Source de données affichée : `"source": "odoo_real_data"`
- Indicateur visuel : Badge "RÉEL" au lieu de "DEMO"
- Données dynamiques qui changent avec Odoo

## 🔧 Dépannage

### **Problème : Données de démo affichées**
```bash
# Vérifier la connexion Odoo
./test_odoo_connection.sh

# Redémarrer avec données réelles
./switch_to_odoo_real_data.sh
```

### **Problème : Erreur de connexion**
```bash
# Vérifier qu'Odoo fonctionne
curl http://localhost:8077

# Démarrer Odoo si nécessaire
./startup_sama_conai_stack.sh
```

### **Problème : Pas de données**
1. Connectez-vous à Odoo : `http://localhost:8077`
2. Créez quelques demandes d'information
3. Redémarrez l'application mobile

## 📋 Checklist de Validation

- [ ] ✅ Odoo accessible sur port 8077
- [ ] ✅ Base de données `sama_conai_test` existe
- [ ] ✅ Module SAMA CONAI installé
- [ ] ✅ Application mobile redémarrée
- [ ] ✅ Interface neumorphique active
- [ ] ✅ Source de données = "odoo_real_data"
- [ ] ✅ Statistiques dynamiques
- [ ] ✅ Demandes réelles affichées

## 🎉 Résultat Final

Après avoir suivi ce guide, vous aurez :

✅ **Application mobile neumorphique** avec design moderne  
✅ **Données réelles d'Odoo** en temps réel  
✅ **3 thèmes** sélectionnables  
✅ **Synchronisation complète** avec le backend  
✅ **Interface responsive** optimisée mobile  
✅ **Authentification sécurisée** via Odoo  

## 🔄 Retour aux Données de Démo

Si nécessaire, pour revenir aux données de démo :

```bash
# Restaurer le serveur démo
cp mobile_app_web/server_demo.js mobile_app_web/server.js

# Redémarrer
pkill -f "node.*server.js"
cd mobile_app_web && npm start
```

## 🇸🇳 SAMA CONAI - Transparence Numérique

**Votre application mobile utilise maintenant les vraies données d'Odoo pour une transparence gouvernementale authentique !**

---

### 📞 Support

En cas de problème :
1. Exécutez `./test_odoo_connection.sh` pour diagnostiquer
2. Vérifiez les logs : `tail -f logs/mobile_odoo_real.log`
3. Redémarrez le stack complet : `./startup_sama_conai_stack.sh`