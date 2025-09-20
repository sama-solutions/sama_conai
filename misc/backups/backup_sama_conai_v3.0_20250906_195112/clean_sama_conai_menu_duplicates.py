#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour nettoyer les doublons de menus SAMA CONAI dans la base de données
"""

import psycopg2
import json

def connect_db():
    """Connexion à la base de données"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="sama_conai_analytics",
            user="odoo",
            password="odoo"
        )
        return conn
    except Exception as e:
        print(f"❌ Erreur de connexion à la base: {e}")
        return None

def get_sama_conai_menus(conn):
    """Récupère tous les menus SAMA CONAI"""
    cursor = conn.cursor()
    
    query = """
    SELECT m.id, m.name, m.parent_id, p.name as parent_name, m.action, m.sequence, m.web_icon
    FROM ir_ui_menu m 
    LEFT JOIN ir_ui_menu p ON m.parent_id = p.id 
    WHERE m.id >= 140 
    ORDER BY m.id;
    """
    
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    
    return results

def identify_valid_menus():
    """Identifie les menus valides selon notre structure"""
    
    # Structure correcte des menus SAMA CONAI
    valid_structure = {
        # Menus principaux (sans parent)
        "main_menus": [
            {"name": "Accès à l'Information", "sequence": 10, "web_icon": "sama_conai,static/description/icon_information.png"},
            {"name": "Signalement d'Alerte", "sequence": 20, "web_icon": "sama_conai,static/description/icon_whistleblowing.png"},
            {"name": "Analytics & Rapports", "sequence": 30, "web_icon": "sama_conai,static/description/icon_analytics.png"}
        ],
        
        # Sous-menus pour Accès à l'Information
        "information_submenus": [
            {"name": "Demandes d'Information", "sequence": 10, "action": "ir.actions.act_window,207"},
            {"name": "Rapports et Analyses", "sequence": 20, "parent": "Accès à l'Information"},
            {"name": "Configuration", "sequence": 90, "parent": "Accès à l'Information"}
        ],
        
        # Sous-menus pour Signalement d'Alerte
        "alert_submenus": [
            {"name": "Signalements", "sequence": 10, "action": "ir.actions.act_window,210"},
            {"name": "Rapports et Analyses", "sequence": 20, "parent": "Signalement d'Alerte"},
            {"name": "Configuration", "sequence": 90, "parent": "Signalement d'Alerte"}
        ],
        
        # Sous-menus pour Analytics & Rapports
        "analytics_submenus": [
            {"name": "Tableaux de Bord", "sequence": 10, "parent": "Analytics & Rapports"},
            {"name": "Générateurs de Rapports", "sequence": 20, "parent": "Analytics & Rapports"}
        ]
    }
    
    return valid_structure

def clean_menu_duplicates():
    """Nettoie les doublons de menus SAMA CONAI"""
    
    print("🧹 NETTOYAGE DES DOUBLONS MENUS SAMA CONAI")
    print("=" * 50)
    
    # Connexion à la base
    conn = connect_db()
    if not conn:
        return False
    
    try:
        # Récupérer tous les menus SAMA CONAI
        menus = get_sama_conai_menus(conn)
        print(f"📊 {len(menus)} menus SAMA CONAI trouvés")
        
        # Identifier les menus valides à conserver
        valid_structure = identify_valid_menus()
        
        # Menus à conserver (IDs des menus corrects)
        menus_to_keep = [
            141,  # Accès à l'Information (principal)
            148,  # Signalement d'Alerte (principal)  
            217,  # Analytics & Rapports (principal)
            210,  # Demandes d'Information
            143,  # Rapports et Analyses (sous Information)
            145,  # Configuration (sous Information)
            211,  # Signalements
            150,  # Rapports et Analyses (sous Alerte)
            156,  # Configuration (sous Alerte)
            218,  # Tableaux de Bord (sous Analytics)
            220,  # Générateurs de Rapports (sous Analytics)
            144,  # Analyse des Demandes
            146,  # Étapes (sous Information)
            147,  # Motifs de Refus (sous Information)
            212,  # Analyse des Signalements
            157,  # Étapes (sous Alerte)
            213,  # Tableau de Bord (sous Information)
            214,  # Générateur de Rapports (sous Information)
            215,  # Tableau de Bord (sous Alerte)
            216,  # Générateur de Rapports (sous Alerte)
            219,  # Tableau de Bord Exécutif
            221,  # Générateurs
            222,  # Instances de Rapports
            158,  # Administration Transparence
            159,  # Utilisateurs et Groupes
            160,  # Configuration Système
            223,  # Utilisateurs
            224   # Groupes de Sécurité
        ]
        
        # Identifier les menus à supprimer
        menus_to_delete = []
        for menu in menus:
            menu_id = menu[0]
            menu_name_raw = menu[1]
            
            # Gérer le cas où menu_name est déjà un dict ou une string JSON
            if isinstance(menu_name_raw, dict):
                menu_name = menu_name_raw.get('en_US', '')
            elif isinstance(menu_name_raw, str):
                try:
                    menu_name = json.loads(menu_name_raw).get('en_US', '')
                except:
                    menu_name = menu_name_raw
            else:
                menu_name = str(menu_name_raw) if menu_name_raw else ''
            
            if menu_id not in menus_to_keep:
                menus_to_delete.append((menu_id, menu_name))
        
        print(f"\\n🗑️ Menus à supprimer: {len(menus_to_delete)}")
        for menu_id, menu_name in menus_to_delete:
            print(f"   ❌ ID {menu_id}: {menu_name}")
        
        print(f"\\n✅ Menus à conserver: {len(menus_to_keep)}")
        
        # Demander confirmation
        if menus_to_delete:
            print(f"\\n⚠️ ATTENTION: Cette opération va supprimer {len(menus_to_delete)} menus dupliqués.")
            response = input("Voulez-vous continuer ? (y/N): ")
            
            if response.lower() in ['y', 'yes', 'oui']:
                # Supprimer les menus dupliqués
                cursor = conn.cursor()
                
                for menu_id, menu_name in menus_to_delete:
                    try:
                        cursor.execute("DELETE FROM ir_ui_menu WHERE id = %s", (menu_id,))
                        print(f"   🗑️ Supprimé: ID {menu_id} - {menu_name}")
                    except Exception as e:
                        print(f"   ❌ Erreur suppression ID {menu_id}: {e}")
                
                # Valider les changements
                conn.commit()
                cursor.close()
                
                print(f"\\n✅ Nettoyage terminé!")
                print(f"   🗑️ {len(menus_to_delete)} menus supprimés")
                print(f"   ✅ {len(menus_to_keep)} menus conservés")
                
                return True
            else:
                print("\\n🚫 Nettoyage annulé")
                return False
        else:
            print("\\n✅ Aucun doublon à supprimer")
            return True
            
    except Exception as e:
        print(f"❌ Erreur lors du nettoyage: {e}")
        return False
    finally:
        conn.close()

