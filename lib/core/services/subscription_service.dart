/// Subscription Service
/// Manages premium subscription state, trial period, and message limits
///
/// Trial: 3 days OR 15 messages total (whichever comes first)
/// Premium: ~$35.99/year (pricing may vary by region and currency), 150 messages/month
///
/// Uses SharedPreferences for local persistence (privacy-first design)
/// Uses Stripe Checkout for web payments (PWA-only, no in-app purchase)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Represents the current subscription state of the user
enum SubscriptionStatus {
  /// Brand new user who hasn't started trial
  neverStarted,

  /// Currently in days 1-3 of trial period
  inTrial,

  /// Trial period ended, no active subscription
  trialExpired,

  /// Active paid subscriber with valid subscription
  premiumActive,

  /// Subscription cancelled but still has time remaining
  premiumCancelled,

  /// Subscription fully expired
  premiumExpired,
}

class SubscriptionService {
  // Singleton instance
  static SubscriptionService? _instance;
  static SubscriptionService get instance {
    _instance ??= SubscriptionService._();
    return _instance!;
  }

  SubscriptionService._();

  // ============================================================================
  // CONSTANTS
  // ============================================================================

  // Product IDs (for reference/tracking only - no IAP)
  static const String premiumYearlyProductId =
      'everyday_christian_free_premium_yearly';
  static const String premiumMonthlyProductId =
      'everyday_christian_free_premium_monthly';

  // Trial configuration
  static const int trialDurationDays = 3;
  static const int trialMessagesPerDay = 5;
  static const int trialTotalMessages =
      trialDurationDays * trialMessagesPerDay; // 15

  // Premium configuration
  static const int premiumMessagesPerMonth = 150;

  // SharedPreferences keys
  static const String _keyTrialStartDate = 'trial_start_date';
  static const String _keyTrialMessagesUsed = 'trial_messages_used';
  static const String _keyTrialLastResetDate = 'trial_last_reset_date';
  static const String _keyPremiumActive = 'premium_active';
  static const String _keyPremiumMessagesUsed = 'premium_messages_used';
  static const String _keyPremiumLastResetDate = 'premium_last_reset_date';
  static const String _keySubscriptionReceipt = 'subscription_receipt';
  // New keys for expiry tracking and trial abuse prevention
  static const String _keyPremiumExpiryDate = 'premium_expiry_date';
  // ignore: unused_field - Reserved for tracking purchase history
  static const String _keyPremiumOriginalPurchaseDate =
      'premium_original_purchase_date';
  // ignore: unused_field - Reserved for trial abuse prevention
  static const String _keyTrialEverUsed = 'trial_ever_used';
  static const String _keyAutoRenewStatus = 'auto_renew_status';
  static const String _keyPurchasedProductId =
      'purchased_product_id'; // Track yearly vs monthly

  // Keychain/KeyStore keys (survives app uninstall for trial abuse prevention)
  static const String _keychainTrialEverUsed = 'trial_ever_used_keychain';
  static const String _keychainTrialMarkedDate = 'trial_marked_date_keychain';

  // ============================================================================
  // PROPERTIES
  // ============================================================================

  SharedPreferences? _prefs;

  // Secure storage for trial abuse prevention (survives app uninstall)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  bool _isInitialized = false;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the service (call this on app start)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // ============================================================
      // TRIAL ABUSE PREVENTION: Check Keychain for previous trial
      // ============================================================
      // This check survives app uninstall/reinstall and prevents
      // users from getting unlimited trials by reinstalling the app.
      // Privacy-first: All data stays on device in secure Keychain/KeyStore
      //
      // ENHANCED: Now includes trial date validation to prevent blocking:
      // - Active ongoing trials (user within 3-day window)
      // - Premium subscribers (even during restore glitches)
      final hasUsedBefore = await hasUsedTrialBefore();

