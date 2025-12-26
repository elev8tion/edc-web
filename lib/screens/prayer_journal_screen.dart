import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../utils/responsive_utils.dart';
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
  ConsumerState<PrayerJournalScreen> createState() => _PrayerJournalScreenState();
}

class _PrayerJournalScreenState extends ConsumerState<PrayerJournalScreen> with TickerProviderStateMixin {
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
          GlassFab(
            key: _addPrayerFabKey,
            onPressed: _showAddPrayerDialog,
            icon: Icons.add,
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
        padding: const EdgeInsets.all(4),
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
            fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
          ),
          tabs: [
            Tab(text: useShortLabel ? l10n.activeShort : l10n.active),
            Tab(text: useShortLabel ? l10n.answeredShort : l10n.answered),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppAnimations.slow, delay: AppAnimations.normal);
  }

  Widget _buildCategoryFilter() {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.filterByCategory,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 13, minSize: 11, maxSize: 15),
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
                          ref.read(selectedCategoryFilterProvider.notifier).state = null;
                        },
                        child: Text(
                          l10n.clearFilter,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: ResponsiveUtils.scaleSize(context, 38, minScale: 0.9, maxScale: 1.4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  clipBehavior: Clip.none,
                  children: [
                    // "All" filter chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(selectedCategoryFilterProvider.notifier).state = null;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: selectedCategory == null
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withValues(alpha: 0.4),
                                      AppTheme.primaryColor.withValues(alpha: 0.2),
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
                                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                                size: ResponsiveUtils.iconSize(context, 16),
                                color: selectedCategory == null
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.all,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.fontSize(context, 13, minSize: 11, maxSize: 15),
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
                    ...categories.map((category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryFilterChip(
                        category: category,
                        isSelected: selectedCategory == category.id,
                        onTap: () {
                          if (selectedCategory == category.id) {
                            ref.read(selectedCategoryFilterProvider.notifier).state = null;
                          } else {
                            ref.read(selectedCategoryFilterProvider.notifier).state = category.id;
                          }
                        },
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppAnimations.slow, delay: (400).ms);
      },
      loading: () => Container(
        margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
        height: ResponsiveUtils.scaleSize(context, 36, minScale: 0.9, maxScale: 1.2),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
          padding: const EdgeInsets.only(left: 50, right: 50, top: 20, bottom: 100),
          itemCount: prayers.length,
          itemBuilder: (context, index) {
            final prayer = prayers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPrayerCard(prayer, index).animate()
                  .fadeIn(duration: AppAnimations.slow, delay: (600 + index * 100).ms)
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
            Icon(Icons.error_outline, size: ResponsiveUtils.iconSize(context, 48), color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.unableToLoadPrayers,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryText),
            ),
            const SizedBox(height: 8),
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
          padding: const EdgeInsets.only(left: 50, right: 50, top: 20, bottom: 100),
          itemCount: prayers.length,
          itemBuilder: (context, index) {
            final prayer = prayers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPrayerCard(prayer, index).animate()
                  .fadeIn(duration: AppAnimations.slow, delay: (600 + index * 100).ms)
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
            Icon(Icons.error_outline, size: ResponsiveUtils.iconSize(context, 48), color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.unableToLoadAnsweredPrayers,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryText),
            ),
            const SizedBox(height: 8),
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
            ).animate().fadeIn(duration: AppAnimations.slow).scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: AppAnimations.slow, delay: AppAnimations.fast),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                color: AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: AppAnimations.slow, delay: AppAnimations.normal),
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
                              orElse: () => categories.isNotEmpty ? categories.first : _getDefaultCategory(),
                            );
                            return CategoryBadge(
                              text: _getLocalizedCategoryName(category.name),
                              badgeColor: category.color,
                              icon: category.icon,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              fontSize: ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 13),
                            );
                          },
                          loading: () => CategoryBadge(
                            text: l10n.loading,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            fontSize: ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 13),
                          ),
                          error: (_, __) => CategoryBadge(
                            text: l10n.general,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            fontSize: ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 13),
                          ),
                        ),
                      ),
                      if (prayer.isAnswered) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: AppRadius.smallRadius,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: ResponsiveUtils.iconSize(context, 16),
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
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.more_vert,
                        size: ResponsiveUtils.iconSize(context, 18),
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
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.more_vert,
                        size: ResponsiveUtils.iconSize(context, 18),
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              prayer.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              prayer.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            if (prayer.isAnswered && prayer.answerDescription != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                        fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prayer.answerDescription!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 13, minSize: 11, maxSize: 15),
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
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
                        size: ResponsiveUtils.iconSize(context, 14),
                        color: AppColors.tertiaryText,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatDate(prayer.dateCreated),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
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
                          size: ResponsiveUtils.iconSize(context, 14),
                          color: Colors.green.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.answered_date(_formatDate(prayer.dateAnswered!)),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
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
                                fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            Text(
                              l10n.title,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              onChanged: (value) => title = value,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: l10n.whatArePrayingFor,
                                hintStyle: TextStyle(color: AppColors.tertiaryText),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.mediumRadius,
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.category,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (categories.isNotEmpty)
                              SizedBox(
                                height: ResponsiveUtils.scaleSize(context, 40, minScale: 0.9, maxScale: 1.2),
                                child: BlurDropdown(
                                  value: _getLocalizedCategoryName(categories.firstWhere((c) => c.id == selectedCategoryId, orElse: () => categories.first).name),
                                  items: categories.map((category) => _getLocalizedCategoryName(category.name)).toList(),
                                  hint: l10n.selectCategory,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        // Find category by matching localized name back to English
                                        final matchedCategory = categories.firstWhere(
                                          (c) => _getLocalizedCategoryName(c.name) == value,
                                          orElse: () => categories.first,
                                        );
                                        selectedCategoryId = matchedCategory.id;
                                      });
                                    }
                                  },
                                ),
                              ),

                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.description,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        onChanged: (value) => description = value,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: l10n.shareMoreDetails,
                          hintStyle: TextStyle(color: AppColors.tertiaryText),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.mediumRadius,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                            const SizedBox(height: AppSpacing.xxl),
                            Row(
                              children: [
                                Expanded(
                                  child: GlassButton(
                                    text: l10n.cancel,
                                    height: 48,
                                    onPressed: () => NavigationService.pop(),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: GlassButton(
                                    text: useShortLabel ? l10n.addPrayerButtonShort : l10n.addPrayerButton,
                                    height: 48,
                                    onPressed: () {
                                      if (title.isNotEmpty && description.isNotEmpty && selectedCategoryId != null) {
                                        _addPrayer(title, description, selectedCategoryId!);
                                        NavigationService.pop();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
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

  Future<void> _addPrayer(String title, String description, String categoryId) async {
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
                            fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Text(
                          l10n.howDidGodAnswer,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
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

                        const SizedBox(height: AppSpacing.xxl),
                        Row(
                          children: [
                            Expanded(
                              child: GlassButton(
                                text: l10n.cancel,
                                height: 48,
                                onPressed: () => NavigationService.pop(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: GlassButton(
                                text: l10n.answered,
                                height: 48,
                                onPressed: () async {
                                  if (answerDescription.isNotEmpty) {
                                    final actions = ref.read(prayerActionsProvider);

                                    try {
                                      await actions.markAnswered(prayer.id, answerDescription);
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
                                        message: l10n.errorWithMessage(e.toString()),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                size: ResponsiveUtils.iconSize(context, 48),
                color: Colors.orange,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.deletePrayer,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.deletePrayerConfirmation(prayer.title),
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                  color: AppColors.secondaryText,
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
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
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
