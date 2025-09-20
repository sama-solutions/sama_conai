#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de test complet pour toutes les vagues de données de démo
"""

def test_all_demo_waves():
    """
    Teste toutes les vagues de données de démo et génère un rapport complet
    """
    print("🧪 TEST COMPLET DES DONNÉES DE DÉMO SAMA CONAI")
    print("=" * 60)
    
    try:
        # Collecte des données
        info_requests = env['request.information'].search([])
        whistleblowing_alerts = env['whistleblowing.alert'].search([])
        info_stages = env['request.information.stage'].search([])
        wb_stages = env['whistleblowing.alert.stage'].search([])
        refusal_reasons = env['request.refusal.reason'].search([])
        
        print(f"📊 STATISTIQUES GÉNÉRALES")
        print(f"   - Demandes d'information: {len(info_requests)}")
        print(f"   - Signalements d'alerte: {len(whistleblowing_alerts)}")
        print(f"   - Étapes d'information: {len(info_stages)}")
        print(f"   - Étapes de signalement: {len(wb_stages)}")
        print(f"   - Motifs de refus: {len(refusal_reasons)}")
        print()
        
        # Analyse des demandes d'information
        print("📋 ANALYSE DES DEMANDES D'INFORMATION")
        print("-" * 40)
        
        # Par état
        states_count = {}
        for request in info_requests:
            state = request.state
            states_count[state] = states_count.get(state, 0) + 1
        
        print("   États:")
        for state, count in sorted(states_count.items()):
            percentage = (count / len(info_requests)) * 100 if info_requests else 0
            print(f"     - {state}: {count} ({percentage:.1f}%)")
        
        # Par qualité de demandeur
        qualities_count = {}
        for request in info_requests:
            quality = request.requester_quality
            qualities_count[quality] = qualities_count.get(quality, 0) + 1
        
        print("   Qualités de demandeurs:")
        for quality, count in sorted(qualities_count.items()):
            percentage = (count / len(info_requests)) * 100 if info_requests else 0
            print(f"     - {quality}: {count} ({percentage:.1f}%)")
        
        # Demandes avec contenu riche
        requests_with_response = len([r for r in info_requests if r.response_body])
        refused_requests = len([r for r in info_requests if r.is_refusal])
        overdue_requests = len([r for r in info_requests if r.is_overdue])
        
        print("   Contenu:")
        print(f"     - Avec réponse: {requests_with_response}")
        print(f"     - Refusées: {refused_requests}")
        print(f"     - En retard: {overdue_requests}")
        print()
        
        # Analyse des signalements d'alerte
        print("🚨 ANALYSE DES SIGNALEMENTS D'ALERTE")
        print("-" * 40)
        
        # Par catégorie
        categories_count = {}
        for alert in whistleblowing_alerts:
            category = alert.category
            categories_count[category] = categories_count.get(category, 0) + 1
        
        print("   Catégories:")
        for category, count in sorted(categories_count.items()):
            percentage = (count / len(whistleblowing_alerts)) * 100 if whistleblowing_alerts else 0
            print(f"     - {category}: {count} ({percentage:.1f}%)")
        
        # Par priorité
        priorities_count = {}
        for alert in whistleblowing_alerts:
            priority = alert.priority
            priorities_count[priority] = priorities_count.get(priority, 0) + 1
        
        print("   Priorités:")
        for priority, count in sorted(priorities_count.items()):
            percentage = (count / len(whistleblowing_alerts)) * 100 if whistleblowing_alerts else 0
            print(f"     - {priority}: {count} ({percentage:.1f}%)")
        
        # Par état
        wb_states_count = {}
        for alert in whistleblowing_alerts:
            state = alert.state
            wb_states_count[state] = wb_states_count.get(state, 0) + 1
        
        print("   États:")
        for state, count in sorted(wb_states_count.items()):
            percentage = (count / len(whistleblowing_alerts)) * 100 if whistleblowing_alerts else 0
            print(f"     - {state}: {count} ({percentage:.1f}%)")
        
        # Signalements avec contenu riche
        anonymous_alerts = len([a for a in whistleblowing_alerts if a.is_anonymous])
        alerts_with_investigation = len([a for a in whistleblowing_alerts if a.investigation_notes])
        resolved_alerts = len([a for a in whistleblowing_alerts if a.resolution])
        urgent_alerts = len([a for a in whistleblowing_alerts if a.priority == 'urgent'])
        
        print("   Contenu:")
        print(f"     - Anonymes: {anonymous_alerts}")
        print(f"     - Avec investigation: {alerts_with_investigation}")
        print(f"     - Résolus: {resolved_alerts}")
        print(f"     - Urgents: {urgent_alerts}")
        print()
        
        # Test des capacités d'analyse
        print("📊 CAPACITÉS D'ANALYSE")
        print("-" * 40)
        
        # Analyse temporelle
        from datetime import datetime, timedelta
        
        recent_requests = env['request.information'].search([
            ('request_date', '>=', (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        ])
        
        recent_alerts = env['whistleblowing.alert'].search([
            ('alert_date', '>=', (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        ])
        
        print(f"   Activité récente (30 derniers jours):")
        print(f"     - Nouvelles demandes: {len(recent_requests)}")
        print(f"     - Nouveaux signalements: {len(recent_alerts)}")
        
        # Performance
        responded_requests = env['request.information'].search([('state', '=', 'responded')])
        avg_response_time = 0
        if responded_requests:
            total_days = 0
            count = 0
            for request in responded_requests:
                if request.request_date and request.response_date:
                    request_dt = datetime.strptime(request.request_date, '%Y-%m-%d %H:%M:%S')
                    response_dt = datetime.strptime(request.response_date, '%Y-%m-%d %H:%M:%S')
                    days = (response_dt - request_dt).days
                    total_days += days
                    count += 1
            avg_response_time = total_days / count if count > 0 else 0
        
        print(f"   Performance:")
        print(f"     - Temps moyen de réponse: {avg_response_time:.1f} jours")
        print(f"     - Taux de réponse: {(len(responded_requests)/len(info_requests)*100):.1f}%" if info_requests else "     - Taux de réponse: 0%")
        print()
        
        # Vérification de la qualité des données
        print("🔍 QUALITÉ DES DONNÉES")
        print("-" * 40)
        
        quality_issues = []
        
        # Vérifier les demandes refusées
        for request in info_requests:
            if request.is_refusal:
                if not request.refusal_reason_id:
                    quality_issues.append(f"Demande {request.name}: refus sans motif")
                if not request.refusal_motivation:
                    quality_issues.append(f"Demande {request.name}: refus sans motivation")
        
        # Vérifier les signalements en investigation
        investigating_alerts = env['whistleblowing.alert'].search([('state', '=', 'investigation')])
        for alert in investigating_alerts:
            if not alert.investigation_notes:
                quality_issues.append(f"Signalement {alert.name}: investigation sans notes")
        
        # Vérifier les signalements résolus
        resolved_alerts_obj = env['whistleblowing.alert'].search([('state', '=', 'resolved')])
        for alert in resolved_alerts_obj:
            if not alert.resolution:
                quality_issues.append(f"Signalement {alert.name}: résolu sans résolution")
        
        if quality_issues:
            print("   ⚠️  Problèmes détectés:")
            for issue in quality_issues[:5]:  # Limiter à 5 pour la lisibilité
                print(f"     - {issue}")
            if len(quality_issues) > 5:
                print(f"     ... et {len(quality_issues) - 5} autres problèmes")
        else:
            print("   ✅ Aucun problème de qualité détecté")
        print()
        
        # Test des vues et fonctionnalités
        print("🎯 TEST DES FONCTIONNALITÉS")
        print("-" * 40)
        
        # Test des actions
        try:
            action_info = env.ref('sama_conai.action_information_request')
            print(f"   ✅ Action demandes d'information: {action_info.name}")
        except:
            print("   ❌ Action demandes d'information: ERREUR")
        
        try:
            action_wb = env.ref('sama_conai.action_whistleblowing_alert', raise_if_not_found=False)
            if action_wb:
                print(f"   ✅ Action signalements: {action_wb.name}")
            else:
                print("   ⚠️  Action signalements: NON TROUVÉE")
        except:
            print("   ❌ Action signalements: ERREUR")
        
        # Test des vues
        view_types = ['kanban', 'list', 'form', 'graph', 'pivot']
        for view_type in view_types:
            try:
                view = env['ir.ui.view'].search([
                    ('model', '=', 'request.information'),
                    ('type', '=', view_type)
                ], limit=1)
                if view:
                    print(f"   ✅ Vue {view_type}: {view.name}")
                else:
                    print(f"   ⚠️  Vue {view_type}: NON TROUVÉE")
            except:
                print(f"   ❌ Vue {view_type}: ERREUR")
        print()
        
        # Évaluation globale
        print("🎉 ÉVALUATION GLOBALE")
        print("-" * 40)
        
        # Critères de succès
        criteria = {
            "Nombre de demandes": len(info_requests) >= 6,
            "Nombre de signalements": len(whistleblowing_alerts) >= 6,
            "Diversité des états (demandes)": len(states_count) >= 4,
            "Diversité des catégories (signalements)": len(categories_count) >= 4,
            "Demandes avec réponse": requests_with_response >= 2,
            "Signalements résolus": resolved_alerts >= 1,
            "Qualité des données": len(quality_issues) == 0,
            "Contenu riche": (requests_with_response + alerts_with_investigation) >= 3
        }
        
        passed_criteria = sum(criteria.values())
        total_criteria = len(criteria)
        success_rate = (passed_criteria / total_criteria) * 100
        
        print(f"   Critères validés: {passed_criteria}/{total_criteria} ({success_rate:.1f}%)")
        print()
        
        for criterion, passed in criteria.items():
            status = "✅" if passed else "❌"
            print(f"   {status} {criterion}")
        
        print()
        
        if success_rate >= 90:
            print("🏆 EXCELLENT! Données de démo complètes et de haute qualité")
            print("   Prêt pour la démonstration et la formation des utilisateurs")
        elif success_rate >= 75:
            print("👍 BIEN! Données de démo satisfaisantes")
            print("   Quelques améliorations mineures possibles")
        elif success_rate >= 50:
            print("⚠️  MOYEN. Données de démo basiques")
            print("   Améliorations nécessaires pour une meilleure expérience")
        else:
            print("❌ INSUFFISANT. Données de démo incomplètes")
            print("   Révision majeure nécessaire")
        
        print()
        print("📈 RECOMMANDATIONS POUR L'ANALYSE DE DONNÉES:")
        print("   1. Utiliser la vue Kanban pour le suivi visuel")
        print("   2. Explorer les vues Graph pour les tendances")
        print("   3. Utiliser Pivot pour les analyses croisées")
        print("   4. Tester les filtres avancés")
        print("   5. Configurer des tableaux de bord personnalisés")
        
        return success_rate >= 75
        
    except Exception as e:
        print(f"❌ Erreur lors du test: {e}")
        import traceback
        traceback.print_exc()
        return False

# Exécuter le test si dans le contexte Odoo
try:
    result = test_all_demo_waves()
    print("\\n" + "=" * 60)
    if result:
        print("🎯 SAMA CONAI: DONNÉES DE DÉMO VALIDÉES!")
        print("   Module prêt pour la formation et la démonstration")
    else:
        print("🔧 SAMA CONAI: AMÉLIORATIONS NÉCESSAIRES")
        print("   Réviser les données avant la mise en production")
except NameError:
    print("❌ Ce script doit être exécuté dans le shell Odoo.")
    print("   Usage: ./odoo-bin shell -c odoo.conf -d your_database")
    print("   Puis: exec(open('scripts/test_all_demo_waves.py').read())")