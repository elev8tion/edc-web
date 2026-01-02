/**
 * Auth Service Worker - Complete Authentication System
 *
 * Endpoints:
 * - POST /signup - Register new user
 * - POST /login - Authenticate user
 * - POST /logout - Invalidate token (blacklists token)
 * - POST /forgot-password - Send password reset email
 * - POST /reset-password - Reset password with token
 * - POST /verify-email - Verify email with token
 * - POST /resend-verification - Resend verification email
 * - GET /validate-token - Validate JWT token
 * - POST /refresh-token - Refresh JWT token
 * - PATCH /profile - Update user profile
 * - DELETE /account - Delete user account
 *
 * Security Features:
 * - Rate limiting (IP-based for login/signup, email-based for forgot-password)
 * - Token blacklisting for logout (KV-based for persistence)
 * - Dynamic CORS origin validation
 * - Secure HttpOnly cookies with __Host- prefix
 * - CSRF protection tokens
 * - Comprehensive security headers (CSP, X-Frame-Options, etc.)
 */

// ============================================
// SECURITY: Cookie & CSRF Configuration
// ============================================

// Cookie configuration for secure tokens
const COOKIE_CONFIG = {
  access: {
    name: '__Host-access_token',
    maxAge: 900,  // 15 minutes
    httpOnly: true,
    secure: true,
    sameSite: 'Strict',
    path: '/'
  },
  refresh: {
    name: '__Host-refresh_token',
    maxAge: 604800,  // 7 days
    httpOnly: true,
    secure: true,
    sameSite: 'Strict',
    path: '/api/auth'
  }
};

const CSRF_CONFIG = {
  name: 'csrf_token',
  maxAge: 604800,
  httpOnly: false,
  secure: true,
  sameSite: 'Strict'
};

// ============================================
// SECURITY: HTTP Security Headers
// ============================================

const SECURITY_HEADERS = {
  'Content-Security-Policy': [
    "default-src 'self'",
    "script-src 'self' https://js.stripe.com",
    "frame-src 'self' https://js.stripe.com https://hooks.stripe.com",
    "connect-src 'self' https://*.workers.dev https://api.stripe.com",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https:",
    "font-src 'self'"
  ].join('; '),
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'geolocation=(), microphone=(), camera=()'
};

// ============================================
// SECURITY: Rate Limiting (In-Memory)
// ============================================

// Rate limit stores: Map<key, { count: number, resetTime: number }>
const loginRateLimits = new Map();
const signupRateLimits = new Map();
const forgotPasswordRateLimits = new Map();

// Rate limit configuration
const RATE_LIMITS = {
  login: { maxAttempts: 5, windowMs: 15 * 60 * 1000 }, // 5 attempts per 15 minutes
  signup: { maxAttempts: 3, windowMs: 60 * 60 * 1000 }, // 3 attempts per hour
  forgotPassword: { maxAttempts: 3, windowMs: 60 * 60 * 1000 }, // 3 attempts per hour
};

// Cleanup interval for rate limit maps (runs every 5 minutes)
const RATE_LIMIT_CLEANUP_INTERVAL = 5 * 60 * 1000;
let lastRateLimitCleanup = Date.now();

/**
 * Clean expired entries from rate limit maps
 */
function cleanupRateLimits() {
  const now = Date.now();
  if (now - lastRateLimitCleanup < RATE_LIMIT_CLEANUP_INTERVAL) return;

  lastRateLimitCleanup = now;

  for (const [key, value] of loginRateLimits) {
    if (now > value.resetTime) loginRateLimits.delete(key);
  }
  for (const [key, value] of signupRateLimits) {
    if (now > value.resetTime) signupRateLimits.delete(key);
  }
  for (const [key, value] of forgotPasswordRateLimits) {
    if (now > value.resetTime) forgotPasswordRateLimits.delete(key);
  }
}

/**
 * Check and update rate limit for a given key
 * Returns { allowed: boolean, remaining: number, resetTime: number }
 */
function checkRateLimit(store, key, config) {
  cleanupRateLimits();

  const now = Date.now();
  const record = store.get(key);

  if (!record || now > record.resetTime) {
    // First request or window expired - create new record
    const resetTime = now + config.windowMs;
    store.set(key, { count: 1, resetTime });
    return {
      allowed: true,
      remaining: config.maxAttempts - 1,
      resetTime,
      limit: config.maxAttempts,
    };
  }

  if (record.count >= config.maxAttempts) {
    // Rate limit exceeded
    return {
      allowed: false,
      remaining: 0,
      resetTime: record.resetTime,
      limit: config.maxAttempts,
    };
  }

  // Increment count
  record.count++;
  store.set(key, record);

  return {
    allowed: true,
    remaining: config.maxAttempts - record.count,
    resetTime: record.resetTime,
    limit: config.maxAttempts,
  };
}

/**
 * Get client IP from request
 */
function getClientIP(request) {
  return request.headers.get('CF-Connecting-IP') ||
         request.headers.get('X-Forwarded-For')?.split(',')[0]?.trim() ||
         request.headers.get('X-Real-IP') ||
         'unknown';
}

/**
 * Add rate limit headers to response
 */
function addRateLimitHeaders(headers, rateLimitResult) {
  headers['X-RateLimit-Limit'] = String(rateLimitResult.limit);
  headers['X-RateLimit-Remaining'] = String(rateLimitResult.remaining);
  headers['X-RateLimit-Reset'] = String(Math.ceil(rateLimitResult.resetTime / 1000));
  return headers;
}

// ============================================
// SECURITY: Token Blacklist (In-Memory - Legacy)
// ============================================

// Token blacklist: Map<token, expirationTime>
const tokenBlacklist = new Map();

// Cleanup interval for blacklist (runs every 10 minutes)
const BLACKLIST_CLEANUP_INTERVAL = 10 * 60 * 1000;
let lastBlacklistCleanup = Date.now();

/**
 * Clean expired entries from token blacklist
 */
function cleanupBlacklist() {
  const now = Date.now();
  if (now - lastBlacklistCleanup < BLACKLIST_CLEANUP_INTERVAL) return;

  lastBlacklistCleanup = now;

  for (const [token, expirationTime] of tokenBlacklist) {
    if (now > expirationTime) tokenBlacklist.delete(token);
  }
}

/**
 * Add token to blacklist (in-memory - legacy)
 */
function blacklistTokenInMemory(token, expirationTime) {
  cleanupBlacklist();
  tokenBlacklist.set(token, expirationTime);
}

/**
 * Check if token is blacklisted (in-memory - legacy)
 */
function isTokenBlacklistedInMemory(token) {
  cleanupBlacklist();
  const expirationTime = tokenBlacklist.get(token);
  if (!expirationTime) return false;

  // If token's blacklist entry has expired, remove it and return false
  if (Date.now() > expirationTime) {
    tokenBlacklist.delete(token);
    return false;
  }

  return true;
}

