# Guide de dépannage - Couleur des menus

## 🎯 Problème
Le premier menu de la barre de navigation supérieure reste bleu au lieu d'être blanc comme les autres menus.

## ✅ Solutions appliquées

### 1. Styles CSS renforcés
J'ai ajouté des styles CSS complets dans `static/src/css/backend.css` avec :
- Sélecteurs multiples pour couvrir toutes les versions d'Odoo
- Force globale avec `!important` sur tous les liens de la navbar
- Sélecteurs spécifiques pour le premier menu

### 2. Vérification automatique
Script `scripts/test_menu_styles.py` pour valider la présence des styles.

## 🔧 Étapes de résolution

### 1. Redémarrer Odoo
```bash
# Arrêter Odoo
sudo systemctl stop odoo
# ou
./stop_sama_conai.sh

# Redémarrer Odoo
sudo systemctl start odoo
# ou
./start_sama_conai.sh
```

### 2. Vider le cache du navigateur
- **Chrome/Edge** : Ctrl+Shift+R ou F12 > Network > Disable cache
- **Firefox** : Ctrl+Shift+R ou F12 > Network > Disable cache
- **Safari** : Cmd+Option+R

### 3. Forcer le rechargement des assets
```bash
# Mettre à jour le module pour recharger les assets
./odoo-bin -c odoo.conf -d your_database -u sama_conai
```

## 🔍 Diagnostic supplémentaire

### Vérifier les styles dans le navigateur
1. Ouvrir les outils de développement (F12)
2. Inspecter le premier menu
3. Vérifier dans l'onglet "Styles" que les règles CSS sont appliquées
4. Chercher les règles avec `color: white !important`

### Classes CSS à vérifier
Le premier menu peut avoir ces classes :
- `.o_menu_entry_lvl_1:first-child`
- `.dropdown-toggle:first-child`
- `.nav-link:first-child`
- `.navbar-nav > li:first-child`

## 🛠️ Solutions de secours

### Solution 1 : CSS encore plus spécifique
Si le problème persiste, ajouter à la fin de `backend.css` :

```css
/* Force absolue pour le premier menu */
.o_main_navbar *:first-child,
.o_main_navbar li:first-child,
.o_main_navbar li:first-child a,
.o_main_navbar li:first-child button,
.o_main_navbar .nav-item:first-child,
.o_main_navbar .nav-item:first-child * {
    color: white !important;
}
```

### Solution 2 : JavaScript de secours
Créer un fichier `static/src/js/menu_fix.js` :

```javascript
odoo.define('sama_conai.menu_fix', function (require) {
    'use strict';
    
    var core = require('web.core');
    
    core.bus.on('web_client_ready', null, function () {
        // Forcer la couleur blanche sur le premier menu
        $('.o_main_navbar .o_menu_sections li:first-child a').css('color', 'white');
        $('.o_main_navbar .navbar-nav li:first-child a').css('color', 'white');
    });
});
```

Et l'ajouter dans `__manifest__.py` :
```python
'assets': {
    'web.assets_backend': [
        'sama_conai/static/src/css/backend.css',
        'sama_conai/static/src/js/menu_fix.js',  # Ajouter cette ligne
    ],
},
```

### Solution 3 : Inspection manuelle
1. Identifier la classe exacte du premier menu dans votre version d'Odoo
2. Ajouter un sélecteur CSS spécifique pour cette classe

## 📞 Support
Si le problème persiste après toutes ces étapes :
1. Vérifier la version d'Odoo utilisée
2. Identifier les classes CSS exactes du premier menu
3. Adapter les sélecteurs CSS en conséquence

## ✅ Test final
Exécuter le script de validation :
```bash
python3 scripts/test_menu_styles.py
```

Le premier menu devrait maintenant être blanc comme les autres ! 🎨