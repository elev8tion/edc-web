-- Complete Bible Loading Workflow Test
-- This demonstrates the exact workflow that will be used on web platform

-- Step 1: Create main bible_verses table
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
    reference TEXT NOT NULL
);

-- Step 2: Load English Bible (WEB)
-- (In web: fetch bible_web_optimized.sql and execute it)
.read bible_web_optimized.sql

-- Step 3: Transform and insert English verses
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
WHERE translation = 'WEB';

-- Step 4: Drop temporary English table
DROP TABLE verses;

-- Step 5: Load Spanish Bible (RVR1909)
-- (In web: fetch spanish_rvr1909_optimized.sql and execute it)
.read spanish_rvr1909_optimized.sql

-- Step 6: Transform and insert Spanish verses
INSERT INTO bible_verses (version, book, chapter, verse, text, language, themes, category, reference)
SELECT
    translation as version,
    book,
    chapter,
    verse_number as verse,
    COALESCE(spanish_text, spanish_text_original, clean_text) as text,
    'es' as language,
    themes,
    NULL as category,
    reference
FROM verses
WHERE translation = 'RVR1909';

-- Step 7: Drop temporary Spanish table
DROP TABLE verses;

-- Step 8: Verify results
SELECT 
    language,
    version,
    COUNT(*) as verse_count,
    MIN(book) as first_book,
    MAX(book) as last_book
FROM bible_verses
GROUP BY language, version;

-- Step 9: Sample verses
SELECT 'ENGLISH GENESIS 1:1' as test;
SELECT version, book, chapter, verse, text 
FROM bible_verses 
WHERE language = 'en' AND book = 'Genesis' AND chapter = 1 AND verse = 1;

SELECT 'SPANISH GENESIS 1:1' as test;
SELECT version, book, chapter, verse, text 
FROM bible_verses 
WHERE language = 'es' AND book = 'Génesis' AND chapter = 1 AND verse = 1;

SELECT 'ENGLISH REVELATION 22:21' as test;
SELECT version, book, chapter, verse, text 
FROM bible_verses 
WHERE language = 'en' AND book = 'Revelation' AND chapter = 22 AND verse = 21;

SELECT 'SPANISH REVELATION 22:21' as test;
SELECT version, book, chapter, verse, text 
FROM bible_verses 
WHERE language = 'es' AND book = 'Apocalipsis' AND chapter = 22 AND verse = 21;
