import '../core/database/database_helper.dart';
import '../models/bible_verse.dart';

/// Service for fetching Bible chapters and verses from bible_verses table
class BibleChapterService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Get all verses for a specific book and chapter
  Future<List<BibleVerse>> getChapterVerses(
    String book,
    int chapter, {
    String version = 'WEB',
    String language = 'en',
  }) async {
    final database = await _db.database;

    final results = await database.query(
      'bible_verses',
      where: 'book = ? AND chapter = ? AND version = ? AND language = ?',
      whereArgs: [book, chapter, version, language],
      orderBy: 'verse ASC',
    );

    return results.map((map) {
      // Map bible_verses columns to BibleVerse expected columns
      return BibleVerse.fromMap({
        'id': map['id'],
        'book': map['book'],
        'chapter': map['chapter'],
        'verse_number': map['verse'], // Map 'verse' to 'verse_number'
        'text': map['text'],
        'translation': map['version'],
      });
    }).toList();
  }

  /// Get verses for a range of chapters
  Future<Map<int, List<BibleVerse>>> getChapterRange(
    String book,
    int startChapter,
    int endChapter, {
    String version = 'WEB',
    String language = 'en',
  }) async {
    final database = await _db.database;

    final results = await database.query(
      'bible_verses',
      where: 'book = ? AND chapter >= ? AND chapter <= ? AND version = ? AND language = ?',
      whereArgs: [book, startChapter, endChapter, version, language],
      orderBy: 'chapter ASC, verse ASC',
    );

    // Group verses by chapter
    final Map<int, List<BibleVerse>> chapterMap = {};
    for (final map in results) {
      final chapterNum = map['chapter'] as int;

      // Map bible_verses columns to BibleVerse expected columns
      final verse = BibleVerse.fromMap({
        'id': map['id'],
        'book': map['book'],
        'chapter': map['chapter'],
        'verse_number': map['verse'], // Map 'verse' to 'verse_number'
        'text': map['text'],
        'translation': map['version'],
      });

      if (!chapterMap.containsKey(chapterNum)) {
        chapterMap[chapterNum] = [];
      }
      chapterMap[chapterNum]!.add(verse);
    }

    return chapterMap;
  }

  /// Get the total number of chapters in a book
  Future<int> getChapterCount(
    String book, {
    String version = 'WEB',
    String language = 'en',
  }) async {
    final database = await _db.database;

    final results = await database.rawQuery('''
      SELECT MAX(chapter) as max_chapter
      FROM bible_verses
      WHERE book = ? AND version = ? AND language = ?
    ''', [book, version, language]);

    if (results.isEmpty) return 0;
    return (results.first['max_chapter'] as int?) ?? 0;
  }

  /// Get all available books
  Future<List<String>> getAllBooks({
    String version = 'WEB',
    String language = 'en',
  }) async {
    final database = await _db.database;

    final results = await database.rawQuery('''
      SELECT DISTINCT book
      FROM bible_verses
      WHERE version = ? AND language = ?
      ORDER BY
        CASE book
          WHEN 'Genesis' THEN 1 WHEN 'Génesis' THEN 1
          WHEN 'Exodus' THEN 2 WHEN 'Éxodo' THEN 2
          WHEN 'Leviticus' THEN 3 WHEN 'Levítico' THEN 3
          WHEN 'Numbers' THEN 4 WHEN 'Números' THEN 4
          WHEN 'Deuteronomy' THEN 5 WHEN 'Deuteronomio' THEN 5
          WHEN 'Joshua' THEN 6 WHEN 'Josué' THEN 6
          WHEN 'Judges' THEN 7 WHEN 'Jueces' THEN 7
          WHEN 'Ruth' THEN 8 WHEN 'Rut' THEN 8
          WHEN '1 Samuel' THEN 9
          WHEN '2 Samuel' THEN 10
          WHEN '1 Kings' THEN 11 WHEN '1 Reyes' THEN 11
          WHEN '2 Kings' THEN 12 WHEN '2 Reyes' THEN 12
          WHEN '1 Chronicles' THEN 13 WHEN '1 Crónicas' THEN 13
          WHEN '2 Chronicles' THEN 14 WHEN '2 Crónicas' THEN 14
          WHEN 'Ezra' THEN 15 WHEN 'Esdras' THEN 15
          WHEN 'Nehemiah' THEN 16 WHEN 'Nehemías' THEN 16
          WHEN 'Esther' THEN 17 WHEN 'Ester' THEN 17
          WHEN 'Job' THEN 18
          WHEN 'Psalms' THEN 19 WHEN 'Salmos' THEN 19
          WHEN 'Proverbs' THEN 20 WHEN 'Proverbios' THEN 20
          WHEN 'Ecclesiastes' THEN 21 WHEN 'Eclesiastés' THEN 21
          WHEN 'Song of Solomon' THEN 22 WHEN 'Cantares' THEN 22
          WHEN 'Isaiah' THEN 23 WHEN 'Isaías' THEN 23
          WHEN 'Jeremiah' THEN 24 WHEN 'Jeremías' THEN 24
          WHEN 'Lamentations' THEN 25 WHEN 'Lamentaciones' THEN 25
          WHEN 'Ezekiel' THEN 26 WHEN 'Ezequiel' THEN 26
          WHEN 'Daniel' THEN 27
          WHEN 'Hosea' THEN 28 WHEN 'Oseas' THEN 28
          WHEN 'Joel' THEN 29
          WHEN 'Amos' THEN 30 WHEN 'Amós' THEN 30
          WHEN 'Obadiah' THEN 31 WHEN 'Abdías' THEN 31
          WHEN 'Jonah' THEN 32 WHEN 'Jonás' THEN 32
          WHEN 'Micah' THEN 33 WHEN 'Miqueas' THEN 33
          WHEN 'Nahum' THEN 34 WHEN 'Nahúm' THEN 34
          WHEN 'Habakkuk' THEN 35 WHEN 'Habacuc' THEN 35
          WHEN 'Zephaniah' THEN 36 WHEN 'Sofonías' THEN 36
          WHEN 'Haggai' THEN 37 WHEN 'Hageo' THEN 37
          WHEN 'Zechariah' THEN 38 WHEN 'Zacarías' THEN 38
          WHEN 'Malachi' THEN 39 WHEN 'Malaquías' THEN 39
          WHEN 'Matthew' THEN 40 WHEN 'Mateo' THEN 40
          WHEN 'Mark' THEN 41 WHEN 'Marcos' THEN 41
          WHEN 'Luke' THEN 42 WHEN 'Lucas' THEN 42
          WHEN 'John' THEN 43 WHEN 'Juan' THEN 43
          WHEN 'Acts' THEN 44 WHEN 'Hechos' THEN 44
          WHEN 'Romans' THEN 45 WHEN 'Romanos' THEN 45
          WHEN '1 Corinthians' THEN 46 WHEN '1 Corintios' THEN 46
          WHEN '2 Corinthians' THEN 47 WHEN '2 Corintios' THEN 47
          WHEN 'Galatians' THEN 48 WHEN 'Gálatas' THEN 48
          WHEN 'Ephesians' THEN 49 WHEN 'Efesios' THEN 49
          WHEN 'Philippians' THEN 50 WHEN 'Filipenses' THEN 50
          WHEN 'Colossians' THEN 51 WHEN 'Colosenses' THEN 51
          WHEN '1 Thessalonians' THEN 52 WHEN '1 Tesalonicenses' THEN 52
          WHEN '2 Thessalonians' THEN 53 WHEN '2 Tesalonicenses' THEN 53
          WHEN '1 Timothy' THEN 54 WHEN '1 Timoteo' THEN 54
          WHEN '2 Timothy' THEN 55 WHEN '2 Timoteo' THEN 55
          WHEN 'Titus' THEN 56 WHEN 'Tito' THEN 56
          WHEN 'Philemon' THEN 57 WHEN 'Filemón' THEN 57
          WHEN 'Hebrews' THEN 58 WHEN 'Hebreos' THEN 58
          WHEN 'James' THEN 59 WHEN 'Santiago' THEN 59
          WHEN '1 Peter' THEN 60 WHEN '1 Pedro' THEN 60
          WHEN '2 Peter' THEN 61 WHEN '2 Pedro' THEN 61
          WHEN '1 John' THEN 62 WHEN '1 Juan' THEN 62
          WHEN '2 John' THEN 63 WHEN '2 Juan' THEN 63
          WHEN '3 John' THEN 64 WHEN '3 Juan' THEN 64
          WHEN 'Jude' THEN 65 WHEN 'Judas' THEN 65
          WHEN 'Revelation' THEN 66 WHEN 'Apocalipsis' THEN 66
          ELSE 999
        END
    ''', [version, language]);

    return results.map((row) => row['book'] as String).toList();
  }

  /// Check if a chapter exists
  Future<bool> chapterExists(
    String book,
    int chapter, {
    String version = 'WEB',
    String language = 'en',
  }) async {
    final database = await _db.database;

    final results = await database.query(
      'bible_verses',
      where: 'book = ? AND chapter = ? AND version = ? AND language = ?',
      whereArgs: [book, chapter, version, language],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  /// Mark a daily reading as complete
  Future<void> markReadingComplete(String readingId) async {
    final database = await _db.database;

    await database.update(
      'daily_readings',
      {'is_completed': 1, 'completed_date': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [readingId],
    );

    // Update the reading plan's completed_readings count
    await database.rawUpdate('''
      UPDATE reading_plans
      SET completed_readings = (
        SELECT COUNT(*) FROM daily_readings
        WHERE plan_id = (SELECT plan_id FROM daily_readings WHERE id = ?)
        AND is_completed = 1
      )
      WHERE id = (SELECT plan_id FROM daily_readings WHERE id = ?)
    ''', [readingId, readingId]);
  }

  /// Check if a reading is completed
  Future<bool> isReadingComplete(String readingId) async {
    final database = await _db.database;

    final results = await database.query(
      'daily_readings',
      where: 'id = ? AND is_completed = 1',
      whereArgs: [readingId],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  /// Search verses by content using Full-Text Search
  Future<List<BibleVerse>> searchVerses(
    String query, {
    String version = 'WEB',
    String language = 'en',
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) return [];

    final database = await _db.database;

    // Use FTS5 MATCH for full-text search
    final results = await database.rawQuery('''
      SELECT bv.id, bv.book, bv.chapter, bv.verse, bv.text, bv.version,
             bv.reference, bv.themes, bv.category
      FROM bible_verses_fts fts
      JOIN bible_verses bv ON fts.rowid = bv.id
      WHERE fts.bible_verses_fts MATCH ?
        AND bv.version = ?
        AND bv.language = ?
      ORDER BY bv.book, bv.chapter, bv.verse
      LIMIT ?
    ''', [query, version, language, limit]);

    return results.map((map) {
      return BibleVerse.fromMap({
        'id': map['id'],
        'book': map['book'],
        'chapter': map['chapter'],
        'verse_number': map['verse'],
        'text': map['text'],
        'translation': map['version'],
        'reference': map['reference'],
        'themes': map['themes'],
        'category': map['category'],
      });
    }).toList();
  }

  /// Get specific verse(s) by reference (e.g., John 3:16 or Gen 1:1-3)
  Future<List<BibleVerse>> getVersesByReference(
    String book,
    int chapter,
    int startVerse, {
    int? endVerse,
    String version = 'WEB',
    String language = 'en',
  }) async {
    final database = await _db.database;

    String whereClause = 'book = ? AND chapter = ? AND verse >= ? AND version = ? AND language = ?';
    List<dynamic> whereArgs = [book, chapter, startVerse, version, language];

    if (endVerse != null) {
      whereClause += ' AND verse <= ?';
      whereArgs.insert(3, endVerse);
    } else {
      // Single verse lookup
      whereClause = 'book = ? AND chapter = ? AND verse = ? AND version = ? AND language = ?';
      whereArgs[2] = startVerse;
    }

    final results = await database.query(
      'bible_verses',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'verse ASC',
    );

    return results.map((map) {
      return BibleVerse.fromMap({
        'id': map['id'],
        'book': map['book'],
        'chapter': map['chapter'],
        'verse_number': map['verse'],
        'text': map['text'],
        'translation': map['version'],
        'reference': map['reference'],
        'themes': map['themes'],
        'category': map['category'],
      });
    }).toList();
  }
}
