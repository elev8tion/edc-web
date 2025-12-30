import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token Manager for secure JWT storage and auto-refresh
///
/// Features:
/// - Secure token storage using flutter_secure_storage
/// - Auto-refresh scheduling (5 minutes before expiry)
/// - JWT decoding for expiry time extraction
/// - Token cleanup on logout
class TokenManager {
  static TokenManager? _instance;
  static TokenManager get instance => _instance ??= TokenManager._();

  TokenManager._();

  /// Secure storage instance with Android/iOS optimized settings
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Storage keys
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyTokenExpiry = 'auth_token_expiry';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';

  /// Refresh timer
  Timer? _refreshTimer;

  /// Callback for token refresh - set by AuthService
  Future<String?> Function()? onTokenRefresh;

  /// Callback for token expiration - set by AuthService
  VoidCallback? onTokenExpired;

  /// Stream controller for auth state changes
  final _authStateController = StreamController<bool>.broadcast();

  /// Stream of authentication state changes
  Stream<bool> get authStateStream => _authStateController.stream;

  /// Initialize token manager and check existing tokens
  Future<void> initialize() async {
    final token = await getAccessToken();
    if (token != null) {
      final isValid = !isTokenExpired(token);
      _authStateController.add(isValid);
      if (isValid) {
        scheduleRefresh(token);
      }
    } else {
      _authStateController.add(false);
    }
  }

  /// Store tokens after successful authentication
  Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
    String? userId,
    String? userEmail,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);

    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }

    if (userId != null) {
      await _storage.write(key: _keyUserId, value: userId);
    }

    if (userEmail != null) {
      await _storage.write(key: _keyUserEmail, value: userEmail);
    }

    // Extract and store expiry time
    final expiry = getTokenExpiry(accessToken);
    if (expiry != null) {
      await _storage.write(
        key: _keyTokenExpiry,
        value: expiry.millisecondsSinceEpoch.toString(),
      );
    }

    // Schedule refresh
    scheduleRefresh(accessToken);

    // Notify auth state change
    _authStateController.add(true);

    debugPrint('[TokenManager] Tokens stored successfully');
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      debugPrint('[TokenManager] Error reading access token: $e');
      return null;
    }
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('[TokenManager] Error reading refresh token: $e');
      return null;
    }
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _keyUserId);
    } catch (e) {
      return null;
    }
  }

  /// Get stored user email
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _keyUserEmail);
    } catch (e) {
      return null;
    }
  }

  /// Clear all stored tokens (logout)
  Future<void> clearTokens() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyTokenExpiry);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUserEmail);
    } catch (e) {
      debugPrint('[TokenManager] Error clearing tokens: $e');
    }

    // Notify auth state change
    _authStateController.add(false);

    debugPrint('[TokenManager] Tokens cleared');
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !isTokenExpired(token);
  }

  /// Decode JWT payload
  Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode base64 payload (middle part)
      String payload = parts[1];

      // Add padding if needed
      switch (payload.length % 4) {
        case 1:
          payload += '===';
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      // Replace URL-safe characters
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final decoded = utf8.decode(base64.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[TokenManager] Error decoding token: $e');
      return null;
    }
  }

  /// Get token expiry time
  DateTime? getTokenExpiry(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp == null) return null;

    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    }

    return null;
  }

  /// Check if token is expired
  bool isTokenExpired(String token) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  /// Check if token needs refresh (within 5 minutes of expiry)
  bool tokenNeedsRefresh(String token) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return true;

    final refreshTime = expiry.subtract(const Duration(minutes: 5));
    return DateTime.now().isAfter(refreshTime);
  }

  /// Get user ID from token
  String? getUserIdFromToken(String token) {
    final payload = decodeToken(token);
    return payload?['sub']?.toString() ?? payload?['user_id']?.toString();
  }

  /// Get email from token
  String? getEmailFromToken(String token) {
    final payload = decodeToken(token);
    return payload?['email']?.toString();
  }

  /// Schedule token refresh 5 minutes before expiry
  void scheduleRefresh(String token) {
    _refreshTimer?.cancel();

    final expiry = getTokenExpiry(token);
    if (expiry == null) {
      debugPrint('[TokenManager] Cannot schedule refresh: no expiry in token');
      return;
    }

    final refreshTime = expiry.subtract(const Duration(minutes: 5));
    final delay = refreshTime.difference(DateTime.now());

    if (delay.isNegative) {
      // Token already needs refresh
      debugPrint('[TokenManager] Token needs immediate refresh');
      _performRefresh();
    } else {
      debugPrint('[TokenManager] Scheduling refresh in ${delay.inMinutes} minutes');
      _refreshTimer = Timer(delay, _performRefresh);
    }
  }

  /// Perform token refresh
  Future<void> _performRefresh() async {
    debugPrint('[TokenManager] Performing token refresh');

    if (onTokenRefresh == null) {
      debugPrint('[TokenManager] No refresh callback set');
      return;
    }

    try {
      final newToken = await onTokenRefresh!();

      if (newToken != null) {
        // Get existing refresh token
        final refreshToken = await getRefreshToken();
        final userId = await getUserId();
        final userEmail = await getUserEmail();

        // Store new token
        await storeTokens(
          accessToken: newToken,
          refreshToken: refreshToken,
          userId: userId,
          userEmail: userEmail,
        );

        debugPrint('[TokenManager] Token refreshed successfully');
      } else {
        debugPrint('[TokenManager] Refresh returned null token');
        _handleTokenExpiration();
      }
    } catch (e) {
      debugPrint('[TokenManager] Token refresh failed: $e');
      _handleTokenExpiration();
    }
  }

  /// Handle token expiration
  void _handleTokenExpiration() {
    debugPrint('[TokenManager] Token expired');
    _authStateController.add(false);
    onTokenExpired?.call();
  }

  /// Get authorization header value
  Future<String?> getAuthorizationHeader() async {
    final token = await getAccessToken();
    if (token == null) return null;
    return 'Bearer $token';
  }

  /// Get remaining token lifetime in seconds
  Future<int?> getRemainingLifetime() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final expiry = getTokenExpiry(token);
    if (expiry == null) return null;

    return expiry.difference(DateTime.now()).inSeconds;
  }

  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    _authStateController.close();
  }
}
