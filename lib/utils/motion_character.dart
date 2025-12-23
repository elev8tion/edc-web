import 'package:flutter/physics.dart';

/// MotionCharacter - Consistent spring animation personalities
///
/// Provides predefined spring characteristics for different UI animation needs:
/// - Smooth: Professional, no bounce (ratio = 1.0)
/// - Playful: Moderate bounce (ratio = 0.7)
/// - Snappy: Fast, responsive (high stiffness)
class MotionCharacter {
  /// Smooth - professional, no bounce
  /// Perfect for menu transitions, overlays, and professional UI elements
  static SpringDescription get smooth => SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 300,
        ratio: 1.0,
      );

  /// Playful - moderate bounce
  /// Great for buttons returning to rest, FAB menu items
  static SpringDescription get playful => SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 300,
        ratio: 0.7,
      );

  /// Snappy - fast, responsive
  /// Ideal for quick interactions, icon changes, immediate feedback
  static SpringDescription get snappy => SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 800,
        ratio: 1.0,
      );
}
