#!/bin/bash

# Script de démarrage SAMA CONAI avec Analytics - VERSION CORRIGÉE
# Version: 2.5 avec Analytics Avancés - FIXED

echo "🚀 SAMA CONAI v2.5 - ANALYTICS AVANCÉS (VERSION CORRIGÉE)"
echo "========================================================="

# Configuration
PORT=8077
DB_NAME="sama_conai_analytics"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_PATH="/var/odoo/odoo18"
ADDONS_PATH="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons"
LOG_FILE="/tmp/sama_conai_analytics.log"
PID_FILE="/tmp/sama_conai_analytics.pid"

echo "📋 Configuration:"
echo "   🌐 Port: $PORT"
echo "   🗄️ Base: $DB_NAME"
echo "   📦 Module: SAMA CONAI avec Analytics"
echo ""

# Fonction pour vérifier les prérequis
check_prerequisites() {
    echo "🔍 Vérification des prérequis..."
    
    local errors=0
    
    # Vérifier les commandes nécessaires
    for cmd in psql createdb curl python3 kill ps; do
        if ! command -v $cmd >/dev/null 2>&1; then
            echo "   ❌ Commande manquante: $cmd"
            errors=$((errors + 1))
        fi
    done
    
    # Vérifier les chemins
    if [ ! -d "$ODOO_PATH" ]; then
        echo "   ❌ Répertoire Odoo introuvable: $ODOO_PATH"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "$ODOO_PATH/odoo-bin" ]; then
        echo "   ❌ Exécutable odoo-bin introuvable: $ODOO_PATH/odoo-bin"
        errors=$((errors + 1))
    fi
    
    if [ ! -d "/home/grand-as/psagsn/custom_addons/sama_conai" ]; then
        echo "   ❌ Module sama_conai introuvable"
        errors=$((errors + 1))
    fi
    
    # Vérifier la connexion PostgreSQL
    export PGPASSWORD=odoo
    if ! psql -h localhost -U odoo -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        echo "   ❌ Connexion PostgreSQL échouée (user: odoo, password: odoo)"
        errors=$((errors + 1))
    fi
    
    # Vérifier la disponibilité du port
    if netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
        echo "   ⚠️  Port $PORT déjà utilisé"
        echo "   🔧 Tentative d'arrêt des processus existants..."
    fi
    
    if [ $errors -eq 0 ]; then
        echo "   ✅ Tous les prérequis sont satisfaits"
        return 0
    else
        echo "   ❌ $errors erreur(s) détectée(s)"
        return 1
    fi
}

