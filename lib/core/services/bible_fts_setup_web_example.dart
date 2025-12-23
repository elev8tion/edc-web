/// Example usage of BibleFtsSetupWeb service
///
/// This file demonstrates how to set up and use FTS5 indexes for Bible search
/// on the web platform.
library bible_fts_setup_web_example;

import 'package:flutter/material.dart';
import '../database/sql_js_helper.dart';
import 'bible_data_loader_web.dart';
import 'bible_fts_setup_web.dart';

// ===========================================================================
// EXAMPLE 1: Basic Setup
// ===========================================================================

/// Complete initialization sequence for Bible search on web
///
/// This shows the proper order of operations:
/// 1. Open database
/// 2. Load Bible data
/// 3. Setup FTS indexes
/// 4. Verify setup
Future<void> basicSetupExample() async {
  print('=== EXAMPLE 1: Basic Setup ===\n');

  // Step 1: Get database instance
  print('Step 1: Opening database...');
  final db = await SqlJsHelper.database;
  print('✅ Database opened\n');

  // Step 2: Load Bible data
  print('Step 2: Loading Bible data...');
  final loader = BibleDataLoaderWeb(db);

  await for (final progress in loader.loadBibleData()) {
    if (progress % 0.1 < 0.01) {
      // Print every 10%
      print('  Loading: ${(progress * 100).toStringAsFixed(0)}%');
    }
  }
  print('✅ Bible data loaded\n');

  // Step 3: Setup FTS indexes
  print('Step 3: Setting up FTS indexes...');
  final ftsSetup = BibleFtsSetupWeb(db);

  await ftsSetup.setupFts(onProgress: (p) {
    if (p % 0.1 < 0.01) {
      // Print every 10%
      print('  Indexing: ${(p * 100).toStringAsFixed(0)}%');
    }
  });
  print('✅ FTS indexes created\n');

  // Step 4: Verify setup
  print('Step 4: Verifying FTS setup...');
  final stats = await ftsSetup.testFts();
  print('✅ FTS Stats:');
  print('  - Total indexed: ${stats['total_indexed']}');
  print('  - Expected: ${stats['expected_count']}');
  print('  - Complete: ${stats['is_complete']}');
  print('  - Love verses: ${stats['search_love']}');
  print('  - John+God verses: ${stats['search_john_god']}');
  print('  - Spanish verses: ${stats['search_spanish']}');
}

// ===========================================================================
// EXAMPLE 2: Search Examples
// ===========================================================================

/// Demonstrate various FTS search techniques
Future<void> searchExamplesExample() async {
  print('\n=== EXAMPLE 2: Search Examples ===\n');

  final db = await SqlJsHelper.database;

  // Basic search
  print('Example 2.1: Basic search for "love"');
  var results = await db.query(
    'bible_verses_fts',
    where: "bible_verses_fts MATCH 'love'",
    limit: 5,
  );
  print('  Found ${results.length} verses:');
  for (final verse in results.take(2)) {
    print('  - ${verse['book']} ${verse['chapter']}:${verse['verse']}');
    print('    "${verse['text']}"');
  }

  // Book-specific search
  print('\nExample 2.2: Search "God" in John');
  results = await db.query(
    'bible_verses_fts',
    where: "bible_verses_fts MATCH 'book:John AND God'",
    limit: 5,
  );
  print('  Found ${results.length} verses in John');

  // Language-specific search
  print('\nExample 2.3: Spanish search for "Dios"');
  results = await db.query(
    'bible_verses_fts',
    where: "bible_verses_fts MATCH 'language:es AND Dios'",
    limit: 5,
  );
  print('  Found ${results.length} Spanish verses');
  if (results.isNotEmpty) {
    final verse = results.first;
    print('  - ${verse['book']} ${verse['chapter']}:${verse['verse']}');
    print('    "${verse['text']}"');
  }

  // Phrase search
  print('\nExample 2.4: Phrase search "faith hope love"');
  results = await db.query(
    'bible_verses_fts',
    where: 'bible_verses_fts MATCH \'"faith hope love"\'',
    limit: 5,
  );
  print('  Found ${results.length} verses with all three words');

  // Boolean operators
  print('\nExample 2.5: Boolean search "faith OR hope"');
  results = await db.query(
    'bible_verses_fts',
    where: "bible_verses_fts MATCH 'faith OR hope'",
    limit: 5,
  );
  print('  Found ${results.length} verses');

  // Exclusion
  print('\nExample 2.6: Exclusion "love NOT fear"');
  results = await db.query(
    'bible_verses_fts',
    where: "bible_verses_fts MATCH 'love NOT fear'",
    limit: 5,
  );
  print('  Found ${results.length} verses about love without fear');
}

