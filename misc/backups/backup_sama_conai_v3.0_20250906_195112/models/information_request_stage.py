# -*- coding: utf-8 -*-

from odoo import models, fields, api, _


class InformationRequestStage(models.Model):
    _name = 'request.information.stage'
    _description = 'Étapes des Demandes d\'Information'
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
    request_count = fields.Integer(
        string='Nombre de Demandes',
        compute='_compute_request_count'
    )

    @api.depends()
    def _compute_request_count(self):
        for stage in self:
            stage.request_count = self.env['request.information'].search_count([
                ('stage_id', '=', stage.id)
            ])

    def action_view_requests(self):
        """Action pour voir les demandes de cette étape"""
        self.ensure_one()
        return {
            'name': _('Demandes - %s') % self.name,
            'type': 'ir.actions.act_window',
            'res_model': 'request.information',
            'view_mode': 'tree,form',
            'domain': [('stage_id', '=', self.id)],
            'context': {'default_stage_id': self.id}
        }