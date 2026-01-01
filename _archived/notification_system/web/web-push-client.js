// Web Push Client - handles subscription from Flutter via JS interop
// Everyday Christian PWA
// No Firebase - uses standard Web Push API with Cloudflare Worker backend

// Worker URL for push notification backend
const WORKER_URL = 'https://edc-web-push.connect-2a2.workers.dev';

// VAPID public key - fetched from Worker or set manually
let VAPID_PUBLIC_KEY = null;

// Current user ID for subscription tracking
let CURRENT_USER_ID = null;

// Convert VAPID key to Uint8Array (required by Push API)
function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

// Fetch VAPID key from Worker
async function fetchVapidKey() {
  try {
    const response = await fetch(`${WORKER_URL}/vapid-public-key`);
    if (response.ok) {
      const data = await response.json();
      VAPID_PUBLIC_KEY = data.publicKey;
      console.log('[WebPush] VAPID key fetched from server');
      return true;
    }
  } catch (error) {
    console.error('[WebPush] Failed to fetch VAPID key:', error);
  }
  return false;
}

// Set VAPID public key manually (called from Flutter)
function setVapidKey(key) {
  VAPID_PUBLIC_KEY = key;
  console.log('[WebPush] VAPID key set manually');
  return true;
}

// Set current user ID for subscription tracking
function setUserId(userId) {
  CURRENT_USER_ID = userId;
  console.log('[WebPush] User ID set:', userId);
  return true;
}

// Check if push is supported
function isPushSupported() {
  return 'serviceWorker' in navigator &&
         'PushManager' in window &&
         'Notification' in window;
}

// Get current permission status
function getPushPermissionStatus() {
  if (!('Notification' in window)) return 'unsupported';
  return Notification.permission; // 'granted', 'denied', or 'default'
}

// Send subscription to Worker backend
async function sendSubscriptionToServer(subscription) {
  if (!CURRENT_USER_ID) {
    console.warn('[WebPush] User ID not set, subscription not sent to server');
    return false;
  }

  try {
    const response = await fetch(`${WORKER_URL}/subscribe`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: CURRENT_USER_ID,
        subscription: subscription
      })
    });

    if (response.ok) {
      console.log('[WebPush] Subscription sent to server');
      return true;
    } else {
      console.error('[WebPush] Failed to send subscription:', await response.text());
      return false;
    }
  } catch (error) {
    console.error('[WebPush] Error sending subscription:', error);
    return false;
  }
}

// Remove subscription from Worker backend
async function removeSubscriptionFromServer() {
  if (!CURRENT_USER_ID) {
    return true; // Nothing to remove
  }

  try {
    const response = await fetch(`${WORKER_URL}/unsubscribe`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: CURRENT_USER_ID })
    });

    return response.ok;
  } catch (error) {
    console.error('[WebPush] Error removing subscription:', error);
    return false;
  }
}

// Initialize push notifications
async function initWebPush() {
  if (!isPushSupported()) {
    console.log('[WebPush] Push notifications not supported');
    return null;
  }

  // Fetch VAPID key from server if not set
  if (!VAPID_PUBLIC_KEY) {
    const fetched = await fetchVapidKey();
    if (!fetched) {
      console.error('[WebPush] Could not get VAPID key');
      return null;
    }
  }

  try {
    // Register service worker
    const registration = await navigator.serviceWorker.register('/web-push-sw.js');
    console.log('[WebPush] Service Worker registered');

    // Wait for service worker to be ready
    await navigator.serviceWorker.ready;

    // Check for existing subscription
    let subscription = await registration.pushManager.getSubscription();

    if (!subscription) {
      // Request permission
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') {
        console.log('[WebPush] Notification permission denied');
        return null;
      }

      // Create new subscription
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY)
      });
      console.log('[WebPush] New subscription created');
    } else {
      console.log('[WebPush] Using existing subscription');
    }

    // Send subscription to server
    const subscriptionJSON = subscription.toJSON();
    await sendSubscriptionToServer(subscriptionJSON);

    return JSON.stringify(subscriptionJSON);
  } catch (error) {
    console.error('[WebPush] Subscription failed:', error);
    return null;
  }
}

// Get existing subscription without prompting
async function getExistingSubscription() {
  if (!isPushSupported()) {
    return null;
  }

  try {
    const registration = await navigator.serviceWorker.getRegistration('/web-push-sw.js');
    if (!registration) {
      return null;
    }

    const subscription = await registration.pushManager.getSubscription();
    if (subscription) {
      return JSON.stringify(subscription);
    }
    return null;
  } catch (error) {
    console.error('[WebPush] Failed to get existing subscription:', error);
    return null;
  }
}

