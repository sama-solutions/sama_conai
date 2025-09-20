# 🚀 Guide de Déploiement - Site Web SAMA CONAI

## 📋 **Vue d'ensemble**

Ce guide détaille les procédures de déploiement du site web de formation et certification SAMA CONAI pour différents environnements.

## 🏗️ **Environnements de Déploiement**

### **1. Développement Local**
- **URL** : http://localhost:8000
- **Usage** : Développement et tests locaux
- **SSL** : Non requis

### **2. Staging**
- **URL** : https://staging.formation.sama-conai.sn
- **Usage** : Tests avant production
- **SSL** : Let's Encrypt

### **3. Production**
- **URL** : https://formation.sama-conai.sn
- **Usage** : Site public officiel
- **SSL** : Let's Encrypt

## 🔧 **Prérequis Système**

### **Serveur Web**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install nginx certbot python3-certbot-nginx
```

### **Outils Optionnels**
```bash
# Optimisation des assets
sudo npm install -g uglifycss uglify-js

# Optimisation des images
sudo apt install imagemagick
```

### **Permissions**
```bash
# Créer utilisateur de déploiement
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG www-data deploy
sudo usermod -aG sudo deploy
```

## 🚀 **Déploiement Rapide**

### **Méthode 1 : Script Automatique**
```bash
# Cloner le repository
git clone https://github.com/sama-solutions/conai.git
cd conai/website

# Déploiement local
./deploy.sh local

# Déploiement staging
./deploy.sh staging

# Déploiement production
./deploy.sh production
```

### **Méthode 2 : Serveur de Développement**
```bash
# Démarrer le serveur local
python3 server.py

# Ou sur un port spécifique
python3 server.py 8080
```

## 📁 **Structure de Déploiement**

### **Arborescence Cible**
```
/var/www/html/formation.sama-conai.sn/
├── index.html
├── assets/
│   ├── css/
│   ├── js/
│   └── images/
├── formation/
│   ├── administrateur.html
│   ├── agent.html
│   ├── citoyen.html
│   └── formateur.html
├── certification/
│   ├── utilisateur.html
│   ├── formateur.html
│   └── expert.html
└── README.md
```

### **Permissions**
```bash
# Propriétaire et groupe
sudo chown -R www-data:www-data /var/www/html/formation.sama-conai.sn

# Permissions des dossiers
sudo find /var/www/html/formation.sama-conai.sn -type d -exec chmod 755 {} \;

