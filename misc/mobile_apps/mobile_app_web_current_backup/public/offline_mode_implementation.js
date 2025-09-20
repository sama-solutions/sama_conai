// SAMA CONAI - Mode Offline et Synchronisation
// Implémentation pour analyser l'interface écran par écran

// Variables globales pour le mode offline
let isOfflineMode = false;
let offlineData = {
    dashboard: null,
    requests: [],
    userProfile: null,
    statistics: null,
    lastSync: null
};

// Service Worker pour la gestion offline
const CACHE_NAME = 'sama-conai-v1';
const urlsToCache = [
    '/',
    '/static/css/main.css',
    '/static/js/main.js',
    'https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap',
    'https://cdn.jsdelivr.net/npm/chart.js'
];

// Détection de l'état de connexion
function initOfflineMode() {
    // Écouter les changements de connexion
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    // Vérifier l'état initial
    if (!navigator.onLine) {
        handleOffline();
    }
    
    // Charger les données en cache
    loadOfflineData();
}

// Gestion du passage en mode offline
function handleOffline() {
    console.log('🔴 Mode offline activé');
    isOfflineMode = true;
    updateConnectionStatus(false);
    showOfflineNotification();
}

// Gestion du retour en ligne
function handleOnline() {
    console.log('🟢 Connexion rétablie');
    isOfflineMode = false;
    updateConnectionStatus(true);
    showOnlineNotification();
    
    // Synchroniser les données
    setTimeout(() => {
        syncOfflineData();
    }, 1000);
}

// Mettre à jour l'indicateur de connexion
function updateConnectionStatus(isOnline) {
    const dataSource = document.getElementById('dataSource');
    if (dataSource) {
        if (isOnline) {
            dataSource.textContent = 'RÉEL';
            dataSource.style.color = 'var(--accent-success)';
        } else {
            dataSource.textContent = 'OFFLINE';
            dataSource.style.color = 'var(--accent-danger)';
        }
    }
    
    // Ajouter un indicateur visuel dans le header
    updateOfflineIndicator(isOnline);
}

// Ajouter un indicateur offline dans l'interface
function updateOfflineIndicator(isOnline) {
    let indicator = document.getElementById('offlineIndicator');
    
    if (!isOnline) {
        if (!indicator) {
            indicator = document.createElement('div');
            indicator.id = 'offlineIndicator';
            indicator.style.cssText = `
                position: fixed;
                top: 10px;
                left: 50%;
                transform: translateX(-50%);
                background: var(--accent-danger);
                color: white;
                padding: 8px 16px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: 600;
                z-index: 1001;
                box-shadow: var(--neumorphic-shadow);
                animation: slideDown 0.3s ease;
            `;
            indicator.textContent = '📡 Mode Offline - Données en cache';
            document.body.appendChild(indicator);
        }
    } else {
        if (indicator) {
            indicator.style.animation = 'slideUp 0.3s ease';
            setTimeout(() => {
                if (indicator.parentNode) {
                    indicator.parentNode.removeChild(indicator);
                }
            }, 300);
        }
    }
}

// Notifications pour les changements de connexion
function showOfflineNotification() {
    showError('📡 Connexion perdue - Passage en mode offline');
}

function showOnlineNotification() {
    showSuccess('🌐 Connexion rétablie - Synchronisation en cours...');
}

// Sauvegarder les données en cache
function saveOfflineData(key, data) {
    try {
        offlineData[key] = data;
        offlineData.lastSync = new Date().toISOString();
        localStorage.setItem('sama_conai_offline_data', JSON.stringify(offlineData));
        console.log(`💾 Données ${key} sauvegardées en cache`);
    } catch (error) {
        console.error('Erreur sauvegarde offline:', error);
    }
}

// Charger les données du cache
function loadOfflineData() {
    try {
        const cached = localStorage.getItem('sama_conai_offline_data');
        if (cached) {
            offlineData = JSON.parse(cached);
            console.log('📂 Données offline chargées:', offlineData);
        }
    } catch (error) {
        console.error('Erreur chargement offline:', error);
    }
}

