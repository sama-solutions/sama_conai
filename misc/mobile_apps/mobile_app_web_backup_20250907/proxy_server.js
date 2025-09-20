const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = 8078; // Port du proxy

// Configuration du proxy pour Odoo
const odooProxy = createProxyMiddleware({
  target: 'http://localhost:8077',
  changeOrigin: true,
  onProxyRes: function (proxyRes, req, res) {
    console.log('📋 Headers avant modification:', Object.keys(proxyRes.headers));
    
    // Supprimer TOUS les headers qui bloquent l'iframe
    delete proxyRes.headers['x-frame-options'];
    delete proxyRes.headers['X-Frame-Options'];
    delete proxyRes.headers['content-security-policy'];
    delete proxyRes.headers['Content-Security-Policy'];
    delete proxyRes.headers['x-content-type-options'];
    delete proxyRes.headers['X-Content-Type-Options'];
    
    // Forcer les headers pour permettre l'iframe
    res.setHeader('X-Frame-Options', 'ALLOWALL');
    res.setHeader('Content-Security-Policy', 'frame-ancestors *');
    
    // Ajouter des headers CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    console.log('✅ Headers après modification:', Object.keys(proxyRes.headers));
  },
  logLevel: 'info'
});

// Utiliser le proxy pour toutes les requêtes
app.use('/', odooProxy);

app.listen(PORT, () => {
  console.log(`🔗 Proxy Odoo pour iframe démarré sur http://localhost:${PORT}`);
  console.log(`📊 Redirige vers Odoo sur http://localhost:8077`);
  console.log(`🎯 Utilisation: iframe src="http://localhost:${PORT}/web"`);
});

module.exports = app;