# Permissions des fichiers
sudo find /var/www/html/formation.sama-conai.sn -type f -exec chmod 644 {} \;
```

## ⚙️ **Configuration Nginx**

### **Configuration de Base**
```nginx
server {
    listen 80;
    server_name formation.sama-conai.sn;
    root /var/www/html/formation.sama-conai.sn;
    index index.html;
    
    # Redirection HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name formation.sama-conai.sn;
    root /var/www/html/formation.sama-conai.sn;
    index index.html;
    
    # Certificats SSL
    ssl_certificate /etc/letsencrypt/live/formation.sama-conai.sn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/formation.sama-conai.sn/privkey.pem;
    
    # Configuration SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Gestion des fichiers
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Cache des assets statiques
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Compression Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    # Sécurité
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Pages d'erreur personnalisées
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
```

### **Activation de la Configuration**
```bash
# Copier la configuration
sudo cp nginx.conf /etc/nginx/sites-available/sama-conai-formation

# Activer le site
sudo ln -s /etc/nginx/sites-available/sama-conai-formation /etc/nginx/sites-enabled/

# Tester la configuration
sudo nginx -t

# Recharger Nginx
sudo systemctl reload nginx
```

## 🔒 **Configuration SSL**

### **Let's Encrypt**
```bash
# Installation Certbot
sudo apt install certbot python3-certbot-nginx

# Obtenir le certificat
sudo certbot --nginx -d formation.sama-conai.sn

# Renouvellement automatique
sudo crontab -e
# Ajouter : 0 12 * * * /usr/bin/certbot renew --quiet
```

### **Vérification SSL**
```bash
# Test SSL
openssl s_client -connect formation.sama-conai.sn:443 -servername formation.sama-conai.sn

# Vérification en ligne
# https://www.ssllabs.com/ssltest/
```

## 📊 **Monitoring et Logs**

### **Logs Nginx**
```bash
# Logs d'accès
sudo tail -f /var/log/nginx/access.log

# Logs d'erreur
sudo tail -f /var/log/nginx/error.log

# Logs spécifiques au site
sudo tail -f /var/log/nginx/formation.sama-conai.sn.access.log
```

### **Monitoring Automatique**
```bash
# Script de monitoring (créé automatiquement par deploy.sh)
/usr/local/bin/monitor-sama-conai-formation formation.sama-conai.sn

# Logs de monitoring
sudo tail -f /var/log/sama-conai-monitor.log
```

### **Métriques de Performance**
```bash
# Test de charge avec Apache Bench
ab -n 1000 -c 10 https://formation.sama-conai.sn/

# Test avec curl
curl -w "@curl-format.txt" -o /dev/null -s https://formation.sama-conai.sn/
```

## 🔄 **Mise à Jour**

### **Mise à Jour Manuelle**
```bash
# Aller dans le répertoire du projet
cd /opt/sama-conai

# Récupérer les dernières modifications
git pull origin main

# Redéployer
cd website
./deploy.sh production
```

### **Mise à Jour Automatique**
```bash
# Script de mise à jour (créé par deploy.sh)
/usr/local/bin/update-sama-conai-formation production
```

### **Rollback**
```bash
# Lister les sauvegardes
ls -la /var/backups/sama-conai-formation_*

# Restaurer une sauvegarde
sudo cp -r /var/backups/sama-conai-formation_20250920_143000/* /var/www/html/formation.sama-conai.sn/

# Recharger Nginx
sudo systemctl reload nginx
```

## 🐳 **Déploiement Docker (Optionnel)**

### **Dockerfile**
```dockerfile
FROM nginx:alpine

# Copier les fichiers du site
COPY . /usr/share/nginx/html

# Copier la configuration Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exposer le port
EXPOSE 80

# Commande par défaut
CMD ["nginx", "-g", "daemon off;"]
```

### **Docker Compose**
```yaml
version: '3.8'

services:
  website:
    build: .
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./ssl:/etc/ssl/certs
    restart: unless-stopped
    
  certbot:
    image: certbot/certbot
    volumes:
      - ./ssl:/etc/letsencrypt
      - ./www:/var/www/certbot
    command: certonly --webroot --webroot-path=/var/www/certbot --email admin@sama-solutions.com --agree-tos --no-eff-email -d formation.sama-conai.sn
```

### **Commandes Docker**
```bash
# Build et démarrage
docker-compose up -d

# Mise à jour
docker-compose pull
docker-compose up -d

# Logs
docker-compose logs -f
```

## 🔧 **Optimisation des Performances**

### **Compression des Assets**
```bash
# CSS
uglifycss assets/css/style.css > assets/css/style.min.css

# JavaScript
uglifyjs assets/js/main.js -o assets/js/main.min.js --compress --mangle

# Images
find assets/images -name "*.jpg" -exec convert {} -quality 85 {} \;
```

### **Cache Navigateur**
```nginx
# Dans la configuration Nginx
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### **CDN (Optionnel)**
```html
<!-- Utiliser un CDN pour les librairies -->
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
```

## 🛡️ **Sécurité**

### **Firewall**
```bash
# UFW (Ubuntu)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### **Fail2Ban**
```bash
# Installation
sudo apt install fail2ban

# Configuration pour Nginx
sudo tee /etc/fail2ban/jail.local <<EOF
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 6
EOF

# Redémarrage
sudo systemctl restart fail2ban
```

### **Mise à Jour Système**
```bash
# Mises à jour automatiques
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 📋 **Checklist de Déploiement**

### **Pré-déploiement**
- [ ] Serveur configuré et accessible
- [ ] Nom de domaine pointant vers le serveur
- [ ] Nginx installé et configuré
- [ ] Certificats SSL configurés
- [ ] Firewall configuré

### **Déploiement**
- [ ] Code source récupéré
- [ ] Assets optimisés
- [ ] Fichiers copiés vers le répertoire web
- [ ] Permissions configurées
- [ ] Configuration Nginx activée
- [ ] SSL fonctionnel

### **Post-déploiement**
- [ ] Site accessible via HTTP/HTTPS
- [ ] Toutes les pages se chargent correctement
- [ ] Assets statiques servis correctement
- [ ] Formulaires fonctionnels
- [ ] Monitoring activé
- [ ] Sauvegardes configurées

## 🆘 **Dépannage**

### **Problèmes Courants**

#### **Site inaccessible**
```bash
# Vérifier Nginx
sudo systemctl status nginx
sudo nginx -t

# Vérifier les logs
sudo tail -f /var/log/nginx/error.log
```

#### **Erreur 404**
```bash
# Vérifier les permissions
ls -la /var/www/html/formation.sama-conai.sn/

# Vérifier la configuration Nginx
sudo nginx -T | grep -A 10 -B 10 "formation.sama-conai.sn"
```

#### **Problème SSL**
```bash
# Vérifier les certificats
sudo certbot certificates

# Renouveler si nécessaire
sudo certbot renew --dry-run
```

#### **Performance lente**
```bash
# Vérifier l'utilisation des ressources
htop
df -h
free -h

# Analyser les logs d'accès
sudo awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -20
```

## 📞 **Support**

### **Contacts**
- **Email** : devops@sama-solutions.com
- **GitHub Issues** : https://github.com/sama-solutions/conai/issues
- **Documentation** : https://formation.sama-conai.sn

### **Ressources**
- **Nginx Documentation** : https://nginx.org/en/docs/
- **Let's Encrypt** : https://letsencrypt.org/docs/
- **Ubuntu Server Guide** : https://ubuntu.com/server/docs

---

## 🎉 **Conclusion**

Ce guide fournit toutes les informations nécessaires pour déployer et maintenir le site web de formation SAMA CONAI. Pour toute question ou problème, n'hésitez pas à consulter la documentation ou contacter l'équipe de support.

**🇸🇳 Promoting transparency and good governance in Senegal!**

---

*Guide mis à jour le 20 septembre 2025*