// ============================================
// SECURITY: Token Blacklist (KV-Based - Persistent)
// ============================================

/**
 * Add token to KV blacklist by JTI (JWT ID)
 * Uses TTL to auto-expire when token would have expired anyway
 */
async function blacklistToken(env, jti, expiresAt) {
  const ttl = Math.ceil((expiresAt - Date.now()) / 1000);
  if (ttl > 0 && env.TOKEN_BLACKLIST) {
    await env.TOKEN_BLACKLIST.put(
      `blacklist:${jti}`,
      'revoked',
      { expirationTtl: ttl }
    );
  }
}

/**
 * Check if token is blacklisted by JTI
 */
async function isTokenBlacklisted(env, jti) {
  if (!env.TOKEN_BLACKLIST) return false;
  const result = await env.TOKEN_BLACKLIST.get(`blacklist:${jti}`);
  return result !== null;
}

// ============================================
// SECURITY: Cookie & CSRF Helpers
// ============================================

/**
 * Build a secure cookie string from configuration
 */
function setSecureCookie(name, value, config) {
  const parts = [
    `${name}=${value}`,
    `Max-Age=${config.maxAge}`,
    `Path=${config.path || '/'}`,
    config.httpOnly ? 'HttpOnly' : '',
    config.secure ? 'Secure' : '',
    `SameSite=${config.sameSite || 'Strict'}`
  ].filter(Boolean);
  return parts.join('; ');
}

/**
 * Generate a cryptographically secure CSRF token
 */
function generateCsrfToken() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return btoa(String.fromCharCode(...array));
}

// ============================================
// SECURITY: Dynamic CORS
// ============================================

// Allowed origins for CORS
const ALLOWED_ORIGINS = [
  'https://everydaychristian.app',
  'https://www.everydaychristian.app',
  'https://app.everydaychristian.app',
];

/**
 * Check if origin is allowed
 */
function isOriginAllowed(origin) {
  if (!origin) return false;

  // Check exact match for production origins
  if (ALLOWED_ORIGINS.includes(origin)) return true;

  // Allow localhost for development (any port)
  if (/^http:\/\/localhost(:\d+)?$/.test(origin)) return true;

  return false;
}

/**
 * Get CORS headers based on request origin
 */
function getCorsHeaders(request) {
  const origin = request.headers.get('Origin');

  if (isOriginAllowed(origin)) {
    return {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Allow-Credentials': 'true',
    };
  }

  // For requests without valid origin, return restrictive headers
  return {
    'Access-Control-Allow-Origin': ALLOWED_ORIGINS[0],
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}

// Main entry point
export default {
  async fetch(request, env, ctx) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: getCorsHeaders(request) });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // Route handling
      switch (path) {
        case '/signup':
          return await handleSignup(request, env);
        case '/login':
          return await handleLogin(request, env);
        case '/logout':
          return await handleLogout(request, env);
        case '/forgot-password':
          return await handleForgotPassword(request, env);
        case '/reset-password':
          return await handleResetPassword(request, env);
        case '/verify-email':
          return await handleVerifyEmail(request, env);
        case '/resend-verification':
          return await handleResendVerification(request, env);
        case '/validate-token':
          return await handleValidateToken(request, env);
        case '/refresh-token':
          return await handleRefreshToken(request, env);
        case '/profile':
          return await handleProfile(request, env);
        case '/account':
          return await handleDeleteAccount(request, env);
        case '/health':
          return jsonResponse({ status: 'ok', service: 'auth-service' }, 200, request);
        default:
          return jsonResponse({ error: 'Not found' }, 404, request);
      }
    } catch (error) {
      console.error('[Auth Service] Unhandled error:', error);
      return jsonResponse({ error: 'Internal server error' }, 500, request);
    }
  }
};

// ============================================
// ENDPOINT HANDLERS
// ============================================

/**
 * POST /signup - Register new user
 */
async function handleSignup(request, env) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  // Rate limiting by IP
  const clientIP = getClientIP(request);
  const rateLimitResult = checkRateLimit(signupRateLimits, clientIP, RATE_LIMITS.signup);

  if (!rateLimitResult.allowed) {
    const retryAfter = Math.ceil((rateLimitResult.resetTime - Date.now()) / 1000);
    return jsonResponse(
      { error: 'Too many signup attempts. Please try again later.' },
      429,
      request,
      rateLimitResult,
      { 'Retry-After': String(retryAfter) }
    );
  }

  try {
    const { email, password, first_name, locale, device_id } = await request.json();

    // Validate required fields
    if (!email || !password) {
      return jsonResponse({ error: 'Email and password are required' }, 400, request, rateLimitResult);
    }

    // Validate email format
    if (!isValidEmail(email)) {
      return jsonResponse({ error: 'Invalid email format' }, 400, request, rateLimitResult);
    }

    // Validate password strength
    if (password.length < 6) {
      return jsonResponse({ error: 'Password must be at least 6 characters' }, 400, request, rateLimitResult);
    }

    const normalizedEmail = email.toLowerCase().trim();

    // Check if user already exists
    const existingUser = await findUserByEmail(normalizedEmail, env);
    if (existingUser) {
      return jsonResponse({ error: 'An account with this email already exists' }, 409, request, rateLimitResult);
    }

    // Hash password with OWASP 2024 recommended iterations
    const passwordHash = await hashPassword(password, env);

    // Generate verification token
    const verificationToken = generateToken();

    // Create user in NoCodeBackend
    const now = formatMySQLDatetime(new Date());
    const expiresAt = formatMySQLDatetime(new Date(Date.now() + parseInt(env.TOKEN_EXPIRES_IN || '86400') * 1000));

    // Build user data - only include fields with values (avoid empty strings for nullable fields)
    const userData = {
      email: normalizedEmail,
      password_hash: passwordHash,
      created_at: now,
      status: 'active',
      email_verified: 0,
      verification_token: verificationToken,
      verification_expires: expiresAt,
    };
    if (first_name?.trim()) userData.first_name = first_name.trim();
    if (locale) userData.locale = locale;
    if (device_id) userData.device_ids = JSON.stringify([device_id]);

    const newUser = await createUser(userData, env);

    if (!newUser || !newUser.id) {
      return jsonResponse({ error: 'Failed to create account' }, 500, request, rateLimitResult);
    }

    // Send verification email
    await sendVerificationEmail(normalizedEmail, verificationToken, locale || 'en', first_name, env);

    // Generate JWT token
    const token = await generateJWT({
      userId: newUser.id,
      email: normalizedEmail,
    }, env);

    // Return user data (excluding sensitive fields)
    return jsonResponse({
      message: 'Account created successfully. Please verify your email.',
      token,
      user: sanitizeUser({
        id: newUser.id,
        email: normalizedEmail,
        first_name: first_name?.trim() || null,
        locale: locale || 'en',
        email_verified: false,
        created_at: new Date().toISOString(),
        status: 'active',
      }),
    }, 201, request, rateLimitResult);

  } catch (error) {
    console.error('[Signup] Error:', error);
    return jsonResponse({ error: 'Failed to create account' }, 500, request);
  }
}

