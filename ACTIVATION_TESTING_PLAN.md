# Activation Code Testing Plan

## Overview
This document outlines the testing strategy for the new Cloudflare Workers-based activation code system replacing the previous Activepieces integration.

**System Architecture**:
- **Worker 1** (Stripe Webhook): Generates codes, saves to NoCodeBackend, sends emails
- **Worker 2** (Code Validation): Validates codes, marks as used with device ID tracking
- **PWA/Mobile**: ActivationScreen → SubscriptionService → Cloudflare Worker validation

---

## Test Environment Setup

### Prerequisites
1. ✅ Cloudflare Workers deployed:
   - Stripe Webhook: `https://stripe-webhook-handler.connect-2a2.workers.dev`
   - Code Validation: `https://code-validation-api.connect-2a2.workers.dev`
2. ✅ NoCodeBackend database: Instance `36905_activation_codes`
3. ✅ EmailIt API configured with domain verification
4. ✅ Stripe test mode enabled
5. ✅ PWA .env file configured with:
   ```env
   CODE_VALIDATION_URL=https://code-validation-api.connect-2a2.workers.dev
   ```

### Test Accounts
- **Email**: ceocre8@gmail.com (for test email delivery)
- **Stripe Test Cards**:
  - Success: `4242 4242 4242 4242`
  - Decline: `4000 0000 0000 0002`

---

## Test Cases

### Phase 1: Code Generation Tests

#### Test 1.1: Monthly Subscription Code Generation
**Objective**: Verify monthly subscription generates M-XXX-XXX code

**Steps**:
1. Trigger Stripe webhook with monthly price ID
2. Check NoCodeBackend for new record
3. Verify email sent to test address

**Expected Results**:
- ✅ Code format: `M-XXX-XXX`
- ✅ Tier: `monthly`
- ✅ Code saved to database
- ✅ Email received with dark-themed template
- ✅ Email displays activation code correctly

**Test Data**:
```bash
curl -X POST https://stripe-webhook-handler.connect-2a2.workers.dev \
  -H "Content-Type: application/json" \
  -d '{
    "type": "invoice.payment_succeeded",
    "data": {
      "object": {
        "id": "in_test_monthly",
        "customer": "cus_TestMonthly",
        "customer_email": "ceocre8@gmail.com",
        "subscription": "sub_test_monthly",
        "lines": {
          "data": [{
            "price": {"id": "price_1ShctRIDgcZhXc4UfDnbNf1s"},
            "period": {"end": 1798201200}
          }]
        }
      }
    }
  }'
```

**Validation**:
```bash
# Check response contains activation code
# Response should be: {"success":true,"activationCode":"M-XXX-XXX","tier":"monthly",...}
```

---

#### Test 1.2: Yearly Subscription Code Generation
**Objective**: Verify yearly subscription generates Y-XXX-XXX code

**Steps**: Same as 1.1 but with yearly price ID

**Expected Results**:
- ✅ Code format: `Y-XXX-XXX`
- ✅ Tier: `yearly`
- ✅ Correct expiry date (12 months from now)

**Test Data**:
```bash
curl -X POST https://stripe-webhook-handler.connect-2a2.workers.dev \
  -H "Content-Type: application/json" \
  -d '{
    "type": "invoice.payment_succeeded",
    "data": {
      "object": {
        "id": "in_test_yearly",
        "customer": "cus_TestYearly",
        "customer_email": "ceocre8@gmail.com",
        "subscription": "sub_test_yearly",
        "lines": {
          "data": [{
            "price": {"id": "price_1Shcv9IDgcZhXc4UUAD2Qfz3"},
            "period": {"end": 1829737200}
          }]
        }
      }
    }
  }'
```

---

#### Test 1.3: Trial Code Generation
**Objective**: Verify unknown price ID generates T-XXX-XXX code

**Expected Results**:
- ✅ Code format: `T-XXX-XXX`
- ✅ Tier: `trial`

---

### Phase 2: Code Validation Tests

#### Test 2.1: Valid Code Activation (First Use)
**Objective**: Verify valid unused code activates successfully

**Steps**:
1. Generate fresh code from Phase 1
2. Open PWA activation screen
3. Enter generated code
4. Submit for validation

**Expected Results**:
- ✅ API returns `{"valid":true,"tier":"monthly",...}`
- ✅ Code marked as used in NoCodeBackend (device_id populated)
- ✅ PWA shows success message
- ✅ PWA navigates to /home
- ✅ Premium status activated locally
- ✅ Message limits updated (150 for monthly/yearly)

