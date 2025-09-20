# -*- coding: utf-8 -*-

from odoo import http, fields, _
from odoo.http import request
from odoo.exceptions import ValidationError, AccessError, MissingError
from odoo.addons.portal.controllers.portal import CustomerPortal
import logging

_logger = logging.getLogger(__name__)


class TransparencyPortalController(http.Controller):
    
    # ========================================
    # CONTRÔLEURS POUR L'ACCÈS À L'INFORMATION
    # ========================================
    
    @http.route('/acces-information', type='http', auth='public', website=True, csrf=False)
    def information_request_form(self, **kwargs):
        """Page de formulaire pour les demandes d'accès à l'information"""
        values = {
            'page_name': 'information_request',
            'default_country_id': request.env.ref('base.sn').id,  # Sénégal par défaut
            'form_data': {},  # Données du formulaire vides par défaut
        }
        
        # Récupérer les qualités de demandeur
        requester_qualities = [
            ('citizen', 'Citoyen'),
            ('journalist', 'Journaliste'),
            ('researcher', 'Chercheur'),
            ('lawyer', 'Avocat'),
            ('ngo', 'ONG'),
            ('other', 'Autre')
        ]
        values['requester_qualities'] = requester_qualities
        
        return request.render('sama_conai.information_request_form_template', values)
    
    @http.route('/acces-information/submit', type='http', auth='public', website=True, csrf=False, methods=['POST'])
    def information_request_submit(self, **post):
        """Soumission du formulaire de demande d'information"""
        try:
            # Validation des champs obligatoires
            required_fields = ['partner_name', 'partner_email', 'requester_quality', 'description']
            for field in required_fields:
                if not post.get(field):
                    raise ValidationError(_('Le champ %s est obligatoire.') % field)
            
            # Validation de l'email
            if '@' not in post.get('partner_email', ''):
                raise ValidationError(_('Veuillez saisir une adresse email valide.'))
            
            # Créer la demande d'information
            try:
                stage_id = request.env.ref('sama_conai.stage_new').id
            except:
                # Fallback si le stage n'existe pas
                stage_id = request.env['request.information.stage'].sudo().search([], limit=1).id
            
            request_vals = {
                'partner_name': post.get('partner_name'),
                'partner_email': post.get('partner_email'),
                'partner_phone': post.get('partner_phone', ''),
                'requester_quality': post.get('requester_quality'),
                'description': post.get('description'),
                'stage_id': stage_id,
                'state': 'submitted',
            }
            
            # Créer l'enregistrement avec les droits système
            info_request = request.env['request.information'].sudo().create(request_vals)
            
            # Envoyer l'accusé de réception (si la méthode existe)
            try:
                info_request._send_acknowledgment_email()
            except AttributeError:
                # Méthode non implémentée, continuer sans erreur
                pass
            
            # Rediriger vers la page de confirmation
            return request.redirect('/acces-information/confirmation?request_id=%s' % info_request.id)
            
        except Exception as e:
            _logger.error('Erreur lors de la soumission de la demande d\'information: %s', str(e))
            values = {
                'error_message': str(e),
                'form_data': post,
                'requester_qualities': [
                    ('citizen', 'Citoyen'),
                    ('journalist', 'Journaliste'),
                    ('researcher', 'Chercheur'),
                    ('lawyer', 'Avocat'),
                    ('ngo', 'ONG'),
                    ('other', 'Autre')
                ]
            }
            return request.render('sama_conai.information_request_form_template', values)
    
    @http.route('/acces-information/confirmation', type='http', auth='public', website=True)
    def information_request_confirmation(self, request_id=None, **kwargs):
        """Page de confirmation après soumission"""
        if not request_id:
            return request.redirect('/acces-information')
        
        try:
            info_request = request.env['request.information'].sudo().browse(int(request_id))
            if not info_request.exists():
                return request.redirect('/acces-information')
            
            values = {
                'info_request': info_request,
                'page_name': 'information_confirmation',
            }
            return request.render('sama_conai.information_request_confirmation_template', values)
            
        except Exception as e:
            _logger.error('Erreur lors de l\'affichage de la confirmation: %s', str(e))
            return request.redirect('/acces-information')
    
    # ========================================
    # CONTRÔLEURS POUR LES SIGNALEMENTS D'ALERTE
    # ========================================
    
    @http.route('/signalement-anonyme', type='http', auth='public', website=True, csrf=False)
    def whistleblowing_form(self, **kwargs):
        """Page de formulaire pour les signalements anonymes"""
        values = {
            'page_name': 'whistleblowing_form',
            'form_data': {},  # Données du formulaire vides par défaut
        }
        
        # Récupérer les catégories de signalement
        categories = [
            ('corruption', 'Corruption'),
            ('fraud', 'Fraude'),
            ('abuse_of_power', 'Abus de Pouvoir'),
            ('discrimination', 'Discrimination'),
            ('harassment', 'Harcèlement'),
            ('safety_violation', 'Violation de Sécurité'),
            ('environmental', 'Violation Environnementale'),
            ('other', 'Autre')
        ]
        values['categories'] = categories
        
        return request.render('sama_conai.whistleblowing_form_template', values)
    
    @http.route('/signalement-anonyme/submit', type='http', auth='public', website=True, csrf=False, methods=['POST'])
    def whistleblowing_submit(self, **post):
        """Soumission du formulaire de signalement anonyme"""
        try:
            # Validation des champs obligatoires
            required_fields = ['category', 'description']
            for field in required_fields:
                if not post.get(field):
                    raise ValidationError(_('Le champ %s est obligatoire.') % field)
            
            # Créer le signalement d'alerte
            try:
                stage_id = request.env.ref('sama_conai.whistleblowing_stage_new').id
            except:
                # Fallback si le stage n'existe pas
                stage_id = request.env['whistleblowing.alert.stage'].sudo().search([], limit=1).id
            
            alert_vals = {
                'category': post.get('category'),
                'description': post.get('description'),
                'is_anonymous': True,
                'stage_id': stage_id,
                'state': 'new',
                'priority': 'medium',
            }
            
            # Créer l'enregistrement avec les droits système
            alert = request.env['whistleblowing.alert'].sudo().create(alert_vals)
            
            # Rediriger vers la page de confirmation avec le token
            return request.redirect('/signalement-anonyme/confirmation?token=%s' % alert.access_token)
            
        except Exception as e:
            _logger.error('Erreur lors de la soumission du signalement: %s', str(e))
            values = {
                'error_message': str(e),
                'form_data': post,
                'categories': [
                    ('corruption', 'Corruption'),
                    ('fraud', 'Fraude'),
                    ('abuse_of_power', 'Abus de Pouvoir'),
                    ('discrimination', 'Discrimination'),
                    ('harassment', 'Harcèlement'),
                    ('safety_violation', 'Violation de Sécurité'),
                    ('environmental', 'Violation Environnementale'),
                    ('other', 'Autre')
                ]
            }
            return request.render('sama_conai.whistleblowing_form_template', values)
    
    @http.route('/signalement-anonyme/confirmation', type='http', auth='public', website=True)
    def whistleblowing_confirmation(self, token=None, **kwargs):
        """Page de confirmation après soumission du signalement"""
        if not token:
            return request.redirect('/signalement-anonyme')
        
        try:
            alert = request.env['whistleblowing.alert'].sudo().search([('access_token', '=', token)], limit=1)
            if not alert:
                return request.redirect('/signalement-anonyme')
            
            values = {
                'alert': alert,
                'token': token,
                'page_name': 'whistleblowing_confirmation',
                'follow_url': '/ws/follow/%s' % token,
            }
            return request.render('sama_conai.whistleblowing_confirmation_template', values)
            
        except Exception as e:
            _logger.error('Erreur lors de l\'affichage de la confirmation: %s', str(e))
            return request.redirect('/signalement-anonyme')
    
    @http.route('/ws/follow/<string:token>', type='http', auth='public', website=True)
    def whistleblowing_follow(self, token, **kwargs):
        """Page de suivi anonyme du signalement"""
        try:
            alert_data = request.env['whistleblowing.alert'].sudo().get_alert_by_token(token)
            if not alert_data:
                values = {
                    'error_message': _('Token de suivi invalide ou signalement introuvable.'),
                    'page_name': 'whistleblowing_follow_error',
                }
                return request.render('sama_conai.whistleblowing_follow_template', values)
            
            values = {
                'alert_data': alert_data,
                'token': token,
                'page_name': 'whistleblowing_follow',
            }
            return request.render('sama_conai.whistleblowing_follow_template', values)
            
        except Exception as e:
            _logger.error('Erreur lors du suivi du signalement: %s', str(e))
            values = {
                'error_message': _('Erreur lors de la récupération des informations.'),
                'page_name': 'whistleblowing_follow_error',
            }
            return request.render('sama_conai.whistleblowing_follow_template', values)


