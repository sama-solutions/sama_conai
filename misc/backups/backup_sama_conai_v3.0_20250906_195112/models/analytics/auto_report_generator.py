# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from odoo.exceptions import ValidationError
from datetime import timedelta
import json
import logging

_logger = logging.getLogger(__name__)


class AutoReportGenerator(models.Model):
    _name = 'auto.report.generator'
    _description = 'Générateur de Rapports Automatique'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'create_date desc'

    # Configuration de base
    name = fields.Char(string='Nom du Rapport', required=True, tracking=True)
    active = fields.Boolean(string='Actif', default=True, tracking=True)
    
    # Type de rapport
    report_type = fields.Selection([
        ('monthly', 'Rapport Mensuel'),
        ('quarterly', 'Rapport Trimestriel'),
        ('annual', 'Rapport Annuel'),
        ('thematic', 'Rapport Thématique'),
        ('compliance', 'Rapport de Conformité'),
        ('performance', 'Rapport de Performance')
    ], string='Type de Rapport', required=True, tracking=True)
    
    # Contenu du rapport
    include_statistics = fields.Boolean(string='Inclure les Statistiques', default=True)
    include_trends = fields.Boolean(string='Inclure les Tendances', default=True)
    include_recommendations = fields.Boolean(string='Inclure les Recommandations', default=True)
    include_charts = fields.Boolean(string='Inclure les Graphiques', default=True)
    anonymize_data = fields.Boolean(string='Anonymiser les Données', default=True)
    
    # Filtres de données
    date_from = fields.Date(string='Date de Début')
    date_to = fields.Date(string='Date de Fin')
    department_ids = fields.Many2many('hr.department', string='Départements')
    request_types = fields.Selection([
        ('all', 'Toutes les Demandes'),
        ('information', 'Demandes d\'Information Seulement'),
        ('alerts', 'Alertes Seulement')
    ], string='Types de Demandes', default='all')
    
    # Distribution
    recipients = fields.Many2many('res.users', string='Destinataires', 
                                 domain=[('share', '=', False)])
    external_emails = fields.Text(string='Emails Externes', 
                                 help='Emails séparés par des virgules')
    
    # Automatisation
    auto_send = fields.Boolean(string='Envoi Automatique', default=True, tracking=True)
    send_frequency = fields.Selection([
        ('weekly', 'Hebdomadaire'),
        ('monthly', 'Mensuel'),
        ('quarterly', 'Trimestriel'),
        ('annual', 'Annuel')
    ], string='Fréquence d\'Envoi', tracking=True)
    
    next_send_date = fields.Datetime(string='Prochaine Génération', 
                                    compute='_compute_next_send_date', store=True)
    last_generated = fields.Datetime(string='Dernière Génération', readonly=True)
    
    # Historique
    generated_reports = fields.One2many('auto.report.instance', 'generator_id', 
                                       string='Rapports Générés')
    generation_count = fields.Integer(string='Nombre de Générations', 
                                     compute='_compute_generation_count')
    
    # Configuration avancée
    template_id = fields.Many2one('mail.template', string='Modèle d\'Email')
    report_format = fields.Selection([
        ('pdf', 'PDF'),
        ('html', 'HTML'),
        ('excel', 'Excel')
    ], string='Format de Rapport', default='pdf')
    
    # Données calculées
    preview_data = fields.Text(string='Aperçu des Données', compute='_compute_preview_data')

    @api.depends('send_frequency', 'last_generated')
    def _compute_next_send_date(self):
        for record in self:
            if not record.send_frequency or not record.auto_send:
                record.next_send_date = False
                continue
                
            base_date = record.last_generated or fields.Datetime.now()
            
            if record.send_frequency == 'weekly':
                record.next_send_date = base_date + timedelta(weeks=1)
            elif record.send_frequency == 'monthly':
                record.next_send_date = base_date + timedelta(days=30)
            elif record.send_frequency == 'quarterly':
                record.next_send_date = base_date + timedelta(days=90)
            elif record.send_frequency == 'annual':
                record.next_send_date = base_date + timedelta(days=365)

    @api.depends('generated_reports')
    def _compute_generation_count(self):
        for record in self:
            record.generation_count = len(record.generated_reports)

    def _compute_preview_data(self):
        for record in self:
            try:
                data = record._collect_report_data()
                preview = {
                    'total_requests': data.get('total_requests', 0),
                    'total_alerts': data.get('total_alerts', 0),
                    'response_rate': data.get('response_rate', 0),
                    'period': f"{record.date_from or 'N/A'} - {record.date_to or 'N/A'}"
                }
                record.preview_data = json.dumps(preview, indent=2)
            except Exception as e:
                record.preview_data = f"Erreur lors du calcul: {str(e)}"

    @api.constrains('date_from', 'date_to')
    def _check_dates(self):
        for record in self:
            if record.date_from and record.date_to and record.date_from > record.date_to:
                raise ValidationError(_('La date de début ne peut pas être postérieure à la date de fin.'))

    @api.constrains('external_emails')
    def _check_external_emails(self):
        for record in self:
            if record.external_emails:
                emails = [email.strip() for email in record.external_emails.split(',')]
                for email in emails:
                    if email and '@' not in email:
                        raise ValidationError(_('Format d\'email invalide: %s') % email)

    def _collect_report_data(self):
        """Collecter les données pour le rapport"""
        self.ensure_one()
        
        # Définir la période
        if not self.date_from or not self.date_to:
            if self.report_type == 'monthly':
                date_to = fields.Date.today()
                date_from = date_to.replace(day=1)
            elif self.report_type == 'quarterly':
                date_to = fields.Date.today()
                date_from = date_to - timedelta(days=90)
            elif self.report_type == 'annual':
                date_to = fields.Date.today()
                date_from = date_to.replace(month=1, day=1)
            else:
                date_to = fields.Date.today()
                date_from = date_to - timedelta(days=30)
        else:
            date_from = self.date_from
            date_to = self.date_to

        data = {
            'period_start': date_from,
            'period_end': date_to,
            'report_type': self.report_type,
            'generated_date': fields.Datetime.now(),
        }

        # Collecter les données des demandes d'information
        if self.request_types in ['all', 'information']:
            requests_domain = [
                ('request_date', '>=', date_from),
                ('request_date', '<=', date_to)
            ]
            
            if self.department_ids:
                requests_domain.append(('department_id', 'in', self.department_ids.ids))

            requests = self.env['request.information'].search(requests_domain)
            
            data.update({
                'total_requests': len(requests),
                'requests_by_state': self._group_by_field(requests, 'state'),
                'requests_by_quality': self._group_by_field(requests, 'requester_quality'),
                'response_rate': self._calculate_response_rate(requests),
                'average_response_time': self._calculate_avg_response_time(requests),
                'overdue_requests': len(requests.filtered(lambda r: r.is_overdue)),
            })

        # Collecter les données des alertes
        if self.request_types in ['all', 'alerts']:
            alerts_domain = [
                ('alert_date', '>=', date_from),
                ('alert_date', '<=', date_to)
            ]

            alerts = self.env['whistleblowing.alert'].search(alerts_domain)
            
            data.update({
                'total_alerts': len(alerts),
                'alerts_by_state': self._group_by_field(alerts, 'state'),
                'alerts_by_category': self._group_by_field(alerts, 'category'),
                'alerts_by_priority': self._group_by_field(alerts, 'priority'),
                'resolution_rate': self._calculate_resolution_rate(alerts),
                'critical_alerts': len(alerts.filtered(lambda a: a.priority in ['high', 'urgent'])),
            })

        # Ajouter les tendances si demandées
        if self.include_trends:
            data['trends'] = self._calculate_trends(date_from, date_to)

        # Ajouter les recommandations si demandées
        if self.include_recommendations:
            data['recommendations'] = self._generate_recommendations(data)

        return data

    def _group_by_field(self, records, field_name):
        """Grouper les enregistrements par champ"""
        groups = {}
        for record in records:
            value = getattr(record, field_name)
            if hasattr(value, 'name'):  # Many2one field
                value = value.name
            groups[value] = groups.get(value, 0) + 1
        return groups

    def _calculate_response_rate(self, requests):
        """Calculer le taux de réponse"""
        if not requests:
            return 0
        responded = requests.filtered(lambda r: r.state in ['responded', 'refused'])
        return (len(responded) / len(requests)) * 100

    def _calculate_avg_response_time(self, requests):
        """Calculer le temps moyen de réponse"""
        responded_requests = requests.filtered(lambda r: r.response_date)
        if not responded_requests:
            return 0
        
        total_days = sum([
            (req.response_date.date() - req.request_date.date()).days 
            for req in responded_requests
        ])
        return total_days / len(responded_requests)

    def _calculate_resolution_rate(self, alerts):
        """Calculer le taux de résolution des alertes"""
        if not alerts:
            return 0
        resolved = alerts.filtered(lambda a: a.state in ['resolved', 'closed'])
        return (len(resolved) / len(alerts)) * 100

    def _calculate_trends(self, date_from, date_to):
        """Calculer les tendances"""
        trends = {}
        
        # Tendance des demandes par mois
        months_data = []
        current_date = date_from
        while current_date <= date_to:
            month_start = current_date.replace(day=1)
            month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
            
            requests_count = self.env['request.information'].search_count([
                ('request_date', '>=', month_start),
                ('request_date', '<=', min(month_end, date_to))
            ])
            
            alerts_count = self.env['whistleblowing.alert'].search_count([
                ('alert_date', '>=', month_start),
                ('alert_date', '<=', min(month_end, date_to))
            ])
            
            months_data.append({
                'month': current_date.strftime('%Y-%m'),
                'requests': requests_count,
                'alerts': alerts_count
            })
            
            current_date = (month_start + timedelta(days=32)).replace(day=1)
        
        trends['monthly_evolution'] = months_data
        return trends

    def _generate_recommendations(self, data):
        """Générer des recommandations basées sur les données"""
        recommendations = []
        
        # Recommandations basées sur le taux de réponse
        response_rate = data.get('response_rate', 0)
        if response_rate < 80:
            recommendations.append({
                'type': 'warning',
                'title': 'Taux de réponse faible',
                'description': f'Le taux de réponse de {response_rate:.1f}% est en dessous du seuil recommandé de 80%.',
                'action': 'Renforcer les équipes de traitement et améliorer les processus.'
            })

        # Recommandations basées sur les demandes en retard
        overdue = data.get('overdue_requests', 0)
        if overdue > 0:
            recommendations.append({
                'type': 'urgent',
                'title': 'Demandes en retard',
                'description': f'{overdue} demande(s) dépassent les délais légaux.',
                'action': 'Traiter en priorité les demandes en retard et analyser les causes des retards.'
            })

        # Recommandations basées sur les alertes critiques
        critical_alerts = data.get('critical_alerts', 0)
        if critical_alerts > 0:
            recommendations.append({
                'type': 'critical',
                'title': 'Alertes critiques',
                'description': f'{critical_alerts} alerte(s) critique(s) nécessitent une attention immédiate.',
                'action': 'Mobiliser les ressources nécessaires pour traiter les alertes critiques.'
            })

        return recommendations

    def generate_report(self):
        """Générer le rapport"""
        self.ensure_one()
        
        try:
            # Collecter les données
            data = self._collect_report_data()
            
            # Créer l'instance de rapport
            report_instance = self.env['auto.report.instance'].create({
                'generator_id': self.id,
                'name': f"{self.name} - {fields.Datetime.now().strftime('%d/%m/%Y %H:%M')}",
                'report_data': json.dumps(data, default=str),
                'status': 'generated'
            })
            
            # Mettre à jour la date de dernière génération
            self.last_generated = fields.Datetime.now()
            
            # Envoyer le rapport si configuré
            if self.auto_send:
                report_instance.send_report()
            
            return {
                'type': 'ir.actions.act_window',
                'name': _('Rapport Généré'),
                'res_model': 'auto.report.instance',
                'res_id': report_instance.id,
                'view_mode': 'form',
                'target': 'current',
            }
            
        except Exception as e:
            _logger.error(f"Erreur lors de la génération du rapport {self.name}: {str(e)}")
            raise ValidationError(_('Erreur lors de la génération du rapport: %s') % str(e))

    def action_test_generation(self):
        """Tester la génération du rapport"""
        self.ensure_one()
        return self.generate_report()

    @api.model
    def cron_generate_reports(self):
        """Cron pour générer automatiquement les rapports"""
        generators = self.search([
            ('active', '=', True),
            ('auto_send', '=', True),
            ('next_send_date', '<=', fields.Datetime.now())
        ])
        
        for generator in generators:
            try:
                generator.generate_report()
                _logger.info(f"Rapport automatique généré: {generator.name}")
            except Exception as e:
                _logger.error(f"Erreur génération automatique {generator.name}: {str(e)}")


