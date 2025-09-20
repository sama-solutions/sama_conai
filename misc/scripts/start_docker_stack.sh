#!/bin/bash

# ========================================
# SAMA CONAI - DÉMARRAGE DOCKER STACK
# ========================================
# Script de démarrage avec Docker Compose
# Version: 1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

print_banner() {
    echo ""
    echo -e "${PURPLE}${BOLD}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║           SAMA CONAI DOCKER STACK             ║${NC}"
    echo -e "${PURPLE}${BOLD}║        Démarrage avec Docker Compose          ║${NC}"
    echo -e "${PURPLE}${BOLD}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

check_docker() {
    print_info "Vérification de Docker..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé"
        echo "Installez Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose n'est pas installé"
        echo "Installez Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker n'est pas en cours d'exécution"
        echo "Démarrez Docker et réessayez"
        exit 1
    fi
    
    print_status "Docker et Docker Compose sont disponibles"
}

create_mobile_dockerfile() {
    if [ ! -f "$SCRIPT_DIR/mobile_app_web/Dockerfile" ]; then
        print_info "Création du Dockerfile pour l'application mobile web..."
        
        cat > "$SCRIPT_DIR/mobile_app_web/Dockerfile" << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copier les fichiers de configuration
COPY package*.json ./

# Installer les dépendances
RUN npm ci --only=production

# Copier le code source
COPY . .

# Exposer le port
EXPOSE 3001

# Variables d'environnement par défaut
ENV PORT=3001
ENV NODE_ENV=production

# Commande de démarrage
CMD ["npm", "start"]
EOF
        
        print_status "Dockerfile créé pour l'application mobile web"
    fi
}

create_nginx_config() {
    mkdir -p "$SCRIPT_DIR/nginx"
    
    if [ ! -f "$SCRIPT_DIR/nginx/nginx.conf" ]; then
        print_info "Création de la configuration Nginx..."
        
        cat > "$SCRIPT_DIR/nginx/nginx.conf" << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream odoo {
        server odoo:8069;
    }
    
    upstream mobile_web {
        server mobile_web:3001;
    }
    
    server {
        listen 80;
        server_name localhost;
        
        # Redirection vers HTTPS (optionnel)
        # return 301 https://$server_name$request_uri;
        
        # Odoo backend
        location / {
            proxy_pass http://odoo;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Application mobile web
        location /mobile {
            rewrite ^/mobile(.*) $1 break;
            proxy_pass http://mobile_web;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
        
        print_status "Configuration Nginx créée"
    fi
}

start_stack() {
    local action="${1:-up}"
    
    case "$action" in
        "up"|"start")
            print_info "Démarrage du stack Docker..."
            docker-compose -f docker-compose-complete.yml up -d
            
            print_info "Attente du démarrage des services..."
            sleep 10
            
            # Vérifier le statut des services
            print_info "Vérification du statut des services..."
            docker-compose -f docker-compose-complete.yml ps
            
            echo ""
            print_status "🎉 Stack Docker démarré avec succès !"
            echo ""
            echo -e "${GREEN}${BOLD}🌐 ACCÈS AUX SERVICES:${NC}"
            echo -e "${BLUE}   📊 Odoo:${NC} http://localhost:8069"
            echo -e "${BLUE}   📱 Mobile Web:${NC} http://localhost:3001"
            echo -e "${BLUE}   🗄️ PostgreSQL:${NC} localhost:5432"
            echo -e "${BLUE}   🔄 Redis:${NC} localhost:6379"
            echo ""
            echo -e "${GREEN}${BOLD}🔑 CONNEXION:${NC}"
            echo -e "${BLUE}   👤 Utilisateur:${NC} admin"
            echo -e "${BLUE}   🔐 Mot de passe:${NC} admin"
            echo ""
            ;;
        "down"|"stop")
            print_info "Arrêt du stack Docker..."
            docker-compose -f docker-compose-complete.yml down
            print_status "Stack Docker arrêté"
            ;;
        "restart")
            print_info "Redémarrage du stack Docker..."
            docker-compose -f docker-compose-complete.yml restart
            print_status "Stack Docker redémarré"
            ;;
        "logs")
            docker-compose -f docker-compose-complete.yml logs -f
            ;;
        "status")
            print_info "Statut du stack Docker:"
            docker-compose -f docker-compose-complete.yml ps
            ;;
        "clean")
            print_warning "Nettoyage complet (suppression des volumes)..."
            read -p "Êtes-vous sûr ? (y/N): " confirm
            if [[ $confirm == [yY] ]]; then
                docker-compose -f docker-compose-complete.yml down -v
                docker system prune -f
                print_status "Nettoyage terminé"
            else
                print_info "Nettoyage annulé"
            fi
            ;;
        *)
            print_error "Action inconnue: $action"
            echo "Actions disponibles: up, down, restart, logs, status, clean"
            exit 1
            ;;
    esac
}

show_help() {
    print_banner
    echo -e "${BLUE}${BOLD}USAGE:${NC} $0 [ACTION]"
    echo ""
    echo -e "${BLUE}${BOLD}ACTIONS:${NC}"
    echo -e "${GREEN}  up, start${NC}    Démarrer le stack (défaut)"
    echo -e "${GREEN}  down, stop${NC}   Arrêter le stack"
    echo -e "${GREEN}  restart${NC}      Redémarrer le stack"
    echo -e "${GREEN}  logs${NC}         Afficher les logs en temps réel"
    echo -e "${GREEN}  status${NC}       Afficher le statut des conteneurs"
    echo -e "${GREEN}  clean${NC}        Nettoyage complet (supprime les données)"
    echo -e "${GREEN}  help${NC}         Afficher cette aide"
    echo ""
    echo -e "${BLUE}${BOLD}EXEMPLES:${NC}"
    echo -e "${GREEN}  $0${NC}           # Démarrer le stack"
    echo -e "${GREEN}  $0 up${NC}        # Démarrer le stack"
    echo -e "${GREEN}  $0 down${NC}      # Arrêter le stack"
    echo -e "${GREEN}  $0 logs${NC}      # Voir les logs"
    echo ""
}

main() {
    local action="${1:-up}"
    
    if [[ "$action" == "help" || "$action" == "-h" || "$action" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    print_banner
    
    # Vérifications
    check_docker
    create_mobile_dockerfile
    create_nginx_config
    
    # Exécuter l'action
    start_stack "$action"
}

# Vérifier que le script est dans le bon répertoire
if [ ! -f "$SCRIPT_DIR/__manifest__.py" ]; then
    print_error "Ce script doit être exécuté depuis le répertoire du module SAMA CONAI"
    exit 1
fi

# Exécuter la fonction principale
main "$@"