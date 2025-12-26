/// Web-specific Bible Data Loader Service
///
/// This service loads Bible data from SQL dumps on the web platform.
/// It replaces the ATTACH DATABASE approach used on mobile platforms.
///
/// Architecture:
/// - Mobile: Uses ATTACH DATABASE to copy from asset .db files
/// - Web: Fetches SQL dumps and executes INSERT statements
///
/// Data Source:
/// - English (WEB): 18 MB uncompressed, ~3.5 MB gzipped
/// - Spanish (RVR1909): 14 MB uncompressed, ~2.0 MB gzipped
/// - Total: 32 MB uncompressed, ~5.5 MB gzipped
///
/// Loading Process:
/// 1. Create bible_verses table schema
/// 2. Fetch bible_web_optimized.sql from assets
/// 3. Execute SQL to create temporary verses table
/// 4. Transform and insert into bible_verses (English)
/// 5. Drop temporary table
/// 6. Repeat steps 2-5 for Spanish Bible
/// 7. Mark as loaded in metadata
///
/// Progress Tracking:
/// - Returns Stream<double> with progress from 0.0 to 1.0
/// - Reports progress during fetch and execution phases
///
/// Error Handling:
/// - Throws BibleLoadException on failures
/// - Handles network errors, SQL errors, and transaction failures
///
/// Usage:
/// ```dart
/// final db = await SqlJsHelper.database;
/// final loader = BibleDataLoaderWeb(db);
///
/// await for (final progress in loader.loadBibleData()) {
///   print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
/// }
///
/// final stats = await loader.getLoadingStats();
/// print('Loaded ${stats['total_verses']} verses');
/// ```
library bible_data_loader_web;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../database/sql_js_helper.dart';

/// Web-specific Bible data loader
///
/// Loads Bible SQL dumps from assets and populates the database.
/// This replaces the ATTACH DATABASE approach used on mobile.
class BibleDataLoaderWeb {
  final SqlJsDatabase _db;

  /// Create a Bible data loader for web platform
  ///
  /// Parameters:
  /// - [_db]: The SqlJsDatabase instance to load data into
  BibleDataLoaderWeb(this._db);

  /// Load all Bible data (English + Spanish)
  ///
  /// Returns a stream of progress values from 0.0 to 1.0.
  ///
  /// Progress breakdown:
  /// - 0.00 - 0.05: Check if already loaded
  /// - 0.05 - 0.10: Create schema
  /// - 0.10 - 0.50: Load English Bible (40% of work)
  /// - 0.50 - 0.90: Load Spanish Bible (40% of work)
  /// - 0.90 - 0.95: Mark as loaded
  /// - 0.95 - 1.00: Finalize
  ///
  /// Throws [BibleLoadException] on error.
  ///
  /// Example:
  /// ```dart
  /// await for (final progress in loader.loadBibleData()) {
  ///   print('Loading: ${(progress * 100).toStringAsFixed(0)}%');
  /// }
  /// ```
  Stream<double> loadBibleData() async* {
    try {
      debugPrint('📖 [BibleDataLoaderWeb] Starting Bible data load...');

      // Check if already loaded (0.00 - 0.05)
      yield 0.00;
      if (await isBibleDataLoaded()) {
        debugPrint('📖 [BibleDataLoaderWeb] ✅ Bible data already loaded');
        yield 1.0;
        return;
      }

      // Create schema (0.05 - 0.10)
      yield 0.05;
      debugPrint('📖 [BibleDataLoaderWeb] Creating schema...');
      await _createSchema();
      yield 0.10;

      // Load English Bible (0.10 - 0.50)
      debugPrint('📖 [BibleDataLoaderWeb] Loading English Bible (WEB)...');
      await loadEnglishBible(
        onProgress: (p) {
          // Map 0.0-1.0 to 0.10-0.50
          return 0.10 + (p * 0.40);
        },
      );
      yield 0.50;
      debugPrint('📖 [BibleDataLoaderWeb] ✅ English Bible loaded');

      // Load Spanish Bible (0.50 - 0.90)
      debugPrint('📖 [BibleDataLoaderWeb] Loading Spanish Bible (RVR1909)...');
      await loadSpanishBible(
        onProgress: (p) {
          // Map 0.0-1.0 to 0.50-0.90
          return 0.50 + (p * 0.40);
        },
      );
      yield 0.90;
      debugPrint('📖 [BibleDataLoaderWeb] ✅ Spanish Bible loaded');

      // Mark as loaded (0.90 - 0.95)
      yield 0.90;
      await _markAsLoaded();
      yield 0.95;

      // Final verification (0.95 - 1.00)
      final stats = await getLoadingStats();
      debugPrint('📖 [BibleDataLoaderWeb] ✅ Load complete: $stats');
      yield 1.0;

      debugPrint('📖 [BibleDataLoaderWeb] ✅ ALL BIBLES LOADED SUCCESSFULLY');
    } catch (e, stackTrace) {
      debugPrint('📖 [BibleDataLoaderWeb] ❌ Error: $e');
      debugPrint('📖 [BibleDataLoaderWeb] Stack trace: $stackTrace');
      throw BibleLoadException('Bible data loading failed: $e');
    }
  }

