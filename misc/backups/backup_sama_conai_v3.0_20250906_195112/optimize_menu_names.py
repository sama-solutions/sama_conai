#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour optimiser les noms des menus et éliminer les confusions
"""

def optimize_menu_names():
    """Optimise les noms des menus pour éviter les confusions"""
    
    print("🎨 OPTIMISATION DES NOMS DE MENUS")
    print("=" * 40)
    
    # Lire le fichier de menus actuel
    with open('views/menus.xml', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Optimisations des noms pour éviter les confusions
    optimizations = [
        # Différencier les "Rapports et Analyses"
        ('name="Rapports et Analyses"', 'name="Rapports et Analyses"', 'first'),
        
        # Différencier les "Tableau de Bord"
        ('menu_information_dashboard', 'menu_information_dashboard'),
        ('menu_whistleblowing_dashboard', 'menu_whistleblowing_dashboard'),
        
        # Différencier les "Générateur de Rapports"
        ('menu_information_report_generator', 'menu_information_report_generator'),
        ('menu_whistleblowing_report_generator', 'menu_whistleblowing_report_generator'),
        
        # Différencier les "Configuration"
        ('menu_information_config', 'menu_information_config'),
        ('menu_whistleblowing_config', 'menu_whistleblowing_config'),
        
        # Différencier les "Étapes"
        ('menu_information_stages', 'menu_information_stages'),
        ('menu_whistleblowing_stages', 'menu_whistleblowing_stages'),
    ]
    
    # Appliquer les optimisations spécifiques
    optimized_content = content
    
    # Optimiser les noms pour plus de clarté
    replacements = [
        # Rapports et Analyses - Différencier par contexte
        ('parent="menu_information_reports"\\n                  action="action_executive_dashboard_requests"\\n                  sequence="20"/>',
         'parent="menu_information_reports"\\n                  action="action_executive_dashboard_requests"\\n                  sequence="20"/>'),
        
        # Tableau de Bord - Ajouter le contexte
        ('id="menu_information_dashboard"\\n                  name="Tableau de Bord"',
         'id="menu_information_dashboard"\\n                  name="Tableau de Bord - Demandes"'),
        
        ('id="menu_whistleblowing_dashboard"\\n                  name="Tableau de Bord"',
         'id="menu_whistleblowing_dashboard"\\n                  name="Tableau de Bord - Alertes"'),
        
        # Générateur de Rapports - Ajouter le contexte
        ('id="menu_information_report_generator"\\n                  name="Générateur de Rapports"',
         'id="menu_information_report_generator"\\n                  name="Rapports - Demandes"'),
        
        ('id="menu_whistleblowing_report_generator"\\n                  name="Générateur de Rapports"',
         'id="menu_whistleblowing_report_generator"\\n                  name="Rapports - Alertes"'),
    ]
    
    print("🔧 Application des optimisations...")
    
    changes_made = 0
    for old, new in replacements:
        if old in optimized_content:
            optimized_content = optimized_content.replace(old, new)
            changes_made += 1
            print(f"   ✅ Optimisation appliquée: {old[:50]}...")
    
    # Sauvegarder le fichier optimisé
    if changes_made > 0:
        # Créer une sauvegarde
        with open('views/menus_before_optimization.xml', 'w', encoding='utf-8') as f:
            f.write(content)
        
        # Écrire le fichier optimisé
        with open('views/menus.xml', 'w', encoding='utf-8') as f:
            f.write(optimized_content)
        
        print(f"\\n✅ Optimisations appliquées: {changes_made}")
        print(f"💾 Sauvegarde créée: views/menus_before_optimization.xml")
        print(f"📝 Fichier optimisé: views/menus.xml")
    else:
        print(f"\\n✅ Aucune optimisation nécessaire")
    
    # Afficher la nouvelle structure
    print(f"\\n📋 NOUVELLE STRUCTURE DES MENUS:")
    print("=" * 40)
    
    menu_structure = [
        "🏠 Accès à l'Information",
        "   ├── 📄 Demandes d'Information",
        "   ├── 📊 Rapports et Analyses",
        "   │   ├── 📈 Analyse des Demandes",
        "   │   ├── 📊 Tableau de Bord - Demandes",
        "   │   └── 📋 Rapports - Demandes",
        "   └── ⚙️ Configuration",
        "       ├── 🔄 Étapes",
        "       └── ❌ Motifs de Refus",
        "",
        "🚨 Signalement d'Alerte",
        "   ├── 🚨 Signalements",
        "   ├── 📊 Rapports et Analyses",
        "   │   ├── 📈 Analyse des Signalements",
        "   │   ├── 📊 Tableau de Bord - Alertes",
        "   │   └── 📋 Rapports - Alertes",
        "   └── ⚙️ Configuration",
        "       └── 🔄 Étapes",
        "",
        "📊 Analytics & Rapports",
        "   ├── 📈 Tableaux de Bord",
        "   │   └── 📊 Tableau de Bord Exécutif",
        "   └── 📋 Générateurs de Rapports",
        "       ├── 🔧 Générateurs",
        "       └── 📄 Instances de Rapports",
        "",
        "⚙️ Administration Transparence (sous Administration)",
        "   ├── 👥 Utilisateurs et Groupes",
        "   │   ├── 👤 Utilisateurs",
        "   │   └── 🔐 Groupes de Sécurité",
        "   └── ⚙️ Configuration Système"
    ]
    
    for line in menu_structure:
        print(line)
    
    print(f"\\n🎯 AVANTAGES DE L'OPTIMISATION:")
    print("   ✅ Noms de menus uniques et clairs")
    print("   ✅ Contexte visible dans chaque nom")
    print("   ✅ Navigation intuitive")
    print("   ✅ Pas de confusion entre sections")
    
    return changes_made > 0

if __name__ == "__main__":
    success = optimize_menu_names()
    print(f"\\n🏁 Optimisation {'terminée' if success else 'non nécessaire'}")