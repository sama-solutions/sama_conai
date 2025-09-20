/* ========================================= */
/* SAMA CONAI - THEME SWITCHER              */
/* ========================================= */

odoo.define('sama_conai.theme_switcher', function (require) {
    'use strict';

    var core = require('web.core');
    var session = require('web.session');
    var rpc = require('web.rpc');
    var _t = core._t;

    console.log('SAMA CONAI Theme Switcher loaded');

    var ThemeSwitcher = {
        
        /**
         * Initialise le système de thème
         */
        init: function() {
            var self = this;
            
            // Attendre que le DOM soit prêt
            $(document).ready(function() {
                self.loadUserTheme();
                self.bindThemeEvents();
            });
        },

        /**
         * Charge le thème de l'utilisateur depuis le serveur
         */
        loadUserTheme: function() {
            var self = this;
            
            rpc.query({
                model: 'res.users',
                method: 'get_current_user_theme',
                args: [],
            }).then(function(theme) {
                console.log('Theme loaded from server:', theme);
                self.applyTheme(theme || 'default');
                self.updateActiveThemeCard(theme || 'default');
            }).catch(function(error) {
                console.warn('Could not load user theme, using default:', error);
                self.applyTheme('default');
            });
        },

        /**
         * Applique un thème à l'interface
         */
        applyTheme: function(themeName) {
            var body = $('body');
            
            // Supprimer tous les attributs de thème existants
            body.removeAttr('data-theme');
            
            // Appliquer le nouveau thème
            body.attr('data-theme', themeName);
            
            console.log('Theme applied:', themeName);
            
            // Déclencher un événement personnalisé
            $(document).trigger('sama_conai:theme_changed', [themeName]);
        },

        /**
         * Met à jour la carte de thème active dans l'interface
         */
        updateActiveThemeCard: function(themeName) {
            $('.theme-choice-card').removeClass('active');
            $('.theme-choice-card[data-theme-name=\"' + themeName + '\"]').addClass('active');
        },

        /**
         * Sauvegarde le thème sur le serveur
         */
        saveTheme: function(themeName) {
            var self = this;
            
            return rpc.query({
                model: 'res.users',
                method: 'write',
                args: [[session.uid], {'sama_conai_theme': themeName}],
            }).then(function() {
                console.log('Theme saved to server:', themeName);
                return true;
            }).catch(function(error) {
                console.error('Could not save theme to server:', error);
                return false;
            });
        },

        /**
         * Change le thème avec animation
         */
        changeTheme: function(themeName) {
            var self = this;
            
            // Animation de transition
            $('body').addClass('theme-transition');
            
            setTimeout(function() {
                // Appliquer le nouveau thème
                self.applyTheme(themeName);
                self.updateActiveThemeCard(themeName);
                
                // Sauvegarder sur le serveur
                self.saveTheme(themeName).then(function(success) {
                    if (success) {
                        // Afficher une notification de succès
                        self.showNotification(_t('Thème appliqué avec succès'), 'success');
                    } else {
                        self.showNotification(_t('Erreur lors de la sauvegarde du thème'), 'warning');
                    }
                });
                
                // Retirer l'animation après un délai
                setTimeout(function() {
                    $('body').removeClass('theme-transition');
                }, 300);
            }, 150);
        },

        /**
         * Lie les événements de changement de thème
         */
        bindThemeEvents: function() {
            var self = this;
            
            // Événement de clic sur les cartes de thème
            $(document).on('click', '.theme-choice-card', function(e) {
                e.preventDefault();
                var themeName = $(this).data('theme-name');
                if (themeName) {
                    self.changeTheme(themeName);
                }
            });

            // Événements pour les boutons de thème dans les vues
            $(document).on('click', '[data-theme-action]', function(e) {
                e.preventDefault();
                var themeName = $(this).data('theme-action');
                if (themeName) {
                    self.changeTheme(themeName);
                }
            });

            // Écouter les changements de thème pour mettre à jour l'interface
            $(document).on('sama_conai:theme_changed', function(event, themeName) {
                self.onThemeChanged(themeName);
            });
        },

        /**
         * Callback appelé quand le thème change
         */
        onThemeChanged: function(themeName) {
            // Mettre à jour les éléments spécifiques si nécessaire
            this.updateChartColors(themeName);
            this.updateIconColors(themeName);
        },

        /**
         * Met à jour les couleurs des graphiques
         */
        updateChartColors: function(themeName) {
            // Si Chart.js est présent, mettre à jour les couleurs
            if (window.Chart && window.Chart.instances) {
                var colors = this.getThemeColors(themeName);
                
                Object.values(window.Chart.instances).forEach(function(chart) {
                    if (chart && chart.data && chart.data.datasets) {
                        chart.data.datasets.forEach(function(dataset) {
                            if (dataset.backgroundColor) {
                                dataset.backgroundColor = colors.primary;
                            }
                            if (dataset.borderColor) {
                                dataset.borderColor = colors.accent;
                            }
                        });
                        chart.update();
                    }
                });
            }
        },

        /**
         * Met à jour les couleurs des icônes
         */
        updateIconColors: function(themeName) {
            var colors = this.getThemeColors(themeName);
            
            // Mettre à jour les icônes avec les nouvelles couleurs
            $('.metric-icon').each(function() {
                var $icon = $(this);
                if ($icon.hasClass('action')) {
                    $icon.css('color', colors.action);
                } else if ($icon.hasClass('danger')) {
                    $icon.css('color', colors.danger);
                }
            });
        },

        /**
         * Retourne les couleurs pour un thème donné
         */
        getThemeColors: function(themeName) {
            var themes = {
                'default': {
                    primary: '#3498DB',
                    accent: '#E67E22',
                    danger: '#E74C3C',
                    success: '#27AE60',
                    action: '#3498DB'
                },
                'terre': {
                    primary: '#D2691E',
                    accent: '#CD853F',
                    danger: '#A0522D',
                    success: '#8FBC8F',
                    action: '#D2691E'
                },
                'moderne': {
                    primary: '#6C5CE7',
                    accent: '#FDCB6E',
                    danger: '#E17055',
                    success: '#00B894',
                    action: '#6C5CE7'
                }
            };
            
            return themes[themeName] || themes['default'];
        },

        /**
         * Affiche une notification
         */
        showNotification: function(message, type) {
            type = type || 'info';
            
            // Utiliser le système de notification d'Odoo si disponible
            if (window.odoo && window.odoo.define) {
                require('web.Notification').notify({
                    title: _t('SAMA CONAI'),
                    message: message,
                    type: type
                });
            } else {
                // Fallback pour une notification simple
                console.log('Notification:', message);
                
                // Créer une notification personnalisée
                var $notification = $('<div class=\"sama-conai-notification ' + type + '\">')
                    .text(message)
                    .css({
                        position: 'fixed',
                        top: '20px',
                        right: '20px',
                        padding: '15px 20px',
                        borderRadius: '10px',
                        zIndex: 9999,
                        opacity: 0
                    });
                
                $('body').append($notification);
                
                $notification.animate({opacity: 1}, 300);
                
                setTimeout(function() {
                    $notification.animate({opacity: 0}, 300, function() {
                        $notification.remove();
                    });
                }, 3000);
            }
        },

        /**
         * Méthodes publiques pour les boutons Odoo
         */
        applyThemeDefault: function() {
            this.changeTheme('default');
        },

        applyThemeTerre: function() {
            this.changeTheme('terre');
        },

        applyThemeModerne: function() {
            this.changeTheme('moderne');
        }
    };

    // CSS pour les transitions de thème
    var transitionCSS = `
        <style>
        .theme-transition * {
            transition: all 0.3s ease !important;
        }
        
        .sama-conai-notification {
            background: var(--background-color);
            color: var(--text-color);
            box-shadow: var(--neumorphic-shadow-extruded);
            border: none;
            font-family: var(--font-family);
        }
        
        .sama-conai-notification.success {
            border-left: 4px solid var(--accent-success);
        }
        
        .sama-conai-notification.warning {
            border-left: 4px solid var(--accent-alert);
        }
        
        .sama-conai-notification.error {
            border-left: 4px solid var(--accent-danger);
        }
        </style>
    `;
    
    $('head').append(transitionCSS);

    // Initialiser le theme switcher
    ThemeSwitcher.init();

    // Exposer globalement pour les boutons Odoo
    window.SamaConaiThemeSwitcher = ThemeSwitcher;

    return ThemeSwitcher;
});

// Initialisation pour les contextes non-Odoo (portal, etc.)
if (typeof odoo === 'undefined') {
    $(document).ready(function() {
        console.log('SAMA CONAI Theme Switcher - Portal mode');
        
        // Version simplifiée pour le portal
        var SimpleThemeSwitcher = {
            init: function() {
                this.loadTheme();
                this.bindEvents();
            },
            
            loadTheme: function() {
                // Charger depuis localStorage en mode portal
                var savedTheme = localStorage.getItem('sama_conai_theme') || 'default';
                this.applyTheme(savedTheme);
            },
            
            applyTheme: function(themeName) {
                $('body').attr('data-theme', themeName);
                $('.theme-choice-card').removeClass('active');
                $('.theme-choice-card[data-theme-name=\"' + themeName + '\"]').addClass('active');
            },
            
            bindEvents: function() {
                var self = this;
                $(document).on('click', '.theme-choice-card', function() {
                    var themeName = $(this).data('theme-name');
                    if (themeName) {
                        self.applyTheme(themeName);
                        localStorage.setItem('sama_conai_theme', themeName);
                    }
                });
            }
        };
        
        SimpleThemeSwitcher.init();
    });
}