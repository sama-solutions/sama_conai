// Serveur SAMA CONAI UX avec intégration Odoo XML-RPC complète
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

// Import du connecteur Odoo XML-RPC
const OdooXMLRPCConnector = require('./odoo_xmlrpc_connector.js');

const PORT = process.env.PORT || 3004;

// Configuration Odoo
const ODOO_CONFIG = {
    url: process.env.ODOO_URL || 'http://localhost:8077',
    database: process.env.ODOO_DB || 'sama_conai_analytics',
    username: process.env.ODOO_USER || 'admin',
    password: process.env.ODOO_PASSWORD || 'admin'
};

// Instance du connecteur Odoo
let odooConnector = null;
let isOdooConnected = false;

// Données de fallback enrichies (utilisées si Odoo n'est pas disponible)
const FALLBACK_DATA = {
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
        }
    ]
};

// Initialisation du connecteur Odoo
async function initializeOdooConnector() {
    try {
        console.log('🔄 Initialisation du connecteur Odoo XML-RPC...');
        
        odooConnector = new OdooXMLRPCConnector(ODOO_CONFIG);
        isOdooConnected = await odooConnector.authenticate();
        
        if (isOdooConnected) {
            console.log('✅ Connexion Odoo établie avec succès');
        } else {
            console.log('⚠️ Connexion Odoo échouée, utilisation du mode fallback');
        }
    } catch (error) {
        console.error('❌ Erreur initialisation Odoo:', error.message);
        isOdooConnected = false;
    }
}

// Fonction pour servir les fichiers statiques
function serveStaticFile(res, filePath, contentType) {
    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Fichier non trouvé');
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content);
        }
    });
}

// Fonction pour envoyer une réponse JSON
function sendJsonResponse(res, data, statusCode = 200) {
    res.writeHead(statusCode, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    });
    res.end(JSON.stringify(data));
}

// Gestionnaire pour les requêtes OPTIONS (CORS)
function handleCors(res) {
    res.writeHead(200, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    });
    res.end();
}

// API Endpoints

// Authentification
async function handleAuth(req, res) {
    if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const { email, password } = JSON.parse(body);
                
                // Comptes de test
                const testAccounts = {
                    'admin@sama-conai.sn': { password: 'admin123', role: 'admin', name: 'Administrateur SAMA CONAI' },
                    'agent@sama-conai.sn': { password: 'agent123', role: 'agent', name: 'Agent Transparence' },
                    'citoyen@email.com': { password: 'citoyen123', role: 'citizen', name: 'Citoyen Sénégalais' }
                };

                const account = testAccounts[email];
                if (account && account.password === password) {
                    sendJsonResponse(res, {
                        success: true,
                        user: {
                            email: email,
                            name: account.name,
                            role: account.role
                        },
                        token: 'fake-jwt-token-' + Date.now()
                    });
                } else {
                    sendJsonResponse(res, {
                        success: false,
                        message: 'Identifiants incorrects'
                    }, 401);
                }
            } catch (error) {
                sendJsonResponse(res, {
                    success: false,
                    message: 'Erreur de traitement'
                }, 400);
            }
        });
    } else {
        sendJsonResponse(res, { message: 'Méthode non autorisée' }, 405);
    }
}

