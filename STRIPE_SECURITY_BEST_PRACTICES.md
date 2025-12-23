# Stripe Security Best Practices for Flutter/Web Applications

Comprehensive guide for implementing secure Stripe payment integration in Flutter web applications.

**Last Updated:** December 2025
**Source:** Official Stripe Documentation and Security Guides

---

## Table of Contents

1. [API Key Management](#1-api-key-management)
2. [Webhook Signature Verification](#2-webhook-signature-verification)
3. [Test Mode vs Production Mode](#3-test-mode-vs-production-mode)
4. [Common Security Vulnerabilities](#4-common-security-vulnerabilities)
5. [Environment Variable Storage](#5-environment-variable-storage)
6. [Secure Implementation Examples](#6-secure-implementation-examples)
7. [PCI DSS Compliance](#7-pci-dss-compliance)
8. [Quick Security Checklist](#8-quick-security-checklist)

---

## 1. API Key Management

### 1.1 Understanding Key Types

Stripe provides different types of API keys with varying security levels:

#### Publishable Keys (pk_test_* / pk_live_*)
- **Safe for client-side use** - Can be included in web pages and mobile apps
- **Limited capabilities** - Only used to generate payment tokens and initialize Stripe.js
- **No financial risk** - Cannot create charges or access sensitive data
- **Public exposure acceptable** - Designed to be embedded in frontend applications

#### Secret Keys (sk_test_* / sk_live_*)
- **NEVER expose to client-side** - Must remain server-side only
- **Full account access** - Can create charges, refunds, and access all customer data
- **Critical security** - If compromised, attackers can make unauthorized transactions
- **Server environment only** - Should only exist in secure backend services

#### Restricted Keys (rk_*)
- **Recommended for third-party integrations** - Safer than sharing full secret keys
- **Granular permissions** - Configure specific read/write access per resource
- **Three permission levels:**
  - **None** - No access
  - **Read** - Read-only access
  - **Write** - Full read/write access
- **Example use cases:**
  - Read-only keys for analytics tools
  - Dispute-only access for support teams
  - Limited refund access for customer service

### 1.2 Security Best Practices

#### Never Store Keys in Source Code
```dart
// ❌ WRONG - Never hardcode keys
class PaymentService {
  final stripe = Stripe('sk_live_51ABC123...'); // NEVER DO THIS
}

// ✅ CORRECT - Use environment variables
class PaymentService {
  final stripe = Stripe(
    dotenv.env['STRIPE_SECRET_KEY']!,
  );
}
```

#### Implement IP Address Restrictions
- Navigate to Stripe Dashboard → Developers → API Keys
- Click on the key you want to restrict
- Add allowed IP addresses under "IP allowlist"
- **Recommended if:** Your service has stable egress IP ranges
- **Benefits:** Additional layer of protection against stolen keys

#### Regular Key Rotation
- **Recommended frequency:** Every 90 days minimum
- **Before going live:** Rotate all keys immediately
- **After compromise:** Immediately rotate and replace throughout system
- **Process:**
  1. Generate new key in Stripe Dashboard
  2. Update key in all environments
  3. Deploy updated configuration
  4. Verify functionality
  5. Delete old key from Stripe Dashboard

#### Use Key Management Systems (KMS)
Recommended solutions:
- **AWS Secrets Manager**
- **Google Cloud Secret Manager**
- **HashiCorp Vault**
- **Azure Key Vault**

Benefits:
- Encryption at rest and in transit
- Audit logging
- Automatic rotation capabilities
- Access control policies

#### Grant Least Privilege Access
```javascript
// Example: Create restricted key for read-only analytics
// Permissions in Stripe Dashboard:
// - Charges: Read
// - Customers: Read
// - Payment Intents: Read
// - All other resources: None
```

### 1.3 Creating Restricted API Keys

**Dashboard Steps:**
1. Go to Developers → API Keys
2. Click "Create restricted key"
3. Enter a descriptive name
4. Select appropriate permissions for each resource
5. Save and securely store the key

**Permission Examples:**

| Use Case | Resource | Permission |
|----------|----------|------------|
| Analytics Dashboard | Charges | Read |
| Analytics Dashboard | Customers | Read |
| Analytics Dashboard | Payment Intents | Read |
| Dispute Monitor | Disputes | Read |
| Refund System | Refunds | Write |
| Customer Service | Customers | Read |

### 1.4 Immediate Response to Compromised Keys

If a key is compromised:

1. **Immediately roll/rotate the key** in Stripe Dashboard
2. **Generate a new key**
3. **Update all services** using the old key
4. **Delete the compromised key** from Stripe
5. **Review logs** for unauthorized activity
6. **Notify security team**
7. **Document the incident**

---

## 2. Webhook Signature Verification

Webhooks are critical for receiving asynchronous events from Stripe (payment success, failed charges, subscription updates). Without proper verification, attackers could send fake events to your system.

### 2.1 Why Signature Verification is Critical

**Without verification:**
- Attackers can forge webhook events
- Fake "payment_succeeded" events could grant unauthorized access
- Your system could be manipulated to:
  - Grant premium features without payment
  - Process fraudulent refunds
  - Expose customer data

**With verification:**
- Cryptographic proof the event came from Stripe
- Protection against replay attacks (timestamp validation)
- Ensures event integrity (hasn't been tampered with)

### 2.2 How Stripe Signs Webhooks

Stripe includes a `Stripe-Signature` header with each webhook:

```
Stripe-Signature: t=1614556800,v1=5257a869e7ecebeda32affa62cdca3fa51cad7e77a0e56ff536d0ce8e108d8bd
```

Components:
- `t` - Unix timestamp when Stripe sent the event
- `v1` - HMAC SHA-256 hash of the payload signed with your endpoint secret

### 2.3 Implementation Guide

#### Step 1: Retrieve Endpoint Secret

1. Go to Stripe Dashboard → Developers → Webhooks
2. Select your webhook endpoint
3. Click "Reveal" next to "Signing secret"
4. Store securely as `STRIPE_WEBHOOK_SECRET`

#### Step 2: Verify Signature (Node.js/Express Backend)

```javascript
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const app = express();

// CRITICAL: Use raw body for signature verification
app.post('/webhook',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    const sig = req.headers['stripe-signature'];
    const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;

    try {
      // Verify the signature
      event = stripe.webhooks.constructEvent(
        req.body,           // Raw body (NOT parsed JSON)
        sig,                // Stripe-Signature header
        endpointSecret      // Your webhook secret
      );
    } catch (err) {
      console.error(`Webhook signature verification failed: ${err.message}`);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Signature verified - safe to process event
    switch (event.type) {
      case 'payment_intent.succeeded':
        const paymentIntent = event.data.object;
        await handlePaymentSuccess(paymentIntent);
        break;

      case 'payment_intent.payment_failed':
        const failedPayment = event.data.object;
        await handlePaymentFailure(failedPayment);
        break;

      case 'customer.subscription.deleted':
        const subscription = event.data.object;
        await handleSubscriptionCancellation(subscription);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    // Return 2xx response quickly (within 20 seconds)
    res.json({ received: true });
  }
);
```

#### Step 3: Verify Signature (Firebase Cloud Functions)

```javascript
const functions = require('firebase-functions');
const stripe = require('stripe')(functions.config().stripe.secret);
const endpointSecret = functions.config().stripe.webhook_secret;

exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];

  let event;

  try {
    // Firebase provides raw body as req.rawBody
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      endpointSecret
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Process event...

  res.json({ received: true });
});
```

#### Step 4: Manual Verification (Advanced)

If you need to verify signatures manually:

```javascript
const crypto = require('crypto');

function verifySignature(payload, signature, secret) {
  // Extract timestamp and signature from header
  const elements = signature.split(',');
  const timestamp = elements.find(e => e.startsWith('t=')).split('=')[1];
  const sig = elements.find(e => e.startsWith('v1=')).split('=')[1];

  // Create expected signature
  const signedPayload = `${timestamp}.${payload}`;
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(signedPayload, 'utf8')
    .digest('hex');

  // Compare signatures (timing-safe comparison)
  if (crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expectedSignature))) {
    // Verify timestamp is recent (within 5 minutes)
    const currentTime = Math.floor(Date.now() / 1000);
    if (currentTime - parseInt(timestamp) > 300) {
      throw new Error('Timestamp too old');
    }
    return true;
  }

  throw new Error('Invalid signature');
}
```

### 2.4 Critical Implementation Notes

#### Always Use Raw Request Body

```javascript
// ❌ WRONG - Parsed JSON will fail verification
app.use(express.json());
app.post('/webhook', (req, res) => {
  const event = stripe.webhooks.constructEvent(
    req.body, // This is parsed JSON - WILL FAIL
    sig,
    secret
  );
});

// ✅ CORRECT - Use raw body
app.post('/webhook',
  express.raw({ type: 'application/json' }),
  (req, res) => {
    const event = stripe.webhooks.constructEvent(
      req.body, // This is raw buffer - WILL SUCCEED
      sig,
      secret
    );
  }
);
```

#### Respond Quickly (< 20 seconds)

```javascript
// ❌ WRONG - Processing before responding
app.post('/webhook', async (req, res) => {
  const event = stripe.webhooks.constructEvent(req.body, sig, secret);

  // Don't do heavy processing here
  await sendEmailToCustomer(event.data.object);
  await updateDatabase(event.data.object);
  await notifySlack(event.data.object);

  res.json({ received: true }); // Too late!
});

// ✅ CORRECT - Respond immediately, process async
app.post('/webhook', async (req, res) => {
  const event = stripe.webhooks.constructEvent(req.body, sig, secret);

  // Respond immediately
  res.json({ received: true });

  // Process in background
  processWebhookAsync(event).catch(err => {
    console.error('Webhook processing failed:', err);
  });
});
```

#### Handle Duplicate Events (Idempotency)

Stripe may send the same event multiple times. Implement idempotency:

```javascript
const processedEvents = new Set(); // In production, use database

async function handleWebhook(event) {
  // Check if already processed
  if (processedEvents.has(event.id)) {
    console.log(`Event ${event.id} already processed`);
    return;
  }

  // Process event
  await processEvent(event);

  // Mark as processed
  processedEvents.add(event.id);

  // In production, store in database:
  // await db.webhookEvents.create({
  //   eventId: event.id,
  //   processedAt: new Date()
  // });
}
```

### 2.5 Webhook Endpoint Security

#### Use HTTPS Only
- Stripe requires HTTPS for production webhooks
- Supports only TLS v1.2 and v1.3
- Use valid SSL certificates (no self-signed in production)

#### Stable Endpoint Path
```
✅ Good:  https://api.example.com/webhooks/stripe
❌ Avoid: https://api.example.com/webhook?version=2&token=abc123
```

#### Rate Limiting
Implement rate limiting to prevent abuse:

```javascript
const rateLimit = require('express-rate-limit');

const webhookLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // Max 100 requests per minute
  message: 'Too many webhook requests'
});

app.post('/webhook', webhookLimiter, webhookHandler);
```

---

## 3. Test Mode vs Production Mode

Stripe provides separate test and production environments to safely develop and test your integration before processing real payments.

### 3.1 Understanding Modes

| Aspect | Test Mode | Production Mode |
|--------|-----------|-----------------|
| **API Keys** | `pk_test_*` / `sk_test_*` | `pk_live_*` / `sk_live_*` |
| **Data** | Isolated, not visible in live | Real customer and transaction data |
| **Payments** | Simulated using test cards | Real money movements |
| **Dashboard** | Orange/blue test banner | No banner, production data |
| **Webhooks** | Separate test endpoints | Separate live endpoints |
| **Objects** | Not accessible in live mode | Not accessible in test mode |

### 3.2 Key Security Practices

#### Separate Keys by Environment

```dart
// ❌ WRONG - Same keys for all environments
class StripeConfig {
  static const publishableKey = 'pk_test_51ABC123...';
}

// ✅ CORRECT - Environment-specific keys
class StripeConfig {
  static String get publishableKey {
    if (kDebugMode) {
      return dotenv.env['STRIPE_TEST_PUBLISHABLE_KEY']!;
    } else {
      return dotenv.env['STRIPE_LIVE_PUBLISHABLE_KEY']!;
    }
  }
}
```

#### Environment Configuration Files

```bash
# .env.development
STRIPE_PUBLISHABLE_KEY=pk_test_51ABC123...
STRIPE_SECRET_KEY=sk_test_51ABC123...
STRIPE_WEBHOOK_SECRET=whsec_test_ABC123...

# .env.production
STRIPE_PUBLISHABLE_KEY=pk_live_51XYZ789...
STRIPE_SECRET_KEY=sk_live_51XYZ789...
STRIPE_WEBHOOK_SECRET=whsec_XYZ789...
```

#### Rotate Keys Before Going Live

**Critical security step:**

1. **One week before launch:**
   - Generate new live mode API keys
   - Update production environment variables
   - Test with new keys in staging

2. **Day of launch:**
   - Verify all keys are correct
   - Delete old test keys (if any were accidentally used in production)
   - Monitor logs for any key-related errors

#### Separate Webhook Endpoints

Configure different endpoints for test and live mode:

```
Test:       https://api.example.com/webhooks/stripe/test
Production: https://api.example.com/webhooks/stripe/live
```

**In webhook handler:**

```javascript
// Determine mode from endpoint path
app.post('/webhooks/stripe/:mode', async (req, res) => {
  const mode = req.params.mode; // 'test' or 'live'

  const secret = mode === 'test'
    ? process.env.STRIPE_TEST_WEBHOOK_SECRET
    : process.env.STRIPE_LIVE_WEBHOOK_SECRET;

  const event = stripe.webhooks.constructEvent(req.body, sig, secret);

  // Process event...
});
```

### 3.3 Dashboard Settings Warning

**IMPORTANT:** Some dashboard settings affect BOTH test and live mode:

- Email receipt settings
- Business information
- Branding/logos
- Tax settings
- Some billing configurations

**Visual indicators:**
- **Orange/blue banner:** Test data (safe to modify)
- **No banner:** Changes affect BOTH modes (careful!)
- **White callout:** Setting is mode-specific

### 3.4 Testing with Test Cards

Stripe provides test card numbers that simulate different scenarios:

```dart
// Test card numbers (TEST MODE ONLY)
const testCards = {
  'success': '4242424242424242',
  'requiresAuthentication': '4000002500003155',
  'declined': '4000000000000002',
  'insufficientFunds': '4000000000009995',
  'expiredCard': '4000000000000069',
  'incorrectCVC': '4000000000000127',
};
```

**Common test scenarios:**

| Card Number | Scenario |
|-------------|----------|
| 4242 4242 4242 4242 | Successful payment |
| 4000 0025 0000 3155 | Requires 3D Secure authentication |
| 4000 0000 0000 0002 | Card declined |
| 4000 0000 0000 9995 | Insufficient funds |
| 4000 0000 0000 0341 | Charge succeeds, dispute created |

**Any future expiration date and any 3-digit CVC works with test cards.**

### 3.5 Go-Live Checklist

Before switching to production:

- [ ] Generate new live mode API keys
- [ ] Update all environment variables with live keys
- [ ] Configure live webhook endpoints in Dashboard
- [ ] Test webhook signature verification with live endpoint
- [ ] Enable live mode in Stripe Dashboard
- [ ] Update publishable key in Flutter app
- [ ] Test a small live transaction
- [ ] Monitor logs for errors
- [ ] Verify webhook events are received
- [ ] Delete any test keys from production environment
- [ ] Document which keys are used where

---

## 4. Common Security Vulnerabilities

Understanding common security vulnerabilities helps you avoid costly mistakes and data breaches.

### 4.1 Exposed Secret Keys

**The Problem:**
27% of payment gateway breaches stem from poor API key management. Exposed secret keys give attackers full control over your Stripe account.

**How it Happens:**
- Hardcoding keys in source code
- Committing `.env` files to Git
- Logging keys in application logs
- Exposing keys in client-side code
- Sharing keys in chat/email
- Using same keys across environments

**Prevention:**

```dart
// ❌ NEVER DO THIS
class StripeService {
  final stripe = Stripe('sk_live_51ABC123...'); // EXPOSED IN CODE

  void debugPrint() {
    print('Stripe key: ${stripe.apiKey}'); // LOGGED
  }
}

// ✅ DO THIS
class StripeService {
  late final Stripe stripe;

  StripeService() {
    final key = dotenv.env['STRIPE_SECRET_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Stripe secret key not configured');
    }
    stripe = Stripe(key);
  }

  // Never log sensitive data
  void debugPrint() {
    print('Stripe initialized: ${stripe.apiKey.substring(0, 7)}***');
  }
}
```

**Git Protection:**

```bash
# .gitignore - ALWAYS include these
.env
.env.local
.env.development
.env.production
.env.*.local

# Flutter specific
.flutter-plugins
.flutter-plugins-dependencies

# Secrets
*secret*
*credentials*
*.key
*.pem
```

**Secret Scanning:**
Use tools to detect accidental commits:
- GitHub Secret Scanning (automatic for public repos)
- GitLeaks
- TruffleHog
- Rafter

### 4.2 Unverified Webhook Signatures

**The Problem:**
Without signature verification, attackers can send fake events to your webhook endpoint.

**Attack Scenario:**
```javascript
// Attacker sends fake event:
POST /webhook
{
  "type": "payment_intent.succeeded",
  "data": {
    "object": {
      "id": "pi_fake123",
      "amount": 10000,
      "customer": "cus_attacker"
    }
  }
}
```

Without verification, your system might:
- Grant premium access without payment
- Mark fake orders as paid
- Update user credits incorrectly

**Prevention:**

```javascript
// ❌ VULNERABLE - No verification
app.post('/webhook', (req, res) => {
  const event = req.body; // Trusting raw input

  if (event.type === 'payment_intent.succeeded') {
    grantPremiumAccess(event.data.object.customer); // DANGEROUS
  }

  res.json({ received: true });
});

// ✅ SECURE - Verified signature
app.post('/webhook', (req, res) => {
  let event;

  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      req.headers['stripe-signature'],
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    return res.status(400).send('Invalid signature');
  }

  // Now safe to trust event
  if (event.type === 'payment_intent.succeeded') {
    grantPremiumAccess(event.data.object.customer);
  }

  res.json({ received: true });
});
```

### 4.3 Client-Side Payment Intent Creation

**The Problem:**
Creating payment intents from the client exposes your secret key and allows amount manipulation.

**Attack Scenario:**
```dart
// ❌ VULNERABLE - Client creates payment intent
Future<void> processPayment() async {
  // Attacker can modify amount to $0.01
  final amount = 100; // Should be $100

  final intent = await Stripe.instance.createPaymentIntent(
    amount: amount, // Attacker changes to 1
    currency: 'usd',
  );

  // Payment processed for $0.01 instead of $100!
}
```

**Prevention:**

```dart
// ✅ SECURE - Server creates payment intent
// Flutter Client
class PaymentService {
  final String backendUrl = 'https://api.example.com';

  Future<String> createPaymentIntent({
    required int amount,
    required String currency,
  }) async {
    final response = await http.post(
      Uri.parse('$backendUrl/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['clientSecret'];
    }

    throw Exception('Failed to create payment intent');
  }
}

// Backend (Node.js)
app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency } = req.body;

  // Server-side validation
  if (amount < 50 || amount > 999999) {
    return res.status(400).json({ error: 'Invalid amount' });
  }

  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency,
    automatic_payment_methods: { enabled: true },
  });

  res.json({ clientSecret: paymentIntent.client_secret });
});
```

### 4.4 Insecure Data Storage

**The Problem:**
Storing sensitive payment data violates PCI compliance and creates liability.

**What NOT to Store:**
- Full credit card numbers
- CVV/CVC codes
- Card expiration dates (unless tokenized)
- Raw payment method details

**What You CAN Store:**
- Stripe customer IDs
- Stripe payment method IDs
- Last 4 digits of card
- Card brand (Visa, Mastercard, etc.)
- Transaction IDs

```dart
// ❌ NEVER STORE THIS
class PaymentRecord {
  String cardNumber;       // PCI violation
  String cvv;              // PCI violation
  String expiryDate;       // PCI violation
}

// ✅ STORE THIS INSTEAD
class PaymentRecord {
  String stripeCustomerId;     // Safe
  String stripePaymentMethodId; // Safe
  String last4;                // Safe
  String brand;                // Safe (Visa, Mastercard, etc.)
  DateTime createdAt;          // Safe
}
```

### 4.5 Missing HTTPS/TLS

**The Problem:**
Transmitting payment data over HTTP exposes it to man-in-the-middle attacks.

**Statistics:**
80% of internet users abandon websites that aren't secure.

**Prevention:**

- **Always use HTTPS** for production
- Use valid SSL/TLS certificates (Let's Encrypt is free)
- Redirect HTTP to HTTPS
- Use HSTS headers

```javascript
// Enforce HTTPS
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https' && process.env.NODE_ENV === 'production') {
    res.redirect(`https://${req.header('host')}${req.url}`);
  } else {
    next();
  }
});

// HSTS header
app.use((req, res, next) => {
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  next();
});
```

### 4.6 Insufficient Input Validation

**The Problem:**
Accepting unvalidated input can lead to injection attacks and business logic errors.

```javascript
// ❌ VULNERABLE - No validation
app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency } = req.body;

  const paymentIntent = await stripe.paymentIntents.create({
    amount,      // Could be negative!
    currency,    // Could be invalid!
  });

  res.json({ clientSecret: paymentIntent.client_secret });
});

// ✅ SECURE - Validated input
app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency } = req.body;

  // Validate amount
  if (!Number.isInteger(amount) || amount < 50 || amount > 999999) {
    return res.status(400).json({
      error: 'Invalid amount. Must be between $0.50 and $9,999.99'
    });
  }

  // Validate currency
  const allowedCurrencies = ['usd', 'eur', 'gbp'];
  if (!allowedCurrencies.includes(currency.toLowerCase())) {
    return res.status(400).json({
      error: 'Invalid currency. Allowed: USD, EUR, GBP'
    });
  }

  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency: currency.toLowerCase(),
    automatic_payment_methods: { enabled: true },
  });

  res.json({ clientSecret: paymentIntent.client_secret });
});
```

### 4.7 Outdated Dependencies

**The Problem:**
Organizations experience an average of 11 vulnerabilities per project due to outdated packages.

**Prevention:**

```bash
# Regularly update dependencies
npm audit
npm audit fix

