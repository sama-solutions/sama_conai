# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from datetime import timedelta
import json
import statistics
import logging

_logger = logging.getLogger(__name__)


class PredictiveAnalytics(models.AbstractModel):
    _name = 'predictive.analytics'
    _description = 'Service d\'Analytics Prédictifs'

    @api.model
    def predict_request_volume(self, period_ahead=30):
        """Prédiction du volume de demandes pour les prochains jours"""
        try:
            # Récupérer les données historiques (6 derniers mois)
            historical_data = self._get_historical_request_data(180)
            
            if not historical_data:
                return {
                    'predicted_volume': 0,
                    'confidence_interval': [0, 0],
                    'peak_periods': [],
                    'recommendations': ['Pas assez de données historiques pour une prédiction fiable']
                }
            
            # Calculer la tendance
            trend = self._calculate_trend(historical_data)
            
            # Détecter la saisonnalité
            seasonality = self._detect_seasonality(historical_data)
            
            # Prédiction simple basée sur la moyenne mobile et la tendance
            recent_average = statistics.mean([d['count'] for d in historical_data[-30:]])
            predicted_volume = max(0, int(recent_average + (trend * period_ahead / 30)))
            
            # Intervalle de confiance basé sur l'écart-type
            std_dev = statistics.stdev([d['count'] for d in historical_data]) if len(historical_data) > 1 else 0
            confidence_interval = [
                max(0, predicted_volume - int(1.96 * std_dev)),
                predicted_volume + int(1.96 * std_dev)
            ]
            
            # Identifier les périodes de pic
            peak_periods = self._identify_peak_periods(historical_data, seasonality)
            
            # Générer des recommandations
            recommendations = self._generate_volume_recommendations(
                predicted_volume, recent_average, trend, peak_periods
            )
            
            return {
                'predicted_volume': predicted_volume,
                'confidence_interval': confidence_interval,
                'peak_periods': peak_periods,
                'trend': trend,
                'seasonality': seasonality,
                'recommendations': recommendations
            }
            
        except Exception as e:
            _logger.error(f"Erreur dans predict_request_volume: {str(e)}")
            return {
                'predicted_volume': 0,
                'confidence_interval': [0, 0],
                'peak_periods': [],
                'recommendations': [f'Erreur de prédiction: {str(e)}']
            }

    @api.model
    def detect_anomalies(self):
        """Détection d'anomalies dans les patterns de demandes et alertes"""
        try:
            anomalies = []
            
            # Analyser les demandes d'information
            request_anomalies = self._detect_request_anomalies()
            anomalies.extend(request_anomalies)
            
            # Analyser les alertes
            alert_anomalies = self._detect_alert_anomalies()
            anomalies.extend(alert_anomalies)
            
            # Analyser les patterns temporels
            temporal_anomalies = self._detect_temporal_anomalies()
            anomalies.extend(temporal_anomalies)
            
            return {
                'anomalies': anomalies,
                'total_anomalies': len(anomalies),
                'severity_distribution': self._categorize_anomalies(anomalies)
            }
            
        except Exception as e:
            _logger.error(f"Erreur dans detect_anomalies: {str(e)}")
            return {
                'anomalies': [],
                'total_anomalies': 0,
                'severity_distribution': {}
            }

    @api.model
    def risk_assessment(self):
        """Évaluation des risques futurs"""
        try:
            risks = []
            
            # Risque de surcharge
            overload_risk = self._assess_overload_risk()
            if overload_risk['level'] > 0:
                risks.append(overload_risk)
            
            # Risque de non-conformité aux délais
            compliance_risk = self._assess_compliance_risk()
            if compliance_risk['level'] > 0:
                risks.append(compliance_risk)
            
            # Risque de sécurité
            security_risk = self._assess_security_risk()
            if security_risk['level'] > 0:
                risks.append(security_risk)
            
            # Risque de qualité de service
            quality_risk = self._assess_quality_risk()
            if quality_risk['level'] > 0:
                risks.append(quality_risk)
            
            # Calculer le score de risque global
            global_risk_score = self._calculate_global_risk(risks)
            
            return {
                'risks': risks,
                'global_risk_score': global_risk_score,
                'recommendations': self._generate_risk_recommendations(risks),
                'mitigation_strategies': self._suggest_mitigation_strategies(risks)
            }
            
        except Exception as e:
            _logger.error(f"Erreur dans risk_assessment: {str(e)}")
            return {
                'risks': [],
                'global_risk_score': 0,
                'recommendations': [],
                'mitigation_strategies': []
            }

    def _get_historical_request_data(self, days_back):
        """Récupérer les données historiques des demandes"""
        end_date = fields.Date.today()
        start_date = end_date - timedelta(days=days_back)
        
        data = []
        current_date = start_date
        
        while current_date <= end_date:
            count = self.env['request.information'].search_count([
                ('request_date', '>=', current_date),
                ('request_date', '<', current_date + timedelta(days=1))
            ])
            
            data.append({
                'date': current_date.strftime('%Y-%m-%d'),
                'count': count,
                'day_of_week': current_date.weekday(),
                'day_of_month': current_date.day,
                'month': current_date.month
            })
            
            current_date += timedelta(days=1)
        
        return data

    def _calculate_trend(self, data):
        """Calculer la tendance linéaire"""
        if len(data) < 2:
            return 0
        
        # Régression linéaire simple
        n = len(data)
        x_values = list(range(n))
        y_values = [d['count'] for d in data]
        
        x_mean = statistics.mean(x_values)
        y_mean = statistics.mean(y_values)
        
        numerator = sum((x_values[i] - x_mean) * (y_values[i] - y_mean) for i in range(n))
        denominator = sum((x_values[i] - x_mean) ** 2 for i in range(n))
        
        if denominator == 0:
            return 0
        
        return numerator / denominator

    def _detect_seasonality(self, data):
        """Détecter les patterns saisonniers"""
        seasonality = {
            'weekly': {},
            'monthly': {},
            'has_weekly_pattern': False,
            'has_monthly_pattern': False
        }
        
        # Pattern hebdomadaire
        weekly_counts = {}
        for d in data:
            day = d['day_of_week']
            if day not in weekly_counts:
                weekly_counts[day] = []
            weekly_counts[day].append(d['count'])
        
        for day, counts in weekly_counts.items():
            seasonality['weekly'][day] = statistics.mean(counts) if counts else 0
        
        # Vérifier s'il y a un pattern hebdomadaire significatif
        weekly_values = list(seasonality['weekly'].values())
        if weekly_values:
            weekly_std = statistics.stdev(weekly_values) if len(weekly_values) > 1 else 0
            weekly_mean = statistics.mean(weekly_values)
            seasonality['has_weekly_pattern'] = weekly_std > (weekly_mean * 0.2)
        
        # Pattern mensuel
        monthly_counts = {}
        for d in data:
            month = d['month']
            if month not in monthly_counts:
                monthly_counts[month] = []
            monthly_counts[month].append(d['count'])
        
        for month, counts in monthly_counts.items():
            seasonality['monthly'][month] = statistics.mean(counts) if counts else 0
        
        # Vérifier s'il y a un pattern mensuel significatif
        monthly_values = list(seasonality['monthly'].values())
        if monthly_values:
            monthly_std = statistics.stdev(monthly_values) if len(monthly_values) > 1 else 0
            monthly_mean = statistics.mean(monthly_values)
            seasonality['has_monthly_pattern'] = monthly_std > (monthly_mean * 0.2)
        
        return seasonality

    def _identify_peak_periods(self, data, seasonality):
        """Identifier les périodes de pic"""
        peaks = []
        
        if seasonality['has_weekly_pattern']:
            # Trouver les jours de la semaine avec le plus de demandes
            weekly_data = seasonality['weekly']
            max_day = max(weekly_data, key=weekly_data.get)
            peaks.append({
                'type': 'weekly',
                'period': f"Jour {max_day} de la semaine",
                'average_volume': weekly_data[max_day]
            })
        
        if seasonality['has_monthly_pattern']:
            # Trouver les mois avec le plus de demandes
            monthly_data = seasonality['monthly']
            max_month = max(monthly_data, key=monthly_data.get)
            month_names = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                          'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc']
            peaks.append({
                'type': 'monthly',
                'period': month_names[max_month - 1],
                'average_volume': monthly_data[max_month]
            })
        
        return peaks

    def _generate_volume_recommendations(self, predicted_volume, recent_average, trend, peak_periods):
        """Générer des recommandations basées sur la prédiction de volume"""
        recommendations = []
        
        # Recommandations basées sur la tendance
        if trend > 0.5:
            recommendations.append(
                "Tendance croissante détectée. Prévoir une augmentation des ressources."
            )
        elif trend < -0.5:
            recommendations.append(
                "Tendance décroissante détectée. Opportunité d'optimisation des ressources."
            )
        
        # Recommandations basées sur le volume prédit
        if predicted_volume > recent_average * 1.5:
            recommendations.append(
                f"Volume élevé prévu ({predicted_volume}). Renforcer les équipes de traitement."
            )
        elif predicted_volume < recent_average * 0.5:
            recommendations.append(
                f"Volume faible prévu ({predicted_volume}). Période propice à la formation et maintenance."
            )
        
        # Recommandations basées sur les pics
        for peak in peak_periods:
            recommendations.append(
                f"Pic prévu en {peak['period']}. Planifier les ressources en conséquence."
            )
        
        return recommendations

    def _detect_request_anomalies(self):
        """Détecter les anomalies dans les demandes d'information"""
        anomalies = []
        
        # Analyser les 30 derniers jours
        end_date = fields.Date.today()
        start_date = end_date - timedelta(days=30)
        
        # Anomalie: Pic soudain de demandes
        daily_counts = []
        current_date = start_date
        while current_date <= end_date:
            count = self.env['request.information'].search_count([
                ('request_date', '>=', current_date),
                ('request_date', '<', current_date + timedelta(days=1))
            ])
            daily_counts.append(count)
            current_date += timedelta(days=1)
        
        if daily_counts:
            mean_count = statistics.mean(daily_counts)
            std_count = statistics.stdev(daily_counts) if len(daily_counts) > 1 else 0
            
            for i, count in enumerate(daily_counts):
                if count > mean_count + (2 * std_count):
                    anomalies.append({
                        'type': 'volume_spike',
                        'severity': 'medium',
                        'description': f'Pic de demandes détecté: {count} demandes',
                        'date': (start_date + timedelta(days=i)).strftime('%Y-%m-%d'),
                        'recommendation': 'Analyser les causes du pic et ajuster les ressources'
                    })
        
        # Anomalie: Demandes répétitives du même demandeur
        frequent_requesters = self.env['request.information'].read_group(
            [('request_date', '>=', start_date)],
            ['partner_email'],
            ['partner_email'],
            having=[('__count', '>', 5)]
        )
        
        for requester in frequent_requesters:
            anomalies.append({
                'type': 'frequent_requester',
                'severity': 'low',
                'description': f'Demandeur fréquent: {requester["partner_email"]} ({requester["partner_email_count"]} demandes)',
                'recommendation': 'Vérifier la légitimité des demandes multiples'
            })
        
        return anomalies

    def _detect_alert_anomalies(self):
        """Détecter les anomalies dans les alertes"""
        anomalies = []
        
        # Analyser les 30 derniers jours
        end_date = fields.Date.today()
        start_date = end_date - timedelta(days=30)
        
        # Anomalie: Augmentation soudaine d'alertes critiques
        critical_alerts = self.env['whistleblowing.alert'].search_count([
            ('alert_date', '>=', start_date),
            ('priority', 'in', ['high', 'urgent'])
        ])
        
        # Comparer avec la période précédente
        prev_start = start_date - timedelta(days=30)
        prev_critical = self.env['whistleblowing.alert'].search_count([
            ('alert_date', '>=', prev_start),
            ('alert_date', '<', start_date),
            ('priority', 'in', ['high', 'urgent'])
        ])
        
        if critical_alerts > prev_critical * 2:
            anomalies.append({
                'type': 'critical_alerts_spike',
                'severity': 'high',
                'description': f'Augmentation significative d\'alertes critiques: {critical_alerts} vs {prev_critical}',
                'recommendation': 'Investigation immédiate des causes de l\'augmentation'
            })
        
        # Anomalie: Catégorie d'alerte inhabituelle
        category_counts = self.env['whistleblowing.alert'].read_group(
            [('alert_date', '>=', start_date)],
            ['category'],
            ['category']
        )
        
        for category in category_counts:
            if category['category_count'] > 10:  # Seuil arbitraire
                anomalies.append({
                    'type': 'category_concentration',
                    'severity': 'medium',
                    'description': f'Concentration d\'alertes dans la catégorie {category["category"]}: {category["category_count"]}',
                    'recommendation': 'Analyser les causes de cette concentration'
                })
        
        return anomalies

    def _detect_temporal_anomalies(self):
        """Détecter les anomalies temporelles"""
        anomalies = []
        
        # Analyser les patterns horaires inhabituels
        # (Demandes en dehors des heures ouvrables)
        night_requests = self.env['request.information'].search_count([
            ('request_date', '>=', fields.Date.today() - timedelta(days=7)),
            ('request_date', '<=', fields.Date.today())
        ])
        
        # Cette analyse nécessiterait des données plus détaillées sur les heures
        # Pour l'instant, on se contente d'une vérification basique
        
        return anomalies

    def _categorize_anomalies(self, anomalies):
        """Catégoriser les anomalies par sévérité"""
        distribution = {'low': 0, 'medium': 0, 'high': 0, 'critical': 0}
        
        for anomaly in anomalies:
            severity = anomaly.get('severity', 'low')
            distribution[severity] = distribution.get(severity, 0) + 1
        
        return distribution

    def _assess_overload_risk(self):
        """Évaluer le risque de surcharge"""
        # Calculer le volume actuel vs capacité
        current_pending = self.env['request.information'].search_count([
            ('state', 'in', ['submitted', 'in_progress'])
        ])
        
        # Estimation de la capacité (à configurer selon l'organisation)
        estimated_capacity = 100  # À adapter
        
        overload_ratio = current_pending / estimated_capacity if estimated_capacity > 0 else 0
        
        if overload_ratio > 0.8:
            level = 3  # High
        elif overload_ratio > 0.6:
            level = 2  # Medium
        elif overload_ratio > 0.4:
            level = 1  # Low
        else:
            level = 0  # No risk
        
        return {
            'type': 'overload',
            'level': level,
            'description': f'Risque de surcharge: {current_pending} demandes en cours',
            'probability': min(overload_ratio * 100, 100),
            'impact': 'Retards dans le traitement des demandes'
        }

    def _assess_compliance_risk(self):
        """Évaluer le risque de non-conformité aux délais"""
        overdue_count = self.env['request.information'].search_count([
            ('is_overdue', '=', True)
        ])
        
        total_active = self.env['request.information'].search_count([
            ('state', 'not in', ['responded', 'refused', 'cancelled'])
        ])
        
        if total_active > 0:
            overdue_ratio = overdue_count / total_active
            
            if overdue_ratio > 0.2:
                level = 3  # High
            elif overdue_ratio > 0.1:
                level = 2  # Medium
            elif overdue_ratio > 0.05:
                level = 1  # Low
            else:
                level = 0  # No risk
        else:
            level = 0
            overdue_ratio = 0
        
        return {
            'type': 'compliance',
            'level': level,
            'description': f'Risque de non-conformité: {overdue_count} demandes en retard',
            'probability': min(overdue_ratio * 100, 100),
            'impact': 'Non-respect des délais légaux'
        }

    def _assess_security_risk(self):
        """Évaluer le risque de sécurité"""
        # Analyser les tentatives d'accès multiples
        # Cette analyse nécessiterait un système d'audit plus avancé
        
        return {
            'type': 'security',
            'level': 0,  # Pas d'évaluation pour l'instant
            'description': 'Évaluation de sécurité non disponible',
            'probability': 0,
            'impact': 'Compromission des données sensibles'
        }

    def _assess_quality_risk(self):
        """Évaluer le risque de qualité de service"""
        # Analyser le temps de réponse moyen
        recent_requests = self.env['request.information'].search([
            ('response_date', '>=', fields.Date.today() - timedelta(days=30)),
            ('response_date', '!=', False)
        ])
        
        if recent_requests:
            avg_response_time = sum([
                (req.response_date.date() - req.request_date.date()).days 
                for req in recent_requests
            ]) / len(recent_requests)
            
            if avg_response_time > 25:  # Plus de 25 jours
                level = 3  # High
            elif avg_response_time > 20:
                level = 2  # Medium
            elif avg_response_time > 15:
                level = 1  # Low
            else:
                level = 0  # No risk
        else:
            level = 0
            avg_response_time = 0
        
        return {
            'type': 'quality',
            'level': level,
            'description': f'Risque qualité: temps de réponse moyen {avg_response_time:.1f} jours',
            'probability': min(avg_response_time * 2, 100),
            'impact': 'Dégradation de la qualité de service'
        }

    def _calculate_global_risk(self, risks):
        """Calculer le score de risque global"""
        if not risks:
            return 0
        
        total_score = sum(risk['level'] * risk['probability'] for risk in risks)
        max_possible = len(risks) * 3 * 100  # 3 = niveau max, 100 = probabilité max
        
        return (total_score / max_possible * 100) if max_possible > 0 else 0

    def _generate_risk_recommendations(self, risks):
        """Générer des recommandations basées sur les risques"""
        recommendations = []
        
        for risk in risks:
            if risk['level'] >= 2:  # Medium ou High
                recommendations.append(f"Risque {risk['type']}: {risk['description']}")
        
        if not recommendations:
            recommendations.append("Aucun risque majeur détecté actuellement.")
        
        return recommendations

    def _suggest_mitigation_strategies(self, risks):
        """Suggérer des stratégies d'atténuation"""
        strategies = []
        
        risk_types = [risk['type'] for risk in risks if risk['level'] >= 2]
        
        if 'overload' in risk_types:
            strategies.append("Augmenter temporairement les ressources de traitement")
        
        if 'compliance' in risk_types:
            strategies.append("Prioriser le traitement des demandes en retard")
        
        if 'quality' in risk_types:
            strategies.append("Réviser les processus de traitement pour améliorer l'efficacité")
        
        return strategies