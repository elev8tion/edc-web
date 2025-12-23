-- Update all book names in kc_edc_spanish_bible.db to Spanish
-- Modern Spanish book naming conventions
-- Run with: sqlite3 assets/kc_edc_spanish_bible.db < assets/update_spanish_book_names.sql

BEGIN TRANSACTION;

-- Old Testament
UPDATE verses SET book = 'Génesis' WHERE book = 'Genesis';
UPDATE verses SET book = 'Éxodo' WHERE book = 'Exodus';
UPDATE verses SET book = 'Levítico' WHERE book = 'Leviticus';
UPDATE verses SET book = 'Números' WHERE book = 'Numbers';
UPDATE verses SET book = 'Deuteronomio' WHERE book = 'Deuteronomy';
UPDATE verses SET book = 'Josué' WHERE book = 'Joshua';
UPDATE verses SET book = 'Jueces' WHERE book = 'Judges';
UPDATE verses SET book = 'Rut' WHERE book = 'Ruth';
-- 1 Samuel and 2 Samuel stay the same
UPDATE verses SET book = '1 Reyes' WHERE book = '1 Kings';
UPDATE verses SET book = '2 Reyes' WHERE book = '2 Kings';
UPDATE verses SET book = '1 Crónicas' WHERE book = '1 Chronicles';
UPDATE verses SET book = '2 Crónicas' WHERE book = '2 Chronicles';
UPDATE verses SET book = 'Esdras' WHERE book = 'Ezra';
UPDATE verses SET book = 'Nehemías' WHERE book = 'Nehemiah';
UPDATE verses SET book = 'Ester' WHERE book = 'Esther';
-- Job stays the same
UPDATE verses SET book = 'Salmos' WHERE book = 'Psalms';
UPDATE verses SET book = 'Proverbios' WHERE book = 'Proverbs';
UPDATE verses SET book = 'Eclesiastés' WHERE book = 'Ecclesiastes';
UPDATE verses SET book = 'Cantares' WHERE book = 'Song of Solomon';
UPDATE verses SET book = 'Isaías' WHERE book = 'Isaiah';
UPDATE verses SET book = 'Jeremías' WHERE book = 'Jeremiah';
UPDATE verses SET book = 'Lamentaciones' WHERE book = 'Lamentations';
UPDATE verses SET book = 'Ezequiel' WHERE book = 'Ezekiel';
-- Daniel stays the same
UPDATE verses SET book = 'Oseas' WHERE book = 'Hosea';
-- Joel stays the same
UPDATE verses SET book = 'Amós' WHERE book = 'Amos';
UPDATE verses SET book = 'Abdías' WHERE book = 'Obadiah';
UPDATE verses SET book = 'Jonás' WHERE book = 'Jonah';
UPDATE verses SET book = 'Miqueas' WHERE book = 'Micah';
UPDATE verses SET book = 'Nahúm' WHERE book = 'Nahum';
UPDATE verses SET book = 'Habacuc' WHERE book = 'Habakkuk';
UPDATE verses SET book = 'Sofonías' WHERE book = 'Zephaniah';
UPDATE verses SET book = 'Hageo' WHERE book = 'Haggai';
UPDATE verses SET book = 'Zacarías' WHERE book = 'Zechariah';
UPDATE verses SET book = 'Malaquías' WHERE book = 'Malachi';

-- New Testament
UPDATE verses SET book = 'Mateo' WHERE book = 'Matthew';
UPDATE verses SET book = 'Marcos' WHERE book = 'Mark';
UPDATE verses SET book = 'Lucas' WHERE book = 'Luke';
UPDATE verses SET book = 'Juan' WHERE book = 'John';
UPDATE verses SET book = 'Hechos' WHERE book = 'Acts';
UPDATE verses SET book = 'Romanos' WHERE book = 'Romans';
UPDATE verses SET book = '1 Corintios' WHERE book = '1 Corinthians';
UPDATE verses SET book = '2 Corintios' WHERE book = '2 Corinthians';
UPDATE verses SET book = 'Gálatas' WHERE book = 'Galatians';
UPDATE verses SET book = 'Efesios' WHERE book = 'Ephesians';
UPDATE verses SET book = 'Filipenses' WHERE book = 'Philippians';
UPDATE verses SET book = 'Colosenses' WHERE book = 'Colossians';
UPDATE verses SET book = '1 Tesalonicenses' WHERE book = '1 Thessalonians';
UPDATE verses SET book = '2 Tesalonicenses' WHERE book = '2 Thessalonians';
UPDATE verses SET book = '1 Timoteo' WHERE book = '1 Timothy';
UPDATE verses SET book = '2 Timoteo' WHERE book = '2 Timothy';
UPDATE verses SET book = 'Tito' WHERE book = 'Titus';
UPDATE verses SET book = 'Filemón' WHERE book = 'Philemon';
UPDATE verses SET book = 'Hebreos' WHERE book = 'Hebrews';
UPDATE verses SET book = 'Santiago' WHERE book = 'James';
UPDATE verses SET book = '1 Pedro' WHERE book = '1 Peter';
UPDATE verses SET book = '2 Pedro' WHERE book = '2 Peter';
UPDATE verses SET book = '1 Juan' WHERE book = '1 John';
UPDATE verses SET book = '2 Juan' WHERE book = '2 John';
UPDATE verses SET book = '3 Juan' WHERE book = '3 John';
UPDATE verses SET book = 'Judas' WHERE book = 'Jude';
UPDATE verses SET book = 'Apocalipsis' WHERE book = 'Revelation';

-- Update metadata to reflect this change
UPDATE translation_metadata
SET value = '2025-11-09',
    last_updated = datetime('now')
WHERE key = 'book_names_updated';

INSERT OR REPLACE INTO translation_metadata (key, value, last_updated)
VALUES ('book_names_language', 'Spanish', datetime('now'));

INSERT OR REPLACE INTO translation_metadata (key, value, last_updated)
VALUES ('version', '1.4.0', datetime('now'));

INSERT OR REPLACE INTO translation_metadata (key, value, last_updated)
VALUES ('version_1.4.0_changes', 'Converted all 66 book names to Spanish', datetime('now'));

COMMIT;

-- Verify the changes
SELECT 'Book names updated successfully. Current book list:' as message;
SELECT DISTINCT book FROM verses ORDER BY book;
