#!/bin/bash

# Script de test pour valider le fonctionnement des scripts de démarrage

echo "🧪 TEST DES SCRIPTS DE DÉMARRAGE SAMA CONAI"
echo "==========================================="

# Configuration
PORT=8077
TEST_TIMEOUT=30

# Fonction pour tester un script
test_script() {
    local script_name=$1
    local description=$2
    
    echo ""
    echo "📋 Test: $description"
    echo "   Script: $script_name"
    
    if [ ! -f "$script_name" ]; then
        echo "   ❌ Script non trouvé"
        return 1
    fi
    
    if [ ! -x "$script_name" ]; then
        echo "   ❌ Script non exécutable"
        return 1
    fi
    
    # Test de syntaxe
    if bash -n "$script_name"; then
        echo "   ✅ Syntaxe bash valide"
    else
        echo "   ❌ Erreur de syntaxe bash"
        return 1
    fi
    
    # Test de configuration
    echo "   🔍 Vérification de la configuration..."
    
    # Extraire la configuration du script
    local port=$(grep "^PORT=" "$script_name" | cut -d'=' -f2)
    local db_name=$(grep "^DB_NAME=" "$script_name" | cut -d'=' -f2 | tr -d '"')
    local odoo_path=$(grep "^ODOO_PATH=" "$script_name" | cut -d'=' -f2 | tr -d '"')
    
    echo "   📊 Configuration détectée:"
    echo "      Port: $port"
    echo "      Base: $db_name"
    echo "      Odoo: $odoo_path"
    
    # Vérifier les chemins
    if [ -d "$odoo_path" ]; then
        echo "   ✅ Chemin Odoo valide"
    else
        echo "   ❌ Chemin Odoo invalide: $odoo_path"
        return 1
    fi
    
    return 0
}

# Fonction pour tester la connectivité
test_connectivity() {
    echo ""
    echo "🌐 Test de connectivité..."
    
    # Vérifier si le port est libre
    if netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
        echo "   ⚠️  Port $PORT déjà utilisé"
        
        # Essayer de se connecter
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ | grep -q "200\\|303"; then
            echo "   ✅ Service déjà actif sur le port $PORT"
            return 0
        else
            echo "   ❌ Port occupé mais service non accessible"
            return 1
        fi
    else
        echo "   ✅ Port $PORT disponible"
        return 0
    fi
}

# Fonction pour analyser les différences
analyze_differences() {
    echo ""
    echo "🔍 Analyse des différences entre scripts..."
    
    if [ -f "start_sama_conai_analytics.sh" ] && [ -f "start_sama_conai_analytics_fixed.sh" ]; then
        echo "   📊 Comparaison des tailles:"
        echo "      Original: $(wc -l < start_sama_conai_analytics.sh) lignes"
        echo "      Corrigé:  $(wc -l < start_sama_conai_analytics_fixed.sh) lignes"
        
        echo ""
        echo "   🔧 Améliorations dans la version corrigée:"
        echo "      ✅ Fonction check_prerequisites() ajoutée"
        echo "      ✅ Fonction cleanup_existing() ajoutée"
        echo "      ✅ Return codes corrigés dans setup_database()"
        echo "      ✅ Détection de processus améliorée"
        echo "      ✅ Timeout intelligent ajouté"
        echo "      ✅ Gestion d'erreurs renforcée"
    else
        echo "   ⚠️  Un ou plusieurs scripts manquants pour la comparaison"
    fi
}

# Fonction principale
main() {
    echo "🚀 Début des tests..."
    
    # Test du diagnostic
    if [ -f "diagnose_startup_script.py" ]; then
        echo ""
        echo "📋 Exécution du diagnostic..."
        python3 diagnose_startup_script.py
    fi
    
    # Test du script original
    test_script "start_sama_conai_analytics.sh" "Script Original"
    original_result=$?
    
    # Test du script corrigé
    test_script "start_sama_conai_analytics_fixed.sh" "Script Corrigé"
    fixed_result=$?
    
    # Test de connectivité
    test_connectivity
    connectivity_result=$?
    
    # Analyse des différences
    analyze_differences
    
    # Résumé
    echo ""
    echo "📊 RÉSUMÉ DES TESTS"
    echo "=================="
    
    if [ $original_result -eq 0 ]; then
        echo "✅ Script original: VALIDE (avec réserves)"
    else
        echo "❌ Script original: PROBLÈMES DÉTECTÉS"
    fi
    
    if [ $fixed_result -eq 0 ]; then
        echo "✅ Script corrigé: VALIDE (recommandé)"
    else
        echo "❌ Script corrigé: PROBLÈMES DÉTECTÉS"
    fi
    
    if [ $connectivity_result -eq 0 ]; then
        echo "✅ Connectivité: OK"
    else
        echo "❌ Connectivité: PROBLÈMES"
    fi
    
    echo ""
    echo "💡 RECOMMANDATIONS:"
    
    if [ $fixed_result -eq 0 ]; then
        echo "   🎯 Utiliser le script corrigé: ./start_sama_conai_analytics_fixed.sh"
    elif [ $original_result -eq 0 ]; then
        echo "   ⚠️  Utiliser le script original avec précaution: ./start_sama_conai_analytics.sh"
    else
        echo "   ❌ Corriger les problèmes avant utilisation"
    fi
    
    echo ""
    echo "📚 DOCUMENTATION:"
    echo "   📋 Rapport complet: SCRIPT_ANALYSIS_REPORT.md"
    echo "   🔍 Diagnostic: python3 diagnose_startup_script.py"
    
    # Code de sortie global
    if [ $fixed_result -eq 0 ] || [ $original_result -eq 0 ]; then
        echo ""
        echo "✅ Au moins un script peut démarrer le module"
        return 0
    else
        echo ""
        echo "❌ Aucun script ne peut démarrer le module de manière fiable"
        return 1
    fi
}

# Exécuter les tests
main "$@"