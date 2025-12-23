import 'package:flutter/material.dart';
import 'glass_card.dart';

/// Achievement badge widget that displays an earned achievement icon
/// with an optional count badge showing how many times it was earned
class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int completionCount;
  final String title;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.completionCount,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$title${completionCount > 1 ? ' (×$completionCount)' : ''}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Badge circle (original size)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.15),
                ],
              ),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),

          // Completion count badge (CategoryBadge style, only if earned)
          if (completionCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  '$completionCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Container for displaying multiple achievement badges in a row
class AchievementBadgeRow extends StatelessWidget {
  final List<AchievementBadgeData> badges;

  const AchievementBadgeRow({
    super.key,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      borderRadius: 20,
      blurStrength: 15.0,
      gradientColors: [
        Colors.white.withValues(alpha: 0.05),
        Colors.white.withValues(alpha: 0.02),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      enableNoise: true,
      enableLightSimulation: true,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: badges.map((badge) {
          return AchievementBadge(
            icon: badge.icon,
            color: badge.color,
            completionCount: badge.completionCount,
            title: badge.title,
          );
        }).toList(),
      ),
    );
  }
}

/// Data class for achievement badge information
class AchievementBadgeData {
  final IconData icon;
  final Color color;
  final int completionCount;
  final String title;

  const AchievementBadgeData({
    required this.icon,
    required this.color,
    required this.completionCount,
    required this.title,
  });
}