# Or for Flutter
flutter pub upgrade
flutter pub outdated

# Use automated tools
# - Dependabot (GitHub)
# - Snyk
# - Renovate
```

**In `package.json`:**

```json
{
  "dependencies": {
    "stripe": "^14.10.0"  // Keep updated
  }
}
```

### 4.8 Missing Rate Limiting

**The Problem:**
Without rate limiting, attackers can:
- Brute force payment attempts
- DDoS your payment endpoints
- Enumerate customer data

**Prevention:**

```javascript
const rateLimit = require('express-rate-limit');

// Payment endpoint rate limiting
const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Max 10 payment attempts per 15 min
  message: 'Too many payment attempts. Please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

app.post('/create-payment-intent', paymentLimiter, async (req, res) => {
  // Handle payment
});

// Webhook rate limiting
const webhookLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // Max 100 webhook events per minute
});

app.post('/webhook', webhookLimiter, webhookHandler);
```

---

## 5. Environment Variable Storage

Secure storage of API keys and secrets is critical. Different approaches work for different environments.

### 5.1 Comparison of Storage Methods

| Method | Security | Flutter Web | CI/CD | Recommended For |
|--------|----------|-------------|-------|-----------------|
| **--dart-define** | High | ✅ Yes | ✅ Yes | Production builds |
| **ENVied** | Very High | ✅ Yes | ✅ Yes | Maximum security |
| **flutter_dotenv** | Medium | ⚠️ Limited | ✅ Yes | Development only |
| **Hardcoded** | ❌ None | ✅ Yes | ❌ No | NEVER use |

### 5.2 Method 1: --dart-define (Recommended for Production)

**How it works:**
Compile-time environment variables baked into the app binary.

**Setup:**

```bash
# Build with environment variables
flutter build web --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_123 \
                   --dart-define=BACKEND_URL=https://api.example.com
