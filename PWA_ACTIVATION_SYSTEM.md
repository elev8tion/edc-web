# PWA Activation System Documentation

## Overview
The Everyday Christian PWA uses a **Cloudflare Workers-based activation code system** to enable premium subscriptions without relying on App Store/Play Store in-app purchases.

**System Transition**:
- ❌ **Old**: Activepieces flows (deprecated)
- ✅ **New**: Cloudflare Workers + NoCodeBackend + EmailIt

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                     ACTIVATION CODE FLOW                         │
└─────────────────────────────────────────────────────────────────┘

1. USER PURCHASE (Stripe Checkout)
   └─> Stripe payment successful
       └─> Triggers webhook event: invoice.payment_succeeded

2. CODE GENERATION (Cloudflare Worker #1)
   URL: https://stripe-webhook-handler.connect-2a2.workers.dev
   ├─> Receives Stripe webhook
   ├─> Generates activation code (M-XXX-XXX / Y-XXX-XXX / T-XXX-XXX)
   ├─> Saves to NoCodeBackend database
   ├─> Updates Stripe invoice metadata
   └─> Sends branded email via EmailIt

3. EMAIL DELIVERY (EmailIt)
   ├─> Dark-themed email template (matches landing page)
   ├─> Contains: Activation code, instructions, support links
   └─> Delivered to customer's email

4. CODE ACTIVATION (PWA → Cloudflare Worker #2)
   URL: https://code-validation-api.connect-2a2.workers.dev
   ├─> User enters code in ActivationScreen
   ├─> PWA sends: {code, deviceId}
   ├─> Worker validates code in NoCodeBackend
   ├─> Marks code as used (sets device_id)
   └─> Returns: {valid, tier, subscriptionId, customerId, expiresAt}

5. PREMIUM ACTIVATION (PWA Local Storage)
   ├─> SubscriptionService stores premium status
   ├─> Message limits updated (150/month)
   ├─> User redirected to home screen
   └─> Premium features unlocked
```

---

## Cloudflare Workers

### Worker 1: Stripe Webhook Handler

**URL**: `https://stripe-webhook-handler.connect-2a2.workers.dev`
**File**: `cloudflare_workers/src/stripe-webhook.js`

**Responsibilities**:
1. Receive Stripe `invoice.payment_succeeded` webhooks
2. Generate activation code based on subscription tier:
   - Monthly → `M-XXX-XXX`
   - Yearly → `Y-XXX-XXX`
   - Trial/Unknown → `T-XXX-XXX`
3. Save code to NoCodeBackend:
   ```json
   {
     "code": "M-ABC-123",
     "customer_id": "cus_xxx",
     "subscription_id": "sub_xxx",
     "tier": "monthly"
   }
   ```
4. Update Stripe invoice metadata with activation code
5. Send branded email to customer

**Environment Variables**:
- `NOCODEBACKEND_API_KEY`
- `STRIPE_API_KEY`
- `MONTHLY_PRICE_ID`
- `YEARLY_PRICE_ID`
- `EMAILIT_API_KEY` (optional for email sending)

**Code Format**:
```javascript
const prefix = tier === 'monthly' ? 'M' : tier === 'yearly' ? 'Y' : 'T';
const randomPart = generateRandomCode(6); // ABCDEFGHJKLMNPQRSTUVWXYZ23456789
const activationCode = `${prefix}-${randomPart.slice(0,3)}-${randomPart.slice(3,6)}`;
// Example: M-AB3-D4F
```

---

### Worker 2: Code Validation API

**URL**: `https://code-validation-api.connect-2a2.workers.dev`
**File**: `cloudflare_workers/src/code-validation.js`

**Responsibilities**:
1. Validate activation code exists in NoCodeBackend
2. Check if code is already used (device_id !== null)
3. Check expiration date (if set)
4. Mark code as used by setting device_id
5. Return subscription details to PWA

**Request Format**:
```json
{
  "code": "M-ABC-123",
  "deviceId": "1703456789123_567890"
}
```

**Response Format (Success)**:
```json
{
  "valid": true,
  "tier": "monthly",
  "subscriptionId": "sub_xxx",
  "customerId": "cus_xxx",
  "expiresAt": "2026-12-25T12:20:00.000Z"
}
```

**Response Format (Failure)**:
```json
{
  "valid": false,
  "error": "Invalid activation code"
}
```

**Error Types**:
- `"Invalid activation code"` - Code not found in database
- `"Code already used on another device"` - device_id already set
- `"Code has expired"` - Past expiry date (if enforced)

---

## NoCodeBackend Database

### Instance Details
- **Instance ID**: `36905_activation_codes`
- **Table**: `activation_codes`
- **API Base**: `https://api.nocodebackend.com`
- **Authentication**: Bearer token

### Schema

| Field | Type | Description | Set By |
|-------|------|-------------|--------|
| `id` | Integer | Auto-increment primary key | NoCodeBackend |
| `code` | String | Activation code (M-XXX-XXX) | Worker 1 |
| `customer_id` | String | Stripe customer ID | Worker 1 |
| `subscription_id` | String | Stripe subscription ID | Worker 1 |
| `tier` | String | monthly, yearly, trial | Worker 1 |
| `status` | String | ⚠️ Cannot set (validation error) | - |
| `expires_at` | DateTime | ⚠️ Cannot set (validation error) | - |
| `used_at` | DateTime | ⚠️ Cannot set (validation error) | - |
| `device_id` | String | UUID when code is activated | Worker 2 |

### API Endpoints

**Create Code** (Worker 1):
```http
POST https://api.nocodebackend.com/create/activation_codes?Instance=36905_activation_codes
Authorization: Bearer {token}
Content-Type: application/json

{
  "code": "M-ABC-123",
  "customer_id": "cus_xxx",
  "subscription_id": "sub_xxx",
  "tier": "monthly"
}
```

**Read Code** (Worker 2):
```http
GET https://api.nocodebackend.com/read/activation_codes?Instance=36905_activation_codes&code=M-ABC-123
Authorization: Bearer {token}
```

**Update Code** (Worker 2 - Mark as Used):
```http
PUT https://api.nocodebackend.com/update/activation_codes/{id}?Instance=36905_activation_codes
Authorization: Bearer {token}
Content-Type: application/json

{
  "device_id": "test-device-123"
}
```

### Known Limitations

⚠️ **Schema Validation Issues**:
- Fields `status`, `expires_at`, `used_at` cause validation errors when set during creation
- **Workaround**: Only store core fields during creation, track usage via `device_id !== null`
- **Impact**: Medium - manual status tracking, no automatic expiry enforcement

---

## PWA Integration

### File Structure

```
lib/
├── core/
│   ├── services/
│   │   └── subscription_service.dart     # Main subscription logic
│   └── providers/
│       └── subscription_providers.dart   # Riverpod providers
└── screens/
    └── activation_screen.dart            # User activation UI
```

### SubscriptionService

**File**: `lib/core/services/subscription_service.dart`

**Key Methods**:

#### `activateWithCode(String code)`
Validates activation code and activates premium subscription.

```dart
Future<ActivationResult> activateWithCode(String code) async {
  // 1. Generate/retrieve device ID
  final deviceId = await _getOrCreateDeviceId();

  // 2. Call Cloudflare Worker validation endpoint
  final validationUrl = dotenv.get('CODE_VALIDATION_URL', fallback: '');
  final response = await http.post(
    Uri.parse(validationUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'code': code, 'deviceId': deviceId}),
  ).timeout(Duration(seconds: 10));

  // 3. Parse response
  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);

    if (result['valid'] == true) {
      // 4. Activate subscription locally
      await _activateSubscriptionFromCode(
        tier: result['tier'],
        subscriptionId: result['subscriptionId'],
        customerId: result['customerId'],
        expiresAt: DateTime.parse(result['expiresAt']),
        activationCode: code,
      );

      return ActivationResult(success: true, message: 'Premium activated!');
    }
  }

  return ActivationResult(success: false, message: 'Invalid code');
}
```

#### `_getOrCreateDeviceId()`
Generates unique device identifier for one-code-per-device enforcement.

```dart
Future<String> _getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  var deviceId = prefs.getString('device_id');

  if (deviceId == null) {
    // Generate pseudo-UUID from timestamps
    deviceId = DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        DateTime.now().microsecondsSinceEpoch.toString().substring(7);
    await prefs.setString('device_id', deviceId);
  }

  return deviceId; // Example: "1703456789123_567890"
}
```

#### `_activateSubscriptionFromCode()`
Stores premium subscription locally in SharedPreferences.

```dart
Future<void> _activateSubscriptionFromCode({
  required String tier,
  required String subscriptionId,
  required String customerId,
  required DateTime expiresAt,
  required String activationCode,
}) async {
  await _prefs?.setBool(_keyPremiumActive, true);
  await _prefs?.setString(_keyPremiumExpiryDate, expiresAt.toIso8601String());
  await _prefs?.setString(_keySubscriptionReceipt, subscriptionId);
  await _prefs?.setString(_keyPurchasedProductId,
      tier === 'monthly' ? premiumMonthlyProductId : premiumYearlyProductId);

  // Reset message counters
  await _prefs?.setInt(_keyPremiumMessagesUsed, 0);
  await _prefs?.setString(_keyPremiumLastResetDate,
      DateTime.now().toIso8601String().substring(0, 7));
}
```

---

### ActivationScreen

**File**: `lib/screens/activation_screen.dart`

**Features**:
1. Code input with format validation (regex)
2. Paste from clipboard button
3. Loading state during validation
4. Error display (red box)
5. Success feedback (green SnackBar)
6. Auto-navigation to /home on success
7. Deep link support (prefilled code)

**Code Format Validation**:
```dart
// Client-side regex validation
final codePattern = RegExp(r'^[MTYA]-[A-Z0-9]{3}-[A-Z0-9]{3}$');
if (!codePattern.hasMatch(value.trim().toUpperCase())) {
  return 'Invalid code format (should be like M-ABC-123)';
}
```

**Usage**:
```dart
// Navigate to activation screen
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ActivationScreen(),
));

// With prefilled code from URL
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ActivationScreen(
    prefilledCode: 'M-ABC-123',
  ),
));
```

---

### Subscription Providers

**File**: `lib/core/providers/subscription_providers.dart`

**Available Providers**:
```dart
// Main service instance
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService.instance;
});

// Subscription status
final subscriptionStatusProvider = Provider<SubscriptionStatus>((ref) { ... });

// Premium status
final isPremiumProvider = Provider<bool>((ref) { ... });

// Message limits
final remainingMessagesProvider = Provider<int>((ref) { ... });
final messagesUsedProvider = Provider<int>((ref) { ... });

// Trial status
final isInTrialProvider = Provider<bool>((ref) { ... });
final hasTrialExpiredProvider = Provider<bool>((ref) { ... });
final trialDaysRemainingProvider = Provider<int>((ref) { ... });
```

**Usage in UI**:
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final remainingMessages = ref.watch(remainingMessagesProvider);

    return Text(isPremium
        ? 'Premium: $remainingMessages messages left'
        : 'Trial mode');
  }
}
```

---

## Environment Configuration

### Required Environment Variables

**PWA `.env` file**:
```env
# Code Validation Endpoint
CODE_VALIDATION_URL=https://code-validation-api.connect-2a2.workers.dev
```

**Cloudflare Workers `wrangler.toml`** (not committed to git):
```toml
[vars]
NOCODEBACKEND_API_KEY = "your_nocodebackend_api_key_here"
STRIPE_API_KEY = "sk_test_your_stripe_test_api_key_here"
EMAILIT_API_KEY = "em_your_emailit_api_key_here"
MONTHLY_PRICE_ID = "price_your_monthly_price_id_here"
YEARLY_PRICE_ID = "price_your_yearly_price_id_here"
```

---

## Email System

### EmailIt Configuration

**Service**: EmailIt (emailit.com)
**API Key**: Stored in Cloudflare Workers env
**From Address**: `Everyday Christian <connect@everydaychristian.app>`
**Domain**: everydaychristian.app
**Quota**: 50,000 emails/month

### Email Template

**Design**:
- Dark background (#1a1b2e, #0f0f1e) matching landing page
- Yellow CTA-style activation code box (#FDB022)
- Clean, minimal layout
- SVG logo (sunrise + open Bible)
- Mobile responsive

**Content**:
1. Header: "Subscription Activated!" with logo
2. Greeting: "Thank you for subscribing"
3. **Activation Code**: Large yellow box with code
4. Instructions: 4-step activation process
5. Important tip: Save email for reinstalls
6. Footer: Support email and copyright

**Example HTML** (simplified):
```html
<div style="background: #1a1b2e;">
  <!-- Activation Code Box -->
  <div style="background: #FDB022; padding: 32px; border-radius: 8px;">
    <p style="font-size: 12px; color: #1a1b2e;">YOUR ACTIVATION CODE</p>
    <div style="font-size: 36px; font-weight: 700; color: #1a1b2e;">
      M-ABC-123
    </div>
  </div>

  <!-- Instructions -->
  <ol>
    <li>Open Everyday Christian app</li>
    <li>Go to Settings → Activate Premium</li>
    <li>Enter code: M-ABC-123</li>
    <li>Start using 150 monthly messages</li>
  </ol>
