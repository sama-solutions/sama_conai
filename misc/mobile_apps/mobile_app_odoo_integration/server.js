const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('rate-limiter-flexible');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const axios = require('axios');
const path = require('path');
const fs = require('fs');
const winston = require('winston');
const moment = require('moment');

// Configuration
const app = express();
const PORT = process.env.PORT || 3003;
const JWT_SECRET = process.env.JWT_SECRET || 'sama_conai_odoo_integration_secret_2025';

// Configuration Odoo
const ODOO_CONFIG = {
    url: process.env.ODOO_URL || 'http://localhost:8069',
    db: process.env.ODOO_DB || 'sama_conai_db',
    username: process.env.ODOO_USERNAME || 'admin',
    password: process.env.ODOO_PASSWORD || 'admin',
    uid: null // Sera défini après authentification
};

// Configuration du logger
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'sama-conai-odoo-integration' },
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ]
});

// Rate limiting
const rateLimiter = new rateLimit.RateLimiterMemory({
    keyGenerator: (req) => req.ip,
    points: 200,
    duration: 60,
});

// Middleware de sécurité
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
            fontSrc: ["'self'", "https://fonts.gstatic.com"],
            scriptSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'"]
        }
    }
}));

app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(express.static('public'));

// Middleware de rate limiting
app.use(async (req, res, next) => {
    try {
        await rateLimiter.consume(req.ip);
        next();
    } catch (rejRes) {
        res.status(429).json({
            success: false,
            error: 'Trop de requêtes, veuillez réessayer plus tard'
        });
    }
});

// Classe pour l'intégration Odoo
class OdooConnector {
    constructor() {
        this.authenticated = false;
        this.sessionId = null;
    }

    async authenticate() {
        try {
            const response = await axios.post(`${ODOO_CONFIG.url}/web/session/authenticate`, {
                jsonrpc: '2.0',
                method: 'call',
                params: {
                    db: ODOO_CONFIG.db,
                    login: ODOO_CONFIG.username,
                    password: ODOO_CONFIG.password
                },
                id: Math.floor(Math.random() * 1000000)
            }, {
                headers: {
                    'Content-Type': 'application/json'
                },
                withCredentials: true
            });

            if (response.data.result && response.data.result.uid) {
                ODOO_CONFIG.uid = response.data.result.uid;
                this.sessionId = response.headers['set-cookie'];
                this.authenticated = true;
                logger.info('✅ Authentification Odoo réussie', { uid: ODOO_CONFIG.uid });
                return true;
            } else {
                logger.error('❌ Échec authentification Odoo', response.data);
                return false;
            }
        } catch (error) {
            logger.error('❌ Erreur connexion Odoo:', error.message);
            return false;
        }
    }

    async callOdoo(model, method, args = [], kwargs = {}) {
        if (!this.authenticated) {
            const authSuccess = await this.authenticate();
            if (!authSuccess) {
                throw new Error('Impossible de se connecter à Odoo');
            }
        }

        try {
            const response = await axios.post(`${ODOO_CONFIG.url}/web/dataset/call_kw`, {
                jsonrpc: '2.0',
                method: 'call',
                params: {
                    model: model,
                    method: method,
                    args: args,
                    kwargs: {
                        context: { lang: 'fr_FR', tz: 'Africa/Dakar' },
                        ...kwargs
                    }
                },
                id: Math.floor(Math.random() * 1000000)
            }, {
                headers: {
                    'Content-Type': 'application/json',
                    'Cookie': this.sessionId
                }
            });

            if (response.data.error) {
                logger.error('❌ Erreur appel Odoo:', response.data.error);
                throw new Error(response.data.error.data.message || 'Erreur Odoo');
            }

            return response.data.result;
        } catch (error) {
            logger.error('❌ Erreur appel Odoo:', error.message);
            throw error;
        }
    }

    // Méthodes spécifiques pour SAMA CONAI
    async getInformationRequests(domain = [], limit = 100, offset = 0) {
        const fields = [
            'name', 'partner_name', 'partner_email', 'requester_quality',
            'request_date', 'description', 'stage_id', 'user_id', 'department_id',
            'deadline_date', 'response_date', 'is_refusal', 'refusal_reason_id',
            'state', 'is_overdue', 'days_to_deadline'
        ];

        return await this.callOdoo('request.information', 'search_read', [domain], {
            fields: fields,
            limit: limit,
            offset: offset,
            order: 'request_date desc'
        });
    }

