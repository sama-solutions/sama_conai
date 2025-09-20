/**
 * SAMA CONAI - JavaScript Principal
 * Fonctionnalités de base pour le site web
 */

// Configuration globale
const SAMA_CONFIG = {
    version: '1.0.0',
    debug: true,
    apiUrl: '/api/v1',
    animationDuration: 300
};

/**
 * Initialisation principale
 */
document.addEventListener('DOMContentLoaded', function() {
    console.log('🌐 SAMA CONAI - Initialisation du site web');
    
    // Initialiser les composants
    initNavigation();
    initAnimations();
    initForms();
    initTooltips();
    initScrollEffects();
    
    console.log('✅ Site web SAMA CONAI initialisé');
});

/**
 * Initialiser la navigation
 */
function initNavigation() {
    // Navigation responsive
    const navbarToggler = document.querySelector('.navbar-toggler');
    const navbarCollapse = document.querySelector('.navbar-collapse');
    
    if (navbarToggler && navbarCollapse) {
        navbarToggler.addEventListener('click', function() {
            navbarCollapse.classList.toggle('show');
        });
    }
    
    // Fermer le menu mobile lors du clic sur un lien
    document.querySelectorAll('.navbar-nav .nav-link').forEach(link => {
        link.addEventListener('click', function() {
            if (navbarCollapse.classList.contains('show')) {
                navbarCollapse.classList.remove('show');
            }
        });
    });
    
    // Highlight de la page active
    highlightActivePage();
    
    console.log('📱 Navigation initialisée');
}

/**
 * Mettre en évidence la page active
 */
function highlightActivePage() {
    const currentPath = window.location.pathname;
    const navLinks = document.querySelectorAll('.navbar-nav .nav-link, .dropdown-item');
    
    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (href && currentPath.includes(href.replace('../', ''))) {
            link.classList.add('active');
            
            // Si c'est un item de dropdown, activer aussi le parent
            const dropdown = link.closest('.dropdown');
            if (dropdown) {
                const dropdownToggle = dropdown.querySelector('.dropdown-toggle');
                if (dropdownToggle) {
                    dropdownToggle.classList.add('active');
                }
            }
        }
    });
}

/**
 * Initialiser les animations
 */
function initAnimations() {
    // Initialiser AOS si disponible
    if (typeof AOS !== 'undefined') {
        AOS.init({
            duration: 800,
            easing: 'ease-in-out',
            once: true,
            offset: 100
        });
        console.log('🎬 Animations AOS initialisées');
    }
    
    // Animations personnalisées
    initCustomAnimations();
}

/**
 * Animations personnalisées
 */
function initCustomAnimations() {
    // Animation des cartes au survol
    document.querySelectorAll('.card, .feature-item, .benefit-item').forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
            this.style.transition = 'transform 0.3s ease';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });
    
    // Animation des boutons
    document.querySelectorAll('.btn').forEach(button => {
        button.addEventListener('click', function(e) {
            // Effet ripple
            const ripple = document.createElement('span');
            const rect = this.getBoundingClientRect();
            const size = Math.max(rect.width, rect.height);
            const x = e.clientX - rect.left - size / 2;
            const y = e.clientY - rect.top - size / 2;
            
            ripple.style.cssText = `
                position: absolute;
                width: ${size}px;
                height: ${size}px;
                left: ${x}px;
                top: ${y}px;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 50%;
                transform: scale(0);
                animation: ripple 0.6s linear;
                pointer-events: none;
            `;
            
            this.style.position = 'relative';
            this.style.overflow = 'hidden';
            this.appendChild(ripple);
            
            setTimeout(() => {
                ripple.remove();
            }, 600);
        });
    });
}

/**
 * Initialiser les formulaires
 */
function initForms() {
    // Validation des formulaires Bootstrap
    const forms = document.querySelectorAll('.needs-validation');
    
    forms.forEach(form => {
        form.addEventListener('submit', function(event) {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
            }
            form.classList.add('was-validated');
        });
    });
    
    // Amélioration des champs de fichier
    document.querySelectorAll('input[type="file"]').forEach(input => {
        input.addEventListener('change', function() {
            const fileName = this.files[0]?.name || 'Aucun fichier sélectionné';
            const label = this.nextElementSibling;
            if (label && label.classList.contains('form-label')) {
                label.textContent = fileName;
            }
        });
    });
    
    console.log('📝 Formulaires initialisés');
}

/**
 * Initialiser les tooltips
 */
function initTooltips() {
    // Initialiser les tooltips Bootstrap si disponible
    if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
        const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function(tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
        console.log('💡 Tooltips initialisés');
    }
    
    // Tooltips personnalisés
    document.querySelectorAll('[title]').forEach(element => {
        if (!element.hasAttribute('data-bs-toggle')) {
            element.addEventListener('mouseenter', showCustomTooltip);
            element.addEventListener('mouseleave', hideCustomTooltip);
        }
    });
}

/**
 * Afficher un tooltip personnalisé
 */
