#!/usr/bin/env python3
"""
Script de vérification des liens du site SAMA CONAI
Vérifie que tous les liens internes pointent vers des fichiers existants
"""

import os
import re
from pathlib import Path

def find_html_files(directory):
    """Trouve tous les fichiers HTML dans le répertoire"""
    html_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.html'):
                html_files.append(os.path.join(root, file))
    return html_files

def extract_links(file_path):
    """Extrait tous les liens href d'un fichier HTML"""
    links = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # Recherche des liens href
            href_pattern = r'href=["\']([^"\']+)["\']'
            matches = re.findall(href_pattern, content)
            for match in matches:
                # Ignore les liens externes et les ancres
                if not match.startswith(('http', 'https', 'mailto', '#')):
                    links.append(match)
    except Exception as e:
        print(f"Erreur lors de la lecture de {file_path}: {e}")
    return links

def check_link_exists(base_path, link):
    """Vérifie si un lien pointe vers un fichier existant"""
    # Séparer le fichier de l'ancre
    if '#' in link:
        file_part, anchor = link.split('#', 1)
        if not file_part:  # Lien vers une ancre dans la même page
            return True, "ancre locale"
    else:
        file_part = link
    
    # Résoudre le chemin relatif
    if file_part.startswith('/'):
        # Lien absolu depuis la racine
        full_path = os.path.join(os.path.dirname(base_path), file_part[1:])
    else:
        # Lien relatif
        full_path = os.path.join(os.path.dirname(base_path), file_part)
    
    # Normaliser le chemin
    full_path = os.path.normpath(full_path)
    
    # Vérifier si le fichier existe
    return os.path.exists(full_path), full_path

def main():
    """Fonction principale"""
    website_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Vérification des liens dans : {website_dir}")
    print("=" * 60)
    
    html_files = find_html_files(website_dir)
    total_links = 0
    broken_links = 0
    
    for html_file in html_files:
        print(f"\n📄 Vérification de : {os.path.relpath(html_file, website_dir)}")
        links = extract_links(html_file)
        
        if not links:
            print("   ✅ Aucun lien interne trouvé")
            continue
            
        for link in links:
            total_links += 1
            exists, full_path = check_link_exists(html_file, link)
            
            if exists:
                print(f"   ✅ {link}")
            else:
                print(f"   ❌ {link} -> {full_path}")
                broken_links += 1
    
    print("\n" + "=" * 60)
    print(f"📊 RÉSUMÉ")
    print(f"   Fichiers HTML vérifiés : {len(html_files)}")
    print(f"   Liens internes trouvés : {total_links}")
    print(f"   Liens cassés : {broken_links}")
    
    if broken_links == 0:
        print("   🎉 Tous les liens fonctionnent correctement !")
    else:
        print(f"   ⚠️  {broken_links} lien(s) à corriger")
    
    return broken_links == 0

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)