```

**Access in Dart:**

```dart
class EnvironmentConfig {
  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Validation
  static void validate() {
    if (stripePublishableKey.isEmpty) {
      throw Exception('STRIPE_PUBLISHABLE_KEY not configured');
    }
    if (!stripePublishableKey.startsWith('pk_')) {
      throw Exception('Invalid Stripe publishable key format');
    }
  }
}

// In main.dart
void main() {
  EnvironmentConfig.validate();
  runApp(MyApp());
}
```

**CI/CD Integration (GitHub Actions):**

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Build web
        env:
          STRIPE_KEY: ${{ secrets.STRIPE_PUBLISHABLE_KEY }}
          BACKEND_URL: ${{ secrets.BACKEND_URL }}
        run: |
          flutter build web \
            --dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_KEY \
            --dart-define=BACKEND_URL=$BACKEND_URL
```

**Pros:**
- ✅ Very secure (compiled into binary)
- ✅ Works perfectly with Flutter Web
- ✅ CI/CD friendly
- ✅ No runtime file loading

**Cons:**
- ❌ Must rebuild to change values
- ❌ Verbose command line

### 5.3 Method 2: ENVied Package (Maximum Security)

**Why ENVied?**
Provides obfuscation and encryption of environment variables, making reverse engineering extremely difficult.

