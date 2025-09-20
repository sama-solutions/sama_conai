#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de validation pour s'assurer qu'aucun champ HTML n'a tracking=True
"""

import os
import re

def validate_no_html_tracking():
    """
    Valide qu'aucun champ HTML n'a tracking=True dans les fichiers Python
    """
    print("🔍 Validation des champs HTML sans tracking...")
    
    models_dir = "models"
    issues_found = []
    
    if not os.path.exists(models_dir):
        print(f"❌ Répertoire {models_dir} non trouvé")
        return False
    
    for filename in os.listdir(models_dir):
        if filename.endswith('.py'):
            filepath = os.path.join(models_dir, filename)
            
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Rechercher les patterns problématiques
            # Pattern 1: fields.Html(...tracking=True...)
            pattern1 = r'fields\.Html\([^)]*tracking\s*=\s*True[^)]*\)'
            matches1 = re.findall(pattern1, content, re.DOTALL)
            
            # Pattern 2: tracking=True après fields.Html
            lines = content.split('\n')
            in_html_field = False
            html_field_start = 0
            
            for i, line in enumerate(lines):
                if 'fields.Html(' in line:
                    in_html_field = True
                    html_field_start = i + 1
                elif in_html_field and line.strip().endswith(')'):
                    in_html_field = False
                elif in_html_field and 'tracking=True' in line:
                    issues_found.append({
                        'file': filepath,
                        'line': i + 1,
                        'content': line.strip()
                    })
            
            if matches1:
                for match in matches1:
                    issues_found.append({
                        'file': filepath,
                        'line': 'pattern',
                        'content': match
                    })
    
    if issues_found:
        print("❌ Problèmes trouvés :")
        for issue in issues_found:
            print(f"   📁 {issue['file']} (ligne {issue['line']})")
            print(f"      {issue['content']}")
        return False
    else:
        print("✅ Aucun champ HTML avec tracking=True trouvé")
        print("✅ Validation réussie !")
        return True

if __name__ == '__main__':
    validate_no_html_tracking()