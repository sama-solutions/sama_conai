# 📦 SAMA CONAI - Installation Guide

## 🎯 Simple Odoo Module Installation

This guide explains how to install SAMA CONAI as a standard Odoo module in your existing Odoo 18 instance.

## 📋 Prerequisites

- **Odoo 18.0** Community or Enterprise Edition
- **Python 3.8+**
- **PostgreSQL 12+**
- **Administrator access** to Odoo instance

### Python Dependencies

**Core module** works with standard Odoo installation - no additional packages required.

**Optional features** may require:
- `requests>=2.25.1` - For mobile app push notifications
- `qrcode[pil]>=6.1` - For QR code generation
- `PyJWT>=2.1.0` - For JWT authentication in mobile apps

See [requirements.txt](requirements.txt) for complete dependency list.

## 🚀 Quick Installation

### Method 1: Direct Installation (Recommended)

1. **Download the module**
   ```bash
   cd /path/to/your/odoo/custom_addons/
   git clone https://github.com/sama-solutions/conai.git sama_conai
   ```

2. **Restart Odoo server**
   ```bash
   sudo systemctl restart odoo
   # or
   sudo service odoo restart
   ```

3. **Install optional dependencies** (if needed)
   ```bash
   # For mobile notifications (recommended)
   pip3 install requests>=2.25.1
   
   # For all optional features
   pip3 install -r requirements-minimal.txt
   ```

4. **Install the module**
   - Go to **Apps** menu in Odoo
   - Click **Update Apps List**
   - Search for **"SAMA CONAI"**
   - Click **Install**

### Method 2: Manual Installation

1. **Download and extract**
   ```bash
   wget https://github.com/sama-solutions/conai/archive/main.zip
   unzip main.zip
   mv conai-main /path/to/your/odoo/custom_addons/sama_conai
   ```

2. **Set permissions**
   ```bash
   sudo chown -R odoo:odoo /path/to/your/odoo/custom_addons/sama_conai
   sudo chmod -R 755 /path/to/your/odoo/custom_addons/sama_conai
   ```

3. **Update addons path** (if needed)
   
   Edit your Odoo configuration file:
   ```bash
   sudo nano /etc/odoo/odoo.conf
   ```
   
   Ensure the addons_path includes your custom_addons directory:
   ```ini
   addons_path = /usr/lib/python3/dist-packages/odoo/addons,/path/to/your/custom_addons
   ```

4. **Restart and install** (same as Method 1, steps 2-3)

## 🔧 Configuration

### Basic Configuration

After installation, the module works out of the box with default settings. No additional configuration is required for basic functionality.

### Optional Configuration

1. **Demo Data** (for testing)
   - The module includes progressive demo data
   - Automatically loaded during installation
   - Can be disabled in production

2. **Email Templates**
   - Pre-configured email templates for notifications
   - Customize in **Settings → Technical → Email Templates**

3. **Security Groups**
   - **SAMA CONAI Manager**: Full access
   - **SAMA CONAI User**: Standard user access
   - **Portal User**: Public access to transparency dashboard

## 🌐 Access Points

After installation, these URLs will be available:

### Public Access (No login required)
- **Transparency Dashboard**: `http://your-odoo-domain/transparence-dashboard`
- **Information Request Form**: `http://your-odoo-domain/acces-information`
- **Anonymous Whistleblowing**: `http://your-odoo-domain/signalement-anonyme`
- **Help & Contact**: `http://your-odoo-domain/transparence-dashboard/help`

### Authenticated Access
- **Main Module**: Apps → SAMA CONAI
- **Information Requests**: SAMA CONAI → Information Requests
- **Whistleblowing Alerts**: SAMA CONAI → Whistleblowing Alerts
- **Analytics Dashboard**: SAMA CONAI → Analytics
- **Administration**: SAMA CONAI → Administration

## 📊 Features Available

### ✅ Core Features
- **Information Request Management**
- **Whistleblowing Alert System**
- **Public Transparency Dashboard**
- **Analytics and Reporting**
- **Portal Integration**
- **Email Notifications**

### ✅ Advanced Features
- **Real-time Data Dashboard**
- **Mobile-responsive Interface**
- **Multi-language Support** (French primary)
- **Compliance Tracking**
- **Automated Workflows**
- **Security and Anonymization**

## 🔒 Security Configuration

### User Groups and Permissions

The module creates these security groups:

1. **SAMA CONAI / Manager**
   - Full access to all features
   - Can manage users and settings
   - Access to sensitive data

2. **SAMA CONAI / User**
   - Can create and manage requests
   - Limited access to reports
   - Standard user permissions

