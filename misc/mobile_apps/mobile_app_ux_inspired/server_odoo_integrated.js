const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

// Import du connecteur Odoo simplifié
const OdooConnector = require('./odoo_connector_simple.js');

const PORT = process.env.PORT || 3004;

// Configuration Odoo
const ODOO_CONFIG = {
    url: process.env.ODOO_URL || 'http://localhost:8069',
    database: process.env.ODOO_DB || 'sama_conai_db',
    username: process.env.ODOO_USER || 'admin',
    password: process.env.ODOO_PASSWORD || 'admin'
};

// Instance du connecteur Odoo
let odooConnector = null;

// Types MIME
const mimeTypes = {
    '.html': 'text/html',
    '.js': 'text/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.wav': 'audio/wav',
    '.mp4': 'video/mp4',
    '.woff': 'application/font-woff',
    '.ttf': 'application/font-ttf',
    '.eot': 'application/vnd.ms-fontobject',
    '.otf': 'application/font-otf',
    '.wasm': 'application/wasm'
};

// Données de fallback en cas d'échec Odoo
const fallbackData = {
    users: {
        'admin@sama-conai.sn': {
            id: 'admin_001',
            name: 'Administrateur SAMA CONAI',
            email: 'admin@sama-conai.sn',
            role: 'admin',
            password: 'admin123'
        },
        'agent@sama-conai.sn': {
            id: 'agent_001',
            name: 'Agent de Transparence',
            email: 'agent@sama-conai.sn',
            role: 'agent',
            password: 'agent123'
        },
        'citoyen@email.com': {
            id: 'citizen_001',
            name: 'Amadou Diallo',
            email: 'citoyen@email.com',
            role: 'citizen',
            password: 'citoyen123'
        }
    }
};

// Initialisation du connecteur Odoo
async function initializeOdooConnector() {
    try {
        console.log('🔄 Initialisation du connecteur Odoo...');
        odooConnector = new OdooConnector(ODOO_CONFIG);
        
        const authenticated = await odooConnector.authenticate();
        if (authenticated) {
            console.log('✅ Connecteur Odoo initialisé avec succès');
            return true;
        } else {
            console.log('⚠️ Échec authentification Odoo, utilisation des données de fallback');
            return false;
        }
    } catch (error) {
        console.error('❌ Erreur initialisation Odoo:', error.message);
        console.log('⚠️ Utilisation des données de fallback');
        return false;
    }
}

// Fonction pour servir les fichiers statiques
function serveStaticFile(filePath, res) {
    const extname = String(path.extname(filePath)).toLowerCase();
    const contentType = mimeTypes[extname] || 'application/octet-stream';

    fs.readFile(filePath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end('<h1>404 - Fichier non trouvé</h1>', 'utf-8');
            } else {
                res.writeHead(500);
                res.end(`Erreur serveur: ${error.code}`, 'utf-8');
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
}

// Fonction pour gérer les requêtes POST
function handlePostRequest(req, res, callback) {
    let body = '';
    req.on('data', chunk => {
        body += chunk.toString();
    });
    req.on('end', () => {
        try {
            const data = JSON.parse(body);
            callback(data);
        } catch (error) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: false, error: 'JSON invalide' }));
        }
    });
}

// Fonction pour extraire l'ID de l'URL
function extractIdFromPath(pathname, basePath) {
    const parts = pathname.split('/');
    const baseIndex = parts.indexOf(basePath.split('/').pop());
    return baseIndex !== -1 && parts[baseIndex + 1] ? parseInt(parts[baseIndex + 1]) : null;
}

// Gestionnaire d'erreur pour les appels Odoo
async function safeOdooCall(odooMethod, fallbackData = null) {
    try {
        if (!odooConnector) {
            console.log('⚠️ Connecteur Odoo non disponible, utilisation du fallback');
            return fallbackData;
        }
        
        const result = await odooMethod();
        return result;
    } catch (error) {
        console.error('❌ Erreur appel Odoo:', error.message);
        console.log('⚠️ Utilisation des données de fallback');
        return fallbackData;
    }
}

