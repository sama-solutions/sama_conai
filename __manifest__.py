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
        # Security
        'security/security_groups.xml',
        'security/ir.model.access.csv',
        
        # Data
        'data/information_request_stages.xml',
        'data/refusal_reasons.xml',
        'data/whistleblowing_stages.xml',
        'data/sequences.xml',
        'data/analytics/cron_jobs.xml',
        
        # Views - Information Request
        'views/information_request_views.xml',
        'views/information_request_stage_views.xml',
        'views/refusal_reason_views.xml',
        
        # Views - Whistleblowing
        'views/whistleblowing_alert_views.xml',
        'views/whistleblowing_stage_views.xml',
        
        # Views - Analytics
        'views/analytics/executive_dashboard_views.xml',
        'views/analytics/auto_report_generator_views.xml',
        
        # Views - Dashboard & KPI
        'views/dashboard_views.xml',
        'views/public_dashboard_actions.xml',
        
        # Views - Administration
        'views/administration_views.xml',
        'views/analytics_filtered_views.xml',
        
        # Portal Templates
        'templates/portal_templates.xml',
        'templates/transparency_dashboard_template.xml',
        'templates/help_contact_template.xml',
        
        # Menus
        'views/menus.xml',
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