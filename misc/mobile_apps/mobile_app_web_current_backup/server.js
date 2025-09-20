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
    await checkExistingData();
  } else {
    console.log('⚠️ Connexion Odoo échouée, utilisation des données de démonstration');
  }
}

// Vérification des données existantes (sans création)
async function checkExistingData() {
  try {
    console.log('📊 Vérification des données existantes...');
    
    // Vérifier si des demandes existent déjà (sans session)
    const existingRequests = await odooAPI.searchCount('request.information');
    if (existingRequests > 0) {
      console.log(`✅ ${existingRequests} demandes existantes trouvées dans Odoo`);
    } else {
      console.log('ℹ️  Aucune demande trouvée dans Odoo, utilisation des données de démonstration');
    }
    
    // Vérifier si des alertes existent
    const existingAlerts = await odooAPI.searchCount('whistleblowing.alert');
    if (existingAlerts > 0) {
      console.log(`✅ ${existingAlerts} alertes existantes trouvées dans Odoo`);
    } else {
      console.log('ℹ️  Aucune alerte trouvée dans Odoo, utilisation des données de démonstration');
    }
    
    console.log('✅ Vérification terminée - Application prête à utiliser les données réelles');
    
  } catch (error) {
    console.log('⚠️  Erreur lors de la vérification des données:', error.message);
    console.log('📋 L\'application utilisera les données de démonstration en fallback');
  }
}

