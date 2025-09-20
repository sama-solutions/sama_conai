# -*- coding: utf-8 -*-

import json
import logging
from datetime import datetime, timedelta
from odoo import http, fields, _
from odoo.http import request
from odoo.exceptions import ValidationError, AccessError

_logger = logging.getLogger(__name__)


class MobileAgentController(http.Controller):
    """
    Contrôleur API mobile pour les agents publics
    """

    def _authenticate_mobile_user(self, token):
        """Authentifier l'utilisateur mobile via token"""
        if not token:
            return None
        
        # Utiliser la méthode de vérification du contrôleur d'auth
        auth_controller = request.env['mobile.auth.controller']
        return auth_controller._verify_mobile_token(token)

    def _require_agent_auth(self, token):
        """Vérifier l'authentification agent et retourner l'utilisateur"""
        user = self._authenticate_mobile_user(token)
        if not user:
            return {
                'success': False,
                'error': 'Token invalide ou expiré',
                'error_code': 'AUTHENTICATION_REQUIRED'
            }
        
        # Vérifier les permissions agent
        if not (user.has_group('sama_conai.group_info_request_user') or 
               user.has_group('sama_conai.group_whistleblowing_user')):
            return {
                'success': False,
                'error': 'Accès agent requis',
                'error_code': 'AGENT_ACCESS_REQUIRED'
            }
        
        return user

    @http.route('/api/mobile/agent/dashboard', type='json', auth='none', methods=['GET'], csrf=False)
    def get_agent_dashboard(self, **kwargs):
        """
        Tableau de bord agent mobile
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_agent_auth(token)
            
            if isinstance(user, dict):  # Erreur d'auth
                return user
            
            # Statistiques des tâches assignées à l'agent
            assigned_info_requests = request.env['request.information'].sudo().search([
                ('user_id', '=', user.id)
            ])
            
            assigned_alerts = request.env['whistleblowing.alert'].sudo().search([
                ('manager_id', '=', user.id)
            ])
            
            # Statistiques des demandes d'information
            info_stats = {
                'total_assigned': len(assigned_info_requests),
                'pending_action': len(assigned_info_requests.filtered(
                    lambda r: r.state in ['submitted', 'in_progress']
                )),
                'pending_validation': len(assigned_info_requests.filtered(
                    lambda r: r.state == 'pending_validation'
                )),
                'overdue': len(assigned_info_requests.filtered(lambda r: r.is_overdue)),
                'completed_today': len(assigned_info_requests.filtered(
                    lambda r: r.response_date and r.response_date.date() == fields.Date.today()
                ))
            }
            
            # Statistiques des alertes
            alert_stats = {
                'total_assigned': len(assigned_alerts),
                'new_alerts': len(assigned_alerts.filtered(lambda a: a.state == 'new')),
                'in_investigation': len(assigned_alerts.filtered(lambda a: a.state == 'investigation')),
                'high_priority': len(assigned_alerts.filtered(lambda a: a.priority == 'high')),
                'urgent': len(assigned_alerts.filtered(lambda a: a.priority == 'urgent'))
            }
            
            # Tâches urgentes
            urgent_tasks = []
            
            # Demandes en retard
            overdue_requests = assigned_info_requests.filtered(lambda r: r.is_overdue)
            for req in overdue_requests[:5]:
                urgent_tasks.append({
                    'id': req.id,
                    'type': 'information_request',
                    'title': f'Demande en retard: {req.name}',
                    'description': req.description[:100] + '...',
                    'priority': 'high',
                    'due_date': req.deadline_date.isoformat() if req.deadline_date else None,
                    'days_overdue': abs(req.days_to_deadline)
                })
            
            # Alertes urgentes
            urgent_alerts = assigned_alerts.filtered(lambda a: a.priority in ['high', 'urgent'])
            for alert in urgent_alerts[:5]:
                urgent_tasks.append({
                    'id': alert.id,
                    'type': 'whistleblowing_alert',
                    'title': f'Alerte {alert.priority}: {alert.name}',
                    'description': alert.description[:100] + '...',
                    'priority': alert.priority,
                    'category': alert.category,
                    'alert_date': alert.alert_date.isoformat()
                })
            
            # Trier par priorité
            priority_order = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3}
            urgent_tasks.sort(key=lambda x: priority_order.get(x['priority'], 3))
            
            # Activités récentes
            recent_activities = self._get_recent_activities(user)
            
            return {
                'success': True,
                'data': {
                    'info_request_stats': info_stats,
                    'alert_stats': alert_stats,
                    'urgent_tasks': urgent_tasks[:10],
                    'recent_activities': recent_activities
                }
            }
            
        except Exception as e:
            _logger.error('Erreur dashboard agent: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors du chargement du tableau de bord',
                'error_code': 'DASHBOARD_ERROR'
            }

    @http.route('/api/mobile/agent/tasks', type='json', auth='none', methods=['GET'], csrf=False)
    def get_agent_tasks(self, **kwargs):
        """
        Liste des tâches assignées à l'agent
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_agent_auth(token)
            
            if isinstance(user, dict):
                return user
            
            data = request.jsonrequest or {}
            task_type = data.get('type', 'all')  # all, info_requests, alerts
            status_filter = data.get('status')
            priority_filter = data.get('priority')
            page = data.get('page', 1)
            limit = data.get('limit', 20)
            
            tasks = []
            
            # Demandes d'information
            if task_type in ['all', 'info_requests']:
                domain = [('user_id', '=', user.id)]
                if status_filter:
                    domain.append(('state', '=', status_filter))
                
                info_requests = request.env['request.information'].sudo().search(
                    domain, order='request_date desc'
                )
                
                for req in info_requests:
                    tasks.append({
                        'id': req.id,
                        'type': 'information_request',
                        'title': f'Demande d\'information: {req.name}',
                        'description': req.description,
                        'requester': req.partner_name,
                        'requester_email': req.partner_email,
                        'request_date': req.request_date.isoformat() if req.request_date else None,
                        'deadline_date': req.deadline_date.isoformat() if req.deadline_date else None,
                        'state': req.state,
                        'state_label': dict(req._fields['state'].selection)[req.state],
                        'stage_name': req.stage_id.name,
                        'days_to_deadline': req.days_to_deadline,
                        'is_overdue': req.is_overdue,
                        'priority': 'high' if req.is_overdue else 'medium',
                        'can_process': req.state in ['submitted', 'in_progress'],
                        'can_validate': req.state == 'pending_validation' and user.has_group('sama_conai.group_info_request_manager')
                    })
            
            # Alertes
            if task_type in ['all', 'alerts']:
                domain = [('manager_id', '=', user.id)]
                if status_filter:
                    domain.append(('state', '=', status_filter))
                if priority_filter:
                    domain.append(('priority', '=', priority_filter))
                
                alerts = request.env['whistleblowing.alert'].sudo().search(
                    domain, order='alert_date desc'
                )
                
                for alert in alerts:
                    tasks.append({
                        'id': alert.id,
                        'type': 'whistleblowing_alert',
                        'title': f'Signalement: {alert.name}',
                        'description': alert.description,
                        'category': alert.category,
                        'category_label': dict(alert._fields['category'].selection)[alert.category],
                        'alert_date': alert.alert_date.isoformat() if alert.alert_date else None,
                        'state': alert.state,
                        'state_label': dict(alert._fields['state'].selection)[alert.state],
                        'stage_name': alert.stage_id.name,
                        'priority': alert.priority,
                        'priority_label': dict(alert._fields['priority'].selection)[alert.priority],
                        'is_anonymous': alert.is_anonymous,
                        'can_process': alert.state in ['new', 'preliminary_assessment', 'investigation']
                    })
            
            # Trier par priorité et date
            priority_order = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3}
            tasks.sort(key=lambda x: (priority_order.get(x.get('priority', 'medium'), 2), x.get('request_date', x.get('alert_date', ''))))
            
            # Pagination
            offset = (page - 1) * limit
            total_count = len(tasks)
            paginated_tasks = tasks[offset:offset + limit]
            
            return {
                'success': True,
                'data': {
                    'tasks': paginated_tasks,
                    'pagination': {
                        'page': page,
                        'limit': limit,
                        'total': total_count,
                        'pages': (total_count + limit - 1) // limit
                    }
                }
            }
            
        except Exception as e:
            _logger.error('Erreur tâches agent: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors du chargement des tâches',
                'error_code': 'TASKS_ERROR'
            }

    @http.route('/api/mobile/agent/info-request/<int:request_id>', type='json', auth='none', methods=['GET'], csrf=False)
    def get_info_request_detail(self, request_id, **kwargs):
        """
        Détail d'une demande d'information
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_agent_auth(token)
            
            if isinstance(user, dict):
                return user
            
            info_request = request.env['request.information'].sudo().browse(request_id)
            
            if not info_request.exists():
                return {
                    'success': False,
                    'error': 'Demande non trouvée',
                    'error_code': 'REQUEST_NOT_FOUND'
                }
            
            # Vérifier les permissions
            if info_request.user_id != user and not user.has_group('sama_conai.group_info_request_manager'):
                return {
                    'success': False,
                    'error': 'Accès non autorisé',
                    'error_code': 'ACCESS_DENIED'
                }
            
            # Historique des activités
            activities = []
            for message in info_request.message_ids.sorted('date'):
                activities.append({
                    'date': message.date.isoformat(),
                    'author': message.author_id.name,
                    'body': message.body,
                    'message_type': message.message_type
                })
            
            return {
                'success': True,
                'data': {
                    'id': info_request.id,
                    'name': info_request.name,
                    'description': info_request.description,
                    'requester_name': info_request.partner_name,
                    'requester_email': info_request.partner_email,
                    'requester_phone': info_request.partner_phone,
                    'requester_quality': info_request.requester_quality,
                    'request_date': info_request.request_date.isoformat() if info_request.request_date else None,
                    'deadline_date': info_request.deadline_date.isoformat() if info_request.deadline_date else None,
                    'response_date': info_request.response_date.isoformat() if info_request.response_date else None,
                    'state': info_request.state,
                    'state_label': dict(info_request._fields['state'].selection)[info_request.state],
                    'stage_name': info_request.stage_id.name,
                    'days_to_deadline': info_request.days_to_deadline,
                    'is_overdue': info_request.is_overdue,
                    'response_body': info_request.response_body,
                    'is_refusal': info_request.is_refusal,
                    'refusal_reason': info_request.refusal_reason_id.name if info_request.refusal_reason_id else None,
                    'refusal_motivation': info_request.refusal_motivation,
                    'assigned_user': info_request.user_id.name if info_request.user_id else None,
                    'department': info_request.department_id.name if info_request.department_id else None,
                    'activities': activities,
                    'permissions': {
                        'can_edit': info_request.user_id == user or user.has_group('sama_conai.group_info_request_manager'),
                        'can_validate': user.has_group('sama_conai.group_info_request_manager'),
                        'can_assign': user.has_group('sama_conai.group_info_request_manager')
                    }
                }
            }
            
        except Exception as e:
            _logger.error('Erreur détail demande: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors du chargement du détail',
                'error_code': 'DETAIL_ERROR'
            }

    @http.route('/api/mobile/agent/info-request/<int:request_id>/update', type='json', auth='none', methods=['POST'], csrf=False)
    def update_info_request(self, request_id, **kwargs):
        """
        Mettre à jour une demande d'information
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_agent_auth(token)
            
            if isinstance(user, dict):
                return user
            
            data = request.jsonrequest
            info_request = request.env['request.information'].sudo().browse(request_id)
            
            if not info_request.exists():
                return {
                    'success': False,
                    'error': 'Demande non trouvée',
                    'error_code': 'REQUEST_NOT_FOUND'
                }
            
            # Vérifier les permissions
            if info_request.user_id != user and not user.has_group('sama_conai.group_info_request_manager'):
                return {
                    'success': False,
                    'error': 'Accès non autorisé',
                    'error_code': 'ACCESS_DENIED'
                }
            
            action = data.get('action')
            
            if action == 'start_processing':
                info_request.action_start_processing()
                message = 'Traitement commencé'
            
            elif action == 'add_response':
                response_body = data.get('response_body')
                if not response_body:
                    return {
                        'success': False,
                        'error': 'Corps de réponse requis',
                        'error_code': 'MISSING_RESPONSE'
                    }
                
                info_request.write({'response_body': response_body})
                message = 'Réponse ajoutée'
            
            elif action == 'refuse':
                refusal_reason_id = data.get('refusal_reason_id')
                refusal_motivation = data.get('refusal_motivation')
                
                if not refusal_reason_id or not refusal_motivation:
                    return {
                        'success': False,
                        'error': 'Motif et motivation de refus requis',
                        'error_code': 'MISSING_REFUSAL_DATA'
                    }
                
                info_request.write({
                    'is_refusal': True,
                    'refusal_reason_id': refusal_reason_id,
                    'refusal_motivation': refusal_motivation
                })
                message = 'Refus enregistré'
            
            elif action == 'request_validation':
                info_request.action_request_validation()
                message = 'Validation demandée'
            
            elif action == 'approve' and user.has_group('sama_conai.group_info_request_manager'):
                info_request.action_approve()
                message = 'Demande approuvée'
            
            elif action == 'reject_validation' and user.has_group('sama_conai.group_info_request_manager'):
                info_request.action_reject_validation()
                message = 'Validation rejetée'
            
            else:
                return {
                    'success': False,
                    'error': 'Action non valide ou non autorisée',
                    'error_code': 'INVALID_ACTION'
                }
            
            # Ajouter un commentaire
            comment = data.get('comment')
            if comment:
                info_request.message_post(
                    body=comment,
                    message_type='comment',
                    author_id=user.partner_id.id
                )
            
            return {
                'success': True,
                'message': message,
                'new_state': info_request.state
            }
            
        except Exception as e:
            _logger.error('Erreur mise à jour demande: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de la mise à jour',
                'error_code': 'UPDATE_ERROR'
            }

    @http.route('/api/mobile/agent/alert/<int:alert_id>', type='json', auth='none', methods=['GET'], csrf=False)
    def get_alert_detail(self, alert_id, **kwargs):
        """
        Détail d'une alerte
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_agent_auth(token)
            
            if isinstance(user, dict):
                return user
            
            alert = request.env['whistleblowing.alert'].sudo().browse(alert_id)
            
            if not alert.exists():
                return {
                    'success': False,
                    'error': 'Alerte non trouvée',
                    'error_code': 'ALERT_NOT_FOUND'
                }
            
            # Vérifier les permissions
            if not user.has_group('sama_conai.group_whistleblowing_user'):
                return {
                    'success': False,
                    'error': 'Accès non autorisé',
                    'error_code': 'ACCESS_DENIED'
                }
            
            # Historique des activités
            activities = []
            for message in alert.message_ids.sorted('date'):
                activities.append({
                    'date': message.date.isoformat(),
                    'author': message.author_id.name,
                    'body': message.body,
                    'message_type': message.message_type
                })
            
            return {
                'success': True,
                'data': {
                    'id': alert.id,
                    'name': alert.name,
                    'description': alert.description,
                    'category': alert.category,
                    'category_label': dict(alert._fields['category'].selection)[alert.category],
                    'alert_date': alert.alert_date.isoformat() if alert.alert_date else None,
                    'state': alert.state,
                    'state_label': dict(alert._fields['state'].selection)[alert.state],
                    'stage_name': alert.stage_id.name,
                    'priority': alert.priority,
                    'priority_label': dict(alert._fields['priority'].selection)[alert.priority],
                    'is_anonymous': alert.is_anonymous,
                    'reporter_name': alert.reporter_name if not alert.is_anonymous else None,
                    'reporter_email': alert.reporter_email if not alert.is_anonymous else None,
                    'investigation_notes': alert.investigation_notes,
                    'investigation_start_date': alert.investigation_start_date.isoformat() if alert.investigation_start_date else None,
                    'investigation_end_date': alert.investigation_end_date.isoformat() if alert.investigation_end_date else None,
                    'resolution': alert.resolution,
                    'resolution_date': alert.resolution_date.isoformat() if alert.resolution_date else None,
                    'assigned_manager': alert.manager_id.name if alert.manager_id else None,
                    'activities': activities,
                    'permissions': {
                        'can_edit': user.has_group('sama_conai.group_whistleblowing_manager'),
                        'can_investigate': user.has_group('sama_conai.group_whistleblowing_manager'),
                        'can_assign': user.has_group('sama_conai.group_whistleblowing_manager')
                    }
                }
            }
            
        except Exception as e:
            _logger.error('Erreur détail alerte: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors du chargement du détail',
                'error_code': 'DETAIL_ERROR'
            }

    @http.route('/api/mobile/agent/alert/<int:alert_id>/update', type='json', auth='none', methods=['POST'], csrf=False)
    def update_alert(self, alert_id, **kwargs):
        """
        Mettre à jour une alerte
        """
        try:
            token = request.httprequest.headers.get('Authorization', '').replace('Bearer ', '')
            user = self._require_agent_auth(token)
            
            if isinstance(user, dict):
                return user
            
            data = request.jsonrequest
            alert = request.env['whistleblowing.alert'].sudo().browse(alert_id)
            
            if not alert.exists():
                return {
                    'success': False,
                    'error': 'Alerte non trouvée',
                    'error_code': 'ALERT_NOT_FOUND'
                }
            
            # Vérifier les permissions
            if not user.has_group('sama_conai.group_whistleblowing_manager'):
                return {
                    'success': False,
                    'error': 'Accès non autorisé',
                    'error_code': 'ACCESS_DENIED'
                }
            
            action = data.get('action')
            
            if action == 'start_assessment':
                alert.action_start_assessment()
                message = 'Évaluation commencée'
            
            elif action == 'start_investigation':
                alert.action_start_investigation()
                message = 'Enquête commencée'
            
            elif action == 'add_investigation_notes':
                notes = data.get('investigation_notes')
                if notes:
                    alert.write({'investigation_notes': notes})
                    message = 'Notes d\'investigation ajoutées'
                else:
                    return {
                        'success': False,
                        'error': 'Notes d\'investigation requises',
                        'error_code': 'MISSING_NOTES'
                    }
            
            elif action == 'resolve':
                resolution = data.get('resolution')
                if not resolution:
                    return {
                        'success': False,
                        'error': 'Résolution requise',
                        'error_code': 'MISSING_RESOLUTION'
                    }
                
                alert.write({'resolution': resolution})
                alert.action_resolve()
                message = 'Alerte résolue'
            
            elif action == 'transmit':
                alert.action_transmit()
                message = 'Alerte transmise'
            
            elif action == 'close':
                alert.action_close()
                message = 'Alerte clôturée'
            
            elif action == 'update_priority':
                priority = data.get('priority')
                if priority in ['low', 'medium', 'high', 'urgent']:
                    alert.write({'priority': priority})
                    message = f'Priorité mise à jour: {priority}'
                else:
                    return {
                        'success': False,
                        'error': 'Priorité invalide',
                        'error_code': 'INVALID_PRIORITY'
                    }
            
            else:
                return {
                    'success': False,
                    'error': 'Action non valide',
                    'error_code': 'INVALID_ACTION'
                }
            
            # Ajouter un commentaire
            comment = data.get('comment')
            if comment:
                alert.message_post(
                    body=comment,
                    message_type='comment',
                    author_id=user.partner_id.id
                )
            
            return {
                'success': True,
                'message': message,
                'new_state': alert.state
            }
            
        except Exception as e:
            _logger.error('Erreur mise à jour alerte: %s', str(e))
            return {
                'success': False,
                'error': 'Erreur lors de la mise à jour',
                'error_code': 'UPDATE_ERROR'
            }

    def _get_recent_activities(self, user):
        """
        Récupérer les activités récentes de l'agent
        """
        activities = []
        
        # Activités sur les demandes d'information
        info_requests = request.env['request.information'].sudo().search([
            ('user_id', '=', user.id)
        ], limit=10, order='write_date desc')
        
        for req in info_requests:
            activities.append({
                'id': req.id,
                'type': 'information_request',
                'title': f'Demande {req.name}',
                'description': f'État: {dict(req._fields["state"].selection)[req.state]}',
                'date': req.write_date.isoformat(),
                'object_id': req.id
            })
        
        # Activités sur les alertes
        alerts = request.env['whistleblowing.alert'].sudo().search([
            ('manager_id', '=', user.id)
        ], limit=10, order='write_date desc')
        
        for alert in alerts:
            activities.append({
                'id': alert.id,
                'type': 'whistleblowing_alert',
                'title': f'Alerte {alert.name}',
                'description': f'État: {dict(alert._fields["state"].selection)[alert.state]}',
                'date': alert.write_date.isoformat(),
                'object_id': alert.id
            })
        
        # Trier par date décroissante
        activities.sort(key=lambda x: x['date'], reverse=True)
        
        return activities[:10]