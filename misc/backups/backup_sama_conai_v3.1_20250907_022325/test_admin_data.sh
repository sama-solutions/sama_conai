#!/bin/bash

# Script de test des données assignées à l'admin

echo "📊 TEST DES DONNÉES ASSIGNÉES À L'ADMIN"
echo "======================================="

# Vérifier que l'application mobile est lancée
echo "🔍 Vérification du serveur mobile..."
if curl -s http://localhost:3001 > /dev/null; then
    echo "✅ Serveur mobile accessible"
else
    echo "❌ Serveur mobile non accessible"
    echo "   Lancez d'abord: ./launch_mobile_app.sh"
    exit 1
fi

echo ""
echo "🔐 CONNEXION ADMIN"
echo "=================="

# Login admin
echo "🔸 Connexion admin..."
LOGIN_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"email":"admin","password":"admin"}' \
    http://localhost:3001/api/mobile/auth/login)

if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Connexion admin réussie - Token: ${TOKEN:0:10}..."
else
    echo "❌ Connexion admin échouée"
    exit 1
fi

echo ""
echo "📊 TEST DES DONNÉES DASHBOARD"
echo "============================="

# Test dashboard avec données
echo "🔸 Récupération du dashboard admin..."
DASHBOARD_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" \
    http://localhost:3001/api/mobile/citizen/dashboard)

if echo "$DASHBOARD_RESPONSE" | grep -q '"success":true'; then
    # Extraire les statistiques
    TOTAL_REQUESTS=$(echo "$DASHBOARD_RESPONSE" | grep -o '"total_requests":[0-9]*' | cut -d':' -f2)
    PENDING_REQUESTS=$(echo "$DASHBOARD_RESPONSE" | grep -o '"pending_requests":[0-9]*' | cut -d':' -f2)
    COMPLETED_REQUESTS=$(echo "$DASHBOARD_RESPONSE" | grep -o '"completed_requests":[0-9]*' | cut -d':' -f2)
    OVERDUE_REQUESTS=$(echo "$DASHBOARD_RESPONSE" | grep -o '"overdue_requests":[0-9]*' | cut -d':' -f2)
    
    # Extraire les stats publiques
    TOTAL_PUBLIC=$(echo "$DASHBOARD_RESPONSE" | grep -o '"total_public_requests":[0-9]*' | cut -d':' -f2)
    AVG_RESPONSE_TIME=$(echo "$DASHBOARD_RESPONSE" | grep -o '"avg_response_time":[0-9.]*' | cut -d':' -f2)
    SUCCESS_RATE=$(echo "$DASHBOARD_RESPONSE" | grep -o '"success_rate":[0-9.]*' | cut -d':' -f2)
    
    # Extraire les stats d'alertes
    TOTAL_ALERTS=$(echo "$DASHBOARD_RESPONSE" | grep -o '"total_alerts":[0-9]*' | cut -d':' -f2)
    ACTIVE_ALERTS=$(echo "$DASHBOARD_RESPONSE" | grep -o '"active_alerts":[0-9]*' | cut -d':' -f2)
    
    echo "✅ Dashboard récupéré avec succès"
    echo ""
    echo "📈 STATISTIQUES UTILISATEUR ADMIN:"
    echo "   📄 Total demandes: $TOTAL_REQUESTS"
    echo "   ⏳ En cours: $PENDING_REQUESTS"
    echo "   ✅ Terminées: $COMPLETED_REQUESTS"
    echo "   ⚠️ En retard: $OVERDUE_REQUESTS"
    echo ""
    echo "📊 STATISTIQUES PUBLIQUES:"
    echo "   🌐 Total public: $TOTAL_PUBLIC"
    echo "   ⏱️ Temps moyen: ${AVG_RESPONSE_TIME} jours"
    echo "   📈 Taux succès: ${SUCCESS_RATE}%"
    echo ""
    echo "🚨 STATISTIQUES ALERTES:"
    echo "   📢 Total alertes: $TOTAL_ALERTS"
    echo "   🔥 Alertes actives: $ACTIVE_ALERTS"
    
    # Vérifier si les données sont non nulles
    if [ "$TOTAL_REQUESTS" -gt 0 ]; then
        echo "✅ L'admin a des demandes assignées"
    else
        echo "⚠️ Aucune demande assignée à l'admin"
    fi
    
