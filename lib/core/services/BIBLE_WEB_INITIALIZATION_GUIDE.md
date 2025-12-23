# Bible Web Initialization Guide

## Complete Initialization Sequence

This guide shows the complete initialization sequence for Bible functionality on web, including data loading and FTS setup.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    App Initialization                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   SqlJsHelper.database                       │
│              (Open/Create database with WASM)                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               BibleDataLoaderWeb.loadBibleData()             │
│                  (Load 62,187 verses)                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 1. Create bible_verses schema                       │   │
│  │ 2. Load English Bible (WEB) - 31,103 verses         │   │
│  │ 3. Load Spanish Bible (RVR1909) - 31,084 verses     │   │
│  │ 4. Mark as loaded in metadata                       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               BibleFtsSetupWeb.setupFts()                    │
│              (Create FTS5 search indexes)                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 1. Create FTS5 virtual table                        │   │
│  │ 2. Create triggers (insert/update/delete)           │   │
│  │ 3. Populate FTS with 62,187 verses                  │   │
│  │ 4. Verify index integrity                           │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  App Ready for Bible Search                  │
└─────────────────────────────────────────────────────────────┘
```

## Implementation

### Option 1: Simple Async Initialization (Recommended for Web)

```dart
import 'package:flutter/material.dart';
import 'package:everyday_christian/core/database/sql_js_helper.dart';
import 'package:everyday_christian/core/services/bible_data_loader_web.dart';
import 'package:everyday_christian/core/services/bible_fts_setup_web.dart';

class BibleInitializationService {
  static bool _initialized = false;
  static String? _error;

  /// Initialize Bible data and FTS indexes
  static Future<void> initialize({
    Function(String)? onStatusUpdate,
    Function(double)? onProgress,
  }) async {
    if (_initialized) return;

    try {
      // Step 1: Open database
      onStatusUpdate?.call('Opening database...');
      final db = await SqlJsHelper.database;
      onProgress?.call(0.05);

      // Step 2: Load Bible data
      onStatusUpdate?.call('Loading Bible data...');
      final loader = BibleDataLoaderWeb(db);

      if (!await loader.isBibleDataLoaded()) {
        await for (final progress in loader.loadBibleData()) {
          // Map 0.0-1.0 to 0.05-0.50
          onProgress?.call(0.05 + (progress * 0.45));
          if (progress % 0.1 < 0.01) {
            onStatusUpdate?.call('Loading Bible: ${(progress * 100).toStringAsFixed(0)}%');
          }
        }
      } else {
        onStatusUpdate?.call('Bible data already loaded');
        onProgress?.call(0.50);
      }

      // Step 3: Setup FTS indexes
      onStatusUpdate?.call('Setting up search indexes...');
      final ftsSetup = BibleFtsSetupWeb(db);

      if (!await ftsSetup.isFtsSetup()) {
        await ftsSetup.setupFts(onProgress: (p) {
          // Map 0.0-1.0 to 0.50-0.95
          onProgress?.call(0.50 + (p * 0.45));
          if (p % 0.1 < 0.01) {
            onStatusUpdate?.call('Indexing: ${(p * 100).toStringAsFixed(0)}%');
          }
        });
      } else {
        onStatusUpdate?.call('Search indexes already setup');
        onProgress?.call(0.95);
      }

      // Step 4: Verify
      onStatusUpdate?.call('Verifying setup...');
      final stats = await ftsSetup.testFts();
      onProgress?.call(1.0);

      if (stats['is_complete'] == true) {
        onStatusUpdate?.call('Bible initialization complete');
        _initialized = true;
      } else {
        throw Exception('Bible initialization incomplete: $stats');
      }
    } catch (e) {
      _error = e.toString();
      onStatusUpdate?.call('Error: $e');
      rethrow;
    }
  }

  /// Check if Bible is initialized
  static bool get isInitialized => _initialized;

  /// Get initialization error (if any)
  static String? get error => _error;

  /// Reset initialization state (for testing)
  static void reset() {
    _initialized = false;
    _error = null;
  }
}
```

### Option 2: Widget-Based Initialization

```dart
class BibleInitializationWidget extends StatefulWidget {
  final Widget child;

  const BibleInitializationWidget({
    super.key,
    required this.child,
  });

  @override
  State<BibleInitializationWidget> createState() => _BibleInitializationWidgetState();
}

class _BibleInitializationWidgetState extends State<BibleInitializationWidget> {
  bool _isInitialized = false;
  String _status = 'Initializing...';
  double _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await BibleInitializationService.initialize(
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() {
              _status = status;
            });
          }
        },
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Initialization Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                    _progress = 0.0;
                  });
                  _initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: LinearProgressIndicator(value: _progress),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
```

### Option 3: FutureBuilder Pattern

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: BibleInitializationService.initialize(
        onStatusUpdate: (status) => debugPrint('Status: $status'),
        onProgress: (progress) => debugPrint('Progress: ${(progress * 100).toFixed(0)}%'),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Initialization Error: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing Bible data...'),
                  ],
                ),
              ),
            ),
          );
        }

        // Initialization complete - show main app
        return MaterialApp(
          home: HomeScreen(),
        );
      },
    );
  }
}
```

## Usage in Main App

### main.dart

```dart
import 'package:flutter/material.dart';
import 'package:everyday_christian/core/services/bible_initialization_service.dart';
import 'package:everyday_christian/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Everyday Christian',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BibleInitializationWidget(
        child: HomeScreen(),
      ),
    );
  }
}
```

## Progress Tracking

### Detailed Progress Breakdown

