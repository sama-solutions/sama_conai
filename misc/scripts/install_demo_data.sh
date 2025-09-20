#!/bin/bash

# Installation des données de démo SAMA CONAI

echo "📊 INSTALLATION DONNÉES DE DÉMO SAMA CONAI"
echo "=========================================="

DB_NAME="sama_conai_test"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_ADDONS_PATH="/var/odoo/odoo18/addons"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

echo "Base de données: $DB_NAME"
echo ""

# Activation environnement
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

echo "1. Mise à jour du module avec données de démo..."
python3 odoo-bin \
  -d "$DB_NAME" \
  -u sama_conai \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --stop-after-init \
  --log-level=info

echo ""
echo "2. Vérification des données installées..."
export PGPASSWORD=odoo

psql -h localhost -U odoo -d $DB_NAME -c "
SELECT 
    'Demandes d''information' as type, 
    COUNT(*) as count 
FROM request_information
UNION ALL
SELECT 
    'Signalements d''alerte' as type, 
    COUNT(*) as count 
FROM whistleblowing_alert
UNION ALL
SELECT 
    'Étapes d''information' as type, 
    COUNT(*) as count 
FROM request_information_stage
UNION ALL
SELECT 
    'Motifs de refus' as type, 
    COUNT(*) as count 
FROM request_refusal_reason;"

echo ""
echo "3. Vérification des menus:"
psql -h localhost -U odoo -d $DB_NAME -c "
SELECT id, name, parent_id, sequence 
FROM ir_ui_menu 
WHERE name ILIKE '%information%' OR name ILIKE '%alerte%' OR name ILIKE '%sama%' OR name ILIKE '%conai%'
ORDER BY sequence, name;"

echo ""
echo "4. Test des actions de menu:"
psql -h localhost -U odoo -d $DB_NAME -c "
SELECT m.name as menu_name, a.name as action_name, a.res_model
FROM ir_ui_menu m
LEFT JOIN ir_act_window a ON m.action = CONCAT('ir.actions.act_window,', a.id)
WHERE m.name ILIKE '%information%' OR m.name ILIKE '%alerte%'
ORDER BY m.name;"

echo ""
echo "🎯 RÉSULTAT:"
echo "   Si les données sont présentes, le module est prêt !"
echo "   Accès: http://localhost:8075/web (admin/admin)"
echo ""
echo "🔧 Si problème de menu:"
echo "   - Redémarrer le serveur Odoo"
echo "   - Vider le cache navigateur"
echo "   - Vérifier les droits utilisateur"