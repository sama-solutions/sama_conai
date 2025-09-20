#!/usr/bin/env python3
"""
SAMA CONAI Formation Website - Lanceur Simple
Lance le serveur sur le port 8000 en arrêtant d'abord les processus existants
"""

import subprocess
import sys
import os
import time
import signal

def kill_port_8000():
    """Arrête tous les processus utilisant le port 8000"""
    print("🔍 Libération du port 8000...")
    
    try:
        # Utiliser lsof pour trouver les processus
        result = subprocess.run(['lsof', '-ti', ':8000'], 
                              capture_output=True, text=True, timeout=5)
        
        if result.returncode == 0 and result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            print(f"🛑 Arrêt de {len(pids)} processus...")
            
            for pid in pids:
                if pid.strip():
                    try:
                        os.kill(int(pid), signal.SIGTERM)
                        print(f"   Processus {pid} arrêté")
                    except:
                        pass
            
            time.sleep(2)
            print("✅ Port 8000 libéré")
        else:
            print("✅ Port 8000 déjà libre")
            
    except FileNotFoundError:
        print("⚠️ lsof non disponible, tentative directe...")
    except Exception as e:
        print(f"⚠️ Erreur: {e}")

def main():
    """Lance le serveur"""
    # Changer vers le répertoire du script
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    print("🚀 SAMA CONAI - Démarrage du serveur...")
    
    # Libérer le port 8000
    kill_port_8000()
    
    # Afficher les informations
    print("=" * 60)
    print("🌐 SAMA CONAI Formation Website")
    print("=" * 60)
    print("📍 URL: http://localhost:8000")
    print("📁 Répertoire:", os.getcwd())
    print("=" * 60)
    print("📋 Pages principales:")
    print("   • Accueil: http://localhost:8000/")
    print("   • Formation Citoyen: http://localhost:8000/formation/citoyen.html")
    print("   • Certifications: http://localhost:8000/certification/utilisateur.html")
    print("=" * 60)
    print("🚀 Démarrage du serveur...")
    print("📝 Appuyez sur Ctrl+C pour arrêter")
    print()
    
    # Lancer le serveur Python
    try:
        subprocess.run([sys.executable, '-m', 'http.server', '8000'], check=True)
    except KeyboardInterrupt:
        print("\n🛑 Serveur arrêté")
        print("👋 Au revoir !")
    except Exception as e:
        print(f"❌ Erreur: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()