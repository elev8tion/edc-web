import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_pwa_install/flutter_pwa_install.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
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
import '../core/services/navigation_debouncer.dart';
import '../l10n/app_localizations.dart';
import '../core/utils/simple_coach_mark.dart';
import '../core/utils/theme_extensions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _backgroundKey = GlobalKey();
  final GlobalKey _fabMenuKey = GlobalKey();
  final _navDebouncer = NavigationDebouncer();
  final AutoSizeGroup _mainFeatureTitlesGroup = AutoSizeGroup();

  @override
  void initState() {
    super.initState();
    _startOnboardingFlow();
  }

  /// Onboarding flow: Tutorial first, then trial dialog
  Future<void> _startOnboardingFlow() async {
    // Wait for widget to build
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Always start with tutorial check
    _showFabTutorialIfNeeded();
  }

  /// Trial welcome dialog removed - users navigate directly to features
  Future<void> _showTrialWelcomeIfNeeded() async {
    // No-op: Trial welcome dialog removed to prevent app reset issues
  }

  Future<void> _showFabTutorialIfNeeded() async {
    final prefsService = await PreferencesService.getInstance();

    // Check if tutorial already shown
    if (prefsService.hasFabTutorialShown()) {
      // Tutorial already shown, proceed to PWA install check
      _showPwaInstallIfNeeded();
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
        // Show PWA install prompt after tutorial
        _showPwaInstallIfNeeded();
      },
      onSkip: () {
        // Mark tutorial as shown even if skipped
        prefsService.setFabTutorialShown();
        // Show PWA install prompt after tutorial
        _showPwaInstallIfNeeded();
      },
    ).show(context);
  }

  /// Show PWA install prompt immediately after tutorial clears (web only)
  /// Then shows trial welcome dialog (LAST in onboarding flow)
  Future<void> _showPwaInstallIfNeeded() async {
    // Only run PWA logic on web, but still show trial dialog on all platforms
    if (!kIsWeb) {
      _showTrialWelcomeIfNeeded();
      return;
    }

    // Minimal delay to let tutorial animation complete
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    try {
      final pwa = FlutterPWAInstall.instance;

      // Debug: Print full installability report to see what's failing
      final report = await pwa.getInstallabilityReport();
      debugPrint('[PWA] Installability Report:\n$report');

      // Check if install prompt is available (browser captured beforeinstallprompt event)
      final canInstall = await pwa.canInstall();

      if (!canInstall) {
        debugPrint('[PWA] Install prompt not available - app may already be installed or not eligible');
        // Still show trial dialog even if PWA install not available
        _showTrialWelcomeIfNeeded();
        return;
      }

      debugPrint('[PWA] Showing install prompt immediately after tutorial');

      // Show install prompt immediately
      final result = await pwa.promptInstall(
        options: PromptOptions(
          onAccepted: () {
            debugPrint('[PWA] User accepted install prompt');
          },
          onDismissed: () {
            debugPrint('[PWA] User dismissed install prompt');
          },
          onError: (error) {
            debugPrint('[PWA] Install prompt error: $error');
          },
        ),
      );

      debugPrint('[PWA] Install result: ${result.outcome.name}');
    } catch (e) {
      // flutter_pwa_install package may throw on some browsers
      // due to navigator.standalone access issues
      debugPrint('[PWA] Install check failed (expected on some browsers): $e');
    }

    // Show trial welcome dialog LAST (after all other dialogs cleared)
    _showTrialWelcomeIfNeeded();
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
                padding: EdgeInsets.only(
                  top: context.theme.appSpacing.xl,
                  bottom: context.theme.appSpacing
                      .xxxl, // Extra bottom padding for button visibility
                ),
                // Optimize scrolling performance
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: 56 +
                            context.theme.appSpacing.lg +
                            32), // Space for FAB + spacing + 32px padding
                    _buildStatsRow(),
                    SizedBox(height: context.theme.appSpacing.xxl),
                    _buildMainFeatures(),
                    SizedBox(height: context.theme.appSpacing.xxl),
                    _buildQuickActions(),
                    SizedBox(height: context.theme.appSpacing.xxl),
                    _buildDailyVerse(),
                    SizedBox(height: context.theme.appSpacing.xxl),
                    _buildStartChatButton(),
                    SizedBox(
                        height: context.theme.appSpacing.xl), // Extra space at bottom
                  ],
                ),
              ),
            ),
          ),
          // Pinned FAB
          Positioned(
            top: MediaQuery.of(context).padding.top + context.theme.appSpacing.xl,
            left: context.theme.appSpacing.xl,
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
          padding: context.theme.appSpacing.horizontalXl,
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
                delay: context.theme.appAnimations.homeStatsCardDelay,
              ),
              loading: () => _buildStatCardLoading(
                label: l10n.dayStreak,
                icon: Icons.local_fire_department,
                color: Colors.orange,
                delay: context.theme.appAnimations.homeStatsCardDelay,
              ),
              error: (_, __) => _buildStatCard(
                value: "0",
                label: l10n.dayStreak,
                icon: Icons.local_fire_department,
                color: Colors.orange,
                delay: context.theme.appAnimations.homeStatsCardDelay,
              ),
            ),
            SizedBox(width: context.theme.appSpacing.lg),
            prayersCountAsync.when(
              data: (count) => _buildStatCard(
                value: "$count",
                label: l10n.prayers,
                icon: Icons.favorite,
                color: Colors.red,
                delay: context.theme.appAnimations.homeStatsCardDelay + context.theme.appAnimations.sequentialMedium,
              ),
              loading: () => _buildStatCardLoading(
                label: l10n.prayers,
                icon: Icons.favorite,
                color: Colors.red,
                delay: context.theme.appAnimations.homeStatsCardDelay + context.theme.appAnimations.sequentialMedium,
              ),
              error: (_, __) => _buildStatCard(
                value: "0",
                label: l10n.prayers,
                icon: Icons.favorite,
                color: Colors.red,
                delay: context.theme.appAnimations.homeStatsCardDelay + context.theme.appAnimations.sequentialMedium,
              ),
            ),
            SizedBox(width: context.theme.appSpacing.lg),
            versesCountAsync.when(
              data: (count) => _buildStatCard(
                value: "$count",
                label: l10n.savedVerses,
                icon: Icons.menu_book,
                color: AppTheme.goldColor,
                delay: context.theme.appAnimations.homeStatsCardDelay + context.theme.appAnimations.sequentialLong,
              ),
              loading: () => _buildStatCardLoading(
                label: l10n.savedVerses,
                icon: Icons.menu_book,
                color: AppTheme.goldColor,
                delay: context.theme.appAnimations.homeStatsCardDelay + context.theme.appAnimations.sequentialLong,
              ),
              error: (_, __) => _buildStatCard(
                value: "0",
                label: l10n.savedVerses,
                icon: Icons.menu_book,
                color: AppTheme.goldColor,
                delay: context.theme.appAnimations.homeStatsCardDelay + context.theme.appAnimations.sequentialLong,
              ),
            ),
            SizedBox(width: context.theme.appSpacing.lg),
            totalCompletedAsync.when(
              data: (total) => _buildStatCard(
                value: "$total",
                label: l10n.devotionals,
                icon: Icons.auto_stories,
                color: Colors.green,
                delay: context.theme.appAnimations.homeStatsCardDelay + context.theme.appAnimations.sequentialLong + context.theme.appAnimations.sequentialShort,
              ),
              loading: () => _buildStatCardLoading(
                label: l10n.devotionals,
                icon: Icons.auto_stories,
                color: Colors.green,
                delay: context.theme.appAnimations.homeStatsCardDelay + context.theme.appAnimations.sequentialLong + context.theme.appAnimations.sequentialShort,
              ),
              error: (_, __) => _buildStatCard(
                value: "0",
                label: l10n.devotionals,
                icon: Icons.auto_stories,
                color: Colors.green,
                delay: context.theme.appAnimations.homeStatsCardDelay + context.theme.appAnimations.sequentialLong + context.theme.appAnimations.sequentialShort,
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
    required Duration delay,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: 120.s,
        padding: EdgeInsets.symmetric(horizontal: 6.s, vertical: 12.s),
        decoration: BoxDecoration(
          gradient: AppGradients.glassMedium,
          borderRadius: context.theme.appRadius.cardRadius,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                  color: color.withOpacity(0.2),
                  borderRadius: context.theme.appRadius.mediumRadius,
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    size:
                        20, // Fixed size for consistent display in fixed container
                    color: context.theme.appColors.secondaryText,
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
                  color: context.theme.appColors.primaryText,
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
                  color: Colors.white.withOpacity(0.9),
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
        .fadeIn(delay: delay)
        .scale(delay: delay);
  }

  Widget _buildStatCardLoading({
    required String label,
    required IconData icon,
    required Color color,
    required Duration delay,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      period: const Duration(milliseconds: 1500),
      child: LayoutBuilder(
        builder: (context, constraints) => Container(
          width: 120.s,
          padding: EdgeInsets.symmetric(horizontal: 6.s, vertical: 12.s),
          decoration: BoxDecoration(
            gradient: AppGradients.glassMedium,
            borderRadius: context.theme.appRadius.cardRadius,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6.s),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: context.theme.appRadius.mediumRadius,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: context.theme.appColors.secondaryText.withOpacity(0.5),
                ),
              ),
              6.sbh,
              Container(
                height: 20.fz,
                width: 40.s,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              4.sbh,
              Container(
                height: 9.fz,
                width: 60.s,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay)
        .scale(delay: delay);
  }

  Widget _buildMainFeatures() {
    final l10n = AppLocalizations.of(context);
    final textSize =
        ref.watch(textSizeProvider); // Watch textSize to force rebuilds

    // Calculate dynamic height using unified responsive scale
    final cardHeight = 160.s;

    return Padding(
      padding: context.theme.appSpacing.horizontalXl,
      child: Column(
        children: [
          SizedBox(
            height: cardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DarkMainFeatureCard(
                    padding: EdgeInsets.all(14.s),
                    onTap: () => _navDebouncer.navigate(() =>
                        NavigationService.pushNamedImmediate(AppRoutes.chat)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClearGlassCard(
                          padding: EdgeInsets.all(8.s),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 20.iz,
                            color: context.theme.appColors.primaryText,
                          ),
                        ),
                        SizedBox(height: context.theme.appSpacing.sm),
                        AutoSizeText(
                          l10n.biblicalChat,
                          group: _mainFeatureTitlesGroup,
                          style: const TextStyle(
                            fontSize: 16,
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
                              color: context.theme.appColors.secondaryText,
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
                SizedBox(width: context.theme.appSpacing.md),
                Expanded(
                  child: DarkMainFeatureCard(
                    padding: EdgeInsets.all(14.s),
                    onTap: () => _navDebouncer.navigate(() =>
                        NavigationService.pushNamedImmediate(
                            AppRoutes.devotional)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClearGlassCard(
                          padding: EdgeInsets.all(8.s),
                          child: Icon(
                            Icons.auto_stories,
                            size: 20.iz,
                            color: context.theme.appColors.primaryText,
                          ),
                        ),
                        SizedBox(height: context.theme.appSpacing.sm),
                        AutoSizeText(
                          l10n.dailyDevotional,
                          group: _mainFeatureTitlesGroup,
                          style: const TextStyle(
                            fontSize: 16,
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
                              color: context.theme.appColors.secondaryText,
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
          )
              .animate()
              .fadeIn(delay: context.theme.appAnimations.homeMainFeatureDelay1)
              .slideX(begin: -0.3, delay: context.theme.appAnimations.homeMainFeatureDelay1),
          SizedBox(height: context.theme.appSpacing.md),
          SizedBox(
            height: cardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DarkMainFeatureCard(
                    padding: EdgeInsets.all(14.s),
                    onTap: () => _navDebouncer.navigate(() =>
                        NavigationService.pushNamedImmediate(
                            AppRoutes.prayerJournal)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClearGlassCard(
                          padding: EdgeInsets.all(8.s),
                          child: Icon(
                            Icons.favorite_outline,
                            size: 20.iz,
                            color: context.theme.appColors.primaryText,
                          ),
                        ),
                        SizedBox(height: context.theme.appSpacing.sm),
                        AutoSizeText(
                          l10n.prayerJournal,
                          group: _mainFeatureTitlesGroup,
                          style: const TextStyle(
                            fontSize: 16,
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
                              color: context.theme.appColors.secondaryText,
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
                SizedBox(width: context.theme.appSpacing.md),
                Expanded(
                  child: DarkMainFeatureCard(
                    padding: EdgeInsets.all(14.s),
                    onTap: () => _navDebouncer.navigate(() =>
                        NavigationService.pushNamedImmediate(
                            AppRoutes.readingPlan)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClearGlassCard(
                          padding: EdgeInsets.all(8.s),
                          child: Icon(
                            Icons.library_books_outlined,
                            size: 20.iz,
                            color: context.theme.appColors.primaryText,
                          ),
                        ),
                        SizedBox(height: context.theme.appSpacing.sm),
                        AutoSizeText(
                          l10n.readingPlans,
                          group: _mainFeatureTitlesGroup,
                          style: const TextStyle(
                            fontSize: 16,
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
                              color: context.theme.appColors.secondaryText,
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
          ).animate().fadeIn(delay: context.theme.appAnimations.homeMainFeatureDelay2).slideX(begin: 0.3, delay: context.theme.appAnimations.homeMainFeatureDelay2),
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
          padding: context.theme.appSpacing.horizontalXl,
          child: Text(
            l10n.quickActions,
            style: TextStyle(
              fontSize: 20.fz,
              fontWeight: FontWeight.w700,
              color: context.theme.appColors.primaryText,
              shadows: AppTheme.textShadowStrong,
            ),
          ),
        ).animate().fadeIn(delay: context.theme.appAnimations.homeQuickActionsHeaderDelay).slideX(begin: -0.3, delay: context.theme.appAnimations.homeQuickActionsHeaderDelay),
        SizedBox(height: context.theme.appSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: scaledHeight.clamp(88.0, 165.0), // Min 88px, max 165px
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: context.theme.appSpacing.horizontalXl,
              // Optimize horizontal scrolling performance
              physics: const BouncingScrollPhysics(),
              cacheExtent: 200,
              children: [
                _buildQuickActionCard(
                  label: l10n.readBible,
                  icon: Icons.menu_book,
                  color: AppTheme.goldColor,
                  onTap: () => _navDebouncer.navigate(() =>
                      NavigationService.pushNamedImmediate(
                          AppRoutes.bibleBrowser)),
                ),
                SizedBox(width: context.theme.appSpacing.lg),
                _buildQuickActionCard(
                  label: useShortLabel
                      ? l10n.verseLibraryShort
                      : l10n.verseLibrary,
                  icon: Icons.search,
                  color: Colors.blue,
                  onTap: () => _navDebouncer.navigate(() =>
                      NavigationService.pushNamedImmediate(
                          AppRoutes.verseLibrary)),
                ),
                SizedBox(width: context.theme.appSpacing.lg),
                _buildQuickActionCard(
                  label: useShortLabel ? l10n.addPrayerShort : l10n.addPrayer,
                  icon: Icons.add,
                  color: Colors.green,
                  onTap: () => _navDebouncer.navigate(() =>
                      NavigationService.pushNamedImmediate(
                          AppRoutes.prayerJournal)),
                ),
                SizedBox(width: context.theme.appSpacing.lg),
                _buildQuickActionCard(
                  label: l10n.settings,
                  icon: Icons.settings,
                  color: Colors.grey[300]!,
                  onTap: () => _navDebouncer.navigate(() =>
                      NavigationService.pushNamedImmediate(AppRoutes.settings)),
                ),
                SizedBox(width: context.theme.appSpacing.lg),
                _buildQuickActionCard(
                  label: l10n.profile,
                  icon: Icons.person,
                  color: Colors.purple,
                  onTap: () => _navDebouncer.navigate(() =>
                      NavigationService.pushNamedImmediate(AppRoutes.profile)),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: context.theme.appAnimations.homeQuickActionsRowDelay).slideX(begin: 0.3, delay: context.theme.appAnimations.homeQuickActionsRowDelay),
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
            borderRadius: context.theme.appRadius.md.br,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                  color: color.withOpacity(0.2),
                  borderRadius: context.theme.appRadius.mediumRadius,
                ),
                child: Icon(
                  icon,
                  size: 24.iz,
                  color: context.theme.appColors.secondaryText,
                ),
              ),
              SizedBox(height: context.theme.appSpacing.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: AutoSizeText(
                    label,
                    style: TextStyle(
                      fontSize: 11.fz,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
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
    final textSize =
        ref.watch(textSizeProvider); // Watch textSize to force rebuilds

    return todaysVerseAsync.when(
      data: (verseData) {
        if (verseData == null) {
          return const SizedBox.shrink(); // Hide if no verse available
        }

        final reference = verseData['reference'] as String? ?? '';
        final text = verseData['text'] as String? ?? '';

        return Padding(
          padding: context.theme.appSpacing.horizontalXl,
          child: Container(
            padding: context.theme.appSpacing.screenPaddingLarge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.s),
                      decoration: BoxDecoration(
                        gradient: AppGradients.goldAccent,
                        borderRadius: context.theme.appRadius.mediumRadius,
                        border: Border.all(
                          color: AppTheme.goldColor.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: context.theme.appColors.primaryText,
                        size: 20.iz,
                      ),
                    ),
                    SizedBox(width: context.theme.appSpacing.lg),
                    Expanded(
                      child: Text(
                        l10n.verseOfTheDay,
                        style: TextStyle(
                          fontSize: 18.fz,
                          fontWeight: FontWeight.w700,
                          color: context.theme.appColors.primaryText,
                          shadows: AppTheme.textShadowStrong,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.theme.appSpacing.xl),
                DarkGlassContainer(
                  borderRadius: context.theme.appRadius.md,
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
                      SizedBox(height: context.theme.appSpacing.md),
                      // Verse text
                      AutoSizeText(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
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
        ).animate().fadeIn(delay: context.theme.appAnimations.homeDailyVerseDelay).slideX(begin: -0.3, delay: context.theme.appAnimations.homeDailyVerseDelay);
      },
      loading: () => Padding(
        padding: context.theme.appSpacing.horizontalXl,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: AppGradients.glassStrong,
            borderRadius: context.theme.appRadius.cardRadius,
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
    final textSize =
        ref.watch(textSizeProvider); // Watch textSize to force rebuilds
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassButton(
        text: l10n.startSpiritualConversation,
        onPressed: () => _navDebouncer.navigate(
            () => NavigationService.pushNamedImmediate(AppRoutes.chat)),
      ),
    ).animate().fadeIn(delay: context.theme.appAnimations.homeStartChatDelay).slideX(begin: 0.3, delay: context.theme.appAnimations.homeStartChatDelay);
  }
}
