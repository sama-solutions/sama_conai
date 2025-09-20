#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Validation finale de la structure des menus après nettoyage
"""

import xml.etree.ElementTree as ET
import os

def final_validation():
    """Validation finale complète de la structure des menus"""
    
    print("🏁 VALIDATION FINALE DES MENUS SAMA CONAI")
    print("=" * 50)
    
    # Vérifications critiques
    checks = {
        'manifest_correct': False,
        'menu_file_exists': False,
        'menu_file_valid': False,
        'no_duplicates': False,
        'all_actions_exist': False,
        'structure_complete': False
    }
    
    # 1. Vérifier le manifest
    print("📋 1. Vérification du manifest...")
    try:
        with open('__manifest__.py', 'r') as f:
            manifest_content = f.read()
        
        if "'views/menus.xml'" in manifest_content and "'views/menus_old.xml'" not in manifest_content:
            checks['manifest_correct'] = True
            print("   ✅ Manifest correct - seul views/menus.xml référencé")
        else:
            print("   ❌ Problème dans le manifest")
    except Exception as e:
        print(f"   ❌ Erreur manifest: {e}")
    
    # 2. Vérifier l'existence du fichier de menus
    print("\\n📄 2. Vérification du fichier de menus...")
    if os.path.exists('views/menus.xml'):
        checks['menu_file_exists'] = True
        print("   ✅ Fichier views/menus.xml existe")
    else:
        print("   ❌ Fichier views/menus.xml manquant")
    
    # 3. Vérifier la validité XML
    print("\\n🔍 3. Validation XML...")
    try:
        tree = ET.parse('views/menus.xml')
        root = tree.getroot()
        checks['menu_file_valid'] = True
        print("   ✅ XML valide")
        
        # Compter les menus
        menus = root.findall(".//menuitem")
        print(f"   📊 {len(menus)} menus définis")
        
    except ET.ParseError as e:
        print(f"   ❌ Erreur XML: {e}")
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
    
    # 4. Vérifier l'absence de doublons
    print("\\n🔍 4. Vérification des doublons...")
    try:
        from collections import defaultdict
        
        menu_ids = defaultdict(int)
        for menuitem in root.findall(".//menuitem"):
            menu_id = menuitem.get('id')
            if menu_id:
                menu_ids[menu_id] += 1
        
        duplicates = {mid: count for mid, count in menu_ids.items() if count > 1}
        
        if not duplicates:
            checks['no_duplicates'] = True
            print("   ✅ Aucun doublon détecté")
        else:
            print(f"   ❌ {len(duplicates)} doublons trouvés: {list(duplicates.keys())}")
            
    except Exception as e:
        print(f"   ❌ Erreur vérification doublons: {e}")
    
    # 5. Vérifier les actions référencées
    print("\\n🎯 5. Vérification des actions...")
    try:
        actions_referenced = set()
        for menuitem in root.findall(".//menuitem"):
            action = menuitem.get('action')
            if action:
                actions_referenced.add(action)
        
        print(f"   📊 {len(actions_referenced)} actions référencées")
        
        # Actions critiques attendues
        critical_actions = [
            'action_information_request',
            'action_information_request_analysis',
            'action_whistleblowing_alert',
            'action_whistleblowing_alert_analysis',
            'action_executive_dashboard',
            'action_auto_report_generator'
        ]
        
        missing_actions = [action for action in critical_actions if action not in actions_referenced]
        
        if not missing_actions:
            checks['all_actions_exist'] = True
            print("   ✅ Toutes les actions critiques référencées")
        else:
            print(f"   ⚠️ Actions manquantes: {missing_actions}")
            
    except Exception as e:
        print(f"   ❌ Erreur vérification actions: {e}")
    
    # 6. Vérifier la structure complète
    print("\\n🏗️ 6. Vérification de la structure...")
    try:
        # Menus principaux attendus
        main_menus = [
            'menu_information_access_root',
            'menu_whistleblowing_root',
            'menu_analytics_root',
            'menu_transparency_admin'
        ]
        
        found_main_menus = []
        for menuitem in root.findall(".//menuitem"):
            menu_id = menuitem.get('id')
            if menu_id in main_menus:
                found_main_menus.append(menu_id)
        
        if len(found_main_menus) >= 3:  # Au moins 3 menus principaux
            checks['structure_complete'] = True
            print(f"   ✅ Structure complète - {len(found_main_menus)} menus principaux")
        else:
            print(f"   ❌ Structure incomplète - seulement {len(found_main_menus)} menus principaux")
            
    except Exception as e:
        print(f"   ❌ Erreur vérification structure: {e}")
    
    # 7. Vérifier l'absence de fichiers problématiques
    print("\\n🧹 7. Vérification de la propreté...")
    problematic_files = [
        'views/menus_old.xml',
        'views/information_request_views.xml.backup',
        'backups/sama_conai_stable_20250906_055044'
    ]
    
    clean = True
    for file in problematic_files:
        if os.path.exists(file):
            print(f"   ⚠️ Fichier problématique encore présent: {file}")
            clean = False
    
    if clean:
        print("   ✅ Environnement propre - aucun fichier problématique")
    
    # Résumé final
    print("\\n📊 RÉSUMÉ DE LA VALIDATION")
    print("=" * 30)
    
    passed_checks = sum(checks.values())
    total_checks = len(checks)
    
    for check_name, passed in checks.items():
        status = "✅" if passed else "❌"
        print(f"   {status} {check_name.replace('_', ' ').title()}")
    
    success_rate = (passed_checks / total_checks) * 100
    
    print(f"\\n📈 Score de validation: {success_rate:.1f}% ({passed_checks}/{total_checks})")
    
    if success_rate == 100:
        print("\\n🎉 VALIDATION PARFAITE !")
        print("✅ Les menus sont prêts pour la production")
        print("🚀 Vous pouvez redémarrer Odoo en toute sécurité")
        
        print("\\n🔄 COMMANDES RECOMMANDÉES:")
        print("   # Redémarrer Odoo")
        print("   ./start_sama_conai_analytics_fixed.sh")
        print("   ")
        print("   # Nettoyer les sauvegardes (optionnel)")
        print("   rm -rf deleted_files_backup_*")
        
    elif success_rate >= 80:
        print("\\n✅ VALIDATION RÉUSSIE avec réserves")
        print("⚠️ Quelques points mineurs à corriger")
        print("🚀 Le module peut être démarré")
        
    else:
        print("\\n❌ VALIDATION ÉCHOUÉE")
        print("🔧 Corrections nécessaires avant utilisation")
    
    print("\\n📚 DOCUMENTATION:")
    print("   📋 Rapport complet: MENU_CLEANUP_REPORT.md")
    print("   🔍 Scripts disponibles: check_active_menus.py")
    
    return success_rate >= 80

if __name__ == "__main__":
    success = final_validation()
    exit(0 if success else 1)