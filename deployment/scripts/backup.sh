#!/bin/bash

# SAMA CONAI Backup Script
set -e

# Configuration
BACKUP_DIR="/backups"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
DB_HOST=${HOST:-db}
DB_USER=${USER:-odoo}
DB_NAME=${POSTGRES_DB:-sama_conai_prod}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Create backup directory
mkdir -p "$BACKUP_DIR/db"
mkdir -p "$BACKUP_DIR/filestore"

# Database backup
backup_database() {
    log "Starting database backup..."
    
    BACKUP_FILE="$BACKUP_DIR/db/sama_conai_${TIMESTAMP}.sql"
    
    if pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"; then
        log "Database backup completed: $BACKUP_FILE"
        
        # Compress the backup
        gzip "$BACKUP_FILE"
        log "Database backup compressed: ${BACKUP_FILE}.gz"
    else
        error "Database backup failed!"
        exit 1
    fi
}

# Filestore backup
backup_filestore() {
    log "Starting filestore backup..."
    
    FILESTORE_PATH="/var/lib/odoo/filestore"
    BACKUP_FILE="$BACKUP_DIR/filestore/filestore_${TIMESTAMP}.tar.gz"
    
    if [ -d "$FILESTORE_PATH" ]; then
        if tar -czf "$BACKUP_FILE" -C "$FILESTORE_PATH" .; then
            log "Filestore backup completed: $BACKUP_FILE"
        else
            error "Filestore backup failed!"
            exit 1
        fi
    else
        warning "Filestore directory not found: $FILESTORE_PATH"
    fi
}

# Clean old backups
cleanup_old_backups() {
    log "Cleaning up old backups (older than $RETENTION_DAYS days)..."
    
    # Clean database backups
    find "$BACKUP_DIR/db" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
    
    # Clean filestore backups
    find "$BACKUP_DIR/filestore" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    log "Old backups cleaned up"
}

# Upload to S3 (if configured)
upload_to_s3() {
    if [ -n "$BACKUP_S3_BUCKET" ] && [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        log "Uploading backups to S3..."
        
        # Install AWS CLI if not present
        if ! command -v aws &> /dev/null; then
            log "Installing AWS CLI..."
            pip install awscli
        fi
        
        # Upload database backup
        DB_BACKUP="$BACKUP_DIR/db/sama_conai_${TIMESTAMP}.sql.gz"
        if [ -f "$DB_BACKUP" ]; then
            aws s3 cp "$DB_BACKUP" "s3://$BACKUP_S3_BUCKET/db/"
            log "Database backup uploaded to S3"
        fi
        
        # Upload filestore backup
        FILESTORE_BACKUP="$BACKUP_DIR/filestore/filestore_${TIMESTAMP}.tar.gz"
        if [ -f "$FILESTORE_BACKUP" ]; then
            aws s3 cp "$FILESTORE_BACKUP" "s3://$BACKUP_S3_BUCKET/filestore/"
            log "Filestore backup uploaded to S3"
        fi
    else
        log "S3 backup not configured, skipping upload"
    fi
}

# Generate backup report
generate_report() {
    REPORT_FILE="$BACKUP_DIR/backup_report_${TIMESTAMP}.txt"
    
    cat > "$REPORT_FILE" << EOF
SAMA CONAI Backup Report
========================
Date: $(date)
Timestamp: $TIMESTAMP

Database Backup:
- File: sama_conai_${TIMESTAMP}.sql.gz
- Size: $(du -h "$BACKUP_DIR/db/sama_conai_${TIMESTAMP}.sql.gz" 2>/dev/null | cut -f1 || echo "N/A")

Filestore Backup:
- File: filestore_${TIMESTAMP}.tar.gz
- Size: $(du -h "$BACKUP_DIR/filestore/filestore_${TIMESTAMP}.tar.gz" 2>/dev/null | cut -f1 || echo "N/A")

Total Backups:
- Database backups: $(ls -1 "$BACKUP_DIR/db"/*.sql.gz 2>/dev/null | wc -l)
- Filestore backups: $(ls -1 "$BACKUP_DIR/filestore"/*.tar.gz 2>/dev/null | wc -l)

Disk Usage:
- Backup directory: $(du -sh "$BACKUP_DIR" | cut -f1)

Status: SUCCESS
EOF

    log "Backup report generated: $REPORT_FILE"
}

# Main backup process
main() {
    log "Starting SAMA CONAI backup process..."
    
    # Check if database is accessible
    if ! pg_isready -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME"; then
        error "Database is not accessible!"
        exit 1
    fi
    
    # Perform backups
    backup_database
    backup_filestore
    
    # Upload to S3 if configured
    upload_to_s3
    
    # Clean old backups
    cleanup_old_backups
    
    # Generate report
    generate_report
    
    log "🎉 Backup process completed successfully!"
}

# Run main function
main "$@"