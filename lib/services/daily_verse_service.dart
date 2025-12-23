import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../models/bible_verse.dart';

/// Service for managing daily verse of the day
///
/// Features:
/// - Fetches random verse once per day at midnight
/// - Persists current daily verse
/// - Handles verse rotation and caching
class DailyVerseService {
  static final DailyVerseService _instance = DailyVerseService._internal();
  factory DailyVerseService() => _instance;
  DailyVerseService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Shared preferences keys
  static const String _currentVerseIdKey = 'daily_verse_id';
  static const String _currentVerseTextKey = 'daily_verse_text';
  static const String _currentVerseReferenceKey = 'daily_verse_reference';
  static const String _lastUpdateDateKey = 'daily_verse_last_update';

  BibleVerse? _cachedVerse;

  /// Initialize the daily verse service
  Future<void> initialize() async {
    developer.log('[DailyVerseService] Initialized', name: 'DailyVerseService');
  }

  /// Get the current daily verse
  ///
  /// Returns cached verse if still valid for today,
  /// otherwise fetches and caches a new one
  ///
  /// [translation] - Bible translation to use (WEB for English, RVR1909 for Spanish)
  Future<BibleVerse?> getDailyVerse({bool forceRefresh = false, String? translation}) async {
    try {
      // Check if we need to refresh
      if (!forceRefresh && _cachedVerse != null) {
        if (await _isVerseFreshForToday()) {
          developer.log('[DailyVerseService] 📖 Returning cached verse: ${_cachedVerse!.reference}', name: 'DailyVerseService');
          return _cachedVerse;
        }
      }

      // Load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateDateKey);

      if (!forceRefresh && lastUpdate != null) {
        final lastUpdateDate = DateTime.parse(lastUpdate);
        if (_isSameDay(lastUpdateDate, DateTime.now())) {
          // Verse is still fresh, load from cache
          final verseText = prefs.getString(_currentVerseTextKey);
          final verseReference = prefs.getString(_currentVerseReferenceKey);
          final verseId = prefs.getInt(_currentVerseIdKey);

          if (verseText != null && verseReference != null) {
            // Create minimal BibleVerse from cache using fromMap
            _cachedVerse = BibleVerse.fromMap({
              'id': verseId,
              'text': verseText,
              'reference': verseReference,
              'book': '',
              'chapter': 0,
              'verse_number': 0,
              'translation': 'WEB',
              'themes': '[]',
              'category': 'general',
            });
            developer.log('[DailyVerseService] 📖 Loaded verse from cache: ${_cachedVerse!.reference}', name: 'DailyVerseService');
            return _cachedVerse;
          }
        }
      }

      // Fetch new verse
      developer.log('[DailyVerseService] 🔄 Fetching new daily verse...', name: 'DailyVerseService');
      final verseData = await _db.getRandomVerse();

      if (verseData == null) {
        developer.log('[DailyVerseService] ⚠️ No verse found in database', name: 'DailyVerseService');
        return null;
      }

      // Convert to BibleVerse model using fromMap factory
      final verse = BibleVerse.fromMap(verseData);

      // Cache the verse
      await _cacheVerse(verse);
      _cachedVerse = verse;

      developer.log('[DailyVerseService] ✅ New daily verse set: ${verse.reference}', name: 'DailyVerseService');

      return verse;
    } catch (e) {
      developer.log('[DailyVerseService] ❌ Error getting daily verse: $e', name: 'DailyVerseService');
      return null;
    }
  }

  /// Force refresh the daily verse (useful for testing or manual refresh)
  Future<BibleVerse?> refreshDailyVerse({String? translation}) async {
    developer.log('[DailyVerseService] 🔄 Force refreshing daily verse', name: 'DailyVerseService');
    return await getDailyVerse(forceRefresh: true, translation: translation);
  }

  /// Check if the app should check for new verse
  ///
  /// Call this on app launch to ensure verse is up-to-date
  ///
  /// [translation] - Bible translation code (WEB or RVR1909)
  Future<void> checkAndUpdateVerse({String? translation}) async {
    try {
      if (!(await _isVerseFreshForToday())) {
        developer.log('[DailyVerseService] 🔔 Verse needs update, refreshing', name: 'DailyVerseService');
        await getDailyVerse(forceRefresh: true, translation: translation);
      } else {
        developer.log('[DailyVerseService] ✅ Verse is up-to-date', name: 'DailyVerseService');
      }
    } catch (e) {
      developer.log('[DailyVerseService] ⚠️ Error checking verse update: $e', name: 'DailyVerseService');
    }
  }

  /// Cache verse to SharedPreferences
  Future<void> _cacheVerse(BibleVerse verse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verseId = verse.id;
      if (verseId != null) {
        await prefs.setInt(_currentVerseIdKey, verseId);
      }
      await prefs.setString(_currentVerseTextKey, verse.text);
      await prefs.setString(_currentVerseReferenceKey, verse.reference);
      await prefs.setString(_lastUpdateDateKey, DateTime.now().toIso8601String());

      developer.log('[DailyVerseService] 💾 Verse cached to SharedPreferences', name: 'DailyVerseService');
    } catch (e) {
      developer.log('[DailyVerseService] ⚠️ Failed to cache verse: $e', name: 'DailyVerseService');
    }
  }

  /// Check if cached verse is fresh for today
  Future<bool> _isVerseFreshForToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateDateKey);

      if (lastUpdate == null) return false;

      final lastUpdateDate = DateTime.parse(lastUpdate);
      return _isSameDay(lastUpdateDate, DateTime.now());
    } catch (e) {
      developer.log('[DailyVerseService] ⚠️ Error checking verse freshness: $e', name: 'DailyVerseService');
      return false;
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Clear cached verse (for testing)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentVerseIdKey);
      await prefs.remove(_currentVerseTextKey);
      await prefs.remove(_currentVerseReferenceKey);
      await prefs.remove(_lastUpdateDateKey);

      _cachedVerse = null;

      developer.log('[DailyVerseService] 🗑️ Cache cleared', name: 'DailyVerseService');
    } catch (e) {
      developer.log('[DailyVerseService] ⚠️ Error clearing cache: $e', name: 'DailyVerseService');
    }
  }
}
