#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de nettoyage après réorganisation des menus
"""

import os
import shutil

def cleanup_files():
    """Nettoie les fichiers temporaires de la réorganisation"""
    
    print("🧹 Nettoyage des fichiers temporaires")
    print("=" * 40)
    
    # Fichiers à supprimer (optionnel)
    temp_files = [
        'validate_menu_structure.py',
        'test_module_syntax.py',
        'cleanup_reorganization.py',  # Ce script lui-même
        'views/menus_old.xml'  # Sauvegarde de l'ancien menu
    ]
    
    # Fichiers à conserver
    keep_files = [
        'MENU_REORGANIZATION_SUMMARY.md',
        'QUICK_TEST_GUIDE.md',
        'static/description/ICONS_README.md'
    ]
    
    print("📋 Fichiers qui peuvent être supprimés :")
    for file in temp_files:
        if os.path.exists(file):
            print(f"   📄 {file}")
        else:
            print(f"   ❌ {file} (non trouvé)")
    
    print(f"\n📋 Fichiers à conserver :")
    for file in keep_files:
        if os.path.exists(file):
            print(f"   ✅ {file}")
        else:
            print(f"   ❌ {file} (non trouvé)")
    
    print(f"\n⚠️  ATTENTION :")
    print(f"   Ce script peut supprimer des fichiers de développement.")
    print(f"   Assurez-vous que la réorganisation fonctionne correctement")
    print(f"   avant d'exécuter le nettoyage.")
    
    response = input(f"\n❓ Voulez-vous procéder au nettoyage ? (y/N): ")
    
    if response.lower() in ['y', 'yes', 'oui']:
        deleted_count = 0
        for file in temp_files:
            if os.path.exists(file):
                try:
                    os.remove(file)
                    print(f"🗑️  Supprimé: {file}")
                    deleted_count += 1
                except Exception as e:
                    print(f"❌ Erreur lors de la suppression de {file}: {e}")
        
        print(f"\n✅ Nettoyage terminé: {deleted_count} fichiers supprimés")
    else:
        print(f"\n🚫 Nettoyage annulé")

def show_final_structure():
    """Affiche la structure finale du module"""
    
    print(f"\n📁 Structure finale du module SAMA CONAI :")
    print("=" * 50)
    
    important_files = [
        '__manifest__.py',
        'views/menus.xml',
        'views/information_request_views.xml',
        'views/whistleblowing_alert_views.xml',
        'views/administration_views.xml',
        'views/analytics_filtered_views.xml',
        'views/analytics/executive_dashboard_views.xml',
        'views/analytics/auto_report_generator_views.xml',
        'MENU_REORGANIZATION_SUMMARY.md',
        'QUICK_TEST_GUIDE.md'
    ]
    
    for file in important_files:
        if os.path.exists(file):
            print(f"✅ {file}")
        else:
            print(f"❌ {file} - MANQUANT")

if __name__ == "__main__":
    show_final_structure()
    cleanup_files()
    
    print(f"\n🎉 Réorganisation des menus SAMA CONAI terminée !")
    print(f"📖 Consultez QUICK_TEST_GUIDE.md pour tester les changements")
    print(f"📚 Consultez MENU_REORGANIZATION_SUMMARY.md pour la documentation complète")