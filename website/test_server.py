#!/usr/bin/env python3
"""
Simple test server for SAMA CONAI website
"""

import http.server
import socketserver
import os
import sys

class SimpleHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

def main():
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port: {sys.argv[1]}")
            sys.exit(1)
    
    # Change to script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    print(f"Starting server on port {port}")
    print(f"Serving directory: {os.getcwd()}")
    print(f"URL: http://localhost:{port}")
    
    try:
        with socketserver.TCPServer(("", port), SimpleHandler) as httpd:
            print("Server started successfully!")
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()