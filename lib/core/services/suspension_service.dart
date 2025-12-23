import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Suspension levels following industry standards
enum SuspensionLevel {
  none,        // No suspension
  warning,     // Warning only (0 days)
  short,       // 7 days (2nd violation)
  medium,      // 30 days (3rd violation)
  long,        // 90 days (4th+ violation)
}

/// Violation types
enum ViolationType {
  promptInjection,      // Attempting to jailbreak AI
  automatedUsage,       // Bot/scripted usage
  contentPolicyAbuse,   // Repeated content policy violations (3+ in short time)
  accountSharing,       // Sharing subscription credentials
  apiKeyTheft,          // Attempting to extract API keys
}

/// Service to handle time-based account suspensions for Terms of Service violations
/// Follows industry standards (ChatGPT, Discord, Spotify, YouTube) for progressive enforcement
///
/// Suspension Schedule:
/// - 1st violation: Warning only (0 days)
/// - 2nd violation: 7-day suspension
/// - 3rd violation: 30-day suspension
/// - 4th+ violation: 90-day suspension (repeats indefinitely)
class SuspensionService {
  // Keychain storage (survives app uninstall)
  static const String _keychainSuspensionLevel = 'suspension_level';
  static const String _keychainViolationHistory = 'violation_history';
  static const String _keychainViolationCount = 'violation_count_keychain';

