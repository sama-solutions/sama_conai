#!/bin/bash

# SAMA CONAI Deployment Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="sama_conai"
DOCKER_COMPOSE_FILE="docker-compose.prod.yml"
BACKUP_DIR="./backups"
LOG_FILE="./logs/deploy.log"

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        error ".env file not found. Please copy .env.example to .env and configure it."
        exit 1
    fi
    
    log "Prerequisites check passed!"
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    mkdir -p "$BACKUP_DIR"
    mkdir -p "./logs"
    mkdir -p "./nginx/ssl"
    mkdir -p "./config"
    log "Directories created successfully!"
}

# Generate SSL certificates if they don't exist
generate_ssl() {
    log "Checking SSL certificates..."
    
    if [ ! -f "./nginx/ssl/cert.pem" ] || [ ! -f "./nginx/ssl/key.pem" ]; then
        warning "SSL certificates not found. Generating self-signed certificates..."
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout ./nginx/ssl/key.pem \
            -out ./nginx/ssl/cert.pem \
            -subj "/C=SN/ST=Dakar/L=Dakar/O=SAMA Solutions/OU=IT Department/CN=sama-conai.sn"
        
        log "Self-signed SSL certificates generated!"
        warning "For production, please replace with valid SSL certificates from a CA."
    else
        log "SSL certificates found!"
    fi
}

# Backup existing data
backup_data() {
    if [ "$1" = "--skip-backup" ]; then
        warning "Skipping backup as requested"
        return
    fi
    
    log "Creating backup before deployment..."
    
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/backup_$BACKUP_TIMESTAMP"
    
    mkdir -p "$BACKUP_PATH"
    
    # Backup database if container is running
    if docker-compose -f "$DOCKER_COMPOSE_FILE" ps db | grep -q "Up"; then
        log "Backing up database..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T db pg_dump -U odoo sama_conai_prod > "$BACKUP_PATH/database.sql"
    fi
    
    # Backup filestore if it exists
    if docker volume ls | grep -q "${PROJECT_NAME}_sama_conai_web_prod"; then
        log "Backing up filestore..."
        docker run --rm -v "${PROJECT_NAME}_sama_conai_web_prod:/source" -v "$(pwd)/$BACKUP_PATH:/backup" alpine tar czf /backup/filestore.tar.gz -C /source .
    fi
    
    log "Backup completed: $BACKUP_PATH"
}

# Build and deploy
deploy() {
    log "Starting deployment..."
    
    # Pull latest images
    log "Pulling latest images..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" pull
    
    # Build custom images
    log "Building SAMA CONAI images..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" build --no-cache
    
    # Stop existing containers
    log "Stopping existing containers..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    
    # Start new containers
    log "Starting new containers..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 30
    
    # Check health
    check_health
    
    log "Deployment completed successfully!"
}

# Check service health
check_health() {
    log "Checking service health..."
    
    # Check Odoo
    if curl -f http://localhost:8069/web/health &> /dev/null; then
        log "✓ Odoo is healthy"
    else
        error "✗ Odoo health check failed"
    fi
    
    # Check database
    if docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T db pg_isready -U odoo -d sama_conai_prod &> /dev/null; then
        log "✓ Database is healthy"
    else
        error "✗ Database health check failed"
    fi
    
    # Check Redis
    if docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T redis redis-cli ping &> /dev/null; then
        log "✓ Redis is healthy"
    else
        warning "✗ Redis health check failed"
    fi
}

# Rollback function
rollback() {
    error "Deployment failed. Starting rollback..."
    
    # Stop current containers
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    
    # Restore from latest backup
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR" | head -n1)
    if [ -n "$LATEST_BACKUP" ]; then
        log "Restoring from backup: $LATEST_BACKUP"
        
        # Restore database
        if [ -f "$BACKUP_DIR/$LATEST_BACKUP/database.sql" ]; then
            docker-compose -f "$DOCKER_COMPOSE_FILE" up -d db
            sleep 10
            docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T db psql -U odoo -d sama_conai_prod < "$BACKUP_DIR/$LATEST_BACKUP/database.sql"
        fi
        
        # Restore filestore
        if [ -f "$BACKUP_DIR/$LATEST_BACKUP/filestore.tar.gz" ]; then
            docker run --rm -v "${PROJECT_NAME}_sama_conai_web_prod:/target" -v "$(pwd)/$BACKUP_DIR/$LATEST_BACKUP:/backup" alpine tar xzf /backup/filestore.tar.gz -C /target
        fi
    fi
    
    error "Rollback completed. Please check the logs and fix the issues."
    exit 1
}

# Main deployment process
main() {
    log "Starting SAMA CONAI deployment process..."
    
    # Parse arguments
    SKIP_BACKUP=false
    FORCE_DEPLOY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --force)
                FORCE_DEPLOY=true
                shift
                ;;
            --help)
                echo "Usage: $0 [--skip-backup] [--force] [--help]"
                echo "  --skip-backup: Skip backup before deployment"
                echo "  --force: Force deployment without confirmation"
                echo "  --help: Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Confirmation
    if [ "$FORCE_DEPLOY" = false ]; then
        echo -e "${YELLOW}This will deploy SAMA CONAI to production. Continue? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "Deployment cancelled by user."
            exit 0
        fi
    fi
    
    # Execute deployment steps
    check_prerequisites
    create_directories
    generate_ssl
    
    if [ "$SKIP_BACKUP" = false ]; then
        backup_data
    else
        backup_data --skip-backup
    fi
    
    # Set trap for rollback on error
    trap rollback ERR
    
    deploy
    
    # Remove trap
    trap - ERR
    
    log "🎉 SAMA CONAI deployment completed successfully!"
    log "🌐 Access the application at: https://sama-conai.sn"
    log "📱 Mobile app available at: https://mobile.sama-conai.sn"
    log "📊 Monitoring available at: http://localhost:3001 (Grafana)"
}

# Run main function
main "$@"