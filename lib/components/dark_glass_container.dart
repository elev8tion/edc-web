import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/noise_overlay.dart';

/// Enhanced DarkGlassContainer with realistic glass surface
///
/// Features:
/// - BackdropFilter for proper glass blur
/// - Dual-shadow technique (ambient + definition)
/// - Static noise overlay for texture authenticity
/// - Light simulation via foreground gradient
/// - Optional parameters with safe defaults (no breaking changes)
class DarkGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurStrength;
  final bool enableNoise;
  final bool enableLightSimulation;

  const DarkGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.md,
    this.blurStrength = 40.0,
    this.enableNoise = true,
    this.enableLightSimulation = true,
  });

  @override
  Widget build(BuildContext context) {
    // Build glass content with blur
    Widget glassContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: Container(
          padding: padding ?? AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.black.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );

    // Add noise overlay if enabled
    if (enableNoise) {
      glassContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: StaticNoiseOverlay(
          opacity: 0.04,
          density: 0.4,
          child: glassContent,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Enhanced dual shadows for realistic depth
        boxShadow: [
          // Ambient shadow (far, soft)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 10),
            blurRadius: 30,
            spreadRadius: -5,
          ),
          // Definition shadow (close, sharp)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      // Light simulation via foreground decoration
      foregroundDecoration: enableLightSimulation
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
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
