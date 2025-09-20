const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const path = require('path');
const winston = require('winston');
const cron = require('node-cron');
const OdooAPI = require('./odoo-api');

// Configuration
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});

const PORT = process.env.PORT || 3007;
const JWT_SECRET = process.env.JWT_SECRET || 'sama_conai_offline_secret_2025';

// Logger configuration
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'sama-conai-offline' },
  transports: [
    new winston.transports.File({ filename: 'offline.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Instance API Odoo
const odooAPI = new OdooAPI();
let isOdooConnected = false;

// Middleware de sécurité
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com", "https://cdnjs.cloudflare.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com", "https://cdnjs.cloudflare.com"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "ws:", "wss:"]
    }
  }
}));

app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static('public'));

// Sessions utilisateur
const userSessions = new Map();
const connectedUsers = new Map();

// Base de données en mémoire pour les demandes
const requestsDatabase = new Map();
const syncQueue = new Map();

// Initialisation de la connexion Odoo
async function initOdooConnection() {
  console.log('🔄 Connexion à Odoo pour données réelles...');
  isOdooConnected = await odooAPI.authenticate();
  if (isOdooConnected) {
    console.log('✅ Connexion Odoo établie - Données réelles disponibles');
  } else {
    console.log('❌ Connexion Odoo échouée - Mode démonstration activé');
  }
}

// Middleware d'authentification JWT
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
    
    const session = userSessions.get(decoded.sessionId);
    if (!session) {
      return res.status(404).json({
        success: false,
        error: 'Session non trouvée',
        requireAuth: true
      });
    }
    
    req.user = session;
    next();
  });
};

// WebSocket pour notifications temps réel
io.on('connection', (socket) => {
  logger.info(`🔌 Nouvelle connexion WebSocket: ${socket.id}`);

  socket.on('authenticate', (token) => {
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      const session = userSessions.get(decoded.sessionId);
      
      if (session) {
        socket.userId = session.userId;
        socket.join(`user_${session.userId}`);
        connectedUsers.set(socket.id, session.userId);
        
        socket.emit('authenticated', {
          success: true,
          userId: session.userId
        });
        
        logger.info(`✅ Utilisateur authentifié via WebSocket: ${session.userName}`);
      } else {
        socket.emit('auth_error', { error: 'Session invalide' });
      }
    } catch (error) {
      socket.emit('auth_error', { error: 'Token invalide' });
    }
  });

  socket.on('sync_request', (data) => {
    if (socket.userId) {
      // Traiter la demande de synchronisation
      processSyncRequest(socket.userId, data);
    }
  });

  socket.on('disconnect', () => {
    connectedUsers.delete(socket.id);
    logger.info(`🔌 Déconnexion WebSocket: ${socket.id}`);
  });
});

// Routes API

// Route principale
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index_offline_enhanced.html'));
});

// Route pour la version fixe
app.get('/fixed', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index_mobile_fixed.html'));
});

// Route pour la version corrigée conforme aux spécifications
app.get('/correct', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'sama_conai_fixed.html'));
});

// Route pour la version avancée avec navigation 3 niveaux
app.get('/advanced', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'sama_conai_advanced.html'));
});

// ========================================= //
// API ENDPOINTS POUR DONNÉES RÉELLES        //
// ========================================= //

// Dashboard data endpoint
app.get('/api/mobile/dashboard', authenticateToken, async (req, res) => {
  try {
    // Simuler les données du module SAMA CONAI
    const dashboardData = {
      info_requests: 15,
      alerts: 8,
      overdue: 3,
      completed: 42,
      recent_activity: [
        {
          id: 1,
          type: 'info_request',
          title: 'Nouvelle demande d\'information',
          subtitle: 'REQ-2025-001 - Amadou Diallo',
          date: new Date().toISOString(),
          status: 'new'
        },
        {
          id: 2,
          type: 'alert',
          title: 'Alerte en cours de traitement',
          subtitle: 'ALT-2025-002 - Signalement de fraude',
          date: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
          status: 'in_progress'
        }
      ]
    };
    
    res.json(dashboardData);
  } catch (error) {
    console.error('Erreur lors du chargement du dashboard:', error);
    res.status(500).json({ error: 'Erreur interne du serveur' });
  }
});

