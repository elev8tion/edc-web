/// Account Lockout Service
/// Implements 3-strike system for crisis detections
/// After 3 crisis events, account is locked for 30 days then deleted

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'crisis_detection_service.dart';

/// Account lockout state
enum LockoutStatus {
  active, // Account is active
  locked, // Account is locked (30-day period)
  pendingDeletion, // Account scheduled for deletion
}

/// Account lockout information
class LockoutInfo {
  final LockoutStatus status;
  final int crisisCount;
  final DateTime? lockoutDate;
  final DateTime? deletionDate;
  final List<CrisisEvent> crisisEvents;

  const LockoutInfo({
    required this.status,
    required this.crisisCount,
    this.lockoutDate,
    this.deletionDate,
    this.crisisEvents = const [],
  });

  bool get isLocked => status == LockoutStatus.locked;
  bool get isPendingDeletion => status == LockoutStatus.pendingDeletion;
  bool get canUseApp => status == LockoutStatus.active;

  /// Days remaining until deletion
  int? get daysUntilDeletion {
    if (deletionDate == null) return null;
    final now = DateTime.now();
    return deletionDate!.difference(now).inDays;
  }

  /// Get warning level (0-3)
  int get warningLevel {
    if (crisisCount >= 3) return 3;
    return crisisCount;
  }

  /// Get warning message
  String getWarningMessage() {
    switch (crisisCount) {
      case 0:
        return '';
      case 1:
        return 'This is your first crisis detection. Two more will result in account lockout for your safety.';
      case 2:
        return 'This is your second crisis detection. One more will lock your account for 30 days.';
      case 3:
        return 'Your account has been locked due to repeated crisis detections. It will be deleted in 30 days. Please seek professional help.';
      default:
        return '';
    }
  }
}

/// Crisis event record
class CrisisEvent {
  final CrisisType type;
  final DateTime timestamp;
  final String? notes;

  const CrisisEvent({
    required this.type,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
      };

  factory CrisisEvent.fromJson(Map<String, dynamic> json) {
    return CrisisEvent(
      type: CrisisType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => CrisisType.suicide,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
    );
  }
}

/// Service for managing account lockouts based on crisis detections
class AccountLockoutService {
  static const String _keyPrefix = 'crisis_lockout_';
  static const String _keyCrisisCount = '${_keyPrefix}count';
  static const String _keyLockoutDate = '${_keyPrefix}lockout_date';
  static const String _keyDeletionDate = '${_keyPrefix}deletion_date';
  static const String _keyCrisisEvents = '${_keyPrefix}events';
  static const String _keyStatus = '${_keyPrefix}status';

  static const int _maxCrisisCount = 3;
  static const int _lockoutDays = 30;

  final SharedPreferences _prefs;

  AccountLockoutService(this._prefs);

  /// Get current lockout information
  Future<LockoutInfo> getLockoutInfo() async {
    final count = _prefs.getInt(_keyCrisisCount) ?? 0;
    final statusStr = _prefs.getString(_keyStatus);
    final lockoutDateStr = _prefs.getString(_keyLockoutDate);
    final deletionDateStr = _prefs.getString(_keyDeletionDate);

    LockoutStatus status;
    if (statusStr != null) {
      status = LockoutStatus.values.firstWhere(
        (s) => s.toString() == statusStr,
        orElse: () => LockoutStatus.active,
      );
    } else {
      status = count >= _maxCrisisCount ? LockoutStatus.locked : LockoutStatus.active;
    }

    DateTime? lockoutDate;
    if (lockoutDateStr != null) {
      lockoutDate = DateTime.parse(lockoutDateStr);
    }

    DateTime? deletionDate;
    if (deletionDateStr != null) {
      deletionDate = DateTime.parse(deletionDateStr);

      // Check if deletion date has passed
      if (deletionDate.isBefore(DateTime.now())) {
        status = LockoutStatus.pendingDeletion;
      }
    }

    final events = await _getCrisisEvents();

    return LockoutInfo(
      status: status,
      crisisCount: count,
      lockoutDate: lockoutDate,
      deletionDate: deletionDate,
      crisisEvents: events,
    );
  }

  /// Record a crisis event
  /// Returns updated LockoutInfo
  Future<LockoutInfo> recordCrisisEvent(CrisisType type) async {
    final currentInfo = await getLockoutInfo();

    // Don't record if already locked
    if (currentInfo.isLocked) {
      return currentInfo;
    }

    final newCount = currentInfo.crisisCount + 1;
    await _prefs.setInt(_keyCrisisCount, newCount);

    // Add crisis event to history
    final event = CrisisEvent(
      type: type,
      timestamp: DateTime.now(),
      notes: 'Crisis detection #$newCount',
    );
    await _addCrisisEvent(event);

    // If reached max count, lock account
    if (newCount >= _maxCrisisCount) {
      await _lockAccount();
    }

    return getLockoutInfo();
  }

  /// Lock account for 30 days
  Future<void> _lockAccount() async {
    final now = DateTime.now();
    final deletionDate = now.add(const Duration(days: _lockoutDays));

    await _prefs.setString(_keyStatus, LockoutStatus.locked.toString());
    await _prefs.setString(_keyLockoutDate, now.toIso8601String());
    await _prefs.setString(_keyDeletionDate, deletionDate.toIso8601String());
  }

  /// Delete all account data (GDPR compliance)
  Future<void> deleteAccountData() async {
    // Clear all crisis-related data
    await _prefs.remove(_keyCrisisCount);
    await _prefs.remove(_keyLockoutDate);
    await _prefs.remove(_keyDeletionDate);
    await _prefs.remove(_keyCrisisEvents);
    await _prefs.remove(_keyStatus);

    // This should cascade to all user-related data for GDPR compliance

    await _prefs.setString(_keyStatus, LockoutStatus.pendingDeletion.toString());
  }

  /// Check if account should be deleted (30 days passed)
  Future<bool> shouldDeleteAccount() async {
    final info = await getLockoutInfo();

    if (info.deletionDate == null) return false;

    return DateTime.now().isAfter(info.deletionDate!);
  }

  /// Reset lockout (for testing or admin override)
  /// WARNING: Only use for testing or with user consent
  Future<void> resetLockout() async {
    await _prefs.remove(_keyCrisisCount);
    await _prefs.remove(_keyLockoutDate);
    await _prefs.remove(_keyDeletionDate);
    await _prefs.remove(_keyCrisisEvents);
    await _prefs.remove(_keyStatus);
  }

  /// Get crisis event history
  Future<List<CrisisEvent>> _getCrisisEvents() async {
    final eventsJson = _prefs.getString(_keyCrisisEvents);
    if (eventsJson == null) return [];

    try {
      final List<dynamic> eventsList =
          (jsonDecode(eventsJson) as List<dynamic>?) ?? [];
      return eventsList
          .map((e) => CrisisEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add crisis event to history
  Future<void> _addCrisisEvent(CrisisEvent event) async {
    final events = await _getCrisisEvents();
    events.add(event);

    // Keep only last 10 events
    if (events.length > 10) {
      events.removeRange(0, events.length - 10);
    }

    final eventsJson = jsonEncode(events.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyCrisisEvents, eventsJson);
  }

  /// Check if user can continue using app
  Future<bool> canUseApp() async {
    final info = await getLockoutInfo();

    // If pending deletion, cannot use
    if (info.isPendingDeletion) return false;

    // If locked and deletion date passed, cannot use
    if (info.isLocked && await shouldDeleteAccount()) {
      await deleteAccountData();
      return false;
    }

    // If locked but deletion date not passed, cannot use
    if (info.isLocked) return false;

    return true;
  }
}