def verify_menu_structure():
    """Vérifie la structure des menus après nettoyage"""
    
    print("\\n🔍 VÉRIFICATION DE LA STRUCTURE FINALE")
    print("=" * 45)
    
    conn = connect_db()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # Récupérer les menus principaux
        cursor.execute("""
            SELECT id, name, sequence, web_icon 
            FROM ir_ui_menu 
            WHERE parent_id IS NULL AND id >= 140
            ORDER BY sequence
        """)
        
        main_menus = cursor.fetchall()
        
        print("🏠 Menus principaux:")
        for menu in main_menus:
            menu_id, name, sequence, web_icon = menu
            menu_name = json.loads(name).get('en_US', '') if name else ''
            print(f"   📋 {menu_name} (ID: {menu_id}, Seq: {sequence})")
        
        # Récupérer tous les sous-menus
        cursor.execute("""
            SELECT m.id, m.name, m.parent_id, p.name as parent_name, m.sequence
            FROM ir_ui_menu m 
            LEFT JOIN ir_ui_menu p ON m.parent_id = p.id 
            WHERE m.parent_id IS NOT NULL AND m.id >= 140
            ORDER BY m.parent_id, m.sequence
        """)
        
        submenus = cursor.fetchall()
        
        print(f"\\n📂 Sous-menus ({len(submenus)}):")
        current_parent = None
        for menu in submenus:
            menu_id, name, parent_id, parent_name, sequence = menu
            menu_name = json.loads(name).get('en_US', '') if name else ''
            parent_menu_name = json.loads(parent_name).get('en_US', '') if parent_name else ''
            
            if parent_id != current_parent:
                current_parent = parent_id
                print(f"\\n   📁 {parent_menu_name}:")
            
            print(f"      └── {menu_name} (ID: {menu_id})")
        
        cursor.close()
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de la vérification: {e}")
        return False
    finally:
        conn.close()

def main():
    """Fonction principale"""
    
    print("🎯 NETTOYAGE DES MENUS SAMA CONAI")
    print("Cet outil va supprimer les menus dupliqués du module SAMA CONAI")
    print("=" * 60)
    
    # Nettoyer les doublons
    if clean_menu_duplicates():
        # Vérifier la structure finale
        verify_menu_structure()
        
        print("\\n🎉 NETTOYAGE TERMINÉ AVEC SUCCÈS!")
        print("\\n🔄 PROCHAINES ÉTAPES:")
        print("   1. Redémarrez Odoo pour appliquer les changements")
        print("   2. Vérifiez les menus dans l'interface")
        print("   3. Testez la navigation")
        
        print("\\n🚀 Commande de redémarrage:")
        print("   ./start_sama_conai_background.sh")
        
        return True
    else:
        print("\\n❌ Échec du nettoyage")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)