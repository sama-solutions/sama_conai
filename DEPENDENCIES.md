# 📦 SAMA CONAI - Dependencies Guide

This document provides comprehensive information about SAMA CONAI dependencies for different deployment scenarios.

## 🎯 Quick Reference

| Deployment Type | Requirements File | Installation Command |
|----------------|------------------|---------------------|
| **Simple Module** | `requirements-minimal.txt` | `pip install -r requirements-minimal.txt` |
| **Full Features** | `requirements.txt` | `pip install -r requirements.txt` |
| **Docker** | `deployment/requirements-docker.txt` | Handled automatically |

## 📋 Core Dependencies

### Odoo Framework Dependencies
These are **automatically included** with Odoo 18.0:

```python
# Odoo framework (required)
odoo>=18.0

# Database connectivity
psycopg2-binary>=2.8.6

# Date and time handling
python-dateutil>=2.8.1

# XML processing
lxml>=4.6.2

# Image processing
Pillow>=8.1.0

# PDF generation
reportlab>=3.5.59
```

### Standard Python Libraries
These are **built-in** with Python 3.8+:

```python
# Data handling
import json
import logging
import datetime
import statistics

# Security and cryptography
import secrets
import string
import hashlib

# System utilities
import os
import sys
import subprocess
```

## 🔧 Module-Specific Dependencies

### Required Dependencies

#### For Mobile App Features
```bash
# Mobile push notifications
pip install requests>=2.25.1
```

**Used in:**
- `controllers/mobile_api/mobile_notification_controller.py`
- `models/mobile/mobile_notification_service.py`

### Optional Dependencies

#### QR Code Generation
```bash
pip install qrcode[pil]>=6.1
```

**Features:**
- Generate QR codes for information requests
- Mobile app integration codes
- Dashboard quick access codes

#### JWT Authentication
```bash
pip install PyJWT>=2.1.0
```

**Features:**
- Mobile app authentication tokens
- API security for mobile endpoints
- Session management

#### Enhanced Security
```bash
pip install bcrypt>=3.2.0
```

**Features:**
- Enhanced password hashing
- Secure token generation
- Additional cryptographic functions

#### Excel Reports
```bash
pip install xlsxwriter>=1.4.3
```

**Features:**
- Export analytics to Excel
- Advanced reporting formats
- Data analysis exports

#### Email Validation
```bash
pip install email-validator>=1.1.3
```

**Features:**
- Enhanced email validation
- Domain verification
- Email format checking

## 🐳 Docker Dependencies

For Docker deployment, additional dependencies are included:

### Production Features
```python
# Monitoring and metrics
prometheus-client>=0.12.0

# Enhanced security
cryptography>=3.4.8

# Caching and performance
redis>=4.0.0

# Cloud storage (S3 backups)
boto3>=1.20.0

# System monitoring
psutil>=5.8.0
```

### System Dependencies
These are handled in the Dockerfile:

```dockerfile
# Health checks
curl

# SSL certificates
openssl

# Database tools
postgresql-client

# Node.js for mobile apps
nodejs>=18.x
```

## 📊 Dependency Matrix

| Feature | Required Packages | Optional Packages | Notes |
|---------|------------------|------------------|-------|
| **Core Module** | None (Odoo built-in) | - | Basic functionality |
| **Mobile Notifications** | `requests` | - | Push notifications |
| **QR Codes** | - | `qrcode[pil]` | Code generation |
| **JWT Auth** | - | `PyJWT` | Mobile security |
| **Excel Reports** | - | `xlsxwriter` | Advanced exports |
| **Enhanced Security** | - | `bcrypt` | Password hashing |
| **Email Validation** | - | `email-validator` | Email checking |

## 🚀 Installation Scenarios

### Scenario 1: Basic Installation
**Goal:** Core SAMA CONAI functionality only

```bash
# No additional packages needed
# All dependencies included with Odoo 18.0
```

**Features Available:**
- ✅ Information request management
- ✅ Whistleblowing alerts
- ✅ Public transparency dashboard
- ✅ Basic analytics
- ❌ Mobile app notifications
- ❌ QR code generation

