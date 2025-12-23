import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../components/dark_glass_container.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.xs)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

// Specialized skeleton variants
class SkeletonChip extends StatelessWidget {
  const SkeletonChip({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: 80,
      height: 36,
      borderRadius: BorderRadius.circular(AppRadius.md + 2), // 18
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DarkGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge + menu button row
          Row(
            children: [
              SkeletonLoader(
                height: 24,
                width: 80,
                borderRadius: BorderRadius.circular(AppRadius.md + 2),
              ),
              const Spacer(),
              SkeletonLoader(
                height: 18,
                width: 18,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Title
          const SkeletonLoader(height: 18, width: 200),
          const SizedBox(height: AppSpacing.sm),
          // Description lines
          const SkeletonLoader(height: 14),
          const SizedBox(height: 4),
          const SkeletonLoader(height: 14),
          const SizedBox(height: 4),
          const SkeletonLoader(height: 14, width: 150),
          const SizedBox(height: AppSpacing.md),
          // Date row
          Row(
            children: [
              SkeletonLoader(
                height: 14,
                width: 14,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              const SizedBox(width: 4),
              const SkeletonLoader(height: 12, width: 80),
            ],
          ),
        ],
      ),
    );
  }
}
