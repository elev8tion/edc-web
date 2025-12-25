# Trial Abuse Prevention for PWA - Strategy Document

> **Critical Issue**: Current trial abuse prevention uses FlutterSecureStorage (Keychain/KeyStore) which **does NOT work on PWA**. Web browsers can easily clear storage, use incognito mode, or switch browsers to get unlimited trials.

---

## Table of Contents
1. [Current System Analysis](#current-system-analysis)
2. [PWA-Specific Vulnerabilities](#pwa-specific-vulnerabilities)
3. [Solution Options](#solution-options)
4. [Recommended Approach](#recommended-approach)
5. [Implementation Plan](#implementation-plan)
6. [Trade-offs Analysis](#trade-offs-analysis)

---

## Current System Analysis

### What You Have (Works for Native Apps Only)

```dart
// From subscription_service.dart:76-86
static const String _keychainTrialEverUsed = 'trial_ever_used_keychain';
static const String _keychainTrialMarkedDate = 'trial_marked_date_keychain';

// Secure storage for trial abuse prevention (survives app uninstall)
final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```

**How it works on iOS/Android:**
- Stores trial usage in device Keychain (iOS) or KeyStore (Android)
- Survives app uninstall/reinstall
- Tied to device hardware
- Cannot be easily cleared by user

**Why it FAILS on PWA:**
- PWA uses SharedPreferences → maps to `localStorage`/`IndexedDB`
- Browser data can be cleared in settings
- Incognito mode = fresh storage every session
- Different browsers = different storage
- No concept of "Keychain" on web

### Current Trial Model
- **Duration**: 3 days OR 15 messages (whichever comes first)
- **Tracking**: Device-level only (no server, no email, no account)
- **Privacy-First**: All data stays on device

---

## PWA-Specific Vulnerabilities

### Easy Exploits (No Technical Knowledge Required)

1. **Clear Browser Data**
   ```
   User Action: Chrome → Settings → Clear browsing data → Cached images and files
   Result: Trial resets, user gets another 15 messages
   Time Required: 10 seconds
   ```

2. **Incognito/Private Mode**
   ```
   User Action: Open PWA in incognito window
   Result: Fresh trial every time
   Time Required: 5 seconds
   ```

3. **Switch Browsers**
   ```
   User Action: Use trial in Chrome, then Safari, then Firefox
   Result: 3 separate trials (45 messages total)
   Time Required: 30 seconds
   ```

4. **Different Devices**
   ```
   User Action: Use PWA on phone, tablet, laptop
   Result: 3 separate trials
   Time Required: 1 minute
   ```

### Advanced Exploits (Requires Some Technical Knowledge)

5. **IndexedDB Manipulation**
   ```javascript
   // User can open browser console and run:
   indexedDB.deleteDatabase('flutter_web_app');
   localStorage.clear();
   sessionStorage.clear();
   ```

6. **Browser Extensions**
   - Cookie/storage cleaner extensions can auto-reset trial
   - VPN extensions can rotate IP addresses

7. **Virtual Machines**
   - Run PWA in disposable VMs for unlimited trials

---

## Solution Options

### Option 1: Email-Gated Trial (Simple, Effective)
**How It Works:**
1. User must enter email to start trial
2. Backend checks if email has been used before
3. Trial code sent to email (like paid subscriptions)
4. One trial per email address

**Implementation:**
```typescript
// Add to landing page or PWA onboarding
interface TrialRequest {
  email: string;
}

// New Cloudflare Worker endpoint
POST /api/trial/request
Body: { email: "user@example.com" }

// Worker logic:
1. Validate email format
2. Check NoCodeBackend if email already used trial
3. If new: Generate trial code (T-XXX-XXX)
4. Store in database: { email, code, createdAt, used: false }
5. Send email with trial code
6. User enters code in PWA to activate trial

// Database schema (NoCodeBackend table: trial_codes)
{
  email: string,
  code: string,
  createdAt: timestamp,
  used: boolean,
  deviceId: string (when activated),
  activatedAt: timestamp
}
```

**Pros:**
- ✅ Simple to implement (reuse existing code generation logic)
- ✅ Requires minimal user friction (just email)
- ✅ Prevents most abuse (creating fake emails requires effort)
- ✅ Builds email list for marketing
- ✅ Can send trial expiry reminders and conversion emails
- ✅ Works across all platforms (PWA, iOS, Android)

**Cons:**
- ❌ Requires backend tracking (violates "privacy-first" principle slightly)
- ❌ Users can create multiple email addresses (Gmail+1@gmail.com, etc.)
- ❌ Adds friction (must enter email before trying app)

**Abuse Potential:** Medium (requires creating multiple emails)

---

### Option 2: Device Fingerprinting (No Email Required)
**How It Works:**
1. Generate unique device fingerprint from browser characteristics
2. Store fingerprint hash in backend when trial starts
3. Check fingerprint against database on each app load

**Implementation:**
```typescript
// Use FingerprintJS or similar library
import FingerprintJS from '@fingerprintjs/fingerprintjs';

async function getDeviceFingerprint(): Promise<string> {
  const fp = await FingerprintJS.load();
  const result = await fp.get();
  return result.visitorId; // Unique hash based on:
  // - Canvas fingerprint
  // - WebGL renderer
  // - Audio fingerprint
  // - Screen resolution
  // - Timezone
  // - Language
  // - Plugins
  // - Fonts
  // - Many other factors
}

// On trial start:
const fingerprint = await getDeviceFingerprint();
await fetch('/api/trial/check', {
  method: 'POST',
  body: JSON.stringify({ fingerprint })
});

// Backend checks if fingerprint exists in database
// If new: Allow trial, store fingerprint
// If exists: Block trial
```

**Pros:**
- ✅ No email required (zero friction)
- ✅ Works across browser sessions
- ✅ Harder to bypass than simple storage clearing
- ✅ Maintains "privacy-first" approach (no PII collected)

**Cons:**
- ❌ Not 100% reliable (fingerprints can change with browser updates)
- ❌ VPN/incognito can still change fingerprint
- ❌ Privacy concerns (some users/regulators dislike fingerprinting)
- ❌ Requires third-party library ($99/month for FingerprintJS Pro)
- ❌ Can have false positives (same device, different fingerprint)

**Abuse Potential:** Medium (requires technical knowledge to bypass)

---

### Option 3: IP Address + Time Window Limiting
**How It Works:**
1. Track trials by IP address + timestamp
2. Allow max 1-2 trials per IP per month
3. No account or email required

**Implementation:**
```typescript
// On trial start:
const ipAddress = request.headers.get('CF-Connecting-IP'); // Cloudflare provides this
const ipHash = await crypto.subtle.digest('SHA-256',
  new TextEncoder().encode(ipAddress)
);

// Check database:
SELECT COUNT(*) FROM trials
WHERE ip_hash = ?
AND created_at > NOW() - INTERVAL 30 DAYS;

// If count < 2: Allow trial
// If count >= 2: Block trial
```

**Pros:**
- ✅ Zero friction for users
- ✅ Simple to implement
- ✅ Privacy-friendly (hash IP, don't store raw)
- ✅ Catches casual abuse (same household/network)

**Cons:**
- ❌ False positives (shared IPs like coffee shops, libraries, corporate networks)
- ❌ Easily bypassed with VPN or mobile data toggle
- ❌ May block legitimate users in same household
- ❌ Dynamic IPs change frequently (especially mobile)

**Abuse Potential:** High (VPN makes this useless)

---

### Option 4: Social Login Gating (Most Secure)
**How It Works:**
1. Require Google/Apple sign-in to access trial
2. One trial per social account
3. Track trial by OAuth sub (user ID from Google/Apple)

**Implementation:**
```typescript
// Use Supabase Auth (already have Supabase in landing page)
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(supabaseUrl, supabaseKey);

// Sign in with Google
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
});

// After auth, get user ID
const { data: { user } } = await supabase.auth.getUser();
const userId = user.sub; // Unique OAuth ID

// Check trial usage:
SELECT * FROM trials WHERE user_id = ?;
// If exists: Block trial
// If new: Allow trial
```

**Pros:**
- ✅ Most secure (hard to create multiple Google/Apple accounts)
- ✅ Enables future features (cloud sync, cross-device)
- ✅ Professional UX (standard for modern apps)
- ✅ One trial per social account (very effective)
- ✅ Can offer longer trial for verified accounts

**Cons:**
- ❌ Highest friction (requires account creation/login)
- ❌ May reduce trial conversion (some users avoid social login)
- ❌ Requires authentication infrastructure
- ❌ Privacy concerns for some users

**Abuse Potential:** Low (creating multiple Google accounts is difficult)

---

### Option 5: Hybrid Multi-Layer Approach (Recommended)
**How It Works:**
Combine multiple techniques for maximum protection while balancing UX.

**Tier 1: Instant Trial (No Email, Low Protection)**
```
- Use device fingerprint + local storage
- 3 days OR 10 messages (reduced from 15)
- If fingerprint seen before: Offer email-gated trial instead
```

**Tier 2: Email-Gated Trial (Medium Protection)**
```
- User enters email
- Backend sends trial code (T-XXX-XXX)
- 7 days OR 25 messages (better than Tier 1)
- One trial per email
```

**Tier 3: Social Login Trial (High Protection, Best Benefits)**
```
- User signs in with Google/Apple
- 14 days OR 50 messages (best trial offer)
- Cross-device sync enabled
- One trial per social account
```

**Implementation Flow:**
```
User opens PWA
  ↓
Generate device fingerprint
  ↓
Check if fingerprint seen before → Backend
  ↓
  ├─ NEW USER → Offer Tier 1 (instant, 10 messages)
  │
  └─ RETURNING USER → Show modal:
      "Want more trial time? Enter your email for 25 messages"
      ↓
      ├─ Enter Email → Tier 2 (email-gated, 25 messages)
      │
      └─ Sign In with Google → Tier 3 (social, 50 messages)
```

**Pros:**
- ✅ Balances UX and security
- ✅ Rewards users who provide more info (gamification)
- ✅ Progressive friction (only ask for email/login if needed)
- ✅ Catches all levels of abuse
- ✅ Builds email list and user accounts
- ✅ Conversion funnel (instant → email → social → paid)

**Cons:**
- ❌ Most complex to implement
- ❌ Requires all three systems working together
- ❌ More code to maintain

**Abuse Potential:** Very Low (multi-layered defense)

---

## Recommended Approach

### 🏆 Winner: Option 5 (Hybrid Multi-Layer)

**Why:**
1. **Best User Experience**
   - New users get instant access (Tier 1)
   - Power users can opt into longer trials (Tier 2/3)
   - No hard gate for first-time visitors

2. **Best Abuse Prevention**
   - Casual abusers blocked by fingerprint (Tier 1)
   - Determined abusers need email (Tier 2)
   - Sophisticated abusers need Google account (Tier 3)

3. **Business Value**
   - Builds email list for marketing
   - Creates user accounts for future features
   - Conversion funnel analytics (track Tier 1 → Tier 2 → Tier 3 → Paid)

4. **Privacy-Friendly**
   - Tier 1 uses fingerprinting only (no PII)
   - Tier 2/3 opt-in (user chooses to provide email/account)
   - Transparent about data usage

---

## Implementation Plan

### Phase 1: Backend Infrastructure (2-3 hours)

#### 1.1: Create NoCodeBackend Table for Trial Tracking
```
Table: trial_tracking

Fields:
- id (auto-increment)
- fingerprint_hash (string, indexed) - SHA-256 hash
- email (string, nullable, indexed)
- tier (enum: 'instant', 'email', 'social')
- trial_code (string, nullable) - For Tier 2/3
- messages_allowed (integer) - 10, 25, or 50
- messages_used (integer, default 0)
- created_at (timestamp)
- expires_at (timestamp)
- device_id (string, nullable)
- user_id (string, nullable) - OAuth sub for Tier 3
```

#### 1.2: Create Cloudflare Worker Endpoint
**File**: `cloudflare_workers/src/trial-manager.js`

```javascript
// POST /trial/start
// Handles all three tiers
async function handleTrialStart(request) {
  const { fingerprint, tier, email, userId } = await request.json();

  // Check if fingerprint exists
  const existing = await checkFingerprint(fingerprint);

  if (tier === 'instant') {
    if (existing) {
      return json({
        allowed: false,
        message: 'Trial already used. Enter email for extended trial.',
        suggestTier: 'email'
      });
    }

    // Create instant trial
    return createTrial({
      fingerprint,
      tier: 'instant',
      messages: 10,
      days: 3
    });
  }

  if (tier === 'email') {
    // Check if email already used
    const emailUsed = await checkEmail(email);
    if (emailUsed) {
      return json({ allowed: false, message: 'Email already used for trial' });
    }

    // Generate trial code and send email
    const code = generateTrialCode('T');
    await sendTrialEmail(email, code);

    return json({
      allowed: true,
      message: 'Trial code sent to email',
      tier: 'email',
      messages: 25
    });
  }

  if (tier === 'social') {
    // Check if user_id already used
    const userIdUsed = await checkUserId(userId);
    if (userIdUsed) {
      return json({ allowed: false, message: 'Account already used for trial' });
    }

    // Create social trial (best benefits)
    return createTrial({
      userId,
      fingerprint,
      tier: 'social',
      messages: 50,
      days: 14
    });
  }
}
```

---

### Phase 2: PWA Frontend (3-4 hours)

#### 2.1: Add Device Fingerprinting
**File**: `lib/core/services/fingerprint_service.dart`

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

class FingerprintService {
  static Future<String> generateFingerprint() async {
    // Collect browser/device characteristics
    final data = {
      'userAgent': window.navigator.userAgent,
      'language': window.navigator.language,
      'platform': window.navigator.platform,
      'screenResolution': '${window.screen.width}x${window.screen.height}',
      'timezone': DateTime.now().timeZoneOffset.inHours,
      'colorDepth': window.screen.colorDepth,
      // Add more factors for uniqueness
    };

    // Create hash
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }
}
```

#### 2.2: Update Trial Start Logic
**File**: `lib/core/services/subscription_service.dart`

Add new methods:
```dart
// Add after existing trial methods

Future<TrialStartResult> requestTrial({
  String? email,
  String? userId,
  String tier = 'instant',
}) async {
  // Generate fingerprint
  final fingerprint = await FingerprintService.generateFingerprint();

  // Call Cloudflare Worker
  final response = await http.post(
    Uri.parse('https://trial-manager.connect-2a2.workers.dev/trial/start'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'fingerprint': fingerprint,
      'tier': tier,
      'email': email,
      'userId': userId,
    }),
  );

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);

    if (result['allowed']) {
      // Start trial with specified message limit
      await _startTrialWithLimit(
        messages: result['messages'],
        tier: result['tier'],
      );

      return TrialStartResult(
        success: true,
        tier: result['tier'],
        messages: result['messages'],
      );
    } else {
      return TrialStartResult(
        success: false,
        message: result['message'],
        suggestedTier: result['suggestTier'],
      );
    }
  }

  return TrialStartResult(success: false, message: 'Network error');
}

Future<void> _startTrialWithLimit({
  required int messages,
  required String tier,
}) async {
  final now = DateTime.now();
  await _prefs?.setString(_keyTrialStartDate, now.toIso8601String());
  await _prefs?.setInt(_keyTrialMessagesUsed, 0);
  await _prefs?.setInt('trial_messages_limit', messages);
  await _prefs?.setString('trial_tier', tier);

  debugPrint('📊 [SubscriptionService] Started $tier trial with $messages messages');
}

class TrialStartResult {
  final bool success;
  final String? message;
  final String? tier;
  final int? messages;
  final String? suggestedTier;

  TrialStartResult({
    required this.success,
    this.message,
    this.tier,
    this.messages,
    this.suggestedTier,
  });
}
```

#### 2.3: Update Trial UI
**File**: `lib/screens/trial_upgrade_modal.dart` (new file)

```dart
// Modal shown when instant trial is blocked
class TrialUpgradeModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Extend Your Trial'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('You\'ve used your instant trial. Choose an option to continue:'),
          SizedBox(height: 20),

          // Tier 2: Email option
          ElevatedButton(
            onPressed: () => _showEmailInput(context),
            child: Text('Get 25 Messages with Email'),
          ),

          // Tier 3: Social login option
          ElevatedButton(
            onPressed: () => _handleSocialLogin(context),
            child: Text('Get 50 Messages with Google Sign-In'),
          ),

          // Or subscribe
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/subscription'),
            child: Text('Subscribe for Unlimited'),
          ),
        ],
      ),
    );
  }
}
```

---

### Phase 3: Email Trial Flow (1-2 hours)

**Reuse existing email infrastructure:**
- Trial code generation (already exists in `stripe-webhook.js`)
- Email template (already styled with dark navy + yellow)
- NoCodeBackend storage (already configured)

**Only need to add:**
1. New endpoint in Cloudflare Worker for trial email sending
2. Email input form in PWA
3. Trial code validation (similar to paid activation)

---

### Phase 4: Testing (2-3 hours)

#### Test Cases:
- [ ] Tier 1: New user gets instant trial (10 messages)
- [ ] Tier 1: Returning user (same fingerprint) blocked
- [ ] Tier 2: Email trial sends code correctly
- [ ] Tier 2: Duplicate email blocked
- [ ] Tier 2: Trial code validates and grants 25 messages
- [ ] Tier 3: Google sign-in grants 50 messages
- [ ] Tier 3: Same Google account blocked on second attempt
- [ ] Browser data clear → still blocked (fingerprint persists)
- [ ] Incognito mode → blocked if fingerprint matches
- [ ] Different browser → gets new instant trial (expected)
- [ ] Message limits enforced correctly (10/25/50)
- [ ] Trial expiry works for all tiers

---

## Trade-offs Analysis

### Option 1 (Email-Gated) vs Option 5 (Hybrid)

| Factor | Email-Gated (Simple) | Hybrid (Recommended) |
|--------|---------------------|----------------------|
| **Implementation Time** | 4-6 hours | 8-12 hours |
| **User Friction** | Medium (email required upfront) | Low (instant trial first) |
| **Abuse Prevention** | Good (70% reduction) | Excellent (95% reduction) |
| **Email List Building** | Fast | Slower but higher quality |
| **False Positives** | Low | Very low |
| **Conversion Rate** | Medium | High (funnel optimization) |
| **Maintenance** | Low | Medium |
| **Privacy Compliance** | GDPR-friendly | GDPR-friendly with consent |

### Recommendation: Start with Option 1, Upgrade to Option 5

**Phase 1 (Launch):** Email-gated trial only
- Faster to implement
- Proven effective
- Build email list immediately
- Get to market quicker

**Phase 2 (Post-launch):** Add instant trial tier
- Analytics show conversion rates
- Add fingerprinting for Tier 1
- Keep email requirement for Tier 2
- Observe funnel metrics

**Phase 3 (Future):** Add social login tier
- After user base grows
- When cloud sync features needed
- Offer best trial for verified users

---

## Security Considerations

### Rate Limiting
Add rate limits to trial endpoints:
```javascript
// Cloudflare Worker rate limiting
const rateLimiter = new RateLimiter({
  limit: 5, // Max 5 trial requests
  window: 3600, // Per hour
  keyPrefix: 'trial_request',
});

