import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/noise_overlay.dart';

/// Enhanced GlassButton with realistic glass surface and press animations
///
/// Visual Enhancements (matching DarkGlassContainer):
/// - BackdropFilter for proper glass blur
/// - Dual-shadow technique (ambient + definition)
/// - Static noise overlay for texture authenticity
/// - Light simulation via foreground gradient
///
/// Interactive Features:
/// - Optional press animation (scale 0.95 default)
/// - Haptic feedback on press (medium impact default)
/// - Maintains all existing functionality
/// - Does not block touch events
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final Widget? loadingWidget;
  final Color? borderColor;

  // ✅ ANIMATION PARAMETERS (with defaults - no breaking changes)
  final bool enablePressAnimation;
  final double pressScale;
  final bool enableHaptics;
  final HapticFeedbackType hapticType;

  // ✅ VISUAL ENHANCEMENT PARAMETERS (matching DarkGlassContainer)
  final double blurStrength;
  final bool enableNoise;
  final bool enableLightSimulation;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.loadingWidget,
    this.borderColor,
    // ✅ Optional animation parameters with safe defaults
    this.enablePressAnimation = true,
    this.pressScale = 0.95, // Rule: 0.90-0.98
    this.enableHaptics = true,
    this.hapticType = HapticFeedbackType.medium,
    // ✅ Optional visual enhancement parameters
    this.blurStrength = 40.0,
    this.enableNoise = true,
    this.enableLightSimulation = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

/// Haptic feedback type enum
enum HapticFeedbackType {
  light,
  medium,
  heavy,
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize animation controller with fast duration (< 100ms for visual feedback)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 80), // Fast press animation
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // ✅ REQUIRED: Dispose animation controller to prevent memory leaks
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading && widget.onPressed != null && widget.enablePressAnimation) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enablePressAnimation) {
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enablePressAnimation) {
      _scaleController.reverse();
    }
  }

  void _handleTap() {
    // ✅ Haptic feedback BEFORE calling onPressed (Rule: provide feedback within 100ms)
    if (widget.enableHaptics && widget.onPressed != null) {
      switch (widget.hapticType) {
        case HapticFeedbackType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          HapticFeedback.heavyImpact();
          break;
      }
    }

    // ✅ PRESERVE EXISTING BEHAVIOR: Call original onPressed
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final responsiveHeight = ResponsiveUtils.scaleSize(
      context,
      widget.height,
      minScale: 0.8,
      maxScale: 1.5,
    );
    final responsiveBorderRadius = ResponsiveUtils.borderRadius(context, 28);

    // ✅ Build button content
    Widget buttonContent = Center(
      child: widget.isLoading
          ? (widget.loadingWidget ?? SizedBox(
              height: ResponsiveUtils.scaleSize(context, 20, minScale: 0.8, maxScale: 1.5),
              width: ResponsiveUtils.scaleSize(context, 20, minScale: 0.8, maxScale: 1.5),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AutoSizeText(
                widget.text,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 18, minSize: 14, maxSize: 27),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
    );

    // ✅ Build glass content with BackdropFilter blur
    Widget glassContent = ClipRRect(
      borderRadius: BorderRadius.circular(responsiveBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurStrength,
          sigmaY: widget.blurStrength,
        ),
        child: Container(
          height: responsiveHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
            color: Colors.black.withValues(alpha: 0.1),
            border: Border.all(
              color: widget.borderColor ?? AppTheme.primaryColor,
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: null, // Handled by GestureDetector
              borderRadius: BorderRadius.circular(responsiveBorderRadius),
              child: buttonContent,
            ),
          ),
        ),
      ),
    );

    // ✅ Add noise overlay if enabled
    if (widget.enableNoise) {
      glassContent = ClipRRect(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
        child: StaticNoiseOverlay(
          opacity: 0.04,
          density: 0.4,
          child: glassContent,
        ),
      );
    }

    // ✅ Wrap with container for dual shadows and light simulation
    Widget enhancedGlass = Container(
      width: widget.width ?? double.infinity,
      height: responsiveHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
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
      foregroundDecoration: widget.enableLightSimulation
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(responsiveBorderRadius),
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

    // ✅ Wrap with GestureDetector and ScaleTransition for press animation
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.isLoading ? null : _handleTap,
        child: enhancedGlass,
      ),
    );
  }
}