/**
 * POST /login - Authenticate user
 */
async function handleLogin(request, env) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  // Rate limiting by IP
  const clientIP = getClientIP(request);
  const rateLimitResult = checkRateLimit(loginRateLimits, clientIP, RATE_LIMITS.login);

  if (!rateLimitResult.allowed) {
    const retryAfter = Math.ceil((rateLimitResult.resetTime - Date.now()) / 1000);
    return jsonResponse(
      { error: 'Too many login attempts. Please try again later.' },
      429,
      request,
      rateLimitResult,
      { 'Retry-After': String(retryAfter) }
    );
  }

  try {
    const { email, password, device_id } = await request.json();

    if (!email || !password) {
      return jsonResponse({ error: 'Email and password are required' }, 400, request, rateLimitResult);
    }

    const normalizedEmail = email.toLowerCase().trim();

    // Find user
    const user = await findUserByEmail(normalizedEmail, env);
    if (!user) {
      return jsonResponse({ error: 'Invalid email or password' }, 401, request, rateLimitResult);
    }

    // Check account status
    if (user.status === 'suspended') {
      return jsonResponse({ error: 'Account has been suspended' }, 403, request, rateLimitResult);
    }

    if (user.status === 'deleted') {
      return jsonResponse({ error: 'Account not found' }, 401, request, rateLimitResult);
    }

    // Verify password (supports both legacy 100k and new 600k iterations)
    const passwordValid = await verifyPassword(password, user.password_hash, env);
    if (!passwordValid) {
      return jsonResponse({ error: 'Invalid email or password' }, 401, request, rateLimitResult);
    }

    // Update device IDs and last login
    let deviceIds = [];
    try {
      deviceIds = JSON.parse(user.device_ids || '[]');
    } catch (e) {
      deviceIds = [];
    }
    if (device_id && !deviceIds.includes(device_id)) {
      deviceIds.push(device_id);
    }

    await updateUser(user.id, {
      device_ids: JSON.stringify(deviceIds),
      last_login: formatMySQLDatetime(new Date()),
    }, env);

    // Generate JWT token
    const token = await generateJWT({
      userId: user.id,
      email: normalizedEmail,
    }, env);

    return jsonResponse({
      message: 'Login successful',
      token,
      user: sanitizeUser(user),
    }, 200, request, rateLimitResult);

  } catch (error) {
    console.error('[Login] Error:', error);
    return jsonResponse({ error: 'Login failed' }, 500, request);
  }
}

/**
 * POST /logout - Logout (blacklists token)
 */
async function handleLogout(request, env) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  try {
    // Extract token from Authorization header
    const authHeader = request.headers.get('Authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const payload = await verifyJWT(token, env);

      if (payload && payload.exp) {
        // Blacklist the token until it expires
        const expirationTime = payload.exp * 1000; // Convert to milliseconds
        blacklistToken(token, expirationTime);
      }
    }

    return jsonResponse({ message: 'Logged out successfully' }, 200, request);
  } catch (error) {
    console.error('[Logout] Error:', error);
    // Still return success - logout should always "succeed" from user perspective
    return jsonResponse({ message: 'Logged out successfully' }, 200, request);
  }
}

/**
 * POST /forgot-password - Send password reset email
 */
async function handleForgotPassword(request, env) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  try {
    const { email, locale } = await request.json();

    if (!email) {
      return jsonResponse({ error: 'Email is required' }, 400, request);
    }

    const normalizedEmail = email.toLowerCase().trim();

    // Rate limiting by email (prevents abuse against specific accounts)
    const rateLimitResult = checkRateLimit(forgotPasswordRateLimits, normalizedEmail, RATE_LIMITS.forgotPassword);

    if (!rateLimitResult.allowed) {
      const retryAfter = Math.ceil((rateLimitResult.resetTime - Date.now()) / 1000);
      return jsonResponse(
        { error: 'Too many password reset requests. Please try again later.' },
        429,
        request,
        rateLimitResult,
        { 'Retry-After': String(retryAfter) }
      );
    }

    const user = await findUserByEmail(normalizedEmail, env);

    // Always return success to prevent email enumeration
    if (!user) {
      return jsonResponse({ message: 'If an account exists, a reset link has been sent' }, 200, request, rateLimitResult);
    }

    // Generate reset token
    const resetToken = generateToken();
    const resetExpires = formatMySQLDatetime(new Date(Date.now() + parseInt(env.TOKEN_EXPIRES_IN || '86400') * 1000));

    // Update user with reset token
    await updateUser(user.id, {
      reset_token: resetToken,
      reset_expires: resetExpires,
    }, env);

    // Send reset email
    await sendPasswordResetEmail(normalizedEmail, resetToken, locale || user.locale || 'en', user.first_name, env);

    return jsonResponse({ message: 'If an account exists, a reset link has been sent' }, 200, request, rateLimitResult);

  } catch (error) {
    console.error('[ForgotPassword] Error:', error);
    return jsonResponse({ error: 'Failed to process request' }, 500, request);
  }
}

/**
 * POST /reset-password - Reset password with token
 */
async function handleResetPassword(request, env) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  try {
    const { token, new_password } = await request.json();

    if (!token || !new_password) {
      return jsonResponse({ error: 'Token and new password are required' }, 400, request);
    }

    if (new_password.length < 6) {
      return jsonResponse({ error: 'Password must be at least 6 characters' }, 400, request);
    }

    // Find user with this reset token
    const user = await findUserByResetToken(token, env);
    if (!user) {
      return jsonResponse({ error: 'Invalid or expired reset token' }, 400, request);
    }

    // Check if token is expired
    if (new Date(user.reset_expires) < new Date()) {
      return jsonResponse({ error: 'Reset token has expired' }, 400, request);
    }

    // Hash new password with OWASP 2024 recommended iterations
    const passwordHash = await hashPassword(new_password, env);

    // Update password and clear reset token (set to null to clear)
    await updateUser(user.id, {
      password_hash: passwordHash,
      reset_token: null,
      reset_expires: null,
    }, env);

    return jsonResponse({ message: 'Password reset successfully' }, 200, request);

  } catch (error) {
    console.error('[ResetPassword] Error:', error);
    return jsonResponse({ error: 'Failed to reset password' }, 500, request);
  }
}

