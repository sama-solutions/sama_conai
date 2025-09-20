#!/bin/bash

# Installation manuelle SAMA CONAI

echo "🔧 INSTALLATION MANUELLE SAMA CONAI"
echo "==================================="
echo ""

DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

echo "Instructions d'installation manuelle:"
echo ""

echo "1. 🐘 Configuration PostgreSQL"
echo "   Créer un fichier ~/.pgpass avec:"
echo "   localhost:5432:*:odoo:odoo"
echo "   chmod 600 ~/.pgpass"
echo ""

echo "2. 🗄️ Création de la base de données"
echo "   Exécuter ces commandes:"
echo "   export PGPASSWORD=odoo"
echo "   dropdb -h localhost -U odoo $DB_NAME 2>/dev/null || true"
echo "   createdb -h localhost -U odoo $DB_NAME"
echo ""

echo "3. 🐍 Activation de l'environnement virtuel"
echo "   source $VENV_PATH/bin/activate"
echo "   cd $ODOO_PATH"
echo ""

echo "4. 📦 Installation du module"
echo "   python3 odoo-bin \\"
echo "     -d $DB_NAME \\"
echo "     -i sama_conai \\"
echo "     --addons-path=$CUSTOM_ADDONS_PATH \\"
echo "     --db_host=localhost \\"
echo "     --db_user=odoo \\"
echo "     --db_password=odoo \\"
echo "     --stop-after-init \\"
echo "     --without-demo=all"
echo ""

echo "5. 🚀 Démarrage du serveur"
echo "   python3 odoo-bin \\"
echo "     -d $DB_NAME \\"
echo "     --addons-path=$CUSTOM_ADDONS_PATH \\"
echo "     --db_host=localhost \\"
echo "     --db_user=odoo \\"
echo "     --db_password=odoo"
echo ""

echo "6. 🌐 Accès web"
echo "   URL: http://localhost:8069"
echo "   Base: $DB_NAME"
echo "   User: admin / Pass: admin"
echo ""

# Créer le fichier pgpass automatiquement
echo "🔧 Configuration automatique de PostgreSQL..."
echo "localhost:5432:*:odoo:odoo" > ~/.pgpass
chmod 600 ~/.pgpass
echo "✅ Fichier ~/.pgpass créé"

# Créer un script d'exécution direct
cat > install_now.sh << EOF
#!/bin/bash
export PGPASSWORD=odoo
echo "Suppression base existante..."
dropdb -h localhost -U odoo $DB_NAME 2>/dev/null || echo "Aucune base à supprimer"

echo "Création nouvelle base..."
createdb -h localhost -U odoo $DB_NAME

echo "Activation environnement..."
source $VENV_PATH/bin/activate
cd $ODOO_PATH

echo "Installation module..."
python3 odoo-bin \\
  -d $DB_NAME \\
  -i sama_conai \\
  --addons-path=$CUSTOM_ADDONS_PATH \\
  --db_host=localhost \\
  --db_user=odoo \\
  --db_password=odoo \\
  --stop-after-init \\
  --without-demo=all

echo "✅ Installation terminée!"
echo "Pour démarrer le serveur:"
echo "cd $ODOO_PATH"
echo "source $VENV_PATH/bin/activate"
echo "python3 odoo-bin -d $DB_NAME --addons-path=$CUSTOM_ADDONS_PATH --db_host=localhost --db_user=odoo --db_password=odoo"
EOF

chmod +x install_now.sh

echo ""
echo "📋 Script d'installation automatique créé: install_now.sh"
echo "   Exécuter: ./install_now.sh"
echo ""
echo "🔍 En cas de problème, vérifier les logs:"
echo "   tail -f /var/log/odoo/odoo.log"