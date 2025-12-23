import 'dart:convert';
import 'package:flutter/services.dart';
import 'database_service.dart';
import '../database/sql_js_helper.dart'; // Import custom ConflictAlgorithm
import '../logging/app_logger.dart';

/// Loads 424 devotionals from JSON batch files (Nov 2025 - Dec 2026)
class DevotionalContentLoader {
  final DatabaseService _database;
  static final AppLogger _logger = AppLogger.instance;

  DevotionalContentLoader(this._database);

  /// Load all devotionals from 14 monthly JSON batch files
  ///
  /// [language] - Language code ('en' or 'es'). Defaults to 'en'.
  Future<void> loadDevotionals({String language = 'en'}) async {
    try {
      final db = await _database.database;

      // Check current language in database
      final meta = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['devotional_language'],
      );
      final currentLang = meta.isNotEmpty ? meta.first['value'] as String : null;

      // If language changed, clear existing devotionals
      if (currentLang != null && currentLang != language) {
        _logger.info('Language changed from $currentLang to $language, reloading devotionals...');
        await db.delete('devotionals');
        await db.delete('app_metadata', where: 'key = ?', whereArgs: ['devotional_language']);
      }

      // Check if devotionals already exist for current language
      final existing = await db.query('devotionals', limit: 1);
      if (existing.isNotEmpty && currentLang == language) {
        _logger.info('Devotionals already loaded for $language, skipping content load');
        return;
      }

      _logger.info('Loading 424 devotionals from JSON batches ($language)...');

      // Load all 14 monthly batch files
      final batches = [
        'batch_01_november_2025.json',
        'batch_02_december_2025.json',
        'batch_03_january_2026.json',
        'batch_04_february_2026.json',
        'batch_05_march_2026.json',
        'batch_06_april_2026.json',
        'batch_07_may_2026.json',
        'batch_08_june_2026.json',
        'batch_09_july_2026.json',
        'batch_10_august_2026.json',
        'batch_11_september_2026.json',
        'batch_12_october_2026.json',
        'batch_13_november_2026.json',
        'batch_14_december_2026.json',
      ];

      int totalLoaded = 0;

      for (final batchFile in batches) {
        final devotionals = await _loadBatchFile(batchFile, language);

        for (final devotional in devotionals) {
          await db.insert(
            'devotionals',
            _devotionalToMap(devotional),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          totalLoaded++;
        }

        _logger.info('Loaded batch: $batchFile (${devotionals.length} devotionals)');
      }

      // Store the language in app_metadata for future reference
      await db.insert(
        'app_metadata',
        {
          'key': 'devotional_language',
          'value': language,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.info('✅ Successfully loaded $totalLoaded devotionals in $language');
    } catch (e, stackTrace) {
      _logger.error('Failed to load devotionals: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load a single JSON batch file from assets
  Future<List<Map<String, dynamic>>> _loadBatchFile(String filename, String language) async {
    try {
      final path = 'assets/devotionals/$language/$filename';
      final jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.error('Failed to load batch file $filename ($language): $e');
      rethrow;
    }
  }

  /// Convert JSON devotional to database map
  Map<String, dynamic> _devotionalToMap(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'date': json['date'],
      'title': json['title'],
      'opening_scripture_reference': json['openingScripture']['reference'],
      'opening_scripture_text': json['openingScripture']['text'],
      'key_verse_reference': json['keyVerseSpotlight']['reference'],
      'key_verse_text': json['keyVerseSpotlight']['text'],
      'reflection': json['reflection'],
      'life_application': json['lifeApplication'],
      'prayer': json['prayer'],
      'action_step': json['actionStep'],
      'going_deeper': (json['goingDeeper'] as List).join('|||'),
      'reading_time': json['readingTime'],
      'is_completed': 0,
      'completed_date': null,
      'action_step_completed': 0,
    };
  }
}
