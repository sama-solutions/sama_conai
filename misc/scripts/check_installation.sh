#!/bin/bash

# Script pour vérifier l'installation du module SAMA CONAI

echo "🔍 VÉRIFICATION INSTALLATION SAMA CONAI"
echo "======================================="

# Vérifier les processus Odoo en cours
echo "1. Processus Odoo en cours:"
ps aux | grep odoo-bin | grep -v grep

echo ""
echo "2. Ports Odoo ouverts:"
netstat -tlnp | grep python3

echo ""
echo "3. Test de connexion aux bases de données:"

# Tester la connexion PostgreSQL
export PGPASSWORD=odoo

echo "   Bases de données disponibles:"
psql -h localhost -U odoo -l | grep -E "(sama_conai|cityzenmag)"

echo ""
echo "4. Test du module SAMA CONAI:"

# Vérifier si le module est installé dans une base
for db in sama_conai_test sama_conai_demo cityzenmag_final; do
    echo "   Base: $db"
    psql -h localhost -U odoo -d $db -c "SELECT name, state FROM ir_module_module WHERE name = 'sama_conai';" 2>/dev/null || echo "     Base non accessible"
done

echo ""
echo "5. Vérification des fichiers du module:"
if [ -f "__manifest__.py" ]; then
    echo "   ✅ Module SAMA CONAI présent"
    echo "   Version: $(grep "'version'" __manifest__.py | cut -d"'" -f4)"
    echo "   Dépendances: $(grep -A5 "'depends'" __manifest__.py | grep -o "'[^']*'" | tr '\n' ' ')"
else
    echo "   ❌ Fichier __manifest__.py non trouvé"
fi

echo ""
echo "6. Test d'accès web:"
for port in 8075 8079 8069; do
    echo "   Port $port:"
    curl -s -o /dev/null -w "     Status: %{http_code}\n" http://localhost:$port/ || echo "     Non accessible"
done

echo ""
echo "🎯 RECOMMANDATIONS:"
echo "   - Si aucun module SAMA CONAI trouvé: lancer ./install_with_deps.sh"
echo "   - Si processus bloqué: kill le processus et relancer"
echo "   - Pour accès web: http://localhost:PORT/web (admin/admin)"