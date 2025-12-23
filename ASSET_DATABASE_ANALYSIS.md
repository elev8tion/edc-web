# Asset Database Analysis

## Overview

The Everyday Christian app uses pre-populated SQLite databases stored in assets to load Bible data efficiently at startup. This analysis documents the complete structure, loading process, and web migration implications for 31,103+ English verses and 31,084 Spanish verses organized across 66 books of the Bible with a 366-day verse rotation schedule.

## Asset Files

### English Bible (WEB - World English Bible)

**File Path:** `assets/bible.db`

**File Size:** 27 MB

**Tables:**
- `verses` - Main Bible content with 31,103 verses
- `daily_verse_schedule` - 366-day rotation calendar
- `verses_fts` - Full-Text Search virtual table (Porter stemming + ASCII tokenization)
- `sqlite_sequence` - SQLite internal auto-increment tracking

**Row Counts:**
- Verses (WEB translation): 31,103
- Daily Schedule Entries: 366 (complete leap-year calendar: Jan 1 - Dec 31, plus Feb 29)

**Books:** 66 (all canonical Old and New Testament books)

### Spanish Bible (RVR1909 - Reina-Valera 1909)

**File Path:** `assets/spanish_bible_rvr1909.db`

**File Size:** 16 MB

**Tables:**
- `verses` - Main Bible content with 31,084 verses (4 fewer verses than English - minor translation variance)
- Indexes only (no separate schedule table in asset DB)

**Row Counts:**
- Verses (RVR1909 translation): 31,084
- Note: No daily_verse_schedule table in Spanish asset DB (schedule is derived from English during load)

**Books:** 66 books with Spanish names (e.g., "Génesis" instead of "Genesis")

## Asset Database Schema

### English Bible DB: verses Table

```sql
CREATE TABLE verses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  translation TEXT DEFAULT 'WEB',
  reference TEXT NOT NULL,
  themes TEXT,
  clean_text TEXT
);

-- Indexes for performance
CREATE INDEX idx_book_chapter ON verses(book, chapter);
CREATE INDEX idx_reference ON verses(reference);
CREATE INDEX idx_book ON verses(book);
CREATE INDEX idx_translation ON verses(translation);
CREATE INDEX idx_verse_number ON verses(verse_number);

-- Full-Text Search virtual table
CREATE VIRTUAL TABLE verses_fts USING fts5(
  text,
  content=verses,
  tokenize='porter ascii'
);
```

**Column Details:**
- `id`: Auto-incrementing primary key (1-31,103 for WEB)
- `book`: Book name in English (e.g., "Genesis", "Matthew", "Revelation")
- `chapter`: Chapter number (1-150 for most books)
- `verse_number`: Verse number within chapter
- `text`: Full verse text (40-300 characters typically)
- `translation`: Always "WEB" for this database
- `reference`: Standardized reference string (e.g., "Genesis 1:1")
- `themes`: JSON array of theme tags (e.g., `["creation", "faith"]`)
- `clean_text`: Cleaned version of text (whitespace normalized)

### Spanish Bible DB: verses Table

```sql
CREATE TABLE verses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  translation TEXT DEFAULT 'RVR1909',
  reference TEXT NOT NULL,
  themes TEXT,
  clean_text TEXT,
  spanish_text TEXT,
  spanish_text_original TEXT
);

-- Same indexes as English DB
CREATE INDEX idx_book_chapter ON verses(book, chapter);
CREATE INDEX idx_reference ON verses(reference);
CREATE INDEX idx_book ON verses(book);
CREATE INDEX idx_translation ON verses(translation);
CREATE INDEX idx_verse_number ON verses(verse_number);
```

**Additional Columns (Spanish-specific):**
- `spanish_text`: Additional Spanish text field (may be variant/commentary)
- `spanish_text_original`: Original Spanish text before processing

### English Bible DB: daily_verse_schedule Table

```sql
CREATE TABLE daily_verse_schedule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  month INTEGER NOT NULL,        -- 1-12
  day INTEGER NOT NULL,          -- 1-31
  verse_id INTEGER NOT NULL,     -- Foreign key to verses.id
  FOREIGN KEY (verse_id) REFERENCES verses (id),
  UNIQUE(month, day)
);

CREATE INDEX idx_daily_verse_schedule_date ON daily_verse_schedule(month, day);
```

