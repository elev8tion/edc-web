import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_theme.dart';
import '../dark_glass_container.dart';
import '../standard_screen_header.dart';
import '../glass_card.dart';
import 'skeleton_theme.dart';

/// Skeleton loading state for the Devotional Screen
/// Matches the actual layout structure for seamless transition
class DevotionalScreenSkeleton extends StatelessWidget {
  const DevotionalScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: SafeArea is provided by parent screen - don't duplicate
    return AppSkeletonTheme.wrap(
      enabled: true,
      child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: AppSpacing.xxl * 2,
          ),
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSkeleton(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildTitleSkeleton(),
              const SizedBox(height: AppSpacing.xl),
              _buildScriptureSectionSkeleton(),
              _buildSectionDivider(),
              _buildKeyVerseSkeleton(),
              _buildSectionDivider(),
              _buildReflectionSkeleton(),
              _buildSectionDivider(),
              _buildLifeApplicationSkeleton(),
              _buildSectionDivider(),
              _buildPrayerSkeleton(),
              _buildSectionDivider(),
              _buildActionStepSkeleton(),
              const SizedBox(height: AppSpacing.xl),
              _buildCompletionButtonSkeleton(),
              const SizedBox(height: AppSpacing.xl),
              _buildNavigationButtonsSkeleton(),
            ],
          ),
        ),
      );
  }

  Widget _buildHeaderSkeleton(BuildContext context) {
    return StandardScreenHeader(
      title: 'Daily Devotional',
      subtitle: '',
      showFAB: false,
      trailingWidget: GlassContainer(
        borderRadius: AppRadius.md,
        blurStrength: 15.0,
        gradientColors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
        padding: EdgeInsets.zero,
        enableNoise: true,
        enableLightSimulation: true,
        border: Border.all(
          color: AppTheme.goldColor,
          width: 1.0,
        ),
        child: const SizedBox(width: 44, height: 44),
      ),
      customSubtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.white.withValues(alpha: 0.5),
                size: 14,
              ),
              const SizedBox(width: 4),
              const Bone.text(words: 2, fontSize: 11),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white.withValues(alpha: 0.5),
                size: 14,
              ),
              const SizedBox(width: 4),
              const Bone.text(words: 2, fontSize: 11),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xl),
      child: Bone.text(words: 4, fontSize: 24),
    );
  }

  Widget _buildScriptureSectionSkeleton() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
                color: AppTheme.goldColor.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Bone.text(words: 2, fontSize: 14),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DarkGlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Bone.multiText(lines: 3, fontSize: 16),
                SizedBox(height: AppSpacing.md),
                Bone.text(words: 2, fontSize: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyVerseSkeleton() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: AppTheme.goldColor.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Bone.text(words: 3, fontSize: 14),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DarkGlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Bone.multiText(lines: 2, fontSize: 17),
                SizedBox(height: AppSpacing.md),
                Bone.text(words: 2, fontSize: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionSkeleton() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Bone.text(words: 1, fontSize: 18),
          SizedBox(height: AppSpacing.md),
          Bone.multiText(lines: 5, fontSize: 15),
        ],
      ),
    );
  }

  Widget _buildLifeApplicationSkeleton() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue.shade300.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Bone.text(words: 2, fontSize: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DarkGlassContainer(
            child: const Bone.multiText(lines: 3, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerSkeleton() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                color: Colors.purple.shade200.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Bone.text(words: 1, fontSize: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DarkGlassContainer(
            child: const Bone.multiText(lines: 3, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildActionStepSkeleton() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Bone.text(
                  words: 3,
                  fontSize: 14,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Bone.multiText(lines: 2, fontSize: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionButtonSkeleton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Center(
        child: Bone.text(words: 3, fontSize: 16),
      ),
    );
  }

  Widget _buildNavigationButtonsSkeleton() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Bone.text(words: 2, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Bone.text(words: 2, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDivider() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
