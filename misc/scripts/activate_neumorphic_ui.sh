#!/bin/bash

# ========================================
# SAMA CONAI - ACTIVATION INTERFACE NEUMORPHIQUE
# ========================================
# Script pour activer la nouvelle interface neumorphique
# Version: 1.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${PURPLE}${BOLD}🎨 SAMA CONAI - Activation Interface Neumorphique${NC}"
echo "=================================================="
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "$SCRIPT_DIR/__manifest__.py" ]; then
    echo -e "${RED}❌ Erreur: Ce script doit être exécuté depuis le répertoire du module SAMA CONAI${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Étapes d'activation:${NC}"
echo "1. Vérification des fichiers neumorphiques"
echo "2. Mise à jour du module Odoo"
echo "3. Redémarrage des services"
echo "4. Test de l'interface"
echo ""

# Étape 1: Vérification des fichiers
echo -e "${BLUE}🔍 1. Vérification des fichiers neumorphiques...${NC}"

required_files=(
    "static/src/css/base_styles.css"
    "static/src/css/themes/theme_institutionnel.css"
    "static/src/css/themes/theme_terre.css"
    "static/src/css/themes/theme_moderne.css"
    "static/src/js/theme_switcher.js"
    "static/src/js/dashboard_client_action.js"
    "views/dashboard_neumorphic_views.xml"
    "templates/dashboard/sama_conai_dashboard_neumorphic.xml"
    "controllers/dashboard_controller.py"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file${NC}"
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -ne 0 ]; then
    echo -e "${RED}❌ Fichiers manquants détectés. L'interface neumorphique ne peut pas être activée.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Tous les fichiers neumorphiques sont présents${NC}"
echo ""

# Étape 2: Mise à jour du module
echo -e "${BLUE}🔄 2. Mise à jour du module SAMA CONAI...${NC}"

# Vérifier si Odoo est en cours d'exécution
if pgrep -f "odoo-bin" > /dev/null; then
    echo -e "${YELLOW}⚠️ Odoo est en cours d'exécution. Arrêt nécessaire pour la mise à jour.${NC}"
    
    read -p "Voulez-vous arrêter Odoo pour effectuer la mise à jour ? (y/N): " choice
    if [[ $choice == [yY] ]]; then
        echo -e "${BLUE}🛑 Arrêt d'Odoo...${NC}"
        pkill -f "odoo-bin" || true
        sleep 3
    else
        echo -e "${YELLOW}⚠️ Mise à jour annulée. Redémarrez Odoo manuellement après avoir arrêté le service.${NC}"
        exit 1
    fi
fi

# Activer l'environnement virtuel et mettre à jour le module
echo -e "${BLUE}📦 Mise à jour du module avec l'environnement virtuel...${NC}"

if [ -f "/home/grand-as/odoo18-venv/bin/activate" ]; then
    source /home/grand-as/odoo18-venv/bin/activate
    echo -e "${GREEN}✅ Environnement virtuel activé${NC}"
else
    echo -e "${YELLOW}⚠️ Environnement virtuel non trouvé, utilisation de Python système${NC}"
fi

# Commande de mise à jour
cd /var/odoo/odoo18

echo -e "${BLUE}🔧 Exécution de la mise à jour du module...${NC}"
python3 odoo-bin \
    -d sama_conai_test \
    --addons-path="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons" \
    --db_host=localhost \
    --db_user=odoo \
    --db_password=odoo \
    -u sama_conai \
    --stop-after-init

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Module mis à jour avec succès${NC}"
else
    echo -e "${RED}❌ Erreur lors de la mise à jour du module${NC}"
    exit 1
fi

cd "$SCRIPT_DIR"
echo ""

# Étape 3: Redémarrage des services
echo -e "${BLUE}🚀 3. Redémarrage des services...${NC}"

# Utiliser le script de démarrage existant si disponible
if [ -f "$SCRIPT_DIR/startup_sama_conai_stack.sh" ]; then
    echo -e "${BLUE}📱 Démarrage avec le script unifié...${NC}"
    nohup "$SCRIPT_DIR/startup_sama_conai_stack.sh" > "$SCRIPT_DIR/logs/neumorphic_activation.log" 2>&1 &
    STARTUP_PID=$!
    echo -e "${GREEN}✅ Services démarrés en arrière-plan (PID: $STARTUP_PID)${NC}"
    
    # Attendre que les services soient prêts
    echo -e "${BLUE}⏳ Attente du démarrage des services (60 secondes)...${NC}"
    sleep 60
    
elif [ -f "$SCRIPT_DIR/start_sama_conai.sh" ]; then
    echo -e "${BLUE}🔧 Démarrage d'Odoo avec le script existant...${NC}"
    nohup "$SCRIPT_DIR/start_sama_conai.sh" > "$SCRIPT_DIR/logs/odoo_neumorphic.log" 2>&1 &
    ODOO_PID=$!
    echo -e "${GREEN}✅ Odoo démarré en arrière-plan (PID: $ODOO_PID)${NC}"
    
    # Attendre qu'Odoo soit prêt
    echo -e "${BLUE}⏳ Attente du démarrage d'Odoo (60 secondes)...${NC}"
    sleep 60
    
else
    echo -e "${YELLOW}⚠️ Aucun script de démarrage trouvé. Démarrez Odoo manuellement.${NC}"
fi

echo ""

# Étape 4: Test de l'interface
echo -e "${BLUE}🧪 4. Test de l'interface neumorphique...${NC}"

# Tester l'accès à Odoo
if curl -s --connect-timeout 10 "http://localhost:8077" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Odoo accessible sur http://localhost:8077${NC}"
    
    # Tester l'accès au dashboard neumorphique
    if curl -s --connect-timeout 10 "http://localhost:8077/sama_conai/dashboard" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Dashboard neumorphique accessible${NC}"
    else
        echo -e "${YELLOW}⚠️ Dashboard neumorphique non accessible (authentification requise)${NC}"
    fi
    
elif curl -s --connect-timeout 10 "http://localhost:8069" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Odoo accessible sur http://localhost:8069${NC}"
    
    # Tester l'accès au dashboard neumorphique
    if curl -s --connect-timeout 10 "http://localhost:8069/sama_conai/dashboard" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Dashboard neumorphique accessible${NC}"
    else
        echo -e "${YELLOW}⚠️ Dashboard neumorphique non accessible (authentification requise)${NC}"
    fi
    
else
    echo -e "${RED}❌ Odoo non accessible. Vérifiez les logs.${NC}"
fi

echo ""

# Résumé final
echo -e "${PURPLE}${BOLD}🎉 ACTIVATION TERMINÉE !${NC}"
echo "========================"
echo ""
echo -e "${GREEN}${BOLD}🌐 Accès à l'interface neumorphique:${NC}"
echo ""
echo -e "${WHITE}1. Connectez-vous à Odoo:${NC}"
echo -e "${CYAN}   http://localhost:8077${NC} (ou http://localhost:8069)"
echo -e "${WHITE}   Identifiants: admin / admin${NC}"
echo ""
echo -e "${WHITE}2. Accédez au nouveau dashboard:${NC}"
echo -e "${CYAN}   Menu → Analytics & Rapports → Tableaux de Bord → Tableau de Bord Principal${NC}"
echo ""
echo -e "${WHITE}3. Ou directement via l'URL:${NC}"
echo -e "${CYAN}   http://localhost:8077/sama_conai/dashboard${NC}"
echo ""
echo -e "${WHITE}4. Changez de thème:${NC}"
echo -e "${CYAN}   Cliquez sur l'icône utilisateur → Préférences → Préférences d'Interface SAMA CONAI${NC}"
echo ""

echo -e "${BLUE}${BOLD}🎨 Thèmes disponibles:${NC}"
echo -e "${WHITE}   • Thème Institutionnel (par défaut)${NC}"
echo -e "${WHITE}   • Thème Terre du Sénégal${NC}"
echo -e "${WHITE}   • Thème Moderne${NC}"
echo ""

echo -e "${BLUE}${BOLD}📱 Application mobile:${NC}"
if [ -f "$SCRIPT_DIR/start_mobile_final.sh" ]; then
    echo -e "${WHITE}   Démarrez avec: ./start_mobile_final.sh${NC}"
    echo -e "${WHITE}   Accès: http://localhost:3005${NC}"
else
    echo -e "${YELLOW}   Script mobile non trouvé${NC}"
fi
echo ""

echo -e "${BLUE}${BOLD}📋 Logs:${NC}"
if [ -f "$SCRIPT_DIR/logs/neumorphic_activation.log" ]; then
    echo -e "${WHITE}   Activation: tail -f logs/neumorphic_activation.log${NC}"
fi
if [ -f "$SCRIPT_DIR/logs/odoo_neumorphic.log" ]; then
    echo -e "${WHITE}   Odoo: tail -f logs/odoo_neumorphic.log${NC}"
fi
echo ""

echo -e "${GREEN}🇸🇳 Interface neumorphique SAMA CONAI activée avec succès !${NC}"