import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Glass-styled circular icon avatar
///
/// Replaces the inline icon container pattern that appears 15+ times
/// across the codebase.
///
/// Usage:
/// ```dart
/// GlassIconAvatar(
///   icon: Icons.person,
/// )
///
/// GlassIconAvatar.large(
///   icon: Icons.chat,
///   iconColor: AppTheme.primaryColor,
/// )
/// ```
class GlassIconAvatar extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final double borderWidth;
  final VoidCallback? onTap;

  const GlassIconAvatar({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = AppSizes.avatarMd,
    this.iconSize = AppSizes.iconSm,
    this.borderWidth = 1.5,
    this.onTap,
  });

  /// Small avatar (32px)
  factory GlassIconAvatar.small({
    Key? key,
    required IconData icon,
    Color? iconColor,
    Color? backgroundColor,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return GlassIconAvatar(
      key: key,
      icon: icon,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      size: AppSizes.avatarSm,
      iconSize: AppSizes.iconXs,
      onTap: onTap,
    );
  }

  /// Medium avatar (40px) - Default
  factory GlassIconAvatar.medium({
    Key? key,
    required IconData icon,
    Color? iconColor,
    Color? backgroundColor,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return GlassIconAvatar(
      key: key,
      icon: icon,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      size: AppSizes.avatarMd,
      iconSize: AppSizes.iconSm,
      onTap: onTap,
    );
  }

  /// Large avatar (56px)
  factory GlassIconAvatar.large({
    Key? key,
    required IconData icon,
    Color? iconColor,
    Color? backgroundColor,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return GlassIconAvatar(
      key: key,
      icon: icon,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      size: AppSizes.avatarLg,
      iconSize: AppSizes.iconLg,
      borderWidth: 2.0,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primaryText;
    final effectiveBackgroundColor =
        backgroundColor ?? AppColors.accentVerySubtle;
    final effectiveBorderColor = borderColor ?? AppColors.accentBorder;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        color: effectiveBackgroundColor,
      ),
      child: Icon(
        icon,
        color: effectiveIconColor,
        size: iconSize,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}

/// Glass-styled rectangular icon container
///
/// For use cases where a square/rectangular shape is needed instead of circular
class GlassIconContainer extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final double borderRadius;
  final double borderWidth;
  final VoidCallback? onTap;

  const GlassIconContainer({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = AppSizes.avatarMd,
    this.iconSize = AppSizes.iconSm,
    this.borderRadius = AppRadius.sm,
    this.borderWidth = 1.5,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primaryText;
    final effectiveBackgroundColor =
        backgroundColor ?? AppColors.accentVerySubtle;
    final effectiveBorderColor = borderColor ?? AppColors.accentBorder;

    Widget container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        color: effectiveBackgroundColor,
      ),
      child: Icon(
        icon,
        color: effectiveIconColor,
        size: iconSize,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}