// Serveur HTTP
const server = http.createServer(async (req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;
    const method = req.method;

    // Headers CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    // Routes API
    if (pathname.startsWith('/api/')) {
        res.setHeader('Content-Type', 'application/json');

        // Authentification
        if (pathname === '/api/auth/login' && method === 'POST') {
            handlePostRequest(req, res, (data) => {
                const { email, password } = data;
                const user = fallbackData.users[email];
                
                if (user && user.password === password) {
                    const { password: _, ...userWithoutPassword } = user;
                    res.writeHead(200);
                    res.end(JSON.stringify({
                        success: true,
                        data: {
                            token: 'fake-jwt-token-' + Date.now(),
                            user: userWithoutPassword
                        }
                    }));
                } else {
                    res.writeHead(401);
                    res.end(JSON.stringify({
                        success: false,
                        error: 'Identifiants incorrects'
                    }));
                }
            });
            return;
        }

        // Dashboard avec données Odoo
        if (pathname === '/api/dashboard' && method === 'GET') {
            try {
                const dashboardData = await safeOdooCall(
                    () => odooConnector.getDashboardStats(),
                    {
                        stats: {
                            totalRequests: 0,
                            pendingRequests: 0,
                            completedRequests: 0,
                            totalAlerts: 0,
                            activeAlerts: 0,
                            satisfactionRate: 0,
                            averageResponseTime: 0
                        },
                        recentRequests: [],
                        recentAlerts: []
                    }
                );

                res.writeHead(200);
                res.end(JSON.stringify({
                    success: true,
                    data: dashboardData,
                    source: odooConnector ? 'odoo' : 'fallback'
                }));
            } catch (error) {
                console.error('❌ Erreur dashboard:', error);
                res.writeHead(500);
                res.end(JSON.stringify({
                    success: false,
                    error: 'Erreur lors du chargement du dashboard'
                }));
            }
            return;
        }

        // Demandes - Liste avec données Odoo
        if (pathname === '/api/requests' && method === 'GET') {
            try {
                const requestsData = await safeOdooCall(
                    () => odooConnector.getInformationRequests({ limit: 100 }),
                    {
                        requests: [],
                        pagination: { page: 1, limit: 100, total: 0, pages: 1 }
                    }
                );

                res.writeHead(200);
                res.end(JSON.stringify({
                    success: true,
                    data: requestsData,
                    source: odooConnector ? 'odoo' : 'fallback'
                }));
            } catch (error) {
                console.error('❌ Erreur requests:', error);
                res.writeHead(500);
                res.end(JSON.stringify({
                    success: false,
                    error: 'Erreur lors du chargement des demandes'
                }));
            }
            return;
        }

        // Demandes - Détail avec données Odoo
        if (pathname.startsWith('/api/requests/') && method === 'GET') {
            const id = extractIdFromPath(pathname, '/api/requests');
            if (id) {
                try {
                    const requestData = await safeOdooCall(
                        () => odooConnector.getInformationRequest(id),
                        null
                    );

                    if (requestData) {
                        res.writeHead(200);
                        res.end(JSON.stringify({
                            success: true,
                            data: requestData,
                            source: odooConnector ? 'odoo' : 'fallback'
                        }));
                    } else {
                        res.writeHead(404);
                        res.end(JSON.stringify({
                            success: false,
                            error: 'Demande non trouvée'
                        }));
                    }
                } catch (error) {
                    console.error('❌ Erreur request detail:', error);
                    res.writeHead(500);
                    res.end(JSON.stringify({
                        success: false,
                        error: 'Erreur lors du chargement de la demande'
                    }));
                }
            } else {
                res.writeHead(400);
                res.end(JSON.stringify({
                    success: false,
                    error: 'ID de demande invalide'
                }));
            }
            return;
        }

        // Alertes - Liste avec données Odoo
        if (pathname === '/api/alerts' && method === 'GET') {
            try {
                const alertsData = await safeOdooCall(
                    () => odooConnector.getWhistleblowingAlerts({ limit: 100 }),
                    {
                        alerts: [],
                        pagination: { page: 1, limit: 100, total: 0, pages: 1 }
                    }
                );

                res.writeHead(200);
                res.end(JSON.stringify({
                    success: true,
                    data: alertsData,
                    source: odooConnector ? 'odoo' : 'fallback'
                }));
            } catch (error) {
                console.error('❌ Erreur alerts:', error);
                res.writeHead(500);
                res.end(JSON.stringify({
                    success: false,
                    error: 'Erreur lors du chargement des alertes'
                }));
            }
            return;
        }

        // Alertes - Détail avec données Odoo
        if (pathname.startsWith('/api/alerts/') && method === 'GET') {
            const id = extractIdFromPath(pathname, '/api/alerts');
            if (id) {
                try {
                    const alertData = await safeOdooCall(
                        () => odooConnector.getWhistleblowingAlert(id),
                        null
                    );

                    if (alertData) {
                        res.writeHead(200);
                        res.end(JSON.stringify({
                            success: true,
                            data: alertData,
                            source: odooConnector ? 'odoo' : 'fallback'
                        }));
                    } else {
                        res.writeHead(404);
                        res.end(JSON.stringify({
                            success: false,
                            error: 'Alerte non trouvée'
                        }));
                    }
                } catch (error) {
                    console.error('❌ Erreur alert detail:', error);
                    res.writeHead(500);
                    res.end(JSON.stringify({
                        success: false,
                        error: 'Erreur lors du chargement de l\'alerte'
                    }));
                }
            } else {
                res.writeHead(400);
                res.end(JSON.stringify({
                    success: false,
                    error: 'ID d\'alerte invalide'
                }));
            }
            return;
        }

        // Test de connexion Odoo
        if (pathname === '/api/test-odoo' && method === 'GET') {
            try {
                const isConnected = odooConnector && odooConnector.uid;
                const stats = isConnected ? await odooConnector.getDashboardStats() : null;
                
                res.writeHead(200);
                res.end(JSON.stringify({
                    success: true,
                    data: {
                        status: isConnected ? 'connected' : 'disconnected',
                        config: {
                            url: ODOO_CONFIG.url,
                            database: ODOO_CONFIG.database,
                            username: ODOO_CONFIG.username
                        },
                        uid: odooConnector ? odooConnector.uid : null,
                        stats: stats ? {
                            requests_count: stats.stats.totalRequests,
                            alerts_count: stats.stats.totalAlerts
                        } : null,
                        timestamp: new Date().toISOString()
                    }
                }));
            } catch (error) {
                res.writeHead(200);
                res.end(JSON.stringify({
                    success: false,
                    data: {
                        status: 'error',
                        error: error.message,
                        config: {
                            url: ODOO_CONFIG.url,
                            database: ODOO_CONFIG.database,
                            username: ODOO_CONFIG.username
                        }
                    }
                }));
            }
            return;
        }

        // Route API non trouvée
        res.writeHead(404);
        res.end(JSON.stringify({
            success: false,
            error: 'Route API non trouvée'
        }));
        return;
    }

    // Servir les fichiers statiques
    let filePath = path.join(__dirname, 'public', pathname === '/' ? 'index.html' : pathname);
    
    // Sécurité : empêcher l'accès aux fichiers en dehors du dossier public
    if (!filePath.startsWith(path.join(__dirname, 'public'))) {
        res.writeHead(403);
        res.end('Accès interdit');
        return;
    }

    serveStaticFile(filePath, res);
});

