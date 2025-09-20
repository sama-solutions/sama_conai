# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from odoo.exceptions import ValidationError
from datetime import datetime, timedelta
import logging

_logger = logging.getLogger(__name__)


class InformationRequest(models.Model):
    _name = 'request.information'
    _description = 'Demande d\'Accès à l\'Information'
    _inherit = ['mail.thread', 'mail.activity.mixin', 'portal.mixin']
    _order = 'request_date desc, id desc'
    _rec_name = 'name'

    # Champs de base
    name = fields.Char(
        string='Numéro de Demande',
        required=True,
        copy=False,
        readonly=True,
        default=lambda self: _('Nouveau'),
        tracking=True
    )
    
    # Informations du demandeur
    partner_name = fields.Char(
        string='Nom du Demandeur',
        required=True,
        tracking=True
    )
    partner_email = fields.Char(
        string='Email du Demandeur',
        required=True,
        tracking=True
    )
    partner_phone = fields.Char(
        string='Téléphone du Demandeur',
        tracking=True
    )
    requester_quality = fields.Selection([
        ('citizen', 'Citoyen'),
        ('journalist', 'Journaliste'),
        ('researcher', 'Chercheur'),
        ('lawyer', 'Avocat'),
        ('ngo', 'ONG'),
        ('other', 'Autre')
    ], string='Qualité du Demandeur', required=True, tracking=True)
    
    # Détails de la demande
    request_date = fields.Datetime(
        string='Date de Demande',
        required=True,
        default=fields.Datetime.now,
        tracking=True
    )
    description = fields.Html(
        string='Description de la Demande',
        required=True
    )
    
    # Workflow et assignation
    stage_id = fields.Many2one(
        'request.information.stage',
        string='Étape',
        required=True,
        tracking=True,
        group_expand='_read_group_stage_ids'
    )
    user_id = fields.Many2one(
        'res.users',
        string='Responsable',
        tracking=True,
        domain=[('groups_id', 'in', [])],  # Will be updated in security
    )
    department_id = fields.Many2one(
        'hr.department',
        string='Département Concerné',
        tracking=True
    )
    
    # Dates et délais
    deadline_date = fields.Date(
        string='Date Limite de Réponse',
        compute='_compute_deadline_date',
        store=True,
        tracking=True
    )
    response_date = fields.Datetime(
        string='Date de Réponse',
        tracking=True
    )
    
    # Réponse
    response_body = fields.Html(
        string='Corps de la Réponse'
    )
    response_attachment_ids = fields.Many2many(
        'ir.attachment',
        'information_request_attachment_rel',
        'request_id',
        'attachment_id',
        string='Pièces Jointes de Réponse'
    )
    
    # Refus
    is_refusal = fields.Boolean(
        string='Demande Refusée',
        tracking=True
    )
    refusal_reason_id = fields.Many2one(
        'request.refusal.reason',
        string='Motif de Refus',
        tracking=True
    )
    refusal_motivation = fields.Text(
        string='Motivation du Refus',
        tracking=True
    )
    
    # Champs calculés
    is_overdue = fields.Boolean(
        string='En Retard',
        compute='_compute_is_overdue',
        store=True
    )
    days_to_deadline = fields.Integer(
        string='Jours Restants',
        compute='_compute_days_to_deadline',
        search='_search_days_to_deadline'
    )
    
    # Champs de statut
    state = fields.Selection([
        ('draft', 'Brouillon'),
        ('submitted', 'Soumise'),
        ('in_progress', 'En Traitement'),
        ('pending_validation', 'En Attente de Validation'),
        ('responded', 'Répondu'),
        ('refused', 'Refusé'),
        ('redirected', 'Réorientée'),
        ('cancelled', 'Annulée')
    ], string='État', default='draft', tracking=True)

    @api.model
    def create(self, vals):
        if vals.get('name', _('Nouveau')) == _('Nouveau'):
            vals['name'] = self.env['ir.sequence'].next_by_code('request.information') or _('Nouveau')
        return super(InformationRequest, self).create(vals)

    @api.depends('request_date')
    def _compute_deadline_date(self):
        for record in self:
            if record.request_date:
                # Délai légal de 30 jours
                deadline = fields.Datetime.from_string(record.request_date) + timedelta(days=30)
                record.deadline_date = deadline.date()
            else:
                record.deadline_date = False

    @api.depends('deadline_date', 'state')
    def _compute_is_overdue(self):
        today = fields.Date.today()
        for record in self:
            record.is_overdue = (
                record.deadline_date and 
                record.deadline_date < today and 
                record.state not in ['responded', 'refused', 'cancelled']
            )

    @api.depends('deadline_date')
    def _compute_days_to_deadline(self):
        today = fields.Date.today()
        for record in self:
            if record.deadline_date:
                delta = record.deadline_date - today
                record.days_to_deadline = delta.days
            else:
                record.days_to_deadline = 0

    @api.model
    def _read_group_stage_ids(self, stages, domain, order=None):
        """Allow kanban column expansion even if 'order' is not provided by caller.
        Compatible with read_group calling conventions that may omit 'order'.
        """
        order = order or 'sequence, id'
        return self.env['request.information.stage'].search([], order=order)

    def _search_days_to_deadline(self, operator, value):
        """
        Translate search on computed (non-stored) days_to_deadline to a domain on deadline_date.
        days_to_deadline = (deadline_date - today).days
        """
        # Ensure numeric value
        try:
            int_value = int(value)
        except Exception:
            # Fallback: if value is not an int, no match
            return [(0, '=', 1)]  # always false domain

        today = fields.Date.today()
        target_date = today + timedelta(days=int_value)

        # Include records with no deadline_date for operators where 0 would satisfy the comparison
        # Since compute sets days_to_deadline = 0 when no deadline_date
        include_false = operator in ('<', '<=', '!=')

        base_domain = [('deadline_date', operator, target_date)]
        if include_false:
            return ['|', ('deadline_date', '=', False)] + base_domain
        return base_domain

    @api.constrains('partner_email')
    def _check_email(self):
        for record in self:
            if record.partner_email and '@' not in record.partner_email:
                raise ValidationError(_('Veuillez saisir une adresse email valide.'))

    @api.constrains('is_refusal', 'refusal_reason_id', 'refusal_motivation')
    def _check_refusal_fields(self):
        for record in self:
            if record.is_refusal:
                if not record.refusal_reason_id:
                    raise ValidationError(_('Le motif de refus est obligatoire pour une demande refusée.'))
                if not record.refusal_motivation:
                    raise ValidationError(_('La motivation du refus est obligatoire pour une demande refusée.'))

    def action_submit(self):
        """Soumettre la demande"""
        self.ensure_one()
        self.write({
            'state': 'submitted',
            'stage_id': self.env.ref('sama_conai.stage_new').id
        })
        self._send_acknowledgment_email()
        return True

    def action_start_processing(self):
        """Commencer le traitement"""
        self.ensure_one()
        self.write({
            'state': 'in_progress',
            'stage_id': self.env.ref('sama_conai.stage_in_progress').id
        })
        return True

    def action_request_validation(self):
        """Demander la validation"""
        self.ensure_one()
        if not self.response_body and not self.is_refusal:
            raise ValidationError(_('Veuillez saisir une réponse avant de demander la validation.'))
        
        self.write({
            'state': 'pending_validation',
            'stage_id': self.env.ref('sama_conai.stage_pending_validation').id
        })
        self._notify_managers()
        return True

    def action_approve(self):
        """Approuver la réponse"""
        self.ensure_one()
        if not self.env.user.has_group('sama_conai.group_info_request_manager'):
            raise ValidationError(_('Seuls les managers peuvent approuver les réponses.'))
        
        state = 'refused' if self.is_refusal else 'responded'
        stage_ref = 'sama_conai.stage_refused' if self.is_refusal else 'sama_conai.stage_responded'
        
        self.write({
            'state': state,
            'stage_id': self.env.ref(stage_ref).id,
            'response_date': fields.Datetime.now()
        })
        self._send_response_email()
        return True

    def action_reject_validation(self):
        """Rejeter la validation"""
        self.ensure_one()
        if not self.env.user.has_group('sama_conai.group_info_request_manager'):
            raise ValidationError(_('Seuls les managers peuvent rejeter les validations.'))
        
        self.write({
            'state': 'in_progress',
            'stage_id': self.env.ref('sama_conai.stage_in_progress').id
        })
        self.message_post(
            body=_('La validation a été rejetée. Veuillez réviser la réponse.'),
            message_type='comment'
        )
        return True

    def _send_acknowledgment_email(self):
        """Envoyer l'accusé de réception"""
        template = self.env.ref('sama_conai.email_template_acknowledgment', raise_if_not_found=False)
        if template:
            # Attacher dynamiquement les pièces jointes de réponse si présentes
            if self.response_attachment_ids:
                template = template.copy({'attachment_ids': [(6, 0, self.response_attachment_ids.ids)]})
            template.send_mail(self.id, force_send=True)

    def _send_response_email(self):
        """Envoyer la réponse finale"""
        template_ref = 'sama_conai.email_template_response_refusal' if self.is_refusal else 'sama_conai.email_template_response'
        template = self.env.ref(template_ref, raise_if_not_found=False)
        if template:
            # Attacher dynamiquement les pièces jointes de réponse si présentes
            if self.response_attachment_ids:
                template = template.copy({'attachment_ids': [(6, 0, self.response_attachment_ids.ids)]})
            template.send_mail(self.id, force_send=True)

    def _notify_managers(self):
        """Notifier les managers pour validation"""
        managers = self.env['res.users'].search([
            ('groups_id', 'in', [self.env.ref('sama_conai.group_info_request_manager').id])
        ])
        for manager in managers:
            self.activity_schedule(
                'mail.mail_activity_data_todo',
                user_id=manager.id,
                summary=_('Validation requise pour la demande %s') % self.name,
                note=_('Une demande d\'information nécessite votre validation.')
            )

    def _compute_access_url(self):
        """Calculer l'URL d'accès au portail"""
        super(InformationRequest, self)._compute_access_url()
        for request in self:
            request.access_url = '/my/information-requests/%s' % request.id

    def action_view_portal(self):
        """Ouvrir la vue portail de la demande"""
        self.ensure_one()
        return {
            'type': 'ir.actions.act_url',
            'url': self.access_url,
            'target': 'new',
        }