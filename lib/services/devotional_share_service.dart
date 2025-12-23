import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';
import '../components/devotional_share_widget.dart';
import '../core/models/devotional.dart';
import '../core/services/database_service.dart';
import '../core/services/achievement_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/platform_share_helper.dart';

/// Service for capturing and sharing devotionals with branding
class DevotionalShareService {
  final ScreenshotController _screenshotController = ScreenshotController();
  final DatabaseService? _databaseService;
  final AchievementService? _achievementService;
  final _uuid = const Uuid();

  DevotionalShareService({
    DatabaseService? databaseService,
    AchievementService? achievementService,
  })  : _databaseService = databaseService,
        _achievementService = achievementService;

  ScreenshotController get controller => _screenshotController;

  /// Captures a devotional as a branded image and shares it
  Future<void> shareDevotional({
    required BuildContext context,
    required Devotional devotional,
    bool showFullReflection = false,
  }) async {
    try {
      // Extract locale and localizations before captureFromWidget
      final locale = Localizations.localeOf(context);
      final l10n = AppLocalizations.of(context);

      // Capture the widget as an image
      // Reset text scale to 1.0 for consistent screenshots regardless of user's text size preference
      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Always use 1.0 for screenshots
          ),
          child: DevotionalShareWidget(
            devotional: devotional,
            showFullReflection: showFullReflection,
            locale: locale,
            l10n: l10n,
          ),
        ),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 100),
      );

      // Share using platform-aware helper
      final filename = 'edc_devotional_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final shareText = '${devotional.title}\n\n"${devotional.keyVerseText}"\n— ${devotional.keyVerseReference}\n\nDaily devotionals with Everyday Christian 🙏\nhttps://everydaychristian.app';

      await PlatformShareHelper.shareImage(
        imageBytes: imageBytes,
        text: shareText,
        subject: 'Daily Devotional - ${devotional.title}',
        filename: filename,
      );

      // Track the share in database
      if (_databaseService != null) {
        await _trackShare(devotional.id);
      }
    } catch (e) {
      debugPrint('Error sharing devotional: $e');
      rethrow;
    }
  }

  /// Track a devotional share in the database
  Future<void> _trackShare(String devotionalId) async {
    try {
      final db = await _databaseService!.database;
      await db.insert('shared_devotionals', {
        'id': _uuid.v4(),
        'devotional_id': devotionalId,
        'shared_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Check for sharing achievements (counts ALL share types)
      if (_achievementService != null) {
        await _achievementService!.checkAllSharesAchievement();
      }
    } catch (e) {
      debugPrint('Error tracking devotional share: $e');
      // Don't rethrow - sharing succeeded, tracking failure shouldn't break UX
    }
  }
}