      if (hasUsedBefore && !isPremium) {
        // Keychain says trial was used before AND user is not premium
        // Additional safety: Check if user has an active trial in progress
        final trialStartDate = _getTrialStartDate();

        if (trialStartDate != null) {
          // User has a trial start date - verify if it's actually expired
          final daysSinceStart =
              DateTime.now().difference(trialStartDate).inDays;

          if (daysSinceStart >= trialDurationDays) {
            // Trial period expired (3+ days), safe to block
            await _prefs?.setBool('trial_blocked', true);
            debugPrint(
                '📊 [SubscriptionService] Trial blocked - expired ($daysSinceStart days since start)');
          } else {
            // Trial still within valid 3-day window, don't block
            await _prefs?.setBool('trial_blocked', false);
            debugPrint(
                '📊 [SubscriptionService] Trial active - $daysSinceStart/$trialDurationDays days used');
          }
        } else {
          // No trial start date but Keychain says used before
          // This means trial was fully exhausted in the past, safe to block
          await _prefs?.setBool('trial_blocked', true);
          debugPrint(
              '📊 [SubscriptionService] Trial blocked - previously exhausted on this device');
        }
      } else {
        // Either first-time user OR paid subscriber - allow access
        await _prefs?.setBool('trial_blocked', false);
        if (isPremium) {
          debugPrint(
              '📊 [SubscriptionService] Premium subscriber - trial check bypassed');
        }
      }

      // Initialize counters for first-time users (no trial start date = brand new)
      final trialStartDate = _prefs?.getString(_keyTrialStartDate);
      if (trialStartDate == null) {
        // Brand new user - initialize with 0 messages used
        await _prefs?.setInt(_keyTrialMessagesUsed, 0);
        await _prefs?.setString(_keyTrialLastResetDate,
            DateTime.now().toIso8601String().substring(0, 10));
        debugPrint(
            '📊 [SubscriptionService] First-time user detected - initialized trial counters');
      }

      // Reset message counters if needed
      await _checkAndResetCounters();

      // Check if trial expired while app was closed
      await _checkAndMarkTrialExpiry();

