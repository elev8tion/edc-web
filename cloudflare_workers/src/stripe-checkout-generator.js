/**
 * Stripe Branded Checkout Session Generator - Cloudflare Worker
 * Generates checkout sessions with email-matching branding on demand
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
      const plan = url.searchParams.get('plan'); // 'monthly' or 'yearly'
      const locale = url.searchParams.get('locale') || 'en'; // 'en' or 'es'

      if (!plan || !['monthly', 'yearly'].includes(plan)) {
        return new Response(JSON.stringify({
          error: 'Invalid plan. Must be monthly or yearly'
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...corsHeaders }
        });
      }

      const priceId = plan === 'monthly'
        ? env.MONTHLY_PRICE_ID
        : env.YEARLY_PRICE_ID;

      // Localized text
      const isSpanish = locale === 'es';
      const submitText = isSpanish
        ? 'Comienza Tu Prueba Gratuita de 3 Días'
        : 'Start Your 3-Day Free Trial';
      const afterSubmitText = isSpanish
        ? '¡Bienvenido a Everyday Christian Premium! Revisa tu correo para tu código de activación.'
        : 'Welcome to Everyday Christian Premium! Check your email for your activation code.';

      // Create Stripe Checkout Session with branding
      const formData = new URLSearchParams({
        'mode': 'subscription',
        'line_items[0][price]': priceId,
        'line_items[0][quantity]': '1',
        'subscription_data[trial_period_days]': '3',
        'success_url': `${env.PWA_URL}?activated=true&session_id={CHECKOUT_SESSION_ID}`,
        'cancel_url': `${env.LANDING_URL}?cancelled=true`,

        // Branding settings matching email template
        'branding_settings[logo][type]': 'file',
        'branding_settings[logo][file]': env.LOGO_FILE_ID,
        'branding_settings[display_name]': 'Everyday Christian',
        'branding_settings[background_color]': '#2d1b69',
        'branding_settings[button_color]': '#FDB022',
        'branding_settings[border_style]': 'rounded',

        // Stripe UI locale (native Stripe translation)
        'locale': locale,

        // Custom text (localized)
        'custom_text[submit][message]': submitText,
        'custom_text[after_submit][message]': afterSubmitText,

        // Tax and compliance settings
        'automatic_tax[enabled]': 'true',
        'tax_id_collection[enabled]': 'true',
        'phone_number_collection[enabled]': 'true',
        'consent_collection[terms_of_service]': 'required',
        'allow_promotion_codes': 'true',
        'billing_address_collection': 'required',

        // Metadata (pass locale to webhook for email language)
        'metadata[plan]': plan,
        'metadata[source]': 'landing_page',
        'metadata[locale]': locale
      });

      const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
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

      // Redirect to checkout
      return Response.redirect(session.url, 303);

    } catch (error) {
      console.error('Checkout generation error:', error);
      return new Response(JSON.stringify({
        error: error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      });
    }
  }
};
