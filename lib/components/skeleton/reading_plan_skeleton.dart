import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_theme.dart';
import '../dark_glass_container.dart';
import 'skeleton_theme.dart';

/// Skeleton loading state for the Reading Plan Screen tabs
class ReadingPlanTabSkeleton extends StatelessWidget {
  const ReadingPlanTabSkeleton({super.key});

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
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildReadingItemSkeleton(),
          );
        },
      ),
    );
  }

  Widget _buildReadingItemSkeleton() {
    return DarkGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Checkbox placeholder
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Reading content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Bone.text(words: 3, fontSize: 16),
                SizedBox(height: 6),
                Bone.text(words: 4, fontSize: 13),
              ],
            ),
          ),
          // Chevron
          Icon(
            Icons.chevron_right,
            color: Colors.white.withValues(alpha: 0.3),
            size: 24,
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the Reading Plan list view
class ReadingPlanListSkeleton extends StatelessWidget {
  const ReadingPlanListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonTheme.wrap(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPlanCardSkeleton(),
          );
        },
      ),
    );
  }

  Widget _buildPlanCardSkeleton() {
    return DarkGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Bone.text(words: 3, fontSize: 18)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Bone.text(words: 1, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          const Bone.multiText(lines: 2, fontSize: 14),
          const SizedBox(height: 16),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          // Progress text
          const Bone.text(words: 3, fontSize: 12),
        ],
      ),
    );
  }
}
