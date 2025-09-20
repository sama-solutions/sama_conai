#!/bin/bash

# 🇸🇳 SAMA CONAI - Script d'arrêt amélioré pour serveur Odoo réel

echo "🇸🇳 SAMA CONAI - Arrêt serveur Odoo réel"
echo "======================================="

# Arrêter par PID si disponible
if [ -f "logs/odoo_real_server.pid" ]; then
    PID=$(cat logs/odoo_real_server.pid)
    echo "🔄 Arrêt du serveur (PID: $PID)..."
    
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        sleep 2
        
        # Vérifier si le processus est arrêté
        if kill -0 $PID 2>/dev/null; then
            echo "⚠️  Arrêt forcé..."
            kill -9 $PID
        fi
        
        echo "✅ Serveur arrêté (PID: $PID)"
    else
        echo "ℹ️  Processus PID $PID déjà arrêté"
    fi
    
    # Supprimer le fichier PID
    rm -f logs/odoo_real_server.pid
fi

# Arrêter tous les processus server_odoo_real.js
echo "🔄 Vérification des processus restants..."
PIDS=$(pgrep -f "server_odoo_real.js")

if [ ! -z "$PIDS" ]; then
    echo "🛑 Arrêt des processus restants: $PIDS"
    pkill -f "server_odoo_real.js"
    sleep 2
    
    # Vérification finale
    REMAINING=$(pgrep -f "server_odoo_real.js")
    if [ ! -z "$REMAINING" ]; then
        echo "⚠️  Arrêt forcé des processus restants..."
        pkill -9 -f "server_odoo_real.js"
    fi
fi

echo "✅ Tous les serveurs Odoo réels sont arrêtés"

# Vérifier les ports
PORT_CHECK=$(netstat -tlnp 2>/dev/null | grep ":3008 " || true)
if [ ! -z "$PORT_CHECK" ]; then
    echo "⚠️  Port 3008 encore utilisé:"
    echo "$PORT_CHECK"
else
    echo "✅ Port 3008 libéré"
fi