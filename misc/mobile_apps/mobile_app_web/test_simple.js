const express = require('express');
const app = express();
const PORT = 3009;

app.get('/', (req, res) => {
    res.json({ message: 'Test serveur simple sur port 3008', status: 'OK' });
});

app.get('/test', (req, res) => {
    res.json({ test: 'OK', port: PORT });
});

app.listen(PORT, () => {
    console.log(`🚀 Serveur test simple démarré sur le port ${PORT}`);
    console.log(`📱 Test: http://localhost:${PORT}/test`);
});