#!/bin/bash

# Script de lancement de l'application mobile SAMA CONAI
# Version web de démonstration

echo "🚀 LANCEMENT APPLICATION MOBILE SAMA CONAI"
echo "=========================================="

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ Node.js n'est pas installé"
    echo "   Veuillez installer Node.js pour continuer"
    exit 1
fi

echo "✅ Node.js détecté: $(node --version)"

# Aller dans le dossier de l'application mobile web
cd mobile_app_web

# Vérifier si les dépendances sont installées
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Erreur lors de l'installation des dépendances"
        exit 1
    fi
    echo "✅ Dépendances installées"
fi

# Arrêter les processus existants sur le port 3001
echo "🧹 Nettoyage des processus existants..."
pkill -f "node.*server.js" 2>/dev/null || true

# Attendre un peu
sleep 2

# Démarrer le serveur en arrière-plan
echo "🌐 Démarrage du serveur mobile..."
nohup node server.js > mobile_app.log 2>&1 &
SERVER_PID=$!

# Attendre que le serveur démarre
echo "⏳ Attente du démarrage du serveur..."
sleep 3

# Vérifier si le serveur est accessible
if curl -s http://localhost:3001 > /dev/null; then
    echo "✅ Serveur mobile démarré avec succès !"
    echo ""
    echo "📱 APPLICATION MOBILE SAMA CONAI LANCÉE"
    echo "======================================"
    echo ""
    echo "🌐 URL d'accès: http://localhost:3001"
    echo "📱 Interface: Simulation mobile dans le navigateur"
    echo "🔧 PID du serveur: $SERVER_PID"
    echo ""
    echo "📋 FONCTIONNALITÉS DISPONIBLES:"
    echo "   👥 Interface Citoyen"
    echo "   📊 Tableau de bord personnel"
    echo "   📄 Gestion des demandes"
    echo "   🚨 Signalements d'alerte"
    echo "   📈 Statistiques publiques"
    echo ""
    echo "🔧 GESTION:"
    echo "   📋 Logs: tail -f mobile_app_web/mobile_app.log"
    echo "   🛑 Arrêt: kill $SERVER_PID"
    echo "   🔄 Redémarrage: ./launch_mobile_app.sh"
    echo ""
    echo "💡 Ouvrez http://localhost:3001 dans votre navigateur"
    echo "   pour accéder à l'interface mobile de démonstration"
    echo ""
    echo "🎯 L'APPLICATION MOBILE EST PRÊTE !"
else
    echo "❌ Erreur: Le serveur ne répond pas"
    echo "📋 Vérifiez les logs: cat mobile_app_web/mobile_app.log"
    exit 1
fi