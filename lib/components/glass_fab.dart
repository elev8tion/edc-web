import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Circular glassmorphic FAB
/// Matches the everyday-christian design system with frosted glass effect
class GlassFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double? bottom;
  final double? right;
  final double size;

  const GlassFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.bottom = 16,
    this.right = 16,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    // Add system padding (navigation bar on Android, home indicator on iOS)
    final systemPadding = MediaQuery.of(context).padding.bottom;
    final effectiveBottom = (bottom ?? 16) + systemPadding;

    return Positioned(
      bottom: effectiveBottom,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.goldColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
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
            borderRadius: BorderRadius.circular(size / 2),
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon,
                color: AppColors.primaryText,
                size: 28,
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: AppAnimations.normal)
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: AppAnimations.normal,
            curve: Curves.easeOut,
          ),
    );
  }
}
