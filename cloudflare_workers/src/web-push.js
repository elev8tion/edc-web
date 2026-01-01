/**
 * Web Push Notification Worker
 *
 * Handles push subscription storage and notification sending
 * Uses Cloudflare KV for subscription storage
 *
 * Endpoints:
 * - POST /subscribe     - Store push subscription
 * - POST /unsubscribe   - Remove subscription
 * - POST /send          - Send notification to specific user
 * - POST /send-all      - Broadcast to all subscribers
 * - GET  /status        - Check service status
 *
 * Environment Variables (Secrets):
 * - VAPID_PUBLIC_KEY    - VAPID public key (base64)
 * - VAPID_PRIVATE_KEY   - VAPID private key (base64)
 * - VAPID_SUBJECT       - mailto: or https:// contact
 *
 * KV Namespace:
 * - PUSH_SUBSCRIPTIONS  - Stores user subscriptions
 */

export default {
  async fetch(request, env) {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // Route requests
      switch (path) {
        case '/subscribe':
          return handleSubscribe(request, env, corsHeaders);
        case '/unsubscribe':
          return handleUnsubscribe(request, env, corsHeaders);
        case '/send':
          return handleSend(request, env, corsHeaders);
        case '/send-all':
          return handleSendAll(request, env, corsHeaders);
        case '/vapid-public-key':
          return handleGetVapidKey(env, corsHeaders);
        case '/status':
          return handleStatus(env, corsHeaders);
        default:
          return jsonResponse({ error: 'Not found' }, 404, corsHeaders);
      }
    } catch (error) {
      console.error('Worker error:', error);
      return jsonResponse({
        error: 'Internal server error',
        message: error.message
      }, 500, corsHeaders);
    }
  },

  // Scheduled handler for daily devotional notifications
  async scheduled(event, env, ctx) {
    console.log('Scheduled push notification triggered');

    try {
      // Get all subscriptions and send daily devotional reminder
      const subscriptions = await getAllSubscriptions(env);

      if (subscriptions.length === 0) {
        console.log('No subscriptions to notify');
        return;
      }

      const payload = JSON.stringify({
        title: 'Daily Devotional Ready',
        body: 'Your daily devotional is waiting for you!',
        icon: '/icons/Icon-192.png',
        badge: '/icons/badge-72.png',
        tag: 'daily-devotional',
        badgeCount: 1,
        data: {
          url: '/devotional',
          type: 'daily-devotional'
        }
      });

      let sent = 0;
      let failed = 0;

      for (const { userId, subscription } of subscriptions) {
        try {
          await sendPushNotification(env, subscription, payload);
          sent++;
        } catch (e) {
          console.error(`Failed to send to ${userId}:`, e.message);
          failed++;

          // Remove invalid subscriptions
          if (e.message.includes('expired') || e.message.includes('unsubscribed')) {
            await env.PUSH_SUBSCRIPTIONS.delete(`sub:${userId}`);
          }
        }
      }

      console.log(`Scheduled push complete: ${sent} sent, ${failed} failed`);
    } catch (error) {
      console.error('Scheduled push error:', error);
    }
  }
};

/**
 * Store a push subscription
 */
async function handleSubscribe(request, env, corsHeaders) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, corsHeaders);
  }

  const body = await request.json();
  const { userId, subscription } = body;

  if (!userId || !subscription) {
    return jsonResponse({
      error: 'Missing required fields: userId, subscription'
    }, 400, corsHeaders);
  }

  // Validate subscription object
  if (!subscription.endpoint || !subscription.keys) {
    return jsonResponse({
      error: 'Invalid subscription object'
    }, 400, corsHeaders);
  }

  try {
    // Store subscription with userId as key
    await env.PUSH_SUBSCRIPTIONS.put(
      `sub:${userId}`,
      JSON.stringify({
        subscription,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }),
      {
        // Expire after 1 year (subscriptions should be refreshed)
        expirationTtl: 365 * 24 * 60 * 60
      }
    );

    // Also add to index for broadcast
    await addToIndex(env, userId);

    console.log(`Subscription stored for user: ${userId}`);

    return jsonResponse({
      success: true,
      message: 'Subscription stored successfully'
    }, 200, corsHeaders);
  } catch (error) {
    console.error('Failed to store subscription:', error);
    return jsonResponse({
      error: 'Failed to store subscription',
      message: error.message
    }, 500, corsHeaders);
  }
}

