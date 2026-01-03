import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'auth_api_service.dart';
import 'secure_storage_service.dart';
import 'biometric_service.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/preferences_service.dart';

/// Auth Service with NoCodeBackend API integration
/// Handles authentication state, token management, and user sessions
class AuthService extends StateNotifier<AuthState> {
  final SecureStorageService _secureStorage;
  final BiometricService _biometric;
  final DatabaseHelper _database;
  final AuthApiService _api;

  // Current JWT token (in-memory for quick access)
  String? _currentToken;

  // Device ID for this device
  String? _deviceId;

  AuthService(this._secureStorage, this._biometric, this._database)
      : _api = AuthApiService(),
        super(const AuthState.initial());

  /// Initialize auth service - check for existing session
  Future<void> initialize() async {
    state = const AuthState.loading();

    try {
      // Get or create device ID
      _deviceId = await _getOrCreateDeviceId();

      // Check for existing token
      final token = await _secureStorage.getSessionToken();
      if (token == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      // Validate token with backend
      final response = await _api.validateToken(token: token);
      if (response.success && response.user != null) {
        _currentToken = token;

        // Load local user data and update with API response
        // Skip email verification - free PWA, users can access app immediately
        final userData = await _secureStorage.getUserData();
        final user = userData != null
            ? User.fromJson(userData).copyWith(
                isNewUser: false,
                isEmailVerified: true,  // Skip verification requirement
              )
            : _authUserToUser(response.user!).copyWith(
                isNewUser: false,
                isEmailVerified: true,  // Skip verification requirement
              );

        state = AuthState.authenticated(user);
      } else {
        // Token invalid - clear and require re-auth
        await _secureStorage.clearUserData();
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      // On network error, check for cached user data
      final userData = await _secureStorage.getUserData();
      if (userData != null) {
        final user = User.fromJson(userData);
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    }
  }

  /// Sign up with email and password (backend API)
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? denomination,
    List<String>? preferredThemes,
  }) async {
    state = const AuthState.loading();

    try {
      // Validate input
      if (!_isValidEmail(email)) {
        state = const AuthState.error('Please enter a valid email address');
        return false;
      }

      if (password.length < 6) {
        state = const AuthState.error('Password must be at least 6 characters');
        return false;
      }

      // Get locale
      final prefs = await PreferencesService.getInstance();
      final locale = prefs.getLocale() ?? 'en';

      // Call API
      final response = await _api.signUp(
        email: email,
        password: password,
        firstName: name,
        locale: locale,
        deviceId: _deviceId!,
      );

      if (!response.success) {
        state = AuthState.error(response.error ?? 'Sign up failed');
        return false;
      }

      // Store token
      if (response.token != null) {
        _currentToken = response.token;
        await _secureStorage.storeSessionToken(response.token!);
      }

      // Create local user from API response
      // Skip email verification - free PWA, go straight to app
      final user = User(
        id: response.user?.id.toString() ?? _generateUserId(),
        email: email,
        name: name,
        denomination: denomination,
        preferredVerseThemes: preferredThemes ?? ['hope', 'strength', 'comfort'],
        dateJoined: DateTime.now(),
        profile: const UserProfile(),
        isAnonymous: false,
        isNewUser: false,  // Skip verification flow
        isEmailVerified: true,  // Skip verification requirement
      );

      // Store user data locally
      await _secureStorage.storeUserData(user.toJson());
      await _updateUserSettings(user);

      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      debugPrint('Sign up error: $e');
      state = AuthState.error('Sign up failed: $e');
      return false;
    }
  }

  /// Sign in with email and password (backend API)
  Future<bool> signIn({
    required String email,
    required String password,
    bool useBiometric = false,
  }) async {
    state = const AuthState.loading();

    try {
      if (useBiometric) {
        return await _signInWithBiometric();
      }

      // Call API
      final response = await _api.signIn(
        email: email,
        password: password,
        deviceId: _deviceId!,
      );

      if (!response.success) {
        state = AuthState.error(response.error ?? 'Sign in failed');
        return false;
      }

      // Store token
      if (response.token != null) {
        _currentToken = response.token;
        await _secureStorage.storeSessionToken(response.token!);
      }

      // Create/update local user
      // Skip email verification - free PWA, users can access app immediately
      final user = _authUserToUser(response.user!).copyWith(
        isNewUser: false,
        isEmailVerified: true,  // Skip verification requirement for sign-in too
      );
      await _secureStorage.storeUserData(user.toJson());
      await _secureStorage.setLastLogin();
      await _updateUserSettings(user);

      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      debugPrint('Sign in error: $e');
      state = AuthState.error('Sign in failed: $e');
      return false;
    }
  }

  /// Sign in with biometric authentication (uses cached credentials)
  Future<bool> _signInWithBiometric() async {
    try {
      final canUseBiometric = await _biometric.canCheckBiometrics();
      if (!canUseBiometric) {
        state = const AuthState.error('Biometric authentication not available');
        return false;
      }

      final authenticated = await _biometric.authenticate();
      if (!authenticated) {
        state = const AuthState.error('Biometric authentication failed');
        return false;
      }

      // Load cached user data after successful biometric auth
      final userData = await _secureStorage.getUserData();
      if (userData == null) {
        state = const AuthState.error('No saved session found');
        return false;
      }

      // Validate token is still valid
      final token = await _secureStorage.getSessionToken();
      if (token != null) {
        final response = await _api.validateToken(token: token);
        if (!response.success) {
          state = const AuthState.error('Session expired. Please sign in again.');
          return false;
        }
        _currentToken = token;
      }

      final user = User.fromJson(userData);
      await _secureStorage.setLastLogin();
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      debugPrint('Biometric sign in error: $e');
      state = AuthState.error('Biometric sign in failed: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AuthState.loading();

    try {
      // Call API to invalidate token
      if (_currentToken != null) {
        await _api.signOut(token: _currentToken!);
      }

      // Clear local session
      _currentToken = null;
      await _secureStorage.clearUserData();

      state = const AuthState.unauthenticated();
    } catch (e) {
      debugPrint('Sign out error: $e');
      // Even on error, clear local session
      _currentToken = null;
      await _secureStorage.clearUserData();
      state = const AuthState.unauthenticated();
    }
  }

  /// Request password reset email
  Future<bool> forgotPassword({required String email}) async {
    try {
      final prefs = await PreferencesService.getInstance();
      final locale = prefs.getLocale() ?? 'en';

      final response = await _api.forgotPassword(
        email: email,
        locale: locale,
      );

      return response.success;
    } catch (e) {
      debugPrint('Forgot password error: $e');
      return false;
    }
  }

  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 6) {
        return false;
      }

      final response = await _api.resetPassword(
        token: token,
        newPassword: newPassword,
      );

      return response.success;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  /// Verify email with token
  Future<bool> verifyEmail({required String token}) async {
    try {
      final response = await _api.verifyEmail(token: token);
      return response.success;
    } catch (e) {
      debugPrint('Verify email error: $e');
      return false;
    }
  }

  /// Resend verification email
  Future<bool> resendVerification({required String email}) async {
    try {
      final prefs = await PreferencesService.getInstance();
      final locale = prefs.getLocale() ?? 'en';

      final response = await _api.resendVerification(
        email: email,
        locale: locale,
      );

      return response.success;
    } catch (e) {
      debugPrint('Resend verification error: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      // Update locally first
      await _secureStorage.storeUserData(updatedUser.toJson());
      await _updateUserSettings(updatedUser);

      // Update on backend if we have a token
      if (_currentToken != null) {
        await _api.updateProfile(
          token: _currentToken!,
          firstName: updatedUser.name,
        );
      }

      state = AuthState.authenticated(updatedUser);
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      state = AuthState.error('Failed to update profile: $e');
      return false;
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      final canUseBiometric = await _biometric.canCheckBiometrics();
      if (!canUseBiometric) {
        state = const AuthState.error('Biometric authentication not available on this device');
        return false;
      }

      final authenticated = await _biometric.authenticate();
      if (authenticated) {
        await _database.setSetting('biometric_enabled', true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Enable biometric error: $e');
      state = AuthState.error('Failed to enable biometric: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await _database.setSetting('biometric_enabled', false);
    } catch (e) {
      debugPrint('Disable biometric error: $e');
      state = AuthState.error('Failed to disable biometric: $e');
    }
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      return await _database.getSetting<bool>('biometric_enabled', defaultValue: false) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount({required String password}) async {
    state = const AuthState.loading();

    try {
      // Call API to delete account
      if (_currentToken != null) {
        final response = await _api.deleteAccount(
          token: _currentToken!,
          password: password,
        );

        if (!response.success) {
          state = AuthState.error(response.error ?? 'Failed to delete account');
          return false;
        }
      }

      // Clear all local data
      _currentToken = null;
      await _secureStorage.clearAllData();
      await _database.deleteOldChatMessages(0);

      state = const AuthState.unauthenticated();
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      state = AuthState.error('Failed to delete account: $e');
      return false;
    }
  }

  /// Update user settings in database
  Future<void> _updateUserSettings(User user) async {
    try {
      await _database.setSetting('preferred_translation', user.preferredTranslation);
      await _database.setSetting('preferred_verse_themes', jsonEncode(user.preferredVerseThemes));

      if (user.name != null) {
        await _database.setSetting('user_name', user.name!);
        // Also save to SharedPreferences for profile screen compatibility
        final prefs = await PreferencesService.getInstance();
        await prefs.saveFirstName(user.name!);
      }
      if (user.email != null) {
        await _database.setSetting('user_email', user.email!);
      }
      if (user.denomination != null) {
        await _database.setSetting('user_denomination', user.denomination!);
      }
    } catch (e) {
      debugPrint('Update user settings error: $e');
    }
  }

  /// Convert AuthUser to User model
  User _authUserToUser(AuthUser authUser, {bool isNewUser = false, bool isEmailVerified = false}) {
    return User(
      id: authUser.id.toString(),
      email: authUser.email,
      name: authUser.firstName,
      dateJoined: authUser.createdAt,
      isAnonymous: false,
      preferredVerseThemes: ['hope', 'strength', 'comfort'],
      profile: const UserProfile(),
      isNewUser: isNewUser,
      isEmailVerified: isEmailVerified,
    );
  }

  /// Generate unique user ID (fallback)
  String _generateUserId() {
    return const Uuid().v4().substring(0, 16);
  }

  /// Get or create device ID
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await PreferencesService.getInstance();
    var deviceId = prefs.getDeviceId();

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setDeviceId(deviceId);
    }

    return deviceId;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Get current user
  User? get currentUser {
    return state.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
  }

  /// Get current JWT token
  String? get token => _currentToken;

  /// Get device ID
  String? get deviceId => _deviceId;

  /// Check if user is authenticated
  bool get isAuthenticated {
    return state.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );
  }

  /// Check if user is anonymous (always false now - no guest mode)
  bool get isAnonymous => false;

  /// Check if the current user's email is verified
  bool isEmailVerified() {
    return state.maybeWhen(
      authenticated: (user) => user.isEmailVerified,
      orElse: () => false,
    );
  }

  /// Refresh user data from the backend to update verification status
  Future<void> refreshUser() async {
    final currentToken = _currentToken;
    if (currentToken == null) {
      debugPrint('RefreshUser: No token found, cannot refresh.');
      return;
    }

    try {
      final response = await _api.validateToken(token: currentToken);
      if (response.success && response.user != null) {
        // Preserve existing local user data while updating from backend
        // Skip email verification - free PWA, users can access app immediately
        final existingUser = currentUser;
        final updatedUser = existingUser?.copyWith(
          // Update from backend response
          email: response.user!.email,
          name: response.user!.firstName ?? existingUser.name,
          isEmailVerified: true,  // Skip verification requirement
          // Preserve local-only fields
          isNewUser: existingUser.isNewUser,
        ) ?? _authUserToUser(response.user!).copyWith(
          isEmailVerified: true,  // Skip verification requirement
        );

        await _secureStorage.storeUserData(updatedUser.toJson());
        state = AuthState.authenticated(updatedUser);
        debugPrint('RefreshUser: User data refreshed. Email verified: ${updatedUser.isEmailVerified}');
      } else {
        debugPrint('RefreshUser: Token invalid or user not found.');
        await signOut(); // Force sign out if token is invalid
      }
    } catch (e) {
      debugPrint('RefreshUser error: $e');
      // Handle network errors gracefully, keep current state
    }
  }
}

/// Auth state management
abstract class AuthState {
  const AuthState();

  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;

  /// Pattern matching helper
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(User user) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    if (this is _Initial) return initial();
    if (this is _Loading) return loading();
    if (this is _Authenticated) return authenticated((this as _Authenticated).user);
    if (this is _Unauthenticated) return unauthenticated();
    if (this is _Error) return error((this as _Error).message);
    throw Exception('Unknown auth state');
  }

  /// Maybe pattern matching
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(User user)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is _Initial && initial != null) return initial();
    if (this is _Loading && loading != null) return loading();
    if (this is _Authenticated && authenticated != null) return authenticated((this as _Authenticated).user);
    if (this is _Unauthenticated && unauthenticated != null) return unauthenticated();
    if (this is _Error && error != null) return error((this as _Error).message);
    return orElse();
  }
}

class _Initial extends AuthState {
  const _Initial();
}

class _Loading extends AuthState {
  const _Loading();
}

class _Authenticated extends AuthState {
  final User user;
  const _Authenticated(this.user);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Authenticated && other.user == user;
  }

  @override
  int get hashCode => user.hashCode;
}

class _Unauthenticated extends AuthState {
  const _Unauthenticated();
}

class _Error extends AuthState {
  final String message;
  const _Error(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Error && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// Providers for dependency injection
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final authServiceProvider = StateNotifierProvider<AuthService, AuthState>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final biometric = ref.watch(biometricServiceProvider);
  final database = DatabaseHelper.instance;

  return AuthService(secureStorage, biometric, database);
});

/// Helper provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authServiceProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});

/// Helper provider for auth status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authServiceProvider);
  return authState.maybeWhen(
    authenticated: (_) => true,
    orElse: () => false,
  );
});