**Installation:**

```yaml
# pubspec.yaml
dependencies:
  envied: ^0.5.4+1

dev_dependencies:
  envied_generator: ^0.5.4+1
  build_runner: ^2.4.7
```

**Setup:**

```dart
// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'STRIPE_PUBLISHABLE_KEY', obfuscate: true)
  static final String stripePublishableKey = _Env.stripePublishableKey;

  @EnviedField(varName: 'BACKEND_URL', obfuscate: true)
  static final String backendUrl = _Env.backendUrl;
}
```

**Create `.env` file:**

```bash
# .env
STRIPE_PUBLISHABLE_KEY=pk_test_51ABC123...
BACKEND_URL=https://api.example.com
```

**Generate encrypted code:**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Usage:**

```dart
import 'package:your_app/env/env.dart';

void initializeStripe() {
  Stripe.publishableKey = Env.stripePublishableKey;
  Stripe.merchantIdentifier = 'merchant.com.example.app';
  Stripe.urlScheme = 'your-app';
  await Stripe.instance.applySettings();
}
```

**CRITICAL: Git Ignore:**

```bash
# .gitignore
.env
.env.local
.env.*.local

# Commit the generated file (it's encrypted)
# lib/env/env.g.dart - OK to commit
```

**Pros:**
- ✅ Encrypted/obfuscated values
- ✅ Very difficult to reverse engineer
- ✅ Type-safe access
- ✅ Works with Flutter Web

