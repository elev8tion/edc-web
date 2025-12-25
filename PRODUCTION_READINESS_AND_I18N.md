# Production Readiness & Spanish Translation Guide

**Project**: Everyday Christian Subscription System
**Date**: 2025-12-25
**Status**: Pre-Production Testing Phase

---

## 📊 Current Status Overview

### ✅ Completed Components
- Stripe Checkout with branded UI
- 3-day trial period (Monthly $5.99, Yearly $35.99)
- Tax and compliance settings
- Webhook handler for payment success
- Activation code generation
- Email delivery system
- Terms of Service

### 🚨 Critical Issues
- No webhook signature verification (security risk)
- Using test API keys
- Missing Spanish translations
- No customer portal
- Incomplete webhook coverage

---

## 🔐 PRIORITY 1: Security Fixes (REQUIRED BEFORE LAUNCH)

### 1. Webhook Signature Verification

**Current Risk**: Anyone can send fake webhooks to your endpoint

**Implementation Needed**:
```javascript
// Add to stripe-webhook.js
async function verifyStripeSignature(request, body, env) {
  const signature = request.headers.get('stripe-signature');

  if (!signature) {
    throw new Error('No signature header');
  }

  // Stripe webhook signature verification
  const stripe = require('stripe')(env.STRIPE_API_KEY);

  try {
    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      env.STRIPE_WEBHOOK_SECRET
    );
    return event;
  } catch (err) {
    throw new Error(`Webhook signature verification failed: ${err.message}`);
  }
}
```

**Environment Variable Needed**:
- `STRIPE_WEBHOOK_SECRET` - Get from Stripe Dashboard → Webhooks

**Files to Update**:
- `/cloudflare_workers/src/stripe-webhook.js`
- `/cloudflare_workers/wrangler.toml` (add STRIPE_WEBHOOK_SECRET)

---

## 🌐 Spanish Translation Implementation

### Overview
Supporting Spanish requires translations in:
1. Stripe Checkout UI
2. Email templates
3. Error messages
4. Landing page

### 1. Stripe Checkout Translations

**Stripe supports locale-based checkout**. Update `stripe-checkout-generator.js`:

```javascript
// Detect user language from query parameter or headers
const url = new URL(request.url);
const locale = url.searchParams.get('locale') || 'en'; // 'en' or 'es'

const formData = new URLSearchParams({
  // ... existing fields ...

  // Set locale for Stripe UI
  'locale': locale === 'es' ? 'es' : 'en',

  // Custom text in Spanish
  'custom_text[submit][message]': locale === 'es'
    ? 'Comienza Tu Prueba Gratuita de 3 Días'
    : 'Start Your 3-Day Free Trial',

  'custom_text[after_submit][message]': locale === 'es'
    ? '¡Bienvenido a Everyday Christian Premium! Revisa tu correo para tu código de activación.'
    : 'Welcome to Everyday Christian Premium! Check your email for your activation code.',
});
```

**Supported Stripe Locales**:
- `en` - English (default)
- `es` - Spanish
- `es-419` - Spanish (Latin America)

**Landing Page Updates**:
```javascript
// Update LandingPage.tsx button handlers
const monthlyLink = import.meta.env.VITE_STRIPE_MONTHLY_LINK;
const userLocale = navigator.language.startsWith('es') ? 'es' : 'en';

window.location.href = `${monthlyLink}&locale=${userLocale}`;
```

### 2. Email Templates (Spanish)

**Create separate email template for Spanish**:

**File**: `/cloudflare_workers/src/email-templates/activation-es.js`

