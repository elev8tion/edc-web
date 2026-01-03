/// Web implementation of Stripe service using Hosted Checkout (URL Redirect)
/// This file is only loaded on web platforms via conditional import
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/services/subscription_service.dart';

// Cloudflare Worker URL
const String _workerUrl =
    'https://edc-stripe-subscription.connect-2a2.workers.dev';

// Storage keys
const _keyCustomerId = 'stripe_customer_id';
const _keySubscriptionId = 'stripe_subscription_id';
const _keyTrialEnd = 'stripe_trial_end';
const _keyDeviceId = 'device_id';

// State
String? _customerId;
String? _subscriptionId;
int? _trialEnd;
String? _deviceId;
bool _isInitialized = false;

/// Initialize Stripe (call on app start)
Future<void> initializeStripe() async {
  if (_isInitialized) return;

  // Load saved state
  final prefs = await SharedPreferences.getInstance();
  _customerId = prefs.getString(_keyCustomerId);
  _subscriptionId = prefs.getString(_keySubscriptionId);
  _trialEnd = prefs.getInt(_keyTrialEnd);
  _deviceId = prefs.getString(_keyDeviceId);

  _isInitialized = true;
  debugPrint(
      '[StripeService] Web initialized (customerId: ${_customerId ?? "none"})');
}

/// Check if Stripe is supported on this platform
bool isStripeSupported() => true;

/// Start a subscription flow using Hosted Checkout (URL Redirect)
/// This is the RECOMMENDED approach for Flutter web - no platform views!
Future<bool> startSubscription({
  required BuildContext context,
  required String userId,
  String? email,
  bool isYearly = true,
  bool forceNoTrial = false,
}) async {
  debugPrint('[StripeService] startSubscription called');

  final eligibleForTrial = canGetTrial() && !forceNoTrial;
  debugPrint('[StripeService] eligibleForTrial: $eligibleForTrial');

  // Create checkout session
  debugPrint('[StripeService] Creating checkout session...');
  final sessionData = await _createCheckoutSession(
    userId: userId,
    email: email,
    isYearly: isYearly,
    withTrial: eligibleForTrial,
  );

  debugPrint('[StripeService] Session data received: ${sessionData != null}');

  if (sessionData == null || sessionData['url'] == null) {
    debugPrint('[StripeService] ERROR: Session data is null or missing URL');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize checkout')),
      );
    }
    return false;
  }

  // Extract checkout URL
  final checkoutUrl = sessionData['url'] as String;
  final sessionId = sessionData['sessionId'] as String?;
  final customerId = sessionData['customerId'] as String?;

  debugPrint('[StripeService] Checkout URL: $checkoutUrl');
  debugPrint('[StripeService] Session ID: $sessionId');

  // Save customer ID for future use
  if (customerId != null) {
    _customerId = customerId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomerId, customerId);
  }

  try {
    // CRITICAL: Redirect to Stripe hosted checkout page
    // For web, use _self to redirect in the same tab
    // Stripe will redirect back to our success_url after completion
    final uri = Uri.parse(checkoutUrl);

    if (kIsWeb) {
      // Web: Redirect in same tab (best UX for checkout flow)
      await launchUrl(uri, webOnlyWindowName: "_self");
    } else {
      // Mobile: Open in external browser (fallback, shouldn't happen)
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    debugPrint('[StripeService] Redirected to Stripe checkout');
    return true;
  } catch (e, stackTrace) {
    debugPrint('[StripeService] ERROR launching checkout URL: $e');
    debugPrint('[StripeService] Stack trace: $stackTrace');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open checkout: $e')),
      );
    }
    return false;
  }
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
      debugPrint('[StripeService] Subscription cancelled');
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
    deviceId =
        '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch.toString().substring(7)}';
    await prefs.setString(_keyDeviceId, deviceId);
  }

  _deviceId = deviceId;
  return deviceId;
}

/// Create a hosted checkout session (returns URL for redirect)
Future<Map<String, dynamic>?> _createCheckoutSession({
  required String userId,
  String? email,
  required bool isYearly,
  required bool withTrial,
}) async {
  try {
    final deviceId = await _getOrCreateDeviceId();

    // CRITICAL: Use hash routing for success/cancel URLs
    // This works better with Flutter web's navigation system
    final origin = web.window.location.origin;
    final successUrl = '$origin/#/checkout-complete?session_id={CHECKOUT_SESSION_ID}';
    final cancelUrl = '$origin/#/paywall';

    debugPrint('[StripeService] Success URL: $successUrl');
    debugPrint('[StripeService] Cancel URL: $cancelUrl');

    final response = await http.post(
      Uri.parse('$_workerUrl/create-checkout-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'email': email,
        'customerId': _customerId,
        'deviceId': deviceId,
        'isYearly': isYearly,
        'withTrial': withTrial,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[StripeService] Checkout session created successfully');
      debugPrint('[StripeService] URL: ${data['url']}');
      return data;
    }
    debugPrint('[StripeService] Checkout session failed: ${response.body}');
    return null;
  } catch (e) {
    debugPrint('[StripeService] Error creating checkout session: $e');
    return null;
  }
}

/// Verify checkout session and activate subscription
/// Called by checkout_complete_screen.dart when user returns from Stripe
Future<Map<String, dynamic>?> verifyCheckoutSession(String sessionId) async {
  try {
    debugPrint('[StripeService] Verifying checkout session: $sessionId');

    final response = await http.post(
      Uri.parse('$_workerUrl/verify-checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sessionId': sessionId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[StripeService] Verification response: $data');

      // Save subscription details
      if (data['status'] == 'complete' && data['subscriptionId'] != null) {
        await _saveSubscription(
          customerId: data['customerId'],
          subscriptionId: data['subscriptionId'],
          trialEnd: data['trialEnd'],
          currentPeriodEnd: data['currentPeriodEnd'],
          isYearly: true, // TODO: Get from metadata if needed
        );
      }

      return data;
    }
    return null;
  } catch (e) {
    debugPrint('[StripeService] Error verifying checkout: $e');
    return null;
  }
}

Future<void> _saveSubscription({
  required String? customerId,
  required String? subscriptionId,
  int? trialEnd,
  int? currentPeriodEnd,
  bool isYearly = true,
}) async {
  if (customerId == null || subscriptionId == null) return;

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(_keyCustomerId, customerId);
  await prefs.setString(_keySubscriptionId, subscriptionId);
  if (trialEnd != null) {
    await prefs.setInt(_keyTrialEnd, trialEnd);
  }

  _customerId = customerId;
  _subscriptionId = subscriptionId;
  _trialEnd = trialEnd;

  // CRITICAL: Activate premium in SubscriptionService
  // This ensures isPremium returns true and user has access
  final subscriptionService = SubscriptionService.instance;
  await subscriptionService.activateFromStripe(
    subscriptionId: subscriptionId,
    customerId: customerId,
    trialEnd: trialEnd,
    currentPeriodEnd: currentPeriodEnd,
    isYearly: isYearly,
  );

  debugPrint(
      '[StripeService] Subscription saved and premium activated (customerId: $customerId)');
}
