// Service Worker pour SAMA CONAI Premium v4.0
// PWA avec cache intelligent et notifications push

const CACHE_NAME = 'sama-conai-premium-v4.0';
const STATIC_CACHE = 'sama-static-v4.0';
const DYNAMIC_CACHE = 'sama-dynamic-v4.0';

// Ressources à mettre en cache
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/images/icon-192x192.png',
  '/images/icon-512x512.png',
  'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap',
  'https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap'
];

// URLs à mettre en cache dynamiquement
const DYNAMIC_URLS = [
  '/api/dashboard',
  '/api/notifications',
  '/api/themes'
];

// Installation du Service Worker
self.addEventListener('install', event => {
  console.log('🔧 Service Worker: Installation');
  
  event.waitUntil(
    Promise.all([
      // Cache statique
      caches.open(STATIC_CACHE).then(cache => {
        console.log('📦 Cache statique: Mise en cache des ressources');
        return cache.addAll(STATIC_ASSETS);
      }),
      
      // Cache dynamique
      caches.open(DYNAMIC_CACHE).then(cache => {
        console.log('🔄 Cache dynamique: Initialisé');
        return Promise.resolve();
      })
    ]).then(() => {
      console.log('✅ Service Worker: Installation terminée');
      return self.skipWaiting();
    })
  );
});

// Activation du Service Worker
self.addEventListener('activate', event => {
  console.log('🚀 Service Worker: Activation');
  
  event.waitUntil(
    Promise.all([
      // Nettoyer les anciens caches
      caches.keys().then(cacheNames => {
        return Promise.all(
          cacheNames.map(cacheName => {
            if (cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
              console.log('🗑️ Suppression ancien cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      }),
      
      // Prendre le contrôle immédiatement
      self.clients.claim()
    ]).then(() => {
      console.log('✅ Service Worker: Activation terminée');
    })
  );
});

// Interception des requêtes
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Ignorer les requêtes non-HTTP
  if (!request.url.startsWith('http')) {
    return;
  }
  
  // Stratégie Cache First pour les ressources statiques
  if (STATIC_ASSETS.some(asset => request.url.includes(asset))) {
    event.respondWith(cacheFirst(request));
    return;
  }
  
  // Stratégie Network First pour les API
  if (request.url.includes('/api/')) {
    event.respondWith(networkFirst(request));
    return;
  }
  
  // Stratégie Stale While Revalidate pour le reste
  event.respondWith(staleWhileRevalidate(request));
});

// Stratégie Cache First
async function cacheFirst(request) {
  try {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(STATIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.error('❌ Cache First error:', error);
    return new Response('Contenu non disponible hors ligne', {
      status: 503,
      statusText: 'Service Unavailable'
    });
  }
}

// Stratégie Network First
async function networkFirst(request) {
  try {
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.log('🔄 Network First: Fallback vers cache pour', request.url);
    
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // Réponse offline pour les API
    return new Response(JSON.stringify({
      success: false,
      error: 'Connexion réseau indisponible',
      offline: true,
      timestamp: new Date().toISOString()
    }), {
      status: 503,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}

// Stratégie Stale While Revalidate
async function staleWhileRevalidate(request) {
  const cache = await caches.open(DYNAMIC_CACHE);
  const cachedResponse = await cache.match(request);
  
  const fetchPromise = fetch(request).then(networkResponse => {
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  }).catch(() => cachedResponse);
  
  return cachedResponse || fetchPromise;
}

// Gestion des notifications push
self.addEventListener('push', event => {
  console.log('🔔 Notification push reçue');
  
  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = { title: 'SAMA CONAI', body: event.data.text() };
    }
  }
  
  const options = {
    title: data.title || 'SAMA CONAI Premium',
    body: data.body || 'Nouvelle notification',
    icon: '/images/icon-192x192.png',
    badge: '/images/badge-72x72.png',
    image: data.image,
    data: data.data || {},
    actions: [
      {
        action: 'open',
        title: 'Ouvrir',
        icon: '/images/action-open.png'
      },
      {
        action: 'dismiss',
        title: 'Ignorer',
        icon: '/images/action-dismiss.png'
      }
    ],
    tag: data.tag || 'sama-notification',
    renotify: true,
    requireInteraction: data.requireInteraction || false,
    silent: data.silent || false,
    vibrate: data.vibrate || [200, 100, 200],
    timestamp: Date.now()
  };
  
  event.waitUntil(
    self.registration.showNotification(options.title, options)
  );
});

// Gestion des clics sur notifications
self.addEventListener('notificationclick', event => {
  console.log('👆 Clic sur notification:', event.action);
  
  event.notification.close();
  
  if (event.action === 'dismiss') {
    return;
  }
  
  const urlToOpen = event.notification.data.url || '/';
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then(clientList => {
        // Chercher une fenêtre existante
        for (const client of clientList) {
          if (client.url.includes(self.location.origin) && 'focus' in client) {
            client.focus();
            if (urlToOpen !== '/') {
              client.navigate(urlToOpen);
            }
            return;
          }
        }
        
        // Ouvrir une nouvelle fenêtre
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});

// Synchronisation en arrière-plan
self.addEventListener('sync', event => {
  console.log('🔄 Synchronisation en arrière-plan:', event.tag);
  
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

// Fonction de synchronisation
async function doBackgroundSync() {
  try {
    // Synchroniser les données en attente
    const pendingData = await getStoredPendingData();
    
    for (const item of pendingData) {
      try {
        await fetch(item.url, {
          method: item.method,
          headers: item.headers,
          body: item.body
        });
        
        // Supprimer de la liste en attente
        await removePendingData(item.id);
      } catch (error) {
        console.error('❌ Erreur sync:', error);
      }
    }
    
    console.log('✅ Synchronisation terminée');
  } catch (error) {
    console.error('❌ Erreur synchronisation:', error);
  }
}

// Utilitaires pour les données en attente
async function getStoredPendingData() {
  // Implémentation simplifiée - en production, utiliser IndexedDB
  return [];
}

async function removePendingData(id) {
  // Implémentation simplifiée
  return Promise.resolve();
}

// Gestion des messages du client
self.addEventListener('message', event => {
  console.log('💬 Message reçu:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: CACHE_NAME });
  }
  
  if (event.data && event.data.type === 'CACHE_URLS') {
    event.waitUntil(
      caches.open(DYNAMIC_CACHE).then(cache => {
        return cache.addAll(event.data.urls);
      })
    );
  }
});

// Gestion des erreurs
self.addEventListener('error', event => {
  console.error('❌ Erreur Service Worker:', event.error);
});

self.addEventListener('unhandledrejection', event => {
  console.error('❌ Promise rejetée:', event.reason);
});

// Nettoyage périodique du cache
setInterval(() => {
  cleanupCache();
}, 24 * 60 * 60 * 1000); // Tous les jours

async function cleanupCache() {
  try {
    const cache = await caches.open(DYNAMIC_CACHE);
    const requests = await cache.keys();
    
    const now = Date.now();
    const maxAge = 7 * 24 * 60 * 60 * 1000; // 7 jours
    
    for (const request of requests) {
      const response = await cache.match(request);
      const dateHeader = response.headers.get('date');
      
      if (dateHeader) {
        const responseDate = new Date(dateHeader).getTime();
        if (now - responseDate > maxAge) {
          await cache.delete(request);
          console.log('🗑️ Cache expiré supprimé:', request.url);
        }
      }
    }
  } catch (error) {
    console.error('❌ Erreur nettoyage cache:', error);
  }
}

console.log('🚀 Service Worker SAMA CONAI Premium v4.0 chargé');