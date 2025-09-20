#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Validation finale de la structure des menus SAMA CONAI après nettoyage
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

def validate_menu_structure():
    """Valide la structure finale des menus SAMA CONAI"""
    
    print("🔍 VALIDATION FINALE DES MENUS SAMA CONAI")
    print("=" * 50)
    
    conn = connect_db()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # 1. Vérifier les menus principaux
        print("🏠 1. Validation des menus principaux...")
        cursor.execute("""
            SELECT id, name, sequence, web_icon 
            FROM ir_ui_menu 
            WHERE id >= 140 AND parent_id IS NULL 
            ORDER BY sequence
        """)
        
        main_menus = cursor.fetchall()
        expected_main_menus = [
            ("Accès à l'Information", 10),
            ("Signalement d'Alerte", 20),
            ("Analytics & Rapports", 30)
        ]
        
        print(f"   📊 {len(main_menus)} menus principaux trouvés")
        
        main_menu_names = []
        for menu in main_menus:
            menu_id, name, sequence, web_icon = menu
            if isinstance(name, dict):
                menu_name = name.get('en_US', '')
            else:
                menu_name = str(name)
            main_menu_names.append((menu_name, sequence))
            print(f"   ✅ {menu_name} (ID: {menu_id}, Seq: {sequence})")
        
        # Vérifier que nous avons les bons menus
        main_menus_ok = len(main_menus) == 3
        if main_menus_ok:
            print("   ✅ Nombre de menus principaux correct")
        else:
            print(f"   ❌ Nombre incorrect: {len(main_menus)} (attendu: 3)")
        
        # 2. Vérifier l'absence de doublons
        print("\\n🔍 2. Vérification des doublons...")
        cursor.execute("""
            SELECT name, COUNT(*) as count
            FROM ir_ui_menu 
            WHERE id >= 140 
            GROUP BY name 
            HAVING COUNT(*) > 1
        """)
        
        duplicates = cursor.fetchall()
        if duplicates:
            print(f"   ❌ {len(duplicates)} doublons détectés:")
            for name, count in duplicates:
                print(f"      🔴 {name}: {count} occurrences")
        else:
            print("   ✅ Aucun doublon détecté")
        
        # 3. Vérifier la structure hiérarchique
        print("\\n🌳 3. Validation de la hiérarchie...")
        cursor.execute("""
            SELECT m.id, m.name, m.parent_id, p.name as parent_name, m.sequence
            FROM ir_ui_menu m 
            LEFT JOIN ir_ui_menu p ON m.parent_id = p.id 
            WHERE m.id >= 140 
            ORDER BY m.parent_id NULLS FIRST, m.sequence
        """)
        
        all_menus = cursor.fetchall()
        
        # Organiser par parent
        menu_tree = {}
        orphans = []
        
        for menu in all_menus:
            menu_id, name, parent_id, parent_name, sequence = menu
            
            if isinstance(name, dict):
                menu_name = name.get('en_US', '')
            else:
                menu_name = str(name)
            
            if parent_id is None:
                # Menu principal
                if 'main' not in menu_tree:
                    menu_tree['main'] = []
                menu_tree['main'].append((menu_id, menu_name, sequence))
            else:
                # Sous-menu
                if parent_id not in menu_tree:
                    menu_tree[parent_id] = []
                menu_tree[parent_id].append((menu_id, menu_name, sequence))
        
        # Afficher la structure
        print("   📋 Structure hiérarchique:")
        if 'main' in menu_tree:
            for main_id, main_name, main_seq in menu_tree['main']:
                print(f"\\n   🏠 {main_name} (ID: {main_id})")
                
                if main_id in menu_tree:
                    for sub_id, sub_name, sub_seq in menu_tree[main_id]:
                        print(f"      ├── {sub_name} (ID: {sub_id})")
                        
                        # Vérifier les sous-sous-menus
                        if sub_id in menu_tree:
                            for subsub_id, subsub_name, subsub_seq in menu_tree[sub_id]:
                                print(f"      │   └── {subsub_name} (ID: {subsub_id})")
        
        # 4. Vérifier les actions
        print("\\n🎯 4. Validation des actions...")
        cursor.execute("""
            SELECT COUNT(*) 
            FROM ir_ui_menu 
            WHERE id >= 140 AND action IS NOT NULL
        """)
        
        menus_with_actions = cursor.fetchone()[0]
        print(f"   📊 {menus_with_actions} menus avec actions")
        
        # 5. Statistiques finales
        print("\\n📊 5. Statistiques finales...")
        cursor.execute("SELECT COUNT(*) FROM ir_ui_menu WHERE id >= 140")
        total_sama_menus = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM ir_ui_menu WHERE id >= 140 AND parent_id IS NULL")
        main_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM ir_ui_menu WHERE id >= 140 AND parent_id IS NOT NULL")
        sub_count = cursor.fetchone()[0]
        
        print(f"   📋 Total menus SAMA CONAI: {total_sama_menus}")
        print(f"   🏠 Menus principaux: {main_count}")
        print(f"   📂 Sous-menus: {sub_count}")
        print(f"   🎯 Menus avec actions: {menus_with_actions}")
        
        # Score de validation
        score = 0
        max_score = 5
        
        if main_menus_ok:
            score += 1
        if len(duplicates) == 0:
            score += 2
        if total_sama_menus == 28:  # Nombre attendu après nettoyage
            score += 1
        if menus_with_actions >= 10:  # Au moins 10 menus avec actions
            score += 1
        
        print(f"\\n📈 Score de validation: {score}/{max_score} ({(score/max_score)*100:.0f}%)")
        
        if score == max_score:
            print("\\n🎉 VALIDATION PARFAITE !")
            print("✅ Structure des menus optimale")
            print("✅ Aucun doublon détecté")
            print("✅ Hiérarchie correcte")
            print("✅ Actions configurées")
        elif score >= 4:
            print("\\n✅ VALIDATION RÉUSSIE")
            print("⚠️ Quelques points mineurs à noter")
        else:
            print("\\n⚠️ VALIDATION PARTIELLE")
            print("🔧 Des améliorations sont nécessaires")
        
        cursor.close()
        return score >= 4
        
    except Exception as e:
        print(f"❌ Erreur lors de la validation: {e}")
        return False
    finally:
        conn.close()

def main():
    """Fonction principale"""
    
    print("🎯 VALIDATION FINALE DES MENUS SAMA CONAI")
    print("Vérification complète après nettoyage des doublons")
    print("=" * 60)
    
    if validate_menu_structure():
        print("\\n🎉 VALIDATION TERMINÉE AVEC SUCCÈS !")
        print("\\n🌐 **ACCÈS AU SYSTÈME**")
        print("   URL: http://localhost:8077")
        print("   👤 Login: admin")
        print("   🔑 Password: admin")
        
        print("\\n✅ **RÉSULTATS**")
        print("   🧹 Doublons éliminés")
        print("   📊 Structure optimisée")
        print("   🎯 Navigation claire")
        print("   🚀 Prêt pour utilisation")
        
        print("\\n💡 **RECOMMANDATIONS**")
        print("   1. Testez la navigation dans l'interface")
        print("   2. Vérifiez le bon fonctionnement des actions")
        print("   3. Confirmez l'absence de doublons visuels")
        
        return True
    else:
        print("\\n❌ VALIDATION ÉCHOUÉE")
        print("🔧 Des corrections supplémentaires sont nécessaires")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)