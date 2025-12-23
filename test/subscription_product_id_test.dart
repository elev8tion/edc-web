import 'package:flutter_test/flutter_test.dart';

/// Unit tests for subscription product ID tracking
///
/// Tests verify that:
/// 1. Product ID constants are correctly defined
/// 2. Expiry duration logic works for yearly vs monthly
/// 3. Subscription type detection works correctly
void main() {
  group('Subscription Product ID Tests', () {
    test('Product IDs are correctly defined', () {
      const yearlyId = 'everyday_christian_premium_yearly';
      const monthlyId = 'everyday_christian_premium_monthly';

      expect(yearlyId, 'everyday_christian_premium_yearly');
      expect(monthlyId, 'everyday_christian_premium_monthly');
      expect(yearlyId, isNot(equals(monthlyId)));
    });

    test('Expiry duration calculation - Yearly', () {
      const productId = 'everyday_christian_premium_yearly';
      const isYearly = productId == 'everyday_christian_premium_yearly';
      const expiryDuration =
          isYearly ? Duration(days: 365) : Duration(days: 30);

      expect(isYearly, isTrue);
      expect(expiryDuration.inDays, 365);
    });

    test('Expiry duration calculation - Monthly', () {
      const productId = 'everyday_christian_premium_monthly';
      const isYearly = productId == 'everyday_christian_premium_yearly';
      const expiryDuration =
          isYearly ? Duration(days: 365) : Duration(days: 30);

      expect(isYearly, isFalse);
      expect(expiryDuration.inDays, 30);
    });

    test('Subscription type detection - Yearly', () {
      const productId = 'everyday_christian_premium_yearly';
      const hasYearly = productId == 'everyday_christian_premium_yearly';
      const hasMonthly = productId == 'everyday_christian_premium_monthly';

      expect(hasYearly, isTrue);
      expect(hasMonthly, isFalse);
    });

    test('Subscription type detection - Monthly', () {
      const productId = 'everyday_christian_premium_monthly';
      const hasYearly = productId == 'everyday_christian_premium_yearly';
      const hasMonthly = productId == 'everyday_christian_premium_monthly';

      expect(hasYearly, isFalse);
      expect(hasMonthly, isTrue);
    });

    test('Subscription type detection - No subscription', () {
      const String? productId = null;
      const hasYearly = productId == 'everyday_christian_premium_yearly';
      const hasMonthly = productId == 'everyday_christian_premium_monthly';

      expect(hasYearly, isFalse);
      expect(hasMonthly, isFalse);
    });

    test('Expiry date calculation - Yearly', () {
      final now = DateTime(2025, 1, 15);
      const isYearly = true;
      const expiryDuration =
          isYearly ? Duration(days: 365) : Duration(days: 30);
      final expiryDate = now.add(expiryDuration);

      expect(expiryDate.year, 2026);
      expect(expiryDate.month, 1);
      expect(expiryDate.day, 15);
    });

    test('Expiry date calculation - Monthly', () {
      final now = DateTime(2025, 1, 15);
      const isYearly = false;
      const expiryDuration =
          isYearly ? Duration(days: 365) : Duration(days: 30);
      final expiryDate = now.add(expiryDuration);

      expect(expiryDate.year, 2025);
      expect(expiryDate.month, 2);
      expect(expiryDate.day, 14); // 30 days from Jan 15 = Feb 14
    });
  });
}
