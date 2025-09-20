#!/bin/bash

# Test de syntaxe Python pour les modules Analytics

echo "🔍 TEST DE SYNTAXE - MODULES ANALYTICS"
echo "======================================"

# Configuration
VENV_PATH="/home/grand-as/odoo18-venv"

# Activer l'environnement virtuel
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    echo "✅ Environnement virtuel activé"
else
    echo "⚠️ Utilisation de Python système"
fi

echo ""
echo "📋 Test des fichiers Python..."

# Tester la syntaxe de chaque fichier
files_to_test=(
    "models/analytics/__init__.py"
    "models/analytics/executive_dashboard.py"
    "models/analytics/auto_report_generator.py"
    "models/analytics/predictive_analytics.py"
)

error_count=0

for file in "${files_to_test[@]}"; do
    echo -n "   Testing $file... "
    
    if [ -f "$file" ]; then
        if python3 -m py_compile "$file" 2>/dev/null; then
            echo "✅"
        else
            echo "❌"
            echo "      Erreur de syntaxe dans $file:"
            python3 -m py_compile "$file"
            ((error_count++))
        fi
    else
        echo "❌ (fichier manquant)"
        ((error_count++))
    fi
done

echo ""
echo "📋 Test des fichiers XML..."

xml_files=(
    "views/analytics/executive_dashboard_views.xml"
    "views/analytics/auto_report_generator_views.xml"
    "data/analytics/cron_jobs.xml"
    "data/analytics/demo_analytics.xml"
)

for file in "${xml_files[@]}"; do
    echo -n "   Testing $file... "
    
    if [ -f "$file" ]; then
        if xmllint --noout "$file" 2>/dev/null; then
            echo "✅"
        else
            echo "❌"
            echo "      Erreur XML dans $file:"
            xmllint --noout "$file"
            ((error_count++))
        fi
    else
        echo "❌ (fichier manquant)"
        ((error_count++))
    fi
done

echo ""
echo "📊 RÉSULTATS:"
if [ $error_count -eq 0 ]; then
    echo "   ✅ Tous les tests de syntaxe sont passés"
    echo "   🚀 Le module est prêt pour l'installation"
else
    echo "   ❌ $error_count erreur(s) détectée(s)"
    echo "   🔧 Corrigez les erreurs avant de continuer"
fi

echo ""
exit $error_count