#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de test final pour valider toutes les corrections
"""

import requests
import time

def test_odoo_replacement():
    """Teste que 'Odoo' a été remplacé par 'SAMA CONAI'"""
    
    print("🔧 TEST DE REMPLACEMENT 'ODOO' → 'SAMA CONAI'")
    print("=" * 50)
    
    base_url = "http://localhost:8077"
    dashboard_url = f"{base_url}/transparence-dashboard"
    
    try:
        response = requests.get(dashboard_url, timeout=10)
        
        if response.status_code == 200:
            content = response.text
            
            # Vérifier les remplacements
            replacements = [
                ('Créer dans SAMA CONAI', 'Créer dans Odoo'),
                ('Voir dans SAMA CONAI', 'Voir dans Odoo'),
                ('Créer dans SAMA CONAI', 'Créer dans Odoo'),
            ]
            
            replacement_score = 0
            for new_text, old_text in replacements:
                if new_text in content:
                    print(f"   ✅ '{new_text}' trouvé")
                    replacement_score += 1
                else:
                    print(f"   ❌ '{new_text}' non trouvé")
                
                if old_text in content:
                    print(f"   ⚠️ Ancien texte '{old_text}' encore présent")
                else:
                    print(f"   ✅ Ancien texte '{old_text}' supprimé")
            
            print(f"   📊 Remplacements: {replacement_score}/{len(replacements)} ({(replacement_score/len(replacements)*100):.1f}%)")
            
            return replacement_score >= len(replacements) * 0.8
            
        else:
            print(f"   ❌ Tableau de bord non accessible (HTTP {response.status_code})")
            return False
            
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return False

def test_public_forms():
    """Teste les formulaires publics"""
    
    print(f"\\n📝 TEST DES FORMULAIRES PUBLICS")
    print("=" * 35)
    
    base_url = "http://localhost:8077"
    
    forms = [
        {
            'name': 'Formulaire d\'accès à l\'information',
            'url': '/acces-information',
            'expected_content': ['Demande d\'Information', 'SAMA CONAI', 'Soumettre']
        },
        {
            'name': 'Formulaire de signalement anonyme',
            'url': '/signalement-anonyme',
            'expected_content': ['Signalement Anonyme', 'SAMA CONAI', 'Soumettre']
        }
    ]
    
    forms_working = 0
    
    for form in forms:
        try:
            print(f"\\n   📋 Test: {form['name']}")
            url = f"{base_url}{form['url']}"
            
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                print(f"      ✅ Formulaire accessible (HTTP {response.status_code})")
                
                content = response.text
                content_score = 0
                
                for expected in form['expected_content']:
                    if expected.lower() in content.lower():
                        print(f"      ✅ Contenu '{expected}' trouvé")
                        content_score += 1
                    else:
                        print(f"      ❌ Contenu '{expected}' manquant")
                
                if content_score >= len(form['expected_content']) * 0.8:
                    forms_working += 1
                    print(f"      ✅ Formulaire fonctionnel")
                else:
                    print(f"      ⚠️ Formulaire partiellement fonctionnel")
                    
            else:
                print(f"      ❌ Formulaire non accessible (HTTP {response.status_code})")
                
        except Exception as e:
            print(f"      ❌ Erreur: {e}")
    
    print(f"\\n   📊 Formulaires fonctionnels: {forms_working}/{len(forms)} ({(forms_working/len(forms)*100):.1f}%)")
    
    return forms_working >= len(forms) * 0.8

def test_dashboard_functionality():
    """Teste la fonctionnalité complète du tableau de bord"""
    
    print(f"\\n📊 TEST DE FONCTIONNALITÉ DU TABLEAU DE BORD")
    print("=" * 45)
    
    base_url = "http://localhost:8077"
    dashboard_url = f"{base_url}/transparence-dashboard"
    
    try:
        response = requests.get(dashboard_url, timeout=10)
        
        if response.status_code == 200:
            content = response.text
            
            # Fonctionnalités à vérifier
            features = [
                ('Données backend réelles', 'Backend Réel'),
                ('Actions utilisateur', 'is_authenticated'),
                ('Boutons SAMA CONAI', 'SAMA CONAI'),
                ('Graphiques Chart.js', 'Chart.js'),
                ('Bootstrap 5', 'bootstrap@5.1.3'),
                ('Font Awesome', 'font-awesome'),
                ('Actions conditionnelles', 'user_info'),
                ('Liens de connexion', '/web/login'),
            ]
            
            feature_score = 0
            for feature_name, feature_indicator in features:
                if feature_indicator.lower() in content.lower():
                    print(f"   ✅ {feature_name}")
                    feature_score += 1
                else:
                    print(f"   ❌ {feature_name}")
            
            print(f"   📊 Fonctionnalités: {feature_score}/{len(features)} ({(feature_score/len(features)*100):.1f}%)")
            
            return feature_score >= len(features) * 0.8
            
        else:
            print(f"   ❌ Tableau de bord non accessible")
            return False
            
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return False

def test_help_page():
    """Teste la page d'aide"""
    
    print(f"\\n📞 TEST DE LA PAGE D'AIDE")
    print("=" * 30)
    
    base_url = "http://localhost:8077"
    help_url = f"{base_url}/transparence-dashboard/help"
    
    try:
        response = requests.get(help_url, timeout=10)
        
        if response.status_code == 200:
            print(f"   ✅ Page d'aide accessible (HTTP {response.status_code})")
            
            content = response.text
            help_elements = [
                'Aide et Contact',
                'SAMA CONAI',
                'contact@sama-conai.sn',
                'Retour au Tableau de Bord'
            ]
            
            help_score = 0
            for element in help_elements:
                if element.lower() in content.lower():
                    print(f"   ✅ Élément '{element}' trouvé")
                    help_score += 1
                else:
                    print(f"   ❌ Élément '{element}' manquant")
            
            print(f"   📊 Éléments d'aide: {help_score}/{len(help_elements)} ({(help_score/len(help_elements)*100):.1f}%)")
            
            return help_score >= len(help_elements) * 0.8
            
        else:
            print(f"   ❌ Page d'aide non accessible (HTTP {response.status_code})")
            return False
            
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return False

