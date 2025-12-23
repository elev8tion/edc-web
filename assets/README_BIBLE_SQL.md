# Bible SQL Files - Web Delivery Optimized

## Overview

This directory contains optimized SQL dumps of Bible translations for web platform delivery. The files have been processed to minimize size and remove unnecessary content while maintaining complete verse data.

## Files

### Production Files (Use These)

| File | Size | Compressed | Verses | Description |
|------|------|------------|--------|-------------|
| `bible_web_optimized.sql` | 18 MB | 3.5 MB | 31,103 | English WEB translation |
| `spanish_rvr1909_optimized.sql` | 14 MB | 2.0 MB | 31,084 | Spanish RVR1909 translation |
| `bible_transform.sql` | 4 KB | - | - | Transformation queries |

**Total Download:** 32 MB uncompressed, 5.5 MB gzipped

### Testing & Documentation

| File | Description |
|------|-------------|
| `OPTIMIZATION_REPORT.md` | Complete optimization report |
| `test_bible_workflow.sql` | Complete loading workflow test |
| `bible_web_optimized.sql.gz` | Pre-compressed English Bible |
| `spanish_rvr1909_optimized.sql.gz` | Pre-compressed Spanish Bible |

### Legacy Files (Can Be Removed)

| File | Status |
|------|--------|
| `bible_kjv.sql` | Not used (KJV not needed) |
| `bible.db` | Source database (can keep for reference) |
| `spanish_bible_rvr1909.db` | Source database (can keep for reference) |

## File Structure

Each optimized SQL file contains:

```sql
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE verses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    book TEXT NOT NULL,
    chapter INTEGER NOT NULL,
    verse_number INTEGER NOT NULL,
    text TEXT NOT NULL,
    translation TEXT DEFAULT 'WEB' or 'RVR1909',
    reference TEXT NOT NULL,
    themes TEXT,
    clean_text TEXT,
    -- Spanish files also have:
    spanish_text TEXT,
    spanish_text_original TEXT
);
INSERT INTO verses VALUES(...);  -- 31,103 or 31,084 rows
COMMIT;
```

**Excluded (for optimization):**
- FTS5 full-text search tables
- daily_verse_schedule table
- CREATE INDEX statements
- Metadata tables

## Usage Workflow

### On Web Platform

```javascript
// 1. Create main bible_verses table
await db.exec(`
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
    reference TEXT NOT NULL
  )
`);

// 2. Fetch and load English Bible
const webSQL = await fetch('/assets/bible_web_optimized.sql').then(r => r.text());
await db.exec(webSQL);

// 3. Transform English verses
await db.exec(`
  INSERT INTO bible_verses (version, book, chapter, verse, text, language, themes, category, reference)
  SELECT
    translation, book, chapter, verse_number,
    COALESCE(NULLIF(clean_text, ''), text),
    'en', themes, NULL, reference
  FROM verses WHERE translation = 'WEB'
`);

// 4. Drop temporary table
await db.exec('DROP TABLE verses');

// 5. Repeat for Spanish
const spanishSQL = await fetch('/assets/spanish_rvr1909_optimized.sql').then(r => r.text());
await db.exec(spanishSQL);

await db.exec(`
  INSERT INTO bible_verses (version, book, chapter, verse, text, language, themes, category, reference)
  SELECT
    translation, book, chapter, verse_number,
    COALESCE(spanish_text, spanish_text_original, clean_text),
    'es', themes, NULL, reference
  FROM verses WHERE translation = 'RVR1909'
`);

await db.exec('DROP TABLE verses');

// 6. Create FTS index
await db.exec(`
  CREATE VIRTUAL TABLE bible_verses_fts USING fts5(
    text, content='bible_verses', content_rowid='id'
  )
`);
```

## Download Performance

| Network | Speed | Load Time |
|---------|-------|-----------|
| Slow 3G | 0.4 Mbps | ~2 minutes |
| Fast 3G | 1.6 Mbps | ~30 seconds |
| 4G | 10 Mbps | ~5 seconds |
| Fast 4G/LTE | 50 Mbps | <1 second |
| Broadband | 25 Mbps | ~2 seconds |

**Recommendation:** Show loading progress indicator for better UX.

## Testing

### Quick Verification

```bash
# Test English Bible
sqlite3 /tmp/test.db < bible_web_optimized.sql
sqlite3 /tmp/test.db "SELECT COUNT(*) FROM verses"
# Expected: 31103

# Test Spanish Bible
sqlite3 /tmp/test.db < spanish_rvr1909_optimized.sql
sqlite3 /tmp/test.db "SELECT COUNT(*) FROM verses"
# Expected: 31084
```

### Complete Workflow Test

```bash
cd assets
sqlite3 /tmp/test_workflow.db < test_bible_workflow.sql
```

This will:
1. Create bible_verses table
2. Load both Bibles
3. Transform data
4. Verify verse counts
5. Display sample verses

## Data Integrity

### English Bible (WEB)
- **Translation:** World English Bible
- **Verses:** 31,103
- **Books:** Genesis through Revelation
- **First Verse:** Genesis 1:1 - "In the beginning, God"
- **Last Verse:** Revelation 22:21 - "The grace of the Lord Jesus Christ..."

### Spanish Bible (RVR1909)
- **Translation:** Reina-Valera 1909
- **Verses:** 31,084
- **Books:** Génesis through Apocalipsis
- **First Verse:** Génesis 1:1 - "EN el principio crió Dios los cielos y la tierra."
- **Last Verse:** Apocalipsis 22:21 - "La gracia de nuestro Señor Jesucristo..."

### Combined
- **Total Verses:** 62,187
- **Languages:** English (en), Spanish (es)
- **Complete Coverage:** Old Testament + New Testament in both languages

## Serving Strategy

### Option 1: Direct SQL Files (Recommended)
```
Content-Type: text/plain; charset=utf-8
Content-Encoding: gzip
```

Serve pre-compressed files and let browser handle decompression.

### Option 2: .gz Files
```
Content-Type: application/x-gzip
```

Serve .sql.gz files and decompress in JavaScript (requires pako.js or similar).

**Recommendation:** Use Option 1 for simplicity and browser-native performance.

## Optimization Summary

- ✅ Removed FTS5 tables (10+ MB saved)
- ✅ Removed daily_verse_schedule (metadata table)
- ✅ Removed CREATE INDEX statements (not needed for temp tables)
- ✅ Using WEB instead of KJV (correct translation)
- ✅ Clean, minimal structure
- ✅ 82.8% compression ratio with gzip
- ✅ All 62,187 verses verified

## Changelog

**2024-12-15 - Task 3.2**
- Created `bible_web_optimized.sql` from bible.db (WEB translation)
- Optimized `spanish_rvr1909_optimized.sql` (removed indices)
- Generated compressed .sql.gz versions
- Verified data integrity (all verses present)
- Updated `bible_transform.sql` with new file references
- Created documentation and test workflow

**Previous State (Task 3.1)**
- Had bible_kjv.sql (28 MB with FTS tables and indices)
- Had spanish_rvr1909.sql (14 MB with indices)

## Next Steps

See Task 3.3: Bible Data Loader Service
- Implement BibleDataLoader service in Flutter/Dart
- Integrate SQL.js for web platform
- Add loading progress UI
- Implement IndexedDB caching
- Add error handling and retry logic
