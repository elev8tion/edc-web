import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/noise_overlay.dart';

/// Simple Coach Mark Library for Everyday Christian
///
/// A lightweight tutorial overlay system with dark glass aesthetics
/// and full accessibility support.
///
/// Usage:
/// ```dart
/// SimpleCoachMark(
///   targets: [
///     CoachTarget(
///       key: buttonKey,
///       title: l10n.tutorialTitle,
///       description: l10n.tutorialDescription,
///     ),
///   ],
/// ).show(context);
/// ```

// ============================================================================
// ENUMS
// ============================================================================

/// Shape of the highlight around the target
enum HighlightShape {
  circle,
  rectangle,
}

/// Position of content relative to the target
enum ContentPosition {
  top,
  bottom,
  left,
  right,
}

// ============================================================================
// MODELS
// ============================================================================

/// Represents a single tutorial target
class CoachTarget {
  /// GlobalKey of the widget to highlight
  final GlobalKey key;

  /// Title text to display
  final String title;

  /// Description text to display
  final String? description;

  /// Custom widget to display instead of title/description
  final Widget? customContent;

  /// Where to position the content (default: bottom)
  final ContentPosition contentPosition;

  /// Shape of the highlight (default: circle)
  final HighlightShape shape;

  /// Padding around the highlighted widget
  final double padding;

  /// Border radius for rectangle shape
  final double borderRadius;

  /// Custom color for this target's highlight
  final Color? highlightColor;

  /// Semantic label for accessibility
  final String? semanticLabel;

  CoachTarget({
    required this.key,
    required this.title,
    this.description,
    this.customContent,
    this.contentPosition = ContentPosition.bottom,
    this.shape = HighlightShape.circle,
    this.padding = 10.0,
    this.borderRadius = AppRadius.md,
    this.highlightColor,
    this.semanticLabel,
  });
}

/// Configuration for the coach mark appearance
class CoachMarkConfig {
  /// Background overlay color
  final Color overlayColor;

  /// Overlay opacity (0.0 to 1.0)
  final double overlayOpacity;

  /// Default highlight color
  final Color highlightColor;

  /// Text style for titles
  final TextStyle titleStyle;

  /// Text style for descriptions
  final TextStyle descriptionStyle;

  /// Skip button text
  final String skipText;

  /// Skip button style
  final TextStyle skipTextStyle;

  /// Next button text
  final String nextText;

  /// Previous button text
  final String previousText;

  /// Animation duration
  final Duration animationDuration;

  /// Enable pulse animation on highlight
  final bool enablePulse;

  /// Enable dark glass styling
  final bool enableGlassEffect;

  /// Enable noise overlay on content cards
  final bool enableNoise;

  CoachMarkConfig({
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.85,
    this.highlightColor = Colors.transparent,
    this.titleStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    this.descriptionStyle = const TextStyle(
      fontSize: 14,
      color: Colors.white70,
    ),
    this.skipText = 'Skip',
    this.skipTextStyle = const TextStyle(
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    this.nextText = 'Next',
    this.previousText = 'Previous',
    this.animationDuration = const Duration(milliseconds: 300),
    this.enablePulse = true,
    this.enableGlassEffect = true,
    this.enableNoise = true,
  });
}

// ============================================================================
// MAIN COACH MARK CLASS
// ============================================================================

class SimpleCoachMark {
  final List<CoachTarget> targets;
  final CoachMarkConfig config;
  final VoidCallback? onFinish;
  final VoidCallback? onSkip;
  final Function(int)? onTargetClick;

  int _currentIndex = 0;
  OverlayEntry? _overlayEntry;

  SimpleCoachMark({
    required this.targets,
    CoachMarkConfig? config,
    this.onFinish,
    this.onSkip,
    this.onTargetClick,
  }) : config = config ?? CoachMarkConfig();

  /// Show the coach mark tutorial
  void show(BuildContext context) {
    if (targets.isEmpty) return;

    _currentIndex = 0;
    _overlayEntry = OverlayEntry(
      builder: (context) => _CoachMarkOverlay(
        coachMark: this,
        currentIndex: _currentIndex,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Go to next target
  void _next() {
    if (_currentIndex < targets.length - 1) {
      _currentIndex++;
      _rebuild();
    } else {
      _finish();
    }
  }

  /// Go to previous target
  void _previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _rebuild();
    }
  }

  /// Skip the tutorial
  void _skip() {
    onSkip?.call();
    _remove();
  }

  /// Finish the tutorial
  void _finish() {
    onFinish?.call();
    _remove();
  }

  /// Remove the overlay
  void _remove() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Rebuild the overlay with new index
  void _rebuild() {
    _overlayEntry?.markNeedsBuild();
  }
}

// ============================================================================
// OVERLAY WIDGET
// ============================================================================

class _CoachMarkOverlay extends StatefulWidget {
  final SimpleCoachMark coachMark;
  final int currentIndex;

  const _CoachMarkOverlay({
    required this.coachMark,
    required this.currentIndex,
  });

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Rect? _targetRect;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.coachMark.config.animationDuration,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted) {
        _updateTargetRect();
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CoachMarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.reset();
      _updateTargetRect();
      _animationController.forward();
    }
  }