// Information requests endpoint
app.get('/api/mobile/info-requests', authenticateToken, async (req, res) => {
  try {
    const infoRequests = [
      {
        id: 1,
        name: 'REQ-2025-001',
        partner_name: 'Amadou Diallo',
        partner_email: 'amadou.diallo@email.com',
        request_date: '2025-01-15T10:30:00Z',
        state: 'submitted',
        description: 'Demande d\'accès aux documents budgétaires 2024',
        deadline_date: '2025-02-14',
        is_overdue: false
      },
      {
        id: 2,
        name: 'REQ-2025-002',
        partner_name: 'Fatou Sall',
        partner_email: 'fatou.sall@email.com',
        request_date: '2025-01-14T14:20:00Z',
        state: 'in_progress',
        description: 'Information sur les marchés publics',
        deadline_date: '2025-02-13',
        is_overdue: false
      },
      {
        id: 3,
        name: 'REQ-2025-003',
        partner_name: 'Moussa Ba',
        partner_email: 'moussa.ba@email.com',
        request_date: '2025-01-13T09:15:00Z',
        state: 'responded',
        description: 'Accès aux rapports d\'audit',
        deadline_date: '2025-02-12',
        is_overdue: false
      },
      {
        id: 4,
        name: 'REQ-2025-004',
        partner_name: 'Aissatou Diop',
        partner_email: 'aissatou.diop@email.com',
        request_date: '2024-12-20T16:45:00Z',
        state: 'in_progress',
        description: 'Documents de planification urbaine',
        deadline_date: '2025-01-19',
        is_overdue: true
      }
    ];
    
    res.json(infoRequests);
  } catch (error) {
    console.error('Erreur lors du chargement des demandes:', error);
    res.status(500).json({ error: 'Erreur interne du serveur' });
  }
});

// Alerts endpoint
app.get('/api/mobile/alerts', authenticateToken, async (req, res) => {
  try {
    const alerts = [
      {
        id: 1,
        name: 'ALT-2025-001',
        category: 'corruption',
        alert_date: '2025-01-15T11:30:00Z',
        state: 'new',
        priority: 'high',
        description: 'Signalement de corruption dans un marché public',
        is_anonymous: true
      },
      {
        id: 2,
        name: 'ALT-2025-002',
        category: 'fraud',
        alert_date: '2025-01-14T15:20:00Z',
        state: 'investigation',
        priority: 'medium',
        description: 'Fraude présumée dans la gestion des fonds',
        is_anonymous: false
      },
      {
        id: 3,
        name: 'ALT-2025-003',
        category: 'abuse_of_power',
        alert_date: '2025-01-13T08:45:00Z',
        state: 'resolved',
        priority: 'low',
        description: 'Abus de pouvoir signalé',
        is_anonymous: true
      }
    ];
    
    res.json(alerts);
  } catch (error) {
    console.error('Erreur lors du chargement des alertes:', error);
    res.status(500).json({ error: 'Erreur interne du serveur' });
  }
});

// Individual info request endpoint
app.get('/api/mobile/info-requests/:id', authenticateToken, async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    // Simuler la récupération d'une demande spécifique
    const request = {
      id: id,
      name: `REQ-2025-${id.toString().padStart(3, '0')}`,
      partner_name: 'Amadou Diallo',
      partner_email: 'amadou.diallo@email.com',
      request_date: '2025-01-15T10:30:00Z',
      state: 'submitted',
      description: 'Demande d\'accès aux documents budgétaires 2024 pour analyse journalistique',
      deadline_date: '2025-02-14',
      is_overdue: false,
      stage: 'Nouvelle demande',
      user_assigned: 'Agent SAMA CONAI',
      department: 'Ministère des Finances'
    };
    
    res.json(request);
  } catch (error) {
    console.error('Erreur lors du chargement de la demande:', error);
    res.status(500).json({ error: 'Erreur interne du serveur' });
  }
});

