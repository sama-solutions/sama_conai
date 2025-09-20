#!/bin/bash

# Script de démarrage SAMA CONAI pour base existante
# Version: 2.5 - Gestion base existante

echo "🚀 SAMA CONAI v2.5 - DÉMARRAGE BASE EXISTANTE"
echo "=============================================="

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
echo "   🗄️ Base: $DB_NAME (existante)"
echo "   📦 Module: SAMA CONAI avec Analytics"
echo ""

# Fonction pour nettoyer les processus existants
cleanup_processes() {
    echo "🧹 Nettoyage des processus existants..."
    
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
    
    # Arrêter les processus sur le port
    PIDS=$(ps aux | grep "[p]ython.*odoo.*$PORT" | awk '{print $2}')
    
    if [ ! -z "$PIDS" ]; then
        echo "   🛑 Arrêt des processus Odoo sur le port $PORT..."
        for PID in $PIDS; do
            kill -TERM $PID 2>/dev/null
            sleep 2
            if kill -0 $PID 2>/dev/null; then
                kill -KILL $PID 2>/dev/null
            fi
        done
        echo "   ✅ Processus arrêtés"
    fi
    
    # Nettoyer les anciens logs
    if [ -f "$LOG_FILE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        echo "   ✅ Ancien log sauvegardé"
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

# Fonction pour vérifier la base de données
check_database() {
    echo "🗄️ Vérification de la base de données..."
    
    export PGPASSWORD=odoo
    
    # Vérifier la connexion PostgreSQL
    if ! psql -h localhost -U odoo -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        echo "   ❌ Connexion PostgreSQL échouée"
        return 1
    fi
    
    # Vérifier si la base existe
    if psql -h localhost -U odoo -lqt | cut -d '|' -f 1 | grep -qw "$DB_NAME"; then
        echo "   ✅ Base $DB_NAME trouvée"
        
        # Vérifier si le module est installé
        if psql -h localhost -U odoo -d "$DB_NAME" -c "SELECT name FROM ir_module_module WHERE name='sama_conai' AND state='installed';" | grep -q sama_conai; then
            echo "   ✅ Module sama_conai installé"
            return 0  # Base existante avec module
        else
            echo "   ⚠️ Module sama_conai non installé dans la base"
            return 1  # Base existante sans module
        fi
    else
        echo "   ❌ Base $DB_NAME non trouvée"
        return 2  # Base inexistante
    fi
}

# Fonction pour démarrer Odoo
start_odoo() {
    local action=$1  # "update" ou "run"
    
    echo "🚀 Démarrage d'Odoo..."
    
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
    
    if [ "$action" = "update" ]; then
        echo "   🔄 Mise à jour du module sama_conai..."
        python3 odoo-bin "${COMMON_PARAMS[@]}" -u sama_conai --stop-after-init
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Mise à jour terminée"
        else
            echo "   ❌ Erreur lors de la mise à jour"
            echo "   📋 Logs: tail -f $LOG_FILE"
            return 1
        fi
    elif [ "$action" = "install" ]; then
        echo "   📦 Installation du module sama_conai..."
        python3 odoo-bin "${COMMON_PARAMS[@]}" -i sama_conai --stop-after-init
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Installation terminée"
        else
            echo "   ❌ Erreur lors de l'installation"
            echo "   📋 Logs: tail -f $LOG_FILE"
            return 1
        fi
    fi
    
    # Démarrage du serveur
    echo "   🌐 Démarrage du serveur web..."
    python3 odoo-bin "${COMMON_PARAMS[@]}" &
    
    SERVER_PID=$!
    echo "   🎯 Serveur démarré (PID: $SERVER_PID)"
    
    # Attendre que le serveur soit prêt
    echo "   ⏳ Attente du démarrage complet..."
    local timeout=60
    local count=0
    
    while [ $count -lt $timeout ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ | grep -q "200\\|303"; then
            echo ""
            echo "   ✅ Serveur accessible"
            return 0
        fi
        sleep 2
        count=$((count + 2))
        echo -n "."
    done
    
    echo ""
    echo "   ⚠️ Timeout atteint, mais le serveur peut encore démarrer"
    echo "   📋 Vérifiez les logs: tail -f $LOG_FILE"
    return 0
}

# Fonction pour afficher les informations
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
    echo "📊 **FONCTIONNALITÉS DISPONIBLES**"
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
    echo "   📊 Analytics & Rapports"
    echo "      ├── Tableaux de Bord"
    echo "      └── Générateurs de Rapports"
    echo ""
    echo "🔧 **GESTION**"
    echo "   📋 Logs: tail -f $LOG_FILE"
    echo "   🛑 Arrêt: kill \\$(cat $PID_FILE)"
    echo "   📊 Statut: ps aux | grep \\$(cat $PID_FILE)"
    echo ""
    echo "✅ **MENUS NETTOYÉS**"
    echo "   🧹 Doublons éliminés"
    echo "   📋 Structure organisée"
    echo "   🎯 Navigation optimisée"
    echo ""
}

# Fonction principale
main() {
    # Nettoyer les processus existants
    cleanup_processes
    
    # Activer l'environnement virtuel
    activate_venv
    
    # Vérifier la base de données
    check_database
    db_status=$?
    
    case $db_status in
        0)
            echo "   🔄 Base existante avec module installé - Mise à jour"
            start_odoo "update"
            ;;
        1)
            echo "   📦 Base existante sans module - Installation"
            start_odoo "install"
            ;;
        2)
            echo "   ❌ Base inexistante - Utilisez le script de création"
            echo "   💡 Suggestion: Supprimez la base et relancez le script principal"
            echo "   🗑️ Commande: dropdb -h localhost -U odoo $DB_NAME"
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
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

# Gestion des signaux
cleanup_on_exit() {
    echo ""
    echo "🛑 Arrêt demandé..."
    if [ -f "$PID_FILE" ] && [ -s "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill -TERM "$PID" 2>/dev/null
            sleep 3
            if kill -0 "$PID" 2>/dev/null; then
                kill -KILL "$PID" 2>/dev/null
            fi
        fi
        rm -f "$PID_FILE"
    fi
    echo "✅ Nettoyage terminé"
    exit 0
}

trap cleanup_on_exit INT TERM

# Lancer le script
main "$@"