#!/bin/bash

# SAMA CONAI Website Deployment Script
# Usage: ./deploy.sh [environment]
# Environments: local, staging, production

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="sama-conai-formation"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Environment configuration
setup_environment() {
    local env=$1
    
    case $env in
        "local")
            DEPLOY_PATH="/var/www/html/sama-conai-formation"
            DOMAIN="localhost:8000"
            SSL_ENABLED=false
            ;;
        "staging")
            DEPLOY_PATH="/var/www/html/staging.formation.sama-conai.sn"
            DOMAIN="staging.formation.sama-conai.sn"
            SSL_ENABLED=true
            ;;
        "production")
            DEPLOY_PATH="/var/www/html/formation.sama-conai.sn"
            DOMAIN="formation.sama-conai.sn"
            SSL_ENABLED=true
            ;;
        *)
            error "Unknown environment: $env. Use: local, staging, or production"
            ;;
    esac
    
    log "Environment: $env"
    log "Deploy path: $DEPLOY_PATH"
    log "Domain: $DOMAIN"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running as root or with sudo
    if [[ $EUID -eq 0 ]]; then
        warn "Running as root. Consider using a non-root user with sudo."
    fi
    
    # Check required commands
    local required_commands=("rsync" "nginx" "systemctl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            error "$cmd is required but not installed."
        fi
    done
    
    # Check if source directory exists
    if [[ ! -d "$SCRIPT_DIR" ]]; then
        error "Source directory not found: $SCRIPT_DIR"
    fi
    
    log "Prerequisites check passed"
}

# Backup existing deployment
backup_existing() {
    if [[ -d "$DEPLOY_PATH" ]]; then
        local backup_path="/var/backups/${PROJECT_NAME}_${TIMESTAMP}"
        log "Creating backup: $backup_path"
        
        sudo mkdir -p /var/backups
        sudo cp -r "$DEPLOY_PATH" "$backup_path"
        
        log "Backup created successfully"
    else
        log "No existing deployment to backup"
    fi
}

# Optimize assets
optimize_assets() {
    log "Optimizing assets..."
    
    local temp_dir="/tmp/${PROJECT_NAME}_${TIMESTAMP}"
    cp -r "$SCRIPT_DIR" "$temp_dir"
    
    # Minify CSS (if uglify-css is available)
    if command -v uglifycss &> /dev/null; then
        log "Minifying CSS files..."
        find "$temp_dir" -name "*.css" -not -name "*.min.css" | while read -r file; do
            uglifycss "$file" > "${file%.css}.min.css"
            mv "${file%.css}.min.css" "$file"
        done
    fi
    
    # Minify JS (if uglifyjs is available)
    if command -v uglifyjs &> /dev/null; then
        log "Minifying JavaScript files..."
        find "$temp_dir" -name "*.js" -not -name "*.min.js" | while read -r file; do
            uglifyjs "$file" -o "$file" --compress --mangle
        done
    fi
    
    # Optimize images (if imagemagick is available)
    if command -v convert &> /dev/null; then
        log "Optimizing images..."
        find "$temp_dir" -name "*.jpg" -o -name "*.jpeg" | while read -r file; do
            convert "$file" -quality 85 "$file"
        done
        
        find "$temp_dir" -name "*.png" | while read -r file; do
            convert "$file" -quality 85 "$file"
        done
    fi
    
    echo "$temp_dir"
}

# Deploy files
deploy_files() {
    local source_dir=$1
    
    log "Deploying files to $DEPLOY_PATH..."
    
    # Create deploy directory
    sudo mkdir -p "$DEPLOY_PATH"
    
    # Copy files with rsync
    sudo rsync -av --delete \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='*.log' \
        --exclude='deploy.sh' \
        "$source_dir/" "$DEPLOY_PATH/"
    
    # Set proper permissions
    sudo chown -R www-data:www-data "$DEPLOY_PATH"
    sudo find "$DEPLOY_PATH" -type d -exec chmod 755 {} \;
    sudo find "$DEPLOY_PATH" -type f -exec chmod 644 {} \;
    
    log "Files deployed successfully"
}

# Configure Nginx
configure_nginx() {
    local env=$1
    
    log "Configuring Nginx for $env environment..."
    
    local nginx_config="/etc/nginx/sites-available/${PROJECT_NAME}-${env}"
    
    # Create Nginx configuration
    sudo tee "$nginx_config" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    root $DEPLOY_PATH;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Main location
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    # Security
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
EOF

    # Enable site
    sudo ln -sf "$nginx_config" "/etc/nginx/sites-enabled/${PROJECT_NAME}-${env}"
    
    # Remove default site if it exists
    if [[ -f "/etc/nginx/sites-enabled/default" ]]; then
        sudo rm -f "/etc/nginx/sites-enabled/default"
    fi
    
    # Test Nginx configuration
    if sudo nginx -t; then
        log "Nginx configuration is valid"
    else
        error "Nginx configuration test failed"
    fi
    
    log "Nginx configured successfully"
}

