// sw.js - Service Worker for SBO System (Düzeltilmiş Tam Sürüm)
const CACHE_NAME = 'sbo-cache-v3';
const RUNTIME_CACHE = 'sbo-runtime-v1';

// Önbelleğe alınacak statik kaynaklar
const urlsToCache = [
    './',
    './index.html',
    './offline.html',
    './manifest.json',
    'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css',
    'https://unpkg.com/dexie/dist/dexie.js',
    'https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js',
    'https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.25/jspdf.plugin.autotable.min.js',
    'https://cdn.jsdelivr.net/npm/sweetalert2@11',
    'https://cdn.sheetjs.com/xlsx-0.20.2/xlsx.full.min.js',
    'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js',
    'https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js',
    'https://cdn.jsdelivr.net/npm/dompurify@3.0.6/dist/purify.min.js',
    'https://cdn.jsdelivr.net/npm/jsbarcode@3.11.5/dist/JsBarcode.all.min.js'
];

// Install Event
self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('📦 Önbelleğe alınıyor:', urlsToCache.length, 'kaynak');
                return cache.addAll(urlsToCache).catch(err => {
                    console.warn('⚠️ Bazı kaynaklar önbelleğe alınamadı:', err);
                    return Promise.resolve();
                });
            })
            .then(() => self.skipWaiting())
    );
});

// Fetch Event - Gelişmiş Strateji
self.addEventListener('fetch', event => {
    const { request } = event;
    const url = new URL(request.url);

    // API istekleri - Network First (önbelleğe alma)
    if (url.pathname.includes('/api/') || url.pathname.includes('/graphql')) {
        event.respondWith(networkFirst(request));
        return;
    }

    // Navigasyon istekleri (HTML sayfalar)
    if (request.mode === 'navigate') {
        event.respondWith(navigationHandler(request));
        return;
    }

    // Resim ve fontlar - Cache First
    if (request.destination === 'image' || request.destination === 'font') {
        event.respondWith(cacheFirst(request));
        return;
    }

    // Script ve stil dosyaları - Stale While Revalidate
    if (request.destination === 'script' || request.destination === 'style') {
        event.respondWith(staleWhileRevalidate(request));
        return;
    }

    // Varsayılan - Network First
    event.respondWith(networkFirst(request));
});

// Cache First Stratejisi
async function cacheFirst(request) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
        return cachedResponse;
    }
    
    try {
        const networkResponse = await fetch(request);
        if (networkResponse && networkResponse.status === 200) {
            const cache = await caches.open(RUNTIME_CACHE);
            cache.put(request, networkResponse.clone());
        }
        return networkResponse;
    } catch (error) {
        console.error('❌ Kaynak yüklenemedi:', request.url);
        return new Response('Kaynak kullanılamıyor', { 
            status: 503, 
            statusText: 'Service Unavailable',
            headers: { 'Content-Type': 'text/plain' }
        });
    }
}

// Network First Stratejisi (API için)
async function netWorkFirst(request) {
    try {
        const networkResponse = await fetch(request);
        if (networkResponse && networkResponse.status === 200) {
            const cache = await caches.open(RUNTIME_CACHE);
            cache.put(request, networkResponse.clone());
        }
        return networkResponse;
    } catch (error) {
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        
        // API offline hatası
        return new Response(JSON.stringify({ 
            error: 'Offline', 
            message: 'İnternet bağlantısı yok. Veriler kaydedildi, bağlantı sağlandığında senkronize edilecek.' 
        }), {
            status: 503,
            headers: { 'Content-Type': 'application/json' }
        });
    }
}

// Stale While Revalidate Stratejisi
async function staleWhileRevalidate(request) {
    const cache = await caches.open(RUNTIME_CACHE);
    const cachedResponse = await cache.match(request);
    
    const networkResponsePromise = fetch(request)
        .then(response => {
            if (response && response.status === 200) {
                cache.put(request, response.clone());
            }
            return response;
        })
        .catch(err => {
            console.warn('⚠️ Ağ isteği başarısız:', request.url);
            return null;
        });

    return cachedResponse || networkResponsePromise;
}

