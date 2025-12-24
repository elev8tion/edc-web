import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_scalify/flutter_scalify.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_card.dart';
import '../components/dark_glass_container.dart';
import '../components/clear_glass_card.dart';
import '../components/glass_button.dart';
import '../components/category_badge.dart';
import '../components/blur_dropdown.dart';
import '../components/blur_popup_menu.dart';
import '../components/category_filter_chip.dart';
import '../components/glass_fab.dart';
import '../components/standard_screen_header.dart';
import '../core/widgets/app_snackbar.dart';
import '../core/services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_gradients.dart';
import '../core/navigation/navigation_service.dart';
import '../core/models/prayer_request.dart';
import '../core/models/prayer_category.dart';
import '../core/providers/prayer_providers.dart';
import '../core/providers/category_providers.dart';
import '../core/providers/app_providers.dart';
import '../core/widgets/skeleton_loader.dart';
import '../utils/blur_dialog_utils.dart';
import '../services/prayer_share_service.dart';
import '../l10n/app_localizations.dart';
import '../core/utils/simple_coach_mark.dart';

class PrayerJournalScreen extends ConsumerStatefulWidget {
  const PrayerJournalScreen({super.key});

  @override
  ConsumerState<PrayerJournalScreen> createState() =>
      _PrayerJournalScreenState();
}

