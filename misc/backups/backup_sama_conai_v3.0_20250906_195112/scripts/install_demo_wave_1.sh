#!/bin/bash

# Script d'installation/mise à jour pour la vague 1 des données de démo

echo "🚀 Installation/Mise à jour SAMA CONAI - Vague 1 des données de démo"
echo "=================================================================="

# Variables
DB_NAME="sama_conai_demo"
ODOO_BIN="./odoo-bin"
ODOO_CONF="odoo.conf"

# Vérifier si Odoo est disponible
if [ ! -f "$ODOO_BIN" ]; then
    echo "❌ Odoo non trouvé. Assurez-vous d'être dans le répertoire racine d'Odoo."
    exit 1
fi

# Vérifier si le fichier de configuration existe
if [ ! -f "$ODOO_CONF" ]; then
    echo "❌ Fichier de configuration $ODOO_CONF non trouvé."
    exit 1
fi

echo "📦 Mise à jour du module sama_conai..."
$ODOO_BIN -c $ODOO_CONF -d $DB_NAME -u sama_conai --stop-after-init

if [ $? -eq 0 ]; then
    echo "✅ Module mis à jour avec succès!"
    echo ""
    echo "🧪 Lancement du test des données de démo..."
    echo "exec(open('custom_addons/sama_conai/scripts/test_demo_wave_1.py').read())" | $ODOO_BIN shell -c $ODOO_CONF -d $DB_NAME
else
    echo "❌ Erreur lors de la mise à jour du module."
    exit 1
fi

echo ""
echo "🎯 Pour tester manuellement:"
echo "   1. Connectez-vous à Odoo"
echo "   2. Allez dans 'Accès à l'Information' > 'Demandes d'Information'"
echo "   3. Vérifiez la vue Kanban avec les données de démo"
echo "   4. Testez les vues Graph et Pivot"
echo ""
echo "✅ Installation terminée!"