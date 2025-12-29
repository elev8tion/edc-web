import 'package:flutter/material.dart';

/// Stub implementation - should never be called
/// Real implementations are in stripe_service_mobile.dart and stripe_service_web.dart

/// Initialize Stripe (call on app start)
Future<void> initializeStripe() async {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// Check if Stripe is supported on this platform
bool isStripeSupported() {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// Start a subscription flow (trial or direct based on eligibility)
/// Returns true if subscription was successful
Future<bool> startSubscription({
  required BuildContext context,
  required String userId,
  String? email,
  bool isYearly = true,
  bool forceNoTrial = false,
}) async {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// Cancel the current subscription
Future<bool> cancelSubscription({bool cancelAtPeriodEnd = true}) async {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// End trial early (when message limit reached)
Future<bool> endTrialEarly() async {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// Get current subscription status
Future<Map<String, dynamic>?> getSubscriptionStatus() async {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// Check if user has an active subscription
bool hasActiveSubscription() {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// Check if user is currently in trial period
bool isInTrialPeriod() {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// Check if user can get a trial (hasn't used one before)
bool canGetTrial() {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// Get the Stripe customer ID (if exists)
String? getCustomerId() {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

/// Get the subscription ID (if exists)
String? getSubscriptionId() {
  throw UnimplementedError('Platform-specific implementation not loaded');
}
