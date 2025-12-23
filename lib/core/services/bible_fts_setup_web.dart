/// FTS5 Index Setup for Bible Search on Web
///
/// This service creates and manages Full-Text Search (FTS5) indexes for bible_verses
/// on the web platform. It must be called after BibleDataLoaderWeb completes.
///
/// FTS5 Features:
/// - Fast full-text search across 62,187 verses
/// - External content table for space efficiency
/// - Automatic sync via triggers
/// - Support for advanced search syntax
///
/// Search Syntax Examples:
/// - Basic search: "love"
/// - Book-specific: "book:John AND God"
/// - Language filter: "language:es AND Dios"
/// - Phrase search: "\"faith hope love\""
/// - Boolean: "faith OR hope"
/// - Exclusion: "love NOT fear"
///
/// Architecture:
/// - FTS5 virtual table linked to bible_verses
/// - Triggers keep FTS in sync with data changes
/// - Batch population for performance
/// - Transaction wrapping for speed
///
/// Usage:
/// ```dart
/// final db = await SqlJsHelper.database;
/// final loader = BibleDataLoaderWeb(db);
/// final ftsSetup = BibleFtsSetupWeb(db);
///
/// // Load Bible data first
/// await for (final progress in loader.loadBibleData()) {
///   print('Loading: ${(progress * 100).toFixed(0)}%');
/// }
///
/// // Setup FTS indexes
/// await ftsSetup.setupFts(onProgress: (p) {
///   print('Indexing: ${(p * 100).toFixed(0)}%');
/// });
///
/// // Test search
/// final results = await db.query(
///   'bible_verses_fts',
///   where: "bible_verses_fts MATCH 'love'",
///   limit: 10,
/// );
/// ```
library bible_fts_setup_web;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/sql_js_helper.dart';

/// FTS5 index setup and management for Bible search
///
/// Creates FTS5 virtual tables, populates them, and manages triggers
/// for automatic synchronization with bible_verses table.
class BibleFtsSetupWeb {
  final SqlJsDatabase _db;

  /// Create FTS setup service
  ///
  /// Parameters:
  /// - [_db]: The SqlJsDatabase instance to set up FTS on
  BibleFtsSetupWeb(this._db);

  /// Setup FTS5 indexes for Bible search
  ///
  /// Creates FTS virtual table, populates it, and sets up triggers.
  /// This is a complete setup operation that should be run after
  /// Bible data is loaded.
  ///
  /// Progress tracking:
  /// - 0.00 - 0.05: Check if already setup
  /// - 0.05 - 0.10: Create FTS virtual table
  /// - 0.10 - 0.15: Create triggers
  /// - 0.15 - 0.95: Populate FTS table (80% of work)
  /// - 0.95 - 1.00: Verify integrity
  ///
  /// Parameters:
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// Throws [FtsSetupException] on error.
  ///
  /// Example:
  /// ```dart
  /// await ftsSetup.setupFts(onProgress: (p) {
  ///   setState(() => progress = p);
  /// });
  /// ```
  Future<void> setupFts({Function(double)? onProgress}) async {
    try {
      debugPrint('🔍 [BibleFtsSetupWeb] Starting FTS setup...');

      // Check if already setup (0.00 - 0.05)
      onProgress?.call(0.0);
      if (await isFtsSetup()) {
        debugPrint('🔍 [BibleFtsSetupWeb] ✅ FTS already setup');
        onProgress?.call(1.0);
        return;
      }

      // Create FTS virtual table (0.05 - 0.10)
      onProgress?.call(0.05);
      debugPrint('🔍 [BibleFtsSetupWeb] Creating FTS virtual table...');
      await _createFtsTable();
      onProgress?.call(0.10);

      // Create triggers (0.10 - 0.15)
      debugPrint('🔍 [BibleFtsSetupWeb] Creating triggers...');
      await _createTriggers();
      onProgress?.call(0.15);

      // Populate FTS table (0.15 - 0.95)
      debugPrint('🔍 [BibleFtsSetupWeb] Populating FTS table...');
      await _populateFts(onProgress: (p) {
        // Map 0.0-1.0 to 0.15-0.95
        onProgress?.call(0.15 + (p * 0.80));
      });
      onProgress?.call(0.95);

      // Verify integrity (0.95 - 1.00)
      debugPrint('🔍 [BibleFtsSetupWeb] Verifying FTS integrity...');
      final stats = await testFts();
      onProgress?.call(1.0);

      debugPrint('🔍 [BibleFtsSetupWeb] ✅ FTS setup complete: $stats');
    } catch (e, stackTrace) {
      debugPrint('🔍 [BibleFtsSetupWeb] ❌ Setup failed: $e');
      debugPrint('🔍 [BibleFtsSetupWeb] Stack trace: $stackTrace');
      throw FtsSetupException(
        'FTS setup failed: $e',
        operation: 'setupFts',
      );
    }
  }

