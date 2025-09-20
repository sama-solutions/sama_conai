#!/usr/bin/env python3
"""
SAMA CONAI Formation Website - Simple Development Server
"""

import http.server
import socketserver
import os
import sys
import webbrowser
import threading
import time

class SimpleHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Simple HTTP Request Handler with CORS support"""
    
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

def open_browser(url, delay=2):
    """Open browser after a delay"""
    time.sleep(delay)
    try:
        webbrowser.open(url)
    except:
        pass

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
    print("   • Certification: /certification/utilisateur.html")
    print("=" * 60)
    print("💡 Tips:")
    print("   • Press Ctrl+C to stop the server")
    print("   • Browser will open automatically")
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
    
    # Find free port if specified port is busy
    try:
        port = find_free_port(port)
    except RuntimeError as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    # Print banner
    print_banner(port, os.getcwd())
    
    # Create server
    try:
        with socketserver.TCPServer(("", port), SimpleHTTPRequestHandler) as httpd:
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
            print("💡 Try a different port: python3 simple_server.py 8001")
        else:
            print(f"❌ Error starting server: {e}")
        sys.exit(1)
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()