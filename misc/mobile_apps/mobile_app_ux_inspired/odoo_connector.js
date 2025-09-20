// Connecteur Odoo XML-RPC pour SAMA CONAI
// Récupération des données réelles depuis Odoo

class OdooConnector {
    constructor(config = {}) {
        this.config = {
            url: config.url || 'http://localhost:8069',
            database: config.database || 'sama_conai_db',
            username: config.username || 'admin',
            password: config.password || 'admin',
            ...config
        };
        this.uid = null;
        this.sessionId = null;
    }

    // Authentification Odoo
    async authenticate() {
        try {
            const response = await this.xmlrpcCall('/xmlrpc/2/common', 'authenticate', [
                this.config.database,
                this.config.username,
                this.config.password,
                {}
            ]);

            if (response && typeof response === 'number') {
                this.uid = response;
                console.log('✅ Authentification Odoo réussie, UID:', this.uid);
                return true;
            } else {
                console.error('❌ Échec authentification Odoo:', response);
                return false;
            }
        } catch (error) {
            console.error('❌ Erreur authentification Odoo:', error);
            return false;
        }
    }

    // Appel XML-RPC générique
    async xmlrpcCall(endpoint, method, params) {
        const url = `${this.config.url}${endpoint}`;
        
        const xmlrpcRequest = `<?xml version="1.0"?>
<methodCall>
    <methodName>${method}</methodName>
    <params>
        ${params.map(param => this.serializeParam(param)).join('')}
    </params>
</methodCall>`;

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'text/xml',
                    'Content-Length': xmlrpcRequest.length.toString()
                },
                body: xmlrpcRequest
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const xmlText = await response.text();
            return this.parseXmlrpcResponse(xmlText);
        } catch (error) {
            console.error('❌ Erreur appel XML-RPC:', error);
            throw error;
        }
    }

    // Sérialisation des paramètres XML-RPC
    serializeParam(param) {
        if (typeof param === 'string') {
            return `<param><value><string>${this.escapeXml(param)}</string></value></param>`;
        } else if (typeof param === 'number') {
            return Number.isInteger(param) 
                ? `<param><value><int>${param}</int></value></param>`
                : `<param><value><double>${param}</double></value></param>`;
        } else if (typeof param === 'boolean') {
            return `<param><value><boolean>${param ? 1 : 0}</boolean></value></param>`;
        } else if (Array.isArray(param)) {
            const arrayItems = param.map(item => this.serializeValue(item)).join('');
            return `<param><value><array><data>${arrayItems}</data></array></value></param>`;
        } else if (typeof param === 'object' && param !== null) {
            const structMembers = Object.entries(param).map(([key, value]) => 
                `<member><name>${this.escapeXml(key)}</name>${this.serializeValue(value)}</member>`
            ).join('');
            return `<param><value><struct>${structMembers}</struct></value></param>`;
        } else {
            return `<param><value><string></string></value></param>`;
        }
    }

    serializeValue(value) {
        if (typeof value === 'string') {
            return `<value><string>${this.escapeXml(value)}</string></value>`;
        } else if (typeof value === 'number') {
            return Number.isInteger(value) 
                ? `<value><int>${value}</int></value>`
                : `<value><double>${value}</double></value>`;
        } else if (typeof value === 'boolean') {
            return `<value><boolean>${value ? 1 : 0}</boolean></value>`;
        } else if (Array.isArray(value)) {
            const arrayItems = value.map(item => this.serializeValue(item)).join('');
            return `<value><array><data>${arrayItems}</data></array></value>`;
        } else if (typeof value === 'object' && value !== null) {
            const structMembers = Object.entries(value).map(([key, val]) => 
                `<member><name>${this.escapeXml(key)}</name>${this.serializeValue(val)}</member>`
            ).join('');
            return `<value><struct>${structMembers}</struct></value>`;
        } else {
            return `<value><string></string></value>`;
        }
    }

    escapeXml(str) {
        return str.toString()
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    // Parsing de la réponse XML-RPC (simplifié)
    parseXmlrpcResponse(xmlText) {
        try {
            // Parsing XML simple pour Node.js
            const xmlDoc = this.parseXmlString(xmlText);
            
            // Vérifier les erreurs
            const fault = xmlDoc.querySelector('fault');
            if (fault) {
                const faultString = xmlDoc.querySelector('fault string')?.textContent || 'Erreur inconnue';
                throw new Error(`Erreur Odoo: ${faultString}`);
            }

            // Extraire la valeur de retour
            const valueElement = xmlDoc.querySelector('methodResponse params param value');
            if (valueElement) {
                return this.parseXmlValue(valueElement);
            }

            return null;
        } catch (error) {
            console.error('❌ Erreur parsing XML-RPC:', error);
            throw error;
        }
    }

    // Parser XML simple pour Node.js
    parseXmlString(xmlText) {
        // Parser XML simple basé sur regex pour Node.js
        const faultMatch = xmlText.match(/<fault>.*?<string>(.*?)<\/string>/s);
        if (faultMatch) {
            throw new Error(`Erreur Odoo: ${faultMatch[1]}`);
        }

        // Extraire la valeur de retour
        const valueMatch = xmlText.match(/<methodResponse>.*?<params>.*?<param>.*?<value>(.*?)<\/value>/s);
        if (valueMatch) {
            return { querySelector: () => ({ textContent: valueMatch[1] }) };
        }

        return null;
    }

    parseXmlValue(element) {
        const child = element.firstElementChild;
        if (!child) return element.textContent;

        switch (child.tagName) {
            case 'string':
                return child.textContent || '';
            case 'int':
            case 'i4':
                return parseInt(child.textContent) || 0;
            case 'double':
                return parseFloat(child.textContent) || 0;
            case 'boolean':
                return child.textContent === '1';
            case 'array':
                const dataElement = child.querySelector('data');
                if (dataElement) {
                    return Array.from(dataElement.querySelectorAll('value')).map(v => this.parseXmlValue(v));
                }
                return [];
            case 'struct':
                const result = {};
                child.querySelectorAll('member').forEach(member => {
                    const name = member.querySelector('name')?.textContent;
                    const value = member.querySelector('value');
                    if (name && value) {
                        result[name] = this.parseXmlValue(value);
                    }
                });
                return result;
            default:
                return child.textContent || '';
        }
    }

    // Recherche d'enregistrements
    async searchRead(model, domain = [], fields = [], options = {}) {
        if (!this.uid) {
            throw new Error('Non authentifié. Appelez authenticate() d\'abord.');
        }

        try {
            const result = await this.xmlrpcCall('/xmlrpc/2/object', 'execute_kw', [
                this.config.database,
                this.uid,
                this.config.password,
                model,
                'search_read',
                [domain],
                {
                    fields: fields,
                    limit: options.limit || 100,
                    offset: options.offset || 0,
                    order: options.order || 'id desc'
                }
            ]);

            return result || [];
        } catch (error) {
            console.error(`❌ Erreur search_read ${model}:`, error);
            return [];
        }
    }

    // Lecture d'enregistrements par ID
    async read(model, ids, fields = []) {
        if (!this.uid) {
            throw new Error('Non authentifié. Appelez authenticate() d\'abord.');
        }

        try {
            const result = await this.xmlrpcCall('/xmlrpc/2/object', 'execute_kw', [
                this.config.database,
                this.uid,
                this.config.password,
                model,
                'read',
                [Array.isArray(ids) ? ids : [ids]],
                { fields: fields }
            ]);

            return result || [];
        } catch (error) {
            console.error(`❌ Erreur read ${model}:`, error);
            return [];
        }
    }

    // Compter les enregistrements
    async searchCount(model, domain = []) {
        if (!this.uid) {
            throw new Error('Non authentifié. Appelez authenticate() d\'abord.');
        }

        try {
            const result = await this.xmlrpcCall('/xmlrpc/2/object', 'execute_kw', [
                this.config.database,
                this.uid,
                this.config.password,
                model,
                'search_count',
                [domain]
            ]);

            return result || 0;
        } catch (error) {
            console.error(`❌ Erreur search_count ${model}:`, error);
            return 0;
        }
    }

    // Méthodes spécifiques SAMA CONAI

    // Récupérer les statistiques du dashboard
    async getDashboardStats() {
        try {
            // Statistiques des demandes d'information
            const totalRequests = await this.searchCount('request.information');
            const pendingRequests = await this.searchCount('request.information', [
                ['state', 'in', ['submitted', 'in_progress', 'pending_validation']]
            ]);
            const completedRequests = await this.searchCount('request.information', [
                ['state', 'in', ['responded', 'refused']]
            ]);

            // Statistiques des alertes
            const totalAlerts = await this.searchCount('whistleblowing.alert');
            const activeAlerts = await this.searchCount('whistleblowing.alert', [
                ['state', 'in', ['new', 'preliminary_assessment', 'investigation']]
            ]);

            // Demandes récentes
            const recentRequests = await this.searchRead('request.information', [], [
                'name', 'description', 'state', 'request_date', 'partner_name'
            ], { limit: 5 });

            // Alertes récentes
            const recentAlerts = await this.searchRead('whistleblowing.alert', [], [
                'name', 'description', 'category', 'priority', 'state', 'alert_date'
            ], { limit: 3 });

            // Calcul du taux de satisfaction (simulé)
            const satisfactionRate = completedRequests > 0 ? 
                Math.round((completedRequests / (completedRequests + pendingRequests)) * 100 * 0.89) : 0;

            // Temps de réponse moyen (simulé)
            const averageResponseTime = 16.8;

            return {
                stats: {
                    totalRequests,
                    pendingRequests,
                    completedRequests,
                    totalAlerts,
                    activeAlerts,
                    satisfactionRate,
                    averageResponseTime
                },
                recentRequests: recentRequests.map(req => ({
                    id: req.id,
                    name: req.name,
                    description: req.description || 'Pas de description',
                    status: req.state,
                    date: req.request_date,
                    requester: req.partner_name
                })),
                recentAlerts: recentAlerts.map(alert => ({
                    id: alert.id,
                    name: alert.name,
                    description: alert.description || 'Pas de description',
                    category: alert.category,
                    priority: alert.priority,
                    status: alert.state,
                    date: alert.alert_date
                }))
            };
        } catch (error) {
            console.error('❌ Erreur getDashboardStats:', error);
            throw error;
        }
    }

    // Récupérer toutes les demandes d'information
    async getInformationRequests(options = {}) {
        try {
            const requests = await this.searchRead('request.information', [], [
                'name', 'description', 'state', 'request_date', 'deadline_date',
                'partner_name', 'partner_email', 'partner_phone', 'requester_quality',
                'user_id', 'department_id', 'response_date', 'is_overdue',
                'days_to_deadline'
            ], options);

            return {
                requests: requests.map(req => ({
                    id: req.id,
                    name: req.name,
                    description: req.description || 'Pas de description',
                    requester: req.partner_name,
                    requesterEmail: req.partner_email,
                    requesterPhone: req.partner_phone,
                    requesterQuality: req.requester_quality,
                    status: req.state,
                    date: req.request_date,
                    deadline: req.deadline_date,
                    responseDate: req.response_date,
                    assignedTo: req.user_id ? req.user_id[1] : null,
                    department: req.department_id ? req.department_id[1] : null,
                    isOverdue: req.is_overdue,
                    daysToDeadline: req.days_to_deadline
                })),
                pagination: {
                    page: 1,
                    limit: options.limit || 100,
                    total: requests.length,
                    pages: 1
                }
            };
        } catch (error) {
            console.error('❌ Erreur getInformationRequests:', error);
            throw error;
        }
    }

    // Récupérer une demande d'information par ID
    async getInformationRequest(id) {
        try {
            const requests = await this.read('request.information', [id], [
                'name', 'description', 'state', 'request_date', 'deadline_date',
                'partner_name', 'partner_email', 'partner_phone', 'requester_quality',
                'user_id', 'department_id', 'response_date', 'response_body',
                'is_refusal', 'refusal_reason_id', 'refusal_motivation',
                'is_overdue', 'days_to_deadline'
            ]);

            if (requests.length === 0) {
                return null;
            }

            const req = requests[0];
            return {
                id: req.id,
                name: req.name,
                description: req.description || 'Pas de description',
                requester: req.partner_name,
                requesterEmail: req.partner_email,
                requesterPhone: req.partner_phone,
                requesterQuality: req.requester_quality,
                status: req.state,
                date: req.request_date,
                deadline: req.deadline_date,
                responseDate: req.response_date,
                responseBody: req.response_body,
                assignedTo: req.user_id ? req.user_id[1] : null,
                department: req.department_id ? req.department_id[1] : null,
                isRefusal: req.is_refusal,
                refusalReason: req.refusal_reason_id ? req.refusal_reason_id[1] : null,
                refusalMotivation: req.refusal_motivation,
                isOverdue: req.is_overdue,
                daysToDeadline: req.days_to_deadline,
                // Historique simulé basé sur l'état
                history: this.generateRequestHistory(req)
            };
        } catch (error) {
            console.error('❌ Erreur getInformationRequest:', error);
            throw error;
        }
    }

    // Récupérer toutes les alertes
    async getWhistleblowingAlerts(options = {}) {
        try {
            const alerts = await this.searchRead('whistleblowing.alert', [], [
                'name', 'description', 'category', 'priority', 'state', 'alert_date',
                'manager_id', 'investigation_start_date', 'investigation_end_date',
                'resolution_date'
            ], options);

            return {
                alerts: alerts.map(alert => ({
                    id: alert.id,
                    name: alert.name,
                    description: alert.description || 'Pas de description',
                    category: alert.category,
                    priority: alert.priority,
                    status: alert.state,
                    date: alert.alert_date,
                    assignedTo: alert.manager_id ? alert.manager_id[1] : null,
                    investigationStartDate: alert.investigation_start_date,
                    investigationEndDate: alert.investigation_end_date,
                    resolutionDate: alert.resolution_date
                })),
                pagination: {
                    page: 1,
                    limit: options.limit || 100,
                    total: alerts.length,
                    pages: 1
                }
            };
        } catch (error) {
            console.error('❌ Erreur getWhistleblowingAlerts:', error);
            throw error;
        }
    }

    // Récupérer une alerte par ID
    async getWhistleblowingAlert(id) {
        try {
            const alerts = await this.read('whistleblowing.alert', [id], [
                'name', 'description', 'category', 'priority', 'state', 'alert_date',
                'manager_id', 'investigation_start_date', 'investigation_end_date',
                'investigation_notes', 'resolution', 'resolution_date'
            ]);

            if (alerts.length === 0) {
                return null;
            }

            const alert = alerts[0];
            return {
                id: alert.id,
                name: alert.name,
                description: alert.description || 'Pas de description',
                category: alert.category,
                priority: alert.priority,
                status: alert.state,
                date: alert.alert_date,
                assignedTo: alert.manager_id ? alert.manager_id[1] : null,
                investigationStartDate: alert.investigation_start_date,
                investigationEndDate: alert.investigation_end_date,
                investigationNotes: alert.investigation_notes,
                resolution: alert.resolution,
                resolutionDate: alert.resolution_date,
                // Informations simulées pour la démo
                reportedBy: 'Anonyme',
                location: 'Dakar, Sénégal',
                estimatedAmount: this.generateEstimatedAmount(alert.category),
                confidentialityLevel: this.getConfidentialityLevel(alert.priority),
                evidence: this.generateEvidence(alert.category),
                // Historique simulé basé sur l'état
                history: this.generateAlertHistory(alert)
            };
        } catch (error) {
            console.error('❌ Erreur getWhistleblowingAlert:', error);
            throw error;
        }
    }

    // Méthodes utilitaires pour enrichir les données

    generateRequestHistory(request) {
        const history = [];
        const baseDate = new Date(request.request_date);

        history.push({
            date: request.request_date,
            action: 'Demande soumise',
            user: request.partner_name,
            comment: 'Demande initiale déposée'
        });

        if (['in_progress', 'pending_validation', 'responded', 'refused'].includes(request.state)) {
            const assignDate = new Date(baseDate.getTime() + 24 * 60 * 60 * 1000);
            history.push({
                date: assignDate.toISOString(),
                action: 'Demande assignée',
                user: 'Système',
                comment: `Assignée à ${request.user_id ? request.user_id[1] : 'un agent'}`
            });
        }

        if (['pending_validation', 'responded', 'refused'].includes(request.state)) {
            const progressDate = new Date(baseDate.getTime() + 2 * 24 * 60 * 60 * 1000);
            history.push({
                date: progressDate.toISOString(),
                action: 'En cours de traitement',
                user: request.user_id ? request.user_id[1] : 'Agent',
                comment: 'Début de la collecte des documents'
            });
        }

        if (['responded', 'refused'].includes(request.state) && request.response_date) {
            history.push({
                date: request.response_date,
                action: request.is_refusal ? 'Demande refusée' : 'Demande traitée',
                user: request.user_id ? request.user_id[1] : 'Agent',
                comment: request.is_refusal ? 'Demande refusée avec motivation' : 'Réponse fournie'
            });
        }

        return history;
    }

    generateAlertHistory(alert) {
        const history = [];
        const baseDate = new Date(alert.alert_date);

        history.push({
            date: alert.alert_date,
            action: 'Signalement reçu',
            user: 'Système',
            comment: 'Alerte soumise via canal sécurisé'
        });

        if (['preliminary_assessment', 'investigation', 'resolved', 'closed'].includes(alert.state)) {
            const assessDate = new Date(baseDate.getTime() + 24 * 60 * 60 * 1000);
            history.push({
                date: assessDate.toISOString(),
                action: 'Évaluation préliminaire',
                user: 'Agent d\'évaluation',
                comment: 'Début de l\'évaluation du signalement'
            });
        }

        if (['investigation', 'resolved', 'closed'].includes(alert.state)) {
            const investDate = alert.investigation_start_date || 
                new Date(baseDate.getTime() + 3 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
            history.push({
                date: investDate,
                action: 'Enquête ouverte',
                user: 'Chef d\'équipe',
                comment: 'Assignation à l\'équipe spécialisée'
            });
        }

        if (['resolved', 'closed'].includes(alert.state) && alert.resolution_date) {
            history.push({
                date: alert.resolution_date,
                action: 'Enquête terminée',
                user: 'Enquêteur principal',
                comment: 'Investigation terminée avec résolution'
            });
        }

        return history;
    }

    generateEstimatedAmount(category) {
        const amounts = {
            'corruption': '2.5 milliards FCFA',
            'fraud': '800 millions FCFA',
            'abuse_of_power': '50,000 - 100,000 FCFA',
            'discrimination': 'Non applicable',
            'harassment': 'Non applicable',
            'safety_violation': '1.2 millions FCFA',
            'environmental': '500 millions FCFA',
            'other': 'À déterminer'
        };
        return amounts[category] || 'À déterminer';
    }

    getConfidentialityLevel(priority) {
        const levels = {
            'urgent': 'Maximum',
            'high': 'Élevé',
            'medium': 'Moyen',
            'low': 'Standard'
        };
        return levels[priority] || 'Moyen';
    }

    generateEvidence(category) {
        const evidenceTypes = {
            'corruption': ['Documents photographiés', 'Témoignages audio', 'Correspondances email'],
            'fraud': ['Documents comptables', 'Factures suspectes', 'Rapports financiers'],
            'abuse_of_power': ['Enregistrements audio', 'Témoignages de victimes'],
            'discrimination': ['Témoignages', 'Documents RH', 'Correspondances'],
            'harassment': ['Messages', 'Témoignages', 'Enregistrements'],
            'safety_violation': ['Photos', 'Rapports d\'incident', 'Témoignages'],
            'environmental': ['Photos', 'Analyses', 'Rapports d\'expertise'],
            'other': ['Documents divers', 'Témoignages']
        };
        return evidenceTypes[category] || ['Documents', 'Témoignages'];
    }
}

// Export pour utilisation
if (typeof module !== 'undefined' && module.exports) {
    module.exports = OdooConnector;
} else if (typeof window !== 'undefined') {
    window.OdooConnector = OdooConnector;
}