#!/usr/bin/env python3
"""
SAMA CONAI Formation Website - Vérificateur de serveur
Vérifie si le serveur fonctionne correctement
"""

import requests
import sys
import time

def check_server(port=8000, timeout=5):
    """Vérifier si le serveur répond"""
    url = f"http://localhost:{port}"
    
    try:
        print(f"🔍 Vérification du serveur sur {url}...")
        response = requests.get(url, timeout=timeout)
        
        if response.status_code == 200:
            print(f"✅ Serveur actif sur le port {port}")
            print(f"📄 Page d'accueil accessible")
            return True
        else:
            print(f"⚠️ Serveur répond avec le code {response.status_code}")
            return False
            
    except requests.exceptions.ConnectionError:
        print(f"❌ Aucun serveur trouvé sur le port {port}")
        return False
    except requests.exceptions.Timeout:
        print(f"⏰ Timeout lors de la connexion au port {port}")
        return False
    except Exception as e:
        print(f"❌ Erreur lors de la vérification: {e}")
        return False

def check_pages(port=8000):
    """Vérifier les pages principales"""
    pages = [
        "/",
        "/formation/citoyen.html",
        "/formation/agent.html", 
        "/formation/administrateur.html",
        "/formation/formateur.html",
        "/certification/utilisateur.html"
    ]
    
    base_url = f"http://localhost:{port}"
    working_pages = []
    broken_pages = []
    
    for page in pages:
        url = base_url + page
        try:
            response = requests.get(url, timeout=3)
            if response.status_code == 200:
                working_pages.append(page)
                print(f"✅ {page}")
            else:
                broken_pages.append(page)
                print(f"❌ {page} (Code: {response.status_code})")
        except Exception as e:
            broken_pages.append(page)
            print(f"❌ {page} (Erreur: {e})")
    
    print(f"\n📊 Résumé:")
    print(f"   ✅ Pages fonctionnelles: {len(working_pages)}")
    print(f"   ❌ Pages en erreur: {len(broken_pages)}")
    
    return len(broken_pages) == 0

def main():
    """Fonction principale"""
    print("🌐 SAMA CONAI - Vérificateur de serveur")
    print("=" * 50)
    
    # Vérifier si le serveur répond
    if not check_server():
        print("\n💡 Pour démarrer le serveur:")
        print("   python3 start_server.py")
        print("   ou")
        print("   ./start.sh")
        sys.exit(1)
    
    print("\n📋 Vérification des pages principales:")
    if check_pages():
        print("\n🎉 Tous les tests sont passés!")
        print("🌐 Le site SAMA CONAI fonctionne correctement")
    else:
        print("\n⚠️ Certaines pages ont des problèmes")
        sys.exit(1)

if __name__ == "__main__":
    main()