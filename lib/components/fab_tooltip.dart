import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dark_glass_container.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

/// A tooltip that appears above or below a UI element to guide first-time users
///
/// This widget shows a DarkGlassContainer with instructional text and
/// an arrow to point at the target element.
class FabTooltip extends StatelessWidget {
  final String message;
  final bool pointingDown;

  const FabTooltip({
    super.key,
    this.message = 'Tap here to navigate ✨',
    this.pointingDown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Arrow at top if pointing down
          if (pointingDown) ...[
            // Tooltip content with pulse animation and gold border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  // Gold glow effect
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  // Depth shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: DarkGlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: AppTheme.goldColor,
                      size: ResponsiveUtils.iconSize(context, 20),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          .animate()
          .fadeIn(duration: 600.ms, delay: 300.ms, curve: Curves.easeOut)
          .slideY(begin: -0.1, end: 0, duration: 600.ms, delay: 300.ms, curve: Curves.easeOutCubic)
          .then() // Start pulse after initial animation
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.05,
            duration: 1500.ms,
            curve: Curves.easeInOut,
          ),

            const SizedBox(height: 4),

            // Arrow pointing down
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: const CustomPaint(
                size: Size(16, 12),
                painter: _ArrowPainter(pointingUp: false),
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: -0.5, end: 0, duration: 400.ms),
          ] else ...[
            // Original layout: Arrow up, then content (for FAB)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: const CustomPaint(
                size: Size(16, 12),
                painter: _ArrowPainter(pointingUp: true),
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.5, end: 0, duration: 400.ms),

            const SizedBox(height: 4),

            // Tooltip content with pulse animation and gold border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  // Gold glow effect
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  // Depth shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: DarkGlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: AppTheme.goldColor,
                      size: ResponsiveUtils.iconSize(context, 20),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 200.ms)
            .then() // Start pulse after initial animation
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleXY(
              begin: 1.0,
              end: 1.05,
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
          ],
        ],
      );
  }
}

/// Custom painter for arrow (can point up or down)
class _ArrowPainter extends CustomPainter {
  final bool pointingUp;

  const _ArrowPainter({this.pointingUp = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.goldColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppTheme.goldColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();

    if (pointingUp) {
      // Arrow pointing up
      path
        ..moveTo(0, size.height) // Bottom left
        ..lineTo(size.width / 2, 0) // Top center (point)
        ..lineTo(size.width, size.height) // Bottom right
        ..close();
    } else {
      // Arrow pointing down
      path
        ..moveTo(0, 0) // Top left
        ..lineTo(size.width / 2, size.height) // Bottom center (point)
        ..lineTo(size.width, 0) // Top right
        ..close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