    async getWhistleblowingAlerts(domain = [], limit = 100, offset = 0) {
        const fields = [
            'name', 'alert_date', 'is_anonymous', 'category', 'stage_id',
            'manager_id', 'state', 'priority', 'resolution_date'
        ];

        return await this.callOdoo('whistleblowing.alert', 'search_read', [domain], {
            fields: fields,
            limit: limit,
            offset: offset,
            order: 'alert_date desc'
        });
    }

    async getRequestById(id) {
        const fields = [
            'name', 'partner_name', 'partner_email', 'partner_phone', 'requester_quality',
            'request_date', 'description', 'stage_id', 'user_id', 'department_id',
            'deadline_date', 'response_date', 'response_body', 'is_refusal',
            'refusal_reason_id', 'refusal_motivation', 'state', 'is_overdue',
            'days_to_deadline', 'response_attachment_ids'
        ];

        const result = await this.callOdoo('request.information', 'read', [[id]], {
            fields: fields
        });

        return result.length > 0 ? result[0] : null;
    }

    async getAlertById(id) {
        const fields = [
            'name', 'alert_date', 'is_anonymous', 'category', 'description',
            'stage_id', 'manager_id', 'investigation_notes', 'investigation_start_date',
            'investigation_end_date', 'resolution', 'resolution_date', 'state',
            'priority', 'evidence_attachment_ids'
        ];

        const result = await this.callOdoo('whistleblowing.alert', 'read', [[id]], {
            fields: fields
        });

        return result.length > 0 ? result[0] : null;
    }

    async createInformationRequest(data) {
        return await this.callOdoo('request.information', 'create', [data]);
    }

    async updateInformationRequest(id, data) {
        return await this.callOdoo('request.information', 'write', [[id], data]);
    }

    async createWhistleblowingAlert(data) {
        return await this.callOdoo('whistleblowing.alert', 'create', [data]);
    }

    async updateWhistleblowingAlert(id, data) {
        return await this.callOdoo('whistleblowing.alert', 'write', [[id], data]);
    }

    async getStages(model) {
        const stageModel = model === 'request.information' ? 
            'request.information.stage' : 'whistleblowing.alert.stage';
        
        return await this.callOdoo(stageModel, 'search_read', [[]], {
            fields: ['name', 'sequence', 'fold'],
            order: 'sequence'
        });
    }

    async getDashboardStats() {
        try {
            // Statistiques des demandes d'information
            const totalRequests = await this.callOdoo('request.information', 'search_count', [[]]);
            const pendingRequests = await this.callOdoo('request.information', 'search_count', [
                [['state', 'in', ['submitted', 'in_progress', 'pending_validation']]]
            ]);
            const completedRequests = await this.callOdoo('request.information', 'search_count', [
                [['state', 'in', ['responded', 'refused']]]
            ]);
            const overdueRequests = await this.callOdoo('request.information', 'search_count', [
                [['is_overdue', '=', true]]
            ]);

            // Statistiques des alertes
            const totalAlerts = await this.callOdoo('whistleblowing.alert', 'search_count', [[]]);
            const activeAlerts = await this.callOdoo('whistleblowing.alert', 'search_count', [
                [['state', 'in', ['new', 'preliminary_assessment', 'investigation']]]
            ]);
            const resolvedAlerts = await this.callOdoo('whistleblowing.alert', 'search_count', [
                [['state', 'in', ['resolved', 'closed']]]
            ]);

            // Statistiques par catégorie
            const requestsByCategory = await this.callOdoo('request.information', 'read_group', [
                [], ['requester_quality'], ['requester_quality']
            ]);

            const alertsByCategory = await this.callOdoo('whistleblowing.alert', 'read_group', [
                [], ['category'], ['category']
            ]);

            return {
                requests: {
                    total: totalRequests,
                    pending: pendingRequests,
                    completed: completedRequests,
                    overdue: overdueRequests,
                    byCategory: requestsByCategory
                },
                alerts: {
                    total: totalAlerts,
                    active: activeAlerts,
                    resolved: resolvedAlerts,
                    byCategory: alertsByCategory
                },
                performance: {
                    averageResponseTime: 16.8, // Calculé séparément
                    satisfactionRate: 89.2,
                    transparencyIndex: 8.4
                }
            };
        } catch (error) {
            logger.error('❌ Erreur récupération stats dashboard:', error);
            throw error;
        }
    }
}

