# SAMA CONAI - Odoo 18 Container
FROM odoo:18

# Maintainer information
LABEL maintainer="SAMA Solutions <contact@sama-solutions.com>"
LABEL description="SAMA CONAI - Transparence Sénégal - Odoo 18 Module"
LABEL version="18.0.1.0.0"

# Set environment variables
ENV ODOO_RC=/etc/odoo/odoo.conf
ENV ODOO_DATA_DIR=/var/lib/odoo
ENV ADDONS_PATH=/mnt/extra-addons

# Install additional system dependencies
USER root

# Copy and install Python dependencies for SAMA CONAI
COPY ../requirements-docker.txt /tmp/requirements-docker.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements-docker.txt

# Install Node.js for mobile applications
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Create directories
RUN mkdir -p /mnt/extra-addons/sama_conai \
    && mkdir -p /var/lib/odoo/filestore \
    && mkdir -p /var/log/odoo

# Copy the SAMA CONAI module
COPY . /mnt/extra-addons/sama_conai/

# Set proper permissions
RUN chown -R odoo:odoo /mnt/extra-addons/sama_conai \
    && chown -R odoo:odoo /var/lib/odoo \
    && chown -R odoo:odoo /var/log/odoo

# Switch back to odoo user
USER odoo

# Expose ports
EXPOSE 8069 8071 8072

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8069/web/health || exit 1

# Default command
CMD ["odoo"]