**Test Data**:
```bash
# Manual test via PWA UI or:
curl -X POST https://code-validation-api.connect-2a2.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"code":"M-ABC-123","deviceId":"test-device-001"}'
```

**Validation Checklist**:
- [ ] Response: `{"valid":true}`
- [ ] NoCodeBackend record updated with `device_id`
- [ ] PWA localStorage has `premium_active=true`
- [ ] PWA shows correct message limit

---

#### Test 2.2: Invalid Code Format
**Objective**: Verify invalid format is rejected

**Test Codes**:
- `INVALID` (no hyphens)
- `M-12-34` (numbers in wrong position)
- `X-ABC-123` (invalid prefix)
- `M-ABCD-123` (wrong length)

**Expected Results**:
- ✅ PWA validation error before API call (client-side regex)
- ✅ Error message: "Invalid code format (should be like M-ABC-123)"

---

#### Test 2.3: Non-Existent Code
**Objective**: Verify code not in database is rejected

**Test Code**: `M-ZZZ-999` (not generated)

**Expected Results**:
- ✅ API returns `{"valid":false,"error":"Invalid activation code"}`
- ✅ PWA shows error message
- ✅ No database changes

---

#### Test 2.4: Already Used Code (Same Device)
**Objective**: Verify code can't be reused on same device

**Steps**:
1. Activate code successfully (Test 2.1)
2. Try same code with same device ID again

**Expected Results**:
- ✅ API returns `{"valid":false,"error":"Code already used on another device"}`
- ✅ PWA shows error message
- ✅ No duplicate activation

---

#### Test 2.5: Already Used Code (Different Device)
**Objective**: Verify one code = one device enforcement

**Steps**:
1. Activate code with device ID `test-device-001`
2. Try same code with device ID `test-device-002`

**Expected Results**:
- ✅ API returns `{"valid":false,"error":"Code already used on another device"}`
- ✅ Original device still has access
- ✅ New device rejected

---

#### Test 2.6: Expired Code (Future Feature)
**Objective**: Verify expiration logic works

**Note**: Currently expiry is only stored, not enforced during validation. This test is for when expiry enforcement is added.

**Expected Results** (when implemented):
- ❌ Expired code rejected
- ✅ Non-expired code accepted

---

### Phase 3: Email Delivery Tests

#### Test 3.1: Email Template Rendering
**Objective**: Verify email displays correctly across clients

**Email Clients to Test**:
- [ ] Gmail (Web)
- [ ] Gmail (Mobile App)
- [ ] Apple Mail (macOS)
- [ ] Apple Mail (iOS)
- [ ] Outlook (Web)
- [ ] Outlook (Desktop)

