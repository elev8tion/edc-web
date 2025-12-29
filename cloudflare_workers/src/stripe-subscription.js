// stripe-subscription.js
// Stripe Subscription Management Worker for EDC
// Handles SetupIntent creation, subscription management, and trial ending
// Deploy: wrangler deploy -c wrangler-stripe.toml

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json',
};

// Price IDs from Stripe Dashboard
const YEARLY_PRICE_ID = 'price_1Shcv9IDgcZhXc4UUAD2Qfz3';  // $49.99/year
const MONTHLY_PRICE_ID = 'price_1ShctRIDgcZhXc4UfDnbNf1s'; // $6.99/month

export default {
  async fetch(request, env) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);

    try {
      switch (url.pathname) {
        case '/create-setup-intent':
          return await createSetupIntent(request, env);
        case '/create-subscription':
          return await createSubscription(request, env);
        case '/end-trial':
          return await endTrial(request, env);
        case '/cancel':
          return await cancelSubscription(request, env);
        case '/get-subscription':
          return await getSubscription(request, env);
        case '/health':
          return new Response(JSON.stringify({ status: 'ok' }), { headers: CORS_HEADERS });
        default:
          return new Response(JSON.stringify({ error: 'Not found' }), {
            status: 404,
            headers: CORS_HEADERS
          });
      }
    } catch (e) {
      console.error('Worker error:', e);
      return new Response(JSON.stringify({ error: e.message }), {
        status: 500,
        headers: CORS_HEADERS,
      });
    }
  },
};

// ============================================================================
// STEP 1: Create SetupIntent to collect card details
// ============================================================================
// This is similar to createPaymentIntent but for saving cards for future use
// Includes device tracking for trial abuse prevention
async function createSetupIntent(request, env) {
  const { customerId, email, userId, deviceId } = await request.json();

  let customer = customerId;

  // Create customer if needed (with device tracking in metadata)
  if (!customer) {
    const custResponse = await fetch('https://api.stripe.com/v1/customers', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        email: email || '',
        'metadata[user_id]': userId || '',
        'metadata[device_id]': deviceId || '',
        'metadata[created_at]': new Date().toISOString(),
        'metadata[source]': 'edc_pwa',
      }),
    });

    if (!custResponse.ok) {
      const error = await custResponse.json();
      throw new Error(`Failed to create customer: ${error.error?.message || 'Unknown error'}`);
    }

    const custData = await custResponse.json();
    customer = custData.id;
    console.log(`Created new Stripe customer: ${customer}`);
  } else {
    // Update existing customer with device ID if not set
    await fetch(`https://api.stripe.com/v1/customers/${customer}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        'metadata[device_id]': deviceId || '',
        'metadata[last_seen]': new Date().toISOString(),
      }),
    });
  }

  // Create SetupIntent (similar pattern to PaymentIntent)
  const response = await fetch('https://api.stripe.com/v1/setup_intents', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      customer: customer,
      'payment_method_types[]': 'card',
      usage: 'off_session', // Allow charging when customer not present
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Failed to create SetupIntent: ${error.error?.message || 'Unknown error'}`);
  }

  const setupIntent = await response.json();
  console.log(`Created SetupIntent: ${setupIntent.id} for customer: ${customer}`);

  return new Response(JSON.stringify({
    clientSecret: setupIntent.client_secret,
    customerId: customer,
  }), { headers: CORS_HEADERS });
}

