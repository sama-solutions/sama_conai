const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('rate-limiter-flexible');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const path = require('path');
const fs = require('fs');
const cron = require('node-cron');
const winston = require('winston');

// Configuration avancée
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});

const PORT = process.env.PORT || 3002;
const JWT_SECRET = process.env.JWT_SECRET || 'sama_conai_premium_secret_2025';

// Configuration du logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'sama-conai-premium' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Rate limiting avancé
const rateLimiter = new rateLimit.RateLimiterMemory({
  keyGenerator: (req) => req.ip,
  points: 100, // Nombre de requêtes
  duration: 60, // Par minute
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
      connectSrc: ["'self'", "ws:", "wss:"]
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

// Base de données en mémoire avancée (en production, utiliser MongoDB/PostgreSQL)
const database = {
  users: new Map(),
  sessions: new Map(),
  notifications: new Map(),
  requests: new Map(),
  alerts: new Map(),
  analytics: new Map(),
  themes: new Map(),
  gamification: new Map()
};

// Données utilisateurs par défaut avec rôles avancés
const defaultUsers = [
  {
    id: 'admin_001',
    email: 'admin@sama-conai.sn',
    password: bcrypt.hashSync('admin123', 10),
    name: 'Administrateur SAMA CONAI',
    role: 'admin',
    department: 'Direction Générale',
    avatar: '/images/avatars/admin.jpg',
    permissions: ['all'],
    preferences: {
      theme: 'auto',
      notifications: true,
      language: 'fr'
    },
    gamification: {
      level: 10,
      points: 2500,
      badges: ['expert', 'leader', 'innovator']
    }
  },
  {
    id: 'agent_001',
    email: 'agent@sama-conai.sn',
    password: bcrypt.hashSync('agent123', 10),
    name: 'Agent de Transparence',
    role: 'agent',
    department: 'Service Information',
    avatar: '/images/avatars/agent.jpg',
    permissions: ['read_requests', 'update_requests', 'create_responses'],
    preferences: {
      theme: 'light',
      notifications: true,
      language: 'fr'
    },
    gamification: {
      level: 5,
      points: 1200,
      badges: ['efficient', 'responsive']
    }
  },
  {
    id: 'citizen_001',
    email: 'citoyen@email.com',
    password: bcrypt.hashSync('citoyen123', 10),
    name: 'Amadou Diallo',
    role: 'citizen',
    department: null,
    avatar: '/images/avatars/citizen.jpg',
    permissions: ['create_requests', 'view_own_requests', 'create_alerts'],
    preferences: {
      theme: 'dark',
      notifications: true,
      language: 'fr'
    },
    gamification: {
      level: 3,
      points: 450,
      badges: ['active_citizen', 'transparency_advocate']
    }
  }
];

// Initialiser les utilisateurs
defaultUsers.forEach(user => {
  database.users.set(user.id, user);
});

// Données de démonstration enrichies
const demoRequests = [
  {
    id: 'REQ-2025-001',
    title: 'Accès aux documents budgétaires 2024',
    description: 'Demande d\'accès aux documents détaillés du budget national 2024, incluant les allocations par ministère et les dépenses d\'investissement.',
    requester: 'citizen_001',
    assignee: 'agent_001',
    status: 'in_progress',
    priority: 'high',
    category: 'budget',
    created_at: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    deadline: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
    attachments: [],
    timeline: [
      {
        date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
        action: 'created',
        user: 'citizen_001',
        description: 'Demande créée'
      },
      {
        date: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
        action: 'assigned',
        user: 'admin_001',
        description: 'Assignée à l\'agent de transparence'
      }
    ],
    tags: ['budget', 'finances', 'transparence'],
    sentiment: 'neutral',
    ai_analysis: {
      complexity: 'medium',
      estimated_time: '15 jours',
      similar_requests: 3,
      success_probability: 0.85
    }
  },
  {
    id: 'REQ-2025-002',
    title: 'Information sur les marchés publics 2024',
    description: 'Demande d\'information sur tous les marchés publics attribués en 2024, incluant les montants, entreprises bénéficiaires et critères de sélection.',
    requester: 'citizen_001',
    assignee: 'agent_001',
    status: 'completed',
    priority: 'medium',
    category: 'marches_publics',
    created_at: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000),
    deadline: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    completed_at: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    response: 'Veuillez trouver ci-joint la liste complète des marchés publics 2024. Total: 247 marchés pour 156 milliards FCFA.',
    attachments: ['marches_publics_2024.pdf'],
    timeline: [
      {
        date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000),
        action: 'created',
        user: 'citizen_001',
        description: 'Demande créée'
      },
      {
        date: new Date(Date.now() - 18 * 24 * 60 * 60 * 1000),
        action: 'assigned',
        user: 'admin_001',
        description: 'Assignée pour traitement'
      },
      {
        date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
        action: 'in_progress',
        user: 'agent_001',
        description: 'Collecte des données en cours'
      },
      {
        date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
        action: 'completed',
        user: 'agent_001',
        description: 'Réponse fournie avec documents'
      }
    ],
    tags: ['marchés', 'transparence', 'économie'],
    sentiment: 'positive',
    rating: 5,
    ai_analysis: {
      complexity: 'high',
      estimated_time: '20 jours',
      similar_requests: 8,
      success_probability: 0.92
    }
  }
];

