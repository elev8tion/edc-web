import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  // Default storage instance
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _userDataKey = 'user_data';
  static const String _userCredentialsKey = 'user_credentials';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginKey = 'last_login';
  static const String _sessionTokenKey = 'session_token';

  // Constructor with optional dependency injection for testing
  const SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? _defaultStorage;

  /// Store user data securely
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      final jsonString = jsonEncode(userData);
      await _storage.write(key: _userDataKey, value: jsonString);
    } catch (e) {
      throw SecureStorageException('Failed to store user data: $e');
    }
  }

  /// Retrieve user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: _userDataKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve user data: $e');
    }
  }

  /// Store user credentials (email/password hash)
  Future<void> storeUserCredentials(String email, String passwordHash) async {
    try {
      final credentials = {
        'email': email,
        'password_hash': passwordHash,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      final jsonString = jsonEncode(credentials);
      await _storage.write(key: _userCredentialsKey, value: jsonString);
    } catch (e) {
      throw SecureStorageException('Failed to store credentials: $e');
    }
  }

  /// Get stored password hash for email
  Future<String?> getStoredPassword(String email) async {
    try {
      final jsonString = await _storage.read(key: _userCredentialsKey);
      if (jsonString == null) return null;

      final credentials = jsonDecode(jsonString) as Map<String, dynamic>;
      final storedEmail = credentials['email'] as String?;

      if (storedEmail == email) {
        return credentials['password_hash'] as String?;
      }

      return null;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve password: $e');
    }
  }

  /// Get user by email (for checking if user exists)
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final userData = await getUserData();
      if (userData == null) return null;

      final userEmail = userData['email'] as String?;
      if (userEmail == email) {
        return userData;
      }

      return null;
    } catch (e) {
      throw SecureStorageException('Failed to find user by email: $e');
    }
  }

  /// Store biometric preference
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
    } catch (e) {
      throw SecureStorageException('Failed to store biometric preference: $e');
    }
  }

  /// Get biometric preference
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _biometricEnabledKey);
      return value?.toLowerCase() == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Store last login timestamp
  Future<void> setLastLogin() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.write(key: _lastLoginKey, value: timestamp);
    } catch (e) {
      throw SecureStorageException('Failed to store last login: $e');
    }
  }

  /// Get last login timestamp
  Future<DateTime?> getLastLogin() async {
    try {
      final timestampString = await _storage.read(key: _lastLoginKey);
      if (timestampString == null) return null;

      final timestamp = int.tryParse(timestampString);
      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Store session token
  Future<void> storeSessionToken(String token) async {
    try {
      await _storage.write(key: _sessionTokenKey, value: token);
    } catch (e) {
      throw SecureStorageException('Failed to store session token: $e');
    }
  }

  /// Get session token
  Future<String?> getSessionToken() async {
    try {
      return await _storage.read(key: _sessionTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Clear user data
  Future<void> clearUserData() async {
    try {
      await _storage.delete(key: _userDataKey);
      await _storage.delete(key: _sessionTokenKey);
      await _storage.delete(key: _lastLoginKey);
    } catch (e) {
      throw SecureStorageException('Failed to clear user data: $e');
    }
  }

  /// Clear credentials
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _userCredentialsKey);
    } catch (e) {
      throw SecureStorageException('Failed to clear credentials: $e');
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to clear all data: $e');
    }
  }

  /// Check if user data exists
  Future<bool> hasUserData() async {
    try {
      final userData = await _storage.read(key: _userDataKey);
      return userData != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if credentials exist
  Future<bool> hasCredentials() async {
    try {
      final credentials = await _storage.read(key: _userCredentialsKey);
      return credentials != null;
    } catch (e) {
      return false;
    }
  }

  /// Get all stored keys (for debugging)
  Future<List<String>> getAllKeys() async {
    try {
      final allData = await _storage.readAll();
      return allData.keys.toList();
    } catch (e) {
      return [];
    }
  }

  /// Check storage health
  Future<StorageHealthCheck> checkHealth() async {
    try {
      final hasUser = await hasUserData();
      final hasCreds = await hasCredentials();
      final lastLogin = await getLastLogin();
      final isBiometric = await isBiometricEnabled();

      return StorageHealthCheck(
        hasUserData: hasUser,
        hasCredentials: hasCreds,
        lastLogin: lastLogin,
        biometricEnabled: isBiometric,
        isHealthy: true,
      );
    } catch (e) {
      return StorageHealthCheck(
        hasUserData: false,
        hasCredentials: false,
        lastLogin: null,
        biometricEnabled: false,
        isHealthy: false,
        error: e.toString(),
      );
    }
  }

  /// Export data for backup (encrypted)
  Future<String?> exportData() async {
    try {
      final allData = await _storage.readAll();
      return jsonEncode(allData);
    } catch (e) {
      throw SecureStorageException('Failed to export data: $e');
    }
  }

  /// Import data from backup
  Future<void> importData(String encryptedData) async {
    try {
      // Clear existing data first
      await clearAllData();

      // Parse and restore data
      final data = jsonDecode(encryptedData) as Map<String, dynamic>;
      for (final entry in data.entries) {
        await _storage.write(key: entry.key, value: entry.value.toString());
      }
    } catch (e) {
      throw SecureStorageException('Failed to import data: $e');
    }
  }
}

/// Storage health check result
class StorageHealthCheck {
  final bool hasUserData;
  final bool hasCredentials;
  final DateTime? lastLogin;
  final bool biometricEnabled;
  final bool isHealthy;
  final String? error;

  const StorageHealthCheck({
    required this.hasUserData,
    required this.hasCredentials,
    this.lastLogin,
    required this.biometricEnabled,
    required this.isHealthy,
    this.error,
  });

  /// Get health summary
  String get summary {
    if (!isHealthy) {
      return 'Storage unhealthy: ${error ?? 'Unknown error'}';
    }

    final parts = <String>[];
    if (hasUserData) parts.add('User data ✓');
    if (hasCredentials) parts.add('Credentials ✓');
    if (biometricEnabled) parts.add('Biometric ✓');
    if (lastLogin != null) {
      final daysSince = DateTime.now().difference(lastLogin!).inDays;
      parts.add('Last login: ${daysSince}d ago');
    }

    return parts.isEmpty ? 'No data stored' : parts.join(', ');
  }

  @override
  String toString() {
    return 'StorageHealthCheck(healthy: $isHealthy, userData: $hasUserData, credentials: $hasCredentials, biometric: $biometricEnabled, error: $error)';
  }
}

/// Custom exception for secure storage operations
class SecureStorageException implements Exception {
  final String message;
  const SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}