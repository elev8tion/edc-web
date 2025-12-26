import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_card.dart';
import '../components/standard_screen_header.dart';
import '../core/navigation/navigation_service.dart';
import '../core/services/book_name_service.dart';
import '../core/services/bible_config.dart';
import '../core/services/bible_book_service.dart';
import '../services/bible_chapter_service.dart';
import '../models/bible_verse.dart';
import '../models/bible_book.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../utils/bible_reference_parser.dart';
import '../utils/blur_dialog_utils.dart';
import '../l10n/app_localizations.dart';
import '../widgets/noise_overlay.dart';

/// Free Bible Browser - allows users to browse and read any Bible chapter
class BibleBrowserScreen extends ConsumerStatefulWidget {
  const BibleBrowserScreen({super.key});

  @override
  ConsumerState<BibleBrowserScreen> createState() => _BibleBrowserScreenState();
}

class _BibleBrowserScreenState extends ConsumerState<BibleBrowserScreen>
    with TickerProviderStateMixin {
  final BibleChapterService _bibleService = BibleChapterService();
  final BibleBookService _bookService = BibleBookService.instance;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounceTimer;

  List<String> _allBooks = [];
  List<String> _filteredBooks = [];
  List<BibleBook> _bibleBooks = [];
  List<BibleVerse> _verseSearchResults = [];
  bool _isLoading = true;
  bool _isSearchingVerses = false;
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allBooks.isEmpty) {
      _loadBooks();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    try {
      // Load Bible book metadata from JSON
      _bibleBooks = await _bookService.getAllBooks();

      // Get actual books from database
      final (language, version) = _getLanguageAndVersion();
      final books = await _bibleService.getAllBooks(
        language: language,
        version: version,
      );
      if (mounted) {
        setState(() {
          _allBooks = books;
          _filteredBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading books: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterBooks(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    setState(() {
      _searchQuery = query;

      if (query.isEmpty) {
        _filteredBooks = _allBooks;
        _verseSearchResults = [];
        _isSearchingVerses = false;
        return;
      }

      // Step 1: Check if input looks like a Bible reference
      if (BibleReferenceParser.looksLikeReference(query)) {
        final parsed = BibleReferenceParser.parse(query);

        if (parsed != null) {
          // Direct reference lookup - instant results
          _isSearchingVerses = true;
          _filteredBooks = [];

          final (language, version) = _getLanguageAndVersion();
          _bibleService
              .getVersesByReference(
            parsed.book,
            parsed.chapter,
            parsed.startVerse,
            endVerse: parsed.endVerse,
            language: language,
            version: version,
          )
              .then((verses) {
            if (mounted) {
              setState(() {
                _verseSearchResults = verses;
                _isSearchingVerses = false;
              });
            }
          }).catchError((e) {
            if (mounted) {
              setState(() {
                _verseSearchResults = [];
                _isSearchingVerses = false;
              });
            }
          });
          return;
        }
      }

      // Step 2: Filter books - check both English and translated names
      final language = Localizations.localeOf(context).languageCode;

      _filteredBooks = _allBooks.where((book) {
        final englishName = book.toLowerCase();
        final translatedName =
            BookNameService.getBookName(book, language).toLowerCase();
        final searchLower = query.toLowerCase();
        return englishName.contains(searchLower) ||
            translatedName.contains(searchLower);
      }).toList();

      // Step 3: If no books match, fall back to FTS5 verse search
      if (_filteredBooks.isEmpty) {
        _isSearchingVerses = true;
        _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
          try {
            final (language, version) = _getLanguageAndVersion();
            final verses = await _bibleService.searchVerses(
              query,
              language: language,
              version: version,
              limit: 50,
            );
            if (mounted) {
              setState(() {
                _verseSearchResults = verses;
                _isSearchingVerses = false;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isSearchingVerses = false;
              });
            }
          }
        });
      } else {
        _verseSearchResults = [];
        _isSearchingVerses = false;
      }
    });
  }

  List<String> _getOldTestamentBooks() {
    // Get Old Testament book names for current language
    final language = Localizations.localeOf(context).languageCode;
    final otBooks = _bibleBooks
        .where((b) => b.testament == 'Old Testament')
        .map((b) => b.getName(language))
        .toSet();

    // Filter current books list
    return _filteredBooks.where((book) => otBooks.contains(book)).toList();
  }

  List<String> _getNewTestamentBooks() {
    // Get New Testament book names for current language
    final language = Localizations.localeOf(context).languageCode;
    final ntBooks = _bibleBooks
        .where((b) => b.testament == 'New Testament')
        .map((b) => b.getName(language))
        .toSet();

    // Filter current books list
    return _filteredBooks.where((book) => ntBooks.contains(book)).toList();
  }

  /// Get current language and Bible version
  (String, String) _getLanguageAndVersion() {
    final language = Localizations.localeOf(context).languageCode;
    final version = BibleConfig.getVersion(language);
    return (language, version);
  }

  /// Check if we should show search overlay
  bool get _showSearchOverlay {
    return _searchQuery.isNotEmpty;
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
                  _buildHeader()
                      .animate()
                      .fadeIn(duration: AppAnimations.normal)
                      .slideY(begin: -0.2, end: 0),
                  _buildSearchBar()
                      .animate()
                      .fadeIn(duration: AppAnimations.normal, delay: 100.ms)
                      .slideY(begin: -0.2, end: 0),
                  // TabBar - hide during search
                  if (!_showSearchOverlay)
                    _buildTabBar()
                        .animate()
                        .fadeIn(duration: AppAnimations.normal, delay: 200.ms),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.goldColor),
                              strokeWidth: 3,
                            ),
                          )
                        : _showSearchOverlay
                            ? _buildSearchOverlay()
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildTestamentView(_getOldTestamentBooks()),
                                  _buildTestamentView(_getNewTestamentBooks()),
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

  /// Build search overlay that covers TabBarView
  Widget _buildSearchOverlay() {
    final l10n = AppLocalizations.of(context);
    return _isSearchingVerses
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.searchingVerses,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        : (_filteredBooks.isNotEmpty
            ? _buildFilteredBooks()
            : _buildVerseResults());
  }

  /// Build filtered books list (shown when books match search)
  Widget _buildFilteredBooks() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _filteredBooks.length,
      itemBuilder: (context, index) =>
          _buildBookListItem(_filteredBooks[index]),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return StandardScreenHeader(
      title: l10n.bibleBrowser,
      subtitle: l10n.readAnyChapterFreely,
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);

    final searchWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl + 1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterBooks,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: ResponsiveUtils.fontSize(context, 15,
                      minSize: 13, maxSize: 17),
                ),
                decoration: InputDecoration(
                  hintText: l10n.searchBooks,
                  hintStyle: TextStyle(
                    color: AppColors.tertiaryText,
                    fontSize: ResponsiveUtils.fontSize(context, 15,
                        minSize: 13, maxSize: 17),
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: ResponsiveUtils.iconSize(context, 20),
                  ),
                ),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl + 1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.clear, color: AppColors.primaryText),
                onPressed: () {
                  _searchController.clear();
                  _filterBooks('');
                },
                tooltip: l10n.clearSearch,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return searchWidget;
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);

    // Check if we need scrollable tabs based on text length
    final oldTestamentText = l10n.oldTestament;
    final newTestamentText = l10n.newTestament;
    final totalTextLength = oldTestamentText.length + newTestamentText.length;

    // Make scrollable if combined text length is > 25 characters (Spanish needs ~30)
    final needsScrollable = totalTextLength > 25;

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
        child: needsScrollable
            ? Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
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
                        fontSize: ResponsiveUtils.fontSize(context, 13,
                            minSize: 11, maxSize: 15),
                      ),
                      tabs: [
                        Tab(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(oldTestamentText),
                          ),
                        ),
                        Tab(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(newTestamentText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : TabBar(
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
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                ),
                tabs: [
                  Tab(text: oldTestamentText),
                  Tab(text: newTestamentText),
                ],
              ),
      ),
    );
  }

  Widget _buildTestamentView(List<String> books) {
    final l10n = AppLocalizations.of(context);
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: ResponsiveUtils.iconSize(context, 64),
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noBooksFound,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 18,
                      minSize: 16, maxSize: 20),
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tryDifferentSearchTerm,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: books.length,
      itemBuilder: (context, index) => _buildBookListItem(books[index]),
    );
  }

  Widget _buildBookListItem(String book) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final displayName = BookNameService.getBookName(book, language);

    // Get book metadata from BibleBookService
    final bibleBook = _bibleBooks.firstWhere(
      (b) => b.matchesName(book),
      orElse: () => BibleBook(
        id: 0,
        testament: 'Old Testament',
        englishName: book,
        spanishName: book,
        abbreviation: 'Bk',
        chapters: 0,
      ),
    );

    final abbreviation = bibleBook.abbreviation;
    final chapterCount = bibleBook.chapters;

    return GestureDetector(
      onTap: () => _showChapterSelector(book),
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
                // Icon with abbreviation - Enhanced with glass surface
                ClipRRect(
                  borderRadius: AppRadius.mediumRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.mediumRadius,
                        color: Colors.black.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppTheme.goldColor,
                          width: 1.0,
                        ),
                        boxShadow: [
                          // Ambient shadow (far, soft)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                          // Definition shadow (close, sharp)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: AppRadius.mediumRadius,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.5],
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: StaticNoiseOverlay(
                        opacity: 0.04,
                        density: 0.4,
                        child: Center(
                          child: Text(
                            abbreviation,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 14,
                                  minSize: 12, maxSize: 16),
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.lg),

                // Book name and chapter count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 16,
                              minSize: 14, maxSize: 18),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chapterCount == 1
                            ? l10n.chapterCount(chapterCount)
                            : l10n.chaptersCount(chapterCount),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 12,
                              minSize: 10, maxSize: 14),
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
  }

  Future<void> _showChapterSelector(String book) async {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final localizedBookName = BookNameService.getBookName(book, language);

    // Get chapter count from BibleBook metadata (faster than database query)
    final bibleBook = _bibleBooks.firstWhere(
      (b) => b.matchesName(book),
      orElse: () => BibleBook(
        id: 0,
        testament: 'Old Testament',
        englishName: book,
        spanishName: book,
        abbreviation: 'Bk',
        chapters: 0,
      ),
    );
    final chapterCount = bibleBook.chapters;

    if (!mounted) return;

    showBlurredBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          const borderRadius =
              BorderRadius.vertical(top: Radius.circular(AppRadius.xxl));

          // ✅ Build sheet content
          Widget sheetContent = Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xs / 4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.selectChapterBook(localizedBookName),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 20,
                        minSize: 18, maxSize: 24),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: chapterCount,
                  itemBuilder: (context, index) {
                    final chapterNum = index + 1;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        NavigationService.goToChapterReading(
                          book: book,
                          startChapter: chapterNum,
                          endChapter: chapterNum,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.2),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: AppRadius.mediumRadius,
                          border: Border.all(
                            color: AppTheme.goldColor,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$chapterNum',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 16,
                                  minSize: 14, maxSize: 18),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );

          // ✅ Build glass content with BackdropFilter blur
          Widget glassContent = ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E293B).withValues(alpha: 0.95),
                      const Color(0xFF0F172A).withValues(alpha: 0.98),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: sheetContent,
              ),
            ),
          );

          // ✅ Add noise overlay
          glassContent = ClipRRect(
            borderRadius: borderRadius,
            child: StaticNoiseOverlay(
              opacity: 0.04,
              density: 0.4,
              child: glassContent,
            ),
          );

          // ✅ Wrap with container for dual shadows and light simulation
          return Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              // Enhanced dual shadows for realistic depth
              boxShadow: [
                // Ambient shadow (far, soft)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, -10),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
                // Definition shadow (close, sharp)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, -4),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            // Light simulation via foreground decoration
            foregroundDecoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5],
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
            child: glassContent,
          );
        },
      ),
    );
  }

  Widget _buildVerseResults() {
    final l10n = AppLocalizations.of(context);
    if (_verseSearchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: ResponsiveUtils.iconSize(context, 64),
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noVersesFound,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 18,
                      minSize: 16, maxSize: 20),
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tryDifferentSearchTerm,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            l10n.versesFoundCount(_verseSearchResults.length),
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 14,
                  minSize: 12, maxSize: 16),
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _verseSearchResults.length,
            itemBuilder: (context, index) =>
                _buildVerseCard(_verseSearchResults[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildVerseCard(BibleVerse verse) {
    final reference = '${verse.book} ${verse.chapter}:${verse.verseNumber}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          NavigationService.goToChapterReading(
            book: verse.book,
            startChapter: verse.chapter,
            endChapter: verse.chapter,
          );
        },
        child: FrostedGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.goldColor.withValues(alpha: 0.3),
                          AppTheme.goldColor.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: AppRadius.smallRadius,
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      reference,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12,
                            minSize: 10, maxSize: 14),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: ResponsiveUtils.iconSize(context, 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                verse.text,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 15,
                      minSize: 13, maxSize: 17),
                  color: AppColors.primaryText,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
