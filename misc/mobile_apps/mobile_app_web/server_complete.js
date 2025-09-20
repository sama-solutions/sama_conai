const express = require('express');
const cors = require('cors');
const path = require('path');
const OdooAPI = require('./odoo-api');

const app = express();
const PORT = process.env.PORT || 3007;

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
  console.log('🔄 Connexion à Odoo pour données réelles SAMA CONAI...');
  isOdooConnected = await odooAPI.authenticate();
  if (isOdooConnected) {
    console.log('✅ Connexion Odoo établie - Données réelles SAMA CONAI disponibles');
    console.log('👤 Mode Admin Global : Toutes les données assignées à l\'administrateur');
  } else {
    console.log('❌ Connexion Odoo échouée - Vérifiez que le serveur Odoo est démarré');
  }
}

// Route principale - Interface complète
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'sama_conai_complete.html'));
});

// Route alternative pour l'interface avancée
app.get('/advanced', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'sama_conai_advanced.html'));
});

// Route alternative pour l'interface corrigée
app.get('/correct', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'sama_conai_fixed.html'));
});

// Route pour l'interface avec layers corrigés
app.get('/fixed-layers', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'sama_conai_fixed_layers.html'));
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
    
    // Seul admin est autorisé - toutes les données lui sont assignées
    if (email === 'admin' && password === 'admin') {
      isValidUser = true;
      userData = {
        id: 2,
        name: 'Administrateur SAMA CONAI',
        email: 'admin@sama-conai.sn',
        login: 'admin',
        is_admin: true
      };
      console.log(`✅ Authentification admin réussie : ${userData.name}`);
    }
    
    if (isValidUser && userData) {
      // Créer une session admin
      const sessionToken = generateSessionToken();
      userSessions.set(sessionToken, {
        userId: userData.id,
        userName: userData.name,
        userEmail: userData.email,
        loginTime: new Date(),
        isAdmin: true,
        isOdooUser: isOdooConnected,
        hasGlobalAccess: true
      });
      
      res.json({
        success: true,
        data: {
          token: sessionToken,
          user: {
            id: userData.id,
            name: userData.name,
            email: userData.email,
            isAdmin: true,
            hasGlobalAccess: true
          }
        }
      });
    } else {
      res.json({
        success: false,
        error: 'Seul l\'administrateur peut accéder au système'
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

// NIVEAU 1: Dashboard principal avec données globales admin
app.get('/api/mobile/level1/dashboard', authenticateUser, async (req, res) => {
  try {
    console.log(`📊 Chargement dashboard admin global`);

    if (!isOdooConnected) {
      return res.json({
        success: false,
        error: 'Connexion Odoo non disponible',
        requireOdoo: true
      });
    }

    // Récupérer TOUTES les données (admin global)
    const [
      totalRequests,
      pendingRequests,
      completedRequests,
      overdueRequests,
      totalAlerts,
      activeAlerts,
      newAlerts,
      urgentAlerts,
      recentRequests,
      recentAlerts
    ] = await Promise.all([
      odooAPI.searchCount('request.information'),
      odooAPI.searchCount('request.information', [['state', 'in', ['submitted', 'in_progress', 'pending_validation']]]),
      odooAPI.searchCount('request.information', [['state', '=', 'responded']]),
      odooAPI.searchCount('request.information', [['is_overdue', '=', true]]),
      odooAPI.searchCount('whistleblowing.alert'),
      odooAPI.searchCount('whistleblowing.alert', [['state', 'in', ['new', 'investigation']]]),
      odooAPI.searchCount('whistleblowing.alert', [['state', '=', 'new']]),
      odooAPI.searchCount('whistleblowing.alert', [['priority', 'in', ['high', 'urgent']]]),
      odooAPI.searchRead('request.information', [], 
        ['name', 'partner_name', 'request_date', 'state', 'deadline_date'], 5, 0, 'request_date desc'),
      odooAPI.searchRead('whistleblowing.alert', [], 
        ['name', 'category', 'alert_date', 'state', 'priority'], 5, 0, 'alert_date desc')
    ]);

    const dashboardData = {
      user_info: {
        name: req.user.userName,
        email: req.user.userEmail,
        isAdmin: true,
        hasGlobalAccess: true
      },
      global_stats: {
        total_requests: totalRequests,
        pending_requests: pendingRequests,
        completed_requests: completedRequests,
        overdue_requests: overdueRequests,
        total_alerts: totalAlerts,
        active_alerts: activeAlerts,
        new_alerts: newAlerts,
        urgent_alerts: urgentAlerts
      },
      recent_activity: {
        requests: recentRequests.map(req => ({
          id: req.id,
          name: req.name,
          partner_name: req.partner_name,
          request_date: req.request_date,
          state: req.state,
          state_label: getStateLabel(req.state),
          days_to_deadline: calculateDaysToDeadline(req.deadline_date)
        })),
        alerts: recentAlerts.map(alert => ({
          id: alert.id,
          name: alert.name,
          category: alert.category,
          alert_date: alert.alert_date,
          state: alert.state,
          priority: alert.priority
        }))
      }
    };

    res.json({
      success: true,
      data: dashboardData,
      source: 'odoo_admin_global',
      level: 1
    });

  } catch (error) {
    console.error('❌ Erreur dashboard admin:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement du dashboard admin',
      details: error.message
    });
  }
});

// NIVEAU 2: Liste des demandes d'information (toutes pour admin)
app.get('/api/mobile/level2/requests', authenticateUser, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status;

    console.log(`📋 Chargement TOUTES les demandes (admin global), page: ${page}, statut: ${status}`);

    if (!isOdooConnected) {
      return res.json({
        success: false,
        error: 'Connexion Odoo non disponible',
        requireOdoo: true
      });
    }

    // Admin voit TOUTES les demandes
    let domain = [];
    if (status && status !== 'all') {
      domain.push(['state', '=', status]);
    }

    const offset = (page - 1) * limit;
    const [requests, totalCount] = await Promise.all([
      odooAPI.searchRead('request.information', domain, [
        'name', 'description', 'partner_name', 'partner_email', 'requester_quality',
        'request_date', 'deadline_date', 'response_date', 'state', 'stage_id',
        'user_id', 'department_id', 'is_overdue', 'response_body', 'is_refusal'
      ], limit, offset, 'request_date desc'),
      odooAPI.searchCount('request.information', domain)
    ]);

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
      department: req.department_id ? req.department_id[1] : 'Non assigné',
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
      source: 'odoo_admin_global',
      level: 2
    });

  } catch (error) {
    console.error('❌ Erreur liste demandes admin:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement des demandes',
      details: error.message
    });
  }
});

