# -*- coding: utf-8 -*-

from odoo import models, fields, api
from datetime import timedelta


class ResUsers(models.Model):
    _inherit = 'res.users'

    sama_conai_theme = fields.Selection([
        ('default', 'Thème Institutionnel'),
        ('terre', 'Thème Terre du Sénégal'),
        ('moderne', 'Thème Moderne')
    ], string='Thème SAMA CONAI', default='default',
       help="Choisissez votre thème préféré pour l'interface SAMA CONAI")

    @api.model
    def get_current_user_theme(self):
        """Retourne le thème de l'utilisateur actuel pour les appels RPC"""
        if self.env.user:
            return self.env.user.sama_conai_theme or 'default'
        return 'default'

    def write(self, vals):
        """Override pour notifier les changements de thème"""
        result = super(ResUsers, self).write(vals)
        if 'sama_conai_theme' in vals:
            # Optionnel: ajouter une notification ou un log
            pass
        return result

    def apply_theme_default(self):
        """Applique le thème institutionnel"""
        self.write({'sama_conai_theme': 'default'})
        return {
            'type': 'ir.actions.client',
            'tag': 'reload',
        }

    def apply_theme_terre(self):
        """Applique le thème terre du Sénégal"""
        self.write({'sama_conai_theme': 'terre'})
        return {
            'type': 'ir.actions.client',
            'tag': 'reload',
        }

    def apply_theme_moderne(self):
        """Applique le thème moderne"""
        self.write({'sama_conai_theme': 'moderne'})
        return {
            'type': 'ir.actions.client',
            'tag': 'reload',
        }

    def refresh_dashboard(self):
        """Actualise les données du dashboard"""
        return {
            'type': 'ir.actions.client',
            'tag': 'reload',
        }

    @api.model
    def get_dashboard_data(self):
        """Retourne les données pour le dashboard"""
        # Cette méthode sera utilisée par le contrôleur
        InformationRequest = self.env['request.information']
        WhistleblowingAlert = self.env['whistleblowing.alert']
        
        # Calculs de base
        in_progress_count = InformationRequest.search_count([
            ('state', 'in', ['submitted', 'in_progress', 'pending_validation'])
        ])
        overdue_count = InformationRequest.search_count([
            ('is_overdue', '=', True)
        ])
        
        return {
            'in_progress_count': in_progress_count,
            'overdue_count': overdue_count,
            'total_requests': InformationRequest.search_count([]) + WhistleblowingAlert.search_count([]),
        }