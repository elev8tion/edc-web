import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';

/// Calendar heatmap widget showing reading activity over time
/// Similar to GitHub's contribution graph
class CalendarHeatmapWidget extends StatelessWidget {
  final Map<DateTime, int> activityData;
  final int columns;
  final double cellSize;
  final Color Function(int count) colorForCount;

  const CalendarHeatmapWidget({
    super.key,
    required this.activityData,
    this.columns = 12,
    this.cellSize = 12.0,
    Color Function(int count)? colorForCount,
  }) : colorForCount = colorForCount ?? _defaultColorForCount;

  static Color _defaultColorForCount(int count) {
    if (count == 0) return Colors.white.withValues(alpha: 0.1);
    if (count == 1) return AppTheme.goldColor.withValues(alpha: 0.3);
    if (count == 2) return AppTheme.goldColor.withValues(alpha: 0.6);
    return AppTheme.goldColor.withValues(alpha: 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day); // normalize
    // Start on Monday of the earliest week we want to show.
    DateTime startOfThisWeek = end.subtract(Duration(days: end.weekday - DateTime.monday));
    final start = startOfThisWeek.subtract(Duration(days: (columns - 1) * 7));

    // Build exactly `columns` weeks, each with 7 days (Mon..Sun)
    final List<List<DateTime>> weeks = List.generate(columns, (i) {
      final weekStart = start.add(Duration(days: i * 7));
      return List.generate(7, (j) => weekStart.add(Duration(days: j)));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels (M, W, F)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDayLabel('M', 0, context),
                  _buildDayLabel('', 1, context),
                  _buildDayLabel('W', 2, context),
                  _buildDayLabel('', 3, context),
                  _buildDayLabel('F', 4, context),
                  _buildDayLabel('', 5, context),
                  _buildDayLabel('', 6, context),
                ],
              ),
            ),
            // Heatmap grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...weeks.map((week) => _buildWeekColumn(week, context)),
                    const SizedBox(width: 4), // breathing room
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildDayLabel(String label, int index, BuildContext context) {
    return SizedBox(
      height: cellSize + 4,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 10, minSize: 8, maxSize: 12),
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekColumn(List<DateTime> week, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Column(
        children: week.map((date) => _buildDayCell(date, context)).toList(),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, BuildContext context) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final isFuture = normalizedDate.isAfter(end);

    final count = isFuture ? 0 : (activityData[normalizedDate] ?? 0);
    final color = isFuture ? Colors.white.withValues(alpha: 0.05) : colorForCount(count);

    final isToday = normalizedDate == end;

    return Tooltip(
      message: isFuture
          ? _formatDate(date)
          : '${_formatDate(date)}: ${count > 0 ? '$count reading${count > 1 ? 's' : ''}' : 'No activity'}',
      child: Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.xs / 4),
          border: isToday && !isFuture
              ? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5)
              : null,
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          l10n.heatmapLess,
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 10, minSize: 8, maxSize: 12),
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        _buildLegendCell(0, context),
        _buildLegendCell(1, context),
        _buildLegendCell(2, context),
        _buildLegendCell(3, context),
        const SizedBox(width: 8),
        Text(
          l10n.heatmapMore,
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 10, minSize: 8, maxSize: 12),
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendCell(int count, BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: colorForCount(count),
        borderRadius: BorderRadius.circular(AppRadius.xs / 4),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
