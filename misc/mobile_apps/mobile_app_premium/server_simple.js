const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 3002;

// MIME types
const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

// Données de démonstration
const users = new Map([
  ['admin@sama-conai.sn', {
    id: 'admin_001',
    email: 'admin@sama-conai.sn',
    password: 'admin123',
    name: 'Administrateur SAMA CONAI',
    role: 'admin',
    gamification: { level: 10, points: 2500, badges: ['expert', 'leader'] }
  }],
  ['agent@sama-conai.sn', {
    id: 'agent_001',
    email: 'agent@sama-conai.sn',
    password: 'agent123',
    name: 'Agent de Transparence',
    role: 'agent',
    gamification: { level: 5, points: 1200, badges: ['efficient'] }
  }],
  ['citoyen@email.com', {
    id: 'citizen_001',
    email: 'citoyen@email.com',
    password: 'citoyen123',
    name: 'Amadou Diallo',
    role: 'citizen',
    gamification: { level: 3, points: 450, badges: ['active_citizen'] }
  }]
]);

const sessions = new Map();

// Fonction pour servir les fichiers statiques
function serveStatic(req, res, filePath) {
  const fullPath = path.join(__dirname, 'public', filePath);
  
  fs.readFile(fullPath, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('404 Not Found');
      return;
    }
    
    const ext = path.extname(filePath);
    const contentType = mimeTypes[ext] || 'text/plain';
    
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

// Fonction pour générer un token simple
function generateToken() {
  return Math.random().toString(36).substr(2, 15);
}

// Créer le serveur
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  // Headers CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Route principale
  if (pathname === '/' || pathname === '/index.html') {
    serveStatic(req, res, 'index.html');
    return;
  }

  // Routes API
  if (pathname.startsWith('/api/')) {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        // Login
        if (pathname === '/api/auth/login' && method === 'POST') {
          const { email, password } = JSON.parse(body);
          const user = users.get(email);
          
          if (user && user.password === password) {
            const token = generateToken();
            sessions.set(token, user);
            
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
              success: true,
              data: {
                token,
                user: {
                  id: user.id,
                  name: user.name,
                  email: user.email,
                  role: user.role,
                  gamification: user.gamification
                }
              }
            }));
          } else {
            res.writeHead(401, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
              success: false,
              error: 'Identifiants incorrects'
            }));
          }
          return;
        }

        // Dashboard
        if (pathname === '/api/dashboard' && method === 'GET') {
          const authHeader = req.headers.authorization;
          const token = authHeader && authHeader.split(' ')[1];
          const user = sessions.get(token);
          
          if (!user) {
            res.writeHead(401, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
              success: false,
              error: 'Token invalide',
              requireAuth: true
            }));
            return;
          }

          let dashboardData = {
            user: {
              id: user.id,
              name: user.name,
              role: user.role,
              gamification: user.gamification
            },
            notifications: { unread: 0, recent: [] }
          };

          // Données spécifiques selon le rôle
          if (user.role === 'admin') {
            dashboardData.admin = {
              totalRequests: 156,
              pendingRequests: 23,
              completedRequests: 128,
              totalUsers: 1247,
              systemHealth: {
                status: 'healthy',
                uptime: 86400,
                memory: { used: 134217728 },
                connections: 42
              },
              analytics: {
                requestsThisMonth: 45,
                averageResponseTime: 16.8,
                satisfactionRate: 89.2
              }
            };
          } else if (user.role === 'agent') {
            dashboardData.agent = {
              assignedRequests: 12,
              pendingRequests: 5,
              completedToday: 3,
              averageResponseTime: 14.2,
              performance: {
                thisMonth: { completed: 12, averageTime: 14.2, satisfaction: 4.6 },
                ranking: 2
              }
            };
          } else if (user.role === 'citizen') {
            dashboardData.citizen = {
              myRequests: 8,
              pendingRequests: 3,
              completedRequests: 5,
              publicStats: {
                totalPublicRequests: 1847,
                averageResponseTime: 16.8,
                successRate: 89.2,
                transparencyIndex: 8.4
              },
              tips: [
                'Soyez précis dans vos demandes pour obtenir des réponses plus rapides',
                'Consultez les demandes similaires avant de créer la vôtre'
              ]
            };
          }

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            success: true,
            data: dashboardData
          }));
          return;
        }

        // Assistant IA
        if (pathname === '/api/ai/chat' && method === 'POST') {
          const { message } = JSON.parse(body);
          
          let response = "Je suis votre assistant SAMA CONAI. Comment puis-je vous aider ?";
          
          if (message.toLowerCase().includes('demande')) {
            response = "Pour créer une demande, cliquez sur 'Nouvelle Demande' et remplissez le formulaire avec des détails précis.";
          } else if (message.toLowerCase().includes('délai')) {
            response = "Le délai légal de réponse est de 30 jours. En moyenne, nous répondons en 16.8 jours.";
          } else if (message.toLowerCase().includes('transparence')) {
            response = "SAMA CONAI garantit la transparence gouvernementale au Sénégal avec un taux de succès de 89.2%.";
          }

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            success: true,
            data: { content: response }
          }));
          return;
        }

        // Route non trouvée
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          error: 'Route non trouvée'
        }));

      } catch (error) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          error: 'Erreur serveur'
        }));
      }
    });
    return;
  }

  // Fichiers statiques
  if (pathname.startsWith('/')) {
    serveStatic(req, res, pathname.substring(1));
    return;
  }

  // 404
  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('404 Not Found');
});

// Démarrer le serveur
server.listen(PORT, () => {
  console.log(`
🎉 SAMA CONAI PREMIUM v4.0 DÉMARRÉ !
====================================

🌐 URL: http://localhost:${PORT}
📱 Interface: Ultra-moderne avec glassmorphism
🔐 Auth: Système simplifié mais fonctionnel
🎮 Gamification: Niveaux, points, badges
🤖 IA: Assistant conversationnel
🎨 Thèmes: Clair/Sombre/Auto/Gouvernement

🔑 COMPTES DE DÉMONSTRATION:
   👑 Admin: admin@sama-conai.sn / admin123
   🛡️ Agent: agent@sama-conai.sn / agent123
   👤 Citoyen: citoyen@email.com / citoyen123

🚀 PRÊT POUR UNE EXPÉRIENCE RÉVOLUTIONNAIRE !
  `);
});

// Gestion des erreurs
server.on('error', (err) => {
  console.error('❌ Erreur serveur:', err);
});

process.on('SIGINT', () => {
  console.log('\n👋 Arrêt du serveur SAMA CONAI Premium...');
  server.close(() => {
    console.log('✅ Serveur arrêté proprement');
    process.exit(0);
  });
});