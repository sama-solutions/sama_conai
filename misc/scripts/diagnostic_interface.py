#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Diagnostic complet de l'interface pour identifier les problèmes
avec le dark mode, les graphiques et le drill-down
"""

import requests
import re

def diagnostic_interface():
    """Diagnostic complet de l'interface"""
    print("🔧 Diagnostic Interface SAMA CONAI")
    print("=" * 50)
    
    mobile_url = "http://localhost:3005"
    
    # 1. Test de l'interface principale
    print("1. Analyse de l'interface principale...")
    try:
        response = requests.get(mobile_url, timeout=10)
        if response.status_code == 200:
            html_content = response.text
            
            # Diagnostic Dark Mode
            print("\n🌙 DIAGNOSTIC DARK MODE:")
            dark_mode_elements = [
                ("Bouton Dark Mode", "🌙 Dark Mode" in html_content),
                ("CSS Dark Mode", 'body[data-theme="dark"]' in html_content),
                ("Variables CSS dark", '--background-color: #1a1a1a' in html_content),
                ("Fonction setTheme", "setTheme('dark')" in html_content),
                ("Menu thèmes", 'class="theme-menu"' in html_content),
                ("Icône sélecteur", "🎨" in html_content)
            ]
            
            for element, present in dark_mode_elements:
                status = "✅" if present else "❌"
                print(f"   {status} {element}")
            
            # Diagnostic Graphiques
            print("\n📊 DIAGNOSTIC GRAPHIQUES:")
            chart_elements = [
                ("Chart.js CDN", "chart.js" in html_content),
                ("Fonction createRequestsChart", "createRequestsChart" in html_content),
                ("Canvas dashboard", 'id="requestsChart"' in html_content),
                ("Fonction createStatusChart", "createStatusChart" in html_content),
                ("Canvas statusChart", 'id="statusChart"' in html_content),
                ("Fonction createMonthlyChart", "createMonthlyChart" in html_content),
                ("Canvas monthlyChart", 'id="monthlyChart"' in html_content),
                ("Appel createRequestsChart", "createRequestsChart(data.user_stats)" in html_content)
            ]
            
            for element, present in chart_elements:
                status = "✅" if present else "❌"
                print(f"   {status} {element}")
            
            # Diagnostic Drill-down
            print("\n🔍 DIAGNOSTIC DRILL-DOWN:")
            drilldown_elements = [
                ("Fonction loadRequestsList", "loadRequestsList" in html_content),
                ("Fonction loadRequestDetail", "loadRequestDetail" in html_content),
                ("Fonction loadMyPortal", "loadMyPortal" in html_content),
                ("Fonction loadGlobalStats", "loadGlobalStats" in html_content),
                ("Navigation", 'onclick="loadRequestsList()"' in html_content),
                ("Détails demandes", 'onclick="loadRequestDetail(' in html_content)
            ]
            
            for element, present in drilldown_elements:
                status = "✅" if present else "❌"
                print(f"   {status} {element}")
            
            # Diagnostic Structure HTML
            print("\n🏗️ DIAGNOSTIC STRUCTURE:")
            structure_elements = [
                ("Div content", 'id="content"' in html_content),
                ("Theme selector", 'id="themeSelector"' in html_content),
                ("Theme menu", 'id="themeMenu"' in html_content),
                ("Loading div", 'id="loading"' in html_content),
                ("Error div", 'id="error"' in html_content)
            ]
            
            for element, present in structure_elements:
                status = "✅" if present else "❌"
                print(f"   {status} {element}")
            
            # Vérifier les erreurs JavaScript potentielles
            print("\n🐛 RECHERCHE D'ERREURS POTENTIELLES:")
            
            # Vérifier les fonctions manquantes
            js_functions = [
                "setTheme", "createRequestsChart", "loadRequestsList", 
                "loadRequestDetail", "loadMyPortal", "loadGlobalStats"
            ]
            
            missing_functions = []
            for func in js_functions:
                if f"function {func}" not in html_content and f"{func} =" not in html_content:
                    missing_functions.append(func)
            
            if missing_functions:
                print(f"   ❌ Fonctions manquantes: {', '.join(missing_functions)}")
            else:
                print("   ✅ Toutes les fonctions JavaScript présentes")
            
            # Vérifier les IDs manquants
            required_ids = ["content", "themeSelector", "themeMenu", "loading", "error"]
            missing_ids = []
            for id_name in required_ids:
                if f'id="{id_name}"' not in html_content:
                    missing_ids.append(id_name)
            
            if missing_ids:
                print(f"   ❌ IDs manquants: {', '.join(missing_ids)}")
            else:
                print("   ✅ Tous les IDs requis présents")
            
            return True
        else:
            print(f"❌ Interface non accessible: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def test_authentication():
    """Test d'authentification pour vérifier les données"""
    print("\n2. Test authentification et données...")
    mobile_url = "http://localhost:3005"
    
    try:
        auth_data = {"email": "admin", "password": "admin"}
        response = requests.post(f"{mobile_url}/api/mobile/auth/login", json=auth_data, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                token = data['data']['token']
                print("✅ Authentification réussie")
                
                # Test dashboard
                dashboard_response = requests.get(f"{mobile_url}/api/mobile/citizen/dashboard", 
                                                headers={"Authorization": f"Bearer {token}"}, timeout=10)
                
                if dashboard_response.status_code == 200:
                    dashboard_data = dashboard_response.json()
                    if dashboard_data.get('success'):
                        stats = dashboard_data['data']['user_stats']
                        print(f"✅ Dashboard accessible - {stats['total_requests']} demandes")
                        return stats['total_requests'] > 0
                    else:
                        print(f"❌ Erreur dashboard: {dashboard_data.get('error')}")
                else:
                    print(f"❌ Dashboard non accessible: {dashboard_response.status_code}")
            else:
                print(f"❌ Échec authentification: {data.get('error')}")
        else:
            print(f"❌ Erreur HTTP: {response.status_code}")
    except Exception as e:
        print(f"❌ Erreur: {e}")
    
    return False

def main():
    """Fonction principale"""
    interface_ok = diagnostic_interface()
    data_ok = test_authentication()
    
    print("\n" + "=" * 50)
    print("📋 RÉSUMÉ DU DIAGNOSTIC:")
    
    if interface_ok:
        print("✅ Interface HTML chargée correctement")
    else:
        print("❌ Problème avec l'interface HTML")
    
    if data_ok:
        print("✅ Données disponibles pour les graphiques")
    else:
        print("❌ Pas de données pour alimenter les graphiques")
    
    print("\n🔧 SOLUTIONS RECOMMANDÉES:")
    
    if not interface_ok:
        print("   1. Vérifier que l'application mobile est bien démarrée")
        print("   2. Vider le cache du navigateur (Ctrl+F5)")
        print("   3. Vérifier les logs d'erreur dans la console du navigateur")
    
    if not data_ok:
        print("   1. Vérifier que les demandes sont assignées à l'admin")
        print("   2. Redémarrer l'application mobile")
        print("   3. Vérifier la connexion à Odoo")
    
    print("\n🌐 ÉTAPES DE TEST MANUEL:")
    print("   1. Ouvrir http://localhost:3005")
    print("   2. Ouvrir les outils de développement (F12)")
    print("   3. Vérifier la console pour les erreurs JavaScript")
    print("   4. Chercher l'icône 🎨 en haut à droite")
    print("   5. Se connecter avec admin/admin")
    print("   6. Vérifier que les graphiques apparaissent")
    print("   7. Tester la navigation entre les sections")
    
    return 0 if (interface_ok and data_ok) else 1

if __name__ == "__main__":
    exit(main())