// NIVEAU 2: Liste des alertes (toutes pour admin)
app.get('/api/mobile/level2/alerts', authenticateUser, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status;

    console.log(`🚨 Chargement TOUTES les alertes (admin global), page: ${page}, statut: ${status}`);

    if (!isOdooConnected) {
      return res.json({
        success: false,
        error: 'Connexion Odoo non disponible',
        requireOdoo: true
      });
    }

    // Admin voit TOUTES les alertes
    let domain = [];
    if (status && status !== 'all') {
      domain.push(['state', '=', status]);
    }

    const offset = (page - 1) * limit;
    const [alerts, totalCount] = await Promise.all([
      odooAPI.searchRead('whistleblowing.alert', domain, [
        'name', 'description', 'category', 'alert_date', 'state', 'stage_id',
        'priority', 'is_anonymous', 'reporter_name', 'reporter_email', 'manager_id'
      ], limit, offset, 'alert_date desc'),
      odooAPI.searchCount('whistleblowing.alert', domain)
    ]);

    const formattedAlerts = alerts.map(alert => ({
      id: alert.id,
      name: alert.name,
      description: alert.description,
      category: alert.category,
      category_label: getCategoryLabel(alert.category),
      alert_date: alert.alert_date,
      state: alert.state,
      state_label: getAlertStateLabel(alert.state),
      stage_name: alert.stage_id ? alert.stage_id[1] : 'Non définie',
      priority: alert.priority,
      priority_label: getPriorityLabel(alert.priority),
      is_anonymous: alert.is_anonymous,
      reporter_name: alert.is_anonymous ? 'Anonyme' : alert.reporter_name,
      reporter_email: alert.is_anonymous ? 'Anonyme' : alert.reporter_email,
      manager: alert.manager_id ? alert.manager_id[1] : 'Non assigné'
    }));

    res.json({
      success: true,
      data: {
        alerts: formattedAlerts,
        pagination: {
          page: page,
          limit: limit,
          total: totalCount,
          has_more: (page * limit) < totalCount
        }
      },
      source: 'odoo_admin_global',
      level: 2
    });

  } catch (error) {
    console.error('❌ Erreur liste alertes admin:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement des alertes',
      details: error.message
    });
  }
});

