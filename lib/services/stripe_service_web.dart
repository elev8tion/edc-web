/// Web implementation of Stripe service using Embedded Checkout
/// This file is only loaded on web platforms via conditional import

// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import '../core/services/subscription_service.dart';

// Cloudflare Worker URL
const String _workerUrl = 'https://edc-stripe-subscription.connect-2a2.workers.dev';

// Stripe publishable key
const String _publishableKey = 'pk_test_51SefukIDgcZhXc4USbi8BYmZmt6ITBeN8tmk7ZEsXG7aMf5VtEuvM5Eu3Txe4vX5H9htjPIL1rO8azTLE4JhZpfL00DzHWOZls';

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
bool _viewFactoryRegistered = false;

// Current checkout element ID (for mounting Stripe)
int _checkoutViewId = 0;

// JS Interop for Stripe
@JS('Stripe')
external JSFunction get _stripeConstructor;

/// Stripe JS object
extension type StripeJS._(JSObject _) implements JSObject {
  external JSPromise<EmbeddedCheckoutJS> initEmbeddedCheckout(JSObject options);
}

/// Embedded Checkout JS object
extension type EmbeddedCheckoutJS._(JSObject _) implements JSObject {
  external void mount(JSString selector);
  external void unmount();
  external void destroy();
}

/// Create Stripe instance
StripeJS _createStripe(String publishableKey) {
  return _stripeConstructor.callAsFunction(null, publishableKey.toJS) as StripeJS;
}

/// Register the view factory for Stripe checkout (must be called before using)
void _registerViewFactory() {
  if (_viewFactoryRegistered) return;

  ui_web.platformViewRegistry.registerViewFactory(
    'stripe-checkout-element',
    (int viewId, {Object? params}) {
      _checkoutViewId = viewId;
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = 'stripe-checkout-$viewId';
      div.style.width = '100%';
      div.style.height = '100%';
      div.style.minHeight = '400px';
      return div;
    },
  );

  _viewFactoryRegistered = true;
}

/// Initialize Stripe (call on app start)
Future<void> initializeStripe() async {
  if (_isInitialized) return;

  // Register the view factory
  _registerViewFactory();

  // Load saved state
  final prefs = await SharedPreferences.getInstance();
  _customerId = prefs.getString(_keyCustomerId);
  _subscriptionId = prefs.getString(_keySubscriptionId);
  _trialEnd = prefs.getInt(_keyTrialEnd);
  _deviceId = prefs.getString(_keyDeviceId);

  _isInitialized = true;
  debugPrint('[StripeService] Web initialized (customerId: ${_customerId ?? "none"})');
}

/// Check if Stripe is supported on this platform
bool isStripeSupported() => true;

/// Start a subscription flow using Embedded Checkout
Future<bool> startSubscription({
  required BuildContext context,
  required String userId,
  String? email,
  bool isYearly = true,
  bool forceNoTrial = false,
}) async {
  final eligibleForTrial = canGetTrial() && !forceNoTrial;

  // Create checkout session
  final sessionData = await _createEmbeddedCheckoutSession(
    userId: userId,
    email: email,
    isYearly: isYearly,
    withTrial: eligibleForTrial,
  );

  if (sessionData == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize checkout')),
      );
    }
    return false;
  }

  final clientSecret = sessionData['clientSecret'] as String;
  final sessionId = sessionData['sessionId'] as String;
  final customerId = sessionData['customerId'] as String?;

  // Show embedded checkout dialog
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StripeEmbeddedCheckoutDialog(
      clientSecret: clientSecret,
      isYearly: isYearly,
      isTrial: eligibleForTrial,
    ),
  );

  if (result == true) {
    // Verify checkout completion and save subscription
    final status = await _verifyCheckoutSession(sessionId);

    if (status != null && status['status'] == 'complete') {
      await _saveSubscription(
        customerId: customerId ?? status['customerId'],
        subscriptionId: status['subscriptionId'],
        trialEnd: eligibleForTrial ? status['trialEnd'] : null,
      );

      if (context.mounted) {
        final message = eligibleForTrial
            ? 'Trial started! 3 days or 15 messages free.'
            : 'Subscription activated! Welcome to Premium.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
      return true;
    }
  }

  return false;
}