3. **Portal / Portal User**
   - Public access to transparency dashboard
   - Can submit information requests
   - Can submit anonymous alerts

### Data Privacy

- **Anonymization**: Whistleblowing alerts are automatically anonymized
- **Access Control**: Sensitive data is protected by security rules
- **Audit Trail**: All actions are logged for compliance
- **GDPR Compliance**: Built-in data protection features

## 🎨 Customization

### Branding and Styling

1. **Logo and Colors**
   - Upload your logo in **Settings → General Settings**
   - Customize colors in **Website → Configuration → Themes**

2. **Email Templates**
   - Customize in **Settings → Technical → Email Templates**
   - Filter by "SAMA CONAI" to find module templates

3. **Dashboard Content**
   - Modify transparency dashboard content
   - Edit templates in **Settings → Technical → Views**

### Workflow Customization

1. **Request Stages**
   - Customize in **SAMA CONAI → Configuration → Request Stages**
   - Add custom stages for your workflow

2. **Refusal Reasons**
   - Configure in **SAMA CONAI → Configuration → Refusal Reasons**
   - Add organization-specific reasons

3. **Notification Rules**
   - Set up automated actions in **Settings → Technical → Automated Actions**
   - Filter by "SAMA CONAI" model

## 🔧 Troubleshooting

### Common Issues

#### Module Not Appearing in Apps List

1. **Check addons path**
   ```bash
   grep addons_path /etc/odoo/odoo.conf
   ```

2. **Verify permissions**
   ```bash
   ls -la /path/to/custom_addons/sama_conai/
   ```

3. **Update apps list**
   - Go to Apps → Update Apps List
   - Enable Developer Mode if needed

#### Installation Errors

1. **Check Odoo logs**
   ```bash
   sudo tail -f /var/log/odoo/odoo.log
   ```

2. **Verify dependencies**
   - All dependencies are standard Odoo modules
   - No external Python packages required

3. **Database issues**
   ```bash
   # Check database connection
   sudo -u postgres psql -l
   ```

#### Dashboard Not Loading

1. **Check URL configuration**
   - Verify base URL in **Settings → General Settings**
   - Ensure website module is installed (optional)

2. **Clear browser cache**
   - Hard refresh (Ctrl+F5)
   - Clear browser cache and cookies

3. **Check permissions**
   - Verify public user has portal access
   - Check security rules for public access

### Performance Optimization

1. **Database Indexing**
   - Indexes are automatically created
   - Monitor query performance in logs

2. **Caching**
   - Enable Redis for session storage (optional)
   - Configure Nginx for static file caching

3. **Workers Configuration**
   ```ini
   # In odoo.conf for high-traffic sites
   workers = 4
   max_cron_threads = 2
   ```

## 📞 Support

### Getting Help

1. **Documentation**
   - Check `misc/documentation/` for detailed guides
   - Review module-specific documentation

2. **Community Support**
   - GitHub Issues: [https://github.com/sama-solutions/conai/issues](https://github.com/sama-solutions/conai/issues)
   - Odoo Community Forum

3. **Professional Support**
   - Contact: contact@sama-solutions.com
   - Website: [https://www.sama-solutions.com](https://www.sama-solutions.com)

### Reporting Issues

When reporting issues, please include:

1. **Odoo version** and edition
2. **Module version** (check `__manifest__.py`)
3. **Error logs** from `/var/log/odoo/odoo.log`
4. **Steps to reproduce** the issue
5. **Browser and OS** information

## 🔄 Updates

### Updating the Module

1. **Backup your data**
   ```bash
   # Database backup
   sudo -u postgres pg_dump your_database > backup.sql
   
   # Filestore backup
   tar -czf filestore_backup.tar.gz /var/lib/odoo/filestore/
   ```

2. **Update module files**
   ```bash
   cd /path/to/custom_addons/sama_conai
   git pull origin main
   ```

3. **Update in Odoo**
   - Go to Apps → SAMA CONAI
   - Click **Upgrade**

### Version Compatibility

- **Current Version**: 18.0.1.0.0
- **Odoo Compatibility**: 18.0+
- **Python Compatibility**: 3.8+
- **Database Compatibility**: PostgreSQL 12+

## 🎉 Success!

After successful installation, you should see:

- ✅ **SAMA CONAI** appears in the Apps menu
- ✅ **Transparency Dashboard** accessible at `/transparence-dashboard`
- ✅ **Public forms** working for information requests and alerts
- ✅ **Menu items** visible in the main navigation
- ✅ **Demo data** loaded (if enabled)

**Welcome to SAMA CONAI - Promoting transparency in Senegal! 🇸🇳**

---

*For Docker deployment options, see `deployment/docker/DOCKER_README.md`*