/**
 * POST /verify-email - Verify email with token
 */
async function handleVerifyEmail(request, env) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  try {
    const { token } = await request.json();

    if (!token) {
      return jsonResponse({ error: 'Verification token is required' }, 400, request);
    }

    // Find user with this verification token
    const user = await findUserByVerificationToken(token, env);
    if (!user) {
      return jsonResponse({ error: 'Invalid or expired verification token' }, 400, request);
    }

    // Check if token is expired
    if (new Date(user.verification_expires) < new Date()) {
      return jsonResponse({ error: 'Verification token has expired' }, 400, request);
    }

    // Mark email as verified and clear token (set to null to clear)
    await updateUser(user.id, {
      email_verified: 1,
      verification_token: null,
      verification_expires: null,
    }, env);

    // Generate new JWT token with verified status
    const jwtToken = await generateJWT({
      userId: user.id,
      email: user.email,
    }, env);

    return jsonResponse({
      message: 'Email verified successfully',
      token: jwtToken,
      user: sanitizeUser({ ...user, email_verified: true }),
    }, 200, request);

  } catch (error) {
    console.error('[VerifyEmail] Error:', error);
    return jsonResponse({ error: 'Failed to verify email' }, 500, request);
  }
}

/**
 * POST /resend-verification - Resend verification email
 */
async function handleResendVerification(request, env) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  try {
    const { email, locale } = await request.json();

    if (!email) {
      return jsonResponse({ error: 'Email is required' }, 400, request);
    }

    const normalizedEmail = email.toLowerCase().trim();
    const user = await findUserByEmail(normalizedEmail, env);

    // Always return success to prevent email enumeration
    if (!user) {
      return jsonResponse({ message: 'If the email exists and is unverified, a new verification link has been sent' }, 200, request);
    }

    // Check if already verified
    if (user.email_verified === 1) {
      return jsonResponse({ message: 'Email is already verified' }, 200, request);
    }

    // Generate new verification token
    const verificationToken = generateToken();
    const verificationExpires = formatMySQLDatetime(new Date(Date.now() + parseInt(env.TOKEN_EXPIRES_IN || '86400') * 1000));

    // Update user with new token
    await updateUser(user.id, {
      verification_token: verificationToken,
      verification_expires: verificationExpires,
    }, env);

    // Send verification email
    await sendVerificationEmail(normalizedEmail, verificationToken, locale || user.locale || 'en', user.first_name, env);

    return jsonResponse({ message: 'If the email exists and is unverified, a new verification link has been sent' }, 200, request);

  } catch (error) {
    console.error('[ResendVerification] Error:', error);
    return jsonResponse({ error: 'Failed to send verification email' }, 500, request);
  }
}

/**
 * GET /validate-token - Validate JWT token
 */
async function handleValidateToken(request, env) {
  if (request.method !== 'GET') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  try {
    // Extract token from Authorization header
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return jsonResponse({ error: 'No token provided' }, 401, request);
    }

    const token = authHeader.substring(7);

    // Check if token is blacklisted (logged out)
    if (isTokenBlacklisted(token)) {
      return jsonResponse({ error: 'Token has been invalidated' }, 401, request);
    }

    const payload = await verifyJWT(token, env);

    if (!payload) {
      return jsonResponse({ error: 'Invalid or expired token' }, 401, request);
    }

    // Get fresh user data
    const user = await findUserById(payload.userId, env);
    if (!user) {
      return jsonResponse({ error: 'User not found' }, 401, request);
    }

    if (user.status !== 'active') {
      return jsonResponse({ error: 'Account is not active' }, 401, request);
    }

    return jsonResponse({
      message: 'Token is valid',
      user: sanitizeUser(user),
    }, 200, request);

  } catch (error) {
    console.error('[ValidateToken] Error:', error);
    return jsonResponse({ error: 'Token validation failed' }, 401, request);
  }
}

/**
 * POST /refresh-token - Refresh JWT token
 */
async function handleRefreshToken(request, env) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  try {
    // Extract token from Authorization header
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return jsonResponse({ error: 'No token provided' }, 401, request);
    }

    const token = authHeader.substring(7);

    // Check if token is blacklisted (logged out)
    if (isTokenBlacklisted(token)) {
      return jsonResponse({ error: 'Token has been invalidated' }, 401, request);
    }

    const payload = await verifyJWT(token, env);

    if (!payload) {
      return jsonResponse({ error: 'Invalid or expired token' }, 401, request);
    }

    // Get fresh user data
    const user = await findUserById(payload.userId, env);
    if (!user || user.status !== 'active') {
      return jsonResponse({ error: 'User not found or inactive' }, 401, request);
    }

    // Generate new token
    const newToken = await generateJWT({
      userId: user.id,
      email: user.email,
    }, env);

    // Blacklist the old token (optional, prevents reuse)
    if (payload.exp) {
      blacklistToken(token, payload.exp * 1000);
    }

    return jsonResponse({
      message: 'Token refreshed',
      token: newToken,
      user: sanitizeUser(user),
    }, 200, request);

  } catch (error) {
    console.error('[RefreshToken] Error:', error);
    return jsonResponse({ error: 'Token refresh failed' }, 401, request);
  }
}

/**
 * PATCH /profile - Update user profile
 */
async function handleProfile(request, env) {
  if (request.method !== 'PATCH') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  try {
    // Extract and verify token
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return jsonResponse({ error: 'No token provided' }, 401, request);
    }

    const token = authHeader.substring(7);

    // Check if token is blacklisted (logged out)
    if (isTokenBlacklisted(token)) {
      return jsonResponse({ error: 'Token has been invalidated' }, 401, request);
    }

    const payload = await verifyJWT(token, env);

    if (!payload) {
      return jsonResponse({ error: 'Invalid or expired token' }, 401, request);
    }

    const { first_name, locale, trial_started_at } = await request.json();

    // Build update object with only provided fields
    const updates = {};
    if (first_name !== undefined) updates.first_name = first_name?.trim() || null;
    if (locale !== undefined) updates.locale = locale;
    if (trial_started_at !== undefined) updates.trial_started_at = trial_started_at;

    if (Object.keys(updates).length === 0) {
      return jsonResponse({ error: 'No fields to update' }, 400, request);
    }

    // Update user
    await updateUser(payload.userId, updates, env);

    // Get updated user
    const user = await findUserById(payload.userId, env);

    return jsonResponse({
      message: 'Profile updated',
      user: sanitizeUser(user),
    }, 200, request);

  } catch (error) {
    console.error('[Profile] Error:', error);
    return jsonResponse({ error: 'Failed to update profile' }, 500, request);
  }
}

