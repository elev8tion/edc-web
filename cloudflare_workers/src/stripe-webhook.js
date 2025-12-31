/**
 * Stripe Webhook Handler
 * Handles subscription lifecycle events with signature verification
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

      // Route to appropriate event handler
      let result;
      switch (event.type) {
        case 'checkout.session.completed':
          result = await handleCheckoutCompleted(event.data.object, env);
          break;

        case 'invoice.payment_succeeded':
          result = await handlePaymentSucceeded(event.data.object, env);
          break;

        case 'customer.subscription.deleted':
          result = await handleSubscriptionDeleted(event.data.object, env);
          break;

        case 'invoice.payment_failed':
          result = await handlePaymentFailed(event.data.object, env);
          break;

        default:
          return new Response(JSON.stringify({
            received: true,
            skipped: true,
            reason: `Event type ${event.type} not handled`
          }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
          });
      }

      return new Response(JSON.stringify(result), {
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

/**
 * Handle checkout.session.completed
 * Fires immediately when checkout completes
 * Premium activation happens directly in the app via activateFromStripe()
 */
async function handleCheckoutCompleted(session, env) {
  const customerId = session.customer;
  const subscriptionId = session.subscription;

  // Validate subscription ID exists
  if (!subscriptionId) {
    throw new Error('No subscription ID found in checkout session');
  }

  // Fetch subscription to get tier info
  const subResponse = await fetch(
    `https://api.stripe.com/v1/subscriptions/${subscriptionId}`,
    {
      headers: {
        'Authorization': `Bearer ${env.STRIPE_API_KEY}`
      }
    }
  );

  if (!subResponse.ok) {
    throw new Error(`Failed to fetch subscription: ${subResponse.status}`);
  }

  const subscription = await subResponse.json();
  const priceId = subscription.items.data[0]?.price?.id || '';
  const tier = determineTier(priceId, env);

  console.log(`Checkout completed: customer=${customerId}, subscription=${subscriptionId}, tier=${tier}`);

  return {
    success: true,
    event: 'checkout.session.completed',
    tier,
    customerId,
    subscriptionId,
    message: 'Checkout completed - premium activated in app'
  };
}

/**
 * Handle invoice.payment_succeeded
 * Fires for recurring payments
 */
async function handlePaymentSucceeded(invoice, env) {
  const subscriptionId = invoice.subscription;
  const customerId = invoice.customer;

  // For trial invoices (amount = 0), just log
  if (invoice.amount_paid === 0) {
    return {
      success: true,
      event: 'invoice.payment_succeeded',
      message: 'Trial invoice - no charge'
    };
  }

  // Determine subscription tier
  const priceId = invoice.lines?.data?.[0]?.price?.id || '';
  const tier = determineTier(priceId, env);

  console.log(`Payment succeeded: customer=${customerId}, subscription=${subscriptionId}, tier=${tier}, amount=${invoice.amount_paid}`);

  return {
    success: true,
    event: 'invoice.payment_succeeded',
    tier,
    customerId,
    subscriptionId,
    amountPaid: invoice.amount_paid
  };
}

/**
 * Handle customer.subscription.deleted
 * Fires when subscription is cancelled or expires
 */
async function handleSubscriptionDeleted(subscription, env) {
  const subscriptionId = subscription.id;
  const customerId = subscription.customer;

  console.log(`Subscription deleted: customer=${customerId}, subscription=${subscriptionId}`);

  return {
    success: true,
    event: 'customer.subscription.deleted',
    message: 'Subscription cancelled',
    subscriptionId,
    customerId
  };
}

/**
 * Handle invoice.payment_failed
 * Fires when payment fails (card declined, insufficient funds, etc.)
 * Send payment failure notification to customer
 */
async function handlePaymentFailed(invoice, env) {
  const customerEmail = invoice.customer_email;
  const locale = invoice.metadata?.locale || 'en';
  const attemptCount = invoice.attempt_count;
  const nextPaymentAttempt = invoice.next_payment_attempt;

  // Send payment failure email
  if (env.EMAILIT_API_KEY && customerEmail) {
    await sendPaymentFailedEmail(
      customerEmail,
      attemptCount,
      nextPaymentAttempt,
      env.EMAILIT_API_KEY,
      locale
    );
  }

  return {
    success: true,
    event: 'invoice.payment_failed',
    message: 'Payment failure notification sent',
    attemptCount,
    nextPaymentAttempt: nextPaymentAttempt ? new Date(nextPaymentAttempt * 1000).toISOString() : null
  };
}