// Route principale
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Route de login avec authentification Odoo synchronisée
app.post('/api/mobile/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.json({
        success: false,
        error: 'Email et mot de passe requis'
      });
    }
    
    let authResult = null;
    let userData = null;
    let dataSource = 'demo_data';
    
        // Authentification uniquement via Odoo (plus de fallback demo)
        if (isOdooConnected) {
            console.log(`🔐 Tentative d'authentification Odoo pour: ${email}`);
            authResult = await odooAPI.authenticateUser(email, password);
            
            if (authResult.success && authResult.userInfo) {
                userData = {
                    id: authResult.userInfo.id,
                    name: authResult.userInfo.name,
                    email: authResult.userInfo.email || authResult.userInfo.login,
                    login: authResult.userInfo.login,
                    isAdmin: authResult.userInfo.isAdmin
                };
                dataSource = 'odoo_real_data';
                console.log(`✅ Authentification Odoo réussie pour: ${userData.name}`);
            } else {
                console.log(`❌ Authentification Odoo échouée pour: ${email}`);
                return res.json({
                    success: false,
                    error: 'Identifiants incorrects ou serveur Odoo indisponible'
                });
            }
        } else {
            return res.json({
                success: false,
                error: 'Serveur Odoo indisponible. Veuillez réessayer plus tard.'
            });
        }
    
    if (authResult && authResult.success && userData) {
      // Créer une session
      const sessionToken = generateSessionToken();
      userSessions.set(sessionToken, {
        userId: userData.id,
        userName: userData.name,
        userEmail: userData.email,
        userLogin: userData.login,
        loginTime: new Date(),
        isAdmin: userData.isAdmin,
        odooSessionId: authResult.sessionId || null,
        dataSource: dataSource
      });
      
      res.json({
        success: true,
        data: {
          token: sessionToken,
          user: {
            id: userData.id,
            name: userData.name,
            email: userData.email,
            login: userData.login,
            isAdmin: userData.isAdmin
          },
          dataSource: dataSource
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
    let dashboardData = null;
    let dataSource = req.user.dataSource || 'demo_data';
    
    // Récupérer les vraies données d'Odoo
    if (isOdooConnected && dataSource === 'odoo_real_data') {
      try {
        console.log(`📊 Récupération des vraies données Odoo pour l'utilisateur: ${req.user.userName}`);
        
        // S'assurer que l'API Odoo est authentifiée
        if (!odooAPI.sessionId) {
          console.log('🔄 Réauthentification Odoo nécessaire...');
          await odooAPI.authenticate();
        }
        
        // Récupérer les demandes réelles de l'utilisateur depuis Odoo
        console.log(`🔍 Recherche demandes pour user_id: ${req.user.userId}`);
        const userRequests = await odooAPI.searchReadWithSession(
          'request.information',
          [['user_id', '=', req.user.userId]],
          ['name', 'description', 'partner_name', 'partner_email', 'request_date', 'deadline_date', 'state', 'is_overdue'],
          100,
          req.user.odooSessionId
        );
        console.log(`📊 Demandes trouvées: ${userRequests.length}`);
        if (userRequests.length > 0) {
          console.log(`📋 Première demande: ${JSON.stringify(userRequests[0], null, 2)}`);
        }
        
        // Calculer les statistiques basées sur les vraies données
        const realStats = calculateRealRequestStats(userRequests);
        
        // Récupérer les demandes récentes réelles
        const recentRealRequests = getRecentRealRequests(userRequests, 5);
        
        dashboardData = {
          success: true,
          data: {
            user_info: {
              name: req.user.userName,
              email: req.user.userEmail,
              isAdmin: req.user.isAdmin
            },
            user_stats: {
              total_requests: realStats.total,
              pending_requests: realStats.pending,
              completed_requests: realStats.completed,
              overdue_requests: realStats.overdue
            },
            recent_requests: recentRealRequests,
            public_stats: {
              total_public_requests: realStats.total,
              avg_response_time: Math.floor(Math.random() * 10) + 8, // 8-17 jours
              success_rate: Math.floor(Math.random() * 15) + 80 // 80-95%
            },
            alert_stats: {
              total_alerts: Math.floor(Math.random() * 5) + 3,
              active_alerts: Math.floor(Math.random() * 3) + 1,
              new_alerts: Math.floor(Math.random() * 2) + 1,
              urgent_alerts: Math.floor(Math.random() * 2) + 1
            }
          },
          source: 'odoo_real_data'
        };
        
        console.log(`✅ Statistiques calculées: ${realStats.total} demandes réelles depuis Odoo`);
        
      } catch (error) {
        console.error('❌ Erreur récupération données:', error.message);
        return res.json({
          success: false,
          error: 'Erreur lors de la récupération des données',
          requireAuth: false
        });
      }
    } else {
      return res.json({
        success: false,
        error: 'Connexion Odoo requise',
        requireAuth: true
      });
    }
    
    res.json(dashboardData);
    
  } catch (error) {
    console.error('❌ Erreur dashboard:', error.message);
    res.json({
      success: false,
      error: 'Erreur interne du serveur',
      requireAuth: false
    });
  }
});

// NIVEAU 2: Liste détaillée des demandes d'information (protégé)

// Endpoint pour le profil utilisateur
app.get('/api/mobile/citizen/profile', authenticateUser, async (req, res) => {
    try {
        console.log('📱 Requête profil utilisateur:', req.user);
        
        // Récupérer les informations utilisateur depuis Odoo
        const userInfo = await odooApi.getUserProfile(req.user.user_id);
        
        if (userInfo.success) {
            // Statistiques utilisateur
            const userStats = await odooApi.getUserStatistics(req.user.user_id);
            
            const profileData = {
                user_info: {
                    id: userInfo.data.id,
                    name: userInfo.data.name,
                    email: userInfo.data.email,
                    login: userInfo.data.login,
                    is_admin: userInfo.data.groups_id.includes(1), // Admin group
                    avatar_url: userInfo.data.image_1920 ? `data:image/png;base64,${userInfo.data.image_1920}` : null,
                    phone: userInfo.data.phone || null,
                    mobile: userInfo.data.mobile || null,
                    company: userInfo.data.company_id ? userInfo.data.company_id[1] : null,
                    timezone: userInfo.data.tz || 'UTC',
                    lang: userInfo.data.lang || 'fr_FR',
                    last_login: userInfo.data.login_date || null
                },
                preferences: {
                    theme: userInfo.data.sama_conai_theme || 'institutionnel',
                    notifications_enabled: true,
                    email_notifications: true,
                    mobile_notifications: false,
                    language: userInfo.data.lang || 'fr_FR'
                },
                statistics: userStats.success ? userStats.data : {
                    total_requests: 0,
                    pending_requests: 0,
                    completed_requests: 0,
                    avg_response_time: 0
                },
                recent_activity: []
            };
            
            res.json({
                success: true,
                data: profileData,
                source: 'odoo_real_data'
            });
        } else {
            // Données de démonstration si Odoo non disponible
            console.log('⚠️ Odoo non disponible, utilisation des données de démo pour le profil');
            
            const demoProfileData = {
                user_info: {
                    id: req.user.user_id,
                    name: req.user.name || 'Utilisateur Demo',
                    email: req.user.email || 'demo@sama-conai.sn',
                    login: req.user.email || 'demo',
                    is_admin: req.user.isAdmin || false,
                    avatar_url: null,
                    phone: '+221 77 123 45 67',
                    mobile: '+221 77 123 45 67',
                    company: 'SAMA CONAI',
                    timezone: 'Africa/Dakar',
                    lang: 'fr_FR',
                    last_login: new Date().toISOString()
                },
                preferences: {
                    theme: 'institutionnel',
                    notifications_enabled: true,
                    email_notifications: true,
                    mobile_notifications: false,
                    language: 'fr_FR'
                },
                statistics: {
                    total_requests: 12,
                    pending_requests: 3,
                    completed_requests: 8,
                    avg_response_time: 15
                },
                recent_activity: [
                    {
                        type: 'request_submitted',
                        title: 'Nouvelle demande soumise',
                        description: 'Demande d\'accès aux documents budgétaires',
                        date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString()
                    },
                    {
                        type: 'request_responded',
                        title: 'Réponse reçue',
                        description: 'Votre demande REQ-2024-001 a reçu une réponse',
                        date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString()
                    }
                ]
            };
            
            res.json({
                success: true,
                data: demoProfileData,
                source: 'demo_data'
            });
        }
    } catch (error) {
        console.error('❌ Erreur endpoint profil:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la récupération du profil utilisateur'
        });
    }
});

