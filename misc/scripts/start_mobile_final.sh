#!/bin/bash

echo "🚀 Démarrage Final - Application Mobile SAMA CONAI"
echo "=================================================="

# Vérifier si le répertoire existe
if [ ! -d "mobile_app_web" ]; then
    echo "❌ Erreur: Le répertoire mobile_app_web n'existe pas"
    exit 1
fi

# Aller dans le répertoire
cd mobile_app_web

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ Erreur: Node.js n'est pas installé"
    exit 1
fi

# Vérifier si les dépendances sont installées
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Erreur lors de l'installation des dépendances"
        exit 1
    fi
fi

# Arrêter les processus existants
echo "🛑 Arrêt des processus existants..."
pkill -f "node.*server.js" 2>/dev/null || true
sleep 2

# Vérifier que le backend Odoo fonctionne
echo "🔍 Vérification du backend Odoo..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8077 | grep -q "200"; then
    echo "✅ Backend Odoo accessible sur http://localhost:8077"
else
    echo "⚠️ Backend Odoo non accessible - l'application fonctionnera en mode démonstration"
fi

# Démarrer l'application
echo "🎯 Démarrage du serveur mobile..."
echo "📱 L'application sera accessible sur http://localhost:3005"
echo "👤 Credentials: admin/admin"
echo ""
echo "🔄 Démarrage en cours..."

# Lancer le serveur
node server.js

echo ""
echo "🛑 Serveur arrêté"