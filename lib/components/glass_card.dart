import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/noise_overlay.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;
  final Color? borderColor;
  final double borderWidth;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.blurSigma = 40,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: borderColor ?? (isDark ? Colors.white24 : Colors.white54),
                width: borderWidth,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurStrength;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;
  final Border? border;
  final bool enableNoise;
  final bool enableLightSimulation;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.blurStrength = 4.0,
    this.gradientColors,
    this.gradientStops,
    this.border,
    this.enableNoise = true,
    this.enableLightSimulation = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradientColors = [
      Colors.white.withValues(alpha: 0.18), // Increased from 0.15 for dramatic lightening
      Colors.white.withValues(alpha: 0.12), // Increased from 0.05 for dramatic lightening
    ];

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );

    // Add noise overlay if enabled
    if (enableNoise) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: StaticNoiseOverlay(
          opacity: 0.04,
          density: 0.4,
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? defaultGradientColors,
          stops: gradientStops ?? const [0.0, 1.0],
          begin: const AlignmentDirectional(0.98, -1.0),
          end: const AlignmentDirectional(-0.98, 1.0),
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(
          color: Colors.white.withValues(alpha: 0.4), // Increased from 0.2 for dramatic lightening
          width: 1,
        ),
        // Enhanced dual shadows for realistic depth
        boxShadow: [
          // Ambient shadow (far, soft) - reduced for dramatic lightening
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // Reduced from 0.3
            offset: const Offset(0, 10),
            blurRadius: 30,
            spreadRadius: -5,
          ),
          // Definition shadow (close, sharp) - reduced for dramatic lightening
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Reduced from 0.2
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
                  Colors.white.withValues(alpha: 0.3), // Increased to 0.3 for dramatic lightening
                  Colors.transparent,
                ],
              ),
            )
          : null,
      child: content,
    );
  }
}

class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blurSigma = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.3),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: child,
        ),
      ),
    );
  }
}

