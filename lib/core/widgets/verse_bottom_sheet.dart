import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import '../../core/database/models/bible_verse.dart';
import '../../core/database/database_helper.dart';
import '../../theme/app_theme.dart';
import '../../screens/chapter_reading_screen.dart';
import '../providers/app_providers.dart';
import 'app_snackbar.dart';
import '../../models/bible_verse.dart' as app_models;
import '../../utils/blur_dialog_utils.dart';
import '../../widgets/noise_overlay.dart';

/// Model for parsed verse reference
class VerseReference {
  final String book;
  final int chapter;
  final int verse;

  VerseReference({
    required this.book,
    required this.chapter,
    required this.verse,
  });

  @override
  String toString() => '$book $chapter:$verse';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseReference &&
          runtimeType == other.runtimeType &&
          book == other.book &&
          chapter == other.chapter &&
          verse == other.verse;

  @override
  int get hashCode => book.hashCode ^ chapter.hashCode ^ verse.hashCode;
}

/// Provider for loading verse context (verse + 2 before + 2 after)
final verseContextProvider = FutureProvider.family<List<BibleVerse>, VerseReference>(
  (ref, verseRef) async {
    try {
      // Get database instance
      final db = await DatabaseHelper.instance.database;

      // Calculate verse range
      final startVerse = max(1, verseRef.verse - 2);
      final endVerse = verseRef.verse + 2;

      // Query bible_verses table for context verses
      final results = await db.query(
        'bible_verses',
        where: 'book = ? AND chapter = ? AND verse >= ? AND verse <= ?',
        whereArgs: [verseRef.book, verseRef.chapter, startVerse, endVerse],
        orderBy: 'verse ASC',
      );

      if (results.isEmpty) {
        throw Exception('Verse not found: ${verseRef.toString()}');
      }

      return results.map((map) => BibleVerse.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to load verse context: $e');
    }
  },
);

/// Quick verse viewer bottom sheet
class VerseBottomSheet extends ConsumerWidget {
  final String reference;

  const VerseBottomSheet({
    super.key,
    required this.reference,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse reference
    final parsed = _parseReference(reference);

    if (parsed == null) {
      return _buildErrorSheet(context, 'Invalid verse reference: $reference');
    }

    // Load verse + context
    final versesAsync = ref.watch(verseContextProvider(parsed));

    const borderRadius = BorderRadius.vertical(top: Radius.circular(AppRadius.xxl));

    // ✅ Build main content
    Widget sheetContent = versesAsync.when(
      loading: () => _buildLoading(),
      error: (error, _) => _buildErrorSheet(context, error.toString()),
      data: (verses) => _buildContent(context, ref, verses, parsed),
    );

    // ✅ Build glass content with BackdropFilter blur
    Widget glassContent = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
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
  }

  /// Build loading state
  Widget _buildLoading() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading verse...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorSheet(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load verse',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build main content
  Widget _buildContent(BuildContext context, WidgetRef ref, List<BibleVerse> verses, VerseReference parsed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        _buildHeader(context, parsed),

        // Verse list
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: verses.map((verse) {
                final isTargetVerse = verse.verseNumber == parsed.verse;
                return _buildVerseItem(verse, isTargetVerse);
              }).toList(),
            ),
          ),
        ),

        // Action buttons
        _buildActionButtons(context, ref, verses, parsed),
      ],
    );
  }

  /// Build header
  Widget _buildHeader(BuildContext context, VerseReference parsed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parsed.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'WEB',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: AppRadius.mediumRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              iconSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual verse item
  Widget _buildVerseItem(BibleVerse verse, bool isTargetVerse) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTargetVerse
              ? [
                  AppTheme.primaryColor.withValues(alpha: 0.3),
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                ]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isTargetVerse
              ? AppTheme.primaryColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: isTargetVerse ? 2 : 1,
        ),
        boxShadow: isTargetVerse
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse number indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTargetVerse
                    ? [
                        AppTheme.primaryColor,
                        AppTheme.accentColor,
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.1),
                      ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isTargetVerse
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '${verse.verseNumber}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isTargetVerse ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Verse text
          Expanded(
            child: Text(
              verse.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTargetVerse ? 17 : 16,
                fontWeight: isTargetVerse ? FontWeight.w600 : FontWeight.w400,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, List<BibleVerse> verses, VerseReference parsed) {
    // Find the target verse for sharing
    final targetVerse = verses.firstWhere(
      (v) => v.verseNumber == parsed.verse,
      orElse: () => verses.first,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0.98),
            Colors.transparent,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Read Full Chapter button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChapterReadingScreen(
                      book: parsed.book,
                      startChapter: parsed.chapter,
                      endChapter: parsed.chapter,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book, size: 20),
              label: const Text('Read Chapter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Share button
          _buildIconButton(
            context,
            icon: Icons.share,
            onPressed: () => _shareVerse(context, ref, targetVerse),
          ),
          const SizedBox(width: 12),
          // Copy button
          _buildIconButton(
            context,
            icon: Icons.copy,
            onPressed: () => _copyVerse(context, targetVerse),
          ),
        ],
      ),
    );
  }

  /// Build icon button
  Widget _buildIconButton(BuildContext context, {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  /// Parse verse reference
  VerseReference? _parseReference(String ref) {
    try {
      // Handle formats: "John 3:16", "1 John 3:16", "2 Corinthians 5:17"
      final parts = ref.trim().split(' ');
      if (parts.length < 2) return null;

      // Find the last part with ":"
      int chapterVerseIndex = -1;
      for (int i = parts.length - 1; i >= 0; i--) {
        if (parts[i].contains(':')) {
          chapterVerseIndex = i;
          break;
        }
      }

      if (chapterVerseIndex == -1) return null;

      // Book name is everything before the chapter:verse
      final book = parts.sublist(0, chapterVerseIndex).join(' ');

      // Parse chapter:verse
      final chapterVerse = parts[chapterVerseIndex].split(':');
      if (chapterVerse.length != 2) return null;

      final chapter = int.tryParse(chapterVerse[0]);
      final verse = int.tryParse(chapterVerse[1]);

      if (chapter == null || verse == null || book.isEmpty) return null;

      return VerseReference(
        book: book,
        chapter: chapter,
        verse: verse,
      );
    } catch (e) {
      return null;
    }
  }

  /// Share verse
  Future<void> _shareVerse(BuildContext context, WidgetRef ref, BibleVerse verse) async {
    final shareText = '"${verse.text}"\n\n${verse.reference} (${verse.translation})\n\nShared from Everyday Christian';

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
        ),
      );

      // Only proceed if share was successful (not dismissed/cancelled)
      if (result.status == ShareResultStatus.success) {
        final appVerse = app_models.BibleVerse(
          id: verse.id,
          book: verse.book,
          chapter: verse.chapter,
          verseNumber: verse.verseNumber,
          text: verse.text,
          translation: verse.translation,
          reference: verse.reference,
          themes: verse.themes,
          category: verse.themes.isNotEmpty ? verse.themes.first : 'general',
        );

        await ref.read(unifiedVerseServiceProvider).recordSharedVerse(appVerse);

        ref.invalidate(sharedVersesProvider);
        ref.invalidate(sharedVersesCountProvider);
        ref.invalidate(totalSharesCountProvider);
        // Don't invalidate savedVersesCountProvider - sharing doesn't affect saved count

        if (!context.mounted) return;
        AppSnackBar.show(
          context,
          message: 'Verse shared successfully!',
          icon: Icons.share,
          iconColor: AppTheme.primaryColor,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Unable to share verse: $e',
      );
    }
  }

  /// Copy verse to clipboard
  Future<void> _copyVerse(BuildContext context, BibleVerse verse) async {
    final copyText = '"${verse.text}" - ${verse.reference} (${verse.translation})';
    await Clipboard.setData(ClipboardData(text: copyText));

    // Show snackbar confirmation
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B), // slate-800
                  Color(0xFF0F172A), // slate-900
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.goldColor,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verse copied to clipboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

/// Helper function to show verse bottom sheet
void showVerseBottomSheet(BuildContext context, String reference) {
  showBlurredBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VerseBottomSheet(reference: reference),
  );
}
