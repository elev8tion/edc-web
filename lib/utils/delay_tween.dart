import 'package:flutter/animation.dart';

/// A Tween that delays the animation by a specified amount
///
/// Used for creating staggered animations where multiple elements
/// animate with offset timing. Essential for the DancingLogoLoader.
class DelayTween extends Tween<double> {
  /// Creates a delayed tween
  ///
  /// [begin] - Starting value (typically 0.0)
  /// [end] - Ending value (typically 1.0)
  /// [delay] - Delay fraction (0.0 to 1.0) before animation starts
  DelayTween({
    required double begin,
    required double end,
    required this.delay,
  }) : super(begin: begin, end: end);

  /// The delay as a fraction of the total animation duration (0.0 to 1.0)
  final double delay;

  @override
  double lerp(double t) {
    // Calculate the adjusted time after applying delay
    // If t is before the delay, return begin value
    // If delay is 1.0, animation never starts - always return start value
    if (delay >= 1.0) {
      return begin ?? 0.0;
    }

    // Clamp t to valid range
    final clampedT = t.clamp(0.0, 1.0);

    // If t is before delay, return begin value
    if (clampedT < delay) {
      return begin ?? 0.0;
    }

    // Otherwise, scale the remaining time (t - delay) / (1 - delay)
    final adjustedT = ((clampedT - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    return super.lerp(adjustedT);
  }
}
