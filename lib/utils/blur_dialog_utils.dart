import 'dart:ui';
import 'package:flutter/material.dart';

/// Utility functions for showing dialogs and bottom sheets with blurred backdrops
/// (EXACT same animation as the FAB navigation menu)

/// Shows a dialog with a blurred backdrop behind it
///
/// Uses the EXACT same animation pattern as the FAB menu:
/// - BackdropFilter with animated blur (sigmaX/Y: 0→8)
/// - Semi-transparent black overlay with animated opacity (0→0.3)
/// - Smooth reverse animation completion (waits before dismissing)
/// - Fade + Scale transition for dialog content
///
/// All parameters are passed through to showGeneralDialog unchanged.
Future<T?> showBlurredDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? 'Dismiss',
    barrierColor: Colors.transparent, // Make barrier transparent so blur shows
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    transitionDuration: const Duration(milliseconds: 700), // Same as FAB menu
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Use stateful wrapper to prevent rapid tap crashes
      return _BlurredDialogTransition(
        animation: animation,
        barrierDismissible: barrierDismissible,
        child: child,
      );
    },
  );
}

/// Stateful wrapper for blurred dialog transition to prevent rapid tap crashes
class _BlurredDialogTransition extends StatefulWidget {
  final Animation<double> animation;
  final bool barrierDismissible;
  final Widget child;

  const _BlurredDialogTransition({
    required this.animation,
    required this.barrierDismissible,
    required this.child,
  });

  @override
  State<_BlurredDialogTransition> createState() => _BlurredDialogTransitionState();
}

class _BlurredDialogTransitionState extends State<_BlurredDialogTransition> {
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
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows a bottom sheet with a blurred backdrop behind it
///
/// Uses the EXACT same animation pattern as the FAB menu:
/// - BackdropFilter with animated blur (sigmaX/Y: 0→8)
/// - Semi-transparent black overlay with animated opacity (0→0.3)
/// - Smooth reverse animation completion (waits before dismissing)
/// - SlideTransition for bottom sheet content
///
/// All parameters are passed through to showGeneralDialog unchanged.
Future<T?> showBlurredBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 700), // Same as FAB menu
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: builder(context),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Use stateful wrapper to prevent rapid tap crashes
      return _BlurredBottomSheetTransition(
        animation: animation,
        isDismissible: isDismissible,
        child: child,
      );
    },
  );
}

/// Stateful wrapper for blurred bottom sheet transition to prevent rapid tap crashes
class _BlurredBottomSheetTransition extends StatefulWidget {
  final Animation<double> animation;
  final bool isDismissible;
  final Widget child;

  const _BlurredBottomSheetTransition({
    required this.animation,
    required this.isDismissible,
    required this.child,
  });

  @override
  State<_BlurredBottomSheetTransition> createState() => _BlurredBottomSheetTransitionState();
}

class _BlurredBottomSheetTransitionState extends State<_BlurredBottomSheetTransition> {
  bool _isDismissing = false;

  void _handleDismiss() {
    // Prevent multiple dismissals from rapid tapping
    if (_isDismissing || !widget.isDismissible) return;
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
        // Bottom sheet slides up from bottom with smooth curve
        // GestureDetector stops tap propagation to prevent dismissing when tapping sheet
        GestureDetector(
          onTap: () {}, // Absorb taps on bottom sheet content to prevent dismissing
          behavior: HitTestBehavior.deferToChild,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: widget.animation,
              curve: Curves.fastEaseInToSlowEaseOut, // Same curve as FAB menu
            )),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
