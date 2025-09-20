# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from datetime import datetime, timedelta
import logging

_logger = logging.getLogger(__name__)


class MobileDevice(models.Model):
    _name = 'mobile.device'
    _description = 'Device Mobile Enregistré'
    _order = 'last_active desc'

    # Informations de base
    user_id = fields.Many2one(
        'res.users',
        string='Utilisateur',
        required=True,
        ondelete='cascade'
    )
    device_token = fields.Char(
        string='Token du Device',
        required=True,
        help='Token FCM/APNS pour les notifications push'
    )
    device_type = fields.Selection([
        ('ios', 'iOS'),
        ('android', 'Android'),
        ('unknown', 'Inconnu')
    ], string='Type de Device', default='unknown')
    
    # Informations techniques
    app_version = fields.Char(
        string='Version de l\'App',
        help='Version de l\'application mobile'
    )
    os_version = fields.Char(
        string='Version OS',
        help='Version du système d\'exploitation'
    )
    device_model = fields.Char(
        string='Modèle du Device',
        help='Modèle du téléphone/tablette'
    )
    
    # Statut et activité
    is_active = fields.Boolean(
        string='Actif',
        default=True,
        help='Si le device est actif pour recevoir des notifications'
    )
    last_active = fields.Datetime(
        string='Dernière Activité',
        default=fields.Datetime.now
    )
    registration_date = fields.Datetime(
        string='Date d\'Enregistrement',
        default=fields.Datetime.now
    )
    
    # Statistiques
    notification_count = fields.Integer(
        string='Notifications Envoyées',
        default=0,
        help='Nombre total de notifications envoyées à ce device'
    )
    last_notification_date = fields.Datetime(
        string='Dernière Notification'
    )
    
    # Préférences
    timezone = fields.Char(
        string='Fuseau Horaire',
        help='Fuseau horaire du device'
    )
    language = fields.Char(
        string='Langue',
        help='Langue préférée du device'
    )

    @api.model
    def create(self, vals):
        """Surcharger create pour gérer les doublons"""
        # Vérifier s'il existe déjà un device avec ce token pour cet utilisateur
        existing_device = self.search([
            ('user_id', '=', vals.get('user_id')),
            ('device_token', '=', vals.get('device_token'))
        ], limit=1)
        
        if existing_device:
            # Mettre à jour le device existant
            existing_device.write({
                'is_active': True,
                'last_active': fields.Datetime.now(),
                'app_version': vals.get('app_version', existing_device.app_version),
                'device_type': vals.get('device_type', existing_device.device_type)
            })
            return existing_device
        
        return super(MobileDevice, self).create(vals)

    def write(self, vals):
        """Mettre à jour last_active lors de modifications"""
        if 'last_active' not in vals:
            vals['last_active'] = fields.Datetime.now()
        return super(MobileDevice, self).write(vals)

    def action_deactivate(self):
        """Désactiver le device"""
        self.write({'is_active': False})

    def action_activate(self):
        """Activer le device"""
        self.write({'is_active': True})

    def increment_notification_count(self):
        """Incrémenter le compteur de notifications"""
        self.write({
            'notification_count': self.notification_count + 1,
            'last_notification_date': fields.Datetime.now()
        })

    @api.model
    def cleanup_inactive_devices(self):
        """
        Nettoyer les devices inactifs (appelé par un cron)
        Désactive les devices qui n'ont pas été actifs depuis 30 jours
        """
        cutoff_date = fields.Datetime.now() - timedelta(days=30)
        inactive_devices = self.search([
            ('last_active', '<', cutoff_date),
            ('is_active', '=', True)
        ])
        
        if inactive_devices:
            inactive_devices.write({'is_active': False})
            _logger.info(f'Désactivé {len(inactive_devices)} devices inactifs')

    @api.model
    def get_active_devices_for_user(self, user_id):
        """Récupérer tous les devices actifs d'un utilisateur"""
        return self.search([
            ('user_id', '=', user_id),
            ('is_active', '=', True)
        ])

    @api.model
    def get_devices_by_type(self, device_type):
        """Récupérer les devices par type"""
        return self.search([
            ('device_type', '=', device_type),
            ('is_active', '=', True)
        ])

    def name_get(self):
        """Affichage personnalisé du nom"""
        result = []
        for device in self:
            name = f"{device.user_id.name} - {device.device_type.upper()}"
            if device.device_model:
                name += f" ({device.device_model})"
            result.append((device.id, name))
        return result

    @api.depends('user_id', 'device_type', 'device_model')
    def _compute_display_name(self):
        """Calculer le nom d'affichage"""
        for device in self:
            name = f"{device.user_id.name} - {device.device_type.upper()}"
            if device.device_model:
                name += f" ({device.device_model})"
            device.display_name = name