#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script d'analyse des doublons de menus Odoo
"""

import xml.etree.ElementTree as ET
import os
from collections import defaultdict

def analyze_menu_files():
    """Analyse tous les fichiers XML pour détecter les doublons de menus"""
    
    print("🔍 ANALYSE DES DOUBLONS DE MENUS ODOO")
    print("=" * 50)
    
    # Fichiers à analyser
    xml_files = []
    
    # Rechercher tous les fichiers XML
    for root, dirs, files in os.walk('.'):
        # Ignorer certains répertoires
        dirs[:] = [d for d in dirs if not d.startswith('.') and d != '__pycache__']
        
        for file in files:
            if file.endswith('.xml'):
                xml_files.append(os.path.join(root, file))
    
    print(f"📁 Fichiers XML trouvés: {len(xml_files)}")
    
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
                    # Calculer le numéro de ligne approximatif
                    line_num = i + 1
                    menu_definitions[menu_id].append((xml_file, line_num, menu_name))
                    
                if menu_name:
                    menu_names[menu_name].append((xml_file, menu_id))
                    
        except ET.ParseError as e:
            print(f"   ⚠️ Erreur XML dans {xml_file}: {e}")
        except Exception as e:
            print(f"   ⚠️ Erreur dans {xml_file}: {e}")
    
    # Analyser les doublons
    print(f"\n📊 RÉSULTATS DE L'ANALYSE")
    print("=" * 30)
    
    # Doublons par ID
    id_duplicates = {menu_id: files for menu_id, files in menu_definitions.items() if len(files) > 1}
    
    if id_duplicates:
        print(f"\n❌ DOUBLONS PAR ID ({len(id_duplicates)} trouvés):")
        for menu_id, files in id_duplicates.items():
            print(f"\n   🔴 ID: {menu_id}")
            for file, line, name in files:
                print(f"      📄 {file}:{line} - '{name}'")
    else:
        print(f"\n✅ Aucun doublon par ID détecté")
    
    # Doublons par nom
    name_duplicates = {name: files for name, files in menu_names.items() if len(files) > 1}
    
    if name_duplicates:
        print(f"\n⚠️ DOUBLONS PAR NOM ({len(name_duplicates)} trouvés):")
        for name, files in name_duplicates.items():
            print(f"\n   🟡 Nom: '{name}'")
            for file, menu_id in files:
                print(f"      📄 {file} - ID: {menu_id}")
    else:
        print(f"\n✅ Aucun doublon par nom détecté")
    
    # Fichiers suspects
    print(f"\n🕵️ FICHIERS SUSPECTS:")
    
    suspect_files = []
    for xml_file in xml_files:
        if any(pattern in xml_file for pattern in ['_old', 'backup', '.backup', 'temp']):
            suspect_files.append(xml_file)
    
    if suspect_files:
        for file in suspect_files:
            print(f"   ⚠️ {file}")
    else:
        print(f"   ✅ Aucun fichier suspect détecté")
    
    # Fichiers dans le manifest
    print(f"\n📋 VÉRIFICATION DU MANIFEST:")
    
    try:
        with open('__manifest__.py', 'r') as f:
            manifest_content = f.read()
            
        # Extraire les fichiers de données
        if "'data': [" in manifest_content:
            data_section = manifest_content.split("'data': [")[1].split(']')[0]
            data_files = []
            for line in data_section.split('\n'):
                if '.xml' in line and 'views/' in line:
                    # Extraire le nom du fichier
                    file_ref = line.strip().strip(',').strip("'").strip('"')
                    if file_ref:
                        data_files.append(file_ref)
            
            print(f"   📄 Fichiers de vues dans le manifest:")
            for file in data_files:
                if os.path.exists(file):
                    print(f"      ✅ {file}")
                else:
                    print(f"      ❌ {file} (manquant)")
                    
    except Exception as e:
        print(f"   ❌ Erreur lors de la lecture du manifest: {e}")
    
    # Recommandations
    print(f"\n💡 RECOMMANDATIONS:")
    
    if id_duplicates:
        print(f"   🔧 Supprimer les fichiers dupliqués ou les renommer")
        
    if suspect_files:
        print(f"   🗑️ Supprimer les fichiers de sauvegarde/temporaires:")
        for file in suspect_files:
            print(f"      rm {file}")
    
    if not id_duplicates and not suspect_files:
        print(f"   ✅ Structure des menus propre")
        print(f"   🔍 Vérifier la base de données Odoo pour les doublons persistants")
    
    return len(id_duplicates) == 0 and len(suspect_files) == 0

if __name__ == "__main__":
    success = analyze_menu_files()
    exit(0 if success else 1)