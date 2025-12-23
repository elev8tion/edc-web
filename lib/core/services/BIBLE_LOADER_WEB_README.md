# Bible Data Loader for Web Platform

## Overview

The `BibleDataLoaderWeb` service provides web-specific Bible data loading functionality. It replaces the `ATTACH DATABASE` approach used on mobile platforms with SQL dump execution.

### Key Files

- **Service:** `bible_data_loader_web.dart` - Main implementation
- **Tests:** `test/bible_data_loader_web_test.dart` - Unit/integration tests
- **Examples:** `bible_data_loader_web_example.dart` - Usage examples

## Architecture

### Mobile vs Web Comparison

| Aspect | Mobile (sqflite) | Web (sql.js) |
|--------|------------------|--------------|
| Database | Native SQLite | WASM SQLite |
| Bible Loading | ATTACH DATABASE | SQL dump execution |
| File Format | .db files | .sql files |
| File Size | 8 MB (en) + 7 MB (es) | 18 MB (en) + 14 MB (es) |
| Compressed | N/A | 3.5 MB (en) + 2.0 MB (es) gzipped |

### Data Flow

```
Assets
  ├── bible_web_optimized.sql (18 MB, 31,103 verses)
  └── spanish_rvr1909_optimized.sql (14 MB, 31,084 verses)
                    ↓
            BibleDataLoaderWeb
                    ↓
        1. Fetch SQL from assets
        2. Execute SQL (creates temp verses table)
        3. Transform to bible_verses table
        4. Drop temp table
        5. Repeat for Spanish
                    ↓
            SqlJsDatabase
              (IndexedDB persistence)
```

## API Reference

### Main Methods

#### `loadBibleData()` → Stream<double>

Loads all Bible data (English + Spanish) with progress tracking.

**Returns:** Progress stream from 0.0 to 1.0

**Progress Breakdown:**
- 0.00 - 0.05: Check if already loaded
- 0.05 - 0.10: Create schema
- 0.10 - 0.50: Load English Bible
- 0.50 - 0.90: Load Spanish Bible
- 0.90 - 0.95: Mark as loaded
- 0.95 - 1.00: Finalize

**Example:**
```dart
final db = await SqlJsHelper.database;
final loader = BibleDataLoaderWeb(db);

await for (final progress in loader.loadBibleData()) {
  print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
}
```

#### `isBibleDataLoaded()` → Future<bool>

Checks if Bible data is already loaded.

**Returns:** True if bible_verses table contains data

**Example:**
```dart
if (await loader.isBibleDataLoaded()) {
  print('Already loaded, skipping...');
  return;
}
```

#### `loadEnglishBible({onProgress})` → Future<void>

Loads only the English Bible (WEB).

**Parameters:**
- `onProgress`: Optional callback for progress updates (0.0 to 1.0)

**Example:**
```dart
await loader.loadEnglishBible(
  onProgress: (p) => print('Progress: ${(p * 100).toFixed(1)}%'),
);
```

#### `loadSpanishBible({onProgress})` → Future<void>

Loads only the Spanish Bible (RVR1909).

**Parameters:**
- `onProgress`: Optional callback for progress updates (0.0 to 1.0)

**Example:**
```dart
await loader.loadSpanishBible(
  onProgress: (p) => print('Progress: ${(p * 100).toFixed(1)}%'),
);
```

#### `getLoadingStats()` → Future<Map<String, dynamic>>

Gets verse counts and loading status.

**Returns:**
```dart
{
  'english_verses': 31103,
  'spanish_verses': 31084,
  'total_verses': 62187,
  'expected_total': 62187,
  'is_complete': true,
  'english_expected': 31103,
  'spanish_expected': 31084,
}
```

**Example:**
```dart
final stats = await loader.getLoadingStats();
print('Loaded ${stats['total_verses']} verses');
```

#### `clearBibleData()` → Future<void>

Clears all Bible data (for testing/reset).

**Example:**
```dart
await loader.clearBibleData();
// Bible data can now be reloaded
```

### Exception: BibleLoadException

Custom exception thrown when Bible data loading fails.

**Properties:**
- `message`: Human-readable error message
- `sqlFile`: SQL file that failed (optional)
- `originalError`: Original error from system (optional)

