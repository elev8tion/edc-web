/// Authentication models for the Everyday Christian app
///
/// Contains:
/// - AuthUser: User data from auth API
/// - AuthResult: Response wrapper for auth operations
/// - AuthException: Custom exception for auth errors

/// User data returned from authentication endpoints
class AuthUser {
  final String id;
  final String email;
  final String? firstName;
  final String? locale;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String? stripeCustomerId;
  final String? subscriptionStatus;
  final DateTime? premiumExpires;
  final String? deviceId;

  const AuthUser({
    required this.id,
    required this.email,
    this.firstName,
    this.locale,
    this.emailVerified = false,
    this.createdAt,
    this.lastLoginAt,
    this.stripeCustomerId,
    this.subscriptionStatus,
    this.premiumExpires,
    this.deviceId,
  });

  /// Create AuthUser from API JSON response
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? json['firstName'] as String?,
      locale: json['locale'] as String?,
      emailVerified: json['email_verified'] == 1 ||
                     json['email_verified'] == true ||
                     json['emailVerified'] == true,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      lastLoginAt: _parseDateTime(json['last_login_at'] ?? json['lastLoginAt']),
      stripeCustomerId: json['stripe_customer_id'] as String?,
      subscriptionStatus: json['subscription_status'] as String?,
      premiumExpires: _parseDateTime(json['premium_expires'] ?? json['premiumExpires']),
      deviceId: json['device_id'] as String?,
    );
  }

  /// Convert AuthUser to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'locale': locale,
      'email_verified': emailVerified,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'stripe_customer_id': stripeCustomerId,
      'subscription_status': subscriptionStatus,
      'premium_expires': premiumExpires?.toIso8601String(),
      'device_id': deviceId,
    };
  }

  /// Check if user has premium access
  bool get hasPremium {
    if (premiumExpires == null) return false;
    return premiumExpires!.isAfter(DateTime.now());
  }

  /// Get display name (first name or email prefix)
  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!;
    }
    return email.split('@').first;
  }

  /// Get user initials for avatar
  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName![0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  /// Copy with updated fields
  AuthUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? locale,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? stripeCustomerId,
    String? subscriptionStatus,
    DateTime? premiumExpires,
    String? deviceId,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      locale: locale ?? this.locale,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      premiumExpires: premiumExpires ?? this.premiumExpires,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  /// Parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AuthUser(id: $id, email: $email, firstName: $firstName, verified: $emailVerified)';
  }
}

/// Result wrapper for authentication operations
class AuthResult {
  /// Access token (JWT)
  final String? accessToken;

  /// Refresh token for obtaining new access tokens
  final String? refreshToken;

  /// Authenticated user data
  final AuthUser? user;

  /// Success/info message from server
  final String? message;

  /// Whether the operation was successful
  final bool success;

  const AuthResult({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.message,
    this.success = true,
  });

  /// Create AuthResult from API JSON response
  factory AuthResult.fromJson(Map<String, dynamic> json) {
    AuthUser? user;

    // Parse user from nested 'user' object or from root
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      user = AuthUser.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['id'] != null || json['user_id'] != null) {
      user = AuthUser.fromJson(json);
    }

    return AuthResult(
      accessToken: json['token'] as String? ??
                   json['access_token'] as String? ??
                   json['accessToken'] as String?,
      refreshToken: json['refresh_token'] as String? ??
                    json['refreshToken'] as String?,
      user: user,
      message: json['message'] as String?,
      success: json['success'] as bool? ??
               json['error'] == null,
    );
  }

  /// Create a success result with message only
  factory AuthResult.success({String? message}) {
    return AuthResult(
      success: true,
      message: message,
    );
  }

  /// Create a failure result
  factory AuthResult.failure({String? message}) {
    return AuthResult(
      success: false,
      message: message,
    );
  }

  /// Check if result has tokens
  bool get hasTokens => accessToken != null && accessToken!.isNotEmpty;

  /// Check if result has user data
  bool get hasUser => user != null;

  @override
  String toString() {
    return 'AuthResult(success: $success, hasTokens: $hasTokens, message: $message)';
  }
}

/// Exception for authentication errors
class AuthException implements Exception {
  /// Error code from API (e.g., 'invalid_credentials', 'email_not_verified')
  final String code;

