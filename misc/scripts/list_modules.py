#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour lister les modules disponibles dans Odoo
"""

import xmlrpc.client

# Configuration Odoo
ODOO_URL = 'http://localhost:8077'
ODOO_DB = 'sama_conai_test'
ODOO_USERNAME = 'admin'
ODOO_PASSWORD = 'admin'

def main():
    print("🔍 Liste des modules Odoo")
    print("=" * 40)
    
    try:
        # Connexion
        common = xmlrpc.client.ServerProxy(f'{ODOO_URL}/xmlrpc/2/common')
        uid = common.authenticate(ODOO_DB, ODOO_USERNAME, ODOO_PASSWORD, {})
        
        if not uid:
            print("❌ Erreur d'authentification")
            return
        
        print(f"✅ Connexion réussie - UID: {uid}")
        
        models = xmlrpc.client.ServerProxy(f'{ODOO_URL}/xmlrpc/2/object')
        
        # Lister tous les modules
        modules = models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'search_read',
            [],
            {'fields': ['name', 'state', 'summary'], 'limit': 20}
        )
        
        print(f"\n📦 {len(modules)} premiers modules trouvés:")
        for module in modules:
            print(f"  - {module['name']} ({module['state']})")
        
        # Rechercher spécifiquement sama
        print("\n🔍 Recherche modules contenant 'sama':")
        sama_modules = models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'search_read',
            [['name', 'ilike', 'sama']],
            {'fields': ['name', 'state', 'summary']}
        )
        
        if sama_modules:
            for module in sama_modules:
                print(f"  ✅ {module['name']} ({module['state']})")
        else:
            print("  ❌ Aucun module contenant 'sama' trouvé")
        
        # Rechercher spécifiquement conai
        print("\n🔍 Recherche modules contenant 'conai':")
        conai_modules = models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'search_read',
            [['name', 'ilike', 'conai']],
            {'fields': ['name', 'state', 'summary']}
        )
        
        if conai_modules:
            for module in conai_modules:
                print(f"  ✅ {module['name']} ({module['state']})")
        else:
            print("  ❌ Aucun module contenant 'conai' trouvé")
            
    except Exception as e:
        print(f"❌ Erreur: {e}")

if __name__ == '__main__':
    main()