// ============================================================================
// STEP 2: Create Subscription with optional trial
// ============================================================================
// Called after card is saved via SetupIntent
// Includes device tracking in subscription metadata
async function createSubscription(request, env) {
  const { customerId, isYearly, trialDays, deviceId } = await request.json();

  // Get customer's payment methods to find the default
  const pmResponse = await fetch(
    `https://api.stripe.com/v1/payment_methods?customer=${customerId}&type=card`,
    {
      headers: { 'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}` },
    }
  );

  const pmData = await pmResponse.json();
  const paymentMethodId = pmData.data?.[0]?.id;

  if (!paymentMethodId) {
    throw new Error('No payment method found for customer');
  }

  // Set as default payment method
  await fetch(`https://api.stripe.com/v1/customers/${customerId}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      'invoice_settings[default_payment_method]': paymentMethodId,
    }),
  });

  const priceId = isYearly ? YEARLY_PRICE_ID : MONTHLY_PRICE_ID;

  // Build subscription params
  const params = new URLSearchParams({
    customer: customerId,
    'items[0][price]': priceId,
    default_payment_method: paymentMethodId,
    // Track device and trial info in metadata
    'metadata[device_id]': deviceId || '',
    'metadata[is_trial]': trialDays > 0 ? 'true' : 'false',
    'metadata[plan_type]': isYearly ? 'yearly' : 'monthly',
    'metadata[created_at]': new Date().toISOString(),
    'metadata[source]': 'edc_pwa',
    // Payment behavior for handling failures
    payment_behavior: 'default_incomplete',
    'expand[]': 'latest_invoice.payment_intent',
  });

  // Only add trial if trialDays > 0
  if (trialDays > 0) {
    params.append('trial_period_days', trialDays.toString());
  }

  // Create subscription
  const response = await fetch('https://api.stripe.com/v1/subscriptions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params,
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Failed to create subscription: ${error.error?.message || 'Unknown error'}`);
  }

  const subscription = await response.json();
  console.log(`Created subscription: ${subscription.id} (trial: ${trialDays > 0 ? 'yes' : 'no'})`);

  return new Response(JSON.stringify({
    subscriptionId: subscription.id,
    status: subscription.status,
    trialEnd: subscription.trial_end, // null if no trial
    currentPeriodEnd: subscription.current_period_end,
  }), { headers: CORS_HEADERS });
}

// ============================================================================
// STEP 3: End Trial Early (when 15 messages consumed)
// ============================================================================
async function endTrial(request, env) {
  const { subscriptionId } = await request.json();

  if (!subscriptionId) {
    throw new Error('subscriptionId is required');
  }

  const response = await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      trial_end: 'now', // End trial immediately, triggering first charge
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Failed to end trial: ${error.error?.message || 'Unknown error'}`);
  }

  const subscription = await response.json();
  console.log(`Ended trial for subscription: ${subscriptionId}, new status: ${subscription.status}`);

  return new Response(JSON.stringify({
    status: subscription.status,
    currentPeriodEnd: subscription.current_period_end,
  }), { headers: CORS_HEADERS });
}

// ============================================================================
// STEP 4: Cancel Subscription
// ============================================================================
async function cancelSubscription(request, env) {
  const { subscriptionId, cancelAtPeriodEnd } = await request.json();

  if (!subscriptionId) {
    throw new Error('subscriptionId is required');
  }

  let response;

  if (cancelAtPeriodEnd) {
    // Cancel at end of billing period (graceful)
    response = await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        cancel_at_period_end: 'true',
      }),
    });
  } else {
    // Cancel immediately
    response = await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}` },
    });
  }

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Failed to cancel subscription: ${error.error?.message || 'Unknown error'}`);
  }

  console.log(`Cancelled subscription: ${subscriptionId}`);

  return new Response(JSON.stringify({ cancelled: true }), { headers: CORS_HEADERS });
}

// ============================================================================
// STEP 5: Get Subscription Status
// ============================================================================
async function getSubscription(request, env) {
  const { subscriptionId, customerId } = await request.json();

  let subscription;

  if (subscriptionId) {
    const response = await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
      headers: { 'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}` },
    });

    if (!response.ok) {
      return new Response(JSON.stringify({ found: false }), { headers: CORS_HEADERS });
    }

    subscription = await response.json();
  } else if (customerId) {
    // Get customer's active subscriptions
    const response = await fetch(
      `https://api.stripe.com/v1/subscriptions?customer=${customerId}&status=active&limit=1`,
      {
        headers: { 'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}` },
      }
    );

    const data = await response.json();
    subscription = data.data?.[0];

    if (!subscription) {
      // Check for trialing subscriptions too
      const trialResponse = await fetch(
        `https://api.stripe.com/v1/subscriptions?customer=${customerId}&status=trialing&limit=1`,
        {
          headers: { 'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}` },
        }
      );
      const trialData = await trialResponse.json();
      subscription = trialData.data?.[0];
    }
  }

  if (!subscription) {
    return new Response(JSON.stringify({ found: false }), { headers: CORS_HEADERS });
  }

  return new Response(JSON.stringify({
    found: true,
    subscriptionId: subscription.id,
    status: subscription.status,
    trialEnd: subscription.trial_end,
    currentPeriodEnd: subscription.current_period_end,
    cancelAtPeriodEnd: subscription.cancel_at_period_end,
  }), { headers: CORS_HEADERS });
}