  /// Technical error message
  final String message;

  /// HTTP status code if applicable
  final int? statusCode;

  /// Additional error details
  final Map<String, dynamic>? details;

  const AuthException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  /// Create from API error response
  factory AuthException.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return AuthException(
      code: json['code'] as String? ??
            json['error'] as String? ??
            'unknown_error',
      message: json['message'] as String? ??
               json['error_description'] as String? ??
               'An unknown error occurred',
      statusCode: statusCode ?? json['status'] as int?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Create network error
  factory AuthException.network({String? message}) {
    return AuthException(
      code: 'network_error',
      message: message ?? 'Unable to connect to server',
    );
  }

  /// Create timeout error
  factory AuthException.timeout() {
    return const AuthException(
      code: 'timeout',
      message: 'Request timed out',
    );
  }

  /// Create invalid token error
  factory AuthException.invalidToken() {
    return const AuthException(
      code: 'invalid_token',
      message: 'Authentication token is invalid or expired',
      statusCode: 401,
    );
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (code) {
      case 'invalid_credentials':
        return 'Email or password is incorrect';
      case 'email_not_verified':
        return 'Please verify your email to continue';
      case 'user_exists':
      case 'email_exists':
        return 'An account with this email already exists';
      case 'user_not_found':
        return 'No account found with this email';
      case 'token_expired':
        return 'Your session has expired. Please sign in again.';
      case 'invalid_token':
        return 'Your session is invalid. Please sign in again.';
      case 'rate_limited':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'weak_password':
        return 'Password must be at least 8 characters with a mix of letters and numbers';
      case 'invalid_email':
        return 'Please enter a valid email address';
      case 'network_error':
        return 'Unable to connect. Please check your internet connection.';
      case 'timeout':
        return 'Connection timed out. Please try again.';
      case 'email_send_failed':
        return 'Unable to send email. Please try again later.';
      case 'invalid_verification_token':
        return 'This verification link is invalid or has expired';
      case 'invalid_reset_token':
        return 'This password reset link is invalid or has expired';
      case 'password_mismatch':
        return 'Current password is incorrect';
      case 'account_disabled':
        return 'This account has been disabled. Please contact support.';
      case 'account_locked':
        return 'Account temporarily locked due to too many failed attempts';
      case 'server_error':
        return 'Something went wrong. Please try again later.';
      default:
        if (message.isNotEmpty && !message.contains('error')) {
          return message;
        }
        return 'Something went wrong. Please try again.';
    }
  }

  /// Check if error is retryable
  bool get isRetryable {
    switch (code) {
      case 'network_error':
      case 'timeout':
      case 'server_error':
      case 'rate_limited':
        return true;
      default:
        return statusCode != null && statusCode! >= 500;
    }
  }

  /// Check if error requires re-authentication
  bool get requiresReauth {
    return code == 'token_expired' ||
           code == 'invalid_token' ||
           statusCode == 401;
  }

  /// Check if this is a validation error
  bool get isValidationError {
    return code == 'invalid_email' ||
           code == 'weak_password' ||
           code == 'validation_error';
  }

  @override
  String toString() {
    return 'AuthException(code: $code, message: $message, status: $statusCode)';
  }
}

/// Authentication error codes for reference
abstract class AuthErrorCodes {
  static const String invalidCredentials = 'invalid_credentials';
  static const String emailNotVerified = 'email_not_verified';
  static const String userExists = 'user_exists';
  static const String userNotFound = 'user_not_found';
  static const String tokenExpired = 'token_expired';
  static const String invalidToken = 'invalid_token';
  static const String rateLimited = 'rate_limited';
  static const String weakPassword = 'weak_password';
  static const String invalidEmail = 'invalid_email';
  static const String networkError = 'network_error';
  static const String timeout = 'timeout';
  static const String emailSendFailed = 'email_send_failed';
  static const String invalidVerificationToken = 'invalid_verification_token';
  static const String invalidResetToken = 'invalid_reset_token';
  static const String passwordMismatch = 'password_mismatch';
  static const String accountDisabled = 'account_disabled';
  static const String accountLocked = 'account_locked';
  static const String serverError = 'server_error';
}
