#!/bin/bash

# Script de démarrage SAMA CONAI en arrière-plan
# Version: 2.5 - Démarrage en daemon

echo "🚀 SAMA CONAI v2.5 - DÉMARRAGE EN ARRIÈRE-PLAN"
echo "==============================================="

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
    else
        echo "   ⚠️ Environnement virtuel non trouvé, utilisation de Python système"
    fi
}

# Fonction pour démarrer Odoo en arrière-plan
start_odoo_daemon() {
    echo "🚀 Démarrage d'Odoo en arrière-plan..."
    
    cd "$ODOO_PATH" || {
        echo "   ❌ Impossible d'accéder au répertoire Odoo"
        return 1
    }
    
    # Mise à jour du module d'abord
    echo "   🔄 Mise à jour du module sama_conai..."
    python3 odoo-bin \
        -d "$DB_NAME" \
        --addons-path="$ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --http-port="$PORT" \
        --log-level=info \
        --logfile="$LOG_FILE" \
        -u sama_conai \
        --stop-after-init
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Mise à jour terminée"
    else
        echo "   ❌ Erreur lors de la mise à jour"
        return 1
    fi
    
    # Démarrage du serveur en daemon
    echo "   🌐 Démarrage du serveur en daemon..."
    
    nohup python3 odoo-bin \
        -d "$DB_NAME" \
        --addons-path="$ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --http-port="$PORT" \
        --log-level=info \
        --logfile="$LOG_FILE" \
        --pidfile="$PID_FILE" \
        > /dev/null 2>&1 &
    
    SERVER_PID=$!
    echo "   🎯 Serveur démarré en arrière-plan (PID: $SERVER_PID)"
    
    # Attendre que le serveur soit prêt
    echo "   ⏳ Attente du démarrage complet..."
    local timeout=30
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
    echo "   ⚠️ Timeout atteint, mais le serveur peut encore démarrer"
    echo "   📋 Vérifiez les logs: tail -f $LOG_FILE"
    return 0
}

# Fonction pour vérifier le statut
check_status() {
    echo ""
    echo "📊 VÉRIFICATION DU STATUT"
    echo "========================"
    
    # Vérifier le processus
    if [ -f "$PID_FILE" ] && [ -s "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "   ✅ Processus actif (PID: $PID)"
        else
            echo "   ❌ Processus non trouvé (PID: $PID)"
            return 1
        fi
    else
        echo "   ❌ Fichier PID non trouvé"
        return 1
    fi
    
    # Vérifier la connectivité
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ | grep -q "200\\|303"; then
        echo "   ✅ Serveur accessible sur http://localhost:$PORT"
    else
        echo "   ❌ Serveur non accessible"
        return 1
    fi
    
    return 0
}

# Fonction pour afficher les informations
show_info() {
    echo ""
    echo "🎉 SAMA CONAI v2.5 DÉMARRÉ EN ARRIÈRE-PLAN !"
    echo "============================================="
    echo ""
    echo "🌐 **ACCÈS AU SYSTÈME**"
    echo "   URL: http://localhost:$PORT"
    echo "   👤 Login: admin"
    echo "   🔑 Password: admin"
    echo ""
    echo "📊 **FONCTIONNALITÉS DISPONIBLES**"
    echo "   📄 Accès à l'Information (menus nettoyés)"
    echo "   🚨 Signalement d'Alerte (menus nettoyés)"
    echo "   📊 Analytics & Rapports (nouveau)"
    echo "   ⚙️ Administration Transparence"
    echo ""
    echo "🔧 **GESTION DU SERVEUR**"
    echo "   📋 Logs: tail -f $LOG_FILE"
    echo "   🛑 Arrêt: kill \\$(cat $PID_FILE)"
    echo "   📊 Statut: python3 verify_sama_conai_running.py"
    echo "   🔄 Redémarrage: $0"
    echo ""
    echo "✅ **MENUS NETTOYÉS ET OPTIMISÉS**"
    echo "   🧹 Doublons éliminés"
    echo "   📋 Structure réorganisée"
    echo "   🎯 Navigation claire et intuitive"
    echo ""
}

# Fonction principale
main() {
    # Nettoyer les processus existants
    cleanup_processes
    
    # Activer l'environnement virtuel
    activate_venv
    
    # Démarrer Odoo en daemon
    if start_odoo_daemon; then
        # Vérifier le statut
        sleep 5  # Laisser le temps au serveur de démarrer
        
        if check_status; then
            show_info
            
            echo "💡 **RECOMMANDATIONS**"
            echo "   1. Testez l'accès: http://localhost:$PORT"
            echo "   2. Vérifiez les menus (plus de doublons)"
            echo "   3. Surveillez les logs si nécessaire"
            echo ""
            echo "🎯 **LE SERVEUR FONCTIONNE EN ARRIÈRE-PLAN**"
            echo "   Vous pouvez fermer ce terminal en toute sécurité"
        else
            echo "❌ Problème de démarrage détecté"
            echo "📋 Consultez les logs: tail -f $LOG_FILE"
            exit 1
        fi
    else
        echo "❌ Échec du démarrage"
        exit 1
    fi
}

# Lancer le script
main "$@"