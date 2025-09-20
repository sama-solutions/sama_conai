#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de test de syntaxe pour le module SAMA CONAI
"""

import xml.etree.ElementTree as ET
import os
import sys

def test_xml_syntax():
    """Teste la syntaxe XML de tous les fichiers de vues"""
    
    print("🧪 Test de syntaxe XML - Module SAMA CONAI")
    print("=" * 50)
    
    xml_files = []
    
    # Rechercher tous les fichiers XML dans views/
    for root, dirs, files in os.walk('views'):
        for file in files:
            if file.endswith('.xml'):
                xml_files.append(os.path.join(root, file))
    
    # Ajouter les fichiers de données
    data_files = [
        'data/information_request_stages.xml',
        'data/refusal_reasons.xml', 
        'data/whistleblowing_stages.xml',
        'data/sequences.xml'
    ]
    
    for data_file in data_files:
        if os.path.exists(data_file):
            xml_files.append(data_file)
    
    errors = []
    success_count = 0
    
    for xml_file in xml_files:
        try:
            tree = ET.parse(xml_file)
            print(f"✅ {xml_file}")
            success_count += 1
        except ET.ParseError as e:
            print(f"❌ {xml_file}: {e}")
            errors.append((xml_file, str(e)))
        except FileNotFoundError:
            print(f"⚠️  {xml_file}: Fichier non trouvé")
    
    print(f"\n📊 Résultats:")
    print(f"   Fichiers testés: {len(xml_files)}")
    print(f"   Succès: {success_count}")
    print(f"   Erreurs: {len(errors)}")
    
    if errors:
        print(f"\n❌ Erreurs détectées:")
        for file, error in errors:
            print(f"   {file}: {error}")
        return False
    else:
        print(f"\n✅ Tous les fichiers XML sont valides!")
        return True

def test_manifest_syntax():
    """Teste la syntaxe du fichier manifest"""
    
    print(f"\n🔍 Test du fichier __manifest__.py")
    
    try:
        with open('__manifest__.py', 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Test de compilation Python
        compile(content, '__manifest__.py', 'exec')
        print("✅ Syntaxe Python valide")
        
        # Test d'évaluation du dictionnaire
        manifest_dict = eval(content)
        
        # Vérifications de base
        required_keys = ['name', 'version', 'depends', 'data']
        for key in required_keys:
            if key not in manifest_dict:
                print(f"❌ Clé manquante: {key}")
                return False
            else:
                print(f"✅ Clé présente: {key}")
        
        # Vérifier que tous les fichiers de données existent
        missing_files = []
        for data_file in manifest_dict['data']:
            if not os.path.exists(data_file):
                missing_files.append(data_file)
        
        if missing_files:
            print(f"❌ Fichiers manquants dans 'data':")
            for file in missing_files:
                print(f"   {file}")
            return False
        else:
            print(f"✅ Tous les fichiers de données existent ({len(manifest_dict['data'])} fichiers)")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur dans __manifest__.py: {e}")
        return False

def main():
    """Fonction principale"""
    
    xml_ok = test_xml_syntax()
    manifest_ok = test_manifest_syntax()
    
    print(f"\n🏁 Résultat final:")
    if xml_ok and manifest_ok:
        print("✅ Module prêt pour l'installation!")
        return 0
    else:
        print("❌ Erreurs détectées - Correction nécessaire")
        return 1

if __name__ == "__main__":
    sys.exit(main())