/**
 * DELETE /account - Delete user account
 *
 * Supports two modes:
 * - Soft delete (default): Marks account as deleted but retains data
 * - Hard delete (GDPR): Permanently removes all user data from the database
 *
 * Request body:
 * - password: Required for verification
 * - hard_delete: Optional boolean (default: false). If true, permanently deletes data.
 */
async function handleDeleteAccount(request, env) {
  if (request.method !== 'DELETE') {
    return jsonResponse({ error: 'Method not allowed' }, 405, request);
  }

  try {
    // Extract and verify token
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return jsonResponse({ error: 'No token provided' }, 401, request);
    }

    const token = authHeader.substring(7);

    // Check if token is blacklisted (logged out)
    if (isTokenBlacklisted(token)) {
      return jsonResponse({ error: 'Token has been invalidated' }, 401, request);
    }

    const payload = await verifyJWT(token, env);

    if (!payload) {
      return jsonResponse({ error: 'Invalid or expired token' }, 401, request);
    }

    const { password, hard_delete = false } = await request.json();

    if (!password) {
      return jsonResponse({ error: 'Password is required to delete account' }, 400, request);
    }

    // Get user and verify password
    const user = await findUserById(payload.userId, env);
    if (!user) {
      return jsonResponse({ error: 'User not found' }, 404, request);
    }

    const passwordValid = await verifyPassword(password, user.password_hash, env);
    if (!passwordValid) {
      return jsonResponse({ error: 'Incorrect password' }, 401, request);
    }

    if (hard_delete) {
      // GDPR Hard Delete - permanently remove user from database
      console.log(`[DeleteAccount] Hard deleting user ${user.id}`);

      // Delete user from main database
      const deleted = await deleteUser(user.id, env);
      if (!deleted) {
        console.error('[DeleteAccount] Failed to hard delete user from database');
        // Fall back to soft delete if hard delete fails
        await updateUser(user.id, {
          status: 'deleted',
          email: `deleted_${user.id}_${user.email}`,
        }, env);
      }

      // Also remove push subscription if exists (cleanup)
      try {
        await deletePushSubscription(user.id, env);
      } catch (e) {
        console.log('[DeleteAccount] No push subscription to delete or error:', e);
      }
    } else {
      // Soft delete - mark as deleted (original behavior)
      console.log(`[DeleteAccount] Soft deleting user ${user.id}`);
      await updateUser(user.id, {
        status: 'deleted',
        email: `deleted_${user.id}_${user.email}`, // Prevent email reuse issues
      }, env);
    }

    // Blacklist the token to prevent further use
    if (payload.exp) {
      blacklistToken(token, payload.exp * 1000);
    }

    const deleteType = hard_delete ? 'permanently' : 'successfully';
    return jsonResponse({ message: `Account deleted ${deleteType}` }, 200, request);

  } catch (error) {
    console.error('[DeleteAccount] Error:', error);
    return jsonResponse({ error: 'Failed to delete account' }, 500, request);
  }
}

// ============================================
// DATABASE HELPERS (NoCodeBackend)
// ============================================

/**
 * Create a new user in NoCodeBackend
 */
async function createUser(userData, env) {
  const instance = env.NOCODEBACKEND_INSTANCE || '36905_activation_codes';
  const response = await fetch(`${env.NOCODEBACKEND_API_URL}/create/users?Instance=${instance}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
    },
    body: JSON.stringify(userData),
  });

  const result = await response.json();
  if (result.status === 'success') {
    return { id: result.id, ...userData };
  }
  throw new Error(result.message || 'Failed to create user');
}

/**
 * Find user by email
 */
async function findUserByEmail(email, env) {
  const instance = env.NOCODEBACKEND_INSTANCE || '36905_activation_codes';
  const response = await fetch(`${env.NOCODEBACKEND_API_URL}/search/users?Instance=${instance}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
    },
    body: JSON.stringify({ email }),
  });

  const result = await response.json();
  if (result.status === 'success' && result.data && result.data.length > 0) {
    return result.data[0];
  }
  return null;
}

/**
 * Find user by ID
 */
async function findUserById(id, env) {
  const instance = env.NOCODEBACKEND_INSTANCE || '36905_activation_codes';
  const response = await fetch(`${env.NOCODEBACKEND_API_URL}/read/users/${id}?Instance=${instance}`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
    },
  });

  const result = await response.json();
  if (result.status === 'success' && result.data) {
    return result.data;
  }
  return null;
}

/**
 * Find user by reset token
 */
async function findUserByResetToken(token, env) {
  const instance = env.NOCODEBACKEND_INSTANCE || '36905_activation_codes';
  const response = await fetch(`${env.NOCODEBACKEND_API_URL}/search/users?Instance=${instance}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
    },
    body: JSON.stringify({ reset_token: token }),
  });

  const result = await response.json();
  if (result.status === 'success' && result.data && result.data.length > 0) {
    return result.data[0];
  }
  return null;
}

/**
 * Find user by verification token
 */
async function findUserByVerificationToken(token, env) {
  const instance = env.NOCODEBACKEND_INSTANCE || '36905_activation_codes';
  const response = await fetch(`${env.NOCODEBACKEND_API_URL}/search/users?Instance=${instance}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
    },
    body: JSON.stringify({ verification_token: token }),
  });

  const result = await response.json();
  if (result.status === 'success' && result.data && result.data.length > 0) {
    return result.data[0];
  }
  return null;
}

/**
 * Update user by ID
 */
