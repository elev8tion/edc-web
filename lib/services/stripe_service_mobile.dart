/// Mobile implementation of Stripe service using flutter_stripe package
/// This file is only loaded on iOS/Android platforms via conditional import

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/services/subscription_service.dart';
import '../components/payment_bottom_sheet.dart';

// Cloudflare Worker URL
const String _workerUrl = 'https://edc-stripe-subscription.connect-2a2.workers.dev';

// Storage keys
const _keyCustomerId = 'stripe_customer_id';
const _keySubscriptionId = 'stripe_subscription_id';
const _keyTrialEnd = 'stripe_trial_end';
const _keyDeviceId = 'device_id';

// Keychain keys (survive app uninstall)
const _keychainStripeCustomerId = 'stripe_customer_id_keychain';
const _keychainTrialEverUsed = 'trial_ever_used_keychain';
const _keychainTrialMarkedDate = 'trial_marked_date_keychain';

// Secure storage
final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

// State
String? _customerId;
String? _subscriptionId;
int? _trialEnd;
String? _deviceId;
bool _isInitialized = false;

/// Initialize Stripe (call on app start)
Future<void> initializeStripe() async {
  if (_isInitialized) return;

  // Set publishable key
  Stripe.publishableKey = 'pk_test_51SefukIDgcZhXc4USbi8BYmZmt6ITBeN8tmk7ZEsXG7aMf5VtEuvM5Eu3Txe4vX5H9htjPIL1rO8azTLE4JhZpfL00DzHWOZls';
  await Stripe.instance.applySettings();

  // Load saved state
  final prefs = await SharedPreferences.getInstance();
  _customerId = prefs.getString(_keyCustomerId);
  _subscriptionId = prefs.getString(_keySubscriptionId);
  _trialEnd = prefs.getInt(_keyTrialEnd);
  _deviceId = prefs.getString(_keyDeviceId);

  // Check Keychain for customer ID (survives reinstall)
  final keychainCustomerId = await _secureStorage.read(key: _keychainStripeCustomerId);
  if (keychainCustomerId != null && _customerId == null) {
    _customerId = keychainCustomerId;
    await prefs.setString(_keyCustomerId, keychainCustomerId);
    debugPrint('[StripeService] Restored customer ID from Keychain');
  }

  _isInitialized = true;
  debugPrint('[StripeService] Mobile initialized (customerId: ${_customerId ?? "none"})');
}

/// Check if Stripe is supported on this platform
bool isStripeSupported() => true;

/// Start a subscription flow
Future<bool> startSubscription({
  required BuildContext context,
  required String userId,
  String? email,
  bool isYearly = true,
  bool forceNoTrial = false,
}) async {
  final eligibleForTrial = canGetTrial() && !forceNoTrial;

  if (eligibleForTrial) {
    return _startTrial(context: context, userId: userId, email: email, isYearly: isYearly);
  } else {
    return _subscribeNow(context: context, userId: userId, email: email, isYearly: isYearly);
  }
}