```javascript
export function getSpanishActivationEmail(code, tier) {
  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="utf-8">
      <style>/* Same styles as English version */</style>
    </head>
    <body>
      <div class="email-wrapper">
        <div class="email-container">
          <!-- Header -->
          <div class="header">
            <!-- Same SVG logo -->
            <h1 class="header-title">¡Suscripción Activada!</h1>
            <p class="header-subtitle">Bienvenido a Everyday Christian Premium</p>
          </div>

          <!-- Content -->
          <div class="content">
            <p class="greeting">Gracias por suscribirte</p>
            <p class="message">
              Tu viaje de fe está a punto de ser aún más enriquecedor con acceso ilimitado
              a orientación espiritual y apoyo impulsado por IA.
            </p>

            <!-- Activation Code -->
            <div class="code-section">
              <p class="code-label">Tu Código de Activación</p>
              <div class="activation-code">${code}</div>
            </div>

            <!-- Instructions -->
            <div class="instructions">
              <div class="instructions-title">Cómo Activar</div>
              <ol>
                <li>Abre la aplicación <strong>Everyday Christian</strong></li>
                <li>Ve a <strong>Configuración</strong> → <strong>Activar Premium</strong></li>
                <li>Ingresa el código: <strong>${code}</strong></li>
                <li>Comienza a usar tus <strong>150 mensajes mensuales</strong></li>
              </ol>
            </div>

            <!-- Important Tip -->
            <div class="tip-box">
              <span class="tip-text">
                <strong>Importante:</strong> Guarda este correo. Necesitarás este código
                para activar en nuevos dispositivos. Un código funciona en un dispositivo a la vez.
              </span>
            </div>

            <div class="divider"></div>

            <p class="message" style="text-align: center; color: rgba(255,255,255,0.5); font-size: 14px;">
              Que Dios bendiga tu caminar diario con Él
            </p>
          </div>

          <!-- Footer -->
          <div class="footer">
            <p class="footer-text">
              ¿Preguntas o necesitas ayuda?<br>
              Envíanos un correo a <a href="mailto:connect@everydaychristian.app" class="contact-link">connect@everydaychristian.app</a>
            </p>
            <p class="footer-text" style="margin-top: 16px; font-size: 12px;">
              © ${new Date().getFullYear()} Everyday Christian. Todos los derechos reservados.
            </p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;
}
```

**Update `stripe-webhook.js` to detect language**:

```javascript
async function sendActivationEmail(to, code, tier, apiKey, locale = 'en') {
  const subject = locale === 'es'
    ? 'Tu Código de Activación - Everyday Christian'
    : 'Your Activation Code - Everyday Christian';

  const htmlContent = locale === 'es'
    ? getSpanishActivationEmail(code, tier)
    : getEnglishActivationEmail(code, tier);

  // Send via EmailIt
  await fetch('https://api.emailit.com/v1/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: 'Everyday Christian <connect@everydaychristian.app>',
      to: to,
      subject: subject,
      html: htmlContent
    })
  });
}
```

**Language Detection Strategy**:
1. Check Stripe checkout session metadata (passed from landing page)
2. Store customer language preference in database
3. Default to English if not specified

### 3. Landing Page Spanish Support

**You already have**: `/everyday-christian-landing/public/legal/terms-of-service.es.md`

**Add language switcher**:
```javascript
// Add to landing page
const [language, setLanguage] = useState(
  localStorage.getItem('language') ||
  (navigator.language.startsWith('es') ? 'es' : 'en')
);

// Update button onClick
const checkoutUrl = language === 'es'
  ? `${monthlyLink}&locale=es`
  : monthlyLink;
```

### 4. Database Schema Update

**Add language field to activation codes**:
```javascript
// NoCodeBackend activation_codes table
{
  code: "M-ABC-123",
  customer_id: "cus_xxx",
  subscription_id: "sub_xxx",
  tier: "monthly",
  locale: "es",  // NEW FIELD
  created_at: "2025-12-25T00:00:00Z"
}
```

---

## 📧 Additional Webhook Events Needed

### 1. Subscription Canceled
```javascript
// Handle: customer.subscription.deleted
if (event.type === 'customer.subscription.deleted') {
  const subscription = event.data.object;

  // Deactivate activation code in database
  await deactivateCode(subscription.id);

  // Send cancellation confirmation email
  await sendCancellationEmail(
    subscription.customer,
    subscription.metadata.locale || 'en'
  );
}
```

### 2. Payment Failed
```javascript
// Handle: invoice.payment_failed
if (event.type === 'invoice.payment_failed') {
  const invoice = event.data.object;

  // Send payment failed email with update payment link
  await sendPaymentFailedEmail(
    invoice.customer_email,
    invoice.hosted_invoice_url,
    invoice.metadata.locale || 'en'
  );
}
```

### 3. Trial Ending Reminder
```javascript
// Handle: customer.subscription.trial_will_end
if (event.type === 'customer.subscription.trial_will_end') {
  const subscription = event.data.object;

  // Send reminder 2 days before trial ends
  await sendTrialEndingEmail(
    subscription.customer,
    subscription.trial_end,
    subscription.metadata.locale || 'en'
  );
}
```