**Sample Data:**
```
id   month  day  verse_id  -> Resolves to
---  -----  ---  --------
379  1      1    20377     Lamentations 3:22
380  7      1    26418     John 8:36
381  1      2    18524     Isaiah 43:18
382  7      2    28860     2 Corinthians 3:17
383  1      3    29463     Philippians 4:19
```

**Calendar Structure:**
- 366 entries covering Jan 1 - Dec 31, plus Feb 29 (leap year)
- Each (month, day) pair maps to exactly one verse via verse_id
- Dates are repeated: Jan 1 has a different verse than Jul 1 (2 verses per date)
- Used to create a full-year rotation of daily verses

## Loading Process

### Entry Point (in `lib/core/providers/app_providers.dart`)

The loading is triggered in the app initialization flow:

```dart
// Pseudo-code showing when loaders are called
if (!webLoaded) {
  await bibleLoader.loadEnglishBible();
}
if (!spanishLoaded) {
  await bibleLoader.loadSpanishBible();
}
```

### English Bible Loading Flow

**File:** `lib/core/services/bible_loader_service.dart` (Lines 43-102)

```
Step 1: Check database readiness
   └─ Await _database.database instance

Step 2: Prepare temp location
   └─ Get databasesPath from platform
   └─ Build temp path: {databasesPath}/asset_bible_en.db

Step 3: Copy asset to temp location (Line 50-52)
   └─ Load 'assets/bible.db' via rootBundle.load()
   └─ Convert ByteData to Uint8List
   └─ Write bytes to temp file with flush: true

Step 4: ATTACH asset database (Line 56)
   └─ Execute: ATTACH DATABASE '{assetDbPath}' AS asset_db_en

Step 5: INSERT verses with transformation (Lines 60-71)
   └─ Copy from asset_db_en.verses to app db.bible_verses
   └─ Apply column mappings (see Schema Transformation below)
   └─ Filter: WHERE translation = 'WEB'
   └─ INSERT OR REPLACE (handles duplicates)
   └─ ~31,103 verses inserted

Step 6: INSERT daily schedule with JOIN (Lines 75-91)
   └─ Copy from asset_db_en.daily_verse_schedule
   └─ JOIN with asset verses to get book/chapter/verse info
   └─ JOIN with app db.bible_verses to get target verse_id
   └─ Add language='en' hardcoded
   └─ ~366 schedule entries inserted

Step 7: DETACH asset database (Line 94)
   └─ Execute: DETACH DATABASE asset_db_en

Step 8: Clean up temp file (Line 97)
   └─ Delete temp file from device storage
```

### Spanish Bible Loading Flow

**File:** `lib/core/services/bible_loader_service.dart` (Lines 105-231)

```
Step 1-4: Same as English (copy asset to temp, ATTACH)

Step 5: INSERT verses with transformation (Lines 121-132)
   └─ Copy from asset_db_es.verses to app db.bible_verses
   └─ Column mappings same as English
   └─ Filter: WHERE translation = 'RVR1909'
   └─ Add language='es' hardcoded
   └─ ~31,084 verses inserted

Step 6: INSERT daily schedule with BOOK NAME TRANSLATION (Lines 137-220)
   └─ Query existing English schedule from app db.daily_verse_schedule
   └─ JOIN with app db.bible_verses (English versions) to get English book names
   └─ Use CASE statement to translate English names → Spanish names (66 books)
   └─ JOIN with app db.bible_verses (Spanish versions) using translated names
   └─ Add language='es'
   └─ ~366 Spanish schedule entries inserted
   └─ This reuses the same daily calendar but with Spanish verse_ids

Step 7-8: DETACH and cleanup (same as English)
```

## Schema Transformation

### Asset DB → App DB Column Mapping

#### English Bible

| Asset DB Column | App DB Column | Transformation | Line |
|-----------------|---------------|----------------|------|
| `translation` | `version` | Direct copy ("WEB") | 63 |
| `book` | `book` | Direct copy (English names) | 64 |
| `chapter` | `chapter` | Direct copy | 65 |
| `verse_number` | `verse` | Direct copy | 66 |
| `clean_text` | `text` | Direct copy (normalized text) | 67 |
| N/A | `language` | Hardcoded 'en' | 68 |
| N/A | `themes` | NULL (not copied) | - |
| N/A | `category` | NULL (not set during load) | - |
| N/A | `reference` | NULL (calculated later if needed) | - |

**English SQL Transformation (Lines 60-71):**

