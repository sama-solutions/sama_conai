# -*- coding: utf-8 -*-

import json
import logging
from datetime import datetime, timedelta
from odoo import http, fields, _
from odoo.http import request
from odoo.exceptions import ValidationError, AccessError
import secrets
import hashlib

_logger = logging.getLogger(__name__)


class MobileAuthController(http.Controller):
    """
    Contrôleur d'authentification pour l'application mobile SAMA CONAI
    """

    @http.route('/api/mobile/auth/login', type='json', auth='none', methods=['POST'], csrf=False)
    def mobile_login(self, **kwargs):
        """
        Authentification mobile pour citoyens et agents
        """
        try:
            data = request.jsonrequest
            email = data.get('email')
            password = data.get('password')
            user_type = data.get('user_type', 'citizen')  # citizen ou agent
            device_token = data.get('device_token')  # Pour les notifications push
            
            if not email or not password:
                return {
                    'success': False,
                    'error': 'Email et mot de passe requis',
                    'error_code': 'MISSING_CREDENTIALS'
                }
            
            # Tentative d'authentification
            uid = request.session.authenticate(request.session.db, email, password)
            
            if not uid:
                return {
                    'success': False,
                    'error': 'Identifiants invalides',
                    'error_code': 'INVALID_CREDENTIALS'
                }
            
            user = request.env['res.users'].browse(uid)
            
            # Vérifier les permissions selon le type d'utilisateur
            if user_type == 'agent':
                if not (user.has_group('sama_conai.group_info_request_user') or 
                       user.has_group('sama_conai.group_whistleblowing_user')):
                    return {
                        'success': False,
                        'error': 'Accès agent non autorisé',
                        'error_code': 'AGENT_ACCESS_DENIED'
                    }
            
            # Générer un token d'accès mobile
            mobile_token = self._generate_mobile_token(user)
            
            # Enregistrer le token de device pour les notifications
            if device_token:
                self._register_device_token(user, device_token)
            
            # Préparer les informations utilisateur
            user_info = {
                'id': user.id,
                'name': user.name,
                'email': user.email,
                'user_type': user_type,
                'permissions': self._get_user_permissions(user),
                'profile_image': self._get_user_avatar(user)
            }
            
            return {
                'success': True,
                'token': mobile_token,
                'user': user_info,
                'expires_in': 86400  # 24 heures
            }
            
        except Exception as e:
            _logger.error('Erreur lors de l\'authentification mobile: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur interne du serveur',
                'error_code': 'INTERNAL_ERROR'
            }

    @http.route('/api/mobile/auth/register', type='json', auth='none', methods=['POST'], csrf=False)
    def mobile_register(self, **kwargs):
        """
        Inscription mobile pour les citoyens
        """
        try:
            data = request.jsonrequest
            name = data.get('name')
            email = data.get('email')
            password = data.get('password')
            phone = data.get('phone')
            
            if not all([name, email, password]):
                return {
                    'success': False,
                    'error': 'Nom, email et mot de passe requis',
                    'error_code': 'MISSING_FIELDS'
                }
            
            # Vérifier si l'email existe déjà
            existing_user = request.env['res.users'].sudo().search([('email', '=', email)], limit=1)
            if existing_user:
                return {
                    'success': False,
                    'error': 'Un compte avec cet email existe déjà',
                    'error_code': 'EMAIL_EXISTS'
                }
            
            # Créer l'utilisateur citoyen
            user_vals = {
                'name': name,
                'login': email,
                'email': email,
                'phone': phone,
                'groups_id': [(6, 0, [request.env.ref('base.group_portal').id])],
                'password': password,
                'active': True
            }
            
            user = request.env['res.users'].sudo().create(user_vals)
            
            # Envoyer email de bienvenue
            self._send_welcome_email(user)
            
            return {
                'success': True,
                'message': 'Compte créé avec succès',
                'user_id': user.id
            }
            
        except Exception as e:
            _logger.error('Erreur lors de l\'inscription mobile: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de la création du compte',
                'error_code': 'REGISTRATION_ERROR'
            }

    @http.route('/api/mobile/auth/refresh', type='json', auth='none', methods=['POST'], csrf=False)
    def mobile_refresh_token(self, **kwargs):
        """
        Renouveler le token d'accès mobile
        """
        try:
            data = request.jsonrequest
            token = data.get('token')
            
            if not token:
                return {
                    'success': False,
                    'error': 'Token requis',
                    'error_code': 'MISSING_TOKEN'
                }
            
            # Vérifier et décoder le token
            user = self._verify_mobile_token(token)
            if not user:
                return {
                    'success': False,
                    'error': 'Token invalide ou expiré',
                    'error_code': 'INVALID_TOKEN'
                }
            
            # Générer un nouveau token
            new_token = self._generate_mobile_token(user)
            
            return {
                'success': True,
                'token': new_token,
                'expires_in': 86400
            }
            
        except Exception as e:
            _logger.error('Erreur lors du renouvellement du token: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur interne du serveur',
                'error_code': 'INTERNAL_ERROR'
            }

    @http.route('/api/mobile/auth/logout', type='json', auth='none', methods=['POST'], csrf=False)
    def mobile_logout(self, **kwargs):
        """
        Déconnexion mobile
        """
        try:
            data = request.jsonrequest
            token = data.get('token')
            device_token = data.get('device_token')
            
            if token:
                user = self._verify_mobile_token(token)
                if user and device_token:
                    self._unregister_device_token(user, device_token)
            
            return {
                'success': True,
                'message': 'Déconnexion réussie'
            }
            
        except Exception as e:
            _logger.error('Erreur lors de la déconnexion mobile: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de la déconnexion',
                'error_code': 'LOGOUT_ERROR'
            }

    @http.route('/api/mobile/auth/forgot-password', type='json', auth='none', methods=['POST'], csrf=False)
    def mobile_forgot_password(self, **kwargs):
        """
        Réinitialisation de mot de passe
        """
        try:
            data = request.jsonrequest
            email = data.get('email')
            
            if not email:
                return {
                    'success': False,
                    'error': 'Email requis',
                    'error_code': 'MISSING_EMAIL'
                }
            
            user = request.env['res.users'].sudo().search([('email', '=', email)], limit=1)
            if not user:
                return {
                    'success': False,
                    'error': 'Aucun compte trouvé avec cet email',
                    'error_code': 'USER_NOT_FOUND'
                }
            
            # Générer un token de réinitialisation
            reset_token = self._generate_reset_token(user)
            
            # Envoyer l'email de réinitialisation
            self._send_reset_password_email(user, reset_token)
            
            return {
                'success': True,
                'message': 'Email de réinitialisation envoyé'
            }
            
        except Exception as e:
            _logger.error('Erreur lors de la réinitialisation: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de l\'envoi de l\'email',
                'error_code': 'RESET_ERROR'
            }

    def _generate_mobile_token(self, user):
        """Générer un token d'accès mobile sécurisé"""
        timestamp = str(int(datetime.now().timestamp()))
        random_string = secrets.token_urlsafe(32)
        token_data = f"{user.id}:{timestamp}:{random_string}"
        
        # Hasher le token avec une clé secrète
        secret_key = request.env['ir.config_parameter'].sudo().get_param('sama_conai.mobile_secret_key', 'default_secret')
        token_hash = hashlib.sha256(f"{token_data}:{secret_key}".encode()).hexdigest()
        
        return f"{token_data}:{token_hash}"

    def _verify_mobile_token(self, token):
        """Vérifier et décoder un token mobile"""
        try:
            parts = token.split(':')
            if len(parts) != 4:
                return False
            
            user_id, timestamp, random_string, token_hash = parts
            
            # Vérifier l'expiration (24 heures)
            token_time = datetime.fromtimestamp(int(timestamp))
            if datetime.now() - token_time > timedelta(hours=24):
                return False
            
            # Vérifier le hash
            secret_key = request.env['ir.config_parameter'].sudo().get_param('sama_conai.mobile_secret_key', 'default_secret')
            expected_hash = hashlib.sha256(f"{user_id}:{timestamp}:{random_string}:{secret_key}".encode()).hexdigest()
            
            if token_hash != expected_hash:
                return False
            
            # Retourner l'utilisateur
            user = request.env['res.users'].sudo().browse(int(user_id))
            return user if user.exists() else False
            
        except Exception:
            return False

    def _get_user_permissions(self, user):
        """Obtenir les permissions de l'utilisateur"""
        permissions = {
            'can_create_info_request': True,  # Tous les utilisateurs peuvent créer des demandes
            'can_create_alert': True,  # Tous les utilisateurs peuvent créer des alertes
            'can_manage_info_requests': user.has_group('sama_conai.group_info_request_user'),
            'can_manage_alerts': user.has_group('sama_conai.group_whistleblowing_user'),
            'is_info_manager': user.has_group('sama_conai.group_info_request_manager'),
            'is_alert_manager': user.has_group('sama_conai.group_whistleblowing_manager'),
            'is_admin': user.has_group('sama_conai.group_sama_conai_admin')
        }
        return permissions

    def _get_user_avatar(self, user):
        """Obtenir l'avatar de l'utilisateur"""
        if user.image_1920:
            return f"/web/image/res.users/{user.id}/image_1920"
        return None

    def _register_device_token(self, user, device_token):
        """Enregistrer le token de device pour les notifications"""
        # Créer ou mettre à jour l'enregistrement du device
        device = request.env['mobile.device'].sudo().search([
            ('user_id', '=', user.id),
            ('device_token', '=', device_token)
        ], limit=1)
        
        if not device:
            request.env['mobile.device'].sudo().create({
                'user_id': user.id,
                'device_token': device_token,
                'last_active': fields.Datetime.now(),
                'is_active': True
            })
        else:
            device.write({
                'last_active': fields.Datetime.now(),
                'is_active': True
            })

    def _unregister_device_token(self, user, device_token):
        """Désactiver le token de device"""
        device = request.env['mobile.device'].sudo().search([
            ('user_id', '=', user.id),
            ('device_token', '=', device_token)
        ], limit=1)
        
        if device:
            device.write({'is_active': False})

    def _generate_reset_token(self, user):
        """Générer un token de réinitialisation"""
        token = secrets.token_urlsafe(32)
        # Stocker le token avec expiration
        user.sudo().write({
            'reset_password_token': token,
            'reset_password_expires': fields.Datetime.now() + timedelta(hours=1)
        })
        return token

    def _send_welcome_email(self, user):
        """Envoyer l'email de bienvenue"""
        template = request.env.ref('sama_conai.email_template_mobile_welcome', raise_if_not_found=False)
        if template:
            template.sudo().send_mail(user.id, force_send=True)

    def _send_reset_password_email(self, user, reset_token):
        """Envoyer l'email de réinitialisation"""
        template = request.env.ref('sama_conai.email_template_mobile_reset_password', raise_if_not_found=False)
        if template:
            # Ajouter le token au contexte
            template = template.with_context(reset_token=reset_token)
            template.sudo().send_mail(user.id, force_send=True)