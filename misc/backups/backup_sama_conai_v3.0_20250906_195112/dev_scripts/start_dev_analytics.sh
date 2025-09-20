#!/bin/bash

# Script de développement pour tester les améliorations SAMA CONAI
# Port dédié: 8076

echo "🚀 DÉMARRAGE DEV - SAMA CONAI AMÉLIORATIONS"
echo "=========================================="

# Configuration
DEV_PORT=8076
DB_NAME="sama_conai_dev_analytics"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_PATH="/var/odoo/odoo18"
ADDONS_PATH="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons"

echo "📋 Configuration:"
echo "   Port: $DEV_PORT"
echo "   Base: $DB_NAME"
echo "   Addons: $ADDONS_PATH"
echo ""

# Fonction pour arrêter les processus sur notre port
stop_processes() {
    echo "🛑 Arrêt des processus sur le port $DEV_PORT..."
    
    # Trouver et tuer les processus Odoo sur notre port
    PIDS=$(ps aux | grep "odoo.*$DEV_PORT" | grep -v grep | awk '{print $2}')
    
    if [ ! -z "$PIDS" ]; then
        echo "   Processus trouvés: $PIDS"
        for PID in $PIDS; do
            echo "   Arrêt du processus $PID..."
            kill -TERM $PID 2>/dev/null
            sleep 2
            # Force kill si nécessaire
            if kill -0 $PID 2>/dev/null; then
                echo "   Force kill du processus $PID..."
                kill -KILL $PID 2>/dev/null
            fi
        done
        echo "   ✅ Processus arrêtés"
    else
        echo "   ✅ Aucun processus à arrêter"
    fi
    
    # Attendre un peu pour s'assurer que les ports sont libérés
    sleep 3
}

# Fonction pour vérifier si la base existe
check_database() {
    echo "🗄️ Vérification de la base de données..."
    
    export PGPASSWORD=odoo
    DB_EXISTS=$(psql -h localhost -U odoo -lqt | cut -d \| -f 1 | grep -w $DB_NAME | wc -l)
    
    if [ $DB_EXISTS -eq 0 ]; then
        echo "   📝 Création de la base $DB_NAME..."
        createdb -h localhost -U odoo $DB_NAME
        if [ $? -eq 0 ]; then
            echo "   ✅ Base créée avec succès"
            return 1  # Nouvelle base
        else
            echo "   ❌ Erreur lors de la création de la base"
            exit 1
        fi
    else
        echo "   ✅ Base $DB_NAME existe déjà"
        return 0  # Base existante
    fi
}

# Fonction pour activer l'environnement virtuel
activate_venv() {
    echo "🐍 Activation de l'environnement virtuel..."
    
    if [ -f "$VENV_PATH/bin/activate" ]; then
        source "$VENV_PATH/bin/activate"
        echo "   ✅ Environnement virtuel activé"
    else
        echo "   ⚠️ Environnement virtuel non trouvé à $VENV_PATH"
        echo "   Utilisation de Python système"
    fi
}

