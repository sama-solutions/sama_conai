#!/bin/bash

# =============================================================================
# SAMA CONAI - Script de Démarrage Rapide
# =============================================================================
# Script simplifié pour démarrer SAMA CONAI rapidement
# =============================================================================

echo "🚀 Démarrage rapide de SAMA CONAI..."
echo "===================================="

# Exécuter le script principal
./startup_sama_conai.sh start

echo ""
echo "🎯 SAMA CONAI est maintenant accessible :"
echo "   • Backend Odoo: http://localhost:8077"
echo "   • Application Mobile: http://localhost:3005"
echo ""
echo "💡 Utilisez './startup_sama_conai.sh status' pour vérifier le statut"
echo "💡 Utilisez './startup_sama_conai.sh stop' pour arrêter les services"