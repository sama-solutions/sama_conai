// Connecteur Odoo simplifié pour SAMA CONAI
// Version Node.js compatible sans dépendances externes

class OdooConnectorSimple {
    constructor(config = {}) {
        this.config = {
            url: config.url || 'http://localhost:8077',
            database: config.database || 'sama_conai_analytics',
            username: config.username || 'admin',
            password: config.password || 'admin',
            ...config
        };
        this.uid = null;
        this.sessionId = null;
    }

    // Authentification Odoo simplifiée
    async authenticate() {
        try {
            console.log('🔄 Tentative d\'authentification Odoo...');
            
            // Test de connectivité de base
            const testResponse = await fetch(`${this.config.url}/web/database/list`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (testResponse.ok) {
                console.log('✅ Serveur Odoo accessible');
                // Simuler une authentification réussie pour la démo
                this.uid = 1;
                return true;
            } else {
                console.log('⚠️ Serveur Odoo non accessible');
                return false;
            }
        } catch (error) {
            console.error('❌ Erreur authentification Odoo:', error.message);
            return false;
        }
    }

    // Méthodes spécifiques SAMA CONAI avec données simulées enrichies

    // Récupérer les statistiques du dashboard
    async getDashboardStats() {
        try {
            console.log('📊 Récupération des statistiques dashboard...');
            
            // Données simulées enrichies basées sur la structure Odoo
            return {
                stats: {
                    totalRequests: 47,
                    pendingRequests: 12,
                    completedRequests: 35,
                    totalAlerts: 23,
                    activeAlerts: 8,
                    satisfactionRate: 89,
                    averageResponseTime: 16.8
                },
                recentRequests: [
                    {
                        id: 1,
                        name: 'REQ-2024-001',
                        description: 'Demande d\'accès aux documents budgétaires 2024',
                        status: 'in_progress',
                        date: '2024-09-05',
                        requester: 'Amadou Diallo'
                    },
                    {
                        id: 2,
                        name: 'REQ-2024-002',
                        description: 'Information sur les marchés publics en cours',
                        status: 'pending_validation',
                        date: '2024-09-04',
                        requester: 'Fatou Sall'
                    },
                    {
                        id: 3,
                        name: 'REQ-2024-003',
                        description: 'Accès aux rapports d\'audit interne',
                        status: 'responded',
                        date: '2024-09-03',
                        requester: 'Moussa Ba'
                    },
                    {
                        id: 4,
                        name: 'REQ-2024-004',
                        description: 'Documents relatifs aux projets d\'infrastructure',
                        status: 'submitted',
                        date: '2024-09-02',
                        requester: 'Aïcha Ndiaye'
                    },
                    {
                        id: 5,
                        name: 'REQ-2024-005',
                        description: 'Informations sur les subventions accordées',
                        status: 'refused',
                        date: '2024-09-01',
                        requester: 'Ibrahima Sarr'
                    }
                ],
                recentAlerts: [
                    {
                        id: 1,
                        name: 'ALERT-2024-001',
                        description: 'Suspicion de détournement de fonds publics',
                        category: 'corruption',
                        priority: 'urgent',
                        status: 'investigation',
                        date: '2024-09-06'
                    },
                    {
                        id: 2,
                        name: 'ALERT-2024-002',
                        description: 'Irrégularités dans l\'attribution des marchés',
                        category: 'fraud',
                        priority: 'high',
                        status: 'preliminary_assessment',
                        date: '2024-09-05'
                    },
                    {
                        id: 3,
                        name: 'ALERT-2024-003',
                        description: 'Harcèlement au sein d\'une administration',
                        category: 'harassment',
                        priority: 'medium',
                        status: 'resolved',
                        date: '2024-09-04'
                    }
                ]
            };
        } catch (error) {
            console.error('❌ Erreur getDashboardStats:', error);
            throw error;
        }
    }

    // Récupérer toutes les demandes d'information
    async getInformationRequests(options = {}) {
        try {
            console.log('📄 Récupération des demandes d\'information...');
            
            const requests = [
                {
                    id: 1,
                    name: 'REQ-2024-001',
                    description: 'Demande d\'accès aux documents budgétaires 2024 pour analyse de la répartition des fonds publics',
                    requester: 'Amadou Diallo',
                    requesterEmail: 'amadou.diallo@email.com',
                    requesterPhone: '+221 77 123 45 67',
                    requesterQuality: 'Journaliste',
                    status: 'in_progress',
                    date: '2024-09-05',
                    deadline: '2024-09-20',
                    responseDate: null,
                    assignedTo: 'Agent Transparence',
                    department: 'Ministère des Finances',
                    isOverdue: false,
                    daysToDeadline: 13
                },
                {
                    id: 2,
                    name: 'REQ-2024-002',
                    description: 'Information sur les marchés publics en cours et leurs attributaires',
                    requester: 'Fatou Sall',
                    requesterEmail: 'fatou.sall@ong.sn',
                    requesterPhone: '+221 76 987 65 43',
                    requesterQuality: 'Représentante ONG',
                    status: 'pending_validation',
                    date: '2024-09-04',
                    deadline: '2024-09-19',
                    responseDate: null,
                    assignedTo: 'Chef de service',
                    department: 'Direction des Marchés Publics',
                    isOverdue: false,
                    daysToDeadline: 12
                },
                {
                    id: 3,
                    name: 'REQ-2024-003',
                    description: 'Accès aux rapports d\'audit interne des 6 derniers mois',
                    requester: 'Moussa Ba',
                    requesterEmail: 'moussa.ba@universite.sn',
                    requesterPhone: '+221 78 456 78 90',
                    requesterQuality: 'Chercheur universitaire',
                    status: 'responded',
                    date: '2024-09-03',
                    deadline: '2024-09-18',
                    responseDate: '2024-09-06',
                    assignedTo: 'Directeur Audit',
                    department: 'Inspection Générale d\'État',
                    isOverdue: false,
                    daysToDeadline: 11
                },
                {
                    id: 4,
                    name: 'REQ-2024-004',
                    description: 'Documents relatifs aux projets d\'infrastructure routière',
                    requester: 'Aïcha Ndiaye',
                    requesterEmail: 'aicha.ndiaye@citoyen.sn',
                    requesterPhone: '+221 77 234 56 78',
                    requesterQuality: 'Citoyenne',
                    status: 'submitted',
                    date: '2024-09-02',
                    deadline: '2024-09-17',
                    responseDate: null,
                    assignedTo: null,
                    department: 'Ministère des Infrastructures',
                    isOverdue: false,
                    daysToDeadline: 10
                }
            ];

            return {
                requests: requests,
                pagination: {
                    page: 1,
                    limit: options.limit || 100,
                    total: requests.length,
                    pages: 1
                }
            };
        } catch (error) {
            console.error('❌ Erreur getInformationRequests:', error);
            throw error;
        }
    }

    // Récupérer une demande d'information par ID
    async getInformationRequest(id) {
        try {
            console.log(`📄 Récupération de la demande ${id}...`);
            
            const requests = {
                1: {
                    id: 1,
                    name: 'REQ-2024-001',
                    description: 'Demande d\'accès aux documents budgétaires 2024 pour analyse de la répartition des fonds publics dans le cadre d\'une enquête journalistique sur la transparence budgétaire.',
                    requester: 'Amadou Diallo',
                    requesterEmail: 'amadou.diallo@email.com',
                    requesterPhone: '+221 77 123 45 67',
                    requesterQuality: 'Journaliste',
                    status: 'in_progress',
                    date: '2024-09-05',
                    deadline: '2024-09-20',
                    responseDate: null,
                    responseBody: null,
                    assignedTo: 'Agent Transparence',
                    department: 'Ministère des Finances',
                    isRefusal: false,
                    refusalReason: null,
                    refusalMotivation: null,
                    isOverdue: false,
                    daysToDeadline: 13,
                    history: [
                        {
                            date: '2024-09-05',
                            action: 'Demande soumise',
                            user: 'Amadou Diallo',
                            comment: 'Demande initiale déposée via le portail en ligne'
                        },
                        {
                            date: '2024-09-05',
                            action: 'Demande assignée',
                            user: 'Système',
                            comment: 'Assignée automatiquement au service compétent'
                        },
                        {
                            date: '2024-09-06',
                            action: 'En cours de traitement',
                            user: 'Agent Transparence',
                            comment: 'Début de la collecte des documents demandés'
                        }
                    ]
                },
                2: {
                    id: 2,
                    name: 'REQ-2024-002',
                    description: 'Information sur les marchés publics en cours et leurs attributaires pour vérification de la conformité aux procédures.',
                    requester: 'Fatou Sall',
                    requesterEmail: 'fatou.sall@ong.sn',
                    requesterPhone: '+221 76 987 65 43',
                    requesterQuality: 'Représentante ONG',
                    status: 'pending_validation',
                    date: '2024-09-04',
                    deadline: '2024-09-19',
                    responseDate: null,
                    responseBody: null,
                    assignedTo: 'Chef de service',
                    department: 'Direction des Marchés Publics',
                    isRefusal: false,
                    refusalReason: null,
                    refusalMotivation: null,
                    isOverdue: false,
                    daysToDeadline: 12,
                    history: [
                        {
                            date: '2024-09-04',
                            action: 'Demande soumise',
                            user: 'Fatou Sall',
                            comment: 'Demande déposée par courrier officiel'
                        },
                        {
                            date: '2024-09-04',
                            action: 'Demande assignée',
                            user: 'Système',
                            comment: 'Assignée au chef de service pour validation'
                        },
                        {
                            date: '2024-09-05',
                            action: 'En attente de validation',
                            user: 'Chef de service',
                            comment: 'Vérification de la légitimité de la demande'
                        }
                    ]
                }
            };

            return requests[id] || null;
        } catch (error) {
            console.error('❌ Erreur getInformationRequest:', error);
            throw error;
        }
    }

    // Récupérer toutes les alertes
    async getWhistleblowingAlerts(options = {}) {
        try {
            console.log('🚨 Récupération des alertes...');
            
            const alerts = [
                {
                    id: 1,
                    name: 'ALERT-2024-001',
                    description: 'Suspicion de détournement de fonds publics dans un projet d\'infrastructure',
                    category: 'corruption',
                    priority: 'urgent',
                    status: 'investigation',
                    date: '2024-09-06',
                    assignedTo: 'Enquêteur Principal',
                    investigationStartDate: '2024-09-06',
                    investigationEndDate: null,
                    resolutionDate: null
                },
                {
                    id: 2,
                    name: 'ALERT-2024-002',
                    description: 'Irrégularités dans l\'attribution des marchés publics',
                    category: 'fraud',
                    priority: 'high',
                    status: 'preliminary_assessment',
                    date: '2024-09-05',
                    assignedTo: 'Agent d\'évaluation',
                    investigationStartDate: null,
                    investigationEndDate: null,
                    resolutionDate: null
                },
                {
                    id: 3,
                    name: 'ALERT-2024-003',
                    description: 'Harcèlement au sein d\'une administration publique',
                    category: 'harassment',
                    priority: 'medium',
                    status: 'resolved',
                    date: '2024-09-04',
                    assignedTo: 'Médiateur',
                    investigationStartDate: '2024-09-04',
                    investigationEndDate: '2024-09-06',
                    resolutionDate: '2024-09-06'
                }
            ];

            return {
                alerts: alerts,
                pagination: {
                    page: 1,
                    limit: options.limit || 100,
                    total: alerts.length,
                    pages: 1
                }
            };
        } catch (error) {
            console.error('❌ Erreur getWhistleblowingAlerts:', error);
            throw error;
        }
    }

    // Récupérer une alerte par ID
    async getWhistleblowingAlert(id) {
        try {
            console.log(`🚨 Récupération de l'alerte ${id}...`);
            
            const alerts = {
                1: {
                    id: 1,
                    name: 'ALERT-2024-001',
                    description: 'Suspicion de détournement de fonds publics dans un projet d\'infrastructure routière. Montant estimé : 2.5 milliards FCFA.',
                    category: 'corruption',
                    priority: 'urgent',
                    status: 'investigation',
                    date: '2024-09-06',
                    assignedTo: 'Enquêteur Principal',
                    investigationStartDate: '2024-09-06',
                    investigationEndDate: null,
                    investigationNotes: 'Enquête en cours. Plusieurs témoins interrogés. Documents comptables en cours d\'analyse.',
                    resolution: null,
                    resolutionDate: null,
                    reportedBy: 'Anonyme',
                    location: 'Dakar, Sénégal',
                    estimatedAmount: '2.5 milliards FCFA',
                    confidentialityLevel: 'Maximum',
                    evidence: ['Documents photographiés', 'Témoignages audio', 'Correspondances email'],
                    history: [
                        {
                            date: '2024-09-06',
                            action: 'Signalement reçu',
                            user: 'Système',
                            comment: 'Alerte soumise via canal sécurisé'
                        },
                        {
                            date: '2024-09-06',
                            action: 'Évaluation préliminaire',
                            user: 'Agent d\'évaluation',
                            comment: 'Évaluation de la crédibilité du signalement'
                        },
                        {
                            date: '2024-09-06',
                            action: 'Enquête ouverte',
                            user: 'Chef d\'équipe',
                            comment: 'Assignation à l\'équipe spécialisée'
                        }
                    ]
                },
                2: {
                    id: 2,
                    name: 'ALERT-2024-002',
                    description: 'Irrégularités dans l\'attribution des marchés publics. Suspicion de favoritisme et non-respect des procédures.',
                    category: 'fraud',
                    priority: 'high',
                    status: 'preliminary_assessment',
                    date: '2024-09-05',
                    assignedTo: 'Agent d\'évaluation',
                    investigationStartDate: null,
                    investigationEndDate: null,
                    investigationNotes: 'Évaluation préliminaire en cours.',
                    resolution: null,
                    resolutionDate: null,
                    reportedBy: 'Anonyme',
                    location: 'Thiès, Sénégal',
                    estimatedAmount: '800 millions FCFA',
                    confidentialityLevel: 'Élevé',
                    evidence: ['Documents comptables', 'Factures suspectes', 'Rapports financiers'],
                    history: [
                        {
                            date: '2024-09-05',
                            action: 'Signalement reçu',
                            user: 'Système',
                            comment: 'Alerte soumise via formulaire web'
                        },
                        {
                            date: '2024-09-05',
                            action: 'Évaluation préliminaire',
                            user: 'Agent d\'évaluation',
                            comment: 'Début de l\'évaluation du signalement'
                        }
                    ]
                }
            };

            return alerts[id] || null;
        } catch (error) {
            console.error('❌ Erreur getWhistleblowingAlert:', error);
            throw error;
        }
    }
}

// Export pour utilisation
if (typeof module !== 'undefined' && module.exports) {
    module.exports = OdooConnectorSimple;
} else if (typeof window !== 'undefined') {
    window.OdooConnectorSimple = OdooConnectorSimple;
}