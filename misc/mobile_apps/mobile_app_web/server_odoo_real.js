const express = require('express');
const path = require('path');
const cors = require('cors');
const OdooConnector = require('./odoo_connector');

const app = express();
const PORT = 3008; // Nouveau port pour la version Odoo réelle

// Middleware
app.use(cors());
app.use(express.json());

// Désactiver le cache pour le développement
app.use(express.static(path.join(__dirname, 'public'), {
    etag: false,
    lastModified: false,
    setHeaders: (res, path) => {
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
    }
}));

// Configuration Odoo
const ODOO_CONFIG = {
    url: 'http://localhost:8077',
    db: 'sama_conai_test',
    username: 'admin',
    password: 'admin'
};

// Initialisation du connecteur Odoo
const odooConnector = new OdooConnector(ODOO_CONFIG);

// Données de fallback (simulées) en cas d'erreur Odoo
const fallbackData = {
    users: [{
        id: 1,
        name: 'Administrateur SAMA CONAI',
        email: 'admin@sama-conai.sn',
        role: 'admin',
        department: 'Direction Générale',
        avatar: '👨‍💼'
    }],
    
    global_stats: {
        total_requests: 0,
        pending_requests: 0,
        completed_requests: 0,
        overdue_requests: 0,
        total_alerts: 0,
        active_alerts: 0,
        new_alerts: 0,
        urgent_alerts: 0,
        response_time_avg: 0,
        satisfaction_rate: 0
    },
    
    kpis: [
        {
            name: 'Demandes Traitées',
            value: 0,
            target: 20,
            percentage: 0,
            trend: 'stable',
            icon: '📋',
            source: 'odoo'
        },
        {
            name: 'Temps Moyen Réponse en jours',
            value: 0,
            target: 15,
            percentage: 0,
            trend: 'stable',
            icon: '⏱️',
            source: 'odoo'
        },
        {
            name: 'Satisfaction Client',
            value: 0,
            target: 90,
            percentage: 0,
            trend: 'stable',
            icon: '😊',
            unit: '%',
            source: 'odoo'
        },
        {
            name: 'Alertes Résolues',
            value: 0,
            target: 15,
            percentage: 0,
            trend: 'stable',
            icon: '✅',
            source: 'odoo'
        }
    ],
    
    notifications: [
        {
            id: 1,
            type: 'info',
            title: 'Connexion Odoo',
            message: 'Connexion aux données réelles en cours...',
            date: new Date().toISOString(),
            read: false,
            icon: '🔗'
        }
    ]
};

