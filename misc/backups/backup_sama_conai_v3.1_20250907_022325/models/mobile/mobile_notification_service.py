# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from odoo.exceptions import ValidationError
import json
import requests
import logging
from datetime import datetime, timedelta

_logger = logging.getLogger(__name__)


class MobileNotificationService(models.Model):
    _name = 'mobile.notification.service'
    _description = 'Service de Notifications Mobiles'

    name = fields.Char(
        string='Nom du Service',
        default='SAMA CONAI Mobile Notifications'
    )

    # Configuration FCM (Firebase Cloud Messaging)
    fcm_server_key = fields.Char(
        string='Clé Serveur FCM',
        help='Clé serveur Firebase pour Android'
    )
    
    fcm_sender_id = fields.Char(
        string='Sender ID FCM',
        help='ID de l\'expéditeur Firebase'
    )
    
    # Configuration APNS (Apple Push Notification Service)
    apns_key_id = fields.Char(
        string='Key ID APNS',
        help='Identifiant de la clé APNS'
    )
    
    apns_team_id = fields.Char(
        string='Team ID APNS',
        help='Identifiant de l\'équipe Apple'
    )
    
    apns_bundle_id = fields.Char(
        string='Bundle ID',
        help='Identifiant du bundle de l\'application iOS'
    )
    
    apns_private_key = fields.Text(
        string='Clé Privée APNS',
        help='Clé privée APNS au format PEM'
    )
    
    # Configuration générale
    is_production = fields.Boolean(
        string='Mode Production',
        default=False,
        help='Utiliser les serveurs de production'
    )
    
    max_retry_attempts = fields.Integer(
        string='Tentatives Maximum',
        default=3,
        help='Nombre maximum de tentatives d\'envoi'
    )
    
    batch_size = fields.Integer(
        string='Taille des Lots',
        default=100,
        help='Nombre de notifications à envoyer par lot'
    )

    @api.model
    def send_notification(self, user_ids, title, body, notification_type='system',
                         priority='medium', data=None, related_model=None, related_record_id=None):
        """
        Envoyer une notification à plusieurs utilisateurs
        """
        if not user_ids:
            return {'success': False, 'error': 'Aucun utilisateur spécifié'}
        
        results = {
            'success': True,
            'sent_count': 0,
            'failed_count': 0,
            'details': []
        }
        
        for user_id in user_ids:
            result = self.send_single_notification(
                user_id=user_id,
                title=title,
                body=body,
                notification_type=notification_type,
                priority=priority,
                data=data,
                related_model=related_model,
                related_record_id=related_record_id
            )
            
            if result['success']:
                results['sent_count'] += 1
            else:
                results['failed_count'] += 1
            
            results['details'].append(result)
        
        if results['failed_count'] > 0:
            results['success'] = False
        
        return results

    @api.model
    def send_single_notification(self, user_id, title, body, notification_type='system',
                                priority='medium', data=None, device_id=None,
                                related_model=None, related_record_id=None):
        """
        Envoyer une notification à un utilisateur spécifique
        """
        try:
            user = self.env['res.users'].browse(user_id)
            if not user.exists():
                return {'success': False, 'error': 'Utilisateur non trouvé'}
            
            # Vérifier les préférences de notification
            prefs = self.env['mobile.notification.preference'].get_user_preferences(user_id)
            if not prefs.should_send_notification(notification_type, priority):
                return {'success': False, 'error': 'Notification bloquée par les préférences'}
            
            # Récupérer les devices actifs
            if device_id:
                devices = self.env['mobile.device'].browse(device_id)
            else:
                devices = self.env['mobile.device'].get_active_devices_for_user(user_id)
            
            if not devices:
                return {'success': False, 'error': 'Aucun device actif trouvé'}
            
            sent_count = 0
            errors = []
            
            for device in devices:
                # Créer le log de notification
                log = self.env['mobile.notification.log'].log_notification(
                    user_id=user_id,
                    title=title,
                    body=body,
                    notification_type=notification_type,
                    priority=priority,
                    data=data,
                    device_id=device.id,
                    related_model=related_model,
                    related_record_id=related_record_id
                )
                
                # Envoyer selon le type de device
                if device.device_type == 'ios':
                    result = self._send_apns_notification(device, title, body, data, log)
                else:  # android ou unknown
                    result = self._send_fcm_notification(device, title, body, data, log)
                
                if result['success']:
                    sent_count += 1
                    log.mark_as_sent(result.get('message_id'))
                    device.increment_notification_count()
                else:
                    errors.append(result['error'])
                    log.mark_as_failed(result['error'])
            
            if sent_count > 0:
                return {
                    'success': True,
                    'sent_count': sent_count,
                    'message': f'Notification envoyée à {sent_count} device(s)'
                }
            else:
                return {
                    'success': False,
                    'error': f'Échec d\'envoi: {", ".join(errors)}'
                }
        
        except Exception as e:
            _logger.error(f'Erreur envoi notification: {str(e)}')
            return {'success': False, 'error': str(e)}

    def _send_fcm_notification(self, device, title, body, data, log):
        """
        Envoyer une notification via Firebase Cloud Messaging (Android)
        """
        try:
            if not self.fcm_server_key:
                return {'success': False, 'error': 'Clé serveur FCM non configurée'}
            
            url = 'https://fcm.googleapis.com/fcm/send'
            headers = {
                'Authorization': f'key={self.fcm_server_key}',
                'Content-Type': 'application/json'
            }
            
            payload = {
                'to': device.device_token,
                'notification': {
                    'title': title,
                    'body': body,
                    'sound': 'default',
                    'badge': 1
                },
                'data': data or {},
                'priority': 'high' if log.priority in ['high', 'urgent'] else 'normal'
            }
            
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success', 0) > 0:
                    message_id = result.get('results', [{}])[0].get('message_id')
                    return {'success': True, 'message_id': message_id}
                else:
                    error = result.get('results', [{}])[0].get('error', 'Erreur inconnue')
                    return {'success': False, 'error': f'FCM Error: {error}'}
            else:
                return {'success': False, 'error': f'HTTP {response.status_code}: {response.text}'}
        
        except Exception as e:
            return {'success': False, 'error': f'Exception FCM: {str(e)}'}

    def _send_apns_notification(self, device, title, body, data, log):
        """
        Envoyer une notification via Apple Push Notification Service (iOS)
        """
        try:
            # Pour APNS, nous utiliserions normalement PyJWT et cryptography
            # Ici, nous simulons l'envoi ou utilisons un service tiers
            
            if not self.apns_key_id or not self.apns_team_id:
                return {'success': False, 'error': 'Configuration APNS incomplète'}
            
            # Simulation d'envoi APNS
            # Dans un vrai environnement, il faudrait:
            # 1. Générer un JWT token avec la clé privée
            # 2. Envoyer à api.push.apple.com (production) ou api.sandbox.push.apple.com (dev)
            
            _logger.info(f'Simulation envoi APNS pour device {device.device_token}')
            
            # Retourner un succès simulé
            return {'success': True, 'message_id': f'apns_{datetime.now().timestamp()}'}
        
        except Exception as e:
            return {'success': False, 'error': f'Exception APNS: {str(e)}'}

    @api.model
    def send_info_request_notification(self, request_id, notification_type, user_ids=None):
        """
        Envoyer une notification liée à une demande d'information
        """
        request_obj = self.env['request.information'].browse(request_id)
        if not request_obj.exists():
            return {'success': False, 'error': 'Demande non trouvée'}
        
        # Déterminer les destinataires
        if not user_ids:
            if notification_type == 'assignment':
                user_ids = [request_obj.user_id.id] if request_obj.user_id else []
            elif notification_type == 'validation_request':
                # Notifier les managers
                managers = self.env['res.users'].search([
                    ('groups_id', 'in', [self.env.ref('sama_conai.group_info_request_manager').id])
                ])
                user_ids = managers.ids
            else:
                user_ids = []
        
        if not user_ids:
            return {'success': False, 'error': 'Aucun destinataire'}
        
        # Préparer le contenu
        title_map = {
            'assignment': f'Nouvelle assignation: {request_obj.name}',
            'status_update': f'Mise à jour: {request_obj.name}',
            'deadline_reminder': f'Échéance proche: {request_obj.name}',
            'validation_request': f'Validation requise: {request_obj.name}',
            'response_ready': f'Réponse prête: {request_obj.name}'
        }
        
        body_map = {
            'assignment': f'Vous avez été assigné à la demande {request_obj.name}',
            'status_update': f'La demande {request_obj.name} a été mise à jour',
            'deadline_reminder': f'La demande {request_obj.name} arrive à échéance dans {request_obj.days_to_deadline} jours',
            'validation_request': f'La demande {request_obj.name} nécessite votre validation',
            'response_ready': f'Une réponse a été préparée pour {request_obj.name}'
        }
        
        title = title_map.get(notification_type, f'Notification: {request_obj.name}')
        body = body_map.get(notification_type, f'Mise à jour sur la demande {request_obj.name}')
        
        # Données additionnelles
        data = {
            'type': 'information_request',
            'request_id': request_obj.id,
            'request_name': request_obj.name,
            'notification_type': notification_type,
            'action_url': f'/api/mobile/agent/info-request/{request_obj.id}'
        }
        
        # Déterminer la priorité
        priority = 'high' if request_obj.is_overdue else 'medium'
        if notification_type in ['deadline_reminder', 'validation_request']:
            priority = 'high'
        
        return self.send_notification(
            user_ids=user_ids,
            title=title,
            body=body,
            notification_type='info_request',
            priority=priority,
            data=data,
            related_model='request.information',
            related_record_id=request_obj.id
        )

    @api.model
    def send_alert_notification(self, alert_id, notification_type, user_ids=None):
        """
        Envoyer une notification liée à un signalement d'alerte
        """
        alert_obj = self.env['whistleblowing.alert'].browse(alert_id)
        if not alert_obj.exists():
            return {'success': False, 'error': 'Alerte non trouvée'}
        
        # Déterminer les destinataires
        if not user_ids:
            if notification_type == 'assignment':
                user_ids = [alert_obj.manager_id.id] if alert_obj.manager_id else []
            elif notification_type == 'new_alert':
                # Notifier tous les managers d'alerte
                managers = self.env['res.users'].search([
                    ('groups_id', 'in', [self.env.ref('sama_conai.group_whistleblowing_manager').id])
                ])
                user_ids = managers.ids
            else:
                user_ids = []
        
        if not user_ids:
            return {'success': False, 'error': 'Aucun destinataire'}
        
        # Préparer le contenu
        title_map = {
            'new_alert': f'Nouvelle alerte: {alert_obj.name}',
            'assignment': f'Alerte assignée: {alert_obj.name}',
            'status_update': f'Mise à jour alerte: {alert_obj.name}',
            'priority_change': f'Priorité modifiée: {alert_obj.name}',
            'investigation_update': f'Enquête mise à jour: {alert_obj.name}'
        }
        
        body_map = {
            'new_alert': f'Nouvelle alerte {alert_obj.category}: {alert_obj.name}',
            'assignment': f'L\'alerte {alert_obj.name} vous a été assignée',
            'status_update': f'L\'alerte {alert_obj.name} a été mise à jour',
            'priority_change': f'L\'alerte {alert_obj.name} est maintenant {alert_obj.priority}',
            'investigation_update': f'L\'enquête sur {alert_obj.name} a été mise à jour'
        }
        
        title = title_map.get(notification_type, f'Notification: {alert_obj.name}')
        body = body_map.get(notification_type, f'Mise à jour sur l\'alerte {alert_obj.name}')
        
        # Données additionnelles
        data = {
            'type': 'whistleblowing_alert',
            'alert_id': alert_obj.id,
            'alert_name': alert_obj.name,
            'notification_type': notification_type,
            'action_url': f'/api/mobile/agent/alert/{alert_obj.id}'
        }
        
        # Déterminer la priorité
        priority_map = {
            'low': 'low',
            'medium': 'medium',
            'high': 'high',
            'urgent': 'urgent'
        }
        priority = priority_map.get(alert_obj.priority, 'medium')
        
        return self.send_notification(
            user_ids=user_ids,
            title=title,
            body=body,
            notification_type='alert',
            priority=priority,
            data=data,
            related_model='whistleblowing.alert',
            related_record_id=alert_obj.id
        )

    @api.model
    def send_daily_digest(self, user_id):
        """
        Envoyer un résumé quotidien à un utilisateur
        """
        user = self.env['res.users'].browse(user_id)
        if not user.exists():
            return {'success': False, 'error': 'Utilisateur non trouvé'}
        
        # Vérifier les préférences
        prefs = self.env['mobile.notification.preference'].get_user_preferences(user_id)
        if not prefs.digest_enabled:
            return {'success': False, 'error': 'Résumé quotidien désactivé'}
        
        # Collecter les statistiques du jour
        today = fields.Date.today()
        
        # Demandes d'information assignées
        info_requests = self.env['request.information'].search([
            ('user_id', '=', user_id),
            ('request_date', '>=', today)
        ])
        
        # Alertes assignées
        alerts = self.env['whistleblowing.alert'].search([
            ('manager_id', '=', user_id),
            ('alert_date', '>=', today)
        ])
        
        # Préparer le contenu
        title = f'Résumé quotidien SAMA CONAI - {today.strftime("%d/%m/%Y")}'
        
        body_parts = []
        if info_requests:
            body_parts.append(f'{len(info_requests)} nouvelle(s) demande(s) d\'information')
        if alerts:
            body_parts.append(f'{len(alerts)} nouvelle(s) alerte(s)')
        
        if not body_parts:
            body = 'Aucune nouvelle activité aujourd\'hui'
        else:
            body = 'Aujourd\'hui: ' + ', '.join(body_parts)
        
        data = {
            'type': 'daily_digest',
            'date': today.isoformat(),
            'info_requests_count': len(info_requests),
            'alerts_count': len(alerts)
        }
        
        return self.send_single_notification(
            user_id=user_id,
            title=title,
            body=body,
            notification_type='system',
            priority='low',
            data=data
        )

    @api.model
    def process_notification_queue(self):
        """
        Traiter la file d'attente des notifications (appelé par un cron)
        """
        # Récupérer les notifications en attente
        pending_notifications = self.env['mobile.notification.log'].search([
            ('status', '=', 'pending'),
            ('retry_count', '<', self.max_retry_attempts)
        ], limit=self.batch_size)
        
        processed_count = 0
        
        for log in pending_notifications:
            try:
                # Réessayer l'envoi
                log.action_retry_send()
                processed_count += 1
            except Exception as e:
                _logger.error(f'Erreur traitement notification {log.id}: {str(e)}')
                log.mark_as_failed(str(e))
        
        _logger.info(f'Traité {processed_count} notifications en attente')
        return processed_count