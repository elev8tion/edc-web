import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/reading_plan.dart';
import 'database_service.dart';
import 'book_name_service.dart';

/// Service for generating daily readings for reading plans based on actual Bible data
class ReadingPlanGenerator {
  final DatabaseService _database;
  final _uuid = const Uuid();
  String _language = 'en'; // Default language

  ReadingPlanGenerator(this._database);

  /// Set the language for generated content
  void setLanguage(String language) {
    _language = language;
  }

  /// Bible book metadata with chapter counts
  static const Map<String, Map<String, dynamic>> bibleBooks = {
    // Old Testament
    'Genesis': {'chapters': 50, 'testament': 'OT', 'category': 'pentateuch'},
    'Exodus': {'chapters': 40, 'testament': 'OT', 'category': 'pentateuch'},
    'Leviticus': {'chapters': 27, 'testament': 'OT', 'category': 'pentateuch'},
    'Numbers': {'chapters': 36, 'testament': 'OT', 'category': 'pentateuch'},
    'Deuteronomy': {'chapters': 34, 'testament': 'OT', 'category': 'pentateuch'},
    'Joshua': {'chapters': 24, 'testament': 'OT', 'category': 'history'},
    'Judges': {'chapters': 21, 'testament': 'OT', 'category': 'history'},
    'Ruth': {'chapters': 4, 'testament': 'OT', 'category': 'history'},
    '1 Samuel': {'chapters': 31, 'testament': 'OT', 'category': 'history'},
    '2 Samuel': {'chapters': 24, 'testament': 'OT', 'category': 'history'},
    '1 Kings': {'chapters': 22, 'testament': 'OT', 'category': 'history'},
    '2 Kings': {'chapters': 25, 'testament': 'OT', 'category': 'history'},
    '1 Chronicles': {'chapters': 29, 'testament': 'OT', 'category': 'history'},
    '2 Chronicles': {'chapters': 36, 'testament': 'OT', 'category': 'history'},
    'Ezra': {'chapters': 10, 'testament': 'OT', 'category': 'history'},
    'Nehemiah': {'chapters': 13, 'testament': 'OT', 'category': 'history'},
    'Esther': {'chapters': 10, 'testament': 'OT', 'category': 'history'},
    'Job': {'chapters': 42, 'testament': 'OT', 'category': 'wisdom'},
    'Psalm': {'chapters': 150, 'testament': 'OT', 'category': 'wisdom'},
    'Proverbs': {'chapters': 31, 'testament': 'OT', 'category': 'wisdom'},
    'Ecclesiastes': {'chapters': 12, 'testament': 'OT', 'category': 'wisdom'},
    'Song of Solomon': {'chapters': 8, 'testament': 'OT', 'category': 'wisdom'},
    'Isaiah': {'chapters': 66, 'testament': 'OT', 'category': 'prophecy'},
    'Jeremiah': {'chapters': 52, 'testament': 'OT', 'category': 'prophecy'},
    'Lamentations': {'chapters': 5, 'testament': 'OT', 'category': 'prophecy'},
    'Ezekiel': {'chapters': 48, 'testament': 'OT', 'category': 'prophecy'},
    'Daniel': {'chapters': 12, 'testament': 'OT', 'category': 'prophecy'},
    'Hosea': {'chapters': 14, 'testament': 'OT', 'category': 'prophecy'},
    'Joel': {'chapters': 3, 'testament': 'OT', 'category': 'prophecy'},
    'Amos': {'chapters': 9, 'testament': 'OT', 'category': 'prophecy'},
    'Obadiah': {'chapters': 1, 'testament': 'OT', 'category': 'prophecy'},
    'Jonah': {'chapters': 4, 'testament': 'OT', 'category': 'prophecy'},
    'Micah': {'chapters': 7, 'testament': 'OT', 'category': 'prophecy'},
    'Nahum': {'chapters': 3, 'testament': 'OT', 'category': 'prophecy'},
    'Habakkuk': {'chapters': 3, 'testament': 'OT', 'category': 'prophecy'},
    'Zephaniah': {'chapters': 3, 'testament': 'OT', 'category': 'prophecy'},
    'Haggai': {'chapters': 2, 'testament': 'OT', 'category': 'prophecy'},
    'Zechariah': {'chapters': 14, 'testament': 'OT', 'category': 'prophecy'},
    'Malachi': {'chapters': 4, 'testament': 'OT', 'category': 'prophecy'},
    // New Testament
    'Matthew': {'chapters': 28, 'testament': 'NT', 'category': 'gospel'},
    'Mark': {'chapters': 16, 'testament': 'NT', 'category': 'gospel'},
    'Luke': {'chapters': 24, 'testament': 'NT', 'category': 'gospel'},
    'John': {'chapters': 21, 'testament': 'NT', 'category': 'gospel'},
    'Acts': {'chapters': 28, 'testament': 'NT', 'category': 'history'},
    'Romans': {'chapters': 16, 'testament': 'NT', 'category': 'epistle'},
    '1 Corinthians': {'chapters': 16, 'testament': 'NT', 'category': 'epistle'},
    '2 Corinthians': {'chapters': 13, 'testament': 'NT', 'category': 'epistle'},
    'Galatians': {'chapters': 6, 'testament': 'NT', 'category': 'epistle'},
    'Ephesians': {'chapters': 6, 'testament': 'NT', 'category': 'epistle'},
    'Philippians': {'chapters': 4, 'testament': 'NT', 'category': 'epistle'},
    'Colossians': {'chapters': 4, 'testament': 'NT', 'category': 'epistle'},
    '1 Thessalonians': {'chapters': 5, 'testament': 'NT', 'category': 'epistle'},
    '2 Thessalonians': {'chapters': 3, 'testament': 'NT', 'category': 'epistle'},
    '1 Timothy': {'chapters': 6, 'testament': 'NT', 'category': 'epistle'},
    '2 Timothy': {'chapters': 4, 'testament': 'NT', 'category': 'epistle'},
    'Titus': {'chapters': 3, 'testament': 'NT', 'category': 'epistle'},
    'Philemon': {'chapters': 1, 'testament': 'NT', 'category': 'epistle'},
    'Hebrews': {'chapters': 13, 'testament': 'NT', 'category': 'epistle'},
    'James': {'chapters': 5, 'testament': 'NT', 'category': 'epistle'},
    '1 Peter': {'chapters': 5, 'testament': 'NT', 'category': 'epistle'},
    '2 Peter': {'chapters': 3, 'testament': 'NT', 'category': 'epistle'},
    '1 John': {'chapters': 5, 'testament': 'NT', 'category': 'epistle'},
    '2 John': {'chapters': 1, 'testament': 'NT', 'category': 'epistle'},
    '3 John': {'chapters': 1, 'testament': 'NT', 'category': 'epistle'},
    'Jude': {'chapters': 1, 'testament': 'NT', 'category': 'epistle'},
    'Revelation': {'chapters': 22, 'testament': 'NT', 'category': 'prophecy'},
  };

