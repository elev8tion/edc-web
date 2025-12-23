import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_scalify/flutter_scalify.dart';
import '../theme/app_theme.dart';
import '../theme/app_gradients.dart';
import '../components/dark_main_feature_card.dart';
import '../components/clear_glass_card.dart';
import '../components/glass_button.dart';
import '../components/gradient_background.dart';
import '../components/glassmorphic_fab_menu.dart';
import '../components/dark_glass_container.dart';
import '../core/navigation/app_routes.dart';
import '../core/providers/app_providers.dart';
import '../core/navigation/navigation_service.dart';
import '../core/services/preferences_service.dart';
import '../core/services/subscription_service.dart';
import '../components/trial_welcome_dialog.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';
import '../core/utils/simple_coach_mark.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _backgroundKey = GlobalKey();
  final GlobalKey _fabMenuKey = GlobalKey();
  bool _isNavigating = false;
  final AutoSizeGroup _mainFeatureTitlesGroup = AutoSizeGroup();

  @override
  void initState() {
    super.initState();
    _checkShowTrialWelcome();
  }

  Future<void> _checkShowTrialWelcome() async {
    // Wait for widget to build
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final subscriptionService = SubscriptionService.instance;

    // Show dialog if:
    // 1. User hasn't started trial yet
    // 2. User isn't premium
    // 3. Haven't shown dialog before
    if (!subscriptionService.hasStartedTrial &&
        !subscriptionService.isPremium) {
      final prefsService = await PreferencesService.getInstance();
      final sharedPrefs = prefsService.prefs;
      final shownBefore = sharedPrefs?.getBool('trial_welcome_shown') ?? false;

      if (!shownBefore && mounted) {
        // Mark as shown
        await sharedPrefs?.setBool('trial_welcome_shown', true);

        // Show dialog
        // ignore: use_build_context_synchronously
        final result = await TrialWelcomeDialog.show(context);

        // If user clicked "Start Free Trial", navigate to chat
        if (result == true && mounted) {
          Navigator.of(context).pushNamed(AppRoutes.chat);
        }

        // After dialog closes, show FAB tutorial if first time
        if (mounted) {
          _showFabTutorialIfNeeded();
        }
      } else {
        // If trial dialog already shown, check for tutorial
        _showFabTutorialIfNeeded();
      }
    } else {
      // Premium user or trial started, still show tutorial if needed
      _showFabTutorialIfNeeded();
    }
  }

  Future<void> _showFabTutorialIfNeeded() async {
    final prefsService = await PreferencesService.getInstance();

    // Check if tutorial already shown
    if (prefsService.hasFabTutorialShown()) {
      return;
    }

    // Wait a bit for UI to settle
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    // Show tutorial
    SimpleCoachMark(
      targets: [
        CoachTarget(
          key: _fabMenuKey,
          title: l10n.tutorialHomeTitle,
          description: l10n.tutorialHomeDescription,
          contentPosition: ContentPosition.bottom,
          shape: HighlightShape.rectangle,
          borderRadius: 20,
          padding: 8,
          semanticLabel: l10n.tutorialHomeTitle,
        ),
      ],
      config: CoachMarkConfig(
        skipText: l10n.tutorialSkip,
        nextText: l10n.tutorialNext,
        previousText: l10n.tutorialPrevious,
      ),
      onFinish: () {
        // Mark tutorial as shown
        prefsService.setFabTutorialShown();
      },
      onSkip: () {
        // Mark tutorial as shown even if skipped
        prefsService.setFabTutorialShown();
      },
    ).show(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            key: _backgroundKey,
            child: const GradientBackground(),
          ),
          AppWidthLimiter(
            maxWidth: 1200,
            horizontalPadding: 0,
            backgroundColor: Colors.transparent,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xl,
                  bottom: AppSpacing.xxxl, // Extra bottom padding for button visibility
                ),
                // Optimize scrolling performance
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                        height: 56 +
                            AppSpacing.lg +
                            32), // Space for FAB + spacing + 32px padding
                    _buildStatsRow(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildMainFeatures(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildQuickActions(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildDailyVerse(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildStartChatButton(),
                    const SizedBox(height: AppSpacing.xl), // Extra space at bottom
                  ],
                ),
              ),
            ),
          ),
          // Pinned FAB - positioned directly without AppWidthLimiter to avoid LayoutBuilder nesting issues
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.xl,
            left: AppSpacing.xl,
            child: GlassmorphicFABMenu(key: _fabMenuKey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final l10n = AppLocalizations.of(context);
    final streakAsync = ref.watch(devotionalStreakProvider);
    final totalCompletedAsync = ref.watch(totalDevotionalsCompletedProvider);
    final prayersCountAsync = ref.watch(activePrayersCountProvider);
    final versesCountAsync = ref.watch(savedVersesCountProvider);

    // Scale height based on BOTH screen size AND text scale factor
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final baseHeight = 110.s;
    // Apply text scale factor with damping (not full 1.5x, but enough to prevent overflow)
    final scaledHeight = baseHeight * (1.0 + (textScaleFactor - 1.0) * 0.5);

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: scaledHeight.clamp(88.0, 165.0), // Min 88px, max 165px
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: AppSpacing.horizontalXl,
          // Optimize horizontal scrolling performance
          physics: const BouncingScrollPhysics(),
          cacheExtent: 300,
          children: [
            streakAsync.when(
              data: (streak) => _buildStatCard(
                value: "$streak",
                label: l10n.dayStreak,
                icon: Icons.local_fire_department,
                color: Colors.orange,
                delay: 600,
              ),
              loading: () => _buildStatCardLoading(
                label: l10n.dayStreak,
                icon: Icons.local_fire_department,
                color: Colors.orange,
                delay: 600,
              ),
              error: (_, __) => _buildStatCard(
                value: "0",
                label: l10n.dayStreak,
                icon: Icons.local_fire_department,
                color: Colors.orange,
                delay: 600,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            prayersCountAsync.when(
              data: (count) => _buildStatCard(
                value: "$count",
                label: l10n.prayers,
                icon: Icons.favorite,
                color: Colors.red,
                delay: 700,
              ),
              loading: () => _buildStatCardLoading(
                label: l10n.prayers,
                icon: Icons.favorite,
                color: Colors.red,
                delay: 700,
              ),
              error: (_, __) => _buildStatCard(
                value: "0",
                label: l10n.prayers,
                icon: Icons.favorite,
                color: Colors.red,
                delay: 700,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            versesCountAsync.when(
              data: (count) => _buildStatCard(
                value: "$count",
                label: l10n.savedVerses,
                icon: Icons.menu_book,
                color: AppTheme.goldColor,
                delay: 800,
              ),
              loading: () => _buildStatCardLoading(
                label: l10n.savedVerses,
                icon: Icons.menu_book,
                color: AppTheme.goldColor,
                delay: 800,
              ),
              error: (_, __) => _buildStatCard(
                value: "0",
                label: l10n.savedVerses,
                icon: Icons.menu_book,
                color: AppTheme.goldColor,
                delay: 800,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            totalCompletedAsync.when(
              data: (total) => _buildStatCard(
                value: "$total",
                label: l10n.devotionals,
                icon: Icons.auto_stories,
                color: Colors.green,
                delay: 900,
              ),
              loading: () => _buildStatCardLoading(
                label: l10n.devotionals,
                icon: Icons.auto_stories,
                color: Colors.green,
                delay: 900,
              ),
              error: (_, __) => _buildStatCard(
                value: "0",
                label: l10n.devotionals,
                icon: Icons.auto_stories,
                color: Colors.green,
                delay: 900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: 120.s,
        padding: EdgeInsets.symmetric(horizontal: 6.s, vertical: 12.s),
        decoration: BoxDecoration(
          gradient: AppGradients.glassMedium,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10.s,
              offset: Offset(0, 4.s),
            ),
          ],
        ),
        // FittedBox scales down entire content to fit container (Rule 2)
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6.s),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: AppRadius.mediumRadius,
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: 20,  // Fixed size for consistent display in fixed container
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              4.sbh,
              // Value text
              Text(
                value,
                style: TextStyle(
                  fontSize: 20.fz,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                  shadows: AppTheme.textShadowStrong,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              2.sbh,
              // Label text
              Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.fz,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: AppTheme.textShadowSubtle,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .scale(delay: Duration(milliseconds: delay));
  }

  Widget _buildStatCardLoading({
    required String label,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: 120.s,
        padding: EdgeInsets.symmetric(horizontal: 6.s, vertical: 12.s),
        decoration: BoxDecoration(
          gradient: AppGradients.glassMedium,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10.s,
              offset: Offset(0, 4.s),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6.s),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: AppRadius.mediumRadius,
              ),
              child: ExcludeSemantics(
                child: Icon(
                  icon,
                  size: 20,  // Fixed size for consistent display in fixed container
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            6.sbh,
            // Placeholder text instead of infinite spinner (fixes test timeouts)
            AutoSizeText(
              "...",
              style: TextStyle(
                fontSize: 20.fz,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText.withValues(alpha: 0.5),
                shadows: AppTheme.textShadowStrong,
              ),
              maxLines: 1,
              minFontSize: 14,
              maxFontSize: 22,
              textAlign: TextAlign.center,
            ),
            4.sbh,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.s),
              child: AutoSizeText(
                label,
                style: TextStyle(
                  fontSize: 9.fz,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  shadows: AppTheme.textShadowSubtle,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 7,
                maxFontSize: 11,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .scale(delay: Duration(milliseconds: delay));
  }

  Widget _buildMainFeatures() {
    final l10n = AppLocalizations.of(context);
    final textSize = ref.watch(textSizeProvider); // Watch textSize to force rebuilds

    // Calculate dynamic height using unified responsive scale
    final cardHeight = 160.s;

    return Padding(
      padding: AppSpacing.horizontalXl,
      child: Column(
        children: [
          SizedBox(
            height: cardHeight,
            key: ValueKey('main_features_row1_$textSize'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DarkMainFeatureCard(
                    padding: EdgeInsets.all(14.s),
                    onTap: () async {
                      if (_isNavigating) return;
                      _isNavigating = true;
                      await NavigationService.pushNamedImmediate(AppRoutes.chat);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) setState(() => _isNavigating = false);
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClearGlassCard(
                          padding: EdgeInsets.all(8.s),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 20.iz,
                            color: AppColors.primaryText,
                          ),
                        ),
                        AppSpacing.sm.sbh,
                        AutoSizeText(
                          l10n.biblicalChat,
                          group: _mainFeatureTitlesGroup,
                          style: TextStyle(
                            fontSize: 16.fz,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                        6.sbh,
                        Flexible(
                          child: AutoSizeText(
                            l10n.biblicalChatDesc,
                            style: TextStyle(
                              fontSize: 12.fz,
                              color: AppColors.secondaryText,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            minFontSize: 9,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DarkMainFeatureCard(
                    padding: EdgeInsets.all(14.s),
                    onTap: () async {
                      if (_isNavigating) return;
                      _isNavigating = true;
                      await NavigationService.pushNamedImmediate(AppRoutes.devotional);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) setState(() => _isNavigating = false);
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClearGlassCard(
                          padding: EdgeInsets.all(8.s),
                          child: Icon(
                            Icons.auto_stories,
                            size: 20.iz,
                            color: AppColors.primaryText,
                          ),
                        ),
                        AppSpacing.sm.sbh,
                        AutoSizeText(
                          l10n.dailyDevotional,
                          group: _mainFeatureTitlesGroup,
                          style: TextStyle(
                            fontSize: 16.fz,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                        6.sbh,
                        Flexible(
                          child: AutoSizeText(
                            l10n.dailyDevotionalDesc,
                            style: TextStyle(
                              fontSize: 12.fz,
                              color: AppColors.secondaryText,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            minFontSize: 9,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.3, delay: 1000.ms),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: cardHeight,
            key: ValueKey('main_features_row2_$textSize'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DarkMainFeatureCard(
                    padding: EdgeInsets.all(14.s),
                    onTap: () async {
                      if (_isNavigating) return;
                      _isNavigating = true;
                      await NavigationService.pushNamedImmediate(AppRoutes.prayerJournal);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) setState(() => _isNavigating = false);
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClearGlassCard(
                          padding: EdgeInsets.all(8.s),
                          child: Icon(
                            Icons.favorite_outline,
                            size: 20.iz,
                            color: AppColors.primaryText,
                          ),
                        ),
                        AppSpacing.sm.sbh,
                        AutoSizeText(
                          l10n.prayerJournal,
                          group: _mainFeatureTitlesGroup,
                          style: TextStyle(
                            fontSize: 16.fz,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                        6.sbh,
                        Flexible(
                          child: AutoSizeText(
                            l10n.prayerJournalDesc,
                            style: TextStyle(
                              fontSize: 12.fz,
                              color: AppColors.secondaryText,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            minFontSize: 9,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.md.sbw,
                Expanded(
                  child: DarkMainFeatureCard(
                    padding: EdgeInsets.all(14.s),
                    onTap: () async {
                      if (_isNavigating) return;
                      _isNavigating = true;
                      await NavigationService.pushNamedImmediate(AppRoutes.readingPlan);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) setState(() => _isNavigating = false);
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClearGlassCard(
                          padding: EdgeInsets.all(8.s),
                          child: Icon(
                            Icons.library_books_outlined,
                            size: 20.iz,
                            color: AppColors.primaryText,
                          ),
                        ),
                        AppSpacing.sm.sbh,
                        AutoSizeText(
                          l10n.readingPlans,
                          group: _mainFeatureTitlesGroup,
                          style: TextStyle(
                            fontSize: 16.fz,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                        6.sbh,
                        Flexible(
                          child: AutoSizeText(
                            l10n.readingPlansDesc,
                            style: TextStyle(
                              fontSize: 12.fz,
                              color: AppColors.secondaryText,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            minFontSize: 9,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 1100.ms).slideX(begin: 0.3, delay: 1100.ms),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);
    final textSize = ref.watch(textSizeProvider);
    final useShortLabel = textSize >= 1.3;
    // Scale height based on BOTH screen size AND text scale factor
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final baseHeight = 110.s;
    final scaledHeight = baseHeight * (1.0 + (textScaleFactor - 1.0) * 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.horizontalXl,
          key: ValueKey('quick_actions_header_$textSize'),
          child: Text(
            l10n.quickActions,
            style: TextStyle(
              fontSize: 20.fz,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
              shadows: AppTheme.textShadowStrong,
            ),
          ),
        ).animate().fadeIn(delay: 1200.ms).slideX(begin: -0.3, delay: 1200.ms),
        AppSpacing.lg.sbh,
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: scaledHeight.clamp(88.0, 165.0), // Min 88px, max 165px
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.horizontalXl,
              // Optimize horizontal scrolling performance
              physics: const BouncingScrollPhysics(),
              cacheExtent: 200,
              children: [
                _buildQuickActionCard(
                  label: l10n.readBible,
                  icon: Icons.menu_book,
                  color: AppTheme.goldColor,
                  onTap: () async {
                    if (_isNavigating) return;
                    _isNavigating = true;
                    await NavigationService.pushNamedImmediate(AppRoutes.bibleBrowser);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => _isNavigating = false);
                    });
                  },
                ),
                const SizedBox(width: AppSpacing.lg),
                _buildQuickActionCard(
                  label: useShortLabel ? l10n.verseLibraryShort : l10n.verseLibrary,
                  icon: Icons.search,
                  color: Colors.blue,
                  onTap: () async {
                    if (_isNavigating) return;
                    _isNavigating = true;
                    await NavigationService.pushNamedImmediate(AppRoutes.verseLibrary);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => _isNavigating = false);
                    });
                  },
                ),
                const SizedBox(width: AppSpacing.lg),
                _buildQuickActionCard(
                  label: useShortLabel ? l10n.addPrayerShort : l10n.addPrayer,
                  icon: Icons.add,
                  color: Colors.green,
                  onTap: () async {
                    if (_isNavigating) return;
                    _isNavigating = true;
                    await NavigationService.pushNamedImmediate(AppRoutes.prayerJournal);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => _isNavigating = false);
                    });
                  },
                ),
                const SizedBox(width: AppSpacing.lg),
                _buildQuickActionCard(
                  label: l10n.settings,
                  icon: Icons.settings,
                  color: Colors.grey[300]!,
                  onTap: () async {
                    if (_isNavigating) return;
                    _isNavigating = true;
                    await NavigationService.pushNamedImmediate(AppRoutes.settings);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => _isNavigating = false);
                    });
                  },
                ),
                const SizedBox(width: AppSpacing.lg),
                _buildQuickActionCard(
                  label: l10n.profile,
                  icon: Icons.person,
                  color: Colors.purple,
                  onTap: () async {
                    if (_isNavigating) return;
                    _isNavigating = true;
                    await NavigationService.pushNamedImmediate(AppRoutes.profile);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => _isNavigating = false);
                    });
                  },
                ),
              ],
            ),
          ),
          key: ValueKey('quick_actions_row_$textSize'),
        ).animate().fadeIn(delay: 1300.ms).slideX(begin: 0.3, delay: 1300.ms),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100.s,
          padding: EdgeInsets.symmetric(horizontal: 6.s, vertical: 8.s),
          decoration: BoxDecoration(
            gradient: AppGradients.glassMedium,
            borderRadius: AppRadius.md.br,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8.s,
                offset: Offset(0, 4.s),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(10.s),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: AppRadius.mediumRadius,
                ),
                child: Icon(
                  icon,
                  size: 24.iz,
                  color: AppColors.secondaryText,
                ),
              ),
              AppSpacing.sm.sbh,
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: AutoSizeText(
                  label,
                  style: TextStyle(
                    fontSize: 11.fz,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: AppTheme.textShadowSubtle,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  minFontSize: 7,
                  maxFontSize: 11,
                  overflow: TextOverflow.ellipsis,
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyVerse() {
    final l10n = AppLocalizations.of(context);
    final todaysVerseAsync = ref.watch(todaysVerseProvider);
    final textSize = ref.watch(textSizeProvider); // Watch textSize to force rebuilds

    return todaysVerseAsync.when(
      data: (verseData) {
        if (verseData == null) {
          return const SizedBox.shrink(); // Hide if no verse available
        }

        final reference = verseData['reference'] as String? ?? '';
        final text = verseData['text'] as String? ?? '';

        return Padding(
          padding: AppSpacing.horizontalXl,
          key: ValueKey('daily_verse_$textSize'),
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
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppColors.primaryText,
                        size: 20.iz,
                      ),
                    ),
                    AppSpacing.lg.sbw,
                    Expanded(
                      child: Text(
                        l10n.verseOfTheDay,
                        style: TextStyle(
                          fontSize: 18.fz,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                          shadows: AppTheme.textShadowStrong,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.xl.sbh,
                DarkGlassContainer(
                  borderRadius: AppRadius.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reference ABOVE text
                      AutoSizeText(
                        reference,
                        style: TextStyle(
                          fontSize: 14.fz,
                          color: AppTheme.goldColor,
                          fontWeight: FontWeight.w700,
                          shadows: AppTheme.textShadowSubtle,
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                        maxFontSize: 16,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.md.sbh,
                      // Verse text
                      AutoSizeText(
                        text,
                        style: TextStyle(
                          fontSize: 16.fz,
                          color: AppColors.primaryText,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          shadows: AppTheme.textShadowSubtle,
                        ),
                        maxLines: 6,
                        minFontSize: 12,
                        maxFontSize: 18,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 1400.ms).slideX(begin: -0.3, delay: 1400.ms);
      },
      loading: () => Padding(
        padding: AppSpacing.horizontalXl,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: AppGradients.glassStrong,
            borderRadius: AppRadius.cardRadius,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
              strokeWidth: 3,
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStartChatButton() {
    final l10n = AppLocalizations.of(context);
    final textSize = ref.watch(textSizeProvider); // Watch textSize to force rebuilds
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.s),
      key: ValueKey('start_chat_button_$textSize'),
      child: GlassButton(
        text: l10n.startSpiritualConversation,
        onPressed: () async {
          if (_isNavigating) return;
          _isNavigating = true;
          await NavigationService.pushNamedImmediate(AppRoutes.chat);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _isNavigating = false);
          });
        },
      ),
    ).animate().fadeIn(delay: 1500.ms).slideX(begin: 0.3, delay: 1500.ms);
  }
}