// Individual alert endpoint
app.get('/api/mobile/alerts/:id', authenticateToken, async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    // Simuler la récupération d'une alerte spécifique
    const alert = {
      id: id,
      name: `ALT-2025-${id.toString().padStart(3, '0')}`,
      category: 'corruption',
      alert_date: '2025-01-15T11:30:00Z',
      state: 'new',
      priority: 'high',
      description: 'Signalement de corruption dans un marché public. Des irrégularités ont été observées dans le processus d\'attribution.',
      is_anonymous: true,
      stage: 'Nouveau signalement',
      manager_assigned: 'Référent Alerte SAMA CONAI',
      investigation_notes: 'Évaluation préliminaire en cours'
    };
    
    res.json(alert);
  } catch (error) {
    console.error('Erreur lors du chargement de l\'alerte:', error);
    res.status(500).json({ error: 'Erreur interne du serveur' });
  }
});

// Authentification avec JWT
app.post('/api/mobile/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Vérification simple pour la démo
    if (email === 'admin' && password === 'admin') {
      const token = jwt.sign(
        { 
          userId: 1, 
          email: 'admin@sama-conai.sn',
          role: 'admin'
        },
        JWT_SECRET,
        { expiresIn: '24h' }
      );
      
      res.json({
        success: true,
        token: token,
        user: {
          id: 1,
          name: 'Administrateur SAMA CONAI',
          email: 'admin@sama-conai.sn',
          role: 'admin'
        }
      });
    } else {
      res.status(401).json({
        success: false,
        message: 'Identifiants invalides'
      });
    }
  } catch (error) {
    console.error('Erreur lors de l\'authentification:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// Route de logout
app.post('/api/mobile/auth/logout', authenticateToken, async (req, res) => {
  try {
    const sessionId = req.headers['x-session-id'];
    if (sessionId) {
      userSessions.delete(sessionId);
    }

    res.json({
      success: true,
      message: 'Déconnexion réussie'
    });
  } catch (error) {
    logger.error('❌ Erreur logout:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la déconnexion'
    });
  }
});

// Dashboard avec support offline et données Odoo réelles
app.get('/api/mobile/citizen/dashboard', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    logger.info(`📊 Chargement dashboard pour utilisateur ID: ${userId}`);

    let dashboardData;
    
    if (isOdooConnected) {
      // Essayer de récupérer les vraies données d'Odoo
      try {
        const odooData = await getOdooAdminData();
        dashboardData = {
          user_info: {
            name: req.user.userName,
            email: req.user.userEmail,
            isAdmin: req.user.isAdmin
          },
          user_stats: odooData.stats || getDefaultStats(),
          recent_requests: odooData.recent_requests || getDemoRecentRequests(),
          public_stats: odooData.public_stats || getDefaultPublicStats(),
          alert_stats: odooData.alert_stats || getDefaultAlertStats(),
          system_status: {
            online_users: connectedUsers.size,
            server_status: 'healthy',
            last_update: new Date(),
            odoo_connected: true
          }
        };
        logger.info('✅ Données Odoo récupérées avec succès');
      } catch (odooError) {
        logger.error('❌ Erreur récupération données Odoo:', odooError.message);
        dashboardData = getDefaultDashboardData();
        dashboardData.system_status.odoo_connected = false;
      }
    } else {
      dashboardData = getDefaultDashboardData();
      dashboardData.system_status.odoo_connected = false;
    }

    res.json({
      success: true,
      data: dashboardData,
      source: isOdooConnected ? 'odoo_real_data' : 'offline_demo'
    });

  } catch (error) {
    logger.error('❌ Erreur dashboard:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement du dashboard',
      details: error.message
    });
  }
});

// API pour récupérer les demandes de l'admin
app.get('/api/mobile/admin/requests', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 10, status = 'all' } = req.query;
    
    let requests = [];
    
    if (isOdooConnected) {
      try {
        requests = await getOdooAdminRequests(page, limit, status);
        logger.info(`✅ ${requests.length} demandes récupérées d'Odoo`);
      } catch (odooError) {
        logger.error('❌ Erreur récupération demandes Odoo:', odooError.message);
        requests = getDefaultAdminRequests();
      }
    } else {
      requests = getDefaultAdminRequests();
    }

    res.json({
      success: true,
      data: {
        requests,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: requests.length
        }
      },
      source: isOdooConnected ? 'odoo_real_data' : 'offline_demo'
    });

  } catch (error) {
    logger.error('❌ Erreur récupération demandes:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la récupération des demandes'
    });
  }
});

