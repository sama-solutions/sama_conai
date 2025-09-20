#!/bin/bash

echo "🔄 Redémarrage de l'application mobile SAMA CONAI..."

# Arrêter l'application mobile actuelle
echo "🛑 Arrêt de l'application mobile..."
pkill -f "node server.js" 2>/dev/null || true
sleep 2

# Redémarrer l'application mobile
echo "🚀 Redémarrage de l'application mobile..."
cd mobile_app_web
nohup node server.js > mobile_app.log 2>&1 &
MOBILE_PID=$!

echo "✅ Application mobile redémarrée avec PID: $MOBILE_PID"
echo "📋 Logs: $(pwd)/mobile_app.log"

# Attendre le démarrage
echo "⏳ Attente du démarrage (5 secondes)..."
sleep 5

# Tester la connexion
echo "🧪 Test de la connexion..."
if curl -s --connect-timeout 5 http://localhost:3005 > /dev/null; then
    echo "✅ Application mobile accessible sur http://localhost:3005"
    echo "🎨 Interface neumorphique avec données réelles d'Odoo"
    echo "👤 Credentials: admin/admin ou demo@sama-conai.sn/demo123"
else
    echo "❌ Application mobile non accessible"
    echo "📋 Vérifiez les logs: $(pwd)/mobile_app.log"
fi

echo ""
echo "🎯 SAMA CONAI Mobile - Interface Neumorphique"
echo "📱 URL: http://localhost:3005"
echo "🔗 Données: Odoo réelles (si module installé)"
echo "🎨 Design: Neumorphique avec 3 thèmes"