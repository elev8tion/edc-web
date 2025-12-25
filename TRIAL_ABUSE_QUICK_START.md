# Trial Abuse Prevention - Quick Start Guide

> **Deploy in 20 minutes** - Complete step-by-step guide from zero to production.

---

## Overview

You're implementing **IP + Fingerprint Hybrid** trial abuse prevention with:
- ✅ Separate NoCodeBackend table for trial tracking
- ✅ Cloudflare Worker for validation
- ✅ PWA integration with device fingerprinting
- ✅ 85% effectiveness against abuse

---

## Step 1: Create NoCodeBackend Table (5 minutes)

### 1.1 Log in to NoCodeBackend
- Go to https://nocodebackend.com
- Log in to your account

### 1.2 Create New Instance
- Click "Instances" → "Create New Instance"
- **Name**: `trial_tracking`
- **Description**: "PWA trial abuse prevention"
- Click "Create"

### 1.3 Add Fields (copy-paste from table below)

**Quick reference**:
| Field | Type | Required | Indexed |
|-------|------|----------|---------|
| `ip_hash` | Text | Yes | ✅ Yes |
| `fingerprint_hash` | Text | Yes | ✅ Yes |
| `trial_started_at` | DateTime | Yes | Yes |
| `trial_expires_at` | DateTime | Yes | Yes |
| `status` | Text | Yes | Yes |
| `messages_used` | Integer | No | No |

**Detailed instructions**: See `NOCODEBACKEND_TRIAL_TABLE_SCHEMA.md`

### 1.4 Copy API Details
- Go to "API" tab in your new instance
- Copy **API URL**: `https://api.nocodebackend.com/api/XXXXX`
- Copy **API Key**: From Settings → API Keys
- **Save these** - you'll need them next!

---

## Step 2: Deploy Cloudflare Worker (5 minutes)

### 2.1 Configure Worker
```bash
cd /Users/kcdacre8tor/edc_web/cloudflare_workers

# Copy example config
cp trial-validator-wrangler.toml.example trial-validator-wrangler.toml

# Edit trial-validator-wrangler.toml
nano trial-validator-wrangler.toml
```

**Update these lines**:
```toml
NOCODEBACKEND_TRIAL_API_KEY = "YOUR_ACTUAL_API_KEY_HERE"
NOCODEBACKEND_TRIAL_API_URL = "https://api.nocodebackend.com/api/YOUR_INSTANCE_ID"
```

### 2.2 Deploy
```bash
# Deploy to Cloudflare
wrangler deploy src/trial-validator.js --config trial-validator-wrangler.toml

# Output will show your worker URL:
# ✨ Published trial-validator
# https://trial-validator.YOUR_SUBDOMAIN.workers.dev
```

### 2.3 Test Deployment
```bash
# Test with curl (should return "allowed": true first time)
curl -X POST https://trial-validator.YOUR_SUBDOMAIN.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"fingerprint":"test_fingerprint_'$(date +%s)'"}'

# Expected response:
# {"allowed":true,"message":"Trial activated","trialDays":3,"trialMessages":15}
```

### 2.4 Verify Database
- Go back to NoCodeBackend
- Open your `trial_tracking` instance
- Click "Data" tab
- You should see 1 new record with your test fingerprint

**If you see the record**: ✅ Worker is working!

---

## Step 3: Update PWA Code (10 minutes)

### 3.1 Add crypto dependency
```bash
cd /Users/kcdacre8tor/edc_web

# Check if crypto is in pubspec.yaml
grep "crypto:" pubspec.yaml

# If not found, add it:
# dependencies:
#   crypto: ^3.0.3

flutter pub get
```

### 3.2 Verify fingerprint service exists
```bash
ls -la lib/core/services/device_fingerprint_service.dart
# Should show the file exists
```

### 3.3 Update subscription_service.dart

**File**: `lib/core/services/subscription_service.dart`

**Add import** (top of file, around line 10):
```dart
import 'device_fingerprint_service.dart';
```

**Add TrialEligibilityResult class** (end of file, around line 1100):
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
  String toString() =>
      'TrialEligibilityResult(allowed: $allowed, message: $message, reason: $reason)';
}
```

**Add validation method** (before `startTrial()`, around line 900):
```dart
/// Validate trial eligibility via Cloudflare Worker
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
        debugPrint('📊 [SubscriptionService] ✅ Trial allowed');
        return TrialEligibilityResult(
          allowed: true,
          message: result['message'] ?? 'Trial activated',
        );
      }
    } else if (response.statusCode == 403) {
      final result = jsonDecode(response.body);
      debugPrint('📊 [SubscriptionService] ❌ Trial blocked: ${result['reason']}');
      return TrialEligibilityResult(
        allowed: false,
        message: result['message'] ?? 'Trial already used',
        reason: result['reason'],
      );
    }

    // Error - fail open
    return TrialEligibilityResult(allowed: true, message: 'Trial activated');
  } catch (error) {
    debugPrint('📊 [SubscriptionService] ⚠️ Validation error: $error');
    return TrialEligibilityResult(allowed: true, message: 'Trial activated');
  }
}
```

**Update startTrial()** (replace existing method around line 316):
```dart
/// Start trial (called on first AI message)
Future<TrialEligibilityResult> startTrial() async {
  if (hasStartedTrial) {
    return TrialEligibilityResult(allowed: true, message: 'Trial already active');
  }

  // NEW: Check trial eligibility
  final eligibility = await _validateTrialEligibility();

  if (!eligibility.allowed) {
    debugPrint('📊 [SubscriptionService] Cannot start trial: ${eligibility.message}');
    await _prefs?.setBool('trial_blocked', true);
    return eligibility;
  }

  // Existing trial start logic
  await _prefs?.setString(_keyTrialStartDate, DateTime.now().toISOString());
  await _prefs?.setInt(_keyTrialMessagesUsed, 0);

  debugPrint('📊 [SubscriptionService] ✅ Trial started successfully');
  return TrialEligibilityResult(allowed: true, message: 'Trial activated!');
}
```

**⚠️ Important**: `startTrial()` now returns `Future<TrialEligibilityResult>` instead of `Future<void>`.

### 3.4 Update UI Code

Find where `startTrial()` is called and update to handle the result:

**Before**:
```dart
await subscriptionService.startTrial();
// Send message...
```

**After**:
```dart
final eligibility = await subscriptionService.startTrial();

