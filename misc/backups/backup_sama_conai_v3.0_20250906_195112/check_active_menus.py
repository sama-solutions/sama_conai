#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour vérifier les menus actifs (hors sauvegardes)
"""

import xml.etree.ElementTree as ET
import os
from collections import defaultdict

def check_active_menus():
    """Vérifie les menus dans les fichiers actifs uniquement"""
    
    print("🔍 VÉRIFICATION DES MENUS ACTIFS")
    print("=" * 40)
    
    # Fichiers à analyser (hors sauvegardes)
    xml_files = []
    
    # Rechercher tous les fichiers XML actifs
    for root, dirs, files in os.walk('.'):
        # Ignorer les répertoires de sauvegarde
        dirs[:] = [d for d in dirs if not any(skip in d for skip in [
            'deleted_files_backup', 'backup', '__pycache__', '.git'
        ])]
        
        # Ignorer les fichiers de sauvegarde
        if any(skip in root for skip in ['deleted_files_backup', 'backup']):
            continue
            
        for file in files:
            if file.endswith('.xml') and not any(skip in file for skip in [
                '_old', '.backup', 'backup'
            ]):
                xml_files.append(os.path.join(root, file))
    
    print(f"📁 Fichiers XML actifs: {len(xml_files)}")
    
    # Dictionnaires pour stocker les informations
    menu_definitions = defaultdict(list)  # menu_id -> [(file, line, name)]
    menu_names = defaultdict(list)        # menu_name -> [(file, menu_id)]
    
    # Analyser chaque fichier
    for xml_file in xml_files:
        try:
            tree = ET.parse(xml_file)
            root = tree.getroot()
            
            # Chercher les menuitem
            for i, menuitem in enumerate(root.findall(".//menuitem")):
                menu_id = menuitem.get('id')
                menu_name = menuitem.get('name')
                
                if menu_id:
                    line_num = i + 1
                    menu_definitions[menu_id].append((xml_file, line_num, menu_name))
                    
                if menu_name:
                    menu_names[menu_name].append((xml_file, menu_id))
                    
        except ET.ParseError as e:
            print(f"   ⚠️ Erreur XML dans {xml_file}: {e}")
        except Exception as e:
            print(f"   ⚠️ Erreur dans {xml_file}: {e}")
    
    # Analyser les doublons
    print(f"\\n📊 RÉSULTATS DE L'ANALYSE (FICHIERS ACTIFS)")
    print("=" * 50)
    
    # Doublons par ID
    id_duplicates = {menu_id: files for menu_id, files in menu_definitions.items() if len(files) > 1}
    
    if id_duplicates:
        print(f"\\n❌ DOUBLONS PAR ID ({len(id_duplicates)} trouvés):")
        for menu_id, files in id_duplicates.items():
            print(f"\\n   🔴 ID: {menu_id}")
            for file, line, name in files:
                print(f"      📄 {file}:{line} - '{name}'")
    else:
        print(f"\\n✅ Aucun doublon par ID détecté dans les fichiers actifs")
    
    # Doublons par nom (mais dans le même fichier, c'est normal)
    name_duplicates_cross_files = {}
    for name, files in menu_names.items():
        if len(files) > 1:
            # Vérifier si c'est dans des fichiers différents
            unique_files = set(file for file, menu_id in files)
            if len(unique_files) > 1:
                name_duplicates_cross_files[name] = files
    
    if name_duplicates_cross_files:
        print(f"\\n⚠️ DOUBLONS PAR NOM ENTRE FICHIERS ({len(name_duplicates_cross_files)} trouvés):")
        for name, files in name_duplicates_cross_files.items():
            print(f"\\n   🟡 Nom: '{name}'")
            for file, menu_id in files:
                print(f"      📄 {file} - ID: {menu_id}")
    else:
        print(f"\\n✅ Aucun doublon par nom entre fichiers différents")
    
    # Noms dupliqués dans le même fichier (normal pour les sous-menus)
    same_file_duplicates = {}
    for name, files in menu_names.items():
        if len(files) > 1:
            unique_files = set(file for file, menu_id in files)
            if len(unique_files) == 1:  # Même fichier
                same_file_duplicates[name] = files
    
    if same_file_duplicates:
        print(f"\\n📋 NOMS IDENTIQUES DANS LE MÊME FICHIER (normal pour sous-menus):")
        for name, files in same_file_duplicates.items():
            print(f"   📝 '{name}' - {len(files)} occurrences dans {files[0][0]}")
    
    # Structure des menus principaux
    print(f"\\n🏠 MENUS PRINCIPAUX DÉTECTÉS:")
    main_menus = []
    for menu_id, files in menu_definitions.items():
        if len(files) == 1:  # Pas de doublon
            file, line, name = files[0]
            if 'root' in menu_id or any(main in menu_id for main in ['information_access', 'whistleblowing', 'analytics']):
                main_menus.append((menu_id, name, file))
    
    for menu_id, name, file in main_menus:
        print(f"   🏠 {name} (ID: {menu_id})")
    
    # Résumé
    print(f"\\n📊 RÉSUMÉ:")
    print(f"   📄 Fichiers XML actifs analysés: {len(xml_files)}")
    print(f"   🆔 Menus uniques: {len([m for m in menu_definitions.values() if len(m) == 1])}")
    print(f"   🔴 Doublons par ID: {len(id_duplicates)}")
    print(f"   🟡 Doublons par nom (entre fichiers): {len(name_duplicates_cross_files)}")
    print(f"   🏠 Menus principaux: {len(main_menus)}")
    
    if len(id_duplicates) == 0 and len(name_duplicates_cross_files) == 0:
        print(f"\\n🎉 EXCELLENT ! Aucun doublon détecté dans les fichiers actifs")
        print(f"\\n✅ Structure des menus propre et prête pour Odoo")
        return True
    else:
        print(f"\\n⚠️ Des doublons persistent dans les fichiers actifs")
        return False

if __name__ == "__main__":
    success = check_active_menus()
    exit(0 if success else 1)