# Fonction pour démarrer Odoo
start_odoo() {
    local is_new_db=$1
    
    echo "🚀 Démarrage d'Odoo..."
    
    cd "$ODOO_PATH"
    
    if [ $is_new_db -eq 1 ]; then
        echo "   📦 Installation du module sur nouvelle base..."
        python3 odoo-bin \
            -d $DB_NAME \
            --addons-path="$ADDONS_PATH" \
            --db_host=localhost \
            --db_user=odoo \
            --db_password=odoo \
            --http-port=$DEV_PORT \
            --log-level=info \
            --logfile=/tmp/odoo_dev_analytics.log \
            --pidfile=/tmp/odoo_dev_analytics.pid \
            -i sama_conai \
            --stop-after-init &
        
        INSTALL_PID=$!
        echo "   ⏳ Installation en cours (PID: $INSTALL_PID)..."
        
        # Attendre la fin de l'installation
        wait $INSTALL_PID
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Installation terminée"
        else
            echo "   ❌ Erreur lors de l'installation"
            echo "   📋 Vérifiez les logs: tail -f /tmp/odoo_dev_analytics.log"
            exit 1
        fi
        
        # Démarrer en mode normal
        echo "   🔄 Démarrage en mode normal..."
    else
        echo "   🔄 Mise à jour du module..."
        python3 odoo-bin \
            -d $DB_NAME \
            --addons-path="$ADDONS_PATH" \
            --db_host=localhost \
            --db_user=odoo \
            --db_password=odoo \
            --http-port=$DEV_PORT \
            --log-level=info \
            --logfile=/tmp/odoo_dev_analytics.log \
            --pidfile=/tmp/odoo_dev_analytics.pid \
            -u sama_conai \
            --stop-after-init &
        
        UPDATE_PID=$!
        echo "   ⏳ Mise à jour en cours (PID: $UPDATE_PID)..."
        
        # Attendre la fin de la mise à jour
        wait $UPDATE_PID
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Mise à jour terminée"
        else
            echo "   ❌ Erreur lors de la mise à jour"
            echo "   📋 Vérifiez les logs: tail -f /tmp/odoo_dev_analytics.log"
            exit 1
        fi
    fi
    
    # Démarrage final en mode serveur
    echo "   🌐 Démarrage du serveur web..."
    python3 odoo-bin \
        -d $DB_NAME \
        --addons-path="$ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --http-port=$DEV_PORT \
        --log-level=info \
        --logfile=/tmp/odoo_dev_analytics.log \
        --pidfile=/tmp/odoo_dev_analytics.pid &
    
    SERVER_PID=$!
    echo "   🎯 Serveur démarré (PID: $SERVER_PID)"
    echo "   📝 PID sauvegardé dans /tmp/odoo_dev_analytics.pid"
    
    # Attendre que le serveur soit prêt
    echo "   ⏳ Attente du démarrage complet..."
    sleep 10
    
    # Vérifier que le serveur répond
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$DEV_PORT/ | grep -q "200\|303"; then
        echo "   ✅ Serveur accessible"
        return 0
    else
        echo "   ⚠️ Serveur peut-être pas encore prêt"
        return 1
    fi
}

# Fonction pour afficher les informations de connexion
show_connection_info() {
    echo ""
    echo "🎉 SAMA CONAI DEV ANALYTICS DÉMARRÉ !"
    echo "===================================="
    echo ""
    echo "🌐 URL d'accès:"
    echo "   http://localhost:$DEV_PORT"
    echo ""
    echo "👤 Connexion:"
    echo "   Utilisateur: admin"
    echo "   Mot de passe: admin"
    echo ""
    echo "📊 Base de données:"
    echo "   Nom: $DB_NAME"
    echo "   Port: $DEV_PORT"
    echo ""
    echo "📋 Nouveaux modules disponibles:"
    echo "   📈 Tableau de Bord Exécutif"
    echo "   📊 Générateurs de Rapports Automatiques"
    echo "   🔮 Analytics Prédictifs"
    echo ""
    echo "📝 Logs en temps réel:"
    echo "   tail -f /tmp/odoo_dev_analytics.log"
    echo ""
    echo "🛑 Pour arrêter:"
    echo "   kill \$(cat /tmp/odoo_dev_analytics.pid)"
    echo ""
}

# Fonction pour surveiller les logs
monitor_logs() {
    echo "📋 Surveillance des logs (Ctrl+C pour arrêter)..."
    echo "================================================"
    tail -f /tmp/odoo_dev_analytics.log
}

# Exécution principale
main() {
    # Arrêter les processus existants
    stop_processes
    
    # Activer l'environnement virtuel
    activate_venv
    
    # Vérifier/créer la base de données
    check_database
    is_new_db=$?
    
    # Démarrer Odoo
    start_odoo $is_new_db
    
    if [ $? -eq 0 ]; then
        # Afficher les informations de connexion
        show_connection_info
        
        # Demander si l'utilisateur veut surveiller les logs
        echo "Voulez-vous surveiller les logs en temps réel ? (y/N)"
        read -t 10 -n 1 response
        echo ""
        
        if [[ $response =~ ^[Yy]$ ]]; then
            monitor_logs
        else
            echo "✅ Serveur en cours d'exécution en arrière-plan"
            echo "📋 Consultez les logs avec: tail -f /tmp/odoo_dev_analytics.log"
        fi
    else
        echo "❌ Échec du démarrage du serveur"
        echo "📋 Consultez les logs: cat /tmp/odoo_dev_analytics.log"
        exit 1
    fi
}

# Gestion des signaux pour un arrêt propre
trap 'echo ""; echo "🛑 Arrêt demandé..."; stop_processes; exit 0' INT TERM

# Lancer le script principal
main "$@"