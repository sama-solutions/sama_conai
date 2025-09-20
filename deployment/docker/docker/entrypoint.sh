#!/bin/bash
set -e

# SAMA CONAI Docker Entrypoint Script

# Function to wait for database
wait_for_db() {
    echo "Waiting for database to be ready..."
    while ! pg_isready -h "$HOST" -p 5432 -U "$USER" -d "$POSTGRES_DB"; do
        echo "Database not ready, waiting..."
        sleep 2
    done
    echo "Database is ready!"
}

# Function to initialize database
init_db() {
    echo "Initializing database..."
    if [ "$1" = "odoo" ]; then
        shift
        if [ -z "$ODOO_DATABASE" ]; then
            echo "Error: ODOO_DATABASE environment variable not set"
            exit 1
        fi
        
        # Check if database exists
        if ! psql -h "$HOST" -U "$USER" -lqt | cut -d \| -f 1 | grep -qw "$ODOO_DATABASE"; then
            echo "Creating database $ODOO_DATABASE..."
            createdb -h "$HOST" -U "$USER" "$ODOO_DATABASE"
            
            # Initialize with SAMA CONAI module
            echo "Installing SAMA CONAI module..."
            odoo --config="$ODOO_RC" \
                 --database="$ODOO_DATABASE" \
                 --init=sama_conai \
                 --stop-after-init \
                 --no-http
        else
            echo "Database $ODOO_DATABASE already exists"
        fi
    fi
}

# Function to update modules
update_modules() {
    if [ "$UPDATE_MODULES" = "true" ]; then
        echo "Updating SAMA CONAI module..."
        odoo --config="$ODOO_RC" \
             --database="$ODOO_DATABASE" \
             --update=sama_conai \
             --stop-after-init \
             --no-http
    fi
}

# Function to setup logging
setup_logging() {
    echo "Setting up logging..."
    mkdir -p /var/log/odoo
    touch /var/log/odoo/odoo.log
    chown odoo:odoo /var/log/odoo/odoo.log
}

# Function to check configuration
check_config() {
    echo "Checking configuration..."
    if [ ! -f "$ODOO_RC" ]; then
        echo "Warning: Odoo configuration file not found at $ODOO_RC"
        echo "Using default configuration"
    fi
}

# Main execution
main() {
    echo "Starting SAMA CONAI container..."
    echo "Version: 18.0.1.0.0"
    echo "Environment: ${ENVIRONMENT:-development}"
    
    # Setup logging
    setup_logging
    
    # Check configuration
    check_config
    
    # Wait for database if running Odoo
    if [ "$1" = "odoo" ]; then
        wait_for_db
        init_db "$@"
        update_modules
    fi
    
    # Execute the main command
    echo "Starting Odoo with command: $@"
    exec "$@"
}

# Run main function
main "$@"