### Scenario 2: Recommended Installation
**Goal:** Core + mobile notifications

```bash
pip install requests>=2.25.1
```

**Features Available:**
- ✅ All basic features
- ✅ Mobile app notifications
- ✅ Push notification service
- ❌ QR code generation
- ❌ JWT authentication

### Scenario 3: Full Installation
**Goal:** All features enabled

```bash
pip install -r requirements.txt
```

**Features Available:**
- ✅ All basic features
- ✅ Mobile app notifications
- ✅ QR code generation
- ✅ JWT authentication
- ✅ Enhanced security
- ✅ Excel exports
- ✅ Email validation

### Scenario 4: Docker Deployment
**Goal:** Production-ready containerized deployment

```bash
# Handled automatically in Docker build
docker-compose up -d
```

**Features Available:**
- ✅ All features
- ✅ Production monitoring
- ✅ Automated backups
- ✅ SSL/TLS termination
- ✅ Health checks
- ✅ Scalability

## 🔍 Dependency Verification

### Check Installed Packages
```bash
# Check if requests is installed
python3 -c "import requests; print(f'requests {requests.__version__}')"

# Check all SAMA CONAI dependencies
python3 -c "
import sys
packages = ['requests', 'qrcode', 'jwt', 'bcrypt', 'xlsxwriter']
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg} - installed')
    except ImportError:
        print(f'❌ {pkg} - not installed')
"
```

### Verify Odoo Dependencies
```bash
# Check Odoo installation
python3 -c "import odoo; print(f'Odoo {odoo.release.version}')"

# Check database connectivity
python3 -c "import psycopg2; print(f'psycopg2 {psycopg2.__version__}')"
```

## 🛠️ Troubleshooting Dependencies

### Common Issues

#### Missing requests package
```bash
# Error: ModuleNotFoundError: No module named 'requests'
# Solution:
pip install requests>=2.25.1
```

#### Permission errors during installation
```bash
# Error: Permission denied
# Solution:
sudo pip install requests>=2.25.1
# Or use virtual environment:
python3 -m venv venv
source venv/bin/activate
pip install requests>=2.25.1
```

#### Conflicting package versions
```bash
# Check installed versions
pip list | grep requests

# Upgrade to required version
pip install --upgrade requests>=2.25.1
```

### Dependency Conflicts

If you encounter conflicts with existing packages:

```bash
# Create isolated environment
python3 -m venv sama_conai_env
source sama_conai_env/bin/activate

# Install only required packages
pip install -r requirements-minimal.txt

# Configure Odoo to use this environment
# (Update your Odoo service configuration)
```

## 📝 Development Dependencies

For development and testing:

```bash
# Code formatting
pip install black>=21.0.0

# Linting
pip install flake8>=3.9.0

# Testing
pip install pytest>=6.2.0

# Debugging
pip install ipython>=7.30.0
pip install ipdb>=0.13.9
```

## 🔄 Updating Dependencies

### Regular Updates
```bash
# Update all packages
pip install --upgrade -r requirements.txt

# Update specific package
pip install --upgrade requests
```

### Security Updates
```bash
# Check for security vulnerabilities
pip audit

# Update security-critical packages
pip install --upgrade cryptography bcrypt
```

## 📞 Support

### Dependency Issues
1. **Check Python version**: `python3 --version` (requires 3.8+)
2. **Check pip version**: `pip --version`
3. **Verify Odoo installation**: `python3 -c "import odoo"`
4. **Check package conflicts**: `pip check`

### Getting Help
- **GitHub Issues**: [https://github.com/sama-solutions/conai/issues](https://github.com/sama-solutions/conai/issues)
- **Documentation**: [INSTALLATION.md](INSTALLATION.md)
- **Docker Guide**: [deployment/docker/DOCKER_README.md](deployment/docker/DOCKER_README.md)

---

**📦 Dependencies managed for optimal SAMA CONAI experience!**