#!/bin/bash

# Démarrage du serveur SAMA CONAI avec données de démo

echo "🚀 DÉMARRAGE SAMA CONAI AVEC DONNÉES DE DÉMO"
echo "============================================"
echo ""
echo "📋 Module : SAMA CONAI - Transparence Sénégal"
echo "🌐 URL    : http://localhost:8075"
echo "👤 Login  : admin / admin"
echo "📊 Base   : sama_conai_demo (avec données de démo)"
echo ""
echo "📊 DONNÉES DE DÉMO DISPONIBLES :"
echo "   📋 6 Demandes d'information (citoyens, journalistes, chercheurs, avocats, ONG)"
echo "   🚨 6 Signalements d'alerte (corruption, fraude, harcèlement, environnement)"
echo "   🎯 États variés : nouveau, en cours, validé, répondu, refusé, résolu"
echo "   🔥 Priorités : normale, élevée, urgente"
echo ""
echo "⏳ Démarrage en cours..."
echo ""

# Activation environnement et démarrage
source /home/grand-as/odoo18-venv/bin/activate
cd /var/odoo/odoo18

python3 odoo-bin \
  -d sama_conai_demo \
  --addons-path="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --http-port=8075 \
  --log-level=info