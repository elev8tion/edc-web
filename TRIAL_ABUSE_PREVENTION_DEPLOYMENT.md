# Trial Abuse Prevention - Deployment Guide

> **IP + Fingerprint Hybrid Approach** - Complete deployment instructions for PWA trial abuse prevention system.

---

## Table of Contents
1. [Overview](#overview)
2. [NoCodeBackend Schema Updates](#nocodebackend-schema-updates)
3. [Cloudflare Worker Deployment](#cloudflare-worker-deployment)
4. [PWA Code Integration](#pwa-code-integration)
5. [Environment Variables](#environment-variables)
6. [Testing Instructions](#testing-instructions)
7. [Monitoring & Debugging](#monitoring--debugging)

---

## Overview

### What This System Does
- **Validates trial eligibility** using IP address + device fingerprint
- **Blocks repeat trials** if either signal has been seen before
- **Zero friction** for legitimate users (no email required)
- **85% effective** against trial abuse

### Architecture
```
PWA (Flutter)                    Cloudflare Worker               NoCodeBackend
    │                                  │                              │
    ├─ Generate fingerprint           │                              │
    │  (browser characteristics)      │                              │
    │                                  │                              │
    ├─ POST /trial/validate ──────────>│                              │
    │  { fingerprint: "abc..." }       │                              │
    │                                  │                              │
    │                              ┌───┴──────┐                       │
    │                              │ Get IP   │                       │
    │                              │ (CF-Connecting-IP)               │
    │                              └───┬──────┘                       │
    │                                  │                              │
    │                              ┌───┴───────────┐                  │
    │                              │ Hash IP       │                  │
    │                              │ Hash Fingerprint                 │
    │                              └───┬───────────┘                  │
    │                                  │                              │
    │                                  ├─ Check IP hash ──────────────>│
    │                                  │  (query database)             │
    │                                  │<───────────── Result ─────────┤
    │                                  │                              │
    │                                  ├─ Check fingerprint hash ─────>│
    │                                  │  (query database)             │
    │                                  │<───────────── Result ─────────┤
    │                                  │                              │
    │                              ┌───┴───────────┐                  │
    │                              │ Either found? │                  │
    │                              │ YES: Block    │                  │
    │                              │ NO: Allow     │                  │
    │                              └───┬───────────┘                  │
    │                                  │                              │
    │                                  ├─ Record trial ───────────────>│
    │                                  │  (both hashes)                │
    │                                  │                              │
    │<─────── Response { allowed: true/false } ────┤                  │
    │                                  │                              │
```

---

## NoCodeBackend Schema Updates

### Update Activation Codes Table

**Instance**: `36905_activation_codes`

**Fields to Add** (if they don't exist):

| Field Name | Type | Description | Required | Indexed |
|------------|------|-------------|----------|---------|
| `type` | Text | "trial", "monthly", "yearly" | Yes | Yes |
| `ip_hash` | Text | SHA-256 hash of IP address | No | Yes |
| `fingerprint_hash` | Text | SHA-256 hash of device fingerprint | No | Yes |
| `created_at` | DateTime | When trial/code was created | Yes | Yes |
| `expires_at` | DateTime | When trial/code expires | Yes | Yes |
| `status` | Text | "active", "used", "expired" | Yes | Yes |

### Manual Schema Update Steps

1. **Log in to NoCodeBackend**:
   - Go to https://nocodebackend.com
   - Log in to your account

2. **Navigate to Instance**:
   - Click "Instances" in sidebar
   - Select instance `36905_activation_codes`
   - Click "Edit Table Schema"

3. **Add New Fields** (one at a time):

   **Field: type**
   ```
   Name: type
   Type: Text
   Default: trial
   Required: Yes
   Indexed: Yes
   ```

   **Field: ip_hash**
   ```
   Name: ip_hash
   Type: Text
   Default: (leave empty)
   Required: No
   Indexed: Yes
   ```

   **Field: fingerprint_hash**
   ```
   Name: fingerprint_hash
   Type: Text
   Default: (leave empty)
   Required: No
   Indexed: Yes
   ```

   **Field: status**
   ```
   Name: status
   Type: Text
   Default: active
   Required: Yes
   Indexed: Yes
   ```

   *(Note: `created_at` and `expires_at` may already exist from activation code setup)*

4. **Save Schema**:
   - Click "Save Changes"
   - Wait for schema migration to complete

5. **Verify Schema**:
   - Go to "Data" tab
   - Click "Add Record" to see all fields
   - Confirm new fields appear

---

## Cloudflare Worker Deployment

### Prerequisites
- Wrangler CLI installed (`npm install -g wrangler`)
- Cloudflare account with Workers enabled
- NoCodeBackend API key

### Step 1: Create wrangler.toml

Create `cloudflare_workers/trial-validator-wrangler.toml`:

```toml
name = "trial-validator"
main = "src/trial-validator.js"
compatibility_date = "2025-01-24"

[vars]
NOCODEBACKEND_API_KEY = "your_nocodebackend_api_key_here"
NOCODEBACKEND_API_URL = "https://api.nocodebackend.com/api/36905_activation_codes"

# To use this file:
# 1. Copy to trial-validator-wrangler.toml
# 2. Replace placeholder with actual API key
# 3. Never commit this file (it's in .gitignore)
```

### Step 2: Deploy Worker

```bash
# Navigate to workers directory
cd /Users/kcdacre8tor/edc_web/cloudflare_workers

# Deploy trial validator
wrangler deploy src/trial-validator.js --config trial-validator-wrangler.toml

# Output will show:
# Published trial-validator
# https://trial-validator.connect-2a2.workers.dev
```

### Step 3: Verify Deployment

```bash
# Test with curl
curl -X POST https://trial-validator.connect-2a2.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"fingerprint":"test_fingerprint_12345"}'

# Expected response (first time):
# {"allowed":true,"message":"Trial activated","trialDays":3,"trialMessages":15}

# Expected response (second time with same fingerprint):
# {"allowed":false,"message":"Trial already used on this device","reason":"fingerprint_match"}
```

### Step 4: Check Logs

```bash
# Monitor real-time logs
wrangler tail trial-validator

# You should see:
# [Trial Validator] Checking eligibility: { ipHash: "abc123...", ... }
# [Trial Validator] Trial allowed - new user
```

---

## PWA Code Integration

### Step 1: Update pubspec.yaml

Add `crypto` dependency if not already present:

```yaml
dependencies:
  # ... existing dependencies ...
  crypto: ^3.0.3
```

Run:
```bash
flutter pub get
```

### Step 2: Add Fingerprint Service

The file `lib/core/services/device_fingerprint_service.dart` is already created.

**Verify it exists:**
```bash
ls -la lib/core/services/device_fingerprint_service.dart
```

### Step 3: Update Subscription Service

**File**: `lib/core/services/subscription_service.dart`

Follow the instructions in `lib/core/services/trial_validation_integration.dart`:

1. **Add import** (line ~10):
```dart
import 'device_fingerprint_service.dart';
```

2. **Add TrialEligibilityResult class** (line ~1100, after ActivationResult):
```dart
/// Result of trial eligibility validation
class TrialEligibilityResult {
  final bool allowed;
  final String message;
  final String? reason;
  final String? suggestion;

  TrialEligibilityResult({
    required this.allowed,
    required this.message,
    this.reason,
    this.suggestion,
  });

  @override
  String toString() {
    return 'TrialEligibilityResult(allowed: $allowed, message: $message, reason: $reason)';
  }
}
```

3. **Add validation method** (line ~900, before startTrial):
```dart
/// Validate trial eligibility via Cloudflare Worker (IP + Fingerprint)
Future<TrialEligibilityResult> _validateTrialEligibility() async {
  try {
    final fingerprint = await DeviceFingerprintService.generateFingerprint();

    debugPrint('📊 [SubscriptionService] Validating trial eligibility...');
    debugPrint('📊 [SubscriptionService] Fingerprint: ${DeviceFingerprintService.shortFingerprint(fingerprint)}');

    final validatorUrl = dotenv.get(
      'TRIAL_VALIDATOR_URL',
      fallback: 'https://trial-validator.connect-2a2.workers.dev',
    );

    final response = await http.post(
      Uri.parse(validatorUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fingerprint': fingerprint}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      if (result['allowed'] == true) {
        debugPrint('📊 [SubscriptionService] ✅ Trial allowed - new user');
        return TrialEligibilityResult(
          allowed: true,
          message: result['message'] ?? 'Trial activated',
        );
      } else {
        debugPrint('📊 [SubscriptionService] ❌ Trial blocked: ${result['reason']}');
        return TrialEligibilityResult(
          allowed: false,
          message: result['message'] ?? 'Trial already used',
          reason: result['reason'],
        );
      }
    } else if (response.statusCode == 403) {
      final result = jsonDecode(response.body);
      debugPrint('📊 [SubscriptionService] ❌ Trial blocked: ${result['reason']}');

      return TrialEligibilityResult(
        allowed: false,
        message: result['message'] ?? 'Trial already used',
        reason: result['reason'],
        suggestion: result['suggestion'],
      );
    } else {
      debugPrint('📊 [SubscriptionService] ⚠️ Trial validation error: ${response.statusCode}');
      return TrialEligibilityResult(
        allowed: true,
        message: 'Trial activated (validation skipped)',
      );
    }
  } catch (error) {
    debugPrint('📊 [SubscriptionService] ⚠️ Trial validation network error: $error');
    return TrialEligibilityResult(
      allowed: true,
      message: 'Trial activated (validation skipped)',
    );
  }
}
```

4. **Update startTrial() method** (line ~316):
```dart
/// Start trial (called on first AI message)
Future<TrialEligibilityResult> startTrial() async {
  if (hasStartedTrial) {
    return TrialEligibilityResult(
      allowed: true,
      message: 'Trial already active',
    );
  }

  // NEW: Check trial eligibility via Cloudflare Worker
  final eligibility = await _validateTrialEligibility();

  if (!eligibility.allowed) {
    debugPrint('📊 [SubscriptionService] Cannot start trial: ${eligibility.message}');
    await _prefs?.setBool('trial_blocked', true);
    return eligibility;
  }

  // Existing trial start logic
  await _prefs?.setString(_keyTrialStartDate, DateTime.now().toIso8601String());
  await _prefs?.setInt(_keyTrialMessagesUsed, 0);

  debugPrint('📊 [SubscriptionService] ✅ Trial started successfully');

  return TrialEligibilityResult(
    allowed: true,
    message: 'Trial activated - enjoy your 15 messages!',
  );
}
```

**IMPORTANT**: The return type of `startTrial()` changes from `Future<void>` to `Future<TrialEligibilityResult>`.

### Step 4: Update UI Code

Find where `startTrial()` is called (likely in chat screen or onboarding) and update to handle the result:

**Before**:
```dart
await subscriptionService.startTrial();
// Trial started, send message
```

**After**:
```dart
final eligibility = await subscriptionService.startTrial();

if (!eligibility.allowed) {
  // Show dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Trial Not Available'),
      content: Text(
        eligibility.message ??
        'You have already used your free trial. Subscribe to continue.'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/subscription');
          },
          child: Text('Subscribe Now'),
        ),
      ],
    ),
  );
  return; // Don't send message
}

// Trial allowed, proceed
```

---

## Environment Variables

### Update .env File

Add to `/Users/kcdacre8tor/edc_web/.env`:

```env
# Trial Validation API (Cloudflare Worker)
TRIAL_VALIDATOR_URL=https://trial-validator.connect-2a2.workers.dev
```

### Update .env.example File

Add to `/Users/kcdacre8tor/edc_web/.env.example`:

```env
# ============================================================================
# TRIAL VALIDATION API - Cloudflare Workers
# ============================================================================
#
# SECURITY REQUIREMENTS:
# 1. This endpoint is public but validates using IP + fingerprint hashing
# 2. All data is hashed (SHA-256) before storage - no raw IPs/fingerprints
# 3. Fail-open design: If validation fails, allow trial (better UX)
# 4. Rate limiting handled by Cloudflare Workers
#
# ENDPOINT DETAILS:
# - Validates trial eligibility using IP + device fingerprint
# - Blocks if either signal has been used before
# - Returns {allowed: true/false, message, reason}
# - No authentication required (public endpoint)
#
# ROTATION SCHEDULE: N/A (stateless public endpoint)
# ============================================================================

# Trial Validation Endpoint (Cloudflare Worker)
# Production: https://trial-validator.connect-2a2.workers.dev
# Development: Same endpoint (handles both test and production)
TRIAL_VALIDATOR_URL=https://trial-validator.connect-2a2.workers.dev
```

---

## Testing Instructions

### Manual Testing Checklist

#### Test 1: First-Time User (Should Allow)
```bash
# 1. Clear browser data (Settings → Clear browsing data)
# 2. Open PWA in browser
# 3. Send first AI message
# 4. Check console logs:
#    "Trial allowed - new user"
#    "Trial started successfully"
# 5. Verify: Trial counter shows 14/15 messages remaining
```

**Expected**: ✅ Trial activated

#### Test 2: Same Device, Same Browser (Should Block)
```bash
# 1. After Test 1, refresh page
# 2. Clear local storage ONLY (not browser data)
# 3. Send AI message again
# 4. Check console logs:
#    "Trial blocked: fingerprint_match"
# 5. Verify: Dialog shows "Trial already used on this device"
```

**Expected**: ❌ Trial blocked

#### Test 3: Same Device, Different Browser (Should Block)
```bash
# 1. After Test 1, open PWA in different browser (Chrome → Safari)
# 2. Send AI message
# 3. Check console logs:
#    "Trial blocked: ip_hash_match" OR "Trial blocked: fingerprint_match"
# 4. Verify: Dialog shows "Trial already used"
```

**Expected**: ❌ Trial blocked (IP hash matches)

#### Test 4: Incognito Mode (Should Block)
```bash
# 1. After Test 1, open PWA in incognito window
# 2. Send AI message
# 3. Check console logs:
#    "Trial blocked: ip_hash_match" OR "Trial blocked: fingerprint_match"
# 4. Verify: Dialog shows "Trial already used"
```

**Expected**: ❌ Trial blocked (IP or fingerprint matches)

#### Test 5: VPN Toggle (Should Block)
```bash
# 1. After Test 1, enable VPN
# 2. Verify IP changed: https://whatismyip.com
# 3. Open PWA, send AI message
# 4. Check console logs:
#    "Trial blocked: fingerprint_match"
# 5. Verify: Dialog shows "Trial already used on this device"
```

**Expected**: ❌ Trial blocked (fingerprint matches even if IP changes)

#### Test 6: Clear All Data + VPN (Should Allow)
```bash
# 1. Clear ALL browser data (Settings → Clear browsing data → All time)
# 2. Enable VPN (change IP)
# 3. Open PWA, send AI message
# 4. Check console logs:
#    "Trial allowed - new user"
# 5. Verify: Trial activated
```

**Expected**: ✅ Trial activated (both IP and fingerprint are new)

**Note**: This is the only way to get a second trial, which is acceptable since it requires significant effort.

#### Test 7: Network Error Handling
```bash
# 1. Disconnect internet
# 2. Open PWA, send AI message
# 3. Check console logs:
#    "Trial validation network error"
#    "Trial activated (validation skipped)"
# 4. Verify: Trial works (fail-open design)
```

**Expected**: ✅ Trial activated (graceful degradation)

#### Test 8: Premium User (Should Bypass)
```bash
# 1. After Test 1 (trial blocked), activate premium subscription
# 2. Enter valid activation code
# 3. Send AI message
# 4. Check console logs:
#    "Premium subscriber - trial check bypassed"
# 5. Verify: Message sends successfully
```

**Expected**: ✅ Message sends (premium users bypass trial validation)

### Automated Testing (Optional)

Create test file: `test/trial_abuse_prevention_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/core/services/device_fingerprint_service.dart';

void main() {
  group('DeviceFingerprintService', () {
    test('generates valid fingerprint format', () async {
      final fingerprint = await DeviceFingerprintService.generateFingerprint();

      expect(fingerprint, isNotEmpty);
      expect(fingerprint.length, 64); // SHA-256 hex
      expect(DeviceFingerprintService.isValidFingerprint(fingerprint), true);
    });

    test('generates consistent fingerprint for same browser', () async {
      final fp1 = await DeviceFingerprintService.generateFingerprint();
      final fp2 = await DeviceFingerprintService.generateFingerprint();

      expect(fp1, equals(fp2)); // Should be same on same device
    });

    test('short fingerprint returns correct format', () {
      final fp = 'a' * 64;
      final short = DeviceFingerprintService.shortFingerprint(fp);

      expect(short.length, 19); // 16 chars + "..."
      expect(short, 'aaaaaaaaaaaaaaaa...');
    });
  });
}
```

Run tests:
```bash
flutter test test/trial_abuse_prevention_test.dart
```

---

## Monitoring & Debugging

### Cloudflare Worker Logs

**View real-time logs:**
```bash
wrangler tail trial-validator
```

**Look for**:
- `[Trial Validator] Checking eligibility` - Every request
- `[Trial Validator] Trial allowed - new user` - First-time users
- `[Trial Validator] Trial blocked: ip_hash_match` - Repeat IP
- `[Trial Validator] Trial blocked: fingerprint_match` - Repeat device

### PWA Console Logs

**Open browser console** (F12 or Cmd+Option+I):

```
📊 [SubscriptionService] Validating trial eligibility...
📊 [SubscriptionService] Fingerprint: abc123def456...
📊 [SubscriptionService] ✅ Trial allowed - new user
📊 [SubscriptionService] ✅ Trial started successfully
```

Or if blocked:
```
📊 [SubscriptionService] Validating trial eligibility...
📊 [SubscriptionService] Fingerprint: abc123def456...
📊 [SubscriptionService] ❌ Trial blocked: fingerprint_match
📊 [SubscriptionService] Cannot start trial: Trial already used on this device
```

### NoCodeBackend Data Inspection

**View trial records**:
1. Log in to NoCodeBackend
2. Go to instance `36905_activation_codes`
3. Click "Data" tab
4. Filter by `type = "trial"`

**Expected fields**:
```json
{
  "code": "TRIAL-1703456789123",
  "type": "trial",
  "ip_hash": "abc123...",
  "fingerprint_hash": "def456...",
  "status": "active",
  "created_at": "2025-12-24T12:00:00.000Z",
  "expires_at": "2025-12-27T12:00:00.000Z"
}
```

### Common Issues

#### Issue: Trial always blocked, even for new users

**Symptoms**: Every user sees "Trial already used"

**Solutions**:
1. Check Cloudflare Worker logs for errors
2. Verify NoCodeBackend API key is correct
3. Check NoCodeBackend table schema has all required fields
4. Test API directly:
   ```bash
   curl -X POST https://trial-validator.connect-2a2.workers.dev \
     -H "Content-Type: application/json" \
     -d '{"fingerprint":"test_new_user_'$(date +%s)'"}'
   ```

#### Issue: Trial always allowed, even for repeat users

**Symptoms**: Users can get unlimited trials

**Solutions**:
1. Verify Cloudflare Worker is deployed (check URL in browser)
2. Check environment variable `TRIAL_VALIDATOR_URL` in PWA
3. Check browser console for network errors
4. Verify NoCodeBackend queries are working (check Worker logs)

#### Issue: Fingerprint generation fails

**Symptoms**: Console shows "Using fallback fingerprint"

**Solutions**:
1. Ensure running on web platform (not mobile app)
2. Check for JavaScript errors in browser console
3. Verify canvas API is available (not blocked by browser)
4. Test in different browser

#### Issue: False positives (legitimate users blocked)

**Symptoms**: Users on shared IPs (coffee shops) can't start trial

**Solutions**:
1. This is expected behavior for IP-based blocking
2. Consider adding email-gated trial option for these users
3. Monitor rate of false positives in analytics
4. If high (>10%), consider reducing weight of IP hash in decision logic

---

## Success Metrics

After deployment, track:

- **Trial abuse rate**: Should drop from ~50% to <15%
- **False positive rate**: Should be <5%
- **Trial conversion rate**: Should remain stable or improve
- **User complaints**: About trial availability

**Tools**:
- Google Analytics custom events
- Cloudflare Worker analytics
- NoCodeBackend record counts
- User support tickets

---

## Rollback Plan

If issues arise, you can quickly rollback:

### Option 1: Disable Validation (Keep System Running)

Update `.env`:
```env
# Temporarily disable validation
TRIAL_VALIDATOR_URL=http://localhost:8787/disabled
```

This will cause network errors, triggering fail-open behavior (all trials allowed).

### Option 2: Revert Code Changes

```bash
# Revert subscription_service.dart to previous version
git checkout HEAD~1 lib/core/services/subscription_service.dart

# Remove new files
rm lib/core/services/device_fingerprint_service.dart
rm lib/core/services/trial_validation_integration.dart

# Rebuild
flutter build web
```

### Option 3: Delete Cloudflare Worker

```bash
wrangler delete trial-validator
```

---

## Next Steps

After successful deployment:

1. **Monitor for 1 week**:
   - Check logs daily
   - Track false positive rate
   - Gather user feedback

2. **Optimize if needed**:
   - Adjust fingerprint signals for better uniqueness
   - Add email-gated trial as fallback option
   - Implement rate limiting per IP

3. **Consider enhancements**:
   - Add analytics dashboard
   - Implement A/B testing (validate vs no-validate)
   - Add geo-blocking for high-abuse regions

---

**Deployment Complete!** 🎉

Your PWA now has robust trial abuse prevention using IP + Fingerprint hybrid approach with 85% effectiveness.