  /// Check if FTS is already setup
  ///
  /// Returns true if:
  /// 1. FTS virtual table exists
  /// 2. FTS table is populated with data
  ///
  /// This check prevents redundant setup operations.
  Future<bool> isFtsSetup() async {
    try {
      // Check if table exists
      final tables = await _db.query(
        'sqlite_master',
        where: "type='table' AND name='bible_verses_fts'",
      );

      if (tables.isEmpty) {
        debugPrint('🔍 [BibleFtsSetupWeb] FTS table does not exist');
        return false;
      }

      // Check if populated
      final count = await _db.query(
        'bible_verses_fts',
        columns: ['COUNT(*) as count'],
      );

      final rowCount = count.first['count'] as int;
      final isPopulated = rowCount > 0;

      debugPrint('🔍 [BibleFtsSetupWeb] FTS table has $rowCount rows');
      return isPopulated;
    } catch (e) {
      debugPrint('🔍 [BibleFtsSetupWeb] FTS check failed: $e');
      return false;
    }
  }

  /// Rebuild FTS index from scratch
  ///
  /// Use this to recover from data corruption or after Bible updates.
  /// This operation:
  /// 1. Drops existing FTS table and triggers
  /// 2. Recreates everything
  /// 3. Repopulates FTS data
  ///
  /// Parameters:
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// Throws [FtsSetupException] on error.
  ///
  /// Example:
  /// ```dart
  /// // After Bible update
  /// await ftsSetup.rebuildFts(onProgress: (p) {
  ///   print('Rebuilding: ${(p * 100).toFixed(0)}%');
  /// });
  /// ```
  Future<void> rebuildFts({Function(double)? onProgress}) async {
    try {
      debugPrint('🔍 [BibleFtsSetupWeb] Rebuilding FTS index...');

      onProgress?.call(0.1);

      // Drop existing FTS
      await dropFts();

      onProgress?.call(0.2);

      // Recreate
      await setupFts(onProgress: (p) {
        // Map 0.0-1.0 to 0.2-1.0
        onProgress?.call(0.2 + (p * 0.8));
      });

      debugPrint('🔍 [BibleFtsSetupWeb] ✅ FTS rebuild complete');
    } catch (e) {
      throw FtsSetupException(
        'FTS rebuild failed: $e',
        operation: 'rebuildFts',
      );
    }
  }

  /// Drop FTS table and triggers
  ///
  /// Removes all FTS components. Use before rebuilding or cleanup.
  /// This does not affect the bible_verses table.
  ///
  /// Throws [FtsSetupException] on error.
  Future<void> dropFts() async {
    try {
      debugPrint('🔍 [BibleFtsSetupWeb] Dropping FTS table and triggers...');

      // Drop triggers
      await _db.execute('DROP TRIGGER IF EXISTS bible_verses_ai');
      await _db.execute('DROP TRIGGER IF EXISTS bible_verses_ad');
      await _db.execute('DROP TRIGGER IF EXISTS bible_verses_au');

      // Drop FTS table
      await _db.execute('DROP TABLE IF EXISTS bible_verses_fts');

      debugPrint('🔍 [BibleFtsSetupWeb] ✅ FTS dropped');
    } catch (e) {
      throw FtsSetupException(
        'FTS drop failed: $e',
        operation: 'dropFts',
      );
    }
  }

