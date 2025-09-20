# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from odoo.exceptions import ValidationError
from datetime import timedelta
import json
import logging

_logger = logging.getLogger(__name__)


class ExecutiveDashboard(models.Model):
    _name = 'executive.dashboard'
    _description = 'Tableau de Bord Exécutif'
    _order = 'create_date desc'

    # Informations de base
    name = fields.Char(string='Nom du Tableau de Bord', required=True, default='Dashboard Exécutif')
    period_start = fields.Date(string='Début de Période', required=True, default=fields.Date.today)
    period_end = fields.Date(string='Fin de Période', required=True, 
                            default=lambda self: fields.Date.today() + timedelta(days=30))
    
    # KPI Accès à l'information
    total_requests_month = fields.Integer(string='Demandes du Mois', compute='_compute_requests_kpi', store=True)
    total_requests_year = fields.Integer(string='Demandes de l\'Année', compute='_compute_requests_kpi', store=True)
    response_rate = fields.Float(string='Taux de Réponse (%)', compute='_compute_response_rate', store=True)
    average_response_time = fields.Float(string='Temps Moyen de Réponse (jours)', 
                                        compute='_compute_avg_response_time', store=True)
    overdue_requests = fields.Integer(string='Demandes en Retard', compute='_compute_overdue', store=True)
    
    # KPI Lanceurs d'alerte
    total_alerts_month = fields.Integer(string='Alertes du Mois', compute='_compute_alerts_kpi', store=True)
    total_alerts_year = fields.Integer(string='Alertes de l\'Année', compute='_compute_alerts_kpi', store=True)
    critical_alerts = fields.Integer(string='Alertes Critiques', compute='_compute_critical_alerts', store=True)
    resolution_rate = fields.Float(string='Taux de Résolution (%)', compute='_compute_resolution_rate', store=True)
    
    # Tendances (JSON pour graphiques)
    requests_trend = fields.Text(string='Tendance Demandes', compute='_compute_requests_trend', store=True)
    alerts_trend = fields.Text(string='Tendance Alertes', compute='_compute_alerts_trend', store=True)
    
    # Alertes management
    management_alerts = fields.Html(string='Alertes Management', compute='_compute_management_alerts')
    
    # Données pour graphiques
    requests_by_category = fields.Text(string='Demandes par Catégorie', compute='_compute_category_data')
    alerts_by_priority = fields.Text(string='Alertes par Priorité', compute='_compute_priority_data')
    monthly_evolution = fields.Text(string='Évolution Mensuelle', compute='_compute_monthly_evolution')

    @api.depends('period_start', 'period_end')
    def _compute_requests_kpi(self):
        for record in self:
            # Demandes du mois
            month_start = fields.Date.today().replace(day=1)
            month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
            
            record.total_requests_month = self.env['request.information'].search_count([
                ('request_date', '>=', month_start),
                ('request_date', '<=', month_end)
            ])
            
            # Demandes de l'année
            year_start = fields.Date.today().replace(month=1, day=1)
            year_end = fields.Date.today().replace(month=12, day=31)
            
            record.total_requests_year = self.env['request.information'].search_count([
                ('request_date', '>=', year_start),
                ('request_date', '<=', year_end)
            ])

    @api.depends('period_start', 'period_end')
    def _compute_response_rate(self):
        for record in self:
            total_requests = self.env['request.information'].search_count([
                ('request_date', '>=', record.period_start),
                ('request_date', '<=', record.period_end)
            ])
            
            responded_requests = self.env['request.information'].search_count([
                ('request_date', '>=', record.period_start),
                ('request_date', '<=', record.period_end),
                ('state', 'in', ['responded', 'refused'])
            ])
            
            record.response_rate = (responded_requests / total_requests * 100) if total_requests > 0 else 0

    @api.depends('period_start', 'period_end')
    def _compute_avg_response_time(self):
        for record in self:
            requests = self.env['request.information'].search([
                ('request_date', '>=', record.period_start),
                ('request_date', '<=', record.period_end),
                ('response_date', '!=', False)
            ])
            
            if requests:
                total_days = sum([
                    (req.response_date.date() - req.request_date.date()).days 
                    for req in requests
                ])
                record.average_response_time = total_days / len(requests)
            else:
                record.average_response_time = 0

    @api.depends('period_start', 'period_end')
    def _compute_overdue(self):
        for record in self:
            today = fields.Date.today()
            record.overdue_requests = self.env['request.information'].search_count([
                ('deadline_date', '<', today),
                ('state', 'not in', ['responded', 'refused', 'cancelled'])
            ])

    @api.depends('period_start', 'period_end')
    def _compute_alerts_kpi(self):
        for record in self:
            # Alertes du mois
            month_start = fields.Date.today().replace(day=1)
            month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
            
            record.total_alerts_month = self.env['whistleblowing.alert'].search_count([
                ('alert_date', '>=', month_start),
                ('alert_date', '<=', month_end)
            ])
            
            # Alertes de l'année
            year_start = fields.Date.today().replace(month=1, day=1)
            year_end = fields.Date.today().replace(month=12, day=31)
            
            record.total_alerts_year = self.env['whistleblowing.alert'].search_count([
                ('alert_date', '>=', year_start),
                ('alert_date', '<=', year_end)
            ])

    @api.depends('period_start', 'period_end')
    def _compute_critical_alerts(self):
        for record in self:
            record.critical_alerts = self.env['whistleblowing.alert'].search_count([
                ('alert_date', '>=', record.period_start),
                ('alert_date', '<=', record.period_end),
                ('priority', 'in', ['high', 'urgent'])
            ])

    @api.depends('period_start', 'period_end')
    def _compute_resolution_rate(self):
        for record in self:
            total_alerts = self.env['whistleblowing.alert'].search_count([
                ('alert_date', '>=', record.period_start),
                ('alert_date', '<=', record.period_end)
            ])
            
            resolved_alerts = self.env['whistleblowing.alert'].search_count([
                ('alert_date', '>=', record.period_start),
                ('alert_date', '<=', record.period_end),
                ('state', 'in', ['resolved', 'closed'])
            ])
            
            record.resolution_rate = (resolved_alerts / total_alerts * 100) if total_alerts > 0 else 0

    @api.depends('period_start', 'period_end')
    def _compute_requests_trend(self):
        for record in self:
            # Calculer les données de tendance pour les 12 derniers mois
            trend_data = []
            for i in range(12):
                month_date = fields.Date.today() - timedelta(days=30*i)
                month_start = month_date.replace(day=1)
                month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
                
                count = self.env['request.information'].search_count([
                    ('request_date', '>=', month_start),
                    ('request_date', '<=', month_end)
                ])
                
                trend_data.append({
                    'month': month_date.strftime('%Y-%m'),
                    'count': count
                })
            
            record.requests_trend = json.dumps(trend_data)

    @api.depends('period_start', 'period_end')
    def _compute_alerts_trend(self):
        for record in self:
            # Calculer les données de tendance pour les 12 derniers mois
            trend_data = []
            for i in range(12):
                month_date = fields.Date.today() - timedelta(days=30*i)
                month_start = month_date.replace(day=1)
                month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
                
                count = self.env['whistleblowing.alert'].search_count([
                    ('alert_date', '>=', month_start),
                    ('alert_date', '<=', month_end)
                ])
                
                trend_data.append({
                    'month': month_date.strftime('%Y-%m'),
                    'count': count
                })
            
            record.alerts_trend = json.dumps(trend_data)

    def _compute_management_alerts(self):
        for record in self:
            alerts = []
            
            # Vérifier les demandes en retard
            if record.overdue_requests > 0:
                alerts.append(f"⚠️ {record.overdue_requests} demande(s) en retard")
            
            # Vérifier les alertes critiques
            if record.critical_alerts > 0:
                alerts.append(f"🚨 {record.critical_alerts} alerte(s) critique(s)")
            
            # Vérifier le taux de réponse
            if record.response_rate < 80:
                alerts.append(f"📉 Taux de réponse faible: {record.response_rate:.1f}%")
            
            # Vérifier le temps de réponse
            if record.average_response_time > 25:
                alerts.append(f"⏰ Temps de réponse élevé: {record.average_response_time:.1f} jours")
            
            if alerts:
                record.management_alerts = "<br/>".join(alerts)
            else:
                record.management_alerts = "✅ Tous les indicateurs sont au vert"

    def _compute_category_data(self):
        for record in self:
            # Données pour graphique par catégorie de demandeur
            categories = ['citizen', 'journalist', 'researcher', 'lawyer', 'ngo', 'other']
            data = []
            
            for category in categories:
                count = self.env['request.information'].search_count([
                    ('request_date', '>=', record.period_start),
                    ('request_date', '<=', record.period_end),
                    ('requester_quality', '=', category)
                ])
                data.append({'category': category, 'count': count})
            
            record.requests_by_category = json.dumps(data)

    def _compute_priority_data(self):
        for record in self:
            # Données pour graphique par priorité d'alerte
            priorities = ['low', 'medium', 'high', 'urgent']
            data = []
            
            for priority in priorities:
                count = self.env['whistleblowing.alert'].search_count([
                    ('alert_date', '>=', record.period_start),
                    ('alert_date', '<=', record.period_end),
                    ('priority', '=', priority)
                ])
                data.append({'priority': priority, 'count': count})
            
            record.alerts_by_priority = json.dumps(data)

    def _compute_monthly_evolution(self):
        for record in self:
            # Évolution mensuelle combinée
            evolution_data = []
            for i in range(6):  # 6 derniers mois
                month_date = fields.Date.today() - timedelta(days=30*i)
                month_start = month_date.replace(day=1)
                month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
                
                requests_count = self.env['request.information'].search_count([
                    ('request_date', '>=', month_start),
                    ('request_date', '<=', month_end)
                ])
                
                alerts_count = self.env['whistleblowing.alert'].search_count([
                    ('alert_date', '>=', month_start),
                    ('alert_date', '<=', month_end)
                ])
                
                evolution_data.append({
                    'month': month_date.strftime('%Y-%m'),
                    'requests': requests_count,
                    'alerts': alerts_count
                })
            
            record.monthly_evolution = json.dumps(evolution_data)

    @api.model
    def get_current_dashboard(self):
        """Récupérer le dashboard actuel ou en créer un"""
        dashboard = self.search([], limit=1, order='create_date desc')
        if not dashboard:
            dashboard = self.create({
                'name': 'Dashboard Exécutif - ' + fields.Date.today().strftime('%B %Y'),
                'period_start': fields.Date.today().replace(day=1),
                'period_end': fields.Date.today()
            })
        return dashboard

    def action_refresh_data(self):
        """Actualiser toutes les données du dashboard"""
        self.ensure_one()
        # Forcer le recalcul de tous les champs calculés
        self._compute_requests_kpi()
        self._compute_response_rate()
        self._compute_avg_response_time()
        self._compute_overdue()
        self._compute_alerts_kpi()
        self._compute_critical_alerts()
        self._compute_resolution_rate()
        self._compute_requests_trend()
        self._compute_alerts_trend()
        self._compute_management_alerts()
        self._compute_category_data()
        self._compute_priority_data()
        self._compute_monthly_evolution()
        
        return {
            'type': 'ir.actions.client',
            'tag': 'display_notification',
            'params': {
                'title': _('Dashboard Actualisé'),
                'message': _('Toutes les données ont été mises à jour.'),
                'type': 'success',
            }
        }

    def action_export_report(self):
        """Exporter le rapport du dashboard"""
        self.ensure_one()
        return {
            'type': 'ir.actions.report',
            'report_name': 'sama_conai.executive_dashboard_report',
            'report_type': 'qweb-pdf',
            'data': {'dashboard_id': self.id},
            'context': self.env.context,
        }