</div>
```

---

## Security Considerations

### Code Generation Security
- **Randomness**: Uses `Math.random()` (sufficient for activation codes, not cryptographic)
- **Character Set**: Excludes ambiguous characters (I, O, 0, 1)
- **Format**: Easy to read/type (X-XXX-XXX)

### Code Validation Security
- **One-Time Use**: Code can only be activated once (device_id tracking)
- **Device Binding**: Code tied to specific device
- **No Brute Force**: Random 36^6 combinations (~2 billion)
- **Timeout**: 10-second API timeout
- **HTTPS**: All endpoints use HTTPS
- **CORS**: Validation endpoint allows all origins (public API)

### Potential Vulnerabilities

1. **No Rate Limiting**:
   - **Risk**: Brute force code guessing
   - **Mitigation**: Statistical improbability (~2B combinations)
   - **Recommendation**: Add Cloudflare rate limiting (100 req/hr per IP)

2. **No Webhook Signature Verification**:
   - **Risk**: Fake webhook events generating codes
   - **Mitigation**: Webhook URL is secret
   - **Recommendation**: Add Stripe signature verification

3. **Public Validation Endpoint**:
   - **Risk**: Anyone can attempt code validation
   - **Mitigation**: Codes are single-use, hard to guess
   - **Recommendation**: Acceptable for current scale

---

## Monitoring & Analytics

### Recommended Tracking

**Cloudflare Workers Analytics**:
- Request count per worker
- Error rate
- Response time
- Geographic distribution

**Custom Events to Track**:
```javascript
// In PWA
analytics.logEvent('activation_attempt', { code_prefix: 'M' });
analytics.logEvent('activation_success', { tier: 'monthly' });
analytics.logEvent('activation_failure', { error: 'invalid_code' });
```

**Key Metrics**:
- Activation success rate (target: >95%)
- Average time from email to activation (target: <5 minutes)
- Device reactivation rate (indicates code sharing)
- Email deliverability rate (target: >99%)

---

## Troubleshooting

### Common Issues

#### 1. "Activation service not configured"
**Cause**: `CODE_VALIDATION_URL` missing from `.env`
**Fix**: Add `CODE_VALIDATION_URL=https://code-validation-api.connect-2a2.workers.dev`

