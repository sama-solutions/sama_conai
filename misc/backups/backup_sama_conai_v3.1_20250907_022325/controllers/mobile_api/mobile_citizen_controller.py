# -*- coding: utf-8 -*-

import json
import logging
from datetime import datetime, timedelta
from odoo import http, fields, _
from odoo.http import request
from odoo.exceptions import ValidationError, AccessError

_logger = logging.getLogger(__name__)


class MobileCitizenController(http.Controller):
    """
    Contrôleur API mobile pour les citoyens
    """

    def _authenticate_mobile_user(self, token):
        """Authentifier l'utilisateur mobile via token"""
        if not token:
            return None
        
        # Utiliser la méthode de vérification du contrôleur d'auth
        auth_controller = request.env['mobile.auth.controller']
        return auth_controller._verify_mobile_token(token)

    def _require_auth(self, token):
        """Vérifier l'authentification et retourner l'utilisateur"""
        user = self._authenticate_mobile_user(token)
        if not user:
            return {
                'success': False,
                'error': 'Token invalide ou expiré',
                'error_code': 'AUTHENTICATION_REQUIRED'
            }
        return user

    @http.route('/api/mobile/citizen/dashboard', type='json', auth='none', methods=['GET'], csrf=False)
    def get_citizen_dashboard(self, **kwargs):
        """
        Tableau de bord citoyen mobile
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_auth(token)
            
            if isinstance(user, dict):  # Erreur d'auth
                return user
            
            # Statistiques personnelles du citoyen
            info_requests = request.env['request.information'].sudo().search([
                ('partner_email', '=', user.email)
            ])
            
            # Compter par état
            stats = {
                'total_requests': len(info_requests),
                'pending_requests': len(info_requests.filtered(lambda r: r.state in ['submitted', 'in_progress'])),
                'completed_requests': len(info_requests.filtered(lambda r: r.state in ['responded', 'refused'])),
                'overdue_requests': len(info_requests.filtered(lambda r: r.is_overdue))
            }
            
            # Dernières demandes
            recent_requests = info_requests.sorted('request_date', reverse=True)[:5]
            requests_data = []
            
            for req in recent_requests:
                requests_data.append({
                    'id': req.id,
                    'name': req.name,
                    'description': req.description[:100] + '...' if len(req.description) > 100 else req.description,
                    'request_date': req.request_date.isoformat() if req.request_date else None,
                    'state': req.state,
                    'state_label': dict(req._fields['state'].selection)[req.state],
                    'stage_name': req.stage_id.name,
                    'days_to_deadline': req.days_to_deadline,
                    'is_overdue': req.is_overdue
                })
            
            # Statistiques globales publiques
            all_requests = request.env['request.information'].sudo().search([])
            public_stats = {
                'total_public_requests': len(all_requests),
                'avg_response_time': self._calculate_avg_response_time(all_requests),
                'success_rate': self._calculate_success_rate(all_requests)
            }
            
            return {
                'success': True,
                'data': {
                    'user_stats': stats,
                    'recent_requests': requests_data,
                    'public_stats': public_stats
                }
            }
            
        except Exception as e:
            _logger.error('Erreur dashboard citoyen: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors du chargement du tableau de bord',
                'error_code': 'DASHBOARD_ERROR'
            }

    @http.route('/api/mobile/citizen/requests', type='json', auth='none', methods=['GET'], csrf=False)
    def get_citizen_requests(self, **kwargs):
        """
        Liste des demandes d'information du citoyen
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_auth(token)
            
            if isinstance(user, dict):
                return user
            
            data = request.jsonrequest or {}
            page = data.get('page', 1)
            limit = data.get('limit', 20)
            state_filter = data.get('state')
            
            domain = [('partner_email', '=', user.email)]
            if state_filter:
                domain.append(('state', '=', state_filter))
            
            # Pagination
            offset = (page - 1) * limit
            total_count = request.env['request.information'].sudo().search_count(domain)
            
            requests = request.env['request.information'].sudo().search(
                domain, 
                order='request_date desc',
                limit=limit,
                offset=offset
            )
            
            requests_data = []
            for req in requests:
                requests_data.append({
                    'id': req.id,
                    'name': req.name,
                    'description': req.description,
                    'request_date': req.request_date.isoformat() if req.request_date else None,
                    'deadline_date': req.deadline_date.isoformat() if req.deadline_date else None,
                    'response_date': req.response_date.isoformat() if req.response_date else None,
                    'state': req.state,
                    'state_label': dict(req._fields['state'].selection)[req.state],
                    'stage_name': req.stage_id.name,
                    'days_to_deadline': req.days_to_deadline,
                    'is_overdue': req.is_overdue,
                    'response_body': req.response_body if req.state in ['responded', 'refused'] else None,
                    'is_refusal': req.is_refusal,
                    'refusal_reason': req.refusal_reason_id.name if req.refusal_reason_id else None
                })
            
            return {
                'success': True,
                'data': {
                    'requests': requests_data,
                    'pagination': {
                        'page': page,
                        'limit': limit,
                        'total': total_count,
                        'pages': (total_count + limit - 1) // limit
                    }
                }
            }
            
        except Exception as e:
            _logger.error('Erreur liste demandes citoyen: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors du chargement des demandes',
                'error_code': 'REQUESTS_ERROR'
            }

    @http.route('/api/mobile/citizen/requests/create', type='json', auth='none', methods=['POST'], csrf=False)
    def create_information_request(self, **kwargs):
        """
        Créer une nouvelle demande d'information
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_auth(token)
            
            if isinstance(user, dict):
                return user
            
            data = request.jsonrequest
            
            # Validation des champs requis
            required_fields = ['description', 'requester_quality']
            for field in required_fields:
                if not data.get(field):
                    return {
                        'success': False,
                        'error': f'Le champ {field} est requis',
                        'error_code': 'MISSING_FIELD'
                    }
            
            # Créer la demande
            request_vals = {
                'partner_name': user.name,
                'partner_email': user.email,
                'partner_phone': data.get('phone', user.phone),
                'requester_quality': data.get('requester_quality'),
                'description': data.get('description'),
                'state': 'submitted'
            }
            
            # Assigner le stage initial
            try:
                stage_id = request.env.ref('sama_conai.stage_new').id
                request_vals['stage_id'] = stage_id
            except:
                # Fallback
                stage = request.env['request.information.stage'].sudo().search([], limit=1)
                if stage:
                    request_vals['stage_id'] = stage.id
            
            info_request = request.env['request.information'].sudo().create(request_vals)
            
            # Envoyer l'accusé de réception
            try:
                info_request._send_acknowledgment_email()
            except:
                pass  # Ne pas faire échouer la création si l'email échoue
            
            return {
                'success': True,
                'data': {
                    'request_id': info_request.id,
                    'request_number': info_request.name,
                    'deadline_date': info_request.deadline_date.isoformat() if info_request.deadline_date else None
                },
                'message': 'Demande créée avec succès'
            }
            
        except Exception as e:
            _logger.error('Erreur création demande: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de la création de la demande',
                'error_code': 'CREATE_ERROR'
            }

    @http.route('/api/mobile/citizen/alerts/create', type='json', auth='none', methods=['POST'], csrf=False)
    def create_whistleblowing_alert(self, **kwargs):
        """
        Créer un signalement d'alerte (anonyme ou identifié)
        """
        try:
            data = request.jsonrequest
            
            # Validation des champs requis
            required_fields = ['description', 'category']
            for field in required_fields:
                if not data.get(field):
                    return {
                        'success': False,
                        'error': f'Le champ {field} est requis',
                        'error_code': 'MISSING_FIELD'
                    }
            
            # Vérifier si c'est anonyme ou identifié
            is_anonymous = data.get('is_anonymous', True)
            alert_vals = {
                'description': data.get('description'),
                'category': data.get('category'),
                'is_anonymous': is_anonymous,
                'priority': data.get('priority', 'medium'),
                'state': 'new'
            }
            
            # Si identifié, récupérer les infos utilisateur
            if not is_anonymous:
                token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
                user = self._authenticate_mobile_user(token)
                
                if user:
                    alert_vals.update({
                        'reporter_name': user.name,
                        'reporter_email': user.email,
                        'reporter_phone': user.phone
                    })
            
            # Assigner le stage initial
            try:
                stage_id = request.env.ref('sama_conai.whistleblowing_stage_new').id
                alert_vals['stage_id'] = stage_id
            except:
                # Fallback
                stage = request.env['whistleblowing.alert.stage'].sudo().search([], limit=1)
                if stage:
                    alert_vals['stage_id'] = stage.id
            
            alert = request.env['whistleblowing.alert'].sudo().create(alert_vals)
            
            return {
                'success': True,
                'data': {
                    'alert_id': alert.id,
                    'alert_number': alert.name,
                    'access_token': alert.access_token if is_anonymous else None,
                    'tracking_url': f'/ws/follow/{alert.access_token}' if is_anonymous else None
                },
                'message': 'Signalement créé avec succès'
            }
            
        except Exception as e:
            _logger.error('Erreur création alerte: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de la création du signalement',
                'error_code': 'CREATE_ALERT_ERROR'
            }

    @http.route('/api/mobile/citizen/alerts/track', type='json', auth='none', methods=['POST'], csrf=False)
    def track_alert(self, **kwargs):
        """
        Suivre un signalement anonyme via token
        """
        try:
            data = request.jsonrequest
            access_token = data.get('access_token')
            
            if not access_token:
                return {
                    'success': False,
                    'error': 'Token d\'accès requis',
                    'error_code': 'MISSING_TOKEN'
                }
            
            alert_data = request.env['whistleblowing.alert'].sudo().get_alert_by_token(access_token)
            
            if not alert_data:
                return {
                    'success': False,
                    'error': 'Signalement non trouvé',
                    'error_code': 'ALERT_NOT_FOUND'
                }
            
            return {
                'success': True,
                'data': alert_data
            }
            
        except Exception as e:
            _logger.error('Erreur suivi alerte: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors du suivi du signalement',
                'error_code': 'TRACK_ERROR'
            }

    @http.route('/api/mobile/citizen/notifications', type='json', auth='none', methods=['GET'], csrf=False)
    def get_notifications(self, **kwargs):
        """
        Récupérer les notifications du citoyen
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_auth(token)
            
            if isinstance(user, dict):
                return user
            
            # Récupérer les notifications liées aux demandes de l'utilisateur
            notifications = []
            
            # Notifications des demandes d'information
            info_requests = request.env['request.information'].sudo().search([
                ('partner_email', '=', user.email)
            ])
            
            for req in info_requests:
                # Vérifier si proche de l'échéance
                if req.days_to_deadline <= 5 and req.state in ['submitted', 'in_progress']:
                    notifications.append({
                        'id': f'deadline_{req.id}',
                        'type': 'deadline_warning',
                        'title': 'Échéance proche',
                        'message': f'Votre demande {req.name} arrive à échéance dans {req.days_to_deadline} jours',
                        'date': datetime.now().isoformat(),
                        'related_object': {
                            'type': 'information_request',
                            'id': req.id
                        }
                    })
                
                # Notification de réponse
                if req.state in ['responded', 'refused'] and req.response_date:
                    # Vérifier si c'est récent (dernières 7 jours)
                    if (datetime.now() - req.response_date).days <= 7:
                        notifications.append({
                            'id': f'response_{req.id}',
                            'type': 'response_received',
                            'title': 'Réponse reçue',
                            'message': f'Une réponse a été donnée à votre demande {req.name}',
                            'date': req.response_date.isoformat(),
                            'related_object': {
                                'type': 'information_request',
                                'id': req.id
                            }
                        })
            
            # Trier par date décroissante
            notifications.sort(key=lambda x: x['date'], reverse=True)
            
            return {
                'success': True,
                'data': {
                    'notifications': notifications[:20]  # Limiter à 20
                }
            }
            
        except Exception as e:
            _logger.error('Erreur notifications: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors du chargement des notifications',
                'error_code': 'NOTIFICATIONS_ERROR'
            }

    def _calculate_avg_response_time(self, requests):
        """Calculer le temps de réponse moyen"""
        responded_requests = requests.filtered(lambda r: r.response_date and r.request_date)
        if not responded_requests:
            return 0
        
        total_days = sum([
            (req.response_date.date() - req.request_date.date()).days 
            for req in responded_requests
        ])
        
        return round(total_days / len(responded_requests), 1)

    def _calculate_success_rate(self, requests):
        """Calculer le taux de succès"""
        if not requests:
            return 0
        
        completed_requests = requests.filtered(lambda r: r.state in ['responded', 'refused'])
        if not completed_requests:
            return 0
        
        successful_requests = completed_requests.filtered(lambda r: r.state == 'responded')
        return round((len(successful_requests) / len(completed_requests)) * 100, 1)