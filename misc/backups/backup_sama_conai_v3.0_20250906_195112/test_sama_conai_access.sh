#!/bin/bash

# Test d'accès au module SAMA CONAI

echo "🧪 TEST D'ACCÈS AU MODULE SAMA CONAI"
echo "===================================="

ODOO_URL="http://localhost:8075"
DB_NAME="sama_conai_test"

echo "URL Odoo: $ODOO_URL"
echo "Base de données: $DB_NAME"
echo ""

echo "1. Test de la page de connexion:"
curl -s -o /dev/null -w "   Status: %{http_code}\n" "$ODOO_URL/web/login"

echo ""
echo "2. Test direct de la base de données:"
export PGPASSWORD=odoo

echo "   Modules installés:"
psql -h localhost -U odoo -d $DB_NAME -c "
SELECT name, state, latest_version 
FROM ir_module_module 
WHERE name IN ('sama_conai', 'base', 'mail', 'portal', 'hr')
ORDER BY name;" 2>/dev/null

echo ""
echo "   Tables du module SAMA CONAI:"
psql -h localhost -U odoo -d $DB_NAME -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_name LIKE '%request%' OR table_name LIKE '%whistleblowing%'
ORDER BY table_name;" 2>/dev/null

echo ""
echo "   Données de démo:"
psql -h localhost -U odoo -d $DB_NAME -c "
SELECT 
    'Demandes d''information' as type, 
    COUNT(*) as count 
FROM request_information
UNION ALL
SELECT 
    'Signalements d''alerte' as type, 
    COUNT(*) as count 
FROM whistleblowing_alert;" 2>/dev/null

echo ""
echo "   Menus SAMA CONAI:"
psql -h localhost -U odoo -d $DB_NAME -c "
SELECT name, parent_id 
FROM ir_ui_menu 
WHERE name ILIKE '%sama%' OR name ILIKE '%conai%' OR name ILIKE '%information%' OR name ILIKE '%alerte%'
ORDER BY name;" 2>/dev/null

echo ""
echo "3. Test des vues:"
psql -h localhost -U odoo -d $DB_NAME -c "
SELECT model, type, COUNT(*) as count
FROM ir_ui_view 
WHERE model IN ('request.information', 'whistleblowing.alert')
GROUP BY model, type
ORDER BY model, type;" 2>/dev/null

echo ""
echo "🎯 INSTRUCTIONS D'ACCÈS:"
echo "   1. Ouvrir: $ODOO_URL/web"
echo "   2. Se connecter avec: admin / admin"
echo "   3. Chercher le menu 'Accès à l'Information'"
echo "   4. Ou aller directement aux applications installées"
echo ""
echo "🔍 Si le menu n'apparaît pas:"
echo "   - Vérifier les droits d'accès utilisateur"
echo "   - Actualiser la liste des modules"
echo "   - Redémarrer le serveur Odoo"