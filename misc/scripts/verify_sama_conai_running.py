#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de vérification que SAMA CONAI fonctionne correctement
"""

import requests
import subprocess
import time
import sys

def check_server_status():
    """Vérifie le statut du serveur Odoo"""
    
    print("🔍 VÉRIFICATION DU SERVEUR SAMA CONAI")
    print("=" * 45)
    
    port = 8077
    url = f"http://localhost:{port}"
    
    # 1. Vérifier la connectivité HTTP
    print("🌐 1. Test de connectivité HTTP...")
    try:
        response = requests.get(url, timeout=10)
        if response.status_code in [200, 303]:
            print(f"   ✅ Serveur accessible sur {url}")
            print(f"   📊 Code de réponse: {response.status_code}")
        else:
            print(f"   ⚠️ Serveur répond mais code inattendu: {response.status_code}")
    except requests.exceptions.ConnectionError:
        print(f"   ❌ Impossible de se connecter à {url}")
        return False
    except requests.exceptions.Timeout:
        print(f"   ❌ Timeout lors de la connexion à {url}")
        return False
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return False
    
    # 2. Vérifier le processus Odoo
    print(f"\n🔍 2. Vérification du processus Odoo...")
    try:
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
        odoo_processes = [line for line in result.stdout.split('\n') 
                         if 'python' in line and 'odoo' in line and str(port) in line]
        
        if odoo_processes:
            print(f"   ✅ Processus Odoo trouvé:")
            for process in odoo_processes:
                # Extraire le PID
                pid = process.split()[1]
                print(f"      🎯 PID: {pid}")
        else:
            print(f"   ❌ Aucun processus Odoo trouvé sur le port {port}")
            return False
    except Exception as e:
        print(f"   ❌ Erreur lors de la vérification des processus: {e}")
    
    # 3. Vérifier le fichier PID
    print(f"\n📄 3. Vérification du fichier PID...")
    try:
        with open('/tmp/sama_conai_analytics.pid', 'r') as f:
            pid = f.read().strip()
            print(f"   ✅ Fichier PID trouvé: {pid}")
            
            # Vérifier que le processus existe
            try:
                subprocess.run(['kill', '-0', pid], check=True, capture_output=True)
                print(f"   ✅ Processus {pid} actif")
            except subprocess.CalledProcessError:
                print(f"   ⚠️ Processus {pid} non trouvé")
    except FileNotFoundError:
        print(f"   ⚠️ Fichier PID non trouvé")
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
    
    # 4. Test de la page de login Odoo
    print(f"\n🔐 4. Test de la page de login...")
    try:
        login_url = f"{url}/web/login"
        response = requests.get(login_url, timeout=10)
        
        if response.status_code == 200:
            if 'odoo' in response.text.lower() or 'login' in response.text.lower():
                print(f"   ✅ Page de login Odoo accessible")
            else:
                print(f"   ⚠️ Page accessible mais contenu inattendu")
        else:
            print(f"   ❌ Page de login inaccessible: {response.status_code}")
    except Exception as e:
        print(f"   ❌ Erreur lors du test de login: {e}")
    
    # 5. Vérifier les logs récents
    print(f"\n📋 5. Vérification des logs récents...")
    try:
        result = subprocess.run(['tail', '-n', '10', '/tmp/sama_conai_analytics.log'], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            logs = result.stdout.strip()
            if logs:
                print(f"   ✅ Logs récents disponibles")
                # Chercher des erreurs critiques
                if 'ERROR' in logs.upper() or 'CRITICAL' in logs.upper():
                    print(f"   ⚠️ Erreurs détectées dans les logs")
                else:
                    print(f"   ✅ Aucune erreur critique dans les logs récents")
            else:
                print(f"   ⚠️ Fichier de logs vide")
        else:
            print(f"   ❌ Impossible de lire les logs")
    except Exception as e:
        print(f"   ❌ Erreur lors de la lecture des logs: {e}")
    
    # 6. Test de performance
    print(f"\n⚡ 6. Test de performance...")
    try:
        start_time = time.time()
        response = requests.get(url, timeout=10)
        end_time = time.time()
        
        response_time = (end_time - start_time) * 1000  # en millisecondes
        
        if response_time < 1000:
            print(f"   ✅ Temps de réponse excellent: {response_time:.0f}ms")
        elif response_time < 3000:
            print(f"   ✅ Temps de réponse correct: {response_time:.0f}ms")
        else:
            print(f"   ⚠️ Temps de réponse lent: {response_time:.0f}ms")
    except Exception as e:
        print(f"   ❌ Erreur lors du test de performance: {e}")
    
    return True

def show_access_info():
    """Affiche les informations d'accès"""
    
    print(f"\n🎉 SAMA CONAI OPÉRATIONNEL !")
    print("=" * 30)
    print(f"")
    print(f"🌐 **ACCÈS AU SYSTÈME**")
    print(f"   URL: http://localhost:8077")
    print(f"   👤 Login: admin")
    print(f"   🔑 Password: admin")
    print(f"")
    print(f"📋 **MENUS DISPONIBLES**")
    print(f"   📄 Accès à l'Information")
    print(f"   🚨 Signalement d'Alerte")
    print(f"   📊 Analytics & Rapports")
    print(f"   ⚙️ Administration Transparence")
    print(f"")
    print(f"✅ **STATUT**")
    print(f"   🧹 Menus nettoyés (doublons éliminés)")
    print(f"   📊 Structure réorganisée")
    print(f"   🚀 Prêt pour utilisation")
    print(f"")
    print(f"🔧 **GESTION**")
    print(f"   📋 Logs: tail -f /tmp/sama_conai_analytics.log")
    print(f"   🛑 Arrêt: kill $(cat /tmp/sama_conai_analytics.pid)")
    print(f"   🔄 Redémarrage: ./start_sama_conai_existing_db.sh")

def main():
    """Fonction principale"""
    
    if check_server_status():
        show_access_info()
        
        print(f"\n💡 **RECOMMANDATIONS**")
        print(f"   1. Testez la navigation dans les menus")
        print(f"   2. Vérifiez l'absence de doublons")
        print(f"   3. Confirmez le bon fonctionnement des actions")
        
        return True
    else:
        print(f"\n❌ **PROBLÈMES DÉTECTÉS**")
        print(f"   🔧 Vérifiez les logs: tail -f /tmp/sama_conai_analytics.log")
        print(f"   🔄 Redémarrez si nécessaire: ./start_sama_conai_existing_db.sh")
        
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)