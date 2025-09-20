import axios from 'axios';
import Config from 'react-native-config';

// Configuration de base de l'API
const API_BASE_URL = Config.API_BASE_URL || 'http://localhost:8077';
const API_TIMEOUT = parseInt(Config.API_TIMEOUT || '30000');

// Instance Axios configurée
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Intercepteur pour ajouter le token d'authentification
apiClient.interceptors.request.use(
  (config) => {
    // TODO: Récupérer le token depuis le stockage sécurisé
    // const token = await getStoredToken();
    // if (token) {
    //   config.headers.Authorization = `Bearer ${token}`;
    // }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Intercepteur pour gérer les réponses et erreurs
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      // TODO: Gérer la déconnexion automatique
      console.log('Token expiré, déconnexion nécessaire');
    }
    return Promise.reject(error);
  }
);

// API pour les citoyens
export const citizenApi = {
  // Tableau de bord
  getDashboard: async () => {
    try {
      const response = await apiClient.get('/api/mobile/citizen/dashboard');
      return response.data;
    } catch (error) {
      console.error('Erreur getDashboard:', error);
      // Retourner des données de démonstration
      return {
        success: true,
        data: {
          user_stats: {
            total_requests: 5,
            pending_requests: 2,
            completed_requests: 3,
            overdue_requests: 0,
          },
          recent_requests: [
            {
              id: 1,
              name: 'REQ-2025-001',
              description: 'Demande d\'accès aux documents budgétaires 2024',
              request_date: '2025-01-15T10:00:00Z',
              state: 'in_progress',
              state_label: 'En cours',
              days_to_deadline: 15,
              is_overdue: false,
            },
            {
              id: 2,
              name: 'REQ-2025-002',
              description: 'Information sur les marchés publics',
              request_date: '2025-01-10T14:30:00Z',
              state: 'responded',
              state_label: 'Répondu',
              days_to_deadline: 0,
              is_overdue: false,
            },
          ],
          public_stats: {
            total_public_requests: 1250,
            avg_response_time: 18.5,
            success_rate: 87.3,
          },
        },
      };
    }
  },

  // Mes demandes
  getRequests: async (page = 1, limit = 20) => {
    try {
      const response = await apiClient.post('/api/mobile/citizen/requests', {
        page,
        limit,
      });
      return response.data;
    } catch (error) {
      console.error('Erreur getRequests:', error);
      return {
        success: false,
        error: 'Erreur de connexion au serveur',
      };
    }
  },

  // Créer une demande
  createRequest: async (requestData: any) => {
    try {
      const response = await apiClient.post('/api/mobile/citizen/requests/create', requestData);
      return response.data;
    } catch (error) {
      console.error('Erreur createRequest:', error);
      return {
        success: false,
        error: 'Erreur lors de la création de la demande',
      };
    }
  },
};

// API pour l'authentification
export const authApi = {
  login: async (email: string, password: string) => {
    try {
      const response = await apiClient.post('/api/mobile/auth/login', {
        email,
        password,
      });
      return response.data;
    } catch (error) {
      console.error('Erreur login:', error);
      return {
        success: false,
        error: 'Erreur de connexion',
      };
    }
  },

  register: async (userData: any) => {
    try {
      const response = await apiClient.post('/api/mobile/auth/register', userData);
      return response.data;
    } catch (error) {
      console.error('Erreur register:', error);
      return {
        success: false,
        error: 'Erreur lors de l\'inscription',
      };
    }
  },
};

export default apiClient;