/// Stripe Subscription Service
/// Handles SetupIntent creation, subscription management, and trial ending
///
/// Flow:
/// 1. smartSubscribe() - Routes to trial or direct based on eligibility
/// 2. startTrial() - For new users: collect card, create subscription WITH trial
/// 3. subscribeNow() - For returning users: collect card, create subscription WITHOUT trial
/// 4. endTrialNow() - Called when 15 messages consumed
///
/// Uses Cloudflare Worker for backend operations (never exposes secret keys)

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../components/payment_bottom_sheet.dart';
import '../core/services/subscription_service.dart';

class StripeSubscriptionService {
  static final instance = StripeSubscriptionService._();
  StripeSubscriptionService._();

  // Cloudflare Worker URL
  static const String _workerUrl = 'https://edc-stripe-subscription.connect-2a2.workers.dev';

  // ============================================================================
  // STORAGE KEYS (matching existing trial abuse prevention system)
  // ============================================================================

  // SharedPreferences keys
  static const _keyCustomerId = 'stripe_customer_id';
  static const _keySubscriptionId = 'stripe_subscription_id';
  static const _keyTrialEnd = 'stripe_trial_end';
  static const _keyDeviceId = 'device_id'; // Existing key from SubscriptionService

  // Keychain keys (survive app uninstall - iOS Keychain / Android KeyStore)
  static const _keychainStripeCustomerId = 'stripe_customer_id_keychain';
  static const _keychainTrialEverUsed = 'trial_ever_used_keychain';
  static const _keychainTrialMarkedDate = 'trial_marked_date_keychain';

  // Secure storage (Keychain/KeyStore)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _customerId;
  String? _subscriptionId;
  int? _trialEnd;
  String? _deviceId;
  bool _isInitialized = false;

  /// Initialize the service (call on app start)
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _customerId = prefs.getString(_keyCustomerId);
    _subscriptionId = prefs.getString(_keySubscriptionId);
    _trialEnd = prefs.getInt(_keyTrialEnd);
    _deviceId = prefs.getString(_keyDeviceId);

    // Also check Keychain for customer ID (survives reinstall)
    final keychainCustomerId = await _secureStorage.read(key: _keychainStripeCustomerId);
    if (keychainCustomerId != null && _customerId == null) {
      // Restore from Keychain after reinstall
      _customerId = keychainCustomerId;
      await prefs.setString(_keyCustomerId, keychainCustomerId);
      debugPrint('[StripeSubscriptionService] Restored customer ID from Keychain');
    }

