import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'secure_storage_service.dart';
import 'biometric_service.dart';
import '../../../core/database/database_helper.dart';

class AuthService extends StateNotifier<AuthState> {
  final SecureStorageService _secureStorage;
  final BiometricService _biometric;
  final DatabaseHelper _database;

  AuthService(this._secureStorage, this._biometric, this._database)
      : super(const AuthState.initial());

  /// Initialize auth service
  Future<void> initialize() async {
    state = const AuthState.loading();

    try {
      // Check for existing user session
      final userData = await _secureStorage.getUserData();
      if (userData != null) {
        final user = User.fromJson(userData);
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error('Failed to initialize auth: $e');
    }
  }

  /// Sign up with email and password
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

      // Check if user already exists
      final existingUser = await _secureStorage.getUserByEmail(email);
      if (existingUser != null) {
        state = const AuthState.error('An account with this email already exists');
        return false;
      }

      // Create new user
      final user = User(
        id: _generateUserId(),
        email: email,
        name: name,
        denomination: denomination,
        preferredVerseThemes: preferredThemes ?? ['hope', 'strength', 'comfort'],
        dateJoined: DateTime.now(),
        profile: const UserProfile(),
      );

      // Hash password and store securely
      final hashedPassword = _hashPassword(password);
      await _secureStorage.storeUserCredentials(email, hashedPassword);
      await _secureStorage.storeUserData(user.toJson());

      // Update user settings in database
      await _updateUserSettings(user);

      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error('Sign up failed: $e');
      return false;
    }
  }

  /// Sign in with email and password
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

      // Validate credentials
      final storedPassword = await _secureStorage.getStoredPassword(email);
      if (storedPassword == null) {
        state = const AuthState.error('No account found with this email');
        return false;
      }

      final hashedPassword = _hashPassword(password);
      if (storedPassword != hashedPassword) {
        state = const AuthState.error('Incorrect password');
        return false;
      }

      // Load user data
      final userData = await _secureStorage.getUserData();
      if (userData == null) {
        state = const AuthState.error('User data not found');
        return false;
      }

      final user = User.fromJson(userData);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error('Sign in failed: $e');
      return false;
    }
  }

  /// Sign in with biometric authentication
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

      // Load user data after successful biometric auth
      final userData = await _secureStorage.getUserData();
      if (userData == null) {
        state = const AuthState.error('User data not found');
        return false;
      }

      final user = User.fromJson(userData);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error('Biometric sign in failed: $e');
      return false;
    }
  }

  /// Continue as guest (anonymous user)
  Future<void> continueAsGuest() async {
    state = const AuthState.loading();

    try {
      final user = User.anonymous();

      // Store anonymous user data temporarily
      await _secureStorage.storeUserData(user.toJson());

      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error('Failed to continue as guest: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AuthState.loading();

    try {
      // Clear secure storage
      await _secureStorage.clearUserData();

      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error('Sign out failed: $e');
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      // Store updated user data
      await _secureStorage.storeUserData(updatedUser.toJson());

      // Update settings in database
      await _updateUserSettings(updatedUser);

      state = AuthState.authenticated(updatedUser);
      return true;
    } catch (e) {
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
      state = AuthState.error('Failed to enable biometric: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await _database.setSetting('biometric_enabled', false);
    } catch (e) {
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
  Future<bool> deleteAccount() async {
    state = const AuthState.loading();

    try {
      // Clear all user data
      await _secureStorage.clearAllData();

      // Clear database (keep structure, remove personal data)
      await _database.deleteOldChatMessages(0); // Delete all chat messages

      state = const AuthState.unauthenticated();
      return true;
    } catch (e) {
      state = AuthState.error('Failed to delete account: $e');
      return false;
    }
  }

  /// Reset password (for local auth, this means creating a new password)
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 6) {
        state = const AuthState.error('Password must be at least 6 characters');
        return false;
      }

      // Check if user exists
      final userData = await _secureStorage.getUserData();
      if (userData == null) {
        state = const AuthState.error('User not found');
        return false;
      }

      final user = User.fromJson(userData);
      if (user.email != email) {
        state = const AuthState.error('Email does not match current user');
        return false;
      }

      // Update password
      final hashedPassword = _hashPassword(newPassword);
      await _secureStorage.storeUserCredentials(email, hashedPassword);

      return true;
    } catch (e) {
      state = AuthState.error('Failed to reset password: $e');
      return false;
    }
  }

  /// Update user settings in database
  Future<void> _updateUserSettings(User user) async {
    try {
      await _database.setSetting('preferred_translation', user.preferredTranslation);
      await _database.setSetting('preferred_verse_themes', jsonEncode(user.preferredVerseThemes));

      if (!user.isAnonymous) {
        await _database.setSetting('user_name', user.name ?? '');
        await _database.setSetting('user_email', user.email ?? '');
        await _database.setSetting('user_denomination', user.denomination ?? '');
      }
    } catch (e) {
      // Log error but don't fail auth
    }
  }

  /// Generate unique user ID
  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString() + DateTime.now().microsecond.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  /// Hash password with salt
  String _hashPassword(String password) {
    const salt = 'everyday_christian_salt_2024'; // In production, use random salt per user
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
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

  /// Check if user is authenticated
  bool get isAuthenticated {
    return state.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );
  }

  /// Check if user is anonymous
  bool get isAnonymous {
    return currentUser?.isAnonymous ?? false;
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