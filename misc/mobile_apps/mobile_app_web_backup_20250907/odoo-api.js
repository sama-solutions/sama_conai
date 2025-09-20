const axios = require('axios');

// Configuration du backend Odoo
const ODOO_BASE_URL = process.env.ODOO_URL || 'http://localhost:8077';
const ODOO_DB = process.env.ODOO_DB || 'sama_conai_analytics';

class OdooAPI {
  constructor() {
    this.baseURL = ODOO_BASE_URL;
    this.database = ODOO_DB;
    this.sessionId = null;
    this.userId = null;
  }

  // Authentification avec Odoo
  async authenticate(login = 'admin', password = 'admin') {
    try {
      const response = await axios.post(`${this.baseURL}/web/session/authenticate`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          db: this.database,
          login: login,
          password: password
        }
      }, {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 10000
      });

      if (response.data && response.data.result && response.data.result.uid) {
        this.sessionId = response.data.result.session_id;
        this.userId = response.data.result.uid;
        console.log('✅ Authentification Odoo réussie');
        return true;
      }
      return false;
    } catch (error) {
      console.error('❌ Erreur authentification Odoo:', error.message);
      return false;
    }
  }

  // Authentification d'un utilisateur spécifique
  async authenticateUser(login, password) {
    try {
      const response = await axios.post(`${this.baseURL}/web/session/authenticate`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          db: this.database,
          login: login,
          password: password
        }
      }, {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 10000
      });

      if (response.data && response.data.result && response.data.result.uid) {
        // Utiliser les informations de la session directement
        const sessionResult = response.data.result;
        const userInfo = {
          id: sessionResult.uid,
          name: sessionResult.name || sessionResult.username || 'Utilisateur',
          login: sessionResult.username || login,
          email: sessionResult.username || login,
          isAdmin: sessionResult.is_admin || sessionResult.is_system || false
        };
        
        return {
          success: true,
          sessionId: sessionResult.session_id,
          userId: sessionResult.uid,
          userInfo: userInfo
        };
      }
      return { success: false, error: 'Identifiants incorrects' };
    } catch (error) {
      console.error('❌ Erreur authentification utilisateur:', error.message);
      return { success: false, error: 'Erreur de connexion au serveur' };
    }
  }

  // Récupérer les informations d'un utilisateur
  async getUserInfo(userId, sessionId = null) {
    try {
      const headers = {
        'Content-Type': 'application/json'
      };
      
      if (sessionId) {
        headers['Cookie'] = `session_id=${sessionId}`;
      } else if (this.sessionId) {
        headers['Cookie'] = `session_id=${this.sessionId}`;
      }

      const response = await axios.post(`${this.baseURL}/web/dataset/call_kw`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          model: 'res.users',
          method: 'search_read',
          args: [[['id', '=', userId]]],
          kwargs: {
            fields: ['id', 'name', 'login', 'email', 'groups_id'],
            limit: 1
          }
        }
      }, {
        headers: headers,
        timeout: 10000
      });

      if (response.data && response.data.result && response.data.result.length > 0) {
        const user = response.data.result[0];
        return {
          id: user.id,
          name: user.name,
          login: user.login,
          email: user.email,
          isAdmin: user.groups_id && user.groups_id.includes(1) // Groupe Administration/Settings
        };
      }
      return null;
    } catch (error) {
      console.error('❌ Erreur récupération info utilisateur:', error.message);
      return null;
    }
  }

  // Recherche d'enregistrements avec session spécifique
  async searchReadWithSession(model, domain = [], fields = [], limit = 10, sessionId = null, offset = 0) {
    try {
      const headers = {
        'Content-Type': 'application/json'
      };
      
      if (sessionId) {
        headers['Cookie'] = `session_id=${sessionId}`;
      } else if (this.sessionId) {
        headers['Cookie'] = `session_id=${this.sessionId}`;
      }

      const response = await axios.post(`${this.baseURL}/web/dataset/call_kw`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          model: model,
          method: 'search_read',
          args: [domain],
          kwargs: {
            fields: fields,
            limit: limit,
            offset: offset,
            order: 'id desc'
          }
        }
      }, {
        headers: headers,
        timeout: 10000
      });

      if (response.data && response.data.result) {
        return response.data.result || [];
      }
      return [];
    } catch (error) {
      console.error(`❌ Erreur recherche ${model}:`, error.message);
      return [];
    }
  }

  // Recherche d'enregistrements
  async searchRead(model, domain = [], fields = [], limit = 10) {
    try {
      console.log(`🔍 searchRead ${model} avec domain:`, JSON.stringify(domain));
      console.log(`🔍 sessionId:`, this.sessionId ? 'présent' : 'absent');
      
      const response = await axios.post(`${this.baseURL}/web/dataset/call_kw`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          model: model,
          method: 'search_read',
          args: [domain],
          kwargs: {
            fields: fields,
            limit: limit,
            order: 'id desc'
          }
        }
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Cookie': `session_id=${this.sessionId}`
        },
        timeout: 10000
      });

      console.log(`📊 Réponse ${model}:`, response.data?.result?.length || 0, 'enregistrements');
      if (response.data?.error) {
        console.error(`❌ Erreur API ${model}:`, response.data.error);
      }

      if (response.data && response.data.result) {
        return response.data.result || [];
      }
      return [];
    } catch (error) {
      console.error(`❌ Erreur recherche ${model}:`, error.message);
      if (error.response?.data) {
        console.error(`❌ Détails erreur:`, error.response.data);
      }
      return [];
    }
  }

  // Compter les enregistrements avec session spécifique
  async searchCountWithSession(model, domain = [], sessionId = null) {
    try {
      const headers = {
        'Content-Type': 'application/json'
      };
      
      if (sessionId) {
        headers['Cookie'] = `session_id=${sessionId}`;
      } else if (this.sessionId) {
        headers['Cookie'] = `session_id=${this.sessionId}`;
      }

      const response = await axios.post(`${this.baseURL}/web/dataset/call_kw`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          model: model,
          method: 'search_count',
          args: [domain],
          kwargs: {}
        }
      }, {
        headers: headers,
        timeout: 10000
      });

      if (response.data && response.data.result !== undefined) {
        return response.data.result;
      }
      return 0;
    } catch (error) {
      console.error(`❌ Erreur comptage ${model}:`, error.message);
      return 0;
    }
  }

  // Compter les enregistrements
  async searchCount(model, domain = []) {
    try {
      const response = await axios.post(`${this.baseURL}/web/dataset/call_kw`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          model: model,
          method: 'search_count',
          args: [domain],
          kwargs: {}
        }
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Cookie': `session_id=${this.sessionId}`
        },
        timeout: 10000
      });

      if (response.data && response.data.result !== undefined) {
        return response.data.result;
      }
      return 0;
    } catch (error) {
      console.error(`❌ Erreur comptage ${model}:`, error.message);
      return 0;
    }
  }

  // Créer un enregistrement
  async create(model, data) {
    try {
      const response = await axios.post(`${this.baseURL}/web/dataset/call_kw`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          model: model,
          method: 'create',
          args: [data],
          kwargs: {}
        }
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Cookie': `session_id=${this.sessionId}`
        },
        timeout: 10000
      });

      if (response.data && response.data.result) {
        return response.data.result;
      }
      return null;
    } catch (error) {
      console.error(`❌ Erreur création ${model}:`, error.message);
      console.error('Détails erreur:', error.response?.data || error.message);
      return null;
    }
  }

  // Créer un enregistrement avec session spécifique
  async createWithSession(model, data, sessionId = null) {
    try {
      const headers = {
        'Content-Type': 'application/json'
      };
      
      if (sessionId) {
        headers['Cookie'] = `session_id=${sessionId}`;
      } else if (this.sessionId) {
        headers['Cookie'] = `session_id=${this.sessionId}`;
      }

      const response = await axios.post(`${this.baseURL}/web/dataset/call_kw`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          model: model,
          method: 'create',
          args: [data],
          kwargs: {}
        }
      }, {
        headers: headers,
        timeout: 10000
      });

      if (response.data && response.data.result) {
        return response.data.result;
      }
      return null;
    } catch (error) {
      console.error(`❌ Erreur création ${model}:`, error.message);
      console.error('Détails erreur:', error.response?.data || error.message);
      return null;
    }
  }

  // Mettre à jour un enregistrement
  async write(model, id, data) {
    try {
      const response = await axios.post(`${this.baseURL}/web/dataset/call_kw`, {
        jsonrpc: '2.0',
        method: 'call',
        params: {
          model: model,
          method: 'write',
          args: [[id], data],
          kwargs: {}
        }
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Cookie': `session_id=${this.sessionId}`
        },
        timeout: 10000
      });

      return response.data && response.data.result;
    } catch (error) {
      console.error(`❌ Erreur mise à jour ${model}:`, error.message);
      return false;
    }
  }

  // Récupérer les demandes d'information
  async getInformationRequests(limit = 10, userId = null) {
    const fields = [
      'name', 'description', 'partner_name', 'partner_email',
      'request_date', 'deadline_date', 'response_date', 'state',
      'stage_id', 'user_id', 'department_id', 'is_overdue',
      'days_to_deadline', 'response_body', 'is_refusal'
    ];
    
    let domain = [];
    if (userId) {
      domain.push(['user_id', '=', userId]);
    }
    
    return await this.searchRead('request.information', domain, fields, limit);
  }

  // Récupérer les alertes de signalement
  async getWhistleblowingAlerts(limit = 10, userId = null) {
    const fields = [
      'name', 'description', 'category', 'alert_date', 'state',
      'stage_id', 'priority', 'is_anonymous', 'reporter_name',
      'reporter_email', 'manager_id', 'investigation_notes'
    ];
    
    let domain = [];
    if (userId) {
      domain.push(['manager_id', '=', userId]);
    }
    
    return await this.searchRead('whistleblowing.alert', domain, fields, limit);
  }

  // Statistiques des demandes d'information
  async getInformationRequestStats(userId = null) {
    let baseDomain = [];
    if (userId) {
      baseDomain.push(['user_id', '=', userId]);
    }
    
    const total = await this.searchCount('request.information', baseDomain);
    const submitted = await this.searchCount('request.information', [...baseDomain, ['state', '=', 'submitted']]);
    const in_progress = await this.searchCount('request.information', [...baseDomain, ['state', '=', 'in_progress']]);
    const responded = await this.searchCount('request.information', [...baseDomain, ['state', '=', 'responded']]);
    const refused = await this.searchCount('request.information', [...baseDomain, ['state', '=', 'refused']]);
    const overdue = await this.searchCount('request.information', [...baseDomain, ['is_overdue', '=', true]]);

    return {
      total,
      submitted,
      in_progress,
      responded,
      refused,
      overdue,
      pending: submitted + in_progress,
      completed: responded + refused
    };
  }

  // Statistiques des alertes
  async getWhistleblowingStats(userId = null) {
    let baseDomain = [];
    if (userId) {
      baseDomain.push(['manager_id', '=', userId]);
    }
    
    const total = await this.searchCount('whistleblowing.alert', baseDomain);
    const new_alerts = await this.searchCount('whistleblowing.alert', [...baseDomain, ['state', '=', 'new']]);
    const investigation = await this.searchCount('whistleblowing.alert', [...baseDomain, ['state', '=', 'investigation']]);
    const resolved = await this.searchCount('whistleblowing.alert', [...baseDomain, ['state', '=', 'resolved']]);
    const high_priority = await this.searchCount('whistleblowing.alert', [...baseDomain, ['priority', '=', 'high']]);
    const urgent = await this.searchCount('whistleblowing.alert', [...baseDomain, ['priority', '=', 'urgent']]);

    return {
      total,
      new_alerts,
      investigation,
      resolved,
      high_priority,
      urgent,
      active: new_alerts + investigation
    };
  }

  // Récupérer les départements
  async getDepartments() {
    const fields = ['name', 'description', 'manager_id'];
    return await this.searchRead('hr.department', [], fields, 50);
  }

  // Récupérer les étapes
  async getStages(model) {
    const fields = ['name', 'description', 'sequence'];
    return await this.searchRead(`${model}.stage`, [], fields, 20);
  }

  // Calculer le temps de réponse moyen
  async getAverageResponseTime(userId = null) {
    try {
      let baseDomain = [['state', '=', 'responded'], ['response_date', '!=', false]];
      if (userId) {
        baseDomain.push(['user_id', '=', userId]);
      }
      
      const requests = await this.searchRead('request.information', 
        baseDomain, 
        ['request_date', 'response_date'], 
        100
      );

      if (requests.length === 0) return 0;

      let totalDays = 0;
      let validRequests = 0;

      requests.forEach(req => {
        if (req.request_date && req.response_date) {
          const requestDate = new Date(req.request_date);
          const responseDate = new Date(req.response_date);
          const diffTime = Math.abs(responseDate - requestDate);
          const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
          totalDays += diffDays;
          validRequests++;
        }
      });

      return validRequests > 0 ? Math.round((totalDays / validRequests) * 10) / 10 : 0;
    } catch (error) {
      console.error('❌ Erreur calcul temps moyen:', error.message);
      return 0;
    }
  }

  // Calculer le taux de succès
  async getSuccessRate(userId = null) {
    try {
      let baseDomain = [];
      if (userId) {
        baseDomain.push(['user_id', '=', userId]);
      }
      
      const total = await this.searchCount('request.information', baseDomain);
      const responded = await this.searchCount('request.information', [...baseDomain, ['state', '=', 'responded']]);
      
      return total > 0 ? Math.round((responded / total) * 1000) / 10 : 0;
    } catch (error) {
      console.error('❌ Erreur calcul taux succès:', error.message);
      return 0;
    }
  }
}

module.exports = OdooAPI;