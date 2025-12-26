import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_card.dart';
import '../components/dark_glass_container.dart';
import '../components/clear_glass_card.dart';
import '../components/glass_button.dart';
import '../components/standard_screen_header.dart';
import '../components/calendar_heatmap_widget.dart';
import '../components/reading_progress_stats_widget.dart';
import '../core/widgets/app_snackbar.dart';
import '../theme/app_theme.dart';
import '../core/providers/app_providers.dart';
import '../core/models/reading_plan.dart';
import '../core/navigation/navigation_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/reading_reference_parser.dart';
import '../utils/blur_dialog_utils.dart';
import '../l10n/app_localizations.dart';

class ReadingPlanScreen extends ConsumerStatefulWidget {
  const ReadingPlanScreen({super.key});

  @override
  ConsumerState<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends ConsumerState<ReadingPlanScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Optimistic UI state: tracks checkbox toggles before database confirms
  final Map<String, bool> _optimisticCompletions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            const GradientBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTodayTab(),
                        _buildProgressTab(),
                        _buildMyPlansTab(),
                        _buildExplorePlansTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return StandardScreenHeader(
      title: l10n.readingPlans,
      subtitle: l10n.growInGodsWord,
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: AppSpacing.horizontalXl,
      child: GlassContainer(
        borderRadius: 24,
        blurStrength: 15.0,
        gradientColors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
        padding: const EdgeInsets.all(4),
        enableNoise: true,
        enableLightSimulation: true,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicator: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            borderRadius: AppRadius.mediumRadius,
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 1,
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize:
                ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
          ),
          tabs: [
            Tab(text: l10n.todayTab),
            Tab(text: l10n.progress),
            Tab(text: l10n.myPlans),
            Tab(text: l10n.explore),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.slow, delay: AppAnimations.normal);
  }

  Widget _buildProgressTab() {
    final l10n = AppLocalizations.of(context);
    final currentPlanAsync = ref.watch(currentReadingPlanProvider);

    return currentPlanAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (currentPlan) {
        if (currentPlan == null) {
          return _buildEmptyState(
            icon: Icons.insights,
            title: 'No Progress to Track',
            subtitle:
                'Start a reading plan to see your progress and statistics',
            action: () => _tabController.animateTo(3),
            actionText: l10n.explorePlans,
          );
        }

        final statsAsync =
            ref.watch(planCompletionStatsProvider(currentPlan.id));
        final heatmapAsync = ref.watch(planHeatmapDataProvider(currentPlan.id));
        final estimatedDateAsync =
            ref.watch(planEstimatedCompletionDateProvider(currentPlan.id));

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan header
              Text(
                currentPlan.title,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 24,
                      minSize: 20, maxSize: 28),
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ).animate().fadeIn(duration: AppAnimations.slow),
              const SizedBox(height: 8),
              Text(
                l10n.yourProgressAndStatistics,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: AppColors.secondaryText,
                ),
              ).animate().fadeIn(
                  duration: AppAnimations.slow, delay: AppAnimations.fast),
              const SizedBox(height: AppSpacing.xxl),