```sql
INSERT OR REPLACE INTO bible_verses (version, book, chapter, verse, text, language)
SELECT
  translation as version,           -- "WEB" → version
  book,                             -- Direct copy
  chapter,                          -- Direct copy
  verse_number as verse,            -- Column rename
  clean_text as text,               -- Normalized text content
  'en' as language                  -- Constant
FROM asset_db_en.verses
WHERE translation = 'WEB'
```

**Data Types:**
- No explicit type conversions needed (SQLite is dynamically typed)
- All asset columns map to compatible app DB types

#### Spanish Bible

| Asset DB Column | App DB Column | Transformation | Line |
|-----------------|---------------|----------------|------|
| `translation` | `version` | Direct copy ("RVR1909") | 124 |
| `book` | `book` | Direct copy (Spanish names) | 125 |
| `chapter` | `chapter` | Direct copy | 126 |
| `verse_number` | `verse` | Direct copy | 127 |
| `text` | `text` | Direct copy (Spanish text) | 128 |
| N/A | `language` | Hardcoded 'es' | 129 |

**Spanish SQL Transformation (Lines 121-132):**

```sql
INSERT OR REPLACE INTO bible_verses (version, book, chapter, verse, text, language)
SELECT
  translation as version,           -- "RVR1909" → version
  book,                             -- Direct copy (already in Spanish)
  chapter,                          -- Direct copy
  verse_number as verse,            -- Column rename
  text,                             -- Spanish text (already clean)
  'es' as language                  -- Constant
FROM asset_db_es.verses
WHERE translation = 'RVR1909'
```

### Book Name Translation (66 Books)

English → Spanish mapping is implemented as a CASE statement used during Spanish schedule insertion (Lines 147-214):

```sql
CASE bv_en.book
  -- Old Testament (39 books)
  WHEN 'Genesis' THEN 'Génesis'
  WHEN 'Exodus' THEN 'Éxodo'
  WHEN 'Leviticus' THEN 'Levítico'
  WHEN 'Numbers' THEN 'Números'
  WHEN 'Deuteronomy' THEN 'Deuteronomio'
  WHEN 'Joshua' THEN 'Josué'
  WHEN 'Judges' THEN 'Jueces'
  WHEN 'Ruth' THEN 'Rut'
  WHEN '1 Samuel' THEN '1 Samuel'
  WHEN '2 Samuel' THEN '2 Samuel'
  WHEN '1 Kings' THEN '1 Reyes'
  WHEN '2 Kings' THEN '2 Reyes'
  WHEN '1 Chronicles' THEN '1 Crónicas'
  WHEN '2 Chronicles' THEN '2 Crónicas'
  WHEN 'Ezra' THEN 'Esdras'
  WHEN 'Nehemiah' THEN 'Nehemías'
  WHEN 'Esther' THEN 'Ester'
  WHEN 'Job' THEN 'Job'
  WHEN 'Psalms' THEN 'Salmos'
  WHEN 'Proverbs' THEN 'Proverbios'
  WHEN 'Ecclesiastes' THEN 'Eclesiastés'
  WHEN 'Song of Solomon' THEN 'Cantares'
  WHEN 'Isaiah' THEN 'Isaías'
  WHEN 'Jeremiah' THEN 'Jeremías'
  WHEN 'Lamentations' THEN 'Lamentaciones'
  WHEN 'Ezekiel' THEN 'Ezequiel'
  WHEN 'Daniel' THEN 'Daniel'
  WHEN 'Hosea' THEN 'Oseas'
  WHEN 'Joel' THEN 'Joel'
  WHEN 'Amos' THEN 'Amós'
  WHEN 'Obadiah' THEN 'Abdías'
  WHEN 'Jonah' THEN 'Jonás'
  WHEN 'Micah' THEN 'Miqueas'
  WHEN 'Nahum' THEN 'Nahúm'
  WHEN 'Habakkuk' THEN 'Habacuc'
  WHEN 'Zephaniah' THEN 'Sofonías'
  WHEN 'Haggai' THEN 'Hageo'
  WHEN 'Zechariah' THEN 'Zacarías'
  WHEN 'Malachi' THEN 'Malaquías'
  -- New Testament (27 books)
  WHEN 'Matthew' THEN 'Mateo'
  WHEN 'Mark' THEN 'Marcos'
  WHEN 'Luke' THEN 'Lucas'
  WHEN 'John' THEN 'Juan'
  WHEN 'Acts' THEN 'Hechos'
  WHEN 'Romans' THEN 'Romanos'
  WHEN '1 Corinthians' THEN '1 Corintios'
  WHEN '2 Corinthians' THEN '2 Corintios'
  WHEN 'Galatians' THEN 'Gálatas'
  WHEN 'Ephesians' THEN 'Efesios'
  WHEN 'Philippians' THEN 'Filipenses'
  WHEN 'Colossians' THEN 'Colosenses'
  WHEN '1 Thessalonians' THEN '1 Tesalonicenses'
  WHEN '2 Thessalonians' THEN '2 Tesalonicenses'
  WHEN '1 Timothy' THEN '1 Timoteo'
  WHEN '2 Timothy' THEN '2 Timoteo'
  WHEN 'Titus' THEN 'Tito'
  WHEN 'Philemon' THEN 'Filemón'
  WHEN 'Hebrews' THEN 'Hebreos'
  WHEN 'James' THEN 'Santiago'
  WHEN '1 Peter' THEN '1 Pedro'
  WHEN '2 Peter' THEN '2 Pedro'
  WHEN '1 John' THEN '1 Juan'
  WHEN '2 John' THEN '2 Juan'
  WHEN '3 John' THEN '3 Juan'
  WHEN 'Jude' THEN 'Judas'
  WHEN 'Revelation' THEN 'Apocalipsis'
  ELSE bv_en.book  -- Fallback (should not occur with valid data)
END = bv_es.book
```

