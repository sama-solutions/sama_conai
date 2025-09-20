# 🐳 SAMA CONAI Docker Deployment

This guide explains how to deploy SAMA CONAI using Docker containers for development and production environments.

## 📋 Prerequisites

- **Docker** 20.10+
- **Docker Compose** 2.0+
- **Git** (for cloning the repository)
- **OpenSSL** (for SSL certificate generation)

## 🚀 Quick Start (Development)

### 1. Clone and Setup

```bash
git clone https://github.com/sama-solutions/conai.git
cd conai
cp .env.example .env
```

### 2. Configure Environment

Edit the `.env` file with your settings:

```bash
# Basic configuration
DB_PASSWORD=your_secure_password
ODOO_ADMIN_PASSWORD=admin_password
REDIS_PASSWORD=redis_password
```

### 3. Start Development Environment

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 4. Access the Application

- **Odoo**: http://localhost:8069
- **Mobile App**: http://localhost:3000
- **Transparency Dashboard**: http://localhost:8069/transparence-dashboard

## 🏭 Production Deployment

### 1. Prepare Production Environment

```bash
# Copy production environment
cp .env.example .env

# Edit with production values
nano .env
```

### 2. Generate SSL Certificates

```bash
# Create SSL directory
mkdir -p nginx/ssl

# Generate self-signed certificates (for testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/key.pem \
    -out nginx/ssl/cert.pem \
    -subj "/C=SN/ST=Dakar/L=Dakar/O=SAMA Solutions/CN=sama-conai.sn"

# For production, replace with valid certificates from a CA
```

### 3. Deploy to Production

```bash
# Make deploy script executable
chmod +x scripts/deploy.sh

# Run deployment
./scripts/deploy.sh

# Or skip backup (first deployment)
./scripts/deploy.sh --skip-backup
```

### 4. Verify Deployment

```bash
# Check service health
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f

# Test endpoints
curl -f https://sama-conai.sn/web/health
```

## 📊 Container Architecture

### Services Overview

| Service | Description | Port | Health Check |
|---------|-------------|------|--------------|
| **odoo** | Main Odoo application | 8069 | `/web/health` |
| **db** | PostgreSQL database | 5432 | `pg_isready` |
| **redis** | Session storage | 6379 | `redis-cli ping` |
| **nginx** | Reverse proxy | 80, 443 | `/health` |
| **mobile_app** | Mobile web app | 3000 | `/health` |
| **prometheus** | Monitoring | 9090 | - |
| **grafana** | Dashboards | 3001 | - |

### Network Configuration

```
sama_conai_network (172.20.0.0/16)
├── odoo (172.20.0.2)
├── db (172.20.0.3)
├── redis (172.20.0.4)
├── nginx (172.20.0.5)
└── mobile_app (172.20.0.6)
```

## 🔧 Configuration Files

### Docker Compose Files

- `docker-compose.yml` - Development environment
- `docker-compose.prod.yml` - Production environment

### Dockerfiles

- `Dockerfile` - Development image
- `Dockerfile.prod` - Production image with optimizations

### Configuration

- `.env.example` - Environment variables template
- `nginx/nginx.conf` - Nginx configuration
- `docker/supervisor.conf` - Process management
- `docker/entrypoint.sh` - Container startup script

## 📦 Volume Management

### Persistent Volumes

```bash
# List volumes
docker volume ls | grep sama_conai

# Backup volume
docker run --rm -v sama_conai_web_data:/source -v $(pwd)/backup:/backup alpine tar czf /backup/filestore.tar.gz -C /source .

# Restore volume
docker run --rm -v sama_conai_web_data:/target -v $(pwd)/backup:/backup alpine tar xzf /backup/filestore.tar.gz -C /target
```

### Volume Structure

- `sama_conai_db_data` - PostgreSQL data
- `sama_conai_web_data` - Odoo filestore
- `sama_conai_redis_data` - Redis data
- `sama_conai_logs` - Application logs

## 🔄 Backup and Restore

### Automated Backups