async function updateUser(id, updates, env) {
  const instance = env.NOCODEBACKEND_INSTANCE || '36905_activation_codes';
  const response = await fetch(`${env.NOCODEBACKEND_API_URL}/update/users/${id}?Instance=${instance}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
    },
    body: JSON.stringify(updates),
  });

  const result = await response.json();
  return result.status === 'success';
}

/**
 * Permanently delete a user from NoCodeBackend (GDPR hard delete)
 */
async function deleteUser(id, env) {
  const instance = env.NOCODEBACKEND_INSTANCE || '36905_activation_codes';
  try {
    const response = await fetch(`${env.NOCODEBACKEND_API_URL}/delete/users/${id}?Instance=${instance}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.NOCODEBACKEND_API_KEY}`,
      },
    });

    const result = await response.json();
    console.log(`[deleteUser] Result for ${id}:`, result);
    return result.status === 'success';
  } catch (error) {
    console.error('[deleteUser] Error:', error);
    return false;
  }
}

/**
 * Delete push subscription from KV storage (cleanup for hard delete)
 */
async function deletePushSubscription(userId, env) {
  // Check if KV binding exists
  if (!env.PUSH_SUBSCRIPTIONS) {
    console.log('[deletePushSubscription] KV not available');
    return false;
  }

  try {
    // Delete subscription by user ID
    await env.PUSH_SUBSCRIPTIONS.delete(`user:${userId}`);
    console.log(`[deletePushSubscription] Deleted subscription for user ${userId}`);
    return true;
  } catch (error) {
    console.error('[deletePushSubscription] Error:', error);
    return false;
  }
}

// ============================================
// CRYPTO & JWT HELPERS
// ============================================

/**
 * Hash password using PBKDF2
 * Uses 600,000 iterations per OWASP 2024 recommendations
 */
async function hashPassword(password, env = null) {
  const encoder = new TextEncoder();
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const passwordData = encoder.encode(password);

  // Use env variable if available, otherwise default to 600000 (OWASP 2024)
  const iterations = env?.PBKDF2_ITERATIONS ? parseInt(env.PBKDF2_ITERATIONS) : 600000;

  const key = await crypto.subtle.importKey(
    'raw',
    passwordData,
    'PBKDF2',
    false,
    ['deriveBits']
  );

  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt: salt,
      iterations: iterations,
      hash: 'SHA-256',
    },
    key,
    256
  );

  const hashArray = new Uint8Array(derivedBits);
  const combined = new Uint8Array(salt.length + hashArray.length);
  combined.set(salt);
  combined.set(hashArray, salt.length);

  return btoa(String.fromCharCode(...combined));
}

/**
 * Verify password against hash
 * Supports both legacy (100k) and new (600k) iteration counts for migration
 */
async function verifyPassword(password, storedHash, env = null) {
  try {
    const combined = Uint8Array.from(atob(storedHash), c => c.charCodeAt(0));
    const salt = combined.slice(0, 16);
    const storedHashBytes = combined.slice(16);

    const encoder = new TextEncoder();
    const passwordData = encoder.encode(password);

    const key = await crypto.subtle.importKey(
      'raw',
      passwordData,
      'PBKDF2',
      false,
      ['deriveBits']
    );

    // Try with current iteration count first (600000)
    const currentIterations = env?.PBKDF2_ITERATIONS ? parseInt(env.PBKDF2_ITERATIONS) : 600000;

    let derivedBits = await crypto.subtle.deriveBits(
      {
        name: 'PBKDF2',
        salt: salt,
        iterations: currentIterations,
        hash: 'SHA-256',
      },
      key,
      256
    );

    let computedHash = new Uint8Array(derivedBits);

    // Check if current iterations work
    if (computedHash.length === storedHashBytes.length) {
      let result = 0;
      for (let i = 0; i < computedHash.length; i++) {
        result |= computedHash[i] ^ storedHashBytes[i];
      }
      if (result === 0) return true;
    }

    // Fall back to legacy iteration count (100000) for existing passwords
    derivedBits = await crypto.subtle.deriveBits(
      {
        name: 'PBKDF2',
        salt: salt,
        iterations: 100000,
        hash: 'SHA-256',
      },
      key,
      256
    );

    computedHash = new Uint8Array(derivedBits);

    // Constant-time comparison for legacy hash
    if (computedHash.length !== storedHashBytes.length) return false;
    let legacyResult = 0;
    for (let i = 0; i < computedHash.length; i++) {
      legacyResult |= computedHash[i] ^ storedHashBytes[i];
    }
    return legacyResult === 0;
  } catch (error) {
    console.error('[VerifyPassword] Error:', error);
    return false;
  }
}

/**
 * Format date to MySQL datetime format (YYYY-MM-DD HH:MM:SS)
 */
function formatMySQLDatetime(date) {
  if (!date) return '';
  const d = new Date(date);
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())} ${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())}:${pad(d.getUTCSeconds())}`;
}

/**
 * Generate random token
 */
function generateToken() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * Generate JWT token
 */
async function generateJWT(payload, env) {
  const header = {
    alg: 'HS256',
    typ: 'JWT',
  };

  const now = Math.floor(Date.now() / 1000);
  const expiresIn = parseInt(env.JWT_EXPIRES_IN || '604800');

  const jwtPayload = {
    ...payload,
    iat: now,
    exp: now + expiresIn,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(jwtPayload));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;

  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(env.JWT_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(signatureInput)
  );

  const encodedSignature = base64UrlEncode(String.fromCharCode(...new Uint8Array(signature)));

  return `${signatureInput}.${encodedSignature}`;
}

/**
 * Verify JWT token
 */
async function verifyJWT(token, env) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;

    const [encodedHeader, encodedPayload, encodedSignature] = parts;
    const signatureInput = `${encodedHeader}.${encodedPayload}`;

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(env.JWT_SECRET),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    );

    const signatureBytes = Uint8Array.from(
      base64UrlDecode(encodedSignature),
      c => c.charCodeAt(0)
    );

    const valid = await crypto.subtle.verify(
      'HMAC',
      key,
      signatureBytes,
      encoder.encode(signatureInput)
    );

    if (!valid) return null;

    const payload = JSON.parse(base64UrlDecode(encodedPayload));

    // Check expiration
    if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
      return null;
    }

    return payload;
  } catch (error) {
    console.error('[VerifyJWT] Error:', error);
    return null;
  }
}

/**
 * Base64 URL encode
 */
function base64UrlEncode(str) {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

/**
 * Base64 URL decode
 */
function base64UrlDecode(str) {
  let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4) {
    base64 += '=';
  }
  return atob(base64);
}

// ============================================
// EMAIL HELPERS
// ============================================

/**
 * Send verification email
 */
async function sendVerificationEmail(email, token, locale, firstName, env) {
  const verifyUrl = `${env.APP_URL_WEB}/verify-email?token=${token}`;
  const subject = locale === 'es' ? 'Verifique su Correo - Everyday Christian' : 'Verify Your Email - Everyday Christian';
  const body = locale === 'es'
    ? getVerificationEmailHTML_ES(verifyUrl, firstName)
    : getVerificationEmailHTML_EN(verifyUrl, firstName);
  return sendEmail(email, subject, body, env);
}

/**
 * Send password reset email
 */
async function sendPasswordResetEmail(email, token, locale, firstName, env) {
  const resetUrl = `${env.APP_URL_WEB}/reset-password?token=${token}`;
  const subject = locale === 'es' ? 'Restablecer Contraseña - Everyday Christian' : 'Reset Your Password - Everyday Christian';
  const body = locale === 'es'
    ? getPasswordResetEmailHTML_ES(resetUrl, firstName)
    : getPasswordResetEmailHTML_EN(resetUrl, firstName);
  return sendEmail(email, subject, body, env);
}

/**
 * Branded email base template
 */
