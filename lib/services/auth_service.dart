import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import 'token_manager.dart';

/// Authentication Service for Everyday Christian app
///
/// Handles all authentication operations with the Cloudflare Worker backend:
/// - User registration (signup)
/// - Login/logout
/// - Email verification
/// - Password reset
/// - Token management
/// - Profile updates
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._() {
    // Set up token refresh callback
    _tokenManager.onTokenRefresh = _refreshTokenInternal;
    _tokenManager.onTokenExpired = _handleTokenExpired;
  }

  /// Base URL for auth API
  static const String baseUrl = 'https://auth.everydaychristian.app';

  /// Request timeout duration
  static const Duration _timeout = Duration(seconds: 30);

  /// Token manager instance
  final TokenManager _tokenManager = TokenManager.instance;

  /// HTTP client (reusable)
  final http.Client _client = http.Client();

  /// Current authenticated user (cached)
  AuthUser? _currentUser;

  /// Get current user
  AuthUser? get currentUser => _currentUser;

  /// Check if user is authenticated
  Future<bool> get isAuthenticated => _tokenManager.isAuthenticated();

  /// Stream of authentication state changes
  Stream<bool> get authStateStream => _tokenManager.authStateStream;

  /// Initialize auth service
  Future<void> initialize() async {
    await _tokenManager.initialize();

    // Try to load user data if authenticated
    if (await isAuthenticated) {
      try {
        await getProfile();
      } catch (e) {
        debugPrint('[AuthService] Failed to load profile on init: $e');
      }
    }
  }

  // ============================================================
  // CORE AUTHENTICATION
  // ============================================================

  /// Sign up a new user
  ///
  /// [email] - User's email address
  /// [password] - User's password (min 8 characters)
  /// [firstName] - Optional first name
  /// [locale] - Optional locale (e.g., 'en', 'es')
  /// [deviceId] - Optional device identifier
  ///
  /// Returns [AuthResult] with token and user on success
  /// Throws [AuthException] on failure
  Future<AuthResult> signup(
    String email,
    String password, {
    String? firstName,
    String? locale,
    String? deviceId,
  }) async {
    final body = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    if (firstName != null && firstName.isNotEmpty) {
      body['first_name'] = firstName.trim();
    }
    if (locale != null) {
      body['locale'] = locale;
    }
    if (deviceId != null) {
      body['device_id'] = deviceId;
    }

    final response = await _post('/signup', body);
    final result = AuthResult.fromJson(response);

    // Store tokens if provided
    if (result.hasTokens) {
      await _tokenManager.storeTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
        userId: result.user?.id,
        userEmail: result.user?.email ?? email,
      );
      _currentUser = result.user;
    }

    return result;
  }

  /// Log in an existing user
  ///
  /// [email] - User's email address
  /// [password] - User's password
  /// [deviceId] - Optional device identifier
  ///
  /// Returns [AuthResult] with token and user on success
  /// Throws [AuthException] on failure
  Future<AuthResult> login(
    String email,
    String password, {
    String? deviceId,
  }) async {
    final body = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    if (deviceId != null) {
      body['device_id'] = deviceId;
    }

    final response = await _post('/login', body);
    final result = AuthResult.fromJson(response);

    // Store tokens
    if (result.hasTokens) {
      await _tokenManager.storeTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
        userId: result.user?.id,
        userEmail: result.user?.email ?? email,
      );
      _currentUser = result.user;
    }

    return result;
  }

  /// Log out the current user
  ///
  /// Clears local tokens and optionally notifies server
  Future<void> logout() async {
    try {
      // Notify server (best effort)
      final token = await _tokenManager.getAccessToken();
      if (token != null) {
        await _post('/logout', {}, authenticated: true).catchError((_) => <String, dynamic>{});
      }
    } finally {
      // Always clear local tokens
      await _tokenManager.clearTokens();
      _currentUser = null;
    }
  }

  // ============================================================
  // EMAIL VERIFICATION
  // ============================================================

  /// Verify email with token from email link
  ///
  /// [token] - Verification token from email
  ///
  /// Returns true on success
  /// Throws [AuthException] on failure
  Future<bool> verifyEmail(String token) async {
    final response = await _post('/verify-email', {'token': token});
    return response['success'] == true;
  }

  /// Resend verification email
  ///
  /// [email] - Email address to send verification to
  /// [locale] - Optional locale for email content
  ///
  /// Returns true on success
  /// Throws [AuthException] on failure
  Future<bool> resendVerification(String email, {String? locale}) async {
    final body = <String, dynamic>{
      'email': email.trim().toLowerCase(),
    };

    if (locale != null) {
      body['locale'] = locale;
    }

    final response = await _post('/resend-verification', body);
    return response['success'] == true;
  }

  // ============================================================
  // PASSWORD MANAGEMENT
  // ============================================================

  /// Request password reset email
  ///
  /// [email] - Email address for password reset
  /// [locale] - Optional locale for email content
  ///
  /// Returns true on success
  /// Throws [AuthException] on failure
  Future<bool> forgotPassword(String email, {String? locale}) async {
    final body = <String, dynamic>{
      'email': email.trim().toLowerCase(),
    };

    if (locale != null) {
      body['locale'] = locale;
    }

    final response = await _post('/forgot-password', body);
    return response['success'] == true;
  }

  /// Reset password with token from email
  ///
  /// [token] - Reset token from email
  /// [newPassword] - New password to set
  ///
  /// Returns true on success
  /// Throws [AuthException] on failure
  Future<bool> resetPassword(String token, String newPassword) async {
    final response = await _post('/reset-password', {
      'token': token,
      'new_password': newPassword,
    });
    return response['success'] == true;
  }

  /// Change password for authenticated user
  ///
  /// [currentPassword] - Current password for verification
  /// [newPassword] - New password to set
  ///
  /// Returns true on success
  /// Throws [AuthException] on failure
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final response = await _post('/change-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    }, authenticated: true);
    return response['success'] == true;
  }

  // ============================================================
  // TOKEN MANAGEMENT
  // ============================================================

  /// Validate current access token
  ///
  /// Returns true if token is valid
  Future<bool> validateToken() async {
    final token = await _tokenManager.getAccessToken();
    if (token == null) return false;

    try {
      final response = await _get('/validate-token', authenticated: true);
      return response['message'] == 'Token is valid';
    } catch (e) {
      return false;
    }
  }

  /// Refresh access token using refresh token
  ///
  /// Returns new access token on success
  /// Throws [AuthException] on failure
  Future<String?> refreshToken() async {
    return await _refreshTokenInternal();
  }

  /// Internal refresh token implementation
  Future<String?> _refreshTokenInternal() async {
    try {
      final response = await _post('/refresh-token', {}, authenticated: true);

      final newToken = response['token'] as String? ??
                       response['access_token'] as String?;

      if (newToken != null) {
        final refreshToken = await _tokenManager.getRefreshToken();
        await _tokenManager.storeTokens(
          accessToken: newToken,
          refreshToken: refreshToken,
          userId: await _tokenManager.getUserId(),
          userEmail: await _tokenManager.getUserEmail(),
        );
        return newToken;
      }

      return null;
    } catch (e) {
      debugPrint('[AuthService] Token refresh failed: $e');
      rethrow;
    }
  }

  /// Get current access token (for manual use)
  Future<String?> getAccessToken() => _tokenManager.getAccessToken();

  /// Get authorization header
  Future<String?> getAuthorizationHeader() => _tokenManager.getAuthorizationHeader();

  // ============================================================
  // USER PROFILE
  // ============================================================

  /// Get current user profile
  ///
  /// Returns [AuthUser] on success
  /// Throws [AuthException] on failure
  Future<AuthUser> getProfile() async {
    final response = await _get('/validate-token', authenticated: true);
    if (response['user'] != null) {
      _currentUser = AuthUser.fromJson(response['user'] as Map<String, dynamic>);
      return _currentUser!;
    }
    throw const AuthException(
      code: 'no_user_data',
      message: 'No user data in response',
    );
  }

  /// Update user profile
  ///
  /// [firstName] - Optional new first name
  /// [locale] - Optional new locale
  ///
  /// Returns updated [AuthUser] on success
  /// Throws [AuthException] on failure
  Future<AuthUser> updateProfile({
    String? firstName,
    String? locale,
  }) async {
    final body = <String, dynamic>{};

    if (firstName != null) {
      body['first_name'] = firstName.trim();
    }
    if (locale != null) {
      body['locale'] = locale;
    }

    if (body.isEmpty) {
      throw const AuthException(
        code: 'validation_error',
        message: 'No fields to update',
      );
    }

    final response = await _patch('/profile', body, authenticated: true);
    if (response['user'] != null) {
      _currentUser = AuthUser.fromJson(response['user'] as Map<String, dynamic>);
      return _currentUser!;
    }
    throw const AuthException(
      code: 'no_user_data',
      message: 'No user data in response',
    );
  }

  /// Delete user account
  ///
  /// [password] - Password for verification
  ///
  /// Returns true on success
  /// Throws [AuthException] on failure
  Future<bool> deleteAccount(String password) async {
    final response = await _delete('/account', {
      'password': password,
    }, authenticated: true);

    if (response['message']?.toString().contains('deleted') == true) {
      await _tokenManager.clearTokens();
      _currentUser = null;
      return true;
    }

    return false;
  }

  // ============================================================
  // PRIVATE HTTP HELPERS
  // ============================================================

  /// Make a GET request
  Future<Map<String, dynamic>> _get(
    String endpoint, {
    bool authenticated = false,
  }) async {
    final headers = await _buildHeaders(authenticated: authenticated);

    try {
      final response = await _client
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw AuthException.network();
    } on TimeoutException {
      throw AuthException.timeout();
    }
  }

  /// Make a POST request
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final headers = await _buildHeaders(authenticated: authenticated);

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw AuthException.network();
    } on TimeoutException {
      throw AuthException.timeout();
    }
  }

  /// Make a PATCH request
  Future<Map<String, dynamic>> _patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final headers = await _buildHeaders(authenticated: authenticated);

    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw AuthException.network();
    } on TimeoutException {
      throw AuthException.timeout();
    }
  }

  /// Make a DELETE request
  Future<Map<String, dynamic>> _delete(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final headers = await _buildHeaders(authenticated: authenticated);

    try {
      final request = http.Request('DELETE', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(headers);
      request.body = jsonEncode(body);

      final streamedResponse = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw AuthException.network();
    } on TimeoutException {
      throw AuthException.timeout();
    }
  }

  /// Build request headers
  Future<Map<String, String>> _buildHeaders({bool authenticated = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final authHeader = await _tokenManager.getAuthorizationHeader();
      if (authHeader != null) {
        headers['Authorization'] = authHeader;
      }
    }

    return headers;
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      body = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Handle errors
    throw AuthException.fromJson(body, statusCode: response.statusCode);
  }

  /// Handle token expiration
  void _handleTokenExpired() {
    _currentUser = null;
    debugPrint('[AuthService] Token expired, user logged out');
  }

  /// Dispose resources
  void dispose() {
    _client.close();
    _tokenManager.dispose();
  }
}
