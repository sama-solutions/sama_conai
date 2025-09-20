#!/bin/bash

# SAMA CONAI - Arrêt Mobile App Offline Enhanced

echo "🛑 SAMA CONAI - Arrêt Mobile App Offline Enhanced"
echo "==============================================="
echo ""

# Arrêter le processus via PID si le fichier existe
if [ -f "mobile_app_web/offline.pid" ]; then
    OFFLINE_PID=$(cat mobile_app_web/offline.pid)
    echo "🔄 Arrêt du processus Offline Enhanced PID: $OFFLINE_PID"
    kill $OFFLINE_PID 2>/dev/null || true
    rm -f mobile_app_web/offline.pid
fi

# Arrêter tous les processus server_offline_enhanced.js
echo "🔄 Arrêt de tous les processus server_offline_enhanced.js..."
pkill -f "node.*server_offline_enhanced.js" 2>/dev/null || true

# Libérer le port 3007
echo "🔄 Libération du port 3007..."
lsof -ti:3007 | xargs kill -9 2>/dev/null || true

# Attendre un peu
sleep 2

# Vérifier si le port est libre
if ! lsof -i:3007 > /dev/null 2>&1; then
    echo "✅ Mobile App Offline Enhanced arrêté avec succès"
    echo "🔓 Port 3007 libéré"
else
    echo "⚠️  Certains processus peuvent encore être actifs"
    echo "🔍 Processus restants sur le port 3007:"
    lsof -i:3007 2>/dev/null || echo "   Aucun"
fi

echo ""
echo "📋 Pour redémarrer:"
echo "   ./launch_mobile_offline.sh"
echo ""
echo "🌐 Autres versions disponibles:"
echo "   • Version standard: ./launch_mobile_app.sh (port 3005)"
echo "   • Version enhanced: ./launch_mobile_enhanced.sh (port 3006)"
echo ""