import 'package:flutter/material.dart';
import '../gradient_background.dart';
import '../glassmorphic_fab_menu.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extensions.dart';

/// A scaffold wrapper that maintains the gradient background during loading states.
/// Use this as the base for any screen that needs skeleton loading.
class SkeletonScaffold extends StatelessWidget {
  final Widget child;
  final bool showFAB;
  final GlobalKey? fabKey;

  const SkeletonScaffold({
    super.key,
    required this.child,
    this.showFAB = true,
    this.fabKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Always show gradient background
          const GradientBackground(),
          // Content
          child,
          // Optionally show FAB
          if (showFAB)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.xl,
              left: AppSpacing.xl,
              child: GlassmorphicFABMenu(key: fabKey),
            ),
        ],
      ),
    );
  }
}
