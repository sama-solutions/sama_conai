#!/bin/bash

# Vérification des données de démo par vagues

echo "🌊 VÉRIFICATION DES DONNÉES DE DÉMO PAR VAGUES"
echo "=============================================="

DB_NAME="sama_conai_demo"
export PGPASSWORD=odoo

echo "Base de données: $DB_NAME"
echo ""

echo "📊 RÉSUMÉ GÉNÉRAL :"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    'Demandes d''information' as type,
    COUNT(*) as total
FROM request_information
UNION ALL
SELECT 
    'Signalements d''alerte' as type,
    COUNT(*) as total
FROM whistleblowing_alert
UNION ALL
SELECT 
    'Étapes configurées' as type,
    COUNT(*) as total
FROM request_information_stage
UNION ALL
SELECT 
    'Motifs de refus' as type,
    COUNT(*) as total
FROM request_refusal_reason;" 2>/dev/null

echo ""
echo "🌊 VAGUE 1 - DONNÉES MINIMALES :"
echo "   📋 Demandes d'information de base"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    name as numero,
    partner_name as demandeur,
    requester_quality as qualite,
    state as etat
FROM request_information 
WHERE name IN ('REQ-2025-001')
ORDER BY name;" 2>/dev/null

echo ""
echo "   🚨 Signalements d'alerte de base"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    name as numero,
    CASE WHEN is_anonymous THEN 'Anonyme' ELSE reporter_name END as signaleur,
    category as categorie,
    state as etat
FROM whistleblowing_alert 
WHERE name IN ('WB-2025-001')
ORDER BY name;" 2>/dev/null

echo ""
echo "🌊 VAGUE 2 - DONNÉES ÉTENDUES :"
echo "   📋 Demandes variées (journaliste, chercheur, refus)"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    name as numero,
    partner_name as demandeur,
    requester_quality as qualite,
    state as etat,
    CASE WHEN is_refusal THEN 'Oui' ELSE 'Non' END as refuse
FROM request_information 
WHERE name IN ('REQ-2025-002', 'REQ-2025-003', 'REQ-2025-004')
ORDER BY name;" 2>/dev/null

echo ""
echo "   🚨 Signalements variés (fraude, abus, harcèlement)"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    name as numero,
    CASE WHEN is_anonymous THEN 'Anonyme' ELSE reporter_name END as signaleur,
    category as categorie,
    state as etat,
    priority as priorite
FROM whistleblowing_alert 
WHERE name IN ('WB-2025-002', 'WB-2025-003', 'WB-2025-004')
ORDER BY name;" 2>/dev/null

echo ""
echo "🌊 VAGUE 3 - DONNÉES AVANCÉES :"
echo "   📋 Demandes complexes (avocat, ONG)"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    name as numero,
    partner_name as demandeur,
    requester_quality as qualite,
    state as etat,
    LENGTH(description) as taille_description
FROM request_information 
WHERE name IN ('REQ-2025-005', 'REQ-2025-006')
ORDER BY name;" 2>/dev/null

echo ""
echo "   🚨 Signalements complexes (environnement, discrimination)"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    name as numero,
    CASE WHEN is_anonymous THEN 'Anonyme' ELSE reporter_name END as signaleur,
    category as categorie,
    state as etat,
    priority as priorite,
    LENGTH(description) as taille_description
FROM whistleblowing_alert 
WHERE name IN ('WB-2025-005', 'WB-2025-006')
ORDER BY name;" 2>/dev/null

echo ""
echo "📈 ANALYSE PAR ÉTAT :"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    'Demandes - ' || state as type_etat,
    COUNT(*) as nombre
FROM request_information 
GROUP BY state
UNION ALL
SELECT 
    'Signalements - ' || state as type_etat,
    COUNT(*) as nombre
FROM whistleblowing_alert 
GROUP BY state
ORDER BY type_etat;" 2>/dev/null

echo ""
echo "🎯 ANALYSE PAR PRIORITÉ (Signalements) :"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    priority as priorite,
    COUNT(*) as nombre
FROM whistleblowing_alert 
GROUP BY priority
ORDER BY 
    CASE priority 
        WHEN 'urgent' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        WHEN 'low' THEN 4 
    END;" 2>/dev/null

echo ""
echo "👥 ANALYSE PAR QUALITÉ DU DEMANDEUR :"
psql -h localhost -U odoo -d "$DB_NAME" -c "
SELECT 
    requester_quality as qualite,
    COUNT(*) as nombre
FROM request_information 
GROUP BY requester_quality
ORDER BY nombre DESC;" 2>/dev/null

echo ""
echo "🎉 DONNÉES DE DÉMO CHARGÉES AVEC SUCCÈS !"
echo ""
echo "🚀 Pour démarrer le serveur avec les données de démo :"
echo "   ./start_with_demo.sh"
echo ""
echo "🌐 Accès à l'application :"
echo "   URL: http://localhost:8075"
echo "   Login: admin / admin"
echo ""
echo "📚 Fonctionnalités à tester :"
echo "   ✅ Vue Kanban avec cartes colorées par urgence"
echo "   ✅ Filtres par état, priorité, qualité du demandeur"
echo "   ✅ Vues Graph pour analyses temporelles"
echo "   ✅ Vues Pivot pour analyses croisées"
echo "   ✅ Workflow complet de traitement"
echo "   ✅ Gestion des refus avec motifs"
echo "   ✅ Signalements anonymes et nominatifs"