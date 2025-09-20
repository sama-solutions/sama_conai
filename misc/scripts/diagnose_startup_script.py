#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de diagnostic pour start_sama_conai_analytics.sh
"""

import os
import subprocess
import sys
import socket

def check_command(cmd):
    """Vérifie si une commande est disponible"""
    try:
        subprocess.run(['which', cmd], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError:
        return False

def check_path(path):
    """Vérifie si un chemin existe"""
    return os.path.exists(path)

def check_port(port):
    """Vérifie si un port est disponible"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('localhost', port))
            return True
    except OSError:
        return False

def check_postgres_connection():
    """Vérifie la connexion PostgreSQL"""
    try:
        result = subprocess.run([
            'psql', '-h', 'localhost', '-U', 'odoo', '-d', 'postgres', 
            '-c', 'SELECT version();'
        ], env={'PGPASSWORD': 'odoo'}, capture_output=True, text=True)
        return result.returncode == 0
    except Exception:
        return False

def analyze_script():
    """Analyse le script start_sama_conai_analytics.sh"""
    
    print("🔍 DIAGNOSTIC DU SCRIPT start_sama_conai_analytics.sh")
    print("=" * 60)
    
    # Configuration du script
    config = {
        'PORT': 8077,
        'DB_NAME': 'sama_conai_analytics',
        'VENV_PATH': '/home/grand-as/odoo18-venv',
        'ODOO_PATH': '/var/odoo/odoo18',
        'ADDONS_PATH': '/var/odoo/odoo18/addons,/home/grand-as/psagsn/custom_addons'
    }
    
    print("📋 Configuration extraite du script:")
    for key, value in config.items():
        print(f"   {key}: {value}")
    
    print(f"\n🔧 Vérification des prérequis:")
    
    # Vérifier les commandes
    commands = ['psql', 'createdb', 'curl', 'python3', 'kill', 'ps']
    for cmd in commands:
        status = "✅" if check_command(cmd) else "❌"
        print(f"   {status} Commande '{cmd}' disponible")
    
    # Vérifier les chemins
    paths_to_check = [
        config['VENV_PATH'],
        config['ODOO_PATH'],
        config['ODOO_PATH'] + '/odoo-bin',
        '/home/grand-as/psagsn/custom_addons',
        '/home/grand-as/psagsn/custom_addons/sama_conai'
    ]
    
    print(f"\n📁 Vérification des chemins:")
    for path in paths_to_check:
        status = "✅" if check_path(path) else "❌"
        print(f"   {status} {path}")
    
    # Vérifier le port
    print(f"\n🌐 Vérification du port:")
    port_available = check_port(config['PORT'])
    status = "✅" if port_available else "❌"
    print(f"   {status} Port {config['PORT']} {'disponible' if port_available else 'occupé'}")
    
    # Vérifier PostgreSQL
    print(f"\n🗄️ Vérification PostgreSQL:")
    pg_ok = check_postgres_connection()
    status = "✅" if pg_ok else "❌"
    print(f"   {status} Connexion PostgreSQL (user: odoo, password: odoo)")
    
    # Vérifier les permissions
    print(f"\n🔐 Vérification des permissions:")
    
    # Permissions sur le répertoire custom_addons
    custom_addons_writable = os.access('/home/grand-as/psagsn/custom_addons', os.W_OK)
    status = "✅" if custom_addons_writable else "❌"
    print(f"   {status} Écriture dans custom_addons")
    
    # Permissions sur /tmp
    tmp_writable = os.access('/tmp', os.W_OK)
    status = "✅" if tmp_writable else "❌"
    print(f"   {status} Écriture dans /tmp (pour logs et PID)")
    
    # Analyser les problèmes potentiels du script
    print(f"\n⚠️  Problèmes potentiels identifiés:")
    
    issues = []
    
    if not check_path(config['VENV_PATH']):
        issues.append("Environnement virtuel introuvable")
    
    if not check_path(config['ODOO_PATH'] + '/odoo-bin'):
        issues.append("Exécutable odoo-bin introuvable")
    
    if not port_available:
        issues.append(f"Port {config['PORT']} déjà utilisé")
    
    if not pg_ok:
        issues.append("Connexion PostgreSQL échouée")
    
    if not check_path('/home/grand-as/psagsn/custom_addons/sama_conai'):
        issues.append("Module sama_conai introuvable")
    
    # Problèmes dans le code du script
    script_issues = [
        "Return codes inversés dans setup_database() (ligne 67)",
        "Pas de vérification des dépendances système",
        "Gestion d'erreur limitée pour les commandes PostgreSQL",
        "Détection des processus peut être imprécise",
        "Pas de nettoyage des fichiers PID existants"
    ]
    
    if issues:
        for issue in issues:
            print(f"   ❌ {issue}")
    else:
        print(f"   ✅ Aucun problème majeur détecté")
    
    print(f"\n🐛 Problèmes de code identifiés:")
    for issue in script_issues:
        print(f"   ⚠️  {issue}")
    
    # Recommandations
    print(f"\n💡 Recommandations:")
    
    if not pg_ok:
        print("   🔧 Configurer PostgreSQL avec utilisateur 'odoo'")
        print("      sudo -u postgres createuser -s odoo")
        print("      sudo -u postgres psql -c \"ALTER USER odoo PASSWORD 'odoo';\"")
    
    if not port_available:
        print(f"   🔧 Libérer le port {config['PORT']} ou changer de port")
    
    print("   🔧 Corriger les return codes dans la fonction setup_database()")
    print("   🔧 Ajouter des vérifications de prérequis au début du script")
    print("   🔧 Améliorer la gestion d'erreurs")
    
    # Score global
    total_checks = len(commands) + len(paths_to_check) + 3  # +3 pour port, pg, permissions
    passed_checks = sum([
        sum(check_command(cmd) for cmd in commands),
        sum(check_path(path) for path in paths_to_check),
        port_available,
        pg_ok,
        tmp_writable
    ])
    
    score = (passed_checks / total_checks) * 100
    
    print(f"\n📊 Score de compatibilité: {score:.1f}% ({passed_checks}/{total_checks})")
    
    if score >= 80:
        print("✅ Le script devrait fonctionner avec des corrections mineures")
    elif score >= 60:
        print("⚠️  Le script nécessite des corrections importantes")
    else:
        print("❌ Le script nécessite des corrections majeures")
    
    return score >= 60

if __name__ == "__main__":
    success = analyze_script()
    sys.exit(0 if success else 1)