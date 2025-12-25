/**
 * Stripe Customer Portal Generator - Cloudflare Worker
 * Creates billing portal sessions for subscription management
 * Allows customers to cancel, update payment methods, view invoices
 */

export default {
  async fetch(request, env) {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Only accept GET requests
    if (request.method !== 'GET') {
      return new Response('Method not allowed', { status: 405 });
    }

    try {
      // Parse query parameters
      const url = new URL(request.url);
      const customerId = url.searchParams.get('customer_id');
      const locale = url.searchParams.get('locale') || 'en';

      if (!customerId) {
        return new Response(JSON.stringify({
          error: 'Missing customer_id parameter'
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders }
        });
      }

      // Validate customer_id format (should start with cus_)
      if (!customerId.startsWith('cus_')) {
        return new Response(JSON.stringify({
          error: 'Invalid customer_id format. Must start with cus_'
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders }
        });
      }

      // Create Stripe Billing Portal Session
      const formData = new URLSearchParams({
        'customer': customerId,
        'return_url': `${env.PWA_URL}?portal_return=true`,
        'locale': locale, // 'en' or 'es' for Spanish
      });

      const response = await fetch('https://api.stripe.com/v1/billing_portal/sessions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${env.STRIPE_API_KEY}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: formData.toString()
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Stripe API error: ${response.status} - ${errorText}`);
      }

      const session = await response.json();

      // Redirect to billing portal
      return Response.redirect(session.url, 303);

    } catch (error) {
      console.error('Customer portal error:', error);
      return new Response(JSON.stringify({
        error: error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      });
    }
  }
};
