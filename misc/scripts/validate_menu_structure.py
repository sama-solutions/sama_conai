#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de validation de la structure des menus SAMA CONAI
"""

import xml.etree.ElementTree as ET
import os

def validate_menu_structure():
    """Valide la structure des menus et actions"""
    
    print("🔍 Validation de la structure des menus SAMA CONAI")
    print("=" * 60)
    
    # Fichiers à vérifier
    files_to_check = [
        'views/menus.xml',
        'views/information_request_views.xml',
        'views/information_request_stage_views.xml',
        'views/refusal_reason_views.xml',
        'views/whistleblowing_alert_views.xml',
        'views/whistleblowing_stage_views.xml',
        'views/administration_views.xml',
        'views/analytics_filtered_views.xml',
        'views/analytics/executive_dashboard_views.xml',
        'views/analytics/auto_report_generator_views.xml'
    ]
    
    actions_found = set()
    menus_found = set()
    
    for file_path in files_to_check:
        if os.path.exists(file_path):
            print(f"✅ Fichier trouvé: {file_path}")
            try:
                tree = ET.parse(file_path)
                root = tree.getroot()
                
                # Chercher les actions
                for record in root.findall(".//record[@model='ir.actions.act_window']"):
                    action_id = record.get('id')
                    if action_id:
                        actions_found.add(action_id)
                
                # Chercher les menus
                for menuitem in root.findall(".//menuitem"):
                    menu_id = menuitem.get('id')
                    if menu_id:
                        menus_found.add(menu_id)
                        
            except ET.ParseError as e:
                print(f"❌ Erreur XML dans {file_path}: {e}")
        else:
            print(f"❌ Fichier manquant: {file_path}")
    
    print(f"\n📊 Résumé:")
    print(f"   Actions trouvées: {len(actions_found)}")
    print(f"   Menus trouvés: {len(menus_found)}")
    
    # Actions attendues
    expected_actions = [
        'action_information_request',
        'action_information_request_analysis',
        'action_information_request_stage',
        'action_refusal_reason',
        'action_whistleblowing_alert',
        'action_whistleblowing_alert_analysis',
        'action_whistleblowing_stage',
        'action_executive_dashboard',
        'action_auto_report_generator',
        'action_auto_report_instance',
        'action_transparency_users',
        'action_transparency_groups',
        'action_transparency_config',
        'action_executive_dashboard_requests',
        'action_executive_dashboard_alerts',
        'action_auto_report_generator_requests',
        'action_auto_report_generator_alerts'
    ]
    
    print(f"\n🎯 Vérification des actions critiques:")
    for action in expected_actions:
        if action in actions_found:
            print(f"   ✅ {action}")
        else:
            print(f"   ❌ {action} - MANQUANT")
    
    # Menus principaux attendus
    expected_main_menus = [
        'menu_information_access_root',
        'menu_whistleblowing_root',
        'menu_analytics_root',
        'menu_transparency_admin'
    ]
    
    print(f"\n🏠 Vérification des menus principaux:")
    for menu in expected_main_menus:
        if menu in menus_found:
            print(f"   ✅ {menu}")
        else:
            print(f"   ❌ {menu} - MANQUANT")
    
    print(f"\n✨ Validation terminée!")

if __name__ == "__main__":
    validate_menu_structure()