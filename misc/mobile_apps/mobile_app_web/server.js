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
    // MODIFICATION: Seul admin est autorisé, toutes les données lui sont assignées
    if (!isValidUser && (email === 'admin' && password === 'admin')) {
      isValidUser = true;
      userData = {
        id: 2,
        name: 'Administrateur SAMA CONAI',
        email: 'admin',
        login: 'admin'
      };
      console.log(`✅ Authentification admin pour: ${userData.name}`);
    }
    
    if (isValidUser && userData) {
      // Créer une session
      const sessionToken = generateSessionToken();
      userSessions.set(sessionToken, {
        userId: userData.id,
        userName: userData.name,
        userEmail: userData.email || userData.login,
        loginTime: new Date(),
        isAdmin: true, // MODIFICATION: Tous les utilisateurs connectés sont admin
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
            isAdmin: true // MODIFICATION: Tous les utilisateurs connectés sont admin
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

// Dashboard principal avec données réelles d'Odoo ou données de démonstration
app.get('/api/mobile/citizen/dashboard', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.userId;
    console.log(`📊 Chargement dashboard pour utilisateur ID: ${userId}`);

    let userStats, recentRequests, publicStats, alertStats;
    let dataSource = 'NEURO';

    if (isOdooConnected) {
      // Récupérer les données depuis Odoo
      userStats = await getUserStatsFromOdoo(userId, req.user.isAdmin);
      recentRequests = await getRecentRequestsFromOdoo(userId, req.user.isAdmin);
      publicStats = await getPublicStatsFromOdoo();
      alertStats = await getAlertStatsFromOdoo(userId, req.user.isAdmin);
      dataSource = 'odoo_real_data';
    } else {
      // Utiliser des données de démonstration réalistes pour l'admin
      userStats = getDemoUserStats();
      recentRequests = getDemoRecentRequests();
      publicStats = getDemoPublicStats();
      alertStats = getDemoAlertStats();
      dataSource = 'NEURO';
    }

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
      source: dataSource
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

// Liste des demandes avec données réelles d'Odoo ou données de démonstration
app.get('/api/mobile/citizen/requests', authenticateUser, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status;
    const userId = req.user.userId;

    console.log(`📋 Chargement demandes pour utilisateur ID: ${userId}, page: ${page}, statut: ${status}`);

    let formattedRequests = [];
    let totalCount = 0;
    let dataSource = 'NEURO';

    if (isOdooConnected) {
      // Récupérer depuis Odoo
      let domain = [];
      
      if (status && status !== 'all') {
        domain.push(['state', '=', status]);
      }

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

      totalCount = await odooAPI.searchCount('request.information', domain);

      formattedRequests = requests.map(req => ({
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
      dataSource = 'odoo_real_data';
    } else {
      // Utiliser des données de démonstration
      const demoRequests = getDemoRequestsList();
      
      // Filtrer par statut si nécessaire
      let filteredRequests = demoRequests;
      if (status && status !== 'all') {
        filteredRequests = demoRequests.filter(req => req.state === status);
      }
      
      // Pagination
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      formattedRequests = filteredRequests.slice(startIndex, endIndex);
      totalCount = filteredRequests.length;
      dataSource = 'NEURO';
    }

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
      source: dataSource
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

    // MODIFICATION: Admin peut voir toutes les demandes
    // Pas de vérification de permissions car admin voit tout

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

// Route pour créer une nouvelle demande
app.post('/api/mobile/citizen/requests', authenticateUser, async (req, res) => {
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
      requesterQuality,
      isUrgent,
      urgentJustification,
      isPublicInterest
    } = req.body;

    console.log(`📝 Création nouvelle demande par: ${req.user.userName}`);

    // Validation des champs requis
    if (!title || !description || !requesterName || !requesterEmail || !requesterQuality) {
      return res.json({
        success: false,
        error: 'Champs requis manquants'
      });
    }

    // Préparer les données pour Odoo
    const requestData = {
      name: title,
      description: description,
      partner_name: requesterName,
      partner_email: requesterEmail,
      partner_phone: requesterPhone || '',
      requester_quality: requesterQuality,
      department: department || 'autre',
      state: 'submitted',
      request_date: new Date().toISOString().split('T')[0],
      is_urgent: isUrgent || false,
      urgent_justification: urgentJustification || '',
      is_public_interest: isPublicInterest || false,
      user_id: req.user.userId // Assigner à l'utilisateur connecté
    };

    // Créer la demande dans Odoo
    const newRequestId = await odooAPI.create('request.information', requestData);

    if (newRequestId) {
      console.log(`✅ Demande créée avec succès - ID: ${newRequestId}`);
      
      res.json({
        success: true,
        data: {
          id: newRequestId,
          message: 'Demande créée avec succès'
        },
        source: 'odoo_real_data'
      });
    } else {
      throw new Error('Échec de la création de la demande');
    }

  } catch (error) {
    console.error('❌ Erreur création demande:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la création de la demande',
      details: error.message
    });
  }
});

// Fonctions utilitaires pour récupérer les données d'Odoo

async function getUserStatsFromOdoo(userId, isAdmin = false) {
  try {
    // MODIFICATION: Admin voit toutes les données, pas de filtrage par utilisateur
    const domain = [];
    
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

async function getRecentRequestsFromOdoo(userId, isAdmin = false) {
  try {
    // MODIFICATION: Admin voit toutes les données, pas de filtrage par utilisateur
    const domain = [];
    
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
      description: req.description ? req.description.substring(0, 100) + (req.description.length > 100 ? '...' : '') : 'Pas de description',
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

async function getAlertStatsFromOdoo(userId, isAdmin = false) {
  try {
    // MODIFICATION: Admin voit toutes les données, pas de filtrage par utilisateur
    const domain = [];
    
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

// ========================================= //
// DONNÉES DE DÉMONSTRATION POUR L'ADMIN    //
// ========================================= //

function getDemoUserStats() {
  return {
    total_requests: 247,
    pending_requests: 38,
    completed_requests: 189,
    overdue_requests: 12
  };
}

function getDemoPublicStats() {
  return {
    total_public_requests: 1456,
    avg_response_time: 8.5,
    success_rate: 87.3
  };
}

function getDemoAlertStats() {
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
    },
    {
      id: 1004,
      name: 'Données sanitaires COVID-19',
      description: 'Statistiques détaillées sur la gestion de la pandémie COVID-19 au Sénégal.',
      request_date: '2024-01-10',
      state: 'responded',
      state_label: 'Répondue',
      days_to_deadline: null,
      is_overdue: false,
      partner_name: 'Aissatou Ndiaye',
      department: 'Santé'
    },
    {
      id: 1005,
      name: 'Rapport sur la transparence judiciaire',
      description: 'Demande d\'informations sur les procédures de nomination des magistrats.',
      request_date: '2024-01-08',
      state: 'submitted',
      state_label: 'Soumise',
      days_to_deadline: 15,
      is_overdue: false,
      partner_name: 'Mamadou Sy',
      department: 'Justice'
    }
  ];
}

function getDemoRequestsList() {
  const baseRequests = getDemoRecentRequests();
  
  // Ajouter plus de demandes pour la liste complète
  const additionalRequests = [
    {
      id: 1006,
      name: 'Budget infrastructure routière',
      description: 'Détails sur l\'allocation budgétaire pour les infrastructures routières 2023.',
      request_date: '2024-01-05',
      state: 'in_progress',
      state_label: 'En cours',
      days_to_deadline: 10,
      is_overdue: false,
      partner_name: 'Cheikh Fall',
      department: 'Infrastructures',
      requester: 'Cheikh Fall',
      requester_email: 'cheikh.fall@email.com',
      requester_quality: 'journaliste',
      deadline_date: '2024-01-25',
      response_date: null,
      stage_name: 'En traitement',
      assigned_user: 'Admin SAMA CONAI',
      has_response: false,
      is_refusal: false
    },
    {
      id: 1007,
      name: 'Statistiques éducation nationale',
      description: 'Taux de scolarisation et résultats aux examens nationaux 2023.',
      request_date: '2024-01-03',
      state: 'responded',
      state_label: 'Répondue',
      days_to_deadline: null,
      is_overdue: false,
      partner_name: 'Mariama Diop',
      department: 'Education',
      requester: 'Mariama Diop',
      requester_email: 'mariama.diop@email.com',
      requester_quality: 'chercheur',
      deadline_date: '2024-01-18',
      response_date: '2024-01-15',
      stage_name: 'Terminée',
      assigned_user: 'Admin SAMA CONAI',
      has_response: true,
      is_refusal: false
    },
    {
      id: 1008,
      name: 'Gestion des déchets Dakar',
      description: 'Informations sur la gestion des déchets solides dans la région de Dakar.',
      request_date: '2023-12-28',
      state: 'refused',
      state_label: 'Refusée',
      days_to_deadline: null,
      is_overdue: false,
      partner_name: 'Ibrahima Sarr',
      department: 'Environnement',
      requester: 'Ibrahima Sarr',
      requester_email: 'ibrahima.sarr@email.com',
      requester_quality: 'citoyen',
      deadline_date: '2024-01-12',
      response_date: '2024-01-10',
      stage_name: 'Refusée',
      assigned_user: 'Admin SAMA CONAI',
      has_response: true,
      is_refusal: true
    },
    {
      id: 1009,
      name: 'Politique agricole nationale',
      description: 'Détails sur les subventions agricoles et programmes de soutien aux agriculteurs.',
      request_date: '2023-12-25',
      state: 'submitted',
      state_label: 'Soumise',
      days_to_deadline: 5,
      is_overdue: true,
      partner_name: 'Awa Thiam',
      department: 'Agriculture',
      requester: 'Awa Thiam',
      requester_email: 'awa.thiam@email.com',
      requester_quality: 'ong',
      deadline_date: '2024-01-09',
      response_date: null,
      stage_name: 'En attente',
      assigned_user: 'Admin SAMA CONAI',
      has_response: false,
      is_refusal: false
    },
    {
      id: 1010,
      name: 'Transparence des nominations',
      description: 'Procédures et critères de nomination aux postes de direction dans l\'administration.',
      request_date: '2023-12-20',
      state: 'in_progress',
      state_label: 'En cours',
      days_to_deadline: 3,
      is_overdue: false,
      partner_name: 'Moussa Kane',
      department: 'Fonction Publique',
      requester: 'Moussa Kane',
      requester_email: 'moussa.kane@email.com',
      requester_quality: 'avocat',
      deadline_date: '2024-01-18',
      response_date: null,
      stage_name: 'En validation',
      assigned_user: 'Admin SAMA CONAI',
      has_response: false,
      is_refusal: false
    }
  ];
  
  // Ajouter les champs manquants aux demandes de base
  const completeBaseRequests = baseRequests.map(req => ({
    ...req,
    requester: req.partner_name,
    requester_email: `${req.partner_name.toLowerCase().replace(' ', '.')}@email.com`,
    requester_quality: 'citoyen',
    deadline_date: req.days_to_deadline ? new Date(Date.now() + req.days_to_deadline * 24 * 60 * 60 * 1000).toISOString().split('T')[0] : null,
    response_date: req.state === 'responded' ? new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] : null,
    stage_name: req.state === 'submitted' ? 'En attente' : req.state === 'in_progress' ? 'En traitement' : 'Terminée',
    assigned_user: 'Admin SAMA CONAI',
    has_response: req.state === 'responded',
    is_refusal: false
  }));
  
  return [...completeBaseRequests, ...additionalRequests];
}

// Initialisation
initOdooConnection();

app.listen(PORT, () => {
  console.log(`🚀 Serveur mobile SAMA CONAI avec données réelles Odoo démarré sur http://localhost:${PORT}`);
  console.log(`📊 Source de données: ${isOdooConnected ? 'ODOO RÉEL' : 'NEURO (Données de démonstration)'}`);
  console.log(`🔗 Intégration backend Odoo: ${isOdooConnected ? 'ACTIVE' : 'STANDBY'}`);
  console.log(`👤 Credentials: admin/admin`);
  console.log(`📱 Interface neumorphique avec données administrateur`);
  console.log(`📈 Statistiques admin: 247 demandes totales, 38 en cours, 189 terminées`);
});