**Example:**
```dart
try {
  await loader.loadBibleData();
} on BibleLoadException catch (e) {
  print('Failed to load ${e.sqlFile}: ${e.message}');
  print('Original error: ${e.originalError}');
}
```

## Implementation Details

### Schema Creation

The service creates the `bible_verses` table with indexes:

```sql
CREATE TABLE bible_verses (
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

CREATE INDEX idx_bible_version ON bible_verses(version)
CREATE INDEX idx_bible_book ON bible_verses(book)
CREATE INDEX idx_bible_language ON bible_verses(language)
```

### Data Transformation

#### English Bible (WEB)

Column mapping from temporary `verses` table:
- `translation` → `version`
- `verse_number` → `verse`
- `COALESCE(NULLIF(clean_text, ''), text)` → `text`
- Add `language = 'en'`
- Add `category = NULL`

```sql
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
```

#### Spanish Bible (RVR1909)

Column mapping with Spanish-specific fields:
- `translation` → `version`
- `verse_number` → `verse`
- `COALESCE(spanish_text, spanish_text_original, clean_text, text)` → `text`
- Add `language = 'es'`
- Add `category = NULL`

```sql
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
```

### SQL Execution Optimization

The service uses a two-tier execution strategy:

1. **Batch Execution (Primary):** Attempts to execute the entire SQL file at once for maximum speed
2. **Statement-by-Statement (Fallback):** If batch fails, splits on semicolons and executes individually with progress tracking

```dart
try {
  // Try batch execution first (fastest)
  await _db.execute(sql);
} catch (batchError) {
  // Fall back to statement-by-statement with progress
  final statements = sql.split(';').where((s) => s.trim().isNotEmpty);
  for (final statement in statements) {
    await _db.execute(statement);
    // Report progress every 1000 statements
  }
}
```

### Progress Tracking

Progress is reported through a `Stream<double>` with values from 0.0 to 1.0:

| Phase | Progress Range | Description |
|-------|----------------|-------------|
| Check loaded | 0.00 - 0.05 | Verify if data already exists |
| Create schema | 0.05 - 0.10 | Create bible_verses table |
| Load English | 0.10 - 0.50 | Fetch, execute, transform English |
| Load Spanish | 0.50 - 0.90 | Fetch, execute, transform Spanish |
| Mark loaded | 0.90 - 0.95 | Update metadata |
| Finalize | 0.95 - 1.00 | Final verification |

### Error Handling

The service handles multiple error scenarios:

1. **Network Errors:** Asset files not found or inaccessible
2. **SQL Errors:** Syntax errors in SQL statements
3. **Database Errors:** Transaction failures, locked database
4. **Memory Errors:** Out of memory with large files
5. **Validation Errors:** Incorrect verse counts after loading

All errors are wrapped in `BibleLoadException` with detailed context.

## Testing

### Running Tests

```bash
# Run all tests
flutter test test/bible_data_loader_web_test.dart

# Run specific test
flutter test test/bible_data_loader_web_test.dart --name "loadBibleData"

# Run with verbose output
flutter test test/bible_data_loader_web_test.dart --verbose
```

### Test Coverage

The test suite covers:
- ✅ Initial loading state check
- ✅ Full Bible data loading with progress
- ✅ Individual Bible loading (English/Spanish)
- ✅ Loading statistics accuracy
- ✅ Clear and reload functionality
- ✅ Idempotent loading (skip if already loaded)
- ✅ Schema validation
- ✅ Error handling and exceptions

## Performance

### Loading Times (Estimated)

| Operation | Time | Notes |
|-----------|------|-------|
| Asset fetch | 0.5-2s | Depends on network/browser cache |
| SQL execution (batch) | 2-5s | Optimal case |
| SQL execution (statements) | 10-30s | Fallback case |
| Data transformation | 1-3s | Per language |
| **Total (English)** | **4-10s** | Batch execution |
| **Total (Spanish)** | **3-8s** | Batch execution |
| **Total (Both)** | **7-18s** | Batch execution |

### Optimization Strategies

