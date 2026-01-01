// Native Web Push Service Worker
// No Firebase - uses standard Push API
// Everyday Christian PWA

// Handle incoming push notifications
self.addEventListener('push', (event) => {
  // Parse notification data
  let data = {};
  try {
    data = event.data?.json() || {};
  } catch (e) {
    data = { body: event.data?.text() || 'New notification' };
  }

  const title = data.title || 'Everyday Christian';
  const options = {
    body: data.body || 'You have a new update',
    icon: data.icon || '/icons/Icon-192.png',
    badge: '/icons/badge-72.png',
    vibrate: [200, 100, 200],
    tag: data.tag || 'default',
    renotify: true,
    data: {
      url: data.url || '/',
      type: data.type || 'general'
    },
    actions: [
      { action: 'open', title: 'Open' },
      { action: 'dismiss', title: 'Dismiss' }
    ]
  };

  // Update app badge if count provided
  if (data.badgeCount !== undefined && navigator.setAppBadge) {
    navigator.setAppBadge(parseInt(data.badgeCount));
  }

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'dismiss') {
    return;
  }

  // Open or focus the app
  const urlToOpen = event.notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Focus existing window if available
        for (const client of clientList) {
          if (client.url.includes(self.location.origin) && 'focus' in client) {
            client.navigate(urlToOpen);
            return client.focus();
          }
        }
        // Open new window
        return clients.openWindow(urlToOpen);
      })
  );
});

// Handle subscription change (browser may rotate keys)
self.addEventListener('pushsubscriptionchange', (event) => {
  console.log('[SW] Push subscription changed, resubscribing...');

  event.waitUntil(
    self.registration.pushManager.subscribe({
      userVisibleOnly: true,
      // Note: applicationServerKey will be set from the main app
    })
    .then((subscription) => {
      // Send updated subscription to server
      return fetch('/api/push/update-subscription', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(subscription)
      });
    })
    .catch((error) => {
      console.error('[SW] Failed to resubscribe:', error);
    })
  );
});

// Log service worker lifecycle events
self.addEventListener('install', (event) => {
  console.log('[SW] Web Push Service Worker installed');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log('[SW] Web Push Service Worker activated');
  event.waitUntil(clients.claim());
});
