# Security Configuration Guide

## Overview

This document describes the secure configuration of Everyday Christian app's environment variables, API keys, and sensitive data.

**SECURITY CRITICAL:** Follow these guidelines to prevent:
- API key exposure
- Unauthorized access
- Data breaches
- Fake webhook attacks
- Account takeover

---

## Quick Start

### 1. Initial Setup

```bash
# Copy template
cp .env.example .env

# Edit .env and fill in real values
# NEVER commit .env to git!
```

### 2. Validate Configuration

Add to `lib/main.dart`:

```dart
import 'package:everyday_christian/core/config/env_validator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment
  await dotenv.load();

  // Validate configuration (will throw if issues found)
  EnvValidator.validate();

  runApp(MyApp());
}
```

### 3. Verify Webhooks

When receiving Stripe webhooks, always verify:

```dart
import 'package:everyday_christian/core/security/stripe_webhook_verifier.dart';

Future<Response> handleWebhook(Request request) async {
  try {
    // Verify signature (CRITICAL - prevents fake webhooks!)
    final event = StripeWebhookVerifier.verifyAndParse(
      payload: await request.body,
      signature: request.headers['stripe-signature']!,
    );

    // Process verified webhook
    switch (event['type']) {
      case 'customer.subscription.created':
        // Handle subscription...
        break;
    }

    return Response.ok('');
  } on WebhookVerificationException catch (e) {
    print('Invalid webhook: $e');
    return Response(400);
  }
}
```

---

## Environment Variables

### APP_ENV

**Purpose:** Identifies the environment
**Values:** `development`, `staging`, `production`
**Security:** Prevents accidental use of production keys in development

```bash
APP_ENV=development  # Use in development
APP_ENV=staging      # Use in staging
APP_ENV=production   # Use in production ONLY
```

### Key Rotation Dates

**Purpose:** Track when API keys were last rotated
**Rotation Schedule:** Every 90 days
**Action:** Update these dates when rotating keys

```bash
LAST_KEY_ROTATION_DATE=2025-01-23
NEXT_KEY_ROTATION_DATE=2025-04-23
```

**Important:** The env validator will warn you when keys are due for rotation!

---

## Stripe Configuration

### STRIPE_SECRET_KEY

**Security Level:** 🔴 CRITICAL - NEVER expose in client code!

**Formats:**
- Development: `sk_test_...` (secret key) or `rk_test_...` (restricted key)
- Production: `rk_live_...` (restricted key ONLY)

**Best Practice:** Use restricted keys in production with minimum permissions:
- Products: Read + Write
- Prices: Read + Write
- Customers: Read + Write
- Subscriptions: Read + Write
- Payment Links: Read + Write

**Create Restricted Key:**
1. Go to: https://dashboard.stripe.com/test/apikeys (Test Mode)
2. Click "Create restricted key"
3. Name it: "Everyday Christian - Backend"
4. Enable ONLY the permissions listed above
5. Copy the `rk_test_...` key

### STRIPE_PUBLISHABLE_KEY

**Security Level:** 🟡 Safe for client-side use

**Formats:**
- Development: `pk_test_...`
- Production: `pk_live_...`

**Usage:** Can be safely embedded in Flutter app

### STRIPE_WEBHOOK_SECRET

**Security Level:** 🔴 CRITICAL - Required for webhook verification!

**Format:** `whsec_...`

**Purpose:** Verifies webhook authenticity (prevents fake webhooks)

**Setup:**
1. Go to: https://dashboard.stripe.com/test/webhooks
2. Click "Add endpoint"
3. Enter your Activepieces webhook URL
4. Select events:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Copy the **Signing secret** (starts with `whsec_`)
6. Add to `.env`

**CRITICAL:** Always verify webhook signatures using `StripeWebhookVerifier`!

---

## Activepieces Configuration

### ACTIVEPIECES_MCP_URL

**Security Level:** 🟡 Medium - URL is semi-public

**Format:** `https://cloud.activepieces.com/api/v1/projects/{PROJECT_ID}/mcp-server/http`

**Security:** Must use HTTPS

### ACTIVEPIECES_TOKEN

**Security Level:** 🔴 CRITICAL - Backend only!

**Security Features:**
- 256-bit encryption in Activepieces
- Cannot be retrieved once set
- Use different tokens for dev/staging/production

**Permissions:** Minimum required:
- Read flows
- Execute flows

**Rotation:** Every 90 days

### ACTIVEPIECES_WEBHOOK_SECRET

**Security Level:** 🔴 CRITICAL (if using HMAC verification)

**Purpose:** Verify webhook authenticity from Activepieces

**Implementation:** See `ACTIVEPIECES_SECURITY_BEST_PRACTICES.md` for HMAC setup

---

## Security Validation

### Automatic Validation

The `EnvValidator` class automatically checks:
- ✅ All required keys are present
- ✅ No placeholder values (YOUR_KEY_HERE)
- ✅ Correct key formats (pk_test_, sk_test_, etc.)
- ✅ Production uses live keys only
- ✅ Development uses test keys
- ✅ HTTPS for all webhook URLs
- ✅ Key rotation dates
- ✅ Webhook secrets configured

### Manual Validation

```bash
# Run the app - validator runs automatically on startup
flutter run

# Check for validation errors in console:
# ✅ Environment configuration validated successfully
# OR
# ❌ Environment configuration validation failed:
# ❌ STRIPE_SECRET_KEY is using placeholder value
# ⚠️  Warning: API keys need rotation in 5 days
```

### Production Deployment Validation

Before deploying to production:

```dart
// In your deployment script/CI
EnvValidator.validateProduction();
```

This ensures:
- APP_ENV=production
- No test keys
- All production keys configured

