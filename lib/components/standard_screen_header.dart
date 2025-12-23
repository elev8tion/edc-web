import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../components/glassmorphic_fab_menu.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

/// Standardized screen header component for consistent appearance across all screens
///
/// Usage:
/// - For screens with FAB in header: Use default (showFAB: true)
/// - For screens with positioned FAB elsewhere: Set showFAB: false
/// - For screens with trailing widget (like Verse Library menu): Provide trailingWidget
class StandardScreenHeader extends StatelessWidget {
  /// The title text (e.g., "Bible Browser", "Prayer Journal")
  final String title;

  /// The subtitle text (e.g., "Read any chapter freely")
  final String subtitle;

  /// Whether to show the FAB menu in the header row
  /// Set to false if FAB is positioned separately (Devotional, Settings)
  final bool showFAB;

  /// Optional widget to show on the right side (e.g., menu button for Verse Library)
  final Widget? trailingWidget;

  /// Optional custom subtitle widget (for Devotional stats)
  final Widget? customSubtitle;

  const StandardScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showFAB = true,
    this.trailingWidget,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Row(
        children: [
          // FAB or spacer
          if (showFAB)
            const GlassmorphicFABMenu()
          else
            const SizedBox(width: 56 + AppSpacing.lg), // Reserve space for positioned FAB

          const SizedBox(width: AppSpacing.lg),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 24, minSize: 20, maxSize: 28),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(duration: AppAnimations.slow).slideX(begin: -0.3),

                const SizedBox(height: 4),

                // Use custom subtitle widget if provided, otherwise default text
                if (customSubtitle != null)
                  customSubtitle!
                else
                  AutoSizeText(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).animate().fadeIn(duration: AppAnimations.slow, delay: AppAnimations.fast),
              ],
            ),
          ),

          // Optional trailing widget (menu button, etc.)
          if (trailingWidget != null) ...[
            const SizedBox(width: 8),
            trailingWidget!,
          ],
        ],
      ),
    );
  }
}