**Cons:**
- ❌ Requires build step
- ❌ Slightly more complex setup

### 5.4 Method 3: flutter_dotenv (Development Only)

**⚠️ WARNING:** Not recommended for production or Flutter Web.

**Why not for production:**
- Assets must be bundled in web builds (exposes .env file)
- .env file accessible in browser DevTools
- No encryption or obfuscation

**Setup (if you must):**

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

```dart
// main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

// Usage
final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
```

**Only use for:**
- Local development
- Testing
- Non-sensitive configuration

### 5.5 Backend Environment Variables

For your Node.js/Express backend, environment variables are essential.

**Using .env files:**

```bash
# .env.production
NODE_ENV=production
STRIPE_SECRET_KEY=sk_live_51XYZ789...
STRIPE_WEBHOOK_SECRET=whsec_XYZ789...
DATABASE_URL=postgresql://user:pass@host:5432/db
```

**Load with dotenv:**

```javascript
// Load before any other imports
require('dotenv').config({
  path: `.env.${process.env.NODE_ENV || 'development'}`
});

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

// Validate required variables
const requiredEnvVars = [
  'STRIPE_SECRET_KEY',
  'STRIPE_WEBHOOK_SECRET',
  'DATABASE_URL',
];

requiredEnvVars.forEach((varName) => {
  if (!process.env[varName]) {
    throw new Error(`Missing required environment variable: ${varName}`);
  }
});
```

**Production deployment:**

Never commit `.env.production` to Git. Instead:

**Option 1: Platform environment variables**
- Heroku: Config Vars
- AWS: Parameter Store / Secrets Manager
- Google Cloud: Secret Manager
- Vercel: Environment Variables dashboard

**Option 2: CI/CD secrets**

```yaml
# .github/workflows/deploy.yml
- name: Deploy to production
  env:
    STRIPE_SECRET_KEY: ${{ secrets.STRIPE_SECRET_KEY }}
    STRIPE_WEBHOOK_SECRET: ${{ secrets.STRIPE_WEBHOOK_SECRET }}
  run: |
    # Deploy script
```

### 5.6 Security Best Practices

#### Never Commit Secrets

```bash
# .gitignore - Always include
.env
.env.local
.env.*.local
.env.development
.env.production
*.key
*.pem
*secret*
*credentials*
```

#### Use Different Keys Per Environment

```
Development:  sk_test_51ABC...
Staging:      sk_test_51DEF...  (different test key)
Production:   sk_live_51XYZ...
```

#### Rotate Regularly

- Development keys: Every 3-6 months
- Production keys: Every 90 days
- Immediately on any suspected compromise

#### Audit Access

- Review who has access to production secrets
- Use principle of least privilege
- Log secret access (KMS/Secrets Manager)

#### Validate at Startup

```dart
void validateEnvironment() {
  final key = Env.stripePublishableKey;

  if (key.isEmpty) {
    throw Exception('Stripe key not configured');
  }

  // Check key format
  final isTest = key.startsWith('pk_test_');
  final isLive = key.startsWith('pk_live_');

  if (!isTest && !isLive) {
    throw Exception('Invalid Stripe key format');
  }

  // Warn about test keys in production
  if (kReleaseMode && isTest) {
    throw Exception('Test Stripe key in production build!');
  }
}
```

---

## 6. Secure Implementation Examples

Complete, production-ready code examples for implementing Stripe securely in Flutter web applications.

### 6.1 Flutter Client Implementation

#### Project Structure

```
lib/
├── config/
│   ├── environment.dart
│   └── stripe_config.dart
├── services/
│   ├── payment_service.dart
│   └── backend_api.dart
├── models/
│   └── payment_intent_response.dart
└── screens/
    └── checkout_screen.dart
```

#### Environment Configuration

```dart
// lib/config/environment.dart
import 'package:flutter/foundation.dart';

class Environment {
  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );

  static bool get isProduction => kReleaseMode;
  static bool get isTest => stripePublishableKey.startsWith('pk_test_');

  static void validate() {
    if (stripePublishableKey.isEmpty) {
      throw Exception('STRIPE_PUBLISHABLE_KEY not configured');
    }

    if (!stripePublishableKey.startsWith('pk_')) {
      throw Exception('Invalid Stripe publishable key format');
    }

    if (isProduction && isTest) {
      throw Exception('Test key in production build!');
    }

    if (backendUrl.isEmpty) {
      throw Exception('BACKEND_URL not configured');
    }
  }
}
```

#### Stripe Initialization

```dart
// lib/config/stripe_config.dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'environment.dart';

class StripeConfig {
  static Future<void> initialize() async {
    Environment.validate();

    Stripe.publishableKey = Environment.stripePublishableKey;
    Stripe.merchantIdentifier = 'merchant.com.example.app';
    Stripe.urlScheme = 'your-app';

    await Stripe.instance.applySettings();
  }
}
```

#### Backend API Service

```dart
// lib/services/backend_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/payment_intent_response.dart';

class BackendApi {
  static final String baseUrl = Environment.backendUrl;

  static Future<PaymentIntentResponse> createPaymentIntent({
    required int amount,
    required String currency,
    String? customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          if (customerId != null) 'customer': customerId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentIntentResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create payment intent');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> confirmPayment({
    required String paymentIntentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/confirm-payment'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to confirm payment');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
```

#### Payment Intent Model

```dart
// lib/models/payment_intent_response.dart
class PaymentIntentResponse {
  final String clientSecret;
  final String paymentIntentId;
  final int amount;
  final String currency;

  PaymentIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      clientSecret: json['clientSecret'] as String,
      paymentIntentId: json['paymentIntentId'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
    );
  }
}
```

#### Payment Service

```dart
// lib/services/payment_service.dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'backend_api.dart';
import '../models/payment_intent_response.dart';

class PaymentService {
  /// Process a payment
  ///
  /// Returns true if successful, throws exception on failure
  static Future<bool> processPayment({
    required int amount,
    required String currency,
    String? customerId,
  }) async {
    try {
      // 1. Create payment intent on backend
      final paymentIntent = await BackendApi.createPaymentIntent(
        amount: amount,
        currency: currency,
        customerId: customerId,
      );

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent.clientSecret,
          merchantDisplayName: 'Your Company Name',
          customerId: customerId,
          style: ThemeMode.system,
        ),
      );

      // 3. Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Payment successful
      return true;

    } on StripeException catch (e) {
      // Payment failed or cancelled
      if (e.error.code == FailureCode.Canceled) {
        throw Exception('Payment cancelled');
      } else {
        throw Exception('Payment failed: ${e.error.message}');
      }
    } catch (e) {
      throw Exception('Payment error: $e');
    }
  }

  /// Process payment with custom flow (for advanced use cases)
  static Future<bool> processPaymentCustomFlow({
    required int amount,
    required String currency,
  }) async {
    try {
      // 1. Create payment intent
      final paymentIntent = await BackendApi.createPaymentIntent(
        amount: amount,
        currency: currency,
      );

      // 2. Confirm payment
      final confirmResult = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent.clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (confirmResult.status == PaymentIntentsStatus.Succeeded) {
        return true;
      } else {
        throw Exception('Payment not completed');
      }

    } catch (e) {
      throw Exception('Payment error: $e');
    }
  }
}
```

