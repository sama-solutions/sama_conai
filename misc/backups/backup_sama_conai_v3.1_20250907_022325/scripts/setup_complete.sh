#!/bin/bash

# Script de configuration complète SAMA CONAI

echo "🎯 CONFIGURATION COMPLÈTE SAMA CONAI"
echo "===================================="
echo ""

DB_NAME="${1:-sama_conai_demo}"

echo "Ce script va:"
echo "   1. Valider l'installation système"
echo "   2. Installer le module SAMA CONAI"
echo "   3. Charger les données de démo"
echo "   4. Tester le fonctionnement"
echo "   5. Proposer le démarrage du serveur"
echo ""
echo "Base de données: $DB_NAME"
echo ""

read -p "Continuer? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Configuration annulée."
    exit 0
fi

echo ""

# Étape 1: Validation
echo "🔍 ÉTAPE 1: VALIDATION SYSTÈME"
echo "=============================="
./scripts/validate_installation.sh "$DB_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Validation échouée. Arrêt du processus."
    exit 1
fi

echo ""

# Étape 2: Installation
echo "📦 ÉTAPE 2: INSTALLATION MODULE"
echo "==============================="
./scripts/install_sama_conai.sh "$DB_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Installation échouée. Arrêt du processus."
    exit 1
fi

echo ""

# Étape 3: Test
echo "🧪 ÉTAPE 3: TEST FONCTIONNEL"
echo "============================"
./scripts/test_sama_conai.sh "$DB_NAME"

echo ""

# Étape 4: Résumé
echo "🎉 CONFIGURATION TERMINÉE!"
echo "=========================="
echo ""
echo "✅ Système validé et configuré"
echo "✅ Module SAMA CONAI installé"
echo "✅ Données de démo chargées"
echo "✅ Tests fonctionnels réussis"
echo ""

# Étape 5: Démarrage optionnel
read -p "Démarrer le serveur Odoo maintenant? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 DÉMARRAGE DU SERVEUR..."
    echo "========================="
    echo "Serveur accessible sur: http://localhost:8069"
    echo "Base de données: $DB_NAME"
    echo "Utilisateur: admin / Mot de passe: admin"
    echo ""
    echo "Appuyez sur Ctrl+C pour arrêter le serveur"
    echo ""
    ./scripts/start_sama_conai.sh "$DB_NAME"
else
    echo ""
    echo "🎯 PROCHAINES ÉTAPES:"
    echo "===================="
    echo ""
    echo "1. Démarrer le serveur:"
    echo "   ./scripts/start_sama_conai.sh $DB_NAME"
    echo ""
    echo "2. Se connecter à Odoo:"
    echo "   URL: http://localhost:8069"
    echo "   Base: $DB_NAME"
    echo "   User: admin / Pass: admin"
    echo ""
    echo "3. Explorer le module:"
    echo "   Menu: Accès à l'Information > Demandes d'Information"
    echo "   Vues: Kanban, Graph, Pivot"
    echo ""
    echo "📚 Documentation:"
    echo "   - Guide rapide: INSTALLATION_RAPIDE.md"
    echo "   - Guide complet: GUIDE_ANALYSE_DONNEES.md"
    echo "   - Résumé données: DEMO_DATA_SUMMARY.md"
    echo ""
    echo "🎯 SAMA CONAI prêt à l'emploi!"
fi