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

  // Static gradient colors cached by intensity - avoids recalculating on every build
  static final Map<GlassIntensity, List<Color>> _gradientColorsCache = {
    GlassIntensity.light: [
      Colors.white.withValues(alpha: 0.10),
      Colors.white.withValues(alpha: 0.05),
    ],
    GlassIntensity.medium: [
      Colors.white.withValues(alpha: 0.15),
      Colors.white.withValues(alpha: 0.08),
    ],
    GlassIntensity.strong: [
      Colors.white.withValues(alpha: 0.25),
      Colors.white.withValues(alpha: 0.15),
    ],
  };

  // Static inner border color - avoids recalculating on every build
  static final Color _innerBorderColor = Colors.white.withValues(alpha: 0.2);

  // Get gradient colors from cache
  List<Color> _getGradientColors() => _gradientColorsCache[intensity]!;

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
                      color: _innerBorderColor,
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