---

## Key Rotation

### When to Rotate

**Schedule:** Every 90 days

**Triggers:**
- Regular 90-day schedule
- Key exposure (immediate)
- Team member leaves
- Security audit finding

### How to Rotate

**Stripe Keys:**
1. Create new restricted key in Stripe dashboard
2. Update `.env` with new key
3. Deploy to production
4. Wait 24 hours for old key usage to drop
5. Delete old key
6. Update rotation dates in `.env`

**Activepieces Token:**
1. Generate new token in Activepieces
2. Update `.env`
3. Restart services
4. Delete old token
5. Update rotation dates

**Example:**
```bash
# After rotating keys on 2025-02-15
LAST_KEY_ROTATION_DATE=2025-02-15
NEXT_KEY_ROTATION_DATE=2025-05-15  # 90 days later
```

---

## Common Security Issues

### ❌ WRONG: Exposing Secret Keys

```dart
// NEVER do this!
const stripeKey = 'sk_test_51Sef...'; // Hardcoded
final response = await http.post(
  '/charge',
  body: {'stripe_key': stripeKey},  // Sent to client!
);
```

### ✅ CORRECT: Keep Keys Server-Side

```dart
// Keys stay on backend
// Flutter app only sends payment intent ID
final response = await http.post(
  '/create-payment-intent',
  body: {'amount': 499},
);
```

### ❌ WRONG: Not Verifying Webhooks

```dart
// DANGEROUS - Anyone can send fake webhooks!
Future<void> handleWebhook(Map event) async {
  if (event['type'] == 'customer.subscription.created') {
    await grantPremiumAccess(event['customer']);  // EXPLOITABLE!
  }
}
```

### ✅ CORRECT: Always Verify Signatures

```dart
Future<void> handleWebhook(String body, String signature) async {
  // Verify signature FIRST
  final event = StripeWebhookVerifier.verifyAndParse(
    payload: body,
    signature: signature,
  );

  // Now safe to process
  if (event['type'] == 'customer.subscription.created') {
    await grantPremiumAccess(event['customer']);
  }
}
```

### ❌ WRONG: Using Test Keys in Production

```bash
# In production .env
APP_ENV=production
STRIPE_SECRET_KEY=sk_test_...  # WRONG! Won't charge real cards!
```

### ✅ CORRECT: Production Uses Live Keys

```bash
# In production .env
APP_ENV=production
STRIPE_SECRET_KEY=rk_live_...  # Correct restricted live key
STRIPE_PUBLISHABLE_KEY=pk_live_...
```

---

## Incident Response

### If API Key is Exposed

**Immediate Actions (within 1 hour):**

1. **Delete the exposed key immediately**
   - Stripe: Dashboard → API Keys → Delete
   - Activepieces: Regenerate token

2. **Generate new key**
   - Follow key creation steps above
   - Use different key with new restrictions

3. **Update .env and deploy**
   ```bash
   # Update .env
   STRIPE_SECRET_KEY=rk_test_NEW_KEY_HERE

   # Deploy immediately
   flutter build web --release
   # Deploy to hosting
   ```

4. **Monitor for unauthorized usage**
   - Stripe: Dashboard → Developers → Logs
   - Activepieces: Audit logs

5. **Update rotation date**
   ```bash
   LAST_KEY_ROTATION_DATE=2025-01-23  # Today
   NEXT_KEY_ROTATION_DATE=2025-04-23  # 90 days
   ```

**Document Actions (within 24 hours):**
- What was exposed
- When it was exposed
- How it was discovered
- Actions taken
- Lessons learned

**Prevent Future Exposure:**
- Run: `git log -p | grep -i "sk_test_"` (check git history)
- Set up secret scanning: https://github.com/settings/security-analysis
- Add pre-commit hooks to prevent commits with secrets

---

## Security Checklist

### Development

- [ ] `.env` file exists and is in `.gitignore`
- [ ] Using test mode keys (`sk_test_`, `pk_test_`)
- [ ] `APP_ENV=development`
- [ ] Environment validator runs on app startup
- [ ] Webhook signature verification implemented
- [ ] No secrets in git history

### Staging

- [ ] Separate `.env` with staging keys
- [ ] `APP_ENV=staging`
- [ ] Using test mode keys or separate staging keys
- [ ] Webhook endpoints point to staging Activepieces
- [ ] All security validations pass

### Production

- [ ] `APP_ENV=production`
- [ ] Using LIVE restricted keys (`rk_live_`, `pk_live_`)
- [ ] Webhook secret configured
- [ ] HTTPS for all webhooks
- [ ] Production validation passes: `EnvValidator.validateProduction()`
- [ ] Secrets stored in secure secrets manager (AWS Secrets Manager, etc.)
- [ ] Key rotation schedule documented
- [ ] Incident response plan documented
- [ ] Monitoring and alerting configured (Sentry)

---

## Additional Resources

- [STRIPE_SECURITY_BEST_PRACTICES.md](./STRIPE_SECURITY_BEST_PRACTICES.md) - Comprehensive Stripe security guide
- [ACTIVEPIECES_SECURITY_BEST_PRACTICES.md](./ACTIVEPIECES_SECURITY_BEST_PRACTICES.md) - Activepieces security guide
- [Stripe Security Docs](https://stripe.com/docs/security)
- [Stripe Webhook Signatures](https://stripe.com/docs/webhooks/signatures)
- [Activepieces Security](https://www.activepieces.com/docs/security)

---

## Support

If you discover a security vulnerability:
1. **DO NOT** open a public GitHub issue
2. Email security@yourdomain.com (if available)
3. Or contact maintainers privately

---

**Last Updated:** 2025-01-23
**Next Review:** 2025-04-23
