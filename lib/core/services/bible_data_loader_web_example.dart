/// Example usage of BibleDataLoaderWeb
///
/// This file demonstrates how to use the web-specific Bible data loader
/// in various scenarios.
///
/// DO NOT import this file in production code - it's for documentation only.
library bible_data_loader_web_example;

import 'package:flutter/material.dart';
import '../database/sql_js_helper.dart';
import 'bible_data_loader_web.dart';

// ============================================================================
// Example 1: Basic Usage - Load All Bibles with Progress
// ============================================================================

Future<void> basicUsageExample() async {
  // Get database instance
  final db = await SqlJsHelper.database;

  // Create loader
  final loader = BibleDataLoaderWeb(db);

  // Load all Bibles with progress tracking
  print('Loading Bibles...');
  await for (final progress in loader.loadBibleData()) {
    print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
  }

  // Get statistics
  final stats = await loader.getLoadingStats();
  print('Loaded ${stats['total_verses']} verses');
  print('English: ${stats['english_verses']}');
  print('Spanish: ${stats['spanish_verses']}');
  print('Complete: ${stats['is_complete']}');
}

// ============================================================================
// Example 2: Load with UI Progress Indicator
// ============================================================================

class BibleLoadingScreen extends StatefulWidget {
  const BibleLoadingScreen({super.key});

  @override
  State<BibleLoadingScreen> createState() => _BibleLoadingScreenState();
}