// Check rate limit by IP
const ip = request.headers.get('CF-Connecting-IP');
if (await rateLimiter.isLimited(ip)) {
  return json({ error: 'Too many trial requests. Try again later.' }, 429);
}
```

### Input Validation
```javascript
// Validate email format
function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Block disposable email domains
const disposableDomains = ['tempmail.com', 'guerrillamail.com', ...];
function isDisposableEmail(email) {
  const domain = email.split('@')[1];
  return disposableDomains.includes(domain);
}
```

### Fingerprint Poisoning Prevention
```javascript
// Detect impossible fingerprints (indicates tampering)
function validateFingerprint(data) {
  // Check for unrealistic values
  if (data.screenResolution === '1x1') return false;
  if (data.timezone < -12 || data.timezone > 14) return false;
  if (data.colorDepth < 1 || data.colorDepth > 48) return false;

  return true;
}
```

---

## Cost Analysis

### Email-Gated Trial Only
- NoCodeBackend: Free tier (under 10K records/month)
- EmailIt: $0.001 per email = $1 per 1000 trials
- Cloudflare Workers: Free tier (100K requests/day)
- **Total**: ~$0-$10/month for < 10K trials

### Hybrid with Fingerprinting
- FingerprintJS Open Source: Free (less accurate)
- FingerprintJS Pro: $99/month (99.5% accuracy)
- **Recommendation**: Start with open source, upgrade if abuse detected

### Hybrid with Social Login
- Supabase Auth: Free tier (50K MAU)
- Google OAuth: Free
- **Total**: $0 until 50K users

---

## Privacy & Compliance

### GDPR Compliance
```
✅ Tier 1 (Fingerprint): Legitimate interest, no PII
✅ Tier 2 (Email): Explicit consent required
✅ Tier 3 (Social): OAuth consent flow

Privacy Policy must disclose:
- Device fingerprinting for abuse prevention
- Email storage for trial code delivery
- Trial usage tracking (anonymized)
- User has right to delete data
```

### Data Retention
```sql
-- Delete trial data after 90 days
DELETE FROM trial_tracking
WHERE created_at < NOW() - INTERVAL 90 DAYS;

-- Scheduled job in Cloudflare Worker (runs weekly)
addEventListener('scheduled', event => {
  event.waitUntil(cleanupOldTrials());
});
```

---

## Monitoring & Analytics

### Key Metrics to Track
```typescript
// Track trial funnel
analytics.track('trial_tier1_started', { fingerprint: hash });
analytics.track('trial_tier1_blocked', { reason: 'fingerprint_match' });
analytics.track('trial_tier2_email_submitted', { email: hash });
analytics.track('trial_tier2_code_activated', {});
analytics.track('trial_tier3_google_signin', {});

// Conversion funnel
Tier 1 Start → Tier 1 Complete → Tier 2 Start → Tier 2 Complete → Subscribe
```

### Abuse Detection Dashboard
Monitor for patterns:
- Same fingerprint attempting multiple trials
- Email patterns (test@, temp@, etc.)
- Unusually high trial requests from same IP
- Geographic anomalies (VPN detection)

---

## Next Steps

1. **Decide on approach**:
   - Quick win: Email-gated only (Option 1)
   - Long-term: Hybrid multi-tier (Option 5)

2. **Gather requirements**:
   - Message limits for each tier
   - Trial duration for each tier
   - Email template preferences

3. **Implementation priority**:
   - Week 1: Backend (trial tracking, NoCodeBackend table)
   - Week 2: Frontend (fingerprinting, trial UI)
   - Week 3: Email flow (trial code delivery)
   - Week 4: Testing & refinement

4. **Deployment strategy**:
   - Deploy backend first (Cloudflare Worker)
   - A/B test with 20% of users
   - Monitor abuse rates
   - Gradually roll out to 100%

---

**Questions to Answer:**

1. Which option do you prefer? (1, 5, or another combination?)
2. What message limits feel right for each tier?
3. Do you want to require email immediately or offer instant trial first?
4. Are you okay with device fingerprinting from privacy standpoint?
5. Should we integrate social login now or later?

Let me know your preferences and I can start implementing! 🚀
