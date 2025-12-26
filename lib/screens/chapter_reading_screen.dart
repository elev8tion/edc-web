import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_card.dart';
import '../components/glass_button.dart';
import '../components/dark_glass_container.dart';
import '../components/audio_control_pill.dart';
import '../theme/app_theme.dart';
import '../core/navigation/navigation_service.dart';
import '../core/providers/app_providers.dart';
import '../core/services/preferences_service.dart';
import '../core/services/database_service.dart';
import '../services/bible_chapter_service.dart';
import '../models/bible_verse.dart';
import '../models/verse_context.dart';
import '../utils/responsive_utils.dart';
import '../core/widgets/app_snackbar.dart';
import '../core/services/tts_service.dart';
import '../core/services/book_name_service.dart';
import '../core/services/bible_config.dart';
import 'chat_screen.dart';
import '../l10n/app_localizations.dart';

/// Chapter Reading Screen - displays Bible chapters with verse-by-verse reading
class ChapterReadingScreen extends ConsumerStatefulWidget {
  final String book;
  final int startChapter;
  final int endChapter;
  final String? readingId;
  final int? initialVerseNumber;

  const ChapterReadingScreen({
    super.key,
    required this.book,
    required this.startChapter,
    required this.endChapter,
    this.readingId,
    this.initialVerseNumber,
  });

  @override
  ConsumerState<ChapterReadingScreen> createState() => _ChapterReadingScreenState();
}

