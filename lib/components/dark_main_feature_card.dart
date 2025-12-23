import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'dart:ui';
import '../utils/motion_character.dart';
import '../utils/ui_audio.dart';
import '../widgets/noise_overlay.dart';

enum GlassIntensity {
  light, // Subtle glass, more transparent
  medium, // Balanced glass effect
  strong, // Deep glass, more frosted
}

class DarkMainFeatureCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurStrength;
  final GlassIntensity intensity;
  final Color? borderColor;
  final bool showInnerBorder;

  // NEW: Optional press animation parameters
  final bool enablePressAnimation;
  final double pressScale;
  final bool enableHaptics;
  final bool enableAudio;

  const DarkMainFeatureCard({
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
    this.enablePressAnimation = true,
    this.pressScale = 0.98,
    this.enableHaptics = true,
    this.enableAudio = true,
  });

  @override
  State<DarkMainFeatureCard> createState() => _DarkMainFeatureCardState();
}

class _DarkMainFeatureCardState extends State<DarkMainFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  final _audio = UIAudio();

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0), // Driven by spring physics
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      // Spring animation: press down with snappy spring
      _scaleController.animateWith(
        SpringSimulation(
          MotionCharacter.snappy,
          _scaleController.value,
          widget.pressScale,
          0,
        ),
      );
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enablePressAnimation) {
      // Spring animation: release with smooth spring
      _scaleController.animateWith(
        SpringSimulation(
          MotionCharacter.smooth,
          _scaleController.value,
          1.0,
          0,
        ),
      );
    }
  }

  void _handleTapCancel() {
    if (widget.enablePressAnimation) {
      // Spring animation: cancel with playful bounce back
      _scaleController.animateWith(
        SpringSimulation(
          MotionCharacter.playful,
          _scaleController.value,
          1.0,
          0,
        ),
      );
    }
  }

  void _handleTap() {
    // Haptic & audio feedback BEFORE calling onTap
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    if (widget.enableAudio) {
      _audio.playClick();
    }

    widget.onTap?.call();
  }

  // Get gradient opacity based on intensity
  List<Color> _getGradientColors() {
    switch (widget.intensity) {
      case GlassIntensity.light:
        return [
          Colors.black.withValues(alpha: 0.10),
          Colors.black.withValues(alpha: 0.05),
        ];
      case GlassIntensity.medium:
        return [
          Colors.black.withValues(alpha: 0.15),
          Colors.black.withValues(alpha: 0.08),
        ];
      case GlassIntensity.strong:
        return [
          Colors.black.withValues(alpha: 0.25),
          Colors.black.withValues(alpha: 0.15),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build glass content with noise overlay
    Widget glassContent = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius - 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blurStrength, sigmaY: widget.blurStrength),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius - 2),
            gradient: LinearGradient(
              colors: _getGradientColors(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            // Add subtle inner border for depth
            border: widget.showInnerBorder
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );

    // Add noise overlay for texture authenticity
    glassContent = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius - 2),
      child: StaticNoiseOverlay(
        opacity: 0.04,
        density: 0.4,
        child: glassContent,
      ),
    );

    Widget cardWidget = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: widget.borderColor ?? Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
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
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5],
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: glassContent,
    );

    if (widget.onTap != null) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}