/**
 * Remove a push subscription
 */
async function handleUnsubscribe(request, env, corsHeaders) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, corsHeaders);
  }

  const body = await request.json();
  const { userId } = body;

  if (!userId) {
    return jsonResponse({ error: 'Missing userId' }, 400, corsHeaders);
  }

  try {
    await env.PUSH_SUBSCRIPTIONS.delete(`sub:${userId}`);
    await removeFromIndex(env, userId);

    console.log(`Subscription removed for user: ${userId}`);

    return jsonResponse({
      success: true,
      message: 'Subscription removed'
    }, 200, corsHeaders);
  } catch (error) {
    console.error('Failed to remove subscription:', error);
    return jsonResponse({
      error: 'Failed to remove subscription'
    }, 500, corsHeaders);
  }
}

/**
 * Send notification to specific user
 */
async function handleSend(request, env, corsHeaders) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, corsHeaders);
  }

  const body = await request.json();
  const { userId, title, body: messageBody, icon, badge, tag, url, badgeCount } = body;

  if (!userId) {
    return jsonResponse({ error: 'Missing userId' }, 400, corsHeaders);
  }

  // Get subscription
  const stored = await env.PUSH_SUBSCRIPTIONS.get(`sub:${userId}`);
  if (!stored) {
    return jsonResponse({ error: 'No subscription found for user' }, 404, corsHeaders);
  }

  const { subscription } = JSON.parse(stored);

  // Build notification payload
  const payload = JSON.stringify({
    title: title || 'Everyday Christian',
    body: messageBody || 'You have a new notification',
    icon: icon || '/icons/Icon-192.png',
    badge: badge || '/icons/badge-72.png',
    tag: tag || 'general',
    badgeCount: badgeCount,
    data: {
      url: url || '/',
      timestamp: Date.now()
    }
  });

  try {
    await sendPushNotification(env, subscription, payload);
    return jsonResponse({ success: true, message: 'Notification sent' }, 200, corsHeaders);
  } catch (error) {
    console.error('Failed to send notification:', error);

    // Remove invalid subscription
    if (error.message.includes('expired') || error.message.includes('unsubscribed') || error.message.includes('410')) {
      await env.PUSH_SUBSCRIPTIONS.delete(`sub:${userId}`);
      await removeFromIndex(env, userId);
      return jsonResponse({
        error: 'Subscription expired',
        removed: true
      }, 410, corsHeaders);
    }

    return jsonResponse({
      error: 'Failed to send notification',
      message: error.message
    }, 500, corsHeaders);
  }
}

/**
 * Broadcast notification to all subscribers
 */
async function handleSendAll(request, env, corsHeaders) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, corsHeaders);
  }

  const body = await request.json();
  const { title, body: messageBody, icon, badge, tag, url, badgeCount } = body;

  const payload = JSON.stringify({
    title: title || 'Everyday Christian',
    body: messageBody || 'You have a new notification',
    icon: icon || '/icons/Icon-192.png',
    badge: badge || '/icons/badge-72.png',
    tag: tag || 'broadcast',
    badgeCount: badgeCount,
    data: {
      url: url || '/',
      timestamp: Date.now()
    }
  });

  try {
    const subscriptions = await getAllSubscriptions(env);

    let sent = 0;
    let failed = 0;
    const errors = [];

    for (const { userId, subscription } of subscriptions) {
      try {
        await sendPushNotification(env, subscription, payload);
        sent++;
      } catch (e) {
        failed++;
        errors.push({ userId, error: e.message });

        // Remove invalid subscriptions
        if (e.message.includes('expired') || e.message.includes('410')) {
          await env.PUSH_SUBSCRIPTIONS.delete(`sub:${userId}`);
          await removeFromIndex(env, userId);
        }
      }
    }

    return jsonResponse({
      success: true,
      sent,
      failed,
      total: subscriptions.length,
      errors: errors.length > 0 ? errors.slice(0, 10) : undefined // Limit error details
    }, 200, corsHeaders);
  } catch (error) {
    console.error('Broadcast failed:', error);
    return jsonResponse({
      error: 'Broadcast failed',
      message: error.message
    }, 500, corsHeaders);
  }
}

