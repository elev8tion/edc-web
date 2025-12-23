import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';
import '../components/prayer_share_widget.dart';
import '../core/models/prayer_request.dart';
import '../core/services/database_service.dart';
import '../core/services/achievement_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/platform_share_helper.dart';

/// Service for capturing and sharing prayer requests with branding
class PrayerShareService {
  final ScreenshotController _screenshotController = ScreenshotController();
  final DatabaseService? _databaseService;
  final AchievementService? _achievementService;
  final _uuid = const Uuid();

  PrayerShareService({
    DatabaseService? databaseService,
    AchievementService? achievementService,
  })  : _databaseService = databaseService,
        _achievementService = achievementService;

  ScreenshotController get controller => _screenshotController;

  /// Captures a prayer request as a branded image and shares it
  Future<void> sharePrayer({
    required BuildContext context,
    required PrayerRequest prayer,
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
          child: PrayerShareWidget(
            prayer: prayer,
            locale: locale,
            l10n: l10n,
          ),
        ),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 100),
      );

      // Share using platform-aware helper
      final status = prayer.isAnswered ? 'Answered Prayer' : 'Prayer Request';
      final filename = 'edc_prayer_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final shareText = '$status: ${prayer.title}\n\nJoin me in prayer with Everyday Christian 🙏\nhttps://everydaychristian.app';

      await PlatformShareHelper.shareImage(
        imageBytes: imageBytes,
        text: shareText,
        subject: '$status - ${prayer.title}',
        filename: filename,
      );

      // Track the share in database
      if (_databaseService != null) {
        await _trackShare(prayer);
      }
    } catch (e) {
      debugPrint('Error sharing prayer: $e');
      rethrow;
    }
  }

  /// Track a prayer share in the database
  Future<void> _trackShare(PrayerRequest prayer) async {
    try {
      final db = await _databaseService!.database;
      await db.insert('shared_prayers', {
        'id': _uuid.v4(),
        'prayer_id': prayer.id,
        'title': prayer.title,
        'category': prayer.categoryId,
        'is_answered': prayer.isAnswered ? 1 : 0,
        'shared_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Check for Disciple achievement (10 total shares across all types)
      if (_achievementService != null) {
        await _achievementService!.checkAllSharesAchievement();
      }
    } catch (e) {
      debugPrint('Error tracking prayer share: $e');
      // Don't rethrow - sharing succeeded, tracking failure shouldn't break UX
    }
  }
}