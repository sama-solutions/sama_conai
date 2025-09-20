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
   - Portail web pour les citoyens
   - Respect des délais légaux (30 jours)

2. **Signalement d'Alerte** 
   - Protection des lanceurs d'alerte
   - Signalement anonyme sécurisé
   - Gestion confidentielle des alertes
   - Suivi anonyme via token

Fonctionnalités :
- Interface Kanban pour le suivi des demandes
- Notifications automatiques par email
- Rapports et analyses statistiques
- Sécurité renforcée pour les alertes
- Conformité avec la législation sénégalaise
    """,
    'author': 'SAMA CONAI',
    'website': 'https://www.sama-conai.sn',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'web',
        'mail',
        'portal',
        'website',
        'hr',
    ],
    'data': [
        # Security
        'security/security_groups.xml',
        'security/ir.model.access.csv',
        'security/security_rules.xml',
        
        # Data
        'data/information_request_stages.xml',
        'data/refusal_reasons.xml',
        'data/whistleblowing_stages.xml',
        'data/email_templates.xml',
        'data/sequences.xml',

        # One-off demo records to load on upgrade in test DBs
        'data/demo_oneoff_min_records.xml',
        
        # Views - Information Request
        'views/information_request_views.xml',
        'views/information_request_stage_views.xml',
        'views/refusal_reason_views.xml',
        
        # Views - Whistleblowing
        'views/whistleblowing_alert_views.xml',
        'views/whistleblowing_stage_views.xml',
        
        # Menus
        'views/menus.xml',
        
        # Portal Templates
        'templates/portal_templates.xml',
    ],
    'demo': [
        # Démo minimale par modèle (vague 1)
        'data/demo_min_request_information.xml',
        'data/demo_min_whistleblowing_alert.xml',
        # Démo one-off pour charger dans les bases de test existantes
        'data/demo_oneoff_min_records.xml',
        # Démo complète (vagues suivantes)
        'data/demo_data.xml',
    ],
    'assets': {
        'web.assets_frontend': [
            'sama_conai/static/src/css/portal.css',
        ],
        'web.assets_backend': [
            'sama_conai/static/src/css/backend.css',
        ],
    },
    'images': [],
    'installable': True,
    'auto_install': False,
    'application': True,
    'sequence': 10,
}