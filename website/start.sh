#!/bin/bash

# SAMA CONAI Formation Website - Lanceur de serveur
# Arrête automatiquement les processus sur le port 8000 et démarre le serveur

PORT=8000
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Démarrage du serveur SAMA CONAI..."
echo "📁 Répertoire: $SCRIPT_DIR"

# Changer vers le répertoire du script
cd "$SCRIPT_DIR"

# Fonction pour arrêter les processus sur le port
kill_port_processes() {
    echo "🔍 Vérification du port $PORT..."
    
    # Méthode 1: Utiliser lsof
    if command -v lsof >/dev/null 2>&1; then
        PIDS=$(lsof -ti :$PORT 2>/dev/null)
        if [ ! -z "$PIDS" ]; then
            echo "🛑 Arrêt des processus utilisant le port $PORT..."
            echo "$PIDS" | xargs -r kill -TERM
            sleep 2
            
            # Vérifier s'il reste des processus et les forcer à s'arrêter
            REMAINING_PIDS=$(lsof -ti :$PORT 2>/dev/null)
            if [ ! -z "$REMAINING_PIDS" ]; then
                echo "⚡ Arrêt forcé des processus restants..."
                echo "$REMAINING_PIDS" | xargs -r kill -KILL
                sleep 1
            fi
            echo "✅ Port $PORT libéré"
        else
            echo "✅ Port $PORT déjà libre"
        fi
    # Méthode 2: Utiliser netstat si lsof n'est pas disponible
    elif command -v netstat >/dev/null 2>&1; then
        echo "🔄 Utilisation de netstat..."
        PIDS=$(netstat -tlnp 2>/dev/null | grep ":$PORT " | grep LISTEN | awk '{print $7}' | cut -d'/' -f1 | grep -E '^[0-9]+$')
        if [ ! -z "$PIDS" ]; then
            echo "🛑 Arrêt des processus utilisant le port $PORT..."
            echo "$PIDS" | xargs -r kill -TERM
            sleep 2
            echo "✅ Port $PORT libéré"
        else
            echo "✅ Port $PORT déjà libre"
        fi
    else
        echo "⚠️ lsof et netstat non disponibles, tentative de démarrage direct..."
    fi
}

# Fonction pour afficher la bannière
print_banner() {
    echo "======================================================================"
    echo "🌐 SAMA CONAI Formation Website - Serveur de Développement"
    echo "======================================================================"
    echo "📁 Répertoire: $(pwd)"
    echo "🌍 URL Locale: http://localhost:$PORT"
    echo "🔗 URL Réseau: http://0.0.0.0:$PORT"
    echo "======================================================================"
    echo "📋 Pages disponibles:"
    echo "   • Accueil: http://localhost:$PORT/"
    echo "   • Formation Citoyen: http://localhost:$PORT/formation/citoyen.html"
    echo "   • Formation Agent: http://localhost:$PORT/formation/agent.html"
    echo "   • Formation Admin: http://localhost:$PORT/formation/administrateur.html"
    echo "   • Formation Formateur: http://localhost:$PORT/formation/formateur.html"
    echo "   • Certification: http://localhost:$PORT/certification/utilisateur.html"
    echo "======================================================================"
    echo "💡 Conseils:"
    echo "   • Appuyez sur Ctrl+C pour arrêter le serveur"
    echo "   • Le navigateur s'ouvrira automatiquement"
    echo "======================================================================"
}

# Fonction pour ouvrir le navigateur
open_browser() {
    sleep 3
    URL="http://localhost:$PORT"
    
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$URL" >/dev/null 2>&1 &
    elif command -v open >/dev/null 2>&1; then
        open "$URL" >/dev/null 2>&1 &
    elif command -v firefox >/dev/null 2>&1; then
        firefox "$URL" >/dev/null 2>&1 &
    elif command -v google-chrome >/dev/null 2>&1; then
        google-chrome "$URL" >/dev/null 2>&1 &
    elif command -v chromium >/dev/null 2>&1; then
        chromium "$URL" >/dev/null 2>&1 &
    else
        echo "🌐 Ouvrez manuellement: $URL"
    fi
}

# Gestionnaire de signal pour arrêt propre
cleanup() {
    echo ""
    echo "🛑 Arrêt du serveur..."
    echo "👋 Merci d'avoir utilisé SAMA CONAI Formation Website!"
    exit 0
}

# Capturer Ctrl+C
trap cleanup SIGINT SIGTERM

# Arrêter les processus sur le port
kill_port_processes

# Afficher la bannière
print_banner

# Ouvrir le navigateur en arrière-plan
open_browser &

echo "🚀 Démarrage du serveur Python..."
echo "📝 Appuyez sur Ctrl+C pour arrêter"
echo ""

# Démarrer le serveur Python
if command -v python3 >/dev/null 2>&1; then
    python3 -m http.server $PORT
elif command -v python >/dev/null 2>&1; then
    python -m http.server $PORT
else
    echo "❌ Python non trouvé. Veuillez installer Python 3."
    exit 1
fi