class _BibleLoadingScreenState extends State<BibleLoadingScreen> {
  double _progress = 0.0;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBibles();
  }

  Future<void> _loadBibles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = await SqlJsHelper.database;
      final loader = BibleDataLoaderWeb(db);

      await for (final progress in loader.loadBibleData()) {
        setState(() {
          _progress = progress;
        });
      }

      // Navigate to home screen after successful load
      if (mounted) {
        // Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const Text(
                'Loading Bible Data...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (_error != null) ...[
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 20),
              const Text(
                'Error loading Bible data',
                style: TextStyle(fontSize: 20, color: Colors.red),
              ),
              const SizedBox(height: 10),
              Text(_error!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadBibles,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Example 3: Load Individual Bibles
// ============================================================================

Future<void> loadIndividualBiblesExample() async {
  final db = await SqlJsHelper.database;
  final loader = BibleDataLoaderWeb(db);

  // Load only English Bible
  print('Loading English Bible...');
  await loader.loadEnglishBible(
    onProgress: (progress) {
      print('English progress: ${(progress * 100).toStringAsFixed(1)}%');
      return progress; // Must return the progress value
    },
  );
  print('English Bible loaded');

  // Load only Spanish Bible
  print('Loading Spanish Bible...');
  await loader.loadSpanishBible(
    onProgress: (progress) {
      print('Spanish progress: ${(progress * 100).toStringAsFixed(1)}%');
      return progress; // Must return the progress value
    },
  );
  print('Spanish Bible loaded');
}

// ============================================================================
// Example 4: Error Handling
// ============================================================================

Future<void> errorHandlingExample() async {
  final db = await SqlJsHelper.database;
  final loader = BibleDataLoaderWeb(db);

  try {
    await for (final progress in loader.loadBibleData()) {
      print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
    }
  } on BibleLoadException catch (e) {
    print('Bible loading failed: ${e.message}');
    if (e.sqlFile != null) {
      print('Failed SQL file: ${e.sqlFile}');
    }
    if (e.originalError != null) {
      print('Original error: ${e.originalError}');
    }

    // Handle specific error cases
    if (e.message.contains('fetch')) {
      print('Network error - check asset files');
    } else if (e.message.contains('SQL')) {
      print('Database error - check SQL syntax');
    }
  } catch (e) {
    print('Unexpected error: $e');
  }
}

// ============================================================================
// Example 5: Check if Already Loaded (Skip Re-loading)
// ============================================================================

Future<void> checkIfLoadedExample() async {
  final db = await SqlJsHelper.database;
  final loader = BibleDataLoaderWeb(db);

  // Check if data is already loaded
  final isLoaded = await loader.isBibleDataLoaded();

  if (isLoaded) {
    print('Bible data already loaded, skipping...');
    return;
  }

  // Load if not loaded
  print('Bible data not loaded, loading now...');
  await for (final progress in loader.loadBibleData()) {
    print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
  }
}

// ============================================================================
// Example 6: Get Loading Statistics
// ============================================================================

Future<void> getStatsExample() async {
  final db = await SqlJsHelper.database;
  final loader = BibleDataLoaderWeb(db);

  final stats = await loader.getLoadingStats();

  print('=== Bible Loading Statistics ===');
  print(
      'English verses: ${stats['english_verses']} / ${stats['english_expected']}');
  print(
      'Spanish verses: ${stats['spanish_verses']} / ${stats['spanish_expected']}');
  print('Total verses: ${stats['total_verses']} / ${stats['expected_total']}');
  print('Is complete: ${stats['is_complete']}');

  // Check if loading is complete
  if (stats['is_complete'] == true) {
    print('✅ All Bibles loaded successfully!');
  } else {
    print('⚠️ Bible loading incomplete');
  }
}

// ============================================================================
// Example 7: Clear and Reload (Testing/Development)
// ============================================================================

Future<void> clearAndReloadExample() async {
  final db = await SqlJsHelper.database;
  final loader = BibleDataLoaderWeb(db);

  // Clear existing data
  print('Clearing Bible data...');
  await loader.clearBibleData();
  print('Bible data cleared');

  // Reload from scratch
  print('Reloading Bible data...');
  await for (final progress in loader.loadBibleData()) {
    if (progress == 0.0 || progress == 1.0) {
      print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
    }
  }
  print('Bible data reloaded');
}

// ============================================================================
// Example 8: Integration with App Initialization
// ============================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible App',
      home: FutureBuilder<bool>(
        future: _checkBibleLoaded(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          final isLoaded = snapshot.data ?? false;

          if (!isLoaded) {
            // Show loading screen
            return const BibleLoadingScreen();
          }

          // Show main app
          return const Scaffold(
            body: Center(
              child: Text('Bible loaded - show main app'),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _checkBibleLoaded() async {
    final db = await SqlJsHelper.database;
    final loader = BibleDataLoaderWeb(db);
    return await loader.isBibleDataLoaded();
  }
}

// ============================================================================
// Example 9: Query Loaded Verses
// ============================================================================

Future<void> queryLoadedVersesExample() async {
  final db = await SqlJsHelper.database;
  final loader = BibleDataLoaderWeb(db);

  // Ensure data is loaded
  if (!await loader.isBibleDataLoaded()) {
    print('Loading Bible data first...');
    await for (final _ in loader.loadBibleData()) {
      // Wait for load to complete
    }
  }

  // Query Genesis 1:1 in English
  final englishVerse = await db.query(
    'bible_verses',
    where: 'book = ? AND chapter = ? AND verse = ? AND language = ?',
    whereArgs: ['Genesis', 1, 1, 'en'],
    limit: 1,
  );

  if (englishVerse.isNotEmpty) {
    print('Genesis 1:1 (English): ${englishVerse.first['text']}');
  }

  // Query Genesis 1:1 in Spanish
  final spanishVerse = await db.query(
    'bible_verses',
    where: 'book = ? AND chapter = ? AND verse = ? AND language = ?',
    whereArgs: ['Génesis', 1, 1, 'es'],
    limit: 1,
  );

  if (spanishVerse.isNotEmpty) {
    print('Génesis 1:1 (Spanish): ${spanishVerse.first['text']}');
  }

  // Count all verses by language
  final englishCount = await db.query(
    'bible_verses',
    where: 'language = ?',
    whereArgs: ['en'],
  );
  print('Total English verses: ${englishCount.length}');

  final spanishCount = await db.query(
    'bible_verses',
    where: 'language = ?',
    whereArgs: ['es'],
  );
  print('Total Spanish verses: ${spanishCount.length}');
}

// ============================================================================
// Example 10: Performance Monitoring
// ============================================================================

Future<void> performanceMonitoringExample() async {
  final db = await SqlJsHelper.database;
  final loader = BibleDataLoaderWeb(db);

  final startTime = DateTime.now();
  var lastProgress = 0.0;
  var lastUpdate = startTime;

  await for (final progress in loader.loadBibleData()) {
    final now = DateTime.now();
    final elapsed = now.difference(startTime);
    final sinceLastUpdate = now.difference(lastUpdate);

    if (progress - lastProgress >= 0.1) {
      // Report every 10%
      print(
        'Progress: ${(progress * 100).toStringAsFixed(0)}% | '
        'Elapsed: ${elapsed.inSeconds}s | '
        'Delta: ${sinceLastUpdate.inMilliseconds}ms',
      );
      lastProgress = progress;
      lastUpdate = now;
    }
  }

  final totalTime = DateTime.now().difference(startTime);
  print('Total loading time: ${totalTime.inSeconds}s');

  final stats = await loader.getLoadingStats();
  print('Verses loaded: ${stats['total_verses']}');
  print(
      'Average: ${stats['total_verses']! / totalTime.inSeconds} verses/second');
}