  /// Test FTS functionality
  ///
  /// Runs various search tests to verify FTS is working correctly.
  ///
  /// Returns a map with test results:
  /// - search_love: Number of verses mentioning "love"
  /// - search_john_god: Verses in John mentioning "God"
  /// - search_spanish: Spanish verses mentioning "Dios"
  /// - total_indexed: Total verses in FTS index
  /// - expected_count: Expected total (62,187)
  /// - is_complete: Whether all verses are indexed
  ///
  /// Example:
  /// ```dart
  /// final stats = await ftsSetup.testFts();
  /// print('Indexed: ${stats['total_indexed']} / ${stats['expected_count']}');
  /// print('Complete: ${stats['is_complete']}');
  /// ```
  Future<Map<String, dynamic>> testFts() async {
    try {
      final tests = <String, dynamic>{};

      // Test 1: Basic search - verses mentioning "love"
      try {
        final loveResults = await _db.query(
          'bible_verses_fts',
          where: "bible_verses_fts MATCH 'love'",
          limit: 5,
        );
        tests['search_love'] = loveResults.length;
        debugPrint('🔍 [BibleFtsSetupWeb] Test 1: Found ${loveResults.length} verses about love');
      } catch (e) {
        tests['search_love'] = 'ERROR: $e';
        debugPrint('🔍 [BibleFtsSetupWeb] Test 1 failed: $e');
      }

      // Test 2: Book-specific search - John + God
      try {
        final johnResults = await _db.query(
          'bible_verses_fts',
          where: "bible_verses_fts MATCH 'book:John AND God'",
          limit: 5,
        );
        tests['search_john_god'] = johnResults.length;
        debugPrint('🔍 [BibleFtsSetupWeb] Test 2: Found ${johnResults.length} John verses about God');
      } catch (e) {
        tests['search_john_god'] = 'ERROR: $e';
        debugPrint('🔍 [BibleFtsSetupWeb] Test 2 failed: $e');
      }

      // Test 3: Language filter - Spanish "Dios"
      try {
        final spanishResults = await _db.query(
          'bible_verses_fts',
          where: "bible_verses_fts MATCH 'language:es AND Dios'",
          limit: 5,
        );
        tests['search_spanish'] = spanishResults.length;
        debugPrint('🔍 [BibleFtsSetupWeb] Test 3: Found ${spanishResults.length} Spanish verses about Dios');
      } catch (e) {
        tests['search_spanish'] = 'ERROR: $e';
        debugPrint('🔍 [BibleFtsSetupWeb] Test 3 failed: $e');
      }

      // Test 4: Index completeness
      try {
        final sizeResult = await _db.query(
          'bible_verses_fts',
          columns: ['COUNT(*) as count'],
        );
        tests['total_indexed'] = sizeResult.first['count'];
        tests['expected_count'] = 62187; // 31,103 English + 31,084 Spanish
        tests['is_complete'] = tests['total_indexed'] == tests['expected_count'];

        debugPrint('🔍 [BibleFtsSetupWeb] Test 4: Indexed ${tests['total_indexed']} / ${tests['expected_count']} verses');
      } catch (e) {
        tests['total_indexed'] = 'ERROR: $e';
        tests['expected_count'] = 62187;
        tests['is_complete'] = false;
        debugPrint('🔍 [BibleFtsSetupWeb] Test 4 failed: $e');
      }

      return tests;
    } catch (e) {
      throw FtsSetupException(
        'FTS test failed: $e',
        operation: 'testFts',
      );
    }
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  /// Create FTS5 virtual table
  ///
  /// FTS5 Configuration:
  /// - book: Indexed for book-specific searches
  /// - chapter: UNINDEXED (only used for filtering results)
  /// - verse: UNINDEXED (only used for filtering results)
  /// - text: Indexed for full-text search
  /// - version: UNINDEXED (WEB/RVR1909 filter)
  /// - language: UNINDEXED (en/es filter)
  /// - content='bible_verses': External content table (saves space)
  /// - content_rowid='id': Maps rowid to bible_verses.id
  ///
  /// UNINDEXED columns are not searchable via FTS but can be used in
  /// WHERE clauses after the FTS MATCH.
  Future<void> _createFtsTable() async {
    try {
      await _db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS bible_verses_fts USING fts5(
          book,
          chapter UNINDEXED,
          verse UNINDEXED,
          text,
          version UNINDEXED,
          language UNINDEXED,
          content='bible_verses',
          content_rowid='id'
        )
      ''');
      debugPrint('🔍 [BibleFtsSetupWeb] ✅ FTS table created');
    } catch (e) {
      throw FtsSetupException(
        'Failed to create FTS table: $e',
        operation: '_createFtsTable',
      );
    }
  }

  /// Create triggers to keep FTS in sync with bible_verses
  ///
  /// Triggers:
  /// - bible_verses_ai: Insert trigger
  /// - bible_verses_ad: Delete trigger
  /// - bible_verses_au: Update trigger
  ///
  /// These triggers automatically update the FTS index when data changes.
  Future<void> _createTriggers() async {
    try {
      // Insert trigger
      await _db.execute('''
        CREATE TRIGGER IF NOT EXISTS bible_verses_ai
        AFTER INSERT ON bible_verses BEGIN
          INSERT INTO bible_verses_fts(rowid, book, chapter, verse, text, version, language)
          VALUES (new.id, new.book, new.chapter, new.verse, new.text, new.version, new.language);
        END
      ''');
      debugPrint('🔍 [BibleFtsSetupWeb] ✅ Insert trigger created');

      // Delete trigger
      await _db.execute('''
        CREATE TRIGGER IF NOT EXISTS bible_verses_ad
        AFTER DELETE ON bible_verses BEGIN
          DELETE FROM bible_verses_fts WHERE rowid = old.id;
        END
      ''');
      debugPrint('🔍 [BibleFtsSetupWeb] ✅ Delete trigger created');

      // Update trigger
      await _db.execute('''
        CREATE TRIGGER IF NOT EXISTS bible_verses_au
        AFTER UPDATE ON bible_verses BEGIN
          UPDATE bible_verses_fts
          SET book=new.book, chapter=new.chapter, verse=new.verse,
              text=new.text, version=new.version, language=new.language
          WHERE rowid=new.id;
        END
      ''');
      debugPrint('🔍 [BibleFtsSetupWeb] ✅ Update trigger created');
    } catch (e) {
      throw FtsSetupException(
        'Failed to create triggers: $e',
        operation: '_createTriggers',
      );
    }
  }

  /// Populate FTS table from bible_verses
  ///
  /// Uses batch processing to avoid memory issues with 62,187 verses.
  /// All inserts are wrapped in a transaction for speed.
  ///
  /// Parameters:
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// Performance:
  /// - Batch size: 1000 rows per transaction
  /// - Estimated time: 2-5 seconds for 62k verses
  Future<void> _populateFts({Function(double)? onProgress}) async {
    try {
      // Get total verse count
      final countResult = await _db.query(
        'bible_verses',
        columns: ['COUNT(*) as count'],
      );
      final total = countResult.first['count'] as int;

      debugPrint('🔍 [BibleFtsSetupWeb] Populating FTS with $total verses...');

      if (total == 0) {
        throw FtsSetupException(
          'Cannot populate FTS: bible_verses table is empty',
          operation: '_populateFts',
        );
      }

      // Populate in batches with transaction wrapping
      const batchSize = 1000;
      int processed = 0;

      for (int offset = 0; offset < total; offset += batchSize) {
        // Use transaction for speed
        await _db.transaction((txn) async {
          await txn.execute('''
            INSERT INTO bible_verses_fts(rowid, book, chapter, verse, text, version, language)
            SELECT id, book, chapter, verse, text, version, language
            FROM bible_verses
            LIMIT $batchSize OFFSET $offset
          ''');
        });

        processed += batchSize;
        final progress = processed / total;
        onProgress?.call(progress.clamp(0.0, 1.0));

        // Log progress every 10,000 verses
        if (processed % 10000 == 0 || processed >= total) {
          debugPrint('🔍 [BibleFtsSetupWeb] Progress: $processed / $total verses (${(progress * 100).toStringAsFixed(1)}%)');
        }
      }

      onProgress?.call(1.0);
      debugPrint('🔍 [BibleFtsSetupWeb] ✅ FTS populated with $total verses');
    } catch (e) {
      throw FtsSetupException(
        'Failed to populate FTS: $e',
        operation: '_populateFts',
      );
    }
  }
}

/// Exception thrown when FTS setup fails
///
/// Contains detailed information about the failure including:
/// - Human-readable error message
/// - Operation that failed (setupFts, rebuildFts, etc.)
///
/// Example:
/// ```dart
/// try {
///   await ftsSetup.setupFts();
/// } catch (e) {
///   if (e is FtsSetupException) {
///     print('FTS setup failed during ${e.operation}: ${e.message}');
///   }
/// }
/// ```
class FtsSetupException implements Exception {
  /// Human-readable error message
  final String message;

  /// Operation that failed (optional)
  final String? operation;

  /// Create an FTS setup exception
  ///
  /// Parameters:
  /// - [message]: Human-readable error message
  /// - [operation]: Optional operation name that failed
  FtsSetupException(this.message, {this.operation});

  @override
  String toString() {
    final buffer = StringBuffer('FtsSetupException: $message');
    if (operation != null) {
      buffer.write(' (during $operation)');
    }
    return buffer.toString();
  }
}