#### Checkout Screen

```dart
// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  final int amount;
  final String currency;

  const CheckoutScreen({
    Key? key,
    required this.amount,
    required this.currency,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      final success = await PaymentService.processPayment(
        amount: widget.amount,
        currency: widget.currency,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to success screen
        Navigator.of(context).pushReplacementNamed('/success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Total: \$${(widget.amount / 100).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _handlePayment,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Main App Entry

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'config/stripe_config.dart';
import 'screens/checkout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe
  await StripeConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stripe Payment Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CheckoutScreen(
        amount: 5000, // $50.00
        currency: 'usd',
      ),
    );
  }
}
```

### 6.2 Backend Implementation (Node.js/Express)

#### Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── stripe.js
│   │   └── environment.js
│   ├── controllers/
│   │   ├── payment.controller.js
│   │   └── webhook.controller.js
│   ├── middleware/
│   │   ├── validation.js
│   │   └── rateLimit.js
│   ├── routes/
│   │   ├── payment.routes.js
│   │   └── webhook.routes.js
│   └── server.js
├── .env.example
├── package.json
└── README.md
```

#### Environment Configuration

```javascript
// src/config/environment.js
require('dotenv').config();

const requiredEnvVars = [
  'STRIPE_SECRET_KEY',
  'STRIPE_WEBHOOK_SECRET',
  'NODE_ENV',
];

// Validate required environment variables
requiredEnvVars.forEach((varName) => {
  if (!process.env[varName]) {
    throw new Error(`Missing required environment variable: ${varName}`);
  }
});

// Validate Stripe keys
if (!process.env.STRIPE_SECRET_KEY.startsWith('sk_')) {
  throw new Error('Invalid Stripe secret key format');
}

if (process.env.NODE_ENV === 'production' &&
    process.env.STRIPE_SECRET_KEY.startsWith('sk_test_')) {
  throw new Error('Test Stripe key in production!');
}

module.exports = {
  stripe: {
    secretKey: process.env.STRIPE_SECRET_KEY,
    webhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
  },
  server: {
    port: process.env.PORT || 3000,
    nodeEnv: process.env.NODE_ENV,
  },
};
```

#### Stripe Configuration

```javascript
// src/config/stripe.js
const Stripe = require('stripe');
const config = require('./environment');

const stripe = Stripe(config.stripe.secretKey, {
  apiVersion: '2023-10-16',
  maxNetworkRetries: 2,
  timeout: 30000, // 30 seconds
});

module.exports = stripe;
```

#### Payment Controller

```javascript
// src/controllers/payment.controller.js
const stripe = require('../config/stripe');
const { v4: uuidv4 } = require('uuid');

class PaymentController {
  /**
   * Create a payment intent
   */
  static async createPaymentIntent(req, res) {
    try {
      const { amount, currency, customerId } = req.body;

      // Validate amount (minimum 50 cents, maximum $999,999.99)
      if (!Number.isInteger(amount) || amount < 50 || amount > 99999999) {
        return res.status(400).json({
          error: 'Invalid amount. Must be between $0.50 and $999,999.99',
        });
      }

      // Validate currency
      const allowedCurrencies = ['usd', 'eur', 'gbp'];
      if (!allowedCurrencies.includes(currency?.toLowerCase())) {
        return res.status(400).json({
          error: 'Invalid currency. Allowed: USD, EUR, GBP',
        });
      }

      // Generate idempotency key
      const idempotencyKey = uuidv4();

      // Create payment intent
      const paymentIntent = await stripe.paymentIntents.create(
        {
          amount,
          currency: currency.toLowerCase(),
          customer: customerId,
          automatic_payment_methods: {
            enabled: true,
          },
          metadata: {
            createdAt: new Date().toISOString(),
          },
        },
        {
          idempotencyKey,
        }
      );

      res.json({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
      });

    } catch (error) {
      console.error('Payment intent creation failed:', error);
      res.status(500).json({
        error: 'Failed to create payment intent',
        message: error.message,
      });
    }
  }

  /**
   * Confirm a payment intent
   */
  static async confirmPayment(req, res) {
    try {
      const { paymentIntentId } = req.body;

      if (!paymentIntentId) {
        return res.status(400).json({
          error: 'Payment intent ID is required',
        });
      }

      const paymentIntent = await stripe.paymentIntents.confirm(
        paymentIntentId
      );

      res.json({
        status: paymentIntent.status,
        paymentIntentId: paymentIntent.id,
      });

    } catch (error) {
      console.error('Payment confirmation failed:', error);
      res.status(500).json({
        error: 'Failed to confirm payment',
        message: error.message,
      });
    }
  }

  /**
   * Get payment intent status
   */
  static async getPaymentIntent(req, res) {
    try {
      const { paymentIntentId } = req.params;

      const paymentIntent = await stripe.paymentIntents.retrieve(
        paymentIntentId
      );

      res.json({
        status: paymentIntent.status,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
      });

    } catch (error) {
      console.error('Failed to retrieve payment intent:', error);
      res.status(500).json({
        error: 'Failed to retrieve payment intent',
        message: error.message,
      });
    }
  }
}

module.exports = PaymentController;
```

#### Webhook Controller

```javascript
// src/controllers/webhook.controller.js
const stripe = require('../config/stripe');
const config = require('../config/environment');

class WebhookController {
  /**
   * Handle Stripe webhooks
   */
  static async handleWebhook(req, res) {
    const sig = req.headers['stripe-signature'];
    const endpointSecret = config.stripe.webhookSecret;

    let event;

    try {
      // Verify webhook signature
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        endpointSecret
      );
    } catch (err) {
      console.error('Webhook signature verification failed:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Respond immediately
    res.json({ received: true });

    // Process event asynchronously
    processWebhookEvent(event).catch((err) => {
      console.error('Webhook processing failed:', err);
    });
  }
}

/**
 * Process webhook event (async)
 */
async function processWebhookEvent(event) {
  console.log(`Processing webhook: ${event.type}`);

  switch (event.type) {
    case 'payment_intent.succeeded':
      await handlePaymentSuccess(event.data.object);
      break;

    case 'payment_intent.payment_failed':
      await handlePaymentFailure(event.data.object);
      break;

    case 'customer.subscription.created':
      await handleSubscriptionCreated(event.data.object);
      break;

    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object);
      break;

    case 'customer.subscription.deleted':
      await handleSubscriptionDeleted(event.data.object);
      break;

    case 'charge.dispute.created':
      await handleDisputeCreated(event.data.object);
      break;

    default:
      console.log(`Unhandled event type: ${event.type}`);
  }
}