class TransparencyCustomerPortal(CustomerPortal):
    """Extension du portail client pour les demandes d'information"""
    
    def _prepare_home_portal_values(self, counters):
        """Ajouter les compteurs des demandes d'information au portail"""
        values = super()._prepare_home_portal_values(counters)
        
        if 'information_request_count' in counters:
            # Compter les demandes de l'utilisateur connecté
            partner = request.env.user.partner_id
            information_request_count = request.env['request.information'].search_count([
                ('partner_email', '=', partner.email)
            ]) if partner.email else 0
            values['information_request_count'] = information_request_count
        
        return values
    
    @http.route(['/my/information-requests', '/my/information-requests/page/<int:page>'], 
                type='http', auth="user", website=True)
    def portal_my_information_requests(self, page=1, date_begin=None, date_end=None, sortby=None, **kw):
        """Page du portail pour voir ses demandes d'information"""
        values = self._prepare_portal_layout_values()
        partner = request.env.user.partner_id
        
        domain = [('partner_email', '=', partner.email)] if partner.email else [('id', '=', 0)]
        
        # Filtres par date
        if date_begin and date_end:
            domain += [('request_date', '>=', date_begin), ('request_date', '<=', date_end)]
        
        # Options de tri
        searchbar_sortings = {
            'date': {'label': _('Date de Demande'), 'order': 'request_date desc'},
            'name': {'label': _('Référence'), 'order': 'name'},
            'stage': {'label': _('Étape'), 'order': 'stage_id'},
        }
        
        if not sortby:
            sortby = 'date'
        order = searchbar_sortings[sortby]['order']
        
        # Pagination simple (sans module website)
        request_count = request.env['request.information'].search_count(domain)
        items_per_page = getattr(self, '_items_per_page', 20)  # 20 par défaut
        
        # Calculer l'offset
        offset = (page - 1) * items_per_page
        
        # Créer un objet pager simple
        total_pages = (request_count + items_per_page - 1) // items_per_page
        pager = {
            'page': page,
            'total': request_count,
            'total_pages': total_pages,
            'offset': offset,
            'step': items_per_page,
            'has_previous': page > 1,
            'has_next': page < total_pages,
            'previous_page': page - 1 if page > 1 else None,
            'next_page': page + 1 if page < total_pages else None,
        }
        
        # Récupérer les demandes
        requests = request.env['request.information'].search(domain, order=order, limit=items_per_page, offset=pager['offset'])
        
        values.update({
            'date': date_begin,
            'date_end': date_end,
            'requests': requests,
            'page_name': 'information_request',
            'pager': pager,
            'default_url': '/my/information-requests',
            'searchbar_sortings': searchbar_sortings,
            'sortby': sortby
        })
        
        return request.render("sama_conai.portal_my_information_requests", values)
    
    @http.route(['/my/information-requests/<int:request_id>'], type='http', auth="user", website=True)
    def portal_information_request_detail(self, request_id, access_token=None, **kw):
        """Page de détail d'une demande d'information"""
        try:
            request_sudo = self._document_check_access('request.information', request_id, access_token)
        except (AccessError, MissingError):
            return request.redirect('/my')
        
        values = {
            'info_request': request_sudo,
            'page_name': 'information_request_detail',
        }
        
        return request.render("sama_conai.portal_information_request_detail", values)