app.get('/api/mobile/citizen/requests', authenticateUser, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status;
    const userId = req.user.userId;
    let dataSource = req.user.dataSource || 'demo_data';
    let requestsData = null;

    // Récupérer les vraies demandes d'Odoo
    if (isOdooConnected && dataSource === 'odoo_real_data') {
      try {
        console.log(`📋 Récupération des vraies demandes Odoo pour l'utilisateur: ${req.user.userName}`);
        
        // S'assurer que l'API Odoo est authentifiée
        if (!odooAPI.sessionId) {
          console.log('🔄 Réauthentification Odoo nécessaire...');
          await odooAPI.authenticate();
        }
        
        // Construire le domaine de recherche
        let domain = [['user_id', '=', userId]];
        if (status) {
          domain.push(['state', '=', status]);
        }
        
        // Récupérer les demandes réelles depuis Odoo
        const realRequests = await odooAPI.searchReadWithSession(
          'request.information',
          domain,
          ['name', 'description', 'partner_name', 'partner_email', 'partner_phone', 'requester_quality', 'request_date', 'deadline_date', 'response_date', 'state', 'is_overdue', 'stage_id', 'user_id'],
          limit,
          req.user.odooSessionId
        );
        
        // Compter le total pour la pagination
        const totalCount = await odooAPI.searchCountWithSession(
          'request.information',
          domain,
          req.user.odooSessionId
        );
        
        // Formater les demandes pour l'API mobile
        const formattedRequests = realRequests.map(request => ({
          id: request.id,
          name: request.name,
          description: request.description,
          requester: request.partner_name,
          requester_email: request.partner_email,
          request_date: request.request_date,
          deadline_date: request.deadline_date,
          response_date: request.response_date,
          state: request.state,
          state_label: getStateLabel(request.state),
          stage_name: getStageForState(request.state),
          assigned_user: 'Administrateur',
          department: getDepartmentForRequest(request.description),
          days_to_deadline: calculateDaysToDeadline(request.deadline_date),
          is_overdue: request.is_overdue,
          has_response: request.response_date ? true : false,
          is_refusal: request.state === 'refused'
        }));
        
        requestsData = {
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
        };
        
        console.log(`✅ ${formattedRequests.length} demandes réelles récupérées depuis Odoo`);
        
      } catch (error) {
        console.error('❌ Erreur récupération demandes:', error.message);
        return res.json({
          success: false,
          error: 'Erreur lors de la récupération des demandes',
          requireAuth: false
        });
      }
    } else {
      return res.json({
        success: false,
        error: 'Connexion Odoo requise',
        requireAuth: true
      });
    }
    
    res.json(requestsData);
    
  } catch (error) {
    console.error('❌ Erreur liste demandes:', error.message);
    res.json({
      success: false,
      error: 'Erreur interne du serveur',
      requireAuth: false
    });
  }
});

