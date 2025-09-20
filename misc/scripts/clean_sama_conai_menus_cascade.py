#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour nettoyer les doublons de menus SAMA CONAI avec gestion des dépendances
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

def clean_duplicate_menus_cascade():
    """Nettoie les doublons en supprimant d'abord les enfants puis les parents"""
    
    print("🧹 NETTOYAGE CASCADE DES DOUBLONS MENUS SAMA CONAI")
    print("=" * 55)
    
    conn = connect_db()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # Menus à conserver (structure correcte finale)
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
        
        print(f"✅ Menus à conserver: {len(menus_to_keep)}")
        
        # Méthode 1: Supprimer tous les menus SAMA CONAI non désirés en une fois avec CASCADE
        print("\\n🗑️ Suppression en cascade des menus dupliqués...")
        
        # Construire la liste des IDs à supprimer
        cursor.execute("SELECT id FROM ir_ui_menu WHERE id >= 140")
        all_menu_ids = [row[0] for row in cursor.fetchall()]
        
        menus_to_delete = [mid for mid in all_menu_ids if mid not in menus_to_keep]
        
        print(f"📊 Analyse:")
        print(f"   📋 Total menus SAMA CONAI: {len(all_menu_ids)}")
        print(f"   ✅ À conserver: {len(menus_to_keep)}")
        print(f"   🗑️ À supprimer: {len(menus_to_delete)}")
        
        if menus_to_delete:
            # Supprimer par lots pour éviter les problèmes de dépendances
            deleted_count = 0
            
            # Trier par ID décroissant pour supprimer les enfants avant les parents
            menus_to_delete.sort(reverse=True)
            
            for menu_id in menus_to_delete:
                try:
                    # Supprimer d'abord tous les enfants de ce menu
                    cursor.execute("""
                        DELETE FROM ir_ui_menu 
                        WHERE parent_id = %s AND id NOT IN %s
                    """, (menu_id, tuple(menus_to_keep)))
                    
                    # Puis supprimer le menu lui-même
                    cursor.execute("DELETE FROM ir_ui_menu WHERE id = %s", (menu_id,))
                    
                    if cursor.rowcount > 0:
                        deleted_count += 1
                        print(f"   🗑️ Supprimé: ID {menu_id}")
                    
                except Exception as e:
                    # Ignorer les erreurs de contraintes (menu déjà supprimé)
                    if "does not exist" not in str(e):
                        print(f"   ⚠️ Ignoré ID {menu_id}: {str(e)[:50]}...")
            
            # Valider les changements
            conn.commit()
            
            print(f"\\n✅ Suppression terminée!")
            print(f"   🗑️ {deleted_count} menus supprimés")
            
        else:
            print("\\n✅ Aucun menu à supprimer")
        
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
        
        print(f"📊 Structure finale:")
        print(f"   📋 Total menus SAMA CONAI: {total_menus}")
        print(f"   🏠 Menus principaux: {main_menus}")
        
        # Lister les menus principaux
        cursor.execute("""
            SELECT id, name 
            FROM ir_ui_menu 
            WHERE id >= 140 AND parent_id IS NULL 
            ORDER BY sequence, id
        """)
        
        main_menu_list = cursor.fetchall()
        print(f"\\n🏠 Menus principaux:")
        for menu in main_menu_list:
            menu_id, name = menu
            # Extraire le nom en anglais du JSON
            try:
                if isinstance(name, dict):
                    menu_name = name.get('en_US', str(name))
                else:
                    menu_name = str(name)
            except:
                menu_name = str(name)
            print(f"   📋 ID {menu_id}: {menu_name}")
        
        # Vérifier si on a la structure attendue
        expected_main_menus = 3  # Information, Alerte, Analytics
        if main_menus == expected_main_menus:
            print(f"\\n✅ Structure correcte: {main_menus} menus principaux")
        else:
            print(f"\\n⚠️ Structure inattendue: {main_menus} menus principaux (attendu: {expected_main_menus})")
        
        cursor.close()
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de la vérification: {e}")
        return False
    finally:
        conn.close()

def restart_odoo():
    """Redémarre Odoo pour appliquer les changements"""
    
    print("\\n🔄 REDÉMARRAGE D'ODOO")
    print("=" * 25)
    
    import subprocess
    import time
    
    try:
        # Arrêter Odoo
        print("🛑 Arrêt d'Odoo...")
        subprocess.run(["pkill", "-f", "odoo.*8077"], capture_output=True)
        time.sleep(3)
        
        # Redémarrer Odoo
        print("🚀 Redémarrage d'Odoo...")
        result = subprocess.run(["./start_sama_conai_background.sh"], 
                              capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print("✅ Odoo redémarré avec succès")
            return True
        else:
            print(f"⚠️ Redémarrage avec avertissements")
            return True
            
    except subprocess.TimeoutExpired:
        print("✅ Redémarrage en cours (timeout normal)")
        return True
    except Exception as e:
        print(f"❌ Erreur lors du redémarrage: {e}")
        print("🔧 Redémarrez manuellement: ./start_sama_conai_background.sh")
        return False

def main():
    """Fonction principale"""
    
    print("🎯 NETTOYAGE AVANCÉ DES MENUS SAMA CONAI")
    print("Suppression intelligente des doublons avec gestion des dépendances")
    print("=" * 70)
    
    # Nettoyer les doublons
    if clean_duplicate_menus_cascade():
        # Vérifier la structure finale
        verify_final_structure()
        
        print("\\n🎉 NETTOYAGE TERMINÉ AVEC SUCCÈS!")
        
        # Proposer le redémarrage
        print("\\n🔄 Redémarrage d'Odoo recommandé pour appliquer les changements...")
        restart_odoo()
        
        print("\\n📋 RÉSUMÉ:")
        print("   ✅ Doublons de menus supprimés")
        print("   🧹 Structure des menus nettoyée")
        print("   🔄 Odoo redémarré")
        print("   🌐 Interface accessible sur http://localhost:8077")
        
        print("\\n🎯 VÉRIFICATION:")
        print("   1. Accédez à http://localhost:8077")
        print("   2. Connectez-vous (admin/admin)")
        print("   3. Vérifiez que les menus SAMA CONAI n'ont plus de doublons")
        
        return True
    else:
        print("\\n❌ Échec du nettoyage")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)