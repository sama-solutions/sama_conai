#!/bin/bash

# SAMA CONAI - Arrêt Mobile App Enhanced

echo "🛑 SAMA CONAI - Arrêt Mobile App Enhanced"
echo "========================================"
echo ""

# Arrêter le processus via PID si le fichier existe
if [ -f "mobile_app_web/enhanced.pid" ]; then
    ENHANCED_PID=$(cat mobile_app_web/enhanced.pid)
    echo "🔄 Arrêt du processus Enhanced PID: $ENHANCED_PID"
    kill $ENHANCED_PID 2>/dev/null || true
    rm -f mobile_app_web/enhanced.pid
fi

# Arrêter tous les processus server_enhanced.js
echo "🔄 Arrêt de tous les processus server_enhanced.js..."
pkill -f "node.*server_enhanced.js" 2>/dev/null || true

# Libérer le port 3006
echo "🔄 Libération du port 3006..."
lsof -ti:3006 | xargs kill -9 2>/dev/null || true

# Attendre un peu
sleep 2

# Vérifier si le port est libre
if ! lsof -i:3006 > /dev/null 2>&1; then
    echo "✅ Mobile App Enhanced arrêté avec succès"
    echo "🔓 Port 3006 libéré"
else
    echo "⚠️  Certains processus peuvent encore être actifs"
    echo "🔍 Processus restants sur le port 3006:"
    lsof -i:3006 2>/dev/null || echo "   Aucun"
fi

echo ""
echo "📋 Pour redémarrer:"
echo "   ./launch_mobile_enhanced.sh"
echo ""