#!/bin/bash

# 🇸🇳 SAMA CONAI - Test de l'interface corrigée

echo "🇸🇳 SAMA CONAI - Test Interface Corrigée"
echo "========================================"

# Test 1: Vérifier que le serveur répond
echo "🔍 Test 1: Connexion serveur..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3008/)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Serveur répond correctement (HTTP $HTTP_CODE)"
else
    echo "❌ Erreur serveur (HTTP $HTTP_CODE)"
    exit 1
fi

# Test 2: Vérifier la connexion Odoo
echo "🔍 Test 2: Connexion Odoo..."
ODOO_RESPONSE=$(curl -s http://localhost:3008/api/odoo/test)
if echo "$ODOO_RESPONSE" | grep -q '"success":true'; then
    echo "✅ Connexion Odoo fonctionnelle"
    echo "📋 Réponse: $ODOO_RESPONSE"
else
    echo "❌ Problème connexion Odoo"
    echo "📋 Réponse: $ODOO_RESPONSE"
fi

# Test 3: Vérifier le contenu HTML
echo "🔍 Test 3: Contenu HTML..."
HTML_CONTENT=$(curl -s http://localhost:3008/)
if echo "$HTML_CONTENT" | grep -q "SAMA CONAI - Version Odoo Réelle"; then
    echo "✅ Titre HTML correct"
else
    echo "❌ Problème titre HTML"
fi

if echo "$HTML_CONTENT" | grep -q "mobile-container"; then
    echo "✅ Structure mobile présente"
else
    echo "❌ Structure mobile manquante"
fi

if echo "$HTML_CONTENT" | grep -q "flex-direction: column"; then
    echo "✅ CSS Flexbox configuré"
else
    echo "❌ CSS Flexbox manquant"
fi

# Test 4: Vérifier la taille du fichier HTML
echo "🔍 Test 4: Taille fichier HTML..."
HTML_SIZE=$(echo "$HTML_CONTENT" | wc -c)
if [ "$HTML_SIZE" -gt 100000 ]; then
    echo "✅ Fichier HTML complet ($HTML_SIZE caractères)"
else
    echo "⚠️ Fichier HTML petit ($HTML_SIZE caractères)"
fi

# Test 5: Vérifier les processus
echo "🔍 Test 5: Processus actifs..."
ODOO_PID=$(pgrep -f "server_odoo_real.js")
if [ ! -z "$ODOO_PID" ]; then
    echo "✅ Serveur Odoo réel actif (PID: $ODOO_PID)"
else
    echo "❌ Serveur Odoo réel non trouvé"
fi

MAIN_ODOO_PID=$(pgrep -f "odoo-bin.*8077")
if [ ! -z "$MAIN_ODOO_PID" ]; then
    echo "✅ Serveur Odoo principal actif (PID: $MAIN_ODOO_PID)"
else
    echo "❌ Serveur Odoo principal non trouvé"
fi

# Test 6: Vérifier les ports
echo "🔍 Test 6: Ports réseau..."
if netstat -tlnp 2>/dev/null | grep -q ":3008.*LISTEN"; then
    echo "✅ Port 3008 en écoute"
else
    echo "❌ Port 3008 non disponible"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8077.*LISTEN"; then
    echo "✅ Port 8077 (Odoo) en écoute"
else
    echo "❌ Port 8077 (Odoo) non disponible"
fi

echo ""
echo "🎯 RÉSUMÉ DES TESTS"
echo "=================="
echo "📱 Interface: http://localhost:3008/"
echo "🔗 Test Odoo: http://localhost:3008/api/odoo/test"
echo "📊 Comparaison: http://localhost:3007/enriched"
echo ""
echo "💡 CONSEILS DE DÉBOGAGE:"
echo "- Vider le cache du navigateur (Ctrl+F5)"
echo "- Ouvrir les outils développeur (F12)"
echo "- Vérifier la console pour les erreurs JavaScript"
echo "- Tester en navigation privée"
echo ""
echo "✅ Tests terminés !"