              // Statistics
              statsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                    strokeWidth: 3,
                  ),
                ),
                error: (error, stack) =>
                    Text(l10n.errorWithMessage(error.toString())),
                data: (stats) {
                  return estimatedDateAsync.when(
                    loading: () => ReadingProgressStatsWidget(stats: stats),
                    error: (_, __) => ReadingProgressStatsWidget(stats: stats),
                    data: (estimatedDate) => ReadingProgressStatsWidget(
                      stats: stats,
                      estimatedCompletionDate: estimatedDate,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Calendar heatmap
              Text(
                'Reading Activity',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 20,
                      minSize: 18, maxSize: 24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ).animate().fadeIn(duration: AppAnimations.slow, delay: 600.ms),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Days with completed readings in the last 90 days',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 12,
                      minSize: 10, maxSize: 14),
                  color: AppColors.secondaryText,
                ),
              ).animate().fadeIn(duration: AppAnimations.slow, delay: 700.ms),
              const SizedBox(height: AppSpacing.lg),
              heatmapAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                    strokeWidth: 3,
                  ),
                ),
                error: (error, stack) =>
                    Text(l10n.errorWithMessage(error.toString())),
                data: (heatmapData) {
                  return DarkGlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: CalendarHeatmapWidget(
                      activityData: heatmapData,
                      columns: 13,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: AppAnimations.slow, delay: 800.ms);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayTab() {
    final l10n = AppLocalizations.of(context);
    final currentPlanAsync = ref.watch(currentReadingPlanProvider);

    return currentPlanAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (currentPlan) {
        if (currentPlan == null) {
          return _buildEmptyState(
            icon: Icons.book_outlined,
            title: l10n.noActiveReadingPlan,
            subtitle: l10n.startReadingPlanPrompt,
            action: () => _tabController.animateTo(3),
            actionText: l10n.explorePlans,
          );
        }

        final todaysReadingsAsync =
            ref.watch(todaysReadingsProvider(currentPlan.id));

        return todaysReadingsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
              strokeWidth: 3,
            ),
          ),
          error: (error, stack) => _buildErrorState(error.toString()),
          data: (todaysReadings) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentPlanCard(currentPlan),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.todaysReadings,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 20,
                          minSize: 18, maxSize: 24),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ).animate().fadeIn(
                      duration: AppAnimations.slow, delay: AppAnimations.slow),
                  const SizedBox(height: AppSpacing.lg),
                  if (todaysReadings.isEmpty)
                    _buildEmptyReadingsMessage()
                  else
                    ...List.generate(todaysReadings.length, (index) {
                      final reading = todaysReadings[index];
                      return _buildReadingCard(reading, index)
                          .animate()
                          .fadeIn(
                              duration: AppAnimations.slow,
                              delay: (700 + index * 100).ms)
                          .slideY(begin: 0.3);
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyPlansTab() {
    final l10n = AppLocalizations.of(context);
    final activePlansAsync = ref.watch(activeReadingPlansProvider);

    return activePlansAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (activePlans) {
        if (activePlans.isEmpty) {
          return _buildEmptyState(
            icon: Icons.library_books_outlined,
            title: l10n.noActivePlans,
            subtitle: l10n.startReadingPlanToTrack,
            action: () => _tabController.animateTo(3),
            actionText: l10n.explorePlans,
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(left: 50, right: 50, top: 20, bottom: 20),
          itemCount: activePlans.length + (activePlans.length == 1 ? 1 : 0),
          itemBuilder: (context, index) {
            // Show reading plan card(s)
            if (index < activePlans.length) {
              final plan = activePlans[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPlanCard(plan, index, isActive: true)
                    .animate()
                    .fadeIn(
                        duration: AppAnimations.slow,
                        delay: (600 + index * 100).ms)
                    .slideY(begin: 0.3),
              );
            }

            // Show info message BELOW the reading plan card when there's exactly 1 active plan
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.secondaryText,
                    size: ResponsiveUtils.iconSize(context, 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.onlyOnePlanActive,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: ResponsiveUtils.fontSize(context, 13,
                            minSize: 11, maxSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: AppAnimations.slow, delay: 700.ms);
          },
        );
      },
    );
  }

  Widget _buildExplorePlansTab() {
    final allPlansAsync = ref.watch(allReadingPlansProvider);

    return allPlansAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (allPlans) {
        return ListView.builder(
          padding:
              const EdgeInsets.only(left: 50, right: 50, top: 20, bottom: 20),
          itemCount: allPlans.length,
          itemBuilder: (context, index) {
            final plan = allPlans[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPlanCard(plan, index, isActive: false)
                  .animate()
                  .fadeIn(
                      duration: AppAnimations.slow,
                      delay: (600 + index * 100).ms)
                  .slideY(begin: 0.3),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentPlanCard(ReadingPlan plan) {
    final l10n = AppLocalizations.of(context);
    final progressAsync = ref.watch(planProgressPercentageProvider(plan.id));
    final currentDayAsync = ref.watch(planCurrentDayProvider(plan.id));
    final streakAsync = ref.watch(planStreakProvider(plan.id));

    final progress =
        (plan.completedReadings / plan.totalReadings).clamp(0.0, 1.0);

    return DarkGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 18,
                            minSize: 16, maxSize: 20),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.category.getLocalizedName(context),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 14,
                            minSize: 12, maxSize: 16),
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Stats row - use Wrap for accessibility at large text scales
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: ResponsiveUtils.iconSize(context, 16),
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    plan.estimatedTimePerDay,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 14,
                          minSize: 12, maxSize: 16),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              currentDayAsync.when(
                data: (day) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: ResponsiveUtils.iconSize(context, 16),
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.dayNumber(day),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 14,
                            minSize: 12, maxSize: 16),
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              streakAsync.when(
                data: (streak) => streak > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: ResponsiveUtils.iconSize(context, 16),
                            color: Colors.orange.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streak day${streak > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 14,
                                  minSize: 12, maxSize: 16),
                              color: Colors.orange.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.progress,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                '${plan.completedReadings} / ${plan.totalReadings}',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            borderRadius: BorderRadius.circular(AppRadius.xs / 2),
          ),
          const SizedBox(height: AppSpacing.sm),
          progressAsync.when(
            data: (percentage) => Text(
              l10n.percentComplete(percentage.toStringAsFixed(1)),
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 12,
                    minSize: 10, maxSize: 14),
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow, delay: 500.ms);
  }

  Widget _buildReadingCard(DailyReading reading, int index) {
    // Check optimistic state first for instant UI feedback
    final isCompleted =
        _optimisticCompletions[reading.id] ?? reading.isCompleted;
    final l10n = AppLocalizations.of(context);

    final readingCard = Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _openChapterReader(context, reading),
        child: DarkGlassContainer(
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.mediumRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.2)
                          : AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.book,
                  color: isCompleted ? Colors.green : AppTheme.primaryColor,
                  size: ResponsiveUtils.iconSize(context, 24),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reading.title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 16,
                            minSize: 14, maxSize: 18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reading.description,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 14,
                            minSize: 12, maxSize: 16),
                        color: AppColors.secondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: ResponsiveUtils.iconSize(context, 14),
                          color: AppColors.tertiaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reading.estimatedTime,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 12,
                                minSize: 10, maxSize: 14),
                            color: AppColors.tertiaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleReadingComplete(reading),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smallRadius,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle_outlined,
                    color: AppColors.primaryText,
                    size: ResponsiveUtils.iconSize(context, 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return readingCard;
  }

  Widget _buildPlanCard(ReadingPlan plan, int index, {required bool isActive}) {
    final l10n = AppLocalizations.of(context);
    final progressPercentageAsync = plan.isStarted
        ? ref.watch(planProgressPercentageProvider(plan.id))
        : null;

    // Check if there's already an active plan (for Explore tab)
    final currentPlanAsync =
        !isActive ? ref.watch(currentReadingPlanProvider) : null;

    return DarkGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 18,
                            minSize: 16, maxSize: 20),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.category.getLocalizedName(context),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 14,
                            minSize: 12, maxSize: 16),
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            plan.description,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 14,
                  minSize: 12, maxSize: 16),
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Stats row - use Wrap for accessibility at large text scales
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _buildPlanStat(Icons.schedule, plan.estimatedTimePerDay),
              _buildPlanStat(Icons.calendar_today, plan.duration),
            ],
          ),
          if (plan.isStarted) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.progress,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  '${plan.completedReadings} / ${plan.totalReadings}',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value:
                  (plan.completedReadings / plan.totalReadings).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              borderRadius: BorderRadius.circular(AppRadius.xs / 2),
            ),
            if (progressPercentageAsync != null) ...[
              const SizedBox(height: AppSpacing.sm),
              progressPercentageAsync.when(
                data: (percentage) => Text(
                  l10n.percentComplete(percentage.toStringAsFixed(1)),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 12,
                        minSize: 10, maxSize: 14),
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          // Conditionally disable "Start Plan" button if viewing from Explore tab and another plan is active
          if (currentPlanAsync != null)
            currentPlanAsync.when(
              loading: () => SizedBox(
                width: double.infinity,
                child: GlassButton(
                  text: l10n.startPlan,
                  height: 48,
                  onPressed: () => _handlePlanAction(plan),
                ),
              ),
              error: (_, __) => SizedBox(
                width: double.infinity,
                child: GlassButton(
                  text: l10n.startPlan,
                  height: 48,
                  onPressed: () => _handlePlanAction(plan),
                ),
              ),
              data: (currentPlan) {
                final hasActivePlan = currentPlan != null;
                return SizedBox(
                  width: double.infinity,
                  child: Tooltip(
                    message: hasActivePlan
                        ? 'Reset your current plan before starting a new one'
                        : '',
                    child: GlassButton(
                      text: l10n.startPlan,
                      height: 48,
                      onPressed:
                          hasActivePlan ? null : () => _handlePlanAction(plan),
                    ),
                  ),
                );
              },
            )
          else
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    text:
                        plan.isStarted ? l10n.continueReading : l10n.startPlan,
                    height: 48,
                    onPressed: () => _handlePlanAction(plan),
                  ),
                ),
                if (plan.isStarted) ...[
                  const SizedBox(width: AppSpacing.md),
                  GestureDetector(
                    onTap: () => _showResetConfirmation(plan),
                    child: Container(
                      height: 48,
                      padding: AppSpacing.horizontalLg,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: AppRadius.mediumRadius,
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.restart_alt,
                        color: AppColors.primaryText,
                        size: ResponsiveUtils.iconSize(context, 20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPlanStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ResponsiveUtils.iconSize(context, 16),
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 14,
                  minSize: 12, maxSize: 16),
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? action,
    String? actionText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClearGlassCard(
              padding: AppSpacing.screenPaddingLarge,
              child: Icon(
                icon,
                size: ResponsiveUtils.iconSize(context, 48),
                color: AppColors.tertiaryText,
              ),
            )
                .animate()
                .fadeIn(duration: AppAnimations.slow)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 20,
                    minSize: 18, maxSize: 24),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
                duration: AppAnimations.slow, delay: AppAnimations.fast),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 14,
                    minSize: 12, maxSize: 16),
                color: AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
                duration: AppAnimations.slow, delay: AppAnimations.normal),
            if (action != null && actionText != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              GlassButton(
                text: actionText,
                onPressed: action,
              ).animate().fadeIn(
                  duration: AppAnimations.slow, delay: AppAnimations.slow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveUtils.iconSize(context, 48),
              color: Colors.red,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.oopsSomethingWrong,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 20,
                    minSize: 18, maxSize: 24),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 14,
                    minSize: 12, maxSize: 16),
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReadingsMessage() {
    final l10n = AppLocalizations.of(context);
    return DarkGlassContainer(
      child: Column(
        children: [
          Icon(
            Icons.celebration,
            size: ResponsiveUtils.iconSize(context, 48),
            color: AppColors.tertiaryText,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.allCaughtUp,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 18,
                  minSize: 16, maxSize: 20),
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.noReadingsToday,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 14,
                  minSize: 12, maxSize: 16),
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the chapter reader for a specific daily reading
  void _openChapterReader(BuildContext context, DailyReading reading) {
    final l10n = AppLocalizations.of(context);
    try {
      final parsed = ReadingReferenceParser.fromDailyReading(
        reading.book,
        reading.chapters,
      );

      NavigationService.goToChapterReading(
        book: parsed.book,
        startChapter: parsed.startChapter,
        endChapter: parsed.endChapter,
        readingId: reading.id,
      );
    } catch (e) {
      AppSnackBar.showError(
        context,
        message: l10n.errorWithMessage(e.toString()),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _toggleReadingComplete(DailyReading reading) async {
    final l10n = AppLocalizations.of(context);
    // Get the current completion state (check optimistic state first)
    final currentlyCompleted =
        _optimisticCompletions[reading.id] ?? reading.isCompleted;
    final newCompletedState = !currentlyCompleted;

    // Step 1: Optimistic UI update (instant feedback)
    setState(() {
      _optimisticCompletions[reading.id] = newCompletedState;
    });

    // Step 2: Execute database operation in background
    final progressService = ref.read(readingPlanProgressServiceProvider);

    try {
      if (currentlyCompleted) {
        await progressService.markDayIncomplete(reading.id);
      } else {
        await progressService.markDayComplete(reading.id);
      }

      // Step 3: Success - clear optimistic state and refresh providers
      setState(() {
        _optimisticCompletions.remove(reading.id);
      });

      ref.invalidate(currentReadingPlanProvider);
      ref.invalidate(todaysReadingsProvider(reading.planId));
      ref.invalidate(planProgressPercentageProvider(reading.planId));
      ref.invalidate(planStreakProvider(reading.planId));
      // Use refresh() instead of invalidate() to force immediate update
      // even when Progress tab isn't visible
      ref.refresh(planHeatmapDataProvider(reading.planId));
      ref.invalidate(planCompletionStatsProvider(reading.planId));
      ref.invalidate(planEstimatedCompletionDateProvider(reading.planId));
      ref.invalidate(activeReadingPlansProvider);
      ref.invalidate(allReadingPlansProvider);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: currentlyCompleted
              ? l10n.markedAsIncomplete
              : l10n.greatJobKeepUp,
          icon: currentlyCompleted
              ? Icons.remove_circle_outline
              : Icons.check_circle,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Step 4: Error - revert optimistic state
      setState(() {
        _optimisticCompletions[reading.id] = currentlyCompleted;
      });

      if (mounted) {
        AppSnackBar.showError(
          context,
          message: l10n.errorWithMessage(e.toString()),
        );
      }
    }
  }

  Future<void> _handlePlanAction(ReadingPlan plan) async {
    final l10n = AppLocalizations.of(context);
    if (plan.isStarted) {
      // Navigate to today's tab
      _tabController.animateTo(0);
    } else {
      // Start the plan
      final planService = ref.read(readingPlanServiceProvider);
      final progressService = ref.read(readingPlanProgressServiceProvider);

      try {
        await planService.startPlan(plan.id);

        // Check if ANY readings exist for this plan (not just today's)
        // This prevents overwriting curated plans that were loaded from JSON
        final allReadings = await planService.getReadingsForPlan(plan.id);
        if (allReadings.isEmpty) {
          // No readings exist - generate them based on plan category
          // Get user's language for localized titles and descriptions
          // ignore: use_build_context_synchronously
          final language = Localizations.localeOf(context).languageCode;
          await progressService.generateReadingsForPlan(
            plan.id,
            plan.category,
            plan.totalReadings,
            language: language,
          );
        }

        // Refresh providers
        ref.invalidate(currentReadingPlanProvider);
        ref.invalidate(activeReadingPlansProvider);
        ref.invalidate(allReadingPlansProvider);

        // Navigate to today's tab
        _tabController.animateTo(0);

        if (mounted) {
          AppSnackBar.show(
            context,
            message: l10n.readingPlanStarted,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            message: l10n.errorStartingPlan(e.toString()),
          );
        }
      }
    }
  }

  Future<void> _showResetConfirmation(ReadingPlan plan) async {
    final l10n = AppLocalizations.of(context);
    // Fetch current streak to show in confirmation
    final progressService = ref.read(readingPlanProgressServiceProvider);
    int streak = 0;
    try {
      streak = await progressService.getStreak(plan.id);
    } catch (e) {
      // If we can't get streak, proceed without it
    }

    if (!mounted) return;

    final confirmed = await showBlurredDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FrostedGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: ResponsiveUtils.iconSize(context, 48),
                color: Colors.orange,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.resetReadingPlan,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 20,
                      minSize: 18, maxSize: 24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.resetPlanConfirmation(plan.title),
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mediumRadius,
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ This will permanently delete:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveUtils.fontSize(context, 14,
                            minSize: 12, maxSize: 16),
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ${plan.completedReadings} completed reading${plan.completedReadings != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 13,
                            minSize: 11, maxSize: 15),
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (streak > 0)
                      Text(
                        '• Your $streak-day streak 🔥',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 13,
                              minSize: 11, maxSize: 15),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    Text(
                      '• All progress history',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 13,
                            minSize: 11, maxSize: 15),
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: l10n.cancel,
                      height: 48,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GlassButton(
                      text: l10n.reset,
                      height: 48,
                      borderColor: Colors.red.withValues(alpha: 0.8),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final progressService = ref.read(readingPlanProgressServiceProvider);

      try {
        await progressService.resetPlan(plan.id);

        // Refresh all providers
        ref.invalidate(currentReadingPlanProvider);
        ref.invalidate(activeReadingPlansProvider);
        ref.invalidate(allReadingPlansProvider);
        ref.invalidate(planProgressPercentageProvider(plan.id));
        ref.invalidate(planStreakProvider(plan.id));
        // Use refresh() to immediately update heatmap even if Progress tab isn't visible
        ref.refresh(planHeatmapDataProvider(plan.id));
        ref.invalidate(planCompletionStatsProvider(plan.id));
        ref.invalidate(planEstimatedCompletionDateProvider(plan.id));

        if (mounted) {
          AppSnackBar.show(
            context,
            message: l10n.readingPlanReset,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            message: l10n.errorResettingPlan(e.toString()),
          );
        }
      }
    }
  }
}
