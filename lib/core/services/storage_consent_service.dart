import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Consent level for storage usage
enum StorageConsentLevel {
  /// User hasn't made a choice yet
  notSet,

  /// User accepted all storage (IndexedDB, localStorage, analytics)
  acceptAll,

  /// User only accepted essential storage (required for app to function)
  essentialOnly,
}

/// Service for managing EU ePrivacy storage consent
///
/// This service handles user consent for browser storage mechanisms:
/// - IndexedDB (SQLite database on web)
/// - localStorage/SharedPreferences
/// - Service worker caching
///
/// Required for EU ePrivacy Directive compliance.
class StorageConsentService {
  // Singleton pattern
  static StorageConsentService? _instance;
  static SharedPreferences? _preferences;

  // Private constructor
  StorageConsentService._();

  /// Get the singleton instance
  static Future<StorageConsentService> getInstance() async {
    if (_instance == null) {
      _instance = StorageConsentService._();
      await _instance!._init();
    }
    return _instance!;
  }

  /// Initialize SharedPreferences
  Future<void> _init() async {
    try {
      _preferences = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[StorageConsent] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Access the underlying SharedPreferences instance
  SharedPreferences? get prefs => _preferences;

  // Keys for stored preferences
  static const String _consentLevelKey = 'storage_consent_level_v1';
  static const String _consentTimestampKey = 'storage_consent_timestamp';
  static const String _consentVersionKey = 'storage_consent_version';

  // Current consent version - increment when policy changes
  static const int _currentConsentVersion = 1;

  // ============================================================================
  // CONSENT STATE METHODS
  // ============================================================================

  /// Check if user has made a consent choice
  bool hasConsented() {
    final level = _preferences?.getString(_consentLevelKey);
    return level != null && level.isNotEmpty;
  }

  /// Check if consent needs to be re-requested (policy version changed)
  bool needsConsentRefresh() {
    final savedVersion = _preferences?.getInt(_consentVersionKey) ?? 0;
    return savedVersion < _currentConsentVersion;
  }

  /// Get current consent level
  StorageConsentLevel getConsentLevel() {
    final level = _preferences?.getString(_consentLevelKey);
    if (level == null || level.isEmpty) {
      return StorageConsentLevel.notSet;
    }

    switch (level) {
      case 'accept_all':
        return StorageConsentLevel.acceptAll;
      case 'essential_only':
        return StorageConsentLevel.essentialOnly;
      default:
        return StorageConsentLevel.notSet;
    }
  }

  /// Check if user accepted full storage
  bool isFullConsent() {
    return getConsentLevel() == StorageConsentLevel.acceptAll;
  }

  /// Check if user only accepted essential storage
  bool isEssentialOnly() {
    return getConsentLevel() == StorageConsentLevel.essentialOnly;
  }

  /// Get timestamp of when consent was given
  DateTime? getConsentTimestamp() {
    final timestamp = _preferences?.getInt(_consentTimestampKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // ============================================================================
  // CONSENT ACTION METHODS
  // ============================================================================

  /// Accept all storage (full consent)
  Future<bool> acceptAll() async {
    try {
      final results = await Future.wait([
        _preferences?.setString(_consentLevelKey, 'accept_all') ??
            Future.value(false),
        _preferences?.setInt(
                _consentTimestampKey, DateTime.now().millisecondsSinceEpoch) ??
            Future.value(false),
        _preferences?.setInt(_consentVersionKey, _currentConsentVersion) ??
            Future.value(false),
      ]);

      final success = results.every((r) => r);
      if (success) {
        debugPrint('[StorageConsent] User accepted all storage');
      }
      return success;
    } catch (e) {
      debugPrint('[StorageConsent] Failed to save acceptAll: $e');
      return false;
    }
  }

  /// Accept essential storage only
  Future<bool> acceptEssentialOnly() async {
    try {
      final results = await Future.wait([
        _preferences?.setString(_consentLevelKey, 'essential_only') ??
            Future.value(false),
        _preferences?.setInt(
                _consentTimestampKey, DateTime.now().millisecondsSinceEpoch) ??
            Future.value(false),
        _preferences?.setInt(_consentVersionKey, _currentConsentVersion) ??
            Future.value(false),
      ]);

      final success = results.every((r) => r);
      if (success) {
        debugPrint('[StorageConsent] User accepted essential only');
      }
      return success;
    } catch (e) {
      debugPrint('[StorageConsent] Failed to save essentialOnly: $e');
      return false;
    }
  }

  /// Reset consent (for settings screen "Manage Storage Preferences")
  Future<bool> resetConsent() async {
    try {
      final results = await Future.wait([
        _preferences?.remove(_consentLevelKey) ?? Future.value(false),
        _preferences?.remove(_consentTimestampKey) ?? Future.value(false),
        _preferences?.remove(_consentVersionKey) ?? Future.value(false),
      ]);

      final success = results.every((r) => r);
      if (success) {
        debugPrint('[StorageConsent] Consent reset');
      }
      return success;
    } catch (e) {
      debugPrint('[StorageConsent] Failed to reset consent: $e');
      return false;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if storage consent banner should be shown
  ///
  /// Only shows on web platform when:
  /// - User hasn't consented yet, OR
  /// - Consent version has changed
  bool shouldShowConsentBanner() {
    // Only show on web
    if (!kIsWeb) return false;

    // Show if no consent or needs refresh
    return !hasConsented() || needsConsentRefresh();
  }

  /// Get a human-readable consent status string
  String getConsentStatusString() {
    switch (getConsentLevel()) {
      case StorageConsentLevel.acceptAll:
        return 'All storage accepted';
      case StorageConsentLevel.essentialOnly:
        return 'Essential only';
      case StorageConsentLevel.notSet:
        return 'Not set';
    }
  }
}
