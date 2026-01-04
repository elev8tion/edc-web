/**
 * Promo Code Validation Worker
 * Securely validates and redeems promo codes via NocodeBackend API
 */

const NOCODEBACKEND_BASE_URL = 'https://openapi.nocodebackend.com';
const NOCODEBACKEND_INSTANCE = '36905_activation_codes';

export default {
  async fetch(request, env) {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Only allow POST
    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    try {
      const { code, userEmail, action = 'validate' } = await request.json();

      if (!code) {
        return new Response(JSON.stringify({ error: 'Promo code required' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const normalizedCode = code.toUpperCase().trim();
      const apiKey = env.NOCODEBACKEND_API_KEY;

      if (!apiKey) {
        console.error('NOCODEBACKEND_API_KEY not configured');
        return new Response(JSON.stringify({ error: 'Server configuration error' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Validate promo code
      const validateUrl = `${NOCODEBACKEND_BASE_URL}/read/promo_codes?Instance=${NOCODEBACKEND_INSTANCE}&code=${normalizedCode}`;
      const validateResponse = await fetch(validateUrl, {
        headers: { 'Authorization': `Bearer ${apiKey}` },
      });

      if (validateResponse.status !== 200) {
        return new Response(JSON.stringify({ valid: false, error: 'API error' }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const validateData = await validateResponse.json();

      if (!validateData.data || validateData.data.length === 0) {
        return new Response(JSON.stringify({ valid: false, error: 'Code not found' }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const promoCode = validateData.data[0];

      // Check if already used
      if (promoCode.is_used === 1 || promoCode.is_used === true) {
        return new Response(JSON.stringify({ valid: false, error: 'Code already used' }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // If action is just validate, return the promo data
      if (action === 'validate') {
        return new Response(JSON.stringify({
          valid: true,
          data: {
            id: promoCode.id,
            code: promoCode.code,
            type: promoCode.type,
            duration_days: promoCode.duration_days,
          }
        }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // If action is redeem, mark as used
      if (action === 'redeem') {
        const now = new Date();
        const usedAt = now.toISOString().slice(0, 19).replace('T', ' ');

        const updateUrl = `${NOCODEBACKEND_BASE_URL}/update/promo_codes/${promoCode.id}?Instance=${NOCODEBACKEND_INSTANCE}`;
        const updateResponse = await fetch(updateUrl, {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            is_used: 1,
            used_by_email: userEmail || 'unknown@user.com',
            used_at: usedAt,
          }),
        });

        if (updateResponse.status !== 200) {
          console.error('Failed to mark code as used');
          return new Response(JSON.stringify({ valid: false, error: 'Failed to redeem' }), {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        return new Response(JSON.stringify({
          valid: true,
          redeemed: true,
          data: {
            id: promoCode.id,
            code: promoCode.code,
            type: promoCode.type,
            duration_days: promoCode.duration_days,
          }
        }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      return new Response(JSON.stringify({ error: 'Invalid action' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });

    } catch (error) {
      console.error('Promo code validation error:', error);
      return new Response(JSON.stringify({ error: 'Internal server error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};
