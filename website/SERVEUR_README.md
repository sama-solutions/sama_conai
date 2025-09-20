# 🌐 SAMA CONAI Formation Website - Guide du Serveur

## 🚀 Démarrage Rapide

### Option 1: Script Python (Recommandé)
```bash
cd website
python3 start_server.py
```

### Option 2: Script Bash
```bash
cd website
./start.sh
```

### Option 3: Serveur Simple
```bash
cd website
python3 simple_server.py
```

## 🔧 Fonctionnalités

### ✅ Arrêt Automatique des Processus
- **Détection automatique** des processus utilisant le port 8000
- **Arrêt gracieux** avec SIGTERM puis SIGKILL si nécessaire
- **Vérification** que le port est libre avant démarrage

### 🌐 Serveur HTTP avec CORS
- **Port fixe** : 8000 (http://localhost:8000)
- **CORS activé** pour les tests API
- **Headers de cache** optimisés pour le développement
- **Logs personnalisés** avec timestamps

### 🎯 Ouverture Automatique du Navigateur
- **Délai de 2-3 secondes** pour laisser le serveur démarrer
- **Détection automatique** du navigateur disponible
- **URL directe** vers la page d'accueil

## 📋 Pages Disponibles

| Page | URL | Description |
|------|-----|-------------|
| **Accueil** | http://localhost:8000/ | Page principale du site |
| **Formation Citoyen** | http://localhost:8000/formation/citoyen.html | Formation complète (18 leçons) |
| **Formation Agent** | http://localhost:8000/formation/agent.html | Formation pour agents publics |
| **Formation Admin** | http://localhost:8000/formation/administrateur.html | Formation administrateurs |
| **Formation Formateur** | http://localhost:8000/formation/formateur.html | Formation des formateurs |
| **Certification Utilisateur** | http://localhost:8000/certification/utilisateur.html | Certification citoyens |
| **Certification Formateur** | http://localhost:8000/certification/formateur.html | Certification formateurs |
| **Certification Expert** | http://localhost:8000/certification/expert.html | Certification experts |

## 🛠️ Scripts Disponibles

### `start_server.py` - Lanceur Principal
- **Arrêt automatique** des processus sur le port 8000
- **Serveur HTTP** avec CORS et logs personnalisés
- **Ouverture automatique** du navigateur
- **Gestion des erreurs** complète

### `start.sh` - Alternative Bash
- **Compatible** avec tous les systèmes Unix/Linux
- **Détection automatique** de Python (python3/python)
- **Fallback** vers le serveur HTTP simple de Python

### `check_server.py` - Vérificateur
```bash
python3 check_server.py
```
- **Vérification** que le serveur répond
- **Test** des pages principales
- **Rapport** de statut détaillé

### `simple_server.py` - Serveur Basique
- **Version simplifiée** sans arrêt automatique des processus
- **Recherche automatique** d'un port libre
- **Idéal** pour les environnements contraints

## 🔍 Résolution de Problèmes

### Port 8000 Occupé
```bash
# Vérifier les processus
lsof -i :8000

# Arrêter manuellement
kill -9 $(lsof -ti :8000)

# Ou utiliser le script qui le fait automatiquement
python3 start_server.py
```

### Python Non Trouvé
```bash
# Vérifier l'installation
python3 --version

# Installer si nécessaire (Ubuntu/Debian)
sudo apt install python3

# Installer si nécessaire (CentOS/RHEL)
sudo yum install python3
```

### Permissions Refusées
```bash
# Rendre les scripts exécutables
chmod +x start.sh
chmod +x start_server.py
chmod +x check_server.py
```

### Navigateur Ne S'Ouvre Pas
- **Ouvrez manuellement** : http://localhost:8000
- **Vérifiez** que le serveur fonctionne avec `check_server.py`
- **Testez** avec curl : `curl http://localhost:8000`

## 📊 Vérification du Fonctionnement

### Test Rapide
```bash
# Démarrer le serveur
python3 start_server.py

# Dans un autre terminal
python3 check_server.py
```

### Test Manuel
```bash
# Vérifier que le serveur répond
curl -I http://localhost:8000

# Tester une page spécifique
curl http://localhost:8000/formation/citoyen.html
```

## 🎯 Utilisation en Production

### ⚠️ Important
Ces scripts sont conçus pour le **développement local** uniquement.

Pour la production, utilisez :
- **Nginx** ou **Apache** comme serveur web
- **HTTPS** avec certificats SSL
- **Reverse proxy** pour la sécurité
- **Load balancer** pour la scalabilité

### Configuration Nginx Exemple
```nginx
server {
    listen 80;
    server_name sama-conai.sn;
    root /path/to/website;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

## 🔧 Personnalisation

### Changer le Port
Modifiez la variable `PORT` dans les scripts :
```python
PORT = 8080  # Au lieu de 8000
```

### Ajouter des Headers
Modifiez la méthode `end_headers()` dans `CORSHTTPRequestHandler` :
```python
def end_headers(self):
    self.send_header('X-Custom-Header', 'SAMA-CONAI')
    super().end_headers()
```

### Logs Personnalisés
Modifiez la méthode `log_message()` :
```python
def log_message(self, format, *args):
    with open('access.log', 'a') as f:
        f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - {format % args}\n")
```

## 📞 Support

Pour toute question ou problème :
1. **Vérifiez** ce README
2. **Testez** avec `check_server.py`
3. **Consultez** les logs du serveur
4. **Vérifiez** les permissions et dépendances

---

**🇸🇳 SAMA CONAI - Transparence et Excellence !**