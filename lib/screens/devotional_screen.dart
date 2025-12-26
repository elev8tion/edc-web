import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/clear_glass_card.dart';
import '../components/glass_button.dart';
import '../components/glassmorphic_fab_menu.dart';
import '../components/standard_screen_header.dart';
import '../components/dark_glass_container.dart';
import '../components/glass_card.dart';
import '../theme/app_theme.dart';
import '../core/providers/app_providers.dart';
import '../core/models/devotional.dart';
import '../utils/responsive_utils.dart';
import 'chapter_reading_screen.dart';
import '../services/devotional_share_service.dart';
import '../core/services/database_service.dart';
import '../core/services/achievement_service.dart';
import '../core/widgets/app_snackbar.dart';
import '../components/base_bottom_sheet.dart';
import '../core/navigation/navigation_service.dart';
import '../l10n/app_localizations.dart';

class DevotionalScreen extends ConsumerStatefulWidget {
  const DevotionalScreen({super.key});

  @override
  ConsumerState<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends ConsumerState<DevotionalScreen> {
  int _currentDay = 0;
  bool _isInitialized = false;
  late DevotionalShareService _devotionalShareService;

  @override
  void initState() {
    super.initState();
    final databaseService = DatabaseService();
    _devotionalShareService = DevotionalShareService(
      databaseService: databaseService,
      achievementService: AchievementService(databaseService),
    );
  }

  void _initializeCurrentDay(List<Devotional> devotionals) {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Find today's devotional or the most recent one available
    int todayIndex = devotionals.indexWhere((d) => d.date == todayString);

    if (todayIndex == -1) {
      // Today's devotional not found, find the most recent one that's not in the future
      todayIndex = devotionals.lastIndexWhere((d) {
        final devotionalDate = DateTime.parse(d.date);
        return devotionalDate.isBefore(today) ||
            devotionalDate.isAtSameMomentAs(today);
      });
    }

    // If still not found (all devotionals are in the future), show the first one
    if (todayIndex == -1) {
      todayIndex = 0;
    }

    setState(() {
      _currentDay = todayIndex;
      _isInitialized = true;
    });
  }

  void _showDevotionalOptions() {
    final devotionalsAsync = ref.read(allDevotionalsProvider);

    devotionalsAsync.whenData((devotionals) {
      if (devotionals.isEmpty || _currentDay >= devotionals.length) return;
      final currentDevotional = devotionals[_currentDay];

      final l10n = AppLocalizations.of(context);
      showCustomBottomSheet(
        context: context,
        title: l10n.devotionalOptions,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: _buildSheetIcon(Icons.share),
                title: Text(l10n.shareDevotional,
                    style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  NavigationService.pop();
                  await _shareDevotional(currentDevotional);
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _shareDevotional(Devotional devotional) async {
    try {
      await _devotionalShareService.shareDevotional(
        context: context,
        devotional: devotional,
        showFullReflection: false,
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      AppSnackBar.show(
        context,
        message: l10n.devotionalShared,
        icon: Icons.share,
        iconColor: AppTheme.goldColor,
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      AppSnackBar.showError(
        context,
        message: l10n.unableToShareDevotional(e.toString()),
      );
    }
  }

  Widget _buildSheetIcon(IconData icon, {Color? iconColor}) {
    final baseColor = iconColor ?? AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withValues(alpha: 0.24),
            baseColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(
          color: baseColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: baseColor,
        size: ResponsiveUtils.iconSize(context, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devotionalsAsync = ref.watch(allDevotionalsProvider);
    final streakAsync = ref.watch(devotionalStreakProvider);
    final totalCompletedAsync = ref.watch(totalDevotionalsCompletedProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: devotionalsAsync.when(
              data: (devotionals) {
                if (devotionals.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(
                        top: AppSpacing.xl), // Top padding
                    child: Column(
                      children: [
                        _buildHeader(streakAsync, totalCompletedAsync, null),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildEmptyState(),
                      ],
                    ),
                  );
                }

                // Initialize current day to first uncompleted or last completed
                if (!_isInitialized && devotionals.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _initializeCurrentDay(devotionals);
                  });
                }

                // Ensure current day is within bounds
                if (_currentDay >= devotionals.length) {
                  _currentDay = devotionals.length - 1;
                }

                final currentDevotional = devotionals[_currentDay];

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xl,
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    bottom: AppSpacing.xxl *
                        2, // Add substantial bottom padding to prevent overflow
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                          streakAsync, totalCompletedAsync, currentDevotional),
                      const SizedBox(height: AppSpacing.xxl),

                      // Devotional Title Card
                      _buildTitleCard(currentDevotional),
                      const SizedBox(height: AppSpacing.xl),

                      // 1. Opening Scripture
                      _buildOpeningScripture(currentDevotional),
                      _buildSectionDivider(),

                      // 2. Key Verse Spotlight
                      _buildKeyVerse(currentDevotional),
                      _buildSectionDivider(),

                      // 3. Reflection
                      _buildReflection(currentDevotional),
                      _buildSectionDivider(),

                      // 4. Life Application
                      _buildLifeApplication(currentDevotional),
                      _buildSectionDivider(),

                      // 5. Prayer
                      _buildPrayer(currentDevotional),
                      _buildSectionDivider(),

                      // 6. Action Step (with checkbox)
                      _buildActionStep(currentDevotional),
                      _buildSectionDivider(),

                      // 7. Extended
                      _buildGoingDeeper(currentDevotional),
                      _buildSectionDivider(),

                      // 8. Reading Time
                      _buildReadingTime(currentDevotional),
                      const SizedBox(height: AppSpacing.xl),

                      // Completion Button
                      _buildCompletionButton(currentDevotional),
                      const SizedBox(height: AppSpacing.xl),

                      // Navigation Buttons
                      _buildNavigationButtons(devotionals.length, devotionals),
                      const SizedBox(height: AppSpacing.xxl),

                      // Progress Indicator
                      _buildProgressIndicator(devotionals),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                );
              },
              loading: () => SingleChildScrollView(
                padding:
                    const EdgeInsets.only(top: AppSpacing.xl), // Top padding
                child: Column(
                  children: [
                    _buildHeader(streakAsync, totalCompletedAsync, null),
                    const SizedBox(height: AppSpacing.xxl),
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => SingleChildScrollView(
                padding:
                    const EdgeInsets.only(top: AppSpacing.xl), // Top padding
                child: Column(
                  children: [
                    _buildHeader(streakAsync, totalCompletedAsync, null),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildErrorState(error),
                  ],
                ),
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

  Widget _buildHeader(
    AsyncValue<int> streakAsync,
    AsyncValue<int> totalCompletedAsync,
    Devotional? currentDevotional,
  ) {
    final l10n = AppLocalizations.of(context);
    return StandardScreenHeader(
      title: l10n.dailyDevotional,
      subtitle: '', // Not used because we provide customSubtitle
      showFAB: false, // FAB is positioned separately
      trailingWidget: GlassContainer(
        borderRadius: AppRadius.md,
        blurStrength: 15.0,
        gradientColors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
        padding: EdgeInsets.zero,
        enableNoise: true,
        enableLightSimulation: true,
        border: Border.all(
          color: AppTheme.goldColor,
          width: 1.0,
        ),
        child: IconButton(
          icon: Icon(Icons.more_vert,
              color: Colors.white, size: ResponsiveUtils.iconSize(context, 24)),
          onPressed: _showDevotionalOptions,
          tooltip: l10n.devotionalOptions,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
        ),
      ),
      customSubtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          streakAsync.when(
            data: (streak) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: streak > 0
                      ? Colors.orange
                      : Colors.white.withValues(alpha: 0.5),
                  size: ResponsiveUtils.iconSize(context, 14),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.dayStreakCount(streak),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 11,
                          minSize: 10, maxSize: 13),
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 2),
          totalCompletedAsync.when(
            data: (total) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: total > 0
                      ? Colors.green
                      : Colors.white.withValues(alpha: 0.5),
                  size: ResponsiveUtils.iconSize(context, 14),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.completed(total),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 11,
                          minSize: 10, maxSize: 13),
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: AppAnimations.slow, delay: AppAnimations.fast),
    );
  }

  // Section Divider (gradient line like bible browser)
  Widget _buildSectionDivider() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Title Card
  Widget _buildTitleCard(Devotional devotional) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AutoSizeText(
        devotional.title,
        style: TextStyle(
          fontSize:
              ResponsiveUtils.fontSize(context, 24, minSize: 20, maxSize: 28),
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
          height: 1.3,
        ),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        minFontSize: 16,
        maxLines: 3,
        stepGranularity: 0.5,
        wrapWords: true,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  // Helper to split title intelligently
  Map<String, String> _splitTitle(String title) {
    final words = title.split(' ');
    if (words.length <= 1) {
      return {'first': title, 'second': ''};
    }

    // Try to split at common prepositions for natural phrasing
    final prepositions = [
      ' in ',
      ' on ',
      ' of ',
      ' to ',
      ' for ',
      ' with ',
      ' from '
    ];
    for (final prep in prepositions) {
      final prepIndex = title.toLowerCase().indexOf(prep);
      if (prepIndex != -1) {
        final firstPart = title.substring(0, prepIndex).trim();
        final secondPart =
            title.substring(prepIndex + 1).trim(); // Skip the space

        // Check if this creates a good split (avoid single long words on second line)
        final secondWords = secondPart.split(' ');
        if (secondWords.length > 1 || secondWords[0].length <= 12) {
          return {
            'first': firstPart,
            'second': secondPart,
          };
        }
      }
    }

    // Try to split after "a " or "an " for natural phrasing
    final aIndex = title.toLowerCase().indexOf(' a ');
    final anIndex = title.toLowerCase().indexOf(' an ');

    if (aIndex != -1) {
      final firstPart = title.substring(0, aIndex + 2).trim();
      final secondPart = title.substring(aIndex + 2).trim();

      // Check if second part is a single long word
      final secondWords = secondPart.split(' ');
      if (secondWords.length > 1 || secondWords[0].length <= 12) {
        return {
          'first': firstPart,
          'second': secondPart,
        };
      }
    } else if (anIndex != -1) {
      final firstPart = title.substring(0, anIndex + 3).trim();
      final secondPart = title.substring(anIndex + 3).trim();

      // Check if second part is a single long word
      final secondWords = secondPart.split(' ');
      if (secondWords.length > 1 || secondWords[0].length <= 12) {
        return {
          'first': firstPart,
          'second': secondPart,
        };
      }
    }

    // Fallback: split as evenly as possible, avoiding single long words on second line
    final halfLength = title.length / 2;
    int bestSplitIndex = 1;
    int bestDifference = title.length;

    int currentLength = words[0].length;
    for (int i = 1; i < words.length; i++) {
      final secondPart = words.sublist(i).join(' ');
      final secondWords = secondPart.split(' ');

      // Penalize splits that leave a single long word on the second line
      final penalty =
          (secondWords.length == 1 && secondWords[0].length > 12) ? 1000 : 0;

      final difference = (currentLength - halfLength).abs() + penalty;
      if (difference < bestDifference) {
        bestDifference = difference.toInt();
        bestSplitIndex = i;
      }
      currentLength += words[i].length + 1; // +1 for space
    }

    return {
      'first': words.sublist(0, bestSplitIndex).join(' '),
      'second': words.sublist(bestSplitIndex).join(' '),
    };
  }

  // 1. Opening Scripture
  Widget _buildOpeningScripture(Devotional devotional) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
                color: AppTheme.goldColor,
                size: ResponsiveUtils.iconSize(context, 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.openingScripture,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DarkGlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${devotional.openingScriptureText}"',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16,
                        minSize: 14, maxSize: 18),
                    color: AppColors.primaryText,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  devotional.openingScriptureReference,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  // 2. Key Verse Spotlight
  Widget _buildKeyVerse(Devotional devotional) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: AppTheme.goldColor,
                size: ResponsiveUtils.iconSize(context, 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.keyVerseSpotlight,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DarkGlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${devotional.keyVerseText}"',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 17,
                        minSize: 15, maxSize: 19),
                    color: AppColors.primaryText,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  devotional.keyVerseReference,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  // 3. Reflection
  Widget _buildReflection(Devotional devotional) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reflection,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 18,
                  minSize: 16, maxSize: 20),
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            devotional.reflection,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 15,
                  minSize: 13, maxSize: 17),
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  // 4. Life Application
  Widget _buildLifeApplication(Devotional devotional) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue.shade300,
                size: ResponsiveUtils.iconSize(context, 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.lifeApplication,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16,
                        minSize: 14, maxSize: 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DarkGlassContainer(
            child: Text(
              devotional.lifeApplication,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 15,
                    minSize: 13, maxSize: 17),
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  // 5. Prayer
  Widget _buildPrayer(Devotional devotional) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                color: Colors.purple.shade200,
                size: ResponsiveUtils.iconSize(context, 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.prayer,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16,
                        minSize: 14, maxSize: 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DarkGlassContainer(
            child: Text(
              devotional.prayer,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 15,
                    minSize: 13, maxSize: 17),
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  // 6. Action Step (with checkbox)
  Widget _buildActionStep(Devotional devotional) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: devotional.actionStepCompleted,
            onChanged: (value) async {
              final service = ref.read(devotionalServiceProvider);
              await service.toggleActionStepCompleted(
                devotional.id,
                value ?? false,
              );
              ref.invalidate(allDevotionalsProvider);
            },
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.green;
              }
              return Colors.white.withValues(alpha: 0.3);
            }),
            checkColor: Colors.white,
            shape: const CircleBorder(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  l10n.todaysActionStep,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade300,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  devotional.actionStep,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 15,
                        minSize: 13, maxSize: 17),
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  // 7. Extended
  Widget _buildGoingDeeper(Devotional devotional) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.explore,
                color: AppTheme.goldColor,
                size: ResponsiveUtils.iconSize(context, 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.extended,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16,
                        minSize: 14, maxSize: 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: devotional.goingDeeper.asMap().entries.map((entry) {
              final index = entry.key;
              final reference = entry.value;

              final verseCard = GestureDetector(
                onTap: () => _navigateToVerse(reference),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Reference text
                          Expanded(
                            child: Text(
                              reference,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 16,
                                    minSize: 14, maxSize: 18),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Chevron
                          Icon(
                            Icons.chevron_right,
                            size: ResponsiveUtils.iconSize(context, 24),
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ),

                      // Divider
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.2),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              return verseCard;
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  // 8. Reading Time
  Widget _buildReadingTime(Devotional devotional) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Colors.white.withValues(alpha: 0.5),
            size: ResponsiveUtils.iconSize(context, 16),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              devotional.readingTime,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 12,
                    minSize: 10, maxSize: 14),
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.2);
  }

  Widget _buildCompletionButton(Devotional devotional) {
    final l10n = AppLocalizations.of(context);
    final progressService = ref.read(devotionalProgressServiceProvider);

    return !devotional.isCompleted
        ? GlassButton(
            text: l10n.markAsCompleted,
            onPressed: () async {
              await progressService.markAsComplete(devotional.id);
              // Refresh the providers
              ref.invalidate(allDevotionalsProvider);
              ref.invalidate(devotionalStreakProvider);
              ref.invalidate(totalDevotionalsCompletedProvider);
              ref.invalidate(completedDevotionalsProvider);
            },
          )
        : Container(
            width: double.infinity,
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: AppRadius.mediumRadius,
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: ResponsiveUtils.iconSize(context, 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.devotionalCompleted,
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtils.fontSize(context, 16,
                                    minSize: 14, maxSize: 18),
                              ),
                            ),
                            if (devotional.completedDate != null)
                              Text(
                                _formatCompletedDate(devotional.completedDate!),
                                style: TextStyle(
                                  color: Colors.green.withValues(alpha: 0.8),
                                  fontSize: ResponsiveUtils.fontSize(
                                      context, 12,
                                      minSize: 10, maxSize: 14),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await progressService.markAsIncomplete(devotional.id);
                    // Refresh the providers
                    ref.invalidate(allDevotionalsProvider);
                    ref.invalidate(devotionalStreakProvider);
                    ref.invalidate(totalDevotionalsCompletedProvider);
                    ref.invalidate(completedDevotionalsProvider);
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.green.withValues(alpha: 0.6),
                    size: ResponsiveUtils.iconSize(context, 20),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildNavigationButtons(
      int totalDevotionals, List<Devotional> devotionals) {
    final l10n = AppLocalizations.of(context);
    // Check if the next devotional is in the future
    bool canGoForward = false;
    if (_currentDay < totalDevotionals - 1) {
      final nextDevotional = devotionals[_currentDay + 1];
      final nextDate = DateTime.parse(nextDevotional.date);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final nextDateOnly =
          DateTime(nextDate.year, nextDate.month, nextDate.day);

      // Allow navigation if next devotional's date is today or in the past
      canGoForward = nextDateOnly.isBefore(todayDate) ||
          nextDateOnly.isAtSameMomentAs(todayDate);
    }

    // At 130%+ text scale, show icons only to prevent overflow
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final showIconsOnly = textScale >= 1.3;

    return Row(
      children: [
        Expanded(
          child: _currentDay > 0
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentDay--;
                    });
                  },
                  child: ClearGlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.primaryText,
                          size: ResponsiveUtils.iconSize(context, 16),
                        ),
                        if (!showIconsOnly) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.previousDay,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox(),
        ),
        if (_currentDay > 0 && canGoForward)
          const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: canGoForward
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentDay++;
                    });
                  },
                  child: ClearGlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!showIconsOnly) ...[
                          Text(
                            l10n.nextDay,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.primaryText,
                          size: ResponsiveUtils.iconSize(context, 16),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(),
        ),
      ],
    ).animate().fadeIn(duration: AppAnimations.slow, delay: 800.ms);
  }

  Widget _buildProgressIndicator(List<Devotional> devotionals) {
    final l10n = AppLocalizations.of(context);
    // Get current devotional's date to determine the month
    final currentDevotional = devotionals[_currentDay];
    final currentDate = DateTime.parse(currentDevotional.date);

    // Filter devotionals for the current month
    final monthlyDevotionals = devotionals.where((d) {
      final date = DateTime.parse(d.date);
      return date.year == currentDate.year && date.month == currentDate.month;
    }).toList();

    // Find the current day's index within the monthly devotionals
    final monthlyIndex =
        monthlyDevotionals.indexWhere((d) => d.id == currentDevotional.id);

    // Get month name
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final monthName = monthNames[currentDate.month - 1];

    // At 130%+ text scale, show shorter header to prevent overflow
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final useShortHeader = textScale >= 1.3;
    final headerText = useShortHeader
        ? '$monthName ${currentDate.year}'
        : l10n.monthYearProgress(monthName, currentDate.year.toString());

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  headerText,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16,
                        minSize: 14, maxSize: 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.progressCount(monthlyIndex + 1, monthlyDevotionals.length),
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: (monthlyIndex + 1) / monthlyDevotionals.length,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            borderRadius: BorderRadius.circular(AppRadius.xs / 2),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Responsive 7-column grid using LayoutBuilder for precise sizing
          LayoutBuilder(
            builder: (context, constraints) {
              const columns = 7;
              const spacing = 8.0;
              const runSpacing = 8.0;
              // Calculate item width based on available space and column count
              const totalSpacing = spacing * (columns - 1);
              final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: List.generate(monthlyDevotionals.length, (index) {
                  final devotional = monthlyDevotionals[index];
                  final isCompleted = devotional.isCompleted;
                  final isCurrent = index == monthlyIndex;
                  final dayOfMonth = DateTime.parse(devotional.date).day;

                  return Container(
                    width: itemWidth,
                    height: ResponsiveUtils.scaleSize(context, 40,
                        minScale: 0.9, maxScale: 1.2),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppTheme.primaryColor.withValues(alpha: 0.3)
                          : isCompleted
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                      borderRadius: AppRadius.smallRadius,
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.primaryColor
                            : isCompleted
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                              size: ResponsiveUtils.iconSize(context, 20),
                            )
                          : Text(
                              '$dayOfMonth',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtils.fontSize(context, 14,
                                    minSize: 12, maxSize: 16),
                              ),
                            ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow, delay: 1000.ms);
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: FrostedGlassCard(
        padding: AppSpacing.screenPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories,
              color: Colors.white.withValues(alpha: 0.5),
              size: ResponsiveUtils.iconSize(context, 64),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.noDevotionalsAvailable,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 20,
                    minSize: 18, maxSize: 24),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.checkBackForDevotionals,
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

  Widget _buildErrorState(Object error) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: FrostedGlassCard(
        padding: AppSpacing.screenPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withValues(alpha: 0.8),
              size: ResponsiveUtils.iconSize(context, 64),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.errorLoadingDevotionals,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 20,
                    minSize: 18, maxSize: 24),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
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

  String _formatCompletedDate(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return l10n.completedToday;
    } else if (dateDay == yesterday) {
      return l10n.completedYesterday;
    } else {
      final difference = today.difference(dateDay).inDays;
      return l10n.completedDaysAgo(difference);
    }
  }

  /// Navigate to a Bible verse from a reference string
  /// Examples: "John 3:16", "1 Thessalonians 5:18 - Give thanks", "Psalm 136:1 - His loving kindness", "Psalm 136:1-3"
  void _navigateToVerse(String reference) {
    try {
      // Remove any text after " - " (e.g., "Psalm 136:1 - His loving kindness" -> "Psalm 136:1")
      final cleanReference = reference.split(' - ').first.trim();

      // Parse the reference (e.g., "1 Thessalonians 5:18" or "1 Thessalonians 5:18-20")
      final parts = cleanReference.split(':');
      if (parts.length != 2) {
        debugPrint('⚠️ Invalid reference format: $cleanReference');
        return;
      }

      // Handle verse ranges like "18-20" by taking the first verse
      final versePart = parts[1].trim();
      final verseRange = versePart.split('-');
      final verseNumber = int.tryParse(verseRange.first.trim());
      if (verseNumber == null) {
        debugPrint('⚠️ Invalid verse number: $versePart');
        return;
      }

      // Split book and chapter (e.g., "1 Thessalonians 5")
      final bookChapterParts = parts[0].trim().split(RegExp(r'\s+'));
      if (bookChapterParts.isEmpty) {
        debugPrint('⚠️ Invalid book/chapter format: ${parts[0]}');
        return;
      }

      // Get chapter number (last part)
      final chapterNumber = int.tryParse(bookChapterParts.last);
      if (chapterNumber == null) {
        debugPrint('⚠️ Invalid chapter number: ${bookChapterParts.last}');
        return;
      }

      // Get book name (everything except the last part)
      var book =
          bookChapterParts.sublist(0, bookChapterParts.length - 1).join(' ');

      // Normalize book name (database uses "Psalms" but devotionals use "Psalm")
      if (book == 'Psalm') {
        book = 'Psalms';
      }

      // Navigate to ChapterReadingScreen with auto-scroll to verse
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChapterReadingScreen(
            book: book,
            startChapter: chapterNumber,
            endChapter: chapterNumber,
            initialVerseNumber: verseNumber,
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error navigating to verse $reference: $e');
    }
  }
}
