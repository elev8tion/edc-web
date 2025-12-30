import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_theme.dart';
import '../dark_glass_container.dart';
import 'skeleton_theme.dart';

/// Skeleton loading state for the Prayer Journal Screen tabs
class PrayerJournalTabSkeleton extends StatelessWidget {
  const PrayerJournalTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonTheme.wrap(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPrayerCardSkeleton(),
          );
        },
      ),
    );
  }

  Widget _buildPrayerCardSkeleton() {
    return DarkGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with category and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Bone.text(words: 1, fontSize: 12),
              ),
              const Bone.text(words: 2, fontSize: 12),
            ],
          ),
          const SizedBox(height: 12),
          // Prayer title
          const Bone.text(words: 4, fontSize: 16),
          const SizedBox(height: 8),
          // Prayer content
          const Bone.multiText(lines: 2, fontSize: 14),
          const SizedBox(height: 12),
          // Footer row with actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Bone.circle(size: 24),
              const SizedBox(width: 12),
              Bone.circle(size: 24),
              const SizedBox(width: 12),
              Bone.circle(size: 24),
            ],
          ),
        ],
      ),
    );
  }
}
