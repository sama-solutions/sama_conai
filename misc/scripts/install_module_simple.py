#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script simple pour installer le module SAMA CONAI
"""

import xmlrpc.client
import time

# Configuration Odoo
ODOO_URL = 'http://localhost:8077'
ODOO_DB = 'sama_conai_test'
ODOO_USERNAME = 'admin'
ODOO_PASSWORD = 'admin'

def main():
    print("🇸🇳 SAMA CONAI - Installation Module")
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
        
        # Rechercher tous les modules
        print("\n🔍 Recherche du module sama_conai...")
        all_modules = models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'search_read',
            [[]],
            {'fields': ['id', 'name', 'state'], 'limit': 200}
        )
        
        # Trouver sama_conai
        sama_module = None
        for module in all_modules:
            if module['name'] == 'sama_conai':
                sama_module = module
                break
        
        if not sama_module:
            print("❌ Module sama_conai non trouvé")
            return
        
        print(f"📦 Module trouvé: {sama_module['name']} (ID: {sama_module['id']})")
        print(f"📊 État: {sama_module['state']}")
        
        if sama_module['state'] == 'installed':
            print("✅ Module déjà installé !")
        elif sama_module['state'] == 'uninstalled':
            print("🚀 Installation du module...")
            
            # Installer le module
            result = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'ir.module.module', 'button_immediate_install',
                [[sama_module['id']]]
            )
            
            print("✅ Commande d'installation envoyée")
            print("⏳ Attente de l'installation (10 secondes)...")
            time.sleep(10)
            
            # Vérifier l'état après installation
            updated_module = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'ir.module.module', 'read',
                [[sama_module['id']]],
                {'fields': ['name', 'state']}
            )
            
            new_state = updated_module[0]['state']
            print(f"📊 Nouvel état: {new_state}")
            
            if new_state == 'installed':
                print("🎉 Module installé avec succès !")
            else:
                print(f"⚠️ Module en état: {new_state}")
        
        # Test final des modèles
        print("\n🔍 Test final des modèles...")
        
        try:
            count = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'request.information', 'search_count', [[]]
            )
            print(f"✅ request.information: {count} enregistrement(s)")
        except Exception as e:
            print(f"❌ request.information: {str(e)}")
        
        try:
            count = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'whistleblowing.alert', 'search_count', [[]]
            )
            print(f"✅ whistleblowing.alert: {count} enregistrement(s)")
        except Exception as e:
            print(f"❌ whistleblowing.alert: {str(e)}")
            
    except Exception as e:
        print(f"❌ Erreur: {e}")

if __name__ == '__main__':
    main()