# -*- coding: utf-8 -*-

from odoo import models, fields, api, _


class WhistleblowingAlertStage(models.Model):
    _name = 'whistleblowing.alert.stage'
    _description = 'Étapes des Signalements d\'Alerte'
    _order = 'sequence, id'

    name = fields.Char(
        string='Nom de l\'Étape',
        required=True,
        translate=True
    )
    description = fields.Text(
        string='Description',
        translate=True
    )
    sequence = fields.Integer(
        string='Séquence',
        default=10,
        help='Ordre d\'affichage des étapes'
    )
    is_closed = fields.Boolean(
        string='Étape de Clôture',
        default=False,
        help='Indique si cette étape marque la fin du processus'
    )
    fold = fields.Boolean(
        string='Plier dans Kanban',
        default=False,
        help='Plier cette étape par défaut dans la vue Kanban'
    )
    
    # Couleurs pour l'affichage
    color = fields.Integer(
        string='Couleur',
        default=0,
        help='Couleur de l\'étape dans la vue Kanban'
    )
    
    # Statistiques
    alert_count = fields.Integer(
        string='Nombre d\'Alertes',
        compute='_compute_alert_count'
    )

    @api.depends()
    def _compute_alert_count(self):
        for stage in self:
            stage.alert_count = self.env['whistleblowing.alert'].search_count([
                ('stage_id', '=', stage.id)
            ])

    def action_view_alerts(self):
        """Action pour voir les alertes de cette étape"""
        self.ensure_one()
        return {
            'name': _('Alertes - %s') % self.name,
            'type': 'ir.actions.act_window',
            'res_model': 'whistleblowing.alert',
            'view_mode': 'tree,form',
            'domain': [('stage_id', '=', self.id)],
            'context': {'default_stage_id': self.id}
        }