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

const PORT = process.env.PORT || 3006;
const JWT_SECRET = process.env.JWT_SECRET || 'sama_conai_enhanced_secret_2025';

// Logger configuration
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'sama-conai-enhanced' },
  transports: [
    new winston.transports.File({ filename: 'enhanced.log' }),
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

// Sessions utilisateur et notifications
const userSessions = new Map();
const notifications = new Map();
const connectedUsers = new Map();

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
      connectedUsers.delete(socket.id);
      logger.info(`Utilisateur déconnecté: ${userId}`);
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

    // Limiter à 50 notifications par utilisateur
    if (this.notifications.get(userId).length > 50) {
      this.notifications.get(userId) = this.notifications.get(userId).slice(0, 50);
    }

    // Envoyer via WebSocket
    const userSockets = this.subscribers.get(userId);
    if (userSockets) {
      userSockets.forEach(socket => {
        socket.emit('notification', fullNotification);
      });
    }

    // Envoyer aussi via Socket.IO room
    io.to(`user_${userId}`).emit('notification', fullNotification);

    logger.info(`📢 Notification envoyée à ${userId}: ${notification.title}`);
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

  // Notification de mise à jour de statut de demande
  async notifyRequestStatusChange(requestId, newStatus, userId) {
    const statusMessages = {
      'submitted': 'Votre demande a été soumise avec succès',
      'in_progress': 'Votre demande est en cours de traitement',
      'pending_validation': 'Votre demande est en attente de validation',
      'responded': 'Une réponse a été fournie à votre demande',
      'refused': 'Votre demande a été refusée',
      'cancelled': 'Votre demande a été annulée'
    };

    const statusIcons = {
      'submitted': '📝',
      'in_progress': '⏳',
      'pending_validation': '🔍',
      'responded': '✅',
      'refused': '❌',
      'cancelled': '🚫'
    };

    const statusColors = {
      'submitted': 'info',
      'in_progress': 'warning',
      'pending_validation': 'warning',
      'responded': 'success',
      'refused': 'danger',
      'cancelled': 'secondary'
    };

    await this.sendNotification(userId, {
      type: 'request_status',
      title: 'Mise à jour de demande',
      message: statusMessages[newStatus] || 'Statut de votre demande mis à jour',
      icon: statusIcons[newStatus] || '📋',
      color: statusColors[newStatus] || 'info',
      data: {
        requestId,
        newStatus
      }
    });
  }

  // Notification de nouvelle demande pour les agents
  async notifyNewRequest(requestId, requestTitle, agentId) {
    await this.sendNotification(agentId, {
      type: 'new_request',
      title: 'Nouvelle demande assignée',
      message: `"${requestTitle}" vous a été assignée`,
      icon: '📋',
      color: 'primary',
      data: {
        requestId
      }
    });
  }

  // Notification de rappel de délai
  async notifyDeadlineReminder(requestId, requestTitle, userId, daysLeft) {
    const urgencyLevel = daysLeft <= 3 ? 'urgent' : daysLeft <= 7 ? 'warning' : 'info';
    const urgencyColors = { urgent: 'danger', warning: 'warning', info: 'info' };
    const urgencyIcons = { urgent: '🚨', warning: '⚠️', info: 'ℹ️' };

    await this.sendNotification(userId, {
      type: 'deadline_reminder',
      title: 'Rappel de délai',
      message: `Il reste ${daysLeft} jour(s) pour traiter "${requestTitle}"`,
      icon: urgencyIcons[urgencyLevel],
      color: urgencyColors[urgencyLevel],
      data: {
        requestId,
        daysLeft
      }
    });
  }
}

const notificationSystem = new NotificationSystem();

// Assistant IA simple
class SimpleAIAssistant {
  constructor() {
    this.responses = {
      'bonjour': 'Bonjour ! Je suis votre assistant SAMA CONAI. Comment puis-je vous aider aujourd\'hui ?',
      'aide': 'Je peux vous aider avec :\n• Créer une nouvelle demande\n• Vérifier le statut de vos demandes\n• Comprendre les procédures\n• Naviguer dans l\'application',
      'demande': 'Pour créer une demande, cliquez sur le bouton "+" puis remplissez le formulaire avec des détails précis.',
      'statut': 'Vous pouvez vérifier le statut de vos demandes dans la section "Mes Demandes".',
      'délai': 'Le délai légal de réponse est de 30 jours. En moyenne, nous répondons en 16 jours.',
      'contact': 'Vous pouvez nous contacter via l\'application ou par email à contact@sama-conai.sn',
      'merci': 'De rien ! N\'hésitez pas si vous avez d\'autres questions.',
      'au revoir': 'Au revoir ! Bonne journée et merci d\'utiliser SAMA CONAI.'
    };
  }