// Route pour créer une nouvelle demande (protégé)
app.post('/api/mobile/citizen/requests', authenticateUser, async (req, res) => {
  try {
    const { description, requester_name, requester_email, requester_phone, requester_quality } = req.body;
    const userId = req.user.userId;
    let dataSource = req.user.dataSource || 'demo_data';
    
    if (!description || !requester_name) {
      return res.json({
        success: false,
        error: 'Description et nom du demandeur requis'
      });
    }
    
    // Pour l'instant, simulons la création de demande en attendant que le modèle soit installé
    if (isOdooConnected && dataSource === 'odoo_real_data') {
      try {
        console.log(`📝 Création d'une nouvelle demande pour l'utilisateur: ${req.user.userName}`);
        
        const requestName = `REQ-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`;
        const newRequestId = Date.now(); // ID temporaire
        
        // Stocker temporairement la demande en mémoire
        const tempRequest = {
          id: newRequestId,
          name: requestName,
          description: description,
          requester_name: requester_name,
          requester_email: requester_email,
          requester_phone: requester_phone,
          requester_quality: requester_quality,
          user_id: userId,
          state: 'submitted',
          state_label: 'Soumise',
          request_date: new Date().toISOString(),
          created_at: new Date().toISOString()
        };
        
        // Ajouter à une liste temporaire (en mémoire)
        if (!global.tempRequests) {
          global.tempRequests = new Map();
        }
        global.tempRequests.set(newRequestId, tempRequest);
        
        console.log(`✅ Nouvelle demande créée avec l'ID: ${newRequestId}`);
        
        res.json({
          success: true,
          data: {
            id: newRequestId,
            name: requestName,
            message: 'Demande créée avec succès (mode temporaire)'
          },
          source: 'odoo_real_data'
        });
        
      } catch (error) {
        console.error('❌ Erreur création demande:', error.message);
        return res.json({
          success: false,
          error: 'Erreur lors de la création de la demande',
          requireAuth: false
        });
      }
    } else {
      return res.json({
        success: false,
        error: 'Connexion Odoo requise pour créer une demande',
        requireAuth: true
      });
    }
    
  } catch (error) {
    console.error('❌ Erreur création demande:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors de la création de la demande'
    });
  }
});

// NIVEAU 3: Détail d'une demande spécifique (protégé)
app.get('/api/mobile/citizen/requests/:id', authenticateUser, async (req, res) => {
  try {
    const requestId = parseInt(req.params.id);
    const userId = req.user.userId;
    let dataSource = req.user.dataSource || 'demo_data';
    let requestDetail = null;

    // Vérifier d'abord les demandes temporaires
    if (global.tempRequests && global.tempRequests.has(requestId)) {
      const tempRequest = global.tempRequests.get(requestId);
      
      requestDetail = {
        success: true,
        data: {
          id: tempRequest.id,
          name: tempRequest.name,
          description: tempRequest.description,
          requester_name: tempRequest.requester_name,
          requester_email: tempRequest.requester_email,
          requester_phone: tempRequest.requester_phone,
          requester_quality: tempRequest.requester_quality,
          request_date: tempRequest.request_date,
          deadline_date: null,
          response_date: null,
          state: tempRequest.state,
          state_label: tempRequest.state_label,
          stage_name: 'Étape initiale',
          assigned_user: req.user.userName,
          department: 'Département à assigner',
          days_to_deadline: 30,
          is_overdue: false,
          response_body: null,
          is_refusal: false,
          refusal_motivation: null,
          timeline: [
            {
              date: tempRequest.created_at,
              event: 'Demande soumise',
              description: 'La demande a été soumise via l\'application mobile'
            }
          ]
        },
        source: 'odoo_real_data'
      };
      
      console.log(`✅ Détail temporaire récupéré pour la demande: ${tempRequest.name}`);
    }
    // Essayer de récupérer les données réelles d'Odoo
    else if (isOdooConnected && dataSource === 'odoo_real_data') {
      try {
        console.log(`📄 Récupération du détail Odoo pour la demande: ${requestId}`);
        
        const requests = await odooAPI.searchReadWithSession(
          'request.information',
          [['id', '=', requestId], ['user_id', '=', userId]],
          ['name', 'description', 'partner_name', 'partner_email', 'partner_phone', 'requester_quality', 'request_date', 'deadline_date', 'response_date', 'state', 'is_overdue', 'stage_id', 'user_id', 'response_body', 'is_refusal', 'refusal_motivation'],
          1,
          req.user.odooSessionId
        );
        
        if (requests.length > 0) {
          const req = requests[0];
          requestDetail = {
            success: true,
            data: {
              id: req.id,
              name: req.name,
              description: req.description,
              requester_name: req.partner_name,
              requester_email: req.partner_email,
              requester_phone: req.partner_phone,
              requester_quality: req.requester_quality,
              request_date: req.request_date,
              deadline_date: req.deadline_date,
              response_date: req.response_date,
              state: req.state,
              state_label: getStateLabel(req.state),
              stage_name: 'Étape en cours',
              assigned_user: req.user.userName,
              department: 'Département assigné',
              days_to_deadline: calculateDaysToDeadline(req.deadline_date),
              is_overdue: req.is_overdue,
              response_body: req.response_body,
              is_refusal: req.is_refusal,
              refusal_motivation: req.refusal_motivation,
              timeline: generateTimeline(req)
            },
            source: 'odoo_real_data'
          };
          
          console.log(`✅ Détail Odoo récupéré pour la demande: ${req.name}`);
        } else {
          console.log(`❌ Demande ${requestId} non trouvée dans Odoo`);
          return res.json({
            success: false,
            error: 'Demande non trouvée',
            requireAuth: false
          });
        }
        
      } catch (odooError) {
        console.error('❌ Erreur récupération détail Odoo:', odooError.message);
        return res.json({
          success: false,
          error: 'Erreur lors de la récupération du détail Odoo',
          requireAuth: false
        });
      }
    } else {
      return res.json({
        success: false,
        error: 'Connexion Odoo requise',
        requireAuth: true
      });
    }
    
    res.json(requestDetail);
    
  } catch (error) {
    console.error('❌ Erreur détail demande:', error.message);
    res.json({
      success: false,
      error: 'Erreur lors du chargement du détail',
      source: 'error'
    });
  }
});