**Translation Coverage:** 66 books (complete biblical canon)

**Encoding:** UTF-8 (supports Spanish diacriticals: á, é, í, ó, ú, ü, ñ, ¿, ¡)

## Daily Verse Schedule Loading

### English Schedule Creation (In Asset DB)

Pre-populated in `assets/bible.db`:
- 366 entries (Jan 1 - Dec 31, with Feb 29)
- Created by asset DB maintainer (not generated at runtime)
- Each date points to specific verse_id in asset DB

### Spanish Schedule Creation (Runtime Generation)

**Process (Lines 137-220 in bible_loader_service.dart):**

1. Query existing English schedule from app DB:
   ```sql
   FROM daily_verse_schedule s
   WHERE s.language = 'en'
   ```

2. For each English schedule entry:
   - Get the English verse via `verse_id`
   - Extract book name, chapter, verse number
   - Translate book name using CASE statement
   - Find corresponding Spanish verse using translated book + chapter + verse
   - Insert new entry with Spanish verse_id

3. Result: 366 Spanish schedule entries (same calendar, different verse IDs)

### Calendar Coverage

**Date Range:** 
- January 1 - December 31
- Includes February 29 (leap year support)
- Total: 366 calendar days

**Verse Rotation:**
- 366 daily verses mean every date has exactly one verse assigned
- Users see different verses if they check the same date in future years (not reused within same year)

**Bilingual Support:**
- English (language='en'): 366 entries
- Spanish (language='es'): 366 entries (same dates, different verses)
- Total: 732 schedule entries in app DB

**Index:** `idx_daily_verse_schedule_date_lang` on (month, day, language)

## Temporary Files Management

### File Copy Process

**English Bible:**
- Source: Bundle asset `assets/bible.db` (27 MB)
- Temp Location: `{databasesPath}/asset_bible_en.db`
- Method: `rootBundle.load()` → Uint8List → File.writeAsBytes()
- Flush: `flush: true` ensures write to disk before ATTACH

**Spanish Bible:**
- Source: Bundle asset `assets/spanish_bible_rvr1909.db` (16 MB)
- Temp Location: `{databasesPath}/asset_bible_es.db`
- Same process as English

### Cleanup

**After successful load:**
1. DETACH DATABASE completes
2. File deleted immediately: `await File(assetDbPath).delete()`
3. No orphaned temp files remain

**Error Handling:**
- Both methods use `try/catch` with `rethrow`
- If load fails, temp file may persist (not explicitly cleaned in catch block)
- Should be cleaned up during next app startup or manually

### Storage Impact

**Device Disk Usage During Load:**
- English temp file: 27 MB (temporary)
- Spanish temp file: 16 MB (temporary)
- App DB growth: ~43 MB total (verses + schedule + indexes)
- Peak usage: ~86 MB (during simultaneous temp file + app DB persistence)

## Performance Characteristics

### Data Volume

| Category | Count | Size |
|----------|-------|------|
| English verses (WEB) | 31,103 | 27 MB asset |
| Spanish verses (RVR1909) | 31,084 | 16 MB asset |
| English schedule entries | 366 | ~10 KB |
| Spanish schedule entries | 366 | ~10 KB |
| Total Bible data | ~62,187 verses | ~43 MB (final DB) |
| Total verses + schedule | ~62,919 records | - |