/**
 * Get VAPID public key for client
 */
async function handleGetVapidKey(env, corsHeaders) {
  const publicKey = env.VAPID_PUBLIC_KEY;

  if (!publicKey) {
    return jsonResponse({ error: 'VAPID key not configured' }, 500, corsHeaders);
  }

  return jsonResponse({ publicKey }, 200, corsHeaders);
}

/**
 * Health check endpoint
 */
async function handleStatus(env, corsHeaders) {
  const hasVapid = !!(env.VAPID_PUBLIC_KEY && env.VAPID_PRIVATE_KEY);
  const hasKV = !!env.PUSH_SUBSCRIPTIONS;

  // Get subscriber count
  let subscriberCount = 0;
  try {
    const index = await env.PUSH_SUBSCRIPTIONS.get('index:users');
    if (index) {
      subscriberCount = JSON.parse(index).length;
    }
  } catch (e) {
    // Ignore
  }

  return jsonResponse({
    status: 'ok',
    vapidConfigured: hasVapid,
    kvConfigured: hasKV,
    subscriberCount,
    timestamp: new Date().toISOString()
  }, 200, corsHeaders);
}

/**
 * Send push notification using Web Push protocol
 */
async function sendPushNotification(env, subscription, payload) {
  const vapidPublicKey = env.VAPID_PUBLIC_KEY;
  const vapidPrivateKey = env.VAPID_PRIVATE_KEY;
  const vapidSubject = env.VAPID_SUBJECT || 'mailto:support@everydaychristian.app';

  if (!vapidPublicKey || !vapidPrivateKey) {
    throw new Error('VAPID keys not configured');
  }

  // Import web-push compatible library functions
  const { endpoint, keys } = subscription;
  const { p256dh, auth } = keys;

  // Create VAPID JWT
  const vapidToken = await createVapidJWT(vapidPrivateKey, vapidPublicKey, endpoint, vapidSubject);

  // Encrypt payload
  const encryptedPayload = await encryptPayload(payload, p256dh, auth);

  // Send to push service
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'TTL': '86400', // 24 hours
      'Content-Encoding': 'aes128gcm',
      'Content-Type': 'application/octet-stream',
      'Authorization': `vapid t=${vapidToken.token}, k=${vapidToken.publicKey}`,
    },
    body: encryptedPayload,
  });

  if (!response.ok) {
    const status = response.status;
    if (status === 404 || status === 410) {
      throw new Error('Subscription expired or unsubscribed (410)');
    }
    const text = await response.text();
    throw new Error(`Push failed: ${status} ${text}`);
  }

  return true;
}

/**
 * Create VAPID JWT for authorization
 */
async function createVapidJWT(privateKeyBase64, publicKeyBase64, endpoint, subject) {
  const audience = new URL(endpoint).origin;
  const expiry = Math.floor(Date.now() / 1000) + (12 * 60 * 60); // 12 hours

  const header = {
    typ: 'JWT',
    alg: 'ES256'
  };

  const payload = {
    aud: audience,
    exp: expiry,
    sub: subject
  };

  // Base64URL encode
  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(payload));
  const unsignedToken = `${headerB64}.${payloadB64}`;

  // Sign with private key
  const privateKey = await importPrivateKey(privateKeyBase64);
  const signature = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    privateKey,
    new TextEncoder().encode(unsignedToken)
  );

  const signatureB64 = base64UrlEncode(new Uint8Array(signature));

  return {
    token: `${unsignedToken}.${signatureB64}`,
    publicKey: publicKeyBase64
  };
}

