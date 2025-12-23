import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scalify/flutter_scalify.dart';
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
              child: AppWidthLimiter(
                maxWidth: 1200,
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
        padding: EdgeInsets.all(4.s),
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
                14.fz,
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
          padding: EdgeInsets.symmetric(horizontal: 30.s, vertical: 20.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan header
              Text(
                currentPlan.title,
                style: TextStyle(
                  fontSize: 24.fz,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ).animate().fadeIn(duration: AppAnimations.slow),
              8.sbh,
              Text(
                l10n.yourProgressAndStatistics,
                style: TextStyle(
                  fontSize: 14.fz,
                  color: AppColors.secondaryText,
                ),
              ).animate().fadeIn(
                  duration: AppAnimations.slow, delay: AppAnimations.fast),
              AppSpacing.xxl.sbh,

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
              AppSpacing.xxl.sbh,

              // Calendar heatmap
              Text(
                'Reading Activity',
                style: TextStyle(
                  fontSize: 20.fz,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ).animate().fadeIn(duration: AppAnimations.slow, delay: 600.ms),
              AppSpacing.md.sbh,
              Text(
                'Days with completed readings in the last 90 days',
                style: TextStyle(
                  fontSize: 12.fz,
                  color: AppColors.secondaryText,
                ),
              ).animate().fadeIn(duration: AppAnimations.slow, delay: 700.ms),
              AppSpacing.lg.sbh,
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
                    padding: EdgeInsets.all(AppSpacing.lg.s),
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
              padding: EdgeInsets.symmetric(horizontal: 30.s, vertical: 20.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentPlanCard(currentPlan),
                  AppSpacing.xxl.sbh,
                  Text(
                    l10n.todaysReadings,
                    style: TextStyle(
                      fontSize: 20.fz,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ).animate().fadeIn(
                      duration: AppAnimations.slow, delay: AppAnimations.slow),
                  AppSpacing.lg.sbh,
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
              EdgeInsets.only(left: 50.s, right: 50.s, top: 20.s, bottom: 20.s),
          itemCount: activePlans.length + (activePlans.length == 1 ? 1 : 0),
          itemBuilder: (context, index) {
            // Show reading plan card(s)
            if (index < activePlans.length) {
              final plan = activePlans[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16.s),
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
              padding: EdgeInsets.only(top: 8.s),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.secondaryText,
                    size: 18.iz,
                  ),
                  12.sbw,
                  Expanded(
                    child: Text(
                      l10n.onlyOnePlanActive,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13.fz,
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
              EdgeInsets.only(left: 50.s, right: 50.s, top: 20.s, bottom: 20.s),
          itemCount: allPlans.length,
          itemBuilder: (context, index) {
            final plan = allPlans[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 16.s),
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
                        fontSize: 18.fz,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    4.sbh,
                    Text(
                      plan.category.getLocalizedName(context),
                      style: TextStyle(
                        fontSize: 14.fz,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.lg.sbh,
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
                    size: 16.iz,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  6.sbw,
                  Text(
                    plan.estimatedTimePerDay,
                    style: TextStyle(
                      fontSize: 14.fz,
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
                      size: 16.iz,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    6.sbw,
                    Text(
                      l10n.dayNumber(day),
                      style: TextStyle(
                        fontSize: 14.fz,
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
                            size: 16.iz,
                            color: Colors.orange.withValues(alpha: 0.9),
                          ),
                          4.sbw,
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
          AppSpacing.lg.sbh,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.progress,
                style: TextStyle(
                  fontSize: 14.fz,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                '${plan.completedReadings} / ${plan.totalReadings}',
                style: TextStyle(
                  fontSize: 14.fz,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          AppSpacing.sm.sbh,
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            borderRadius: (AppRadius.xs / 2).br,
          ),
          AppSpacing.sm.sbh,
          progressAsync.when(
            data: (percentage) => Text(
              l10n.percentComplete(percentage.toStringAsFixed(1)),
              style: TextStyle(
                fontSize: 12.fz,
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
      margin: EdgeInsets.only(bottom: 16.s),
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
                  size: 24.iz,
                ),
              ),
              AppSpacing.lg.sbw,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reading.title,
                      style: TextStyle(
                        fontSize: 16.fz,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.sbh,
                    Text(
                      reading.description,
                      style: TextStyle(
                        fontSize: 14.fz,
                        color: AppColors.secondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.sm.sbh,
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14.iz,
                          color: AppColors.tertiaryText,
                        ),
                        4.sbw,
                        Text(
                          reading.estimatedTime,
                          style: TextStyle(
                            fontSize: 12.fz,
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
                  padding: EdgeInsets.all(AppSpacing.sm.s),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smallRadius,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle_outlined,
                    color: AppColors.primaryText,
                    size: 20.iz,
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
                        fontSize: 18.fz,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.sbh,
                    Text(
                      plan.category.getLocalizedName(context),
                      style: TextStyle(
                        fontSize: 14.fz,
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
          AppSpacing.md.sbh,
          Text(
            plan.description,
            style: TextStyle(
              fontSize: 14.fz,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          AppSpacing.lg.sbh,
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
            AppSpacing.lg.sbh,
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
            AppSpacing.sm.sbh,
            LinearProgressIndicator(
              value:
                  (plan.completedReadings / plan.totalReadings).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              borderRadius: (AppRadius.xs / 2).br,
            ),
            if (progressPercentageAsync != null) ...[
              AppSpacing.sm.sbh,
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
          AppSpacing.lg.sbh,
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
                  AppSpacing.md.sbw,
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
                        size: 20.iz,
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
          size: 16.iz,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        6.sbw,
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.fz,
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
        padding: EdgeInsets.all(40.s),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClearGlassCard(
              padding: AppSpacing.screenPaddingLarge,
              child: Icon(
                icon,
                size: 48.iz,
                color: AppColors.tertiaryText,
              ),
            )
                .animate()
                .fadeIn(duration: AppAnimations.slow)
                .scale(begin: const Offset(0.8, 0.8)),
            AppSpacing.xxl.sbh,
            Text(
              title,
              style: TextStyle(
                fontSize: 20.fz,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
                duration: AppAnimations.slow, delay: AppAnimations.fast),
            AppSpacing.md.sbh,
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
              AppSpacing.xxl.sbh,
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
        padding: EdgeInsets.all(40.s),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.iz,
              color: Colors.red,
            ),
            AppSpacing.lg.sbh,
            Text(
              l10n.oopsSomethingWrong,
              style: TextStyle(
                fontSize: 20.fz,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.sm.sbh,
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
            size: 48.iz,
            color: AppColors.tertiaryText,
          ),
          AppSpacing.lg.sbh,
          Text(
            l10n.allCaughtUp,
            style: TextStyle(
              fontSize: 18.fz,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          AppSpacing.sm.sbh,
          Text(
            l10n.noReadingsToday,
            style: TextStyle(
              fontSize: 14.fz,
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
                size: 48.iz,
                color: Colors.orange,
              ),
              AppSpacing.lg.sbh,
              Text(
                l10n.resetReadingPlan,
                style: TextStyle(
                  fontSize: 20.fz,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              AppSpacing.md.sbh,
              Text(
                l10n.resetPlanConfirmation(plan.title),
                style: TextStyle(
                  fontSize: 14.fz,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.lg.sbh,
              Container(
                padding: EdgeInsets.all(12.s),
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
                        fontSize: 14.fz,
                        color: AppColors.primaryText,
                      ),
                    ),
                    8.sbh,
                    Text(
                      '• ${plan.completedReadings} completed reading${plan.completedReadings != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13.fz,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (streak > 0)
                      Text(
                        '• Your $streak-day streak 🔥',
                        style: TextStyle(
                          fontSize: 13.fz,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    Text(
                      '• All progress history',
                      style: TextStyle(
                        fontSize: 13.fz,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.md.sbh,
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.fz,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.xxl.sbh,
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: l10n.cancel,
                      height: 48,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  AppSpacing.md.sbw,
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