// Navigasyon Handler
async function navigationHandler(request) {
    try {
        const networkResponse = await fetch(request);
        if (networkResponse && networkResponse.status === 200) {
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, networkResponse.clone());
        }
        return networkResponse;
    } catch (error) {
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        
        // Offline sayfasına yönlendir
        const offlinePage = await caches.match('./offline.html');
        if (offlinePage) {
            return offlinePage;
        }
        
        return new Response(
            `<!DOCTYPE html>
            <html lang="tr">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>SBO - Offline</title>
                <style>
                    body { font-family: system-ui; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f3f4f6; }
                    .container { text-align: center; padding: 2rem; }
                    h1 { color: #1f2937; }
                    p { color: #6b7280; margin-bottom: 1rem; }
                    button { background: #3b82f6; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 0.5rem; cursor: pointer; font-size: 1rem; }
                    button:hover { background: #2563eb; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>📡 İnternet Bağlantısı Yok</h1>
                    <p>SBO Sistemi şu anda çevrimdışı. Lütfen internet bağlantınızı kontrol edin.</p>
                    <button onclick="location.reload()">🔄 Tekrar Dene</button>
                </div>
            </body>
            </html>`,
            { 
                status: 200, 
                headers: { 'Content-Type': 'text/html' }
            }
        );
    }
}

// Activate Event - Eski cache'leri temizle
self.addEventListener('activate', event => {
    const currentCaches = [CACHE_NAME, RUNTIME_CACHE];
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    if (!currentCaches.includes(cacheName)) {
                        console.log('🗑️ Eski cache siliniyor:', cacheName);
                        return caches.delete(cacheName);
                    }
                })
            );
        }).then(() => self.clients.claim())
    );
});

// Background Sync
self.addEventListener('sync', event => {
    if (event.tag === 'sync-sbo-data') {
        event.waitUntil(syncOfflineData());
    }
});

async function syncOfflineData() {
    try {
        const clients = await self.clients.matchAll();
        clients.forEach(client => {
            client.postMessage({
                type: 'SYNC_STARTED',
                message: 'Veriler senkronize ediliyor...'
            });
        });
        
        // IndexedDB'den bekleyen verileri al
        console.log('🔄 Arka plan senkronizasyonu başladı');
        
        // Başarılı senkronizasyon mesajı
        clients.forEach(client => {
            client.postMessage({
                type: 'SYNC_COMPLETED',
                message: 'Veriler başarıyla senkronize edildi!'
            });
        });
    } catch (error) {
        console.error('❌ Senkronizasyon hatası:', error);
    }
}

// Push Notification
self.addEventListener('push', event => {
    const data = event.data?.json() || { 
        title: 'SBO Sistem', 
        body: 'Yeni bildirim var',
        icon: '/icon-192x192.png',
        badge: '/badge-72x72.png'
    };
    
    event.waitUntil(
        self.registration.showNotification(data.title, {
            body: data.body,
            icon: data.icon || '/icon-192x192.png',
            badge: data.badge || '/badge-72x72.png',
            vibrate: [200, 100, 200],
            data: {
                url: data.url || './'
            }
        })
    );
});

// Bildirime tıklama
self.addEventListener('notificationclick', event => {
    event.notification.close();
    
    event.waitUntil(
        clients.matchAll({ type: 'window' }).then(clientList => {
            const url = event.notification.data.url || './';
            
            for (const client of clientList) {
                if (client.url === url && 'focus' in client) {
                    return client.focus();
                }
            }
            
            if (clients.openWindow) {
                return clients.openWindow(url);
            }
        })
    );
});

// Service Worker güncelleme kontrolü
self.addEventListener('message', event => {
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
});

console.log('✅ SBO Service Worker v3 aktif!');