### 4. Checkout Session Completed (Immediate Activation)
```javascript
// Handle: checkout.session.completed
if (event.type === 'checkout.session.completed') {
  const session = event.data.object;

  if (session.mode === 'subscription') {
    // Generate activation code immediately for trial users
    // Don't wait for invoice.payment_succeeded
    const code = generateActivationCode();

    await saveActivationCode(code, session);
    await sendActivationEmail(
      session.customer_email,
      code,
      session.metadata.locale || 'en'
    );
  }
}
```

---

## 🏪 Customer Portal Setup

**Why Needed**: Let customers self-serve (cancel, update payment, view invoices)

**Stripe Customer Portal Configuration**:
1. Go to https://dashboard.stripe.com/settings/billing/portal
2. Configure:
   - ✅ Allow cancellation
   - ✅ Allow payment method updates
   - ✅ Show invoice history
   - ✅ Subscription pause (optional)

**Implementation**:

**File**: `/cloudflare_workers/src/customer-portal-redirect.js`
```javascript
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const customerId = url.searchParams.get('customer_id');

    if (!customerId) {
      return new Response('Missing customer_id', { status: 400 });
    }

    // Create portal session
    const formData = new URLSearchParams({
      'customer': customerId,
      'return_url': env.PWA_URL
    });

    const response = await fetch('https://api.stripe.com/v1/billing_portal/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.STRIPE_API_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData.toString()
    });

    const session = await response.json();

    // Redirect to portal
    return Response.redirect(session.url, 303);
  }
};
```

**Add to app settings**:
```dart
// Flutter app - Settings screen
ElevatedButton(
  onPressed: () async {
    final customerId = await getCustomerId(); // From Supabase
    final portalUrl = 'https://customer-portal.connect-2a2.workers.dev?customer_id=$customerId';

    await launchUrl(Uri.parse(portalUrl));
  },
  child: Text('Manage Subscription'),
)
```

---

## 🔄 Production Deployment Checklist

### Phase 1: Security (URGENT)
- [ ] Add webhook signature verification
- [ ] Get production API keys from Stripe
- [ ] Set up production webhook endpoint
- [ ] Test webhook signature verification

### Phase 2: Spanish Support (HIGH PRIORITY)
- [ ] Add locale parameter to checkout generator
- [ ] Create Spanish email template
- [ ] Update landing page with language switcher
- [ ] Add locale field to database
- [ ] Test Spanish checkout flow end-to-end

### Phase 3: Webhook Coverage (HIGH PRIORITY)
- [ ] Add `checkout.session.completed` handler (immediate trial activation)
- [ ] Add `customer.subscription.deleted` handler
- [ ] Add `invoice.payment_failed` handler
- [ ] Add `customer.subscription.trial_will_end` handler
- [ ] Test all webhook events in Stripe Dashboard

### Phase 4: Customer Portal (MEDIUM PRIORITY)
- [ ] Configure Stripe Customer Portal in Dashboard
- [ ] Deploy customer-portal-redirect worker
- [ ] Add "Manage Subscription" button to app
- [ ] Test cancellation flow
- [ ] Test payment method update

### Phase 5: Email Templates (MEDIUM PRIORITY)
- [ ] Trial ending reminder (English)
- [ ] Trial ending reminder (Spanish)
- [ ] Payment failed (English)
- [ ] Payment failed (Spanish)
- [ ] Cancellation confirmation (English)
- [ ] Cancellation confirmation (Spanish)

### Phase 6: Legal & Compliance (BEFORE PRODUCTION)
- [ ] Create refund policy (English)
- [ ] Create refund policy (Spanish)
- [ ] Update Terms of Service with subscription details
- [ ] Add Privacy Policy link to checkout
- [ ] Configure Stripe Tax settings (if required)

### Phase 7: Testing (CRITICAL)
- [ ] Test checkout with Spanish locale
- [ ] Test email delivery (English & Spanish)
- [ ] Test webhook delivery and signature
- [ ] Test trial activation
- [ ] Test subscription cancellation
- [ ] Test payment failure scenarios
- [ ] Test customer portal access

