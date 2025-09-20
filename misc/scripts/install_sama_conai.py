#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour installer le module SAMA CONAI dans Odoo
"""

import xmlrpc.client
import time

# Configuration Odoo
ODOO_URL = 'http://localhost:8077'
ODOO_DB = 'sama_conai_test'
ODOO_USERNAME = 'admin'
ODOO_PASSWORD = 'admin'

def main():
    print("🇸🇳 SAMA CONAI - Installation Module Odoo")
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
        
        # Rechercher le module sama_conai
        print("\n🔍 Recherche du module sama_conai...")
        module_ids = models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'search',
            [['name', '=', 'sama_conai']]
        )
        
        if not module_ids:
            print("❌ Module sama_conai non trouvé")
            return
        
        # Vérifier l'état du module
        module_data = models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'read',
            [module_ids],
            {'fields': ['name', 'state', 'summary']}
        )
        
        module = module_data[0]
        print(f"📦 Module trouvé: {module['name']}")
        print(f"📊 État actuel: {module['state']}")
        
        if module['state'] == 'installed':
            print("✅ Module déjà installé !")
        elif module['state'] == 'uninstalled':
            print("🚀 Installation du module...")
            
            # Installer le module
            models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'ir.module.module', 'button_immediate_install',
                [module_ids]
            )
            
            print("✅ Installation lancée avec succès !")
            print("⏳ Attente de l'installation...")
            
            # Attendre un peu pour l'installation
            time.sleep(5)
            
            # Vérifier l'état après installation
            module_data = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'ir.module.module', 'read',
                [module_ids],
                {'fields': ['name', 'state']}
            )
            
            new_state = module_data[0]['state']
            print(f"📊 Nouvel état: {new_state}")
            
            if new_state == 'installed':
                print("🎉 Module installé avec succès !")
            else:
                print(f"⚠️ Module en état: {new_state}")
        
        # Test des modèles après installation
        print("\n🔍 Test des modèles SAMA CONAI...")
        
        try:
            # Test request.information
            count = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'request.information', 'search_count', [[]]
            )
            print(f"✅ Modèle request.information: {count} enregistrement(s)")
        except Exception as e:
            print(f"❌ Modèle request.information: {e}")
        
        try:
            # Test whistleblowing.alert
            count = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'whistleblowing.alert', 'search_count', [[]]
            )
            print(f"✅ Modèle whistleblowing.alert: {count} enregistrement(s)")
        except Exception as e:
            print(f"❌ Modèle whistleblowing.alert: {e}")
            
    except Exception as e:
        print(f"❌ Erreur: {e}")

if __name__ == '__main__':
    main()