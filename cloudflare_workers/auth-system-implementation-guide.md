# Everyday Christian - Auth System Implementation Guide

## Overview

This document outlines the remaining tasks for completing the authentication system implementation, with detailed explanations of each component and a sub-agent orchestration strategy for parallel execution.

---

## 1. Testing & Verification

### 1.1 End-to-End Test: Signup → Email Verification → Login Flow

**What it is:**
A complete user journey test that validates the entire authentication pipeline works correctly from account creation to successful login.

**Steps to test:**
1. Call `POST /signup` with email, password, and optional first_name
2. Check NoCodeBackend users table for new record with `email_verified: 0`
3. Verify EmailIt sends verification email to the provided address
4. Extract verification token from email link
5. Call `POST /verify-email` with the token
6. Confirm `email_verified` is now `1` in database
7. Call `POST /login` with credentials
8. Verify JWT token is returned with correct payload

**Success criteria:**
- User record created with correct fields
- Verification email received within 60 seconds
- Token validates email successfully
- Login returns valid JWT with user data

**Test endpoints:**
```bash
# Signup
curl -X POST https://auth.everydaychristian.app/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123!","first_name":"Test"}'

# Verify (after getting token from email)
curl -X POST https://auth.everydaychristian.app/verify-email \
  -H "Content-Type: application/json" \
  -d '{"token":"<verification_token>"}'

# Login
curl -X POST https://auth.everydaychristian.app/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123!"}'
```

---

### 1.2 Password Reset Email Delivery Test

**What it is:**
Validates that users can recover their accounts through the password reset flow.

**Steps to test:**
1. Call `POST /forgot-password` with registered email
2. Verify reset email is sent with correct branding
3. Extract reset token from email link
4. Call `POST /reset-password` with token and new password
5. Attempt login with new password
6. Verify old password no longer works

**Success criteria:**
- Reset email arrives within 60 seconds
- Token expires after 1 hour (security requirement)
- Password update persists correctly
- Old password is invalidated

**Test endpoints:**
```bash
# Request reset
curl -X POST https://auth.everydaychristian.app/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'

# Reset password (after getting token from email)
curl -X POST https://auth.everydaychristian.app/reset-password \
  -H "Content-Type: application/json" \
  -d '{"token":"<reset_token>","new_password":"NewSecurePass456!"}'
```

---

### 1.3 JWT Token Expiration and Refresh Handling

**What it is:**
Ensures tokens expire correctly and can be refreshed without requiring re-login.

**Current implementation:**
- Access token expires in 7 days
- Refresh token expires in 30 days
- Tokens are signed with HS256 algorithm

**Steps to test:**
1. Login to get access and refresh tokens
2. Decode JWT to verify expiration claim (`exp`)
3. Call protected endpoint with valid token (should succeed)
4. Call protected endpoint with expired token (should fail with 401)
5. Call `POST /refresh` with refresh token
6. Verify new access token is issued

**Enhancement considerations:**
- Reduce access token expiry to 15 minutes for production
- Implement token blacklisting for logout
- Add refresh token rotation (issue new refresh token on each refresh)

**Test endpoints:**
```bash
# Refresh token
curl -X POST https://auth.everydaychristian.app/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<refresh_token>"}'

# Validate token
curl -X POST https://auth.everydaychristian.app/validate \
  -H "Content-Type: application/json" \
  -d '{"token":"<access_token>"}'
```

---

## 2. Frontend Integration

### 2.1 Flutter App Auth Service Connecting to Worker Endpoints

**What it is:**
A dedicated service class in the Flutter app that handles all authentication API calls.

**Implementation location:**
`/lib/services/auth_service.dart`

