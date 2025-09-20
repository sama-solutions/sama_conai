# Guide de Contribution - SAMA CONAI

Merci de votre intérêt pour contribuer à **SAMA CONAI** ! Ce guide vous aidera à comprendre comment participer efficacement au développement de cette solution innovante pour l'administration publique sénégalaise.

## 🎯 Vision de la Contribution

SAMA CONAI est un projet open source qui vise à transformer l'accès à l'information publique au Sénégal. Nous encourageons les contributions de tous les développeurs, designers, experts en gouvernance, et citoyens passionnés par la transparence administrative.

## 🤝 Types de Contributions

### 💻 Développement
- **Nouvelles fonctionnalités** : Amélioration des capacités existantes
- **Corrections de bugs** : Résolution de problèmes identifiés
- **Optimisations** : Amélioration des performances et de l'efficacité
- **Tests** : Développement de tests unitaires et d'intégration

### 📚 Documentation
- **Guides utilisateur** : Amélioration de la documentation existante
- **Tutoriels** : Création de guides pas-à-pas
- **Traductions** : Localisation en langues locales sénégalaises
- **API Documentation** : Documentation technique détaillée

### 🎨 Design & UX
- **Interface utilisateur** : Amélioration de l'expérience utilisateur
- **Accessibilité** : Conformité aux standards d'accessibilité
- **Design responsive** : Optimisation mobile et tablette
- **Iconographie** : Création d'éléments visuels

### 🧪 Tests & Qualité
- **Tests automatisés** : Développement de suites de tests
- **Tests d'utilisabilité** : Validation de l'expérience utilisateur
- **Tests de performance** : Optimisation des temps de réponse
- **Tests de sécurité** : Validation des mesures de sécurité

## 🚀 Processus de Contribution

### 1. Préparation

#### Fork du Repository
```bash
# Forker le projet sur GitHub
# Puis cloner votre fork
git clone https://github.com/VOTRE-USERNAME/sama_conai.git
cd sama_conai

# Ajouter le repository original comme remote
git remote add upstream https://github.com/AUTEURS-ORIGINAUX/sama_conai.git
```

#### Configuration de l'Environnement
```bash
# Créer un environnement virtuel
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# Installer les dépendances de développement
pip install -r requirements-dev.txt

# Installer les hooks pre-commit
pre-commit install
```

### 2. Développement

#### Création d'une Branche
```bash
# Synchroniser avec le repository principal
git fetch upstream
git checkout main
git merge upstream/main

# Créer une nouvelle branche pour votre contribution
git checkout -b feature/nom-de-votre-fonctionnalite
# ou
git checkout -b fix/description-du-bug
# ou
git checkout -b docs/amelioration-documentation
```

#### Standards de Code

##### Python (Backend)
- **PEP 8** : Respecter les conventions de style Python
- **Type Hints** : Utiliser les annotations de type
- **Docstrings** : Documenter toutes les fonctions et classes
- **Tests** : Écrire des tests pour toute nouvelle fonctionnalité

```python
def process_request(request_id: int, user_id: int) -> Dict[str, Any]:
    """
    Traite une demande d'accès à l'information.
    
    Args:
        request_id: Identifiant unique de la demande
        user_id: Identifiant de l'utilisateur
        
    Returns:
        Dictionnaire contenant le résultat du traitement
        
    Raises:
        RequestNotFoundError: Si la demande n'existe pas
        PermissionError: Si l'utilisateur n'a pas les droits
    """
    # Implémentation...
    pass
```

##### JavaScript (Frontend)
- **ES6+** : Utiliser les fonctionnalités modernes de JavaScript
- **JSDoc** : Documenter les fonctions complexes
- **Modules** : Organiser le code en modules réutilisables

```javascript
/**
 * Soumet une nouvelle demande d'accès à l'information
 * @param {Object} requestData - Données de la demande
 * @param {string} requestData.title - Titre de la demande
 * @param {string} requestData.description - Description détaillée
 * @returns {Promise<Object>} Réponse du serveur
 */
async function submitRequest(requestData) {
    // Implémentation...
}
```

##### CSS/SCSS
- **BEM Methodology** : Utiliser la convention de nommage BEM
- **Mobile First** : Approche responsive mobile-first
- **Variables CSS** : Utiliser les custom properties pour la cohérence

