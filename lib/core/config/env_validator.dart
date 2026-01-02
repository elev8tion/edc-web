/// Environment configuration validator
///
/// Validates all environment variables at startup to catch configuration
/// errors early and prevent security issues.
///
/// SECURITY FEATURES:
/// - Validates key formats (prevents using wrong environment keys)
/// - Checks for placeholder values
/// - Ensures HTTPS for production webhooks
/// - Validates key rotation dates
/// - Prevents production deployment with test keys
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvValidator {
  /// Validates all environment variables
  /// Throws [EnvValidationException] if any issues are found
  static void validate() {
    final errors = <String>[];

    // Validate environment
    _validateEnvironment(errors);

    // Validate Stripe configuration
    _validateStripe(errors);

    // Validate Activepieces configuration
    _validateActivepieces(errors);

    // Validate key rotation
    _validateKeyRotation(errors);

    if (errors.isNotEmpty) {
      throw EnvValidationException(
        'Environment configuration validation failed:\n${errors.join('\n')}',
      );
    }

    if (kDebugMode) {
      print('✅ Environment configuration validated successfully');
    }
  }

  static void _validateEnvironment(List<String> errors) {
    final env = dotenv.get('APP_ENV', fallback: 'development');

    if (!['development', 'staging', 'production'].contains(env)) {
      errors.add('❌ APP_ENV must be development, staging, or production');
    }
  }

  static void _validateStripe(List<String> errors) {
    final env = dotenv.get('APP_ENV', fallback: 'development');
    final secretKey = dotenv.get('STRIPE_SECRET_KEY', fallback: '');
    final publishableKey = dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: '');
    final webhookSecret = dotenv.get('STRIPE_WEBHOOK_SECRET', fallback: '');

    // Validate secret key format
    if (secretKey.isEmpty) {
      errors.add('❌ STRIPE_SECRET_KEY is required');
    } else if (secretKey.contains('YOUR_') || secretKey == 'sk_test_YOUR_KEY') {
      errors.add('❌ STRIPE_SECRET_KEY is using placeholder value');
    } else if (env == 'production' &&
        !secretKey.startsWith('sk_live_') &&
        !secretKey.startsWith('rk_live_')) {
      errors.add(
          '❌ Production must use live Stripe keys (sk_live_* or rk_live_*)');
    } else if (env == 'development' &&
        !secretKey.startsWith('sk_test_') &&
        !secretKey.startsWith('rk_test_')) {
      errors.add(
          '⚠️  Warning: Development should use test Stripe keys (sk_test_* or rk_test_*)');
    }

    // Validate publishable key
    if (publishableKey.isEmpty) {
      errors.add('❌ STRIPE_PUBLISHABLE_KEY is required');
    } else if (publishableKey.contains('YOUR_')) {
      errors.add('❌ STRIPE_PUBLISHABLE_KEY is using placeholder value');
    } else if (env == 'production' && !publishableKey.startsWith('pk_live_')) {
      errors.add('❌ Production must use live publishable key (pk_live_*)');
    }

    // Validate webhook secret
    if (webhookSecret.isEmpty) {
      errors.add(
          '⚠️  Warning: STRIPE_WEBHOOK_SECRET not set (required for webhooks)');
    } else if (webhookSecret.contains('YOUR_')) {
      errors.add('❌ STRIPE_WEBHOOK_SECRET is using placeholder value');
    } else if (!webhookSecret.startsWith('whsec_')) {
      errors.add('❌ STRIPE_WEBHOOK_SECRET must start with whsec_');
    }

    // Validate product IDs
    final monthlyProduct =
        dotenv.get('STRIPE_PRODUCT_MONTHLY_ID', fallback: '');
    final yearlyProduct = dotenv.get('STRIPE_PRODUCT_YEARLY_ID', fallback: '');

    if (monthlyProduct.isEmpty || monthlyProduct.contains('YOUR_')) {
      errors.add('⚠️  Warning: STRIPE_PRODUCT_MONTHLY_ID not configured');
    }

    if (yearlyProduct.isEmpty || yearlyProduct.contains('YOUR_')) {
      errors.add('⚠️  Warning: STRIPE_PRODUCT_YEARLY_ID not configured');
    }
  }

  static void _validateActivepieces(List<String> errors) {
    final url = dotenv.get('ACTIVEPIECES_MCP_URL', fallback: '');
    final token = dotenv.get('ACTIVEPIECES_TOKEN', fallback: '');

    // Validate URL
    if (url.isEmpty) {
      errors.add('❌ ACTIVEPIECES_MCP_URL is required');
    } else if (url.contains('YOUR_')) {
      errors.add('❌ ACTIVEPIECES_MCP_URL is using placeholder value');
    } else if (!url.startsWith('https://')) {
      errors.add('❌ ACTIVEPIECES_MCP_URL must use HTTPS');
    }

    // Validate token
    if (token.isEmpty) {
      errors.add('❌ ACTIVEPIECES_TOKEN is required');
    } else if (token.contains('YOUR_')) {
      errors.add('❌ ACTIVEPIECES_TOKEN is using placeholder value');
    } else if (token.length < 32) {
      errors.add('❌ ACTIVEPIECES_TOKEN appears to be invalid (too short)');
    }

    // Validate webhook URLs
    final webhookUrls = [
      'ACTIVEPIECES_MESSAGE_LIMIT_URL',
      'ACTIVEPIECES_START_TRIAL_URL',
      'ACTIVEPIECES_STRIPE_WEBHOOK_URL',
    ];

    for (final key in webhookUrls) {
      final value = dotenv.get(key, fallback: '');
      if (value.isNotEmpty && !value.startsWith('https://')) {
        errors.add('❌ $key must use HTTPS');
      }
    }
  }

  static void _validateKeyRotation(List<String> errors) {
    final lastRotation = dotenv.get('LAST_KEY_ROTATION_DATE', fallback: '');
    final nextRotation = dotenv.get('NEXT_KEY_ROTATION_DATE', fallback: '');

    if (lastRotation.isEmpty) {
      errors.add('⚠️  Warning: LAST_KEY_ROTATION_DATE not set');
      return;
    }

    if (nextRotation.isEmpty) {
      errors.add('⚠️  Warning: NEXT_KEY_ROTATION_DATE not set');
      return;
    }

    try {
      final next = DateTime.parse(nextRotation);
      final now = DateTime.now();

      if (next.isBefore(now)) {
        errors.add('⚠️  WARNING: API keys are overdue for rotation!');
        errors.add('   Next rotation was: $nextRotation');
        errors.add('   Please rotate all API keys immediately');
      } else {
        final daysUntilRotation = next.difference(now).inDays;
        if (daysUntilRotation < 7) {
          errors.add(
              '⚠️  Warning: API keys need rotation in $daysUntilRotation days');
        }
      }
    } catch (e) {
      errors.add('❌ Invalid date format in rotation dates (use YYYY-MM-DD)');
    }
  }

  /// Validates configuration is safe for production deployment
  static void validateProduction() {
    final env = dotenv.get('APP_ENV', fallback: 'development');

    if (env != 'production') {
      throw EnvValidationException(
        'Cannot deploy: APP_ENV must be set to "production"',
      );
    }

    final secretKey = dotenv.get('STRIPE_SECRET_KEY', fallback: '');
    if (secretKey.startsWith('sk_test_') || secretKey.startsWith('rk_test_')) {
      throw EnvValidationException(
        'Cannot deploy: Using test Stripe keys in production!',
      );
    }

    final publishableKey = dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: '');
    if (publishableKey.startsWith('pk_test_')) {
      throw EnvValidationException(
        'Cannot deploy: Using test Stripe publishable key in production!',
      );
    }

    if (kDebugMode) {
      print('✅ Production configuration validated');
    }
  }
}

class EnvValidationException implements Exception {
  final String message;

  EnvValidationException(this.message);

  @override
  String toString() => message;
}
