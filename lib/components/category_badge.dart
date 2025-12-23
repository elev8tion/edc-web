import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Category badge widget for displaying labeled categories with consistent styling
class CategoryBadge extends StatelessWidget {
  final String text;
  final Color? badgeColor;
  final Color? textColor;
  final IconData? icon;
  final double? size;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final bool isSelected;

  const CategoryBadge({
    super.key,
    required this.text,
    this.badgeColor,
    this.textColor,
    this.icon,
    this.size,
    this.fontSize = 14,
    this.padding,
    this.isSelected = false,
  });

  /// Get category color based on category name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return AppTheme.primaryColor; // Gold
      case 'faith':
        return const Color(0xFF3b82f6); // Blue
      case 'hope':
        return const Color(0xFF10b981); // Green
      case 'love':
        return const Color(0xFFef4444); // Red
      case 'peace':
        return const Color(0xFF8b5cf6); // Purple
      case 'strength':
        return const Color(0xFFf59e0b); // Amber
      case 'comfort':
        return const Color(0xFFec4899); // Pink
      case 'guidance':
        return const Color(0xFF06b6d4); // Cyan
      case 'wisdom':
        return const Color(0xFF6366f1); // Indigo
      case 'forgiveness':
        return const Color(0xFFa855f7); // Purple-500
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = badgeColor ?? getCategoryColor(text);

    // For pill-style badges (no size specified)
    if (size == null) {
      return Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    color.withValues(alpha: 0.5),
                    color.withValues(alpha: 0.3),
                  ]
                : [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.15),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.largeCardRadius,
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.6),
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // For square badges (size specified)
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.xs - 2),
        border: Border.all(color: color, width: 1),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
