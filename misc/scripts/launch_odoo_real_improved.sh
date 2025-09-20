#!/bin/bash

# 🇸🇳 SAMA CONAI - Script de lancement amélioré pour serveur Odoo réel
# Port 3008 - Version avec données Odoo réelles

echo "🇸🇳 SAMA CONAI - Lancement serveur Odoo réel (Port 3008)"
echo "=================================================="

# Vérifier si le répertoire existe
if [ ! -d "mobile_app_web" ]; then
    echo "❌ Erreur: Répertoire mobile_app_web non trouvé"
    exit 1
fi

# Aller dans le répertoire
cd mobile_app_web

# Vérifier si le fichier serveur existe
if [ ! -f "server_odoo_real.js" ]; then
    echo "❌ Erreur: Fichier server_odoo_real.js non trouvé"
    exit 1
fi

# Arrêter le processus existant s'il existe
echo "🔄 Vérification des processus existants..."
pkill -f "server_odoo_real.js" 2>/dev/null || true

# Attendre un peu
sleep 2

# Créer le répertoire de logs s'il n'existe pas
mkdir -p ../logs

# Lancer le serveur avec nohup et redirection complète
echo "🚀 Lancement du serveur Odoo réel..."
nohup node server_odoo_real.js > ../logs/odoo_real_$(date +%Y%m%d_%H%M%S).log 2>&1 &

# Récupérer le PID
SERVER_PID=$!

# Attendre un peu pour que le serveur démarre
sleep 5

# Vérifier si le processus est toujours actif
if kill -0 $SERVER_PID 2>/dev/null; then
    echo "✅ Serveur lancé avec succès!"
    echo "📋 PID: $SERVER_PID"
    echo "📱 URL: http://localhost:3008/"
    echo "🔗 Test: http://localhost:3008/api/odoo/test"
    echo "📊 Comparaison: http://localhost:3007/enriched"
    echo ""
    echo "📝 Logs: logs/odoo_real_$(date +%Y%m%d_%H%M%S).log"
    echo ""
    echo "🛑 Pour arrêter: ./stop_odoo_real_sama_conai.sh"
    
    # Sauvegarder le PID
    echo $SERVER_PID > ../logs/odoo_real_server.pid
    
else
    echo "❌ Erreur: Le serveur n'a pas pu démarrer"
    echo "📝 Vérifiez les logs dans le répertoire logs/"
    exit 1
fi