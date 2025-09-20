# 🚀 Guide de Test Rapide - Menus Réorganisés

## 📋 **Pré-requis**
- Odoo 18 CE installé et fonctionnel
- Module SAMA CONAI dans le répertoire des addons
- Droits d'administration sur l'instance Odoo

## 🔧 **Étapes de Test**

### 1. **Validation Préalable**
```bash
# Vérifier la syntaxe des fichiers
python3 test_module_syntax.py

# Valider la structure des menus
python3 validate_menu_structure.py
```

### 2. **Mise à Jour du Module**
```bash
# Si le module est déjà installé, le mettre à jour
./odoo-bin -u sama_conai -d votre_base_de_donnees

# Si c'est une nouvelle installation
./odoo-bin -i sama_conai -d votre_base_de_donnees
```

### 3. **Vérification des Menus**

#### 🔍 **Menu Principal 1 : Accès à l'Information**
- [ ] Menu visible dans la barre principale
- [ ] Sous-menu "Demandes d'Information" accessible
- [ ] Sous-menu "Rapports et Analyses" avec 3 options
- [ ] Sous-menu "Configuration" avec 2 options

#### 🔍 **Menu Principal 2 : Signalement d'Alerte**
- [ ] Menu visible pour les référents d'alerte uniquement
- [ ] Sous-menu "Signalements" accessible
- [ ] Sous-menu "Rapports et Analyses" avec 3 options
- [ ] Sous-menu "Configuration" avec 1 option

#### 🔍 **Menu Principal 3 : Analytics & Rapports**
- [ ] Nouveau menu visible dans la barre principale
- [ ] Sous-menu "Tableaux de Bord" accessible
- [ ] Sous-menu "Générateurs de Rapports" avec 2 options

#### 🔍 **Menu Administration**
- [ ] Menu "Administration Transparence" sous Administration
- [ ] Sous-menus d'administration accessibles

### 4. **Test des Actions**

#### ✅ **Actions à Tester**
```
□ action_information_request - Vue Kanban des demandes
□ action_information_request_analysis - Vue Graph/Pivot
□ action_executive_dashboard_requests - Dashboard filtré
□ action_auto_report_generator_requests - Générateur filtré
□ action_whistleblowing_alert - Vue Kanban des signalements
□ action_whistleblowing_alert_analysis - Vue Graph/Pivot
□ action_executive_dashboard - Dashboard complet
□ action_auto_report_generator - Générateur complet
□ action_transparency_users - Liste des utilisateurs
```

### 5. **Test des Permissions**

#### 👤 **Utilisateur Standard (group_info_request_user)**
- [ ] Accès au menu "Accès à l'Information"
- [ ] Pas d'accès au menu "Signalement d'Alerte"
- [ ] Pas d'accès aux menus de configuration

#### 👨‍💼 **Manager (group_info_request_manager)**
- [ ] Accès complet au menu "Accès à l'Information"
- [ ] Accès au menu "Analytics & Rapports"
- [ ] Accès aux configurations

#### 🛡️ **Référent Alerte (group_whistleblowing_manager)**
- [ ] Accès au menu "Signalement d'Alerte"
- [ ] Accès aux analytics filtrées pour les alertes

#### ⚙️ **Administrateur (group_transparency_admin)**
- [ ] Accès à tous les menus
- [ ] Accès au menu "Administration Transparence"

## 🐛 **Dépannage**

### Erreurs Communes

#### ❌ **Menu non visible**
```bash
# Vérifier les groupes de l'utilisateur
# Aller dans Paramètres > Utilisateurs et Entreprises > Utilisateurs
# Vérifier les groupes SAMA CONAI assignés
```

#### ❌ **Action non trouvée**
```bash
# Vérifier les logs Odoo
tail -f /var/log/odoo/odoo.log

# Rechercher les erreurs liées aux actions
grep "action_" /var/log/odoo/odoo.log
```

#### ❌ **Erreur de permission**
```bash
# Vérifier les groupes de sécurité
# Aller dans Paramètres > Technique > Sécurité > Groupes
# Vérifier la catégorie "SAMA CONAI"
```

### Commandes de Diagnostic

```bash
# Redémarrer Odoo en mode debug
./odoo-bin --dev=all -d votre_base

# Vérifier la structure des menus en base
# Se connecter à PostgreSQL et exécuter :
SELECT name, parent_id, action FROM ir_ui_menu WHERE name LIKE '%SAMA%' OR name LIKE '%Information%' OR name LIKE '%Alerte%';
```

## 📞 **Support**

### En cas de problème :

1. **Vérifier les logs** - Consulter les logs Odoo pour les erreurs
2. **Restaurer l'ancien menu** - Utiliser `views/menus_old.xml` si nécessaire
3. **Réinstaller le module** - Désinstaller puis réinstaller complètement
4. **Vérifier les dépendances** - S'assurer que tous les modules requis sont installés

### Fichiers de Référence :
- `MENU_REORGANIZATION_SUMMARY.md` - Documentation complète
- `validate_menu_structure.py` - Script de validation
- `test_module_syntax.py` - Test de syntaxe

---
**⚠️ Important** : Toujours tester sur un environnement de développement avant la production !

**✅ Validation** : Si tous les tests passent, la réorganisation est réussie !