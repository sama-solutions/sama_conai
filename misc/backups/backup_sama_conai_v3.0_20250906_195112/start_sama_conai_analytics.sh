#!/bin/bash

# Script de démarrage SAMA CONAI avec Analytics
# Version: 2.5 avec Analytics Avancés

echo "🚀 SAMA CONAI v2.5 - ANALYTICS AVANCÉS"
echo "======================================"

# Configuration
PORT=8077
DB_NAME="sama_conai_analytics"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_PATH="/var/odoo/odoo18"
ADDONS_PATH="/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons"

echo "📋 Configuration:"
echo "   🌐 Port: $PORT"
echo "   🗄️ Base: $DB_NAME"
echo "   📦 Module: SAMA CONAI avec Analytics"
echo ""

# Fonction pour arrêter les processus sur notre port
stop_processes() {
    echo "🛑 Arrêt des processus sur le port $PORT..."
    
    PIDS=$(ps aux | grep "odoo.*$PORT" | grep -v grep | awk '{print $2}')
    
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
    
    sleep 3
}

# Fonction pour vérifier/créer la base
setup_database() {
    echo "🗄️ Configuration de la base de données..."
    
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
        echo "   ⚠️ Utilisation de Python système"
    fi
}

# Fonction pour démarrer Odoo
start_odoo() {
    local is_new_db=$1
    
    echo "🚀 Démarrage d'Odoo avec Analytics..."
    
    cd "$ODOO_PATH"
    
    if [ $is_new_db -eq 1 ]; then
        echo "   📦 Installation complète sur nouvelle base..."
        python3 odoo-bin \
            -d $DB_NAME \
            --addons-path="$ADDONS_PATH" \
            --db_host=localhost \
            --db_user=odoo \
            --db_password=odoo \
            --http-port=$PORT \
            --log-level=info \
            --logfile=/tmp/sama_conai_analytics.log \
            --pidfile=/tmp/sama_conai_analytics.pid \
            -i sama_conai \
            --stop-after-init
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Installation terminée"
        else
            echo "   ❌ Erreur lors de l'installation"
            echo "   📋 Logs: tail -f /tmp/sama_conai_analytics.log"
            exit 1
        fi
    else
        echo "   🔄 Mise à jour du module..."
        python3 odoo-bin \
            -d $DB_NAME \
            --addons-path="$ADDONS_PATH" \
            --db_host=localhost \
            --db_user=odoo \
            --db_password=odoo \
            --http-port=$PORT \
            --log-level=info \
            --logfile=/tmp/sama_conai_analytics.log \
            --pidfile=/tmp/sama_conai_analytics.pid \
            -u sama_conai \
            --stop-after-init
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Mise à jour terminée"
        else
            echo "   ❌ Erreur lors de la mise à jour"
            echo "   📋 Logs: tail -f /tmp/sama_conai_analytics.log"
            exit 1
        fi
    fi
    
    # Démarrage final
    echo "   🌐 Démarrage du serveur web..."
    python3 odoo-bin \
        -d $DB_NAME \
        --addons-path="$ADDONS_PATH" \
        --db_host=localhost \
        --db_user=odoo \
        --db_password=odoo \
        --http-port=$PORT \
        --log-level=info \
        --logfile=/tmp/sama_conai_analytics.log \
        --pidfile=/tmp/sama_conai_analytics.pid &
    
    SERVER_PID=$!
    echo "   🎯 Serveur démarré (PID: $SERVER_PID)"
    
    # Attendre que le serveur soit prêt
    echo "   ⏳ Attente du démarrage complet..."
    sleep 15
    
    # Vérifier la connectivité
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ | grep -q "200\|303"; then
        echo "   ✅ Serveur accessible"
        return 0
    else
        echo "   ⚠️ Serveur en cours de démarrage..."
        return 1
    fi
}

# Fonction pour afficher les informations
show_info() {
    echo ""
    echo "🎉 SAMA CONAI v2.5 ANALYTICS DÉMARRÉ !"
    echo "====================================="
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
    echo "   🔮 Analytics Prédictifs"
    echo "      → Prédiction de volume"
    echo "      → Détection d'anomalies"
    echo "      → Évaluation des risques"
    echo ""
    echo "📋 **MODULES DISPONIBLES**"
    echo "   📝 Demandes d'Information"
    echo "   🚨 Signalements d'Alerte"
    echo "   📊 Analytics & Rapports (NOUVEAU)"
    echo "   ⚙️ Configuration"
    echo ""
    echo "🔧 **GESTION**"
    echo "   📋 Logs: tail -f /tmp/sama_conai_analytics.log"
    echo "   🛑 Arrêt: kill \$(cat /tmp/sama_conai_analytics.pid)"
    echo ""
    echo "📈 **FONCTIONNALITÉS ANALYTICS**"
    echo "   ✅ Dashboard exécutif avec KPI"
    echo "   ✅ Rapports automatisés"
    echo "   ✅ Prédictions et tendances"
    echo "   ✅ Détection d'anomalies"
    echo "   ✅ Évaluation des risques"
    echo "   ✅ Vues Kanban, Graph, Pivot"
    echo ""
}

# Fonction principale
main() {
    # Arrêter les processus existants
    stop_processes
    
    # Activer l'environnement virtuel
    activate_venv
    
    # Configurer la base de données
    setup_database
    is_new_db=$?
    
    # Démarrer Odoo
    start_odoo $is_new_db
    
    if [ $? -eq 0 ]; then
        show_info
        
        echo "Voulez-vous surveiller les logs ? (y/N)"
        read -t 10 -n 1 response
        echo ""
        
        if [[ $response =~ ^[Yy]$ ]]; then
            echo "📋 Surveillance des logs (Ctrl+C pour arrêter)..."
            tail -f /tmp/sama_conai_analytics.log
        else
            echo "✅ Serveur en cours d'exécution"
            echo "🌐 Accédez à http://localhost:$PORT"
        fi
    else
        echo "❌ Échec du démarrage"
        exit 1
    fi
}

# Gestion des signaux
trap 'echo ""; echo "🛑 Arrêt demandé..."; stop_processes; exit 0' INT TERM

# Lancer le script
main "$@"