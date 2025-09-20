#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de test pour la vague 2 des données de démo
"""

def test_demo_wave_2():
    """
    Teste que les données de démo de la vague 2 sont correctement chargées
    """
    print("🧪 Test de la vague 2 des données de démo...")
    
    try:
        # Test 1: Vérifier la diversité des demandes d'information
        info_requests = env['request.information'].search([])
        print(f"   📊 Total demandes d'information: {len(info_requests)}")
        
        # Analyser par état
        states = {}
        qualities = {}
        for request in info_requests:
            state = request.state
            quality = request.requester_quality
            states[state] = states.get(state, 0) + 1
            qualities[quality] = qualities.get(quality, 0) + 1
        
        print("   📈 Répartition par état:")
        for state, count in states.items():
            print(f"      - {state}: {count}")
        
        print("   👥 Répartition par qualité de demandeur:")
        for quality, count in qualities.items():
            print(f"      - {quality}: {count}")
        
        # Test 2: Vérifier la diversité des signalements
        whistleblowing_alerts = env['whistleblowing.alert'].search([])
        print(f"   🚨 Total signalements d'alerte: {len(whistleblowing_alerts)}")
        
        # Analyser par catégorie et priorité
        categories = {}
        priorities = {}
        for alert in whistleblowing_alerts:
            category = alert.category
            priority = alert.priority
            categories[category] = categories.get(category, 0) + 1
            priorities[priority] = priorities.get(priority, 0) + 1
        
        print("   📊 Répartition par catégorie:")
        for category, count in categories.items():
            print(f"      - {category}: {count}")
        
        print("   ⚡ Répartition par priorité:")
        for priority, count in priorities.items():
            print(f"      - {priority}: {count}")
        
        # Test 3: Vérifier les données riches
        requests_with_response = env['request.information'].search([('response_body', '!=', False)])
        print(f"   💬 Demandes avec réponse: {len(requests_with_response)}")
        
        refused_requests = env['request.information'].search([('is_refusal', '=', True)])
        print(f"   ❌ Demandes refusées: {len(refused_requests)}")
        
        alerts_with_investigation = env['whistleblowing.alert'].search([('investigation_notes', '!=', False)])
        print(f"   🔍 Signalements avec notes d'investigation: {len(alerts_with_investigation)}")
        
        resolved_alerts = env['whistleblowing.alert'].search([('resolution', '!=', False)])
        print(f"   ✅ Signalements résolus: {len(resolved_alerts)}")
        
        # Test 4: Vérifier les vues analytiques
        print("   📊 Test des capacités d'analyse...")
        
        # Simuler des requêtes d'analyse
        recent_requests = env['request.information'].search([
            ('request_date', '>=', (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        ])
        print(f"      - Demandes du mois: {len(recent_requests)}")
        
        urgent_alerts = env['whistleblowing.alert'].search([('priority', '=', 'urgent')])
        print(f"      - Signalements urgents: {len(urgent_alerts)}")
        
        # Test 5: Vérifier la cohérence des données
        print("   🔍 Vérification de la cohérence...")
        
        errors = []
        
        # Vérifier que les demandes refusées ont un motif
        for request in refused_requests:
            if not request.refusal_reason_id or not request.refusal_motivation:
                errors.append(f"Demande {request.name}: refus sans motif complet")
        
        # Vérifier que les signalements en investigation ont des notes
        investigating_alerts = env['whistleblowing.alert'].search([('state', '=', 'investigation')])
        for alert in investigating_alerts:
            if not alert.investigation_notes:
                errors.append(f"Signalement {alert.name}: investigation sans notes")
        
        if errors:
            print("   ⚠️  Erreurs de cohérence détectées:")
            for error in errors:
                print(f"      - {error}")
        else:
            print("   ✅ Données cohérentes")
        
        # Résumé
        print("\\n✅ Résumé de la vague 2:")
        print(f"   - Total demandes: {len(info_requests)}")
        print(f"   - États différents: {len(states)}")
        print(f"   - Qualités de demandeurs: {len(qualities)}")
        print(f"   - Total signalements: {len(whistleblowing_alerts)}")
        print(f"   - Catégories différentes: {len(categories)}")
        print(f"   - Priorités différentes: {len(priorities)}")
        print(f"   - Demandes avec réponse: {len(requests_with_response)}")
        print(f"   - Signalements résolus: {len(resolved_alerts)}")
        
        # Critères de succès
        success_criteria = [
            len(info_requests) >= 4,  # Au moins 4 demandes
            len(whistleblowing_alerts) >= 4,  # Au moins 4 signalements
            len(states) >= 3,  # Au moins 3 états différents
            len(categories) >= 3,  # Au moins 3 catégories différentes
            len(requests_with_response) >= 1,  # Au moins 1 réponse
            len(resolved_alerts) >= 1,  # Au moins 1 résolution
            len(errors) == 0  # Aucune erreur de cohérence
        ]
        
        if all(success_criteria):
            print("\\n🎉 Vague 2 des données de démo: SUCCÈS COMPLET!")
            print("   ✅ Diversité des données")
            print("   ✅ Richesse du contenu")
            print("   ✅ Cohérence des informations")
            print("   ✅ Prêt pour l'analyse de données")
            return True
        else:
            print("\\n⚠️  Vague 2 des données de démo: AMÉLIORATIONS NÉCESSAIRES")
            return False
            
    except Exception as e:
        print(f"\\n❌ Erreur lors du test: {e}")
        import traceback
        traceback.print_exc()
        return False

# Exécuter le test si dans le contexte Odoo
try:
    result = test_demo_wave_2()
    if result:
        print("\\n🚀 Prêt pour la vague 3 des données de démo!")
        print("\\n📊 Suggestions pour tester les vues analytiques:")
        print("   1. Vue Kanban: Vérifier le groupement par étapes")
        print("   2. Vue Graph: Analyser les tendances par mois")
        print("   3. Vue Pivot: Croiser états et qualités de demandeurs")
        print("   4. Filtres: Tester les filtres par urgence, retard, etc.")
    else:
        print("\\n🔧 Corriger les problèmes avant de continuer.")
except NameError:
    print("❌ Ce script doit être exécuté dans le shell Odoo.")
    print("   Usage: ./odoo-bin shell -c odoo.conf -d your_database")
    print("   Puis: exec(open('scripts/test_demo_wave_2.py').read())")