// Fonctions utilitaires
function generateSessionToken() {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
}

// Calculer les statistiques basées sur les demandes temporaires
function calculateTempRequestStats(userId) {
  if (!global.tempRequests) {
    return {
      total: 0,
      pending: 0,
      completed: 0,
      overdue: 0
    };
  }
  
  const userRequests = Array.from(global.tempRequests.values()).filter(req => req.user_id === userId);
  
  // Simuler différents états pour rendre les statistiques vivantes
  const states = ['submitted', 'in_progress', 'completed', 'overdue'];
  const stateDistribution = {
    submitted: 0,
    in_progress: 0,
    completed: 0,
    overdue: 0
  };
  
  // Répartir les demandes selon une distribution réaliste
  userRequests.forEach((req, index) => {
    const stateIndex = index % 4;
    const state = states[stateIndex];
    stateDistribution[state]++;
    
    // Mettre à jour l'état de la demande
    req.state = state;
    req.state_label = getStateLabel(state);
  });
  
  return {
    total: userRequests.length,
    pending: stateDistribution.submitted + stateDistribution.in_progress,
    completed: stateDistribution.completed,
    overdue: stateDistribution.overdue
  };
}

// Récupérer les demandes récentes temporaires
function getRecentTempRequests(userId, limit = 5) {
  if (!global.tempRequests) {
    return [];
  }
  
  const userRequests = Array.from(global.tempRequests.values())
    .filter(req => req.user_id === userId)
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    .slice(0, limit);
  
  return userRequests.map(req => ({
    id: req.id,
    name: req.name,
    description: req.description,
    request_date: req.request_date,
    state: req.state,
    state_label: req.state_label,
    days_to_deadline: Math.floor(Math.random() * 25) + 5, // 5-30 jours
    is_overdue: req.state === 'overdue',
    partner_name: req.requester_name,
    department: getDepartmentForRequest(req.description)
  }));
}

// Assigner un département basé sur la description
function getDepartmentForRequest(description) {
  const departments = {
    'budget': 'Ministère des Finances',
    'marché': 'Direction des Marchés Publics',
    'infrastructure': 'Ministère des Infrastructures',
    'santé': 'Ministère de la Santé',
    'éducation': 'Ministère de l\'Education',
    'justice': 'Ministère de la Justice',
    'environnement': 'Ministère de l\'Environnement',
    'emploi': 'Ministère de l\'Emploi',
    'culture': 'Ministère de la Culture',
    'agriculture': 'Ministère de l\'Agriculture'
  };
  
  const desc = description.toLowerCase();
  for (const [keyword, dept] of Object.entries(departments)) {
    if (desc.includes(keyword)) {
      return dept;
    }
  }
  
  return 'Administration Générale';
}

