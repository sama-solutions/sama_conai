#!/bin/bash
export PGPASSWORD=odoo
echo "Suppression base existante..."
dropdb -h localhost -U odoo sama_conai_demo 2>/dev/null || echo "Aucune base à supprimer"

echo "Création nouvelle base..."
createdb -h localhost -U odoo sama_conai_demo

echo "Activation environnement..."
source /home/grand-as/odoo18-venv/bin/activate
cd /var/odoo/odoo18

echo "Installation module..."
python3 odoo-bin \
  -d sama_conai_demo \
  -i sama_conai \
  --addons-path=/home/grand-as/psagsn/custom_addons \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --stop-after-init \
  --without-demo=all

echo "✅ Installation terminée!"
echo "Pour démarrer le serveur:"
echo "cd /var/odoo/odoo18"
echo "source /home/grand-as/odoo18-venv/bin/activate"
echo "python3 odoo-bin -d sama_conai_demo --addons-path=/home/grand-as/psagsn/custom_addons --db_host=localhost --db_user=odoo --db_password=odoo"
