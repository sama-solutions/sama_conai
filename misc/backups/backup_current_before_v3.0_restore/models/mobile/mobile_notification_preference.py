# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from odoo.exceptions import ValidationError
import logging

_logger = logging.getLogger(__name__)


class MobileNotificationPreference(models.Model):
    _name = 'mobile.notification.preference'
    _description = 'Préférences de Notification Mobile'
    _rec_name = 'user_id'

    # Utilisateur
    user_id = fields.Many2one(
        'res.users',
        string='Utilisateur',
        required=True,
        ondelete='cascade'
    )
    
    # Préférences générales
    notifications_enabled = fields.Boolean(
        string='Notifications Activées',
        default=True,
        help='Activer/désactiver toutes les notifications'
    )
    
    # Préférences par type de notification
    info_request_updates = fields.Boolean(
        string='Mises à jour des Demandes d\'Information',
        default=True,
        help='Recevoir des notifications pour les mises à jour des demandes d\'information'
    )
    
    alert_updates = fields.Boolean(
        string='Mises à jour des Alertes',
        default=True,
        help='Recevoir des notifications pour les mises à jour des signalements'
    )
    
    deadline_reminders = fields.Boolean(
        string='Rappels d\'Échéance',
        default=True,
        help='Recevoir des rappels avant les échéances'
    )
    
    assignment_notifications = fields.Boolean(
        string='Notifications d\'Assignation',
        default=True,
        help='Recevoir des notifications lors d\'assignations de tâches'
    )
    
    system_notifications = fields.Boolean(
        string='Notifications Système',
        default=True,
        help='Recevoir des notifications système importantes'
    )
    
    # Préférences de timing
    quiet_hours_enabled = fields.Boolean(
        string='Heures Silencieuses Activées',
        default=False,
        help='Activer les heures silencieuses'
    )
    
    quiet_start_time = fields.Float(
        string='Début Heures Silencieuses',
        default=22.0,
        help='Heure de début des heures silencieuses (format 24h)'
    )
    
    quiet_end_time = fields.Float(
        string='Fin Heures Silencieuses',
        default=8.0,
        help='Heure de fin des heures silencieuses (format 24h)'
    )
    
    # Préférences par priorité
    urgent_notifications = fields.Boolean(
        string='Notifications Urgentes',
        default=True,
        help='Recevoir les notifications urgentes même pendant les heures silencieuses'
    )
    
    high_priority_notifications = fields.Boolean(
        string='Notifications Haute Priorité',
        default=True,
        help='Recevoir les notifications haute priorité'
    )
    
    medium_priority_notifications = fields.Boolean(
        string='Notifications Priorité Moyenne',
        default=True,
        help='Recevoir les notifications de priorité moyenne'
    )
    
    low_priority_notifications = fields.Boolean(
        string='Notifications Faible Priorité',
        default=False,
        help='Recevoir les notifications de faible priorité'
    )
    
    # Préférences de fréquence
    digest_enabled = fields.Boolean(
        string='Résumé Quotidien Activé',
        default=False,
        help='Recevoir un résumé quotidien des activités'
    )
    
    digest_time = fields.Float(
        string='Heure du Résumé',
        default=9.0,
        help='Heure d\'envoi du résumé quotidien'
    )
    
    weekly_summary = fields.Boolean(
        string='Résumé Hebdomadaire',
        default=False,
        help='Recevoir un résumé hebdomadaire'
    )
    
    # Métadonnées
    last_updated = fields.Datetime(
        string='Dernière Mise à Jour',
        default=fields.Datetime.now
    )

    @api.model
    def create(self, vals):
        """Créer des préférences par défaut"""
        vals['last_updated'] = fields.Datetime.now()
        return super(MobileNotificationPreference, self).create(vals)

    def write(self, vals):
        """Mettre à jour la date de modification"""
        vals['last_updated'] = fields.Datetime.now()
        return super(MobileNotificationPreference, self).write(vals)

    @api.model
    def get_user_preferences(self, user_id):
        """Récupérer les préférences d'un utilisateur"""
        prefs = self.search([('user_id', '=', user_id)], limit=1)
        if not prefs:
            # Créer des préférences par défaut
            prefs = self.create({'user_id': user_id})
        return prefs

    def should_send_notification(self, notification_type, priority='medium'):
        """
        Vérifier si une notification doit être envoyée selon les préférences
        """
        # Vérifier si les notifications sont activées
        if not self.notifications_enabled:
            return False
        
        # Vérifier le type de notification
        type_mapping = {
            'info_request': self.info_request_updates,
            'alert': self.alert_updates,
            'deadline': self.deadline_reminders,
            'assignment': self.assignment_notifications,
            'system': self.system_notifications
        }
        
        if notification_type in type_mapping and not type_mapping[notification_type]:
            return False
        
        # Vérifier la priorité
        priority_mapping = {
            'urgent': self.urgent_notifications,
            'high': self.high_priority_notifications,
            'medium': self.medium_priority_notifications,
            'low': self.low_priority_notifications
        }
        
        if priority in priority_mapping and not priority_mapping[priority]:
            return False
        
        # Vérifier les heures silencieuses
        if self.quiet_hours_enabled and priority != 'urgent':
            current_time = fields.Datetime.now().hour + fields.Datetime.now().minute / 60.0
            
            # Gérer le cas où les heures silencieuses traversent minuit
            if self.quiet_start_time > self.quiet_end_time:
                # Ex: 22h à 8h
                if current_time >= self.quiet_start_time or current_time <= self.quiet_end_time:
                    return False
            else:
                # Ex: 1h à 6h
                if self.quiet_start_time <= current_time <= self.quiet_end_time:
                    return False
        
        return True

    def get_notification_settings_summary(self):
        """Retourner un résumé des paramètres de notification"""
        return {
            'notifications_enabled': self.notifications_enabled,
            'types': {
                'info_requests': self.info_request_updates,
                'alerts': self.alert_updates,
                'deadlines': self.deadline_reminders,
                'assignments': self.assignment_notifications,
                'system': self.system_notifications
            },
            'priorities': {
                'urgent': self.urgent_notifications,
                'high': self.high_priority_notifications,
                'medium': self.medium_priority_notifications,
                'low': self.low_priority_notifications
            },
            'quiet_hours': {
                'enabled': self.quiet_hours_enabled,
                'start': self.quiet_start_time,
                'end': self.quiet_end_time
            },
            'digest': {
                'daily': self.digest_enabled,
                'time': self.digest_time,
                'weekly': self.weekly_summary
            }
        }

    @api.constrains('quiet_start_time', 'quiet_end_time', 'digest_time')
    def _check_time_values(self):
        """Valider les valeurs de temps"""
        for record in self:
            for time_field in [record.quiet_start_time, record.quiet_end_time, record.digest_time]:
                if time_field < 0 or time_field >= 24:
                    raise ValidationError(_('Les heures doivent être entre 0 et 23.59'))

    def action_reset_to_defaults(self):
        """Remettre les préférences par défaut"""
        self.write({
            'notifications_enabled': True,
            'info_request_updates': True,
            'alert_updates': True,
            'deadline_reminders': True,
            'assignment_notifications': True,
            'system_notifications': True,
            'quiet_hours_enabled': False,
            'quiet_start_time': 22.0,
            'quiet_end_time': 8.0,
            'urgent_notifications': True,
            'high_priority_notifications': True,
            'medium_priority_notifications': True,
            'low_priority_notifications': False,
            'digest_enabled': False,
            'digest_time': 9.0,
            'weekly_summary': False
        })