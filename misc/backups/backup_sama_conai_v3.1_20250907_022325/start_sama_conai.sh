#!/bin/bash

# Script de démarrage simple pour SAMA CONAI

echo "🚀 DÉMARRAGE SAMA CONAI"
echo "======================"
echo ""
echo "📋 Module : SAMA CONAI - Transparence Sénégal"
echo "🌐 URL    : http://localhost:8075"
echo "👤 Login  : admin / admin"
echo ""
echo "⏳ Démarrage en cours..."
echo ""

# Activation environnement et démarrage
source /home/grand-as/odoo18-venv/bin/activate
cd /var/odoo/odoo18

python3 odoo-bin \
  -d sama_conai_test \
  --addons-path="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --http-port=8075 \
  --log-level=info