/// Tests for BibleDataLoaderWeb
///
/// These tests validate the web-specific Bible data loading functionality.
///
/// Note: These are integration tests that require the actual SQL files
/// to be present in the assets directory.
import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/core/database/sql_js_helper.dart';
import 'package:everyday_christian/core/services/bible_data_loader_web.dart';

void main() {
  group('BibleDataLoaderWeb', () {
    late SqlJsDatabase db;
    late BibleDataLoaderWeb loader;

    setUp(() async {
      // Get database instance
      db = await SqlJsHelper.database;
      loader = BibleDataLoaderWeb(db);

      // Clear any existing data
      try {
        await loader.clearBibleData();
      } catch (e) {
        // Ignore if table doesn't exist
      }
    });

    test('isBibleDataLoaded returns false when no data', () async {
      final isLoaded = await loader.isBibleDataLoaded();
      expect(isLoaded, false);
    });

    test('loadBibleData loads all verses with progress tracking', () async {
      // Track progress updates
      final progressUpdates = <double>[];

      await for (final progress in loader.loadBibleData()) {
        progressUpdates.add(progress);
        print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
      }

      // Verify progress tracking
      expect(progressUpdates.isNotEmpty, true);
      expect(progressUpdates.first, 0.0);
      expect(progressUpdates.last, 1.0);

      // Verify data is loaded
      final isLoaded = await loader.isBibleDataLoaded();
      expect(isLoaded, true);

      // Verify verse counts
      final stats = await loader.getLoadingStats();
      print('Stats: $stats');

      expect(stats['english_verses'], 31103);
      expect(stats['spanish_verses'], 31084);
      expect(stats['total_verses'], 62187);
      expect(stats['is_complete'], true);
    }, timeout: const Timeout(Duration(minutes: 5))); // Loading can take time

    test('loadEnglishBible loads only English verses', () async {
      await loader.loadEnglishBible();

      final stats = await loader.getLoadingStats();
      expect(stats['english_verses'], 31103);
      expect(stats['spanish_verses'], 0);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('loadSpanishBible loads only Spanish verses', () async {
      await loader.loadSpanishBible();

      final stats = await loader.getLoadingStats();
      expect(stats['english_verses'], 0);
      expect(stats['spanish_verses'], 31084);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('getLoadingStats returns correct structure', () async {
      final stats = await loader.getLoadingStats();

      expect(stats.containsKey('english_verses'), true);
      expect(stats.containsKey('spanish_verses'), true);
      expect(stats.containsKey('total_verses'), true);
      expect(stats.containsKey('expected_total'), true);
      expect(stats.containsKey('is_complete'), true);
      expect(stats['expected_total'], 62187);
    });

    test('clearBibleData removes all verses', () async {
      // Load data first
      await loader.loadEnglishBible();

      // Verify data exists
      var isLoaded = await loader.isBibleDataLoaded();
      expect(isLoaded, true);

      // Clear data
      await loader.clearBibleData();

      // Verify data is cleared
      isLoaded = await loader.isBibleDataLoaded();
      expect(isLoaded, false);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('loadBibleData is idempotent', () async {
      // Load data first time
      await for (final _ in loader.loadBibleData()) {
        // Consume stream
      }

      final stats1 = await loader.getLoadingStats();

      // Load data second time (should skip)
      await for (final _ in loader.loadBibleData()) {
        // Should complete immediately
      }

      final stats2 = await loader.getLoadingStats();

      // Stats should be identical
      expect(stats1['total_verses'], stats2['total_verses']);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('loaded verses have correct schema', () async {
      await loader.loadEnglishBible();

      // Query a specific verse
      final result = await db.query(
        'bible_verses',
        where: 'book = ? AND chapter = ? AND verse = ? AND language = ?',
        whereArgs: ['Genesis', 1, 1, 'en'],
        limit: 1,
      );

      expect(result.length, 1);
      final verse = result.first;

      // Verify schema
      expect(verse.containsKey('id'), true);
      expect(verse.containsKey('version'), true);
      expect(verse.containsKey('book'), true);
      expect(verse.containsKey('chapter'), true);
      expect(verse.containsKey('verse'), true);
      expect(verse.containsKey('text'), true);
      expect(verse.containsKey('language'), true);

      // Verify values
      expect(verse['version'], 'WEB');
      expect(verse['book'], 'Genesis');
      expect(verse['chapter'], 1);
      expect(verse['verse'], 1);
      expect(verse['language'], 'en');
      expect((verse['text'] as String).isNotEmpty, true);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('BibleLoadException has proper error details', () {
      final exception = BibleLoadException(
        'Test error',
        sqlFile: 'test.sql',
        originalError: 'Original error message',
      );

      expect(exception.message, 'Test error');
      expect(exception.sqlFile, 'test.sql');
      expect(exception.originalError, 'Original error message');

      final string = exception.toString();
      expect(string.contains('Test error'), true);
      expect(string.contains('test.sql'), true);
      expect(string.contains('Original error message'), true);
    });
  });

  group('BibleDataLoaderWeb - Error Handling', () {
    test('throws BibleLoadException on invalid SQL file', () async {
      final db = await SqlJsHelper.database;
      final loader = BibleDataLoaderWeb(db);

      // This should throw because the file doesn't exist
      expect(
        () => loader.loadEnglishBible(),
        throwsA(isA<BibleLoadException>()),
      );
    });
  });
}