### Load Time Estimate

**Assumptions:**
- Device: Modern phone (2020+)
- I/O: Flash storage (typical mobile SSD)
- Network: N/A (local assets)

**Breakdown:**
- Copy English asset to temp: ~500 ms (27 MB write)
- ATTACH + INSERT verses (31,103): ~1.5-2 seconds (SQL processing)
- INSERT schedule (366): ~100-200 ms
- DETACH + cleanup: ~100 ms
- **Subtotal English:** ~2-3 seconds

- Copy Spanish asset to temp: ~300 ms (16 MB write)
- ATTACH + INSERT verses (31,084): ~1.5-2 seconds
- INSERT schedule with CASE translation (366): ~200-400 ms (more complex JOIN)
- DETACH + cleanup: ~100 ms
- **Subtotal Spanish:** ~2-3 seconds

**Total Load Time:** 4-6 seconds (both languages)

**Optimization Opportunities:**
- Parallel loading (both languages simultaneously)
- Batch inserts vs individual inserts
- Index creation timing (currently created during app DB creation)
- Async loading with progress updates

### Memory Usage

**Peak Memory (During Load):**
- Asset DB in memory: ~27 MB (English) + ~16 MB (Spanish) = 43 MB
- App DB connection: ~5-10 MB
- Statement buffers: ~2-5 MB
- **Total: ~50-60 MB peak**

**Steady State:**
- App DB (on disk): ~43 MB
- In-memory cache: varies by query operations

### FTS (Full-Text Search) Details

**English DB Only:**
- FTS5 virtual table created during asset DB setup
- Indexes 31,103 verse texts
- Tokenizer: "porter ascii" (Porter stemming + ASCII normalization)
- Supports: MATCH queries, snippet(), rank

**Not Copied to App DB:**
- FTS from asset DB stays in asset DB
- App DB has separate FTS table (see database_helper.dart for app DB FTS config)
- App DB uses platform-specific FTS (FTS5 on iOS, FTS4 on Android)

## Code References

### Primary File

**File:** `/lib/core/services/bible_loader_service.dart`

**Key Methods:**

| Method | Lines | Purpose |
|--------|-------|---------|
| `loadAllBibles()` | 15-26 | Public entry point, loads both languages |
| `loadEnglishBible()` | 29-33 | Public entry point, English only |
| `loadSpanishBible()` | 36-40 | Public entry point, Spanish only |
| `_copyEnglishBible()` | 43-102 | Implementation: copy + INSERT English verses + schedule |
| `_copySpanishBible()` | 105-231 | Implementation: copy + INSERT Spanish verses + schedule |
| `isBibleLoaded()` | 235-244 | Check if Bible data already loaded |
| `getLoadingProgress()` | 247-260 | Get verse count for progress indication |

**SQL Queries:**

| Operation | Lines | Type |
|-----------|-------|------|
| ATTACH asset DB (English) | 56 | Session setup |
| INSERT English verses | 60-71 | Data transformation |
| INSERT English schedule | 75-91 | Data transformation + JOIN |
| DETACH asset DB (English) | 94 | Session cleanup |
| ATTACH asset DB (Spanish) | 117 | Session setup |
| INSERT Spanish verses | 121-132 | Data transformation |
| INSERT Spanish schedule | 137-220 | Data transformation + CASE translation + JOIN |
| DETACH asset DB (Spanish) | 223 | Session cleanup |

**Error Handling:**
- All methods use try/catch with rethrow
- BibleLoaderService throws exceptions to caller
- Caller (app_providers.dart) responsible for retry/fallback logic

## Web Migration Strategy

### Current Platform Dependencies

**iOS/Android (Current Implementation):**
- ✅ Native SQLite via `sqflite` package
- ✅ Asset loading via `rootBundle`
- ✅ File system access via `path_provider`
- ✅ ATTACH DATABASE syntax supported
- ✅ Direct file I/O operations

### Web Platform Challenges

| Feature | iOS/Android | Web | Issue |
|---------|------------|-----|-------|
| File system I/O | ✅ | ❌ | WASM sandboxed, no FS access |
| SQLite ATTACH | ✅ | ⚠️ | sql.js supports ATTACH but limited |
| Asset loading | ✅ | ✅ | Via fetch(), same semantic |
| Binary DB copy | ✅ | ❌ | Can't create temp files |
| File cleanup | ✅ | N/A | No file system |
| Concurrent DBs | ✅ | ⚠️ | sql.js in single WASM instance |