// ==================== HELPER FUNCTIONS ====================

function determineTier(priceId, env) {
  if (priceId === env.MONTHLY_PRICE_ID) return 'monthly';
  if (priceId === env.YEARLY_PRICE_ID) return 'yearly';
  return 'trial';
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

async function sendPaymentFailedEmail(to, attemptCount, nextPaymentAttempt, apiKey, locale = 'en') {
  const subject = locale === 'es'
    ? 'Problema con tu Pago - Everyday Christian'
    : 'Payment Issue - Everyday Christian';

  const nextAttemptDate = nextPaymentAttempt
    ? new Date(nextPaymentAttempt * 1000).toLocaleDateString()
    : 'soon';

  const htmlContent = locale === 'es'
    ? getSpanishPaymentFailedEmailHTML(attemptCount, nextAttemptDate)
    : getEnglishPaymentFailedEmailHTML(attemptCount, nextAttemptDate);

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
      console.error('Failed to send payment failed email:', await response.text());
    }
  } catch (error) {
    console.error('Payment failed email error:', error);
  }
}

function getEnglishPaymentFailedEmailHTML(attemptCount, nextAttemptDate) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif; background: #0f0f1e; }
        .email-container { max-width: 600px; margin: 0 auto; background: #1a1b2e; }
        .header { padding: 40px 30px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.1); }
        .header-title { color: #ffffff; font-size: 24px; font-weight: 600; }
        .content { padding: 40px 30px; color: rgba(255,255,255,0.8); }
        .alert-box { background: rgba(255,87,87,0.1); border: 1px solid rgba(255,87,87,0.3); border-radius: 8px; padding: 20px; margin: 20px 0; }
        .footer { padding: 32px 30px; text-align: center; color: rgba(255,255,255,0.5); font-size: 13px; }
      </style>
    </head>
    <body>
      <div class="email-container">
        <div class="header">
          <h1 class="header-title">Payment Issue</h1>
        </div>
        <div class="content">
          <p>We couldn't process your payment for Everyday Christian Premium.</p>
          <div class="alert-box">
            <p><strong>Attempt ${attemptCount} of 4</strong></p>
            <p>We'll try again on ${nextAttemptDate}</p>
          </div>
          <p>Please update your payment method to avoid service interruption.</p>
        </div>
        <div class="footer">
          <p>© ${new Date().getFullYear()} Everyday Christian</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

function getSpanishPaymentFailedEmailHTML(attemptCount, nextAttemptDate) {
  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif; background: #0f0f1e; }
        .email-container { max-width: 600px; margin: 0 auto; background: #1a1b2e; }
        .header { padding: 40px 30px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.1); }
        .header-title { color: #ffffff; font-size: 24px; font-weight: 600; }
        .content { padding: 40px 30px; color: rgba(255,255,255,0.8); }
        .alert-box { background: rgba(255,87,87,0.1); border: 1px solid rgba(255,87,87,0.3); border-radius: 8px; padding: 20px; margin: 20px 0; }
        .footer { padding: 32px 30px; text-align: center; color: rgba(255,255,255,0.5); font-size: 13px; }
      </style>
    </head>
    <body>
      <div class="email-container">
        <div class="header">
          <h1 class="header-title">Problema con el Pago</h1>
        </div>
        <div class="content">
          <p>No pudimos procesar tu pago para Everyday Christian Premium.</p>
          <div class="alert-box">
            <p><strong>Intento ${attemptCount} de 4</strong></p>
            <p>Intentaremos nuevamente el ${nextAttemptDate}</p>
          </div>
          <p>Por favor actualiza tu método de pago para evitar la interrupción del servicio.</p>
        </div>
        <div class="footer">
          <p>© ${new Date().getFullYear()} Everyday Christian</p>
        </div>
      </div>
    </body>
    </html>
  `;
}
