import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

enum GlassIntensity {
  light, // Subtle glass, more transparent
  medium, // Balanced glass effect
  strong, // Deep glass, more frosted
}

class FrostedGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurStrength;
  final GlassIntensity intensity;
  final Color? borderColor;
  final bool showInnerBorder;

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.blurStrength = 40.0,
    this.intensity = GlassIntensity.medium,
    this.borderColor,
    this.showInnerBorder = true,
  });

  // Get gradient opacity based on intensity
  List<Color> _getGradientColors() {
    switch (intensity) {
      case GlassIntensity.light:
        return [
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.05),
        ];
      case GlassIntensity.medium:
        return [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.08),
        ];
      case GlassIntensity.strong:
        return [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.15),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppTheme.goldColor.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius - 2),
              gradient: LinearGradient(
                colors: _getGradientColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // Add subtle inner border for depth
              border: showInnerBorder
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
