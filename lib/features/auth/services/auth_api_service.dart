import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Auth API Service for communicating with the Cloudflare Worker backend
/// Handles all authentication operations: signup, login, logout, password reset, email verification
class AuthApiService {
  // Use the deployed Cloudflare Worker URL
  static const String _baseUrl = 'https://auth-service.connect-2a2.workers.dev';

  // Singleton instance
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  /// Sign up a new user
  /// Returns user data with JWT token on success
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? firstName,
    required String locale,
    required String deviceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'password': password,
          'first_name': firstName?.trim(),
          'locale': locale,
          'device_id': deviceId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('SignUp error: $e');
      return AuthResponse.error('Network error. Please check your connection.');
    }
  }

  /// Sign in an existing user
  /// Returns user data with JWT token on success
  Future<AuthResponse> signIn({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'password': password,
          'device_id': deviceId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('SignIn error: $e');
      return AuthResponse.error('Network error. Please check your connection.');
    }
  }

  /// Sign out (invalidates token on backend)
  Future<AuthResponse> signOut({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return AuthResponse.success(message: 'Logged out successfully');
      }
      return _handleResponse(response);
    } catch (e) {
      debugPrint('SignOut error: $e');
      // Even if network fails, we can still clear local session
      return AuthResponse.success(message: 'Logged out locally');
    }
  }

  /// Request password reset email
  Future<AuthResponse> forgotPassword({
    required String email,
    required String locale,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'locale': locale,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('ForgotPassword error: $e');
      return AuthResponse.error('Network error. Please check your connection.');
    }
  }

  /// Reset password with token from email
  Future<AuthResponse> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('ResetPassword error: $e');
      return AuthResponse.error('Network error. Please check your connection.');
    }
  }

  /// Verify email with token from email
  Future<AuthResponse> verifyEmail({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('VerifyEmail error: $e');
      return AuthResponse.error('Network error. Please check your connection.');
    }
  }

  /// Resend verification email
  Future<AuthResponse> resendVerification({
    required String email,
    required String locale,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'locale': locale,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('ResendVerification error: $e');
      return AuthResponse.error('Network error. Please check your connection.');
    }
  }

  /// Validate JWT token (check if still valid)
  Future<AuthResponse> validateToken({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/validate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('ValidateToken error: $e');
      return AuthResponse.error('Token validation failed');
    }
  }

  /// Refresh JWT token
  Future<AuthResponse> refreshToken({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('RefreshToken error: $e');
      return AuthResponse.error('Token refresh failed');
    }
  }

  /// Update user profile (first name, locale)
  Future<AuthResponse> updateProfile({
    required String token,
    String? firstName,
    String? locale,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName.trim();
      if (locale != null) body['locale'] = locale;

      final response = await http.patch(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('UpdateProfile error: $e');
      return AuthResponse.error('Network error. Please check your connection.');
    }
  }

  /// Delete user account
  Future<AuthResponse> deleteAccount({
    required String token,
    required String password,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': password,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('DeleteAccount error: $e');
      return AuthResponse.error('Network error. Please check your connection.');
    }
  }

  /// Handle HTTP response and parse into AuthResponse
  AuthResponse _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthResponse.success(
          message: data['message'] as String?,
          token: data['token'] as String?,
          user: data['user'] != null
              ? AuthUser.fromJson(data['user'] as Map<String, dynamic>)
              : null,
        );
      } else {
        final error = data['error'] as String? ?? 'An error occurred';
        return AuthResponse.error(error);
      }
    } catch (e) {
      debugPrint('Response parsing error: $e');
      return AuthResponse.error('Failed to process response');
    }
  }
}

/// Response model for auth operations
class AuthResponse {
  final bool success;
  final String? message;
  final String? error;
  final String? token;
  final AuthUser? user;

  AuthResponse._({
    required this.success,
    this.message,
    this.error,
    this.token,
    this.user,
  });

  factory AuthResponse.success({
    String? message,
    String? token,
    AuthUser? user,
  }) {
    return AuthResponse._(
      success: true,
      message: message,
      token: token,
      user: user,
    );
  }

  factory AuthResponse.error(String error) {
    return AuthResponse._(
      success: false,
      error: error,
    );
  }
}

/// User model from API response
class AuthUser {
  final int id;
  final String email;
  final String? firstName;
  final String locale;
  final String? stripeCustomerId;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String status;

  AuthUser({
    required this.id,
    required this.email,
    this.firstName,
    required this.locale,
    this.stripeCustomerId,
    required this.emailVerified,
    required this.createdAt,
    this.lastLogin,
    required this.status,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      locale: json['locale'] as String? ?? 'en',
      stripeCustomerId: json['stripe_customer_id'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'locale': locale,
      'stripe_customer_id': stripeCustomerId,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'status': status,
    };
  }

  /// Get display name (first name or email prefix)
  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!;
    }
    return email.split('@').first;
  }

  /// Get initials for avatar
  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Copy with updated fields
  AuthUser copyWith({
    int? id,
    String? email,
    String? firstName,
    String? locale,
    String? stripeCustomerId,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? status,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      locale: locale ?? this.locale,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      status: status ?? this.status,
    );
  }
}