      _isInitialized = true;
      debugPrint('📊 [SubscriptionService] SubscriptionService initialized (PWA mode)');
    } catch (e) {
      debugPrint(
          '📊 [SubscriptionService] Failed to initialize SubscriptionService: $e');
      _isInitialized = true; // Still mark as initialized to prevent blocking
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    // No resources to dispose in PWA mode
  }

  // ============================================================================
  // TRIAL STATUS
  // ============================================================================

  /// Check if user is in trial period (first 3 days)
  bool get isInTrial {
    if (isPremium) return false; // Premium users are not in trial

    // Check if trial is blocked from previous use (survives app uninstall)
    if (isTrialBlocked) return false;

    final trialStartDate = _getTrialStartDate();
    if (trialStartDate == null) return true; // Never started trial = can start

    final now = DateTime.now();
    final daysSinceStart = now.difference(trialStartDate).inDays;
    return daysSinceStart < trialDurationDays;
  }

  /// Check if trial has been used (started)
  bool get hasStartedTrial {
    return _getTrialStartDate() != null;
  }

  /// Check if trial has expired
  bool get hasTrialExpired {
    if (!hasStartedTrial) return false;
    return !isInTrial && !isPremium;
  }

  /// Get days remaining in trial (0 if not in trial)
  int get trialDaysRemaining {
    if (!isInTrial) return 0;

    final trialStartDate = _getTrialStartDate();
    if (trialStartDate == null) return trialDurationDays; // Not started

    final now = DateTime.now();
    final daysSinceStart = now.difference(trialStartDate).inDays;
    return (trialDurationDays - daysSinceStart).clamp(0, trialDurationDays);
  }

  /// Get total trial messages used (no daily reset)
  int get trialMessagesUsed {
    if (!isInTrial) return 0;
    return _prefs?.getInt(_keyTrialMessagesUsed) ?? 0;
  }

  /// Get remaining trial messages (out of 15 total)
  int get trialMessagesRemaining {
    if (!isInTrial) return 0;
    return (trialTotalMessages - trialMessagesUsed)
        .clamp(0, trialTotalMessages);
  }

  /// Start trial (called on first AI message)
  Future<void> startTrial() async {
    if (hasStartedTrial) return;

    // Check if trial is blocked (already used before)
    if (isTrialBlocked) {
      debugPrint(
          '📊 [SubscriptionService] Cannot start trial - already used on this device');
      return;
    }

    await _prefs?.setString(
        _keyTrialStartDate, DateTime.now().toIso8601String());
    await _prefs?.setInt(_keyTrialMessagesUsed, 0);

    debugPrint('📊 [SubscriptionService] Trial started');
  }

  // ============================================================================
  // PREMIUM STATUS
  // ============================================================================

  /// Check if user has active premium subscription
  bool get isPremium {
    // Check if premium flag is set
    final premiumActive = _prefs?.getBool(_keyPremiumActive) ?? false;
    if (!premiumActive) return false;

    // Check if subscription has expired
    final expiryDate = _getExpiryDate();
    if (expiryDate != null) {
      if (DateTime.now().isAfter(expiryDate)) {
        debugPrint(
            '📊 [SubscriptionService] Premium subscription expired on $expiryDate');
        return false;
      }
    }

    // Premium is active and not expired
    return true;
  }

  /// Get detailed subscription status for granular state management
  SubscriptionStatus getSubscriptionStatus() {
    // Check if premium first
    if (isPremium) {
      final expiryDate = _getExpiryDate();
      final autoRenew = _prefs?.getBool(_keyAutoRenewStatus) ?? true;

      // Check if subscription has expired
      if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
        return SubscriptionStatus.premiumExpired;
      }

      // Check if subscription is cancelled but still active
      if (!autoRenew) {
        return SubscriptionStatus.premiumCancelled;
      }

      // Active premium with auto-renew
      return SubscriptionStatus.premiumActive;
    }

    // Check if trial is blocked (used before, survives app uninstall)
    if (isTrialBlocked) {
      return SubscriptionStatus.trialExpired;
    }

    // Check trial status
    final trialStartDate = _getTrialStartDate();

    // User has never started trial
    if (trialStartDate == null) {
      return SubscriptionStatus.neverStarted;
    }

    // Check if still in trial period
    if (isInTrial) {
      return SubscriptionStatus.inTrial;
    }

    // Trial has expired
    return SubscriptionStatus.trialExpired;
  }

  /// Get premium messages used this month
  int get premiumMessagesUsed {
    if (!isPremium) return 0;

    final lastResetDate = _prefs?.getString(_keyPremiumLastResetDate);
    final thisMonth =
        DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM

    // If last reset was not this month, return 0
    if (lastResetDate != thisMonth) return 0;

    return _prefs?.getInt(_keyPremiumMessagesUsed) ?? 0;
  }

  /// Get remaining premium messages this month
  int get premiumMessagesRemaining {
    if (!isPremium) return 0;
    return (premiumMessagesPerMonth - premiumMessagesUsed)
        .clamp(0, premiumMessagesPerMonth);
  }

  /// Get subscription receipt (for verification)
  String? get subscriptionReceipt {
    return _prefs?.getString(_keySubscriptionReceipt);
  }

  // ============================================================================
  // MESSAGE LIMITS
  // ============================================================================

  /// Check if user can send a message (has remaining messages)
  bool get canSendMessage {
    debugPrint(
        '📊 [SubscriptionService] canSendMessage check: kDebugMode=$kDebugMode, isPremium=$isPremium, isInTrial=$isInTrial, trialMessagesRemaining=$trialMessagesRemaining');

    if (isPremium) {
      return premiumMessagesRemaining > 0;
    } else if (isInTrial) {
      return trialMessagesRemaining > 0;
    }
    return false;
  }

  /// Get remaining messages (trial or premium)
  int get remainingMessages {
    if (isPremium) {
      return premiumMessagesRemaining;
    } else if (isInTrial) {
      return trialMessagesRemaining;
    }
    return 0;
  }

  /// Get total messages used (trial or premium)
  int get messagesUsed {
    if (isPremium) {
      return premiumMessagesUsed;
    } else if (isInTrial) {
      return trialMessagesUsed;
    }
    return 0;
  }

  /// Consume one message (call this when sending AI message)
  Future<bool> consumeMessage() async {
    if (!canSendMessage) return false;

    try {
      if (isPremium) {
        // Consume premium message
        final used = premiumMessagesUsed + 1;
        await _prefs?.setInt(_keyPremiumMessagesUsed, used);
        await _updatePremiumResetDate();
        debugPrint(
            '📊 [SubscriptionService] Premium message consumed ($used/$premiumMessagesPerMonth)');
        return true;
      } else if (isInTrial) {
        // Start trial if not started
        if (!hasStartedTrial) {
          await startTrial();
        }

        // Consume trial message (no daily reset)
        final used = trialMessagesUsed + 1;
        await _prefs?.setInt(_keyTrialMessagesUsed, used);
        debugPrint(
            '📊 [SubscriptionService] Trial message consumed ($used/$trialTotalMessages total)');

        // Check if trial just expired (message limit or time limit)
        await _checkAndMarkTrialExpiry();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Failed to consume message: $e');
      return false;
    }
  }

  // ============================================================================
  // STRIPE CHECKOUT (PWA)
  // ============================================================================

  // Stripe Payment Links (Production)
  static const String _paymentLinkYearly = 'https://buy.stripe.com/3cIaEYbLj8ccbq75VZ0RG00';
  static const String _paymentLinkMonthly = 'https://buy.stripe.com/6oU14odTrgIIcubfwz0RG01';

  /// Get Stripe Checkout URL for the selected plan
  String getStripeCheckoutUrl({required bool isYearly, String locale = 'en'}) {
    final url = isYearly ? _paymentLinkYearly : _paymentLinkMonthly;
    debugPrint('💳 [SubscriptionService] Using Payment Link: ${isYearly ? 'yearly' : 'monthly'}');
    return url;
  }

  /// Get the purchased product ID (yearly vs monthly)
  /// Returns null if no subscription purchased
  String? get purchasedProductId => _prefs?.getString(_keyPurchasedProductId);

  /// Check if user has yearly subscription
  bool get hasYearlySubscription {
    final productId = purchasedProductId;
    return productId == premiumYearlyProductId;
  }

  /// Check if user has monthly subscription
  bool get hasMonthlySubscription {
    final productId = purchasedProductId;
    return productId == premiumMonthlyProductId;
  }

  // ============================================================================
  // INTERNAL HELPERS
  // ============================================================================

  /// Get trial start date
  DateTime? _getTrialStartDate() {
    final dateString = _prefs?.getString(_keyTrialStartDate);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  /// Get premium subscription expiry date
  DateTime? _getExpiryDate() {
    final dateString = _prefs?.getString(_keyPremiumExpiryDate);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  /// Update premium reset date (for monthly message counter)
  Future<void> _updatePremiumResetDate() async {
    final thisMonth = DateTime.now().toIso8601String().substring(0, 7);
    await _prefs?.setString(_keyPremiumLastResetDate, thisMonth);
  }

  /// Check and reset message counters (monthly for premium only, trial has no reset)
  Future<void> _checkAndResetCounters() async {
    try {
      // Trial no longer has daily resets - messages counted against 15 total

      // Reset premium counter if needed (monthly)
      if (isPremium) {
        final lastResetDate = _prefs?.getString(_keyPremiumLastResetDate);
        final thisMonth = DateTime.now().toIso8601String().substring(0, 7);

        if (lastResetDate != thisMonth) {
          await _prefs?.setInt(_keyPremiumMessagesUsed, 0);
          await _prefs?.setString(_keyPremiumLastResetDate, thisMonth);
          debugPrint(
              '📊 [SubscriptionService] Premium messages reset for new month');
        }
      }
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Failed to reset counters: $e');
    }
  }

  /// Check if trial has expired and mark in Keychain if so
  /// Marks trial as used when EITHER condition is met:
  /// 1. User has consumed all 15 messages
  /// 2. 3 days have passed since trial started
  Future<void> _checkAndMarkTrialExpiry() async {
    try {
      // Only check if user is in trial (not premium)
      if (isPremium || !hasStartedTrial) return;

      bool shouldMark = false;
      String reason = '';

      // Check message limit (15 total messages)
      final used = trialMessagesUsed;
      if (used >= trialTotalMessages) {
        shouldMark = true;
        reason = '$used/$trialTotalMessages messages exhausted';
      }

      // Check time limit (3 days)
      final trialStartDate = _getTrialStartDate();
      if (trialStartDate != null) {
        final daysSinceStart = DateTime.now().difference(trialStartDate).inDays;
        if (daysSinceStart >= trialDurationDays) {
          shouldMark = true;
          reason = '$daysSinceStart days elapsed';
        }
      }

      // Mark trial as expired in Keychain if limit reached
      if (shouldMark) {
        await markTrialAsUsed();
        debugPrint(
            '📊 [SubscriptionService] Trial expired and marked in Keychain ($reason)');
      }
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Failed to check trial expiry: $e');
      // Non-critical - don't block message sending
    }
  }

  // ============================================================================
  // KEYCHAIN TRIAL TRACKING (SURVIVES APP UNINSTALL)
  // ============================================================================

  /// Check if trial has been used before on this device
  /// Uses iOS Keychain / Android KeyStore which persists across app uninstalls
  ///
  /// Privacy-first: All data stays on device, nothing transmitted to servers
  Future<bool> hasUsedTrialBefore() async {
    try {
      final trialUsed = await _secureStorage.read(key: _keychainTrialEverUsed);
      final hasUsed = trialUsed == 'true';

      if (hasUsed) {
        final markedDate =
            await _secureStorage.read(key: _keychainTrialMarkedDate);
        debugPrint(
            '📊 [SubscriptionService] Trial already used on this device (marked: $markedDate)');
      }

      return hasUsed;
    } catch (e) {
      debugPrint(
          '📊 [SubscriptionService] Error reading Keychain trial status: $e');
      // Fail open - don't block users if Keychain read fails
      return false;
    }
  }

  /// Mark trial as used in Keychain (persists across app uninstalls)
  /// Called when user starts their first trial
  ///
  /// Privacy-first: Stored locally on device in secure Keychain/KeyStore
  Future<void> markTrialAsUsed() async {
    try {
      await _secureStorage.write(key: _keychainTrialEverUsed, value: 'true');
      await _secureStorage.write(
        key: _keychainTrialMarkedDate,
        value: DateTime.now().toIso8601String(),
      );
      debugPrint('📊 [SubscriptionService] Trial marked as used in Keychain');
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Error writing to Keychain: $e');
      // Non-critical failure - continue execution
    }
  }

  /// Check if trial is blocked (used before and not premium)
  /// Returns true if user should be blocked from starting a new trial
  bool get isTrialBlocked {
    return _prefs?.getBool('trial_blocked') ?? false;
  }

  // ============================================================================
  // DEBUG / TESTING
  // ============================================================================

  /// Clear all subscription data (for testing only)
  @visibleForTesting
  Future<void> clearAllData() async {
    await _prefs?.remove(_keyTrialStartDate);
    await _prefs?.remove(_keyTrialMessagesUsed);
    await _prefs?.remove(_keyTrialLastResetDate);
    await _prefs?.remove(_keyPremiumActive);
    await _prefs?.remove(_keyPremiumMessagesUsed);
    await _prefs?.remove(_keyPremiumLastResetDate);
    await _prefs?.remove(_keySubscriptionReceipt);
    await _prefs?.remove('trial_blocked');
    debugPrint(
        '📊 [SubscriptionService] All subscription data cleared (SharedPreferences only)');
    debugPrint(
        '📊 [SubscriptionService] Note: Keychain trial marker persists - use clearKeychainForTesting() to reset');
  }

  /// Clear Keychain trial marker (for testing only)
  /// WARNING: This defeats the trial abuse prevention system
  /// Only use during development/testing
  @visibleForTesting
  Future<void> clearKeychainForTesting() async {
    try {
      await _secureStorage.delete(key: _keychainTrialEverUsed);
      await _secureStorage.delete(key: _keychainTrialMarkedDate);
      await _prefs?.setBool('trial_blocked', false);
      debugPrint(
          '📊 [SubscriptionService] Keychain trial marker cleared - trial can be used again');
      debugPrint(
          '⚠️  [SubscriptionService] WARNING: Only use this method for testing!');
    } catch (e) {
      debugPrint('📊 [SubscriptionService] Error clearing Keychain: $e');
    }
  }

  /// Manually activate premium (for testing only)
  @visibleForTesting
  Future<void> activatePremiumForTesting() async {
    await _prefs?.setBool(_keyPremiumActive, true);
    await _prefs?.setInt(_keyPremiumMessagesUsed, 0);
    await _prefs?.setString(_keyPremiumLastResetDate,
        DateTime.now().toIso8601String().substring(0, 7));
    debugPrint('📊 [SubscriptionService] Premium activated for testing');
  }

  // ============================================================================
  // ACTIVATION CODE VALIDATION
  // ============================================================================

  /// Activate subscription using activation code from Stripe purchase
  /// Returns success status and message
  Future<ActivationResult> activateWithCode(String code) async {
    try {
      debugPrint('🔑 [SubscriptionService] Validating activation code: $code');

      // Generate device ID for tracking
      final deviceId = await _getOrCreateDeviceId();

      // Call Cloudflare Worker validation endpoint
      final validationUrl = dotenv.get('CODE_VALIDATION_URL', fallback: '');

      if (validationUrl.isEmpty) {
        return ActivationResult(
          success: false,
          message:
              'Activation service not configured. Please check your .env file.',
        );
      }

      final response = await http
          .post(
            Uri.parse(validationUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['valid'] == true) {
          // Activate subscription locally
          await _activateSubscriptionFromCode(
            tier: result['tier'],
            subscriptionId: result['subscriptionId'],
            customerId: result['customerId'],
            expiresAt: DateTime.parse(result['expiresAt']),
            activationCode: code,
          );

          debugPrint(
              '✅ [SubscriptionService] Activation successful: ${result['tier']}');

          return ActivationResult(
            success: true,
            message: 'Premium activated! Enjoy ${result['tier']} subscription.',
            tier: result['tier'],
          );
        } else {
          return ActivationResult(
            success: false,
            message: result['error'] ?? 'Invalid activation code',
          );
        }
      } else {
        return ActivationResult(
          success: false,
          message: 'Failed to validate code (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Activation error: $e');
      return ActivationResult(
        success: false,
        message: 'Error validating code: ${e.toString()}',
      );
    }
  }

  /// Get or create unique device ID for activation tracking
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      // Generate new UUID
      deviceId =
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch.toString().substring(7)}';
      await prefs.setString('device_id', deviceId);
      debugPrint('🆔 [SubscriptionService] Generated new device ID: $deviceId');
    }

    return deviceId;
  }

  /// Activate subscription from validated code
  Future<void> _activateSubscriptionFromCode({
    required String tier,
    required String subscriptionId,
    required String customerId,
    required DateTime expiresAt,
    required String activationCode,
  }) async {
    // Set premium active
    await _prefs?.setBool(_keyPremiumActive, true);

    // Set expiry date
    await _prefs?.setString(_keyPremiumExpiryDate, expiresAt.toIso8601String());

    // Set subscription details
    await _prefs?.setString(_keyPurchasedProductId,
        tier == 'yearly' ? premiumYearlyProductId : premiumMonthlyProductId);

    // Store Stripe IDs
    await _prefs?.setString('stripe_subscription_id', subscriptionId);
    await _prefs?.setString('stripe_customer_id', customerId);

    // Store activation code (for reference in settings)
    await _prefs?.setString('activation_code', activationCode);

    // Set auto-renew to true
    await _prefs?.setBool(_keyAutoRenewStatus, true);

    // Reset message counter
    await _prefs?.setInt(_keyPremiumMessagesUsed, 0);
    await _prefs?.setString(_keyPremiumLastResetDate,
        DateTime.now().toIso8601String().substring(0, 7));

    // Mark trial as completed (if applicable)
    if (isInTrial) {
      await markTrialAsUsed();
    }

    debugPrint('✅ [SubscriptionService] Subscription activated: $tier');
  }

  /// Get stored activation code (if exists)
  String? get activationCode => _prefs?.getString('activation_code');

  /// Get debug info
  Map<String, dynamic> get debugInfo {
    return {
      'isInitialized': _isInitialized,
      'isPremium': isPremium,
      'isInTrial': isInTrial,
      'isTrialBlocked': isTrialBlocked,
      'hasStartedTrial': hasStartedTrial,
      'hasTrialExpired': hasTrialExpired,
      'trialDaysRemaining': trialDaysRemaining,
      'trialMessagesUsed': trialMessagesUsed,
      'trialMessagesRemaining': trialMessagesRemaining,
      'premiumMessagesUsed': premiumMessagesUsed,
      'premiumMessagesRemaining': premiumMessagesRemaining,
      'canSendMessage': canSendMessage,
      'purchasedProductId': purchasedProductId,
      'hasYearlySubscription': hasYearlySubscription,
      'hasMonthlySubscription': hasMonthlySubscription,
      'mode': 'PWA (Stripe Checkout)',
    };
  }
}

/// Result of activation code validation
class ActivationResult {
  final bool success;
  final String message;
  final String? tier;

  ActivationResult({
    required this.success,
    required this.message,
    this.tier,
  });
}
