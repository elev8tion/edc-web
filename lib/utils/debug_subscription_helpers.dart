/// Debug helpers for testing subscription functionality
///
/// IMPORTANT: Only use these methods in debug/testing environments!
/// These methods manipulate SharedPreferences to simulate different subscription states.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulate trial expiration by setting the trial start date to X days ago
///
/// Usage:
/// ```dart
/// await DebugSubscriptionHelpers.simulateTrialExpiration(daysAgo: 4);
/// ```
///
/// Default: 4 days ago (1 day past the 3-day trial period)
class DebugSubscriptionHelpers {
  DebugSubscriptionHelpers._(); // Private constructor - use static methods only

  /// Simulate trial expiration by backdating the trial start date
  ///
  /// [daysAgo] - Number of days to backdate the trial start (default: 4)
  ///
  /// After calling this, the trial will appear expired and chat should show paywall.
  /// Hot restart the app to see the changes take effect.
  static Future<void> simulateTrialExpiration({int daysAgo = 4}) async {
    if (!kDebugMode) {
      debugPrint('⚠️  simulateTrialExpiration() can only be called in debug mode!');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Calculate date X days ago
    final expirationDate = DateTime.now().subtract(Duration(days: daysAgo));

    // Set trial start date to X days ago
    await prefs.setString('trial_start_date', expirationDate.toIso8601String());

    debugPrint('✅ [DEBUG] Trial start date set to $daysAgo days ago: $expirationDate');
    debugPrint('📊 [DEBUG] Current status:');
    debugPrint('   - Trial should now be EXPIRED (started $daysAgo days ago)');
    debugPrint('   - Chat should show paywall when attempting to send');
    debugPrint('   - Days past expiration: ${daysAgo - 3}');
    debugPrint('\n⚠️  Hot restart app to see changes take effect');
  }

  /// Reset trial to active state (started now, 3 days remaining)
  ///
  /// Use this to reset back to an active trial after testing expiration.
  static Future<void> resetTrialToActive() async {
    if (!kDebugMode) {
      debugPrint('⚠️  resetTrialToActive() can only be called in debug mode!');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setString('trial_start_date', now.toIso8601String());
    await prefs.setInt('trial_messages_used', 0);

    debugPrint('✅ [DEBUG] Trial reset to active state');
    debugPrint('   - Start date: $now');
    debugPrint('   - Days remaining: 3');
    debugPrint('   - Messages used: 0/15');
    debugPrint('\n⚠️  Hot restart app to see changes take effect');
  }

  /// Simulate X messages have been used in the trial
  ///
  /// [messagesUsed] - Number of messages to mark as used (0-15)
  ///
  /// Useful for testing the 15-message trial limit without sending 15 actual messages.
  static Future<void> simulateTrialMessagesUsed({required int messagesUsed}) async {
    if (!kDebugMode) {
      debugPrint('⚠️  simulateTrialMessagesUsed() can only be called in debug mode!');
      return;
    }

    if (messagesUsed < 0 || messagesUsed > 15) {
      debugPrint('⚠️  Invalid messagesUsed value: $messagesUsed (must be 0-15)');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trial_messages_used', messagesUsed);

    final remaining = 15 - messagesUsed;
    debugPrint('✅ [DEBUG] Trial messages set to $messagesUsed/15 used');
    debugPrint('   - Messages remaining: $remaining');
    if (remaining == 0) {
      debugPrint('   - Trial EXPIRED by message limit!');
      debugPrint('   - Chat should show paywall when attempting to send');
    }
    debugPrint('\n⚠️  Hot restart app to see changes take effect');
  }

  /// Check current trial status from SharedPreferences
  ///
  /// Prints debug info about the current trial state.
  /// Does NOT require app restart - reads current state immediately.
  static Future<void> checkTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStartStr = prefs.getString('trial_start_date');
    final messagesUsed = prefs.getInt('trial_messages_used') ?? 0;

    debugPrint('📊 [DEBUG] Current Trial Status from SharedPreferences:');

    if (trialStartStr == null) {
      debugPrint('   - Status: ❌ NO TRIAL STARTED YET');
      debugPrint('   - User has not sent their first AI message');
      return;
    }

    final trialStart = DateTime.parse(trialStartStr);
    final now = DateTime.now();
    final daysSinceStart = now.difference(trialStart).inDays;
    final daysRemaining = (3 - daysSinceStart).clamp(0, 3);
    final messagesRemaining = (15 - messagesUsed).clamp(0, 15);

    final isExpiredByTime = daysSinceStart >= 3;
    final isExpiredByMessages = messagesUsed >= 15;
    final isExpired = isExpiredByTime || isExpiredByMessages;

    debugPrint('   - Start Date: $trialStart');
    debugPrint('   - Current Date: $now');
    debugPrint('   - Days Since Start: $daysSinceStart / 3');
    debugPrint('   - Days Remaining: $daysRemaining');
    debugPrint('   - Messages Used: $messagesUsed / 15');
    debugPrint('   - Messages Remaining: $messagesRemaining');
    debugPrint('   - Expired by Time: ${isExpiredByTime ? "YES ⚠️" : "NO ✅"}');
    debugPrint('   - Expired by Messages: ${isExpiredByMessages ? "YES ⚠️" : "NO ✅"}');
    debugPrint('   - Overall Status: ${isExpired ? "❌ EXPIRED" : "✅ ACTIVE"}');

    if (isExpired) {
      debugPrint('\n⚠️  Trial is EXPIRED - chat should show paywall');
    }
  }

  /// Clear ALL trial data (reset to brand new user state)
  ///
  /// WARNING: This will clear trial start date, messages used, and trial blocked flag.
  /// Use this to simulate a fresh install.
  static Future<void> clearAllTrialData() async {
    if (!kDebugMode) {
      debugPrint('⚠️  clearAllTrialData() can only be called in debug mode!');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('trial_start_date');
    await prefs.remove('trial_messages_used');
    await prefs.remove('trial_last_reset_date');
    await prefs.remove('trial_blocked');

    debugPrint('✅ [DEBUG] All trial data cleared');
    debugPrint('   - User now appears as brand new (never started trial)');
    debugPrint('   - First AI message will start a fresh 3-day trial');
    debugPrint('\n⚠️  Hot restart app to see changes take effect');
    debugPrint('\n⚠️  Note: Keychain trial marker still persists (use SubscriptionService.clearKeychainForTesting() to reset)');
  }

  /// Print all subscription-related SharedPreferences keys
  ///
  /// Useful for debugging - shows raw data stored in SharedPreferences.
  static Future<void> dumpAllSubscriptionData() async {
    final prefs = await SharedPreferences.getInstance();

    final subscriptionKeys = [
      'trial_start_date',
      'trial_messages_used',
      'trial_last_reset_date',
      'trial_blocked',
      'premium_active',
      'premium_messages_used',
      'premium_last_reset_date',
      'subscription_receipt',
      'premium_expiry_date',
      'premium_original_purchase_date',
      'auto_renew_status',
      'auto_subscribe_attempted',
    ];

    debugPrint('📊 [DEBUG] All Subscription Data in SharedPreferences:');
    debugPrint('=' * 60);

    for (final key in subscriptionKeys) {
      final value = prefs.get(key);
      if (value != null) {
        debugPrint('   $key: $value');
      } else {
        debugPrint('   $key: (not set)');
      }
    }

    debugPrint('=' * 60);
  }
}