### Phase 8: Monitoring (POST-LAUNCH)
- [ ] Set up Stripe webhook monitoring
- [ ] Monitor failed payment emails
- [ ] Track activation code usage
- [ ] Monitor customer support requests
- [ ] Review Stripe Dashboard daily

---

## 🚀 Quick Start Implementation Guide

### 1. Add Webhook Security (15 minutes)

```bash
# Get webhook secret from Stripe
stripe listen --forward-to https://stripe-webhook.connect-2a2.workers.dev

# Add to wrangler secrets
wrangler secret put STRIPE_WEBHOOK_SECRET --env production

# Update stripe-webhook.js with verification code
```

### 2. Add Spanish Support (30 minutes)

```bash
# 1. Create Spanish email template
touch /Users/kcdacre8tor/edc_web/cloudflare_workers/src/email-templates/activation-es.js

# 2. Update checkout generator
# Add locale parameter support

# 3. Update landing page
# Add language detection
```

### 3. Deploy Customer Portal (20 minutes)

```bash
# Create new worker
touch /Users/kcdacre8tor/edc_web/cloudflare_workers/src/customer-portal-redirect.js
touch /Users/kcdacre8tor/edc_web/cloudflare_workers/wrangler-portal.toml

# Deploy
wrangler deploy --config wrangler-portal.toml
```

---

## 📊 Environment Variables Reference

### Development (.env.local)
```env
VITE_STRIPE_MONTHLY_LINK=https://stripe-checkout-generator.connect-2a2.workers.dev?plan=monthly
VITE_STRIPE_YEARLY_LINK=https://stripe-checkout-generator.connect-2a2.workers.dev?plan=yearly
VITE_PWA_URL=https://remarkable-capybara-1ec7f2.netlify.app
```

### Cloudflare Workers (wrangler.toml)
```toml
[vars]
PWA_URL = "https://remarkable-capybara-1ec7f2.netlify.app"
LANDING_URL = "https://landing-edc.netlify.app"
MONTHLY_PRICE_ID = "price_1SiCmTIDgcZhXc4U1I7oaBN3"  # Test
YEARLY_PRICE_ID = "price_1SiCnMIDgcZhXc4UkpKVvoXu"   # Test
LOGO_FILE_ID = "file_1SiEtJIDgcZhXc4UNRS3GPFG"

# Secrets (via: wrangler secret put <NAME>)
# STRIPE_API_KEY = "sk_test_..." (currently)
# STRIPE_WEBHOOK_SECRET = "whsec_..."
# NOCODEBACKEND_API_KEY = "..."
# EMAILIT_API_KEY = "..."
```

### Production (Switch Before Launch)
```toml
MONTHLY_PRICE_ID = "price_LIVE_xxx"  # Production price ID
YEARLY_PRICE_ID = "price_LIVE_xxx"   # Production price ID

# Secrets
# STRIPE_API_KEY = "sk_live_..."  # Production key
```

---

## 📚 Documentation Links

- **Stripe Webhooks**: https://stripe.com/docs/webhooks
- **Stripe Checkout Localization**: https://stripe.com/docs/payments/checkout/customization#localize-checkout
- **Stripe Customer Portal**: https://stripe.com/docs/billing/subscriptions/integrating-customer-portal
- **Stripe Testing**: https://stripe.com/docs/testing

---

## ✅ Final Production Checklist

**Before switching to production mode:**

- [ ] All webhook signature verification added
- [ ] All webhook events handled
- [ ] Spanish translations complete and tested
- [ ] Customer portal configured
- [ ] All email templates created (EN + ES)
- [ ] Refund policy published
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] Stripe Tax configured (if applicable)
- [ ] Test mode checkout works perfectly
- [ ] Production API keys obtained from Stripe
- [ ] Production webhooks registered
- [ ] Full end-to-end test in production mode
- [ ] Monitoring and alerting set up
- [ ] Customer support email ready (connect@everydaychristian.app)

**Estimated Time to Production Ready**:
- Security fixes: 1-2 hours
- Spanish support: 2-3 hours
- Additional webhooks: 3-4 hours
- Customer portal: 1-2 hours
- Testing: 2-3 hours

**Total**: ~10-14 hours of development work

---

**Status**: ⚠️ Pre-Production - Security & Translation Work Needed
**Next Steps**: Implement webhook signature verification + Spanish email templates
**Target Launch Date**: TBD after security fixes complete