// Simulation d'une base de données enrichie en mémoire
let enrichedDatabase = {
    users: [
        {
            id: 1,
            name: 'Administrateur SAMA CONAI',
            email: 'admin@sama-conai.sn',
            role: 'admin',
            department: 'Direction Générale',
            avatar: '👨‍💼'
        }
    ],
    
    // Données enrichies pour les demandes d'information
    informationRequests: [
        {
            id: 1,
            name: 'REQ-2024-001',
            requester_name: 'Amadou Diallo',
            requester_email: 'amadou.diallo@email.sn',
            requester_quality: 'Journaliste',
            request_date: '2024-01-15T09:30:00Z',
            description: 'Demande d\'informations sur les marchés publics 2023 supérieurs à 50M FCFA',
            state: 'responded',
            state_label: 'Répondu',
            priority: 'medium',
            department: 'Marchés Publics',
            assigned_user: 'Marie Faye',
            response_body: 'Réponse complète fournie avec documents en annexe',
            response_date: '2024-02-10T14:20:00Z',
            deadline_date: '2024-02-14',
            is_overdue: false,
            tags: ['marchés publics', 'transparence', 'journalisme'],
            attachments: ['marches_2023.pdf', 'criteres_attribution.xlsx'],
            timeline: [
                {
                    date: '2024-01-15T09:30:00Z',
                    event: 'Demande reçue',
                    description: 'Demande soumise par Amadou Diallo',
                    author: 'Système'
                },
                {
                    date: '2024-01-16T10:00:00Z',
                    event: 'Assignation',
                    description: 'Demande assignée à Marie Faye',
                    author: 'Admin'
                },
                {
                    date: '2024-02-10T14:20:00Z',
                    event: 'Réponse envoyée',
                    description: 'Réponse complète transmise au demandeur',
                    author: 'Marie Faye'
                }
            ]
        },
        {
            id: 2,
            name: 'REQ-2024-002',
            requester_name: 'Fatou Seck',
            requester_email: 'fatou.seck@univ.sn',
            requester_quality: 'Chercheur',
            request_date: '2024-02-01T11:15:00Z',
            description: 'Données sur la gouvernance locale pour thèse de doctorat',
            state: 'in_progress',
            state_label: 'En Traitement',
            priority: 'high',
            department: 'Collectivités Locales',
            assigned_user: 'Ousmane Diop',
            deadline_date: '2024-03-02',
            is_overdue: false,
            tags: ['recherche', 'gouvernance', 'collectivités'],
            timeline: [
                {
                    date: '2024-02-01T11:15:00Z',
                    event: 'Demande reçue',
                    description: 'Demande de recherche académique',
                    author: 'Système'
                },
                {
                    date: '2024-02-02T09:00:00Z',
                    event: 'En traitement',
                    description: 'Collecte des données en cours',
                    author: 'Ousmane Diop'
                }
            ]
        },
        {
            id: 3,
            name: 'REQ-2024-003',
            requester_name: 'Moussa Ba',
            requester_email: 'moussa.ba@avocat.sn',
            requester_quality: 'Avocat',
            request_date: '2024-02-20T16:45:00Z',
            description: 'Documents pour défense dans affaire judiciaire',
            state: 'refused',
            state_label: 'Refusé',
            priority: 'urgent',
            department: 'Affaires Juridiques',
            assigned_user: 'Aïcha Ndiaye',
            refusal_reason: 'Procédure judiciaire en cours',
            response_date: '2024-03-05T10:30:00Z',
            deadline_date: '2024-03-21',
            is_overdue: false,
            tags: ['juridique', 'confidentiel'],
            timeline: [
                {
                    date: '2024-02-20T16:45:00Z',
                    event: 'Demande reçue',
                    description: 'Demande d\'avocat pour défense',
                    author: 'Système'
                },
                {
                    date: '2024-03-05T10:30:00Z',
                    event: 'Demande refusée',
                    description: 'Refus motivé par procédure en cours',
                    author: 'Aïcha Ndiaye'
                }
            ]
        },
        {
            id: 4,
            name: 'REQ-2024-004',
            requester_name: 'Aïssatou Diop',
            requester_email: 'aissatou.diop@ong.sn',
            requester_quality: 'ONG',
            request_date: '2024-03-01T08:20:00Z',
            description: 'Déclarations de patrimoine pour étude transparence',
            state: 'pending_validation',
            state_label: 'En Validation',
            priority: 'medium',
            department: 'Éthique et Transparence',
            assigned_user: 'Ibrahima Fall',
            deadline_date: '2024-03-31',
            is_overdue: false,
            tags: ['transparence', 'patrimoine', 'ong'],
            timeline: [
                {
                    date: '2024-03-01T08:20:00Z',
                    event: 'Demande reçue',
                    description: 'Demande ONG Transparence Citoyenne',
                    author: 'Système'
                },
                {
                    date: '2024-03-15T14:00:00Z',
                    event: 'En validation',
                    description: 'Réponse préparée, en attente validation',
                    author: 'Ibrahima Fall'
                }
            ]
        },
        {
            id: 5,
            name: 'REQ-2024-005',
            requester_name: 'Ibrahima Ndiaye',
            requester_email: 'ibrahima.ndiaye@citoyen.sn',
            requester_quality: 'Citoyen',
            request_date: '2024-03-10T14:10:00Z',
            description: 'Budget infrastructures scolaires région Kaolack',
            state: 'submitted',
            state_label: 'Soumise',
            priority: 'low',
            department: 'Éducation',
            deadline_date: '2024-04-09',
            is_overdue: false,
            tags: ['éducation', 'budget', 'kaolack'],
            timeline: [
                {
                    date: '2024-03-10T14:10:00Z',
                    event: 'Demande reçue',
                    description: 'Demande citoyenne sur éducation',
                    author: 'Système'
                }
            ]
        }
    ],
    
    // Données enrichies pour les alertes
    whistleblowingAlerts: [
        {
            id: 1,
            name: 'WB-2024-001',
            alert_date: '2024-01-20T10:30:00Z',
            category: 'corruption',
            category_label: 'Corruption',
            priority: 'high',
            priority_label: 'Élevée',
            state: 'investigation',
            state_label: 'Enquête en Cours',
            description: 'Pratiques suspectes dans attribution marché public',
            reporter_name: 'Anonyme',
            manager: 'Commissaire Sarr',
            investigation_notes: 'Enquête approfondie en cours, témoins auditionnés',
            is_anonymous: true,
            tags: ['marché public', 'corruption', 'enquête'],
            timeline: [
                {
                    date: '2024-01-20T10:30:00Z',
                    event: 'Signalement reçu',
                    description: 'Alerte anonyme sur corruption',
                    author: 'Système'
                },
                {
                    date: '2024-01-25T09:00:00Z',
                    event: 'Enquête démarrée',
                    description: 'Investigation formelle ouverte',
                    author: 'Commissaire Sarr'
                }
            ]
        },
        {
            id: 2,
            name: 'WB-2024-002',
            alert_date: '2024-02-05T15:45:00Z',
            category: 'harassment',
            category_label: 'Harcèlement',
            priority: 'urgent',
            priority_label: 'Urgente',
            state: 'resolved',
            state_label: 'Résolu',
            description: 'Harcèlement moral répété par supérieur hiérarchique',
            reporter_name: 'Confidentiel',
            manager: 'Mme Diallo',
            investigation_notes: 'Enquête terminée, mesures disciplinaires prises',
            resolution: 'Sanctions disciplinaires appliquées, formation organisée',
            is_anonymous: false,
            tags: ['harcèlement', 'rh', 'résolu'],
            timeline: [
                {
                    date: '2024-02-05T15:45:00Z',
                    event: 'Signalement reçu',
                    description: 'Alerte harcèlement moral',
                    author: 'Système'
                },
                {
                    date: '2024-02-28T16:00:00Z',
                    event: 'Résolution',
                    description: 'Mesures correctives appliquées',
                    author: 'Mme Diallo'
                }
            ]
        },
        {
            id: 3,
            name: 'WB-2024-003',
            alert_date: '2024-02-15T09:20:00Z',
            category: 'fraud',
            category_label: 'Fraude',
            priority: 'medium',
            priority_label: 'Moyenne',
            state: 'preliminary_assessment',
            state_label: 'Évaluation Préliminaire',
            description: 'Suspicion fraude gestion stocks fournitures',
            reporter_name: 'Anonyme',
            manager: 'M. Sow',
            is_anonymous: true,
            tags: ['fraude', 'stocks', 'évaluation'],
            timeline: [
                {
                    date: '2024-02-15T09:20:00Z',
                    event: 'Signalement reçu',
                    description: 'Alerte fraude stocks',
                    author: 'Système'
                },
                {
                    date: '2024-02-16T10:00:00Z',
                    event: 'Évaluation démarrée',
                    description: 'Vérifications préliminaires en cours',
                    author: 'M. Sow'
                }
            ]
        },
        {
            id: 4,
            name: 'WB-2024-004',
            alert_date: '2024-03-01T11:30:00Z',
            category: 'environmental',
            category_label: 'Environnemental',
            priority: 'high',
            priority_label: 'Élevée',
            state: 'transmitted',
            state_label: 'Transmis',
            description: 'Violations environnementales graves par entreprise',
            reporter_name: 'Anonyme',
            manager: 'Dr. Kane',
            resolution: 'Transmis au Ministère de l\'Environnement',
            is_anonymous: true,
            tags: ['environnement', 'pollution', 'transmis'],
            timeline: [
                {
                    date: '2024-03-01T11:30:00Z',
                    event: 'Signalement reçu',
                    description: 'Alerte pollution environnementale',
                    author: 'Système'
                },
                {
                    date: '2024-03-05T14:00:00Z',
                    event: 'Transmis',
                    description: 'Dossier transmis aux autorités compétentes',
                    author: 'Dr. Kane'
                }
            ]
        },
        {
            id: 5,
            name: 'WB-2024-005',
            alert_date: '2024-03-08T16:15:00Z',
            category: 'abuse_of_power',
            category_label: 'Abus de Pouvoir',
            priority: 'medium',
            priority_label: 'Moyenne',
            state: 'new',
            state_label: 'Nouveau',
            description: 'Abus pouvoir attribution logements sociaux',
            reporter_name: 'Anonyme',
            is_anonymous: true,
            tags: ['abus pouvoir', 'logement', 'nouveau'],
            timeline: [
                {
                    date: '2024-03-08T16:15:00Z',
                    event: 'Signalement reçu',
                    description: 'Nouvelle alerte abus de pouvoir',
                    author: 'Système'
                }
            ]
        }
    ],
    
    // Statistiques enrichies
    statistics: {
        global_stats: {
            total_requests: 25,
            pending_requests: 8,
            completed_requests: 15,
            overdue_requests: 2,
            total_alerts: 18,
            active_alerts: 12,
            new_alerts: 3,
            urgent_alerts: 1,
            response_time_avg: 18.5, // jours
            satisfaction_rate: 87.3 // %
        },
        monthly_trends: {
            requests: [12, 15, 18, 22, 25],
            alerts: [8, 10, 14, 16, 18],
            months: ['Nov', 'Déc', 'Jan', 'Fév', 'Mar']
        },
        categories: {
            requests: {
                'citizen': 40,
                'journalist': 25,
                'researcher': 20,
                'lawyer': 10,
                'ngo': 5
            },
            alerts: {
                'corruption': 35,
                'fraud': 25,
                'harassment': 20,
                'environmental': 15,
                'abuse_of_power': 5
            }
        }
    },
    
    // Notifications enrichies
    notifications: [
        {
            id: 1,
            type: 'urgent',
            title: 'Alerte Urgente',
            message: 'Nouveau signalement de harcèlement nécessitant action immédiate',
            date: '2024-03-15T10:30:00Z',
            read: false,
            icon: '🚨'
        },
        {
            id: 2,
            type: 'deadline',
            title: 'Échéance Proche',
            message: '3 demandes d\'information arrivent à échéance dans 2 jours',
            date: '2024-03-14T15:20:00Z',
            read: false,
            icon: '⏰'
        },
        {
            id: 3,
            type: 'success',
            title: 'Objectif Atteint',
            message: 'Taux de réponse mensuel de 95% atteint !',
            date: '2024-03-13T09:15:00Z',
            read: true,
            icon: '🎯'
        }
    ],
    
    // Tableau de bord enrichi
    dashboard: {
        kpis: [
            {
                name: 'Demandes Traitées',
                value: 15,
                target: 20,
                percentage: 75,
                trend: 'up',
                icon: '📋'
            },
            {
                name: 'Temps Moyen Réponse en jours',
                value: 18.5,
                target: 15,
                percentage: 81,
                trend: 'down',
                icon: '⏱️'
            },
            {
                name: 'Satisfaction Client',
                value: 87.3,
                target: 90,
                percentage: 97,
                trend: 'up',
                icon: '😊',
                unit: '%'
            },
            {
                name: 'Alertes Résolues',
                value: 12,
                target: 15,
                percentage: 80,
                trend: 'stable',
                icon: '✅'
            }
        ],
        recent_activity: {
            requests: [
                {
                    id: 1,
                    name: 'REQ-2024-001',
                    state: 'responded',
                    state_label: 'Répondu',
                    partner_name: 'Amadou Diallo',
                    request_date: '2024-01-15T09:30:00Z'
                },
                {
                    id: 2,
                    name: 'REQ-2024-002',
                    state: 'in_progress',
                    state_label: 'En Traitement',
                    partner_name: 'Fatou Seck',
                    request_date: '2024-02-01T11:15:00Z'
                }
            ],
            alerts: [
                {
                    id: 1,
                    name: 'WB-2024-001',
                    state: 'investigation',
                    category: 'Corruption',
                    priority: 'Élevée',
                    alert_date: '2024-01-20T10:30:00Z'
                },
                {
                    id: 2,
                    name: 'WB-2024-002',
                    state: 'resolved',
                    category: 'Harcèlement',
                    priority: 'Urgente',
                    alert_date: '2024-02-05T15:45:00Z'
                }
            ]
        }
    }
};

