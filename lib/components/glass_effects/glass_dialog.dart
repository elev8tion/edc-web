import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

/// Shows a glass morphism style dialog
///
/// Uses the EXACT same animation pattern as the FAB menu:
/// - BackdropFilter with animated blur (sigmaX/Y: 0→8)
/// - Semi-transparent black overlay with animated opacity (0→0.3)
/// - Smooth reverse animation completion (waits before dismissing)
/// - Fade + Scale transition for dialog content
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  Color? barrierColor,
  Duration transitionDuration = const Duration(milliseconds: 700),
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent, // Make barrier transparent so blur shows
    transitionDuration: transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) {
      return child;
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Use stateful wrapper to prevent rapid tap crashes
      return _GlassDialogTransition(
        animation: animation,
        barrierDismissible: barrierDismissible,
        child: child,
      );
    },
  );
}

/// Stateful wrapper for glass dialog transition to prevent rapid tap crashes
class _GlassDialogTransition extends StatefulWidget {
  final Animation<double> animation;
  final bool barrierDismissible;
  final Widget child;

  const _GlassDialogTransition({
    required this.animation,
    required this.barrierDismissible,
    required this.child,
  });

  @override
  State<_GlassDialogTransition> createState() => _GlassDialogTransitionState();
}

class _GlassDialogTransitionState extends State<_GlassDialogTransition> {
  bool _isDismissing = false;

  void _handleDismiss() {
    // Prevent multiple dismissals from rapid tapping
    if (_isDismissing || !widget.barrierDismissible) return;
    _isDismissing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated blurred backdrop with tap-to-dismiss - ONLY on the backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: _handleDismiss,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: widget.animation,
              builder: (context, _) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.animation.value * 8, // 0→8 during open, 8→0 during close
                    sigmaY: widget.animation.value * 8,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3 * widget.animation.value), // 0→0.3
                  ),
                );
              },
            ),
          ),
        ),
        // Dialog content with fade + scale animation (like FAB menu items)
        // GestureDetector stops tap propagation to prevent dismissing when tapping dialog
        Center(
          child: GestureDetector(
            onTap: () {}, // Absorb taps on dialog content to prevent dismissing
            behavior: HitTestBehavior.deferToChild,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: widget.animation,
                curve: Curves.fastEaseInToSlowEaseOut, // Same curve as FAB menu
              ),
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: widget.animation,
                  curve: Curves.fastEaseInToSlowEaseOut,
                ),
                child: AlertDialog(
                  backgroundColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Glass morphism container widget for dialogs - uses main GlassContainer from glass_card.dart

/// Standard glass dialog button
class GlassDialogButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final bool isPrimary;

  const GlassDialogButton({
    super.key,
    required this.text,
    required this.onTap,
    this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? (isPrimary ? AppTheme.primaryColor : AppTheme.secondaryColor);
    final responsivePaddingHorizontal = ResponsiveUtils.scaleSize(context, 24, minScale: 0.8, maxScale: 1.5);
    final responsivePaddingVertical = ResponsiveUtils.scaleSize(context, 12, minScale: 0.8, maxScale: 1.5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: responsivePaddingHorizontal, vertical: responsivePaddingVertical),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              buttonColor,
              buttonColor.withValues(alpha: 0.8),
              buttonColor,
            ],
            stops: const [0, 0.6, 1],
            begin: const AlignmentDirectional(-1, 0.5),
            end: const AlignmentDirectional(1, -0.5),
          ),
          borderRadius: AppRadius.largeCardRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 11, maxSize: 21),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}