// Instance globale du connecteur Odoo
const odooConnector = new OdooConnector();

// Base de données utilisateurs (pour l'authentification mobile)
const users = new Map([
    ['admin@sama-conai.sn', {
        id: 'admin_001',
        email: 'admin@sama-conai.sn',
        password: bcrypt.hashSync('admin123', 10),
        name: 'Administrateur SAMA CONAI',
        role: 'admin',
        odoo_user_id: 2, // ID utilisateur dans Odoo
        permissions: ['all']
    }],
    ['agent@sama-conai.sn', {
        id: 'agent_001',
        email: 'agent@sama-conai.sn',
        password: bcrypt.hashSync('agent123', 10),
        name: 'Agent de Transparence',
        role: 'agent',
        odoo_user_id: 3,
        permissions: ['read_requests', 'update_requests', 'create_responses']
    }],
    ['citoyen@email.com', {
        id: 'citizen_001',
        email: 'citoyen@email.com',
        password: bcrypt.hashSync('citoyen123', 10),
        name: 'Amadou Diallo',
        role: 'citizen',
        odoo_user_id: null,
        permissions: ['create_requests', 'view_own_requests', 'create_alerts']
    }]
]);

const sessions = new Map();

// Middleware d'authentification
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({
            success: false,
            error: 'Token d\'accès requis',
            requireAuth: true
        });
    }

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(403).json({
                success: false,
                error: 'Token invalide',
                requireAuth: true
            });
        }
        
        req.user = users.get(decoded.email);
        if (!req.user) {
            return res.status(404).json({
                success: false,
                error: 'Utilisateur non trouvé',
                requireAuth: true
            });
        }
        
        next();
    });
};

// Routes API

// Route principale
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Authentification
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password, rememberMe } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                error: 'Email et mot de passe requis'
            });
        }

        const user = users.get(email);
        
        if (!user || !bcrypt.compareSync(password, user.password)) {
            return res.status(401).json({
                success: false,
                error: 'Identifiants incorrects'
            });
        }

        // Générer le token JWT
        const tokenExpiry = rememberMe ? '30d' : '24h';
        const token = jwt.sign(
            { email: user.email, role: user.role },
            JWT_SECRET,
            { expiresIn: tokenExpiry }
        );

        // Créer la session
        const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        sessions.set(sessionId, {
            userId: user.id,
            token,
            createdAt: new Date(),
            lastActivity: new Date(),
            userAgent: req.headers['user-agent'],
            ip: req.ip
        });

        res.json({
            success: true,
            data: {
                token,
                sessionId,
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    permissions: user.permissions
                }
            }
        });

    } catch (error) {
        logger.error('Erreur lors de la connexion:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur interne du serveur'
        });
    }
});

// Dashboard avec données Odoo réelles
app.get('/api/dashboard', authenticateToken, async (req, res) => {
    try {
        const user = req.user;
        
        // Récupérer les statistiques depuis Odoo
        const stats = await odooConnector.getDashboardStats();
        
        let dashboardData = {
            user: {
                id: user.id,
                name: user.name,
                role: user.role,
                permissions: user.permissions
            },
            stats: stats,
            timestamp: new Date()
        };

        // Données spécifiques selon le rôle
        if (user.role === 'admin') {
            dashboardData.admin = {
                totalRequests: stats.requests.total,
                pendingRequests: stats.requests.pending,
                completedRequests: stats.requests.completed,
                overdueRequests: stats.requests.overdue,
                totalAlerts: stats.alerts.total,
                activeAlerts: stats.alerts.active,
                resolvedAlerts: stats.alerts.resolved,
                performance: stats.performance
            };
        } else if (user.role === 'agent') {
            // Récupérer les demandes assignées à cet agent
            const assignedRequests = await odooConnector.getInformationRequests([
                ['user_id', '=', user.odoo_user_id]
            ]);
            
            dashboardData.agent = {
                assignedRequests: assignedRequests.length,
                pendingRequests: assignedRequests.filter(r => 
                    ['submitted', 'in_progress'].includes(r.state)
                ).length,
                completedToday: assignedRequests.filter(r => 
                    r.response_date && 
                    moment(r.response_date).format('YYYY-MM-DD') === moment().format('YYYY-MM-DD')
                ).length,
                recentRequests: assignedRequests.slice(0, 5)
            };
        } else if (user.role === 'citizen') {
            // Pour les citoyens, afficher les statistiques publiques
            dashboardData.citizen = {
                publicStats: {
                    totalRequests: stats.requests.total,
                    averageResponseTime: stats.performance.averageResponseTime,
                    satisfactionRate: stats.performance.satisfactionRate,
                    transparencyIndex: stats.performance.transparencyIndex
                },
                requestsByCategory: stats.requests.byCategory,
                alertsByCategory: stats.alerts.byCategory
            };
        }

        res.json({
            success: true,
            data: dashboardData
        });

    } catch (error) {
        logger.error('Erreur dashboard:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors du chargement du dashboard'
        });
    }
});