// ========================================= //
// ROUTES PRINCIPALES                        //
// ========================================= //

// Route principale - Interface Odoo réelle
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'sama_conai_odoo_real.html'));
});

// Routes alternatives (redirection vers la nouvelle interface)
app.get('/enriched', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'sama_conai_odoo_real.html'));
});

app.get('/real', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'sama_conai_odoo_real.html'));
});

// ========================================= //
// API AVEC DONNÉES ODOO RÉELLES             //
// ========================================= //

// Test de connexion Odoo
app.get('/api/odoo/test', async (req, res) => {
    try {
        const result = await odooConnector.testConnection();
        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        console.error('Erreur test connexion:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Test des modèles SAMA CONAI
app.get('/api/odoo/test-models', async (req, res) => {
    try {
        console.log('🔍 Test des modèles SAMA CONAI...');
        
        const results = {};
        
        // Test modèle request.information
        try {
            const requestCount = await odooConnector.execute('request.information', 'search_count', [[]]);
            results.request_information = {
                exists: true,
                count: requestCount,
                error: null
            };
            console.log(`✅ Modèle request.information: ${requestCount} enregistrement(s)`);
        } catch (error) {
            results.request_information = {
                exists: false,
                count: 0,
                error: error.message
            };
            console.log(`❌ Modèle request.information: ${error.message}`);
        }
        
        // Test modèle whistleblowing.alert
        try {
            const alertCount = await odooConnector.execute('whistleblowing.alert', 'search_count', [[]]);
            results.whistleblowing_alert = {
                exists: true,
                count: alertCount,
                error: null
            };
            console.log(`✅ Modèle whistleblowing.alert: ${alertCount} enregistrement(s)`);
        } catch (error) {
            results.whistleblowing_alert = {
                exists: false,
                count: 0,
                error: error.message
            };
            console.log(`❌ Modèle whistleblowing.alert: ${error.message}`);
        }
        
        // Test modèles de base
        try {
            const userCount = await odooConnector.execute('res.users', 'search_count', [[]]);
            results.res_users = {
                exists: true,
                count: userCount,
                error: null
            };
            console.log(`✅ Modèle res.users: ${userCount} enregistrement(s)`);
        } catch (error) {
            results.res_users = {
                exists: false,
                count: 0,
                error: error.message
            };
        }
        
        const allModelsExist = results.request_information.exists && results.whistleblowing_alert.exists;
        
        res.json({
            success: true,
            data: {
                models: results,
                sama_conai_ready: allModelsExist,
                summary: {
                    total_requests: results.request_information.count,
                    total_alerts: results.whistleblowing_alert.count,
                    total_users: results.res_users.count
                }
            }
        });
    } catch (error) {
        console.error('Erreur test modèles:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Authentification avec données Odoo
app.post('/api/mobile/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Pour la démo, on accepte admin/admin et on teste la connexion Odoo
        if (email === 'admin' && password === 'admin') {
            try {
                // Test de connexion Odoo
                const connectionTest = await odooConnector.testConnection();
                
                if (connectionTest.success) {
                    const userInfo = await odooConnector.getUserInfo();
                    const token = 'odoo_token_' + Date.now();
                    
                    res.json({
                        success: true,
                        data: {
                            token: token,
                            user: userInfo,
                            odoo_connected: true,
                            odoo_version: connectionTest.version
                        }
                    });
                } else {
                    // Fallback si Odoo non accessible
                    const token = 'fallback_token_' + Date.now();
                    res.json({
                        success: true,
                        data: {
                            token: token,
                            user: enrichedDatabase.users[0],
                            odoo_connected: false,
                            error: connectionTest.error
                        }
                    });
                }
            } catch (error) {
                console.error('Erreur connexion Odoo lors du login:', error);
                // Fallback
                const token = 'fallback_token_' + Date.now();
                res.json({
                    success: true,
                    data: {
                        token: token,
                        user: enrichedDatabase.users[0],
                        odoo_connected: false,
                        error: error.message
                    }
                });
            }
        } else {
            res.status(401).json({
                success: false,
                error: 'Identifiants incorrects'
            });
        }
    } catch (error) {
        console.error('Erreur login:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur serveur'
        });
    }
});

// Dashboard avec données Odoo réelles (PHASE 1)
app.get('/api/mobile/level1/dashboard', async (req, res) => {
    try {
        console.log('🎯 Chargement dashboard avec données Odoo réelles...');
        
        let globalStats, userInfo, kpis;
        let odooConnected = false;
        
        try {
            // Tentative de récupération des données réelles
            [globalStats, userInfo] = await Promise.all([
                odooConnector.getGlobalStats(),
                odooConnector.getUserInfo()
            ]);
            
            // Calcul des KPIs basés sur les vraies données
            kpis = [
                {
                    name: 'Demandes Traitées',
                    value: globalStats.completed_requests,
                    target: 20,
                    percentage: Math.min((globalStats.completed_requests / 20) * 100, 100),
                    trend: globalStats.completed_requests > 15 ? 'up' : 'stable',
                    icon: '📋',
                    source: 'odoo'
                },
                {
                    name: 'Temps Moyen Réponse en jours',
                    value: globalStats.response_time_avg,
                    target: 15,
                    percentage: Math.max(100 - ((globalStats.response_time_avg / 15) * 100), 0),
                    trend: globalStats.response_time_avg < 15 ? 'up' : 'down',
                    icon: '⏱️',
                    source: 'odoo'
                },
                {
                    name: 'Satisfaction Client',
                    value: globalStats.satisfaction_rate,
                    target: 90,
                    percentage: (globalStats.satisfaction_rate / 90) * 100,
                    trend: globalStats.satisfaction_rate > 80 ? 'up' : 'stable',
                    icon: '😊',
                    unit: '%',
                    source: 'odoo'
                },
                {
                    name: 'Alertes Résolues',
                    value: globalStats.total_alerts - globalStats.active_alerts,
                    target: 15,
                    percentage: Math.min(((globalStats.total_alerts - globalStats.active_alerts) / 15) * 100, 100),
                    trend: 'stable',
                    icon: '✅',
                    source: 'odoo'
                }
            ];
            
            odooConnected = true;
            console.log('✅ Données Odoo récupérées avec succès');
            
        } catch (error) {
            console.error('❌ Erreur récupération données Odoo, utilisation fallback:', error);
            globalStats = enrichedDatabase.statistics.global_stats;
            userInfo = enrichedDatabase.users[0];
            kpis = enrichedDatabase.dashboard.kpis.map(kpi => ({ ...kpi, source: 'fallback' }));
            odooConnected = false;
        }
        
        const data = {
            user_info: userInfo,
            global_stats: globalStats,
            kpis: kpis,
            odoo_connected: odooConnected,
            data_source: odooConnected ? 'odoo' : 'fallback',
            recent_activity: {
                requests: [],
                alerts: []
            },
            notifications: enrichedDatabase.notifications.filter(n => !n.read).slice(0, 3),
            trends: {
                requests: [8, 12, 15, 18, globalStats.total_requests],
                alerts: [3, 5, 8, 12, globalStats.total_alerts],
                months: ['Nov', 'Déc', 'Jan', 'Fév', 'Mar']
            }
        };
        
        res.json({
            success: true,
            data: data
        });
    } catch (error) {
        console.error('Erreur dashboard:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors du chargement du dashboard'
        });
    }
});

// Liste enrichie des demandes niveau 2 - DONNÉES ODOO RÉELLES
app.get('/api/mobile/level2/requests', async (req, res) => {
    try {
        console.log('🎯 Chargement demandes niveau 2 avec données Odoo réelles...');
        
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const filter = req.query.filter || 'all';
        const offset = (page - 1) * limit;
        
        let requests, totalCount, filters;
        let dataSource = 'fallback';
        let error = null;
        
        try {
            // Tentative de récupération des données Odoo réelles
            const filterObj = filter !== 'all' ? { state: filter } : {};
            
            [requests, totalCount] = await Promise.all([
                odooConnector.getInformationRequests(filterObj, limit, offset),
                odooConnector.execute('request.information', 'search_count', [[]])
            ]);
            
            // Calcul des filtres
            const [submitted, inProgress, responded, refused] = await Promise.all([
                odooConnector.execute('request.information', 'search_count', [['state', '=', 'submitted']]),
                odooConnector.execute('request.information', 'search_count', [['state', '=', 'in_progress']]),
                odooConnector.execute('request.information', 'search_count', [['state', '=', 'responded']]),
                odooConnector.execute('request.information', 'search_count', [['state', '=', 'refused']])
            ]);
            
            filters = {
                all: totalCount,
                submitted: submitted,
                in_progress: inProgress,
                responded: responded,
                refused: refused
            };
            
            dataSource = 'odoo';
            console.log(`✅ ${requests.length} demandes Odoo récupérées avec succès`);
            
        } catch (odooError) {
            console.error('❌ Erreur récupération demandes Odoo, utilisation fallback:', odooError);
            error = odooError.message;
            
            // Fallback vers données simulées
            let fallbackRequests = enrichedDatabase.informationRequests;
            
            if (filter !== 'all') {
                fallbackRequests = fallbackRequests.filter(r => r.state === filter);
            }
            
            const startIndex = (page - 1) * limit;
            const endIndex = startIndex + limit;
            requests = fallbackRequests.slice(startIndex, endIndex);
            totalCount = enrichedDatabase.informationRequests.length;
            
            filters = {
                all: enrichedDatabase.informationRequests.length,
                submitted: enrichedDatabase.informationRequests.filter(r => r.state === 'submitted').length,
                in_progress: enrichedDatabase.informationRequests.filter(r => r.state === 'in_progress').length,
                responded: enrichedDatabase.informationRequests.filter(r => r.state === 'responded').length,
                refused: enrichedDatabase.informationRequests.filter(r => r.state === 'refused').length
            };
            
            dataSource = 'fallback';
        }
        
        res.json({
            success: true,
            data: {
                requests: requests,
                pagination: {
                    page: page,
                    limit: limit,
                    total: totalCount,
                    has_more: (page * limit) < totalCount
                },
                filters: filters,
                data_source: dataSource,
                error: error
            }
        });
    } catch (error) {
        console.error('Erreur requests:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors du chargement des demandes'
        });
    }
});

// Liste enrichie des alertes niveau 2 - DONNÉES ODOO RÉELLES
app.get('/api/mobile/level2/alerts', async (req, res) => {
    try {
        console.log('🎯 Chargement alertes niveau 2 avec données Odoo réelles...');
        
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const filter = req.query.filter || 'all';
        const offset = (page - 1) * limit;
        
        let alerts, totalCount, filters;
        let dataSource = 'fallback';
        let error = null;
        
        try {
            // Tentative de récupération des données Odoo réelles
            const filterObj = filter !== 'all' ? { state: filter } : {};
            
            [alerts, totalCount] = await Promise.all([
                odooConnector.getWhistleblowingAlerts(filterObj, limit, offset),
                odooConnector.execute('whistleblowing.alert', 'search_count', [[]])
            ]);
            
            // Calcul des filtres
            const [newAlerts, investigation, resolved] = await Promise.all([
                odooConnector.execute('whistleblowing.alert', 'search_count', [['state', '=', 'new']]),
                odooConnector.execute('whistleblowing.alert', 'search_count', [['state', '=', 'investigation']]),
                odooConnector.execute('whistleblowing.alert', 'search_count', [['state', '=', 'resolved']])
            ]);
            
            filters = {
                all: totalCount,
                new: newAlerts,
                investigation: investigation,
                resolved: resolved
            };
            
            dataSource = 'odoo';
            console.log(`✅ ${alerts.length} alertes Odoo récupérées avec succès`);
            
        } catch (odooError) {
            console.error('❌ Erreur récupération alertes Odoo, utilisation fallback:', odooError);
            error = odooError.message;
            
            // Fallback vers données simulées
            let fallbackAlerts = enrichedDatabase.whistleblowingAlerts;
            
            if (filter !== 'all') {
                fallbackAlerts = fallbackAlerts.filter(a => a.state === filter);
            }
            
            const startIndex = (page - 1) * limit;
            const endIndex = startIndex + limit;
            alerts = fallbackAlerts.slice(startIndex, endIndex);
            totalCount = enrichedDatabase.whistleblowingAlerts.length;
            
            filters = {
                all: enrichedDatabase.whistleblowingAlerts.length,
                new: enrichedDatabase.whistleblowingAlerts.filter(a => a.state === 'new').length,
                investigation: enrichedDatabase.whistleblowingAlerts.filter(a => a.state === 'investigation').length,
                resolved: enrichedDatabase.whistleblowingAlerts.filter(a => a.state === 'resolved').length
            };
            
            dataSource = 'fallback';
        }
        
        res.json({
            success: true,
            data: {
                alerts: alerts,
                pagination: {
                    page: page,
                    limit: limit,
                    total: totalCount,
                    has_more: (page * limit) < totalCount
                },
                filters: filters,
                data_source: dataSource,
                error: error
            }
        });
    } catch (error) {
        console.error('Erreur alerts:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors du chargement des alertes'
        });
    }
});

// Détail enrichi demande niveau 3
app.get('/api/mobile/level3/request/:id', (req, res) => {
    try {
        const requestId = parseInt(req.params.id);
        const request = enrichedDatabase.informationRequests.find(r => r.id === requestId);
        
        if (!request) {
            return res.status(404).json({
                success: false,
                error: 'Demande non trouvée'
            });
        }
        
        // Enrichir avec URL Odoo
        const enrichedRequest = {
            ...request,
            odoo_url: `/web#id=${requestId}&model=request.information&view_type=form`,
            statistics: {
                similar_requests: 3,
                avg_response_time: 15,
                requester_history: 2
            }
        };
        
        res.json({
            success: true,
            data: enrichedRequest
        });
    } catch (error) {
        console.error('Erreur request detail:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors du chargement du détail'
        });
    }
});

// Détail enrichi alerte niveau 3
app.get('/api/mobile/level3/alert/:id', (req, res) => {
    try {
        const alertId = parseInt(req.params.id);
        const alert = enrichedDatabase.whistleblowingAlerts.find(a => a.id === alertId);
        
        if (!alert) {
            return res.status(404).json({
                success: false,
                error: 'Alerte non trouvée'
            });
        }
        
        // Enrichir avec URL Odoo
        const enrichedAlert = {
            ...alert,
            odoo_url: `/web#id=${alertId}&model=whistleblowing.alert&view_type=form`,
            statistics: {
                similar_alerts: 2,
                category_total: 8,
                resolution_rate: 75
            }
        };
        
        res.json({
            success: true,
            data: enrichedAlert
        });
    } catch (error) {
        console.error('Erreur alert detail:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors du chargement du détail'
        });
    }
});

