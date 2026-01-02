/// Stripe Webhook Signature Verifier
///
/// SECURITY CRITICAL: Always verify webhook signatures to prevent:
/// - Fake webhook attacks
/// - Replay attacks
/// - Data tampering
/// - Unauthorized subscription changes
///
/// Reference: https://stripe.com/docs/webhooks/signatures
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeWebhookVerifier {
  /// Verifies a Stripe webhook signature
  ///
  /// [payload] - Raw webhook body as string (IMPORTANT: Use raw body, not parsed JSON!)
  /// [signature] - Value from 'Stripe-Signature' header
  /// [webhookSecret] - Your webhook signing secret from Stripe dashboard
  ///
  /// Returns `true` if signature is valid
  /// Throws [WebhookVerificationException] if verification fails
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   StripeWebhookVerifier.verify(
  ///     payload: request.body,
  ///     signature: request.headers['stripe-signature']!,
  ///   );
  ///   // Process webhook...
  /// } on WebhookVerificationException catch (e) {
  ///   print('Invalid webhook: $e');
  ///   return Response(400);
  /// }
  /// ```
  static bool verify({
    required String payload,
    required String signature,
    String? webhookSecret,
    int toleranceSeconds = 300, // 5 minutes
  }) {
    // Get webhook secret from env if not provided
    final secret =
        webhookSecret ?? dotenv.get('STRIPE_WEBHOOK_SECRET', fallback: '');

    if (secret.isEmpty) {
      throw WebhookVerificationException(
        'STRIPE_WEBHOOK_SECRET not configured. '
        'Get it from: https://dashboard.stripe.com/webhooks',
      );
    }

    if (!secret.startsWith('whsec_')) {
      throw WebhookVerificationException(
        'Invalid STRIPE_WEBHOOK_SECRET format. Must start with whsec_',
      );
    }

    // Parse signature header
    final signatureParts = _parseSignatureHeader(signature);
    final timestamp = signatureParts['t'];
    final signatures = signatureParts['v1'];

    if (timestamp == null || signatures == null || signatures.isEmpty) {
      throw WebhookVerificationException(
        'Invalid Stripe-Signature header format',
      );
    }

    // Check timestamp tolerance (prevents replay attacks)
    final webhookTime = int.tryParse(timestamp);
    if (webhookTime == null) {
      throw WebhookVerificationException('Invalid timestamp in signature');
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if ((currentTime - webhookTime).abs() > toleranceSeconds) {
      throw WebhookVerificationException(
        'Webhook timestamp too old. Possible replay attack. '
        'Timestamp: $webhookTime, Current: $currentTime',
      );
    }

    // Compute expected signature
    final signedPayload = '$timestamp.$payload';
    final expectedSignature = _computeSignature(signedPayload, secret);

    // Compare signatures (constant-time comparison to prevent timing attacks)
    var isValid = false;
    for (final sig in signatures) {
      if (_secureCompare(sig, expectedSignature)) {
        isValid = true;
        break;
      }
    }

    if (!isValid) {
      throw WebhookVerificationException(
        'Signature verification failed. Webhook may be fake or tampered.',
      );
    }

    return true;
  }

  /// Parses Stripe-Signature header
  /// Format: t=1234567890,v1=signature1,v1=signature2
  static Map<String, dynamic> _parseSignatureHeader(String header) {
    final result = <String, dynamic>{
      't': null,
      'v1': <String>[],
    };

    final parts = header.split(',');
    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length != 2) continue;

      final key = keyValue[0];
      final value = keyValue[1];

      if (key == 't') {
        result['t'] = value;
      } else if (key == 'v1') {
        (result['v1'] as List<String>).add(value);
      }
    }

    return result;
  }

  /// Computes HMAC-SHA256 signature
  static String _computeSignature(String payload, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Constant-time string comparison (prevents timing attacks)
  static bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }

  /// Verifies webhook and parses event data
  ///
  /// Convenience method that verifies signature and returns parsed event
  ///
  /// Example:
  /// ```dart
  /// final event = StripeWebhookVerifier.verifyAndParse(
  ///   payload: request.body,
  ///   signature: request.headers['stripe-signature']!,
  /// );
  ///
  /// switch (event['type']) {
  ///   case 'customer.subscription.created':
  ///     // Handle subscription created
  ///     break;
  ///   case 'customer.subscription.deleted':
  ///     // Handle subscription cancelled
  ///     break;
  /// }
  /// ```
  static Map<String, dynamic> verifyAndParse({
    required String payload,
    required String signature,
    String? webhookSecret,
  }) {
    // Verify signature first
    verify(
      payload: payload,
      signature: signature,
      webhookSecret: webhookSecret,
    );

    // Parse and return event data
    try {
      return json.decode(payload) as Map<String, dynamic>;
    } catch (e) {
      throw WebhookVerificationException(
        'Failed to parse webhook payload: $e',
      );
    }
  }
}

class WebhookVerificationException implements Exception {
  final String message;

  WebhookVerificationException(this.message);

  @override
  String toString() => 'WebhookVerificationException: $message';
}