/**
 * Encrypt notification payload using Web Push encryption
 */
async function encryptPayload(payload, p256dhBase64, authBase64) {
  // Decode client public key and auth secret
  const clientPublicKey = base64UrlDecode(p256dhBase64);
  const authSecret = base64UrlDecode(authBase64);

  // Generate ephemeral key pair
  const ephemeralKeyPair = await crypto.subtle.generateKey(
    { name: 'ECDH', namedCurve: 'P-256' },
    true,
    ['deriveBits']
  );

  // Import client public key
  const clientKey = await crypto.subtle.importKey(
    'raw',
    clientPublicKey,
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    []
  );

  // Derive shared secret
  const sharedSecret = await crypto.subtle.deriveBits(
    { name: 'ECDH', public: clientKey },
    ephemeralKeyPair.privateKey,
    256
  );

  // Export ephemeral public key
  const ephemeralPublicKey = await crypto.subtle.exportKey('raw', ephemeralKeyPair.publicKey);

  // Derive encryption key using HKDF
  const salt = crypto.getRandomValues(new Uint8Array(16));

  // Build info for HKDF
  const keyInfo = buildInfo('aesgcm', clientPublicKey, new Uint8Array(ephemeralPublicKey));
  const nonceInfo = buildInfo('nonce', clientPublicKey, new Uint8Array(ephemeralPublicKey));

  // Import auth secret
  const authKey = await crypto.subtle.importKey(
    'raw',
    authSecret,
    { name: 'HKDF' },
    false,
    ['deriveBits']
  );

  // Derive PRK
  const prk = await crypto.subtle.deriveBits(
    { name: 'HKDF', hash: 'SHA-256', salt: authSecret, info: concatBuffers(new TextEncoder().encode('Content-Encoding: auth\0'), new Uint8Array(sharedSecret)) },
    await crypto.subtle.importKey('raw', new Uint8Array(sharedSecret), { name: 'HKDF' }, false, ['deriveBits']),
    256
  );

  // Derive content encryption key
  const cekInfo = concatBuffers(new TextEncoder().encode('Content-Encoding: aes128gcm\0'), keyInfo);
  const cek = await crypto.subtle.deriveBits(
    { name: 'HKDF', hash: 'SHA-256', salt, info: cekInfo },
    await crypto.subtle.importKey('raw', new Uint8Array(prk), { name: 'HKDF' }, false, ['deriveBits']),
    128
  );

  // Derive nonce
  const nonceInfoFull = concatBuffers(new TextEncoder().encode('Content-Encoding: nonce\0'), nonceInfo);
  const nonce = await crypto.subtle.deriveBits(
    { name: 'HKDF', hash: 'SHA-256', salt, info: nonceInfoFull },
    await crypto.subtle.importKey('raw', new Uint8Array(prk), { name: 'HKDF' }, false, ['deriveBits']),
    96
  );

  // Encrypt with AES-GCM
  const encryptionKey = await crypto.subtle.importKey(
    'raw',
    new Uint8Array(cek),
    { name: 'AES-GCM' },
    false,
    ['encrypt']
  );

  // Add padding (single byte for delimiter)
  const paddedPayload = concatBuffers(new TextEncoder().encode(payload), new Uint8Array([2]));

  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: new Uint8Array(nonce) },
    encryptionKey,
    paddedPayload
  );

  // Build aes128gcm encrypted content
  // Header: salt (16) + rs (4) + idlen (1) + keyid (65) + encrypted content
  const rs = new Uint8Array(4);
  new DataView(rs.buffer).setUint32(0, 4096, false);

  const header = concatBuffers(
    salt,
    rs,
    new Uint8Array([65]),
    new Uint8Array(ephemeralPublicKey)
  );

  return concatBuffers(header, new Uint8Array(encrypted));
}