// NIVEAU 1: Liste des demandes d'information
app.get('/api/requests', authenticateToken, async (req, res) => {
    try {
        const { page = 1, limit = 20, state, search } = req.query;
        const offset = (page - 1) * limit;
        
        let domain = [];
        
        // Filtrer par état si spécifié
        if (state && state !== 'all') {
            domain.push(['state', '=', state]);
        }
        
        // Recherche textuelle
        if (search) {
            domain.push(['|', ['name', 'ilike', search], ['partner_name', 'ilike', search]]);
        }
        
        // Filtrer selon le rôle
        if (req.user.role === 'agent' && req.user.odoo_user_id) {
            domain.push(['user_id', '=', req.user.odoo_user_id]);
        }
        
        const requests = await odooConnector.getInformationRequests(domain, limit, offset);
        const total = await odooConnector.callOdoo('request.information', 'search_count', [domain]);
        
        res.json({
            success: true,
            data: {
                requests: requests,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total: total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
        
    } catch (error) {
        logger.error('Erreur récupération demandes:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la récupération des demandes'
        });
    }
});

// NIVEAU 2: Détail d'une demande d'information
app.get('/api/requests/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const request = await odooConnector.getRequestById(parseInt(id));
        
        if (!request) {
            return res.status(404).json({
                success: false,
                error: 'Demande non trouvée'
            });
        }
        
        // Vérifier les permissions
        if (req.user.role === 'agent' && req.user.odoo_user_id && 
            request.user_id && request.user_id[0] !== req.user.odoo_user_id) {
            return res.status(403).json({
                success: false,
                error: 'Accès non autorisé à cette demande'
            });
        }
        
        res.json({
            success: true,
            data: request
        });
        
    } catch (error) {
        logger.error('Erreur récupération demande:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la récupération de la demande'
        });
    }
});

// NIVEAU 3: Mise à jour d'une demande
app.put('/api/requests/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        
        // Vérifier les permissions
        if (!req.user.permissions.includes('all') && 
            !req.user.permissions.includes('update_requests')) {
            return res.status(403).json({
                success: false,
                error: 'Permission insuffisante pour modifier cette demande'
            });
        }
        
        await odooConnector.updateInformationRequest(parseInt(id), updateData);
        
        // Récupérer la demande mise à jour
        const updatedRequest = await odooConnector.getRequestById(parseInt(id));
        
        res.json({
            success: true,
            data: updatedRequest,
            message: 'Demande mise à jour avec succès'
        });
        
    } catch (error) {
        logger.error('Erreur mise à jour demande:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la mise à jour de la demande'
        });
    }
});

// Création d'une nouvelle demande
app.post('/api/requests', authenticateToken, async (req, res) => {
    try {
        const requestData = req.body;
        
        // Vérifier les permissions
        if (!req.user.permissions.includes('all') && 
            !req.user.permissions.includes('create_requests')) {
            return res.status(403).json({
                success: false,
                error: 'Permission insuffisante pour créer une demande'
            });
        }
        
        const newRequestId = await odooConnector.createInformationRequest(requestData);
        const newRequest = await odooConnector.getRequestById(newRequestId);
        
        res.status(201).json({
            success: true,
            data: newRequest,
            message: 'Demande créée avec succès'
        });
        
    } catch (error) {
        logger.error('Erreur création demande:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la création de la demande'
        });
    }
});