function getEmailBaseHTML(content, locale = 'en') {
  return `<!DOCTYPE html>
<html lang="${locale}" xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light dark">
  <meta name="supported-color-schemes" content="light dark">
  <!--[if mso]>
  <noscript>
    <xml>
      <o:OfficeDocumentSettings>
        <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
  </noscript>
  <![endif]-->
  <style>
    :root { color-scheme: light dark; supported-color-schemes: light dark; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif; line-height: 1.6; margin: 0; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    [data-ogsc] .email-wrapper, .email-wrapper { background-color: #0f0f1e !important; }
    [data-ogsc] .email-container, .email-container { background-color: #1a1b2e !important; }
    [data-ogsc] .header, .header { background-color: #1a1b2e !important; }
    [data-ogsc] .content, .content { background-color: #1a1b2e !important; }
    [data-ogsc] .footer, .footer { background-color: #0f0f1e !important; }
    [data-ogsc] .header-title, .header-title { color: #ffffff !important; }
    [data-ogsc] .greeting, .greeting { color: #ffffff !important; }
    [data-ogsc] .message, .message { color: #cccccc !important; }
    [data-ogsc] .cta-button, .cta-button { background-color: #FDB022 !important; color: #1a1b2e !important; }
    [data-ogsc] .tip-box, .tip-box { background-color: #2a2b3e !important; border-color: #FDB022 !important; }
    [data-ogsc] .tip-text, .tip-text { color: #e0e0e0 !important; }
    [data-ogsc] .footer-text, .footer-text { color: #999999 !important; }
    [data-ogsc] .contact-link, .contact-link { color: #FDB022 !important; }
    @media (prefers-color-scheme: dark) {
      .email-wrapper { background-color: #0f0f1e !important; }
      .email-container, .header, .content { background-color: #1a1b2e !important; }
      .footer { background-color: #0f0f1e !important; }
      .header-title, .greeting { color: #ffffff !important; }
      .message { color: #cccccc !important; }
      .cta-button { background-color: #FDB022 !important; color: #1a1b2e !important; }
    }
    @media only screen and (max-width: 600px) {
      .email-wrapper { padding: 20px 10px !important; }
      .header { padding: 32px 24px !important; }
      .content { padding: 32px 24px !important; }
      .header-title { font-size: 24px !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: #0f0f1e; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%;">
  <div class="email-wrapper" style="background-color: #0f0f1e; padding: 40px 20px;">
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width: 600px; margin: 0 auto;">
      <tr>
        <td class="email-container" style="background-color: #1a1b2e; border-radius: 8px; overflow: hidden;">
          <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
            <tr>
              <td class="header" style="background-color: #1a1b2e; padding: 40px 30px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.1);">
                <img src="https://everydaychristian.app/images/logo-email.png" alt="Everyday Christian" width="80" height="80" style="display: block; margin: 0 auto 20px; width: 80px; height: 80px;" />
                <h1 class="header-title" style="color: #ffffff !important; font-size: 28px; font-weight: 600; margin: 0 0 8px 0; -webkit-text-fill-color: #ffffff;">Everyday Christian</h1>
              </td>
            </tr>
            <tr>
              <td>${content}</td>
            </tr>
            <tr>
              <td class="footer" style="background-color: #0f0f1e; padding: 32px 30px; text-align: center; border-top: 1px solid rgba(255,255,255,0.1);">
                <p class="footer-text" style="color: #999999 !important; font-size: 13px; line-height: 1.8; margin: 0; -webkit-text-fill-color: #999999;">
                  © 2025 Everyday Christian<br>
                  <a href="mailto:connect@everydaychristian.app" class="contact-link" style="color: #FDB022 !important; text-decoration: none; font-weight: 500; -webkit-text-fill-color: #FDB022;">connect@everydaychristian.app</a>
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </div>
</body>
</html>`;
}

/**
 * Verification email - English
 */
function getVerificationEmailHTML_EN(verifyUrl, firstName) {
  const content = `
    <td class="content" style="padding: 40px 30px; background-color: #1a1b2e;">
      <p class="greeting" style="font-size: 18px; color: #ffffff !important; margin: 0 0 16px 0; font-weight: 400; -webkit-text-fill-color: #ffffff;">Welcome${firstName ? `, ${firstName}` : ''}!</p>
      <p class="message" style="color: #cccccc !important; font-size: 15px; margin: 0 0 24px 0; line-height: 1.6; -webkit-text-fill-color: #cccccc;">Thank you for joining Everyday Christian. Please verify your email address to complete your registration.</p>
      <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin: 32px 0;">
        <tr>
          <td align="center">
            <a href="${verifyUrl}" class="cta-button" style="display: inline-block; background-color: #FDB022 !important; color: #1a1b2e !important; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; -webkit-text-fill-color: #1a1b2e;">Verify Email Address</a>
          </td>
        </tr>
      </table>
      <p style="color: #999999 !important; font-size: 13px; word-break: break-all; margin: 16px 0; -webkit-text-fill-color: #999999;">Or copy and paste this link:<br>${verifyUrl}</p>
      <div class="tip-box" style="background-color: #2a2b3e !important; border: 1px solid #FDB022; border-radius: 8px; padding: 20px; margin: 24px 0;">
        <p class="tip-text" style="color: #e0e0e0 !important; font-size: 14px; line-height: 1.6; margin: 0; -webkit-text-fill-color: #e0e0e0;"><strong style="color: #FDB022 !important; -webkit-text-fill-color: #FDB022;">Note:</strong> This link expires in 24 hours. If you didn't create an account, you can safely ignore this email.</p>
      </div>
      <p class="message" style="color: #cccccc !important; font-size: 15px; margin: 0; line-height: 1.6; -webkit-text-fill-color: #cccccc;">Blessings,<br>The Everyday Christian Team</p>
    </td>`;
  return getEmailBaseHTML(content, 'en');
}

/**
 * Verification email - Spanish
 */
function getVerificationEmailHTML_ES(verifyUrl, firstName) {
  const content = `
    <td class="content" style="padding: 40px 30px; background-color: #1a1b2e;">
      <p class="greeting" style="font-size: 18px; color: #ffffff !important; margin: 0 0 16px 0; font-weight: 400; -webkit-text-fill-color: #ffffff;">¡Bienvenido${firstName ? `, ${firstName}` : ''}!</p>
      <p class="message" style="color: #cccccc !important; font-size: 15px; margin: 0 0 24px 0; line-height: 1.6; -webkit-text-fill-color: #cccccc;">Gracias por unirte a Everyday Christian. Por favor verifica tu correo electrónico para completar tu registro.</p>
      <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin: 32px 0;">
        <tr>
          <td align="center">
            <a href="${verifyUrl}" class="cta-button" style="display: inline-block; background-color: #FDB022 !important; color: #1a1b2e !important; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; -webkit-text-fill-color: #1a1b2e;">Verificar Correo</a>
          </td>
        </tr>
      </table>
      <p style="color: #999999 !important; font-size: 13px; word-break: break-all; margin: 16px 0; -webkit-text-fill-color: #999999;">O copia y pega este enlace:<br>${verifyUrl}</p>
      <div class="tip-box" style="background-color: #2a2b3e !important; border: 1px solid #FDB022; border-radius: 8px; padding: 20px; margin: 24px 0;">
        <p class="tip-text" style="color: #e0e0e0 !important; font-size: 14px; line-height: 1.6; margin: 0; -webkit-text-fill-color: #e0e0e0;"><strong style="color: #FDB022 !important; -webkit-text-fill-color: #FDB022;">Nota:</strong> Este enlace expira en 24 horas. Si no creaste una cuenta, puedes ignorar este correo.</p>
      </div>
      <p class="message" style="color: #cccccc !important; font-size: 15px; margin: 0; line-height: 1.6; -webkit-text-fill-color: #cccccc;">Bendiciones,<br>El Equipo de Everyday Christian</p>
    </td>`;
  return getEmailBaseHTML(content, 'es');
}