**Required methods:**
```dart
class AuthService {
  static const String baseUrl = 'https://auth.everydaychristian.app';

  // Core authentication
  Future<AuthResult> signup(String email, String password, {String? firstName});
  Future<AuthResult> login(String email, String password, {String? deviceId});
  Future<void> logout();

  // Email verification
  Future<bool> verifyEmail(String token);
  Future<void> resendVerification(String email);

  // Password management
  Future<void> forgotPassword(String email);
  Future<bool> resetPassword(String token, String newPassword);
  Future<bool> changePassword(String currentPassword, String newPassword);

  // Token management
  Future<String?> refreshToken();
  Future<bool> validateToken(String token);

  // User profile
  Future<User> getProfile();
  Future<User> updateProfile(Map<String, dynamic> updates);
}
```

**HTTP client configuration:**
- Use `dio` or `http` package
- Set default headers for Content-Type
- Implement request/response interceptors for token injection
- Handle network errors gracefully

---

### 2.2 Error Handling UI for Auth Failures

**What it is:**
User-friendly error messages and UI states for various authentication failures.

**Error types to handle:**

| Error Code | User Message | UI Action |
|------------|--------------|-----------|
| `invalid_credentials` | "Email or password is incorrect" | Shake form, highlight fields |
| `email_not_verified` | "Please verify your email first" | Show resend button |
| `user_exists` | "An account with this email already exists" | Offer login link |
| `token_expired` | "Your session has expired" | Redirect to login |
| `rate_limited` | "Too many attempts. Please wait." | Show countdown timer |
| `network_error` | "Unable to connect. Check your internet." | Show retry button |
| `weak_password` | "Password must be at least 8 characters" | Show requirements |

**Implementation pattern:**
```dart
class AuthException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  String get userMessage {
    switch (code) {
      case 'invalid_credentials':
        return 'Email or password is incorrect';
      case 'email_not_verified':
        return 'Please verify your email to continue';
      // ... etc
    }
  }
}
```

---

### 2.3 Token Storage and Auto-Refresh Logic

**What it is:**
Secure persistent storage for authentication tokens with automatic refresh before expiration.

**Storage strategy:**
- Use `flutter_secure_storage` for tokens (encrypted)
- Store token expiry timestamps
- Never store passwords locally

**Auto-refresh implementation:**
```dart
class TokenManager {
  final FlutterSecureStorage _storage;
  Timer? _refreshTimer;

  // Schedule refresh 5 minutes before expiry
  void scheduleRefresh(String token) {
    final payload = JwtDecoder.decode(token);
    final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
    final refreshTime = expiry.subtract(Duration(minutes: 5));
    final delay = refreshTime.difference(DateTime.now());

    _refreshTimer?.cancel();
    if (delay.isNegative) {
      // Token already needs refresh
      _performRefresh();
    } else {
      _refreshTimer = Timer(delay, _performRefresh);
    }
  }

  Future<void> _performRefresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      final newToken = await AuthService.refresh(refreshToken);
      await _storage.write(key: 'access_token', value: newToken);
      scheduleRefresh(newToken);
    }
  }
}
```

---

## 3. Security

### 3.1 Rate Limiting on Login/Signup Endpoints

**What it is:**
Protection against brute force attacks by limiting the number of requests per IP/email.

**Recommended limits:**
| Endpoint | Limit | Window | Action on exceed |
|----------|-------|--------|------------------|
| `/login` | 5 attempts | 15 minutes | Block IP, notify user |
| `/signup` | 3 attempts | 1 hour | Block IP |
| `/forgot-password` | 3 attempts | 1 hour | Block email |
| `/verify-email` | 10 attempts | 1 hour | Block token |

**Implementation using Cloudflare:**
```javascript
// In auth-service.js
async function checkRateLimit(request, env, key, limit, windowSeconds) {
  const rateLimitKey = `ratelimit:${key}`;
  const current = await env.KV.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;

  if (count >= limit) {
    return { limited: true, remaining: 0 };
  }

  await env.KV.put(rateLimitKey, String(count + 1), {
    expirationTtl: windowSeconds
  });

  return { limited: false, remaining: limit - count - 1 };
}
```

**Alternative:** Use Cloudflare's built-in rate limiting rules in the dashboard.

---

### 3.2 CORS Configuration for Flutter Web Domain

**What it is:**
Cross-Origin Resource Sharing headers that allow your Flutter web app to make requests to the auth API.

