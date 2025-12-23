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
import 'package:flutter_scalify/flutter_scalify.dart';
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
          AppWidthLimiter(
            maxWidth: 900,
            horizontalPadding: 0,
            backgroundColor: Colors.transparent,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: AppSpacing.xl.s,
                  left: AppSpacing.xl.s,
                  right: AppSpacing.xl.s,
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with StandardScreenHeader
                  _buildAppBar(
                      isInTrial, trialDaysRemaining, subscriptionService),
                  AppSpacing.xl.sbh,

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
                          fontSize: 16.fz,
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
                          fontSize: 16.fz,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  AppSpacing.xxl.sbh,

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
                        AppSpacing.md.sbw,
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
                        AppSpacing.md.sbw,
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
                    AppSpacing.xxl.sbh,
                  ],

                  // Plan Selector (show when trial expired/blocked OR when out of messages)
                  if (hasTrialExpired ||
                      isTrialBlocked ||
                      remainingMessages == 0 ||
                      widget.showMessageStats) ...[
                    _buildPlanSelector(context, l10n, subscriptionService),
                    AppSpacing.xl.sbh,
                  ],

                  // 150 Scripture Chats badge (centered under plan selectors)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl.s,
                            vertical: AppSpacing.md.s,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: 30.br,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.paywall150MessagesPerMonth,
                            style: TextStyle(
                              fontSize: 14.fz,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        AppSpacing.sm.sbh,
                        // Pricing disclaimer below badge
                        Text(
                          l10n.paywallPricingDisclaimer,
                          style: TextStyle(
                            fontSize: 11.fz,
                            color:
                                AppColors.secondaryText.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.xxl.sbh,

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
                  AppSpacing.lg.sbh,

                  // Restore Button
                  GestureDetector(
                    onTap: _isProcessing ? null : _handleRestore,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.md.s,
                      ),
                      child: Center(
                        child: Text(
                          l10n.paywallRestorePurchase,
                          style: TextStyle(
                            fontSize: 16.fz,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.goldColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.xxl.sbh,

                  // Features Section (moved below Subscribe button)
                  GlassSectionHeader(
                    title: l10n.paywallWhatsIncluded,
                    icon: Icons.check_circle_outline,
                  ),
                  AppSpacing.lg.sbh,

                  // Feature List
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: l10n.paywallFeatureIntelligentChat,
                    subtitle: l10n.paywallFeatureIntelligentChatDesc,
                  ),
                  AppSpacing.md.sbh,
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.all_inclusive,
                    title: l10n.paywallFeature150Messages,
                    subtitle: l10n.paywallFeature150MessagesDesc,
                  ),
                  AppSpacing.md.sbh,
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.psychology,
                    title: l10n.paywallFeatureContextAware,
                    subtitle: l10n.paywallFeatureContextAwareDesc,
                  ),
                  AppSpacing.md.sbh,
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: l10n.paywallFeatureCrisisDetection,
                    subtitle: l10n.paywallFeatureCrisisDetectionDesc,
                  ),
                  AppSpacing.md.sbh,
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.book_outlined,
                    title: l10n.paywallFeatureFullBibleAccess,
                    subtitle: l10n.paywallFeatureFullBibleAccessDesc,
                  ),
                  AppSpacing.lg.sbh,

                  // Terms
                  FrostedGlassCard(
                    padding: EdgeInsets.all(AppSpacing.lg.s),
                    intensity: GlassIntensity.light,
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.secondaryText,
                          size: 20.iz,
                        ),
                        AppSpacing.sm.sbh,
                        Text(
                          Platform.isIOS
                              ? l10n.paywallSubscriptionTerms // iOS: App Store
                              : l10n
                                  .paywallSubscriptionTermsAndroid, // Android: Google Play
                          style: TextStyle(
                            fontSize: 12.fz,
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.xxl.sbh,
                ],
              ),
            ),
          ),
          ),
          // Pinned FAB
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.xl.s,
            left: AppSpacing.xl.s,
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
      padding: EdgeInsets.all(AppSpacing.md.s),
      intensity: GlassIntensity.medium,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10.s),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: AppRadius.sm.br,
            ),
            child: Icon(icon, size: 24.iz, color: color),
          ),
          AppSpacing.sm.sbh,
          Text(
            value,
            style: TextStyle(
              fontSize: 20.fz,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              shadows: AppTheme.textShadowStrong,
            ),
          ),
          4.sbh,
          Text(
            label,
            style: TextStyle(
              fontSize: 11.fz,
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
      padding: EdgeInsets.all(AppSpacing.lg.s),
      intensity: GlassIntensity.medium,
      borderColor: AppTheme.goldColor.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md.s),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.2),
              borderRadius: AppRadius.sm.br,
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 24.iz,
              color: AppTheme.goldColor,
            ),
          ),
          AppSpacing.lg.sbw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.fz,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                4.sbh,
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.fz,
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
            margin: EdgeInsets.all(16.s),
            padding: EdgeInsets.zero,
            content: Container(
              padding: EdgeInsets.all(16.s),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // slate-800
                    Color(0xFF0F172A), // slate-900
                  ],
                ),
                borderRadius: 12.br,
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.goldColor,
                    size: 20.iz,
                  ),
                  12.sbw,
                  Expanded(
                    child: Text(
                      l10n.paywallPremiumActivatedSuccess,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.fz,
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
            margin: EdgeInsets.all(16.s),
            padding: EdgeInsets.zero,
            content: Container(
              padding: EdgeInsets.all(16.s),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // slate-800
                    Color(0xFF0F172A), // slate-900
                  ],
                ),
                borderRadius: 12.br,
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
                    size: 20.iz,
                  ),
                  12.sbw,
                  Expanded(
                    child: Text(
                      error ?? l10n.paywallPurchaseFailed,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.fz,
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
            margin: EdgeInsets.all(16.s),
            padding: EdgeInsets.zero,
            content: Container(
              padding: EdgeInsets.all(16.s),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // slate-800
                    Color(0xFF0F172A), // slate-900
                  ],
                ),
                borderRadius: 12.br,
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.goldColor,
                    size: 20.iz,
                  ),
                  12.sbw,
                  Expanded(
                    child: Text(
                      l10n.paywallPurchaseRestoredSuccess,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.fz,
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
            margin: EdgeInsets.all(16.s),
            padding: EdgeInsets.zero,
            content: Container(
              padding: EdgeInsets.all(16.s),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // slate-800
                    Color(0xFF0F172A), // slate-900
                  ],
                ),
                borderRadius: 12.br,
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
                    size: 20.iz,
                  ),
                  12.sbw,
                  Expanded(
                    child: Text(
                      l10n.paywallNoPreviousPurchaseFound,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.fz,
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
                padding: EdgeInsets.all(AppSpacing.lg.s),
                enableNoise: true,
                enableLightSimulation: true,
                child: Column(
                  children: [
                    // "BEST VALUE" badge
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.s, vertical: 4.s),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor,
                        borderRadius: 4.br,
                      ),
                      child: Text(
                        l10n.paywallBestValue,
                        style: TextStyle(
                          fontSize: 10.fz,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    8.sbh,
                    // Plan name
                    Text(
                      l10n.paywallPlanYearly,
                      style: TextStyle(
                        fontSize: 16.fz,
                        fontWeight: FontWeight.bold,
                        color: _selectedPlanIsYearly
                            ? AppTheme.goldColor
                            : AppColors.primaryText,
                      ),
                    ),
                    4.sbh,
                    // Price
                    Text(
                      yearlyProduct?.price ?? '\$35.99',
                      style: TextStyle(
                        fontSize: 20.fz,
                        fontWeight: FontWeight.bold,
                        color: _selectedPlanIsYearly
                            ? AppTheme.goldColor
                            : AppColors.primaryText,
                      ),
                    ),
                    2.sbh,
                    // Per period
                    Text(
                      l10n.paywallPerYear,
                      style: TextStyle(
                        fontSize: 12.fz,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    4.sbh,
                    // Savings
                    Text(
                      l10n.paywallSavePercent(savings),
                      style: TextStyle(
                        fontSize: 12.fz,
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
        AppSpacing.md.sbw,
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
                padding: EdgeInsets.all(AppSpacing.lg.s),
                enableNoise: true,
                enableLightSimulation: true,
                child: Column(
                  children: [
                    // Spacer to match yearly badge height
                    18.sbh,
                    8.sbh,
                    // Plan name
                    Text(
                      l10n.paywallPlanMonthly,
                      style: TextStyle(
                        fontSize: 16.fz,
                        fontWeight: FontWeight.bold,
                        color: !_selectedPlanIsYearly
                            ? AppTheme.goldColor
                            : AppColors.primaryText,
                      ),
                    ),
                    4.sbh,
                    // Price
                    Text(
                      monthlyProduct?.price ?? '\$5.99',
                      style: TextStyle(
                        fontSize: 20.fz,
                        fontWeight: FontWeight.bold,
                        color: !_selectedPlanIsYearly
                            ? AppTheme.goldColor
                            : AppColors.primaryText,
                      ),
                    ),
                    2.sbh,
                    // Per period
                    Text(
                      l10n.paywallPerMonth,
                      style: TextStyle(
                        fontSize: 12.fz,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    4.sbh,
                    // Billed info
                    Text(
                      l10n.paywallBilledMonthly,
                      style: TextStyle(
                        fontSize: 12.fz,
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
