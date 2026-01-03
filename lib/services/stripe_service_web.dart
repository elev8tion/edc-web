/// Web implementation of Stripe service using Embedded Checkout
/// This file is only loaded on web platforms via conditional import
library;

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
const String _workerUrl =
    'https://edc-stripe-subscription.connect-2a2.workers.dev';

// Stripe publishable key (LIVE MODE)
const String _publishableKey =
    'pk_live_51SefudIFwav1xmJDf1gc1OHStb4tQvLet9jSx9w1KHzAcoByHPxJLsMP2k94PWXST4pbZiWTMAou9bS0sieDTmSh00uvK4jMmV';

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

// Track registered view factories by their unique type name
final Set<String> _registeredViewTypes = {};

// Completer map to signal when view factory has created the element
final Map<String, Completer<int>> _viewReadyCompleters = {};

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
  return _stripeConstructor.callAsFunction(null, publishableKey.toJS)
      as StripeJS;
}

/// Register a unique view factory for each dialog instance
/// Returns the unique viewType name to use with HtmlElementView
String _registerUniqueViewFactory(String instanceId) {
  final viewType = 'stripe-checkout-$instanceId';

  // Skip if already registered (shouldn't happen with unique IDs)
  if (_registeredViewTypes.contains(viewType)) {
    return viewType;
  }

  // Create a completer for this view instance
  _viewReadyCompleters[viewType] = Completer<int>();

  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId, {Object? params}) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = 'stripe-element-$instanceId-$viewId';
      div.style.width = '100%';
      div.style.height = '100%';
      div.style.minHeight = '500px';
      div.style.overflow = 'auto';
      div.style.setProperty('-webkit-overflow-scrolling', 'touch');

      // Signal that the view factory has created the element
      final completer = _viewReadyCompleters[viewType];
      if (completer != null && !completer.isCompleted) {
        completer.complete(viewId);
      }

      return div;
    },
  );

  _registeredViewTypes.add(viewType);
  debugPrint('[StripeService] Registered view factory: $viewType');
  return viewType;
}

/// Wait for the DOM element to be ready with polling
Future<String?> _waitForElement(String elementId, {int maxAttempts = 20, int delayMs = 100}) async {
  for (int i = 0; i < maxAttempts; i++) {
    final element = web.document.getElementById(elementId);
    if (element != null) {
      debugPrint('[StripeService] Element found after ${i * delayMs}ms: #$elementId');
      return elementId;
    }
    await Future.delayed(Duration(milliseconds: delayMs));
  }
  debugPrint('[StripeService] Element not found after ${maxAttempts * delayMs}ms: #$elementId');
  return null;
}

/// Clean up view factory resources for an instance
void _cleanupViewFactory(String viewType) {
  _viewReadyCompleters.remove(viewType);
  // Note: Cannot unregister view factories, but we track them to avoid re-registration
}

/// Initialize Stripe (call on app start)
Future<void> initializeStripe() async {
  if (_isInitialized) return;

  // View factories are now registered per-dialog instance
  // No global registration needed here

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

  // Show embedded checkout dialog - verification happens inside dialog
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StripeEmbeddedCheckoutDialog(
      clientSecret: clientSecret,
      sessionId: sessionId,
      customerId: customerId,
      isYearly: isYearly,
      isTrial: eligibleForTrial,
    ),
  );

  if (result == true && context.mounted) {
    final message = eligibleForTrial
        ? 'Trial started! 3 days or 15 messages free.'
        : 'Subscription activated! Welcome to Premium.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
    return true;
  }

  return false;
}

/// Embedded Checkout Dialog Widget
class StripeEmbeddedCheckoutDialog extends StatefulWidget {
  final String clientSecret;
  final String sessionId;
  final String? customerId;
  final bool isYearly;
  final bool isTrial;

  const StripeEmbeddedCheckoutDialog({
    super.key,
    required this.clientSecret,
    required this.sessionId,
    this.customerId,
    required this.isYearly,
    required this.isTrial,
  });

  @override
  State<StripeEmbeddedCheckoutDialog> createState() =>
      _StripeEmbeddedCheckoutDialogState();
}

class _StripeEmbeddedCheckoutDialogState
    extends State<StripeEmbeddedCheckoutDialog> {
  EmbeddedCheckoutJS? _checkout;
  bool _isLoading = true;
  String? _error;

  // Per-instance state for view factory
  late final String _instanceId;
  late final String _viewType;
  int? _viewId;

  @override
  void initState() {
    super.initState();

    // Generate unique instance ID for this dialog
    _instanceId = '${DateTime.now().millisecondsSinceEpoch}_${identityHashCode(this)}';

    // Register a unique view factory for this instance
    _viewType = _registerUniqueViewFactory(_instanceId);

    // Delay initialization to allow HtmlElementView to mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initCheckout();
      }
    });
  }

  Future<void> _initCheckout() async {
    if (!mounted) return;

    try {
      // Wait for the view factory to create the element
      final completer = _viewReadyCompleters[_viewType];
      if (completer != null) {
        if (!completer.isCompleted) {
          // First attempt: wait with timeout for view factory callback
          _viewId = await completer.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('[StripeService] Timeout waiting for view factory');
              return -1;
            },
          );
        } else {
          // Retry attempt: completer already completed, get the value
          // This handles the case where first attempt timed out but view factory completed later
          _viewId = await completer.future;
        }
      }

      if (!mounted) return;

      if (_viewId == null || _viewId == -1) {
        throw Exception('View factory did not create element in time');
      }

      // Construct the element ID that was created by the view factory
      final elementId = 'stripe-element-$_instanceId-$_viewId';

      // Poll the DOM to verify the element exists
      final foundElement = await _waitForElement(elementId);
      if (foundElement == null) {
        throw Exception('DOM element not found: #$elementId');
      }

      if (!mounted) return;

      final stripe = _createStripe(_publishableKey);

      // Create options object with onComplete callback
      final checkoutCompleter = Completer<void>();

      final onComplete = () {
        if (!checkoutCompleter.isCompleted) {
          checkoutCompleter.complete();
        }
      }.toJS;

      final options = <String, dynamic>{
        'clientSecret': widget.clientSecret,
        'onComplete': onComplete,
      }.jsify() as JSObject;

      final checkoutPromise = stripe.initEmbeddedCheckout(options);
      _checkout = await checkoutPromise.toDart;

      if (!mounted) return;

      // Mount to the checkout div using the verified element ID
      final selector = '#$elementId';
      debugPrint('[StripeService] Mounting Stripe checkout to: $selector');
      _checkout!.mount(selector.toJS);

      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Wait for checkout completion
      await checkoutCompleter.future;

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
    // Clean up Stripe checkout
    try {
      _checkout?.destroy();
    } catch (e) {
      // Ignore errors on destroy
    }

    // Clean up view factory resources
    _cleanupViewFactory(_viewType);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceText = widget.isYearly ? r'$35.99/year' : r'$5.99/month';
    final title = widget.isTrial ? 'Start Free Trial' : 'Subscribe Now';
    final subtitle = widget.isTrial
        ? "Add payment method. You won't be charged until trial ends."
        : "You'll be charged $priceText today.";

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: 600,
        ),
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
          clipBehavior: Clip.antiAlias,
          child: HtmlElementView(viewType: _viewType),
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
    deviceId =
        '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch.toString().substring(7)}';
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