```scss
// Composant selon la méthodologie BEM
.request-card {
    &__header {
        // Styles pour l'en-tête
    }
    
    &__content {
        // Styles pour le contenu
    }
    
    &--urgent {
        // Modificateur pour les demandes urgentes
    }
}
```

### 3. Tests

#### Tests Unitaires
```bash
# Exécuter tous les tests
python -m pytest

# Tests avec couverture
python -m pytest --cov=sama_conai

# Tests spécifiques
python -m pytest tests/test_requests.py
```

#### Tests d'Intégration
```bash
# Tests d'intégration avec base de données
python -m pytest tests/integration/

# Tests de l'API
python -m pytest tests/api/
```

#### Tests Frontend
```bash
# Tests JavaScript
npm test

# Tests end-to-end
npm run test:e2e
```

### 4. Documentation

#### Mise à Jour de la Documentation
- Mettre à jour les docstrings et commentaires
- Ajouter des exemples d'utilisation
- Mettre à jour les guides utilisateur si nécessaire
- Documenter les changements dans CHANGELOG.md

#### Génération de la Documentation
```bash
# Générer la documentation API
python -m sphinx.cmd.build docs/ docs/_build/

# Vérifier les liens
python -m sphinx.cmd.build -b linkcheck docs/ docs/_build/
```

### 5. Commit et Push

#### Messages de Commit
Utiliser la convention **Conventional Commits** :

```bash
# Nouvelle fonctionnalité
git commit -m "feat(requests): add automatic deadline calculation"

# Correction de bug
git commit -m "fix(auth): resolve login timeout issue"

# Documentation
git commit -m "docs(api): add examples for request endpoints"

# Tests
git commit -m "test(requests): add unit tests for validation"

# Refactoring
git commit -m "refactor(dashboard): optimize query performance"
```

#### Push et Pull Request
```bash
# Push vers votre fork
git push origin feature/nom-de-votre-fonctionnalite

# Créer une Pull Request sur GitHub
# Utiliser le template de PR fourni
```

## 📋 Template de Pull Request

```markdown
## Description
Brève description des changements apportés.

## Type de Changement
- [ ] Bug fix (changement non-breaking qui corrige un problème)
- [ ] Nouvelle fonctionnalité (changement non-breaking qui ajoute une fonctionnalité)
- [ ] Breaking change (correction ou fonctionnalité qui casserait la compatibilité)
- [ ] Documentation (changements de documentation uniquement)

## Tests
- [ ] Tests unitaires ajoutés/mis à jour
- [ ] Tests d'intégration ajoutés/mis à jour
- [ ] Tests manuels effectués

## Checklist
- [ ] Mon code suit les standards du projet
- [ ] J'ai effectué une auto-review de mon code
- [ ] J'ai commenté mon code, particulièrement les parties complexes
- [ ] J'ai mis à jour la documentation correspondante
- [ ] Mes changements ne génèrent pas de nouveaux warnings
- [ ] J'ai ajouté des tests qui prouvent que ma correction/fonctionnalité fonctionne
- [ ] Les tests nouveaux et existants passent avec mes changements

## Screenshots (si applicable)
Ajouter des captures d'écran pour illustrer les changements visuels.

## Contexte Additionnel
Ajouter tout contexte supplémentaire sur la Pull Request ici.
```

## 🔍 Processus de Review

### Critères de Review
1. **Fonctionnalité** : Le code fait-il ce qu'il est censé faire ?
2. **Qualité** : Le code est-il lisible et maintenable ?
3. **Performance** : Y a-t-il des impacts sur les performances ?
4. **Sécurité** : Le code introduit-il des vulnérabilités ?
5. **Tests** : Les tests sont-ils suffisants et pertinents ?
6. **Documentation** : La documentation est-elle à jour ?

### Processus de Review
1. **Review automatique** : Vérification par les outils CI/CD
2. **Review par les pairs** : Examen par d'autres contributeurs
3. **Review par les mainteneurs** : Validation finale
4. **Tests d'intégration** : Validation en environnement de test

## 🐛 Signalement de Bugs