**Current implementation in auth-service.js:**
```javascript
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',  // CHANGE THIS
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};
```

**Production configuration:**
```javascript
const ALLOWED_ORIGINS = [
  'https://everydaychristian.app',
  'https://www.everydaychristian.app',
  'http://localhost:3000',  // Development only
];

function getCorsHeaders(request) {
  const origin = request.headers.get('Origin');
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];

  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Credentials': 'true',
  };
}
```

---

### 3.3 Token Invalidation on Logout

**What it is:**
Ensures that logging out actually prevents the old token from being used.

**Challenge:**
JWTs are stateless - the server doesn't track them. A valid JWT remains valid until it expires.

**Solutions:**

1. **Token blacklist (recommended for MVP):**
```javascript
// Store invalidated tokens until they naturally expire
async function logout(request, env) {
  const token = extractToken(request);
  const payload = await verifyJWT(token, env.JWT_SECRET);

  // Add to blacklist with TTL matching token expiry
  const ttl = payload.exp - Math.floor(Date.now() / 1000);
  await env.KV.put(`blacklist:${token}`, '1', { expirationTtl: ttl });

  return jsonResponse({ success: true });
}

// Check blacklist on protected routes
async function validateToken(token, env) {
  const blacklisted = await env.KV.get(`blacklist:${token}`);
  if (blacklisted) {
    throw new Error('Token has been revoked');
  }
  return verifyJWT(token, env.JWT_SECRET);
}
```

2. **Token versioning:**
- Store a `token_version` in the user record
- Include version in JWT payload
- Increment version on logout (invalidates all tokens)

3. **Short-lived tokens:**
- Use 15-minute access tokens
- Require refresh token for new access tokens
- Revoke refresh token on logout

---

## 4. Integration Points

### 4.1 Stripe Subscription Sync with User Accounts

**What it is:**
Keeping user premium access in sync with their Stripe subscription status.

**Current implementation:**
- `stripe-webhook.js` handles Stripe events
- Updates user `stripe_customer_id` and subscription status

**Sync points:**

| Stripe Event | Action |
|--------------|--------|
| `customer.subscription.created` | Set premium_expires, update status |
| `customer.subscription.updated` | Update premium_expires |
| `customer.subscription.deleted` | Clear premium access |
| `invoice.payment_succeeded` | Extend premium_expires |
| `invoice.payment_failed` | Send warning email, grace period |

**User table fields for Stripe:**
```sql
stripe_customer_id VARCHAR(255)    -- Stripe customer ID
subscription_id VARCHAR(255)       -- Active subscription ID
subscription_status VARCHAR(50)    -- active, past_due, canceled
premium_expires DATETIME           -- When access ends
```

**Auth integration:**
```javascript
// Include subscription status in JWT
function generateUserToken(user, env) {
  const payload = {
    sub: user.id,
    email: user.email,
    premium: user.premium_expires && new Date(user.premium_expires) > new Date(),
    subscription_status: user.subscription_status,
    exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60),
  };
  return signJWT(payload, env.JWT_SECRET);
}
```

---

## 5. Deployment

### 5.1 Verify Worker is Deployed to Production

**Commands:**
```bash
# Navigate to workers directory
cd /Users/kcdacre8tor/edc_web/cloudflare_workers

# Deploy auth service
wrangler deploy -c wrangler-auth.toml

# Check deployment status
wrangler deployments list -c wrangler-auth.toml

# View real-time logs
wrangler tail -c wrangler-auth.toml
```

**Verification checklist:**
- [ ] Worker deployed successfully (no errors)
- [ ] Custom domain configured (auth.everydaychristian.app)
- [ ] SSL certificate active
- [ ] Environment variables set (KV namespace, secrets)
- [ ] Routes configured correctly

---

### 5.2 Test Production Endpoints

**Health check:**
```bash
curl https://auth.everydaychristian.app/health
# Expected: {"status":"ok","timestamp":"..."}
```

