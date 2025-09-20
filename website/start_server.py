#!/usr/bin/env python3
"""
SAMA CONAI Formation Website - Server Launcher
Automatically kills processes on port 8000 and starts the server
"""

import http.server
import socketserver
import os
import sys
import subprocess
import signal
import time
import webbrowser
import threading

PORT = 8000

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP Request Handler with CORS support"""
    
    def end_headers(self):
        """Add CORS headers to all responses"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle OPTIONS requests for CORS preflight"""
        self.send_response(200)
        self.end_headers()
    
    def log_message(self, format, *args):
        """Custom log format"""
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {format % args}")

def kill_processes_on_port(port):
    """Kill all processes using the specified port"""
    print(f"🔍 Vérification du port {port}...")
    
    try:
        # Méthode 1: Utiliser lsof pour trouver les processus
        result = subprocess.run(
            ['lsof', '-ti', f':{port}'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            print(f"🛑 Trouvé {len(pids)} processus utilisant le port {port}")
            
            for pid in pids:
                if pid.strip():
                    try:
                        pid_int = int(pid.strip())
                        print(f"   Arrêt du processus {pid_int}")
                        
                        # Tentative d'arrêt gracieux
                        os.kill(pid_int, signal.SIGTERM)
                        time.sleep(1)
                        
                        # Vérifier si le processus existe encore
                        try:
                            os.kill(pid_int, 0)  # Test si le processus existe
                            print(f"   Arrêt forcé du processus {pid_int}")
                            os.kill(pid_int, signal.SIGKILL)
                        except ProcessLookupError:
                            pass  # Processus déjà arrêté
                            
                    except (ValueError, ProcessLookupError, PermissionError) as e:
                        print(f"   ⚠️ Impossible d'arrêter le processus {pid}: {e}")
            
            print(f"✅ Port {port} libéré")
            time.sleep(1)  # Attendre que les ports soient vraiment libérés
        else:
            print(f"✅ Port {port} déjà libre")
            
    except subprocess.TimeoutExpired:
        print(f"⚠️ Timeout lors de la vérification du port {port}")
    except FileNotFoundError:
        # lsof n'est pas disponible, essayer avec netstat
        print("🔄 lsof non disponible, utilisation de netstat...")
        try:
            result = subprocess.run(
                ['netstat', '-tlnp'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                lines = result.stdout.split('\n')
                for line in lines:
                    if f':{port} ' in line and 'LISTEN' in line:
                        # Extraire le PID de la sortie netstat
                        parts = line.split()
                        if len(parts) > 6 and '/' in parts[6]:
                            pid = parts[6].split('/')[0]
                            if pid.isdigit():
                                try:
                                    pid_int = int(pid)
                                    print(f"🛑 Arrêt du processus {pid_int} (netstat)")
                                    os.kill(pid_int, signal.SIGTERM)
                                    time.sleep(1)
                                except (ProcessLookupError, PermissionError) as e:
                                    print(f"⚠️ Impossible d'arrêter le processus {pid}: {e}")
        except (subprocess.TimeoutExpired, FileNotFoundError):
            print(f"⚠️ Impossible de vérifier le port {port}")
    except Exception as e:
        print(f"⚠️ Erreur lors de la libération du port {port}: {e}")

def open_browser(url, delay=2):
    """Ouvrir le navigateur après un délai"""
    time.sleep(delay)
    try:
        webbrowser.open(url)
        print(f"🌐 Navigateur ouvert sur {url}")
    except Exception as e:
        print(f"⚠️ Impossible d'ouvrir le navigateur: {e}")

def print_banner(port):
    """Afficher la bannière de démarrage"""
    print("=" * 70)
    print("🌐 SAMA CONAI Formation Website - Serveur de Développement")
    print("=" * 70)
    print(f"📁 Répertoire: {os.getcwd()}")
    print(f"🌍 URL Locale: http://localhost:{port}")
    print(f"🔗 URL Réseau: http://0.0.0.0:{port}")
    print("=" * 70)
    print("📋 Pages disponibles:")
    print(f"   • Accueil: http://localhost:{port}/")
    print(f"   • Formation Citoyen: http://localhost:{port}/formation/citoyen.html")
    print(f"   • Formation Agent: http://localhost:{port}/formation/agent.html")
    print(f"   • Formation Admin: http://localhost:{port}/formation/administrateur.html")
    print(f"   • Formation Formateur: http://localhost:{port}/formation/formateur.html")
    print(f"   • Certification Utilisateur: http://localhost:{port}/certification/utilisateur.html")
    print(f"   • Certification Formateur: http://localhost:{port}/certification/formateur.html")
    print(f"   • Certification Expert: http://localhost:{port}/certification/expert.html")
    print("=" * 70)
    print("💡 Conseils:")
    print("   • Appuyez sur Ctrl+C pour arrêter le serveur")
    print("   • Le navigateur s'ouvrira automatiquement")
    print("   • CORS activé pour les tests API")
    print("=" * 70)

def main():
    """Fonction principale"""
    # Changer vers le répertoire du script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    print("🚀 Démarrage du serveur SAMA CONAI...")
    
    # Arrêter les processus sur le port 8000
    kill_processes_on_port(PORT)
    
    # Afficher la bannière
    print_banner(PORT)
    
    # Créer le serveur
    try:
        with socketserver.TCPServer(("", PORT), CORSHTTPRequestHandler) as httpd:
            server_url = f"http://localhost:{PORT}"
            
            # Ouvrir le navigateur en arrière-plan
            browser_thread = threading.Thread(target=open_browser, args=(server_url,))
            browser_thread.daemon = True
            browser_thread.start()
            
            print(f"🚀 Serveur démarré avec succès sur le port {PORT}!")
            print(f"🌐 Ouvrez {server_url} dans votre navigateur")
            print("\n⏳ Serveur en fonctionnement...")
            print("📝 Appuyez sur Ctrl+C pour arrêter\n")
            
            # Démarrer le serveur
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n\n🛑 Serveur arrêté par l'utilisateur")
        print("👋 Merci d'avoir utilisé SAMA CONAI Formation Website!")
        
    except OSError as e:
        if e.errno == 98:  # Adresse déjà utilisée
            print(f"❌ Erreur: Le port {PORT} est encore utilisé")
            print("🔄 Tentative de libération forcée...")
            kill_processes_on_port(PORT)
            print("💡 Relancez le script dans quelques secondes")
        else:
            print(f"❌ Erreur lors du démarrage du serveur: {e}")
        sys.exit(1)
        
    except Exception as e:
        print(f"❌ Erreur inattendue: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()