/// Start trial with payment collection
Future<bool> _startTrial({
  required BuildContext context,
  required String userId,
  String? email,
  bool isYearly = true,
}) async {
  // Create SetupIntent
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

  // Show payment bottom sheet
  final result = await PaymentBottomSheet.show(
    context: context,
    title: 'Start Free Trial',
    subtitle: "Add payment method. You won't be charged until trial ends.",
    buttonText: 'Start 3-Day Trial',
    onConfirm: (cardDetails) async {
      // Confirm SetupIntent
      await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: clientSecret,
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // Create subscription with trial
      final subData = await _createSubscription(
        customerId: customerId,
        isYearly: isYearly,
        trialDays: 3,
      );

      if (subData == null) {
        throw Exception('Failed to create subscription');
      }

      // Save subscription info
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

/// Subscribe now (no trial)
Future<bool> _subscribeNow({
  required BuildContext context,
  required String userId,
  String? email,
  bool isYearly = true,
}) async {
  // Create SetupIntent
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
  final priceText = isYearly ? r'$49.99/year' : r'$6.99/month';

  // Show payment bottom sheet
  final result = await PaymentBottomSheet.show(
    context: context,
    title: 'Subscribe Now',
    subtitle: "You'll be charged $priceText today.",
    buttonText: 'Subscribe - $priceText',
    onConfirm: (cardDetails) async {
      // Confirm SetupIntent
      await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: clientSecret,
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // Create subscription without trial
      final subData = await _createSubscription(
        customerId: customerId,
        isYearly: isYearly,
        trialDays: 0,
      );

      if (subData == null) {
        throw Exception('Failed to create subscription');
      }

      // Save subscription info
      await _saveSubscription(
        customerId: customerId,
        subscriptionId: subData['subscriptionId'],
        trialEnd: null,
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

/// Cancel the current subscription
Future<bool> cancelSubscription({bool cancelAtPeriodEnd = true}) async {
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
      debugPrint('[StripeService] Subscription cancelled (atPeriodEnd: $cancelAtPeriodEnd)');
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('[StripeService] Error cancelling: $e');
    return false;
  }
}

/// End trial early
Future<bool> endTrialEarly() async {
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
      debugPrint('[StripeService] Trial ended early');
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('[StripeService] Error ending trial: $e');
    return false;
  }
}

/// Get subscription status
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
    debugPrint('[StripeService] Error getting status: $e');
    return null;
  }
}

/// Check if user has active subscription
bool hasActiveSubscription() => _subscriptionId != null;

/// Check if in trial period
bool isInTrialPeriod() {
  if (_trialEnd == null) return false;
  return DateTime.now().millisecondsSinceEpoch < _trialEnd! * 1000;
}

/// Check if can get trial
bool canGetTrial() {
  final subscriptionService = SubscriptionService.instance;
  return !subscriptionService.isTrialBlocked;
}

/// Get customer ID
String? getCustomerId() => _customerId;

/// Get subscription ID
String? getSubscriptionId() => _subscriptionId;

// Private helpers

Future<String> _getOrCreateDeviceId() async {
  if (_deviceId != null) return _deviceId!;

  final prefs = await SharedPreferences.getInstance();
  var deviceId = prefs.getString(_keyDeviceId);

  if (deviceId == null) {
    deviceId = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch.toString().substring(7)}';
    await prefs.setString(_keyDeviceId, deviceId);
  }

  _deviceId = deviceId;
  return deviceId;
}

Future<Map<String, dynamic>?> _createSetupIntent({
  required String userId,
  String? email,
}) async {
  try {
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
    debugPrint('[StripeService] SetupIntent failed: ${response.body}');
    return null;
  } catch (e) {
    debugPrint('[StripeService] Error creating SetupIntent: $e');
    return null;
  }
}

Future<Map<String, dynamic>?> _createSubscription({
  required String customerId,
  required bool isYearly,
  required int trialDays,
}) async {
  try {
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
    debugPrint('[StripeService] Subscription failed: ${response.body}');
    return null;
  } catch (e) {
    debugPrint('[StripeService] Error creating subscription: $e');
    return null;
  }
}

Future<void> _saveSubscription({
  required String customerId,
  required String subscriptionId,
  int? trialEnd,
}) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(_keyCustomerId, customerId);
  await prefs.setString(_keySubscriptionId, subscriptionId);
  if (trialEnd != null) {
    await prefs.setInt(_keyTrialEnd, trialEnd);
  }

  // Save to Keychain
  await _secureStorage.write(key: _keychainStripeCustomerId, value: customerId);

  if (trialEnd != null) {
    await _secureStorage.write(key: _keychainTrialEverUsed, value: 'true');
    await _secureStorage.write(
      key: _keychainTrialMarkedDate,
      value: DateTime.now().toIso8601String(),
    );
    await prefs.setBool('trial_blocked', true);
  }

  _customerId = customerId;
  _subscriptionId = subscriptionId;
  _trialEnd = trialEnd;

  debugPrint('[StripeService] Subscription saved (customerId: $customerId)');
}
