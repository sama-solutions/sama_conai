# -*- coding: utf-8 -*-

from odoo import http, fields, _
from odoo.http import request
from datetime import datetime, timedelta
import json

class PublicDashboardController(http.Controller):
    """Contrôleur pour le tableau de bord public de transparence"""
    
    @http.route('/transparence-dashboard', type='http', auth='public', website=True, csrf=False)
    def transparency_dashboard(self, **kwargs):
        """Page principale du tableau de bord de transparence"""
        
        try:
            # Calculer les statistiques publiques
            stats = self._get_public_statistics()
            
            # Préparer les données pour les graphiques
            charts_data = self._get_charts_data()
            
            # Informations générales
            values = {
                'page_name': 'transparency_dashboard',
                'stats': stats,
                'charts_data': charts_data,
                'last_update': datetime.now(),
            }
            
            return request.render('sama_conai.transparency_dashboard_template', values)
            
        except Exception as e:
            # En cas d'erreur, afficher un dashboard minimal
            values = {
                'page_name': 'transparency_dashboard_error',
                'error_message': 'Erreur lors du chargement des données',
                'last_update': datetime.now(),
            }
            return request.render('sama_conai.transparency_dashboard_template', values)
    
    def _get_public_statistics(self):
        """Calcule les statistiques publiques anonymisées"""
        
        stats = {}
        
        try:
            # Statistiques des demandes d'information
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
            
            # Taux de traitement
            if stats['total_requests'] > 0:
                stats['processing_rate'] = round(
                    (stats['processed_requests'] / stats['total_requests']) * 100, 1
                )
            else:
                stats['processing_rate'] = 0
            
            # Délai moyen de traitement (pour les demandes traitées)
            processed_requests = info_requests.search([
                ('state', 'in', ['responded', 'refused']),
                ('response_date', '!=', False)
            ])
            
            if processed_requests:
                total_days = 0
                count = 0
                for req in processed_requests:
                    if req.request_date and req.response_date:
                        delta = fields.Date.from_string(req.response_date) - fields.Date.from_string(req.request_date)
                        total_days += delta.days
                        count += 1
                
                stats['avg_processing_days'] = round(total_days / count, 1) if count > 0 else 0
            else:
                stats['avg_processing_days'] = 0
            
            # Demandes dans les délais (30 jours)
            on_time_requests = info_requests.search_count([
                ('state', 'in', ['responded', 'refused']),
                ('response_date', '!=', False),
                ('response_date', '<=', 'deadline_date')
            ])
            
            if stats['processed_requests'] > 0:
                stats['on_time_rate'] = round(
                    (on_time_requests / stats['processed_requests']) * 100, 1
                )
            else:
                stats['on_time_rate'] = 0
            
        except Exception:
            # Valeurs par défaut en cas d'erreur
            stats.update({
                'total_requests': 0,
                'processed_requests': 0,
                'pending_requests': 0,
                'processing_rate': 0,
                'avg_processing_days': 0,
                'on_time_rate': 0,
            })
        
        try:
            # Statistiques des signalements (anonymisées)
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
    
    def _get_charts_data(self):
        """Prépare les données pour les graphiques"""
        
        charts_data = {}
        
        try:
            # Évolution mensuelle des demandes (12 derniers mois)
            monthly_data = self._get_monthly_requests_data()
            charts_data['monthly_requests'] = monthly_data
            
            # Répartition par état des demandes
            status_data = self._get_requests_by_status()
            charts_data['requests_by_status'] = status_data
            
            # Répartition par catégorie des signalements (anonymisée)
            category_data = self._get_alerts_by_category()
            charts_data['alerts_by_category'] = category_data
            
        except Exception:
            charts_data = {
                'monthly_requests': [],
                'requests_by_status': [],
                'alerts_by_category': [],
            }
        
        return charts_data
    
    def _get_monthly_requests_data(self):
        """Données mensuelles des demandes (12 derniers mois)"""
        
        data = []
        
        try:
            # Calculer les 12 derniers mois
            today = datetime.now().date()
            for i in range(12):
                # Calculer le mois
                month_date = today.replace(day=1) - timedelta(days=i*30)
                month_start = month_date.replace(day=1)
                
                if month_date.month == 12:
                    month_end = month_date.replace(year=month_date.year + 1, month=1, day=1) - timedelta(days=1)
                else:
                    month_end = month_date.replace(month=month_date.month + 1, day=1) - timedelta(days=1)
                
                # Compter les demandes du mois
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
    
    def _get_requests_by_status(self):
        """Répartition des demandes par état"""
        
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
                        'count': count
                    })
                    
        except Exception:
            data = []
        
        return data
    
    def _get_alerts_by_category(self):
        """Répartition anonymisée des signalements par catégorie"""
        
        data = []
        
        try:
            categories = [
                ('corruption', 'Corruption'),
                ('fraud', 'Fraude'),
                ('abuse_of_power', 'Abus de pouvoir'),
                ('discrimination', 'Discrimination'),
                ('harassment', 'Harcèlement'),
                ('other', 'Autres'),
            ]
            
            for cat_code, cat_name in categories:
                count = request.env['whistleblowing.alert'].sudo().search_count([
                    ('category', '=', cat_code)
                ])
                
                if count > 0:
                    data.append({
                        'category': cat_name,
                        'count': count
                    })
                    
        except Exception:
            data = []
        
        return data
    
    @http.route('/transparence-dashboard/api/stats', type='json', auth='public', csrf=False)
    def get_dashboard_stats_api(self, **kwargs):
        """API pour récupérer les statistiques en JSON (pour actualisation AJAX)"""
        
        try:
            stats = self._get_public_statistics()
            charts_data = self._get_charts_data()
            
            return {
                'success': True,
                'stats': stats,
                'charts_data': charts_data,
                'last_update': datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }