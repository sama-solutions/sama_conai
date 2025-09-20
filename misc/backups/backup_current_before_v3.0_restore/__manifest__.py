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
        'portal',
        'hr',
    ],
    'data': [
        'security/ir.model.access.csv',
        'security/security.xml',
        'data/ir_sequence.xml',
        'data/demo_content_enriched.xml',
        'views/information_request_views.xml',
        'views/information_request_stage_views.xml',
        'views/whistleblowing_alert_views.xml',
        'views/whistleblowing_alert_stage_views.xml',
        'views/menu_views.xml',
        'data/email_templates.xml',
    ],
    'demo': [
        # Données de démo par vagues progressives
        'data/demo_wave_1_minimal.xml',      # Vague 1: Données minimales
        'data/demo_wave_2_extended.xml',     # Vague 2: Données étendues
        'data/demo_wave_3_advanced.xml',     # Vague 3: Données avancées
        'data/analytics/demo_analytics_simple.xml', # Données de démo Analytics
    ],
    'installable': True,
    'auto_install': False,
    'application': True,
    'sequence': 10,
}