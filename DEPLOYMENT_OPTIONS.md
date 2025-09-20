# 🚀 SAMA CONAI - Deployment Options

This document outlines the two deployment approaches available for SAMA CONAI.

## 📦 Option 1: Simple Odoo Module (Recommended)

### ✅ **Best for:**
- Existing Odoo installations
- Standard business deployments
- Organizations with existing Odoo infrastructure
- Quick setup and testing

### 🚀 **Quick Start:**
```bash
# Automated installation
curl -sSL https://raw.githubusercontent.com/sama-solutions/conai/main/install.sh | bash

# Or manual installation
cd /path/to/your/odoo/custom_addons/
git clone https://github.com/sama-solutions/conai.git sama_conai
sudo systemctl restart odoo
# Then install via Odoo Apps interface
```

### 📋 **Requirements:**
- Existing Odoo 18.0 installation
- Access to custom_addons directory
- Restart permissions for Odoo service

### 📖 **Documentation:**
- **[Complete Installation Guide](INSTALLATION.md)**
- **[User Documentation](misc/documentation/)**

### ✅ **Advantages:**
- ✅ Simple installation process
- ✅ Integrates with existing Odoo setup
- ✅ No additional infrastructure needed
- ✅ Standard Odoo module management
- ✅ Easy updates and maintenance
- ✅ Minimal resource overhead

### ⚠️ **Considerations:**
- Requires existing Odoo installation
- Limited to single-instance deployment
- Depends on host Odoo configuration

---

## 🐳 Option 2: Docker Deployment (Advanced)

### ✅ **Best for:**
- New deployments from scratch
- Microservices architecture
- Development environments
- Scalable production setups
- Multi-environment deployments

### 🚀 **Quick Start:**
```bash
# Clone repository
git clone https://github.com/sama-solutions/conai.git
cd conai

# Development deployment
cp deployment/.env.example deployment/.env
cd deployment/docker
docker-compose up -d

# Production deployment
./deployment/scripts/deploy.sh
```

### 📋 **Requirements:**
- Docker 20.10+
- Docker Compose 2.0+
- 4GB+ RAM recommended
- SSL certificates for production

### 📖 **Documentation:**
- **[Docker Deployment Guide](deployment/docker/DOCKER_README.md)**
- **[Container Setup Report](deployment/docker/CONTAINER_SETUP_REPORT.md)**

### ✅ **Advantages:**
- ✅ Complete isolated environment
- ✅ Includes monitoring (Prometheus/Grafana)
- ✅ Automated backups and deployment
- ✅ SSL/TLS termination with Nginx
- ✅ Horizontal scaling capabilities
- ✅ Development/production parity
- ✅ Easy rollback and updates

### ⚠️ **Considerations:**
- Requires Docker knowledge
- Higher resource requirements
- More complex initial setup
- Additional infrastructure components

---

## 🔄 Comparison Matrix

| Feature | Simple Module | Docker Deployment |
|---------|---------------|-------------------|
| **Setup Complexity** | ⭐ Simple | ⭐⭐⭐ Advanced |
| **Resource Usage** | ⭐⭐⭐ Low | ⭐⭐ Medium |
| **Scalability** | ⭐⭐ Limited | ⭐⭐⭐ High |
| **Monitoring** | ⭐ Basic | ⭐⭐⭐ Advanced |
| **Backup/Recovery** | ⭐⭐ Manual | ⭐⭐⭐ Automated |
| **SSL/Security** | ⭐⭐ Host-dependent | ⭐⭐⭐ Built-in |
| **Maintenance** | ⭐⭐⭐ Easy | ⭐⭐ Moderate |
| **Development** | ⭐⭐ Good | ⭐⭐⭐ Excellent |

## 🎯 Decision Guide

### Choose **Simple Module** if:
- ✅ You have an existing Odoo installation
- ✅ You want minimal setup complexity
- ✅ You need quick deployment
- ✅ You have limited infrastructure resources
- ✅ You prefer standard Odoo module management

### Choose **Docker Deployment** if:
- ✅ You're starting a new deployment
- ✅ You need advanced monitoring and logging
- ✅ You want automated backups and deployment
- ✅ You plan to scale horizontally
- ✅ You need development/production parity
- ✅ You want complete environment isolation

## 🔄 Migration Between Options

### From Simple Module to Docker:
1. **Backup your data:**
   ```bash
   # Database backup
   pg_dump your_database > backup.sql
   
   # Filestore backup
   tar -czf filestore.tar.gz /var/lib/odoo/filestore/
   ```

2. **Deploy Docker environment:**
   ```bash
   git clone https://github.com/sama-solutions/conai.git
   cd conai/deployment/docker
   cp ../.env.example .env
   # Configure .env
   docker-compose up -d
   ```

3. **Restore data:**
   ```bash
   # Restore database
   docker-compose exec -T db psql -U odoo -d sama_conai < backup.sql
   
   # Restore filestore
   docker run --rm -v sama_conai_web_data:/target -v $(pwd):/backup alpine tar xzf /backup/filestore.tar.gz -C /target
   ```

### From Docker to Simple Module:
1. **Backup from Docker:**
   ```bash
   # Database backup
   docker-compose exec db pg_dump -U odoo sama_conai > backup.sql
   
   # Filestore backup
   docker run --rm -v sama_conai_web_data:/source -v $(pwd):/backup alpine tar czf /backup/filestore.tar.gz -C /source .
   ```

2. **Install as simple module:**
   ```bash
   cd /path/to/odoo/custom_addons/
   git clone https://github.com/sama-solutions/conai.git sama_conai
   sudo systemctl restart odoo
   ```

3. **Restore data to Odoo:**
   ```bash
   # Restore database
   psql -U odoo -d your_database < backup.sql
   
   # Restore filestore
   tar xzf filestore.tar.gz -C /var/lib/odoo/filestore/
   ```

## 📞 Support

### For Simple Module Installation:
- **Documentation**: [INSTALLATION.md](INSTALLATION.md)
- **Issues**: Use automated installer or manual steps
- **Support**: Standard Odoo community support

### For Docker Deployment:
- **Documentation**: [deployment/docker/DOCKER_README.md](deployment/docker/DOCKER_README.md)
- **Issues**: Check container logs and health status
- **Support**: Docker and containerization knowledge required

### General Support:
- **GitHub Issues**: [https://github.com/sama-solutions/conai/issues](https://github.com/sama-solutions/conai/issues)
- **Email**: contact@sama-solutions.com
- **Documentation**: [misc/documentation/](misc/documentation/)

---

## 🎉 Conclusion

Both deployment options provide a complete SAMA CONAI experience:

- **Simple Module**: Perfect for existing Odoo users who want quick, straightforward installation
- **Docker Deployment**: Ideal for new deployments requiring advanced features and scalability

Choose the option that best fits your infrastructure, expertise, and requirements. Both approaches are fully supported and documented.

**🇸🇳 Promoting transparency in Senegal with flexible deployment options!**