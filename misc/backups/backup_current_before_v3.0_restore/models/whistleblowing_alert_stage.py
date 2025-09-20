# -*- coding: utf-8 -*-

from odoo import models, fields, api, _


class WhistleblowingAlertStage(models.Model):
    _name = 'whistleblowing.alert.stage'
    _description = 'Étape d\'Alerte Whistleblowing'
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
        help="Étape par défaut pour les nouvelles alertes"
    )
    is_final = fields.Boolean(
        string='Étape Finale',
        default=False,
        help="Étape finale du processus"
    )
    requires_manager = fields.Boolean(
        string='Nécessite un Manager',
        default=False,
        help="Cette étape nécessite l'intervention d'un manager"
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

    @api.model
    def get_default_stage(self):
        """Retourner l'étape par défaut pour les nouvelles alertes"""
        default_stage = self.search([('is_initial', '=', True)], limit=1)
        if not default_stage:
            default_stage = self.search([], order='sequence', limit=1)
        return default_stage

    def action_view_alerts(self):
        """Voir les alertes de cette étape"""
        self.ensure_one()
        return {
            'name': _('Alertes - %s') % self.name,
            'type': 'ir.actions.act_window',
            'res_model': 'whistleblowing.alert',
            'view_mode': 'tree,form',
            'domain': [('stage_id', '=', self.id)],
            'context': {'default_stage_id': self.id}
        }


class WhistleblowingCategory(models.Model):
    _name = 'whistleblowing.category'
    _description = 'Catégorie de Signalement'
    _order = 'sequence, name'

    name = fields.Char(
        string='Nom de la Catégorie',
        required=True,
        translate=True
    )
    description = fields.Text(
        string='Description',
        translate=True
    )
    code = fields.Char(
        string='Code',
        required=True,
        help="Code unique pour cette catégorie"
    )
    sequence = fields.Integer(
        string='Séquence',
        default=10
    )
    active = fields.Boolean(
        string='Actif',
        default=True
    )
    
    # Couleur et icône
    color = fields.Integer(
        string='Couleur',
        default=0
    )
    icon = fields.Char(
        string='Icône',
        help="Classe CSS de l'icône (ex: fa-exclamation-triangle)"
    )
    
    # Règles de traitement
    priority_default = fields.Selection([
        ('low', 'Faible'),
        ('medium', 'Moyenne'),
        ('high', 'Élevée'),
        ('urgent', 'Urgente')
    ], string='Priorité par Défaut', default='medium')
    
    requires_immediate_action = fields.Boolean(
        string='Action Immédiate Requise',
        default=False,
        help="Cette catégorie nécessite une action immédiate"
    )
    
    # Statistiques
    alert_count = fields.Integer(
        string='Nombre d\'Alertes',
        compute='_compute_alert_count'
    )

    @api.depends()
    def _compute_alert_count(self):
        for category in self:
            category.alert_count = self.env['whistleblowing.alert'].search_count([
                ('category', '=', category.code)
            ])

    @api.constrains('code')
    def _check_code_unique(self):
        for record in self:
            if self.search_count([('code', '=', record.code), ('id', '!=', record.id)]) > 0:
                raise ValidationError(_('Le code de catégorie doit être unique.'))

    def action_view_alerts(self):
        """Voir les alertes de cette catégorie"""
        self.ensure_one()
        return {
            'name': _('Alertes - %s') % self.name,
            'type': 'ir.actions.act_window',
            'res_model': 'whistleblowing.alert',
            'view_mode': 'tree,form',
            'domain': [('category', '=', self.code)],
            'context': {'default_category': self.code}
        }