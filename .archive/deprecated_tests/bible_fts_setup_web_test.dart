/// Tests for BibleFtsSetupWeb service
///
/// These tests validate FTS5 index creation, population, and search functionality.
/// They require Bible data to be loaded first via BibleDataLoaderWeb.
///
/// Test Coverage:
/// - FTS table creation
/// - Trigger creation
/// - Data population
/// - Search functionality
/// - Index integrity
/// - Rebuild operations
library bible_fts_setup_web_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/core/database/sql_js_helper.dart';
import 'package:everyday_christian/core/services/bible_data_loader_web.dart';
import 'package:everyday_christian/core/services/bible_fts_setup_web.dart';

void main() {
  group('BibleFtsSetupWeb', () {
    late SqlJsDatabase db;
    late BibleDataLoaderWeb loader;
    late BibleFtsSetupWeb ftsSetup;

    setUpAll(() async {
      // Initialize database
      db = await SqlJsHelper.database;
      loader = BibleDataLoaderWeb(db);
      ftsSetup = BibleFtsSetupWeb(db);

      // Load Bible data (required for FTS setup)
      print('Loading Bible data...');
      await for (final progress in loader.loadBibleData()) {
        if (progress == 1.0) {
          print('Bible data loaded successfully');
        }
      }
    });

    tearDownAll(() async {
      await SqlJsHelper.close();
    });

    test('isFtsSetup returns false before setup', () async {
      // Drop any existing FTS
      await ftsSetup.dropFts();

      final isSetup = await ftsSetup.isFtsSetup();
      expect(isSetup, false);
    });

    test('setupFts creates FTS table and populates it', () async {
      // Drop any existing FTS
      await ftsSetup.dropFts();

      // Setup FTS
      double? lastProgress;
      await ftsSetup.setupFts(onProgress: (p) {
        lastProgress = p;
      });

      // Verify progress reached 100%
      expect(lastProgress, 1.0);

      // Verify FTS is now setup
      final isSetup = await ftsSetup.isFtsSetup();
      expect(isSetup, true);
    });

    test('FTS table contains all verses', () async {
      final result = await db.query(
        'bible_verses_fts',
        columns: ['COUNT(*) as count'],
      );

      final count = result.first['count'] as int;
      expect(count, 62187); // 31,103 English + 31,084 Spanish
    });

    test('FTS search for "love" returns results', () async {
      final results = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'love'",
        limit: 10,
      );

      expect(results.isNotEmpty, true);
      expect(results.length, lessThanOrEqualTo(10));

      // Verify each result contains "love" in the text
      for (final verse in results) {
        final text = verse['text'] as String;
        expect(
          text.toLowerCase().contains('love'),
          true,
          reason: 'Verse should contain "love": $text',
        );
      }
    });

    test('FTS search with book filter works', () async {
      final results = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'book:John'",
        limit: 10,
      );

      expect(results.isNotEmpty, true);

      // Verify each result is from John
      for (final verse in results) {
        final book = verse['book'] as String;
        expect(book, 'John');
      }
    });

    test('FTS search with language filter works', () async {
      final results = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'language:es'",
        limit: 10,
      );

      expect(results.isNotEmpty, true);

      // Verify each result is Spanish
      for (final verse in results) {
        final language = verse['language'] as String;
        expect(language, 'es');
      }
    });

    test('FTS search with combined filters works', () async {
      final results = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'book:Juan AND Dios'",
        limit: 10,
      );

      expect(results.isNotEmpty, true);

      // Verify each result is from Juan (Spanish John)
      for (final verse in results) {
        final book = verse['book'] as String;
        expect(book, 'Juan');

        // Verify contains "Dios"
        final text = verse['text'] as String;
        expect(
          text.contains('Dios'),
          true,
          reason: 'Spanish verse should contain "Dios": $text',
        );
      }
    });

    test('testFts returns comprehensive stats', () async {
      final stats = await ftsSetup.testFts();

      expect(stats.containsKey('search_love'), true);
      expect(stats.containsKey('search_john_god'), true);
      expect(stats.containsKey('search_spanish'), true);
      expect(stats.containsKey('total_indexed'), true);
      expect(stats.containsKey('expected_count'), true);
      expect(stats.containsKey('is_complete'), true);

      expect(stats['total_indexed'], 62187);
      expect(stats['expected_count'], 62187);
      expect(stats['is_complete'], true);

      print('FTS Test Stats: $stats');
    });

    test('triggers sync FTS when inserting new verse', () async {
      // Insert a test verse
      await db.insert('bible_verses', {
        'version': 'TEST',
        'book': 'TestBook',
        'chapter': 1,
        'verse': 1,
        'text': 'This is a test verse about faith and hope',
        'language': 'en',
        'themes': null,
        'category': null,
        'reference': 'TestBook 1:1',
      });

      // Search for the test verse
      final results = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'book:TestBook AND faith'",
      );

      expect(results.isNotEmpty, true);
      expect(results.first['text'], contains('faith and hope'));

      // Cleanup: delete test verse
      await db.delete(
        'bible_verses',
        where: 'version = ?',
        whereArgs: ['TEST'],
      );
    });

    test('triggers sync FTS when updating verse', () async {
      // Insert a test verse
      final id = await db.insert('bible_verses', {
        'version': 'TEST',
        'book': 'TestBook',
        'chapter': 1,
        'verse': 1,
        'text': 'Original text',
        'language': 'en',
        'themes': null,
        'category': null,
        'reference': 'TestBook 1:1',
      });

      // Update the verse
      await db.update(
        'bible_verses',
        {'text': 'Updated text with uniqueword123'},
        where: 'id = ?',
        whereArgs: [id],
      );

      // Search for updated text
      final results = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'uniqueword123'",
      );

      expect(results.isNotEmpty, true);
      expect(results.first['text'], contains('uniqueword123'));

      // Cleanup
      await db.delete('bible_verses', where: 'id = ?', whereArgs: [id]);
    });

    test('triggers sync FTS when deleting verse', () async {
      // Insert a test verse
      final id = await db.insert('bible_verses', {
        'version': 'TEST',
        'book': 'TestBook',
        'chapter': 1,
        'verse': 1,
        'text': 'Verse to be deleted with uniqueword456',
        'language': 'en',
        'themes': null,
        'category': null,
        'reference': 'TestBook 1:1',
      });

      // Verify it's in FTS
      var results = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'uniqueword456'",
      );
      expect(results.isNotEmpty, true);

      // Delete the verse
      await db.delete('bible_verses', where: 'id = ?', whereArgs: [id]);

      // Verify it's removed from FTS
      results = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'uniqueword456'",
      );
      expect(results.isEmpty, true);
    });

    test('rebuildFts recreates index successfully', () async {
      // Rebuild FTS
      await ftsSetup.rebuildFts(onProgress: (p) {
        // Progress tracking
      });

      // Verify FTS is setup
      final isSetup = await ftsSetup.isFtsSetup();
      expect(isSetup, true);

      // Verify all verses are indexed
      final result = await db.query(
        'bible_verses_fts',
        columns: ['COUNT(*) as count'],
      );
      final count = result.first['count'] as int;
      expect(count, 62187);
    });

    test('dropFts removes FTS table and triggers', () async {
      // Drop FTS
      await ftsSetup.dropFts();

      // Verify FTS is not setup
      final isSetup = await ftsSetup.isFtsSetup();
      expect(isSetup, false);

      // Verify table doesn't exist
      final tables = await db.query(
        'sqlite_master',
        where: "type='table' AND name='bible_verses_fts'",
      );
      expect(tables.isEmpty, true);
    });

    test('setupFts is idempotent (safe to call multiple times)', () async {
      // Setup FTS
      await ftsSetup.setupFts();

      // Get initial count
      final result1 = await db.query(
        'bible_verses_fts',
        columns: ['COUNT(*) as count'],
      );
      final count1 = result1.first['count'] as int;

      // Setup again (should be no-op)
      await ftsSetup.setupFts();

      // Verify count is the same
      final result2 = await db.query(
        'bible_verses_fts',
        columns: ['COUNT(*) as count'],
      );
      final count2 = result2.first['count'] as int;

      expect(count2, count1);
      expect(count2, 62187);
    });

    test('FTS search performance is acceptable', () async {
      final stopwatch = Stopwatch()..start();

      final results = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'faith'",
        limit: 100,
      );

      stopwatch.stop();

      expect(results.isNotEmpty, true);
      print('FTS search time: ${stopwatch.elapsedMilliseconds}ms for ${results.length} results');

      // Search should complete in under 500ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('FTS supports phrase search', () async {
      final results = await db.query(
        'bible_verses_fts',
        where: 'bible_verses_fts MATCH \'"faith hope love"\'',
      );

      // Should return verses with all three words
      expect(results, isNotEmpty);

      for (final verse in results) {
        final text = verse['text'] as String;
        final lowerText = text.toLowerCase();
        expect(lowerText.contains('faith'), true);
        expect(lowerText.contains('hope'), true);
        expect(lowerText.contains('love'), true);
      }
    });

    test('FTS supports Boolean operators', () async {
      // Test OR
      final orResults = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'faith OR hope'",
        limit: 10,
      );
      expect(orResults.isNotEmpty, true);

      // Test AND
      final andResults = await db.query(
        'bible_verses_fts',
        where: "bible_verses_fts MATCH 'faith AND hope'",
        limit: 10,
      );
      expect(andResults.isNotEmpty, true);

      // AND should return fewer or equal results than OR
      // (Not always true with LIMIT, but generally true)
    });
  });
}
