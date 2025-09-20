#!/bin/bash

# Arreter les processus Odoo existants sur le port 8070
lsof -t -i:8070 | xargs --no-run-if-empty kill
sleep 2

# Activer l'environnement virtuel
source /home/grand-as/odoo18-venv/bin/activate

# Définir les variables d'environnement
export PGUSER=odoo
export PGPASSWORD=odoo

# Supprimer l'ancienne base de données de test
dropdb --if-exists sama_conai_test

# Démarrer Odoo et initialiser
/var/odoo/odoo18/odoo-bin --addons-path=/var/odoo/odoo18/odoo/addons,/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons -d sama_conai_test -i sama_conai --db-filter=sama_conai_test --http-port=8070 --stop-after-init
