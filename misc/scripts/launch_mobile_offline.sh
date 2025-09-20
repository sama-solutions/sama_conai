#!/bin/bash

# SAMA CONAI - Lancement Mobile App Offline Enhanced
# Version avec mode offline complet et synchronisation

echo "🚀 SAMA CONAI - Mobile App Offline Enhanced"
echo "==========================================="
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

# Arrêter les processus existants sur le port 3007
echo "🔄 Arrêt des processus existants..."
pkill -f "node.*server_offline_enhanced.js" 2>/dev/null || true
lsof -ti:3007 | xargs kill -9 2>/dev/null || true

# Attendre un peu
sleep 2

# Démarrer le serveur offline enhanced
echo "🚀 Démarrage du serveur SAMA CONAI Offline Enhanced..."
echo "📱 Interface: Neumorphique avec mode offline complet"
echo "🔄 Synchronisation: Automatique et manuelle"
echo "📊 Navigation: 3 niveaux vers backend Odoo"
echo "🔐 Auth: JWT + Sessions sécurisées"
echo ""

# Démarrer en arrière-plan et sauvegarder le PID
nohup node server_offline_enhanced.js > offline.log 2>&1 &
OFFLINE_PID=$!
echo $OFFLINE_PID > offline.pid

echo "✅ Serveur Offline Enhanced démarré avec PID: $OFFLINE_PID"
echo "🌐 URL: http://localhost:3007"
echo "👤 Credentials: admin/admin"
echo "📋 Log: mobile_app_web/offline.log"
echo ""

# Attendre que le serveur démarre
echo "⏳ Vérification du démarrage..."
sleep 3

# Vérifier si le serveur répond
if curl -s http://localhost:3007 > /dev/null; then
    echo "✅ Serveur Offline Enhanced opérationnel !"
    echo ""
    echo "🎉 SAMA CONAI OFFLINE ENHANCED v3.3"
    echo "==================================="
    echo "🌐 URL: http://localhost:3007"
    echo "📱 Interface: Neumorphique avec mode offline complet"
    echo "🔄 Synchronisation: Automatique et manuelle"
    echo "📊 Navigation: 3 niveaux vers backend Odoo"
    echo "🔐 Auth: JWT + Sessions sécurisées"
    echo "👤 Credentials: admin/admin"
    echo "🚀 Prêt pour une expérience offline révolutionnaire !"
    echo ""
    echo "📋 Fonctionnalités principales:"
    echo "   • Mode offline complet avec stockage local"
    echo "   • Synchronisation automatique à la reconnexion"
    echo "   • Navigation à 3 niveaux vers backend Odoo"
    echo "   • Formulaire de demande corrigé et optimisé"
    echo "   • Titre SAMA CONAI centré sur toutes les pages"
    echo "   • Interface adaptée à l'écran mobile"
    echo "   • Gestion intelligente du contenu scrollable"
    echo ""
    echo "🔧 Commandes utiles:"
    echo "   • Arrêter: ./stop_mobile_offline.sh"
    echo "   • Logs: tail -f mobile_app_web/offline.log"
    echo "   • Status: ps aux | grep server_offline_enhanced"
    echo ""
    echo "🌐 Autres versions disponibles:"
    echo "   • Version standard: http://localhost:3005"
    echo "   • Version enhanced: http://localhost:3006"
    echo "   • Version offline: http://localhost:3007 (actuelle)"
    echo ""
else
    echo "❌ Erreur: Le serveur ne répond pas"
    echo "📋 Vérifiez les logs: tail -f mobile_app_web/offline.log"
    exit 1
fi