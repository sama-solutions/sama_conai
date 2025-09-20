#!/bin/bash

# ========================================
# SAMA CONAI - CONFIGURATION RAPIDE
# ========================================
# Script de configuration rapide pour SAMA CONAI
# Version: 1.0.0

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 SAMA CONAI - Configuration Rapide${NC}"
echo "========================================"
echo ""

# Vérifier si le fichier config.env existe
if [ -f "$SCRIPT_DIR/config.env" ]; then
    echo -e "${GREEN}✅ Fichier config.env trouvé${NC}"
    source "$SCRIPT_DIR/config.env"
else
    echo -e "${YELLOW}⚠️ Création du fichier config.env${NC}"
    
    # Créer le fichier de configuration par défaut
    cat > "$SCRIPT_DIR/config.env" << 'EOF'
# =============================================================================
# SAMA CONAI - Configuration Environment
# =============================================================================
# Fichier de configuration pour personnaliser les paramètres de démarrage
# =============================================================================

# Chemins des applications
ODOO_PATH="/var/odoo/odoo18"
ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

# Configuration de la base de données
DB_NAME="sama_conai_production"

# Ports des services
ODOO_PORT="8069"
MOBILE_WEB_PORT="3001"

# Configuration des logs
LOG_LEVEL="info"

# Timeouts (en secondes)
STARTUP_TIMEOUT="120"
SHUTDOWN_TIMEOUT="15"

# Options Odoo
ODOO_WORKERS="0"
ODOO_MAX_CRON_THREADS="2"

# Configuration de l'application mobile
MOBILE_ENV="production"
EOF
    
    echo -e "${GREEN}✅ Fichier config.env créé${NC}"
fi

# Créer les répertoires nécessaires
echo -e "${BLUE}📁 Création des répertoires...${NC}"
mkdir -p "$SCRIPT_DIR/.pids"
mkdir -p "$SCRIPT_DIR/logs"
mkdir -p "$SCRIPT_DIR/backups"
echo -e "${GREEN}✅ Répertoires créés${NC}"

# Vérifier les permissions
echo -e "${BLUE}🔐 Vérification des permissions...${NC}"
if [ -w "$SCRIPT_DIR" ]; then
    echo -e "${GREEN}✅ Permissions OK${NC}"
else
    echo -e "${RED}❌ Permissions insuffisantes${NC}"
    echo "Exécutez: chmod +w $SCRIPT_DIR"
    exit 1
fi

# Rendre les scripts exécutables
echo -e "${BLUE}⚙️ Configuration des scripts...${NC}"
chmod +x "$SCRIPT_DIR/startup_sama_conai_complete.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
echo -e "${GREEN}✅ Scripts configurés${NC}"

echo ""
echo -e "${GREEN}🎉 Configuration terminée !${NC}"
echo ""
echo -e "${BLUE}Commandes disponibles:${NC}"
echo -e "${YELLOW}  ./startup_sama_conai_complete.sh${NC}        # Démarrer tout le stack"
echo -e "${YELLOW}  ./startup_sama_conai_complete.sh stop${NC}   # Arrêter les services"
echo -e "${YELLOW}  ./startup_sama_conai_complete.sh status${NC} # Voir le statut"
echo -e "${YELLOW}  ./startup_sama_conai_complete.sh help${NC}   # Aide complète"
echo ""
echo -e "${GREEN}🚀 Prêt à démarrer SAMA CONAI !${NC}"