# -*- coding: utf-8 -*-

from odoo import http
from odoo.http import request
import json
import logging

_logger = logging.getLogger(__name__)


class SamaConaiDashboardController(http.Controller):
    """
    Contrôleur pour le dashboard neumorphique SAMA CONAI
    """

    @http.route('/sama_conai/dashboard', type='http', auth='user', website=True)
    def dashboard_main(self, **kwargs):
        """
        Route principale du dashboard neumorphique
        """
        try:
            # Récupérer les données du dashboard
            dashboard_data = self._get_dashboard_data()
            
            # Récupérer le thème de l'utilisateur
            user_theme = request.env.user.sama_conai_theme or 'default'
            
            # Préparer le contexte pour le template
            values = {
                'dashboard_data': dashboard_data,
                'user_theme': user_theme,
                'user': request.env.user,
                **dashboard_data  # Décompresser les données pour un accès direct
            }
            
            return request.render('sama_conai.dashboard_template', values)
            
        except Exception as e:
            _logger.error("Erreur lors du chargement du dashboard: %s", str(e))
            return request.render('web.http_error', {
                'status_code': 500,
                'status_message': 'Erreur interne du serveur'
            })

    @http.route('/sama_conai/dashboard/mobile', type='http', auth='user', website=True)
    def dashboard_mobile(self, **kwargs):
        """
        Route pour la version mobile du dashboard
        """
        try:
            dashboard_data = self._get_dashboard_data()
            user_theme = request.env.user.sama_conai_theme or 'default'
            
            values = {
                'dashboard_data': dashboard_data,
                'user_theme': user_theme,
                'user': request.env.user,
                **dashboard_data
            }
            
            return request.render('sama_conai.mobile_dashboard_template', values)
            
        except Exception as e:
            _logger.error("Erreur lors du chargement du dashboard mobile: %s", str(e))
            return request.render('web.http_error', {
                'status_code': 500,
                'status_message': 'Erreur interne du serveur'
            })

    @http.route('/sama_conai/theme_selector', type='http', auth='user', website=True)
    def theme_selector(self, **kwargs):
        """
        Route pour le sélecteur de thème
        """
        try:
            user_theme = request.env.user.sama_conai_theme or 'default'
            
            values = {
                'user_theme': user_theme,
                'user': request.env.user,
                'available_themes': [
                    {
                        'key': 'default',
                        'name': 'Thème Institutionnel',
                        'description': 'Couleurs officielles et professionnelles',
                        'colors': ['#EFF2F5', '#3498DB', '#E67E22', '#E74C3C']
                    },
                    {
                        'key': 'terre',
                        'name': 'Thème Terre du Sénégal',
                        'description': 'Inspiré des couleurs chaudes de la terre',
                        'colors': ['#F5F1E8', '#D2691E', '#CD853F', '#A0522D']
                    },
                    {
                        'key': 'moderne',
                        'name': 'Thème Moderne',
                        'description': 'Design contemporain et élégant',
                        'colors': ['#F8F9FA', '#6C5CE7', '#FDCB6E', '#E17055']
                    }
                ]
            }
            
            return request.render('sama_conai.theme_selector_template', values)
            
        except Exception as e:
            _logger.error("Erreur lors du chargement du sélecteur de thème: %s", str(e))
            return request.render('web.http_error', {
                'status_code': 500,
                'status_message': 'Erreur interne du serveur'
            })

    @http.route('/sama_conai/api/dashboard_data', type='json', auth='user')
    def api_dashboard_data(self, **kwargs):
        """
        API JSON pour récupérer les données du dashboard
        """
        try:
            return {
                'success': True,
                'data': self._get_dashboard_data()
            }
        except Exception as e:
            _logger.error("Erreur API dashboard_data: %s", str(e))
            return {
                'success': False,
                'error': str(e)
            }

    @http.route('/sama_conai/api/change_theme', type='json', auth='user')
    def api_change_theme(self, theme_name=None, **kwargs):
        """
        API pour changer le thème de l'utilisateur
        """
        try:
            if not theme_name:
                return {
                    'success': False,
                    'error': 'Nom du thème requis'
                }
            
            # Valider le nom du thème
            valid_themes = ['default', 'terre', 'moderne']
            if theme_name not in valid_themes:
                return {
                    'success': False,
                    'error': f'Thème invalide. Thèmes disponibles: {valid_themes}'
                }
            
            # Mettre à jour le thème de l'utilisateur
            request.env.user.write({'sama_conai_theme': theme_name})
            
            return {
                'success': True,
                'message': f'Thème "{theme_name}" appliqué avec succès',
                'theme': theme_name
            }
            
        except Exception as e:
            _logger.error("Erreur lors du changement de thème: %s", str(e))
            return {
                'success': False,
                'error': str(e)
            }

    @http.route('/sama_conai/api/user_theme', type='json', auth='user')
    def api_get_user_theme(self, **kwargs):
        """
        API pour récupérer le thème actuel de l'utilisateur
        """
        try:
            return {
                'success': True,
                'theme': request.env.user.sama_conai_theme or 'default'
            }
        except Exception as e:
            _logger.error("Erreur lors de la récupération du thème: %s", str(e))
            return {
                'success': False,
                'error': str(e)
            }

    def _get_dashboard_data(self):
        """
        Méthode privée pour récupérer les données du dashboard
        """
        try:
            # Modèles
            InformationRequest = request.env['request.information']
            WhistleblowingAlert = request.env['whistleblowing.alert']
            
            # Compter les demandes par statut
            in_progress_count = InformationRequest.search_count([
                ('state', 'in', ['submitted', 'in_progress', 'pending_validation'])
            ])
            
            completed_count = InformationRequest.search_count([
                ('state', '=', 'completed')
            ])
            
            overdue_count = InformationRequest.search_count([
                ('is_overdue', '=', True)
            ])
            
            cancelled_count = InformationRequest.search_count([
                ('state', '=', 'cancelled')
            ])
            
            # Compter les alertes actives
            active_alerts = WhistleblowingAlert.search_count([
                ('state', 'in', ['submitted', 'in_progress'])
            ])
            
            # Total des demandes
            total_requests = InformationRequest.search_count([]) + WhistleblowingAlert.search_count([])
            
            # Récupérer les tâches prioritaires
            priority_tasks = self._get_priority_tasks()
            
            return {
                'in_progress_count': in_progress_count,
                'completed_count': completed_count,
                'overdue_count': overdue_count,
                'cancelled_count': cancelled_count,
                'active_alerts': active_alerts,
                'total_requests': total_requests,
                'priority_tasks': priority_tasks,
            }
            
        except Exception as e:
            _logger.error("Erreur lors de la récupération des données: %s", str(e))
            # Retourner des données par défaut en cas d'erreur
            return {
                'in_progress_count': 0,
                'completed_count': 0,
                'overdue_count': 0,
                'cancelled_count': 0,
                'active_alerts': 0,
                'total_requests': 0,
                'priority_tasks': [],
            }

    def _get_priority_tasks(self):
        """
        Récupère les tâches prioritaires pour affichage
        """
        try:
            tasks = []
            
            # Demandes en retard (priorité haute)
            overdue_requests = request.env['request.information'].search([
                ('is_overdue', '=', True)
            ], limit=3)
            
            for req in overdue_requests:
                tasks.append({
                    'reference': req.name or 'N/A',
                    'title': f"Demande en retard: {req.subject[:50]}..." if req.subject else "Demande sans objet",
                    'urgency_color': '#E74C3C'  # Rouge pour urgent
                })
            
            # Alertes récentes (priorité moyenne)
            recent_alerts = request.env['whistleblowing.alert'].search([
                ('state', '=', 'submitted')
            ], limit=2)
            
            for alert in recent_alerts:
                tasks.append({
                    'reference': alert.name or 'N/A',
                    'title': f"Nouvelle alerte: {alert.subject[:50]}..." if alert.subject else "Alerte sans objet",
                    'urgency_color': '#E67E22'  # Orange pour moyen
                })
            
            # Si pas assez de tâches, ajouter des tâches génériques
            if len(tasks) < 3:
                tasks.append({
                    'reference': 'INFO',
                    'title': 'Système opérationnel - Aucune tâche urgente',
                    'urgency_color': '#27AE60'  # Vert pour normal
                })
            
            return tasks[:5]  # Limiter à 5 tâches maximum
            
        except Exception as e:
            _logger.error("Erreur lors de la récupération des tâches prioritaires: %s", str(e))
            return [{
                'reference': 'ERROR',
                'title': 'Erreur lors du chargement des tâches',
                'urgency_color': '#E74C3C'
            }]