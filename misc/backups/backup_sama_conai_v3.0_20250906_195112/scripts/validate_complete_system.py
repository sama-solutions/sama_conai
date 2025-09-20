#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de validation complète du système SAMA CONAI
Teste toutes les fonctionnalités et génère un rapport de conformité
"""

def validate_complete_system():
    """
    Validation complète du système SAMA CONAI
    """
    print("🔍 VALIDATION COMPLÈTE DU SYSTÈME SAMA CONAI")
    print("=" * 60)
    
    validation_results = {
        'models': {},
        'views': {},
        'data': {},
        'workflows': {},
        'security': {},
        'performance': {}
    }
    
    try:
        # ========================================
        # 1. VALIDATION DES MODÈLES
        # ========================================
        print("📋 1. VALIDATION DES MODÈLES")
        print("-" * 30)
        
        models_to_test = [
            'request.information',
            'request.information.stage',
            'request.refusal.reason',
            'whistleblowing.alert',
            'whistleblowing.alert.stage'
        ]
        
        for model_name in models_to_test:
            try:
                model = env[model_name]
                count = model.search_count([])
                validation_results['models'][model_name] = {
                    'exists': True,
                    'count': count,
                    'status': 'OK'
                }
                print(f"   ✅ {model_name}: {count} enregistrements")
            except Exception as e:
                validation_results['models'][model_name] = {
                    'exists': False,
                    'error': str(e),
                    'status': 'ERROR'
                }
                print(f"   ❌ {model_name}: ERREUR - {e}")
        
        print()
        
        # ========================================
        # 2. VALIDATION DES VUES
        # ========================================
        print("🎨 2. VALIDATION DES VUES")
        print("-" * 30)
        
        view_types = ['kanban', 'list', 'form', 'graph', 'pivot', 'search']
        main_models = ['request.information', 'whistleblowing.alert']
        
        for model in main_models:
            validation_results['views'][model] = {}
            for view_type in view_types:
                try:
                    views = env['ir.ui.view'].search([
                        ('model', '=', model),
                        ('type', '=', view_type)
                    ])
                    if views:
                        validation_results['views'][model][view_type] = {
                            'exists': True,
                            'count': len(views),
                            'status': 'OK'
                        }
                        print(f"   ✅ {model} - {view_type}: {len(views)} vue(s)")
                    else:
                        validation_results['views'][model][view_type] = {
                            'exists': False,
                            'status': 'MISSING'
                        }
                        print(f"   ⚠️  {model} - {view_type}: MANQUANT")
                except Exception as e:
                    validation_results['views'][model][view_type] = {
                        'exists': False,
                        'error': str(e),
                        'status': 'ERROR'
                    }
                    print(f"   ❌ {model} - {view_type}: ERREUR")
        
        print()
        
        # ========================================
        # 3. VALIDATION DES DONNÉES
        # ========================================
        print("📊 3. VALIDATION DES DONNÉES")
        print("-" * 30)
        
        # Test de la richesse des données
        info_requests = env['request.information'].search([])
        wb_alerts = env['whistleblowing.alert'].search([])
        
        # Diversité des états
        states = set(info_requests.mapped('state'))
        categories = set(wb_alerts.mapped('category'))
        priorities = set(wb_alerts.mapped('priority'))
        
        validation_results['data'] = {
            'info_requests_count': len(info_requests),
            'wb_alerts_count': len(wb_alerts),
            'states_diversity': len(states),
            'categories_diversity': len(categories),
            'priorities_diversity': len(priorities),
            'rich_content': {
                'requests_with_response': len([r for r in info_requests if r.response_body]),
                'refused_requests': len([r for r in info_requests if r.is_refusal]),
                'alerts_with_investigation': len([a for a in wb_alerts if a.investigation_notes]),
                'resolved_alerts': len([a for a in wb_alerts if a.resolution])
            }
        }
        
        print(f"   📈 Demandes d'information: {len(info_requests)}")
        print(f"   🚨 Signalements d'alerte: {len(wb_alerts)}")
        print(f"   🎯 États différents: {len(states)}")
        print(f"   📂 Catégories différentes: {len(categories)}")
        print(f"   ⚡ Priorités différentes: {len(priorities)}")
        print(f"   💬 Demandes avec réponse: {validation_results['data']['rich_content']['requests_with_response']}")
        print(f"   ✅ Signalements résolus: {validation_results['data']['rich_content']['resolved_alerts']}")
        
        print()
        
        # ========================================
        # 4. VALIDATION DES WORKFLOWS
        # ========================================
        print("⚙️  4. VALIDATION DES WORKFLOWS")
        print("-" * 30)
        
        # Test des méthodes de workflow
        workflow_tests = {}
        
        # Test sur une demande d'information
        if info_requests:
            test_request = info_requests[0]
            try:
                # Test des méthodes sans les exécuter réellement
                methods_to_test = [
                    'action_submit',
                    'action_start_processing',
                    'action_request_validation',
                    '_compute_deadline_date',
                    '_compute_is_overdue'
                ]
                
                for method in methods_to_test:
                    if hasattr(test_request, method):
                        workflow_tests[f'info_request_{method}'] = 'OK'
                        print(f"   ✅ Demande info - {method}: Disponible")
                    else:
                        workflow_tests[f'info_request_{method}'] = 'MISSING'
                        print(f"   ❌ Demande info - {method}: MANQUANT")
                        
            except Exception as e:
                print(f"   ❌ Erreur test workflow demandes: {e}")
        
        # Test sur un signalement d'alerte
        if wb_alerts:
            test_alert = wb_alerts[0]
            try:
                methods_to_test = [
                    'action_start_assessment',
                    'action_start_investigation',
                    'action_resolve',
                    '_generate_access_token'
                ]
                
                for method in methods_to_test:
                    if hasattr(test_alert, method):
                        workflow_tests[f'wb_alert_{method}'] = 'OK'
                        print(f"   ✅ Signalement - {method}: Disponible")
                    else:
                        workflow_tests[f'wb_alert_{method}'] = 'MISSING'
                        print(f"   ❌ Signalement - {method}: MANQUANT")
                        
            except Exception as e:
                print(f"   ❌ Erreur test workflow signalements: {e}")
        
        validation_results['workflows'] = workflow_tests
        print()
        
        # ========================================
        # 5. VALIDATION DE LA SÉCURITÉ
        # ========================================
        print("🔒 5. VALIDATION DE LA SÉCURITÉ")
        print("-" * 30)
        
        # Test des groupes de sécurité
        security_groups = [
            'sama_conai.group_info_request_user',
            'sama_conai.group_info_request_manager',
            'sama_conai.group_whistleblowing_manager',
            'sama_conai.group_transparency_admin'
        ]
        
        security_results = {}
        for group_ref in security_groups:
            try:
                group = env.ref(group_ref)
                security_results[group_ref] = {
                    'exists': True,
                    'users_count': len(group.users),
                    'status': 'OK'
                }
                print(f"   ✅ {group.name}: {len(group.users)} utilisateur(s)")
            except Exception as e:
                security_results[group_ref] = {
                    'exists': False,
                    'error': str(e),
                    'status': 'ERROR'
                }
                print(f"   ❌ {group_ref}: ERREUR")
        
        # Test des règles d'accès
        access_rules = env['ir.model.access'].search([
            ('model_id.model', 'in', ['request.information', 'whistleblowing.alert'])
        ])
        
        security_results['access_rules'] = len(access_rules)
        print(f"   🛡️  Règles d'accès: {len(access_rules)}")
        
        validation_results['security'] = security_results
        print()
        
        # ========================================
        # 6. VALIDATION DES PERFORMANCES
        # ========================================
        print("⚡ 6. VALIDATION DES PERFORMANCES")
        print("-" * 30)
        
        import time
        
        # Test de performance des recherches
        start_time = time.time()
        env['request.information'].search([])
        search_time = time.time() - start_time
        
        # Test de performance des vues
        start_time = time.time()
        env['ir.ui.view'].search([('model', '=', 'request.information')])
        view_time = time.time() - start_time
        
        validation_results['performance'] = {
            'search_time': search_time,
            'view_time': view_time,
            'total_records': len(info_requests) + len(wb_alerts)
        }
        
        print(f"   🔍 Temps de recherche: {search_time:.3f}s")
        print(f"   🎨 Temps de chargement vues: {view_time:.3f}s")
        print(f"   📊 Total enregistrements: {validation_results['performance']['total_records']}")
        
        print()
        
        # ========================================
        # 7. RAPPORT DE VALIDATION
        # ========================================
        print("📋 7. RAPPORT DE VALIDATION")
        print("-" * 30)
        
        # Calcul du score global
        total_tests = 0
        passed_tests = 0
        
        # Score modèles
        for model, result in validation_results['models'].items():
            total_tests += 1
            if result['status'] == 'OK':
                passed_tests += 1
        
        # Score vues
        for model, views in validation_results['views'].items():
            for view_type, result in views.items():
                total_tests += 1
                if result['status'] == 'OK':
                    passed_tests += 1
        
        # Score workflows
        for workflow, status in validation_results['workflows'].items():
            total_tests += 1
            if status == 'OK':
                passed_tests += 1
        
        # Score sécurité
        for group, result in validation_results['security'].items():
            if isinstance(result, dict):
                total_tests += 1
                if result['status'] == 'OK':
                    passed_tests += 1
        
        # Score données (critères de qualité)
        data_criteria = [
            validation_results['data']['info_requests_count'] >= 4,
            validation_results['data']['wb_alerts_count'] >= 4,
            validation_results['data']['states_diversity'] >= 3,
            validation_results['data']['categories_diversity'] >= 3,
            validation_results['data']['rich_content']['requests_with_response'] >= 1,
            validation_results['data']['rich_content']['resolved_alerts'] >= 1
        ]
        
        for criterion in data_criteria:
            total_tests += 1
            if criterion:
                passed_tests += 1
        
        # Score performance
        performance_criteria = [
            validation_results['performance']['search_time'] < 1.0,
            validation_results['performance']['view_time'] < 0.5
        ]
        
        for criterion in performance_criteria:
            total_tests += 1
            if criterion:
                passed_tests += 1
        
        # Calcul du score final
        success_rate = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
        
        print(f"   📊 Tests réussis: {passed_tests}/{total_tests}")
        print(f"   🎯 Taux de réussite: {success_rate:.1f}%")
        print()
        
        # Évaluation finale
        if success_rate >= 95:
            status = "🏆 EXCELLENT"
            message = "Système prêt pour la production"
            color = "green"
        elif success_rate >= 85:
            status = "✅ TRÈS BIEN"
            message = "Système prêt avec quelques améliorations mineures"
            color = "lightgreen"
        elif success_rate >= 75:
            status = "👍 BIEN"
            message = "Système fonctionnel, améliorations recommandées"
            color = "yellow"
        elif success_rate >= 60:
            status = "⚠️  MOYEN"
            message = "Système partiellement fonctionnel, corrections nécessaires"
            color = "orange"
        else:
            status = "❌ INSUFFISANT"
            message = "Système non prêt, révision majeure requise"
            color = "red"
        
        print(f"🎯 ÉVALUATION FINALE: {status}")
        print(f"   {message}")
        print()
        
        # Recommandations
        print("💡 RECOMMANDATIONS:")
        
        if success_rate >= 85:
            print("   ✅ Procéder à la formation des utilisateurs")
            print("   ✅ Configurer les notifications email")
            print("   ✅ Personnaliser les workflows si nécessaire")
            print("   ✅ Planifier la mise en production")
        else:
            print("   🔧 Corriger les erreurs identifiées")
            print("   📊 Enrichir les données de démonstration")
            print("   🎨 Vérifier toutes les vues")
            print("   🔒 Valider la configuration de sécurité")
        
        print()
        print("📚 RESSOURCES DISPONIBLES:")
        print("   📖 Guide d'analyse: GUIDE_ANALYSE_DONNEES.md")
        print("   🧪 Scripts de test: scripts/")
        print("   📋 Documentation: README.md")
        print("   🔧 Scripts d'installation: scripts/install_complete_demo.sh")
        
        return success_rate >= 75
        
    except Exception as e:
        print(f"❌ Erreur critique lors de la validation: {e}")
        import traceback
        traceback.print_exc()
        return False

# Exécuter la validation si dans le contexte Odoo
try:
    result = validate_complete_system()
    print("\\n" + "=" * 60)
    if result:
        print("🎉 SAMA CONAI: VALIDATION RÉUSSIE!")
        print("   Le système est prêt pour l'utilisation")
    else:
        print("🔧 SAMA CONAI: VALIDATION PARTIELLE")
        print("   Des améliorations sont nécessaires")
    print("=" * 60)
except NameError:
    print("❌ Ce script doit être exécuté dans le shell Odoo.")
    print("   Usage: ./odoo-bin shell -c odoo.conf -d your_database")
    print("   Puis: exec(open('scripts/validate_complete_system.py').read())")