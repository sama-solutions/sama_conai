#!/usr/bin/env python3
"""
SAMA CONAI - Script de test automatisé
Teste les fonctionnalités de la formation
"""

import requests
import time
import json
from urllib.parse import urljoin

class FormationTester:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        self.session = requests.Session()
        self.results = {
            'tests_passed': 0,
            'tests_failed': 0,
            'errors': []
        }
    
    def log(self, message, status="INFO"):
        timestamp = time.strftime('%H:%M:%S')
        status_icons = {
            'INFO': 'ℹ️',
            'SUCCESS': '✅',
            'ERROR': '❌',
            'WARNING': '⚠️'
        }
        icon = status_icons.get(status, 'ℹ️')
        print(f"[{timestamp}] {icon} {message}")
    
    def test_server_connection(self):
        """Tester la connexion au serveur"""
        self.log("Test de connexion au serveur...")
        try:
            response = self.session.get(self.base_url, timeout=5)
            if response.status_code == 200:
                self.log("Serveur accessible", "SUCCESS")
                self.results['tests_passed'] += 1
                return True
            else:
                self.log(f"Serveur répond avec le code {response.status_code}", "ERROR")
                self.results['tests_failed'] += 1
                return False
        except Exception as e:
            self.log(f"Erreur de connexion: {e}", "ERROR")
            self.results['tests_failed'] += 1
            return False
    
    def test_formation_citoyen_page(self):
        """Tester la page de formation citoyen"""
        self.log("Test de la page Formation Citoyen...")
        try:
            url = urljoin(self.base_url, "/formation/citoyen.html")
            response = self.session.get(url, timeout=5)
            
            if response.status_code == 200:
                content = response.text
                
                # Vérifier la présence des éléments essentiels
                checks = [
                    ('Formation Citoyen', 'Titre de la formation'),
                    ('lesson-section', 'Sections de leçons'),
                    ('formation.js', 'Script JavaScript de formation'),
                    ('main.js', 'Script JavaScript principal'),
                    ('formation.css', 'Styles de formation'),
                    ('startFormation()', 'Fonction de démarrage'),
                    ('nextLesson()', 'Fonction de navigation'),
                    ('checkQuiz()', 'Fonction de quiz'),
                    ('lesson-1.1', 'Première leçon'),
                    ('quiz-section', 'Sections de quiz')
                ]
                
                passed_checks = 0
                for check_text, description in checks:
                    if check_text in content:
                        self.log(f"✓ {description} trouvé", "SUCCESS")
                        passed_checks += 1
                    else:
                        self.log(f"✗ {description} manquant", "ERROR")
                        self.results['errors'].append(f"Manque: {description}")
                
                if passed_checks == len(checks):
                    self.log("Page Formation Citoyen complète", "SUCCESS")
                    self.results['tests_passed'] += 1
                    return True
                else:
                    self.log(f"Page incomplète: {passed_checks}/{len(checks)} éléments", "WARNING")
                    self.results['tests_failed'] += 1
                    return False
            else:
                self.log(f"Page inaccessible: {response.status_code}", "ERROR")
                self.results['tests_failed'] += 1
                return False
                
        except Exception as e:
            self.log(f"Erreur lors du test de la page: {e}", "ERROR")
            self.results['tests_failed'] += 1
            return False
    
    def test_javascript_files(self):
        """Tester l'accessibilité des fichiers JavaScript"""
        self.log("Test des fichiers JavaScript...")
        
        js_files = [
            ('/assets/js/formation.js', 'Script de formation'),
            ('/assets/js/main.js', 'Script principal')
        ]
        
        all_passed = True
        for js_path, description in js_files:
            try:
                url = urljoin(self.base_url, js_path)
                response = self.session.get(url, timeout=5)
                
                if response.status_code == 200:
                    content = response.text
                    
                    # Vérifier le contenu du fichier
                    if js_path.endswith('formation.js'):
                        required_functions = [
                            'startFormation',
                            'nextLesson',
                            'previousLesson',
                            'checkQuiz',
                            'toggleModule',
                            'showLesson'
                        ]
                        
                        for func in required_functions:
                            if func in content:
                                self.log(f"✓ Fonction {func} trouvée", "SUCCESS")
                            else:
                                self.log(f"✗ Fonction {func} manquante", "ERROR")
                                all_passed = False
                    
                    self.log(f"✓ {description} accessible", "SUCCESS")
                else:
                    self.log(f"✗ {description} inaccessible: {response.status_code}", "ERROR")
                    all_passed = False
                    
            except Exception as e:
                self.log(f"✗ Erreur avec {description}: {e}", "ERROR")
                all_passed = False
        
        if all_passed:
            self.results['tests_passed'] += 1
        else:
            self.results['tests_failed'] += 1
        
        return all_passed
    
    def test_css_files(self):
        """Tester l'accessibilité des fichiers CSS"""
        self.log("Test des fichiers CSS...")
        
        css_files = [
            ('/assets/css/style.css', 'Styles principaux'),
            ('/assets/css/formation.css', 'Styles de formation')
        ]
        
        all_passed = True
        for css_path, description in css_files:
            try:
                url = urljoin(self.base_url, css_path)
                response = self.session.get(url, timeout=5)
                
                if response.status_code == 200:
                    content = response.text
                    
                    # Vérifier la présence de classes importantes
                    if css_path.endswith('formation.css'):
                        required_classes = [
                            '.lesson-section',
                            '.quiz-section',
                            '.formation-hero',
                            '.lesson-navigation'
                        ]
                        
                        for css_class in required_classes:
                            if css_class in content:
                                self.log(f"✓ Classe {css_class} trouvée", "SUCCESS")
                            else:
                                self.log(f"✗ Classe {css_class} manquante", "ERROR")
                                all_passed = False
                    
                    self.log(f"✓ {description} accessible", "SUCCESS")
                else:
                    self.log(f"✗ {description} inaccessible: {response.status_code}", "ERROR")
                    all_passed = False
                    
            except Exception as e:
                self.log(f"✗ Erreur avec {description}: {e}", "ERROR")
                all_passed = False
        
        if all_passed:
            self.results['tests_passed'] += 1
        else:
            self.results['tests_failed'] += 1
        
        return all_passed
    
    def test_other_formation_pages(self):
        """Tester les autres pages de formation"""
        self.log("Test des autres pages de formation...")
        
        pages = [
            ('/formation/agent.html', 'Formation Agent'),
            ('/formation/administrateur.html', 'Formation Administrateur'),
            ('/formation/formateur.html', 'Formation Formateur')
        ]
        
        accessible_pages = 0
        for page_path, description in pages:
            try:
                url = urljoin(self.base_url, page_path)
                response = self.session.get(url, timeout=5)
                
                if response.status_code == 200:
                    self.log(f"✓ {description} accessible", "SUCCESS")
                    accessible_pages += 1
                else:
                    self.log(f"✗ {description} inaccessible: {response.status_code}", "ERROR")
                    
            except Exception as e:
                self.log(f"✗ Erreur avec {description}: {e}", "ERROR")
        
        if accessible_pages == len(pages):
            self.results['tests_passed'] += 1
            return True
        else:
            self.log(f"Seulement {accessible_pages}/{len(pages)} pages accessibles", "WARNING")
            self.results['tests_failed'] += 1
            return False
    
    def test_certification_pages(self):
        """Tester les pages de certification"""
        self.log("Test des pages de certification...")
        
        pages = [
            ('/certification/utilisateur.html', 'Certification Utilisateur'),
            ('/certification/formateur.html', 'Certification Formateur'),
            ('/certification/expert.html', 'Certification Expert')
        ]
        
        accessible_pages = 0
        for page_path, description in pages:
            try:
                url = urljoin(self.base_url, page_path)
                response = self.session.get(url, timeout=5)
                
                if response.status_code == 200:
                    self.log(f"✓ {description} accessible", "SUCCESS")
                    accessible_pages += 1
                else:
                    self.log(f"✗ {description} inaccessible: {response.status_code}", "ERROR")
                    
            except Exception as e:
                self.log(f"✗ Erreur avec {description}: {e}", "ERROR")
        
        if accessible_pages >= len(pages) // 2:  # Au moins la moitié accessible
            self.results['tests_passed'] += 1
            return True
        else:
            self.results['tests_failed'] += 1
            return False
    
    def run_all_tests(self):
        """Exécuter tous les tests"""
        self.log("🚀 Démarrage des tests SAMA CONAI Formation")
        self.log("=" * 60)
        
        start_time = time.time()
        
        # Tests principaux
        tests = [
            ("Connexion serveur", self.test_server_connection),
            ("Page Formation Citoyen", self.test_formation_citoyen_page),
            ("Fichiers JavaScript", self.test_javascript_files),
            ("Fichiers CSS", self.test_css_files),
            ("Autres formations", self.test_other_formation_pages),
            ("Pages certification", self.test_certification_pages)
        ]
        
        for test_name, test_func in tests:
            self.log(f"\n📋 Test: {test_name}")
            self.log("-" * 40)
            test_func()
        
        # Résultats finaux
        end_time = time.time()
        duration = round(end_time - start_time, 2)
        
        self.log("\n" + "=" * 60)
        self.log("📊 RÉSULTATS FINAUX")
        self.log("=" * 60)
        self.log(f"✅ Tests réussis: {self.results['tests_passed']}")
        self.log(f"❌ Tests échoués: {self.results['tests_failed']}")
        self.log(f"⏱️ Durée: {duration} secondes")
        
        total_tests = self.results['tests_passed'] + self.results['tests_failed']
        if total_tests > 0:
            success_rate = round((self.results['tests_passed'] / total_tests) * 100, 1)
            self.log(f"📈 Taux de réussite: {success_rate}%")
            
            if success_rate >= 80:
                self.log("🎉 EXCELLENT! Formation prête pour utilisation", "SUCCESS")
            elif success_rate >= 60:
                self.log("👍 BIEN! Quelques améliorations nécessaires", "WARNING")
            else:
                self.log("⚠️ ATTENTION! Corrections importantes requises", "ERROR")
        
        if self.results['errors']:
            self.log("\n🔍 Erreurs détectées:")
            for error in self.results['errors']:
                self.log(f"  • {error}", "ERROR")
        
        return self.results

def main():
    """Fonction principale"""
    print("🌐 SAMA CONAI - Test Automatisé de Formation")
    print("=" * 60)
    
    # Vérifier si le serveur est accessible
    tester = FormationTester()
    
    # Attendre un peu que le serveur soit prêt
    print("⏳ Attente du démarrage du serveur...")
    time.sleep(2)
    
    # Exécuter les tests
    results = tester.run_all_tests()
    
    # Code de sortie basé sur les résultats
    if results['tests_failed'] == 0:
        print("\n🎯 Tous les tests sont passés!")
        return 0
    else:
        print(f"\n⚠️ {results['tests_failed']} test(s) ont échoué")
        return 1

if __name__ == "__main__":
    exit(main())