```dart
// Total progress: 0.0 to 1.0

// Phase 1: Database (0.00 - 0.05)
0.00 - 0.05: Opening database

// Phase 2: Bible Data Loading (0.05 - 0.50)
0.05 - 0.10: Creating schema
0.10 - 0.30: Loading English Bible (WEB)
0.30 - 0.50: Loading Spanish Bible (RVR1909)

// Phase 3: FTS Setup (0.50 - 0.95)
0.50 - 0.55: Creating FTS virtual table
0.55 - 0.60: Creating triggers
0.60 - 0.90: Populating FTS index (62,187 verses)
0.90 - 0.95: Verifying integrity

// Phase 4: Finalization (0.95 - 1.00)
0.95 - 1.00: Final verification
```

## Status Messages

```dart
// Status message examples:
'Opening database...'
'Creating Bible schema...'
'Loading English Bible (WEB)...'
'Loading: 25%'
'Loading Spanish Bible (RVR1909)...'
'Loading: 75%'
'Setting up search indexes...'
'Creating FTS virtual table...'
'Creating triggers...'
'Indexing verses...'
'Indexing: 50%'
'Verifying setup...'
'Bible initialization complete'
```

## Error Handling

```dart
try {
  await BibleInitializationService.initialize();
} catch (e) {
  if (e is BibleLoadException) {
    // Bible data loading failed
    print('Failed to load Bible: ${e.message}');
    if (e.sqlFile != null) {
      print('SQL File: ${e.sqlFile}');
    }
  } else if (e is FtsSetupException) {
    // FTS setup failed
    print('Failed to setup FTS: ${e.message}');
    print('Operation: ${e.operation}');
  } else {
    // Other error
    print('Initialization failed: $e');
  }
}
```

## Testing

### Unit Test

```dart
void main() {
  test('Bible initialization completes successfully', () async {
    final statuses = <String>[];
    final progresses = <double>[];

    await BibleInitializationService.initialize(
      onStatusUpdate: (status) => statuses.add(status),
      onProgress: (progress) => progresses.add(progress),
    );

    expect(BibleInitializationService.isInitialized, true);
    expect(BibleInitializationService.error, null);
    expect(progresses.last, 1.0);
    expect(statuses.last, 'Bible initialization complete');
  });
}
```

### Integration Test

```dart
void main() {
  testWidgets('App initializes Bible before showing home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Should show loading initially
    expect(find.text('Initializing...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for initialization
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Should show home screen after initialization
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Initializing...'), findsNothing);
  });
}
```

## Performance Expectations

### First Launch (No Cache)
- **Database Open:** < 200ms
- **Bible Data Load:** 5-10 seconds (32 MB download + parse)
- **FTS Setup:** 2-5 seconds (index 62,187 verses)
- **Total:** 7-15 seconds

### Subsequent Launches (With IndexedDB Cache)
- **Database Open:** < 100ms
- **Bible Data Check:** < 50ms (already loaded)
- **FTS Check:** < 50ms (already setup)
- **Total:** < 200ms

## Optimization Tips

### 1. Lazy Loading
```dart
// Only initialize when needed
if (userNeedsBibleSearch) {
  await BibleInitializationService.initialize();
}
```

### 2. Background Initialization
```dart
// Initialize in background while showing other content
Future.microtask(() async {
  await BibleInitializationService.initialize();
});
```

### 3. Progressive Loading
```dart
// Load English first, Spanish later
await loader.loadEnglishBible();
await ftsSetup.setupFts(); // With English only

// Load Spanish in background
Future.microtask(() async {
  await loader.loadSpanishBible();
  await ftsSetup.rebuildFts(); // Rebuild with both languages
});
```

## Monitoring

### Add Analytics
```dart
await BibleInitializationService.initialize(
  onStatusUpdate: (status) {
    // Log to analytics
    analytics.logEvent(
      name: 'bible_init_status',
      parameters: {'status': status},
    );
  },
  onProgress: (progress) {
    // Track progress
    if (progress == 1.0) {
      analytics.logEvent(name: 'bible_init_complete');
    }
  },
);
```

### Add Error Reporting
```dart
try {
  await BibleInitializationService.initialize();
} catch (e, stackTrace) {
  // Report to error tracking service
  await FirebaseCrashlytics.instance.recordError(
    e,
    stackTrace,
    reason: 'Bible initialization failed',
  );
  rethrow;
}
```

## Troubleshooting

### Issue: Initialization Hangs

**Symptoms:** Progress stops at a specific percentage

**Solutions:**
1. Check browser console for errors
2. Verify asset files are accessible
3. Check IndexedDB quota
4. Try clearing IndexedDB cache

### Issue: FTS Search Doesn't Work

**Symptoms:** Search returns empty results

**Solutions:**
1. Verify FTS is setup: `await ftsSetup.isFtsSetup()`
2. Run FTS tests: `await ftsSetup.testFts()`
3. Rebuild FTS: `await ftsSetup.rebuildFts()`

### Issue: Slow Performance

**Symptoms:** Initialization takes > 30 seconds

**Solutions:**
1. Check network speed (for first load)
2. Verify WASM files are loading
3. Check IndexedDB performance
4. Try smaller batch sizes

## Summary

This guide provides everything needed to initialize Bible functionality on web:

1. ✅ Database setup (SqlJsHelper)
2. ✅ Bible data loading (BibleDataLoaderWeb)
3. ✅ FTS index setup (BibleFtsSetupWeb)
4. ✅ Progress tracking
5. ✅ Error handling
6. ✅ Performance optimization
7. ✅ Testing strategies

**Total initialization time:**
- First launch: 7-15 seconds
- Subsequent launches: < 200ms

**Result:** Fast, efficient Bible search across 62,187 verses in English and Spanish.
