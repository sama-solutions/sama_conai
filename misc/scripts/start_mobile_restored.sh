#!/bin/bash

echo "🚀 Démarrage de l'application mobile SAMA CONAI restaurée..."

# Vérifier si le répertoire existe
if [ ! -d "mobile_app_web" ]; then
    echo "❌ Erreur: Le répertoire mobile_app_web n'existe pas"
    exit 1
fi

# Aller dans le répertoire
cd mobile_app_web

# Vérifier si les dépendances sont installées
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
fi

# Arrêter les processus existants
echo "🛑 Arrêt des processus existants..."
pkill -f "node.*server.js" 2>/dev/null || true

# Attendre un peu
sleep 2

# Démarrer l'application
echo "🎯 Démarrage du serveur mobile sur le port 3001..."
node server.js &

# Attendre que le serveur démarre
sleep 3

# Vérifier que le serveur fonctionne
if curl -s http://localhost:3001 > /dev/null; then
    echo "✅ Application mobile démarrée avec succès !"
    echo "🌐 Accès: http://localhost:3001"
    echo "👤 Credentials: admin/admin"
    echo ""
    echo "📊 Backend Odoo: http://localhost:8077"
    echo "📱 Application mobile: http://localhost:3001"
else
    echo "❌ Erreur: Le serveur ne répond pas"
    exit 1
fi