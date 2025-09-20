#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de validation des menus SAMA CONAI
Vérifie que toutes les actions référencées dans les menus existent
"""

import os
import re
import xml.etree.ElementTree as ET
from collections import defaultdict

def extract_actions_from_menus(menu_file):
    """Extrait toutes les actions référencées dans le fichier de menu"""
    actions = []
    try:
        tree = ET.parse(menu_file)
        root = tree.getroot()
        
        for menuitem in root.findall('.//menuitem[@action]'):
            action = menuitem.get('action')
            if action:
                actions.append(action)
    except Exception as e:
        print(f"❌ Erreur lors de la lecture de {menu_file}: {e}")
    
    return actions

def extract_actions_from_views(views_dir):
    """Extrait toutes les actions définies dans les fichiers de vues"""
    actions = []
    
    for root, dirs, files in os.walk(views_dir):
        for file in files:
            if file.endswith('.xml') and file != 'menus.xml':
                file_path = os.path.join(root, file)
                try:
                    tree = ET.parse(file_path)
                    xml_root = tree.getroot()
                    
                    for record in xml_root.findall('.//record[@id][@model]'):
                        record_id = record.get('id')
                        model = record.get('model')
                        
                        if record_id and record_id.startswith('action_') and 'action' in model:
                            actions.append(record_id)
                            
                except Exception as e:
                    print(f"⚠️ Erreur lors de la lecture de {file_path}: {e}")
    
    return actions

def validate_menus():
    """Valide que toutes les actions des menus existent"""
    print("🔍 VALIDATION DES MENUS SAMA CONAI")
    print("=" * 50)
    
    # Extraire les actions des menus
    menu_actions = extract_actions_from_menus('views/menus.xml')
    print(f"📋 Actions référencées dans les menus: {len(menu_actions)}")
    
    # Extraire les actions des vues
    view_actions = extract_actions_from_views('views/')
    print(f"📄 Actions définies dans les vues: {len(view_actions)}")
    
    # Vérifier les actions manquantes
    missing_actions = []
    for action in menu_actions:
        if action not in view_actions:
            missing_actions.append(action)
    
    # Vérifier les doublons dans les menus
    action_count = defaultdict(int)
    for action in menu_actions:
        action_count[action] += 1
    
    duplicates = {action: count for action, count in action_count.items() if count > 1}
    
    # Afficher les résultats
    print("\n📊 RÉSULTATS DE LA VALIDATION")
    print("-" * 30)
    
    if missing_actions:
        print(f"❌ Actions manquantes ({len(missing_actions)}):")
        for action in missing_actions:
            print(f"   • {action}")
    else:
        print("✅ Toutes les actions référencées existent")
    
    if duplicates:
        print(f"\n⚠️ Actions dupliquées ({len(duplicates)}):")
        for action, count in duplicates.items():
            print(f"   • {action} (référencée {count} fois)")
    else:
        print("✅ Aucun doublon détecté")
    
    # Actions définies mais non utilisées
    unused_actions = []
    for action in view_actions:
        if action not in menu_actions:
            unused_actions.append(action)
    
    if unused_actions:
        print(f"\n📝 Actions définies mais non utilisées ({len(unused_actions)}):")
        for action in unused_actions:
            print(f"   • {action}")
    
    # Résumé
    print(f"\n🎯 RÉSUMÉ")
    print("-" * 20)
    print(f"✅ Actions valides: {len(menu_actions) - len(missing_actions)}")
    print(f"❌ Actions manquantes: {len(missing_actions)}")
    print(f"⚠️ Doublons: {len(duplicates)}")
    print(f"📝 Actions non utilisées: {len(unused_actions)}")
    
    # Score de qualité
    total_actions = len(menu_actions)
    valid_actions = total_actions - len(missing_actions) - len(duplicates)
    quality_score = (valid_actions / total_actions * 100) if total_actions > 0 else 0
    
    print(f"\n📊 Score de qualité: {quality_score:.1f}%")
    
    if quality_score >= 95:
        print("🎉 Excellente qualité des menus!")
    elif quality_score >= 85:
        print("👍 Bonne qualité des menus")
    elif quality_score >= 70:
        print("⚠️ Qualité acceptable, améliorations recommandées")
    else:
        print("❌ Qualité insuffisante, corrections nécessaires")
    
    return len(missing_actions) == 0 and len(duplicates) == 0

if __name__ == "__main__":
    success = validate_menus()
    exit(0 if success else 1)