async function handlePaymentSuccess(paymentIntent) {
  console.log('Payment succeeded:', paymentIntent.id);

  // Example: Update database
  // await db.orders.update({
  //   where: { paymentIntentId: paymentIntent.id },
  //   data: { status: 'paid' }
  // });

  // Example: Send confirmation email
  // await sendPaymentConfirmationEmail(paymentIntent);
}

async function handlePaymentFailure(paymentIntent) {
  console.log('Payment failed:', paymentIntent.id);

  // Example: Update database
  // await db.orders.update({
  //   where: { paymentIntentId: paymentIntent.id },
  //   data: { status: 'failed' }
  // });

  // Example: Send failure notification
  // await sendPaymentFailureEmail(paymentIntent);
}

async function handleSubscriptionCreated(subscription) {
  console.log('Subscription created:', subscription.id);

  // Grant access to subscription features
}

async function handleSubscriptionUpdated(subscription) {
  console.log('Subscription updated:', subscription.id);

  // Update user's subscription status
}

async function handleSubscriptionDeleted(subscription) {
  console.log('Subscription deleted:', subscription.id);

  // Revoke access to subscription features
}

async function handleDisputeCreated(dispute) {
  console.log('Dispute created:', dispute.id);

  // Alert team about dispute
  // await sendDisputeAlert(dispute);
}

module.exports = WebhookController;
```

#### Rate Limiting Middleware

```javascript
// src/middleware/rateLimit.js
const rateLimit = require('express-rate-limit');

const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Max 10 requests per 15 minutes
  message: 'Too many payment attempts. Please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Too many payment attempts. Please try again later.',
    });
  },
});

const webhookLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // Max 100 webhook events per minute
  message: 'Webhook rate limit exceeded',
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  paymentLimiter,
  webhookLimiter,
};
```

#### Routes

```javascript
// src/routes/payment.routes.js
const express = require('express');
const PaymentController = require('../controllers/payment.controller');
const { paymentLimiter } = require('../middleware/rateLimit');

const router = express.Router();

router.post(
  '/create-payment-intent',
  paymentLimiter,
  PaymentController.createPaymentIntent
);

router.post(
  '/confirm-payment',
  paymentLimiter,
  PaymentController.confirmPayment
);

router.get(
  '/payment-intent/:paymentIntentId',
  PaymentController.getPaymentIntent
);

module.exports = router;
```

```javascript
// src/routes/webhook.routes.js
const express = require('express');
const WebhookController = require('../controllers/webhook.controller');
const { webhookLimiter } = require('../middleware/rateLimit');

const router = express.Router();

router.post(
  '/stripe',
  webhookLimiter,
  WebhookController.handleWebhook
);

module.exports = router;
```

#### Server Setup

```javascript
// src/server.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config/environment');
const paymentRoutes = require('./routes/payment.routes');
const webhookRoutes = require('./routes/webhook.routes');

const app = express();

// Security headers
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
}));

// Webhook route (must use raw body)
app.use(
  '/webhook',
  express.raw({ type: 'application/json' }),
  webhookRoutes
);

// Regular routes (JSON parsing)
app.use(express.json());
app.use('/api', paymentRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// Start server
const PORT = config.server.port;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${config.server.nodeEnv}`);
});

module.exports = app;
```

#### Package.json

```json
{
  "name": "stripe-backend",
  "version": "1.0.0",
  "description": "Secure Stripe payment backend",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest"
  },
  "dependencies": {
    "stripe": "^14.10.0",
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "dotenv": "^16.3.1",
    "express-rate-limit": "^7.1.5",
    "uuid": "^9.0.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "jest": "^29.7.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

#### Environment Variables Template

```bash
# .env.example
NODE_ENV=development
PORT=3000

# Stripe Keys (DO NOT COMMIT REAL KEYS)
STRIPE_SECRET_KEY=sk_test_51ABC123...
STRIPE_WEBHOOK_SECRET=whsec_ABC123...

# CORS
ALLOWED_ORIGINS=http://localhost:8080,https://your-app.com
```

---

## 7. PCI DSS Compliance

PCI DSS (Payment Card Industry Data Security Standard) compliance is legally required for any business that handles credit card data.

### 7.1 What is PCI DSS?

**PCI DSS** is a set of security standards designed to ensure that ALL companies that accept, process, store, or transmit credit card information maintain a secure environment.

**Key Facts:**
- Stripe is PCI Service Provider Level 1 certified (highest level)
- Using Stripe does NOT automatically make you PCI compliant
- PCI compliance is a **shared responsibility**
- Non-compliance can result in fines up to $100,000/month

### 7.2 Compliance Levels

Your PCI compliance level depends on transaction volume:

| Level | Annual Transactions | Requirements |
|-------|---------------------|--------------|
| **Level 1** | > 6 million | Annual on-site audit by QSA |
| **Level 2** | 1-6 million | Annual SAQ + quarterly network scan |
| **Level 3** | 20,000-1 million | Annual SAQ + quarterly network scan |
| **Level 4** | < 20,000 | Annual SAQ |

### 7.3 Self-Assessment Questionnaires (SAQ)

The SAQ type depends on your integration method:

| Integration Method | SAQ Type | Questions | Difficulty |
|-------------------|----------|-----------|------------|
| Stripe Checkout / Elements | **SAQ A** | 22 | Easiest |
| Stripe API (server-side) | **SAQ A-EP** | 178 | Medium |
| Direct card handling | **SAQ D** | 329 | Hardest |

**Recommendation:** Use Stripe Elements or Checkout to qualify for SAQ A.

### 7.4 How to Minimize PCI Scope

#### Use Stripe Elements (SAQ A Eligible)

```dart
// ✅ SAQ A - Card data never touches your servers
// Stripe Elements handles all card input

import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> processPayment() async {
  // 1. Create payment intent on backend
  final clientSecret = await createPaymentIntent();

  // 2. Stripe Elements collects card data securely
  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: clientSecret,
      merchantDisplayName: 'Your Company',
    ),
  );

  // 3. Card data goes directly to Stripe
  await Stripe.instance.presentPaymentSheet();
}
```

#### NEVER Do This (SAQ D Required)

```dart
// ❌ NEVER - Card data touches your app
class CardForm extends StatelessWidget {
  final TextEditingController cardNumberController;
  final TextEditingController cvvController;
  final TextEditingController expiryController;

