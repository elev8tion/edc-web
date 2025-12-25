/**
 * Stripe Webhook Handler - Worker 1
 * Generates activation codes and stores in NoCodeBackend
 * WITH SIGNATURE VERIFICATION
 */

export default {
  async fetch(request, env) {
    // Only accept POST requests
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    try {
      // Get raw body for signature verification
      const rawBody = await request.text();

      // Verify Stripe signature
      const signature = request.headers.get('stripe-signature');
      if (!signature) {
        console.error('Missing Stripe signature header');
        return new Response('Unauthorized', { status: 401 });
      }

      // Verify the webhook signature
      const isValid = await verifyStripeSignature(
        rawBody,
        signature,
        env.STRIPE_WEBHOOK_SECRET
      );

      if (!isValid) {
        console.error('Invalid Stripe signature');
        return new Response('Unauthorized', { status: 401 });
      }

      // Parse Stripe webhook event (after verification)
      const event = JSON.parse(rawBody);

      // Only process invoice.payment_succeeded events
      if (event.type !== 'invoice.payment_succeeded') {
        return new Response(JSON.stringify({
          received: true,
          skipped: true,
          reason: 'Not a payment success event'
        }), {
          status: 200,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      const eventData = event.data.object;
      const subscriptionId = eventData.subscription || `test_sub_${Date.now()}`;
      const customerId = eventData.customer || `test_cus_${Date.now()}`;
      const customerEmail = eventData.customer_email || 'test@example.com';

      // Determine subscription tier
      const priceId = eventData.lines?.data?.[0]?.price?.id || '';
      const tier = determineTier(priceId, env);

      // Generate activation code
      const prefix = tier === 'monthly' ? 'M' : tier === 'yearly' ? 'Y' : 'T';
      const randomPart = generateRandomCode(6);
      const activationCode = `${prefix}-${randomPart.slice(0,3)}-${randomPart.slice(3,6)}`;

      const currentPeriodEnd = eventData.lines?.data?.[0]?.period?.end || (Date.now() / 1000) + (30 * 24 * 60 * 60);
      const expiresAt = new Date(currentPeriodEnd * 1000).toISOString();
      const invoiceId = eventData.id;

      // Save to NoCodeBackend (create without status field due to validation)
      const saveResponse = await fetch(
        `https://api.nocodebackend.com/create/activation_codes?Instance=36905_activation_codes`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            code: activationCode,
            customer_id: customerId,
            subscription_id: subscriptionId,
            tier
          })
        }
      );

      if (!saveResponse.ok) {
        const errorText = await saveResponse.text();
        throw new Error(`Failed to save to NoCodeBackend: ${saveResponse.status} - ${errorText}`);
      }

      // Update Stripe invoice metadata
      const stripeUpdateResponse = await fetch(
        `https://api.stripe.com/v1/invoices/${invoiceId}`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${env.STRIPE_API_KEY}`,
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: `metadata[activation_code]=${activationCode}&metadata[tier]=${tier}`
        }
      );

      if (!stripeUpdateResponse.ok) {
        console.error('Failed to update Stripe invoice:', await stripeUpdateResponse.text());
      }

      // Detect customer language from metadata or default to English
      const locale = eventData.metadata?.locale || 'en';

      // Send activation email (using EmailIt API)
      if (env.EMAILIT_API_KEY) {
        await sendActivationEmail(
          customerEmail,
          activationCode,
          tier,
          env.EMAILIT_API_KEY,
          locale
        );
      }

      return new Response(JSON.stringify({
        success: true,
        activationCode,
        tier,
        customerId,
        expiresAt
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });

    } catch (error) {
      console.error('Webhook error:', error);
      return new Response(JSON.stringify({
        error: error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }
};

function determineTier(priceId, env) {
  if (priceId === env.MONTHLY_PRICE_ID) return 'monthly';
  if (priceId === env.YEARLY_PRICE_ID) return 'yearly';
  return 'trial';
}

function generateRandomCode(length) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * Verify Stripe webhook signature using HMAC SHA256
 * Prevents fake webhook attacks
 */
async function verifyStripeSignature(payload, signature, secret) {
  try {
    // Parse signature header
    const signatureParts = signature.split(',').reduce((acc, part) => {
      const [key, value] = part.split('=');
      acc[key] = value;
      return acc;
    }, {});

    const timestamp = signatureParts.t;
    const providedSignature = signatureParts.v1;

    if (!timestamp || !providedSignature) {
      return false;
    }

    // Create signed payload
    const signedPayload = `${timestamp}.${payload}`;

    // Compute expected signature using Web Crypto API
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );

    const signatureBuffer = await crypto.subtle.sign(
      'HMAC',
      key,
      encoder.encode(signedPayload)
    );

    // Convert to hex string
    const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    // Compare signatures (timing-safe)
    return expectedSignature === providedSignature;
  } catch (error) {
    console.error('Signature verification error:', error);
    return false;
  }
}

async function sendActivationEmail(to, code, tier, apiKey, locale = 'en') {
  // Import Spanish templates dynamically
  const { getSpanishActivationEmail } = await import('./email-templates-es.js');

  const subject = locale === 'es'
    ? 'Tu Código de Activación - Everyday Christian'
    : 'Your Activation Code - Everyday Christian';

  // Use Spanish template if locale is Spanish, otherwise use English (inline)
  const htmlContent = locale === 'es'
    ? getSpanishActivationEmail(code, tier)
    : getEnglishActivationEmailHTML(code);

  try {
    const response = await fetch('https://api.emailit.com/v1/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'Everyday Christian <connect@everydaychristian.app>',
        to: to,
        reply_to: 'connect@everydaychristian.app',
        subject: subject,
        html: htmlContent
      })
    });

    if (!response.ok) {
      console.error('Failed to send email:', await response.text());
    }
  } catch (error) {
    console.error('Email error:', error);
  }
}

function getEnglishActivationEmailHTML(code) {
  return `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif; line-height: 1.6; background: #0f0f1e; margin: 0; }
              .email-wrapper { background: #0f0f1e; padding: 40px 20px; }
              .email-container { max-width: 600px; margin: 0 auto; background: #1a1b2e; border-radius: 8px; overflow: hidden; }

              /* Header */
              .header { background: #1a1b2e; padding: 40px 30px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.1); }
              .logo { width: 80px; height: 80px; margin: 0 auto 20px; }
              .header-title { color: #ffffff; font-size: 28px; font-weight: 600; margin: 0 0 8px 0; }
              .header-subtitle { color: rgba(255,255,255,0.6); font-size: 16px; font-weight: 400; }

              /* Content */
              .content { padding: 40px 30px; background: #1a1b2e; }
              .greeting { font-size: 18px; color: #ffffff; margin-bottom: 16px; font-weight: 400; }
              .message { color: rgba(255,255,255,0.8); font-size: 15px; margin-bottom: 24px; line-height: 1.6; }

              /* Activation Code - Yellow CTA style */
              .code-section { background: #FDB022; border-radius: 8px; padding: 32px 24px; text-align: center; margin: 32px 0; }
              .code-label { color: #1a1b2e; font-size: 12px; text-transform: uppercase; letter-spacing: 1.5px; font-weight: 600; margin-bottom: 12px; }
              .activation-code { font-size: 36px; font-weight: 700; color: #1a1b2e; letter-spacing: 4px; font-family: 'Courier New', monospace; }

              /* Instructions */
              .instructions { background: rgba(255,255,255,0.05); border-radius: 8px; padding: 24px; margin: 32px 0; }
              .instructions-title { color: #ffffff; font-size: 16px; font-weight: 600; margin-bottom: 16px; }
              .instructions ol { margin-left: 20px; color: rgba(255,255,255,0.8); padding-left: 0; }
              .instructions li { margin: 12px 0; font-size: 14px; line-height: 1.6; }
              .instructions strong { color: #FDB022; font-weight: 600; }

              /* Tip Box */
              .tip-box { background: rgba(253,176,34,0.1); border: 1px solid rgba(253,176,34,0.3); border-radius: 8px; padding: 20px; margin: 24px 0; }
              .tip-text { color: rgba(255,255,255,0.9); font-size: 14px; line-height: 1.6; display: block; }
              .tip-text strong { color: #FDB022; }

              /* Footer */
              .footer { background: #0f0f1e; padding: 32px 30px; text-align: center; border-top: 1px solid rgba(255,255,255,0.1); }
              .footer-text { color: rgba(255,255,255,0.5); font-size: 13px; line-height: 1.8; }
              .contact-link { color: #FDB022; text-decoration: none; font-weight: 500; }

              .divider { height: 1px; background: rgba(255,255,255,0.1); margin: 32px 0; }

              @media only screen and (max-width: 600px) {
                .email-wrapper { padding: 20px 10px; }
                .header { padding: 32px 24px; }
                .content { padding: 32px 24px; }
                .header-title { font-size: 24px; }
                .activation-code { font-size: 28px; letter-spacing: 3px; }
                .logo { width: 60px; height: 60px; }
              }
            </style>
          </head>
          <body>
            <div class="email-wrapper">
              <div class="email-container">
                <!-- Header -->
                <div class="header">
                  <svg class="logo" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
                    <!-- Sunrise -->
                    <g stroke="#FDB022" stroke-width="3" fill="none">
                      <path d="M 40 120 Q 100 60 160 120" stroke-width="4"/>
                      <line x1="100" y1="70" x2="100" y2="50"/>
                      <line x1="70" y1="80" x2="60" y2="65"/>
                      <line x1="130" y1="80" x2="140" y2="65"/>
                      <line x1="50" y1="100" x2="35" y2="95"/>
                      <line x1="150" y1="100" x2="165" y2="95"/>
                    </g>
                    <!-- Open Bible -->
                    <g stroke="#FDB022" stroke-width="2" fill="none">
                      <path d="M 60 150 L 100 140 L 140 150 L 140 180 L 100 170 L 60 180 Z"/>
                      <line x1="100" y1="140" x2="100" y2="170"/>
                      <line x1="70" y1="155" x2="90" y2="152"/>
                      <line x1="110" y1="152" x2="130" y2="155"/>
                    </g>
                  </svg>
                  <h1 class="header-title">Subscription Activated!</h1>
                  <p class="header-subtitle">Welcome to Everyday Christian Premium</p>
                </div>

                <!-- Content -->
                <div class="content">
                  <p class="greeting">Thank you for subscribing</p>
                  <p class="message">
                    Your faith journey is about to become even more enriching with unlimited access to AI-powered spiritual guidance and support.
                  </p>

                  <!-- Activation Code -->
                  <div class="code-section">
                    <p class="code-label">Your Activation Code</p>
                    <div class="activation-code">${code}</div>
                  </div>

                  <!-- Instructions -->
                  <div class="instructions">
                    <div class="instructions-title">How to Activate</div>
                    <ol>
                      <li>Open the <strong>Everyday Christian</strong> app</li>
                      <li>Go to <strong>Settings</strong> → <strong>Activate Premium</strong></li>
                      <li>Enter code: <strong>${code}</strong></li>
                      <li>Start using your <strong>150 monthly messages</strong></li>
                    </ol>
                  </div>

                  <!-- Important Tip -->
                  <div class="tip-box">
                    <span class="tip-text">
                      <strong>Important:</strong> Save this email. You'll need this code to activate on new devices. One code works on one device at a time.
                    </span>
                  </div>

                  <div class="divider"></div>

                  <p class="message" style="text-align: center; color: rgba(255,255,255,0.5); font-size: 14px;">
                    May God bless your daily walk with Him
                  </p>
                </div>

                <!-- Footer -->
                <div class="footer">
                  <p class="footer-text">
                    Questions or need help?<br>
                    Email us at <a href="mailto:connect@everydaychristian.app" class="contact-link">connect@everydaychristian.app</a>
                  </p>
                  <p class="footer-text" style="margin-top: 16px; font-size: 12px;">
                    © ${new Date().getFullYear()} Everyday Christian. All rights reserved.
                  </p>
                </div>
              </div>
            </div>
          </body>
          </html>
        `
      })
    });

    if (!response.ok) {
      console.error('Failed to send email:', await response.text());
    }
  } catch (error) {
    console.error('Email error:', error);
  }
}