class _PrayerJournalScreenState extends ConsumerState<PrayerJournalScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _prayerController = TextEditingController();
  final GlobalKey _addPrayerFabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _showPrayerTutorialIfNeeded();
  }

  Future<void> _showPrayerTutorialIfNeeded() async {
    final prefsService = await PreferencesService.getInstance();

    // Check if tutorial already shown
    if (prefsService.hasPrayerTutorialShown()) {
      return;
    }

    // Wait for UI to build and settle
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    // Show tutorial
    SimpleCoachMark(
      targets: [
        CoachTarget(
          key: _addPrayerFabKey,
          title: l10n.tutorialPrayerTitle,
          description: l10n.tutorialPrayerDescription,
          contentPosition: ContentPosition.top,
          shape: HighlightShape.circle,
          padding: 8,
          semanticLabel: l10n.tutorialPrayerTitle,
        ),
      ],
      config: CoachMarkConfig(
        skipText: l10n.tutorialSkip,
        nextText: l10n.tutorialNext,
        previousText: l10n.tutorialPrevious,
      ),
      onFinish: () {
        prefsService.setPrayerTutorialShown();
      },
      onSkip: () {
        prefsService.setPrayerTutorialShown();
      },
    ).show(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _prayerController.dispose();
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
                    _buildCategoryFilter(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildActivePrayers(),
                          _buildAnsweredPrayers(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppWidthLimiter(
              maxWidth: 1200,
              child: GlassFab(
                key: _addPrayerFabKey,
                onPressed: _showAddPrayerDialog,
                icon: Icons.add,
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
      title: l10n.prayerJournal,
      subtitle: l10n.bringRequestsToGod,
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);
    final textSize = ref.watch(textSizeProvider);
    final useShortLabel = textSize >= 1.3;

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
            fontSize: 14.fz,
          ),
          tabs: [
            Tab(text: useShortLabel ? l10n.activeShort : l10n.active),
            Tab(text: useShortLabel ? l10n.answeredShort : l10n.answered),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.slow, delay: AppAnimations.normal);
  }

  Widget _buildCategoryFilter() {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return Container(
          margin:
              EdgeInsets.only(top: AppSpacing.md.s, bottom: AppSpacing.md.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.s),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.filterByCategory,
                        style: TextStyle(
                          fontSize: 13.fz,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Visibility(
                      visible: selectedCategory != null,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: TextButton(
                        onPressed: () {
                          ref
                              .read(selectedCategoryFilterProvider.notifier)
                              .state = null;
                        },
                        child: Text(
                          l10n.clearFilter,
                          style: TextStyle(
                            fontSize: 12.fz,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              8.sbh,
              SizedBox(
                height: 38.s,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.s),
                  clipBehavior: Clip.none,
                  children: [
                    // "All" filter chip
                    Padding(
                      padding: EdgeInsets.only(right: 8.s),
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(selectedCategoryFilterProvider.notifier)
                              .state = null;
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.s, vertical: 4.s),
                          decoration: BoxDecoration(
                            gradient: selectedCategory == null
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor
                                          .withValues(alpha: 0.4),
                                      AppTheme.primaryColor
                                          .withValues(alpha: 0.2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : AppGradients.glassMedium,
                            borderRadius: AppRadius.largeCardRadius,
                            border: Border.all(
                              color: selectedCategory == null
                                  ? AppTheme.primaryColor
                                  : Colors.white.withValues(alpha: 0.2),
                              width: selectedCategory == null ? 2 : 1,
                            ),
                            boxShadow: selectedCategory == null
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grid_view,
                                size: 16.iz,
                                color: selectedCategory == null
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                              6.sbw,
                              Text(
                                l10n.all,
                                style: TextStyle(
                                  fontSize: 13.fz,
                                  fontWeight: selectedCategory == null
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selectedCategory == null
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Category chips
                    ...categories
                        .map((category) => Padding(
                              padding: EdgeInsets.only(right: 8.s),
                              child: CategoryFilterChip(
                                category: category,
                                isSelected: selectedCategory == category.id,
                                onTap: () {
                                  if (selectedCategory == category.id) {
                                    ref
                                        .read(selectedCategoryFilterProvider
                                            .notifier)
                                        .state = null;
                                  } else {
                                    ref
                                        .read(selectedCategoryFilterProvider
                                            .notifier)
                                        .state = category.id;
                                  }
                                },
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppAnimations.slow, delay: (400).ms);
      },
      loading: () => Container(
        margin: EdgeInsets.only(top: AppSpacing.md.s, bottom: AppSpacing.md.s),
        height: 36.s,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.s),
          children: List.generate(
            3,
            (i) => const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SkeletonChip(),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActivePrayers() {
    final l10n = AppLocalizations.of(context);
    final activePrayersAsync = ref.watch(activePrayersProvider);

    return activePrayersAsync.when(
      data: (prayers) {
        if (prayers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_outline,
            title: l10n.noActivePrayers,
            subtitle: l10n.startPrayerJourney,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
              left: 50.s, right: 50.s, top: 20.s, bottom: 100.s),
          itemCount: prayers.length,
          itemBuilder: (context, index) {
            final prayer = prayers[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 16.s),
              child: _buildPrayerCard(prayer, index)
                  .animate()
                  .fadeIn(
                      duration: AppAnimations.slow,
                      delay: (600 + index * 100).ms)
                  .slideY(begin: 0.3),
            );
          },
        );
      },
      loading: () => ListView.builder(
        padding: AppSpacing.screenPadding,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.iz, color: Colors.red.shade300),
            16.sbh,
            Text(
              l10n.unableToLoadPrayers,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.primaryText),
            ),
            8.sbh,
            TextButton(
              onPressed: () => ref.refresh(activePrayersProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnsweredPrayers() {
    final l10n = AppLocalizations.of(context);
    final answeredPrayersAsync = ref.watch(answeredPrayersProvider);

    return answeredPrayersAsync.when(
      data: (prayers) {
        if (prayers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: l10n.noAnsweredPrayersYet,
            subtitle: l10n.markPrayersAnswered,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
              left: 50.s, right: 50.s, top: 20.s, bottom: 100.s),
          itemCount: prayers.length,
          itemBuilder: (context, index) {
            final prayer = prayers[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 16.s),
              child: _buildPrayerCard(prayer, index)
                  .animate()
                  .fadeIn(
                      duration: AppAnimations.slow,
                      delay: (600 + index * 100).ms)
                  .slideY(begin: 0.3),
            );
          },
        );
      },
      loading: () => ListView.builder(
        padding: AppSpacing.screenPadding,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.iz, color: Colors.red.shade300),
            16.sbh,
            Text(
              l10n.unableToLoadAnsweredPrayers,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.primaryText),
            ),
            8.sbh,
            TextButton(
              onPressed: () => ref.refresh(answeredPrayersProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
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
                fontSize: 14.fz,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
                duration: AppAnimations.slow, delay: AppAnimations.normal),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(PrayerRequest prayer, int index) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    final cardWidget = DarkGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category badge and answered icon at LEFT
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: categoriesAsync.when(
                        data: (categories) {
                          final category = categories.firstWhere(
                            (c) => c.id == prayer.categoryId,
                            orElse: () => categories.isNotEmpty
                                ? categories.first
                                : _getDefaultCategory(),
                          );
                          return CategoryBadge(
                            text: _getLocalizedCategoryName(category.name),
                            badgeColor: category.color,
                            icon: category.icon,
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.s, vertical: 6.s),
                            fontSize: 11.fz,
                          );
                        },
                        loading: () => CategoryBadge(
                          text: l10n.loading,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.s, vertical: 6.s),
                          fontSize: 11.fz,
                        ),
                        error: (_, __) => CategoryBadge(
                          text: l10n.general,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.s, vertical: 6.s),
                          fontSize: 11.fz,
                        ),
                      ),
                    ),
                    if (prayer.isAnswered) ...[
                      8.sbw,
                      Container(
                        padding: EdgeInsets.all(6.s),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: AppRadius.smallRadius,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 16.iz,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Menu button at far RIGHT
              if (prayer.isAnswered)
                BlurPopupMenu(
                  items: [
                    BlurPopupMenuItem(
                      value: 'share',
                      icon: Icons.share,
                      label: l10n.share,
                    ),
                    BlurPopupMenuItem(
                      value: 'delete',
                      icon: Icons.delete,
                      label: l10n.delete,
                      iconColor: Colors.red,
                      textColor: Colors.red,
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'share') {
                      _sharePrayer(prayer);
                    } else if (value == 'delete') {
                      _deletePrayer(prayer);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.s),
                    child: Icon(
                      Icons.more_vert,
                      size: 18.iz,
                      color: AppColors.primaryText,
                    ),
                  ),
                )
              else
                BlurPopupMenu(
                  items: [
                    BlurPopupMenuItem(
                      value: 'mark_answered',
                      icon: Icons.check,
                      label: l10n.answered,
                    ),
                    BlurPopupMenuItem(
                      value: 'share',
                      icon: Icons.share,
                      label: l10n.share,
                    ),
                    BlurPopupMenuItem(
                      value: 'delete',
                      icon: Icons.delete,
                      label: l10n.delete,
                      iconColor: Colors.red,
                      textColor: Colors.red,
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'mark_answered') {
                      _markPrayerAnswered(prayer);
                    } else if (value == 'share') {
                      _sharePrayer(prayer);
                    } else if (value == 'delete') {
                      _deletePrayer(prayer);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.s),
                    child: Icon(
                      Icons.more_vert,
                      size: 18.iz,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.md.sbh,
          Text(
            prayer.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.fz,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          AppSpacing.sm.sbh,
          Text(
            prayer.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.fz,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          if (prayer.isAnswered && prayer.answerDescription != null) ...[
            AppSpacing.md.sbh,
            Container(
              padding: EdgeInsets.all(AppSpacing.md.s),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: AppRadius.smallRadius,
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.howGodAnswered,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.fz,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  4.sbh,
                  Text(
                    prayer.answerDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.fz,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
          AppSpacing.md.sbh,
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14.iz,
                      color: AppColors.tertiaryText,
                    ),
                    4.sbw,
                    Flexible(
                      child: Text(
                        _formatDate(prayer.dateCreated),
                        style: TextStyle(
                          fontSize: 12.fz,
                          color: AppColors.tertiaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                if (prayer.isAnswered && prayer.dateAnswered != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14.iz,
                        color: Colors.green.withValues(alpha: 0.8),
                      ),
                      4.sbw,
                      Flexible(
                        child: Text(
                          l10n.answered_date(_formatDate(prayer.dateAnswered!)),
                          style: TextStyle(
                            fontSize: 12.fz,
                            color: Colors.green.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return cardWidget;
  }

  void _showAddPrayerDialog() {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.read(activeCategoriesProvider);
    String? selectedCategoryId;
    String title = '';
    String description = '';

    // Get the first category or default to general
    categoriesAsync.whenData((categories) {
      if (categories.isNotEmpty) {
        selectedCategoryId = categories.first.id;
      }
    });

    showBlurredDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return categoriesAsync.when(
            data: (categories) {
              // Set default category if not set
              if (selectedCategoryId == null && categories.isNotEmpty) {
                selectedCategoryId = categories.first.id;
              }

              // Check text size for short label
              final textSize = ref.watch(textSizeProvider);
              final useShortLabel = textSize >= 1.3;

              return Dialog(
                backgroundColor: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: FrostedGlassCard(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.addPrayerRequest,
                                style: TextStyle(
                                  fontSize: 20.fz,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              AppSpacing.xl.sbh,
                              Text(
                                l10n.title,
                                style: TextStyle(
                                  fontSize: 14.fz,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              AppSpacing.sm.sbh,
                              TextField(
                                onChanged: (value) => title = value,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: l10n.whatArePrayingFor,
                                  hintStyle:
                                      TextStyle(color: AppColors.tertiaryText),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadius.mediumRadius,
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              AppSpacing.lg.sbh,
                              Text(
                                l10n.category,
                                style: TextStyle(
                                  fontSize: 14.fz,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              AppSpacing.sm.sbh,
                              if (categories.isNotEmpty)
                                SizedBox(
                                  height: 40.s,
                                  child: BlurDropdown(
                                    value: _getLocalizedCategoryName(categories
                                        .firstWhere(
                                            (c) => c.id == selectedCategoryId,
                                            orElse: () => categories.first)
                                        .name),
                                    items: categories
                                        .map((category) =>
                                            _getLocalizedCategoryName(
                                                category.name))
                                        .toList(),
                                    hint: l10n.selectCategory,
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          // Find category by matching localized name back to English
                                          final matchedCategory =
                                              categories.firstWhere(
                                            (c) =>
                                                _getLocalizedCategoryName(
                                                    c.name) ==
                                                value,
                                            orElse: () => categories.first,
                                          );
                                          selectedCategoryId =
                                              matchedCategory.id;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              AppSpacing.lg.sbh,
                              Text(
                                l10n.description,
                                style: TextStyle(
                                  fontSize: 14.fz,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              AppSpacing.sm.sbh,
                              TextField(
                                onChanged: (value) => description = value,
                                maxLines: 4,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: l10n.shareMoreDetails,
                                  hintStyle:
                                      TextStyle(color: AppColors.tertiaryText),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadius.mediumRadius,
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              AppSpacing.xxl.sbh,
                              Row(
                                children: [
                                  Expanded(
                                    child: GlassButton(
                                      text: l10n.cancel,
                                      height: 48,
                                      onPressed: () => NavigationService.pop(),
                                    ),
                                  ),
                                  AppSpacing.md.sbw,
                                  Expanded(
                                    child: GlassButton(
                                      text: useShortLabel
                                          ? l10n.addPrayerButtonShort
                                          : l10n.addPrayerButton,
                                      height: 48,
                                      onPressed: () {
                                        if (title.isNotEmpty &&
                                            description.isNotEmpty &&
                                            selectedCategoryId != null) {
                                          _addPrayer(title, description,
                                              selectedCategoryId!);
                                          NavigationService.pop();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.md.sbh,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Dialog(
              backgroundColor: Colors.transparent,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                  strokeWidth: 3,
                ),
              ),
            ),
            error: (_, __) => Dialog(
              backgroundColor: Colors.transparent,
              child: Center(child: Text(l10n.errorLoadingCategories)),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addPrayer(
      String title, String description, String categoryId) async {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(prayerActionsProvider);

    try {
      await actions.addPrayer(title, description, categoryId);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.prayerAddedSuccessfully,
          icon: Icons.check_circle,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          message: l10n.errorAddingPrayer(e.toString()),
        );
      }
    }
  }

  void _markPrayerAnswered(PrayerRequest prayer) {
    final l10n = AppLocalizations.of(context);

    showBlurredDialog(
      context: context,
      builder: (context) {
        String answerDescription = '';

        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: FrostedGlassCard(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.answered,
                          style: TextStyle(
                            fontSize: 20.fz,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        AppSpacing.xl.sbh,
                        Text(
                          l10n.howDidGodAnswer,
                          style: TextStyle(
                            fontSize: 14.fz,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        AppSpacing.sm.sbh,
                        TextField(
                          onChanged: (value) => answerDescription = value,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: l10n.shareHowGodAnswered,
                            hintStyle: TextStyle(color: AppColors.tertiaryText),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.mediumRadius,
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        AppSpacing.xxl.sbh,
                        Row(
                          children: [
                            Expanded(
                              child: GlassButton(
                                text: l10n.cancel,
                                height: 48,
                                onPressed: () => NavigationService.pop(),
                              ),
                            ),
                            AppSpacing.md.sbw,
                            Expanded(
                              child: GlassButton(
                                text: l10n.answered,
                                height: 48,
                                onPressed: () async {
                                  if (answerDescription.isNotEmpty) {
                                    final actions =
                                        ref.read(prayerActionsProvider);

                                    try {
                                      await actions.markAnswered(
                                          prayer.id, answerDescription);
                                      if (!context.mounted) return;

                                      NavigationService.pop();
                                      AppSnackBar.show(
                                        context,
                                        message: l10n.prayerMarkedAnswered,
                                        icon: Icons.check_circle,
                                        duration: const Duration(seconds: 2),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      AppSnackBar.showError(
                                        context,
                                        message:
                                            l10n.errorWithMessage(e.toString()),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.md.sbh,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sharePrayer(PrayerRequest prayer) async {
    final l10n = AppLocalizations.of(context);

    try {
      final databaseService = ref.read(databaseServiceProvider);
      final achievementService = ref.read(achievementServiceProvider);

      final shareService = PrayerShareService(
        databaseService: databaseService,
        achievementService: achievementService,
      );

      await shareService.sharePrayer(
        context: context,
        prayer: prayer,
      );

      // Invalidate shared count providers for achievements
      ref.invalidate(totalSharesCountProvider);

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.prayerSharedSuccessfully,
        icon: Icons.check_circle,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: l10n.unableToSharePrayer(e.toString()),
      );
    }
  }

  Future<void> _deletePrayer(PrayerRequest prayer) async {
    final l10n = AppLocalizations.of(context);

    // Show confirmation dialog
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
                l10n.deletePrayer,
                style: TextStyle(
                  fontSize: 20.fz,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              AppSpacing.md.sbh,
              Text(
                l10n.deletePrayerConfirmation(prayer.title),
                style: TextStyle(
                  fontSize: 14.fz,
                  color: AppColors.secondaryText,
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: AppRadius.largeCardRadius,
                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(true),
                          borderRadius: AppRadius.largeCardRadius,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: Text(
                              l10n.delete,
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.fz,
                              ),
                            ),
                          ),
                        ),
                      ),
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
      final actions = ref.read(prayerActionsProvider);

      try {
        await actions.deletePrayer(prayer.id);

        if (mounted) {
          AppSnackBar.show(
            context,
            message: l10n.prayerDeleted,
            icon: Icons.delete_outline,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            message: l10n.errorDeletingPrayer(e.toString()),
          );
        }
      }
    }
  }

  String _getLocalizedCategoryName(String englishName) {
    final l10n = AppLocalizations.of(context);
    switch (englishName.toLowerCase()) {
      case 'family':
        return l10n.family;
      case 'health':
        return l10n.health;
      case 'work':
        return l10n.work;
      case 'ministry':
        return l10n.ministry;
      case 'thanksgiving':
        return l10n.thanksgiving;
      case 'intercession':
        return l10n.intercession;
      case 'finances':
        return l10n.finances;
      case 'relationships':
        return l10n.relationships;
      case 'guidance':
        return l10n.guidance;
      case 'protection':
        return l10n.protection;
      case 'general':
        return l10n.general;
      case 'faith':
        return l10n.faith;
      case 'gratitude':
        return l10n.gratitude;
      case 'other':
        return l10n.other;
      default:
        return englishName; // Fallback to original name
    }
  }

  PrayerCategory _getDefaultCategory() {
    return PrayerCategory(
      id: 'cat_general',
      name: 'General',
      iconCodePoint: 0xe3fc, // Icons.more_horiz
      colorValue: 0xFF9E9E9E, // Colors.grey
      dateCreated: DateTime.now(),
    );
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return l10n.today;
    } else if (difference == 1) {
      return l10n.yesterday;
    } else if (difference < 7) {
      return l10n.daysAgo(difference);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
