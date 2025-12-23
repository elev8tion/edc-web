import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/verse_context.dart';
import '../utils/responsive_utils.dart';

/// System message component that displays verse context at the top of chat
/// Shows when user navigates from Bible reading to discuss a specific verse
class VerseContextMessage extends StatelessWidget {
  final VerseContext verseContext;

  const VerseContextMessage({
    super.key,
    required this.verseContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.15),
            AppTheme.goldColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with book icon
          Row(
            children: [
              Icon(
                Icons.menu_book,
                size: ResponsiveUtils.iconSize(context, 20),
                color: AppTheme.goldColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Discussing ${verseContext.fullReference}',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 13, maxSize: 15),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Verse text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              verseContext.verseText,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 15, minSize: 14, maxSize: 16),
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.95),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