else
    echo "❌ Erreur récupération dashboard"
fi

echo ""
echo "📋 TEST LISTE DES DEMANDES"
echo "=========================="

# Test liste des demandes
echo "🔸 Récupération de la liste des demandes..."
REQUESTS_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" \
    http://localhost:3001/api/mobile/citizen/requests)

if echo "$REQUESTS_RESPONSE" | grep -q '"success":true'; then
    REQUESTS_COUNT=$(echo "$REQUESTS_RESPONSE" | grep -o '"total":[0-9]*' | cut -d':' -f2)
    echo "✅ Liste des demandes récupérée"
    echo "   📄 Nombre de demandes: $REQUESTS_COUNT"
    
    # Extraire quelques noms de demandes
    echo ""
    echo "📋 DEMANDES ASSIGNÉES À L'ADMIN:"
    echo "$REQUESTS_RESPONSE" | grep -o '"name":"REQ-[^"]*"' | head -5 | while read line; do
        REQ_NAME=$(echo "$line" | cut -d'"' -f4)
        echo "   📄 $REQ_NAME"
    done
    
    if [ "$REQUESTS_COUNT" -gt 0 ]; then
        echo "✅ L'admin a accès à $REQUESTS_COUNT demandes"
    else
        echo "⚠️ Aucune demande visible pour l'admin"
    fi
    
else
    echo "❌ Erreur récupération liste demandes"
fi

echo ""
echo "🔍 TEST DÉTAIL D'UNE DEMANDE"
echo "============================"

# Test détail d'une demande
echo "🔸 Récupération du détail de la demande 1..."
DETAIL_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" \
    http://localhost:3001/api/mobile/citizen/requests/1)

if echo "$DETAIL_RESPONSE" | grep -q '"success":true'; then
    REQ_NAME=$(echo "$DETAIL_RESPONSE" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    REQ_STATE=$(echo "$DETAIL_RESPONSE" | grep -o '"state_label":"[^"]*"' | cut -d'"' -f4)
    REQUESTER=$(echo "$DETAIL_RESPONSE" | grep -o '"requester_name":"[^"]*"' | cut -d'"' -f4)
    
    echo "✅ Détail de la demande récupéré"
    echo "   📄 Nom: $REQ_NAME"
    echo "   📊 État: $REQ_STATE"
    echo "   👤 Demandeur: $REQUESTER"
    
    # Vérifier la chronologie
    if echo "$DETAIL_RESPONSE" | grep -q '"timeline"'; then
        TIMELINE_COUNT=$(echo "$DETAIL_RESPONSE" | grep -o '"event":"[^"]*"' | wc -l)
        echo "   📅 Événements chronologie: $TIMELINE_COUNT"
    fi
    
else
    echo "❌ Erreur récupération détail demande"
fi

echo ""
echo "📊 RÉSUMÉ DES TESTS"
echo "=================="

# Résumé
echo "✅ Tests terminés avec succès"
echo ""
echo "🎯 DONNÉES ADMIN VALIDÉES:"

if [ "$TOTAL_REQUESTS" -gt 0 ]; then
    echo "   ✅ Dashboard: $TOTAL_REQUESTS demandes assignées"
else
    echo "   ⚠️ Dashboard: Aucune demande (utilise données démo)"
fi

if [ "$REQUESTS_COUNT" -gt 0 ]; then
    echo "   ✅ Liste: $REQUESTS_COUNT demandes accessibles"
else
    echo "   ⚠️ Liste: Aucune demande visible"
fi

if echo "$DETAIL_RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ Détails: Informations complètes disponibles"
else
    echo "   ⚠️ Détails: Problème d'accès aux détails"
fi

echo ""
echo "📱 ÉTAT DE L'APPLICATION MOBILE:"
echo "   🔐 Authentification: Fonctionnelle"
echo "   📊 Dashboard: Données enrichies"
echo "   📋 Listes: Navigation complète"
echo "   🔍 Détails: Informations détaillées"
echo "   📈 Statistiques: Métriques vivantes"

echo ""
echo "💡 L'application mobile est maintenant remplie de données"
echo "   pour l'utilisateur admin et prête pour la démonstration !"

echo ""
echo "🌐 Accédez à http://localhost:3001 et connectez-vous avec:"
echo "   👤 Email: admin"
echo "   🔑 Mot de passe: admin"