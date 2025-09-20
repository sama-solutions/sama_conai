#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de validation des nouvelles fonctionnalités intégrées
"""

import psycopg2

def connect_db():
    """Connexion à la base de données"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="sama_conai_analytics",
            user="odoo",
            password="odoo"
        )
        return conn
    except Exception as e:
        print(f"❌ Erreur de connexion à la base: {e}")
        return None

def validate_new_features():
    """Valide l'intégration des nouvelles fonctionnalités"""
    
    print("🔍 VALIDATION DES NOUVELLES FONCTIONNALITÉS")
    print("=" * 50)
    
    conn = connect_db()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # 1. Vérifier les nouvelles actions
        print("🎯 1. Validation des nouvelles actions...")
        
        nouvelles_actions = [
            'action_sama_conai_dashboard',
            'action_info_requests_graph', 
            'action_whistleblowing_by_category',
            'action_overdue_requests',
            'action_urgent_alerts',
            'action_monthly_requests',
            'action_info_requests_analysis'
        ]
        
        actions_trouvees = []
        for action in nouvelles_actions:
            cursor.execute("""
                SELECT name FROM ir_act_window 
                WHERE id = (SELECT res_id FROM ir_model_data WHERE name = %s AND module = 'sama_conai')
            """, (action,))
            
            result = cursor.fetchone()
            if result:
                actions_trouvees.append((action, result[0]))
                print(f"   ✅ {action}: {result[0]}")
            else:
                print(f"   ❌ {action}: Non trouvée")
        
        print(f"   📊 Actions trouvées: {len(actions_trouvees)}/{len(nouvelles_actions)}")
        
        # 2. Vérifier les nouveaux menus
        print(f"\\n📋 2. Validation des nouveaux menus...")
        
        nouveaux_menus = [
            'menu_information_advanced_analysis',
            'menu_information_evolution_graph',
            'menu_whistleblowing_urgent',
            'menu_whistleblowing_by_category',
            'menu_sama_conai_main_dashboard',
            'menu_analytics_kpi',
            'menu_analytics_visualizations',
            'menu_kpi_overdue_requests',
            'menu_kpi_urgent_alerts',
            'menu_kpi_monthly_requests'
        ]
        
        menus_trouves = []
        for menu in nouveaux_menus:
            cursor.execute("""
                SELECT name FROM ir_ui_menu 
                WHERE id = (SELECT res_id FROM ir_model_data WHERE name = %s AND module = 'sama_conai')
            """, (menu,))
            
            result = cursor.fetchone()
            if result:
                # Extraire le nom du JSON
                if isinstance(result[0], dict):
                    menu_name = result[0].get('en_US', str(result[0]))
                else:
                    menu_name = str(result[0])
                menus_trouves.append((menu, menu_name))
                print(f"   ✅ {menu}: {menu_name}")
            else:
                print(f"   ❌ {menu}: Non trouvé")
        
        print(f"   📊 Menus trouvés: {len(menus_trouves)}/{len(nouveaux_menus)}")
        
        # 3. Vérifier la structure enrichie
        print(f"\\n🏗️ 3. Validation de la structure enrichie...")
        
        # Compter les menus par section
        cursor.execute("""
            SELECT COUNT(*) FROM ir_ui_menu m
            JOIN ir_model_data d ON m.id = d.res_id
            WHERE d.module = 'sama_conai' AND d.name LIKE 'menu_analytics_%'
        """)
        analytics_menus = cursor.fetchone()[0]
        
        cursor.execute("""
            SELECT COUNT(*) FROM ir_ui_menu m
            JOIN ir_model_data d ON m.id = d.res_id
            WHERE d.module = 'sama_conai' AND d.name LIKE 'menu_information_%'
        """)
        information_menus = cursor.fetchone()[0]
        
        cursor.execute("""
            SELECT COUNT(*) FROM ir_ui_menu m
            JOIN ir_model_data d ON m.id = d.res_id
            WHERE d.module = 'sama_conai' AND d.name LIKE 'menu_whistleblowing_%'
        """)
        whistleblowing_menus = cursor.fetchone()[0]
        
        print(f"   📊 Menus Analytics: {analytics_menus}")
        print(f"   📄 Menus Information: {information_menus}")
        print(f"   🚨 Menus Signalements: {whistleblowing_menus}")
        
        # 4. Vérifier les nouvelles sections
        print(f"\\n📂 4. Validation des nouvelles sections...")
        
        sections_attendues = [
            ('menu_analytics_kpi', 'KPI & Indicateurs'),
            ('menu_analytics_visualizations', 'Visualisations'),
            ('menu_information_advanced_analysis', 'Analyse Avancée'),
            ('menu_whistleblowing_urgent', 'Signalements Urgents')
        ]
        
        sections_trouvees = 0
        for menu_id, description in sections_attendues:
            cursor.execute("""
                SELECT COUNT(*) FROM ir_ui_menu m
                JOIN ir_model_data d ON m.id = d.res_id
                WHERE d.module = 'sama_conai' AND d.name = %s
            """, (menu_id,))
            
            if cursor.fetchone()[0] > 0:
                sections_trouvees += 1
                print(f"   ✅ {description}")
            else:
                print(f"   ❌ {description}")
        
        print(f"   📊 Sections trouvées: {sections_trouvees}/{len(sections_attendues)}")
        
        # 5. Score global
        print(f"\\n📈 5. Score global d'intégration...")
        
        score_actions = (len(actions_trouvees) / len(nouvelles_actions)) * 100
        score_menus = (len(menus_trouves) / len(nouveaux_menus)) * 100
        score_sections = (sections_trouvees / len(sections_attendues)) * 100
        
        score_global = (score_actions + score_menus + score_sections) / 3
        
        print(f"   📊 Score Actions: {score_actions:.1f}%")
        print(f"   📋 Score Menus: {score_menus:.1f}%")
        print(f"   📂 Score Sections: {score_sections:.1f}%")
        print(f"   🎯 Score Global: {score_global:.1f}%")
        
        # Résultat final
        if score_global >= 80:
            print(f"\\n🎉 INTÉGRATION RÉUSSIE !")
            print("✅ Les nouvelles fonctionnalités sont bien intégrées")
            return True
        elif score_global >= 60:
            print(f"\\n⚠️ INTÉGRATION PARTIELLE")
            print("🔧 Quelques fonctionnalités manquent")
            return True
        else:
            print(f"\\n❌ INTÉGRATION INCOMPLÈTE")
            print("🔧 Plusieurs fonctionnalités manquent")
            return False
        
    except Exception as e:
        print(f"❌ Erreur lors de la validation: {e}")
        return False
    finally:
        cursor.close()
        conn.close()

