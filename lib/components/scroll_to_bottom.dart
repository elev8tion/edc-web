import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Glassmorphic scroll to bottom button that appears when user scrolls up
/// Matches the everyday-christian design system
class ScrollToBottom extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isVisible;
  final double? bottom;
  final double? right;

  const ScrollToBottom({
    super.key,
    required this.onPressed,
    required this.isVisible,
    this.bottom = 140,
    this.right = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: bottom,
      right: right,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.9),
              AppTheme.primaryColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill / 3.33),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill / 3.33),
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.all(14),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primaryText,
                size: 24,
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: AppAnimations.normal)
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            duration: AppAnimations.normal,
            curve: Curves.easeOut,
          ),
    );
  }
}
