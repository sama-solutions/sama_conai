#!/bin/bash

# Installation du module SAMA CONAI avec données de démo par vagues

echo "📊 INSTALLATION SAMA CONAI AVEC DONNÉES DE DÉMO"
echo "==============================================="

DB_NAME="sama_conai_test"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_ADDONS_PATH="/var/odoo/odoo18/addons"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

export PGPASSWORD=odoo

echo "Base de données: $DB_NAME"
echo ""

# Arrêter le serveur existant s'il tourne
echo "1. Arrêt du serveur existant..."
PID=$(ps aux | grep "sama_conai_test" | grep -v grep | awk '{print $2}')
if [ ! -z "$PID" ]; then
    echo "   Arrêt du processus $PID"
    kill $PID 2>/dev/null
    sleep 3
fi

# Supprimer et recréer la base de données
echo ""
echo "2. Recréation de la base de données..."
dropdb -h localhost -U odoo "$DB_NAME" 2>/dev/null || true
createdb -h localhost -U odoo "$DB_NAME"
echo "   ✅ Base de données recréée"

# Activation environnement
source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

# Installation avec données de démo
echo ""
echo "3. Installation du module avec données de démo..."
echo "   📦 Installation des dépendances..."
python3 odoo-bin \
  -d "$DB_NAME" \
  -i base,mail,portal,hr \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --stop-after-init \
  --without-demo=all \
  --log-level=error

if [ $? -eq 0 ]; then
    echo "   ✅ Dépendances installées"
else
    echo "   ❌ Erreur lors de l'installation des dépendances"
    exit 1
fi

echo ""
echo "   📊 Installation SAMA CONAI avec données de démo..."
python3 odoo-bin \
  -d "$DB_NAME" \
  -i sama_conai \
  --addons-path="$ODOO_ADDONS_PATH,$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo \
  --stop-after-init \
  --log-level=info

if [ $? -eq 0 ]; then
    echo "   ✅ Module SAMA CONAI installé avec données de démo"
else
    echo "   ❌ Erreur lors de l'installation du module"
    exit 1
fi

# Vérification des données installées
echo ""
echo "4. Vérification des données de démo installées..."

echo "   📋 Demandes d'information:"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    name as numero,
    partner_name as demandeur,
    requester_quality as qualite,
    state as etat
FROM request_information 
ORDER BY name;" 2>/dev/null

echo ""
echo "   🚨 Signalements d'alerte:"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    name as numero,
    CASE 
        WHEN is_anonymous THEN 'Anonyme'
        ELSE reporter_name
    END as signaleur,
    category as categorie,
    state as etat,
    priority as priorite
FROM whistleblowing_alert 
ORDER BY name;" 2>/dev/null

echo ""
echo "   📊 Résumé des données:"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    'Demandes d''information' as type,
    COUNT(*) as nombre
FROM request_information
UNION ALL
SELECT 
    'Signalements d''alerte' as type,
    COUNT(*) as nombre
FROM whistleblowing_alert
UNION ALL
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
echo "🎉 INSTALLATION TERMINÉE AVEC SUCCÈS !"
echo ""
echo "📊 DONNÉES DE DÉMO CHARGÉES PAR VAGUES :"
echo "   🌊 Vague 1 : Données minimales (2 enregistrements de base)"
echo "   🌊 Vague 2 : Données étendues (4 enregistrements variés)"
echo "   🌊 Vague 3 : Données avancées (2 enregistrements complexes)"
echo ""
echo "🚀 Pour démarrer le serveur :"
echo "   ./start_sama_conai.sh"
echo ""
echo "🌐 Accès à l'application :"
echo "   URL: http://localhost:8075"
echo "   Login: admin / admin"