class AutoReportInstance(models.Model):
    _name = 'auto.report.instance'
    _description = 'Instance de Rapport Automatique'
    _order = 'create_date desc'

    name = fields.Char(string='Nom', required=True)
    generator_id = fields.Many2one('auto.report.generator', string='Générateur', required=True)
    report_data = fields.Text(string='Données du Rapport')
    status = fields.Selection([
        ('generated', 'Généré'),
        ('sent', 'Envoyé'),
        ('error', 'Erreur')
    ], string='Statut', default='generated')
    
    generated_date = fields.Datetime(string='Date de Génération', default=fields.Datetime.now)
    sent_date = fields.Datetime(string='Date d\'Envoi')
    error_message = fields.Text(string='Message d\'Erreur')
    
    attachment_ids = fields.Many2many('ir.attachment', string='Pièces Jointes')

    def send_report(self):
        """Envoyer le rapport"""
        self.ensure_one()
        
        try:
            # Générer le fichier PDF/HTML selon la configuration
            report_data = json.loads(self.report_data)
            
            # Créer le contenu du rapport
            report_content = self._generate_report_content(report_data)
            
            # Créer la pièce jointe
            attachment = self.env['ir.attachment'].create({
                'name': f"{self.name}.{self.generator_id.report_format}",
                'type': 'binary',
                'datas': report_content,
                'res_model': self._name,
                'res_id': self.id,
            })
            
            self.attachment_ids = [(4, attachment.id)]
            
            # Envoyer par email
            self._send_email(attachment)
            
            self.status = 'sent'
            self.sent_date = fields.Datetime.now()
            
        except Exception as e:
            self.status = 'error'
            self.error_message = str(e)
            _logger.error(f"Erreur envoi rapport {self.name}: {str(e)}")

    def _generate_report_content(self, data):
        """Générer le contenu du rapport"""
        # Ici on pourrait utiliser un template plus sophistiqué
        # Pour l'instant, on génère un contenu HTML simple
        html_content = f"""
        <html>
        <head>
            <title>{self.name}</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                .header {{ background-color: #f0f0f0; padding: 20px; text-align: center; }}
                .section {{ margin: 20px 0; }}
                .kpi {{ display: inline-block; margin: 10px; padding: 15px; border: 1px solid #ddd; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>{self.name}</h1>
                <p>Période: {data.get('period_start')} - {data.get('period_end')}</p>
            </div>
            
            <div class="section">
                <h2>Indicateurs Clés</h2>
                <div class="kpi">
                    <h3>Demandes d'Information</h3>
                    <p>Total: {data.get('total_requests', 0)}</p>
                    <p>Taux de réponse: {data.get('response_rate', 0):.1f}%</p>
                </div>
                <div class="kpi">
                    <h3>Alertes</h3>
                    <p>Total: {data.get('total_alerts', 0)}</p>
                    <p>Critiques: {data.get('critical_alerts', 0)}</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        import base64
        return base64.b64encode(html_content.encode('utf-8'))

    def _send_email(self, attachment):
        """Envoyer l'email avec le rapport"""
        # Préparer les destinataires
        recipients = self.generator_id.recipients
        external_emails = []
        
        if self.generator_id.external_emails:
            external_emails = [email.strip() for email in self.generator_id.external_emails.split(',')]
        
        # Envoyer l'email
        mail_values = {
            'subject': f"Rapport Automatique: {self.name}",
            'body_html': f"""
                <p>Bonjour,</p>
                <p>Veuillez trouver en pièce jointe le rapport automatique: <strong>{self.name}</strong></p>
                <p>Ce rapport a été généré automatiquement le {self.generated_date.strftime('%d/%m/%Y à %H:%M')}.</p>
                <p>Cordialement,<br/>Système SAMA CONAI</p>
            """,
            'attachment_ids': [(4, attachment.id)],
        }
        
        # Envoyer aux utilisateurs internes
        for recipient in recipients:
            mail_values.update({
                'email_to': recipient.email,
                'recipient_ids': [(4, recipient.partner_id.id)],
            })
            self.env['mail.mail'].create(mail_values).send()
        
        # Envoyer aux emails externes
        for email in external_emails:
            if email:
                mail_values.update({
                    'email_to': email,
                    'recipient_ids': False,
                })
                self.env['mail.mail'].create(mail_values).send()