1. **Batch Execution:** Execute entire SQL file at once when possible
2. **Transaction Batching:** Process statements in groups of 100
3. **Progress Throttling:** Report progress every 1000 statements
4. **Index Creation:** Create indexes after data load, not during
5. **Schema Reuse:** Don't recreate tables if they exist

### Memory Usage

| Component | Memory | Notes |
|-----------|--------|-------|
| SQL file (English) | ~18 MB | In memory during load |
| SQL file (Spanish) | ~14 MB | In memory during load |
| Database (populated) | ~25 MB | IndexedDB storage |
| **Peak usage** | **~50 MB** | During simultaneous load |

## Integration Guide

### Step 1: Check Database Status

```dart
final db = await SqlJsHelper.database;
final loader = BibleDataLoaderWeb(db);

if (await loader.isBibleDataLoaded()) {
  // Data already loaded, proceed to app
  return;
}
```

### Step 2: Show Loading UI

```dart
class BibleLoadingScreen extends StatefulWidget {
  @override
  State<BibleLoadingScreen> createState() => _BibleLoadingScreenState();
}

class _BibleLoadingScreenState extends State<BibleLoadingScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBibles();
  }

  Future<void> _loadBibles() async {
    final db = await SqlJsHelper.database;
    final loader = BibleDataLoaderWeb(db);

    await for (final progress in loader.loadBibleData()) {
      setState(() => _progress = progress);
    }

    // Navigate to home screen
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Loading Bible Data...'),
            SizedBox(height: 20),
            LinearProgressIndicator(value: _progress),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }
}
```

### Step 3: Verify Loading

```dart
final stats = await loader.getLoadingStats();
if (!stats['is_complete']) {
  throw Exception('Bible loading incomplete!');
}

print('Loaded ${stats['total_verses']} verses');
```

## Troubleshooting

### Issue: "Failed to fetch SQL file"

**Cause:** Asset files not found or not included in pubspec.yaml

**Solution:**
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/bible_web_optimized.sql
    - assets/spanish_rvr1909_optimized.sql
```

### Issue: "SQL execution failed"

**Cause:** SQL syntax error or incompatible SQL.js version

**Solution:**
1. Validate SQL files manually
2. Check sql.js version compatibility
3. Enable fallback statement-by-statement execution

### Issue: "Verse count mismatch"

**Cause:** Incomplete data transformation or corrupted SQL files

**Solution:**
1. Re-export SQL files from Task 3.2
2. Verify SQL file integrity
3. Check transformation queries

### Issue: "Out of memory"

**Cause:** Large SQL files loaded into memory

**Solution:**
1. Use gzipped SQL files if supported
2. Reduce batch size in statement execution
3. Load languages separately (not simultaneously)

### Issue: "Loading takes too long"

**Cause:** Statement-by-statement fallback or slow browser

**Solution:**
1. Verify batch execution is working
2. Check browser console for errors
3. Test in different browsers
4. Consider pre-loading on first visit

## Next Steps

After implementing `BibleDataLoaderWeb`, proceed to:

### Task 3.4: FTS Index Setup

Create Full-Text Search indexes on the loaded Bible data:
- Create FTS5 virtual tables
- Populate FTS indexes from bible_verses
- Optimize for search performance
- Test search functionality

### Task 3.5: Web-Specific Database Service

Update DatabaseService to use conditional imports:
- Mobile: Use sqflite + BibleLoaderService
- Web: Use sql.js + BibleDataLoaderWeb
- Ensure API compatibility

### Task 3.6: Integration Testing

Test the complete web platform:
- Bible data loading
- Search functionality
- Daily verse selection
- Performance benchmarks

## Related Files

- **Mobile Loader:** `lib/core/services/bible_loader_service.dart`
- **SQL Helper:** `lib/core/database/sql_js_helper.dart`
- **Database Service:** `lib/core/services/database_service.dart`
- **SQL Dumps:** `assets/bible_web_optimized.sql`, `assets/spanish_rvr1909_optimized.sql`
- **Transform Queries:** `assets/bible_transform.sql`

## References

- [sql.js Documentation](https://sql.js.org/)
- [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web)
- [IndexedDB API](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API)
- [Flutter Web Best Practices](https://docs.flutter.dev/platform-integration/web/building)