if (!eligibility.allowed) {
  // Show "Subscribe Now" dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Trial Not Available'),
      content: Text(eligibility.message ?? 'Trial already used. Subscribe to continue.'),
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

// Trial allowed, proceed with message...
```

### 3.5 Add environment variable

**File**: `.env`
```env
# Add this line:
TRIAL_VALIDATOR_URL=https://trial-validator.YOUR_SUBDOMAIN.workers.dev
```

**File**: `.env.example`
```env
# Trial Validation API (Cloudflare Worker)
TRIAL_VALIDATOR_URL=https://trial-validator.connect-2a2.workers.dev
```

---

## Step 4: Test End-to-End (5 minutes)

### Test 1: First Trial (Should Work)
1. Clear browser data completely
2. Open PWA
3. Send first AI message
4. ✅ Should work - trial starts

**Check console**:
```
📊 [SubscriptionService] Validating trial eligibility...
📊 [SubscriptionService] Fingerprint: abc123def456...
📊 [SubscriptionService] ✅ Trial allowed
📊 [SubscriptionService] ✅ Trial started successfully
```

### Test 2: Repeat Trial (Should Block)
1. Refresh page (or close/reopen)
2. Clear local storage only (not full browser data)
3. Send AI message again
4. ❌ Should be blocked

**Check console**:
```
📊 [SubscriptionService] Validating trial eligibility...
📊 [SubscriptionService] ❌ Trial blocked: fingerprint_match
📊 [SubscriptionService] Cannot start trial: Trial already used on this device
```

**Expected UI**: Dialog shows "Trial Not Available" with "Subscribe Now" button

### Test 3: Different Browser (Should Block)
1. Open PWA in different browser (Chrome → Safari)
2. Send AI message
3. ❌ Should be blocked (IP hash matches)

### Test 4: Incognito Mode (Should Block)
1. Open PWA in incognito window
2. Send AI message
3. ❌ Should be blocked (IP or fingerprint matches)

---

## Troubleshooting

### Issue: Trial always blocked for everyone
**Solution**: Check Cloudflare Worker logs
```bash
wrangler tail trial-validator --config trial-validator-wrangler.toml
```
Look for errors. Common causes:
- Wrong API key in wrangler.toml
- Wrong API URL (check instance ID)
- NoCodeBackend table schema incorrect

### Issue: Trial always allowed (not blocking repeats)
**Solution**:
1. Check environment variable is loaded: `console.log(import.meta.env.VITE_TRIAL_VALIDATOR_URL)`
2. Check network tab - is validation request being made?
3. Check Cloudflare Worker is deployed: Visit URL in browser

### Issue: Fingerprint generation fails
**Solution**:
- Must run on web (kIsWeb = true)
- Check browser console for errors
- Try different browser

---

## Success Checklist

After completing all steps, verify:

- [ ] NoCodeBackend `trial_tracking` table created with all fields
- [ ] Fields `ip_hash` and `fingerprint_hash` are indexed
- [ ] Cloudflare Worker deployed successfully
- [ ] Worker URL accessible (test with curl)
- [ ] Test record appears in NoCodeBackend after curl test
- [ ] PWA code updated with validation logic
- [ ] Environment variable `TRIAL_VALIDATOR_URL` set
- [ ] Test 1: First trial works
- [ ] Test 2: Repeat trial blocked
- [ ] Test 3: Different browser blocked
- [ ] Test 4: Incognito mode blocked

---

## Next Steps

After successful deployment:

1. **Monitor for 1 week**:
   - Check Cloudflare Worker analytics
   - Review NoCodeBackend trial records
   - Track user feedback/support tickets

2. **Set up data cleanup** (optional):
   - Manually delete trials older than 90 days
   - Or create scheduled Cloudflare Worker job

3. **Enhance if needed**:
   - Add email-gated trial as fallback option
   - Implement message usage tracking in NoCodeBackend
   - Add analytics dashboard

---

## Cost Summary

- **NoCodeBackend**: Free (under 10K records/month)
- **Cloudflare Workers**: Free (under 100K requests/day)
- **Total**: $0/month 🎉

---

## Support

If you encounter issues:

1. **Check logs**:
   ```bash
   wrangler tail trial-validator
   ```

2. **Check NoCodeBackend data**:
   - View records in trial_tracking table
   - Look for duplicate ip_hash/fingerprint_hash

3. **Check PWA console**:
   - Look for validation messages
   - Check for network errors

4. **Review documentation**:
   - `TRIAL_ABUSE_PREVENTION_DEPLOYMENT.md` - Full details
   - `NOCODEBACKEND_TRIAL_TABLE_SCHEMA.md` - Table schema

---

**Ready to deploy!** 🚀

Follow the steps above in order, and you'll have trial abuse prevention running in ~20 minutes.
