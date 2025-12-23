import 'package:flutter/material.dart';

/// Custom page transitions for the app
///
/// Following Animation Enhancement Rules:
/// - Duration: 200-500ms
/// - Easing curves (no linear)
/// - Platform compatible (iOS/Android)
/// - Preserves route settings
class AppPageTransitions {
  /// Standard fade transition (300ms)
  static Route<T> fadeTransition<T>({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      settings: settings, // PRESERVE route settings
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
    );
  }

  /// Slide from right transition (native iOS feel) (350ms)
  static Route<T> slideRightTransition<T>({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Slide from bottom transition (modal feel) (400ms)
  static Route<T> slideUpTransition<T>({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Scale and fade transition (dialog feel) (350ms)
  static Route<T> scaleTransition<T>({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
    double beginScale = 0.8,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween<double>(begin: beginScale, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Fade through transition (Material Design 3 style) (300ms)
  /// Screen A fades out, then Screen B fades in
  static Route<T> fadeThroughTransition<T>({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming page fades in on second half
        final fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
          ),
        );

        // Outgoing page fades out on first half
        final fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );

        return Stack(
          children: [
            // Outgoing page
            FadeTransition(
              opacity: fadeOutAnimation,
              child: Container(), // Previous page handled by Navigator
            ),
            // Incoming page
            FadeTransition(
              opacity: fadeInAnimation,
              child: child,
            ),
          ],
        );
      },
    );
  }

  /// Shared axis transition (Material Design 3 style) (400ms)
  /// Pages slide horizontally with a slight fade
  static Route<T> sharedAxisTransition<T>({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 400),
    bool reverse = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final direction = reverse ? -1.0 : 1.0;

        // Slide animation
        final slideInTween = Tween<Offset>(
          begin: Offset(0.3 * direction, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        final slideOutTween = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(-0.3 * direction, 0.0),
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        // Fade animation
        final fadeInTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        );

        final fadeOutTween = Tween<double>(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        );

        return Stack(
          children: [
            // Outgoing page
            SlideTransition(
              position: secondaryAnimation.drive(slideOutTween),
              child: FadeTransition(
                opacity: secondaryAnimation.drive(fadeOutTween),
                child: Container(), // Previous page handled by Navigator
              ),
            ),
            // Incoming page
            SlideTransition(
              position: animation.drive(slideInTween),
              child: FadeTransition(
                opacity: animation.drive(fadeInTween),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
