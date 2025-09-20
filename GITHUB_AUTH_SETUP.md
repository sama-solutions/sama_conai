# 🔐 Configuration Authentification GitHub - SAMA CONAI

## ⚠️ **PROBLÈME DÉTECTÉ**

L'upload a échoué car l'authentification GitHub n'est pas configurée :
```
fatal: could not read Username for 'https://github.com': Aucun périphérique ou adresse
```

## 🔧 **SOLUTIONS D'AUTHENTIFICATION**

### **SOLUTION 1 : Token d'Accès Personnel (Recommandée)**

#### **Étape 1 : Créer un Token GitHub**
1. **Aller sur GitHub.com** et se connecter
2. **Settings** (coin supérieur droit) → **Developer settings**
3. **Personal access tokens** → **Tokens (classic)**
4. **Generate new token** → **Generate new token (classic)**
5. **Configurer le token** :
   ```
   Note: SAMA CONAI Upload Token
   Expiration: 90 days (ou plus)
   Scopes à cocher:
   ✅ repo (Full control of private repositories)
   ✅ workflow (Update GitHub Action workflows)
   ✅ write:packages (Upload packages)
   ✅ delete:packages (Delete packages)
   ```
6. **Generate token** et **COPIER LE TOKEN** (il ne sera plus affiché)

#### **Étape 2 : Configurer Git avec le Token**
```bash
# Configurer le nom d'utilisateur GitHub
git config --global user.name "Mamadou Mbagnick & Rassol DOGUE"
git config --global user.email "loi200812sn@gmail.com"

# Configurer le credential helper
git config --global credential.helper store

# Mettre à jour l'URL du remote avec le token
git remote set-url origin https://VOTRE-TOKEN@github.com/sama-solutions/conai.git
```

#### **Étape 3 : Tester l'Upload**
```bash
# Push du code
git push origin main

# Push du tag
git push origin v3.0.0
```

---

### **SOLUTION 2 : SSH (Alternative)**

#### **Étape 1 : Générer une Clé SSH**
```bash
# Générer une nouvelle clé SSH
ssh-keygen -t ed25519 -C "loi200812sn@gmail.com"

# Démarrer l'agent SSH
eval "$(ssh-agent -s)"

# Ajouter la clé à l'agent
ssh-add ~/.ssh/id_ed25519
```

#### **Étape 2 : Ajouter la Clé à GitHub**
```bash
# Copier la clé publique
cat ~/.ssh/id_ed25519.pub
```

1. **Aller sur GitHub.com** → **Settings** → **SSH and GPG keys**
2. **New SSH key**
3. **Coller la clé publique**
4. **Add SSH key**

#### **Étape 3 : Changer l'URL du Remote**
```bash
# Changer pour SSH
git remote set-url origin git@github.com:sama-solutions/conai.git

# Tester la connexion
ssh -T git@github.com

# Push du code
git push origin main
git push origin v3.0.0
```

---

### **SOLUTION 3 : GitHub CLI (Plus Simple)**

#### **Installation GitHub CLI**
```bash
# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Ou via snap
sudo snap install gh
```

#### **Authentification et Upload**
```bash
# Se connecter à GitHub
gh auth login

# Suivre les instructions interactives
# Choisir : GitHub.com → HTTPS → Yes (authenticate) → Login with web browser

# Une fois connecté, push du code
git push origin main
git push origin v3.0.0
```

---

## 🚀 **UPLOAD IMMÉDIAT AVEC TOKEN**

### **Méthode Rapide (Recommandée)**

1. **Créer le token GitHub** (voir étapes ci-dessus)

2. **Configurer et uploader** :
```bash
# Remplacer VOTRE-TOKEN par le token créé
git remote set-url origin https://VOTRE-TOKEN@github.com/sama-solutions/conai.git

# Upload immédiat
git push origin main
git push origin v3.0.0
```

3. **Vérifier sur GitHub** : https://github.com/sama-solutions/conai

---

## 📋 **CHECKLIST POST-UPLOAD**

Après un upload réussi :

### **Vérifications Immédiates**
- [ ] Code visible sur GitHub
- [ ] README.md affiché avec logo
- [ ] Tag v3.0.0 présent
- [ ] Templates d'issues disponibles

### **Configuration Repository**
- [ ] Activer Issues, Projects, Wiki
- [ ] Configurer la protection de branche
- [ ] Ajouter topics et labels
- [ ] Créer la première release

### **Promotion**
- [ ] Post LinkedIn
- [ ] Tweet de lancement
- [ ] Partage dans communautés tech

---

## 🔐 **SÉCURITÉ DU TOKEN**

### **Bonnes Pratiques**
- ✅ **Expiration** : Définir une date d'expiration
- ✅ **Scopes minimaux** : Seulement les permissions nécessaires
- ✅ **Stockage sécurisé** : Ne pas partager le token
- ✅ **Rotation** : Renouveler régulièrement

### **En Cas de Problème**
- **Token compromis** : Le révoquer immédiatement sur GitHub
- **Erreur de push** : Vérifier les permissions du token
- **Problème d'accès** : Régénérer un nouveau token

---

## 🎯 **PROCHAINES ÉTAPES**

1. **Choisir une méthode d'authentification** (Token recommandé)
2. **Configurer l'authentification**
3. **Exécuter l'upload**
4. **Vérifier le succès**
5. **Configurer le repository**
6. **Lancer la promotion**

---

## 📞 **SUPPORT**

En cas de problème :
- **Documentation GitHub** : https://docs.github.com/en/authentication
- **Support GitHub** : https://support.github.com/
- **Communauté** : https://github.community/

---

**🚀 SAMA CONAI est prêt ! Il ne reste plus qu'à configurer l'authentification et uploader ! 🇸🇳**