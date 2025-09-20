# -*- coding: utf-8 -*-

from odoo import models, fields, api, _


class RefusalReason(models.Model):
    _name = 'request.refusal.reason'
    _description = 'Motifs de Refus des Demandes d\'Information'
    _order = 'sequence, name'

    name = fields.Char(
        string='Motif de Refus',
        required=True,
        translate=True
    )
    description = fields.Text(
        string='Description Détaillée',
        translate=True,
        help='Description complète du motif de refus selon la législation'
    )
    legal_reference = fields.Char(
        string='Référence Légale',
        help='Article de loi ou référence juridique'
    )
    sequence = fields.Integer(
        string='Séquence',
        default=10,
        help='Ordre d\'affichage des motifs'
    )
    active = fields.Boolean(
        string='Actif',
        default=True
    )
    
    # Statistiques
    usage_count = fields.Integer(
        string='Nombre d\'Utilisations',
        compute='_compute_usage_count'
    )

    @api.depends()
    def _compute_usage_count(self):
        for reason in self:
            reason.usage_count = self.env['request.information'].search_count([
                ('refusal_reason_id', '=', reason.id)
            ])

    def action_view_requests(self):
        """Action pour voir les demandes refusées avec ce motif"""
        self.ensure_one()
        return {
            'name': _('Demandes Refusées - %s') % self.name,
            'type': 'ir.actions.act_window',
            'res_model': 'request.information',
            'view_mode': 'tree,form',
            'domain': [('refusal_reason_id', '=', self.id)],
            'context': {'default_refusal_reason_id': self.id}
        }