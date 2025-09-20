#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour nettoyer les entrées de tracking sur les champs HTML
qui causent l'erreur NotImplementedError dans Odoo.

Usage:
    python3 fix_html_tracking.py

Ou directement dans Odoo:
    ./odoo-bin shell -c odoo.conf -d your_database
    >>> exec(open('scripts/fix_html_tracking.py').read())
"""

import logging

_logger = logging.getLogger(__name__)

def fix_html_tracking_fields():
    """
    Nettoie les entrées de tracking pour les champs HTML qui ne supportent pas le tracking.
    """
    try:
        # Champs HTML problématiques identifiés
        html_fields_to_fix = [
            ('request.information', 'description'),
            ('request.information', 'response_body'),
            ('whistleblowing.alert', 'description'),
            ('whistleblowing.alert', 'investigation_notes'),
        ]
        
        print("🔧 Début du nettoyage des champs HTML avec tracking...")
        
        for model_name, field_name in html_fields_to_fix:
            print(f"   Traitement du champ {field_name} du modèle {model_name}...")
            
            # Rechercher les entrées dans ir.model.fields
            field_records = env['ir.model.fields'].search([
                ('model', '=', model_name),
                ('name', '=', field_name),
                ('tracking', '=', True)
            ])
            
            if field_records:
                print(f"   ✅ Trouvé {len(field_records)} entrée(s) à corriger")
                # Désactiver le tracking
                field_records.write({'tracking': False})
                print(f"   ✅ Tracking désactivé pour {field_name}")
            else:
                print(f"   ℹ️  Aucune entrée de tracking trouvée pour {field_name}")
        
        # Nettoyer les entrées de mail.tracking.value pour ces champs
        print("\n🧹 Nettoyage des valeurs de tracking existantes...")
        
        for model_name, field_name in html_fields_to_fix:
            tracking_values = env['mail.tracking.value'].search([
                ('field', '=', field_name),
                ('mail_message_id.model', '=', model_name)
            ])
            
            if tracking_values:
                print(f"   ✅ Suppression de {len(tracking_values)} valeur(s) de tracking pour {field_name}")
                tracking_values.unlink()
            else:
                print(f"   ℹ️  Aucune valeur de tracking à supprimer pour {field_name}")
        
        # Commit des changements
        env.cr.commit()
        print("\n✅ Nettoyage terminé avec succès!")
        print("   Vous pouvez maintenant mettre à jour votre module sans erreur.")
        
    except Exception as e:
        print(f"\n❌ Erreur lors du nettoyage: {e}")
        env.cr.rollback()
        raise

if __name__ == '__main__':
    # Si exécuté dans le shell Odoo, 'env' sera disponible
    try:
        fix_html_tracking_fields()
    except NameError:
        print("❌ Ce script doit être exécuté dans le shell Odoo.")
        print("   Usage: ./odoo-bin shell -c odoo.conf -d your_database")
        print("   Puis: exec(open('scripts/fix_html_tracking.py').read())")