/// Subscription Settings Screen
/// Shows current subscription status, message usage, and upgrade options
///
/// Displays:
/// - Subscription status (Free/Trial/Premium)
/// - Message usage (trial: 15 total, premium: 150/month)
/// - Trial days remaining or renewal info
/// - Upgrade button (if not premium)
/// - Manage subscription link

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_button.dart';
import '../components/glass_section_header.dart';
import '../components/standard_screen_header.dart';
import '../theme/app_theme.dart';
import '../theme/app_gradients.dart';
import '../core/providers/app_providers.dart';
import '../utils/responsive_utils.dart';
import 'paywall_screen.dart';
import '../l10n/app_localizations.dart';

class SubscriptionSettingsScreen extends ConsumerWidget {
  const SubscriptionSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final isInTrial = ref.watch(isInTrialProvider);
    final hasTrialExpired = ref.watch(hasTrialExpiredProvider);
    final remainingMessages = ref.watch(remainingMessagesProvider);
    final messagesUsed = ref.watch(messagesUsedProvider);
    final trialDaysRemaining = ref.watch(trialDaysRemainingProvider);
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final premiumProduct = subscriptionService.premiumProduct;
    final isTrialBlocked = subscriptionService.isTrialBlocked;

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Header
                        _buildStatusHeader(
                          context: context,
                          l10n: l10n,
                          isPremium: isPremium,
                          isInTrial: isInTrial,
                          hasTrialExpired: hasTrialExpired,
                          trialDaysRemaining: trialDaysRemaining,
                          subscriptionService: subscriptionService,
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Stats Cards
                        _buildStatsCards(
                          context: context,
                          l10n: l10n,
                          isPremium: isPremium,
                          remainingMessages: remainingMessages,
                          messagesUsed: messagesUsed,
                          trialDaysRemaining: trialDaysRemaining,
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // What You Get Section
                        GlassSectionHeader(
                          title: isPremium ? l10n.subscriptionYourPremiumBenefits : l10n.subscriptionUpgradeToPremium,
                          icon: Icons.workspace_premium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildBenefitsList(l10n, isPremium, premiumProduct),
                        const SizedBox(height: AppSpacing.xxl),

                        // Action Buttons
                        if (!isPremium) ...[
                          GlassButton(
                            text: (hasTrialExpired || isTrialBlocked)
                                ? l10n.subscriptionSubscribeNowButton(premiumProduct?.price ?? "\$35.99")
                                : l10n.subscriptionStartFreeTrialButton,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PaywallScreen(
                                    showTrialInfo: !(hasTrialExpired || isTrialBlocked),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ] else ...[
                          GlassButton(
                            text: l10n.subscriptionManageButton,
                            onPressed: () => _openManageSubscription(context, l10n),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Info Card
                        FrostedGlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          intensity: GlassIntensity.light,
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.secondaryText,
                                size: 20,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AutoSizeText(
                                isPremium
                                    ? l10n.subscriptionRenewalInfoPremium(premiumProduct?.price ?? "\$35.99")
                                    : l10n.subscriptionRenewalInfoTrial(premiumProduct?.price ?? "\$35.99"),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 5,
                                minFontSize: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
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

  /// Build custom app bar
  Widget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StandardScreenHeader(
      title: l10n.subscriptionTitle,
      subtitle: l10n.subscriptionSubtitle,
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: -0.3);
  }

  /// Build status header
  Widget _buildStatusHeader({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isPremium,
    required bool isInTrial,
    required bool hasTrialExpired,
    required int trialDaysRemaining,
    required dynamic subscriptionService,
  }) {
    String status;
    String subtitle;
    if (isPremium) {
      status = l10n.subscriptionStatusPremiumActive;
      // Show plan type (Yearly or Monthly) in subtitle
      final planType = subscriptionService.hasYearlySubscription
          ? l10n.subscriptionPlanYearly
          : (subscriptionService.hasMonthlySubscription
              ? l10n.subscriptionPlanMonthly
              : '');
      subtitle = planType.isNotEmpty
          ? '${l10n.subscriptionStatusPremiumActiveDesc} • $planType'
          : l10n.subscriptionStatusPremiumActiveDesc;
    } else if (isInTrial) {
      status = l10n.subscriptionStatusFreeTrial;
      subtitle = l10n.subscriptionStatusTrialDaysRemaining(trialDaysRemaining);
    } else if (hasTrialExpired) {
      status = l10n.subscriptionStatusTrialExpired;
      subtitle = l10n.subscriptionStatusTrialExpiredDesc;
    } else {
      status = l10n.subscriptionStatusFreeVersion;
      subtitle = l10n.subscriptionStatusFreeVersionDesc;
    }

    return Column(
      children: [
        AutoSizeText(
          status,
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 24, minSize: 20, maxSize: 28),
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          minFontSize: 18,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        AutoSizeText(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.secondaryText,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          minFontSize: 14,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms);
  }

  /// Build stats cards
  Widget _buildStatsCards({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isPremium,
    required int remainingMessages,
    required int messagesUsed,
    required int trialDaysRemaining,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context: context,
            value: '$remainingMessages',
            label: l10n.subscriptionMessagesLeft,
            icon: Icons.chat_bubble_outline,
            color: Colors.purple,
            delay: 400,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            context: context,
            value: '$messagesUsed',
            label: isPremium ? l10n.subscriptionUsedThisMonth : l10n.subscriptionUsedToday,
            icon: Icons.check_circle_outline,
            color: Colors.green,
            delay: 500,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            context: context,
            value: isPremium ? '150' : '$trialDaysRemaining',
            label: isPremium ? l10n.subscriptionMonthlyLimit : l10n.subscriptionTrialDaysLeft,
            icon: isPremium ? Icons.all_inclusive : Icons.schedule,
            color: isPremium ? AppTheme.goldColor : Colors.blue,
            delay: 600,
          ),
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard({
    required BuildContext context,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: AppGradients.glassMedium,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: ResponsiveUtils.iconSize(context, 24), color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          AutoSizeText(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 16, maxSize: 24),
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              shadows: AppTheme.textShadowStrong,
            ),
            maxLines: 1,
            minFontSize: 14,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 13),
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
              shadows: AppTheme.textShadowSubtle,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 8,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale(delay: Duration(milliseconds: delay));
  }

  /// Build benefits list
  Widget _buildBenefitsList(AppLocalizations l10n, bool isPremium, dynamic premiumProduct) {
    final benefits = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': l10n.subscriptionBenefitIntelligentChat,
        'subtitle': l10n.subscriptionBenefitIntelligentChatDesc,
      },
      {
        'icon': Icons.all_inclusive,
        'title': l10n.subscriptionBenefit150Messages,
        'subtitle': l10n.subscriptionBenefit150MessagesDesc(premiumProduct?.price ?? "\$35.99"),
      },
      {
        'icon': Icons.psychology,
        'title': l10n.subscriptionBenefitContextAware,
        'subtitle': l10n.subscriptionBenefitContextAwareDesc,
      },
      {
        'icon': Icons.shield_outlined,
        'title': l10n.subscriptionBenefitCrisisDetection,
        'subtitle': l10n.subscriptionBenefitCrisisDetectionDesc,
      },
      {
        'icon': Icons.book_outlined,
        'title': l10n.subscriptionBenefitFullBibleAccess,
        'subtitle': l10n.subscriptionBenefitFullBibleAccessDesc,
      },
    ];

    return Column(
      children: benefits
          .asMap()
          .entries
          .map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FrostedGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  intensity: GlassIntensity.medium,
                  borderColor: AppTheme.goldColor.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          entry.value['icon'] as IconData,
                          size: 24,
                          color: AppTheme.goldColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              entry.value['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                              maxLines: 2,
                              minFontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            AutoSizeText(
                              entry.value['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryText,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              minFontSize: 12,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isPremium)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 700 + (entry.key * 100))).slideX(begin: 0.3, delay: Duration(milliseconds: 700 + (entry.key * 100))),
              ))
          .toList(),
    );
  }

  /// Open manage subscription (App Store or Play Store based on platform)
  Future<void> _openManageSubscription(BuildContext context, AppLocalizations l10n) async {
    // Use platform-specific subscription management URL
    final Uri url = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.subscriptionUnableToOpenSettings),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
