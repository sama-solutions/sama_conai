#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script simplifié pour nettoyer les doublons de menus SAMA CONAI
"""

import psycopg2

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

def clean_duplicate_menus():
    """Nettoie les doublons de menus SAMA CONAI"""
    
    print("🧹 NETTOYAGE DES DOUBLONS MENUS SAMA CONAI")
    print("=" * 50)
    
    conn = connect_db()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # Récupérer tous les menus SAMA CONAI (ID >= 140)
        cursor.execute("""
            SELECT id, name, parent_id, action, sequence 
            FROM ir_ui_menu 
            WHERE id >= 140 
            ORDER BY id
        """)
        
        all_menus = cursor.fetchall()
        print(f"📊 {len(all_menus)} menus SAMA CONAI trouvés")
        
        # Menus à conserver (structure correcte)
        menus_to_keep = [
            141,  # Accès à l'Information (principal)
            143,  # Rapports et Analyses (sous Information)
            144,  # Analyse des Demandes
            145,  # Configuration (sous Information)
            146,  # Étapes (sous Information)
            147,  # Motifs de Refus (sous Information)
            148,  # Signalement d'Alerte (principal)
            150,  # Rapports et Analyses (sous Alerte)
            156,  # Configuration (sous Alerte)
            157,  # Étapes (sous Alerte)
            158,  # Administration Transparence
            159,  # Utilisateurs et Groupes
            160,  # Configuration Système
            210,  # Demandes d'Information
            211,  # Signalements
            212,  # Analyse des Signalements
            213,  # Tableau de Bord (sous Information)
            214,  # Générateur de Rapports (sous Information)
            215,  # Tableau de Bord (sous Alerte)
            216,  # Générateur de Rapports (sous Alerte)
            217,  # Analytics & Rapports (principal)
            218,  # Tableaux de Bord (sous Analytics)
            219,  # Tableau de Bord Exécutif
            220,  # Générateurs de Rapports (sous Analytics)
            221,  # Générateurs
            222,  # Instances de Rapports
            223,  # Utilisateurs
            224   # Groupes de Sécurité
        ]
        
        # Identifier les menus à supprimer
        menus_to_delete = []
        for menu in all_menus:
            menu_id = menu[0]
            if menu_id not in menus_to_keep:
                menus_to_delete.append(menu_id)
        
        print(f"\\n📋 Analyse:")
        print(f"   ✅ Menus à conserver: {len(menus_to_keep)}")
        print(f"   🗑️ Menus à supprimer: {len(menus_to_delete)}")
        
        if menus_to_delete:
            print(f"\\n🗑️ Menus qui seront supprimés:")
            for menu_id in menus_to_delete:
                print(f"   ❌ ID: {menu_id}")
            
            print(f"\n⚠️ ATTENTION: Cette opération va supprimer {len(menus_to_delete)} menus dupliqués.")
            print("🚀 Procédure automatique activée...")
            
            # Procéder automatiquement
            if True:
                # Supprimer les menus dupliqués
                deleted_count = 0
                for menu_id in menus_to_delete:
                    try:
                        cursor.execute("DELETE FROM ir_ui_menu WHERE id = %s", (menu_id,))
                        deleted_count += 1
                        print(f"   🗑️ Supprimé: ID {menu_id}")
                    except Exception as e:
                        print(f"   ❌ Erreur suppression ID {menu_id}: {e}")
                
                # Valider les changements
                conn.commit()
                
                print(f"\\n✅ Nettoyage terminé!")
                print(f"   🗑️ {deleted_count} menus supprimés")
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
        conn.rollback()
        return False
    finally:
        cursor.close()
        conn.close()

def verify_final_structure():
    """Vérifie la structure finale des menus"""
    
    print("\\n🔍 VÉRIFICATION DE LA STRUCTURE FINALE")
    print("=" * 45)
    
    conn = connect_db()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # Compter les menus restants
        cursor.execute("SELECT COUNT(*) FROM ir_ui_menu WHERE id >= 140")
        total_menus = cursor.fetchone()[0]
        
        # Compter les menus principaux
        cursor.execute("SELECT COUNT(*) FROM ir_ui_menu WHERE id >= 140 AND parent_id IS NULL")
        main_menus = cursor.fetchone()[0]
        
        # Compter les sous-menus
        cursor.execute("SELECT COUNT(*) FROM ir_ui_menu WHERE id >= 140 AND parent_id IS NOT NULL")
        sub_menus = cursor.fetchone()[0]
        
        print(f"📊 Structure finale:")
        print(f"   🏠 Menus principaux: {main_menus}")
        print(f"   📂 Sous-menus: {sub_menus}")
        print(f"   📋 Total: {total_menus}")
        
        # Vérifier les menus principaux
        cursor.execute("""
            SELECT id, name 
            FROM ir_ui_menu 
            WHERE id >= 140 AND parent_id IS NULL 
            ORDER BY sequence
        """)
        
        main_menu_list = cursor.fetchall()
        print(f"\\n🏠 Menus principaux détectés:")
        for menu in main_menu_list:
            menu_id, name = menu
            print(f"   📋 ID {menu_id}: {name}")
        
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
    print("Suppression des menus dupliqués du module SAMA CONAI uniquement")
    print("=" * 65)
    
    # Nettoyer les doublons
    if clean_duplicate_menus():
        # Vérifier la structure finale
        verify_final_structure()
        
        print("\\n🎉 NETTOYAGE TERMINÉ AVEC SUCCÈS!")
        print("\\n🔄 PROCHAINES ÉTAPES:")
        print("   1. Redémarrez Odoo pour appliquer les changements")
        print("   2. Vérifiez les menus dans l'interface web")
        print("   3. Testez la navigation dans les menus")
        
        print("\\n🚀 Commandes utiles:")
        print("   # Redémarrer Odoo")
        print("   ./start_sama_conai_background.sh")
        print("   ")
        print("   # Vérifier le statut")
        print("   python3 verify_sama_conai_running.py")
        
        return True
    else:
        print("\\n❌ Échec du nettoyage")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)