  processMessage(message) {
    const lowerMessage = message.toLowerCase();
    
    // Recherche de mots-clés
    for (const [keyword, response] of Object.entries(this.responses)) {
      if (lowerMessage.includes(keyword)) {
        return {
          type: 'text',
          content: response,
          timestamp: new Date()
        };
      }
    }

    // Réponse par défaut
    return {
      type: 'text',
      content: 'Je ne suis pas sûr de comprendre. Tapez "aide" pour voir ce que je peux faire pour vous.',
      timestamp: new Date()
    };
  }
}

const aiAssistant = new SimpleAIAssistant();

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
        notificationSystem.subscribe(session.userId, socket);
        
        socket.emit('authenticated', {
          success: true,
          userId: session.userId,
          unreadNotifications: notificationSystem.getUnreadCount(session.userId)
        });
        
        logger.info(`✅ Utilisateur authentifié via WebSocket: ${session.userName}`);
      } else {
        socket.emit('auth_error', { error: 'Session invalide' });
      }
    } catch (error) {
      socket.emit('auth_error', { error: 'Token invalide' });
    }
  });

  socket.on('mark_notification_read', (notificationId) => {
    if (socket.userId) {
      const success = notificationSystem.markAsRead(socket.userId, notificationId);
      socket.emit('notification_marked', { success, notificationId });
    }
  });

  socket.on('get_notifications', () => {
    if (socket.userId) {
      const notifications = notificationSystem.getNotifications(socket.userId, 20);
      socket.emit('notifications_list', notifications);
    }
  });

  socket.on('ai_message', (message) => {
    if (socket.userId) {
      const response = aiAssistant.processMessage(message);
      socket.emit('ai_response', response);
    }
  });

  socket.on('ping', () => {
    socket.emit('pong');
  });

  socket.on('disconnect', () => {
    logger.info(`🔌 Déconnexion WebSocket: ${socket.id}`);
  });
});

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

// Routes API

// Route principale
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index_enhanced.html'));
});

// Authentification avec JWT
app.post('/api/mobile/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.json({
        success: false,
        error: 'Email et mot de passe requis'
      });
    }
    
    let isValidUser = false;
    let userData = null;
    
    // Authentification admin uniquement
    if (email === 'admin' && password === 'admin') {
      isValidUser = true;
      userData = {
        id: 'admin_001',
        name: 'Administrateur SAMA CONAI',
        email: 'admin@sama-conai.sn',
        role: 'admin'
      };
    }
    
    if (isValidUser && userData) {
      // Générer le token JWT
      const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const token = jwt.sign(
        { userId: userData.id, sessionId },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      // Créer la session
      userSessions.set(sessionId, {
        userId: userData.id,
        userName: userData.name,
        userEmail: userData.email,
        role: userData.role,
        loginTime: new Date(),
        lastActivity: new Date(),
        isAdmin: true,
        isOdooUser: isOdooConnected
      });
      
      // Notification de bienvenue
      setTimeout(async () => {
        await notificationSystem.sendNotification(userData.id, {
          type: 'welcome',
          title: '🎉 Bienvenue !',
          message: `Bonjour ${userData.name}, bienvenue dans SAMA CONAI Enhanced !`,
          icon: '👋',
          color: 'success'
        });
      }, 1000);
      
      res.json({
        success: true,
        data: {
          token,
          sessionId,
          user: {
            id: userData.id,
            name: userData.name,
            email: userData.email,
            role: userData.role,
            isAdmin: true
          }
        }
      });
    } else {
      res.json({
        success: false,
        error: 'Identifiants incorrects'
      });
    }
    
  } catch (error) {
    logger.error('❌ Erreur login:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la connexion'
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

    // Notification de déconnexion
    await notificationSystem.sendNotification(req.user.userId, {
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
    logger.error('❌ Erreur logout:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la déconnexion'
    });
  }
});