#### 2. "Failed to validate code (500)"
**Cause**: NoCodeBackend API error or Worker exception
**Debug**:
```bash
# Check Worker logs
wrangler tail code-validation-api

# Test Worker directly
curl -X POST https://code-validation-api.connect-2a2.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"code":"M-ABC-123","deviceId":"test-device"}'
```

#### 3. "Code already used on another device"
**Cause**: Code previously activated on different device
**Fix**: User needs to purchase new subscription or contact support

#### 4. Email not received
**Causes**:
- Spam folder
- Email typo
- EmailIt quota exceeded
- DNS/SPF issues

**Debug**:
- Check EmailIt dashboard for delivery status
- Verify domain DNS records (SPF, DKIM)
- Test with different email provider

---

## Migration from Activepieces

### Changes Made

**Environment Variables**:
- ❌ Removed: `ACTIVEPIECES_CODE_VALIDATION_URL`
- ✅ Added: `CODE_VALIDATION_URL`

**Code Changes**:
- `subscription_service.dart:979`: Updated env variable name
- `.env.example`: Added Cloudflare Workers section

**Data Migration**:
- No data migration needed (fresh codes generated going forward)
- Old Activepieces codes (if any) can coexist but won't be validated

### Rollback Procedure

If needed to revert to Activepieces:

1. Update `.env`:
   ```env
   CODE_VALIDATION_URL=https://cloud.activepieces.com/api/v1/webhooks/YOUR_VALIDATION_WEBHOOK
   ```

2. No code changes needed (same API format)

3. Ensure Activepieces flow is still active

---

## Future Enhancements

### Short Term (1-3 months)
- [ ] Add code expiry enforcement in validation worker
- [ ] Implement Cloudflare rate limiting
- [ ] Add webhook signature verification
- [ ] Create admin dashboard for code management

### Medium Term (3-6 months)
- [ ] Code revocation feature
- [ ] Family sharing (multiple devices per code)
- [ ] Referral code system
- [ ] Usage analytics tracking

### Long Term (6-12 months)
- [ ] Auto-renewal integration with Stripe
- [ ] Grace period handling
- [ ] Subscription pause/resume
- [ ] Multi-tier support (add more plans)

---

## Support & Contact

**Technical Issues**:
- GitHub: https://github.com/elev8tion/edc-web/issues
- Email: dev@everydaychristian.app

**Customer Support**:
- Email: connect@everydaychristian.app
- Response Time: 24-48 hours

**API Documentation**:
- NoCodeBackend: https://nocodebackend.com/docs
- EmailIt: https://emailit.com/docs
- Cloudflare Workers: https://developers.cloudflare.com/workers

---

**Last Updated**: 2025-12-24
**Version**: 1.0
**Status**: Production Ready
**Maintained By**: Development Team