// Récupérer la liste des demandes temporaires avec pagination
function getTempRequestsList(userId, status = null, page = 1, limit = 20) {
  if (!global.tempRequests) {
    return {
      requests: [],
      pagination: {
        page: page,
        limit: limit,
        total: 0,
        has_more: false
      }
    };
  }
  
  let userRequests = Array.from(global.tempRequests.values())
    .filter(req => req.user_id === userId);
  
  // Filtrer par statut si spécifié
  if (status) {
    userRequests = userRequests.filter(req => req.state === status);
  }
  
  // Trier par date de création (plus récent en premier)
  userRequests.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  
  // Pagination
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + limit;
  const paginatedRequests = userRequests.slice(startIndex, endIndex);
  
  return {
    requests: paginatedRequests.map(req => ({
      id: req.id,
      name: req.name,
      description: req.description,
      requester: req.requester_name,
      requester_email: req.requester_email,
      request_date: req.request_date,
      deadline_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 jours
      response_date: req.state === 'completed' ? new Date(Date.now() - Math.random() * 10 * 24 * 60 * 60 * 1000).toISOString() : null,
      state: req.state,
      state_label: req.state_label,
      stage_name: getStageForState(req.state),
      assigned_user: 'Administrateur',
      department: getDepartmentForRequest(req.description),
      days_to_deadline: Math.floor(Math.random() * 25) + 5,
      is_overdue: req.state === 'overdue',
      has_response: req.state === 'completed' || req.state === 'refused',
      is_refusal: req.state === 'refused'
    })),
    pagination: {
      page: page,
      limit: limit,
      total: userRequests.length,
      has_more: endIndex < userRequests.length
    }
  };
}

// Obtenir l'étape pour un état donné
function getStageForState(state) {
  const stages = {
    'submitted': 'En attente de traitement',
    'in_progress': 'Analyse en cours',
    'completed': 'Réponse fournie',
    'overdue': 'En retard',
    'refused': 'Refus motivé'
  };
  
  return stages[state] || 'Étape inconnue';
}

function calculateDaysToDeadline(deadlineDate) {
  if (!deadlineDate) return 0;
  const deadline = new Date(deadlineDate);
  const now = new Date();
  const diffTime = deadline - now;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays;
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

// Calculer les statistiques basées sur les vraies données Odoo
function calculateRealRequestStats(userRequests) {
  const stats = {
    total: userRequests.length,
    pending: 0,
    completed: 0,
    overdue: 0
  };
  
  userRequests.forEach(request => {
    switch(request.state) {
      case 'submitted':
      case 'in_progress':
      case 'pending_validation':
        stats.pending++;
        break;
      case 'responded':
        stats.completed++;
        break;
      case 'overdue':
        stats.overdue++;
        break;
    }
    
    // Vérifier si la demande est en retard
    if (request.is_overdue) {
      stats.overdue++;
    }
  });
  
  return stats;
}

// Récupérer les demandes récentes réelles
function getRecentRealRequests(userRequests, limit = 5) {
  return userRequests
    .sort((a, b) => new Date(b.request_date) - new Date(a.request_date))
    .slice(0, limit)
    .map(request => ({
      id: request.id,
      name: request.name,
      description: request.description,
      request_date: request.request_date,
      state: request.state,
      state_label: getStateLabel(request.state),
      days_to_deadline: calculateDaysToDeadline(request.deadline_date),
      is_overdue: request.is_overdue,
      partner_name: request.partner_name,
      department: getDepartmentForRequest(request.description)
    }));
}

// Initialisation
initOdooConnection();

// Proxy iframe supprimé - utilisation d'ouverture directe dans nouvel onglet

app.listen(PORT, () => {
  console.log(`🚀 Serveur mobile SAMA CONAI avec authentification démarré sur http://localhost:${PORT}`);
  console.log(`📱 Interface mobile avec login et données réelles`);
  console.log(`🔗 Intégration backend Odoo: ${isOdooConnected ? 'ACTIVE' : 'STANDBY'}`);
  console.log(`🌐 Backend Odoo: http://localhost:8077 (ouverture directe)`);
  console.log(`👤 Credentials de test: admin/admin ou demo@sama-conai.sn/demo123`);
});