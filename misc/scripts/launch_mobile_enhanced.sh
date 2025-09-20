#!/bin/bash

# SAMA CONAI - Lancement Mobile App Enhanced
# Version avec notifications temps réel et assistant IA

echo "🚀 SAMA CONAI - Mobile App Enhanced"
echo "=================================="
echo ""

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ Node.js n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier si npm est installé
if ! command -v npm &> /dev/null; then
    echo "❌ npm n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Aller dans le répertoire mobile_app_web
cd mobile_app_web

# Vérifier si les dépendances sont installées
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
fi

# Arrêter les processus existants sur le port 3006
echo "🔄 Arrêt des processus existants..."
pkill -f "node.*server_enhanced.js" 2>/dev/null || true
lsof -ti:3006 | xargs kill -9 2>/dev/null || true

# Attendre un peu
sleep 2

# Démarrer le serveur enhanced
echo "🚀 Démarrage du serveur SAMA CONAI Enhanced..."
echo "📱 Interface: Neumorphique avec notifications temps réel"
echo "🔔 WebSockets: Activés"
echo "🤖 Assistant IA: Intégré"
echo "🔐 Auth: JWT + Sessions sécurisées"
echo ""

# Démarrer en arrière-plan et sauvegarder le PID
nohup node server_enhanced.js > enhanced.log 2>&1 &
ENHANCED_PID=$!
echo $ENHANCED_PID > enhanced.pid

echo "✅ Serveur Enhanced démarré avec PID: $ENHANCED_PID"
echo "🌐 URL: http://localhost:3006"
echo "👤 Credentials: admin/admin"
echo "📋 Log: mobile_app_web/enhanced.log"
echo ""

# Attendre que le serveur démarre
echo "⏳ Vérification du démarrage..."
sleep 3

# Vérifier si le serveur répond
if curl -s http://localhost:3006 > /dev/null; then
    echo "✅ Serveur Enhanced opérationnel !"
    echo ""
    echo "🎉 SAMA CONAI ENHANCED MOBILE v3.2"
    echo "==================================="
    echo "🌐 URL: http://localhost:3006"
    echo "📱 Interface: Neumorphique avec notifications temps réel"
    echo "🔔 WebSockets: Activés pour notifications live"
    echo "🤖 Assistant IA: Intégré et fonctionnel"
    echo "📊 Analytics: Temps réel"
    echo "🎨 Thèmes: Adaptatifs avec mode sombre"
    echo "👤 Credentials: admin/admin"
    echo "🚀 Prêt pour une expérience révolutionnaire !"
    echo ""
    echo "📋 Nouvelles fonctionnalités:"
    echo "   • Notifications push en temps réel"
    echo "   • Assistant IA conversationnel"
    echo "   • Authentification JWT sécurisée"
    echo "   • Interface neumorphique améliorée"
    echo "   • Analytics et métriques en direct"
    echo "   • Système de sessions avancé"
    echo ""
    echo "🔧 Commandes utiles:"
    echo "   • Arrêter: ./stop_mobile_enhanced.sh"
    echo "   • Logs: tail -f mobile_app_web/enhanced.log"
    echo "   • Status: ps aux | grep server_enhanced"
    echo ""
else
    echo "❌ Erreur: Le serveur ne répond pas"
    echo "📋 Vérifiez les logs: tail -f mobile_app_web/enhanced.log"
    exit 1
fi