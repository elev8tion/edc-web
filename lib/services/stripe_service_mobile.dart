/// Mobile implementation stub - PWA only, this file is never loaded
/// Uses conditional import: dart.library.io only loads on iOS/Android
///
/// For PWA, stripe_service_web.dart is used instead (Embedded Checkout)
library;

import 'package:flutter/material.dart';

/// Initialize Stripe (call on app start)
Future<void> initializeStripe() async {
  // Not used on web/PWA
}

/// Check if Stripe is supported on this platform
bool isStripeSupported() => false;

/// Start a subscription flow
Future<bool> startSubscription({
  required BuildContext context,
  required String userId,
  String? email,
  bool isYearly = true,
  bool forceNoTrial = false,
}) async {
  return false;
}

/// Cancel the current subscription
Future<bool> cancelSubscription({bool cancelAtPeriodEnd = true}) async {
  return false;
}

/// End trial early
Future<bool> endTrialEarly() async {
  return false;
}

/// Get subscription status
Future<Map<String, dynamic>?> getSubscriptionStatus() async {
  return null;
}

/// Check if user has active subscription
bool hasActiveSubscription() => false;

/// Check if in trial period
bool isInTrialPeriod() => false;

/// Check if can get trial
bool canGetTrial() => false;

/// Get customer ID
String? getCustomerId() => null;

/// Get subscription ID
String? getSubscriptionId() => null;
