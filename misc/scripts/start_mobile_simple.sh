#!/bin/bash

echo "🚀 Démarrage Application Mobile SAMA CONAI"
echo "=========================================="

# Aller dans le dossier mobile_app_web
cd mobile_app_web

# Configurer les variables d'environnement
export ODOO_URL="http://localhost:8077"
export ODOO_DB="sama_conai_test"
export PORT="3005"

# Démarrer l'application
echo "📱 Lancement sur http://localhost:3005"
echo "🔗 Backend Odoo: http://localhost:8077"
echo "💾 Base de données: sama_conai_test"
echo ""

node server.js