**Full endpoint test suite:**
```bash
#!/bin/bash
BASE_URL="https://auth.everydaychristian.app"

echo "=== Auth Service Production Tests ==="

# 1. Health check
echo -e "\n1. Health Check:"
curl -s "$BASE_URL/health" | jq .

# 2. Signup (use unique email)
TEST_EMAIL="test_$(date +%s)@example.com"
echo -e "\n2. Signup:"
SIGNUP_RESULT=$(curl -s -X POST "$BASE_URL/signup" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"TestPass123!\"}")
echo $SIGNUP_RESULT | jq .

# 3. Login
echo -e "\n3. Login:"
LOGIN_RESULT=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"TestPass123!\"}")
echo $LOGIN_RESULT | jq .
TOKEN=$(echo $LOGIN_RESULT | jq -r '.token')

# 4. Validate token
echo -e "\n4. Validate Token:"
curl -s -X POST "$BASE_URL/validate" \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\"}" | jq .

# 5. Get profile
echo -e "\n5. Get Profile:"
curl -s "$BASE_URL/me" \
  -H "Authorization: Bearer $TOKEN" | jq .

echo -e "\n=== Tests Complete ==="
```

---

## 6. Sub-Agent Orchestration Strategy

### Overview

To efficiently complete all tasks, we can deploy specialized sub-agents that work in parallel on independent tasks while coordinating on dependent ones.

### Agent Definitions

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ORCHESTRATOR AGENT                                  │
│  Role: Coordinates all sub-agents, manages dependencies, reports progress   │
│  Tools: Task, TodoWrite, AskUserQuestion                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
│   TESTING AGENT   │   │  FRONTEND AGENT   │   │  SECURITY AGENT   │
│                   │   │                   │   │                   │
│ - E2E flow tests  │   │ - Auth service    │   │ - Rate limiting   │
│ - Email delivery  │   │ - Error handling  │   │ - CORS config     │
│ - Token refresh   │   │ - Token storage   │   │ - Token blacklist │
│                   │   │                   │   │                   │
│ Tools: Bash, curl │   │ Tools: Edit, Read │   │ Tools: Edit, Read │
└───────────────────┘   └───────────────────┘   └───────────────────┘
        │                           │                           │
        └───────────────────────────┼───────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │      INTEGRATION AGENT        │
                    │                               │
                    │ - Activation code flow        │
                    │ - Stripe sync verification    │
                    │ - Deployment validation       │
                    │                               │
                    │ Tools: Bash, Read, WebFetch   │
                    └───────────────────────────────┘
```

### Execution Plan

**Phase 1: Parallel Execution (Independent Tasks)**

| Agent | Tasks | Dependencies |
|-------|-------|--------------|
| Testing Agent | E2E signup test, Email delivery test | None |
| Security Agent | Rate limiting implementation, CORS update | None |
| Frontend Agent | Auth service class structure | None |

**Phase 2: Sequential (Dependent Tasks)**

| Agent | Tasks | Depends On |
|-------|-------|------------|
| Frontend Agent | Token storage, Auto-refresh | Phase 1 Frontend |
| Testing Agent | Token refresh test | Phase 1 Security |
| Integration Agent | Activation code flow | Phase 1 Testing |

**Phase 3: Final Validation**

| Agent | Tasks | Depends On |
|-------|-------|------------|
| Integration Agent | Full deployment test | All Phase 2 |
| Orchestrator | Generate completion report | Phase 3 Integration |

### Agent Prompts

**Orchestrator Agent:**
```
You are coordinating the completion of the auth system implementation.

Current status: [READ FROM TODO LIST]

Your responsibilities:
1. Launch sub-agents for parallel tasks
2. Monitor progress and handle blockers
3. Ensure dependencies are respected
4. Report completion status to user

Launch the following agents in parallel:
- Testing Agent: Validate all auth endpoints
- Security Agent: Implement rate limiting and CORS
- Frontend Agent: Create Flutter auth service

After Phase 1 completes, coordinate Phase 2 tasks.
```

**Testing Agent:**
```
You are responsible for validating the auth system endpoints.