/// Embedded Checkout Dialog Widget
class StripeEmbeddedCheckoutDialog extends StatefulWidget {
  final String clientSecret;
  final bool isYearly;
  final bool isTrial;

  const StripeEmbeddedCheckoutDialog({
    super.key,
    required this.clientSecret,
    required this.isYearly,
    required this.isTrial,
  });

  @override
  State<StripeEmbeddedCheckoutDialog> createState() => _StripeEmbeddedCheckoutDialogState();
}

class _StripeEmbeddedCheckoutDialogState extends State<StripeEmbeddedCheckoutDialog> {
  EmbeddedCheckoutJS? _checkout;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Delay initialization to allow HtmlElementView to mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCheckout();
    });
  }

  Future<void> _initCheckout() async {
    // Wait a bit for the HTML element to be ready in the DOM
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final stripe = _createStripe(_publishableKey);

      // Create options object with onComplete callback
      final completer = Completer<void>();

      final onComplete = () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }.toJS;

      final options = <String, dynamic>{
        'clientSecret': widget.clientSecret,
        'onComplete': onComplete,
      }.jsify() as JSObject;

      final checkoutPromise = stripe.initEmbeddedCheckout(options);
      _checkout = await checkoutPromise.toDart;

      // Mount to the checkout div
      final selector = '#stripe-checkout-$_checkoutViewId';
      _checkout!.mount(selector.toJS);

      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Wait for completion
      await completer.future;

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('[StripeService] Error initializing checkout: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      _checkout?.destroy();
    } catch (e) {
      // Ignore errors on destroy
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceText = widget.isYearly ? r'$49.99/year' : r'$6.99/month';
    final title = widget.isTrial ? 'Start Free Trial' : 'Subscribe Now';
    final subtitle = widget.isTrial
        ? "Add payment method. You won't be charged until trial ends."
        : "You'll be charged $priceText today.";

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),

            // Checkout container
            Expanded(
              child: _buildCheckoutContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load checkout',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initCheckout();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show loading overlay while checkout is initializing
    return Stack(
      children: [
        // The actual Stripe checkout will be mounted here
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: const HtmlElementView(viewType: 'stripe-checkout-element'),
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading secure checkout...',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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
    deviceId = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch.toString().substring(7)}';
    await prefs.setString(_keyDeviceId, deviceId);
  }

  _deviceId = deviceId;
  return deviceId;
}

Future<Map<String, dynamic>?> _createEmbeddedCheckoutSession({
  required String userId,
  String? email,
  required bool isYearly,
  required bool withTrial,
}) async {
  try {
    final deviceId = await _getOrCreateDeviceId();
    final returnUrl = '${web.window.location.origin}/checkout-complete';

    final response = await http.post(
      Uri.parse('$_workerUrl/create-embedded-checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'email': email,
        'customerId': _customerId,
        'deviceId': deviceId,
        'isYearly': isYearly,
        'withTrial': withTrial,
        'returnUrl': returnUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    debugPrint('[StripeService] Checkout session failed: ${response.body}');
    return null;
  } catch (e) {
    debugPrint('[StripeService] Error creating checkout session: $e');
    return null;
  }
}

Future<Map<String, dynamic>?> _verifyCheckoutSession(String sessionId) async {
  try {
    final response = await http.post(
      Uri.parse('$_workerUrl/verify-checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sessionId': sessionId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
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
}) async {
  if (customerId == null || subscriptionId == null) return;

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(_keyCustomerId, customerId);
  await prefs.setString(_keySubscriptionId, subscriptionId);
  if (trialEnd != null) {
    await prefs.setInt(_keyTrialEnd, trialEnd);
    await prefs.setBool('trial_blocked', true);
  }

  _customerId = customerId;
  _subscriptionId = subscriptionId;
  _trialEnd = trialEnd;

  debugPrint('[StripeService] Subscription saved (customerId: $customerId)');
}