  /// Generate readings for a specific plan based on its category
  Future<void> generateReadingsForPlan(String planId, PlanCategory category, int totalDays, {String language = 'en'}) async {
    try {
      // Set the language for this generation
      setLanguage(language);

      final db = await _database.database;

      // Get books based on plan category
      final books = _getBooksForCategory(category);

      // Generate daily readings
      final readings = await _generateDailyReadings(planId, books, totalDays);

      // Insert into database
      for (final reading in readings) {
        await db.insert('daily_readings', reading);
      }
    } catch (e) {
      throw Exception('Failed to generate readings for plan: $e');
    }
  }

  /// Get list of books for a specific plan category
  List<String> _getBooksForCategory(PlanCategory category) {
    switch (category) {
      case PlanCategory.newTestament:
        return bibleBooks.entries
            .where((e) => e.value['testament'] == 'NT')
            .map((e) => e.key)
            .toList();

      case PlanCategory.oldTestament:
        return bibleBooks.entries
            .where((e) => e.value['testament'] == 'OT')
            .map((e) => e.key)
            .toList();

      case PlanCategory.gospels:
        return bibleBooks.entries
            .where((e) => e.value['category'] == 'gospel')
            .map((e) => e.key)
            .toList();

      case PlanCategory.epistles:
        return bibleBooks.entries
            .where((e) => e.value['category'] == 'epistle')
            .map((e) => e.key)
            .toList();

      case PlanCategory.psalms:
        return ['Psalm'];

      case PlanCategory.proverbs:
        return ['Proverbs'];

      case PlanCategory.wisdom:
        return bibleBooks.entries
            .where((e) => e.value['category'] == 'wisdom')
            .map((e) => e.key)
            .toList();

      case PlanCategory.prophecy:
        return bibleBooks.entries
            .where((e) => e.value['category'] == 'prophecy')
            .map((e) => e.key)
            .toList();

      case PlanCategory.completeBible:
        return bibleBooks.keys.toList();
    }
  }

