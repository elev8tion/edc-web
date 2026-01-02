import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Auth states for the application
enum SecureAuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Provider for secure authentication state
final secureAuthProvider = StateNotifierProvider<SecureAuthNotifier, SecureAuthState>((ref) {
  return SecureAuthNotifier();
});

/// Notifier that manages authentication state with secure cookie-based auth
class SecureAuthNotifier extends StateNotifier<SecureAuthState> {
  SecureAuthNotifier() : super(SecureAuthState.initial);

  static const _authWorkerUrl = 'https://edc-auth.connect-2a2.workers.dev';

  // CSRF token stored in memory only (from non-HttpOnly cookie)
  String? _csrfToken;
  String? _userEmail;
  String? _userId;

  String? get userEmail => _userEmail;
  String? get userId => _userId;

  /// Initialize auth state by checking existing session
  Future<void> initialize() async {
    state = SecureAuthState.loading;

    try {
      final response = await http.get(
        Uri.parse('$_authWorkerUrl/api/auth/session'),
        headers: {
          'Content-Type': 'application/json',
          if (_csrfToken != null) 'X-CSRF-Token': _csrfToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _extractCsrfToken(response.headers['set-cookie']);
        _userEmail = data['email'];
        _userId = data['userId'];
        state = SecureAuthState.authenticated;
        debugPrint('[SecureAuth] Session valid for: $_userEmail');
      } else {
        state = SecureAuthState.unauthenticated;
        debugPrint('[SecureAuth] No valid session');
      }
    } catch (e) {
      debugPrint('[SecureAuth] Initialize error: $e');
      state = SecureAuthState.error;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    state = SecureAuthState.loading;

    try {
      final response = await http.post(
        Uri.parse('$_authWorkerUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _extractCsrfToken(response.headers['set-cookie']);
        _userEmail = data['email'] ?? email;
        _userId = data['userId'];
        state = SecureAuthState.authenticated;
        debugPrint('[SecureAuth] Sign in successful: $_userEmail');
        return true;
      } else {
        state = SecureAuthState.unauthenticated;
        debugPrint('[SecureAuth] Sign in failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[SecureAuth] Sign in error: $e');
      state = SecureAuthState.error;
      return false;
    }
  }

  /// Sign out and clear session
  Future<void> signOut() async {
    try {
      await http.post(
        Uri.parse('$_authWorkerUrl/api/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          if (_csrfToken != null) 'X-CSRF-Token': _csrfToken!,
        },
      );
      debugPrint('[SecureAuth] Sign out request sent');
    } catch (e) {
      debugPrint('[SecureAuth] Sign out error: $e');
    } finally {
      _clearSession();
    }
  }

  /// Clear local session data
  void _clearSession() {
    _csrfToken = null;
    _userEmail = null;
    _userId = null;
    state = SecureAuthState.unauthenticated;
  }

  /// Extract CSRF token from Set-Cookie header
  void _extractCsrfToken(String? cookieHeader) {
    if (cookieHeader == null) return;
    final match = RegExp(r'csrf_token=([^;]+)').firstMatch(cookieHeader);
    if (match != null) {
      _csrfToken = match.group(1);
      debugPrint('[SecureAuth] CSRF token extracted');
    }
  }

  /// Force refresh of auth state
  Future<void> refresh() async {
    await initialize();
  }
}
