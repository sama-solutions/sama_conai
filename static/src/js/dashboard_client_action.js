/* ========================================= */
/* SAMA CONAI - DASHBOARD CLIENT ACTION     */
/* ========================================= */

odoo.define('sama_conai.dashboard_client_action', function (require) {
    'use strict';

    var AbstractAction = require('web.AbstractAction');
    var core = require('web.core');
    var rpc = require('web.rpc');
    var session = require('web.session');
    var QWeb = core.qweb;
    var _t = core._t;

    var SamaConaiDashboard = AbstractAction.extend({
        template: 'sama_conai.dashboard_client_action',
        
        events: {
            'click .nav-item': '_onNavItemClick',
            'click .theme-choice-card': '_onThemeChange',
            'click .metric-card': '_onMetricClick',
            'click .user-profile-icon': '_onProfileClick',
            'click .refresh-dashboard': '_onRefreshDashboard',
        },

        /**
         * Initialisation du dashboard
         */
        init: function(parent, action) {
            this._super.apply(this, arguments);
            this.dashboard_data = {};
            this.current_theme = 'default';
            this.chart_instance = null;
        },

        /**
         * Démarrage du widget
         */
        start: function() {
            var self = this;
            return this._super().then(function() {
                return self._loadDashboardData().then(function() {
                    self._renderDashboard();
                    self._initializeChart();
                    self._loadUserTheme();
                });
            });
        },

        /**
         * Charge les données du dashboard
         */
        _loadDashboardData: function() {
            var self = this;
            return rpc.query({
                route: '/sama_conai/api/dashboard_data',
                params: {}
            }).then(function(result) {
                if (result.success) {
                    self.dashboard_data = result.data;
                } else {
                    console.error('Erreur lors du chargement des données:', result.error);
                    self.dashboard_data = self._getDefaultData();
                }
            }).catch(function(error) {
                console.error('Erreur RPC dashboard_data:', error);
                self.dashboard_data = self._getDefaultData();
            });
        },

        /**
         * Charge le thème de l'utilisateur
         */
        _loadUserTheme: function() {
            var self = this;
            return rpc.query({
                route: '/sama_conai/api/user_theme',
                params: {}
            }).then(function(result) {
                if (result.success) {
                    self.current_theme = result.theme;
                    self._applyTheme(result.theme);
                }
            }).catch(function(error) {
                console.error('Erreur lors du chargement du thème:', error);
            });
        },

        /**
         * Applique un thème
         */
        _applyTheme: function(theme_name) {
            $('body').attr('data-theme', theme_name);
            this.current_theme = theme_name;
            
            // Mettre à jour les couleurs du graphique
            if (this.chart_instance) {
                this._updateChartColors();
            }
        },

        /**
         * Rendu du dashboard
         */
        _renderDashboard: function() {
            var self = this;
            var $dashboard = $(QWeb.render('sama_conai.dashboard_content', {
                dashboard_data: this.dashboard_data,
                user: session,
                current_theme: this.current_theme
            }));
            
            this.$el.html($dashboard);
            
            // Ajouter les classes CSS appropriées
            this.$el.addClass('sama-conai-dashboard');
        },

        /**
         * Initialise le graphique Chart.js
         */
        _initializeChart: function() {
            var self = this;
            var $canvas = this.$('#main-chart');
            
            if ($canvas.length && typeof Chart !== 'undefined') {
                var ctx = $canvas[0].getContext('2d');
                
                var chartData = {
                    labels: ['En cours', 'Terminées', 'En retard', 'Annulées'],
                    datasets: [{
                        data: [
                            this.dashboard_data.in_progress_count || 0,
                            this.dashboard_data.completed_count || 0,
                            this.dashboard_data.overdue_count || 0,
                            this.dashboard_data.cancelled_count || 0
                        ],
                        backgroundColor: this._getChartColors(),
                        borderWidth: 0,
                        hoverOffset: 4
                    }]
                };\n\n                this.chart_instance = new Chart(ctx, {\n                    type: 'doughnut',\n                    data: chartData,\n                    options: {\n                        responsive: true,\n                        maintainAspectRatio: false,\n                        plugins: {\n                            legend: {\n                                position: 'bottom',\n                                labels: {\n                                    color: 'var(--text-color)',\n                                    font: {\n                                        family: 'var(--font-family)',\n                                        size: 12\n                                    },\n                                    padding: 20\n                                }\n                            },\n                            tooltip: {\n                                backgroundColor: 'var(--background-color)',\n                                titleColor: 'var(--text-color)',\n                                bodyColor: 'var(--text-color)',\n                                borderColor: 'var(--shadow-dark)',\n                                borderWidth: 1\n                            }\n                        },\n                        animation: {\n                            animateScale: true,\n                            animateRotate: true\n                        }\n                    }\n                });\n            }\n        },\n\n        /**\n         * Met à jour les couleurs du graphique\n         */\n        _updateChartColors: function() {\n            if (this.chart_instance) {\n                this.chart_instance.data.datasets[0].backgroundColor = this._getChartColors();\n                this.chart_instance.update();\n            }\n        },\n\n        /**\n         * Retourne les couleurs pour le graphique selon le thème\n         */\n        _getChartColors: function() {\n            var themes = {\n                'default': ['#3498DB', '#27AE60', '#E74C3C', '#95A5A6'],\n                'terre': ['#D2691E', '#8FBC8F', '#A0522D', '#CD853F'],\n                'moderne': ['#6C5CE7', '#00B894', '#E17055', '#B2BEC3']\n            };\n            \n            return themes[this.current_theme] || themes['default'];\n        },\n\n        /**\n         * Données par défaut en cas d'erreur\n         */\n        _getDefaultData: function() {\n            return {\n                in_progress_count: 0,\n                completed_count: 0,\n                overdue_count: 0,\n                cancelled_count: 0,\n                active_alerts: 0,\n                total_requests: 0,\n                priority_tasks: [{\n                    reference: 'INFO',\n                    title: 'Aucune donnée disponible',\n                    urgency_color: '#95A5A6'\n                }]\n            };\n        },\n\n        /**\n         * Gestionnaire de clic sur les éléments de navigation\n         */\n        _onNavItemClick: function(event) {\n            event.preventDefault();\n            var $target = $(event.currentTarget);\n            var href = $target.attr('href');\n            \n            // Mettre à jour l'état actif\n            this.$('.nav-item').removeClass('active');\n            $target.addClass('active');\n            \n            // Navigation selon l'élément cliqué\n            switch(href) {\n                case '#dashboard':\n                    this._showDashboard();\n                    break;\n                case '#requests':\n                    this._showRequests();\n                    break;\n                case '#alerts':\n                    this._showAlerts();\n                    break;\n                case '#analytics':\n                    this._showAnalytics();\n                    break;\n                case '#settings':\n                    this._showSettings();\n                    break;\n            }\n        },\n\n        /**\n         * Gestionnaire de changement de thème\n         */\n        _onThemeChange: function(event) {\n            var $card = $(event.currentTarget);\n            var theme_name = $card.data('theme-name');\n            \n            if (theme_name) {\n                this._changeTheme(theme_name);\n            }\n        },\n\n        /**\n         * Change le thème\n         */\n        _changeTheme: function(theme_name) {\n            var self = this;\n            \n            return rpc.query({\n                route: '/sama_conai/api/change_theme',\n                params: {\n                    theme_name: theme_name\n                }\n            }).then(function(result) {\n                if (result.success) {\n                    self._applyTheme(theme_name);\n                    self._updateThemeCards(theme_name);\n                    self.displayNotification({\n                        title: _t('Thème appliqué'),\n                        message: result.message,\n                        type: 'success'\n                    });\n                } else {\n                    self.displayNotification({\n                        title: _t('Erreur'),\n                        message: result.error,\n                        type: 'danger'\n                    });\n                }\n            }).catch(function(error) {\n                console.error('Erreur lors du changement de thème:', error);\n                self.displayNotification({\n                    title: _t('Erreur'),\n                    message: _t('Impossible de changer le thème'),\n                    type: 'danger'\n                });\n            });\n        },\n\n        /**\n         * Met à jour l'affichage des cartes de thème\n         */\n        _updateThemeCards: function(active_theme) {\n            this.$('.theme-choice-card').removeClass('active');\n            this.$('.theme-choice-card[data-theme-name=\"' + active_theme + '\"]').addClass('active');\n        },\n\n        /**\n         * Gestionnaire de clic sur les métriques\n         */\n        _onMetricClick: function(event) {\n            var $card = $(event.currentTarget);\n            // Ajouter une animation de clic\n            $card.addClass('clicked');\n            setTimeout(function() {\n                $card.removeClass('clicked');\n            }, 200);\n            \n            // Ici, vous pouvez ajouter la logique pour naviguer vers les détails\n            console.log('Métrique cliquée:', $card.find('.metric-title').text());\n        },\n\n        /**\n         * Gestionnaire de clic sur le profil utilisateur\n         */\n        _onProfileClick: function(event) {\n            this._showSettings();\n        },\n\n        /**\n         * Actualise le dashboard\n         */\n        _onRefreshDashboard: function(event) {\n            var self = this;\n            var $button = $(event.currentTarget);\n            \n            $button.addClass('fa-spin');\n            \n            this._loadDashboardData().then(function() {\n                self._renderDashboard();\n                self._initializeChart();\n                $button.removeClass('fa-spin');\n                \n                self.displayNotification({\n                    title: _t('Dashboard actualisé'),\n                    message: _t('Les données ont été mises à jour'),\n                    type: 'success'\n                });\n            });\n        },\n\n        /**\n         * Affiche le dashboard principal\n         */\n        _showDashboard: function() {\n            // Logique pour afficher le dashboard\n            console.log('Affichage du dashboard');\n        },\n\n        /**\n         * Affiche les demandes\n         */\n        _showRequests: function() {\n            this.do_action({\n                type: 'ir.actions.act_window',\n                name: _t('Demandes d\\'Information'),\n                res_model: 'request.information',\n                view_mode: 'kanban,list,form',\n                target: 'current'\n            });\n        },\n\n        /**\n         * Affiche les alertes\n         */\n        _showAlerts: function() {\n            this.do_action({\n                type: 'ir.actions.act_window',\n                name: _t('Alertes de Signalement'),\n                res_model: 'whistleblowing.alert',\n                view_mode: 'kanban,list,form',\n                target: 'current'\n            });\n        },\n\n        /**\n         * Affiche les analyses\n         */\n        _showAnalytics: function() {\n            this.do_action({\n                type: 'ir.actions.act_window',\n                name: _t('Analyses et Rapports'),\n                res_model: 'sama_conai.executive_dashboard',\n                view_mode: 'form',\n                target: 'current'\n            });\n        },\n\n        /**\n         * Affiche les paramètres\n         */\n        _showSettings: function() {\n            this.do_action({\n                type: 'ir.actions.act_window',\n                name: _t('Gestionnaire de Thèmes'),\n                res_model: 'res.users',\n                view_mode: 'form',\n                res_id: session.uid,\n                views: [[false, 'form']],\n                target: 'new',\n                context: {'form_view_ref': 'sama_conai.view_sama_conai_theme_manager'}\n            });\n        },\n\n        /**\n         * Nettoyage lors de la destruction\n         */\n        destroy: function() {\n            if (this.chart_instance) {\n                this.chart_instance.destroy();\n            }\n            this._super();\n        }\n    });\n\n    // Enregistrer l'action client\n    core.action_registry.add('sama_conai.dashboard', SamaConaiDashboard);\n\n    return SamaConaiDashboard;\n});\n\n// Template QWeb pour le contenu du dashboard\nodoo.define('sama_conai.dashboard_templates', function (require) {\n    'use strict';\n    \n    var core = require('web.core');\n    var QWeb = core.qweb;\n    \n    // Ajouter les templates au registre QWeb\n    QWeb.add_template(`\n        <templates>\n            <t t-name=\"sama_conai.dashboard_client_action\">\n                <div class=\"sama-conai-dashboard-container\">\n                    <!-- Le contenu sera rendu dynamiquement -->\n                </div>\n            </t>\n            \n            <t t-name=\"sama_conai.dashboard_content\">\n                <div class=\"sama-conai-dashboard\">\n                    <!-- Header -->\n                    <div class=\"dashboard-header\">\n                        <h1>Tableau de Bord</h1>\n                        <div class=\"header-actions\">\n                            <button class=\"neumorphic-button refresh-dashboard\" title=\"Actualiser\">\n                                <i class=\"fa fa-sync-alt\"></i>\n                            </button>\n                            <div class=\"user-profile-icon\" title=\"Profil utilisateur\">\n                                <i class=\"fa fa-user\"></i>\n                            </div>\n                        </div>\n                    </div>\n\n                    <!-- Métriques -->\n                    <div class=\"metrics-grid\">\n                        <div class=\"neumorphic-card metric-card action\">\n                            <div class=\"metric-content\">\n                                <div class=\"metric-title\">Demandes en Cours</div>\n                                <div class=\"metric-value\"><t t-esc=\"dashboard_data.in_progress_count\"/></div>\n                            </div>\n                            <div class=\"metric-icon action\">\n                                <i class=\"fa fa-clock\"></i>\n                            </div>\n                        </div>\n\n                        <div class=\"neumorphic-card metric-card danger\">\n                            <div class=\"metric-content\">\n                                <div class=\"metric-title\">Dossiers en Retard</div>\n                                <div class=\"metric-value\"><t t-esc=\"dashboard_data.overdue_count\"/></div>\n                            </div>\n                            <div class=\"metric-icon danger\">\n                                <i class=\"fa fa-exclamation-triangle\"></i>\n                            </div>\n                        </div>\n\n                        <div class=\"neumorphic-card metric-card action\">\n                            <div class=\"metric-content\">\n                                <div class=\"metric-title\">Total Demandes</div>\n                                <div class=\"metric-value\"><t t-esc=\"dashboard_data.total_requests\"/></div>\n                            </div>\n                            <div class=\"metric-icon action\">\n                                <i class=\"fa fa-file-alt\"></i>\n                            </div>\n                        </div>\n\n                        <div class=\"neumorphic-card metric-card danger\">\n                            <div class=\"metric-content\">\n                                <div class=\"metric-title\">Alertes Actives</div>\n                                <div class=\"metric-value\"><t t-esc=\"dashboard_data.active_alerts\"/></div>\n                            </div>\n                            <div class=\"metric-icon danger\">\n                                <i class=\"fa fa-bell\"></i>\n                            </div>\n                        </div>\n                    </div>\n\n                    <!-- Graphique -->\n                    <div class=\"neumorphic-card chart-container\">\n                        <div class=\"chart-title\">Répartition des Demandes</div>\n                        <canvas id=\"main-chart\" width=\"400\" height=\"200\"></canvas>\n                    </div>\n\n                    <!-- Tâches prioritaires -->\n                    <div class=\"priority-list\">\n                        <div class=\"list-title\">Tâches Prioritaires</div>\n                        <t t-foreach=\"dashboard_data.priority_tasks\" t-as=\"task\">\n                            <div class=\"neumorphic-card list-item\">\n                                <div class=\"status-bar\" t-attf-style=\"background-color: #{task.urgency_color}\"></div>\n                                <div class=\"item-content\">\n                                    <div class=\"item-id\"><t t-esc=\"task.reference\"/></div>\n                                    <div class=\"item-title\"><t t-esc=\"task.title\"/></div>\n                                </div>\n                            </div>\n                        </t>\n                    </div>\n\n                    <!-- Navigation -->\n                    <nav class=\"bottom-nav neumorphic-nav\">\n                        <a href=\"#dashboard\" class=\"nav-item active\" title=\"Tableau de bord\">\n                            <i class=\"fa fa-tachometer-alt\"></i>\n                        </a>\n                        <a href=\"#requests\" class=\"nav-item\" title=\"Demandes\">\n                            <i class=\"fa fa-file-alt\"></i>\n                        </a>\n                        <a href=\"#alerts\" class=\"nav-item\" title=\"Alertes\">\n                            <i class=\"fa fa-bell\"></i>\n                        </a>\n                        <a href=\"#analytics\" class=\"nav-item\" title=\"Analyses\">\n                            <i class=\"fa fa-chart-bar\"></i>\n                        </a>\n                        <a href=\"#settings\" class=\"nav-item\" title=\"Paramètres\">\n                            <i class=\"fa fa-cog\"></i>\n                        </a>\n                    </nav>\n                </div>\n            </t>\n        </templates>\n    `);\n});"