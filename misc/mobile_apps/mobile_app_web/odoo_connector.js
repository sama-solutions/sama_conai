const xmlrpc = require('xmlrpc');

/**
 * SAMA CONAI - Connecteur Odoo Réel
 * Module de connexion aux données réelles d'Odoo
 */

class OdooConnector {
    constructor(config) {
        this.config = {
            url: config.url || 'http://localhost:8077',
            db: config.db || 'sama_conai_db',
            username: config.username || 'admin',
            password: config.password || 'admin',
            ...config
        };
        
        this.uid = null;
        this.isConnected = false;
        
        // Clients XML-RPC
        this.commonClient = xmlrpc.createClient({
            host: this.getHost(),
            port: this.getPort(),
            path: '/xmlrpc/2/common'
        });
        
        this.objectClient = xmlrpc.createClient({
            host: this.getHost(),
            port: this.getPort(),
            path: '/xmlrpc/2/object'
        });
        
        console.log(`🔗 OdooConnector initialisé pour ${this.config.url}`);
    }
    
    getHost() {
        const url = new URL(this.config.url);
        return url.hostname;
    }
    
    getPort() {
        const url = new URL(this.config.url);
        return url.port || (url.protocol === 'https:' ? 443 : 80);
    }
    
    /**
     * Authentification avec Odoo
     */
    async authenticate() {
        return new Promise((resolve, reject) => {
            this.commonClient.methodCall('authenticate', [
                this.config.db,
                this.config.username,
                this.config.password,
                {}
            ], (error, uid) => {
                if (error) {
                    console.error('❌ Erreur authentification Odoo:', error);
                    this.isConnected = false;
                    reject(error);
                } else if (uid) {
                    this.uid = uid;
                    this.isConnected = true;
                    console.log(`✅ Authentification Odoo réussie - UID: ${uid}`);
                    resolve(uid);
                } else {
                    console.error('❌ Authentification Odoo échouée - Identifiants incorrects');
                    this.isConnected = false;
                    reject(new Error('Identifiants incorrects'));
                }
            });
        });
    }
    
    /**
     * Exécution d'une méthode Odoo
     */
    async execute(model, method, args = [], kwargs = {}) {
        if (!this.isConnected) {
            await this.authenticate();
        }
        
        return new Promise((resolve, reject) => {
            this.objectClient.methodCall('execute_kw', [
                this.config.db,
                this.uid,
                this.config.password,
                model,
                method,
                args,
                kwargs
            ], (error, result) => {
                if (error) {
                    console.error(`❌ Erreur ${model}.${method}:`, error);
                    reject(error);
                } else {
                    console.log(`✅ ${model}.${method} - ${Array.isArray(result) ? result.length : 1} résultat(s)`);
                    resolve(result);
                }
            });
        });
    }
    
    /**
     * Test de connexion
     */
    async testConnection() {
        try {
            await this.authenticate();
            const version = await new Promise((resolve, reject) => {
                this.commonClient.methodCall('version', [], (error, result) => {
                    if (error) reject(error);
                    else resolve(result);
                });
            });
            
            console.log('🎯 Connexion Odoo testée avec succès:', version);
            return { success: true, version, uid: this.uid };
        } catch (error) {
            console.error('❌ Test connexion Odoo échoué:', error);
            return { success: false, error: error.message };
        }
    }
    
    // ========================================= //
    // MÉTHODES SPÉCIFIQUES SAMA CONAI           //
    // ========================================= //
    
    /**
     * Récupération des demandes d'information
     */
    async getInformationRequests(filters = {}, limit = 10, offset = 0) {
        try {
            const domain = [];
            
            // Filtres
            if (filters.state) {
                domain.push(['state', '=', filters.state]);
            }
            
            const requests = await this.execute('request.information', 'search_read', [domain], {
                fields: [
                    'name', 'requester_name', 'requester_email', 'requester_quality',
                    'request_date', 'description', 'state', 'priority', 'department',
                    'assigned_user_id', 'response_body', 'response_date', 'deadline_date',
                    'is_overdue', 'create_date', 'write_date'
                ],
                limit: limit,
                offset: offset,
                order: 'create_date desc'
            });
            
            return requests.map(req => ({
                ...req,
                state_label: this.getStateLabel(req.state),
                tags: [], // À implémenter si nécessaire
                timeline: [] // À construire depuis les logs
            }));
        } catch (error) {
            console.error('❌ Erreur récupération demandes:', error);
            throw error;
        }
    }
    