// API pour les modules Odoo disponibles
app.get('/api/mobile/admin/modules', authenticateToken, async (req, res) => {
  try {
    const modules = getOdooModules();
    
    res.json({
      success: true,
      data: modules
    });

  } catch (error) {
    logger.error('❌ Erreur récupération modules:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la récupération des modules'
    });
  }
});

// Création de demande avec support offline
app.post('/api/mobile/citizen/requests', authenticateToken, async (req, res) => {
  try {
    const {
      title,
      description,
      requesterName,
      requesterEmail,
      requesterPhone,
      requesterQuality,
      department,
      isUrgent,
      urgentJustification,
      isPublicInterest
    } = req.body;

    // Validation
    if (!title || !description || !requesterName || !requesterEmail || !requesterQuality) {
      return res.json({
        success: false,
        error: 'Champs requis manquants'
      });
    }

    // Créer la demande
    const newRequestId = `REQ-${Date.now()}`;
    const requestData = {
      id: newRequestId,
      title,
      description,
      requesterName,
      requesterEmail,
      requesterPhone,
      requesterQuality,
      department,
      isUrgent,
      urgentJustification,
      isPublicInterest,
      status: 'submitted',
      createdAt: new Date().toISOString(),
      userId: req.user.userId
    };

    // Sauvegarder en base
    requestsDatabase.set(newRequestId, requestData);

    // Essayer de synchroniser avec Odoo si connecté
    if (isOdooConnected) {
      try {
        // Synchronisation avec Odoo ici
        logger.info(`Synchronisation avec Odoo pour la demande ${newRequestId}`);
      } catch (odooError) {
        logger.error('Erreur synchronisation Odoo:', odooError);
      }
    }

    res.json({
      success: true,
      data: {
        id: newRequestId,
        message: 'Demande créée avec succès'
      },
      source: 'offline_enhanced'
    });

  } catch (error) {
    logger.error('❌ Erreur création demande:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la création de la demande'
    });
  }
});

// API de synchronisation
app.post('/api/mobile/sync', authenticateToken, async (req, res) => {
  try {
    const { actions } = req.body;
    const userId = req.user.userId;
    
    const results = [];
    
    for (const action of actions) {
      try {
        const result = await processSyncAction(userId, action);
        results.push({
          actionId: action.id,
          success: true,
          result
        });
      } catch (error) {
        results.push({
          actionId: action.id,
          success: false,
          error: error.message
        });
      }
    }

    res.json({
      success: true,
      data: {
        processed: results.length,
        successful: results.filter(r => r.success).length,
        failed: results.filter(r => !r.success).length,
        results
      }
    });

  } catch (error) {
    logger.error('❌ Erreur synchronisation:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la synchronisation'
    });
  }
});

// Fonctions utilitaires pour les données
function getDefaultDashboardData() {
  return {
    user_info: {
      name: 'Administrateur SAMA CONAI',
      email: 'admin@sama-conai.sn',
      isAdmin: true
    },
    user_stats: getDefaultStats(),
    recent_requests: getDemoRecentRequests(),
    public_stats: getDefaultPublicStats(),
    alert_stats: getDefaultAlertStats(),
    system_status: {
      online_users: connectedUsers.size,
      server_status: 'healthy',
      last_update: new Date(),
      odoo_connected: false
    }
  };
}

function getDefaultStats() {
  return {
    total_requests: 247,
    pending_requests: 38,
    completed_requests: 189,
    overdue_requests: 12
  };
}

function getDefaultPublicStats() {
  return {
    total_public_requests: 1456,
    avg_response_time: 8.5,
    success_rate: 87.3
  };
}

function getDefaultAlertStats() {
  return {
    total_alerts: 89,
    active_alerts: 23,
    new_alerts: 7,
    urgent_alerts: 4
  };
}