// NIVEAU 3: Détail d'une demande d'information
app.get('/api/mobile/level3/request/:id', authenticateUser, async (req, res) => {
  try {
    const requestId = parseInt(req.params.id);
    console.log(`📄 Chargement détail demande ID: ${requestId} (admin global)`);

    if (!isOdooConnected) {
      return res.json({
        success: false,
        error: 'Connexion Odoo non disponible',
        requireOdoo: true
      });
    }

    const requests = await odooAPI.searchRead('request.information', 
      [['id', '=', requestId]], [
        'name', 'description', 'partner_name', 'partner_email', 'partner_phone',
        'requester_quality', 'request_date', 'deadline_date', 'response_date',
        'state', 'stage_id', 'user_id', 'department_id', 'is_overdue',
        'response_body', 'is_refusal', 'refusal_reason_id', 'refusal_motivation'
      ], 1);

    if (requests.length === 0) {
      return res.json({
        success: false,
        error: 'Demande non trouvée'
      });
    }

    const request = requests[0];

    // Générer la timeline depuis les activités Odoo
    const timeline = await generateTimelineFromOdoo(requestId);

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
      department: request.department_id ? request.department_id[1] : 'Non assigné',
      days_to_deadline: calculateDaysToDeadline(request.deadline_date),
      is_overdue: request.is_overdue || false,
      response_body: request.response_body,
      is_refusal: request.is_refusal || false,
      refusal_reason: request.refusal_reason_id ? request.refusal_reason_id[1] : null,
      refusal_motivation: request.refusal_motivation,
      timeline: timeline,
      odoo_url: `/web#id=${request.id}&model=request.information&view_type=form`
    };

    res.json({
      success: true,
      data: formattedRequest,
      source: 'odoo_admin_global',
      level: 3
    });

  } catch (error) {
    console.error('❌ Erreur détail demande admin:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement du détail',
      details: error.message
    });
  }
});

// NIVEAU 3: Détail d'une alerte
app.get('/api/mobile/level3/alert/:id', authenticateUser, async (req, res) => {
  try {
    const alertId = parseInt(req.params.id);
    console.log(`🚨 Chargement détail alerte ID: ${alertId} (admin global)`);

    if (!isOdooConnected) {
      return res.json({
        success: false,
        error: 'Connexion Odoo non disponible',
        requireOdoo: true
      });
    }

    const alerts = await odooAPI.searchRead('whistleblowing.alert', 
      [['id', '=', alertId]], [
        'name', 'description', 'category', 'alert_date', 'state', 'stage_id',
        'priority', 'is_anonymous', 'reporter_name', 'reporter_email', 
        'manager_id', 'investigation_notes'
      ], 1);

    if (alerts.length === 0) {
      return res.json({
        success: false,
        error: 'Alerte non trouvée'
      });
    }

    const alert = alerts[0];

    // Générer la timeline depuis les activités Odoo
    const timeline = await generateTimelineFromOdoo(alertId, 'whistleblowing.alert');

    const formattedAlert = {
      id: alert.id,
      name: alert.name,
      description: alert.description,
      category: alert.category,
      category_label: getCategoryLabel(alert.category),
      alert_date: alert.alert_date,
      state: alert.state,
      state_label: getAlertStateLabel(alert.state),
      stage_name: alert.stage_id ? alert.stage_id[1] : 'Non définie',
      priority: alert.priority,
      priority_label: getPriorityLabel(alert.priority),
      is_anonymous: alert.is_anonymous,
      reporter_name: alert.is_anonymous ? 'Anonyme' : alert.reporter_name,
      reporter_email: alert.is_anonymous ? 'Anonyme' : alert.reporter_email,
      manager: alert.manager_id ? alert.manager_id[1] : 'Non assigné',
      investigation_notes: alert.investigation_notes,
      timeline: timeline,
      odoo_url: `/web#id=${alert.id}&model=whistleblowing.alert&view_type=form`
    };

    res.json({
      success: true,
      data: formattedAlert,
      source: 'odoo_admin_global',
      level: 3
    });

  } catch (error) {
    console.error('❌ Erreur détail alerte admin:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement du détail',
      details: error.message
    });
  }
});