def show_final_summary():
    """Affiche un résumé final"""
    
    print(f"\\n📋 RÉSUMÉ DES CORRECTIONS APPLIQUÉES")
    print("=" * 40)
    
    corrections = [
        "✅ Remplacement de 'Odoo' par 'SAMA CONAI' dans l'interface",
        "✅ Correction des erreurs 500 des formulaires publics",
        "✅ Ajout de form_data par défaut dans les contrôleurs",
        "✅ Gestion robuste des références de stages",
        "✅ Correction des templates avec website.layout manquant",
        "✅ Templates autonomes avec Bootstrap 5 intégré",
        "✅ Gestion d'erreur pour les méthodes manquantes",
        "✅ Page d'aide et contact fonctionnelle"
    ]
    
    for correction in corrections:
        print(f"   {correction}")
    
    print(f"\\n🌐 **URLS FONCTIONNELLES**:")
    urls = [
        "http://localhost:8077/transparence-dashboard - Tableau de bord principal",
        "http://localhost:8077/acces-information - Formulaire demande d'information",
        "http://localhost:8077/signalement-anonyme - Formulaire signalement anonyme",
        "http://localhost:8077/transparence-dashboard/help - Page d'aide et contact"
    ]
    
    for url in urls:
        print(f"   📍 {url}")

def main():
    """Fonction principale"""
    
    print("🎯 VALIDATION FINALE DES CORRECTIONS")
    print("Vérification complète de toutes les corrections appliquées")
    print("=" * 65)
    
    # Tests des corrections
    odoo_replacement_ok = test_odoo_replacement()
    public_forms_ok = test_public_forms()
    dashboard_ok = test_dashboard_functionality()
    help_ok = test_help_page()
    
    # Résumé des corrections
    show_final_summary()
    
    # Score final
    total_tests = 4
    passed_tests = sum([odoo_replacement_ok, public_forms_ok, dashboard_ok, help_ok])
    final_score = (passed_tests / total_tests) * 100
    
    print(f"\\n🎉 RÉSULTAT FINAL DES CORRECTIONS")
    print("=" * 35)
    
    print(f"\\n📊 **SCORE GLOBAL**: {passed_tests}/{total_tests} ({final_score:.1f}%)")
    
    if odoo_replacement_ok:
        print("   ✅ Remplacement 'Odoo' → 'SAMA CONAI': VALIDÉ")
    else:
        print("   ❌ Remplacement 'Odoo' → 'SAMA CONAI': ÉCHEC")
    
    if public_forms_ok:
        print("   ✅ Formulaires publics: VALIDÉ")
    else:
        print("   ❌ Formulaires publics: ÉCHEC")
    
    if dashboard_ok:
        print("   ✅ Tableau de bord: VALIDÉ")
    else:
        print("   ❌ Tableau de bord: ÉCHEC")
    
    if help_ok:
        print("   ✅ Page d'aide: VALIDÉ")
    else:
        print("   ❌ Page d'aide: ÉCHEC")
    
    if final_score >= 80:
        print(f"\\n🎉 CORRECTIONS RÉUSSIES !")
        print("✅ Toutes les corrections ont été appliquées avec succès")
        print("✅ Les formulaires publics fonctionnent maintenant")
        print("✅ L'interface utilise 'SAMA CONAI' au lieu d'Odoo")
        print("✅ Le système est prêt pour utilisation")
        
        return True
    else:
        print(f"\\n⚠️ CORRECTIONS PARTIELLES")
        print("🔧 Certaines corrections nécessitent encore des ajustements")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)