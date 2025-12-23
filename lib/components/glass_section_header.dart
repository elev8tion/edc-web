import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_icon_avatar.dart';

/// Glass-styled section header with optional icon and action button
///
/// Provides a consistent header style across all screens
///
/// Usage:
/// ```dart
/// GlassSectionHeader(
///   title: 'My Section',
/// )
///
/// GlassSectionHeader(
///   title: 'With Icon',
///   icon: Icons.book,
/// )
///
/// GlassSectionHeader(
///   title: 'With Action',
///   icon: Icons.list,
///   actionIcon: Icons.add,
///   onActionTap: () => print('Add tapped'),
/// )
/// ```
class GlassSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final IconData? actionIcon;
  final String? actionText;
  final VoidCallback? onActionTap;
  final VoidCallback? onTitleTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionIcon,
    this.actionText,
    this.onActionTap,
    this.onTitleTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? AppSpacing.verticalLg,
      margin: margin,
      child: Row(
        children: [
          // Leading icon
          if (icon != null) ...[
            GlassIconAvatar.small(
              icon: icon!,
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          // Title and subtitle
          Expanded(
            child: GestureDetector(
              onTap: onTitleTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.subheadingStyle,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Trailing action
          if (actionIcon != null || actionText != null) ...[
            const SizedBox(width: AppSpacing.md),
            if (actionIcon != null)
              GlassIconAvatar.small(
                icon: actionIcon!,
                onTap: onActionTap,
              ),
            if (actionText != null)
              GestureDetector(
                onTap: onActionTap,
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Glass-styled divider for section separation
class GlassDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const GlassDivider({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? AppSpacing.verticalMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color ?? AppColors.primaryBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