// Initialiser les demandes
demoRequests.forEach(request => {
  database.requests.set(request.id, request);
});

// Système de notifications en temps réel
class NotificationSystem {
  constructor() {
    this.notifications = new Map();
    this.subscribers = new Map();
  }

  subscribe(userId, socket) {
    if (!this.subscribers.has(userId)) {
      this.subscribers.set(userId, new Set());
    }
    this.subscribers.get(userId).add(socket);
    
    socket.on('disconnect', () => {
      this.subscribers.get(userId)?.delete(socket);
    });
  }

  async sendNotification(userId, notification) {
    const notificationId = `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const fullNotification = {
      id: notificationId,
      ...notification,
      timestamp: new Date(),
      read: false,
      userId
    };

    // Stocker la notification
    if (!this.notifications.has(userId)) {
      this.notifications.set(userId, []);
    }
    this.notifications.get(userId).unshift(fullNotification);

    // Limiter à 100 notifications par utilisateur
    if (this.notifications.get(userId).length > 100) {
      this.notifications.get(userId) = this.notifications.get(userId).slice(0, 100);
    }

    // Envoyer via WebSocket
    const userSockets = this.subscribers.get(userId);
    if (userSockets) {
      userSockets.forEach(socket => {
        socket.emit('notification', fullNotification);
      });
    }

    logger.info(`Notification envoyée à ${userId}: ${notification.title}`);
    return fullNotification;
  }

  getNotifications(userId, limit = 20) {
    return this.notifications.get(userId)?.slice(0, limit) || [];
  }

  markAsRead(userId, notificationId) {
    const userNotifications = this.notifications.get(userId);
    if (userNotifications) {
      const notification = userNotifications.find(n => n.id === notificationId);
      if (notification) {
        notification.read = true;
        return true;
      }
    }
    return false;
  }

  getUnreadCount(userId) {
    const userNotifications = this.notifications.get(userId);
    return userNotifications ? userNotifications.filter(n => !n.read).length : 0;
  }
}

const notificationSystem = new NotificationSystem();

// Système de gamification
class GamificationSystem {
  constructor() {
    this.actions = {
      'create_request': { points: 10, badge: null },
      'complete_request': { points: 50, badge: 'efficient' },
      'quick_response': { points: 25, badge: 'responsive' },
      'quality_response': { points: 30, badge: 'quality' },
      'first_request': { points: 20, badge: 'newcomer' },
      'transparency_advocate': { points: 100, badge: 'advocate' },
      'expert_level': { points: 500, badge: 'expert' }
    };

    this.levels = [
      { level: 1, minPoints: 0, title: 'Débutant' },
      { level: 2, minPoints: 100, title: 'Initié' },
      { level: 3, minPoints: 300, title: 'Actif' },
      { level: 4, minPoints: 600, title: 'Engagé' },
      { level: 5, minPoints: 1000, title: 'Expert' },
      { level: 6, minPoints: 1500, title: 'Maître' },
      { level: 7, minPoints: 2000, title: 'Champion' },
      { level: 8, minPoints: 3000, title: 'Légende' },
      { level: 9, minPoints: 4000, title: 'Héros' },
      { level: 10, minPoints: 5000, title: 'Icône' }
    ];
  }

  awardPoints(userId, action, multiplier = 1) {
    const user = database.users.get(userId);
    if (!user || !this.actions[action]) return null;

    const points = this.actions[action].points * multiplier;
    user.gamification.points += points;

    // Vérifier le niveau
    const newLevel = this.calculateLevel(user.gamification.points);
    const levelUp = newLevel > user.gamification.level;
    user.gamification.level = newLevel;

    // Attribuer un badge si applicable
    const badge = this.actions[action].badge;
    if (badge && !user.gamification.badges.includes(badge)) {
      user.gamification.badges.push(badge);
    }

    // Notification de points
    notificationSystem.sendNotification(userId, {
      type: 'gamification',
      title: `+${points} points gagnés !`,
      message: `Action: ${action}`,
      icon: '🏆',
      color: 'success'
    });

    // Notification de niveau
    if (levelUp) {
      const levelInfo = this.levels.find(l => l.level === newLevel);
      notificationSystem.sendNotification(userId, {
        type: 'level_up',
        title: 'Niveau supérieur atteint !',
        message: `Vous êtes maintenant ${levelInfo.title} (Niveau ${newLevel})`,
        icon: '🎉',
        color: 'primary'
      });
    }

    return {
      points,
      totalPoints: user.gamification.points,
      level: user.gamification.level,
      levelUp,
      badge: badge && !user.gamification.badges.includes(badge) ? badge : null
    };
  }

  calculateLevel(points) {
    for (let i = this.levels.length - 1; i >= 0; i--) {
      if (points >= this.levels[i].minPoints) {
        return this.levels[i].level;
      }
    }
    return 1;
  }

  getLeaderboard(limit = 10) {
    const users = Array.from(database.users.values())
      .sort((a, b) => b.gamification.points - a.gamification.points)
      .slice(0, limit)
      .map(user => ({
        id: user.id,
        name: user.name,
        points: user.gamification.points,
        level: user.gamification.level,
        badges: user.gamification.badges,
        avatar: user.avatar
      }));
    
    return users;
  }
}

const gamificationSystem = new GamificationSystem();

// Assistant IA (simulation)
class AIAssistant {
  constructor() {
    this.responses = {
      'comment créer une demande': 'Pour créer une demande d\'information, cliquez sur le bouton "+" puis sélectionnez "Nouvelle demande". Remplissez le formulaire avec des détails précis pour obtenir une réponse rapide.',
      'délai de réponse': 'Le délai légal de réponse est de 30 jours. En moyenne, nos agents répondent en 16.8 jours. Vous recevrez des notifications sur l\'avancement.',
      'statut de ma demande': 'Je peux vous aider à vérifier le statut de votre demande. Pouvez-vous me donner le numéro de votre demande ?',
      'transparence': 'SAMA CONAI garantit la transparence gouvernementale au Sénégal. Nous traitons les demandes d\'information et les signalements avec professionnalisme.',
      'aide': 'Je suis votre assistant virtuel SAMA CONAI. Je peux vous aider avec les demandes d\'information, les signalements, et répondre à vos questions sur la transparence.'
    };
  }

  async processMessage(message, userId) {
    const lowerMessage = message.toLowerCase();
    
    // Recherche de mots-clés
    for (const [keyword, response] of Object.entries(this.responses)) {
      if (lowerMessage.includes(keyword)) {
        return {
          type: 'text',
          content: response,
          suggestions: this.getSuggestions(keyword)
        };
      }
    }

    // Réponse par défaut avec suggestions
    return {
      type: 'text',
      content: 'Je ne suis pas sûr de comprendre votre question. Voici quelques sujets sur lesquels je peux vous aider :',
      suggestions: [
        'Comment créer une demande ?',
        'Quel est le délai de réponse ?',
        'Vérifier le statut de ma demande',
        'En savoir plus sur la transparence'
      ]
    };
  }

  getSuggestions(context) {
    const suggestions = {
      'comment créer une demande': [
        'Types de demandes possibles',
        'Documents nécessaires',
        'Suivi de ma demande'
      ],
      'délai de réponse': [
        'Facteurs influençant les délais',
        'Demandes urgentes',
        'Historique des délais'
      ],
      'transparence': [
        'Lois sur la transparence',
        'Droits des citoyens',
        'Signaler un problème'
      ]
    };
    
    return suggestions[context] || [
      'Créer une demande',
      'Voir mes demandes',
      'Contacter le support'
    ];
  }
}

const aiAssistant = new AIAssistant();

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

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({
        success: false,
        error: 'Token invalide',
        requireAuth: true
      });
    }
    
    req.user = database.users.get(user.userId);
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

// WebSocket pour notifications temps réel
io.on('connection', (socket) => {
  logger.info(`Nouvelle connexion WebSocket: ${socket.id}`);

  socket.on('authenticate', (token) => {
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      const user = database.users.get(decoded.userId);
      
      if (user) {
        socket.userId = user.id;
        socket.join(`user_${user.id}`);
        notificationSystem.subscribe(user.id, socket);
        
        socket.emit('authenticated', {
          success: true,
          user: {
            id: user.id,
            name: user.name,
            role: user.role
          }
        });
        
        logger.info(`Utilisateur authentifié via WebSocket: ${user.name}`);
      }
    } catch (error) {
      socket.emit('auth_error', { error: 'Token invalide' });
    }
  });

  socket.on('mark_notification_read', (notificationId) => {
    if (socket.userId) {
      notificationSystem.markAsRead(socket.userId, notificationId);
    }
  });

  socket.on('ai_message', async (message) => {
    if (socket.userId) {
      const response = await aiAssistant.processMessage(message, socket.userId);
      socket.emit('ai_response', response);
    }
  });

  socket.on('disconnect', () => {
    logger.info(`Déconnexion WebSocket: ${socket.id}`);
  });
});

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

    // Rechercher l'utilisateur
    const user = Array.from(database.users.values()).find(u => u.email === email);
    
    if (!user || !bcrypt.compareSync(password, user.password)) {
      return res.status(401).json({
        success: false,
        error: 'Identifiants incorrects'
      });
    }

    // Générer le token JWT
    const tokenExpiry = rememberMe ? '30d' : '24h';
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      JWT_SECRET,
      { expiresIn: tokenExpiry }
    );

    // Créer la session
    const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    database.sessions.set(sessionId, {
      userId: user.id,
      token,
      createdAt: new Date(),
      lastActivity: new Date(),
      userAgent: req.headers['user-agent'],
      ip: req.ip
    });

    // Notification de connexion
    await notificationSystem.sendNotification(user.id, {
      type: 'login',
      title: 'Connexion réussie',
      message: `Bienvenue ${user.name} !`,
      icon: '👋',
      color: 'success'
    });

    // Réponse avec informations utilisateur enrichies
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
          department: user.department,
          avatar: user.avatar,
          permissions: user.permissions,
          preferences: user.preferences,
          gamification: user.gamification
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

// Déconnexion
app.post('/api/auth/logout', authenticateToken, async (req, res) => {
  try {
    const sessionId = req.headers['x-session-id'];
    if (sessionId) {
      database.sessions.delete(sessionId);
    }

    await notificationSystem.sendNotification(req.user.id, {
      type: 'logout',
      title: 'Déconnexion',
      message: 'À bientôt !',
      icon: '👋',
      color: 'info'
    });

    res.json({
      success: true,
      message: 'Déconnexion réussie'
    });
  } catch (error) {
    logger.error('Erreur lors de la déconnexion:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur interne du serveur'
    });
  }
});

// Dashboard adaptatif selon le rôle
app.get('/api/dashboard', authenticateToken, async (req, res) => {
  try {
    const user = req.user;
    let dashboardData = {
      user: {
        id: user.id,
        name: user.name,
        role: user.role,
        department: user.department,
        avatar: user.avatar,
        gamification: user.gamification,
        preferences: user.preferences
      },
      notifications: {
        unread: notificationSystem.getUnreadCount(user.id),
        recent: notificationSystem.getNotifications(user.id, 5)
      },
      timestamp: new Date()
    };

    // Données spécifiques selon le rôle
    switch (user.role) {
      case 'admin':
        dashboardData.admin = {
          totalRequests: database.requests.size,
          pendingRequests: Array.from(database.requests.values()).filter(r => r.status === 'pending').length,
          completedRequests: Array.from(database.requests.values()).filter(r => r.status === 'completed').length,
          totalUsers: database.users.size,
          systemHealth: {
            status: 'healthy',
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            connections: io.engine.clientsCount
          },
          recentActivity: Array.from(database.requests.values())
            .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
            .slice(0, 5),
          analytics: {
            requestsThisMonth: 45,
            averageResponseTime: 16.8,
            satisfactionRate: 89.2,
            topCategories: ['budget', 'marches_publics', 'transparence']
          }
        };
        break;

      case 'agent':
        const assignedRequests = Array.from(database.requests.values()).filter(r => r.assignee === user.id);
        dashboardData.agent = {
          assignedRequests: assignedRequests.length,
          pendingRequests: assignedRequests.filter(r => r.status === 'pending' || r.status === 'in_progress').length,
          completedToday: assignedRequests.filter(r => 
            r.status === 'completed' && 
            new Date(r.completed_at).toDateString() === new Date().toDateString()
          ).length,
          averageResponseTime: 14.2,
          workload: assignedRequests,
          performance: {
            thisMonth: {
              completed: 12,
              averageTime: 14.2,
              satisfaction: 4.6
            },
            badges: user.gamification.badges,
            ranking: 2
          }
        };
        break;

      case 'citizen':
        const userRequests = Array.from(database.requests.values()).filter(r => r.requester === user.id);
        dashboardData.citizen = {
          myRequests: userRequests.length,
          pendingRequests: userRequests.filter(r => r.status === 'pending' || r.status === 'in_progress').length,
          completedRequests: userRequests.filter(r => r.status === 'completed').length,
          recentRequests: userRequests
            .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
            .slice(0, 3),
          publicStats: {
            totalPublicRequests: 1847,
            averageResponseTime: 16.8,
            successRate: 89.2,
            transparencyIndex: 8.4
          },
          achievements: {
            level: user.gamification.level,
            points: user.gamification.points,
            badges: user.gamification.badges,
            nextLevelPoints: gamificationSystem.levels.find(l => l.level === user.gamification.level + 1)?.minPoints || null
          },
          tips: [
            'Soyez précis dans vos demandes pour obtenir des réponses plus rapides',
            'Consultez les demandes similaires avant de créer la vôtre',
            'Utilisez l\'assistant IA pour obtenir de l\'aide'
          ]
        };
        break;
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

// Gestion des notifications
app.get('/api/notifications', authenticateToken, (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;
    const notifications = notificationSystem.getNotifications(req.user.id, parseInt(limit));
    const unreadCount = notificationSystem.getUnreadCount(req.user.id);

    res.json({
      success: true,
      data: {
        notifications: notifications.slice(parseInt(offset)),
        unreadCount,
        total: notifications.length
      }
    });
  } catch (error) {
    logger.error('Erreur notifications:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du chargement des notifications'
    });
  }
});

app.put('/api/notifications/:id/read', authenticateToken, (req, res) => {
  try {
    const { id } = req.params;
    const success = notificationSystem.markAsRead(req.user.id, id);

    res.json({
      success,
      message: success ? 'Notification marquée comme lue' : 'Notification non trouvée'
    });
  } catch (error) {
    logger.error('Erreur marquage notification:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du marquage de la notification'
    });
  }
});

// Gestion des thèmes
app.get('/api/themes', authenticateToken, (req, res) => {
  try {
    const themes = {
      light: {
        name: 'Clair',
        primary: '#3B82F6',
        secondary: '#10B981',
        background: '#FFFFFF',
        surface: '#F8FAFC',
        text: '#1F2937'
      },
      dark: {
        name: 'Sombre',
        primary: '#60A5FA',
        secondary: '#34D399',
        background: '#111827',
        surface: '#1F2937',
        text: '#F9FAFB'
      },
      government: {
        name: 'Gouvernement',
        primary: '#DC2626',
        secondary: '#059669',
        background: '#FEFEFE',
        surface: '#F5F5F5',
        text: '#374151'
      },
      accessibility: {
        name: 'Accessibilité',
        primary: '#7C3AED',
        secondary: '#F59E0B',
        background: '#FFFBEB',
        surface: '#FEF3C7',
        text: '#1C1917'
      }
    };

    res.json({
      success: true,
      data: {
        themes,
        current: req.user.preferences.theme
      }
    });
  } catch (error) {
    logger.error('Erreur thèmes:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du chargement des thèmes'
    });
  }
});

app.put('/api/themes/:theme', authenticateToken, (req, res) => {
  try {
    const { theme } = req.params;
    const validThemes = ['light', 'dark', 'auto', 'government', 'accessibility'];

    if (!validThemes.includes(theme)) {
      return res.status(400).json({
        success: false,
        error: 'Thème invalide'
      });
    }

    req.user.preferences.theme = theme;

    res.json({
      success: true,
      message: 'Thème mis à jour',
      data: { theme }
    });
  } catch (error) {
    logger.error('Erreur changement thème:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du changement de thème'
    });
  }
});

// Assistant IA
app.post('/api/ai/chat', authenticateToken, async (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({
        success: false,
        error: 'Message requis'
      });
    }

    const response = await aiAssistant.processMessage(message, req.user.id);

    res.json({
      success: true,
      data: response
    });
  } catch (error) {
    logger.error('Erreur assistant IA:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du traitement du message'
    });
  }
});

// Gamification
app.get('/api/gamification/leaderboard', authenticateToken, (req, res) => {
  try {
    const leaderboard = gamificationSystem.getLeaderboard(10);
    
    res.json({
      success: true,
      data: {
        leaderboard,
        userRank: leaderboard.findIndex(u => u.id === req.user.id) + 1 || null
      }
    });
  } catch (error) {
    logger.error('Erreur leaderboard:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du chargement du classement'
    });
  }
});

// Tâches programmées
cron.schedule('0 9 * * *', () => {
  // Notification quotidienne pour les agents
  database.users.forEach(user => {
    if (user.role === 'agent') {
      const assignedRequests = Array.from(database.requests.values())
        .filter(r => r.assignee === user.id && (r.status === 'pending' || r.status === 'in_progress'));
      
      if (assignedRequests.length > 0) {
        notificationSystem.sendNotification(user.id, {
          type: 'daily_reminder',
          title: 'Rappel quotidien',
          message: `Vous avez ${assignedRequests.length} demande(s) en attente`,
          icon: '📋',
          color: 'warning'
        });
      }
    }
  });
  
  logger.info('Notifications quotidiennes envoyées');
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
server.listen(PORT, () => {
  logger.info(`🚀 Serveur SAMA CONAI Premium démarré sur le port ${PORT}`);
  logger.info(`📱 Interface moderne avec WebSockets et IA`);
  logger.info(`🔐 Authentification JWT activée`);
  logger.info(`🎮 Système de gamification activé`);
  logger.info(`🤖 Assistant IA disponible`);
  logger.info(`🔔 Notifications temps réel activées`);
  
  console.log(`
🎉 SAMA CONAI PREMIUM MOBILE v4.0
==================================
🌐 URL: http://localhost:${PORT}
📱 Interface: Ultra-moderne avec glassmorphism
🔐 Auth: JWT + WebSockets
🎮 Gamification: Niveaux, points, badges
🤖 IA: Assistant conversationnel
🔔 Notifications: Temps réel
🎨 Thèmes: Clair/Sombre/Auto/Gouvernement
👥 Rôles: Admin/Agent/Citoyen
📊 Analytics: Temps réel
🚀 Prêt pour une expérience révolutionnaire !
  `);
});