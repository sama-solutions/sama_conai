#!/usr/bin/env python3
"""
SAMA CONAI - Test simple sans dépendances externes
Vérifie la structure et le contenu des fichiers
"""

import os
import sys
import time

class SimpleFormationTester:
    def __init__(self):
        self.tests_passed = 0
        self.tests_failed = 0
        self.errors = []
    
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
    
    def test_file_exists(self, filepath, description):
        """Tester l'existence d'un fichier"""
        if os.path.exists(filepath):
            self.log(f"✓ {description} existe", "SUCCESS")
            return True
        else:
            self.log(f"✗ {description} manquant: {filepath}", "ERROR")
            self.errors.append(f"Fichier manquant: {filepath}")
            return False
    
    def test_file_content(self, filepath, required_content, description):
        """Tester le contenu d'un fichier"""
        if not os.path.exists(filepath):
            self.log(f"✗ {description} - fichier inexistant", "ERROR")
            return False
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            found_items = 0
            total_items = len(required_content)
            
            for item in required_content:
                if item in content:
                    found_items += 1
                else:
                    self.log(f"  ✗ Manque: {item}", "WARNING")
            
            if found_items == total_items:
                self.log(f"✓ {description} - contenu complet ({found_items}/{total_items})", "SUCCESS")
                return True
            elif found_items >= total_items * 0.8:  # 80% du contenu présent
                self.log(f"⚠ {description} - contenu partiel ({found_items}/{total_items})", "WARNING")
                return True
            else:
                self.log(f"✗ {description} - contenu insuffisant ({found_items}/{total_items})", "ERROR")
                return False
                
        except Exception as e:
            self.log(f"✗ Erreur lecture {description}: {e}", "ERROR")
            return False
    
    def test_html_structure(self):
        """Tester la structure HTML des formations"""
        self.log("Test de la structure HTML...")
        
        html_files = [
            ('formation/citoyen.html', 'Formation Citoyen'),
            ('formation/agent.html', 'Formation Agent'),
            ('formation/administrateur.html', 'Formation Administrateur'),
            ('formation/formateur.html', 'Formation Formateur')
        ]
        
        passed = 0
        for filepath, description in html_files:
            if self.test_file_exists(filepath, description):
                passed += 1
        
        if passed == len(html_files):
            self.tests_passed += 1
        else:
            self.tests_failed += 1
        
        return passed == len(html_files)
    
    def test_javascript_functionality(self):
        """Tester les fichiers JavaScript"""
        self.log("Test des fichiers JavaScript...")
        
        # Test formation.js
        formation_js_content = [
            'startFormation',
            'nextLesson',
            'previousLesson',
            'checkQuiz',
            'toggleModule',
            'showLesson',
            'updateProgress',
            'saveFormationState',
            'loadFormationState'
        ]
        
        js_passed = 0
        
        if self.test_file_exists('assets/js/formation.js', 'Script de formation'):
            if self.test_file_content('assets/js/formation.js', formation_js_content, 'Fonctions de formation'):
                js_passed += 1
        
        # Test main.js
        main_js_content = [
            'initNavigation',
            'initAnimations',
            'initForms',
            'SAMA',
            'DOMContentLoaded'
        ]
        
        if self.test_file_exists('assets/js/main.js', 'Script principal'):
            if self.test_file_content('assets/js/main.js', main_js_content, 'Fonctions principales'):
                js_passed += 1
        
        if js_passed == 2:
            self.tests_passed += 1
            return True
        else:
            self.tests_failed += 1
            return False
    
    def test_css_styles(self):
        """Tester les fichiers CSS"""
        self.log("Test des fichiers CSS...")
        
        # Test formation.css
        formation_css_content = [
            '.formation-hero',
            '.lesson-section',
            '.quiz-section',
            '.lesson-navigation',
            '.progress-card',
            '.module-list'
        ]
        
        css_passed = 0
        
        if self.test_file_exists('assets/css/formation.css', 'Styles de formation'):
            if self.test_file_content('assets/css/formation.css', formation_css_content, 'Classes de formation'):
                css_passed += 1
        
        # Test style.css
        style_css_content = [
            ':root',
            '.navbar',
            '.btn',
            '.card',
            '.alert',
            'responsive'
        ]
        
        if self.test_file_exists('assets/css/style.css', 'Styles principaux'):
            if self.test_file_content('assets/css/style.css', style_css_content, 'Classes principales'):
                css_passed += 1
        
        if css_passed == 2:
            self.tests_passed += 1
            return True
        else:
            self.tests_failed += 1
            return False
    
    def test_formation_citoyen_content(self):
        """Tester le contenu de la formation citoyen"""
        self.log("Test du contenu Formation Citoyen...")
        
        if not os.path.exists('formation/citoyen.html'):
            self.log("✗ Formation Citoyen inexistante", "ERROR")
            self.tests_failed += 1
            return False
        
        # Vérifier les leçons
        required_lessons = [
            'lesson-1.1',
            'lesson-1.2', 
            'lesson-1.3',
            'lesson-2.1',
            'lesson-2.2',
            'lesson-2.3'
        ]
        
        # Vérifier les fonctionnalités
        required_features = [
            'startFormation()',
            'nextLesson(',
            'checkQuiz()',
            'quiz-section',
            'learning-objectives',
            'lesson-navigation'
        ]
        
        content_passed = 0
        
        if self.test_file_content('formation/citoyen.html', required_lessons, 'Leçons de base'):
            content_passed += 1
        
        if self.test_file_content('formation/citoyen.html', required_features, 'Fonctionnalités interactives'):
            content_passed += 1
        
        if content_passed == 2:
            self.tests_passed += 1
            return True
        else:
            self.tests_failed += 1
            return False
    
    def test_server_scripts(self):
        """Tester les scripts de serveur"""
        self.log("Test des scripts de serveur...")
        
        server_files = [
            ('launch.py', 'Lanceur principal'),
            ('start_server.py', 'Serveur avancé'),
            ('start.sh', 'Script bash'),
            ('check_server.py', 'Vérificateur')
        ]
        
        passed = 0
        for filepath, description in server_files:
            if self.test_file_exists(filepath, description):
                passed += 1
        
        if passed >= 3:  # Au moins 3 scripts présents
            self.tests_passed += 1
            return True
        else:
            self.tests_failed += 1
            return False
    
    def test_directory_structure(self):
        """Tester la structure des répertoires"""
        self.log("Test de la structure des répertoires...")
        
        required_dirs = [
            'assets',
            'assets/css',
            'assets/js',
            'formation',
            'certification'
        ]
        
        passed = 0
        for directory in required_dirs:
            if os.path.isdir(directory):
                self.log(f"✓ Répertoire {directory} existe", "SUCCESS")
                passed += 1
            else:
                self.log(f"✗ Répertoire {directory} manquant", "ERROR")
        
        if passed == len(required_dirs):
            self.tests_passed += 1
            return True
        else:
            self.tests_failed += 1
            return False
    
    def run_all_tests(self):
        """Exécuter tous les tests"""
        self.log("🚀 Démarrage des tests SAMA CONAI Formation")
        self.log("=" * 60)
        
        start_time = time.time()
        
        # Tests principaux
        tests = [
            ("Structure des répertoires", self.test_directory_structure),
            ("Structure HTML", self.test_html_structure),
            ("Fonctionnalités JavaScript", self.test_javascript_functionality),
            ("Styles CSS", self.test_css_styles),
            ("Contenu Formation Citoyen", self.test_formation_citoyen_content),
            ("Scripts de serveur", self.test_server_scripts)
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
        self.log(f"✅ Tests réussis: {self.tests_passed}")
        self.log(f"❌ Tests échoués: {self.tests_failed}")
        self.log(f"⏱️ Durée: {duration} secondes")
        
        total_tests = self.tests_passed + self.tests_failed
        if total_tests > 0:
            success_rate = round((self.tests_passed / total_tests) * 100, 1)
            self.log(f"📈 Taux de réussite: {success_rate}%")
            
            if success_rate >= 80:
                self.log("🎉 EXCELLENT! Formation prête pour utilisation", "SUCCESS")
                status = "SUCCESS"
            elif success_rate >= 60:
                self.log("👍 BIEN! Quelques améliorations nécessaires", "WARNING")
                status = "WARNING"
            else:
                self.log("⚠️ ATTENTION! Corrections importantes requises", "ERROR")
                status = "ERROR"
        
        if self.errors:
            self.log("\n🔍 Erreurs détectées:")
            for error in self.errors:
                self.log(f"  • {error}", "ERROR")
        
        return {
            'tests_passed': self.tests_passed,
            'tests_failed': self.tests_failed,
            'success_rate': success_rate if total_tests > 0 else 0,
            'status': status if total_tests > 0 else 'ERROR',
            'errors': self.errors
        }

def main():
    """Fonction principale"""
    print("🌐 SAMA CONAI - Test Simple de Formation")
    print("=" * 60)
    
    # Changer vers le répertoire du script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # Exécuter les tests
    tester = SimpleFormationTester()
    results = tester.run_all_tests()
    
    # Recommandations
    print("\n💡 RECOMMANDATIONS:")
    if results['status'] == 'SUCCESS':
        print("  • Formation prête pour tests utilisateur")
        print("  • Déploiement possible en environnement de test")
        print("  • Continuer le développement des autres formations")
    elif results['status'] == 'WARNING':
        print("  • Corriger les problèmes identifiés")
        print("  • Tester les fonctionnalités JavaScript dans le navigateur")
        print("  • Valider le contenu pédagogique")
    else:
        print("  • Corriger les erreurs critiques avant de continuer")
        print("  • Vérifier l'installation des dépendances")
        print("  • Revoir la structure des fichiers")
    
    # Code de sortie
    if results['tests_failed'] == 0:
        print("\n🎯 Tous les tests sont passés!")
        return 0
    else:
        print(f"\n⚠️ {results['tests_failed']} test(s) ont échoué")
        return 1

if __name__ == "__main__":
    exit(main())