# Setup SSL with Let's Encrypt
setup_ssl() {
    if [[ "$SSL_ENABLED" == "true" ]]; then
        log "Setting up SSL certificate..."
        
        if command -v certbot &> /dev/null; then
            sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@sama-solutions.com
            log "SSL certificate configured"
        else
            warn "Certbot not found. SSL setup skipped."
        fi
    fi
}

# Create monitoring script
create_monitoring() {
    log "Creating monitoring script..."
    
    local monitor_script="/usr/local/bin/monitor-${PROJECT_NAME}"
    
    sudo tee "$monitor_script" > /dev/null <<'EOF'
#!/bin/bash

# SAMA CONAI Website Monitoring Script

DOMAIN="$1"
LOG_FILE="/var/log/sama-conai-monitor.log"

log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if website is accessible
check_website() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN")
    
    if [[ "$response" == "200" ]]; then
        log_message "Website is accessible (HTTP $response)"
        return 0
    else
        log_message "Website is not accessible (HTTP $response)"
        return 1
    fi
}

# Check Nginx status
check_nginx() {
    if systemctl is-active --quiet nginx; then
        log_message "Nginx is running"
        return 0
    else
        log_message "Nginx is not running"
        return 1
    fi
}

# Main monitoring
main() {
    log_message "Starting monitoring check"
    
    if ! check_nginx; then
        log_message "Attempting to restart Nginx"
        systemctl restart nginx
    fi
    
    if ! check_website; then
        log_message "Website check failed"
        # Add notification logic here (email, Slack, etc.)
    fi
    
    log_message "Monitoring check completed"
}

main
EOF

    sudo chmod +x "$monitor_script"
    
    # Create cron job for monitoring
    local cron_job="*/5 * * * * $monitor_script $DOMAIN"
    (sudo crontab -l 2>/dev/null; echo "$cron_job") | sudo crontab -
    
    log "Monitoring script created and scheduled"
}

# Create update script
create_update_script() {
    log "Creating update script..."
    
    local update_script="/usr/local/bin/update-${PROJECT_NAME}"
    
    sudo tee "$update_script" > /dev/null <<EOF
#!/bin/bash

# SAMA CONAI Website Update Script

cd /opt/sama-conai
git pull origin main
cd website
./deploy.sh $1
EOF

    sudo chmod +x "$update_script"
    
    log "Update script created: $update_script"
}

# Restart services
restart_services() {
    log "Restarting services..."
    
    # Reload Nginx
    sudo systemctl reload nginx
    
    # Restart PHP-FPM if available
    if systemctl is-active --quiet php7.4-fpm; then
        sudo systemctl restart php7.4-fpm
    elif systemctl is-active --quiet php8.0-fpm; then
        sudo systemctl restart php8.0-fpm
    elif systemctl is-active --quiet php8.1-fpm; then
        sudo systemctl restart php8.1-fpm
    fi
    
    log "Services restarted successfully"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check if files exist
    if [[ ! -f "$DEPLOY_PATH/index.html" ]]; then
        error "index.html not found in deployment directory"
    fi
    
    # Check website accessibility
    local response=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN")
    if [[ "$response" != "200" ]]; then
        warn "Website returned HTTP $response instead of 200"
    else
        log "Website is accessible and returning HTTP 200"
    fi
    
    # Check SSL if enabled
    if [[ "$SSL_ENABLED" == "true" ]]; then
        local ssl_response=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN")
        if [[ "$ssl_response" == "200" ]]; then
            log "HTTPS is working correctly"
        else
            warn "HTTPS returned HTTP $ssl_response"
        fi
    fi
    
    log "Deployment verification completed"
}

# Cleanup
cleanup() {
    log "Cleaning up temporary files..."
    
    # Remove temporary directories
    rm -rf /tmp/${PROJECT_NAME}_*
    
    # Clean old backups (keep last 5)
    find /var/backups -name "${PROJECT_NAME}_*" -type d | sort -r | tail -n +6 | xargs rm -rf
    
    log "Cleanup completed"
}

# Main deployment function
main() {
    local environment=${1:-"local"}
    
    log "Starting deployment for environment: $environment"
    
    # Setup
    setup_environment "$environment"
    check_prerequisites
    
    # Backup and optimize
    backup_existing
    local optimized_dir=$(optimize_assets)
    
    # Deploy
    deploy_files "$optimized_dir"
    configure_nginx "$environment"
    setup_ssl
    
    # Post-deployment
    create_monitoring
    create_update_script "$environment"
    restart_services
    verify_deployment
    cleanup
    
    log "Deployment completed successfully!"
    log "Website URL: http://$DOMAIN"
    if [[ "$SSL_ENABLED" == "true" ]]; then
        log "HTTPS URL: https://$DOMAIN"
    fi
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi