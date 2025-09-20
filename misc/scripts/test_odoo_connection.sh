#!/bin/bash

# ========================================
# SAMA CONAI - TEST CONNEXION ODOO
# ========================================
# Script pour tester la connexion aux données réelles d'Odoo
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

echo -e "${PURPLE}${BOLD}🔗 SAMA CONAI - Test Connexion Odoo${NC}"
echo "===================================="
echo ""

# Vérifier Odoo
echo -e "${BLUE}🔍 1. Vérification d'Odoo...${NC}"

ODOO_PORT=""
if curl -s --connect-timeout 5 "http://localhost:8077" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Odoo accessible sur le port 8077${NC}"
    ODOO_PORT="8077"
elif curl -s --connect-timeout 5 "http://localhost:8069" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Odoo accessible sur le port 8069${NC}"
    ODOO_PORT="8069"
else
    echo -e "${RED}❌ Odoo non accessible${NC}"
    echo -e "${YELLOW}💡 Démarrez Odoo avec: ./startup_sama_conai_stack.sh${NC}"
    exit 1
fi

# Vérifier PostgreSQL
if pgrep -x "postgres" > /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL en cours d'exécution${NC}"
else
    echo -e "${RED}❌ PostgreSQL non en cours d'exécution${NC}"
    exit 1
fi

# Vérifier la base de données
if PGPASSWORD="odoo" psql -h localhost -U odoo -lqt | cut -d \| -f 1 | grep -qw "sama_conai_test"; then
    echo -e "${GREEN}✅ Base de données sama_conai_test existe${NC}"
else
    echo -e "${RED}❌ Base de données sama_conai_test non trouvée${NC}"
    exit 1
fi

echo ""

# Test de l'API Odoo
echo -e "${BLUE}🧪 2. Test de l'API Odoo...${NC}"

# Test d'authentification
echo -e "${BLUE}🔐 Test d'authentification...${NC}"
auth_response=$(curl -s -X POST "http://localhost:$ODOO_PORT/web/session/authenticate" \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
            "db": "sama_conai_test",
            "login": "admin",
            "password": "admin"
        }
    }')

if echo "$auth_response" | grep -q '"uid"'; then
    echo -e "${GREEN}✅ Authentification Odoo réussie${NC}"
    
    # Extraire l'UID et session_id
    uid=$(echo "$auth_response" | grep -o '"uid":[0-9]*' | cut -d':' -f2)
    session_id=$(echo "$auth_response" | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
    
    echo -e "${WHITE}   UID: $uid${NC}"
    echo -e "${WHITE}   Session: ${session_id:0:20}...${NC}"
else
    echo -e "${RED}❌ Authentification Odoo échouée${NC}"
    echo -e "${YELLOW}Réponse: $auth_response${NC}"
    exit 1
fi

echo ""

# Test des modèles SAMA CONAI
echo -e "${BLUE}📊 3. Test des modèles SAMA CONAI...${NC}"

# Test modèle request.information
echo -e "${BLUE}📋 Test modèle request.information...${NC}"
requests_response=$(curl -s -X POST "http://localhost:$ODOO_PORT/web/dataset/search_count" \
    -H "Content-Type: application/json" \
    -H "Cookie: session_id=$session_id" \
    -d '{
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
            "model": "request.information",
            "domain": []
        }
    }')

if echo "$requests_response" | grep -q '"result"'; then
    requests_count=$(echo "$requests_response" | grep -o '"result":[0-9]*' | cut -d':' -f2)
    echo -e "${GREEN}✅ Modèle request.information accessible${NC}"
    echo -e "${WHITE}   Nombre de demandes: $requests_count${NC}"
else
    echo -e "${RED}❌ Modèle request.information non accessible${NC}"
    echo -e "${YELLOW}Réponse: $requests_response${NC}"
fi

# Test modèle whistleblowing.alert
echo -e "${BLUE}🚨 Test modèle whistleblowing.alert...${NC}"
alerts_response=$(curl -s -X POST "http://localhost:$ODOO_PORT/web/dataset/search_count" \
    -H "Content-Type: application/json" \
    -H "Cookie: session_id=$session_id" \
    -d '{
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
            "model": "whistleblowing.alert",
            "domain": []
        }
    }')

if echo "$alerts_response" | grep -q '"result"'; then
    alerts_count=$(echo "$alerts_response" | grep -o '"result":[0-9]*' | cut -d':' -f2)
    echo -e "${GREEN}✅ Modèle whistleblowing.alert accessible${NC}"
    echo -e "${WHITE}   Nombre d'alertes: $alerts_count${NC}"
else
    echo -e "${RED}❌ Modèle whistleblowing.alert non accessible${NC}"
    echo -e "${YELLOW}Réponse: $alerts_response${NC}"
fi

# Test modèle res.users
echo -e "${BLUE}👤 Test modèle res.users...${NC}"
users_response=$(curl -s -X POST "http://localhost:$ODOO_PORT/web/dataset/search_count" \
    -H "Content-Type: application/json" \
    -H "Cookie: session_id=$session_id" \
    -d '{
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
            "model": "res.users",
            "domain": []
        }
    }')

if echo "$users_response" | grep -q '"result"'; then
    users_count=$(echo "$users_response" | grep -o '"result":[0-9]*' | cut -d':' -f2)
    echo -e "${GREEN}✅ Modèle res.users accessible${NC}"
    echo -e "${WHITE}   Nombre d'utilisateurs: $users_count${NC}"
else
    echo -e "${RED}❌ Modèle res.users non accessible${NC}"
fi

echo ""

# Test de récupération de données
echo -e "${BLUE}📄 4. Test de récupération de données...${NC}"

# Récupérer quelques demandes
echo -e "${BLUE}📋 Récupération des demandes récentes...${NC}"
recent_requests=$(curl -s -X POST "http://localhost:$ODOO_PORT/web/dataset/search_read" \
    -H "Content-Type: application/json" \
    -H "Cookie: session_id=$session_id" \
    -d '{
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
            "model": "request.information",
            "domain": [],
            "fields": ["name", "description", "partner_name", "state", "request_date"],
            "limit": 3,
            "sort": "id desc"
        }
    }')

if echo "$recent_requests" | grep -q '"records"'; then
    echo -e "${GREEN}✅ Récupération des demandes réussie${NC}"
    
    # Afficher les demandes
    echo -e "${WHITE}   Demandes récentes:${NC}"
    echo "$recent_requests" | grep -o '"name":"[^"]*"' | head -3 | while read line; do
        name=$(echo "$line" | cut -d'"' -f4)
        echo -e "${WHITE}   - $name${NC}"
    done
else
    echo -e "${YELLOW}⚠️ Aucune demande trouvée ou erreur de récupération${NC}"
fi

echo ""

# Test de l'application mobile
echo -e "${BLUE}📱 5. Test de l'application mobile...${NC}"

if pgrep -f "node.*server.js" > /dev/null; then
    echo -e "${GREEN}✅ Application mobile en cours d'exécution${NC}"
    
    if curl -s --connect-timeout 5 "http://localhost:3005" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Application mobile accessible${NC}"
        
        # Test de l'API mobile
        echo -e "${BLUE}🔗 Test de l'API mobile avec données Odoo...${NC}"
        
        mobile_login=$(curl -s -X POST "http://localhost:3005/api/mobile/auth/login" \
            -H "Content-Type: application/json" \
            -d '{"email":"admin","password":"admin"}')
        
        if echo "$mobile_login" | grep -q '"success":true'; then
            echo -e "${GREEN}✅ Connexion API mobile réussie${NC}"
            
            # Extraire le token
            mobile_token=$(echo "$mobile_login" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
            
            if [ ! -z "$mobile_token" ]; then
                # Test du dashboard
                mobile_dashboard=$(curl -s "http://localhost:3005/api/mobile/citizen/dashboard" \
                    -H "Authorization: Bearer $mobile_token")
                
                if echo "$mobile_dashboard" | grep -q '"source":"odoo_real_data"'; then
                    echo -e "${GREEN}✅ Dashboard avec données réelles Odoo${NC}"
                elif echo "$mobile_dashboard" | grep -q '"requireOdoo":true'; then
                    echo -e "${YELLOW}⚠️ API mobile configurée pour Odoo mais connexion échouée${NC}"
                else
                    echo -e "${BLUE}ℹ️ API mobile utilise les données de démo${NC}"
                fi
            fi
        else
            echo -e "${RED}❌ Connexion API mobile échouée${NC}"
        fi
    else
        echo -e "${RED}❌ Application mobile non accessible${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Application mobile non en cours d'exécution${NC}"
    echo -e "${WHITE}   Démarrez avec: cd mobile_app_web && npm start${NC}"
fi

echo ""

# Résumé
echo -e "${PURPLE}${BOLD}📋 RÉSUMÉ DU TEST${NC}"
echo "=================="
echo ""

if [ ! -z "$requests_count" ] && [ "$requests_count" -gt 0 ]; then
    echo -e "${GREEN}✅ Connexion Odoo opérationnelle${NC}"
    echo -e "${WHITE}   📊 $requests_count demandes d'information${NC}"
    echo -e "${WHITE}   🚨 $alerts_count alertes de signalement${NC}"
    echo -e "${WHITE}   👤 $users_count utilisateurs${NC}"
    echo ""
    echo -e "${BLUE}${BOLD}🚀 Pour utiliser les données réelles:${NC}"
    echo -e "${WHITE}   ./switch_to_odoo_real_data.sh${NC}"
else
    echo -e "${YELLOW}⚠️ Connexion Odoo limitée ou pas de données${NC}"
    echo ""
    echo -e "${BLUE}${BOLD}💡 Actions recommandées:${NC}"
    echo -e "${WHITE}   1. Vérifiez que le module SAMA CONAI est installé${NC}"
    echo -e "${WHITE}   2. Créez quelques demandes de test dans Odoo${NC}"
    echo -e "${WHITE}   3. Redémarrez l'application mobile${NC}"
fi

echo ""
echo -e "${GREEN}🇸🇳 Test de connexion Odoo terminé !${NC}"