    /**
     * Récupération des alertes
     */
    async getWhistleblowingAlerts(filters = {}, limit = 10, offset = 0) {
        try {
            const domain = [];
            
            if (filters.state) {
                domain.push(['state', '=', filters.state]);
            }
            
            const alerts = await this.execute('whistleblowing.alert', 'search_read', [domain], {
                fields: [
                    'name', 'alert_date', 'category', 'priority', 'state',
                    'description', 'reporter_name', 'manager_id', 'investigation_notes',
                    'is_anonymous', 'create_date', 'write_date'
                ],
                limit: limit,
                offset: offset,
                order: 'create_date desc'
            });
            
            return alerts.map(alert => ({
                ...alert,
                state_label: this.getAlertStateLabel(alert.state),
                category_label: this.getCategoryLabel(alert.category),
                priority_label: this.getPriorityLabel(alert.priority),
                tags: [],
                timeline: []
            }));
        } catch (error) {
            console.error('❌ Erreur récupération alertes:', error);
            throw error;
        }
    }
    
    /**
     * Statistiques globales
     */
    async getGlobalStats() {
        try {
            const [requestCount, alertCount] = await Promise.all([
                this.execute('request.information', 'search_count', [[]]),
                this.execute('whistleblowing.alert', 'search_count', [[]])
            ]);
            
            const [pendingRequests, urgentAlerts] = await Promise.all([
                this.execute('request.information', 'search_count', [['state', 'in', ['submitted', 'in_progress']]]),
                this.execute('whistleblowing.alert', 'search_count', [['priority', '=', 'urgent']])
            ]);
            
            return {
                total_requests: requestCount,
                pending_requests: pendingRequests,
                completed_requests: requestCount - pendingRequests,
                total_alerts: alertCount,
                urgent_alerts: urgentAlerts,
                active_alerts: alertCount - urgentAlerts,
                response_time_avg: 15.5, // À calculer
                satisfaction_rate: 85.0 // À calculer
            };
        } catch (error) {
            console.error('❌ Erreur statistiques globales:', error);
            throw error;
        }
    }
    
    /**
     * Informations utilisateur
     */
    async getUserInfo(userId = null) {
        try {
            const uid = userId || this.uid;
            const user = await this.execute('res.users', 'read', [uid], {
                fields: ['name', 'email', 'login', 'company_id', 'groups_id']
            });
            
            return {
                id: user[0].id,
                name: user[0].name,
                email: user[0].email,
                login: user[0].login,
                department: user[0].company_id ? user[0].company_id[1] : 'SAMA CONAI',
                avatar: '👨‍💼'
            };
        } catch (error) {
            console.error('❌ Erreur informations utilisateur:', error);
            throw error;
        }
    }
    
    // ========================================= //
    // MÉTHODES UTILITAIRES                      //
    // ========================================= //
    
    getStateLabel(state) {
        const labels = {
            'submitted': 'Soumise',
            'in_progress': 'En Traitement',
            'responded': 'Répondu',
            'refused': 'Refusé',
            'pending_validation': 'En Validation'
        };
        return labels[state] || state;
    }
    
    getAlertStateLabel(state) {
        const labels = {
            'new': 'Nouveau',
            'investigation': 'Enquête en Cours',
            'resolved': 'Résolu',
            'transmitted': 'Transmis',
            'closed': 'Fermé'
        };
        return labels[state] || state;
    }
    
    getCategoryLabel(category) {
        const labels = {
            'corruption': 'Corruption',
            'fraud': 'Fraude',
            'harassment': 'Harcèlement',
            'environmental': 'Environnemental',
            'abuse_of_power': 'Abus de Pouvoir'
        };
        return labels[category] || category;
    }
    
    getPriorityLabel(priority) {
        const labels = {
            'low': 'Faible',
            'medium': 'Moyenne',
            'high': 'Élevée',
            'urgent': 'Urgente'
        };
        return labels[priority] || priority;
    }
}

module.exports = OdooConnector;