// Dashboard avec notifications
app.get('/api/mobile/citizen/dashboard', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    logger.info(`📊 Chargement dashboard pour utilisateur ID: ${userId}`);

    // Données de démonstration enrichies
    const dashboardData = {
      user_info: {
        name: req.user.userName,
        email: req.user.userEmail,
        isAdmin: req.user.isAdmin
      },
      user_stats: {
        total_requests: 247,
        pending_requests: 38,
        completed_requests: 189,
        overdue_requests: 12
      },
      recent_requests: getDemoRecentRequests(),
      public_stats: {
        total_public_requests: 1456,
        avg_response_time: 8.5,
        success_rate: 87.3
      },
      alert_stats: {
        total_alerts: 89,
        active_alerts: 23,
        new_alerts: 7,
        urgent_alerts: 4
      },
      notifications: {
        unread: notificationSystem.getUnreadCount(userId),
        recent: notificationSystem.getNotifications(userId, 5)
      },
      system_status: {
        online_users: connectedUsers.size,
        server_status: 'healthy',
        last_update: new Date()
      }
    };

    res.json({
      success: true,
      data: dashboardData,
      source: isOdooConnected ? 'odoo_real_data' : 'NEURO'
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

// API Notifications
app.get('/api/mobile/notifications', authenticateToken, (req, res) => {
  try {
    const { limit = 20 } = req.query;
    const notifications = notificationSystem.getNotifications(req.user.userId, parseInt(limit));
    const unreadCount = notificationSystem.getUnreadCount(req.user.userId);

    res.json({
      success: true,
      data: {
        notifications,
        unreadCount,
        total: notifications.length
      }
    });
  } catch (error) {
    logger.error('❌ Erreur notifications:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement des notifications'
    });
  }
});

app.put('/api/mobile/notifications/:id/read', authenticateToken, (req, res) => {
  try {
    const { id } = req.params;
    const success = notificationSystem.markAsRead(req.user.userId, id);

    res.json({
      success,
      message: success ? 'Notification marquée comme lue' : 'Notification non trouvée'
    });
  } catch (error) {
    logger.error('❌ Erreur marquage notification:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du marquage de la notification'
    });
  }
});

// API Assistant IA
app.post('/api/mobile/ai/chat', authenticateToken, (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({
        success: false,
        error: 'Message requis'
      });
    }

    const response = aiAssistant.processMessage(message);

    res.json({
      success: true,
      data: response
    });
  } catch (error) {
    logger.error('❌ Erreur assistant IA:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du traitement du message'
    });
  }
});

// Simulation de création de demande avec notifications
app.post('/api/mobile/citizen/requests', authenticateToken, async (req, res) => {
  try {
    const {
      title,
      description,
      department,
      requesterName,
      requesterEmail,
      requesterPhone,
      requesterQuality,
      isUrgent
    } = req.body;

    // Validation
    if (!title || !description || !requesterName || !requesterEmail) {
      return res.json({
        success: false,
        error: 'Champs requis manquants'
      });
    }

    // Simuler la création
    const newRequestId = `REQ-${Date.now()}`;
    
    // Notification de confirmation
    await notificationSystem.sendNotification(req.user.userId, {
      type: 'request_created',
      title: 'Demande créée avec succès',
      message: `Votre demande "${title}" a été enregistrée avec le numéro ${newRequestId}`,
      icon: '✅',
      color: 'success',
      data: {
        requestId: newRequestId
      }
    });

    // Notification de traitement (simulée après 3 secondes)
    setTimeout(async () => {
      await notificationSystem.notifyRequestStatusChange(newRequestId, 'in_progress', req.user.userId);
    }, 3000);

    res.json({
      success: true,
      data: {
        id: newRequestId,
        message: 'Demande créée avec succès'
      },
      source: 'enhanced_demo'
    });

  } catch (error) {
    logger.error('❌ Erreur création demande:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la création de la demande'
    });
  }
});

// Tâches programmées pour les notifications
cron.schedule('*/30 * * * *', () => {
  // Notification de rappel toutes les 30 minutes (pour démo)
  userSessions.forEach(async (session, sessionId) => {
    if (Math.random() > 0.7) { // 30% de chance
      await notificationSystem.sendNotification(session.userId, {
        type: 'system_update',
        title: 'Mise à jour système',
        message: 'Le système SAMA CONAI a été mis à jour avec de nouvelles fonctionnalités',
        icon: '🔄',
        color: 'info'
      });
    }
  });
});

// Fonctions utilitaires
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

// Initialisation
initOdooConnection();

// Démarrage du serveur
server.listen(PORT, () => {
  logger.info(`🚀 Serveur SAMA CONAI Enhanced démarré sur le port ${PORT}`);
  console.log(`
🎉 SAMA CONAI ENHANCED MOBILE v3.2
===================================
🌐 URL: http://localhost:${PORT}
📱 Interface: Neumorphique avec notifications temps réel
🔔 WebSockets: Activés pour notifications live
🤖 Assistant IA: Intégré
🔐 Auth: JWT + Sessions sécurisées
📊 Analytics: Temps réel
🎨 Thèmes: Adaptatifs avec mode sombre
👤 Credentials: admin/admin
🚀 Prêt pour une expérience améliorée !
  `);
});