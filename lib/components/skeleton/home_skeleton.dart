import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_scalify/flutter_scalify.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_gradients.dart';
import '../dark_main_feature_card.dart';
import '../clear_glass_card.dart';
import '../dark_glass_container.dart';
import 'skeleton_theme.dart';

/// Skeleton loading state for the Home Screen
/// Matches the actual layout structure for seamless transition
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppSkeletonTheme.wrap(
        enabled: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl,
            bottom: AppSpacing.xxxl,
          ),
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56 + AppSpacing.lg + 32),
              _buildStatsRowSkeleton(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildMainFeaturesSkeleton(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildQuickActionsSkeleton(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildDailyVerseSkeleton(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildStartChatButtonSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRowSkeleton(BuildContext context) {
    final baseHeight = 110.s;
    return SizedBox(
      height: baseHeight.clamp(88.0, 165.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.horizontalXl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStatCardSkeleton(Colors.orange),
          const SizedBox(width: AppSpacing.lg),
          _buildStatCardSkeleton(Colors.red),
          const SizedBox(width: AppSpacing.lg),
          _buildStatCardSkeleton(AppTheme.goldColor),
          const SizedBox(width: AppSpacing.lg),
          _buildStatCardSkeleton(Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCardSkeleton(Color color) {
    return Container(
      width: 120.s,
      padding: EdgeInsets.symmetric(horizontal: 6.s, vertical: 12.s),
      decoration: BoxDecoration(
        gradient: AppGradients.glassMedium,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.s),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: AppRadius.mediumRadius,
            ),
            child: Bone.circle(size: 20),
          ),
          SizedBox(height: 4.s),
          const Bone.text(words: 1, fontSize: 20),
          SizedBox(height: 2.s),
          const Bone.text(words: 1, fontSize: 9),
        ],
      ),
    );
  }

  Widget _buildMainFeaturesSkeleton(BuildContext context) {
    final cardHeight = 160.s;

    return Padding(
      padding: AppSpacing.horizontalXl,
      child: Column(
        children: [
          SizedBox(
            height: cardHeight,
            child: Row(
              children: [
                Expanded(child: _buildFeatureCardSkeleton()),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildFeatureCardSkeleton()),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: cardHeight,
            child: Row(
              children: [
                Expanded(child: _buildFeatureCardSkeleton()),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildFeatureCardSkeleton()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCardSkeleton() {
    return DarkMainFeatureCard(
      padding: EdgeInsets.all(14.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClearGlassCard(
            padding: EdgeInsets.all(8.s),
            child: Bone.circle(size: 20.s),
          ),
          SizedBox(height: AppSpacing.sm),
          const Bone.text(words: 2, fontSize: 16),
          const SizedBox(height: 6),
          const Bone.multiText(lines: 2, fontSize: 12),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSkeleton(BuildContext context) {
    final baseHeight = 110.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.horizontalXl,
          child: const Bone.text(words: 2, fontSize: 20),
        ),
        SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: baseHeight.clamp(88.0, 165.0),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.horizontalXl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildQuickActionCardSkeleton(AppTheme.goldColor),
              const SizedBox(width: AppSpacing.lg),
              _buildQuickActionCardSkeleton(Colors.blue),
              const SizedBox(width: AppSpacing.lg),
              _buildQuickActionCardSkeleton(Colors.green),
              const SizedBox(width: AppSpacing.lg),
              _buildQuickActionCardSkeleton(Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCardSkeleton(Color color) {
    return Container(
      width: 100.s,
      padding: EdgeInsets.symmetric(horizontal: 6.s, vertical: 8.s),
      decoration: BoxDecoration(
        gradient: AppGradients.glassMedium,
        borderRadius: AppRadius.md.br,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.s),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: AppRadius.mediumRadius,
            ),
            child: Bone.circle(size: 24.s),
          ),
          SizedBox(height: AppSpacing.sm),
          const Expanded(
            child: Bone.text(words: 2, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyVerseSkeleton(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalXl,
      child: Container(
        padding: AppSpacing.screenPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.s),
                  decoration: BoxDecoration(
                    gradient: AppGradients.goldAccent,
                    borderRadius: AppRadius.mediumRadius,
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Bone.circle(size: 20.s),
                ),
                SizedBox(width: AppSpacing.lg),
                const Expanded(
                  child: Bone.text(words: 3, fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            DarkGlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Bone.text(words: 2, fontSize: 14),
                  SizedBox(height: AppSpacing.md),
                  const Bone.multiText(lines: 3, fontSize: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartChatButtonSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
      ),
    );
  }
}