```bash
# Run backup manually
docker-compose exec backup /backup.sh

# Schedule with cron (add to crontab)
0 2 * * * cd /path/to/sama_conai && docker-compose exec backup /backup.sh
```

### Manual Backup

```bash
# Database backup
docker-compose exec db pg_dump -U odoo sama_conai > backup_$(date +%Y%m%d).sql

# Filestore backup
docker run --rm -v sama_conai_web_data:/source -v $(pwd):/backup alpine tar czf /backup/filestore_$(date +%Y%m%d).tar.gz -C /source .
```

### Restore Process

```bash
# Stop services
docker-compose down

# Restore database
docker-compose up -d db
docker-compose exec -T db psql -U odoo -d sama_conai < backup_20231201.sql

# Restore filestore
docker run --rm -v sama_conai_web_data:/target -v $(pwd):/backup alpine tar xzf /backup/filestore_20231201.tar.gz -C /target

# Start all services
docker-compose up -d
```

## 📊 Monitoring and Logging

### Log Management

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f odoo
docker-compose logs -f nginx

# Log rotation is handled by logrotate in containers
```

### Monitoring Stack

- **Prometheus**: Metrics collection (http://localhost:9090)
- **Grafana**: Dashboards and visualization (http://localhost:3001)
- **Health checks**: Built-in Docker health checks

### Grafana Dashboards

Default dashboards include:
- Odoo performance metrics
- Database statistics
- Nginx access patterns
- System resource usage

## 🔒 Security Configuration

### SSL/TLS Setup

```bash
# Production SSL certificates (Let's Encrypt)
certbot certonly --webroot -w /var/www/html -d sama-conai.sn -d www.sama-conai.sn

# Copy certificates
cp /etc/letsencrypt/live/sama-conai.sn/fullchain.pem nginx/ssl/cert.pem
cp /etc/letsencrypt/live/sama-conai.sn/privkey.pem nginx/ssl/key.pem
```

### Security Headers

Nginx is configured with security headers:
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection
- Content-Security-Policy
- Referrer-Policy

### Rate Limiting

- API endpoints: 10 requests/second
- Login endpoints: 5 requests/minute
- General traffic: Standard limits

## 🚨 Troubleshooting

### Common Issues

#### Container Won't Start

```bash
# Check logs
docker-compose logs service_name

# Check resource usage
docker stats

# Restart specific service
docker-compose restart service_name
```

#### Database Connection Issues

```bash
# Check database status
docker-compose exec db pg_isready -U odoo

# Reset database password
docker-compose exec db psql -U postgres -c "ALTER USER odoo PASSWORD 'new_password';"
```

#### SSL Certificate Issues

```bash
# Verify certificate
openssl x509 -in nginx/ssl/cert.pem -text -noout

# Test SSL connection
openssl s_client -connect sama-conai.sn:443
```

#### Performance Issues

```bash
# Check resource usage
docker stats

# Scale Odoo workers
docker-compose up -d --scale odoo=2

# Check database performance
docker-compose exec db psql -U odoo -c "SELECT * FROM pg_stat_activity;"
```

### Health Checks

```bash
# Check all service health
docker-compose ps

# Manual health checks
curl -f http://localhost:8069/web/health
curl -f http://localhost:3000/health
```

## 🔄 Updates and Maintenance

### Update Process

```bash
# Pull latest code
git pull origin main

# Rebuild and deploy
./scripts/deploy.sh

# Or manual update
docker-compose build --no-cache
docker-compose up -d
```

### Maintenance Mode

```bash
# Enable maintenance mode
docker-compose exec nginx nginx -s reload

# Disable specific services
docker-compose stop mobile_app

# Scale down
docker-compose up -d --scale odoo=1
```

## 📞 Support

For Docker-related issues:

1. Check the logs: `docker-compose logs -f`
2. Verify configuration: `docker-compose config`
3. Check resource usage: `docker stats`
4. Review health checks: `docker-compose ps`

For application issues, refer to the main [README.md](README.md) documentation.

---

**🐳 Containerized with ❤️ for SAMA CONAI**