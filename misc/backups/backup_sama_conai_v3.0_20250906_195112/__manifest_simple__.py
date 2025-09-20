# -*- coding: utf-8 -*-
{
    'name': 'SAMA CONAI - Transparence Sénégal',
    'version': '18.0.1.0.0',
    'category': 'Administration',
    'summary': 'Module de conformité avec les lois sénégalaises sur l\'accès à l\'information et la protection des lanceurs d\'alerte',
    'description': """
Module Odoo 18 CE pour la conformité avec les lois sénégalaises
================================================================

Ce module implémente deux applications principales :

1. **Accès à l'Information**
   - Gestion des demandes d'accès à l'information publique
   - Workflow de traitement et validation
   - Respect des délais légaux (30 jours)

2. **Signalement d'Alerte** 
   - Protection des lanceurs d'alerte
   - Signalement anonyme sécurisé
   - Gestion confidentielle des alertes

Fonctionnalités :
- Interface Kanban pour le suivi des demandes
- Rapports et analyses statistiques
- Sécurité renforcée pour les alertes
- Conformité avec la législation sénégalaise
    """,
    'author': 'SAMA CONAI',
    'website': 'https://www.sama-conai.sn',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'mail',
    ],
    'data': [
        # Security
        'security/security_groups.xml',
        'security/ir.model.access.csv',
        
        # Data
        'data/information_request_stages.xml',
        'data/refusal_reasons.xml',
        'data/whistleblowing_stages.xml',
        'data/sequences.xml',
        
        # Views - Information Request
        'views/information_request_views.xml',
        'views/information_request_stage_views.xml',
        'views/refusal_reason_views.xml',
        
        # Views - Whistleblowing
        'views/whistleblowing_alert_views.xml',
        'views/whistleblowing_stage_views.xml',
        
        # Menus
        'views/menus.xml',
    ],
    'demo': [
        # Démo minimale par modèle (vague 1)
        'data/demo_wave_1_minimal.xml',
    ],
    'installable': True,
    'auto_install': False,
    'application': True,
    'sequence': 10,
}