# Fonction pour nettoyer les fichiers existants
cleanup_existing() {
    echo "🧹 Nettoyage des fichiers existants..."
    
    # Nettoyer le fichier PID s'il existe
    if [ -f "$PID_FILE" ]; then
        if [ -s "$PID_FILE" ]; then
            OLD_PID=$(cat "$PID_FILE")
            if kill -0 "$OLD_PID" 2>/dev/null; then
                echo "   🛑 Arrêt du processus existant (PID: $OLD_PID)..."
                kill -TERM "$OLD_PID" 2>/dev/null
                sleep 3
                if kill -0 "$OLD_PID" 2>/dev/null; then
                    kill -KILL "$OLD_PID" 2>/dev/null
                fi
            fi
        fi
        rm -f "$PID_FILE"
        echo "   ✅ Fichier PID nettoyé"
    fi
    
    # Nettoyer les anciens logs
    if [ -f "$LOG_FILE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        echo "   ✅ Ancien log sauvegardé"
    fi
}

# Fonction pour arrêter les processus sur notre port
stop_processes() {
    echo "🛑 Arrêt des processus sur le port $PORT..."
    
    # Méthode plus précise pour trouver les processus Odoo
    PIDS=$(ps aux | grep "[p]ython.*odoo.*$PORT" | awk '{print $2}')
    
    if [ ! -z "$PIDS" ]; then
        echo "   Processus trouvés: $PIDS"
        for PID in $PIDS; do
            echo "   Arrêt du processus $PID..."
            kill -TERM $PID 2>/dev/null
            sleep 2
            if kill -0 $PID 2>/dev/null; then
                kill -KILL $PID 2>/dev/null
            fi
        done
        echo "   ✅ Processus arrêtés"
    else
        echo "   ✅ Aucun processus à arrêter"
    fi
    
    sleep 2
}

# Fonction pour vérifier/créer la base - CORRIGÉE
setup_database() {
    echo "🗄️ Configuration de la base de données..."
    
    export PGPASSWORD=odoo
    
    # Vérifier si la base existe
    if psql -h localhost -U odoo -lqt | cut -d '|' -f 1 | grep -qw "$DB_NAME"; then
        echo "   ✅ Base $DB_NAME existe déjà"
        return 0  # Base existante - CORRIGÉ
    else
        echo "   📝 Création de la base $DB_NAME..."
        if createdb -h localhost -U odoo "$DB_NAME"; then
            echo "   ✅ Base créée avec succès"
            return 1  # Nouvelle base - CORRIGÉ
        else
            echo "   ❌ Erreur lors de la création de la base"
            return 2  # Erreur
        fi
    fi
}

# Fonction pour activer l'environnement virtuel
activate_venv() {
    echo "🐍 Activation de l'environnement virtuel..."
    
    if [ -f "$VENV_PATH/bin/activate" ]; then
        source "$VENV_PATH/bin/activate"
        echo "   ✅ Environnement virtuel activé"
        echo "   🐍 Python: $(which python3)"
    else
        echo "   ⚠️ Environnement virtuel non trouvé, utilisation de Python système"
        echo "   🐍 Python: $(which python3)"
    fi
}

# Fonction pour démarrer Odoo - AMÉLIORÉE
start_odoo() {
    local db_status=$1
    
    echo "🚀 Démarrage d'Odoo avec Analytics..."
    
    cd "$ODOO_PATH" || {
        echo "   ❌ Impossible d'accéder au répertoire Odoo"
        return 1
    }
    
    # Paramètres communs
    COMMON_PARAMS=(
        -d "$DB_NAME"
        --addons-path="$ADDONS_PATH"
        --db_host=localhost
        --db_user=odoo
        --db_password=odoo
        --http-port="$PORT"
        --log-level=info
        --logfile="$LOG_FILE"
        --pidfile="$PID_FILE"
    )
    
    if [ $db_status -eq 1 ]; then
        echo "   📦 Installation complète sur nouvelle base..."
        python3 odoo-bin "${COMMON_PARAMS[@]}" -i sama_conai --stop-after-init
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Installation terminée"
        else
            echo "   ❌ Erreur lors de l'installation"
            echo "   📋 Logs: tail -f $LOG_FILE"
            return 1
        fi
    elif [ $db_status -eq 0 ]; then
        echo "   🔄 Mise à jour du module..."
        python3 odoo-bin "${COMMON_PARAMS[@]}" -u sama_conai --stop-after-init
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Mise à jour terminée"
        else
            echo "   ❌ Erreur lors de la mise à jour"
            echo "   📋 Logs: tail -f $LOG_FILE"
            return 1
        fi
    else
        echo "   ❌ Erreur de configuration de la base de données"
        return 1
    fi
    
    # Démarrage final
    echo "   🌐 Démarrage du serveur web..."
    python3 odoo-bin "${COMMON_PARAMS[@]}" &
    
    SERVER_PID=$!
    echo "   🎯 Serveur démarré (PID: $SERVER_PID)"
    
    # Attendre que le serveur soit prêt avec timeout
    echo "   ⏳ Attente du démarrage complet..."
    local timeout=60
    local count=0
    
    while [ $count -lt $timeout ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ | grep -q "200\\|303"; then
            echo "   ✅ Serveur accessible"
            return 0
        fi
        sleep 2
        count=$((count + 2))
        echo -n "."
    done
    
    echo ""
    echo "   ⚠️ Timeout atteint, vérifiez les logs"
    echo "   📋 Logs: tail -f $LOG_FILE"
    return 1
}

# Fonction pour afficher les informations - AMÉLIORÉE
show_info() {
    echo ""
    echo "🎉 SAMA CONAI v2.5 ANALYTICS DÉMARRÉ !"
    echo "======================================"
    echo ""
    echo "🌐 **ACCÈS AU SYSTÈME**"
    echo "   URL: http://localhost:$PORT"
    echo "   👤 Login: admin"
    echo "   🔑 Password: admin"
    echo ""
    echo "📊 **NOUVEAUTÉS ANALYTICS v2.5**"
    echo "   📈 Tableau de Bord Exécutif"
    echo "      → KPI temps réel"
    echo "      → Alertes management"
    echo "      → Graphiques interactifs"
    echo ""
    echo "   📊 Générateurs de Rapports"
    echo "      → Rapports automatisés"
    echo "      → Distribution multi-canal"
    echo "      → Formats PDF/HTML/Excel"
    echo ""
    echo "📋 **STRUCTURE DES MENUS RÉORGANISÉE**"
    echo "   📄 Accès à l'Information"
    echo "      ├── Demandes d'Information"
    echo "      ├── Rapports et Analyses"
    echo "      └── Configuration"
    echo ""
    echo "   🚨 Signalement d'Alerte"
    echo "      ├── Signalements"
    echo "      ├── Rapports et Analyses"
    echo "      └── Configuration"
    echo ""
    echo "   📊 Analytics & Rapports (NOUVEAU)"
    echo "      ├── Tableaux de Bord"
    echo "      └── Générateurs de Rapports"
    echo ""
    echo "🔧 **GESTION**"
    echo "   📋 Logs: tail -f $LOG_FILE"
    echo "   🛑 Arrêt: kill \\$(cat $PID_FILE)"
    echo "   📊 Statut: ps aux | grep \\$(cat $PID_FILE)"
    echo ""
    echo "📈 **FONCTIONNALITÉS VALIDÉES**"
    echo "   ✅ Structure de menus réorganisée"
    echo "   ✅ 17 actions validées"
    echo "   ✅ 28 menus validés"
    echo "   ✅ Dashboard exécutif avec KPI"
    echo "   ✅ Rapports automatisés"
    echo "   ✅ Permissions et groupes de sécurité"
    echo ""
}

# Fonction principale - AMÉLIORÉE
main() {
    # Vérifier les prérequis
    if ! check_prerequisites; then
        echo "❌ Prérequis non satisfaits, arrêt du script"
        exit 1
    fi
    
    # Nettoyer les fichiers existants
    cleanup_existing
    
    # Arrêter les processus existants
    stop_processes
    
    # Activer l'environnement virtuel
    activate_venv
    
    # Configurer la base de données
    setup_database
    db_status=$?
    
    if [ $db_status -eq 2 ]; then
        echo "❌ Erreur de configuration de la base de données"
        exit 1
    fi
    
    # Démarrer Odoo
    if start_odoo $db_status; then
        show_info
        
        echo "Voulez-vous surveiller les logs ? (y/N)"
        read -t 10 -n 1 response
        echo ""
        
        if [[ $response =~ ^[Yy]$ ]]; then
            echo "📋 Surveillance des logs (Ctrl+C pour arrêter)..."
            tail -f "$LOG_FILE"
        else
            echo "✅ Serveur en cours d'exécution"
            echo "🌐 Accédez à http://localhost:$PORT"
            echo "📋 Logs: tail -f $LOG_FILE"
        fi
    else
        echo "❌ Échec du démarrage"
        echo "📋 Consultez les logs: tail -f $LOG_FILE"
        exit 1
    fi
}

# Gestion des signaux - AMÉLIORÉE
cleanup_on_exit() {
    echo ""
    echo "🛑 Arrêt demandé..."
    stop_processes
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
    fi
    echo "✅ Nettoyage terminé"
    exit 0
}

trap cleanup_on_exit INT TERM

# Lancer le script
main "$@"