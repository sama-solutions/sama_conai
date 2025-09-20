# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from odoo.exceptions import ValidationError, AccessError
import secrets
import string
import logging

_logger = logging.getLogger(__name__)


class WhistleblowingAlert(models.Model):
    _name = 'whistleblowing.alert'
    _description = 'Signalement d\'Alerte'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'alert_date desc, id desc'
    _rec_name = 'name'

    # Champs de base
    name = fields.Char(
        string='Référence',
        required=True,
        copy=False,
        readonly=True,
        default=lambda self: _('Nouveau'),
        tracking=True
    )
    
    # Informations temporelles
    alert_date = fields.Datetime(
        string='Date du Signalement',
        required=True,
        default=fields.Datetime.now,
        tracking=True
    )
    
    # Anonymat
    is_anonymous = fields.Boolean(
        string='Signalement Anonyme',
        default=True,
        tracking=True
    )
    
    # Informations du signalant (ULTRA-SENSIBLES)
    reporter_name = fields.Char(
        string='Nom du Signalant',
        groups='sama_conai.group_whistleblowing_manager',
        tracking=True
    )
    reporter_email = fields.Char(
        string='Email du Signalant',
        groups='sama_conai.group_whistleblowing_manager',
        tracking=True
    )
    reporter_phone = fields.Char(
        string='Téléphone du Signalant',
        groups='sama_conai.group_whistleblowing_manager',
        tracking=True
    )
    
    # Contenu du signalement
    description = fields.Html(
        string='Description du Signalement',
        required=True
    )
    category = fields.Selection([
        ('corruption', 'Corruption'),
        ('fraud', 'Fraude'),
        ('abuse_of_power', 'Abus de Pouvoir'),
        ('discrimination', 'Discrimination'),
        ('harassment', 'Harcèlement'),
        ('safety_violation', 'Violation de Sécurité'),
        ('environmental', 'Violation Environnementale'),
        ('other', 'Autre')
    ], string='Catégorie', required=True, tracking=True)
    
    # Preuves
    evidence_attachment_ids = fields.Many2many(
        'ir.attachment',
        'whistleblowing_alert_attachment_rel',
        'alert_id',
        'attachment_id',
        string='Pièces Justificatives'
    )
    
    # Workflow
    stage_id = fields.Many2one(
        'whistleblowing.alert.stage',
        string='Étape',
        required=True,
        tracking=True,
        group_expand='_read_group_stage_ids'
    )
    manager_id = fields.Many2one(
        'res.users',
        string='Référent Assigné',
        tracking=True,
        domain=[('groups_id', 'in', [])],  # Will be updated in security
    )
    
    # Investigation
    investigation_notes = fields.Html(
        string='Notes d\'Investigation',
        groups='sama_conai.group_whistleblowing_manager'
    )
    investigation_start_date = fields.Date(
        string='Date de Début d\'Investigation',
        tracking=True
    )
    investigation_end_date = fields.Date(
        string='Date de Fin d\'Investigation',
        tracking=True
    )
    
    # Résolution
    resolution = fields.Text(
        string='Résolution',
        tracking=True
    )
    resolution_date = fields.Date(
        string='Date de Résolution',
        tracking=True
    )
    
    # Suivi anonyme
    access_token = fields.Char(
        string='Token d\'Accès',
        copy=False,
        groups='sama_conai.group_whistleblowing_manager'
    )
    access_url = fields.Char(
        string='URL d\'Accès',
        compute='_compute_access_url',
        store=False
    )
    
    # État
    state = fields.Selection([
        ('new', 'Nouveau'),
        ('preliminary_assessment', 'Évaluation Préliminaire'),
        ('investigation', 'Enquête Interne'),
        ('resolved', 'Résolu'),
        ('transmitted', 'Transmis'),
        ('closed', 'Clôturé')
    ], string='État', default='new', tracking=True)
    
    # Priorité
    priority = fields.Selection([
        ('low', 'Faible'),
        ('medium', 'Moyenne'),
        ('high', 'Élevée'),
        ('urgent', 'Urgente')
    ], string='Priorité', default='medium', tracking=True)

    @api.model
    def create(self, vals):
        if vals.get('name', _('Nouveau')) == _('Nouveau'):
            vals['name'] = self.env['ir.sequence'].next_by_code('whistleblowing.alert') or _('Nouveau')
        
        # Générer un token d'accès pour le suivi anonyme
        if not vals.get('access_token'):
            vals['access_token'] = self._generate_access_token()
        
        return super(WhistleblowingAlert, self).create(vals)

    def _generate_access_token(self):
        """Générer un token d'accès sécurisé"""
        alphabet = string.ascii_letters + string.digits
        return ''.join(secrets.choice(alphabet) for _ in range(32))

    @api.model
    def _read_group_stage_ids(self, stages, domain, order=None):
        """Allow kanban column expansion even if 'order' is not provided by caller."""
        order = order or 'sequence, id'
        return self.env['whistleblowing.alert.stage'].search([], order=order)

    @api.constrains('reporter_email')
    def _check_email(self):
        for record in self:
            if record.reporter_email and '@' not in record.reporter_email:
                raise ValidationError(_('Veuillez saisir une adresse email valide.'))

    @api.constrains('investigation_start_date', 'investigation_end_date')
    def _check_investigation_dates(self):
        for record in self:
            if (record.investigation_start_date and record.investigation_end_date and 
                record.investigation_start_date > record.investigation_end_date):
                raise ValidationError(_('La date de fin d\'investigation ne peut pas être antérieure à la date de début.'))

    def action_start_assessment(self):
        """Commencer l'évaluation préliminaire"""
        self.ensure_one()
        self._check_manager_access()
        self.write({
            'state': 'preliminary_assessment',
            'stage_id': self.env.ref('sama_conai.whistleblowing_stage_assessment').id
        })
        return True

    def action_start_investigation(self):
        """Commencer l'enquête interne"""
        self.ensure_one()
        self._check_manager_access()
        self.write({
            'state': 'investigation',
            'stage_id': self.env.ref('sama_conai.whistleblowing_stage_investigation').id,
            'investigation_start_date': fields.Date.today()
        })
        return True

    def action_resolve(self):
        """Marquer comme résolu"""
        self.ensure_one()
        self._check_manager_access()
        if not self.resolution:
            raise ValidationError(_('Veuillez saisir une résolution avant de clôturer.'))
        
        self.write({
            'state': 'resolved',
            'stage_id': self.env.ref('sama_conai.whistleblowing_stage_resolved').id,
            'resolution_date': fields.Date.today(),
            'investigation_end_date': fields.Date.today()
        })
        return True

    def action_transmit(self):
        """Transmettre à une autorité externe"""
        self.ensure_one()
        self._check_manager_access()
        self.write({
            'state': 'transmitted',
            'stage_id': self.env.ref('sama_conai.whistleblowing_stage_transmitted').id
        })
        return True

    def action_close(self):
        """Clôturer le signalement"""
        self.ensure_one()
        self._check_manager_access()
        self.write({
            'state': 'closed',
            'stage_id': self.env.ref('sama_conai.whistleblowing_stage_closed').id
        })
        return True

    def _check_manager_access(self):
        """Vérifier que l'utilisateur a les droits de manager"""
        if not self.env.user.has_group('sama_conai.group_whistleblowing_manager'):
            raise AccessError(_('Seuls les référents d\'alerte peuvent effectuer cette action.'))

    @api.model
    def get_alert_by_token(self, token):
        """Récupérer une alerte par son token (pour le portail anonyme)"""
        alert = self.search([('access_token', '=', token)], limit=1)
        if not alert:
            return False
        
        # Retourner seulement les informations non-sensibles
        return {
            'name': alert.name,
            'alert_date': alert.alert_date,
            'category': alert.category,
            'state': alert.state,
            'stage_name': alert.stage_id.name,
            'resolution': alert.resolution if alert.state in ['resolved', 'closed'] else False,
        }

    def _compute_access_url(self):
        """URL d'accès pour le portail (anonyme)"""
        for alert in self:
            if alert.access_token:
                alert.access_url = '/ws/follow/%s' % alert.access_token
            else:
                alert.access_url = False

    def action_view_portal_anonymous(self):
        """Ouvrir la vue portail anonyme du signalement"""
        self.ensure_one()
        if not self.access_token:
            raise ValidationError(_('Aucun token d\'accès disponible pour ce signalement.'))
        
        return {
            'type': 'ir.actions.act_url',
            'url': self.access_url or '/ws/follow/%s' % self.access_token,
            'target': 'new',
        }

    @api.model
    def message_new(self, msg_dict, custom_values=None):
        """Surcharger pour empêcher la création via email"""
        raise ValidationError(_('Les signalements ne peuvent pas être créés par email pour des raisons de sécurité.'))