// API Analytics enrichie
app.get('/api/mobile/analytics', (req, res) => {
    try {
        res.json({
            success: true,
            data: {
                statistics: enrichedDatabase.statistics,
                dashboard: enrichedDatabase.dashboard,
                trends: {
                    weekly: {
                        requests: [3, 5, 2, 7, 4, 6, 8],
                        alerts: [1, 2, 0, 3, 1, 2, 4],
                        days: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                    },
                    performance: {
                        response_time: [20, 18, 15, 17, 16, 14, 18.5],
                        satisfaction: [85, 87, 89, 86, 88, 90, 87.3],
                        months: ['Sep', 'Oct', 'Nov', 'Déc', 'Jan', 'Fév', 'Mar']
                    }
                }
            }
        });
    } catch (error) {
        console.error('Erreur analytics:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors du chargement des analytics'
        });
    }
});

// API Notifications
app.get('/api/mobile/notifications', (req, res) => {
    try {
        res.json({
            success: true,
            data: {
                notifications: enrichedDatabase.notifications,
                unread_count: enrichedDatabase.notifications.filter(n => !n.read).length
            }
        });
    } catch (error) {
        console.error('Erreur notifications:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors du chargement des notifications'
        });
    }
});

// Marquer notification comme lue
app.post('/api/mobile/notifications/:id/read', (req, res) => {
    try {
        const notificationId = parseInt(req.params.id);
        const notification = enrichedDatabase.notifications.find(n => n.id === notificationId);
        
        if (notification) {
            notification.read = true;
        }
        
        res.json({
            success: true,
            data: { message: 'Notification marquée comme lue' }
        });
    } catch (error) {
        console.error('Erreur mark read:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la mise à jour'
        });
    }
});

