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
            stats['total_requests'] = info_requests.search_count([])\n            \n            # Demandes traitées (répondues ou refusées)\n            stats['processed_requests'] = info_requests.search_count([\n                ('state', 'in', ['responded', 'refused'])\n            ])\n            \n            # Demandes en cours\n            stats['pending_requests'] = info_requests.search_count([\n                ('state', 'in', ['submitted', 'in_progress', 'pending_validation'])\n            ])\n            \n            # Taux de traitement réel\n            if stats['total_requests'] > 0:\n                stats['processing_rate'] = round(\n                    (stats['processed_requests'] / stats['total_requests']) * 100, 1\n                )\n            else:\n                stats['processing_rate'] = 0\n            \n            # Délai moyen de traitement RÉEL\n            processed_requests = info_requests.search([\n                ('state', 'in', ['responded', 'refused']),\n                ('response_date', '!=', False),\n                ('request_date', '!=', False)\n            ])\n            \n            if processed_requests:\n                total_days = 0\n                count = 0\n                for req in processed_requests:\n                    try:\n                        request_date = fields.Date.from_string(req.request_date)\n                        response_date = fields.Date.from_string(req.response_date)\n                        delta = response_date - request_date\n                        total_days += delta.days\n                        count += 1\n                    except:\n                        continue\n                \n                stats['avg_processing_days'] = round(total_days / count, 1) if count > 0 else 0\n            else:\n                stats['avg_processing_days'] = 0\n            \n            # Taux de respect des délais RÉEL (30 jours)\n            on_time_requests = 0\n            if processed_requests:\n                for req in processed_requests:\n                    try:\n                        request_date = fields.Date.from_string(req.request_date)\n                        response_date = fields.Date.from_string(req.response_date)\n                        delta = response_date - request_date\n                        if delta.days <= 30:\n                            on_time_requests += 1\n                    except:\n                        continue\n                \n                stats['on_time_rate'] = round(\n                    (on_time_requests / len(processed_requests)) * 100, 1\n                ) if processed_requests else 0\n            else:\n                stats['on_time_rate'] = 0\n            \n            # Demandes récentes (30 derniers jours) - RÉEL\n            thirty_days_ago = (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d')\n            stats['recent_requests'] = info_requests.search_count([\n                ('request_date', '>=', thirty_days_ago)\n            ])\n            \n        except Exception as e:\n            # En cas d'erreur, valeurs nulles\n            stats.update({\n                'total_requests': 0,\n                'processed_requests': 0,\n                'pending_requests': 0,\n                'processing_rate': 0,\n                'avg_processing_days': 0,\n                'on_time_rate': 0,\n                'recent_requests': 0,\n            })\n        \n        try:\n            # Statistiques des signalements (données réelles)\n            alerts = request.env['whistleblowing.alert'].sudo()\n            \n            stats['total_alerts'] = alerts.search_count([])\n            stats['resolved_alerts'] = alerts.search_count([\n                ('state', 'in', ['resolved', 'closed'])\n            ])\n            stats['pending_alerts'] = alerts.search_count([\n                ('state', 'in', ['new', 'preliminary_assessment', 'investigation'])\n            ])\n            \n            if stats['total_alerts'] > 0:\n                stats['alert_resolution_rate'] = round(\n                    (stats['resolved_alerts'] / stats['total_alerts']) * 100, 1\n                )\n            else:\n                stats['alert_resolution_rate'] = 0\n                \n        except Exception:\n            stats.update({\n                'total_alerts': 0,\n                'resolved_alerts': 0,\n                'pending_alerts': 0,\n                'alert_resolution_rate': 0,\n            })\n        \n        return stats\n    \n    def _get_real_charts_data(self):\n        \"\"\"Prépare les données réelles pour les graphiques\"\"\"\n        \n        charts_data = {}\n        \n        try:\n            # Évolution mensuelle des demandes (données réelles)\n            monthly_data = self._get_real_monthly_requests_data()\n            charts_data['monthly_requests'] = monthly_data\n            \n            # Répartition par état des demandes (données réelles)\n            status_data = self._get_real_requests_by_status()\n            charts_data['requests_by_status'] = status_data\n            \n            # Évolution des signalements (données réelles)\n            alerts_monthly = self._get_real_monthly_alerts_data()\n            charts_data['monthly_alerts'] = alerts_monthly\n            \n        except Exception:\n            charts_data = {\n                'monthly_requests': [],\n                'requests_by_status': [],\n                'monthly_alerts': [],\n            }\n        \n        return charts_data\n    \n    def _get_real_monthly_requests_data(self):\n        \"\"\"Données mensuelles réelles des demandes (6 derniers mois)\"\"\"\n        \n        data = []\n        \n        try:\n            today = datetime.now().date()\n            for i in range(6):\n                # Calculer le mois\n                if today.month - i <= 0:\n                    month = today.month - i + 12\n                    year = today.year - 1\n                else:\n                    month = today.month - i\n                    year = today.year\n                \n                month_start = datetime(year, month, 1).date()\n                if month == 12:\n                    month_end = datetime(year + 1, 1, 1).date() - timedelta(days=1)\n                else:\n                    month_end = datetime(year, month + 1, 1).date() - timedelta(days=1)\n                \n                # Compter les demandes réelles du mois\n                count = request.env['request.information'].sudo().search_count([\n                    ('request_date', '>=', month_start.strftime('%Y-%m-%d')),\n                    ('request_date', '<=', month_end.strftime('%Y-%m-%d'))\n                ])\n                \n                data.append({\n                    'month': month_start.strftime('%Y-%m'),\n                    'month_name': month_start.strftime('%B %Y'),\n                    'count': count\n                })\n            \n            # Inverser pour avoir l'ordre chronologique\n            data.reverse()\n            \n        except Exception:\n            data = []\n        \n        return data\n    \n    def _get_real_requests_by_status(self):\n        \"\"\"Répartition réelle des demandes par état\"\"\"\n        \n        data = []\n        \n        try:\n            states = [\n                ('submitted', 'Soumises'),\n                ('in_progress', 'En traitement'),\n                ('pending_validation', 'En validation'),\n                ('responded', 'Répondues'),\n                ('refused', 'Refusées'),\n            ]\n            \n            for state_code, state_name in states:\n                count = request.env['request.information'].sudo().search_count([\n                    ('state', '=', state_code)\n                ])\n                \n                if count > 0:\n                    data.append({\n                        'status': state_name,\n                        'count': count,\n                        'state_code': state_code\n                    })\n                    \n        except Exception:\n            data = []\n        \n        return data\n    \n    def _get_real_monthly_alerts_data(self):\n        \"\"\"Données mensuelles réelles des signalements\"\"\"\n        \n        data = []\n        \n        try:\n            today = datetime.now().date()\n            for i in range(6):\n                # Calculer le mois\n                if today.month - i <= 0:\n                    month = today.month - i + 12\n                    year = today.year - 1\n                else:\n                    month = today.month - i\n                    year = today.year\n                \n                month_start = datetime(year, month, 1).date()\n                if month == 12:\n                    month_end = datetime(year + 1, 1, 1).date() - timedelta(days=1)\n                else:\n                    month_end = datetime(year, month + 1, 1).date() - timedelta(days=1)\n                \n                # Compter les signalements réels du mois\n                count = request.env['whistleblowing.alert'].sudo().search_count([\n                    ('alert_date', '>=', month_start.strftime('%Y-%m-%d')),\n                    ('alert_date', '<=', month_end.strftime('%Y-%m-%d'))\n                ])\n                \n                data.append({\n                    'month': month_start.strftime('%Y-%m'),\n                    'month_name': month_start.strftime('%B %Y'),\n                    'count': count\n                })\n            \n            # Inverser pour avoir l'ordre chronologique\n            data.reverse()\n            \n        except Exception:\n            data = []\n        \n        return data\n    \n    def _get_real_drill_down_data(self):\n        \"\"\"Données réelles pour le drill down\"\"\"\n        \n        drill_data = {}\n        \n        try:\n            # Données réelles par qualité de demandeur\n            drill_data['by_requester_quality'] = self._get_real_requests_by_quality()\n            \n            # Données réelles de performance\n            drill_data['performance_metrics'] = self._get_real_performance_metrics()\n            \n        except Exception:\n            drill_data = {\n                'by_requester_quality': [],\n                'performance_metrics': {}\n            }\n        \n        return drill_data\n    \n    def _get_real_requests_by_quality(self):\n        \"\"\"Répartition réelle des demandes par qualité de demandeur\"\"\"\n        \n        data = []\n        \n        try:\n            qualities = [\n                ('citizen', 'Citoyens'),\n                ('journalist', 'Journalistes'),\n                ('researcher', 'Chercheurs'),\n                ('lawyer', 'Avocats'),\n                ('ngo', 'ONG'),\n                ('other', 'Autres')\n            ]\n            \n            for quality_code, quality_name in qualities:\n                count = request.env['request.information'].sudo().search_count([\n                    ('requester_quality', '=', quality_code)\n                ])\n                \n                if count > 0:\n                    data.append({\n                        'quality': quality_name,\n                        'count': count,\n                        'quality_code': quality_code\n                    })\n                    \n        except Exception:\n            data = []\n        \n        return data\n    \n    def _get_real_performance_metrics(self):\n        \"\"\"Métriques de performance réelles\"\"\"\n        \n        metrics = {}\n        \n        try:\n            # Calculer les délais réels par étape (si des champs existent)\n            info_requests = request.env['request.information'].sudo()\n            \n            # Nombre de recours réels (si un champ existe)\n            # metrics['appeals'] = info_requests.search_count([('has_appeal', '=', True)])\n            metrics['appeals'] = 0  # Par défaut si pas de champ\n            \n            # Taux de satisfaction réel (si un champ existe)\n            # satisfaction_requests = info_requests.search([('satisfaction_rating', '!=', False)])\n            # if satisfaction_requests:\n            #     avg_satisfaction = sum(req.satisfaction_rating for req in satisfaction_requests) / len(satisfaction_requests)\n            #     metrics['satisfaction_rate'] = round(avg_satisfaction * 20, 1)  # Convertir en pourcentage\n            # else:\n            metrics['satisfaction_rate'] = 0  # Par défaut si pas de champ\n            \n        except Exception:\n            metrics = {\n                'satisfaction_rate': 0,\n                'appeals': 0\n            }\n        \n        return metrics\n    \n    @http.route('/transparence-dashboard/api/data', type='json', auth='public', csrf=False)\n    def get_dashboard_data_api(self, **kwargs):\n        \"\"\"API pour récupérer les données réelles du dashboard en AJAX\"\"\"\n        \n        try:\n            stats = self._get_real_statistics()\n            charts_data = self._get_real_charts_data()\n            user_info = self._get_user_info()\n            \n            return {\n                'success': True,\n                'stats': stats,\n                'charts_data': charts_data,\n                'user_info': user_info,\n                'last_update': datetime.now().isoformat()\n            }\n            \n        except Exception as e:\n            return {\n                'success': False,\n                'error': str(e)\n            }