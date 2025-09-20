#!/bin/bash

# Test de correction de l'erreur portal

echo "🔧 TEST DE CORRECTION DE L'ERREUR PORTAL"
echo "========================================"

echo ""
echo "1. 🚀 Démarrage du serveur en arrière-plan..."

# Démarrer le serveur en arrière-plan
python3 /var/odoo/odoo18/odoo-bin \
    -d sama_conai_demo \
    --addons-path=/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    --http-port=8075 \
    --log-level=info \
    --logfile=/tmp/odoo_test.log \
    --pidfile=/tmp/odoo_test.pid &

ODOO_PID=$!
echo "   ✅ Serveur démarré (PID: $ODOO_PID)"

echo ""
echo "2. ⏳ Attente du démarrage complet..."
sleep 15

echo ""
echo "3. 🌐 Test de connectivité..."

# Test de base
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8075/ | grep -q "200"; then
    echo "   ✅ Serveur accessible"
else
    echo "   ❌ Serveur non accessible"
    kill $ODOO_PID 2>/dev/null
    exit 1
fi

echo ""
echo "4. 🔍 Test de la vue portal problématique..."

# Test de la page qui causait l'erreur
RESPONSE=$(curl -s -w "%{http_code}" http://localhost:8075/web/login -o /tmp/test_response.html)

if echo "$RESPONSE" | grep -q "200"; then
    echo "   ✅ Page de login accessible (code: $RESPONSE)"
else
    echo "   ⚠️ Page de login retourne: $RESPONSE"
fi

echo ""
echo "5. 📋 Vérification des logs d'erreur..."

# Vérifier s'il y a encore l'erreur portal dans les logs
if grep -q "portal_information_request_detail" /tmp/odoo_test.log; then
    echo "   ❌ Erreur portal encore présente dans les logs"
    echo "   📄 Extrait des logs :"
    grep "portal_information_request_detail" /tmp/odoo_test.log | tail -3
else
    echo "   ✅ Aucune erreur portal détectée dans les logs"
fi

echo ""
echo "6. 🎯 Test spécifique du module SAMA CONAI..."

# Test d'accès aux vues du module
MENU_RESPONSE=$(curl -s -w "%{http_code}" "http://localhost:8075/web#action=sama_conai.action_information_request" -o /tmp/menu_test.html)

if echo "$MENU_RESPONSE" | grep -q "200"; then
    echo "   ✅ Menu SAMA CONAI accessible (code: $MENU_RESPONSE)"
else
    echo "   ⚠️ Menu SAMA CONAI retourne: $MENU_RESPONSE"
fi

echo ""
echo "7. 📊 Résumé des tests..."

# Compter les erreurs dans les logs
ERROR_COUNT=$(grep -c "ERROR\|CRITICAL\|portal_information_request_detail" /tmp/odoo_test.log 2>/dev/null || echo "0")
WARNING_COUNT=$(grep -c "WARNING" /tmp/odoo_test.log 2>/dev/null || echo "0")

echo "   📈 Statistiques des logs :"
echo "      🔴 Erreurs: $ERROR_COUNT"
echo "      🟡 Avertissements: $WARNING_COUNT"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "   ✅ Aucune erreur critique détectée"
else
    echo "   ❌ $ERROR_COUNT erreur(s) détectée(s)"
    echo "   📄 Dernières erreurs :"
    grep "ERROR\|CRITICAL" /tmp/odoo_test.log | tail -3
fi

echo ""
echo "8. 🧹 Nettoyage..."

# Arrêter le serveur
kill $ODOO_PID 2>/dev/null
sleep 3

# Forcer l'arrêt si nécessaire
if kill -0 $ODOO_PID 2>/dev/null; then
    kill -9 $ODOO_PID 2>/dev/null
    echo "   ⚠️ Arrêt forcé du serveur"
else
    echo "   ✅ Serveur arrêté proprement"
fi

# Nettoyer les fichiers temporaires
rm -f /tmp/odoo_test.pid /tmp/test_response.html /tmp/menu_test.html

echo ""
echo "🎉 TEST TERMINÉ"
echo ""

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ RÉSULTAT : CORRECTION RÉUSSIE"
    echo "   L'erreur portal_information_request_detail a été corrigée"
    echo "   Le module SAMA CONAI fonctionne correctement"
else
    echo "❌ RÉSULTAT : PROBLÈMES DÉTECTÉS"
    echo "   Des erreurs persistent, vérification nécessaire"
fi

echo ""
echo "📋 FICHIERS DE LOG :"
echo "   📄 Log complet : /tmp/odoo_test.log"
echo ""
echo "🚀 POUR DÉMARRER NORMALEMENT :"
echo "   ./start_with_demo.sh"