// Route pour créer une nouvelle demande (assignée automatiquement à admin)
app.post('/api/mobile/create/request', authenticateUser, async (req, res) => {
  try {
    if (!isOdooConnected) {
      return res.json({
        success: false,
        error: 'Connexion Odoo non disponible',
        requireOdoo: true
      });
    }

    const {
      title,
      description,
      department,
      requesterName,
      requesterEmail,
      requesterPhone,
      requesterQuality
    } = req.body;

    console.log(`📝 Création nouvelle demande par admin global`);

    // Validation des champs requis
    if (!title || !description || !requesterName || !requesterEmail || !requesterQuality) {
      return res.json({
        success: false,
        error: 'Champs requis manquants'
      });
    }

    // Préparer les données pour Odoo - assignées à admin
    const requestData = {
      name: title,
      description: description,
      partner_name: requesterName,
      partner_email: requesterEmail,
      partner_phone: requesterPhone || '',
      requester_quality: requesterQuality,
      department_id: department || false,
      state: 'submitted',
      request_date: new Date().toISOString(),
      user_id: req.user.userId // Assigné à l'admin connecté
    };

    const newRequestId = await odooAPI.create('request.information', requestData);

    if (newRequestId) {
      console.log(`✅ Demande créée avec succès - ID: ${newRequestId} (assignée à admin)`);
      
      res.json({
        success: true,
        data: {
          id: newRequestId,
          message: 'Demande créée avec succès et assignée à l\'administrateur',
          odoo_url: `/web#id=${newRequestId}&model=request.information&view_type=form`
        },
        source: 'odoo_admin_global'
      });
    } else {
      throw new Error('Échec de la création de la demande');
    }

  } catch (error) {
    console.error('❌ Erreur création demande admin:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la création de la demande',
      details: error.message
    });
  }
});

// Fonctions utilitaires

async function generateTimelineFromOdoo(recordId, model = 'request.information') {
  try {
    const activities = await odooAPI.searchRead('mail.message', 
      [['res_id', '=', recordId], ['model', '=', model]], 
      ['date', 'subject', 'body', 'author_id'], 10, 0, 'date asc');

    return activities.map(activity => ({
      date: activity.date,
      event: activity.subject || 'Activité',
      description: activity.body ? activity.body.replace(/<[^>]*>/g, '').substring(0, 100) : 'Activité sur l\'enregistrement',
      author: activity.author_id ? activity.author_id[1] : 'Système'
    }));
  } catch (error) {
    console.error('❌ Erreur timeline:', error.message);
    return [];
  }
}

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

function getAlertStateLabel(state) {
  const labels = {
    'new': 'Nouvelle',
    'preliminary_assessment': 'Évaluation préliminaire',
    'investigation': 'Enquête',
    'resolved': 'Résolue',
    'closed': 'Fermée'
  };
  return labels[state] || state;
}

function getCategoryLabel(category) {
  const labels = {
    'corruption': 'Corruption',
    'fraud': 'Fraude',
    'abuse_of_power': 'Abus de pouvoir',
    'discrimination': 'Discrimination',
    'harassment': 'Harcèlement',
    'other': 'Autre'
  };
  return labels[category] || category;
}

function getPriorityLabel(priority) {
  const labels = {
    'low': 'Faible',
    'medium': 'Moyenne',
    'high': 'Élevée',
    'urgent': 'Urgente'
  };
  return labels[priority] || priority;
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
  console.log(`🚀 Serveur SAMA CONAI Complet démarré sur http://localhost:${PORT}`);
  console.log(`📊 Source de données: ${isOdooConnected ? 'ODOO RÉEL (Admin Global)' : 'ATTENTE CONNEXION ODOO'}`)
  console.log(`🔗 Intégration backend Odoo: ${isOdooConnected ? 'ACTIVE' : 'STANDBY'}`);
  console.log(`👤 Mode: Admin Global - Toutes les données assignées à l'administrateur`);
  console.log(`📱 Navigation 3 niveaux: ACTIVE`);
  console.log(`🎨 Theme switcher: CORRIGÉ`);
  console.log(`📈 URLs disponibles:`);
  console.log(`   - http://localhost:${PORT}/ (Interface complète)`);
  console.log(`   - http://localhost:${PORT}/advanced (Interface avancée)`);
  console.log(`   - http://localhost:${PORT}/correct (Interface corrigée)`);
  console.log(`🔧 Backend Odoo: http://localhost:8077`);
});