  /// Generate daily reading schedule
  Future<List<Map<String, dynamic>>> _generateDailyReadings(
    String planId,
    List<String> books,
    int totalDays,
  ) async {
    final readings = <Map<String, dynamic>>[];
    final startDate = DateTime.now();

    // Calculate total chapters to read
    int totalChapters = 0;
    for (final book in books) {
      totalChapters += bibleBooks[book]!['chapters'] as int;
    }

    // Calculate chapters per day
    final chaptersPerDay = (totalChapters / totalDays).ceil();

    // Generate readings
    int currentDay = 0;
    int currentBookIndex = 0;
    int currentChapter = 1;

    while (currentDay < totalDays && currentBookIndex < books.length) {
      final book = books[currentBookIndex];
      final maxChapter = bibleBooks[book]!['chapters'] as int;

      // Calculate end chapter for this reading
      int endChapter = currentChapter + chaptersPerDay - 1;
      if (endChapter > maxChapter) {
        endChapter = maxChapter;
      }

      // Create reading entry
      final chapterRange = currentChapter == endChapter
          ? '$currentChapter'
          : '$currentChapter-$endChapter';

      // Get localized book name for title
      final localizedBook = BookNameService.getBookName(book, _language);

      readings.add({
        'id': _uuid.v4(),
        'plan_id': planId,
        'title': '$localizedBook $chapterRange',
        'description': await _getReadingDescription(book, currentChapter, endChapter),
        'book': book,
        'chapters': chapterRange,
        'estimated_time': _estimateReadingTime(currentChapter, endChapter),
        'date': startDate.add(Duration(days: currentDay)).millisecondsSinceEpoch,
        'is_completed': 0,
        'completed_date': null,
      });

      currentDay++;

      // Move to next chapter or book
      if (endChapter >= maxChapter) {
        currentBookIndex++;
        currentChapter = 1;
      } else {
        currentChapter = endChapter + 1;
      }
    }

    return readings;
  }

  /// Get description for a reading based on its content
  Future<String> _getReadingDescription(String book, int startChapter, int endChapter) async {
    // Get localized book name
    final localizedBook = BookNameService.getBookName(book, _language);

    // Generate descriptions based on book and chapter ranges
    if (_language == 'es') {
      // Spanish descriptions
      if (startChapter == 1) {
        return 'Comienzo de $localizedBook';
      } else if (startChapter == endChapter) {
        return '$localizedBook capítulo $startChapter';
      } else {
        return '$localizedBook capítulos $startChapter-$endChapter';
      }
    } else {
      // English descriptions (default)
      if (startChapter == 1) {
        return 'Beginning of $localizedBook';
      } else if (startChapter == endChapter) {
        return '$localizedBook chapter $startChapter';
      } else {
        return '$localizedBook chapters $startChapter-$endChapter';
      }
    }
  }

  /// Estimate reading time based on chapter count
  String _estimateReadingTime(int startChapter, int endChapter) {
    final chapters = endChapter - startChapter + 1;
    final minutes = chapters * 4; // Roughly 4 minutes per chapter

    if (minutes < 10) {
      return '5-10 min';
    } else if (minutes < 20) {
      return '10-15 min';
    } else if (minutes < 30) {
      return '15-20 min';
    } else if (minutes < 40) {
      return '20-30 min';
    } else {
      return '30+ min';
    }
  }

  /// Verify that books exist in the database
  Future<bool> verifyBooksExist(List<String> books, {String version = 'WEB'}) async {
    final db = await _database.database;

    for (final book in books) {
      final result = await db.query(
        'bible_verses',
        where: 'book = ? AND version = ?',
        whereArgs: [book, version],
        limit: 1,
      );

      if (result.isEmpty) {
        debugPrint('⚠️  Book not found in database: $book');
        return false;
      }
    }

    return true;
  }
}
