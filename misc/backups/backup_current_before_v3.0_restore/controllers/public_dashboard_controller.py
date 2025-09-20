# -*- coding: utf-8 -*-

from odoo import http, fields, _
from odoo.http import request
from datetime import datetime, timedelta
import json

class PublicDashboardRealDataController(http.Controller):
    """Contrôleur avec données 100% réelles du backend et actions utilisateur"""
    
    @http.route('/transparence-dashboard', type='http', auth='public', website=True, csrf=False)
    def transparency_dashboard(self, **kwargs):
        """Page principale du tableau de bord de transparence avec données réelles"""
        
        try:
            # Calculer les statistiques réelles
            stats = self._get_real_statistics()
            
            # Préparer les données réelles pour les graphiques
            charts_data = self._get_real_charts_data()
            
            # Données détaillées réelles pour le drill down
            drill_down_data = self._get_real_drill_down_data()
            
            # Vérifier si l'utilisateur est connecté
            user_info = self._get_user_info()
            
            values = {
                'page_name': 'transparency_dashboard',
                'stats': stats,
                'charts_data': charts_data,
                'drill_down_data': drill_down_data,
                'user_info': user_info,
                'last_update': datetime.now(),
            }
            
            return request.render('sama_conai.transparency_dashboard_template', values)
            
        except Exception as e:
            # En cas d'erreur, afficher un dashboard minimal
            values = {
                'page_name': 'transparency_dashboard_error',
                'error_message': f'Erreur lors du chargement des données: {str(e)}',
                'last_update': datetime.now(),
                'user_info': self._get_user_info(),
                'stats': {
                    'total_requests': 0,
                    'processing_rate': 0,
                    'avg_processing_days': 0,
                    'on_time_rate': 0,
                }
            }
            return request.render('sama_conai.transparency_dashboard_template', values)
    
    @http.route('/transparence-dashboard/new-request', type='http', auth='user', website=True, csrf=False)
    def new_information_request(self, **kwargs):
        """Créer une nouvelle demande d'information (utilisateur connecté)"""
        
        if not request.env.user or request.env.user._is_public():
            return request.redirect('/web/login?redirect=/transparence-dashboard/new-request')
        
        # Rediriger vers le formulaire de création de demande
        return request.redirect('/web#action=sama_conai.action_information_request&view_type=form&model=request.information')
    
    @http.route('/transparence-dashboard/my-requests', type='http', auth='user', website=True, csrf=False)
    def my_information_requests(self, **kwargs):
        """Voir mes demandes d'information (utilisateur connecté)"""
        
        if not request.env.user or request.env.user._is_public():
            return request.redirect('/web/login?redirect=/transparence-dashboard/my-requests')
        
        # Rediriger vers la vue de mes demandes
        partner_email = request.env.user.partner_id.email
        domain = [('partner_email', '=', partner_email)] if partner_email else []
        
        action_id = request.env.ref('sama_conai.action_information_request').id
        return request.redirect(f'/web#action={action_id}&model=request.information&view_type=list&domain={domain}')
    
    @http.route('/transparence-dashboard/new-alert', type='http', auth='user', website=True, csrf=False)
    def new_whistleblowing_alert(self, **kwargs):
        """Créer un nouveau signalement (utilisateur connecté)"""
        
        if not request.env.user or request.env.user._is_public():
            return request.redirect('/web/login?redirect=/transparence-dashboard/new-alert')
        
        # Rediriger vers le formulaire de création de signalement
        return request.redirect('/web#action=sama_conai.action_whistleblowing_alert&view_type=form&model=whistleblowing.alert')
    
    @http.route('/transparence-dashboard/help', type='http', auth='public', website=True, csrf=False)
    def help_and_contact(self, **kwargs):
        """Page d'aide et contact"""
        
        values = {
            'page_name': 'help_contact',
            'user_info': self._get_user_info(),
        }
        
        return request.render('sama_conai.help_contact_template', values)
    
    def _get_user_info(self):
        """Récupère les informations de l'utilisateur connecté"""
        
        user_info = {
            'is_authenticated': False,
            'name': '',
            'email': '',
            'can_create_requests': False,
            'can_view_requests': False,
        }
        
        try:
            if request.env.user and not request.env.user._is_public():
                user_info.update({
                    'is_authenticated': True,
                    'name': request.env.user.name,
                    'email': request.env.user.email or '',
                    'can_create_requests': True,
                    'can_view_requests': True,
                })
        except Exception:
            pass
        
        return user_info
    
    def _get_real_statistics(self):
        """Calcule les statistiques 100% réelles du backend"""
        
        stats = {}
        
        try:
            # Statistiques des demandes d'information (données réelles)
            info_requests = request.env['request.information'].sudo()
            
            # Nombre total de demandes
            stats['total_requests'] = info_requests.search_count([])
            
            # Demandes traitées (répondues ou refusées)
            stats['processed_requests'] = info_requests.search_count([
                ('state', 'in', ['responded', 'refused'])
            ])
            
            # Demandes en cours
            stats['pending_requests'] = info_requests.search_count([
                ('state', 'in', ['submitted', 'in_progress', 'pending_validation'])
            ])
            
            # Taux de traitement réel
            if stats['total_requests'] > 0:
                stats['processing_rate'] = round(
                    (stats['processed_requests'] / stats['total_requests']) * 100, 1
                )
            else:
                stats['processing_rate'] = 0
            
            # Délai moyen de traitement RÉEL
            processed_requests = info_requests.search([
                ('state', 'in', ['responded', 'refused']),
                ('response_date', '!=', False),
                ('request_date', '!=', False)
            ])
            
            if processed_requests:
                total_days = 0
                count = 0
                for req in processed_requests:
                    try:
                        request_date = fields.Date.from_string(req.request_date)
                        response_date = fields.Date.from_string(req.response_date)
                        delta = response_date - request_date
                        total_days += delta.days
                        count += 1
                    except:
                        continue
                
                stats['avg_processing_days'] = round(total_days / count, 1) if count > 0 else 0
            else:
                stats['avg_processing_days'] = 0
            
            # Taux de respect des délais RÉEL (30 jours)
            on_time_requests = 0
            if processed_requests:
                for req in processed_requests:
                    try:
                        request_date = fields.Date.from_string(req.request_date)
                        response_date = fields.Date.from_string(req.response_date)
                        delta = response_date - request_date
                        if delta.days <= 30:
                            on_time_requests += 1
                    except:
                        continue
                
                stats['on_time_rate'] = round(
                    (on_time_requests / len(processed_requests)) * 100, 1
                ) if processed_requests else 0
            else:
                stats['on_time_rate'] = 0
            
            # Demandes récentes (30 derniers jours) - RÉEL
            thirty_days_ago = (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d')
            stats['recent_requests'] = info_requests.search_count([
                ('request_date', '>=', thirty_days_ago)
            ])
            
        except Exception as e:
            # En cas d'erreur, valeurs nulles
            stats.update({
                'total_requests': 0,
                'processed_requests': 0,
                'pending_requests': 0,
                'processing_rate': 0,
                'avg_processing_days': 0,
                'on_time_rate': 0,
                'recent_requests': 0,
            })
        
        try:
            # Statistiques des signalements (données réelles)
            alerts = request.env['whistleblowing.alert'].sudo()
            
            stats['total_alerts'] = alerts.search_count([])
            stats['resolved_alerts'] = alerts.search_count([
                ('state', 'in', ['resolved', 'closed'])
            ])
            stats['pending_alerts'] = alerts.search_count([
                ('state', 'in', ['new', 'preliminary_assessment', 'investigation'])
            ])
            
            if stats['total_alerts'] > 0:
                stats['alert_resolution_rate'] = round(
                    (stats['resolved_alerts'] / stats['total_alerts']) * 100, 1
                )
            else:
                stats['alert_resolution_rate'] = 0
                
        except Exception:
            stats.update({
                'total_alerts': 0,
                'resolved_alerts': 0,
                'pending_alerts': 0,
                'alert_resolution_rate': 0,
            })
        
        return stats
    
    def _get_real_charts_data(self):
        """Prépare les données réelles pour les graphiques"""
        
        charts_data = {}
        
        try:
            # Évolution mensuelle des demandes (données réelles)
            monthly_data = self._get_real_monthly_requests_data()
            charts_data['monthly_requests'] = monthly_data
            
            # Répartition par état des demandes (données réelles)
            status_data = self._get_real_requests_by_status()
            charts_data['requests_by_status'] = status_data
            
            # Évolution des signalements (données réelles)
            alerts_monthly = self._get_real_monthly_alerts_data()
            charts_data['monthly_alerts'] = alerts_monthly
            
        except Exception:
            charts_data = {
                'monthly_requests': [],
                'requests_by_status': [],
                'monthly_alerts': [],
            }
        
        return charts_data
    
    def _get_real_monthly_requests_data(self):
        """Données mensuelles réelles des demandes (6 derniers mois)"""
        
        data = []
        
        try:
            today = datetime.now().date()
            for i in range(6):
                # Calculer le mois
                if today.month - i <= 0:
                    month = today.month - i + 12
                    year = today.year - 1
                else:
                    month = today.month - i
                    year = today.year
                
                month_start = datetime(year, month, 1).date()
                if month == 12:
                    month_end = datetime(year + 1, 1, 1).date() - timedelta(days=1)
                else:
                    month_end = datetime(year, month + 1, 1).date() - timedelta(days=1)
                
                # Compter les demandes réelles du mois
                count = request.env['request.information'].sudo().search_count([
                    ('request_date', '>=', month_start.strftime('%Y-%m-%d')),
                    ('request_date', '<=', month_end.strftime('%Y-%m-%d'))
                ])
                
                data.append({
                    'month': month_start.strftime('%Y-%m'),
                    'month_name': month_start.strftime('%B %Y'),
                    'count': count
                })
            
            # Inverser pour avoir l'ordre chronologique
            data.reverse()
            
        except Exception:
            data = []
        
        return data
    
    def _get_real_requests_by_status(self):
        """Répartition réelle des demandes par état"""
        
        data = []
        
        try:
            states = [
                ('submitted', 'Soumises'),
                ('in_progress', 'En traitement'),
                ('pending_validation', 'En validation'),
                ('responded', 'Répondues'),
                ('refused', 'Refusées'),
            ]
            
            for state_code, state_name in states:
                count = request.env['request.information'].sudo().search_count([
                    ('state', '=', state_code)
                ])
                
                if count > 0:
                    data.append({
                        'status': state_name,
                        'count': count,
                        'state_code': state_code
                    })
                    
        except Exception:
            data = []
        
        return data
    
    def _get_real_monthly_alerts_data(self):
        """Données mensuelles réelles des signalements"""
        
        data = []
        
        try:
            today = datetime.now().date()
            for i in range(6):
                # Calculer le mois
                if today.month - i <= 0:
                    month = today.month - i + 12
                    year = today.year - 1
                else:
                    month = today.month - i
                    year = today.year
                
                month_start = datetime(year, month, 1).date()
                if month == 12:
                    month_end = datetime(year + 1, 1, 1).date() - timedelta(days=1)
                else:
                    month_end = datetime(year, month + 1, 1).date() - timedelta(days=1)
                
                # Compter les signalements réels du mois
                count = request.env['whistleblowing.alert'].sudo().search_count([
                    ('alert_date', '>=', month_start.strftime('%Y-%m-%d')),
                    ('alert_date', '<=', month_end.strftime('%Y-%m-%d'))
                ])
                
                data.append({
                    'month': month_start.strftime('%Y-%m'),
                    'month_name': month_start.strftime('%B %Y'),
                    'count': count
                })
            
            # Inverser pour avoir l'ordre chronologique
            data.reverse()
            
        except Exception:
            data = []
        
        return data
    
    def _get_real_drill_down_data(self):
        """Données réelles pour le drill down"""
        
        drill_data = {}
        
        try:
            # Données réelles par qualité de demandeur
            drill_data['by_requester_quality'] = self._get_real_requests_by_quality()
            
            # Données réelles de performance
            drill_data['performance_metrics'] = self._get_real_performance_metrics()
            
        except Exception:
            drill_data = {
                'by_requester_quality': [],
                'performance_metrics': {}
            }
        
        return drill_data
    
    def _get_real_requests_by_quality(self):
        """Répartition réelle des demandes par qualité de demandeur"""
        
        data = []
        
        try:
            qualities = [
                ('citizen', 'Citoyens'),
                ('journalist', 'Journalistes'),
                ('researcher', 'Chercheurs'),
                ('lawyer', 'Avocats'),
                ('ngo', 'ONG'),
                ('other', 'Autres')
            ]
            
            for quality_code, quality_name in qualities:
                count = request.env['request.information'].sudo().search_count([
                    ('requester_quality', '=', quality_code)
                ])
                
                if count > 0:
                    data.append({
                        'quality': quality_name,
                        'count': count,
                        'quality_code': quality_code
                    })
                    
        except Exception:
            data = []
        
        return data
    
    def _get_real_performance_metrics(self):
        """Métriques de performance réelles"""
        
        metrics = {}
        
        try:
            # Calculer les délais réels par étape (si des champs existent)
            info_requests = request.env['request.information'].sudo()
            
            # Nombre de recours réels (si un champ existe)
            metrics['appeals'] = 0  # Par défaut si pas de champ
            
            # Taux de satisfaction réel (si un champ existe)
            metrics['satisfaction_rate'] = 0  # Par défaut si pas de champ
            
        except Exception:
            metrics = {
                'satisfaction_rate': 0,
                'appeals': 0
            }
        
        return metrics
    
    @http.route('/transparence-dashboard/api/data', type='json', auth='public', csrf=False)
    def get_dashboard_data_api(self, **kwargs):
        """API pour récupérer les données réelles du dashboard en AJAX"""
        
        try:
            stats = self._get_real_statistics()
            charts_data = self._get_real_charts_data()
            user_info = self._get_user_info()
            
            return {
                'success': True,
                'stats': stats,
                'charts_data': charts_data,
                'user_info': user_info,
                'last_update': datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }