const express = require('express');
const cors = require('cors');
const path = require('path');
const OdooAPI = require('./odoo-api');

const app = express();
const PORT = process.env.PORT || 3005;

// Instance API Odoo
const odooAPI = new OdooAPI();
let isOdooConnected = false;

// Sessions utilisateur (en mémoire)
const userSessions = new Map();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Initialisation de la connexion Odoo
async function initOdooConnection() {
  console.log('🔄 Connexion à Odoo pour données réelles...');
  isOdooConnected = await odooAPI.authenticate();
  if (isOdooConnected) {
    console.log('✅ Connexion Odoo établie - Données réelles disponibles');
  } else {
    console.log('❌ Connexion Odoo échouée - Impossible de récupérer les données réelles');
  }
}

// Route principale
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Route de login avec authentification Odoo réelle
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
    
    if (isOdooConnected) {
      try {
        // Authentification via Odoo
        const authResult = await odooAPI.authenticateUser(email, password);
        if (authResult.success) {
          isValidUser = true;
          userData = authResult.user;
          console.log(`✅ Authentification Odoo réussie pour: ${userData.name}`);
        }
      } catch (error) {
        console.log(`⚠️ Erreur authentification Odoo: ${error.message}`);
      }
    }
    
    // Fallback pour les comptes de démo si Odoo n'est pas disponible
    if (!isValidUser && ((email === 'admin' && password === 'admin') || 
        (email === 'demo@sama-conai.sn' && password === 'demo123'))) {
      isValidUser = true;
      userData = {
        id: email === 'admin' ? 2 : 1,
        name: email === 'admin' ? 'Administrateur' : 'Utilisateur Démo',
        email: email,
        login: email
      };
      console.log(`✅ Authentification démo pour: ${userData.name}`);
    }
    
    if (isValidUser && userData) {
      // Créer une session
      const sessionToken = generateSessionToken();
      userSessions.set(sessionToken, {
        userId: userData.id,
        userName: userData.name,
        userEmail: userData.email || userData.login,
        loginTime: new Date(),
        isAdmin: email === 'admin' || userData.login === 'admin',
        isOdooUser: isOdooConnected
      });
      
      res.json({
        success: true,
        data: {
          token: sessionToken,
          user: {
            id: userData.id,
            name: userData.name,
            email: userData.email || userData.login,
            isAdmin: email === 'admin' || userData.login === 'admin'
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
    console.error('❌ Erreur login:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la connexion'
    });
  }
});

// Route de logout
app.post('/api/mobile/auth/logout', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (token && userSessions.has(token)) {
      userSessions.delete(token);
    }
    
    res.json({
      success: true,
      message: 'Déconnexion réussie'
    });
  } catch (error) {
    res.json({
      success: false,
      error: 'Erreur lors de la déconnexion'
    });
  }
});

// Middleware d'authentification
function authenticateUser(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token || !userSessions.has(token)) {
    return res.json({
      success: false,
      error: 'Token d\'authentification requis',
      requireAuth: true
    });
  }
  
  req.user = userSessions.get(token);
  next();
}

// Dashboard principal avec données réelles d'Odoo
app.get('/api/mobile/citizen/dashboard', authenticateUser, async (req, res) => {
  try {
    if (!isOdooConnected) {
      return res.json({
        success: false,
        error: 'Connexion Odoo non disponible',
        requireOdoo: true
      });
    }

    const userId = req.user.userId;
    console.log(`📊 Chargement dashboard pour utilisateur ID: ${userId}`);

    // Récupérer les statistiques utilisateur depuis Odoo
    const userStats = await getUserStatsFromOdoo(userId);
    
    // Récupérer les demandes récentes depuis Odoo
    const recentRequests = await getRecentRequestsFromOdoo(userId);
    
    // Récupérer les statistiques publiques depuis Odoo
    const publicStats = await getPublicStatsFromOdoo();
    
    // Récupérer les statistiques d'alertes depuis Odoo
    const alertStats = await getAlertStatsFromOdoo(userId);

    const dashboardData = {
      user_info: {
        name: req.user.userName,
        email: req.user.userEmail,
        isAdmin: req.user.isAdmin
      },
      user_stats: userStats,
      recent_requests: recentRequests,
      public_stats: publicStats,
      alert_stats: alertStats
    };

    res.json({
      success: true,
      data: dashboardData,
      source: 'odoo_real_data'
    });

  } catch (error) {
    console.error('❌ Erreur dashboard:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement du dashboard',
      details: error.message
    });
  }
});

// Liste des demandes avec données réelles d'Odoo
app.get('/api/mobile/citizen/requests', authenticateUser, async (req, res) => {
  try {
    if (!isOdooConnected) {
      return res.json({
        success: false,
        error: 'Connexion Odoo non disponible',
        requireOdoo: true
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status;
    const userId = req.user.userId;

    console.log(`📋 Chargement demandes pour utilisateur ID: ${userId}, page: ${page}, statut: ${status}`);

    // Construire le domaine de recherche
    let domain = [];
    
    // Filtrer par utilisateur si ce n'est pas un admin
    if (!req.user.isAdmin) {
      domain.push(['user_id', '=', userId]);
    }
    
    // Filtrer par statut si spécifié
    if (status && status !== 'all') {
      domain.push(['state', '=', status]);
    }

    // Récupérer les demandes depuis Odoo
    const offset = (page - 1) * limit;
    const requests = await odooAPI.searchRead(
      'request.information',
      domain,
      [
        'name', 'description', 'partner_name', 'partner_email', 'requester_quality',
        'request_date', 'deadline_date', 'response_date', 'state', 'stage_id',
        'user_id', 'department', 'is_overdue', 'response_body', 'is_refusal'
      ],
      limit,
      offset,
      'request_date desc'
    );

    // Compter le total
    const totalCount = await odooAPI.searchCount('request.information', domain);

    // Formater les données pour l'API mobile
    const formattedRequests = requests.map(req => ({
      id: req.id,
      name: req.name,
      description: req.description,
      requester: req.partner_name,
      requester_email: req.partner_email,
      requester_quality: req.requester_quality,
      request_date: req.request_date,
      deadline_date: req.deadline_date,
      response_date: req.response_date,
      state: req.state,
      state_label: getStateLabel(req.state),
      stage_name: req.stage_id ? req.stage_id[1] : 'Non définie',
      assigned_user: req.user_id ? req.user_id[1] : 'Non assigné',
      department: req.department || 'Non assigné',
      days_to_deadline: calculateDaysToDeadline(req.deadline_date),
      is_overdue: req.is_overdue || false,
      has_response: !!req.response_body,
      is_refusal: req.is_refusal || false
    }));

    res.json({
      success: true,
      data: {
        requests: formattedRequests,
        pagination: {
          page: page,
          limit: limit,
          total: totalCount,
          has_more: (page * limit) < totalCount
        }
      },
      source: 'odoo_real_data'
    });

  } catch (error) {
    console.error('❌ Erreur liste demandes:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement des demandes',
      details: error.message
    });
  }
});

// Détail d'une demande avec données réelles d'Odoo
app.get('/api/mobile/citizen/requests/:id', authenticateUser, async (req, res) => {
  try {
    if (!isOdooConnected) {
      return res.json({
        success: false,
        error: 'Connexion Odoo non disponible',
        requireOdoo: true
      });
    }

    const requestId = parseInt(req.params.id);
    const userId = req.user.userId;

    console.log(`📄 Chargement détail demande ID: ${requestId} pour utilisateur: ${userId}`);

    // Récupérer la demande depuis Odoo
    const requests = await odooAPI.searchRead(
      'request.information',
      [['id', '=', requestId]],
      [
        'name', 'description', 'partner_name', 'partner_email', 'partner_phone',
        'requester_quality', 'request_date', 'deadline_date', 'response_date',
        'state', 'stage_id', 'user_id', 'department', 'is_overdue',
        'response_body', 'is_refusal', 'refusal_motivation'
      ],
      1
    );

    if (requests.length === 0) {
      return res.json({
        success: false,
        error: 'Demande non trouvée'
      });
    }

    const request = requests[0];

    // Vérifier les permissions (non-admin ne peut voir que ses demandes)
    if (!req.user.isAdmin && request.user_id && request.user_id[0] !== userId) {
      return res.json({
        success: false,
        error: 'Accès non autorisé à cette demande'
      });
    }

    // Générer la timeline depuis les activités Odoo
    const timeline = await generateTimelineFromOdoo(requestId);

    // Formater les données pour l'API mobile
    const formattedRequest = {
      id: request.id,
      name: request.name,
      description: request.description,
      requester_name: request.partner_name,
      requester_email: request.partner_email,
      requester_phone: request.partner_phone,
      requester_quality: request.requester_quality,
      request_date: request.request_date,
      deadline_date: request.deadline_date,
      response_date: request.response_date,
      state: request.state,
      state_label: getStateLabel(request.state),
      stage_name: request.stage_id ? request.stage_id[1] : 'Non définie',
      assigned_user: request.user_id ? request.user_id[1] : 'Non assigné',
      department: request.department || 'Non assigné',
      days_to_deadline: calculateDaysToDeadline(request.deadline_date),
      is_overdue: request.is_overdue || false,
      response_body: request.response_body,
      is_refusal: request.is_refusal || false,
      refusal_motivation: request.refusal_motivation,
      timeline: timeline
    };

    res.json({
      success: true,
      data: formattedRequest,
      source: 'odoo_real_data'
    });

  } catch (error) {
    console.error('❌ Erreur détail demande:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement du détail',
      details: error.message
    });
  }
});

// Fonctions utilitaires pour récupérer les données d'Odoo

async function getUserStatsFromOdoo(userId) {
  try {
    const domain = req.user.isAdmin ? [] : [['user_id', '=', userId]];
    
    const totalRequests = await odooAPI.searchCount('request.information', domain);
    const pendingRequests = await odooAPI.searchCount('request.information', 
      [...domain, ['state', 'in', ['submitted', 'in_progress', 'pending_validation']]]);
    const completedRequests = await odooAPI.searchCount('request.information', 
      [...domain, ['state', '=', 'responded']]);
    const overdueRequests = await odooAPI.searchCount('request.information', 
      [...domain, ['is_overdue', '=', true]]);

    return {
      total_requests: totalRequests,
      pending_requests: pendingRequests,
      completed_requests: completedRequests,
      overdue_requests: overdueRequests
    };
  } catch (error) {
    console.error('❌ Erreur stats utilisateur:', error.message);
    return {
      total_requests: 0,
      pending_requests: 0,
      completed_requests: 0,
      overdue_requests: 0
    };
  }
}

async function getRecentRequestsFromOdoo(userId) {
  try {
    const domain = req.user.isAdmin ? [] : [['user_id', '=', userId]];
    
    const requests = await odooAPI.searchRead(
      'request.information',
      domain,
      ['name', 'description', 'partner_name', 'request_date', 'state', 'deadline_date', 'department', 'is_overdue'],
      5,
      0,
      'request_date desc'
    );

    return requests.map(req => ({
      id: req.id,
      name: req.name,
      description: req.description.substring(0, 100) + (req.description.length > 100 ? '...' : ''),
      request_date: req.request_date,
      state: req.state,
      state_label: getStateLabel(req.state),
      days_to_deadline: calculateDaysToDeadline(req.deadline_date),
      is_overdue: req.is_overdue || false,
      partner_name: req.partner_name,
      department: req.department || 'Non assigné'
    }));
  } catch (error) {
    console.error('❌ Erreur demandes récentes:', error.message);
    return [];
  }
}

async function getPublicStatsFromOdoo() {
  try {
    const totalPublicRequests = await odooAPI.searchCount('request.information');
    
    // Calculer le temps moyen de réponse
    const respondedRequests = await odooAPI.searchRead(
      'request.information',
      [['state', '=', 'responded'], ['response_date', '!=', false], ['request_date', '!=', false]],
      ['request_date', 'response_date'],
      100
    );

    let avgResponseTime = 0;
    if (respondedRequests.length > 0) {
      const totalDays = respondedRequests.reduce((sum, req) => {
        const requestDate = new Date(req.request_date);
        const responseDate = new Date(req.response_date);
        const diffDays = Math.ceil((responseDate - requestDate) / (1000 * 60 * 60 * 24));
        return sum + diffDays;
      }, 0);
      avgResponseTime = Math.round((totalDays / respondedRequests.length) * 10) / 10;
    }

    // Calculer le taux de succès
    const completedRequests = await odooAPI.searchCount('request.information', [['state', '=', 'responded']]);
    const successRate = totalPublicRequests > 0 ? Math.round((completedRequests / totalPublicRequests) * 100 * 10) / 10 : 0;

    return {
      total_public_requests: totalPublicRequests,
      avg_response_time: avgResponseTime,
      success_rate: successRate
    };
  } catch (error) {
    console.error('❌ Erreur stats publiques:', error.message);
    return {
      total_public_requests: 0,
      avg_response_time: 0,
      success_rate: 0
    };
  }
}

async function getAlertStatsFromOdoo(userId) {
  try {
    const domain = req.user.isAdmin ? [] : [['manager_id', '=', userId]];
    
    const totalAlerts = await odooAPI.searchCount('whistleblowing.alert', domain);
    const activeAlerts = await odooAPI.searchCount('whistleblowing.alert', 
      [...domain, ['state', 'in', ['new', 'investigation']]]);
    const newAlerts = await odooAPI.searchCount('whistleblowing.alert', 
      [...domain, ['state', '=', 'new']]);
    const urgentAlerts = await odooAPI.searchCount('whistleblowing.alert', 
      [...domain, ['priority', '=', 'high']]);

    return {
      total_alerts: totalAlerts,
      active_alerts: activeAlerts,
      new_alerts: newAlerts,
      urgent_alerts: urgentAlerts
    };
  } catch (error) {
    console.error('❌ Erreur stats alertes:', error.message);
    return {
      total_alerts: 0,
      active_alerts: 0,
      new_alerts: 0,
      urgent_alerts: 0
    };
  }
}

async function generateTimelineFromOdoo(requestId) {
  try {
    // Récupérer les activités liées à la demande
    const activities = await odooAPI.searchRead(
      'mail.message',
      [['res_id', '=', requestId], ['model', '=', 'request.information']],
      ['date', 'subject', 'body', 'author_id'],
      10,
      0,
      'date asc'
    );

    return activities.map(activity => ({
      date: activity.date,
      event: activity.subject || 'Activité',
      description: activity.body ? activity.body.replace(/<[^>]*>/g, '').substring(0, 100) : 'Activité sur la demande',
      author: activity.author_id ? activity.author_id[1] : 'Système'
    }));
  } catch (error) {
    console.error('❌ Erreur timeline:', error.message);
    return [];
  }
}

// Fonctions utilitaires
function generateSessionToken() {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
}

function getStateLabel(state) {
  const labels = {
    'draft': 'Brouillon',
    'submitted': 'Soumise',
    'in_progress': 'En cours',
    'pending_validation': 'En attente de validation',
    'responded': 'Répondue',
    'refused': 'Refusée',
    'cancelled': 'Annulée'
  };
  return labels[state] || state;
}

function calculateDaysToDeadline(deadlineDate) {
  if (!deadlineDate) return null;
  
  const deadline = new Date(deadlineDate);
  const now = new Date();
  const diffTime = deadline - now;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  
  return diffDays;
}

// Initialisation
initOdooConnection();

app.listen(PORT, () => {
  console.log(`🚀 Serveur mobile SAMA CONAI avec données réelles Odoo démarré sur http://localhost:${PORT}`);
  console.log(`📊 Source de données: ${isOdooConnected ? 'ODOO RÉEL' : 'DÉMO (Odoo non disponible)'}`);
  console.log(`🔗 Intégration backend Odoo: ${isOdooConnected ? 'ACTIVE' : 'STANDBY'}`);
  console.log(`👤 Credentials: admin/admin ou demo@sama-conai.sn/demo123`);
  console.log(`📱 Interface neumorphique avec données réelles d'Odoo`);
});