Tasks:
1. Test signup flow with new email
2. Verify email is sent (check logs)
3. Test login with created account
4. Test token validation
5. Test password reset flow
6. Document any failures

Base URL: https://auth.everydaychristian.app
Report results in structured format.
```

**Security Agent:**
```
You are responsible for implementing security features.

Tasks:
1. Add rate limiting to auth-service.js
   - 5 login attempts per 15 minutes
   - 3 signup attempts per hour

2. Update CORS to restrict origins
   - Allow: everydaychristian.app
   - Allow: localhost for dev

3. Implement token blacklist for logout
   - Use Cloudflare KV
   - TTL matches token expiry

File: /Users/kcdacre8tor/edc_web/cloudflare_workers/src/auth-service.js
```

**Frontend Agent:**
```
You are responsible for Flutter frontend auth integration.

Tasks:
1. Create lib/services/auth_service.dart
   - All API methods
   - Error handling
   - Token management

2. Create lib/services/token_manager.dart
   - Secure storage
   - Auto-refresh logic

3. Create lib/models/auth_models.dart
   - AuthResult
   - AuthException
   - User model

Follow existing code patterns in the Flutter project.
```

**Integration Agent:**
```
You are responsible for integration and deployment.

Tasks:
1. Verify activation code flow works with auth
2. Confirm Stripe webhook updates user records
3. Run full deployment validation
4. Test production endpoints

Report any integration issues to orchestrator.
```

### Launching Agents with Claude Code

```bash
# In Claude Code, launch agents like this:

# Testing Agent (background)
Task: "Validate auth endpoints"
Prompt: [Testing Agent prompt above]
subagent_type: general-purpose
run_in_background: true

# Security Agent (background)
Task: "Implement auth security"
Prompt: [Security Agent prompt above]
subagent_type: general-purpose
run_in_background: true

# Frontend Agent (background)
Task: "Create Flutter auth service"
Prompt: [Frontend Agent prompt above]
subagent_type: general-purpose
run_in_background: true

# Monitor progress
TaskOutput: [agent_ids]

# After Phase 1, launch Integration Agent
Task: "Validate integration points"
Prompt: [Integration Agent prompt above]
subagent_type: general-purpose
```

---

## 7. Progress Tracking

Use this checklist to track implementation progress:

### Testing & Verification
- [ ] E2E signup → verify → login tested
- [ ] Password reset email delivered
- [ ] Token refresh working
- [ ] All edge cases documented

### Frontend Integration
- [ ] AuthService class created
- [ ] Error handling implemented
- [ ] Token storage secure
- [ ] Auto-refresh working

### Security
- [ ] Rate limiting active
- [ ] CORS restricted to app domain
- [ ] Logout invalidates tokens
- [ ] Security audit passed

### Integration
- [ ] Activation codes work with auth
- [ ] Stripe sync verified
- [ ] All endpoints tested in production

### Deployment
- [ ] Worker deployed
- [ ] Custom domain working
- [ ] SSL active
- [ ] Monitoring enabled

---

## 8. Quick Reference

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /signup | Create new account |
| POST | /login | Authenticate user |
| POST | /logout | Invalidate token |
| POST | /verify-email | Verify email address |
| POST | /resend-verification | Resend verification email |
| POST | /forgot-password | Request password reset |
| POST | /reset-password | Set new password |
| POST | /change-password | Change password (authenticated) |
| POST | /refresh | Refresh access token |
| POST | /validate | Validate token |
| GET | /me | Get current user profile |
| PUT | /me | Update user profile |

### Environment Variables

| Variable | Description |
|----------|-------------|
| NOCODEBACKEND_API_KEY | NoCodeBackend API key |
| JWT_SECRET | Secret for signing JWTs |
| EMAILIT_API_KEY | EmailIt API key |

### Important Files

| File | Purpose |
|------|---------|
| `src/auth-service.js` | Main auth worker |
| `wrangler-auth.toml` | Worker configuration |
| `.dev.vars` | Local development secrets |

---

*Document generated: December 30, 2025*
*Project: Everyday Christian Authentication System*
