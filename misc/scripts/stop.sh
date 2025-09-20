#!/bin/bash

# =============================================================================
# SAMA CONAI - Script d'Arrêt Rapide
# =============================================================================
# Script simplifié pour arrêter SAMA CONAI rapidement
# =============================================================================

echo "🛑 Arrêt de SAMA CONAI..."
echo "========================"

# Exécuter le script principal
./startup_sama_conai.sh stop

echo ""
echo "✅ SAMA CONAI a été arrêté"
echo ""
echo "💡 Utilisez './start.sh' pour redémarrer les services"