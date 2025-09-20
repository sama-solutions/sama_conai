# Correction du problème de tracking sur les champs HTML

## ❌ Problème identifié

```
NotImplementedError: Unsupported tracking on field description (type html)
```

Odoo ne supporte pas le tracking (`tracking=True`) sur les champs de type `fields.Html()`. Cette limitation cause une erreur lors de la mise à jour du module.

## ✅ Champs corrigés

Les champs HTML suivants avaient `tracking=True` et ont été corrigés :

### Dans `models/information_request.py` :
- `description` : Champ HTML pour la description de la demande
- `response_body` : Champ HTML pour le corps de la réponse

### Dans `models/whistleblowing_alert.py` :
- `description` : Champ HTML pour la description du signalement  
- `investigation_notes` : Champ HTML pour les notes d'investigation

## 🔧 Modifications apportées

### 1. Suppression du tracking dans le code

**Avant :**
```python
description = fields.Html(
    string='Description de la Demande',
    required=True,
    tracking=True  # ❌ Problématique
)
```

**Après :**
```python
description = fields.Html(
    string='Description de la Demande',
    required=True
    # ✅ tracking=True supprimé
)
```

### 2. Script de nettoyage de la base de données

Un script `scripts/fix_html_tracking.py` a été créé pour nettoyer les entrées de tracking déjà présentes dans la base de données.

## 🚀 Étapes de résolution

### 1. Mise à jour du code (✅ Fait)
Les fichiers Python ont été modifiés pour supprimer `tracking=True` des champs HTML.

### 2. Nettoyage de la base de données

Exécutez le script de nettoyage dans le shell Odoo :

```bash
# Ouvrir le shell Odoo
./odoo-bin shell -c odoo.conf -d your_database_name

# Dans le shell, exécuter le script
>>> exec(open('scripts/fix_html_tracking.py').read())
```

### 3. Mise à jour du module

```bash
./odoo-bin -c odoo.conf -d your_database_name -u sama_conai
```

## 🔍 Alternative si le problème persiste

Si l'erreur persiste après les étapes ci-dessus, vous pouvez nettoyer manuellement la base PostgreSQL :

```sql
-- Supprimer les entrées de tracking pour les champs HTML
DELETE FROM ir_model_fields 
WHERE name IN ('description', 'response_body', 'investigation_notes') 
  AND model IN ('request.information', 'whistleblowing.alert') 
  AND tracking = true;

-- Supprimer les valeurs de tracking existantes
DELETE FROM mail_tracking_value 
WHERE field IN ('description', 'response_body', 'investigation_notes')
  AND mail_message_id IN (
    SELECT id FROM mail_message 
    WHERE model IN ('request.information', 'whistleblowing.alert')
  );
```

## 💡 Alternatives pour le suivi

Si vous souhaitez conserver un suivi des modifications sur ces champs :

### Option 1 : Utiliser fields.Text()
```python
description = fields.Text(
    string='Description de la Demande',
    required=True,
    tracking=True  # ✅ Supporté sur Text
)
```

### Option 2 : Suivi personnalisé
Implémenter une logique custom dans les méthodes `write()` pour tracker manuellement les changements HTML.

## 📝 Fichiers modifiés

- `models/information_request.py` : Suppression tracking sur `description` et `response_body`
- `models/whistleblowing_alert.py` : Suppression tracking sur `description` et `investigation_notes`  
- `scripts/fix_html_tracking.py` : Script de nettoyage de la base de données
- `HTML_TRACKING_FIX_README.md` : Cette documentation

## ✅ Résultat attendu

Après ces corrections :
- ✅ Plus d'erreur `NotImplementedError` lors de la mise à jour du module
- ✅ Les champs HTML fonctionnent normalement
- ✅ Le module peut être mis à jour sans problème
- ⚠️ Le tracking automatique des modifications sur ces champs HTML est désactivé