  // SharedPreferences keys (local)
  static const String _keyCurrentSuspensionEnd = 'current_suspension_end';
  static const String _keyLastViolationType = 'last_violation_type';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('SuspensionService initialized');
  }

  /// Get suspension duration in days for each level
  int _getSuspensionDays(SuspensionLevel level) {
    switch (level) {
      case SuspensionLevel.none:
      case SuspensionLevel.warning:
        return 0;
      case SuspensionLevel.short:
        return 7;
      case SuspensionLevel.medium:
        return 30;
      case SuspensionLevel.long:
        return 90;
    }
  }

  /// Record a violation and apply appropriate suspension
  /// Returns the suspension level applied
  Future<SuspensionLevel> recordViolation(ViolationType type) async {
    try {
      // Get current violation count from Keychain (survives uninstall)
      final currentCount = await _getViolationCountFromKeychain();
      final newCount = currentCount + 1;

      // Store updated count in Keychain
      await _secureStorage.write(
        key: _keychainViolationCount,
        value: newCount.toString(),
      );

      // Store violation type locally
      await _prefs?.setString(_keyLastViolationType, type.toString());

      // Add to violation history (Keychain)
      await _addViolationToHistory(type);

      // Determine suspension level based on violation count
      final suspensionLevel = _calculateSuspensionLevel(newCount);

      // Apply suspension
      await _applySuspension(suspensionLevel);

      // Store suspension level in Keychain
      await _secureStorage.write(
        key: _keychainSuspensionLevel,
        value: suspensionLevel.toString(),
      );

      debugPrint('Violation recorded: $type (Count: $newCount, Level: $suspensionLevel)');

      return suspensionLevel;
    } catch (e) {
      debugPrint('Error recording violation: $e');
      return SuspensionLevel.none;
    }
  }

  /// Get violation count from Keychain
  Future<int> _getViolationCountFromKeychain() async {
    try {
      final countStr = await _secureStorage.read(key: _keychainViolationCount);
      return int.tryParse(countStr ?? '0') ?? 0;
    } catch (e) {
      debugPrint('Error reading violation count: $e');
      return 0;
    }
  }

  /// Calculate suspension level based on violation count
  /// 1st = Warning, 2nd = 7 days, 3rd = 30 days, 4th+ = 90 days
  SuspensionLevel _calculateSuspensionLevel(int violationCount) {
    switch (violationCount) {
      case 1:
        return SuspensionLevel.warning;
      case 2:
        return SuspensionLevel.short; // 7 days
      case 3:
        return SuspensionLevel.medium; // 30 days
      default:
        return SuspensionLevel.long; // 90 days (4th+ violations)
    }
  }

  /// Apply suspension by setting end date
  Future<void> _applySuspension(SuspensionLevel level) async {
    final days = _getSuspensionDays(level);
    if (days > 0) {
      final endDate = DateTime.now().add(Duration(days: days));
      await _prefs?.setString(
        _keyCurrentSuspensionEnd,
        endDate.toIso8601String(),
      );
      debugPrint('Suspension applied until: $endDate ($days days)');
    } else {
      debugPrint('Warning issued (no suspension time)');
    }
  }

  /// Add violation to Keychain history
  Future<void> _addViolationToHistory(ViolationType type) async {
    try {
      final historyJson = await _secureStorage.read(key: _keychainViolationHistory);
      final history = historyJson != null ? historyJson.split('|') : <String>[];

      // Add new violation with timestamp
      final newEntry = '${type.toString()}:${DateTime.now().toIso8601String()}';
      history.add(newEntry);

      // Keep only last 20 violations (prevent unbounded growth)
      final trimmedHistory = history.length > 20
          ? history.sublist(history.length - 20)
          : history;

      await _secureStorage.write(
        key: _keychainViolationHistory,
        value: trimmedHistory.join('|'),
      );
    } catch (e) {
      debugPrint('Error adding violation to history: $e');
    }
  }

  /// Check if user is currently suspended
  Future<bool> isSuspended() async {
    final endDateStr = _prefs?.getString(_keyCurrentSuspensionEnd);
    if (endDateStr == null) return false;

    final endDate = DateTime.parse(endDateStr);
    final isStillSuspended = DateTime.now().isBefore(endDate);

    if (!isStillSuspended) {
      // Suspension expired, clear it
      await _clearCurrentSuspension();
    }

    return isStillSuspended;
  }

  /// Get remaining suspension time
  Future<Duration?> getRemainingTime() async {
    final endDateStr = _prefs?.getString(_keyCurrentSuspensionEnd);
    if (endDateStr == null) return null;

    final endDate = DateTime.parse(endDateStr);
    final remaining = endDate.difference(DateTime.now());

    return remaining.isNegative ? null : remaining;
  }

  /// Get suspension end date
  Future<DateTime?> getSuspensionEndDate() async {
    final endDateStr = _prefs?.getString(_keyCurrentSuspensionEnd);
    if (endDateStr == null) return null;

    return DateTime.parse(endDateStr);
  }

  /// Get current suspension level
  Future<SuspensionLevel> getCurrentSuspensionLevel() async {
    final levelStr = await _secureStorage.read(key: _keychainSuspensionLevel);
    if (levelStr == null) return SuspensionLevel.none;

    // Parse enum
    return SuspensionLevel.values.firstWhere(
      (e) => e.toString() == levelStr,
      orElse: () => SuspensionLevel.none,
    );
  }

  /// Get violation count (from Keychain - survives uninstall)
  Future<int> getViolationCount() async {
    return await _getViolationCountFromKeychain();
  }

  /// Clear current temporary suspension (when time expires)
  Future<void> _clearCurrentSuspension() async {
    await _prefs?.remove(_keyCurrentSuspensionEnd);
    debugPrint('Temporary suspension cleared (time expired)');
  }

  /// Get violation history (for admin/support purposes)
  Future<List<Map<String, dynamic>>> getViolationHistory() async {
    try {
      final historyJson = await _secureStorage.read(key: _keychainViolationHistory);
      if (historyJson == null) return [];

      final entries = historyJson.split('|');
      return entries.map((entry) {
        final parts = entry.split(':');
        if (parts.length >= 2) {
          return {
            'type': parts[0],
            'timestamp': DateTime.parse(parts.sublist(1).join(':')),
          };
        }
        return <String, dynamic>{};
      }).where((entry) => entry.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Error reading violation history: $e');
      return [];
    }
  }

  /// Get user-friendly suspension message
  Future<String> getSuspensionMessage() async {
    final level = await getCurrentSuspensionLevel();
    final remaining = await getRemainingTime();
    final endDate = await getSuspensionEndDate();

    switch (level) {
      case SuspensionLevel.none:
        return '';
      case SuspensionLevel.warning:
        return 'Warning: This is your first violation. Future violations will result in suspension of AI features.';
      case SuspensionLevel.short:
      case SuspensionLevel.medium:
      case SuspensionLevel.long:
        if (remaining != null && endDate != null) {
          final days = remaining.inDays;
          final hours = remaining.inHours % 24;
          final endDateFormatted = '${endDate.month}/${endDate.day}/${endDate.year}';

          return 'Your AI chat access is suspended until $endDateFormatted (${days}d ${hours}h remaining) '
              'due to Terms of Service violations.\n\n'
              'Your subscription remains active. You can still use Bible, Prayer, and Verse Library features.';
        }
        return 'Your AI chat access is temporarily suspended.';
    }
  }

  /// Get short suspension status for UI badges
  Future<String> getSuspensionBadgeText() async {
    final remaining = await getRemainingTime();
    if (remaining == null) return '';

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    if (days > 0) {
      return 'Suspended: ${days}d ${hours}h';
    } else {
      return 'Suspended: ${hours}h';
    }
  }

  /// Testing method: Clear all data (for development only)
  @visibleForTesting
  Future<void> clearAllData() async {
    await _prefs?.remove(_keyCurrentSuspensionEnd);
    await _prefs?.remove(_keyLastViolationType);
    await _secureStorage.delete(key: _keychainSuspensionLevel);
    await _secureStorage.delete(key: _keychainViolationHistory);
    await _secureStorage.delete(key: _keychainViolationCount);
    debugPrint('⚠️  All suspension data cleared (testing only)');
  }

  /// Testing method: Simulate specific suspension level
  @visibleForTesting
  Future<void> simulateSuspension(SuspensionLevel level, {int? customDays}) async {
    final violationCount = level.index;
    await _secureStorage.write(
      key: _keychainViolationCount,
      value: violationCount.toString(),
    );

    // Apply suspension with custom days if provided
    if (customDays != null && customDays > 0) {
      final endDate = DateTime.now().add(Duration(days: customDays));
      await _prefs?.setString(
        _keyCurrentSuspensionEnd,
        endDate.toIso8601String(),
      );
    } else {
      await _applySuspension(level);
    }

    await _secureStorage.write(
      key: _keychainSuspensionLevel,
      value: level.toString(),
    );

    debugPrint('⚠️  Suspension simulated: $level (testing only)');
  }
}
