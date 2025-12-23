import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/blur_dialog_utils.dart';
import '../widgets/noise_overlay.dart';

/// Enhanced BaseBottomSheet with realistic glass surface
///
/// This is the UNIVERSAL bottom sheet style used throughout the app.
///
/// Visual Enhancements (matching DarkGlassContainer):
/// - BackdropFilter for proper glass blur
/// - Dual-shadow technique (ambient + definition)
/// - Static noise overlay for texture authenticity
/// - Light simulation via foreground gradient
///
/// Features:
/// - Dark gradient background for maximum content readability
/// - Consistent rounded corners and drag handle
/// - Optional title header
/// - Professional glassmorphism effect
class BaseBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showHandle;
  final double? height;

  // ✅ VISUAL ENHANCEMENT PARAMETERS (matching DarkGlassContainer)
  final double blurStrength;
  final bool enableNoise;
  final bool enableLightSimulation;

  const BaseBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.height,
    // ✅ Optional visual enhancement parameters
    this.blurStrength = 40.0,
    this.enableNoise = true,
    this.enableLightSimulation = true,
  });

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.vertical(top: Radius.circular(AppRadius.xxl));

    // ✅ Build sheet content
    Widget sheetContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHandle)
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.xs / 4),
            ),
          ),
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ),
        Flexible(
          child: SafeArea(
            top: false, // Don't add padding at top
            child: child,
          ),
        ),
      ],
    );

    // ✅ Build glass content with BackdropFilter blur
    Widget glassContent = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurStrength,
          sigmaY: blurStrength,
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate-800
                const Color(0xFF0F172A).withValues(alpha: 0.98), // Slate-900
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: sheetContent,
        ),
      ),
    );

    // ✅ Add noise overlay if enabled
    if (enableNoise) {
      glassContent = ClipRRect(
        borderRadius: borderRadius,
        child: StaticNoiseOverlay(
          opacity: 0.04,
          density: 0.4,
          child: glassContent,
        ),
      );
    }

    // ✅ Wrap with container for dual shadows and light simulation
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // Enhanced dual shadows for realistic depth
        boxShadow: [
          // Ambient shadow (far, soft)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, -10),
            blurRadius: 30,
            spreadRadius: -5,
          ),
          // Definition shadow (close, sharp)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, -4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      // Light simulation via foreground decoration
      foregroundDecoration: enableLightSimulation
          ? BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5],
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            )
          : null,
      child: glassContent,
    );
  }
}

/// Universal helper function for showing standardized dark gradient bottom sheets
///
/// This is the RECOMMENDED way to show bottom sheets throughout the app.
/// Provides consistent dark gradient styling for all bottom sheets.
Future<T?> showCustomBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool showHandle = true,
  double? height,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showBlurredBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    enableDrag: enableDrag,
    isDismissible: isDismissible,
    builder: (context) => BaseBottomSheet(
      title: title,
      showHandle: showHandle,
      height: height,
      child: child,
    ),
  );
}
