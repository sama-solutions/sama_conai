const express = require('express');
const path = require('path');
const fs = require('fs');

// Configuration
const app = express();
const PORT = process.env.PORT || 3004;

// Middleware
app.use(express.static('public'));
app.use(express.json());

// Route principale
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API simulée pour les données
app.get('/api/dashboard', (req, res) => {
    res.json({
        success: true,
        data: {
            stats: {
                totalRequests: 156,
                pendingRequests: 23,
                completedRequests: 128,
                satisfactionRate: 89.2,
                averageResponseTime: 16.8
            },
            recentRequests: [
                {
                    id: 1,
                    name: 'REQ-2025-001',
                    description: 'Documents budgétaires 2024',
                    status: 'in_progress',
                    date: '2025-01-07'
                },
                {
                    id: 2,
                    name: 'REQ-2025-002',
                    description: 'Marchés publics 2024',
                    status: 'completed',
                    date: '2025-01-06'
                }
            ],
            recentAlerts: [
                {
                    id: 1,
                    name: 'ALERT-2025-001',
                    description: 'Corruption marché public',
                    priority: 'urgent',
                    date: '2025-01-07'
                }
            ]
        }
    });
});

app.get('/api/requests', (req, res) => {
    res.json({
        success: true,
        data: {
            requests: [
                {
                    id: 1,
                    name: 'REQ-2025-001',
                    description: 'Documents budgétaires 2024',
                    requester: 'Amadou Diallo',
                    status: 'in_progress',
                    date: '2025-01-07',
                    deadline: '2025-02-06'
                },
                {
                    id: 2,
                    name: 'REQ-2025-002',
                    description: 'Marchés publics 2024',
                    requester: 'Fatou Sall',
                    status: 'completed',
                    date: '2025-01-06',
                    deadline: '2025-02-05'
                },
                {
                    id: 3,
                    name: 'REQ-2025-003',
                    description: 'Rapports d\'audit',
                    requester: 'Moussa Ba',
                    status: 'new',
                    date: '2025-01-07',
                    deadline: '2025-02-06'
                }
            ],
            pagination: {
                page: 1,
                limit: 20,
                total: 3,
                pages: 1
            }
        }
    });
});

app.get('/api/alerts', (req, res) => {
    res.json({
        success: true,
        data: {
            alerts: [
                {
                    id: 1,
                    name: 'ALERT-2025-001',
                    description: 'Corruption marché public',
                    category: 'corruption',
                    priority: 'urgent',
                    status: 'investigation',
                    date: '2025-01-07'
                },
                {
                    id: 2,
                    name: 'ALERT-2025-002',
                    description: 'Abus de pouvoir',
                    category: 'abuse_of_power',
                    priority: 'high',
                    status: 'preliminary_assessment',
                    date: '2025-01-06'
                }
            ],
            pagination: {
                page: 1,
                limit: 20,
                total: 2,
                pages: 1
            }
        }
    });
});

// API d'authentification simulée
app.post('/api/auth/login', (req, res) => {
    const { email, password } = req.body;
    
    const users = {
        'admin@sama-conai.sn': {
            id: 'admin_001',
            name: 'Administrateur SAMA CONAI',
            email: 'admin@sama-conai.sn',
            role: 'admin',
            password: 'admin123'
        },
        'agent@sama-conai.sn': {
            id: 'agent_001',
            name: 'Agent de Transparence',
            email: 'agent@sama-conai.sn',
            role: 'agent',
            password: 'agent123'
        },
        'citoyen@email.com': {
            id: 'citizen_001',
            name: 'Amadou Diallo',
            email: 'citoyen@email.com',
            role: 'citizen',
            password: 'citoyen123'
        }
    };

    const user = users[email];
    
    if (user && user.password === password) {
        const { password: _, ...userWithoutPassword } = user;
        res.json({
            success: true,
            data: {
                token: 'fake-jwt-token-' + Date.now(),
                user: userWithoutPassword
            }
        });
    } else {
        res.status(401).json({
            success: false,
            error: 'Identifiants incorrects'
        });
    }
});

// Gestion des erreurs
app.use((error, req, res, next) => {
    console.error('Erreur serveur:', error);
    res.status(500).json({
        success: false,
        error: 'Erreur interne du serveur'
    });
});

// Démarrage du serveur
const server = app.listen(PORT, () => {
    console.log(`
🎨 SAMA CONAI UX RÉVOLUTIONNAIRE v6.0
=====================================

🌐 URL: http://localhost:${PORT}
🎯 Design: UX Inspiré des Meilleurs Designs
📱 Interface: Mobile-First Révolutionnaire
✨ Animations: Micro-interactions Fluides
🎨 Thème: Design System Moderne
🚀 Performance: Optimisée pour Mobile

🔑 COMPTES DE TEST:
   👑 Admin: admin@sama-conai.sn / admin123
   🛡️ Agent: agent@sama-conai.sn / agent123
   👤 Citoyen: citoyen@email.com / citoyen123

🎉 FONCTIONNALITÉS UX RÉVOLUTIONNAIRES:
   ✨ Glassmorphism et Neumorphism
   🎭 Micro-interactions avancées
   🌊 Animations fluides 60fps
   🎨 Design system sophistiqué
   📱 Navigation gestuelle
   🌙 Mode sombre élégant
   🎯 Transitions seamless

🚀 PRÊT POUR UNE EXPÉRIENCE RÉVOLUTIONNAIRE !
    `);
});

// Gestion de l'arrêt propre
process.on('SIGINT', () => {
    console.log('\n👋 Arrêt du serveur SAMA CONAI UX...');
    server.close(() => {
        console.log('✅ Serveur arrêté proprement');
        process.exit(0);
    });
});