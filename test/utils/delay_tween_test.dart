import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/utils/delay_tween.dart';

void main() {
  group('DelayTween', () {
    test('delays animation start correctly', () {
      final tween = DelayTween(begin: 0.0, end: 1.0, delay: 0.5);

      // Before delay (t < 0.5), should return begin value
      expect(tween.transform(0.0), 0.0);
      expect(tween.transform(0.25), 0.0);
      expect(tween.transform(0.49), 0.0);

      // At delay point (t = 0.5), should start transitioning
      expect(tween.transform(0.5), 0.0);

      // After delay, should interpolate normally
      expect(tween.transform(0.75), closeTo(0.5, 0.01));
      expect(tween.transform(1.0), 1.0);
    });

    test('handles zero delay', () {
      final tween = DelayTween(begin: 0.0, end: 1.0, delay: 0.0);

      // With no delay, should behave like normal tween
      expect(tween.transform(0.0), 0.0);
      expect(tween.transform(0.5), closeTo(0.5, 0.01));
      expect(tween.transform(1.0), 1.0);
    });

    test('handles near-full delay (0.95)', () {
      final tween = DelayTween(begin: 0.0, end: 1.0, delay: 0.95);

      // With near-full delay, most of time is delay
      expect(tween.transform(0.0), 0.0);
      expect(tween.transform(0.5), 0.0);
      expect(tween.transform(0.94), 0.0);
      // After delay, animation happens quickly
      expect(tween.transform(1.0), 1.0);
    });

    test('works with different begin and end values', () {
      final tween = DelayTween(begin: 100.0, end: 200.0, delay: 0.5);

      // Before delay
      expect(tween.transform(0.0), 100.0);
      expect(tween.transform(0.25), 100.0);

      // After delay
      expect(tween.transform(0.75), closeTo(150.0, 1.0));
      expect(tween.transform(1.0), 200.0);
    });

    test('works with negative values', () {
      final tween = DelayTween(begin: -50.0, end: 50.0, delay: 0.3);

      // Before delay
      expect(tween.transform(0.0), -50.0);
      expect(tween.transform(0.2), -50.0);

      // After delay
      expect(tween.transform(0.65), closeTo(0.0, 5.0));
      expect(tween.transform(1.0), 50.0);
    });

    test('clamps values correctly', () {
      final tween = DelayTween(begin: 0.0, end: 1.0, delay: 0.5);

      // Values outside 0-1 range should be handled gracefully
      expect(tween.transform(-0.1), 0.0);
      expect(tween.transform(1.1), 1.0);
    });

    test('different delays produce staggered effect', () {
      final tween1 = DelayTween(begin: 0.0, end: 1.0, delay: 0.0);
      final tween2 = DelayTween(begin: 0.0, end: 1.0, delay: 0.25);
      final tween3 = DelayTween(begin: 0.0, end: 1.0, delay: 0.5);

      // At t=0.5, tweens should be at different stages
      final value1 = tween1.transform(0.5);
      final value2 = tween2.transform(0.5);
      final value3 = tween3.transform(0.5);

      // First tween should be halfway
      expect(value1, closeTo(0.5, 0.01));

      // Second tween should be less than halfway
      expect(value2, lessThan(value1));
      expect(value2, greaterThan(0.0));

      // Third tween should just be starting
      expect(value3, closeTo(0.0, 0.01));
    });

    test('lerp method is correctly overridden', () {
      final tween = DelayTween(begin: 0.0, end: 100.0, delay: 0.4);

      // Test that lerp is called via transform
      final result = tween.transform(0.7);

      // At t=0.7 with delay=0.4:
      // Adjusted t = (0.7 - 0.4) / (1.0 - 0.4) = 0.3 / 0.6 = 0.5
      // lerp(0, 100, 0.5) = 50
      expect(result, closeTo(50.0, 1.0));
    });

    test('handles edge case: delay at boundaries', () {
      final tween = DelayTween(begin: 0.0, end: 1.0, delay: 0.5);

      // Right at the delay point
      expect(tween.transform(0.5), 0.0);

      // Just after the delay point
      expect(tween.transform(0.51), greaterThan(0.0));
    });

    test('maintains linearity after delay', () {
      final tween = DelayTween(begin: 0.0, end: 100.0, delay: 0.5);

      // After delay, should scale linearly
      final value1 = tween.transform(0.75); // 50% through active period
      final value2 = tween.transform(1.0);  // 100% through active period

      expect(value1, closeTo(50.0, 1.0));
      expect(value2, closeTo(100.0, 1.0));
    });
  });
}