// ===========================================================================
// EXAMPLE 3: Flutter Widget Integration
// ===========================================================================

/// Example Flutter widget for Bible search with FTS
class BibleSearchWidget extends StatefulWidget {
  const BibleSearchWidget({super.key});

  @override
  State<BibleSearchWidget> createState() => _BibleSearchWidgetState();
}

class _BibleSearchWidgetState extends State<BibleSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  /// Search Bible verses using FTS
  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = await SqlJsHelper.database;

      // Perform FTS search
      final results = await db.query(
        'bible_verses_fts',
        where: 'bible_verses_fts MATCH ?',
        whereArgs: [query],
        limit: 50,
      );

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Bible (e.g., "love", "book:John AND God")',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _search,
          ),
        ),

        // Search tips
        if (_searchController.text.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Search tips:\n'
              '• Simple: "love"\n'
              '• Book: "book:John AND God"\n'
              '• Language: "language:es AND Dios"\n'
              '• Phrase: "faith hope love"\n'
              '• Boolean: "faith OR hope"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

        // Loading indicator
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),

        // Error message
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),

        // Results
        if (!_isLoading && _error == null && _results.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final verse = _results[index];
                return ListTile(
                  title: Text(
                    '${verse['book']} ${verse['chapter']}:${verse['verse']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(verse['text'] as String),
                  trailing: Text(
                    verse['version'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

        // No results
        if (!_isLoading &&
            _error == null &&
            _results.isEmpty &&
            _searchController.text.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No verses found'),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ===========================================================================
// EXAMPLE 4: Advanced Search Functions
// ===========================================================================

/// Advanced search utilities
class BibleSearchUtils {
  /// Search verses by multiple criteria
  static Future<List<Map<String, dynamic>>> advancedSearch({
    required String query,
    String? book,
    String? language,
    int limit = 50,
  }) async {
    final db = await SqlJsHelper.database;

    // Build FTS query
    final queryParts = <String>[];

    if (book != null) {
      queryParts.add('book:$book');
    }

    if (language != null) {
      queryParts.add('language:$language');
    }

    queryParts.add(query);

    final ftsQuery = queryParts.join(' AND ');

    return await db.query(
      'bible_verses_fts',
      where: 'bible_verses_fts MATCH ?',
      whereArgs: [ftsQuery],
      limit: limit,
    );
  }

  /// Search verses in a specific book
  static Future<List<Map<String, dynamic>>> searchInBook(
    String book,
    String query, {
    int limit = 50,
  }) async {
    return await advancedSearch(
      query: query,
      book: book,
      limit: limit,
    );
  }

  /// Search Spanish verses
  static Future<List<Map<String, dynamic>>> searchSpanish(
    String query, {
    int limit = 50,
  }) async {
    return await advancedSearch(
      query: query,
      language: 'es',
      limit: limit,
    );
  }

  /// Search English verses
  static Future<List<Map<String, dynamic>>> searchEnglish(
    String query, {
    int limit = 50,
  }) async {
    return await advancedSearch(
      query: query,
      language: 'en',
      limit: limit,
    );
  }

  /// Get verse context (surrounding verses)
  static Future<List<Map<String, dynamic>>> getVerseContext({
    required String book,
    required int chapter,
    required int verse,
    int contextBefore = 2,
    int contextAfter = 2,
  }) async {
    final db = await SqlJsHelper.database;

    return await db.query(
      'bible_verses',
      where: 'book = ? AND chapter = ? AND verse BETWEEN ? AND ?',
      whereArgs: [
        book,
        chapter,
        verse - contextBefore,
        verse + contextAfter,
      ],
      orderBy: 'verse ASC',
    );
  }
}

// ===========================================================================
// EXAMPLE 5: Maintenance and Rebuild
// ===========================================================================

/// Demonstrate FTS maintenance operations
Future<void> maintenanceExample() async {
  print('\n=== EXAMPLE 5: Maintenance Operations ===\n');

  final db = await SqlJsHelper.database;
  final ftsSetup = BibleFtsSetupWeb(db);

  // Check if FTS is setup
  print('Checking FTS status...');
  final isSetup = await ftsSetup.isFtsSetup();
  print('  FTS is ${isSetup ? 'setup' : 'not setup'}');

  // Rebuild FTS (useful after data corruption or updates)
  if (isSetup) {
    print('\nRebuilding FTS index...');
    await ftsSetup.rebuildFts(onProgress: (p) {
      if (p % 0.2 < 0.01) {
        // Print every 20%
        print('  Rebuild progress: ${(p * 100).toStringAsFixed(0)}%');
      }
    });
    print('✅ FTS rebuilt');
  }

  // Test FTS functionality
  print('\nTesting FTS functionality...');
  final stats = await ftsSetup.testFts();
  print('  Test results:');
  stats.forEach((key, value) {
    print('    $key: $value');
  });

  // Drop FTS (cleanup)
  // Uncomment if you want to test dropping
  // print('\nDropping FTS...');
  // await ftsSetup.dropFts();
  // print('✅ FTS dropped');
}

// ===========================================================================
// EXAMPLE 6: Performance Testing
// ===========================================================================

/// Test FTS search performance
Future<void> performanceExample() async {
  print('\n=== EXAMPLE 6: Performance Testing ===\n');

  final db = await SqlJsHelper.database;

  // Test 1: Simple search
  print('Test 1: Simple search for "love"');
  var stopwatch = Stopwatch()..start();
  var results = await db.query(
    'bible_verses_fts',
    where: "bible_verses_fts MATCH 'love'",
    limit: 100,
  );
  stopwatch.stop();
  print('  Found ${results.length} results in ${stopwatch.elapsedMilliseconds}ms');

  // Test 2: Complex search
  print('\nTest 2: Complex search with filters');
  stopwatch = Stopwatch()..start();
  results = await db.query(
    'bible_verses_fts',
    where: "bible_verses_fts MATCH 'book:John AND God AND love'",
    limit: 100,
  );
  stopwatch.stop();
  print('  Found ${results.length} results in ${stopwatch.elapsedMilliseconds}ms');

  // Test 3: Spanish search
  print('\nTest 3: Spanish search');
  stopwatch = Stopwatch()..start();
  results = await db.query(
    'bible_verses_fts',
    where: "bible_verses_fts MATCH 'language:es AND amor'",
    limit: 100,
  );
  stopwatch.stop();
  print('  Found ${results.length} results in ${stopwatch.elapsedMilliseconds}ms');

  // Test 4: Phrase search
  print('\nTest 4: Phrase search');
  stopwatch = Stopwatch()..start();
  results = await db.query(
    'bible_verses_fts',
    where: 'bible_verses_fts MATCH \'"in the beginning"\'',
    limit: 100,
  );
  stopwatch.stop();
  print('  Found ${results.length} results in ${stopwatch.elapsedMilliseconds}ms');
}

// ===========================================================================
// MAIN EXAMPLE RUNNER
// ===========================================================================

/// Run all examples
void main() async {
  await basicSetupExample();
  await searchExamplesExample();
  await maintenanceExample();
  await performanceExample();

  print('\n✅ All examples completed!\n');
}