// Synchroniser les données quand la connexion revient
async function syncOfflineData() {
    if (isOfflineMode) return;
    
    console.log('🔄 Synchronisation des données...');
    
    try {
        // Synchroniser le dashboard
        if (authToken) {
            const dashboardResponse = await fetch('/api/mobile/citizen/dashboard', {
                headers: { 'Authorization': `Bearer ${authToken}` }
            });
            
            if (dashboardResponse.ok) {
                const dashboardData = await dashboardResponse.json();
                if (dashboardData.success) {
                    saveOfflineData('dashboard', dashboardData.data);
                }
            }
            
            // Synchroniser les demandes
            const requestsResponse = await fetch('/api/mobile/citizen/requests', {
                headers: { 'Authorization': `Bearer ${authToken}` }
            });
            
            if (requestsResponse.ok) {
                const requestsData = await requestsResponse.json();
                if (requestsData.success) {
                    saveOfflineData('requests', requestsData.data.requests);
                }
            }
        }
        
        console.log('✅ Synchronisation terminée');
        showSuccess('📱 Données synchronisées');
        
    } catch (error) {
        console.error('Erreur synchronisation:', error);
        showError('❌ Erreur de synchronisation');
    }
}

// Wrapper pour les appels API avec gestion offline
async function fetchWithOfflineSupport(url, options = {}, cacheKey = null) {
    // Si en ligne, faire l'appel normal
    if (!isOfflineMode) {
        try {
            const response = await fetch(url, options);
            const data = await response.json();
            
            // Sauvegarder en cache si succès
            if (data.success && cacheKey) {
                saveOfflineData(cacheKey, data.data);
            }
            
            return data;
        } catch (error) {
            console.error('Erreur fetch:', error);
            // Si erreur réseau, basculer en mode offline
            if (!navigator.onLine) {
                handleOffline();
            }
            throw error;
        }
    }
    
    // Mode offline : utiliser les données en cache
    console.log(`📂 Utilisation des données en cache pour ${cacheKey}`);
    
    if (cacheKey && offlineData[cacheKey]) {
        return {
            success: true,
            data: offlineData[cacheKey],
            source: 'offline_cache'
        };
    }
    
    // Pas de données en cache
    return {
        success: false,
        error: 'Aucune donnée disponible en mode offline',
        source: 'offline_cache'
    };
}

