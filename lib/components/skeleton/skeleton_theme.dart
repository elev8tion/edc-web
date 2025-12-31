import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extensions.dart';

/// Custom skeleton theme for dark glassmorphic UI
/// Uses shimmer effect that works well with the gradient background
class AppSkeletonTheme {
  static SkeletonizerConfigData get dark => SkeletonizerConfigData(
        effect: ShimmerEffect(
          baseColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.15),
          duration: const Duration(milliseconds: 1500),
        ),
        justifyMultiLineText: true,
        textBorderRadius: TextBoneBorderRadius(
          BorderRadius.circular(AppRadius.xs),
        ),
        containersColor: Colors.white.withValues(alpha: 0.08),
        enableSwitchAnimation: true,
      );

  /// Wraps a widget with Skeletonizer using the app's dark theme
  static Widget wrap({
    required Widget child,
    required bool enabled,
  }) {
    return Skeletonizer(
      enabled: enabled,
      effect: ShimmerEffect(
        baseColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.15),
        duration: const Duration(milliseconds: 1500),
      ),
      justifyMultiLineText: true,
      containersColor: Colors.white.withValues(alpha: 0.08),
      enableSwitchAnimation: true,
      child: child,
    );
  }
}
