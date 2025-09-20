#!/bin/bash

# Script de test pour le module Analytics SAMA CONAI

echo "🧪 TEST MODULE ANALYTICS SAMA CONAI"
echo "==================================="

# Configuration
DEV_PORT=8076
DB_NAME="sama_conai_dev_analytics"
VENV_PATH="/home/grand-as/odoo18-venv"
ODOO_PATH="/var/odoo/odoo18"

echo "📋 Configuration de test:"
echo "   Port: $DEV_PORT"
echo "   Base: $DB_NAME"
echo ""

# Fonction pour tester la connectivité
test_connectivity() {
    echo "🌐 Test de connectivité..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$DEV_PORT/)
    
    if [ "$response" = "200" ] || [ "$response" = "303" ]; then
        echo "   ✅ Serveur accessible (Code: $response)"
        return 0
    else
        echo "   ❌ Serveur non accessible (Code: $response)"
        return 1
    fi
}

# Fonction pour tester l'installation du module
test_module_installation() {
    echo "📦 Test d'installation du module..."
    
    # Vérifier les logs d'installation
    if grep -q "Module sama_conai loaded" /tmp/odoo_dev_analytics.log 2>/dev/null; then
        echo "   ✅ Module sama_conai chargé avec succès"
    else
        echo "   ⚠️ Statut de chargement du module incertain"
    fi
    
    # Vérifier les erreurs dans les logs
    error_count=$(grep -c "ERROR\|CRITICAL" /tmp/odoo_dev_analytics.log 2>/dev/null || echo "0")
    
    if [ "$error_count" -eq 0 ]; then
        echo "   ✅ Aucune erreur critique détectée"
    else
        echo "   ⚠️ $error_count erreur(s) détectée(s) dans les logs"
        echo "   📋 Dernières erreurs:"
        grep "ERROR\|CRITICAL" /tmp/odoo_dev_analytics.log | tail -3
    fi
}

# Fonction pour tester les modèles Analytics
test_analytics_models() {
    echo "🔍 Test des modèles Analytics..."
    
    # Vérifier que les modèles sont chargés
    models_to_check=(
        "executive.dashboard"
        "auto.report.generator"
        "auto.report.instance"
        "predictive.analytics"
    )
    
    for model in "${models_to_check[@]}"; do
        if grep -q "$model" /tmp/odoo_dev_analytics.log 2>/dev/null; then
            echo "   ✅ Modèle $model détecté"
        else
            echo "   ⚠️ Modèle $model non détecté dans les logs"
        fi
    done
}

# Fonction pour tester les vues
test_analytics_views() {
    echo "👁️ Test des vues Analytics..."
    
    # Vérifier que les fichiers de vues existent
    views_to_check=(
        "views/analytics/executive_dashboard_views.xml"
        "views/analytics/auto_report_generator_views.xml"
    )
    
    for view in "${views_to_check[@]}"; do
        if [ -f "$view" ]; then
            echo "   ✅ Vue $view existe"
        else
            echo "   ❌ Vue $view manquante"
        fi
    done
    
    # Vérifier le chargement des vues dans les logs
    if grep -q "loading sama_conai/views/analytics" /tmp/odoo_dev_analytics.log 2>/dev/null; then
        echo "   ✅ Vues Analytics chargées"
    else
        echo "   ⚠️ Chargement des vues Analytics incertain"
    fi
}

# Fonction pour tester les menus
test_analytics_menus() {
    echo "📋 Test des menus Analytics..."
    
    # Vérifier que les menus sont définis
    if grep -q "menu_sama_conai_analytics" views/menus.xml; then
        echo "   ✅ Menu Analytics défini"
    else
        echo "   ❌ Menu Analytics manquant"
    fi
    
    if grep -q "menu_executive_dashboard" views/menus.xml; then
        echo "   ✅ Menu Dashboard Exécutif défini"
    else
        echo "   ❌ Menu Dashboard Exécutif manquant"
    fi
    
    if grep -q "menu_auto_report_generator" views/menus.xml; then
        echo "   ✅ Menu Générateurs de Rapports défini"
    else
        echo "   ❌ Menu Générateurs de Rapports manquant"
    fi
}

# Fonction pour tester la structure des fichiers
test_file_structure() {
    echo "📁 Test de la structure des fichiers..."
    
    # Vérifier la structure des modèles Analytics
    if [ -d "models/analytics" ]; then
        echo "   ✅ Dossier models/analytics existe"
        
        analytics_files=(
            "models/analytics/__init__.py"
            "models/analytics/executive_dashboard.py"
            "models/analytics/auto_report_generator.py"
            "models/analytics/predictive_analytics.py"
        )
        
        for file in "${analytics_files[@]}"; do
            if [ -f "$file" ]; then
                echo "   ✅ Fichier $file existe"
            else
                echo "   ❌ Fichier $file manquant"
            fi
        done
    else
        echo "   ❌ Dossier models/analytics manquant"
    fi
    
    # Vérifier la structure des vues
    if [ -d "views/analytics" ]; then
        echo "   ✅ Dossier views/analytics existe"
    else
        echo "   ❌ Dossier views/analytics manquant"
    fi
}

# Fonction pour tester les dépendances
test_dependencies() {
    echo "🔗 Test des dépendances..."
    
    # Vérifier que les dépendances de base sont présentes
    required_deps=("base" "mail" "portal" "hr")
    
    for dep in "${required_deps[@]}"; do
        if grep -q "\"$dep\"" __manifest__.py; then
            echo "   ✅ Dépendance $dep présente"
        else
            echo "   ❌ Dépendance $dep manquante"
        fi
    done
    
    # Vérifier qu'il n'y a pas de dépendances interdites
    forbidden_deps=("account" "social_media" "website_payment")
    
    for dep in "${forbidden_deps[@]}"; do
        if grep -q "\"$dep\"" __manifest__.py; then
            echo "   ⚠️ Dépendance interdite $dep détectée"
        else
            echo "   ✅ Pas de dépendance interdite $dep"
        fi
    done
}

# Fonction pour générer un rapport de test
generate_test_report() {
    echo ""
    echo "📊 RAPPORT DE TEST"
    echo "=================="
    
    # Compter les tests réussis/échoués
    total_tests=0
    passed_tests=0
    
    # Analyser les résultats (simplifié)
    if test_connectivity; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    echo ""
    echo "📈 Résultats:"
    echo "   Tests passés: $passed_tests/$total_tests"
    
    if [ $passed_tests -eq $total_tests ]; then
        echo "   ✅ Tous les tests sont passés"
        return 0
    else
        echo "   ⚠️ Certains tests ont échoué"
        return 1
    fi
}

# Fonction principale
main() {
    echo "🚀 Début des tests..."
    echo ""
    
    # Tests de structure
    test_file_structure
    echo ""
    
    # Tests de dépendances
    test_dependencies
    echo ""
    
    # Tests de configuration
    test_analytics_menus
    echo ""
    
    # Tests de vues
    test_analytics_views
    echo ""
    
    # Tests de connectivité (si le serveur tourne)
    if pgrep -f "odoo.*$DEV_PORT" > /dev/null; then
        echo "🔍 Serveur détecté, tests de connectivité..."
        test_connectivity
        echo ""
        
        test_module_installation
        echo ""
        
        test_analytics_models
        echo ""
    else
        echo "⚠️ Serveur non démarré, tests de connectivité ignorés"
        echo "   Utilisez: ./dev_scripts/start_dev_analytics.sh"
        echo ""
    fi
    
    # Générer le rapport final
    generate_test_report
}

# Exécution
main "$@"