### Template d'Issue pour Bug
```markdown
**Description du Bug**
Description claire et concise du problème.

**Étapes pour Reproduire**
1. Aller à '...'
2. Cliquer sur '....'
3. Faire défiler jusqu'à '....'
4. Voir l'erreur

**Comportement Attendu**
Description claire de ce qui devrait se passer.

**Captures d'Écran**
Si applicable, ajouter des captures d'écran.

**Environnement:**
 - OS: [ex: Ubuntu 20.04]
 - Navigateur: [ex: Chrome 91]
 - Version: [ex: 1.2.3]

**Contexte Additionnel**
Ajouter tout autre contexte sur le problème ici.
```

## 💡 Demande de Fonctionnalité

### Template d'Issue pour Fonctionnalité
```markdown
**Votre demande de fonctionnalité est-elle liée à un problème ?**
Description claire du problème. Ex: Je suis frustré quand [...]

**Décrivez la solution que vous aimeriez**
Description claire de ce que vous voulez qu'il se passe.

**Décrivez les alternatives que vous avez considérées**
Description des solutions ou fonctionnalités alternatives.

**Contexte Additionnel**
Ajouter tout autre contexte ou captures d'écran sur la demande.
```

## 🌍 Localisation et Internationalisation

### Ajout de Nouvelles Langues
```python
# Ajouter les traductions dans locale/
# Structure: locale/[code_langue]/LC_MESSAGES/

# Exemple pour le Wolof (wo)
locale/wo/LC_MESSAGES/django.po
locale/wo/LC_MESSAGES/django.mo
```

### Clés de Traduction
```python
# Utiliser gettext pour les chaînes traduisibles
from django.utils.translation import gettext as _

message = _("Votre demande a été soumise avec succès")
```

## 🏆 Reconnaissance des Contributeurs

### Hall of Fame
Les contributeurs significatifs seront reconnus dans :
- Le fichier CONTRIBUTORS.md
- La page "À propos" du site web
- Les notes de version
- Les présentations publiques du projet

### Types de Reconnaissance
- **Contributeur Code** : Développement de fonctionnalités
- **Contributeur Documentation** : Amélioration de la documentation
- **Contributeur Design** : Amélioration de l'interface utilisateur
- **Contributeur Tests** : Amélioration de la qualité
- **Contributeur Communauté** : Support et engagement communautaire

## 📞 Support et Communication

### Canaux de Communication
- **GitHub Issues** : Pour les bugs et demandes de fonctionnalités
- **GitHub Discussions** : Pour les questions générales
- **Email** : contribute@sama-conai.sn
- **Discord** : [Serveur SAMA CONAI](https://discord.gg/sama-conai)

### Réunions Communautaires
- **Réunions mensuelles** : Premier vendredi de chaque mois
- **Sessions de code review** : Tous les mercredis
- **Ateliers de formation** : Selon les besoins

## 📜 Code de Conduite

### Notre Engagement
Nous nous engageons à faire de la participation à notre projet une expérience sans harcèlement pour tous, indépendamment de l'âge, de la taille corporelle, du handicap visible ou invisible, de l'ethnicité, des caractéristiques sexuelles, de l'identité et de l'expression de genre, du niveau d'expérience, de l'éducation, du statut socio-économique, de la nationalité, de l'apparence personnelle, de la race, de la religion, ou de l'identité et de l'orientation sexuelle.

### Standards Attendus
- Utiliser un langage accueillant et inclusif
- Respecter les différents points de vue et expériences
- Accepter gracieusement les critiques constructives
- Se concentrer sur ce qui est le mieux pour la communauté
- Faire preuve d'empathie envers les autres membres de la communauté

### Signalement
Les instances de comportement abusif, harcelant ou autrement inacceptable peuvent être signalées à conduct@sama-conai.sn.

---

## 🙏 Remerciements

Merci de contribuer à **SAMA CONAI** ! Votre participation aide à construire un avenir plus transparent et accessible pour l'administration publique sénégalaise.

Ensemble, nous créons une solution qui bénéficiera à des millions de citoyens et transformera la relation entre l'État et les citoyens.

---

**Mamadou Mbagnick DOGUE** & **Rassol DOGUE**  
*Créateurs et Mainteneurs Principaux*