  // This requires SAQ D (329 questions!)
}
```

### 7.5 What You Can and Cannot Store

#### ❌ NEVER Store (Forbidden by PCI DSS)

| Data Element | Why Forbidden |
|--------------|---------------|
| Full card number | Extreme security risk |
| CVV/CVC code | Must never be stored after authorization |
| PIN | Illegal to store |
| Full magnetic stripe data | Contains sensitive authentication data |

#### ✅ CAN Store (With Encryption)

| Data Element | Notes |
|--------------|-------|
| Cardholder name | Useful for receipts |
| Last 4 digits | For display purposes only |
| Expiration date (if tokenized) | When using Stripe payment methods |
| Stripe customer ID | Safe and recommended |
| Stripe payment method ID | Safe and recommended |

#### Secure Storage Example

```dart
// ❌ WRONG
class PaymentRecord {
  String cardNumber;  // PCI violation!
  String cvv;         // PCI violation!
}

// ✅ CORRECT
class PaymentRecord {
  String stripeCustomerId;      // Safe - Stripe token
  String stripePaymentMethodId; // Safe - Stripe token
  String last4;                 // Safe - Display only
  String brand;                 // Safe - "Visa", "Mastercard"
  DateTime timestamp;           // Safe
  int amount;                   // Safe
}
```

### 7.6 Annual Validation Requirements

**Steps to maintain compliance:**

1. **Complete SAQ annually**
   - Log into Stripe Dashboard
   - Go to Settings → Compliance
   - Complete appropriate SAQ

2. **Quarterly vulnerability scans** (if required)
   - Use approved scanning vendor (ASV)
   - Scan external-facing systems
   - Remediate any vulnerabilities

3. **Submit Attestation of Compliance (AOC)**
   - Sign and date the document
   - Submit to Stripe
   - Keep copy for records

### 7.7 Quick Compliance Checklist

- [ ] Use Stripe Elements or Checkout (for SAQ A)
- [ ] Never handle raw card data
- [ ] Never store prohibited data (CVV, full PAN)
- [ ] Use HTTPS for all communications
- [ ] Keep software and dependencies updated
- [ ] Implement webhook signature verification
- [ ] Use strong passwords and 2FA
- [ ] Restrict access to payment systems
- [ ] Complete annual SAQ
- [ ] Maintain security documentation

---

## 8. Quick Security Checklist

Use this checklist before deploying to production:

### API Key Management

- [ ] Publishable keys only in client-side code
- [ ] Secret keys only in backend/server
- [ ] Keys stored in environment variables (not hardcoded)
- [ ] Different keys for test and production
- [ ] Keys rotated within last 90 days
- [ ] Restricted API keys used where possible
- [ ] IP allowlists configured (if applicable)
- [ ] `.env` files in `.gitignore`
- [ ] No keys committed to Git repository
- [ ] Key management system configured (AWS/GCP/Vault)

### Webhook Security

- [ ] Webhook signature verification implemented
- [ ] Using raw request body for verification
- [ ] Endpoint uses HTTPS (TLS 1.2+)
- [ ] Responding within 20 seconds
- [ ] Idempotency handling for duplicate events
- [ ] Rate limiting configured
- [ ] Webhook secret stored securely
- [ ] Error logging implemented

### Environment Configuration

- [ ] Test mode and production mode separated
- [ ] Environment-specific keys configured
- [ ] Validation at application startup
- [ ] No test keys in production builds
- [ ] Separate webhook endpoints for test/live
- [ ] CI/CD secrets properly configured

### Payment Implementation

- [ ] Payment intents created server-side only
- [ ] Amount validation on backend
- [ ] Currency validation on backend
- [ ] Idempotency keys used for requests
- [ ] Error handling implemented
- [ ] User-friendly error messages
- [ ] Logging for debugging (no sensitive data)

### Data Security

- [ ] No raw card data stored
- [ ] No CVV/CVC stored
- [ ] Only Stripe tokens/IDs stored
- [ ] HTTPS enforced everywhere
- [ ] TLS 1.2 or higher
- [ ] HSTS headers configured
- [ ] Input validation on all endpoints

### PCI Compliance

- [ ] Using Stripe Elements or Checkout
- [ ] Card data never touches your servers
- [ ] SAQ completed (if required)
- [ ] No prohibited data stored
- [ ] Annual compliance validated

### Code Quality

- [ ] Dependencies up to date
- [ ] No security vulnerabilities (`npm audit`)
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] Error handling comprehensive
- [ ] Logging implemented (no sensitive data)

### Testing

- [ ] Tested with test cards
- [ ] Tested 3D Secure flow
- [ ] Tested error scenarios
- [ ] Tested webhook events
- [ ] Load testing completed
- [ ] Security testing completed

### Documentation

- [ ] API keys documented
- [ ] Webhook endpoints documented
- [ ] Error codes documented
- [ ] Runbooks for common issues
- [ ] Incident response plan
- [ ] Key rotation procedure documented

---

## Additional Resources

### Official Stripe Documentation

- [Stripe Security Guide](https://docs.stripe.com/security)
- [API Key Best Practices](https://docs.stripe.com/keys-best-practices)
- [Webhook Security](https://docs.stripe.com/webhooks)
- [PCI Compliance Guide](https://stripe.com/guides/pci-compliance)
- [Integration Security Guide](https://docs.stripe.com/security/guide)

### Flutter Stripe Resources

- [flutter_stripe Package](https://pub.dev/packages/flutter_stripe)
- [Flutter Stripe Documentation](https://docs.page/flutter-stripe/flutter_stripe)

### Security Tools

- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [GitLeaks](https://github.com/gitleaks/gitleaks)
- [Snyk](https://snyk.io/)
- [npm audit](https://docs.npmjs.com/cli/v8/commands/npm-audit)

### Compliance Resources

- [PCI Security Standards Council](https://www.pcisecuritystandards.org/)
- [PCI DSS Quick Reference Guide](https://www.pcisecuritystandards.org/documents/PCI_DSS_v3-2-1_QRG.pdf)

---

## Conclusion

Implementing Stripe securely requires attention to multiple layers of security:

1. **API Key Management:** Use the right keys in the right places, rotate regularly, and never expose secrets.

2. **Webhook Verification:** Always verify signatures to prevent fake events from compromising your system.

3. **Environment Separation:** Keep test and production completely separate with different keys and configurations.

4. **PCI Compliance:** Use Stripe Elements/Checkout to minimize your compliance burden.

5. **Secure Coding:** Validate inputs, handle errors properly, and never store prohibited data.

By following the practices outlined in this guide, you'll build a secure, compliant payment integration that protects both your business and your customers.

**Remember:** Security is not a one-time task—it requires ongoing vigilance, regular updates, and continuous monitoring.

---

**Document Version:** 1.0
**Last Updated:** December 23, 2025
**Author:** Generated from Official Stripe Documentation and Security Best Practices
