import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../components/frosted_glass_card.dart';
import '../core/models/prayer_category.dart';
import '../core/providers/category_providers.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

class CategoryStatisticsWidget extends ConsumerWidget {
  const CategoryStatisticsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(allCategoryStatisticsProvider);

    return statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by total prayers descending
        stats.sort((a, b) => b.totalPrayers.compareTo(a.totalPrayers));

        return FrostedGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: ResponsiveUtils.iconSize(context, 20),
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Prayer Statistics by Category',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...stats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                return _buildStatItem(context, stat, index);
              }),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
            strokeWidth: 3,
          ),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error loading statistics',
          style: TextStyle(
            color: Colors.red.withValues(alpha: 0.8),
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, CategoryStatistics stat, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stat.categoryColor.withValues(alpha: 0.15),
            stat.categoryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(
          color: stat.categoryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: stat.categoryColor.withValues(alpha: 0.2),
                  borderRadius: AppRadius.smallRadius,
                  border: Border.all(
                    color: stat.categoryColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  stat.categoryIcon,
                  color: stat.categoryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.categoryName,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 15, minSize: 13, maxSize: 17),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      '${stat.totalPrayers} ${stat.totalPrayers == 1 ? 'prayer' : 'prayers'}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (stat.answeredPrayers > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: AppRadius.mediumRadius,
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: ResponsiveUtils.iconSize(context, 14),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stat.answerRate.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 13),
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (stat.totalPrayers > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniStat(context, 'Active', stat.activePrayers.toString(), Colors.blue),
                const SizedBox(width: 8),
                _buildMiniStat(context, 'Answered', stat.answeredPrayers.toString(), Colors.green),
                if (stat.archivedPrayers > 0) ...[
                  const SizedBox(width: 8),
                  _buildMiniStat(context, 'Archived', stat.archivedPrayers.toString(), Colors.grey),
                ],
              ],
            ),
          ],
        ],
      ),
    ).animate(delay: (100 * index).ms).fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.smallRadius,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 10, minSize: 8, maxSize: 12),
                color: AppColors.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
