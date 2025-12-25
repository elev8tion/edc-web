/**
 * Code Validation API - Worker 2
 * Validates activation codes and marks them as used
 */

export default {
  async fetch(request, env) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type'
        }
      });
    }

    // Only accept POST requests
    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    try {
      // Parse request body
      const { code, deviceId } = await request.json();

      // Validate input
      if (!code || !deviceId) {
        return jsonResponse({
          valid: false,
          error: 'Missing code or deviceId'
        }, 400);
      }

      // Find code in NoCodeBackend
      const findResponse = await fetch(
        `https://api.nocodebackend.com/read/activation_codes?Instance=36905_activation_codes&code=${encodeURIComponent(code.toUpperCase().trim())}`,
        {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!findResponse.ok) {
        throw new Error(`NoCodeBackend error: ${findResponse.status}`);
      }

      const apiResponse = await findResponse.json();
      const records = apiResponse?.data || [];
      const codeRecord = records.find(r => r.code === code.toUpperCase().trim());

      // Validate code exists
      if (!codeRecord) {
        return jsonResponse({
          valid: false,
          error: 'Invalid activation code'
        }, 400);
      }

      // Check if already used (device_id not null means it's been used)
      if (codeRecord.device_id !== null) {
        return jsonResponse({
          valid: false,
          error: 'Code already used on another device'
        }, 400);
      }

      // Check expiration (skip if expires_at is null)
      if (codeRecord.expires_at) {
        const now = new Date();
        const expiresAt = new Date(codeRecord.expires_at);
        if (now > expiresAt) {
          return jsonResponse({
            valid: false,
            error: 'Code has expired'
          }, 400);
        }
      }

      // Mark code as used in NoCodeBackend (only update device_id due to field validation)
      const recordId = codeRecord.id;
      const updateResponse = await fetch(
        `https://api.nocodebackend.com/update/activation_codes/${recordId}?Instance=36905_activation_codes`,
        {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            device_id: deviceId
          })
        }
      );

      if (!updateResponse.ok) {
        throw new Error(`Failed to update code: ${updateResponse.status}`);
      }

      // Return success
      return jsonResponse({
        valid: true,
        tier: codeRecord.tier,
        subscriptionId: codeRecord.subscription_id,
        customerId: codeRecord.customer_id,
        expiresAt: codeRecord.expires_at
      }, 200);

    } catch (error) {
      console.error('Validation error:', error);
      return jsonResponse({
        valid: false,
        error: 'Internal server error'
      }, 500);
    }
  }
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}
