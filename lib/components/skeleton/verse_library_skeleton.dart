import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_extensions.dart';
import '../dark_glass_container.dart';
import 'skeleton_theme.dart';

/// Skeleton loading state for the Verse Library Screen tabs
class VerseLibraryTabSkeleton extends StatelessWidget {
  const VerseLibraryTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonTheme.wrap(
      enabled: true,
      child: ListView.builder(
        padding:
            const EdgeInsets.only(left: 50, right: 50, top: 20, bottom: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildVerseCardSkeleton(),
          );
        },
      ),
    );
  }

  Widget _buildVerseCardSkeleton() {
    return DarkGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reference row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Bone.text(words: 2, fontSize: 14),
              Bone.circle(size: 24),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Verse text
          const Bone.multiText(lines: 3, fontSize: 16),
          SizedBox(height: AppSpacing.md),
          // Footer row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Bone.text(words: 2, fontSize: 12),
              Row(
                children: [
                  Bone.circle(size: 20),
                  SizedBox(width: 8),
                  Bone.circle(size: 20),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