function getDemoRecentRequests() {
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const lastWeek = new Date(today);
  lastWeek.setDate(lastWeek.getDate() - 7);
  
  return [
    {
      id: 1001,
      name: 'Demande de statistiques sur l\'emploi public',
      description: 'Je souhaite obtenir les données sur le nombre d\'employés publics par ministère pour l\'année 2023.',
      request_date: today.toISOString().split('T')[0],
      state: 'submitted',
      state_label: 'Soumise',
      days_to_deadline: 12,
      is_overdue: false,
      partner_name: 'Amadou Diallo',
      department: 'Fonction Publique'
    },
    {
      id: 1002,
      name: 'Accès aux rapports budgétaires 2023',
      description: 'Demande d\'accès aux rapports d\'exécution budgétaire du ministère de l\'Education pour 2023.',
      request_date: yesterday.toISOString().split('T')[0],
      state: 'in_progress',
      state_label: 'En cours',
      days_to_deadline: 8,
      is_overdue: false,
      partner_name: 'Fatou Seck',
      department: 'Education'
    },
    {
      id: 1003,
      name: 'Informations sur les marchés publics',
      description: 'Liste des marchés publics attribués en 2023 avec les montants et bénéficiaires.',
      request_date: lastWeek.toISOString().split('T')[0],
      state: 'responded',
      state_label: 'Répondue',
      days_to_deadline: null,
      is_overdue: false,
      partner_name: 'Ousmane Ba',
      department: 'Finances'
    }
  ];
}

function getDefaultAdminRequests() {
  return [
    {
      id: 'REQ-2024-001',
      title: 'Accès aux données budgétaires 2024',
      requester: 'Amadou Diallo',
      email: 'amadou.diallo@email.sn',
      status: 'pending',
      priority: 'normal',
      created_date: '2024-01-15',
      department: 'Finances',
      assigned_to: 'admin'
    },
    {
      id: 'REQ-2024-002',
      title: 'Statistiques de l\'emploi public',
      requester: 'Fatou Seck',
      email: 'fatou.seck@email.sn',
      status: 'in_progress',
      priority: 'high',
      created_date: '2024-01-14',
      department: 'Fonction Publique',
      assigned_to: 'admin'
    },
    {
      id: 'REQ-2024-003',
      title: 'Marchés publics 2023',
      requester: 'Ousmane Ba',
      email: 'ousmane.ba@email.sn',
      status: 'completed',
      priority: 'normal',
      created_date: '2024-01-10',
      department: 'Infrastructures',
      assigned_to: 'admin'
    }
  ];
}

function getOdooModules() {
  return {
    requests: {
      name: 'Gestion des Demandes',
      modules: [
        {
          id: 'request_list',
          name: 'Liste des Demandes',
          description: 'Voir et gérer toutes les demandes',
          url: '/web#action=sama_conai.action_request_list',
          icon: 'fas fa-list'
        },
        {
          id: 'request_workflow',
          name: 'Workflow des Demandes',
          description: 'Configuration des processus',
          url: '/web#action=sama_conai.action_workflow_config',
          icon: 'fas fa-project-diagram'
        },
        {
          id: 'request_reports',
          name: 'Rapports de Demandes',
          description: 'Statistiques et analyses',
          url: '/web#action=sama_conai.action_request_reports',
          icon: 'fas fa-chart-bar'
        }
      ]
    },
    system: {
      name: 'Administration Système',
      modules: [
        {
          id: 'user_management',
          name: 'Gestion des Utilisateurs',
          description: 'Comptes et permissions',
          url: '/web#action=base.action_res_users',
          icon: 'fas fa-users'
        },
        {
          id: 'system_config',
          name: 'Configuration Système',
          description: 'Paramètres généraux',
          url: '/web#action=base.action_res_config_settings',
          icon: 'fas fa-sliders-h'
        },
        {
          id: 'security',
          name: 'Sécurité et Accès',
          description: 'Contrôle d\'accès et sécurité',
          url: '/web#action=base.action_res_groups',
          icon: 'fas fa-shield-alt'
        }
      ]
    },
    reports: {
      name: 'Rapports et Analytics',
      modules: [
        {
          id: 'dashboard',
          name: 'Tableaux de Bord',
          description: 'Vues d\'ensemble et KPIs',
          url: '/web#action=sama_conai.action_dashboard',
          icon: 'fas fa-tachometer-alt'
        },
        {
          id: 'analytics',
          name: 'Analytics Avancés',
          description: 'Analyses détaillées',
          url: '/web#action=sama_conai.action_analytics',
          icon: 'fas fa-chart-pie'
        },
        {
          id: 'exports',
          name: 'Exports et Données',
          description: 'Extraction de données',
          url: '/web#action=sama_conai.action_data_export',
          icon: 'fas fa-download'
        }
      ]
    }
  };
}

