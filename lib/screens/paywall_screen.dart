/// Paywall Screen
/// Shown when trial expires or when user needs to upgrade to premium
///
/// Displays:
/// - Trial status or expired message
/// - Premium features list
/// - Pricing ($35.99/year, 150 messages/month)
/// - Purchase and restore buttons

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_button.dart';
import '../components/glass_section_header.dart';
import '../components/category_badge.dart';
import '../components/glassmorphic_fab_menu.dart';
import '../components/standard_screen_header.dart';
import '../components/glass_card.dart';
import '../theme/app_theme.dart';
import '../core/providers/app_providers.dart';
import '../core/services/subscription_service.dart';
import '../l10n/app_localizations.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  /// Optional: show trial info (true) or expired message (false)
  final bool showTrialInfo;

  /// Optional: show message usage stats (messages left, used, days)
  final bool showMessageStats;

  const PaywallScreen({
    Key? key,
    this.showTrialInfo = true,
    this.showMessageStats = false,
  }) : super(key: key);

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isProcessing = false;
  bool _selectedPlanIsYearly = true; // Default to yearly (recommended)

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final isInTrial = ref.watch(isInTrialProvider);
    final trialDaysRemaining = ref.watch(trialDaysRemainingProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final remainingMessages = ref.watch(remainingMessagesProvider);
    final messagesUsed = ref.watch(messagesUsedProvider);
    final hasTrialExpired = ref.watch(hasTrialExpiredProvider);
    final isTrialBlocked = subscriptionService.isTrialBlocked;

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: AppSpacing.xl,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with StandardScreenHeader
                  _buildAppBar(
                      isInTrial, trialDaysRemaining, subscriptionService),
                  const SizedBox(height: AppSpacing.xl),

                  // Subtitle - Trial or Expired (centered below header)
                  if (widget.showTrialInfo && isInTrial)
                    Center(
                      child: CategoryBadge(
                        text: l10n.paywallTrialDaysLeft(trialDaysRemaining),
                        icon: Icons.schedule,
                        badgeColor: Colors.blue,
                        isSelected: true,
                      ),
                    )
                  else if (subscriptionService.isTrialBlocked)
                    // Trial was already used on this device (survives app uninstall)
                    Center(
                      child: Text(
                        l10n.paywallTrialBlockedMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        l10n.paywallTrialEndedMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Message Stats (if enabled)
                  if (widget.showMessageStats) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.chat_bubble_outline,
                            value: '$remainingMessages',
                            label: l10n.paywallMessagesLeft,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle_outline,
                            value: '$messagesUsed',
                            label: isPremium
                                ? l10n.paywallUsedThisMonth
                                : l10n.paywallUsedInTrial,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildStatCard(
                            icon: isPremium
                                ? Icons.all_inclusive
                                : Icons.schedule,
                            value: isPremium ? '150' : '$trialDaysRemaining',
                            label: isPremium
                                ? l10n.paywallMonthlyLimit
                                : l10n.paywallTrialDaysLeft2,
                            color: isPremium ? AppTheme.goldColor : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // Plan Selector - ALWAYS show per Apple Guideline 3.1.2
                  // Apple requires subscription length and price to be visible WITHOUT user action
                  // (cannot be hidden behind a button click or conditional on trial status)
                  _buildPlanSelector(context, l10n, subscriptionService),
                  const SizedBox(height: AppSpacing.xl),

                  // 150 Scripture Chats badge (centered under plan selectors)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.paywall150MessagesPerMonth,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Pricing disclaimer below badge
                        Text(
                          l10n.paywallPricingDisclaimer,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                AppColors.secondaryText.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Purchase Button - generic text that works for both monthly and yearly
                  GlassButton(
                    text: _isProcessing
                        ? l10n.paywallProcessing
                        : (hasTrialExpired ||
                                isTrialBlocked ||
                                remainingMessages == 0 ||
                                widget.showMessageStats)
                            ? l10n
                                .subscribeNow // Generic "Subscribe Now" for all post-trial cases
                            : l10n
                                .paywallStartPremiumButton, // "Start Free Trial" for new users
                    onPressed: _isProcessing ? null : _handlePurchase,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Restore Button
                  GestureDetector(
                    onTap: _isProcessing ? null : _handleRestore,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Center(
                        child: Text(
                          l10n.paywallRestorePurchase,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.goldColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // CRITICAL: Terms of Use & Privacy Policy (required by Apple Guideline 3.1.2)
                  // Apple requires functional links to EULA and Privacy Policy in prominent location
                  FrostedGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    intensity: GlassIntensity.light,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _launchURL(
                              'https://everydaychristian.app/privacy'),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.goldColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '•',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _launchURL('https://everydaychristian.app/terms'),
                          child: const Text(
                            'Terms of Use (EULA)',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.goldColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Features Section (moved below Subscribe button)
                  GlassSectionHeader(
                    title: l10n.paywallWhatsIncluded,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Feature List
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: l10n.paywallFeatureIntelligentChat,
                    subtitle: l10n.paywallFeatureIntelligentChatDesc,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.all_inclusive,
                    title: l10n.paywallFeature150Messages,
                    subtitle: l10n.paywallFeature150MessagesDesc,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.psychology,
                    title: l10n.paywallFeatureContextAware,
                    subtitle: l10n.paywallFeatureContextAwareDesc,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: l10n.paywallFeatureCrisisDetection,
                    subtitle: l10n.paywallFeatureCrisisDetectionDesc,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.book_outlined,
                    title: l10n.paywallFeatureFullBibleAccess,
                    subtitle: l10n.paywallFeatureFullBibleAccessDesc,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Auto-renewal terms and subscription info (required by App Store)
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
                        Text(
                          Platform.isIOS
                              ? l10n.paywallSubscriptionTerms // iOS: App Store
                              : l10n
                                  .paywallSubscriptionTermsAndroid, // Android: Google Play
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
          // Pinned FAB
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.xl,
            left: AppSpacing.xl,
            child: const GlassmorphicFABMenu()
                .animate()
                .fadeIn(duration: AppAnimations.slow)
                .slideY(begin: -0.3),
          ),
        ],
      ),
    );
  }

  /// Build header using StandardScreenHeader
  Widget _buildAppBar(
      bool isInTrial, int trialDaysRemaining, dynamic subscriptionService) {
    final l10n = AppLocalizations.of(context);
    return StandardScreenHeader(
      title: l10n.paywallTitle,
      subtitle: l10n.paywallSubtitle,
      showFAB: false, // FAB is positioned separately
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: -0.3);
  }

  /// Build a stat card (for message stats display)
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      intensity: GlassIntensity.medium,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              shadows: AppTheme.textShadowStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
              shadows: AppTheme.textShadowSubtle,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// Build a feature list item
  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return FrostedGlassCard(
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
              icon,
              size: 24,
              color: AppTheme.goldColor,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle purchase button
  Future<void> _handlePurchase() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final subscriptionService = ref.read(subscriptionServiceProvider);
    final l10n = AppLocalizations.of(context);

    // CRITICAL FIX: Validate products are loaded before attempting purchase
    final selectedProduct = _selectedPlanIsYearly
        ? subscriptionService.premiumProductYearly
        : subscriptionService.premiumProductMonthly;

    if (selectedProduct == null) {
      setState(() => _isProcessing = false);

      // Show detailed error with troubleshooting steps
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B), // slate-800
                  Color(0xFF0F172A), // slate-900
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade300,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Subscription Not Available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please try:\n1. Check your internet connection\n2. Sign in to App Store with your Apple ID\n3. Restart the app',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      debugPrint(
          '📊 [PaywallScreen] Purchase failed - product not loaded. Product IDs configured: yearly=${SubscriptionService.premiumYearlyProductId}, monthly=${SubscriptionService.premiumMonthlyProductId}');
      return;
    }

    // Set up purchase callback
    subscriptionService.onPurchaseUpdate = (success, error) {
      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (success) {
        // CRITICAL FIX: Invalidate provider to refresh UI with new premium status
        ref.invalidate(subscriptionSnapshotProvider);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            padding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // slate-800
                    Color(0xFF0F172A), // slate-900
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.goldColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.paywallPremiumActivatedSuccess,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Close paywall
        Navigator.of(context).pop();
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            padding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // slate-800
                    Color(0xFF0F172A), // slate-900
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade300,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error ?? l10n.paywallPurchaseFailed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    };

    // Initiate purchase with selected product (yearly or monthly)
    await subscriptionService.purchasePremium(
      productId: _selectedPlanIsYearly
          ? SubscriptionService.premiumYearlyProductId
          : SubscriptionService.premiumMonthlyProductId,
    );
  }

  /// Handle restore button
  Future<void> _handleRestore() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final subscriptionService = ref.read(subscriptionServiceProvider);
    final l10n = AppLocalizations.of(context);

    // Set up restore callback
    subscriptionService.onPurchaseUpdate = (success, error) {
      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (success) {
        // CRITICAL FIX: Invalidate provider to refresh UI with restored premium status
        ref.invalidate(subscriptionSnapshotProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            padding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // slate-800
                    Color(0xFF0F172A), // slate-900
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.goldColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.paywallPurchaseRestoredSuccess,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            padding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // slate-800
                    Color(0xFF0F172A), // slate-900
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade300,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.paywallNoPreviousPurchaseFound,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    };

    // Initiate restore
    await subscriptionService.restorePurchases();
  }

  /// Build plan selector (yearly vs monthly)
  Widget _buildPlanSelector(BuildContext context, AppLocalizations l10n,
      dynamic subscriptionService) {
    final yearlyProduct = subscriptionService.premiumProductYearly;
    final monthlyProduct = subscriptionService.premiumProductMonthly;

    // Calculate savings
    final yearlyPrice = double.tryParse(
            yearlyProduct?.price.replaceAll(RegExp(r'[^\d.]'), '') ??
                '35.99') ??
        35.99;
    final monthlyPrice = double.tryParse(
            monthlyProduct?.price.replaceAll(RegExp(r'[^\d.]'), '') ??
                '5.99') ??
        5.99;
    final yearlyTotal = monthlyPrice * 12;
    final savings = ((yearlyTotal - yearlyPrice) / yearlyTotal * 100).round();

    return Row(
      children: [
        // Yearly Plan (Recommended)
        Expanded(
          child: Semantics(
            label:
                '${l10n.paywallPlanYearly} ${yearlyProduct?.price ?? '\$35.99'} ${l10n.paywallPerYear}. ${l10n.paywallBestValue}. ${l10n.paywallSavePercent(savings)}',
            selected: _selectedPlanIsYearly,
            button: true,
            child: GestureDetector(
              onTap: () => setState(() => _selectedPlanIsYearly = true),
              child: GlassContainer(
                borderRadius: 20,
                blurStrength: 15.0,
                gradientColors: _selectedPlanIsYearly
                    ? [
                        AppTheme.goldColor.withValues(alpha: 0.1),
                        AppTheme.goldColor.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                border: Border.all(
                  color: _selectedPlanIsYearly
                      ? AppTheme.goldColor.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
                  width: _selectedPlanIsYearly ? 2 : 1,
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                enableNoise: true,
                enableLightSimulation: true,
                child: Column(
                  children: [
                    // "BEST VALUE" badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.paywallBestValue,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Plan name
                    Text(
                      l10n.paywallPlanYearly,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedPlanIsYearly
                            ? AppTheme.goldColor
                            : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Price
                    Text(
                      yearlyProduct?.price ?? '\$35.99',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _selectedPlanIsYearly
                            ? AppTheme.goldColor
                            : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Per period
                    Text(
                      l10n.paywallPerYear,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // CRITICAL: Subscription length (required by Apple Guideline 3.1.2)
                    Text(
                      '12 months of access',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _selectedPlanIsYearly
                            ? AppTheme.goldColor.withValues(alpha: 0.9)
                            : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Savings
                    Text(
                      l10n.paywallSavePercent(savings),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.goldColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Monthly Plan
        Expanded(
          child: Semantics(
            label:
                '${l10n.paywallPlanMonthly} ${monthlyProduct?.price ?? '\$5.99'} ${l10n.paywallPerMonth}. ${l10n.paywallBilledMonthly}',
            selected: !_selectedPlanIsYearly,
            button: true,
            child: GestureDetector(
              onTap: () => setState(() => _selectedPlanIsYearly = false),
              child: GlassContainer(
                borderRadius: 20,
                blurStrength: 15.0,
                gradientColors: !_selectedPlanIsYearly
                    ? [
                        AppTheme.goldColor.withValues(alpha: 0.1),
                        AppTheme.goldColor.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                border: Border.all(
                  color: !_selectedPlanIsYearly
                      ? AppTheme.goldColor.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
                  width: !_selectedPlanIsYearly ? 2 : 1,
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                enableNoise: true,
                enableLightSimulation: true,
                child: Column(
                  children: [
                    // Spacer to match yearly badge height
                    const SizedBox(height: 18),
                    const SizedBox(height: 8),
                    // Plan name
                    Text(
                      l10n.paywallPlanMonthly,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: !_selectedPlanIsYearly
                            ? AppTheme.goldColor
                            : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Price
                    Text(
                      monthlyProduct?.price ?? '\$5.99',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: !_selectedPlanIsYearly
                            ? AppTheme.goldColor
                            : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Per period
                    Text(
                      l10n.paywallPerMonth,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // CRITICAL: Subscription length (required by Apple Guideline 3.1.2)
                    Text(
                      '1 month of access',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: !_selectedPlanIsYearly
                            ? AppTheme.goldColor.withValues(alpha: 0.9)
                            : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Billed info
                    Text(
                      l10n.paywallBilledMonthly,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Launch URL in external browser (Safari/Chrome)
  /// Used for Privacy Policy and Terms of Use links
  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Open in Safari/browser
        );
      } else {
        debugPrint('📊 [PaywallScreen] Could not launch URL: $urlString');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            padding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade300,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Could not open link. Please check your internet connection.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('📊 [PaywallScreen] Error launching URL: $e');
    }
  }

  @override
  void dispose() {
    // Clear callback - use try-catch since ref may not be accessible after dispose starts
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      subscriptionService.onPurchaseUpdate = null;
    } catch (_) {
      // Widget already disposed, callback will be garbage collected
    }
    super.dispose();
  }
}
