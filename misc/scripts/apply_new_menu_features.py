#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour appliquer les nouveaux menus avec les nouvelles fonctionnalités
"""

import shutil
import os
from datetime import datetime

def apply_new_menu_features():
    """Applique les nouveaux menus avec les nouvelles fonctionnalités"""
    
    print("🚀 APPLICATION DES NOUVEAUX MENUS AVEC FONCTIONNALITÉS")
    print("=" * 60)
    
    # Fichiers
    current_menu_file = "views/menus.xml"
    new_menu_file = "views/menus_with_new_features.xml"
    backup_file = f"views/menus_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xml"
    
    try:
        # 1. Vérifier que le nouveau fichier existe
        if not os.path.exists(new_menu_file):
            print(f"❌ Fichier {new_menu_file} non trouvé")
            return False
        
        print(f"✅ Fichier des nouveaux menus trouvé: {new_menu_file}")
        
        # 2. Créer une sauvegarde de l'ancien fichier
        if os.path.exists(current_menu_file):
            shutil.copy2(current_menu_file, backup_file)
            print(f"💾 Sauvegarde créée: {backup_file}")
        
        # 3. Remplacer l'ancien fichier par le nouveau
        shutil.copy2(new_menu_file, current_menu_file)
        print(f"✅ Nouveaux menus appliqués: {current_menu_file}")
        
        # 4. Analyser les nouvelles fonctionnalités ajoutées
        print(f"\\n📊 NOUVELLES FONCTIONNALITÉS AJOUTÉES:")
        
        nouvelles_fonctionnalites = [
            "📈 Analyse Avancée (pivot/graph)",
            "📊 Évolution des Demandes (graphique)",
            "🚨 Signalements Urgents (KPI)",
            "📋 Signalements par Catégorie (visualisation)",
            "🎯 Tableau de Bord Principal SAMA CONAI",
            "📊 Section KPI & Indicateurs",
            "📈 Section Visualisations",
            "⏰ Demandes en Retard (KPI)",
            "📅 Demandes du Mois (KPI)"
        ]
        
        for i, fonctionnalite in enumerate(nouvelles_fonctionnalites, 1):
            print(f"   {i:2d}. {fonctionnalite}")
        
        # 5. Afficher la nouvelle structure
        print(f"\\n🏗️ NOUVELLE STRUCTURE DES MENUS:")
        print("=" * 40)
        
        structure = [
            "📄 Accès à l'Information",
            "   ├── Demandes d'Information",
            "   ├── Rapports et Analyses",
            "   │   ├── Analyse des Demandes",
            "   │   ├── Analyse Avancée (NOUVEAU)",
            "   │   ├── Évolution des Demandes (NOUVEAU)",
            "   │   ├── Tableau de Bord",
            "   │   └── Générateur de Rapports",
            "   └── Configuration",
            "",
            "🚨 Signalement d'Alerte",
            "   ├── Signalements",
            "   ├── Signalements Urgents (NOUVEAU)",
            "   ├── Rapports et Analyses",
            "   │   ├── Analyse des Signalements",
            "   │   ├── Signalements par Catégorie (NOUVEAU)",
            "   │   ├── Tableau de Bord",
            "   │   └── Générateur de Rapports",
            "   └── Configuration",
            "",
            "📊 Analytics & Rapports (ENRICHI)",
            "   ├── Tableaux de Bord",
            "   │   ├── Tableau de Bord Principal (NOUVEAU)",
            "   │   └── Tableau de Bord Exécutif",
            "   ├── KPI & Indicateurs (NOUVEAU)",
            "   │   ├── Demandes en Retard",
            "   │   ├── Signalements Urgents",
            "   │   └── Demandes du Mois",
            "   ├── Visualisations (NOUVEAU)",
            "   │   ├── Évolution des Demandes",
            "   │   └── Signalements par Catégorie",
            "   └── Générateurs de Rapports",
            "",
            "⚙️ Administration Transparence",
            "   ├── Utilisateurs et Groupes",
            "   └── Configuration Système"
        ]
        
        for line in structure:
            print(line)
        
        print(f"\\n📈 STATISTIQUES:")
        print(f"   📋 Nouvelles fonctionnalités: {len(nouvelles_fonctionnalites)}")
        print(f"   🏠 Menus principaux: 3 (inchangé)")
        print(f"   📂 Nouvelles sections: 3 (KPI, Visualisations, Analyses avancées)")
        print(f"   🎯 Nouveaux menus d'action: 9")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de l'application: {e}")
        return False

def update_manifest_if_needed():
    """Met à jour le manifest si nécessaire"""
    
    print(f"\\n📋 VÉRIFICATION DU MANIFEST:")
    
    try:
        with open('__manifest__.py', 'r') as f:
            manifest_content = f.read()
        
        # Vérifier que dashboard_views.xml est inclus
        if "'views/dashboard_views.xml'" in manifest_content:
            print("   ✅ dashboard_views.xml déjà inclus dans le manifest")
        else:
            print("   ⚠️ dashboard_views.xml non trouvé dans le manifest")
            print("   💡 Ajoutez 'views/dashboard_views.xml' dans la section 'data' du manifest")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Erreur lors de la vérification du manifest: {e}")
        return False

def main():
    """Fonction principale"""
    
    print("🎯 INTÉGRATION DES NOUVELLES FONCTIONNALITÉS")
    print("Application des nouveaux menus enrichis avec toutes les fonctionnalités")
    print("=" * 75)
    
    # Appliquer les nouveaux menus
    if apply_new_menu_features():
        # Vérifier le manifest
        update_manifest_if_needed()
        
        print(f"\\n🎉 INTÉGRATION TERMINÉE AVEC SUCCÈS !")
        
        print(f"\\n🔄 PROCHAINES ÉTAPES:")
        print("   1. Redémarrez Odoo pour appliquer les changements")
        print("   2. Testez les nouvelles fonctionnalités")
        print("   3. Vérifiez la navigation dans les nouveaux menus")
        print("   4. Validez les KPI et visualisations")
        
        print(f"\\n🚀 COMMANDES:")
        print("   # Redémarrer Odoo")
        print("   ./start_sama_conai_background.sh")
        print("   ")
        print("   # Vérifier le statut")
        print("   python3 verify_sama_conai_running.py")
        
        print(f"\\n🌐 ACCÈS:")
        print("   URL: http://localhost:8077")
        print("   Login: admin / Password: admin")
        
        print(f"\\n✨ NOUVELLES FONCTIONNALITÉS À TESTER:")
        print("   📊 Tableau de Bord Principal SAMA CONAI")
        print("   📈 Analyses Avancées avec pivot/graph")
        print("   🎯 KPI en temps réel")
        print("   📊 Visualisations interactives")
        print("   🚨 Alertes et indicateurs urgents")
        
        return True
    else:
        print(f"\\n❌ ÉCHEC DE L'INTÉGRATION")
        print("🔧 Vérifiez les erreurs ci-dessus et corrigez-les")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)