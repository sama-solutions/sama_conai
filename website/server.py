#!/usr/bin/env python3
"""
SAMA CONAI Formation Website - Development Server
Simple HTTP server for local development with CORS support
"""

import http.server
import socketserver
import os
import sys
import webbrowser
import threading
import time
import subprocess
import signal
from urllib.parse import urlparse

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
    
    def guess_type(self, path):
        """Enhanced MIME type guessing"""
        # Custom MIME types first
        if path.endswith('.js'):
            return 'application/javascript'
        elif path.endswith('.css'):
            return 'text/css'
        elif path.endswith('.json'):
            return 'application/json'
        elif path.endswith('.svg'):
            return 'image/svg+xml'
        elif path.endswith('.woff'):
            return 'font/woff'
        elif path.endswith('.woff2'):
            return 'font/woff2'
        
        # Fallback to parent method
        try:
            result = super().guess_type(path)
            if isinstance(result, tuple) and len(result) >= 1:
                return result[0]
            return result
        except Exception:
            return 'application/octet-stream'

def kill_processes_on_port(port):
    """Kill processes using the specified port"""
    try:
        # Find processes using the port
        result = subprocess.run(
            ['lsof', '-ti', f':{port}'],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0 and result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            print(f"🔍 Found {len(pids)} process(es) using port {port}")
            
            for pid in pids:
                if pid.strip():
                    try:
                        print(f"🛑 Killing process {pid}")
                        os.kill(int(pid), signal.SIGTERM)
                        time.sleep(0.5)  # Give process time to terminate gracefully
                        
                        # Check if process still exists, force kill if necessary
                        try:
                            os.kill(int(pid), 0)  # Check if process exists
                            print(f"⚡ Force killing process {pid}")
                            os.kill(int(pid), signal.SIGKILL)
                        except ProcessLookupError:
                            pass  # Process already terminated
                            
                    except (ValueError, ProcessLookupError, PermissionError) as e:
                        print(f"⚠️  Could not kill process {pid}: {e}")
            
            print(f"✅ Port {port} should now be free")
        else:
            print(f"✅ Port {port} is already free")
            
    except subprocess.TimeoutExpired:
        print(f"⚠️  Timeout while checking port {port}")
    except FileNotFoundError:
        # lsof not available, try alternative method
        try:
            result = subprocess.run(
                ['netstat', '-tlnp'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0:
                lines = result.stdout.split('\n')
                for line in lines:
                    if f':{port} ' in line and 'LISTEN' in line:
                        # Extract PID from netstat output
                        parts = line.split()
                        if len(parts) > 6 and '/' in parts[6]:
                            pid = parts[6].split('/')[0]
                            if pid.isdigit():
                                try:
                                    print(f"🛑 Killing process {pid} (from netstat)")
                                    os.kill(int(pid), signal.SIGTERM)
                                    time.sleep(0.5)
                                except (ProcessLookupError, PermissionError) as e:
                                    print(f"⚠️  Could not kill process {pid}: {e}")
        except (subprocess.TimeoutExpired, FileNotFoundError):
            print(f"⚠️  Could not check/kill processes on port {port}")
    except Exception as e:
        print(f"⚠️  Error while freeing port {port}: {e}")

def find_free_port(start_port=8000, max_attempts=100):
    """Find a free port starting from start_port"""
    import socket
    
    for port in range(start_port, start_port + max_attempts):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('localhost', port))
                return port
        except OSError:
            continue
    
    raise RuntimeError(f"Could not find a free port in range {start_port}-{start_port + max_attempts}")

def open_browser(url, delay=1.5):
    """Open browser after a delay"""
    time.sleep(delay)
    webbrowser.open(url)

def print_banner(port, directory):
    """Print startup banner"""
    print("=" * 60)
    print("🌐 SAMA CONAI Formation Website - Development Server")
    print("=" * 60)
    print(f"📁 Serving directory: {directory}")
    print(f"🌍 Local URL: http://localhost:{port}")
    print(f"🔗 Network URL: http://0.0.0.0:{port}")
    print("=" * 60)
    print("📋 Available pages:")
    print("   • Home: /")
    print("   • Formation Admin: /formation/administrateur.html")
    print("   • Formation Agent: /formation/agent.html")
    print("   • Formation Citoyen: /formation/citoyen.html")
    print("   • Formation Formateur: /formation/formateur.html")
    print("   • Certification Utilisateur: /certification/utilisateur.html")
    print("   • Certification Formateur: /certification/formateur.html")
    print("   • Certification Expert: /certification/expert.html")
    print("=" * 60)
    print("💡 Tips:")
    print("   • Press Ctrl+C to stop the server")
    print("   • Browser will open automatically")
    print("   • CORS is enabled for API testing")
    print("=" * 60)

def main():
    """Main server function"""
    # Change to script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # Parse command line arguments
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port number: {sys.argv[1]}")
            sys.exit(1)
    
    # Kill any processes using the desired port
    print(f"🔧 Checking and freeing port {port}...")
    kill_processes_on_port(port)
    
    # Wait a moment for processes to fully terminate
    time.sleep(1)
    
    # Try to use the desired port, or find a free one if still busy
    try:
        import socket
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('localhost', port))
            # Port is free, we can use it
    except OSError:
        # Port still busy, find another one
        print(f"⚠️  Port {port} still busy, finding alternative...")
        try:
            port = find_free_port(port + 1)
        except RuntimeError as e:
            print(f"Error: {e}")
            sys.exit(1)
    
    # Print banner
    print_banner(port, os.getcwd())
    
    # Create server
    try:
        with socketserver.TCPServer(("", port), CORSHTTPRequestHandler) as httpd:
            server_url = f"http://localhost:{port}"
            
            # Open browser in background thread
            browser_thread = threading.Thread(target=open_browser, args=(server_url,))
            browser_thread.daemon = True
            browser_thread.start()
            
            print(f"🚀 Server started successfully!")
            print(f"🌐 Open {server_url} in your browser")
            print("\n⏳ Starting server...")
            
            # Start serving
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped by user")
        print("👋 Thank you for using SAMA CONAI Formation Website!")
        
    except OSError as e:
        if e.errno == 98:  # Address already in use
            print(f"❌ Error: Port {port} is already in use")
            print("💡 Try a different port: python server.py 8001")
        else:
            print(f"❌ Error starting server: {e}")
        sys.exit(1)
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()