// Dashboard avec données Odoo ou fallback
async function handleDashboard(req, res) {
    try {
        let dashboardData;
        
        if (isOdooConnected && odooConnector) {
            console.log('📊 Récupération des données dashboard depuis Odoo...');
            dashboardData = await odooConnector.getDashboardStats();
        } else {
            console.log('📊 Utilisation des données de fallback...');
            dashboardData = FALLBACK_DATA;
        }
        
        sendJsonResponse(res, {
            success: true,
            data: dashboardData,
            source: isOdooConnected ? 'odoo' : 'fallback',
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('❌ Erreur dashboard:', error.message);
        sendJsonResponse(res, {
            success: true,
            data: FALLBACK_DATA,
            source: 'fallback',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
}

// Demandes d'information
async function handleRequests(req, res) {
    const urlParts = req.url.split('/');
    const requestId = urlParts[3]; // /api/requests/:id

    try {
        if (requestId && requestId !== '') {
            // Récupérer une demande spécifique
            let requestData;
            
            if (isOdooConnected && odooConnector) {
                console.log(`📄 Récupération de la demande ${requestId} depuis Odoo...`);
                requestData = await odooConnector.getInformationRequest(parseInt(requestId));
            } else {
                // Données de fallback pour une demande spécifique
                requestData = {
                    id: parseInt(requestId),
                    name: `REQ-2024-${requestId.padStart(3, '0')}`,
                    description: 'Demande d\'accès aux documents budgétaires 2024',
                    requester: 'Amadou Diallo',
                    requesterEmail: 'amadou.diallo@email.com',
                    status: 'in_progress',
                    date: '2024-09-05',
                    deadline: '2024-09-20',
                    assignedTo: 'Agent Transparence',
                    department: 'Ministère des Finances',
                    history: [
                        {
                            date: '2024-09-05',
                            action: 'Demande soumise',
                            user: 'Amadou Diallo',
                            comment: 'Demande initiale déposée'
                        }
                    ]
                };
            }
            
            if (requestData) {
                sendJsonResponse(res, {
                    success: true,
                    data: requestData,
                    source: isOdooConnected ? 'odoo' : 'fallback'
                });
            } else {
                sendJsonResponse(res, {
                    success: false,
                    message: 'Demande non trouvée'
                }, 404);
            }
        } else {
            // Récupérer toutes les demandes
            let requestsData;
            
            if (isOdooConnected && odooConnector) {
                console.log('📄 Récupération des demandes depuis Odoo...');
                requestsData = await odooConnector.getInformationRequests({ limit: 50 });
            } else {
                // Données de fallback
                requestsData = {
                    requests: [
                        {
                            id: 1,
                            name: 'REQ-2024-001',
                            description: 'Demande d\'accès aux documents budgétaires 2024',
                            requester: 'Amadou Diallo',
                            status: 'in_progress',
                            date: '2024-09-05'
                        },
                        {
                            id: 2,
                            name: 'REQ-2024-002',
                            description: 'Information sur les marchés publics en cours',
                            requester: 'Fatou Sall',
                            status: 'pending_validation',
                            date: '2024-09-04'
                        }
                    ],
                    pagination: { page: 1, total: 2, pages: 1 }
                };
            }
            
            sendJsonResponse(res, {
                success: true,
                data: requestsData,
                source: isOdooConnected ? 'odoo' : 'fallback'
            });
        }
    } catch (error) {
        console.error('❌ Erreur requests:', error.message);
        sendJsonResponse(res, {
            success: false,
            message: 'Erreur lors de la récupération des demandes',
            error: error.message
        }, 500);
    }
}

// Alertes
async function handleAlerts(req, res) {
    const urlParts = req.url.split('/');
    const alertId = urlParts[3]; // /api/alerts/:id

    try {
        if (alertId && alertId !== '') {
            // Récupérer une alerte spécifique
            let alertData;
            
            if (isOdooConnected && odooConnector) {
                console.log(`🚨 Récupération de l'alerte ${alertId} depuis Odoo...`);
                alertData = await odooConnector.getWhistleblowingAlert(parseInt(alertId));
            } else {
                // Données de fallback pour une alerte spécifique
                alertData = {
                    id: parseInt(alertId),
                    name: `ALERT-2024-${alertId.padStart(3, '0')}`,
                    description: 'Suspicion de détournement de fonds publics',
                    category: 'corruption',
                    priority: 'urgent',
                    status: 'investigation',
                    date: '2024-09-06',
                    assignedTo: 'Enquêteur Principal',
                    reportedBy: 'Anonyme',
                    location: 'Dakar, Sénégal',
                    estimatedAmount: '2.5 milliards FCFA',
                    confidentialityLevel: 'Maximum',
                    evidence: ['Documents photographiés', 'Témoignages audio'],
                    history: [
                        {
                            date: '2024-09-06',
                            action: 'Signalement reçu',
                            user: 'Système',
                            comment: 'Alerte soumise via canal sécurisé'
                        }
                    ]
                };
            }
            
            if (alertData) {
                sendJsonResponse(res, {
                    success: true,
                    data: alertData,
                    source: isOdooConnected ? 'odoo' : 'fallback'
                });
            } else {
                sendJsonResponse(res, {
                    success: false,
                    message: 'Alerte non trouvée'
                }, 404);
            }
        } else {
            // Récupérer toutes les alertes
            let alertsData;
            
            if (isOdooConnected && odooConnector) {
                console.log('🚨 Récupération des alertes depuis Odoo...');
                alertsData = await odooConnector.getWhistleblowingAlerts({ limit: 50 });
            } else {
                // Données de fallback
                alertsData = {
                    alerts: [
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
                        }
                    ],
                    pagination: { page: 1, total: 2, pages: 1 }
                };
            }
            
            sendJsonResponse(res, {
                success: true,
                data: alertsData,
                source: isOdooConnected ? 'odoo' : 'fallback'
            });
        }
    } catch (error) {
        console.error('❌ Erreur alerts:', error.message);
        sendJsonResponse(res, {
            success: false,
            message: 'Erreur lors de la récupération des alertes',
            error: error.message
        }, 500);
    }
}

// Test de connexion Odoo
async function handleTestOdoo(req, res) {
    try {
        if (isOdooConnected && odooConnector) {
            // Test de connexion en récupérant quelques données
            const testCount = await odooConnector.searchCount('request.information');
            sendJsonResponse(res, {
                success: true,
                connected: true,
                message: 'Connexion Odoo active',
                config: {
                    url: ODOO_CONFIG.url,
                    database: ODOO_CONFIG.database,
                    user: ODOO_CONFIG.username
                },
                testData: {
                    requestCount: testCount
                }
            });
        } else {
            sendJsonResponse(res, {
                success: false,
                connected: false,
                message: 'Connexion Odoo non disponible',
                config: {
                    url: ODOO_CONFIG.url,
                    database: ODOO_CONFIG.database,
                    user: ODOO_CONFIG.username
                }
            });
        }
    } catch (error) {
        sendJsonResponse(res, {
            success: false,
            connected: false,
            message: 'Erreur de test Odoo',
            error: error.message
        });
    }
}

// Serveur HTTP principal
async function startServer() {
    // Initialiser la connexion Odoo
    await initializeOdooConnector();
    
    const server = http.createServer((req, res) => {
        const parsedUrl = url.parse(req.url, true);
        const pathname = parsedUrl.pathname;

        // Gestion CORS
        if (req.method === 'OPTIONS') {
            handleCors(res);
            return;
        }

        // Routes API
        if (pathname.startsWith('/api/')) {
            if (pathname === '/api/auth/login') {
                handleAuth(req, res);
            } else if (pathname === '/api/dashboard') {
                handleDashboard(req, res);
            } else if (pathname.startsWith('/api/requests')) {
                handleRequests(req, res);
            } else if (pathname.startsWith('/api/alerts')) {
                handleAlerts(req, res);
            } else if (pathname === '/api/test-odoo') {
                handleTestOdoo(req, res);
            } else {
                sendJsonResponse(res, { message: 'Endpoint non trouvé' }, 404);
            }
            return;
        }

        // Fichiers statiques
        let filePath = path.join(__dirname, 'public', pathname === '/' ? 'index.html' : pathname);
        
        // Déterminer le type de contenu
        const ext = path.extname(filePath);
        let contentType = 'text/html';
        
        switch (ext) {
            case '.css': contentType = 'text/css'; break;
            case '.js': contentType = 'application/javascript'; break;
            case '.json': contentType = 'application/json'; break;
            case '.png': contentType = 'image/png'; break;
            case '.jpg': contentType = 'image/jpeg'; break;
            case '.svg': contentType = 'image/svg+xml'; break;
        }

        serveStaticFile(res, filePath, contentType);
    });

    server.listen(PORT, () => {
        console.log('\n🎨 SAMA CONAI UX RÉVOLUTIONNAIRE v6.0 - SERVEUR AVEC INTÉGRATION ODOO COMPLÈTE');
        console.log('='.repeat(80));
        console.log('');
        console.log('🌐 URL: http://localhost:' + PORT);
        console.log('🎯 Design: UX Inspiré des Meilleurs Designs');
        console.log('📱 Interface: Mobile-First Révolutionnaire avec Drilldown');
        console.log('✨ Animations: Micro-interactions Fluides');
        console.log('🎨 Thème: Design System Moderne');
        console.log('🚀 Performance: Optimisée pour Mobile');
        console.log(`📊 Données: ${isOdooConnected ? '✅ ODOO CONNECTÉ' : '⚠️ FALLBACK MODE'}`);
        console.log('');
        console.log('🔧 CONFIGURATION ODOO:');
        console.log(`   🌐 URL: ${ODOO_CONFIG.url}`);
        console.log(`   🗄️ Base: ${ODOO_CONFIG.database}`);
        console.log(`   👤 User: ${ODOO_CONFIG.username}`);
        console.log(`   🔗 Status: ${isOdooConnected ? 'CONNECTÉ' : 'DÉCONNECTÉ'}`);
        console.log('');
        console.log('🔑 COMPTES DE TEST:');
        console.log('   👑 Admin: admin@sama-conai.sn / admin123');
        console.log('   🛡️ Agent: agent@sama-conai.sn / agent123');
        console.log('   👤 Citoyen: citoyen@email.com / citoyen123');
        console.log('');
        console.log('🎉 FONCTIONNALITÉS RÉVOLUTIONNAIRES:');
        console.log('   ✨ Glassmorphism et Neumorphism');
        console.log('   🎭 Micro-interactions avancées');
        console.log('   🌊 Animations fluides 60fps');
        console.log('   🎨 Design system sophistiqué');
        console.log('   📱 Navigation gestuelle avec drilldown');
        console.log('   🌙 Mode sombre élégant');
        console.log('   🎯 Transitions seamless');
        console.log(`   📊 ${isOdooConnected ? 'Données Odoo réelles' : 'Données simulées enrichies'}`);
        console.log('   🔍 Détails complets avec historique');
        console.log('');
        console.log('📊 API ENDPOINTS DISPONIBLES:');
        console.log('   🔐 POST /api/auth/login - Authentification');
        console.log(`   📊 GET /api/dashboard - Dashboard ${isOdooConnected ? 'Odoo' : 'fallback'}`);
        console.log(`   📄 GET /api/requests - Liste des demandes ${isOdooConnected ? 'Odoo' : 'fallback'}`);
        console.log(`   📄 GET /api/requests/:id - Détail d'une demande ${isOdooConnected ? 'Odoo' : 'fallback'}`);
        console.log(`   🚨 GET /api/alerts - Liste des alertes ${isOdooConnected ? 'Odoo' : 'fallback'}`);
        console.log(`   🚨 GET /api/alerts/:id - Détail d'une alerte ${isOdooConnected ? 'Odoo' : 'fallback'}`);
        console.log('   🔧 GET /api/test-odoo - Test de connexion Odoo');
        console.log('');
        console.log(`🚀 SERVEUR AVEC INTÉGRATION ODOO ${isOdooConnected ? 'COMPLÈTE' : 'EN MODE FALLBACK'} !`);
        console.log('        ');
    });

    // Gestion de l'arrêt propre
    process.on('SIGINT', () => {
        console.log('\n👋 Arrêt du serveur SAMA CONAI UX...');
        server.close(() => {
            console.log('✅ Serveur arrêté proprement');
            process.exit(0);
        });
    });
}

// Démarrage du serveur
startServer().catch(error => {
    console.error('❌ Erreur démarrage serveur:', error);
    process.exit(1);
});