// Analyser l'interface écran par écran
const screenAnalysis = {
    currentScreen: null,
    issues: [],
    
    // Analyser l'écran de login
    analyzeLoginScreen() {
        console.log('🔍 Analyse écran de login...');
        const issues = [];
        
        // Vérifier les éléments essentiels
        const loginForm = document.getElementById('loginForm');
        const emailInput = document.getElementById('loginEmail');
        const passwordInput = document.getElementById('loginPassword');
        const loginButton = document.getElementById('loginButton');
        
        if (!loginForm) issues.push('❌ Formulaire de login manquant');
        if (!emailInput) issues.push('❌ Champ email manquant');
        if (!passwordInput) issues.push('❌ Champ mot de passe manquant');
        if (!loginButton) issues.push('❌ Bouton de connexion manquant');
        
        // Vérifier l'accessibilité
        if (emailInput && !emailInput.getAttribute('aria-label')) {
            issues.push('⚠️ Champ email sans aria-label');
        }
        
        // Vérifier le style neumorphique
        const loginContainer = document.querySelector('.login-container');
        if (loginContainer) {
            const computedStyle = window.getComputedStyle(loginContainer);
            if (!computedStyle.boxShadow || computedStyle.boxShadow === 'none') {
                issues.push('⚠️ Style neumorphique manquant sur le conteneur');
            }
        }
        
        this.issues = this.issues.concat(issues);
        return issues;
    },
    
    // Analyser l'écran dashboard
    analyzeDashboardScreen() {
        console.log('🔍 Analyse écran dashboard...');
        const issues = [];
        
        // Vérifier les cartes principales
        const cards = document.querySelectorAll('.neumorphic-card');
        if (cards.length < 5) {
            issues.push(`❌ Nombre de cartes insuffisant: ${cards.length}/5 attendues`);
        }
        
        // Vérifier les boutons d'action
        const userHeader = document.querySelector('.user-header');
        if (userHeader) {
            const logoutBtn = userHeader.querySelector('.logout-button');
            const backendBtn = userHeader.querySelector('.backend-button');
            const profileBtn = userHeader.querySelector('.profile-button');
            
            if (!logoutBtn) issues.push('❌ Bouton déconnexion manquant');
            if (!backendBtn) issues.push('❌ Bouton backend manquant');
            if (!profileBtn) issues.push('❌ Bouton profil manquant');
        }
        
        // Vérifier la navigation
        cards.forEach((card, index) => {\n            const arrow = card.querySelector('.card-arrow');\n            if (!arrow) {\n                issues.push(`⚠️ Flèche de navigation manquante sur la carte ${index + 1}`);\n            }\n        });\n        \n        this.issues = this.issues.concat(issues);\n        return issues;\n    },\n    \n    // Analyser l'écran des statistiques\n    analyzeStatsScreen() {\n        console.log('🔍 Analyse écran statistiques...');\n        const issues = [];\n        \n        // Vérifier les graphiques\n        const charts = document.querySelectorAll('canvas');\n        if (charts.length === 0) {\n            issues.push('❌ Aucun graphique trouvé');\n        }\n        \n        // Vérifier Chart.js\n        if (typeof Chart === 'undefined') {\n            issues.push('❌ Librairie Chart.js non chargée');\n        }\n        \n        // Vérifier les conteneurs de graphiques\n        const chartContainers = document.querySelectorAll('.chart-container');\n        chartContainers.forEach((container, index) => {\n            const title = container.querySelector('.chart-title');\n            const canvas = container.querySelector('canvas');\n            \n            if (!title) issues.push(`⚠️ Titre manquant pour le graphique ${index + 1}`);\n            if (!canvas) issues.push(`❌ Canvas manquant pour le graphique ${index + 1}`);\n        });\n        \n        this.issues = this.issues.concat(issues);\n        return issues;\n    },\n    \n    // Analyser l'écran profil\n    analyzeProfileScreen() {\n        console.log('🔍 Analyse écran profil...');\n        const issues = [];\n        \n        // Vérifier les informations utilisateur\n        const profileInfo = document.querySelector('.profile-info');\n        if (profileInfo) {\n            const avatar = profileInfo.querySelector('.profile-avatar');\n            const name = profileInfo.querySelector('.profile-name');\n            const email = profileInfo.querySelector('.profile-email');\n            \n            if (!avatar) issues.push('❌ Avatar utilisateur manquant');\n            if (!name) issues.push('❌ Nom utilisateur manquant');\n            if (!email) issues.push('❌ Email utilisateur manquant');\n        } else {\n            issues.push('❌ Section informations profil manquante');\n        }\n        \n        // Vérifier les sections de préférences\n        const profileSections = document.querySelectorAll('.profile-section');\n        if (profileSections.length < 2) {\n            issues.push(`⚠️ Sections profil insuffisantes: ${profileSections.length}/2 attendues`);\n        }\n        \n        this.issues = this.issues.concat(issues);\n        return issues;\n    },\n    \n    // Analyser les thèmes\n    analyzeThemes() {\n        console.log('🔍 Analyse des thèmes...');\n        const issues = [];\n        \n        // Vérifier le sélecteur de thèmes\n        const themeSelector = document.querySelector('.theme-selector');\n        if (!themeSelector) {\n            issues.push('❌ Sélecteur de thèmes manquant');\n            return issues;\n        }\n        \n        const themeOptions = themeSelector.querySelectorAll('.theme-option');\n        if (themeOptions.length < 4) {\n            issues.push(`⚠️ Options de thèmes insuffisantes: ${themeOptions.length}/4 attendues`);\n        }\n        \n        // Tester chaque thème\n        const themes = ['institutionnel', 'terre', 'moderne', 'dark'];\n        themes.forEach(theme => {\n            // Appliquer temporairement le thème\n            const body = document.body;\n            const originalTheme = body.getAttribute('data-theme');\n            body.setAttribute('data-theme', theme);\n            \n            // Vérifier les variables CSS\n            const computedStyle = window.getComputedStyle(body);\n            const bgColor = computedStyle.getPropertyValue('--background-color');\n            const textColor = computedStyle.getPropertyValue('--text-color');\n            \n            if (!bgColor || bgColor.trim() === '') {\n                issues.push(`❌ Variable --background-color manquante pour le thème ${theme}`);\n            }\n            if (!textColor || textColor.trim() === '') {\n                issues.push(`❌ Variable --text-color manquante pour le thème ${theme}`);\n            }\n            \n            // Restaurer le thème original\n            body.setAttribute('data-theme', originalTheme);\n        });\n        \n        this.issues = this.issues.concat(issues);\n        return issues;\n    },\n    \n    // Rapport complet d'analyse\n    generateReport() {\n        console.log('📊 Génération du rapport d\\'analyse...');\n        \n        const report = {\n            timestamp: new Date().toISOString(),\n            totalIssues: this.issues.length,\n            criticalIssues: this.issues.filter(issue => issue.startsWith('❌')).length,\n            warningIssues: this.issues.filter(issue => issue.startsWith('⚠️')).length,\n            issues: this.issues,\n            recommendations: this.generateRecommendations()\n        };\n        \n        return report;\n    },\n    \n    // Générer des recommandations\n    generateRecommendations() {\n        const recommendations = [];\n        \n        if (this.issues.some(issue => issue.includes('aria-label'))) {\n            recommendations.push('🔧 Améliorer l\\'accessibilité en ajoutant des aria-labels');\n        }\n        \n        if (this.issues.some(issue => issue.includes('Chart.js'))) {\n            recommendations.push('📊 Vérifier le chargement de la librairie Chart.js');\n        }\n        \n        if (this.issues.some(issue => issue.includes('neumorphique'))) {\n            recommendations.push('🎨 Corriger les styles neumorphiques manquants');\n        }\n        \n        if (this.issues.some(issue => issue.includes('navigation'))) {\n            recommendations.push('🧭 Améliorer les éléments de navigation');\n        }\n        \n        return recommendations;\n    }\n};\n\n// Fonction principale pour analyser l'interface\nfunction analyzeCurrentInterface() {\n    console.log('🔍 ANALYSE COMPLÈTE DE L\\'INTERFACE');\n    console.log('=====================================');\n    \n    // Réinitialiser les issues\n    screenAnalysis.issues = [];\n    \n    // Analyser selon l'écran actuel\n    const headerTitle = document.getElementById('headerTitle');\n    const currentTitle = headerTitle ? headerTitle.textContent : '';\n    \n    if (currentTitle.includes('SAMA CONAI') && document.getElementById('loginForm')) {\n        screenAnalysis.currentScreen = 'login';\n        screenAnalysis.analyzeLoginScreen();\n    } else if (currentTitle.includes('Dashboard')) {\n        screenAnalysis.currentScreen = 'dashboard';\n        screenAnalysis.analyzeDashboardScreen();\n    } else if (currentTitle.includes('Statistiques')) {\n        screenAnalysis.currentScreen = 'statistics';\n        screenAnalysis.analyzeStatsScreen();\n    } else if (currentTitle.includes('Profil')) {\n        screenAnalysis.currentScreen = 'profile';\n        screenAnalysis.analyzeProfileScreen();\n    }\n    \n    // Analyser les thèmes (toujours)\n    screenAnalysis.analyzeThemes();\n    \n    // Générer le rapport\n    const report = screenAnalysis.generateReport();\n    \n    console.log('📊 RAPPORT D\\'ANALYSE:');\n    console.log(`📱 Écran analysé: ${screenAnalysis.currentScreen}`);\n    console.log(`🔢 Total des problèmes: ${report.totalIssues}`);\n    console.log(`❌ Problèmes critiques: ${report.criticalIssues}`);\n    console.log(`⚠️ Avertissements: ${report.warningIssues}`);\n    \n    if (report.issues.length > 0) {\n        console.log('\\n📋 PROBLÈMES DÉTECTÉS:');\n        report.issues.forEach(issue => console.log(`  ${issue}`));\n    }\n    \n    if (report.recommendations.length > 0) {\n        console.log('\\n💡 RECOMMANDATIONS:');\n        report.recommendations.forEach(rec => console.log(`  ${rec}`));\n    }\n    \n    return report;\n}\n\n// Initialiser le mode offline au chargement\nif (typeof window !== 'undefined') {\n    window.addEventListener('load', initOfflineMode);\n    \n    // Exposer les fonctions globalement pour les tests\n    window.analyzeInterface = analyzeCurrentInterface;\n    window.offlineMode = {\n        enable: handleOffline,\n        disable: handleOnline,\n        sync: syncOfflineData,\n        isOffline: () => isOfflineMode\n    };\n}\n\n// Export pour utilisation en module\nif (typeof module !== 'undefined' && module.exports) {\n    module.exports = {\n        initOfflineMode,\n        analyzeCurrentInterface,\n        screenAnalysis,\n        fetchWithOfflineSupport\n    };\n}"