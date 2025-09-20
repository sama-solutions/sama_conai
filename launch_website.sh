#!/bin/bash

# SAMA CONAI Website Launcher Script

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to find free port
find_free_port() {
    local start_port=${1:-8000}
    local port=$start_port
    
    while [ $port -lt $((start_port + 100)) ]; do
        if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo 0
    return 1
}

# Function to check if website directory exists
check_website_dir() {
    if [ ! -d "website" ]; then
        print_error "Website directory not found!"
        print_info "Make sure you're in the SAMA CONAI project root directory"
        exit 1
    fi
    
    if [ ! -f "website/index.html" ]; then
        print_error "Website index.html not found!"
        exit 1
    fi
    
    print_success "Website directory found"
}

# Function to start the server
start_server() {
    local port=$(find_free_port 8000)
    
    if [ $port -eq 0 ]; then
        print_error "Could not find a free port!"
        exit 1
    fi
    
    print_info "Starting SAMA CONAI Formation Website..."
    print_info "Port: $port"
    print_info "Directory: $(pwd)/website"
    
    echo ""
    echo "============================================================"
    echo "🌐 SAMA CONAI Formation Website - Development Server"
    echo "============================================================"
    echo "📁 Serving: $(pwd)/website"
    echo "🌍 Local URL: http://localhost:$port"
    echo "🔗 Network URL: http://$(hostname -I | awk '{print $1}'):$port"
    echo "============================================================"
    echo "📋 Available pages:"
    echo "   • Home: /"
    echo "   • Formation Admin: /formation/administrateur.html"
    echo "   • Certification: /certification/utilisateur.html"
    echo "============================================================"
    echo "💡 Tips:"
    echo "   • Press Ctrl+C to stop the server"
    echo "   • Open the URL above in your browser"
    echo "   • The site is fully responsive (mobile/tablet/desktop)"
    echo "============================================================"
    echo ""
    
    # Try to open browser automatically
    if command -v xdg-open >/dev/null 2>&1; then
        print_info "Opening browser automatically..."
        (sleep 2 && xdg-open "http://localhost:$port") &
    elif command -v firefox >/dev/null 2>&1; then
        print_info "Opening Firefox..."
        (sleep 2 && firefox "http://localhost:$port") &
    elif command -v google-chrome >/dev/null 2>&1; then
        print_info "Opening Chrome..."
        (sleep 2 && google-chrome "http://localhost:$port") &
    else
        print_warning "Could not detect browser. Please open http://localhost:$port manually"
    fi
    
    print_success "Server starting on port $port..."
    print_info "Access the website at: http://localhost:$port"
    
    # Start the server
    cd website
    python3 -m http.server $port
}

# Function to show help
show_help() {
    echo "SAMA CONAI Website Launcher"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -p, --port     Specify port (default: auto-detect free port)"
    echo ""
    echo "Examples:"
    echo "  $0              # Start with auto-detected port"
    echo "  $0 -p 8080      # Start on port 8080"
    echo ""
}

# Main function
main() {
    local port=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_website_dir
    
    # Start server
    if [ -n "$port" ]; then
        print_info "Using specified port: $port"
        cd website
        python3 -m http.server $port
    else
        start_server
    fi
}

# Trap Ctrl+C
trap 'echo -e "\n\n🛑 Server stopped by user"; echo "👋 Thank you for using SAMA CONAI Formation Website!"; exit 0' INT

# Run main function
main "$@"