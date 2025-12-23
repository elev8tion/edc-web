import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Glassmorphic animated typing indicator
/// Shows three dots with staggered fade animation
class IsTypingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final Duration duration;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const IsTypingIndicator({
    super.key,
    this.size = 8,
    this.color,
    this.duration = const Duration(milliseconds: 600),
    this.spacing = 4,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          SizedBox(width: spacing),
          _buildDot(200),
          SizedBox(width: spacing),
          _buildDot(400),
        ],
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppColors.tertiaryText,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(
          duration: duration,
          delay: delayMs.ms,
        )
        .then()
        .fadeOut(
          duration: duration,
        );
  }
}

/// Glassmorphic typing indicator container
/// Shows AI is typing with glassmorphic background
class GlassTypingIndicator extends StatelessWidget {
  final double size;
  final Color? dotColor;
  final String? message;

  const GlassTypingIndicator({
    super.key,
    this.size = 8,
    this.dotColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.3),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: AppRadius.mediumRadius,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primaryText,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Typing indicator bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xs),
                  topRight: Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(AppRadius.lg),
                  bottomRight: Radius.circular(AppRadius.lg),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IsTypingIndicator(
                    size: size,
                    color: dotColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: Text(
                        message!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal)
        .slideX(begin: -0.3);
  }
}