### Proposed Solutions

#### Solution 1: Export Asset DBs to SQL Dumps

**Advantages:**
- All data in SQL text format
- Works with any web SQLite implementation (sql.js, better-sqlite3, etc.)
- Easy to version control and diff

**Approach:**
1. Export asset DBs to SQL dump files:
   ```bash
   sqlite3 assets/bible.db .dump > assets/bible_dump.sql
   sqlite3 assets/spanish_bible_rvr1909.db .dump > assets/spanish_dump.sql
   ```

2. Include in web assets (via pubspec.yaml)

3. At app startup (web only):
   ```dart
   if (kIsWeb) {
     final sqlDump = await rootBundle.loadString('assets/bible_dump.sql');
     await db.execute(sqlDump);  // sql.js supports multi-statement execute
   }
   ```

**Size Impact:**
- SQL text ~2-3x larger than binary DB
- GZip compression reduces to ~30-40% of original size
- Acceptable for web bundle size

#### Solution 2: Pre-populate IndexedDB with SQL.js

**Advantages:**
- Persistent across sessions
- No re-download on app launch
- Works offline

**Approach:**
1. Convert asset DBs to sql.js format
2. Serialize to IndexedDB on first load
3. Load from IndexedDB on subsequent launches

#### Solution 3: Hybrid: Server-side SQLite DB

**Advantages:**
- Single source of truth
- Easy updates
- Reduces app bundle size

**Approach:**
1. Host Bible databases on server
2. Download via API on first launch
3. Cache locally in IndexedDB
4. Query local copy for reads

### Web-Specific Implementation

**File:** `lib/core/services/bible_loader_service.dart` (needs web variant)

```dart
// Pseudo-code for web variant
class BibleLoaderService {
  // ... existing code ...

  Future<void> _copyEnglishBible() async {
    if (kIsWeb) {
      await _copyEnglishBibleWeb();
    } else {
      await _copyEnglishBibleNative();
    }
  }

  Future<void> _copyEnglishBibleWeb() async {
    final db = await _database.database;
    
    // Load SQL dump as text
    final sqlDump = await rootBundle.loadString('assets/bible_dump.sql');
    
    // Split into statements and execute
    final statements = sqlDump.split(';\n').where((s) => s.trim().isNotEmpty);
    for (final stmt in statements) {
      await db.execute(stmt);
    }
  }
}
```

### Critical Considerations for Web

1. **Memory:** Binary DBs must fit in browser memory
   - Current total: ~43 MB
   - Browser limit: 2-4 GB (typically)
   - ✅ Acceptable

2. **Download Size:** Asset files must download quickly
   - Current: 27 MB (English) + 16 MB (Spanish)
   - Compressed: ~5-8 MB
   - Time: 1-3 seconds on 4G
   - ✅ Acceptable

3. **Persistence:** Data must survive page reload
   - sql.js + IndexedDB
   - or use localStorage for metadata + re-download

4. **Synchronization:** Web and native must use same databases
   - ✅ Same binary formats means identical loads
   - Only difference: how bytes get into SQLite engine

## Data Validation Notes

**Verified Counts:**
- English verses: 31,103 (WEB translation)
- Spanish verses: 31,084 (RVR1909 translation)
- Schedule entries: 366 (both languages)
- Book names: 66 (mapped correctly)

**Verified Mapping:**
- All book names appear in both translations
- No missing verse mappings (all schedules created successfully)
- Date coverage: Complete (Jan 1 - Dec 31 + Feb 29)

**Testing Recommendations:**
1. Verify 31,103 + 31,084 verses = 62,187 total in app DB
2. Verify 732 schedule entries (366 × 2 languages)
3. Spot-check 10 random verses match source
4. Verify all 66 books present in each language
5. Test that Feb 29 schedule entry exists
6. Verify no duplicate verse_ids in same schedule

## Summary

The asset database system efficiently pre-loads 62,000+ Bible verses into the app database on first launch using SQLite ATTACH/INSERT operations. The English Bible (27 MB, 31,103 verses) and Spanish Bible (16 MB, 31,084 verses) are copied to temporary locations, attached to the main app database, transformed with column mapping and book name translation, and cleaned up. A 366-day verse rotation schedule enables daily verse features. Web migration will require exporting assets to SQL dumps or alternative loading mechanisms, as SQLite file I/O isn't available in web environments.

