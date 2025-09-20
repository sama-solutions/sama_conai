#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour vérifier et installer le module SAMA CONAI dans Odoo
"""

import xmlrpc.client
import sys

# Configuration Odoo
ODOO_URL = 'http://localhost:8077'
ODOO_DB = 'sama_conai_test'
ODOO_USERNAME = 'admin'
ODOO_PASSWORD = 'admin'

def connect_odoo():
    """Connexion à Odoo"""
    try:
        # Connexion aux services XML-RPC
        common = xmlrpc.client.ServerProxy(f'{ODOO_URL}/xmlrpc/2/common')
        
        # Authentification
        uid = common.authenticate(ODOO_DB, ODOO_USERNAME, ODOO_PASSWORD, {})
        if not uid:
            print("❌ Erreur d'authentification")
            return None, None
        
        print(f"✅ Connexion réussie - UID: {uid}")
        
        # Service d'objets
        models = xmlrpc.client.ServerProxy(f'{ODOO_URL}/xmlrpc/2/object')
        
        return uid, models
    except Exception as e:
        print(f"❌ Erreur de connexion: {e}")
        return None, None

def check_module_status(uid, models):
    """Vérifier le statut du module SAMA CONAI"""
    try:
        # Rechercher le module sama_conai
        modules = models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'search_read',
            [['name', '=', 'sama_conai']],
            {'fields': ['name', 'state', 'summary', 'installed_version']}
        )
        
        if modules:
            module = modules[0]
            print(f"📦 Module trouvé: {module['name']}")
            print(f"📊 État: {module['state']}")
            print(f"📝 Résumé: {module['summary']}")
            if module.get('installed_version'):
                print(f"🔢 Version installée: {module['installed_version']}")
            return module
        else:
            print("❌ Module sama_conai non trouvé dans la liste des modules")
            return None
            
    except Exception as e:
        print(f"❌ Erreur lors de la vérification du module: {e}")
        return None

def install_module(uid, models):
    """Installer le module SAMA CONAI"""
    try:
        print("🚀 Installation du module sama_conai...")
        
        # Rechercher le module
        module_ids = models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'search',
            [['name', '=', 'sama_conai']]
        )
        
        if not module_ids:
            print("❌ Module sama_conai non trouvé pour installation")
            return False
        
        # Installer le module
        models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'button_immediate_install',
            [module_ids]
        )
        
        print("✅ Installation lancée avec succès")
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de l'installation: {e}")
        return False

def check_models(uid, models):
    """Vérifier l'existence des modèles SAMA CONAI"""
    try:
        print("\n🔍 Vérification des modèles SAMA CONAI...")
        
        # Test modèle request.information
        try:
            count = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'request.information', 'search_count', [[]]
            )
            print(f"✅ Modèle request.information: {count} enregistrement(s)")
        except Exception as e:
            print(f"❌ Modèle request.information: {e}")
        
        # Test modèle whistleblowing.alert
        try:
            count = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'whistleblowing.alert', 'search_count', [[]]
            )
            print(f"✅ Modèle whistleblowing.alert: {count} enregistrement(s)")
        except Exception as e:
            print(f"❌ Modèle whistleblowing.alert: {e}")
            
    except Exception as e:
        print(f"❌ Erreur lors de la vérification des modèles: {e}")

def update_module_list(uid, models):
    """Mettre à jour la liste des modules"""
    try:
        print("🔄 Mise à jour de la liste des modules...")
        models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.module.module', 'update_list', []
        )
        print("✅ Liste des modules mise à jour")
        return True
    except Exception as e:
        print(f"❌ Erreur lors de la mise à jour: {e}")
        return False

def main():
    print("🇸🇳 SAMA CONAI - Vérification et Installation Module Odoo")
    print("=" * 60)
    
    # Connexion
    uid, models = connect_odoo()
    if not uid:
        sys.exit(1)
    
    # Mise à jour de la liste des modules
    update_module_list(uid, models)
    
    # Vérification du module
    module = check_module_status(uid, models)
    
    if module:
        if module['state'] == 'installed':
            print("✅ Module sama_conai déjà installé")
        elif module['state'] == 'uninstalled':
            print("⚠️ Module sama_conai trouvé mais non installé")
            install_module(uid, models)
        else:
            print(f"ℹ️ Module sama_conai en état: {module['state']}")
    else:
        print("❌ Module sama_conai non trouvé")
        print("💡 Vérifiez que le module est dans le chemin des addons")
    
    # Vérification des modèles
    check_models(uid, models)
    
    print("\n🎯 Vérification terminée")

if __name__ == '__main__':
    main()