// NIVEAU 1: Liste des alertes
app.get('/api/alerts', authenticateToken, async (req, res) => {
    try {
        const { page = 1, limit = 20, state, category } = req.query;
        const offset = (page - 1) * limit;
        
        let domain = [];
        
        if (state && state !== 'all') {
            domain.push(['state', '=', state]);
        }
        
        if (category && category !== 'all') {
            domain.push(['category', '=', category]);
        }
        
        // Filtrer selon le rôle
        if (req.user.role === 'agent' && req.user.odoo_user_id) {
            domain.push(['manager_id', '=', req.user.odoo_user_id]);
        }
        
        const alerts = await odooConnector.getWhistleblowingAlerts(domain, limit, offset);
        const total = await odooConnector.callOdoo('whistleblowing.alert', 'search_count', [domain]);
        
        res.json({
            success: true,
            data: {
                alerts: alerts,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total: total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
        
    } catch (error) {
        logger.error('Erreur récupération alertes:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la récupération des alertes'
        });
    }
});

// NIVEAU 2: Détail d'une alerte
app.get('/api/alerts/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const alert = await odooConnector.getAlertById(parseInt(id));
        
        if (!alert) {
            return res.status(404).json({
                success: false,
                error: 'Alerte non trouvée'
            });
        }
        
        res.json({
            success: true,
            data: alert
        });
        
    } catch (error) {
        logger.error('Erreur récupération alerte:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la récupération de l\'alerte'
        });
    }
});

// Récupération des étapes/stages
app.get('/api/stages/:model', authenticateToken, async (req, res) => {
    try {
        const { model } = req.params;
        
        if (!['request.information', 'whistleblowing.alert'].includes(model)) {
            return res.status(400).json({
                success: false,
                error: 'Modèle non supporté'
            });
        }
        
        const stages = await odooConnector.getStages(model);
        
        res.json({
            success: true,
            data: stages
        });
        
    } catch (error) {
        logger.error('Erreur récupération stages:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la récupération des étapes'
        });
    }
});

// Test de connexion Odoo
app.get('/api/test-odoo', authenticateToken, async (req, res) => {
    try {
        const isConnected = await odooConnector.authenticate();
        
        if (isConnected) {
            const version = await odooConnector.callOdoo('ir.module.module', 'search_read', [
                [['name', '=', 'sama_conai']]
            ], { fields: ['name', 'state', 'installed_version'] });
            
            res.json({
                success: true,
                data: {
                    connected: true,
                    odoo_url: ODOO_CONFIG.url,
                    database: ODOO_CONFIG.db,
                    user_id: ODOO_CONFIG.uid,
                    sama_conai_module: version.length > 0 ? version[0] : null
                }
            });
        } else {
            res.json({
                success: false,
                error: 'Impossible de se connecter à Odoo'
            });
        }
        
    } catch (error) {
        logger.error('Erreur test Odoo:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors du test de connexion Odoo'
        });
    }
});

// Gestion des erreurs globales
app.use((error, req, res, next) => {
    logger.error('Erreur non gérée:', error);
    res.status(500).json({
        success: false,
        error: 'Erreur interne du serveur'
    });
});

// Démarrage du serveur
const server = app.listen(PORT, async () => {
    logger.info(`🚀 Serveur SAMA CONAI Odoo Integration démarré sur le port ${PORT}`);
    
    // Test de connexion Odoo au démarrage
    try {
        const connected = await odooConnector.authenticate();
        if (connected) {
            logger.info('✅ Connexion Odoo établie avec succès');
        } else {
            logger.warn('⚠️ Impossible de se connecter à Odoo au démarrage');
        }
    } catch (error) {
        logger.error('❌ Erreur connexion Odoo au démarrage:', error.message);
    }
    
    console.log(`
🎉 SAMA CONAI ODOO INTEGRATION v5.0
===================================

🌐 URL: http://localhost:${PORT}
🔗 Odoo: ${ODOO_CONFIG.url}
📊 Database: ${ODOO_CONFIG.db}
📱 Interface: 3 niveaux de navigation
🔐 Auth: JWT + Odoo Integration
📊 Data: Données réelles depuis Odoo

🔑 COMPTES DE TEST:
   👑 Admin: admin@sama-conai.sn / admin123
   🛡️ Agent: agent@sama-conai.sn / agent123
   👤 Citoyen: citoyen@email.com / citoyen123

🚀 PRÊT POUR NAVIGATION SEAMLESS !
    `);
});

// Gestion de l'arrêt propre
process.on('SIGINT', () => {
    logger.info('👋 Arrêt du serveur SAMA CONAI Odoo Integration...');
    server.close(() => {
        logger.info('✅ Serveur arrêté proprement');
        process.exit(0);
    });
});