// Démarrage du serveur avec initialisation Odoo
async function startServer() {
    console.log(`
🎨 SAMA CONAI UX RÉVOLUTIONNAIRE v6.0 - SERVEUR AVEC INTÉGRATION ODOO
=====================================================================
`);

    // Initialiser la connexion Odoo
    const odooConnected = await initializeOdooConnector();

    server.listen(PORT, () => {
        console.log(`
🌐 URL: http://localhost:${PORT}
🎯 Design: UX Inspiré des Meilleurs Designs
📱 Interface: Mobile-First Révolutionnaire avec Drilldown
✨ Animations: Micro-interactions Fluides
🎨 Thème: Design System Moderne
🚀 Performance: Optimisée pour Mobile
📊 Données: ${odooConnected ? '✅ ODOO CONNECTÉ' : '⚠️ FALLBACK MODE'}

🔧 CONFIGURATION ODOO:
   🌐 URL: ${ODOO_CONFIG.url}
   🗄️ Base: ${ODOO_CONFIG.database}
   👤 User: ${ODOO_CONFIG.username}
   🔗 Status: ${odooConnected ? 'CONNECTÉ' : 'DÉCONNECTÉ'}

🔑 COMPTES DE TEST:
   👑 Admin: admin@sama-conai.sn / admin123
   🛡️ Agent: agent@sama-conai.sn / agent123
   👤 Citoyen: citoyen@email.com / citoyen123

🎉 FONCTIONNALITÉS RÉVOLUTIONNAIRES:
   ✨ Glassmorphism et Neumorphism
   🎭 Micro-interactions avancées
   🌊 Animations fluides 60fps
   🎨 Design system sophistiqué
   📱 Navigation gestuelle avec drilldown
   🌙 Mode sombre élégant
   🎯 Transitions seamless
   📊 Statistiques ${odooConnected ? 'RÉELLES depuis Odoo' : 'de fallback'}
   🔍 Détails complets avec historique

📊 API ENDPOINTS DISPONIBLES:
   🔐 POST /api/auth/login - Authentification
   📊 GET /api/dashboard - Dashboard avec stats ${odooConnected ? 'Odoo' : 'fallback'}
   📄 GET /api/requests - Liste des demandes ${odooConnected ? 'Odoo' : 'fallback'}
   📄 GET /api/requests/:id - Détail d'une demande ${odooConnected ? 'Odoo' : 'fallback'}
   🚨 GET /api/alerts - Liste des alertes ${odooConnected ? 'Odoo' : 'fallback'}
   🚨 GET /api/alerts/:id - Détail d'une alerte ${odooConnected ? 'Odoo' : 'fallback'}
   🔧 GET /api/test-odoo - Test de connexion Odoo

🚀 SERVEUR AVEC INTÉGRATION ODOO ${odooConnected ? 'RÉUSSIE' : 'EN MODE FALLBACK'} !
        `);
    });
}

// Gestion de l'arrêt propre
process.on('SIGINT', () => {
    console.log('\n👋 Arrêt du serveur SAMA CONAI UX...');
    server.close(() => {
        console.log('✅ Serveur arrêté proprement');
        process.exit(0);
    });
});

process.on('SIGTERM', () => {
    console.log('\n👋 Arrêt du serveur SAMA CONAI UX...');
    server.close(() => {
        console.log('✅ Serveur arrêté proprement');
        process.exit(0);
    });
});

// Démarrer le serveur
startServer().catch(error => {
    console.error('❌ Erreur démarrage serveur:', error);
    process.exit(1);
});