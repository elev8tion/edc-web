import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import 'glassmorphic_fab_menu.dart';
import '../l10n/app_localizations.dart';

/// Persistent header delegate for chat action buttons that sticks to the top
class ChatActionButtonsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  ChatActionButtonsDelegate({
    required this.child,
    this.height = 60.0,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant ChatActionButtonsDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

/// Reusable chat action buttons row component with FAB menu
class ChatActionButtons extends StatelessWidget {
  final VoidCallback onMorePressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onNewPressed;
  final VoidCallback? onReturnToReadingPressed; // Optional return button

  const ChatActionButtons({
    super.key,
    required this.onMorePressed,
    required this.onHistoryPressed,
    required this.onNewPressed,
    this.onReturnToReadingPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const GlassmorphicFABMenu(),
          const Spacer(),

          // Return to Reading button (only visible when navigated from verse)
          if (onReturnToReadingPressed != null) ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: AppRadius.mediumRadius,
                border: Border.all(
                  color: AppTheme.goldColor,
                  width: 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onReturnToReadingPressed,
                  borderRadius: AppRadius.mediumRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: ResponsiveUtils.iconSize(context, 18),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: ResponsiveUtils.iconSize(context, 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: AppRadius.mediumRadius,
              border: Border.all(
                color: AppTheme.goldColor,
                width: 1.0,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white, size: ResponsiveUtils.iconSize(context, 20)),
              onPressed: onMorePressed,
              tooltip: l10n.chatOptionsTooltip,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: AppRadius.mediumRadius,
              border: Border.all(
                color: AppTheme.goldColor,
                width: 1.0,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.history, color: Colors.white, size: ResponsiveUtils.iconSize(context, 20)),
              onPressed: onHistoryPressed,
              tooltip: l10n.conversationHistoryTooltip,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.3),
                  AppTheme.goldColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: AppRadius.mediumRadius,
              border: Border.all(
                color: AppTheme.goldColor,
                width: 1.0,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: AppColors.primaryText, size: ResponsiveUtils.iconSize(context, 20)),
              onPressed: onNewPressed,
              tooltip: l10n.newConversationTooltip,
            ),
          ),
        ],
      ),
    );
  }
}
