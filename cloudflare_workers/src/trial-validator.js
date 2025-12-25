/**
 * Trial Validation Worker - IP + Fingerprint Hybrid Abuse Prevention
 *
 * This worker validates trial eligibility using a multi-signal approach:
 * - PRIMARY: IP address hash (catches casual abuse, shared networks)
 * - SECONDARY: Device fingerprint hash (catches VPN bypass, browser switching)
 *
 * Logic: Block trial if EITHER signal has been seen before
 *
 * Privacy-first: All data is hashed (SHA-256), no raw IPs or fingerprints stored
 */

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

/**
 * Main request handler
 */
async function handleRequest(request) {
  // CORS headers for PWA access
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  // Handle CORS preflight
  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  // Only accept POST requests
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, corsHeaders);
  }

  try {
    const { fingerprint } = await request.json();

    // Validate input
    if (!fingerprint || typeof fingerprint !== 'string') {
      return jsonResponse({
        error: 'Invalid request: fingerprint required'
      }, 400, corsHeaders);
    }

    // Get client IP from Cloudflare headers
    const clientIP = request.headers.get('CF-Connecting-IP') ||
                     request.headers.get('X-Forwarded-For') ||
                     '0.0.0.0';

    // Hash both signals for privacy
    const ipHash = await hashString(clientIP);
    const fingerprintHash = await hashString(fingerprint);

    console.log('[Trial Validator] Checking eligibility:', {
      ipHash: ipHash.substring(0, 12) + '...',
      fingerprintHash: fingerprintHash.substring(0, 12) + '...',
      timestamp: new Date().toISOString()
    });

    // Check if either signal has been seen before
    const eligibility = await checkTrialEligibility(ipHash, fingerprintHash);

    if (eligibility.allowed) {
      // First-time user - record both signals
      await recordTrialUsage(ipHash, fingerprintHash);

      console.log('[Trial Validator] Trial allowed - new user');

      return jsonResponse({
        allowed: true,
        message: 'Trial activated',
        trialDays: 3,
        trialMessages: 15
      }, 200, corsHeaders);
    } else {
      // Previously seen - block trial
      console.log('[Trial Validator] Trial blocked:', eligibility.reason);

      return jsonResponse({
        allowed: false,
        message: eligibility.message,
        reason: eligibility.reason,
        suggestion: 'Subscribe to continue using Everyday Christian'
      }, 403, corsHeaders);
    }

  } catch (error) {
    console.error('[Trial Validator] Error:', error);

    return jsonResponse({
      error: 'Internal server error',
      message: 'Unable to validate trial eligibility'
    }, 500, corsHeaders);
  }
}

/**
 * Check if user is eligible for trial based on IP and fingerprint
 */
async function checkTrialEligibility(ipHash, fingerprintHash) {
  try {
    // Check NoCodeBackend trial_tracking table for existing records
    const apiKey = NOCODEBACKEND_TRIAL_API_KEY;
    const baseUrl = NOCODEBACKEND_BASE_URL;
    const instance = NOCODEBACKEND_INSTANCE;

    // Check IP hash (indexed field for fast lookup)
    // NoCodeBackend API format: GET /read/trial_tracking?Instance=xxx&ip_hash=xxx&status=active
    const ipCheckUrl = `${baseUrl}/read/trial_tracking?Instance=${instance}&ip_hash=${ipHash}&status=active`;
    const ipResponse = await fetch(ipCheckUrl, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    });

    if (!ipResponse.ok) {
      console.error('[Trial Validator] IP check failed:', await ipResponse.text());
      // On API error, allow trial (fail open for better UX)
      return { allowed: true };
    }

    const ipResult = await ipResponse.json();
    const ipData = ipResult.data || ipResult; // Handle both response formats

    // Check if IP has been used for trial before
    if (ipData && Array.isArray(ipData) && ipData.length > 0) {
      console.log('[Trial Validator] IP hash found in database:', ipData.length, 'records');
      return {
        allowed: false,
        reason: 'ip_hash_match',
        message: 'Trial already used from this network'
      };
    }

    // Check fingerprint hash (indexed field for fast lookup)
    const fpCheckUrl = `${baseUrl}/read/trial_tracking?Instance=${instance}&fingerprint_hash=${fingerprintHash}&status=active`;
    const fpResponse = await fetch(fpCheckUrl, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    });

    if (!fpResponse.ok) {
      console.error('[Trial Validator] Fingerprint check failed:', await fpResponse.text());
      // On API error, allow trial (fail open)
      return { allowed: true };
    }

    const fpResult = await fpResponse.json();
    const fpData = fpResult.data || fpResult; // Handle both response formats

    // Check if fingerprint has been used for trial before
    if (fpData && Array.isArray(fpData) && fpData.length > 0) {
      console.log('[Trial Validator] Fingerprint found in database:', fpData.length, 'records');
      return {
        allowed: false,
        reason: 'fingerprint_match',
        message: 'Trial already used on this device'
      };
    }

    // Neither IP nor fingerprint seen before - allow trial
    return { allowed: true };

  } catch (error) {
    console.error('[Trial Validator] Eligibility check error:', error);
    // On error, allow trial (fail open for better UX)
    return { allowed: true };
  }
}

/**
 * Record trial usage in NoCodeBackend trial_tracking table
 */
async function recordTrialUsage(ipHash, fingerprintHash) {
  try {
    const apiKey = NOCODEBACKEND_TRIAL_API_KEY;
    const baseUrl = NOCODEBACKEND_BASE_URL;
    const instance = NOCODEBACKEND_INSTANCE;

    const now = new Date();
    // Convert to MySQL datetime format: "YYYY-MM-DD HH:MM:SS"
    const mysqlDatetime = now.toISOString().slice(0, 19).replace('T', ' ');

    // NoCodeBackend API format: POST /create/trial_tracking
    // Instance must be in query string (matches working stripe-webhook.js pattern)
    const createUrl = `${baseUrl}/create/trial_tracking?Instance=${instance}`;

    const record = {
      ip_hash: ipHash,
      fingerprint_hash: fingerprintHash,
      trial_started_at: mysqlDatetime,
      status: 'active',
      messages_used: 0
    };

    const response = await fetch(createUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(record)
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Trial Validator] Failed to record trial:', errorText);
      // Non-critical error - trial still allowed
      return false;
    }

    const result = await response.json();
    console.log('[Trial Validator] Trial usage recorded successfully, ID:', result.id || 'unknown');
    return true;

  } catch (error) {
    console.error('[Trial Validator] Record trial error:', error);
    // Non-critical error - trial still allowed
    return false;
  }
}

/**
 * Hash string using SHA-256 (privacy-friendly)
 */
async function hashString(input) {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  return hashHex;
}

/**
 * JSON response helper
 */
function jsonResponse(data, status = 200, additionalHeaders = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...additionalHeaders
    }
  });
}
