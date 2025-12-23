import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FrostedGlass extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurStrength;
  final bool isNested;

  const FrostedGlass({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.blurStrength = 40.0,
    this.isNested = false,
  });

  @override
  Widget build(BuildContext context) {
    // Different glass effects for nested vs main containers
    final gradientColors = isNested
        ? [
            Colors.white.withValues(alpha:0.05),
            Colors.white.withValues(alpha:0.02),
          ]
        : [
            Colors.white.withValues(alpha:0.15),
            Colors.white.withValues(alpha:0.08),
          ];

    final borderColor = AppTheme.goldColor.withValues(alpha:0.6);
    final borderWidth = isNested ? 1.0 : 2.0;
    final blur = isNested ? blurStrength * 0.5 : blurStrength;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          stops: const [0.0, 1.0],
          begin: const AlignmentDirectional(0.98, -1.0),
          end: const AlignmentDirectional(-0.98, 1.0),
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}

class ClearGlass extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurStrength;

  const ClearGlass({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.blurStrength = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
