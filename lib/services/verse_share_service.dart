import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';
import '../components/verse_share_widget.dart';
import '../models/bible_verse.dart';
import '../core/services/database_service.dart';
import '../core/services/achievement_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/platform_share_helper.dart';

/// Service for capturing and sharing Bible verses with branding
class VerseShareService {
  final ScreenshotController _screenshotController = ScreenshotController();
  final DatabaseService? _databaseService;
  final AchievementService? _achievementService;
  final _uuid = const Uuid();

  VerseShareService({
    DatabaseService? databaseService,
    AchievementService? achievementService,
  })  : _databaseService = databaseService,
        _achievementService = achievementService;

  ScreenshotController get controller => _screenshotController;

  /// Captures a Bible verse as a branded image and shares it
  Future<void> shareVerse({
    required BuildContext context,
    required BibleVerse verse,
    bool showThemes = true,
  }) async {
    try {
      final locale = Localizations.localeOf(context);
      final l10n = AppLocalizations.of(context);

      // Capture the widget as an image
      // Reset text scale to 1.0 for consistent screenshots regardless of user's text size preference
      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Always use 1.0 for screenshots
          ),
          child: VerseShareWidget(
            verse: verse,
            showThemes: showThemes,
            locale: locale,
            l10n: l10n,
          ),
        ),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 100),
      );

      // Share using platform-aware helper
      final filename = 'edc_verse_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final shareText = '${verse.reference} - "${verse.text}"\n\nFind more scripture with Everyday Christian 🙏\nhttps://everydaychristian.app';

      await PlatformShareHelper.shareImage(
        imageBytes: imageBytes,
        text: shareText,
        subject: 'Bible Verse - ${verse.reference}',
        filename: filename,
      );

      // Track the share in database if verse has an id
      if (verse.id != null && _databaseService != null) {
        await _trackShare(verse.id!);
      }
    } catch (e) {
      debugPrint('Error sharing verse: $e');
      rethrow;
    }
  }

  /// Track a verse share in the database
  Future<void> _trackShare(int verseId) async {
    try {
      final db = await _databaseService!.database;

      // Fetch the full verse data to populate all required columns
      final verses = await db.query(
        'bible_verses',
        where: 'id = ?',
        whereArgs: [verseId],
        limit: 1,
      );

      if (verses.isEmpty) return;

      final verseData = verses.first;

      await db.insert('shared_verses', {
        'id': _uuid.v4(),
        'verse_id': verseId,
        'book': verseData['book'] as String,
        'chapter': verseData['chapter'] as int,
        'verse_number': verseData['verse'] as int,
        'reference': '${verseData['book']} ${verseData['chapter']}:${verseData['verse']}',
        'translation': verseData['version'] as String,
        'text': verseData['text'] as String,
        'themes': verseData['themes'] as String?, // May be null
        'channel': 'share_sheet',
        'shared_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Check for sharing achievements (counts ALL share types)
      if (_achievementService != null) {
        await _achievementService.checkAllSharesAchievement();
      }
    } catch (e) {
      debugPrint('Error tracking verse share: $e');
      // Don't rethrow - sharing succeeded, tracking failure shouldn't break UX
    }
  }
}
