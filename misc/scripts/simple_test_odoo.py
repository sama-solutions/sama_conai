#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script simple pour tester les modèles SAMA CONAI
"""

import xmlrpc.client

# Configuration Odoo
ODOO_URL = 'http://localhost:8077'
ODOO_DB = 'sama_conai_test'
ODOO_USERNAME = 'admin'
ODOO_PASSWORD = 'admin'

def main():
    print("🇸🇳 SAMA CONAI - Test Simple des Modèles")
    print("=" * 50)
    
    try:
        # Connexion
        common = xmlrpc.client.ServerProxy(f'{ODOO_URL}/xmlrpc/2/common')
        uid = common.authenticate(ODOO_DB, ODOO_USERNAME, ODOO_PASSWORD, {})
        
        if not uid:
            print("❌ Erreur d'authentification")
            return
        
        print(f"✅ Connexion réussie - UID: {uid}")
        
        models = xmlrpc.client.ServerProxy(f'{ODOO_URL}/xmlrpc/2/object')
        
        # Test direct des modèles SAMA CONAI
        print("\n🔍 Test des modèles SAMA CONAI...")
        
        # Test 1: request.information
        try:
            count = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'request.information', 'search_count', 
                [[]]  # Domaine vide
            )
            print(f"✅ request.information: {count} enregistrement(s)")
            
            # Récupérer quelques enregistrements
            if count > 0:
                records = models.execute_kw(
                    ODOO_DB, uid, ODOO_PASSWORD,
                    'request.information', 'search_read',
                    [[]],  # Domaine vide
                    {'fields': ['name', 'requester_name', 'state'], 'limit': 3}
                )
                print(f"  📋 Exemples:")
                for record in records:
                    print(f"    - {record.get('name', 'N/A')} ({record.get('state', 'N/A')})")
        except Exception as e:
            print(f"❌ request.information: {str(e)}")
        
        # Test 2: whistleblowing.alert
        try:
            count = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'whistleblowing.alert', 'search_count', 
                [[]]  # Domaine vide
            )
            print(f"✅ whistleblowing.alert: {count} enregistrement(s)")
            
            # Récupérer quelques enregistrements
            if count > 0:
                records = models.execute_kw(
                    ODOO_DB, uid, ODOO_PASSWORD,
                    'whistleblowing.alert', 'search_read',
                    [[]],  # Domaine vide
                    {'fields': ['name', 'category', 'state'], 'limit': 3}
                )
                print(f"  🚨 Exemples:")
                for record in records:
                    print(f"    - {record.get('name', 'N/A')} ({record.get('state', 'N/A')})")
        except Exception as e:
            print(f"❌ whistleblowing.alert: {str(e)}")
        
        # Test 3: Vérifier les modules installés
        print("\n📦 Modules installés contenant 'sama':")
        try:
            # Recherche simple sans domaine complexe
            all_modules = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'ir.module.module', 'search_read',
                [[]],
                {'fields': ['name', 'state'], 'limit': 100}
            )
            
            sama_modules = [m for m in all_modules if 'sama' in m['name'].lower()]
            
            if sama_modules:
                for module in sama_modules:
                    print(f"  📦 {module['name']}: {module['state']}")
            else:
                print("  ❌ Aucun module 'sama' trouvé")
                
        except Exception as e:
            print(f"❌ Erreur modules: {str(e)}")
            
    except Exception as e:
        print(f"❌ Erreur générale: {e}")

if __name__ == '__main__':
    main()