// Unsubscribe from push
async function unsubscribeWebPush() {
  try {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.getSubscription();
    if (subscription) {
      await subscription.unsubscribe();
      console.log('[WebPush] Unsubscribed from browser');
    }

    // Also remove from server
    await removeSubscriptionFromServer();

    return true;
  } catch (error) {
    console.error('[WebPush] Unsubscribe failed:', error);
    return false;
  }
}

// Set app badge count
async function setAppBadge(count) {
  if (!('setAppBadge' in navigator)) {
    console.log('[WebPush] Badge API not supported');
    return false;
  }

  try {
    await navigator.setAppBadge(count);
    console.log('[WebPush] Badge set to:', count);
    return true;
  } catch (error) {
    console.error('[WebPush] Failed to set badge:', error);
    return false;
  }
}

// Clear app badge
async function clearAppBadge() {
  if (!('clearAppBadge' in navigator)) {
    console.log('[WebPush] Badge API not supported');
    return false;
  }

  try {
    await navigator.clearAppBadge();
    console.log('[WebPush] Badge cleared');
    return true;
  } catch (error) {
    console.error('[WebPush] Failed to clear badge:', error);
    return false;
  }
}

// Check if badge API is supported
function isBadgeSupported() {
  return 'setAppBadge' in navigator;
}

// Get browser timezone
function getTimezone() {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  } catch (e) {
    console.error('[WebPush] Failed to get timezone:', e);
    return 'UTC';
  }
}

// Save notification preferences to server
async function savePreferences(preferences) {
  if (!CURRENT_USER_ID) {
    console.warn('[WebPush] User ID not set, cannot save preferences');
    return false;
  }

  try {
    const timezone = getTimezone();

    // Get existing subscription if available
    let subscription = null;
    try {
      const registration = await navigator.serviceWorker.getRegistration('/web-push-sw.js');
      if (registration) {
        const sub = await registration.pushManager.getSubscription();
        if (sub) {
          subscription = sub.toJSON();
        }
      }
    } catch (e) {
      console.warn('[WebPush] Could not get existing subscription:', e);
    }

    const response = await fetch(`${WORKER_URL}/preferences`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: CURRENT_USER_ID,
        timezone: timezone,
        subscription: subscription,
        preferences: preferences
      })
    });

    if (response.ok) {
      const result = await response.json();
      console.log('[WebPush] Preferences saved successfully');
      return result;
    } else {
      const error = await response.text();
      console.error('[WebPush] Failed to save preferences:', error);
      return false;
    }
  } catch (error) {
    console.error('[WebPush] Error saving preferences:', error);
    return false;
  }
}

// Get notification preferences from server
async function getPreferences() {
  if (!CURRENT_USER_ID) {
    console.warn('[WebPush] User ID not set, cannot get preferences');
    return null;
  }

  try {
    const response = await fetch(`${WORKER_URL}/preferences?userId=${encodeURIComponent(CURRENT_USER_ID)}`);

    if (response.ok) {
      return await response.json();
    } else {
      console.error('[WebPush] Failed to get preferences:', await response.text());
      return null;
    }
  } catch (error) {
    console.error('[WebPush] Error getting preferences:', error);
    return null;
  }
}

// Get Worker status
async function getWorkerStatus() {
  try {
    const response = await fetch(`${WORKER_URL}/status`);
    if (response.ok) {
      return await response.json();
    }
  } catch (error) {
    console.error('[WebPush] Failed to get worker status:', error);
  }
  return null;
}

// Expose to Flutter via window object
window.WebPush = {
  setVapidKey: setVapidKey,
  setUserId: setUserId,
  init: initWebPush,
  getExistingSubscription: getExistingSubscription,
  unsubscribe: unsubscribeWebPush,
  isSupported: isPushSupported,
  getPermissionStatus: getPushPermissionStatus,
  setAppBadge: setAppBadge,
  clearAppBadge: clearAppBadge,
  isBadgeSupported: isBadgeSupported,
  getWorkerStatus: getWorkerStatus,
  fetchVapidKey: fetchVapidKey,
  getTimezone: getTimezone,
  savePreferences: savePreferences,
  getPreferences: getPreferences
};

console.log('[WebPush] Client library loaded (with Cloudflare Worker backend)');