def show_feature_summary():
    """Affiche un résumé des nouvelles fonctionnalités"""
    
    print(f"\\n📋 RÉSUMÉ DES NOUVELLES FONCTIONNALITÉS")
    print("=" * 45)
    
    fonctionnalites = [
        {
            "section": "📄 Accès à l'Information",
            "nouvelles": [
                "📈 Analyse Avancée (pivot/graph)",
                "📊 Évolution des Demandes (graphique)",
                "🎯 Menus enrichis avec nouvelles analyses"
            ]
        },
        {
            "section": "🚨 Signalement d'Alerte", 
            "nouvelles": [
                "🚨 Signalements Urgents (accès direct)",
                "📋 Signalements par Catégorie (visualisation)",
                "🎯 Filtres et analyses améliorés"
            ]
        },
        {
            "section": "📊 Analytics & Rapports",
            "nouvelles": [
                "🎯 Tableau de Bord Principal SAMA CONAI",
                "📊 Section KPI & Indicateurs",
                "📈 Section Visualisations",
                "⏰ Demandes en Retard (KPI)",
                "📅 Demandes du Mois (KPI)"
            ]
        }
    ]
    
    for section_info in fonctionnalites:
        print(f"\\n{section_info['section']}:")
        for fonctionnalite in section_info['nouvelles']:
            print(f"   ✨ {fonctionnalite}")
    
    print(f"\\n🎯 AVANTAGES:")
    print("   📊 Meilleure visibilité sur les KPI")
    print("   📈 Analyses plus poussées")
    print("   🚨 Accès rapide aux urgences")
    print("   🎯 Navigation optimisée")
    print("   📋 Tableaux de bord enrichis")

def main():
    """Fonction principale"""
    
    print("🎯 VALIDATION DES NOUVELLES FONCTIONNALITÉS SAMA CONAI")
    print("Vérification de l'intégration des nouvelles fonctionnalités")
    print("=" * 65)
    
    if validate_new_features():
        show_feature_summary()
        
        print(f"\\n🌐 ACCÈS AU SYSTÈME:")
        print("   URL: http://localhost:8077")
        print("   Login: admin / Password: admin")
        
        print(f"\\n🧪 TESTS RECOMMANDÉS:")
        print("   1. Naviguez dans les nouveaux menus")
        print("   2. Testez les KPI et indicateurs")
        print("   3. Vérifiez les nouvelles visualisations")
        print("   4. Explorez les analyses avancées")
        
        print(f"\\n✨ NOUVELLES FONCTIONNALITÉS À DÉCOUVRIR:")
        print("   📊 Tableau de Bord Principal")
        print("   📈 Analyses Pivot Avancées")
        print("   🎯 KPI en Temps Réel")
        print("   🚨 Alertes Urgentes")
        print("   📊 Visualisations Interactives")
        
        return True
    else:
        print(f"\\n🔧 ACTIONS CORRECTIVES NÉCESSAIRES")
        print("Certaines fonctionnalités n'ont pas été intégrées correctement")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)