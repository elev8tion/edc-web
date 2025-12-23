import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../components/frosted_glass_card.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';

/// Widget displaying reading plan progress statistics
class ReadingProgressStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final DateTime? estimatedCompletionDate;

  const ReadingProgressStatsWidget({
    super.key,
    required this.stats,
    this.estimatedCompletionDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentStreak = stats['current_streak'] as int;
    final longestStreak = stats['longest_streak'] as int;
    final totalDaysActive = stats['total_days_active'] as int;
    final completedReadings = stats['completed_readings'] as int;
    final totalReadings = stats['total_readings'] as int;

    return Column(
      children: [
        // Main stats grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                title: l10n.currentStreak,
                value: '$currentStreak',
                subtitle: l10n.streakDays(currentStreak),
              ).animate().fadeIn(duration: AppAnimations.slow, delay: 100.ms),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.emoji_events,
                iconColor: Colors.amber,
                title: l10n.bestStreak,
                value: '$longestStreak',
                subtitle: l10n.streakDays(longestStreak),
              ).animate().fadeIn(duration: AppAnimations.slow, delay: 200.ms),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.event_available,
                iconColor: Colors.green,
                title: l10n.activeDays,
                value: '$totalDaysActive',
                subtitle: l10n.streakDays(totalDaysActive),
              ).animate().fadeIn(duration: AppAnimations.slow, delay: 300.ms),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.check_circle,
                iconColor: Colors.blue,
                title: l10n.completedReadings,
                value: '$completedReadings',
                subtitle: l10n.ofTotal(totalReadings),
              ).animate().fadeIn(duration: AppAnimations.slow, delay: 400.ms),
            ),
          ],
        ),
        if (estimatedCompletionDate != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildEstimatedCompletionCard(context, estimatedCompletionDate!)
              .animate()
              .fadeIn(duration: AppAnimations.slow, delay: 500.ms),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: AppRadius.smallRadius,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: ResponsiveUtils.iconSize(context, 20),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 28, minSize: 24, maxSize: 32),
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                  color: AppColors.tertiaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedCompletionCard(BuildContext context, DateTime estimatedDate) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final daysUntil = estimatedDate.difference(now).inDays;

    return FrostedGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: AppRadius.mediumRadius,
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: AppTheme.primaryColor,
                  size: ResponsiveUtils.iconSize(context, 24),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.estimatedCompletion,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(estimatedDate, context),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      daysUntil > 0
                          ? l10n.inDays(daysUntil, l10n.streakDays(daysUntil))
                          : daysUntil == 0
                              ? l10n.todayExclamation
                              : l10n.daysOverdue(-daysUntil, l10n.streakDays(-daysUntil)),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                        color: daysUntil < 0 ? Colors.orange : AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: AppRadius.smallRadius,
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: ResponsiveUtils.iconSize(context, 16),
                  color: Colors.blue,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.estimatedCompletionExplanation,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 13),
                      color: Colors.blue.shade200,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final months = [
      l10n.monthJanuary, l10n.monthFebruary, l10n.monthMarch, l10n.monthApril,
      l10n.monthMay, l10n.monthJune, l10n.monthJuly, l10n.monthAugust,
      l10n.monthSeptember, l10n.monthOctober, l10n.monthNovember, l10n.monthDecember
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