/**
 * Password reset email - English
 */
function getPasswordResetEmailHTML_EN(resetUrl, firstName) {
  const content = `
    <td class="content" style="padding: 40px 30px; background-color: #1a1b2e;">
      <p class="greeting" style="font-size: 18px; color: #ffffff !important; margin: 0 0 16px 0; font-weight: 400; -webkit-text-fill-color: #ffffff;">Hi${firstName ? ` ${firstName}` : ''},</p>
      <p class="message" style="color: #cccccc !important; font-size: 15px; margin: 0 0 24px 0; line-height: 1.6; -webkit-text-fill-color: #cccccc;">We received a request to reset your password. Click the button below to create a new password.</p>
      <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin: 32px 0;">
        <tr>
          <td align="center">
            <a href="${resetUrl}" class="cta-button" style="display: inline-block; background-color: #FDB022 !important; color: #1a1b2e !important; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; -webkit-text-fill-color: #1a1b2e;">Reset Password</a>
          </td>
        </tr>
      </table>
      <p style="color: #999999 !important; font-size: 13px; word-break: break-all; margin: 16px 0; -webkit-text-fill-color: #999999;">Or copy and paste this link:<br>${resetUrl}</p>
      <div class="tip-box" style="background-color: #2a2b3e !important; border: 1px solid #FDB022; border-radius: 8px; padding: 20px; margin: 24px 0;">
        <p class="tip-text" style="color: #e0e0e0 !important; font-size: 14px; line-height: 1.6; margin: 0; -webkit-text-fill-color: #e0e0e0;"><strong style="color: #FDB022 !important; -webkit-text-fill-color: #FDB022;">Note:</strong> This link expires in 24 hours. If you didn't request a password reset, you can safely ignore this email.</p>
      </div>
      <p class="message" style="color: #cccccc !important; font-size: 15px; margin: 0; line-height: 1.6; -webkit-text-fill-color: #cccccc;">Blessings,<br>The Everyday Christian Team</p>
    </td>`;
  return getEmailBaseHTML(content, 'en');
}

/**
 * Password reset email - Spanish
 */
function getPasswordResetEmailHTML_ES(resetUrl, firstName) {
  const content = `
    <td class="content" style="padding: 40px 30px; background-color: #1a1b2e;">
      <p class="greeting" style="font-size: 18px; color: #ffffff !important; margin: 0 0 16px 0; font-weight: 400; -webkit-text-fill-color: #ffffff;">Hola${firstName ? ` ${firstName}` : ''},</p>
      <p class="message" style="color: #cccccc !important; font-size: 15px; margin: 0 0 24px 0; line-height: 1.6; -webkit-text-fill-color: #cccccc;">Recibimos una solicitud para restablecer tu contraseña. Haz clic en el botón a continuación para crear una nueva contraseña.</p>
      <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin: 32px 0;">
        <tr>
          <td align="center">
            <a href="${resetUrl}" class="cta-button" style="display: inline-block; background-color: #FDB022 !important; color: #1a1b2e !important; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; -webkit-text-fill-color: #1a1b2e;">Restablecer Contraseña</a>
          </td>
        </tr>
      </table>
      <p style="color: #999999 !important; font-size: 13px; word-break: break-all; margin: 16px 0; -webkit-text-fill-color: #999999;">O copia y pega este enlace:<br>${resetUrl}</p>
      <div class="tip-box" style="background-color: #2a2b3e !important; border: 1px solid #FDB022; border-radius: 8px; padding: 20px; margin: 24px 0;">
        <p class="tip-text" style="color: #e0e0e0 !important; font-size: 14px; line-height: 1.6; margin: 0; -webkit-text-fill-color: #e0e0e0;"><strong style="color: #FDB022 !important; -webkit-text-fill-color: #FDB022;">Nota:</strong> Este enlace expira en 24 horas. Si no solicitaste restablecer tu contraseña, puedes ignorar este correo.</p>
      </div>
      <p class="message" style="color: #cccccc !important; font-size: 15px; margin: 0; line-height: 1.6; -webkit-text-fill-color: #cccccc;">Bendiciones,<br>El Equipo de Everyday Christian</p>
    </td>`;
  return getEmailBaseHTML(content, 'es');
}

/**
 * Send email via EmailIt
 */
async function sendEmail(to, subject, htmlBody, env) {
  try {
    const response = await fetch('https://api.emailit.com/v1/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.EMAILIT_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'Everyday Christian <connect@everydaychristian.app>',
        to: to,
        reply_to: 'connect@everydaychristian.app',
        subject: subject,
        html: htmlBody,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('[SendEmail] EmailIt error:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('[SendEmail] Error:', error);
    return false;
  }
}

// ============================================
// UTILITY HELPERS
// ============================================

/**
 * Validate email format
 */
function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

/**
 * Remove sensitive fields from user object
 */
function sanitizeUser(user) {
  const { password_hash, verification_token, verification_expires, reset_token, reset_expires, ...safeUser } = user;
  return {
    ...safeUser,
    email_verified: Boolean(safeUser.email_verified),
  };
}

/**
 * JSON response helper with dynamic CORS, security headers, and rate limit headers
 */
function jsonResponse(data, status = 200, request = null, rateLimitResult = null, extraHeaders = {}) {
  const headers = {
    'Content-Type': 'application/json',
    // Security headers
    ...SECURITY_HEADERS,
    // CORS headers
    ...(request ? getCorsHeaders(request) : { 'Access-Control-Allow-Origin': ALLOWED_ORIGINS[0] }),
    // Extra headers (can override defaults)
    ...extraHeaders,
  };

  // Add rate limit headers if provided
  if (rateLimitResult) {
    addRateLimitHeaders(headers, rateLimitResult);
  }

  return new Response(JSON.stringify(data), { status, headers });
}
