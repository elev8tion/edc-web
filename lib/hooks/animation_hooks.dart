import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Hook for fade-in animation with optional delay
/// Uses isMounted ValueNotifier to safely cancel delayed callbacks
AnimationController useFadeInAnimation({
  Duration duration = const Duration(milliseconds: 600),
  Duration delay = Duration.zero,
}) {
  final controller = useAnimationController(duration: duration);
  final isMounted = useRef(true);

  useEffect(() {
    isMounted.value = true;
    Future.delayed(delay, () {
      // Safety check: only forward if still mounted and not completed
      if (isMounted.value && controller.status != AnimationStatus.completed) {
        try {
          controller.forward();
        } catch (_) {
          // Controller was disposed, ignore
        }
      }
    });
    return () {
      isMounted.value = false;
    };
  }, [delay]);

  return controller;
}

/// Hook for scale animation with optional delay
/// Uses isMounted ValueNotifier to safely cancel delayed callbacks
AnimationController useScaleAnimation({
  Duration duration = const Duration(milliseconds: 800),
  Duration delay = Duration.zero,
}) {
  final controller = useAnimationController(duration: duration);
  final isMounted = useRef(true);

  useEffect(() {
    isMounted.value = true;
    Future.delayed(delay, () {
      // Safety check: only forward if still mounted and not completed
      if (isMounted.value && controller.status != AnimationStatus.completed) {
        try {
          controller.forward();
        } catch (_) {
          // Controller was disposed, ignore
        }
      }
    });
    return () {
      isMounted.value = false;
    };
  }, [delay]);

  return controller;
}

/// Hook for combined fade and scale animation
/// Uses isMounted ValueNotifier to safely cancel delayed callbacks
({AnimationController fade, AnimationController scale}) useFadeAndScale({
  Duration fadeDuration = const Duration(milliseconds: 1500),
  Duration scaleDuration = const Duration(milliseconds: 2000),
  Duration delay = Duration.zero,
}) {
  final fadeController = useAnimationController(duration: fadeDuration);
  final scaleController = useAnimationController(duration: scaleDuration);
  final isMounted = useRef(true);

  useEffect(() {
    isMounted.value = true;
    Future.delayed(delay, () {
      // Safety check: only forward if still mounted
      if (isMounted.value) {
        try {
          fadeController.forward();
          scaleController.forward();
        } catch (_) {
          // Controllers were disposed, ignore
        }
      }
    });
    return () {
      isMounted.value = false;
    };
  }, [delay]);

  return (fade: fadeController, scale: scaleController);
}

/// Hook for auto-scrolling to bottom
void useAutoScrollToBottom(ScrollController controller, List<dynamic> items) {
  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    return null;
  }, [items.length]);
}