    _isInitialized = true;
    debugPrint('[StripeSubscriptionService] Initialized (customerId: ${_customerId ?? "none"})');
  }

  bool get hasSubscription => _subscriptionId != null;

  bool get isInTrial {
    if (_trialEnd == null) return false;
    return DateTime.now().millisecondsSinceEpoch < _trialEnd! * 1000;
  }

  /// Check if user is eligible for trial
  /// Returns false if they already used trial (via Keychain/KeyStore)
  bool get canGetTrial {
    final subscriptionService = SubscriptionService.instance;
    return !subscriptionService.isTrialBlocked;
  }

  // ============================================================================
  // DEVICE ID TRACKING (reuse existing system)
  // ============================================================================

  /// Get or create unique device ID for Stripe customer tracking
  Future<String> _getOrCreateDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_keyDeviceId);

    if (deviceId == null) {
      // Generate new UUID (same format as existing system)
      deviceId = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch.toString().substring(7)}';
      await prefs.setString(_keyDeviceId, deviceId);
      debugPrint('[StripeSubscriptionService] Generated new device ID: $deviceId');
    }

    _deviceId = deviceId;
    return deviceId;
  }

  // ============================================================================
  // MAIN ENTRY POINT - Routes to trial or direct subscription
  // ============================================================================

  /// Smart subscribe - automatically chooses trial vs direct based on eligibility
  Future<bool> smartSubscribe({
    required BuildContext context,
    required String userId,
    String? email,
    bool isYearly = true,
  }) async {
    if (canGetTrial) {
      // New user - start with trial
      return startTrial(
        context: context,
        userId: userId,
        email: email,
        isYearly: isYearly,
      );
    } else {
      // Returning user - direct subscription (no trial)
      return subscribeNow(
        context: context,
        userId: userId,
        email: email,
        isYearly: isYearly,
      );
    }
  }

  // ============================================================================
  // OPTION 1: START TRIAL (for new users)
  // ============================================================================

  /// Start trial - shows custom payment bottom sheet and creates subscription WITH trial
  Future<bool> startTrial({
    required BuildContext context,
    required String userId,
    String? email,
    bool isYearly = true,
  }) async {
    // Step 1: Create SetupIntent to get clientSecret
    final setupData = await _createSetupIntent(userId: userId, email: email);
    if (setupData == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize payment')),
        );
      }
      return false;
    }

    final clientSecret = setupData['clientSecret'] as String;
    final customerId = setupData['customerId'] as String;

    // Step 2: Show custom payment bottom sheet (trial messaging)
    final result = await PaymentBottomSheet.show(
      context: context,
      title: 'Start Free Trial',
      subtitle: "Add payment method. You won't be charged until trial ends.",
      buttonText: 'Start 3-Day Trial',
      onConfirm: (cardDetails) async {
        // Step 3: Confirm SetupIntent with card details
        await Stripe.instance.confirmSetupIntent(
          paymentIntentClientSecret: clientSecret,
          params: const PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(),
          ),
        );

        // Step 4: Create subscription WITH trial (3 days)
        final subData = await _createSubscription(
          customerId: customerId,
          isYearly: isYearly,
          trialDays: 3, // Trial period
        );

        if (subData == null) {
          throw Exception('Failed to create subscription');
        }

        // Step 5: Save subscription info locally
        await _saveSubscription(
          customerId: customerId,
          subscriptionId: subData['subscriptionId'],
          trialEnd: subData['trialEnd'],
        );
      },
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trial started! 3 days or 15 messages free.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    return result == true;
  }

  // ============================================================================
  // OPTION 2: SUBSCRIBE NOW (for returning users who used trial)
  // ============================================================================

  /// Subscribe now - shows payment bottom sheet and creates subscription WITHOUT trial
  Future<bool> subscribeNow({
    required BuildContext context,
    required String userId,
    String? email,
    bool isYearly = true,
  }) async {
    // Step 1: Create SetupIntent to get clientSecret
    final setupData = await _createSetupIntent(userId: userId, email: email);
    if (setupData == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize payment')),
        );
      }
      return false;
    }

    final clientSecret = setupData['clientSecret'] as String;
    final customerId = setupData['customerId'] as String;

    // Calculate price display
    final priceText = isYearly ? r'$49.99/year' : r'$6.99/month';

    // Step 2: Show custom payment bottom sheet (subscription messaging - no trial)
    final result = await PaymentBottomSheet.show(
      context: context,
      title: 'Subscribe Now',
      subtitle: "You'll be charged $priceText today.",
      buttonText: 'Subscribe - $priceText',
      onConfirm: (cardDetails) async {
        // Step 3: Confirm SetupIntent with card details
        await Stripe.instance.confirmSetupIntent(
          paymentIntentClientSecret: clientSecret,
          params: const PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(),
          ),
        );

        // Step 4: Create subscription WITHOUT trial (charge immediately)
        final subData = await _createSubscription(
          customerId: customerId,
          isYearly: isYearly,
          trialDays: 0, // No trial, charge now
        );

        if (subData == null) {
          throw Exception('Failed to create subscription');
        }

        // Step 5: Save subscription info locally
        await _saveSubscription(
          customerId: customerId,
          subscriptionId: subData['subscriptionId'],
          trialEnd: null, // No trial end - active immediately
        );
      },
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription activated! Welcome to Premium.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    return result == true;
  }

  /// End trial early (when 15 messages consumed)
  Future<bool> endTrialNow() async {
    if (_subscriptionId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_workerUrl/end-trial'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'subscriptionId': _subscriptionId}),
      );

      if (response.statusCode == 200) {
        _trialEnd = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyTrialEnd, _trialEnd!);
        debugPrint('[StripeSubscriptionService] Trial ended early');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[StripeSubscriptionService] Error ending trial: $e');
      return false;
    }
  }

  /// Cancel subscription
  Future<bool> cancel({bool cancelAtPeriodEnd = true}) async {
    if (_subscriptionId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_workerUrl/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subscriptionId': _subscriptionId,
          'cancelAtPeriodEnd': cancelAtPeriodEnd,
        }),
      );

      if (response.statusCode == 200) {
        if (!cancelAtPeriodEnd) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_keySubscriptionId);
          await prefs.remove(_keyTrialEnd);
          _subscriptionId = null;
          _trialEnd = null;
        }
        debugPrint('[StripeSubscriptionService] Subscription cancelled (atPeriodEnd: $cancelAtPeriodEnd)');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[StripeSubscriptionService] Error cancelling: $e');
      return false;
    }
  }

  /// Get subscription status from Stripe
  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    if (_subscriptionId == null && _customerId == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_workerUrl/get-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subscriptionId': _subscriptionId,
          'customerId': _customerId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('[StripeSubscriptionService] Error getting status: $e');
      return null;
    }
  }

  // ============================================================================
  // PRIVATE HELPERS (with device tracking)
  // ============================================================================

  Future<Map<String, dynamic>?> _createSetupIntent({
    required String userId,
    String? email,
  }) async {
    try {
      // Get device ID for abuse prevention
      final deviceId = await _getOrCreateDeviceId();

      final response = await http.post(
        Uri.parse('$_workerUrl/create-setup-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'email': email,
          'customerId': _customerId,
          'deviceId': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint('[StripeSubscriptionService] SetupIntent failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[StripeSubscriptionService] Error creating SetupIntent: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _createSubscription({
    required String customerId,
    required bool isYearly,
    required int trialDays,
  }) async {
    try {
      // Get device ID for abuse prevention
      final deviceId = await _getOrCreateDeviceId();

      final response = await http.post(
        Uri.parse('$_workerUrl/create-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'customerId': customerId,
          'isYearly': isYearly,
          'trialDays': trialDays,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint('[StripeSubscriptionService] Subscription failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[StripeSubscriptionService] Error creating subscription: $e');
      return null;
    }
  }

  Future<void> _saveSubscription({
    required String customerId,
    required String subscriptionId,
    int? trialEnd,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Save to SharedPreferences
    await prefs.setString(_keyCustomerId, customerId);
    await prefs.setString(_keySubscriptionId, subscriptionId);
    if (trialEnd != null) {
      await prefs.setInt(_keyTrialEnd, trialEnd);
    }

    // Save customer ID to Keychain (survives app uninstall)
    await _secureStorage.write(key: _keychainStripeCustomerId, value: customerId);

    // Mark trial as used in Keychain (if this was a trial)
    if (trialEnd != null) {
      await _secureStorage.write(key: _keychainTrialEverUsed, value: 'true');
      await _secureStorage.write(
        key: _keychainTrialMarkedDate,
        value: DateTime.now().toIso8601String(),
      );
      debugPrint('[StripeSubscriptionService] Trial marked as used in Keychain');

      // Also set local trial_blocked flag
      await prefs.setBool('trial_blocked', true);
    }

    _customerId = customerId;
    _subscriptionId = subscriptionId;
    _trialEnd = trialEnd;

    debugPrint('[StripeSubscriptionService] Subscription saved (customerId: $customerId)');
  }

  // ============================================================================
  // KEYCHAIN HELPERS
  // ============================================================================

  /// Check if device has a Stripe customer from a previous install
  Future<String?> getKeychainCustomerId() async {
    try {
      return await _secureStorage.read(key: _keychainStripeCustomerId);
    } catch (e) {
      debugPrint('[StripeSubscriptionService] Error reading Keychain: $e');
      return null;
    }
  }

  /// Check if this device has ever had a trial
  Future<bool> hasDeviceUsedTrial() async {
    try {
      final trialUsed = await _secureStorage.read(key: _keychainTrialEverUsed);
      return trialUsed == 'true';
    } catch (e) {
      debugPrint('[StripeSubscriptionService] Error reading Keychain: $e');
      return false;
    }
  }
}
