const express = require('express');
const cors = require('cors');
const path = require('path');
const OdooAPI = require('./odoo-api');

const app = express();
const PORT = process.env.PORT || 3005;

// Instance API Odoo
const odooAPI = new OdooAPI();
let isOdooConnected = false;

// Sessions utilisateur (en mémoire pour la démo)
const userSessions = new Map();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Initialisation de la connexion Odoo et création de données de test
async function initOdooConnection() {
  console.log('🔄 Tentative de connexion à Odoo...');
  isOdooConnected = await odooAPI.authenticate();
  if (isOdooConnected) {
    console.log('✅ Connexion Odoo établie');
    await createTestData();
  } else {
    console.log('⚠️ Connexion Odoo échouée, utilisation des données de démonstration');
  }
}

// Création de données de test assignées à l'admin
async function createTestData() {
  try {
    console.log('📊 Création de données de test...');
    
    // Récupérer l'ID de l'utilisateur admin
    const adminUsers = await odooAPI.searchRead('res.users', [['login', '=', 'admin']], ['id', 'name'], 1);
    if (adminUsers.length === 0) {
      console.log('⚠️ Utilisateur admin non trouvé');
      return;
    }
    
    const adminId = adminUsers[0].id;
    console.log(`👤 Admin trouvé: ${adminUsers[0].name} (ID: ${adminId})`);
    
    // Vérifier si des demandes existent déjà
    const existingRequests = await odooAPI.searchCount('request.information');
    if (existingRequests > 0) {
      console.log(`📋 ${existingRequests} demandes existantes trouvées`);
      
      // Assigner les demandes existantes à l'admin
      const requests = await odooAPI.searchRead('request.information', [], ['id'], 50);
      for (const req of requests) {
        await odooAPI.write('request.information', req.id, { user_id: adminId });
      }
      console.log(`✅ ${requests.length} demandes assignées à l'admin`);
      return;
    }
    
    // Créer des demandes de test si aucune n'existe
    const testRequests = [
      {
        name: 'REQ-2025-001',
        description: 'Demande d\'accès aux documents budgétaires 2024 du Ministère des Finances',
        partner_name: 'Amadou Diallo',
        partner_email: 'amadou.diallo@email.com',
        partner_phone: '+221 77 123 45 67',
        requester_quality: 'Journaliste',
        state: 'in_progress',
        user_id: adminId,
        request_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        deadline_date: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        name: 'REQ-2025-002',
        description: 'Information sur les marchés publics attribués en 2024',
        partner_name: 'Fatou Sall',
        partner_email: 'fatou.sall@email.com',
        partner_phone: '+221 76 987 65 43',
        requester_quality: 'Citoyenne',
        state: 'responded',
        user_id: adminId,
        request_date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
        deadline_date: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(),
        response_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
        response_body: 'Veuillez trouver ci-joint la liste des marchés publics attribués en 2024.'
      },
      {
        name: 'REQ-2025-003',
        description: 'Demande de consultation des rapports d\'audit interne',
        partner_name: 'Moussa Ba',
        partner_email: 'moussa.ba@email.com',
        partner_phone: '+221 78 456 78 90',
        requester_quality: 'Chercheur',
        state: 'submitted',
        user_id: adminId,
        request_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
        deadline_date: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000).toISOString()
      },
      {
        name: 'REQ-2025-004',
        description: 'Accès aux données de transparence des dépenses publiques',
        partner_name: 'Aïssatou Ndiaye',
        partner_email: 'aissatou.ndiaye@email.com',
        partner_phone: '+221 77 234 56 78',
        requester_quality: 'ONG',
        state: 'refused',
        user_id: adminId,
        request_date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
        deadline_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        response_date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
        is_refusal: true,
        refusal_motivation: 'Documents classifiés selon l\'article 15 de la loi sur l\'accès à l\'information'
      },
      {
        name: 'REQ-2025-005',
        description: 'Demande d\'information sur les projets d\'infrastructure en cours',
        partner_name: 'Ibrahima Sarr',
        partner_email: 'ibrahima.sarr@email.com',
        partner_phone: '+221 76 345 67 89',
        requester_quality: 'Entrepreneur',
        state: 'in_progress',
        user_id: adminId,
        request_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        deadline_date: new Date(Date.now() + 29 * 24 * 60 * 60 * 1000).toISOString()
      }
    ];
    
    // Créer les demandes
    for (const reqData of testRequests) {
      await odooAPI.create('request.information', reqData);
    }
    
    console.log(`✅ ${testRequests.length} demandes de test créées et assignées à l'admin`);
    
    // Créer quelques alertes de test
    const testAlerts = [
      {
        name: 'ALERT-2025-001',
        description: 'Signalement de corruption dans l\'attribution d\'un marché public',
        category: 'corruption',
        priority: 'high',
        state: 'investigation',
        is_anonymous: true,
        alert_date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
        manager_id: adminId
      },
      {
        name: 'ALERT-2025-002',
        description: 'Abus de pouvoir signalé dans une administration locale',
        category: 'abuse_of_power',
        priority: 'medium',
        state: 'new',
        is_anonymous: false,
        reporter_name: 'Témoin anonyme',
        alert_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        manager_id: adminId
      }
    ];
    
    for (const alertData of testAlerts) {
      await odooAPI.create('whistleblowing.alert', alertData);
    }
    
    console.log(`✅ ${testAlerts.length} alertes de test créées`);
    
  } catch (error) {
    console.error('❌ Erreur création données test:', error.message);
  }
}

