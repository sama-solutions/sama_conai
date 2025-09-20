#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de test pour vérifier que les styles de menu sont bien présents
"""

import os

def test_menu_styles():
    """
    Vérifie que les styles CSS pour corriger les couleurs de menu sont présents
    """
    css_file = "static/src/css/backend.css"
    
    if not os.path.exists(css_file):
        print(f"❌ Fichier CSS non trouvé: {css_file}")
        return False
    
    with open(css_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Vérifications des styles essentiels
    checks = [
        ("CORRECTION COULEUR MENUS", "Section de correction des menus"),
        ("o_main_navbar", "Sélecteurs de navbar"),
        ("color: white !important", "Couleur blanche forcée"),
        ("dropdown-toggle", "Sélecteurs dropdown"),
        ("first-child", "Sélecteurs premier enfant"),
        ("Force globale sur tous les liens", "Force globale"),
        ("CORRECTION SUPPLÉMENTAIRE PREMIER MENU", "Section supplémentaire")
    ]
    
    print("🔍 Vérification des styles CSS pour les menus...")
    
    all_good = True
    for check, description in checks:
        if check in content:
            print(f"   ✅ {description}")
        else:
            print(f"   ❌ {description} - MANQUANT")
            all_good = False
    
    # Compter les occurrences de color: white !important
    white_count = content.count("color: white !important")
    print(f"   📊 Nombre de 'color: white !important': {white_count}")
    
    if white_count < 5:
        print("   ⚠️  Nombre faible de règles de couleur blanche")
        all_good = False
    else:
        print("   ✅ Nombre suffisant de règles de couleur blanche")
    
    if all_good:
        print("\n✅ Tous les styles de correction des menus sont présents !")
        print("   Redémarrez Odoo et videz le cache du navigateur pour voir les changements.")
    else:
        print("\n❌ Certains styles sont manquants.")
    
    return all_good

if __name__ == '__main__':
    test_menu_styles()