/**
 * Import VAPID private key
 */
async function importPrivateKey(base64Key) {
  const keyData = base64UrlDecode(base64Key);

  // Build JWK from raw private key
  const jwk = {
    kty: 'EC',
    crv: 'P-256',
    d: base64UrlEncode(keyData),
    x: '', // Will be derived
    y: ''
  };

  // For ES256, we need the full key - use raw import
  return await crypto.subtle.importKey(
    'raw',
    keyData,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign']
  );
}

/**
 * Build info parameter for HKDF
 */
function buildInfo(type, clientPublicKey, serverPublicKey) {
  const encoder = new TextEncoder();
  return concatBuffers(
    encoder.encode(`Content-Encoding: ${type}\0`),
    encoder.encode('P-256\0'),
    new Uint8Array([0, 65]),
    clientPublicKey,
    new Uint8Array([0, 65]),
    serverPublicKey
  );
}

/**
 * Concatenate ArrayBuffers/Uint8Arrays
 */
function concatBuffers(...buffers) {
  const totalLength = buffers.reduce((sum, buf) => sum + buf.byteLength, 0);
  const result = new Uint8Array(totalLength);
  let offset = 0;
  for (const buf of buffers) {
    result.set(new Uint8Array(buf instanceof ArrayBuffer ? buf : buf.buffer), offset);
    offset += buf.byteLength;
  }
  return result;
}

/**
 * Base64URL encode
 */
function base64UrlEncode(data) {
  const bytes = typeof data === 'string'
    ? new TextEncoder().encode(data)
    : new Uint8Array(data);
  const base64 = btoa(String.fromCharCode(...bytes));
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/**
 * Base64URL decode
 */
function base64UrlDecode(str) {
  const base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  const padding = (4 - base64.length % 4) % 4;
  const padded = base64 + '='.repeat(padding);
  const binary = atob(padded);
  return new Uint8Array([...binary].map(c => c.charCodeAt(0)));
}

/**
 * Get all subscriptions from KV
 */
async function getAllSubscriptions(env) {
  const subscriptions = [];

  try {
    const indexData = await env.PUSH_SUBSCRIPTIONS.get('index:users');
    if (!indexData) return subscriptions;

    const userIds = JSON.parse(indexData);

    for (const userId of userIds) {
      const stored = await env.PUSH_SUBSCRIPTIONS.get(`sub:${userId}`);
      if (stored) {
        const { subscription } = JSON.parse(stored);
        subscriptions.push({ userId, subscription });
      }
    }
  } catch (e) {
    console.error('Failed to get subscriptions:', e);
  }

  return subscriptions;
}

/**
 * Add user to index
 */
async function addToIndex(env, userId) {
  try {
    const indexData = await env.PUSH_SUBSCRIPTIONS.get('index:users');
    const users = indexData ? JSON.parse(indexData) : [];

    if (!users.includes(userId)) {
      users.push(userId);
      await env.PUSH_SUBSCRIPTIONS.put('index:users', JSON.stringify(users));
    }
  } catch (e) {
    console.error('Failed to update index:', e);
  }
}

/**
 * Remove user from index
 */
async function removeFromIndex(env, userId) {
  try {
    const indexData = await env.PUSH_SUBSCRIPTIONS.get('index:users');
    if (!indexData) return;

    const users = JSON.parse(indexData);
    const filtered = users.filter(id => id !== userId);
    await env.PUSH_SUBSCRIPTIONS.put('index:users', JSON.stringify(filtered));
  } catch (e) {
    console.error('Failed to update index:', e);
  }
}

/**
 * JSON response helper
 */
function jsonResponse(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  });
}