// Logout
app.post('/api/mobile/auth/logout', (req, res) => {
    res.json({
        success: true,
        data: { message: 'Déconnexion réussie' }
    });
});

// ========================================= //
// DÉMARRAGE DU SERVEUR                      //
// ========================================= //

app.listen(PORT, async () => {
    console.log(`🇸🇳 SAMA CONAI - Serveur Odoo Réel démarré sur le port ${PORT}`);
    console.log(`📱 Interface Odoo réelle: http://localhost:${PORT}/`);
    console.log(`🔗 Test connexion Odoo: http://localhost:${PORT}/api/odoo/test`);
    console.log(`📊 Comparaison avec version simulée: http://localhost:3007/enriched`);
    
    // Test initial de connexion Odoo
    console.log('\n🔍 Test initial de connexion Odoo...');
    try {
        const testResult = await odooConnector.testConnection();
        if (testResult.success) {
            console.log('✅ Connexion Odoo établie avec succès!');
            console.log(`📋 Version Odoo: ${JSON.stringify(testResult.version)}`);
            
            // Test des modèles SAMA CONAI
            console.log('\n🔍 Test des modèles SAMA CONAI...');
            try {
                const requestCount = await odooConnector.execute('request.information', 'search_count', [[]]);
                const alertCount = await odooConnector.execute('whistleblowing.alert', 'search_count', [[]]);
                console.log(`✅ Modèle request.information: ${requestCount} enregistrement(s)`);
                console.log(`✅ Modèle whistleblowing.alert: ${alertCount} enregistrement(s)`);
                console.log('🎯 Modèles SAMA CONAI prêts pour utilisation!');
            } catch (modelError) {
                console.log('⚠️ Modèles SAMA CONAI non trouvés, mode fallback activé');
                console.log(`❌ Erreur modèles: ${modelError.message}`);
            }
        } else {
            console.log('⚠️ Connexion Odoo échouée, mode fallback activé');
            console.log(`❌ Erreur: ${testResult.error}`);
        }
    } catch (error) {
        console.log('⚠️ Test connexion Odoo échoué, mode fallback activé');
        console.log(`❌ Erreur: ${error.message}`);
    }
    
    console.log('\n🚀 Serveur prêt pour développement progressif!');
});

module.exports = app;