**Validation Checklist**:
- [ ] Dark background renders (#1a1b2e)
- [ ] Yellow activation code box visible (#FDB022)
- [ ] SVG logo displays (or fallback)
- [ ] Activation code is copy-able
- [ ] Links work (email support link)
- [ ] Mobile responsive design
- [ ] No layout breaking

---

#### Test 3.2: Email Deliverability
**Objective**: Verify emails aren't marked as spam

**Steps**:
1. Send test email
2. Check inbox, spam, promotions folders
3. Verify SPF/DKIM headers

**Expected Results**:
- ✅ Email in inbox (not spam)
- ✅ From: "Everyday Christian <connect@everydaychristian.app>"
- ✅ Subject line correct
- ✅ Email headers show proper authentication

---

### Phase 4: PWA Integration Tests

#### Test 4.1: Activation Screen UI
**Objective**: Verify activation screen renders correctly

**Validation Checklist**:
- [ ] Input field accepts code format
- [ ] Paste button works
- [ ] Format hint displayed (M-XXX-XXX, Y-XXX-XXX, T-XXX-XXX)
- [ ] Client-side validation triggers
- [ ] Loading state shows during API call
- [ ] Error messages display in red box
- [ ] Success message shows green SnackBar

---

#### Test 4.2: Deep Link with Prefilled Code
**Objective**: Verify URL parameter prefills activation code

**Test URL**: `https://everydaychristian.app/activate?code=M-ABC-123`

**Expected Results**:
- ✅ Code auto-filled in input
- ✅ Auto-validation triggered
- ✅ If valid, user redirected to /home
- ✅ If invalid, error shown but user can edit

---

#### Test 4.3: Subscription State Persistence
**Objective**: Verify premium status persists across sessions

**Steps**:
1. Activate code successfully
2. Refresh PWA
3. Close and reopen PWA
4. Check subscription status

**Expected Results**:
- ✅ Premium status retained
- ✅ Message limits correct
- ✅ Expiry date stored
- ✅ No re-activation required

---

#### Test 4.4: Offline Behavior
**Objective**: Verify graceful handling when offline

**Steps**:
1. Disconnect internet
2. Try to activate code
3. Reconnect internet

**Expected Results**:
- ✅ Error message: "Error validating code" (network error)
- ✅ User can retry after reconnecting
- ✅ No data corruption

---

### Phase 5: Edge Cases & Error Handling

#### Test 5.1: API Timeout
**Objective**: Verify timeout handling

**Test Method**: Mock slow API response (>10 seconds)

**Expected Results**:
- ✅ Request times out after 10s
- ✅ Error message shown
- ✅ User can retry

---

#### Test 5.2: Malformed API Response
**Objective**: Verify handling of unexpected response format

**Test Method**: Mock API returning invalid JSON

**Expected Results**:
- ✅ Error caught and handled
- ✅ No app crash
- ✅ User-friendly error message

---

#### Test 5.3: Missing Device ID
**Objective**: Verify device ID generation

**Steps**:
1. Clear all localStorage/SharedPreferences
2. Activate code

**Expected Results**:
- ✅ New device ID auto-generated
- ✅ Activation succeeds
- ✅ Device ID stored locally
- ✅ Same device ID used for subsequent activations

---

#### Test 5.4: Case Insensitivity
**Objective**: Verify codes work in any case

**Test Codes**:
- `m-abc-123`
- `M-ABC-123`
- `M-abc-123`

**Expected Results**:
- ✅ All variations accepted (normalized to uppercase)
- ✅ Same code detected as duplicate

---

#### Test 5.5: Whitespace Handling
**Objective**: Verify trimming of whitespace

**Test Input**: `  M-ABC-123  ` (spaces before/after)

**Expected Results**:
- ✅ Code validated correctly
- ✅ Spaces stripped

---

### Phase 6: Security Tests

#### Test 6.1: SQL Injection Attempt
**Objective**: Verify code input is sanitized

**Test Input**: `M-ABC'; DROP TABLE--`

**Expected Results**:
- ✅ Validation fails (invalid format)
- ✅ No database impact
- ✅ No error exposure

---

#### Test 6.2: XSS Attempt
**Objective**: Verify no script injection

**Test Input**: `<script>alert('xss')</script>`

**Expected Results**:
- ✅ Validation fails
- ✅ No script execution
- ✅ Safe error display

---

#### Test 6.3: Rate Limiting
**Objective**: Verify protection against brute force

**Test Method**: Submit 100 requests rapidly

**Expected Results** (if implemented):
- ✅ Rate limit triggered
- ✅ Temporary block message

**Note**: Currently no rate limiting - consider adding in future

---

### Phase 7: NoCodeBackend Database Tests

#### Test 7.1: Database Record Format
**Objective**: Verify correct data stored

**Check After Activation**:
```
id,code,customer_id,subscription_id,tier,status,expires_at,used_at,device_id
5,M-ABC-123,cus_xxx,sub_xxx,monthly,,(empty),(empty),test-device-001
```

**Expected Schema**:
- ✅ `code`: Uppercase activation code
- ✅ `customer_id`: Stripe customer ID
- ✅ `subscription_id`: Stripe subscription ID
- ✅ `tier`: monthly/yearly/trial
- ✅ `status`: (empty - validation issue)
- ✅ `expires_at`: (empty - validation issue)
- ✅ `used_at`: (empty - validation issue)
- ✅ `device_id`: UUID after validation

---

#### Test 7.2: Database Query Performance
**Objective**: Verify lookup speed

**Test Method**: Query for code by exact match

**Expected Results**:
- ✅ Query completes in <500ms
- ✅ Correct record returned
- ✅ Case-insensitive search works

---

### Phase 8: End-to-End User Journey

#### Test 8.1: Complete Purchase Flow
**Objective**: Full user journey from purchase to activation

**Steps**:
1. User purchases via Stripe Checkout (monthly plan)
2. Stripe webhook triggers code generation
3. User receives email with code
4. User opens PWA
5. User enters code in activation screen
6. User enjoys premium features

**Expected Timeline**:
- t+0s: Payment completed
- t+2s: Code generated and saved
- t+5s: Email sent
- t+30s: Email delivered to inbox
- t+2m: User opens email
- t+3m: User activates code in PWA
- t+3m: Premium access granted

**Validation Checklist**:
- [ ] No steps fail
- [ ] Code works on first try
- [ ] Email contains correct code
- [ ] Premium features unlocked immediately
- [ ] User can send messages (150 limit)

---

## Test Execution Tracking

### Manual Test Results

| Test ID | Test Name | Status | Tester | Date | Notes |
|---------|-----------|--------|--------|------|-------|
| 1.1 | Monthly Code Gen | ⏳ Pending | - | - | - |
| 1.2 | Yearly Code Gen | ⏳ Pending | - | - | - |
| 1.3 | Trial Code Gen | ⏳ Pending | - | - | - |
| 2.1 | Valid Code Activation | ⏳ Pending | - | - | - |
| 2.2 | Invalid Format | ⏳ Pending | - | - | - |
| 2.3 | Non-Existent Code | ⏳ Pending | - | - | - |
| 2.4 | Same Device Reuse | ⏳ Pending | - | - | - |
| 2.5 | Different Device | ⏳ Pending | - | - | - |
| 3.1 | Email Template | ⏳ Pending | - | - | - |
| 3.2 | Email Delivery | ⏳ Pending | - | - | - |
| 4.1 | Activation UI | ⏳ Pending | - | - | - |
| 4.2 | Deep Link | ⏳ Pending | - | - | - |
| 4.3 | State Persistence | ⏳ Pending | - | - | - |
| 4.4 | Offline Behavior | ⏳ Pending | - | - | - |
| 5.1-5.5 | Edge Cases | ⏳ Pending | - | - | - |
| 6.1-6.3 | Security | ⏳ Pending | - | - | - |
| 8.1 | E2E Journey | ⏳ Pending | - | - | - |

---

## Known Issues

### Current Limitations
1. **NoCodeBackend Schema**: Fields `status`, `expires_at`, `used_at` cannot be set during creation due to validation errors
   - **Workaround**: Only track `device_id` for used status
   - **Impact**: Medium - expiry not enforced, status tracking manual

2. **No Rate Limiting**: API endpoint is unprotected against brute force
   - **Risk**: Low (codes are random, hard to guess)
   - **Recommendation**: Add Cloudflare rate limiting rules

3. **No Code Expiry Enforcement**: Expiry date stored but not checked during validation
   - **Impact**: Low (most subscriptions auto-renew)
   - **Recommendation**: Add expiry check in code-validation.js

### Future Enhancements
1. Add webhook signature verification for security
2. Implement code expiry enforcement
3. Add rate limiting (100 requests/hour per IP)
4. Create admin dashboard for code management
5. Add code revocation feature
6. Implement usage analytics tracking

---

## Testing Tools

### Recommended Tools
- **API Testing**: Postman, cURL, HTTPie
- **Email Testing**: Litmus, Email on Acid
- **Browser Testing**: BrowserStack, LambdaTest
- **Performance**: Lighthouse, WebPageTest
- **Security**: OWASP ZAP, Burp Suite Community

### Test Data Generator
```javascript
// Generate random test codes
function generateTestCode(tier = 'monthly') {
  const prefix = tier === 'monthly' ? 'M' : tier === 'yearly' ? 'Y' : 'T';
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const part1 = Array(3).fill(0).map(() => chars[Math.floor(Math.random() * chars.length)]).join('');
  const part2 = Array(3).fill(0).map(() => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `${prefix}-${part1}-${part2}`;
}

// Example: generateTestCode('monthly') -> "M-ABC-D3F"
```

---

## Success Criteria

### Phase 1-3 (Code Generation & Validation)
- [ ] All code generation tests pass (1.1-1.3)
- [ ] All validation tests pass (2.1-2.6)
- [ ] Email delivery reliable (>99%)

### Phase 4 (PWA Integration)
- [ ] Activation UI works on all browsers
- [ ] Deep linking functional
- [ ] State persists correctly
- [ ] Offline handling graceful

### Phase 5-6 (Edge Cases & Security)
- [ ] All edge cases handled
- [ ] No security vulnerabilities
- [ ] Error messages user-friendly

### Phase 8 (End-to-End)
- [ ] Complete user journey works smoothly
- [ ] Average activation time <5 minutes
- [ ] Success rate >95%

---

## Sign-off

**Tested By**: _________________
**Date**: _________________
**Status**: ⏳ In Progress
**Approved By**: _________________

---

**Last Updated**: 2025-12-24
**Version**: 1.0
**Next Review**: After Phase 1 implementation
