import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_card.dart';
import '../components/dark_glass_container.dart';
import '../components/clear_glass_card.dart';
import '../components/blur_popup_menu.dart';
import '../components/base_bottom_sheet.dart';
import '../components/glass_button.dart';
import '../components/standard_screen_header.dart';
import '../theme/app_theme.dart';
import '../core/navigation/navigation_service.dart';
import '../models/bible_verse.dart';
import '../models/shared_verse_entry.dart';
import '../core/providers/app_providers.dart';
import '../utils/responsive_utils.dart';
import '../core/widgets/app_snackbar.dart';
import '../utils/blur_dialog_utils.dart';
import '../services/verse_share_service.dart';
import '../core/services/database_service.dart';
import '../core/services/achievement_service.dart';
import '../l10n/app_localizations.dart';

// Provider for all saved verses
final filteredVersesProvider =
    FutureProvider.autoDispose<List<BibleVerse>>((ref) async {
  final service = ref.watch(unifiedVerseServiceProvider);
  return await service.getAllVerses(limit: 100);
});

class VerseLibraryScreen extends ConsumerStatefulWidget {
  const VerseLibraryScreen({super.key});

  @override
  ConsumerState<VerseLibraryScreen> createState() => _VerseLibraryScreenState();
}

class _VerseLibraryScreenState extends ConsumerState<VerseLibraryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late VerseShareService _verseShareService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final databaseService = DatabaseService();
    _verseShareService = VerseShareService(
      databaseService: databaseService,
      achievementService: AchievementService(databaseService),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                      _buildSavedVerses(),
                      _buildSharedVerses(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return StandardScreenHeader(
      title: l10n.verseLibrary,
      subtitle: l10n.everydayVerses,
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
          onPressed: _showVerseOptions,
          tooltip: l10n.verseOptions,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);
    final textSize = ref.watch(textSizeProvider);
    // At 130% and higher (text size >= 1.3), use shorter label to prevent cutoff
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
            fontSize:
                ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
          ),
          tabs: [
            Tab(text: useShortLabel ? l10n.saved : l10n.savedVerses),
            Tab(text: useShortLabel ? l10n.sharedShort : l10n.shared),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppAnimations.slow, delay: 800.ms);
  }

  Widget _buildSharedVerses() {
    final l10n = AppLocalizations.of(context);
    final sharedAsync = ref.watch(sharedVersesProvider);

    return sharedAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history_toggle_off,
            title: l10n.noSharedVersesYet,
            subtitle: l10n.shareVersesToQuickAccess,
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(left: 50, right: 50, top: 20, bottom: 20),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSharedVerseCard(entry, index)
                  .animate()
                  .fadeIn(
                      duration: AppAnimations.slow,
                      delay: (100 + index * 50).ms)
                  .slideY(begin: 0.3),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      ),
      error: (error, stackTrace) => _buildErrorState(error.toString()),
    );
  }

  // Deprecated: Removed pre-populated "All Verses" tab
  // Widget _buildAllVerses() { ... }

  Widget _buildSavedVerses() {
    final l10n = AppLocalizations.of(context);
    final favoritesAsync = ref.watch(favoriteVersesProvider);

    return favoritesAsync.when(
      data: (verses) {
        if (verses.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_outline,
            title: l10n.noSavedVersesYet,
            subtitle: l10n.saveVersesWhileReading,
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(left: 50, right: 50, top: 20, bottom: 20),
          itemCount: verses.length,
          itemBuilder: (context, index) {
            final verse = verses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildVerseCard(verse, index)
                  .animate()
                  .fadeIn(
                      duration: AppAnimations.slow,
                      delay: (100 + index * 50).ms)
                  .slideY(begin: 0.3),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
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
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.somethingWentWrong,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 20,
                    minSize: 18, maxSize: 24),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 14,
                    minSize: 12, maxSize: 16),
                color: AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseCard(BibleVerse verse, int index) {
    final l10n = AppLocalizations.of(context);
    return DarkGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Book/Chapter/Verse on left
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.book,
                      size: ResponsiveUtils.iconSize(context, 16),
                      color: AppTheme.goldColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        '${verse.reference} (${verse.translation})',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 14,
                              minSize: 12, maxSize: 16),
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 3-dot menu for actions
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
                    _showShareOptions(verse);
                  } else if (value == 'delete') {
                    _deleteSavedVerse(verse);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(
                    Icons.more_vert,
                    size: ResponsiveUtils.iconSize(context, 20),
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '"${verse.text}"',
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 16,
                  minSize: 14, maxSize: 18),
              color: AppColors.primaryText,
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (verse.themes.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: verse.themes.skip(1).take(3).map((theme) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smallRadius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    theme.substring(0, 1).toUpperCase() + theme.substring(1),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 11,
                          minSize: 9, maxSize: 13),
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSharedVerseCard(SharedVerseEntry entry, int index) {
    final l10n = AppLocalizations.of(context);
    final verse = entry.toBibleVerse();
    final sharedTimestamp =
        DateFormat('MMM d, yyyy • h:mm a').format(entry.sharedAt);

    // Don't show internal channel names to users
    final channelLabel =
        entry.channel?.isNotEmpty == true && entry.channel != 'share_sheet'
            ? entry.channel ?? ''
            : '';

    return DarkGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: ResponsiveUtils.iconSize(context, 16),
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            '${verse.reference} (${verse.translation})',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 14,
                                  minSize: 12, maxSize: 16),
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      channelLabel.isNotEmpty
                          ? '$sharedTimestamp • $channelLabel'
                          : sharedTimestamp,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12,
                            minSize: 10, maxSize: 14),
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              // 3-dot menu for actions
              BlurPopupMenu(
                items: [
                  BlurPopupMenuItem(
                    value: 'delete',
                    icon: Icons.delete,
                    label: l10n.delete,
                    iconColor: Colors.red,
                    textColor: Colors.red,
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteSharedVerse(entry.id);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(
                    Icons.more_vert,
                    size: ResponsiveUtils.iconSize(context, 20),
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '"${entry.text}"',
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 16,
                  minSize: 14, maxSize: 18),
              color: AppColors.primaryText,
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (entry.themes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.themes.take(3).map((theme) {
                final displayTheme = theme.isNotEmpty
                    ? theme.substring(0, 1).toUpperCase() + theme.substring(1)
                    : 'General';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smallRadius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    displayTheme,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 11,
                          minSize: 9, maxSize: 13),
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showShareOptions(BibleVerse verse) {
    final l10n = AppLocalizations.of(context);
    showCustomBottomSheet(
      context: context,
      title: l10n.shareVerseTitle,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _buildSheetIcon(Icons.copy),
              title: Text(l10n.copyToClipboard,
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                final text =
                    '"${verse.text}"\n\n${verse.reference} (${verse.translation})';
                Clipboard.setData(ClipboardData(text: text));
                NavigationService.pop();
                if (!mounted) return;
                AppSnackBar.show(
                  context,
                  message: l10n.verseCopiedToClipboard,
                );
              },
            ),
            ListTile(
              leading: _buildSheetIcon(Icons.share),
              title: Text(l10n.shareText,
                  style: const TextStyle(color: Colors.white)),
              onTap: () async {
                NavigationService.pop();
                final shareText = '"${verse.text}"\n\n— ${verse.reference}';
                try {
                  final result = await SharePlus.instance.share(
                    ShareParams(
                      text: shareText,
                      subject: l10n.verseShareSubject(verse.reference),
                    ),
                  );

                  // Only proceed if share was successful (not dismissed/cancelled)
                  if (result.status == ShareResultStatus.success) {
                    await ref
                        .read(unifiedVerseServiceProvider)
                        .recordSharedVerse(verse);

                    ref.invalidate(sharedVersesProvider);
                    ref.invalidate(sharedVersesCountProvider);
                    ref.invalidate(totalSharesCountProvider);
                    // Don't invalidate savedVersesCountProvider - sharing doesn't affect saved count

                    if (!mounted) return;
                    AppSnackBar.show(
                      context,
                      message: 'Verse shared successfully!',
                      icon: Icons.share,
                      iconColor: AppTheme.primaryColor,
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  AppSnackBar.showError(
                    context,
                    message: l10n.unableToShareVerse(e.toString()),
                  );
                }
              },
            ),
            ListTile(
              leading: _buildSheetIcon(Icons.image),
              title: Text(l10n.chatShareAsImage,
                  style: const TextStyle(color: Colors.white)),
              onTap: () async {
                NavigationService.pop();
                try {
                  await _verseShareService.shareVerse(
                    context: context,
                    verse: verse,
                    showThemes: verse.themes.isNotEmpty,
                  );

                  // VerseShareService already tracks the share
                  // Invalidate all relevant providers to refresh UI
                  ref.invalidate(sharedVersesProvider);
                  ref.invalidate(sharedVersesCountProvider);
                  ref.invalidate(
                      totalSharesCountProvider); // For Disciple achievement (all share types)
                  // Don't invalidate savedVersesCountProvider - sharing doesn't affect saved count

                  if (!mounted) return;
                  AppSnackBar.show(
                    context,
                    message: 'Verse shared as image successfully!',
                    icon: Icons.image,
                    iconColor: AppTheme.goldColor,
                  );
                } catch (e) {
                  if (!mounted) return;
                  AppSnackBar.showError(
                    context,
                    message: l10n.unableToShareVerse(e.toString()),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showVerseOptions() {
    final l10n = AppLocalizations.of(context);
    showCustomBottomSheet(
      context: context,
      title: l10n.verseLibraryOptions,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6, // Max 60% of screen
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            ListTile(
              leading: _buildSheetIcon(Icons.info_outline),
              title: Text(
                l10n.aboutVerseLibrary,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              subtitle: Text(
                l10n.browseAndManageYourSavedVerses,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 12,
                      minSize: 10, maxSize: 14),
                  color: AppColors.secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: _buildSheetIcon(Icons.collections_bookmark),
              title: Text(
                l10n.viewSharedHistory,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              subtitle: Text(
                l10n.jumpToRecentlySharedVerses,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 12,
                      minSize: 10, maxSize: 14),
                  color: AppColors.secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: _buildSheetIcon(Icons.delete_forever,
                  iconColor: Colors.redAccent),
              title: Text(
                l10n.clearSavedVerses,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              subtitle: Text(
                l10n.removeAllVersesFromSavedCollection,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 12,
                      minSize: 10, maxSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmClearSavedVerses();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: _buildSheetIcon(Icons.delete_sweep,
                  iconColor: Colors.redAccent),
              title: Text(
                l10n.clearSharedHistory,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              subtitle: Text(
                l10n.removeEveryVerseFromSharedActivity,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 12,
                      minSize: 10, maxSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmClearSharedVerses();
              },
            ),
              ],
            ),
          ),
        ),
      ),
    );
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
      ),
    );
  }

  Future<void> _deleteSharedVerse(String shareId) async {
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
                l10n.delete,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.deleteVerseConfirmation,
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
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
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

    if (confirmed != true) return;

    try {
      final service = ref.read(unifiedVerseServiceProvider);
      await service.deleteSharedVerse(shareId);

      ref.invalidate(sharedVersesProvider);
      ref.invalidate(sharedVersesCountProvider);

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.removedFromSharedHistory,
        icon: Icons.delete_outline,
        iconColor: Colors.redAccent,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: l10n.unableToRemoveSharedVerse(e.toString()),
      );
    }
  }

  Future<void> _deleteSavedVerse(BibleVerse verse) async {
    if (verse.id == null) return;
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
                l10n.delete,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.deleteVerseConfirmation,
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
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
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

    if (confirmed != true) return;

    try {
      final service = ref.read(unifiedVerseServiceProvider);
      final verseId = verse.id;
      if (verseId != null) {
        await service.removeFromFavorites(verseId);
      }

      // Invalidate providers to refresh UI counts
      ref.invalidate(favoriteVersesProvider);
      ref.invalidate(savedVersesCountProvider);

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.removedFromVerseLibrary,
        icon: Icons.heart_broken,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: l10n.unableToRemoveVerse(e.toString()),
      );
    }
  }

  Future<void> _confirmClearSharedVerses() async {
    final l10n = AppLocalizations.of(context);
    final shouldClear = await showBlurredDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FrostedGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    color: Colors.redAccent,
                    size: ResponsiveUtils.iconSize(context, 32),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.clearSharedHistoryQuestion,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 18,
                            minSize: 16, maxSize: 20),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.clearSharedHistoryConfirmation,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: l10n.cancel,
                      height: 48,
                      onPressed: () => Navigator.pop(context, false),
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
                          onTap: () => Navigator.pop(context, true),
                          borderRadius: AppRadius.largeCardRadius,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: Text(
                              l10n.clearAll,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
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

    if (shouldClear == true) {
      try {
        final service = ref.read(unifiedVerseServiceProvider);
        await service.clearSharedVerses();

        ref.invalidate(sharedVersesProvider);
        ref.invalidate(sharedVersesCountProvider);

        if (!mounted) return;
        AppSnackBar.show(
          context,
          message: l10n.sharedHistoryCleared,
          icon: Icons.delete_sweep,
          iconColor: Colors.redAccent,
        );
      } catch (e) {
        if (!mounted) return;
        AppSnackBar.showError(
          context,
          message: l10n.unableToClearSharedHistory(e.toString()),
        );
      }
    }
  }

  Future<void> _confirmClearSavedVerses() async {
    final l10n = AppLocalizations.of(context);
    final shouldClear = await showBlurredDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FrostedGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.delete_sweep,
                    color: Colors.redAccent,
                    size: ResponsiveUtils.iconSize(context, 32),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.clearSavedVersesQuestion,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 18,
                            minSize: 16, maxSize: 20),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.clearSavedVersesConfirmation,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: l10n.cancel,
                      height: 48,
                      onPressed: () => Navigator.pop(context, false),
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
                          onTap: () => Navigator.pop(context, true),
                          borderRadius: AppRadius.largeCardRadius,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: Text(
                              l10n.clearAll,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
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

    if (shouldClear == true) {
      try {
        final service = ref.read(unifiedVerseServiceProvider);
        await service.clearFavoriteVerses();
        ref.invalidate(favoriteVersesProvider);
        ref.invalidate(filteredVersesProvider);
        ref.invalidate(savedVersesCountProvider);
        if (!mounted) return;
        AppSnackBar.show(
          context,
          message: l10n.savedVersesCleared,
          icon: Icons.delete_forever,
          iconColor: Colors.redAccent,
        );
      } catch (e) {
        if (!mounted) return;
        AppSnackBar.showError(
          context,
          message: l10n.unableToClearSavedVerses(e.toString()),
        );
      }
    }
  }
}