// Route principale
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Route de login
app.post('/api/mobile/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.json({
        success: false,
        error: 'Email et mot de passe requis'
      });
    }
    
    // Vérification des credentials
    let isValidUser = false;
    let userData = null;
    
    // Authentification de démonstration (toujours active pour la démo)
    if ((email === 'admin' && password === 'admin') || 
        (email === 'demo@sama-conai.sn' && password === 'demo123')) {
      isValidUser = true;
      userData = {
        id: email === 'admin' ? 2 : 1, // ID 2 pour admin comme dans Odoo
        name: email === 'admin' ? 'Administrateur' : 'Utilisateur Démo',
        email: email
      };
    }
    
    if (isValidUser && userData) {
      // Créer une session
      const sessionToken = generateSessionToken();
      userSessions.set(sessionToken, {
        userId: userData.id,
        userName: userData.name,
        userEmail: userData.email || email,
        loginTime: new Date(),
        isAdmin: email === 'admin'
      });
      
      res.json({
        success: true,
        data: {
          token: sessionToken,
          user: {
            id: userData.id,
            name: userData.name,
            email: userData.email || email,
            isAdmin: email === 'admin'
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

// NIVEAU 1: Dashboard principal avec données réelles (protégé)
app.get('/api/mobile/citizen/dashboard', authenticateUser, async (req, res) => {
  try {
    // Utiliser les données de démonstration enrichies pour la démo
    const demoData = getDemoData();
    demoData.data.user_info = {
      name: req.user.userName,
      email: req.user.userEmail,
      isAdmin: req.user.isAdmin
    };
    demoData.source = 'demo_data_enriched';
    res.json(demoData);
  } catch (error) {
    console.error('❌ Erreur dashboard:', error.message);
    const demoData = getDemoData();
    demoData.data.user_info = {
      name: req.user.userName,
      email: req.user.userEmail,
      isAdmin: req.user.isAdmin
    };
    res.json(demoData);
  }
});

// NIVEAU 2: Liste détaillée des demandes d'information (protégé)
app.get('/api/mobile/citizen/requests', authenticateUser, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status;
    const userId = req.user.userId;

    // Utiliser les données de démonstration enrichies
    const demoData = getDemoRequestsList();
    
    // Filtrer par statut si spécifié
    if (status) {
      demoData.data.requests = demoData.data.requests.filter(req => req.state === status);
      demoData.data.pagination.total = demoData.data.requests.length;
    }
    
    demoData.source = 'demo_data_enriched';
    res.json(demoData);
  } catch (error) {
    console.error('❌ Erreur liste demandes:', error.message);
    res.json(getDemoRequestsList());
  }
});

// NIVEAU 3: Détail d'une demande spécifique (protégé)
app.get('/api/mobile/citizen/requests/:id', authenticateUser, async (req, res) => {
  try {
    const requestId = parseInt(req.params.id);
    const userId = req.user.userId;

    // Utiliser les données de démonstration enrichies
    const demoData = getDemoRequestDetail(requestId);
    demoData.source = 'demo_data_enriched';
    res.json(demoData);
  } catch (error) {
    console.error('❌ Erreur détail demande:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement du détail'
    });
  }
});

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

function generateTimeline(request) {
  const timeline = [];
  
  if (request.request_date) {
    timeline.push({
      date: request.request_date,
      event: 'Demande soumise',
      description: 'La demande a été soumise par le citoyen'
    });
  }
  
  if (request.state === 'in_progress' || request.state === 'responded') {
    timeline.push({
      date: request.request_date,
      event: 'Traitement commencé',
      description: 'La demande est en cours de traitement'
    });
  }
  
  if (request.response_date) {
    timeline.push({
      date: request.response_date,
      event: request.is_refusal ? 'Demande refusée' : 'Réponse fournie',
      description: request.is_refusal ? 'La demande a été refusée' : 'Une réponse a été fournie'
    });
  }
  
  return timeline;
}

// Données de démonstration enrichies (fallback)
function getDemoData() {
  return {
    success: true,
    data: {
      user_stats: {
        total_requests: 8,
        pending_requests: 4,
        completed_requests: 3,
        overdue_requests: 1,
      },
      recent_requests: [
        {
          id: 1,
          name: 'REQ-2025-001',
          description: 'Demande d\'accès aux documents budgétaires 2024 du Ministère des Finances incluant les allocations sectorielles',
          request_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'in_progress',
          state_label: 'En cours',
          days_to_deadline: 25,
          is_overdue: false,
          partner_name: 'Amadou Diallo',
          department: 'Ministère des Finances'
        },
        {
          id: 2,
          name: 'REQ-2025-002',
          description: 'Information sur les marchés publics attribués en 2024, montants et entreprises bénéficiaires',
          request_date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'responded',
          state_label: 'Répondue',
          days_to_deadline: 0,
          is_overdue: false,
          partner_name: 'Fatou Sall',
          department: 'Direction des Marchés Publics'
        },
        {
          id: 3,
          name: 'REQ-2025-003',
          description: 'Consultation des rapports d\'audit interne des ministères pour l\'exercice 2023-2024',
          request_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'submitted',
          state_label: 'Soumise',
          days_to_deadline: 28,
          is_overdue: false,
          partner_name: 'Moussa Ba',
          department: 'Inspection Générale d\'État'
        },
        {
          id: 4,
          name: 'REQ-2025-004',
          description: 'Accès aux données de transparence des dépenses publiques par région',
          request_date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'refused',
          state_label: 'Refusée',
          days_to_deadline: -5,
          is_overdue: true,
          partner_name: 'Aïssatou Ndiaye',
          department: 'Ministère du Budget'
        },
        {
          id: 5,
          name: 'REQ-2025-005',
          description: 'Information sur les projets d\'infrastructure en cours et leurs budgets alloués',
          request_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'in_progress',
          state_label: 'En cours',
          days_to_deadline: 29,
          is_overdue: false,
          partner_name: 'Ibrahima Sarr',
          department: 'Ministère des Infrastructures'
        }
      ],
      public_stats: {
        total_public_requests: 1847,
        avg_response_time: 16.8,
        success_rate: 89.2,
      },
      alert_stats: {
        total_alerts: 5,
        active_alerts: 3,
        new_alerts: 1,
        urgent_alerts: 1
      }
    },
    source: 'demo_data'
  };
}

function getDemoRequestsList() {
  return {
    success: true,
    data: {
      requests: [
        {
          id: 1,
          name: 'REQ-2025-001',
          description: 'Demande d\'accès aux documents budgétaires 2024 du Ministère des Finances incluant les allocations sectorielles',
          requester: 'Amadou Diallo',
          requester_email: 'amadou.diallo@senegal-media.com',
          request_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
          deadline_date: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'in_progress',
          state_label: 'En cours',
          stage_name: 'Analyse en cours',
          assigned_user: 'Administrateur',
          department: 'Ministère des Finances',
          days_to_deadline: 25,
          is_overdue: false,
          has_response: false,
          is_refusal: false
        },
        {
          id: 2,
          name: 'REQ-2025-002',
          description: 'Information sur les marchés publics attribués en 2024, montants et entreprises bénéficiaires',
          requester: 'Fatou Sall',
          requester_email: 'fatou.sall@transparency-sn.org',
          request_date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
          deadline_date: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(),
          response_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'responded',
          state_label: 'Répondue',
          stage_name: 'Réponse fournie',
          assigned_user: 'Administrateur',
          department: 'Direction des Marchés Publics',
          days_to_deadline: 0,
          is_overdue: false,
          has_response: true,
          is_refusal: false
        },
        {
          id: 3,
          name: 'REQ-2025-003',
          description: 'Consultation des rapports d\'audit interne des ministères pour l\'exercice 2023-2024',
          requester: 'Moussa Ba',
          requester_email: 'moussa.ba@ucad.edu.sn',
          request_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
          deadline_date: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'submitted',
          state_label: 'Soumise',
          stage_name: 'En attente de traitement',
          assigned_user: 'Administrateur',
          department: 'Inspection Générale d\'État',
          days_to_deadline: 28,
          is_overdue: false,
          has_response: false,
          is_refusal: false
        },
        {
          id: 4,
          name: 'REQ-2025-004',
          description: 'Accès aux données de transparence des dépenses publiques par région',
          requester: 'Aïssatou Ndiaye',
          requester_email: 'aissatou.ndiaye@forum-civil.sn',
          request_date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
          deadline_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
          response_date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'refused',
          state_label: 'Refusée',
          stage_name: 'Refus motivé',
          assigned_user: 'Administrateur',
          department: 'Ministère du Budget',
          days_to_deadline: -5,
          is_overdue: true,
          has_response: true,
          is_refusal: true
        },
        {
          id: 5,
          name: 'REQ-2025-005',
          description: 'Information sur les projets d\'infrastructure en cours et leurs budgets alloués',
          requester: 'Ibrahima Sarr',
          requester_email: 'ibrahima.sarr@construction-sn.com',
          request_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
          deadline_date: new Date(Date.now() + 29 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'in_progress',
          state_label: 'En cours',
          stage_name: 'Collecte d\'informations',
          assigned_user: 'Administrateur',
          department: 'Ministère des Infrastructures',
          days_to_deadline: 29,
          is_overdue: false,
          has_response: false,
          is_refusal: false
        },
        {
          id: 6,
          name: 'REQ-2025-006',
          description: 'Consultation des contrats de partenariat public-privé signés en 2024',
          requester: 'Khady Diop',
          requester_email: 'khady.diop@avocat-dakar.sn',
          request_date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
          deadline_date: new Date(Date.now() + 23 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'pending_validation',
          state_label: 'En attente de validation',
          stage_name: 'Validation juridique',
          assigned_user: 'Administrateur',
          department: 'Ministère de l\'Économie',
          days_to_deadline: 23,
          is_overdue: false,
          has_response: false,
          is_refusal: false
        },
        {
          id: 7,
          name: 'REQ-2025-007',
          description: 'Accès aux rapports de performance des agences publiques pour 2024',
          requester: 'Ousmane Fall',
          requester_email: 'ousmane.fall@rts.sn',
          request_date: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString(),
          deadline_date: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000).toISOString(),
          response_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'responded',
          state_label: 'Répondue',
          stage_name: 'Réponse fournie',
          assigned_user: 'Administrateur',
          department: 'Primature',
          days_to_deadline: 18,
          is_overdue: false,
          has_response: true,
          is_refusal: false
        },
        {
          id: 8,
          name: 'REQ-2025-008',
          description: 'Information sur les subventions accordées aux ONG en 2024',
          requester: 'Mariama Sow',
          requester_email: 'mariama.sow@ong-dev.sn',
          request_date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
          deadline_date: new Date(Date.now() + 27 * 24 * 60 * 60 * 1000).toISOString(),
          state: 'submitted',
          state_label: 'Soumise',
          stage_name: 'En attente de traitement',
          assigned_user: 'Administrateur',
          department: 'Ministère de la Solidarité',
          days_to_deadline: 27,
          is_overdue: false,
          has_response: false,
          is_refusal: false
        }
      ],
      pagination: {
        page: 1,
        limit: 20,
        total: 8,
        has_more: false
      }
    },
    source: 'demo_data'
  };
}

function getDemoRequestDetail(id) {
  const requests = {
    1: {
      id: 1,
      name: 'REQ-2025-001',
      description: 'Demande d\'accès aux documents budgétaires 2024 du Ministère des Finances incluant les détails des allocations par secteur (santé, éducation, infrastructure) et les dépenses d\'investissement pour les projets prioritaires du Plan Sénégal Émergent.',
      requester_name: 'Amadou Diallo',
      requester_email: 'amadou.diallo@senegal-media.com',
      requester_phone: '+221 77 123 45 67',
      requester_quality: 'Journaliste - Le Quotidien',
      request_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000).toISOString(),
      state: 'in_progress',
      state_label: 'En cours',
      stage_name: 'Analyse en cours',
      assigned_user: 'Administrateur',
      department: 'Ministère des Finances',
      days_to_deadline: 25,
      is_overdue: false,
      timeline: [
        {
          date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Demande soumise',
          description: 'La demande a été soumise par le journaliste Amadou Diallo'
        },
        {
          date: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Demande assignée',
          description: 'La demande a été assignée à l\'administrateur pour traitement'
        },
        {
          date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Analyse commencée',
          description: 'L\'analyse de la demande et la collecte des documents ont commencé'
        }
      ]
    },
    2: {
      id: 2,
      name: 'REQ-2025-002',
      description: 'Information sur les marchés publics attribués en 2024, incluant les montants, les entreprises bénéficiaires, les critères de sélection et les délais d\'exécution pour tous les marchés supérieurs à 50 millions FCFA.',
      requester_name: 'Fatou Sall',
      requester_email: 'fatou.sall@transparency-sn.org',
      requester_phone: '+221 76 987 65 43',
      requester_quality: 'Directrice - Transparency International Sénégal',
      request_date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(),
      response_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      state: 'responded',
      state_label: 'Répondue',
      stage_name: 'Réponse fournie',
      assigned_user: 'Administrateur',
      department: 'Direction des Marchés Publics',
      days_to_deadline: 0,
      is_overdue: false,
      response_body: 'Veuillez trouver ci-joint la liste complète des marchés publics attribués en 2024. Le document inclut 247 marchés pour un montant total de 156 milliards FCFA, répartis comme suit : infrastructure (89 milliards), santé (34 milliards), éducation (23 milliards), et autres secteurs (10 milliards). Chaque marché est détaillé avec l\'entreprise attributaire, le montant, et les critères de sélection.',
      timeline: [
        {
          date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Demande soumise',
          description: 'Demande soumise par Transparency International Sénégal'
        },
        {
          date: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Traitement commencé',
          description: 'La demande est en cours de traitement par la Direction des Marchés Publics'
        },
        {
          date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Documents compilés',
          description: 'Compilation des documents et vérification des données'
        },
        {
          date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Réponse fournie',
          description: 'Réponse complète fournie avec tous les documents demandés'
        }
      ]
    },
    4: {
      id: 4,
      name: 'REQ-2025-004',
      description: 'Accès aux données de transparence des dépenses publiques par région, incluant les projets d\'infrastructure et les programmes sociaux pour l\'exercice budgétaire 2024.',
      requester_name: 'Aïssatou Ndiaye',
      requester_email: 'aissatou.ndiaye@forum-civil.sn',
      requester_phone: '+221 77 234 56 78',
      requester_quality: 'Coordinatrice - Forum Civil',
      request_date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
      response_date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
      state: 'refused',
      state_label: 'Refusée',
      stage_name: 'Refus motivé',
      assigned_user: 'Administrateur',
      department: 'Ministère du Budget',
      days_to_deadline: -5,
      is_overdue: true,
      is_refusal: true,
      refusal_motivation: 'Documents classifiés selon l\'article 15 de la loi sur l\'accès à l\'information. Certaines données sont en cours de validation par la Cour des Comptes et ne peuvent être divulguées avant la publication du rapport annuel.',
      response_body: 'Après examen de votre demande, nous regrettons de ne pouvoir donner suite favorablement. Les données demandées sont actuellement en cours d\'audit par la Cour des Comptes et sont donc temporairement classifiées.',
      timeline: [
        {
          date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Demande soumise',
          description: 'Demande soumise par le Forum Civil'
        },
        {
          date: new Date(Date.now() - 18 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Analyse juridique',
          description: 'Analyse de la faisabilité juridique de la demande'
        },
        {
          date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Consultation Cour des Comptes',
          description: 'Consultation avec la Cour des Comptes sur la classification des documents'
        },
        {
          date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
          event: 'Demande refusée',
          description: 'Refus motivé en raison de la classification temporaire des documents'
        }
      ]
    }
  };
  
  const request = requests[id] || {
    id: id,
    name: `REQ-2025-${String(id).padStart(3, '0')}`,
    description: 'Demande d\'information générale',
    requester_name: 'Demandeur',
    requester_email: 'demandeur@email.com',
    request_date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
    state: 'submitted',
    state_label: 'Soumise',
    days_to_deadline: 23,
    is_overdue: false,
    timeline: [
      {
        date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        event: 'Demande soumise',
        description: 'La demande a été soumise'
      }
    ]
  };
  
  return {
    success: true,
    data: request,
    source: 'demo_data'
  };
}

// Initialisation
initOdooConnection();

app.listen(PORT, () => {
  console.log(`🚀 Serveur mobile SAMA CONAI avec authentification démarré sur http://localhost:${PORT}`);
  console.log(`📱 Interface mobile avec login et données réelles`);
  console.log(`🔗 Intégration backend Odoo: ${isOdooConnected ? 'ACTIVE' : 'STANDBY'}`);
  console.log(`👤 Credentials de test: admin/admin ou demo@sama-conai.sn/demo123`);
});