  void _updateTargetRect() {
    final target = widget.coachMark.targets[widget.coachMark._currentIndex];
    final renderBox = target.key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null && mounted) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      setState(() {
        _targetRect = Rect.fromLTWH(
          position.dx - target.padding,
          position.dy - target.padding,
          size.width + (target.padding * 2),
          size.height + (target.padding * 2),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == null) {
      return const SizedBox.shrink();
    }

    final target = widget.coachMark.targets[widget.coachMark._currentIndex];
    final config = widget.coachMark.config;

    return Semantics(
      label: target.semanticLabel ?? '${target.title}. ${target.description ?? ''}',
      button: true,
      enabled: true,
      child: GestureDetector(
        // Tap anywhere to dismiss
        onTap: widget.coachMark._skip,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Overlay with hole
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _OverlayPainter(
                    targetRect: _targetRect!,
                    overlayColor: config.overlayColor,
                    overlayOpacity: config.overlayOpacity,
                    highlightColor: target.highlightColor ?? config.highlightColor,
                    shape: target.shape,
                    borderRadius: target.borderRadius,
                    pulseAnimation: config.enablePulse ? _animationController : null,
                  ),
                ),

                // Content
                _buildContent(context, target),

                // Skip button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: widget.coachMark._skip,
                    child: _buildGlassButton(
                      context,
                      config.skipText,
                      config.skipTextStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a glass-styled button
  Widget _buildGlassButton(BuildContext context, String text, TextStyle style) {
    final config = widget.coachMark.config;

    Widget button = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(text, style: style),
    );

    if (config.enableGlassEffect) {
      button = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: button,
        ),
      );
    }

    return button;
  }

  Widget _buildContent(BuildContext context, CoachTarget target) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate content position
    double? top, bottom, left, right;

    switch (target.contentPosition) {
      case ContentPosition.top:
        bottom = screenSize.height - _targetRect!.top + 20;
        left = 20;
        right = 20;
        break;
      case ContentPosition.bottom:
        top = _targetRect!.bottom + 20;
        left = 20;
        right = 20;
        break;
      case ContentPosition.left:
        right = screenSize.width - _targetRect!.left + 20;
        top = _targetRect!.top;
        break;
      case ContentPosition.right:
        left = _targetRect!.right + 20;
        top = _targetRect!.top;
        break;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content card with dark glass styling
          _buildContentCard(context, target),

          const SizedBox(height: 16),

          // Navigation buttons
          _buildNavigationButtons(context),
        ],
      ),
    );
  }

  /// Build content card with dark glass styling
  Widget _buildContentCard(BuildContext context, CoachTarget target) {
    final CoachMarkConfig config = widget.coachMark.config;

    Widget content = target.customContent ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(target.title, style: config.titleStyle),
            if (target.description != null) ...[
              const SizedBox(height: 8),
              Text(target.description!, style: config.descriptionStyle),
            ],
          ],
        );

    // Wrap in dark glass container
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          // Ambient shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 10),
            blurRadius: 30,
            spreadRadius: -5,
          ),
          // Definition shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: content,
    );

    // Apply glass effect
    if (config.enableGlassEffect) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: card,
        ),
      );
    }

    // Apply noise overlay
    if (config.enableNoise) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: StaticNoiseOverlay(
          opacity: 0.04,
          density: 0.4,
          child: card,
        ),
      );
    }

    return card;
  }

  /// Build navigation buttons
  Widget _buildNavigationButtons(BuildContext context) {
    final config = widget.coachMark.config;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button (or spacer)
          if (widget.coachMark._currentIndex > 0)
            GestureDetector(
              onTap: widget.coachMark._previous,
              child: _buildGlassButton(
                context,
                config.previousText,
                config.skipTextStyle,
              ),
            )
          else
            const SizedBox.shrink(),

          // Next/Finish button
          GestureDetector(
            onTap: widget.coachMark._next,
            child: _buildGlassButton(
              context,
              widget.coachMark._currentIndex == widget.coachMark.targets.length - 1
                  ? 'Finish'
                  : config.nextText,
              config.skipTextStyle.copyWith(color: AppTheme.goldColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER
// ============================================================================

class _OverlayPainter extends CustomPainter {
  final Rect targetRect;
  final Color overlayColor;
  final double overlayOpacity;
  final Color highlightColor;
  final HighlightShape shape;
  final double borderRadius;
  final AnimationController? pulseAnimation;

  _OverlayPainter({
    required this.targetRect,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.highlightColor,
    required this.shape,
    required this.borderRadius,
    this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw overlay
    final overlayPaint = Paint()
      ..color = overlayColor.withValues(alpha: overlayOpacity);

    // Create path with hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Add hole based on shape
    final holePath = shape == HighlightShape.circle
        ? _createCircleHole()
        : _createRectHole();

    path.addPath(holePath, Offset.zero);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Draw highlight border with pulse effect
    if (pulseAnimation != null) {
      final pulseValue = 1.0 + (pulseAnimation!.value * 0.05);
      final pulsedRect = Rect.fromCenter(
        center: targetRect.center,
        width: targetRect.width * pulseValue,
        height: targetRect.height * pulseValue,
      );

      final highlightPaint = Paint()
        ..color = AppTheme.goldColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      if (shape == HighlightShape.circle) {
        canvas.drawCircle(
          pulsedRect.center,
          pulsedRect.width / 2,
          highlightPaint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            pulsedRect,
            Radius.circular(borderRadius),
          ),
          highlightPaint,
        );
      }
    }
  }

  Path _createCircleHole() {
    final center = targetRect.center;
    final radius = (targetRect.width > targetRect.height
            ? targetRect.width
            : targetRect.height) /
        2;

    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  Path _createRectHole() {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          targetRect,
          Radius.circular(borderRadius),
        ),
      );
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        overlayOpacity != oldDelegate.overlayOpacity;
  }
}
