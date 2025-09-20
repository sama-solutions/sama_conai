# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
import json
import logging
from datetime import timedelta

_logger = logging.getLogger(__name__)


class MobileNotificationLog(models.Model):
    _name = 'mobile.notification.log'
    _description = 'Journal des Notifications Mobiles'
    _order = 'create_date desc'
    _rec_name = 'title'

    # Destinataire
    user_id = fields.Many2one(
        'res.users',
        string='Utilisateur',
        required=True,
        ondelete='cascade'
    )
    
    device_id = fields.Many2one(
        'mobile.device',
        string='Device',
        ondelete='set null'
    )
    
    # Contenu de la notification
    title = fields.Char(
        string='Titre',
        required=True
    )
    
    body = fields.Text(
        string='Corps du Message',
        required=True
    )
    
    notification_type = fields.Selection([
        ('info_request', 'Demande d\'Information'),
        ('alert', 'Signalement d\'Alerte'),
        ('deadline', 'Rappel d\'Échéance'),
        ('assignment', 'Assignation'),
        ('system', 'Système'),
        ('test', 'Test')
    ], string='Type de Notification', required=True)
    
    priority = fields.Selection([
        ('low', 'Faible'),
        ('medium', 'Moyenne'),
        ('high', 'Élevée'),
        ('urgent', 'Urgente')
    ], string='Priorité', default='medium')
    
    # Données additionnelles (JSON)
    data = fields.Text(
        string='Données Additionnelles',
        help='Données JSON pour l\'application mobile'
    )
    
    # Statut d'envoi
    status = fields.Selection([
        ('pending', 'En Attente'),
        ('sent', 'Envoyée'),
        ('delivered', 'Délivrée'),
        ('failed', 'Échec'),
        ('read', 'Lue')
    ], string='Statut', default='pending')
    
    # Dates
    sent_date = fields.Datetime(
        string='Date d\'Envoi'
    )
    
    delivered_date = fields.Datetime(
        string='Date de Livraison'
    )
    
    read_date = fields.Datetime(
        string='Date de Lecture'
    )
    
    # Statut de lecture
    is_read = fields.Boolean(
        string='Lu',
        default=False
    )
    
    # Informations techniques
    fcm_message_id = fields.Char(
        string='ID Message FCM',
        help='Identifiant du message Firebase'
    )
    
    apns_message_id = fields.Char(
        string='ID Message APNS',
        help='Identifiant du message Apple Push'
    )
    
    error_message = fields.Text(
        string='Message d\'Erreur',
        help='Détails de l\'erreur en cas d\'échec'
    )
    
    retry_count = fields.Integer(
        string='Nombre de Tentatives',
        default=0
    )
    
    # Objet lié
    related_model = fields.Char(
        string='Modèle Lié',
        help='Nom du modèle de l\'objet lié'
    )
    
    related_record_id = fields.Integer(
        string='ID Enregistrement Lié',
        help='ID de l\'enregistrement lié'
    )

    @api.model
    def create(self, vals):
        """Créer une entrée de log"""
        # Convertir les données en JSON si nécessaire
        if 'data' in vals and isinstance(vals['data'], dict):
            vals['data'] = json.dumps(vals['data'])
        
        return super(MobileNotificationLog, self).create(vals)

    def write(self, vals):
        """Mettre à jour une entrée de log"""
        # Convertir les données en JSON si nécessaire
        if 'data' in vals and isinstance(vals['data'], dict):
            vals['data'] = json.dumps(vals['data'])
        
        return super(MobileNotificationLog, self).write(vals)

    def mark_as_sent(self, message_id=None):
        """Marquer comme envoyée"""
        vals = {
            'status': 'sent',
            'sent_date': fields.Datetime.now()
        }
        
        if message_id:
            # Déterminer le type de message ID
            if self.device_id.device_type == 'ios':
                vals['apns_message_id'] = message_id
            else:
                vals['fcm_message_id'] = message_id
        
        self.write(vals)

    def mark_as_delivered(self):
        """Marquer comme délivrée"""
        self.write({
            'status': 'delivered',
            'delivered_date': fields.Datetime.now()
        })

    def mark_as_failed(self, error_message=None):
        """Marquer comme échouée"""
        vals = {
            'status': 'failed'
        }
        
        if error_message:
            vals['error_message'] = error_message
        
        self.write(vals)

    def mark_as_read(self):
        """Marquer comme lue"""
        self.write({
            'is_read': True,
            'read_date': fields.Datetime.now(),
            'status': 'read'
        })

    def increment_retry(self):
        """Incrémenter le compteur de tentatives"""
        self.write({'retry_count': self.retry_count + 1})

    def get_data_dict(self):
        """Récupérer les données sous forme de dictionnaire"""
        if self.data:
            try:
                return json.loads(self.data)
            except json.JSONDecodeError:
                return {}
        return {}

    def set_data_dict(self, data_dict):
        """Définir les données à partir d'un dictionnaire"""
        self.data = json.dumps(data_dict) if data_dict else None

    @api.model
    def log_notification(self, user_id, title, body, notification_type, 
                        priority='medium', data=None, device_id=None,
                        related_model=None, related_record_id=None):
        """
        Créer une entrée de log pour une notification
        """
        vals = {
            'user_id': user_id,
            'title': title,
            'body': body,
            'notification_type': notification_type,
            'priority': priority,
            'data': json.dumps(data) if data else None,
            'device_id': device_id,
            'related_model': related_model,
            'related_record_id': related_record_id
        }
        
        return self.create(vals)

    @api.model
    def cleanup_old_logs(self, days=90):
        """
        Nettoyer les anciens logs (appelé par un cron)
        """
        cutoff_date = fields.Datetime.now() - timedelta(days=days)
        old_logs = self.search([('create_date', '<', cutoff_date)])
        
        if old_logs:
            count = len(old_logs)
            old_logs.unlink()
            _logger.info(f'Supprimé {count} anciens logs de notifications')

    @api.model
    def get_user_notification_stats(self, user_id, days=30):
        """
        Obtenir les statistiques de notifications pour un utilisateur
        """
        domain = [
            ('user_id', '=', user_id),
            ('create_date', '>=', fields.Datetime.now() - timedelta(days=days))
        ]
        
        notifications = self.search(domain)
        
        stats = {
            'total': len(notifications),
            'sent': len(notifications.filtered(lambda n: n.status == 'sent')),
            'delivered': len(notifications.filtered(lambda n: n.status == 'delivered')),
            'read': len(notifications.filtered(lambda n: n.is_read)),
            'failed': len(notifications.filtered(lambda n: n.status == 'failed')),
            'by_type': {},
            'by_priority': {}
        }
        
        # Statistiques par type
        for notif_type in ['info_request', 'alert', 'deadline', 'assignment', 'system']:
            stats['by_type'][notif_type] = len(
                notifications.filtered(lambda n: n.notification_type == notif_type)
            )
        
        # Statistiques par priorité
        for priority in ['low', 'medium', 'high', 'urgent']:
            stats['by_priority'][priority] = len(
                notifications.filtered(lambda n: n.priority == priority)
            )
        
        return stats

    def action_retry_send(self):
        """Réessayer l'envoi d'une notification échouée"""
        if self.status != 'failed':
            return
        
        notification_service = self.env['mobile.notification.service']
        result = notification_service.send_single_notification(
            user_id=self.user_id.id,
            title=self.title,
            body=self.body,
            notification_type=self.notification_type,
            priority=self.priority,
            data=self.get_data_dict(),
            device_id=self.device_id.id if self.device_id else None
        )
        
        if result.get('success'):
            self.mark_as_sent(result.get('message_id'))
        else:
            self.increment_retry()
            self.mark_as_failed(result.get('error'))

    def name_get(self):
        """Affichage personnalisé du nom"""
        result = []
        for log in self:
            name = f"{log.title} - {log.user_id.name}"
            result.append((log.id, name))
        return result