class _ChapterReadingScreenState extends ConsumerState<ChapterReadingScreen>
    with SingleTickerProviderStateMixin {
  final BibleChapterService _chapterService = BibleChapterService();
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final TtsService _ttsService = TtsService();

  late Future<Map<int, List<BibleVerse>>> _versesFuture;
  int _currentChapterIndex = 0;
  bool _isCompleted = false;

  // TTS state
  bool _isAudioPlaying = false;
  int _currentPlayingVerseIndex = -1;

  // Keys for verse widgets (for auto-scroll)
  final Map<int, GlobalKey> _verseKeys = {};

  // Double-tap verse interaction state
  int? _activeVerseIndex;
  late AnimationController _iconAnimationController;

  // Guard flag to load verses only once (language never changes at runtime)
  bool _versesLoaded = false;

  @override
  void initState() {
    super.initState();

    // Initialize icon animation controller (700ms like FAB menu)
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Initialize the Future immediately to ensure FutureBuilder starts in waiting state
    // We'll load the actual data in didChangeDependencies when language is available
    _versesFuture = Future.value({});

    _checkCompletion();
    _initializeTts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load verses after dependencies are available (including AppLocalizations)
    // Guard prevents unnecessary reloads (language doesn't change at runtime)
    if (!_versesLoaded) {
      setState(() {
        _loadVerses();
      });
      _versesLoaded = true;

      // Show tutorial after verses load
      _showBibleTutorialIfNeeded();
    }
  }

  Future<void> _showBibleTutorialIfNeeded() async {
    final prefsService = await PreferencesService.getInstance();

    // Check if tutorial already shown
    if (prefsService.hasBibleBrowserTutorialShown()) {
      return;
    }

    // Wait for verses to load and UI to settle
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    // Show informational dialog about Bible features
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: DarkGlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tutorialBibleTapTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tutorialBibleTapDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.tutorialBibleBookmarkTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tutorialBibleBookmarkDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.tutorialBibleChatTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tutorialBibleChatDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: GlassButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    prefsService.setBibleBrowserTutorialShown();
                  },
                  text: l10n.tutorialFinish,
                  width: 100,
                  height: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Mark as shown even if dismissed
    prefsService.setBibleBrowserTutorialShown();
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    _ttsService.stop(); // Stop audio when leaving screen
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initialize();

    // Set up TTS callbacks
    _ttsService.onVerseChanged = (verseIndex) {
      if (mounted) {
        setState(() => _currentPlayingVerseIndex = verseIndex);
        _scrollToVerse(verseIndex);
      }
    };

    _ttsService.onPlayStateChanged = (isPlaying) {
      if (mounted) {
        setState(() => _isAudioPlaying = isPlaying);
      }
    };

    _ttsService.onPlaybackComplete = () {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackBar.show(
          context,
          message: l10n.chapterPlaybackComplete,
          icon: Icons.check_circle,
        );
      }
    };
  }

  void _loadVerses() {
    final language = Localizations.localeOf(context).languageCode;
    final version = BibleConfig.getVersion(language);

    // Translate book name to match database language
    final bookName = BookNameService.getBookName(widget.book, language);

    _versesFuture = _chapterService.getChapterRange(
      bookName,
      widget.startChapter,
      widget.endChapter,
      version: version,
      language: language,
    );
  }

  Future<void> _checkCompletion() async {
    if (widget.readingId != null) {
      final completed = await _chapterService.isReadingComplete(widget.readingId!);
      if (mounted) {
        setState(() => _isCompleted = completed);
      }
    }
  }

  Future<void> _markAsComplete() async {
    if (widget.readingId == null) return;

    try {
      // Use ReadingPlanProgressService for proper achievement tracking
      final progressService = ref.read(readingPlanProgressServiceProvider);

      // First get the reading to find its plan_id
      final db = await DatabaseService().database;
      final readings = await db.query(
        'daily_readings',
        where: 'id = ?',
        whereArgs: [widget.readingId!],
      );

      if (readings.isEmpty) {
        throw Exception('Reading not found');
      }

      final planId = readings.first['plan_id'] as String;

      // Mark complete using the proper service
      await progressService.markDayComplete(widget.readingId!);

      // Refresh all plan-related providers to update progress
      ref.invalidate(currentReadingPlanProvider);
      ref.invalidate(activeReadingPlansProvider);
      ref.invalidate(allReadingPlansProvider);
      ref.invalidate(todaysReadingsProvider(planId));
      ref.invalidate(planProgressPercentageProvider(planId));
      ref.invalidate(planCompletionStatsProvider(planId));

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _isCompleted = true);
        AppSnackBar.show(
          context,
          message: l10n.readingMarkedComplete,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackBar.showError(
          context,
          message: l10n.errorUpdatingReading(e.toString()),
        );
      }
    }
  }

  // TTS Controls
  Future<void> _playAudio(List<BibleVerse> verses) async {
    try {
      await _ttsService.playChapter(verses);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackBar.showError(
          context,
          message: l10n.audioPlaybackError,
        );
      }
    }
  }

  Future<void> _pauseAudio() async {
    await _ttsService.pause();
  }

  Future<void> _resumeAudio() async {
    await _ttsService.resume();
  }

  Future<void> _stopAudio() async {
    await _ttsService.stop();
    setState(() {
      _currentPlayingVerseIndex = -1;
    });
  }

  Future<void> _cycleSpeed() async {
    await _ttsService.cycleSpeed();
    setState(() {}); // Refresh UI to show new speed
  }

  /// Auto-scroll to current verse during playback
  void _scrollToVerse(int verseIndex) {
    final key = _verseKeys[verseIndex];
    if (key == null || key.currentContext == null) return;

    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2, // Keep verse near top of viewport
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalChapters = widget.endChapter - widget.startChapter + 1;
    final currentChapter = widget.startChapter + _currentChapterIndex;

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: FutureBuilder<Map<int, List<BibleVerse>>>(
              future: _versesFuture,
              builder: (context, snapshot) {
                final currentChapterNum = widget.startChapter + _currentChapterIndex;
                final currentVerses = (snapshot.hasData)
                    ? (snapshot.data![currentChapterNum] ?? <BibleVerse>[])
                    : <BibleVerse>[];

                return Column(
                  children: [
                    // Header with integrated audio player
                    _buildHeader(currentChapter, totalChapters, currentVerses),

                    // Chapter indicator
                    _buildChapterIndicator(context, currentChapter, totalChapters),

                    // Content
                    Expanded(
                      child: Builder(builder: (context) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildLoading();
                        }

                        if (snapshot.hasError) {
                          return _buildError(snapshot.error.toString());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildNoData();
                        }

                        final chaptersMap = snapshot.data!;
                        final chapters = List.generate(
                          totalChapters,
                          (i) => widget.startChapter + i,
                        );

                        // Chapter content with PageView
                        return PageView.builder(
                          controller: _pageController,
                          itemCount: chapters.length,
                          onPageChanged: (index) {
                            setState(() => _currentChapterIndex = index);
                            // Auto-stop audio when user swipes to different chapter
                            if (_isAudioPlaying) {
                              _stopAudio();
                            }
                          },
                          itemBuilder: (context, index) {
                            final chapterNum = chapters[index];
                            final verses = chaptersMap[chapterNum] ?? [];
                            return _buildChapterPage(chapterNum, verses, chaptersMap);
                          },
                        );
                      }),
                    ),

                    // Mark as Complete button
                    if (widget.readingId != null) _buildCompleteButton(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int currentChapter, int totalChapters, List<BibleVerse> currentVerses) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 16.0, right: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adaptive audio pill width - compact to allow more title space
          final availableWidth = constraints.maxWidth;
          final audioPillMaxWidth = availableWidth < 400 ? 140.0 : 160.0;

          // Only use abbreviated names at large text scales (130%+)
          // At 100-120%, show full book names
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          final displayBookName = textScale >= 1.3
              ? BookNameService.getAbbreviation(widget.book)
              : widget.book;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: AppRadius.mediumRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: ResponsiveUtils.iconSize(context, 24)),
                  onPressed: () => NavigationService.pop(),
                  tooltip: l10n.backButton,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and subtitle stacked (compact)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayBookName,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 22),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            totalChapters > 1
                              ? l10n.chapterOfTotal(_currentChapterIndex + 1, totalChapters)
                              : 'Chapter $currentChapter',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 11, maxSize: 13),
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isCompleted) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.green.shade300,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Audio player with adaptive width constraint
              if (currentVerses.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: audioPillMaxWidth),
                  child: AudioControlPill(
                    isPlaying: _isAudioPlaying,
                    isPaused: _ttsService.isPaused,
                    speedLabel: _ttsService.speedLabel,
                    currentVerse: _currentPlayingVerseIndex >= 0 ? _currentPlayingVerseIndex + 1 : null,
                    totalVerses: currentVerses.length,
                    onPlayPause: () {
                      if (!_isAudioPlaying) {
                        _playAudio(currentVerses);
                      } else if (_ttsService.isPaused) {
                        _resumeAudio();
                      } else {
                        _pauseAudio();
                      }
                    },
                    onStop: _stopAudio,
                    onSpeedTap: _cycleSpeed,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChapterIndicator(BuildContext context, int currentChapter, int totalChapters) {
    if (totalChapters == 1) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: _currentChapterIndex > 0
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
            onPressed: _currentChapterIndex > 0
                ? () {
                    if (_pageController.hasClients) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                : null,
            tooltip: l10n.previousChapter,
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xs / 4),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentChapterIndex + 1) / totalChapters,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xs / 4),
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: _currentChapterIndex < totalChapters - 1
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
            onPressed: _currentChapterIndex < totalChapters - 1
                ? () {
                    if (_pageController.hasClients) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                : null,
            tooltip: l10n.nextChapter,
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterPage(int chapterNum, List<BibleVerse> verses, Map<int, List<BibleVerse>> chaptersMap) {
    final l10n = AppLocalizations.of(context);

    // Generate keys for verses (for auto-scroll)
    _verseKeys.clear();
    for (int i = 0; i < verses.length; i++) {
      _verseKeys[i] = GlobalKey();
    }

    // If initial verse number is set and matches current chapter, scroll to it after frame
    if (widget.initialVerseNumber != null && chapterNum == widget.startChapter && _currentChapterIndex == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToVerseNumber(widget.initialVerseNumber!);
          }
        });
      });
    }

    if (verses.isEmpty) {
      return Center(
        child: FrostedGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: ResponsiveUtils.iconSize(context, 48),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noVersesFoundForBook(widget.book, chapterNum),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        borderRadius: 24,
        blurStrength: 15.0,
        gradientColors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        enableNoise: true,
        enableLightSimulation: true,
        border: Border.all(
          color: AppTheme.goldColor,
          width: 1.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrollable verses area
            Expanded(
              child: GestureDetector(
                onTap: _dismissActiveVerse,
                behavior: HitTestBehavior.opaque,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    left: 4.0,
                    top: 20.0,
                    right: 8.0,
                    bottom: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verses
                      ...verses.asMap().entries.map((entry) {
                final verseIndex = entry.key;
                final verse = entry.value;
                final isCurrentVerse = _isAudioPlaying && verseIndex == _currentPlayingVerseIndex;

                final isActive = _activeVerseIndex == verseIndex;

                return Padding(
                  key: _verseKeys[verseIndex],
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: isCurrentVerse
                        ? BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.15),
                                AppTheme.primaryColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    padding: isCurrentVerse ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Verse number and action icons column
                      Column(
                        children: [
                          // Verse number with glassmorphic style (always visible)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.25),
                                  Colors.white.withValues(alpha: 0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: AppRadius.smallRadius,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${verse.verseNumber}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            ),
                          ),
                          // Animated icons (only shown when verse is active)
                          if (isActive) ...[
                            const SizedBox(height: 4),
                            // Favorite button with animation
                            AnimatedBuilder(
                              animation: _iconAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _iconAnimationController.value,
                                  child: Opacity(
                                    opacity: _iconAnimationController.value,
                                    child: GestureDetector(
                                      onTap: () => _performVerseAction(() async {
                                        if (verse.id != null) {
                                          await ref.read(unifiedVerseServiceProvider).toggleFavorite(verse.id!);
                                          ref.invalidate(favoriteVersesProvider);
                                        }
                                      }),
                                      child: _buildFavoriteButton(verse),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            // Chat icon with animation
                            AnimatedBuilder(
                              animation: _iconAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _iconAnimationController.value,
                                  child: Opacity(
                                    opacity: _iconAnimationController.value,
                                    child: GestureDetector(
                                      onTap: () => _performVerseAction(() => _navigateToVerseDiscussion(verse)),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.goldColor.withValues(alpha: 0.3),
                                              AppTheme.goldColor.withValues(alpha: 0.1),
                                            ],
                                          ),
                                          borderRadius: AppRadius.smallRadius,
                                          border: Border.all(
                                            color: AppTheme.goldColor.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(AppRadius.xs),
                                          child: Image.asset(
                                            l10n.localeName == 'es'
                                                ? 'assets/images/logo_spanish.png'
                                                : 'assets/images/logo_cropped.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Verse text with double-tap gesture
                      Expanded(
                        child: GestureDetector(
                          onDoubleTap: () => _onVerseDoubleTap(verseIndex),
                          child: Text(
                            verse.text,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 18, minSize: 16, maxSize: 20),
                              height: 1.6,
                              color: isActive ? AppTheme.goldColor : Colors.white,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                );
              }),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BibleVerse verse) {
    if (verse.id == null) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: ref.read(unifiedVerseServiceProvider).isVerseFavorite(verse.id!),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final isFavorite = snapshot.data ?? false;

        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isFavorite
                  ? [
                      Colors.red.withValues(alpha: 0.3),
                      Colors.red.withValues(alpha: 0.2),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.1),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.smallRadius,
            border: Border.all(
              color: isFavorite
                  ? Colors.red.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: ResponsiveUtils.iconSize(context, 18),
              color: isFavorite ? Colors.red : Colors.white.withValues(alpha: 0.7),
            ),
            onPressed: () => _toggleFavorite(verse),
            tooltip: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(BibleVerse verse) async {
    if (verse.id == null) return;

    try {
      final verseService = ref.read(unifiedVerseServiceProvider);
      final wasFavorite = await verseService.isVerseFavorite(verse.id!);

      if (wasFavorite) {
        await verseService.removeFromFavorites(verse.id!);
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        AppSnackBar.show(
          context,
          message: l10n.removedFromVerseLibrary,
          icon: Icons.heart_broken,
        );
      } else {
        // Add verse to favorites directly (no theme selection)
        await verseService.addToFavorites(
          verse.id!,
          text: verse.text,
          reference: verse.reference,
          category: verse.category,
        );

        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        AppSnackBar.show(
          context,
          message: l10n.addedToVerseLibrary,
          icon: Icons.favorite,
        );
      }

      // CRITICAL FIX: Invalidate providers to refresh saved verses count
      // This ensures the verse library and profile screens show accurate counts
      if (mounted) {
        ref.invalidate(savedVersesCountProvider);
      }

      // Trigger UI update
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      AppSnackBar.showError(
        context,
        message: '${l10n.error}: $e',
      );
    }
  }

  /// Navigate to chat screen to discuss a specific verse
  /// Returns to this screen with auto-scroll when user taps "Return to Reading"
  Future<void> _navigateToVerseDiscussion(BibleVerse verse) async {
    final verseContext = VerseContext.fromVerse(verse);

    final result = await Navigator.push<VerseContext>(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          verseContext: verseContext,
        ),
      ),
    );

    // If user returned from chat, scroll to the verse
    if (result != null && mounted) {
      debugPrint('📖 Returned from chat, scrolling to verse ${result.verseNumber}');
      _scrollToVerseNumber(result.verseNumber);
    }
  }

  /// Scroll to a specific verse number in the current chapter
  void _scrollToVerseNumber(int verseNumber) {
    // Find the verse index (0-based)
    final verseIndex = verseNumber - 1;

    // Check if we have a key for this verse
    final key = _verseKeys[verseIndex];
    if (key == null || key.currentContext == null) {
      debugPrint('⚠️ No key found for verse $verseNumber');
      return;
    }

    // Scroll to the verse with animation
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      alignment: 0.2, // Keep verse near top of viewport
    );
  }

  /// Handle double-tap on verse text
  void _onVerseDoubleTap(int verseIndex) {
    if (mounted) {
      setState(() {
        _activeVerseIndex = verseIndex;
      });
      _iconAnimationController.forward();
    }
  }

  /// Dismiss active verse icons
  void _dismissActiveVerse() {
    if (_activeVerseIndex != null) {
      _iconAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _activeVerseIndex = null;
          });
        }
      });
    }
  }

  /// Perform action on verse and dismiss
  void _performVerseAction(VoidCallback action) {
    action();
    _dismissActiveVerse();
  }

  Widget _buildCompleteButton() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassButton(
        text: _isCompleted ? l10n.readingCompleted : l10n.markAsCompleted,
        onPressed: _isCompleted ? null : _markAsComplete,
        height: 56,
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildError(String error) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FrostedGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: ResponsiveUtils.iconSize(context, 64),
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.errorLoadingChapter,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loadVerses();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoData() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FrostedGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: ResponsiveUtils.iconSize(context, 64),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noVersesAvailable,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.couldNotFindVersesForRange(widget.book, widget.startChapter, widget.endChapter),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
