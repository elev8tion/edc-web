-- Bible Database Transformation Script
-- Transforms asset database schema to main database schema
--
-- ASSET SCHEMA:
--   translation, book, chapter, verse_number, clean_text, reference, themes
--
-- TARGET SCHEMA (bible_verses table):
--   version, book, chapter, verse, text, language, themes, category, reference
--
-- COLUMN MAPPING:
--   translation     → version
--   clean_text      → text
--   verse_number    → verse
--   + language      → 'en' or 'es' (added)
--   + category      → NULL (not in asset)
--
-- USAGE FOR ENGLISH BIBLE (WEB):
-- This script is designed to be executed after loading bible_web_optimized.sql
-- The transformation queries below show the mapping strategy
--
-- USAGE FOR SPANISH BIBLE (RVR1909):
-- Similar approach, but use spanish_text or spanish_text_original for text field
-- and set language='es'

-- ==============================================================================
-- ENGLISH BIBLE TRANSFORMATION (WEB)
-- ==============================================================================

-- Step 1: Load the bible_web_optimized.sql dump (creates verses table with asset schema)
-- Step 2: Transform and insert into bible_verses table:

-- INSERT INTO bible_verses (version, book, chapter, verse, text, language, themes, category, reference)
-- SELECT
--   translation as version,
--   book,
--   chapter,
--   verse_number as verse,
--   COALESCE(NULLIF(clean_text, ''), text) as text,  -- Use clean_text if available, fallback to full text
--   'en' as language,
--   themes,
--   NULL as category,
--   reference
-- FROM verses
-- WHERE translation = 'WEB';

-- ==============================================================================
-- SPANISH BIBLE TRANSFORMATION (RVR1909)
-- ==============================================================================

-- Step 1: Load the spanish_rvr1909_optimized.sql dump (creates verses table with asset schema)
-- Step 2: Transform and insert into bible_verses table:

-- INSERT INTO bible_verses (version, book, chapter, verse, text, language, themes, category, reference)
-- SELECT
--   translation as version,
--   book,
--   chapter,
--   verse_number as verse,
--   COALESCE(spanish_text, spanish_text_original, clean_text) as text,
--   'es' as language,
--   themes,
--   NULL as category,
--   reference
-- FROM verses
-- WHERE translation = 'RVR1909';

-- ==============================================================================
-- NOTES FOR WEB IMPLEMENTATION
-- ==============================================================================

-- For web platform, the workflow will be:
-- 1. Create bible_verses table with main schema
-- 2. Fetch bible_web_optimized.sql via HTTP (18 MB uncompressed, 3.5 MB gzipped)
-- 3. Execute it to create temporary verses table
-- 4. Run transformation INSERT query above
-- 5. Drop temporary verses table
-- 6. Repeat for spanish_rvr1909_optimized.sql (14 MB uncompressed, 2.0 MB gzipped)
-- 7. Rebuild FTS index after all data is loaded

-- OPTIMIZATION NOTES:
-- 1. The optimized SQL files contain ONLY the verses table and inserts
-- 2. No FTS tables, no daily_verse_schedule, no indices on temporary tables
-- 3. Total download: ~32 MB uncompressed, ~5.5 MB gzipped
-- 4. Consider serving pre-compressed .sql.gz files with proper Content-Encoding headers

-- DATA QUALITY NOTES:
-- 1. The English Bible has 10 verses where clean_text is empty but text contains
--    annotations (e.g., Psalms 34:1, Proverbs 31:10, Mark 16:9).
--    The transformation uses COALESCE(NULLIF(clean_text, ''), text) to handle this.
-- 2. These verses are primarily section headers or annotation-only verses.
-- 3. Total verse counts: English (WEB) = 31,103, Spanish (RVR1909) = 31,084

-- ==============================================================================
-- VERIFICATION QUERIES
-- ==============================================================================

-- Check verse counts:
-- SELECT COUNT(*) FROM bible_verses WHERE language = 'en' AND version = 'WEB';
-- Expected: 31,103 verses

-- SELECT COUNT(*) FROM bible_verses WHERE language = 'es' AND version = 'RVR1909';
-- Expected: 31,084 verses

-- Sample verification:
-- SELECT * FROM bible_verses WHERE book = 'Genesis' AND chapter = 1 AND verse = 1 LIMIT 2;
-- Should return Genesis 1:1 in both English (WEB) and Spanish (RVR1909)