  /// Check if Bible data is already loaded
  ///
  /// Returns true if bible_verses table contains data.
  ///
  /// This check is performed at the start of [loadBibleData] to avoid
  /// redundant loading.
  Future<bool> isBibleDataLoaded() async {
    try {
      final result = await _db.query(
        'bible_verses',
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      // Table might not exist yet
      return false;
    }
  }

  /// Load English Bible only
  ///
  /// Parameters:
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// Process:
  /// 1. Fetch bible_web_optimized.sql from assets
  /// 2. Execute SQL to create temporary verses table
  /// 3. Transform data into bible_verses table
  /// 4. Drop temporary table
  ///
  /// Throws [BibleLoadException] on error.
  Future<void> loadEnglishBible({
    double Function(double)? onProgress,
  }) async {
    try {
      // Progress tracking helper
      void reportProgress(double p) {
        if (onProgress != null) {
          onProgress(p);
        }
      }

      // Fetch SQL file (0.0 - 0.10)
      reportProgress(0.0);
      debugPrint('📖 [BibleDataLoaderWeb] Fetching bible_web_optimized.sql...');
      final sql = await _fetchSqlFile('assets/bible_web_optimized.sql');
      reportProgress(0.10);
      debugPrint('📖 [BibleDataLoaderWeb] SQL file loaded (${sql.length} bytes)');

      // Execute SQL to create verses table (0.10 - 0.70)
      reportProgress(0.10);
      debugPrint('📖 [BibleDataLoaderWeb] Executing SQL statements...');
      await _executeSqlFile(
        sql,
        onProgress: (p) => reportProgress(0.10 + (p * 0.60)),
      );
      reportProgress(0.70);

      // Transform data to bible_verses table (0.70 - 0.90)
      reportProgress(0.70);
      debugPrint('📖 [BibleDataLoaderWeb] Transforming English data...');
      await _transformEnglishData();
      reportProgress(0.90);

      // Cleanup temporary table (0.90 - 1.0)
      reportProgress(0.90);
      debugPrint('📖 [BibleDataLoaderWeb] Cleaning up temporary table...');
      await _db.execute('DROP TABLE IF EXISTS verses');
      reportProgress(1.0);
    } catch (e) {
      throw BibleLoadException(
        'Failed to load English Bible',
        sqlFile: 'bible_web_optimized.sql',
        originalError: e.toString(),
      );
    }
  }

  /// Load Spanish Bible only
  ///
  /// Parameters:
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// Process:
  /// 1. Fetch spanish_rvr1909_optimized.sql from assets
  /// 2. Execute SQL to create temporary verses table
  /// 3. Transform data into bible_verses table
  /// 4. Drop temporary table
  ///
  /// Throws [BibleLoadException] on error.
  Future<void> loadSpanishBible({
    double Function(double)? onProgress,
  }) async {
    try {
      // Progress tracking helper
      void reportProgress(double p) {
        if (onProgress != null) {
          onProgress(p);
        }
      }

      // Fetch SQL file (0.0 - 0.10)
      reportProgress(0.0);
      debugPrint('📖 [BibleDataLoaderWeb] Fetching spanish_rvr1909_optimized.sql...');
      final sql = await _fetchSqlFile('assets/spanish_rvr1909_optimized.sql');
      reportProgress(0.10);
      debugPrint('📖 [BibleDataLoaderWeb] SQL file loaded (${sql.length} bytes)');

      // Execute SQL to create verses table (0.10 - 0.70)
      reportProgress(0.10);
      debugPrint('📖 [BibleDataLoaderWeb] Executing SQL statements...');
      await _executeSqlFile(
        sql,
        onProgress: (p) => reportProgress(0.10 + (p * 0.60)),
      );
      reportProgress(0.70);

      // Transform data to bible_verses table (0.70 - 0.90)
      reportProgress(0.70);
      debugPrint('📖 [BibleDataLoaderWeb] Transforming Spanish data...');
      await _transformSpanishData();
      reportProgress(0.90);

      // Cleanup temporary table (0.90 - 1.0)
      reportProgress(0.90);
      debugPrint('📖 [BibleDataLoaderWeb] Cleaning up temporary table...');
      await _db.execute('DROP TABLE IF EXISTS verses');
      reportProgress(1.0);
    } catch (e) {
      throw BibleLoadException(
        'Failed to load Spanish Bible',
        sqlFile: 'spanish_rvr1909_optimized.sql',
        originalError: e.toString(),
      );
    }
  }

  /// Clear all Bible data (for testing/reset)
  ///
  /// Removes all verses from bible_verses table and resets metadata.
  /// This does not drop the table, only clears the data.
  ///
  /// Example:
  /// ```dart
  /// await loader.clearBibleData();
  /// // Bible data can now be reloaded
  /// ```
  Future<void> clearBibleData() async {
    try {
      debugPrint('📖 [BibleDataLoaderWeb] Clearing Bible data...');
      await _db.execute('DELETE FROM bible_verses');
      await _db.execute(
        "DELETE FROM app_metadata WHERE key = 'bible_data_loaded'",
      );
      debugPrint('📖 [BibleDataLoaderWeb] ✅ Bible data cleared');
    } catch (e) {
      throw BibleLoadException('Failed to clear Bible data: $e');
    }
  }

  /// Get loading statistics
  ///
  /// Returns verse counts and loading status:
  /// - english_verses: Number of English (WEB) verses
  /// - spanish_verses: Number of Spanish (RVR1909) verses
  /// - total_verses: Total verses loaded
  /// - expected_total: Expected total (62,187 verses)
  /// - is_complete: Whether all verses are loaded
  ///
  /// Example:
  /// ```dart
  /// final stats = await loader.getLoadingStats();
  /// print('Loaded ${stats['total_verses']} / ${stats['expected_total']} verses');
  /// ```
  Future<Map<String, dynamic>> getLoadingStats() async {
    try {
      final englishResult = await _db.query(
        'bible_verses',
        where: 'language = ?',
        whereArgs: ['en'],
      );
      final englishCount = englishResult.length;

      final spanishResult = await _db.query(
        'bible_verses',
        where: 'language = ?',
        whereArgs: ['es'],
      );
      final spanishCount = spanishResult.length;

      final total = englishCount + spanishCount;
      const expectedTotal = 62187; // 31,103 English + 31,084 Spanish

      return {
        'english_verses': englishCount,
        'spanish_verses': spanishCount,
        'total_verses': total,
        'expected_total': expectedTotal,
        'is_complete': total == expectedTotal,
        'english_expected': 31103,
        'spanish_expected': 31084,
      };
    } catch (e) {
      throw BibleLoadException('Failed to get loading stats: $e');
    }
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  /// Fetch SQL file from assets
  ///
  /// Uses Flutter's rootBundle to load SQL files from the assets directory.
  ///
  /// Parameters:
  /// - [path]: Asset path (e.g., 'assets/bible_web_optimized.sql')
  ///
  /// Returns the SQL file content as a string.
  ///
  /// Throws [BibleLoadException] if the file cannot be loaded.
  Future<String> _fetchSqlFile(String path) async {
    try {
      final sql = await rootBundle.loadString(path);
      return sql;
    } catch (e) {
      throw BibleLoadException(
        'Failed to fetch SQL file',
        sqlFile: path,
        originalError: e.toString(),
      );
    }
  }

  /// Execute SQL file with progress tracking
  ///
  /// The SQL files contain many INSERT statements separated by semicolons.
  /// This method first attempts to execute the entire SQL as a single batch
  /// for optimal performance. If that fails, it falls back to executing
  /// statements individually with progress tracking.
  ///
  /// Parameters:
  /// - [sql]: SQL file content
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// Throws [BibleLoadException] if execution fails.
  Future<void> _executeSqlFile(
    String sql, {
    void Function(double)? onProgress,
  }) async {
    try {
      // First, try to execute the entire SQL file at once for maximum speed
      // sql.js should support multi-statement execution
      try {
        debugPrint('📖 [BibleDataLoaderWeb] Attempting batch execution...');
        await _db.execute(sql);
        onProgress?.call(1.0);
        debugPrint('📖 [BibleDataLoaderWeb] ✅ Batch execution successful');
        return;
      } catch (batchError) {
        // Batch execution failed, fall back to statement-by-statement
        debugPrint('📖 [BibleDataLoaderWeb] Batch execution failed, using statement-by-statement');
        debugPrint('📖 [BibleDataLoaderWeb] Error: $batchError');
      }

      // Fallback: Execute statements one by one
      // Split on semicolons and filter out empty statements and transaction control
      final statements = sql
          .split(';')
          .map((s) => s.trim())
          .where((s) {
            if (s.isEmpty) return false;
            final upper = s.toUpperCase();
            // Filter out transaction control statements since we use our own transactions
            if (upper.startsWith('BEGIN')) return false;
            if (upper.startsWith('COMMIT')) return false;
            if (upper.startsWith('ROLLBACK')) return false;
            // Filter out PRAGMA statements that may not be compatible
            if (upper.startsWith('PRAGMA')) return false;
            return true;
          })
          .toList();

      debugPrint('📖 [BibleDataLoaderWeb] Executing ${statements.length} statements...');

      int count = 0;
      final total = statements.length;

      // Execute in batches for better performance
      const batchSize = 100;
      for (int i = 0; i < statements.length; i += batchSize) {
        final end = (i + batchSize < statements.length)
            ? i + batchSize
            : statements.length;
        final batch = statements.sublist(i, end);

        // Execute batch within a transaction for speed
        await _db.transaction((txn) async {
          for (final statement in batch) {
            await txn.execute(statement);
            count++;

            // Report progress every 1000 statements
            if (count % 1000 == 0) {
              onProgress?.call(count / total);
              debugPrint('📖 [BibleDataLoaderWeb] Progress: $count / $total statements');
            }
          }
        });
      }

      onProgress?.call(1.0);
      debugPrint('📖 [BibleDataLoaderWeb] ✅ Executed $count statements');
    } catch (e) {
      throw BibleLoadException(
        'Failed to execute SQL statements',
        originalError: e.toString(),
      );
    }
  }

  /// Transform English Bible data from verses table to bible_verses table
  ///
  /// Performs the column mapping:
  /// - translation → version
  /// - verse_number → verse
  /// - clean_text (with fallback to text) → text
  /// - Add language = 'en'
  /// - Add category = NULL
  ///
  /// Throws [BibleLoadException] if transformation fails.
  Future<void> _transformEnglishData() async {
    try {
      await _db.execute('''
        INSERT INTO bible_verses (version, book, chapter, verse, text, language, themes, category, reference)
        SELECT
          translation as version,
          book,
          chapter,
          verse_number as verse,
          COALESCE(NULLIF(clean_text, ''), text) as text,
          'en' as language,
          themes,
          NULL as category,
          reference
        FROM verses
        WHERE translation = 'WEB'
      ''');

      // Verify the count
      final result = await _db.query(
        'bible_verses',
        where: 'language = ? AND version = ?',
        whereArgs: ['en', 'WEB'],
      );
      debugPrint('📖 [BibleDataLoaderWeb] Transformed ${result.length} English verses');

      if (result.length != 31103) {
        throw BibleLoadException(
          'English verse count mismatch: expected 31,103, got ${result.length}',
        );
      }
    } catch (e) {
      throw BibleLoadException(
        'Failed to transform English data',
        originalError: e.toString(),
      );
    }
  }

  /// Transform Spanish Bible data from verses table to bible_verses table
  ///
  /// Performs the column mapping:
  /// - translation → version
  /// - verse_number → verse
  /// - spanish_text (with fallbacks) → text
  /// - Add language = 'es'
  /// - Add category = NULL
  ///
  /// Throws [BibleLoadException] if transformation fails.
  Future<void> _transformSpanishData() async {
    try {
      await _db.execute('''
        INSERT INTO bible_verses (version, book, chapter, verse, text, language, themes, category, reference)
        SELECT
          translation as version,
          book,
          chapter,
          verse_number as verse,
          COALESCE(spanish_text, spanish_text_original, clean_text, text) as text,
          'es' as language,
          themes,
          NULL as category,
          reference
        FROM verses
        WHERE translation = 'RVR1909'
      ''');

      // Verify the count
      final result = await _db.query(
        'bible_verses',
        where: 'language = ? AND version = ?',
        whereArgs: ['es', 'RVR1909'],
      );
      debugPrint('📖 [BibleDataLoaderWeb] Transformed ${result.length} Spanish verses');

      if (result.length != 31084) {
        throw BibleLoadException(
          'Spanish verse count mismatch: expected 31,084, got ${result.length}',
        );
      }
    } catch (e) {
      throw BibleLoadException(
        'Failed to transform Spanish data',
        originalError: e.toString(),
      );
    }
  }

  /// Create bible_verses table schema
  ///
  /// This matches the schema created by DatabaseHelper on mobile.
  /// Creates the table only if it doesn't already exist.
  ///
  /// Throws [BibleLoadException] if schema creation fails.
  Future<void> _createSchema() async {
    try {
      await _db.execute('''
        CREATE TABLE IF NOT EXISTS bible_verses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          version TEXT NOT NULL,
          book TEXT NOT NULL,
          chapter INTEGER NOT NULL,
          verse INTEGER NOT NULL,
          text TEXT NOT NULL,
          language TEXT NOT NULL,
          themes TEXT,
          category TEXT,
          reference TEXT
        )
      ''');

      // Create indexes for better query performance
      await _db.execute('''
        CREATE INDEX IF NOT EXISTS idx_bible_version ON bible_verses(version)
      ''');
      await _db.execute('''
        CREATE INDEX IF NOT EXISTS idx_bible_book ON bible_verses(book)
      ''');
      await _db.execute('''
        CREATE INDEX IF NOT EXISTS idx_bible_language ON bible_verses(language)
      ''');

      debugPrint('📖 [BibleDataLoaderWeb] Schema created');
    } catch (e) {
      throw BibleLoadException(
        'Failed to create schema',
        originalError: e.toString(),
      );
    }
  }

  /// Mark Bible data as loaded in app metadata
  ///
  /// Stores a timestamp in app_metadata table to track when the Bible
  /// data was loaded. This can be used for cache invalidation or
  /// debugging purposes.
  ///
  /// Throws [BibleLoadException] if marking fails.
  Future<void> _markAsLoaded() async {
    try {
      // First ensure app_metadata table exists (must match schema in database_helper_web.dart)
      await _db.execute('''
        CREATE TABLE IF NOT EXISTS app_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER
        )
      ''');

      // Insert or update the loaded timestamp
      await _db.execute('''
        INSERT OR REPLACE INTO app_metadata (key, value, updated_at)
        VALUES ('bible_data_loaded', ?, ?)
      ''', [DateTime.now().millisecondsSinceEpoch.toString(), DateTime.now().millisecondsSinceEpoch]);

      debugPrint('📖 [BibleDataLoaderWeb] Marked as loaded');
    } catch (e) {
      throw BibleLoadException(
        'Failed to mark as loaded',
        originalError: e.toString(),
      );
    }
  }
}

/// Exception thrown when Bible data loading fails
///
/// Contains detailed information about the failure including:
/// - Human-readable error message
/// - SQL file that failed (if applicable)
/// - Original error from the underlying system
///
/// Example:
/// ```dart
/// try {
///   await loader.loadBibleData();
/// } catch (e) {
///   if (e is BibleLoadException) {
///     print('Failed to load ${e.sqlFile}: ${e.message}');
///     print('Original error: ${e.originalError}');
///   }
/// }
/// ```
class BibleLoadException implements Exception {
  /// Human-readable error message
  final String message;

  /// SQL file that failed (if applicable)
  final String? sqlFile;

  /// Original error from the underlying system
  final String? originalError;

  /// Create a Bible load exception
  ///
  /// Parameters:
  /// - [message]: Human-readable error message
  /// - [sqlFile]: Optional SQL file name that failed
  /// - [originalError]: Optional original error from the system
  BibleLoadException(
    this.message, {
    this.sqlFile,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('BibleLoadException: $message');
    if (sqlFile != null) {
      buffer.write('\nSQL File: $sqlFile');
    }
    if (originalError != null) {
      buffer.write('\nOriginal Error: $originalError');
    }
    return buffer.toString();
  }
}
