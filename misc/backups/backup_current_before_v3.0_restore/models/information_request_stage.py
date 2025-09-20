# -*- coding: utf-8 -*-

from odoo import models, fields, api, _


class InformationRequestStage(models.Model):
    _name = 'request.information.stage'
    _description = 'Étape de Demande d\'Information'
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
        help="Ordre d'affichage des étapes"
    )
    fold = fields.Boolean(
        string='Replier dans Kanban',
        default=False,
        help="Cette étape sera repliée dans la vue kanban"
    )
    active = fields.Boolean(
        string='Actif',
        default=True
    )
    
    # Couleurs pour l'affichage
    color = fields.Integer(
        string='Couleur',
        default=0,
        help="Couleur de l'étape dans la vue kanban"
    )
    
    # Règles métier
    is_initial = fields.Boolean(
        string='Étape Initiale',
        default=False,
        help="Étape par défaut pour les nouvelles demandes"
    )
    is_final = fields.Boolean(
        string='Étape Finale',
        default=False,
        help="Étape finale du processus"
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

    @api.model
    def get_default_stage(self):
        """Retourner l'étape par défaut pour les nouvelles demandes"""
        default_stage = self.search([('is_initial', '=', True)], limit=1)
        if not default_stage:
            default_stage = self.search([], order='sequence', limit=1)
        return default_stage

    def action_view_requests(self):
        """Voir les demandes de cette étape"""
        self.ensure_one()
        return {
            'name': _('Demandes - %s') % self.name,
            'type': 'ir.actions.act_window',
            'res_model': 'request.information',
            'view_mode': 'tree,form',
            'domain': [('stage_id', '=', self.id)],
            'context': {'default_stage_id': self.id}
        }


class RefusalReason(models.Model):
    _name = 'request.refusal.reason'
    _description = 'Motif de Refus'
    _order = 'sequence, name'

    name = fields.Char(
        string='Motif',
        required=True,
        translate=True
    )
    description = fields.Text(
        string='Description',
        translate=True
    )
    legal_basis = fields.Text(
        string='Base Légale',
        help="Référence légale justifiant ce motif de refus"
    )
    sequence = fields.Integer(
        string='Séquence',
        default=10
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

    def action_view_refused_requests(self):
        """Voir les demandes refusées avec ce motif"""
        self.ensure_one()
        return {
            'name': _('Demandes Refusées - %s') % self.name,
            'type': 'ir.actions.act_window',
            'res_model': 'request.information',
            'view_mode': 'tree,form',
            'domain': [('refusal_reason_id', '=', self.id)],
            'context': {'default_refusal_reason_id': self.id}
        }