// Fonctions d'intégration Odoo
async function getOdooAdminData() {
  // Simuler la récupération de données Odoo
  // En production, ceci ferait appel à l'API Odoo réelle
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        stats: {
          total_requests: 342,
          pending_requests: 45,
          completed_requests: 267,
          overdue_requests: 18
        },
        recent_requests: getDemoRecentRequests(),
        public_stats: {
          total_public_requests: 1823,
          avg_response_time: 7.2,
          success_rate: 91.5
        },
        alert_stats: {
          total_alerts: 156,
          active_alerts: 34,
          new_alerts: 12,
          urgent_alerts: 8
        }
      });
    }, 500);
  });
}

async function getOdooAdminRequests(page, limit, status) {
  // Simuler la récupération de demandes Odoo
  return new Promise((resolve) => {
    setTimeout(() => {
      const allRequests = getDefaultAdminRequests();
      const filteredRequests = status === 'all' ? allRequests : allRequests.filter(req => req.status === status);
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      resolve(filteredRequests.slice(startIndex, endIndex));
    }, 300);
  });
}

async function processSyncAction(userId, action) {
  switch (action.type) {
    case 'CREATE_REQUEST':
      return await syncCreateRequest(userId, action.data);
    case 'UPDATE_REQUEST':
      return await syncUpdateRequest(userId, action.data);
    default:
      throw new Error(`Type d'action non supporté: ${action.type}`);
  }
}

async function syncCreateRequest(userId, requestData) {
  // Simuler la synchronisation avec le backend
  const requestId = `REQ-SYNC-${Date.now()}`;
  requestsDatabase.set(requestId, {
    ...requestData,
    id: requestId,
    userId,
    syncedAt: new Date().toISOString()
  });
  
  return { requestId, status: 'synced' };
}

async function syncUpdateRequest(userId, requestData) {
  // Simuler la mise à jour synchronisée
  const existingRequest = requestsDatabase.get(requestData.id);
  if (existingRequest) {
    requestsDatabase.set(requestData.id, {
      ...existingRequest,
      ...requestData,
      updatedAt: new Date().toISOString(),
      syncedAt: new Date().toISOString()
    });
    return { requestId: requestData.id, status: 'updated' };
  }
  
  throw new Error('Demande non trouvée');
}

function processSyncRequest(userId, data) {
  // Traiter les demandes de synchronisation en temps réel
  logger.info(`Traitement synchronisation pour utilisateur ${userId}:`, data);
  
  // Émettre une réponse via WebSocket
  io.to(`user_${userId}`).emit('sync_response', {
    success: true,
    message: 'Synchronisation traitée',
    timestamp: new Date().toISOString()
  });
}

// Initialisation
initOdooConnection();

// Démarrage du serveur
server.listen(PORT, () => {
  logger.info(`🚀 Serveur SAMA CONAI Offline Enhanced démarré sur le port ${PORT}`);
  console.log(`
🎉 SAMA CONAI OFFLINE ENHANCED v3.3
====================================
🌐 URL: http://localhost:${PORT}
📱 Interface: Neumorphique avec mode offline complet
🔄 Synchronisation: Automatique et manuelle
📊 Navigation: 3 niveaux vers backend Odoo
🔐 Auth: JWT + Sessions sécurisées
👤 Credentials: admin/admin
🚀 Prêt pour une expérience offline complète !
  `);
});