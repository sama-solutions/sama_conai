# -*- coding: utf-8 -*-

import json
import logging
import requests
from datetime import datetime, timedelta
from odoo import http, fields, _
from odoo.http import request
from odoo.exceptions import ValidationError

_logger = logging.getLogger(__name__)


class MobileNotificationController(http.Controller):
    """
    Contrôleur pour les notifications push mobiles
    """

    def _authenticate_mobile_user(self, token):
        """Authentifier l'utilisateur mobile via token"""
        if not token:
            return None
        
        # Utiliser la méthode de vérification du contrôleur d'auth
        auth_controller = request.env['mobile.auth.controller']
        return auth_controller._verify_mobile_token(token)

    @http.route('/api/mobile/notifications/register', type='json', auth='none', methods=['POST'], csrf=False)
    def register_device(self, **kwargs):
        """
        Enregistrer un device pour les notifications push
        """
        try:
            data = request.jsonrequest
            token = data.get('token')
            device_token = data.get('device_token')
            device_type = data.get('device_type', 'unknown')  # ios, android
            app_version = data.get('app_version')
            
            if not token or not device_token:
                return {
                    'success': False,
                    'error': 'Token utilisateur et device token requis',
                    'error_code': 'MISSING_TOKENS'
                }
            
            user = self._authenticate_mobile_user(token)
            if not user:
                return {
                    'success': False,
                    'error': 'Token utilisateur invalide',
                    'error_code': 'INVALID_USER_TOKEN'
                }
            
            # Créer ou mettre à jour l'enregistrement du device
            device = request.env['mobile.device'].sudo().search([
                ('user_id', '=', user.id),
                ('device_token', '=', device_token)
            ], limit=1)
            
            device_vals = {
                'user_id': user.id,
                'device_token': device_token,
                'device_type': device_type,
                'app_version': app_version,
                'last_active': fields.Datetime.now(),
                'is_active': True
            }
            
            if device:
                device.write(device_vals)
            else:
                device = request.env['mobile.device'].sudo().create(device_vals)
            
            return {
                'success': True,
                'message': 'Device enregistré avec succès',
                'device_id': device.id
            }
            
        except Exception as e:
            _logger.error('Erreur enregistrement device: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de l\'enregistrement',
                'error_code': 'REGISTRATION_ERROR'
            }

    @http.route('/api/mobile/notifications/unregister', type='json', auth='none', methods=['POST'], csrf=False)
    def unregister_device(self, **kwargs):
        """
        Désactiver un device
        """
        try:
            data = request.jsonrequest
            token = data.get('token')
            device_token = data.get('device_token')
            
            if not token or not device_token:
                return {
                    'success': False,
                    'error': 'Token utilisateur et device token requis',
                    'error_code': 'MISSING_TOKENS'
                }
            
            user = self._authenticate_mobile_user(token)
            if not user:
                return {
                    'success': False,
                    'error': 'Token utilisateur invalide',
                    'error_code': 'INVALID_USER_TOKEN'
                }
            
            # Désactiver le device
            device = request.env['mobile.device'].sudo().search([
                ('user_id', '=', user.id),
                ('device_token', '=', device_token)
            ], limit=1)
            
            if device:
                device.write({'is_active': False})
            
            return {
                'success': True,
                'message': 'Device désactivé avec succès'
            }
            
        except Exception as e:
            _logger.error('Erreur désactivation device: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de la désactivation',
                'error_code': 'UNREGISTRATION_ERROR'
            }

    @http.route('/api/mobile/notifications/test', type='json', auth='none', methods=['POST'], csrf=False)
    def send_test_notification(self, **kwargs):
        """
        Envoyer une notification de test
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._authenticate_mobile_user(token)
            
            if not user:
                return {
                    'success': False,
                    'error': 'Token utilisateur invalide',
                    'error_code': 'INVALID_USER_TOKEN'
                }
            
            return {
                'success': True,
                'message': 'Notification de test simulée',
                'sent_count': 1
            }
            
        except Exception as e:
            _logger.error('Erreur notification test: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de l\'envoi de la notification',
                'error_code': 'TEST_NOTIFICATION_ERROR'
            }