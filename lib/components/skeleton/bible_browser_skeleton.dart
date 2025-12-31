import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extensions.dart';
import 'skeleton_theme.dart';

/// Skeleton loading state for the Bible Browser Screen
class BibleBrowserSkeleton extends StatelessWidget {
  const BibleBrowserSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonTheme.wrap(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildBookItemSkeleton();
        },
      ),
    );
  }

  Widget _buildBookItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Book icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Bone.circle(size: 24),
          ),
          const SizedBox(width: 16),
          // Book name and chapter count
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 2, fontSize: 16),
                SizedBox(height: 4),
                Bone.text(words: 2, fontSize: 12),
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
