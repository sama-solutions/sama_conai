#!/bin/bash

# SAMA CONAI - Simple Installation Script
# This script helps install SAMA CONAI as an Odoo module

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Configuration
MODULE_NAME="sama_conai"
GITHUB_URL="https://github.com/sama-solutions/conai.git"

# Check if running as root
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root. Make sure to set proper permissions after installation."
    fi
}

# Find Odoo installation
find_odoo_path() {
    log "Looking for Odoo installation..."
    
    # Common Odoo paths
    POSSIBLE_PATHS=(
        "/opt/odoo/custom_addons"
        "/var/lib/odoo/addons"
        "/usr/lib/python3/dist-packages/odoo/addons"
        "/home/odoo/custom_addons"
        "/odoo/custom_addons"
        "$(pwd)/../"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -d "$path" ]; then
            ODOO_ADDONS_PATH="$path"
            log "Found Odoo addons directory: $ODOO_ADDONS_PATH"
            return 0
        fi
    done
    
    # Ask user for path
    echo -e "${YELLOW}Could not find Odoo addons directory automatically.${NC}"
    read -p "Please enter your Odoo custom_addons path: " ODOO_ADDONS_PATH
    
    if [ ! -d "$ODOO_ADDONS_PATH" ]; then
        error "Directory does not exist: $ODOO_ADDONS_PATH"
        exit 1
    fi
}

# Check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        error "Git is not installed. Please install git first:"
        echo "  Ubuntu/Debian: sudo apt-get install git"
        echo "  CentOS/RHEL: sudo yum install git"
        exit 1
    fi
}

# Check if module already exists
check_existing_module() {
    if [ -d "$ODOO_ADDONS_PATH/$MODULE_NAME" ]; then
        warning "SAMA CONAI module already exists at $ODOO_ADDONS_PATH/$MODULE_NAME"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Updating existing module..."
            cd "$ODOO_ADDONS_PATH/$MODULE_NAME"
            git pull origin main
            return 0
        else
            error "Installation cancelled."
            exit 1
        fi
    fi
}

# Download module
download_module() {
    log "Downloading SAMA CONAI module..."
    
    cd "$ODOO_ADDONS_PATH"
    
    if git clone "$GITHUB_URL" "$MODULE_NAME"; then
        log "Module downloaded successfully!"
    else
        error "Failed to download module from $GITHUB_URL"
        exit 1
    fi
}

# Set permissions
set_permissions() {
    log "Setting proper permissions..."
    
    # Try to detect odoo user
    ODOO_USER=""
    if id "odoo" &>/dev/null; then
        ODOO_USER="odoo"
    elif id "openerp" &>/dev/null; then
        ODOO_USER="openerp"
    fi
    
    if [ -n "$ODOO_USER" ]; then
        log "Setting ownership to $ODOO_USER user..."
        if command -v sudo &> /dev/null; then
            sudo chown -R "$ODOO_USER:$ODOO_USER" "$ODOO_ADDONS_PATH/$MODULE_NAME"
            sudo chmod -R 755 "$ODOO_ADDONS_PATH/$MODULE_NAME"
        else
            warning "sudo not available. Please set permissions manually:"
            echo "  chown -R $ODOO_USER:$ODOO_USER $ODOO_ADDONS_PATH/$MODULE_NAME"
            echo "  chmod -R 755 $ODOO_ADDONS_PATH/$MODULE_NAME"
        fi
    else
        warning "Could not detect Odoo user. Setting standard permissions..."
        chmod -R 755 "$ODOO_ADDONS_PATH/$MODULE_NAME"
    fi
}

# Check Odoo configuration
check_odoo_config() {
    log "Checking Odoo configuration..."
    
    # Common config file locations
    CONFIG_PATHS=(
        "/etc/odoo/odoo.conf"
        "/etc/odoo.conf"
        "/opt/odoo/odoo.conf"
        "/home/odoo/odoo.conf"
    )
    
    for config_path in "${CONFIG_PATHS[@]}"; do
        if [ -f "$config_path" ]; then
            log "Found Odoo config: $config_path"
            
            # Check if addons_path includes our directory
            if grep -q "$ODOO_ADDONS_PATH" "$config_path"; then
                log "Addons path is correctly configured"
            else
                warning "Your addons_path might need to be updated in $config_path"
                echo "  Make sure it includes: $ODOO_ADDONS_PATH"
            fi
            return 0
        fi
    done
    
    warning "Could not find Odoo configuration file"
    echo "  Make sure your addons_path includes: $ODOO_ADDONS_PATH"
}

# Restart Odoo service
restart_odoo() {
    log "Attempting to restart Odoo service..."
    
    # Try different service names
    SERVICES=("odoo" "odoo18" "openerp" "odoo-server")
    
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log "Found active service: $service"
            if command -v sudo &> /dev/null; then
                if sudo systemctl restart "$service"; then
                    log "Odoo service restarted successfully!"
                    return 0
                fi
            else
                warning "sudo not available. Please restart Odoo manually:"
                echo "  systemctl restart $service"
                return 0
            fi
        fi
    done
    
    warning "Could not find or restart Odoo service automatically."
    echo "  Please restart your Odoo server manually."
}

# Show next steps
show_next_steps() {
    log "Installation completed successfully!"
    echo
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Make sure Odoo server is running"
    echo "2. Go to your Odoo instance (usually http://localhost:8069)"
    echo "3. Go to Apps menu"
    echo "4. Click 'Update Apps List'"
    echo "5. Search for 'SAMA CONAI'"
    echo "6. Click 'Install'"
    echo
    echo -e "${GREEN}After installation, you can access:${NC}"
    echo "• Transparency Dashboard: http://your-odoo-domain/transparence-dashboard"
    echo "• Information Requests: http://your-odoo-domain/acces-information"
    echo "• Anonymous Alerts: http://your-odoo-domain/signalement-anonyme"
    echo
    echo -e "${BLUE}For detailed documentation, see:${NC}"
    echo "• Installation Guide: $ODOO_ADDONS_PATH/$MODULE_NAME/INSTALLATION.md"
    echo "• User Guide: $ODOO_ADDONS_PATH/$MODULE_NAME/misc/documentation/"
    echo
    echo -e "${GREEN}🎉 Welcome to SAMA CONAI - Promoting transparency in Senegal! 🇸🇳${NC}"
}

# Main installation process
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    SAMA CONAI Installation                   ║"
    echo "║              Transparence Sénégal - Odoo Module             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Parse arguments
    SKIP_RESTART=false
    CUSTOM_PATH=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-restart)
                SKIP_RESTART=true
                shift
                ;;
            --path)
                CUSTOM_PATH="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [--skip-restart] [--path /custom/path] [--help]"
                echo "  --skip-restart: Skip Odoo service restart"
                echo "  --path: Custom addons path"
                echo "  --help: Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Run installation steps
    check_permissions
    check_git
    
    if [ -n "$CUSTOM_PATH" ]; then
        ODOO_ADDONS_PATH="$CUSTOM_PATH"
        if [ ! -d "$ODOO_ADDONS_PATH" ]; then
            error "Custom path does not exist: $ODOO_ADDONS_PATH"
            exit 1
        fi
    else
        find_odoo_path
    fi
    
    check_existing_module
    download_module
    set_permissions
    check_odoo_config
    
    if [ "$SKIP_RESTART" = false ]; then
        restart_odoo
    else
        warning "Skipping Odoo restart. Please restart manually."
    fi
    
    show_next_steps
}

# Run main function
main "$@"