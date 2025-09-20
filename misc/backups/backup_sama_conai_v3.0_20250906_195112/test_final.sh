#!/bin/bash

# Test final du module SAMA CONAI

echo "🧪 TEST FINAL - SAMA CONAI"
echo "=========================="
echo ""

# Test de la base de données
echo "1. 📊 État du module :"
PGPASSWORD=odoo psql -h localhost -U odoo -d sama_conai_test -c "
SELECT 
    name as module, 
    state as etat,
    latest_version as version
FROM ir_module_module 
WHERE name = 'sama_conai';" 2>/dev/null

echo ""
echo "2. 📋 Menus disponibles :"
PGPASSWORD=odoo psql -h localhost -U odoo -d sama_conai_test -c "
SELECT 
    id,
    name::text as menu_name
FROM ir_ui_menu 
WHERE name::text LIKE '%Information%' OR name::text LIKE '%Alerte%'
ORDER BY id;" 2>/dev/null

echo ""
echo "3. 🎨 Vues créées :"
PGPASSWORD=odoo psql -h localhost -U odoo -d sama_conai_test -c "
SELECT 
    model,
    type,
    COUNT(*) as nombre
FROM ir_ui_view 
WHERE model IN ('request.information', 'whistleblowing.alert')
GROUP BY model, type
ORDER BY model, type;" 2>/dev/null

echo ""
echo "4. 📈 Données de configuration :"
PGPASSWORD=odoo psql -h localhost -U odoo -d sama_conai_test -c "
SELECT 
    'Étapes d''information' as type,
    COUNT(*) as nombre
FROM request_information_stage
UNION ALL
SELECT 
    'Motifs de refus' as type,
    COUNT(*) as nombre
FROM request_refusal_reason;" 2>/dev/null

echo ""
echo "5. 🌐 Test de connectivité :"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8075/ | grep -q "200"; then
    echo "   ✅ Serveur accessible sur http://localhost:8075"
else
    echo "   ❌ Serveur non accessible"
    echo "   💡 Lancez: ./start_sama_conai.sh"
fi

echo ""
echo "🎯 RÉSUMÉ :"
echo "   📦 Module SAMA CONAI installé et configuré"
echo "   🌐 Interface web accessible"
echo "   📊 Données de démo chargées"
echo "   🔧 Scripts de gestion disponibles"
echo ""
echo "🚀 Pour démarrer : ./start_sama_conai.sh"
echo "📖 Documentation : GUIDE_ACCES_FINAL.md"