function showCustomTooltip(event) {
    const element = event.target;
    const title = element.getAttribute('title');
    
    if (!title) return;
    
    // Créer le tooltip
    const tooltip = document.createElement('div');
    tooltip.className = 'custom-tooltip';
    tooltip.textContent = title;
    tooltip.style.cssText = `
        position: absolute;
        background: #333;
        color: white;
        padding: 8px 12px;
        border-radius: 4px;
        font-size: 12px;
        z-index: 9999;
        pointer-events: none;
        opacity: 0;
        transition: opacity 0.3s ease;
    `;
    
    document.body.appendChild(tooltip);
    
    // Positionner le tooltip
    const rect = element.getBoundingClientRect();
    tooltip.style.left = rect.left + (rect.width / 2) - (tooltip.offsetWidth / 2) + 'px';
    tooltip.style.top = rect.top - tooltip.offsetHeight - 8 + 'px';
    
    // Animer l'apparition
    setTimeout(() => {
        tooltip.style.opacity = '1';
    }, 10);
    
    // Stocker la référence
    element._customTooltip = tooltip;
    
    // Cacher le title original
    element.setAttribute('data-original-title', title);
    element.removeAttribute('title');
}

/**
 * Cacher un tooltip personnalisé
 */
function hideCustomTooltip(event) {
    const element = event.target;
    const tooltip = element._customTooltip;
    
    if (tooltip) {
        tooltip.style.opacity = '0';
        setTimeout(() => {
            if (tooltip.parentElement) {
                tooltip.remove();
            }
        }, 300);
        delete element._customTooltip;
    }
    
    // Restaurer le title original
    const originalTitle = element.getAttribute('data-original-title');
    if (originalTitle) {
        element.setAttribute('title', originalTitle);
        element.removeAttribute('data-original-title');
    }
}

/**
 * Initialiser les effets de scroll
 */
function initScrollEffects() {
    // Navbar transparente/opaque selon le scroll
    const navbar = document.querySelector('.navbar');
    if (navbar) {
        window.addEventListener('scroll', function() {
            if (window.scrollY > 50) {
                navbar.classList.add('scrolled');
            } else {
                navbar.classList.remove('scrolled');
            }
        });
    }
    
    // Bouton retour en haut
    createBackToTopButton();
    
    // Smooth scroll pour les ancres
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
    
    console.log('📜 Effets de scroll initialisés');
}

/**
 * Créer le bouton retour en haut
 */
function createBackToTopButton() {
    const backToTop = document.createElement('button');
    backToTop.innerHTML = '<i class="fas fa-chevron-up"></i>';
    backToTop.className = 'btn btn-primary back-to-top';
    backToTop.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        width: 50px;
        height: 50px;
        border-radius: 50%;
        display: none;
        z-index: 9999;
        border: none;
        box-shadow: 0 2px 10px rgba(0,0,0,0.3);
        transition: all 0.3s ease;
    `;
    
    document.body.appendChild(backToTop);
    
    // Afficher/cacher selon le scroll
    window.addEventListener('scroll', function() {
        if (window.scrollY > 300) {
            backToTop.style.display = 'block';
            setTimeout(() => {
                backToTop.style.opacity = '1';
                backToTop.style.transform = 'scale(1)';
            }, 10);
        } else {
            backToTop.style.opacity = '0';
            backToTop.style.transform = 'scale(0.8)';
            setTimeout(() => {
                if (window.scrollY <= 300) {
                    backToTop.style.display = 'none';
                }
            }, 300);
        }
    });
    
    // Action du bouton
    backToTop.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}

/**
 * Utilitaires globaux
 */
window.SAMA = {
    // Afficher une notification
    notify: function(message, type = 'info', duration = 3000) {
        const notification = document.createElement('div');
        notification.className = `alert alert-${type} notification-global`;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 10000;
            min-width: 300px;
            opacity: 0;
            transform: translateX(100%);
            transition: all 0.3s ease;
        `;
        
        notification.innerHTML = `
            <div class="d-flex align-items-center">
                <i class="fas fa-info-circle me-2"></i>
                <span>${message}</span>
                <button type="button" class="btn-close ms-auto" onclick="this.closest('.notification-global').remove()"></button>
            </div>
        `;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.opacity = '1';
            notification.style.transform = 'translateX(0)';
        }, 100);
        
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (notification.parentElement) {
                    notification.remove();
                }
            }, 300);
        }, duration);
    },
    
    // Confirmer une action
    confirm: function(message, callback) {
        if (confirm(message)) {
            callback();
        }
    },
    
    // Copier du texte dans le presse-papiers
    copyToClipboard: function(text) {
        navigator.clipboard.writeText(text).then(() => {
            this.notify('Texte copié dans le presse-papiers', 'success');
        }).catch(() => {
            this.notify('Erreur lors de la copie', 'error');
        });
    },
    
    // Formater une date
    formatDate: function(date, locale = 'fr-FR') {
        return new Date(date).toLocaleDateString(locale, {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    },
    
    // Débounce pour les événements
    debounce: function(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
};

// Gestion des erreurs globales
window.addEventListener('error', function(event) {
    if (SAMA_CONFIG.debug) {
        console.error('Erreur JavaScript:', event.error);
    }
});

// Gestion des promesses rejetées
window.addEventListener('unhandledrejection', function(event) {
    if (SAMA_CONFIG.debug) {
        console.error('Promise rejetée:', event.reason);
    }
});

console.log('🚀 SAMA CONAI - JavaScript principal chargé');