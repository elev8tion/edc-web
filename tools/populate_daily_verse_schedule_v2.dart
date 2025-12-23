import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

/// Script to populate daily_verse_schedule table from verse_of_the_day_list.csv (new format)
/// Run with: dart run tools/populate_daily_verse_schedule_v2.dart
void main() async {
  print('🔄 Starting daily verse schedule population (v2)...\n');

  // Initialize FFI for desktop SQLite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Read the CSV file
  final csvFile = File('verse_of_the_day_list.csv');
  if (!await csvFile.exists()) {
    print('❌ Error: verse_of_the_day_list.csv not found');
    exit(1);
  }

  final csvContent = await csvFile.readAsString();
  final lines = csvContent.split('\n');

  // Open the assets/bible.db database
  final dbPath = path.join(
    Directory.current.path,
    'assets',
    'bible.db',
  );

  if (!await File(dbPath).exists()) {
    print('❌ Error: assets/bible.db not found');
    exit(1);
  }

  print('📂 Using database: $dbPath\n');

  final db = await openDatabase(dbPath);

  // Create daily_verse_schedule table if it doesn't exist
  await db.execute('''
    CREATE TABLE IF NOT EXISTS daily_verse_schedule (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      month INTEGER NOT NULL,
      day INTEGER NOT NULL,
      verse_id INTEGER NOT NULL,
      FOREIGN KEY (verse_id) REFERENCES verses (id),
      UNIQUE(month, day)
    )
  ''');

  await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_verse_schedule_date ON daily_verse_schedule(month, day)');

  // Clear existing schedule
  await db.delete('daily_verse_schedule');
  print('🗑️  Cleared existing schedule\n');

  // Month name to number mapping
  final monthMap = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  int totalInserted = 0;
  int totalMissing = 0;

  // Track current months (left and right columns)
  int? currentLeftMonth;
  int? currentRightMonth;

  // Skip header row
  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;

    // Parse CSV line - format: Month,Day,Theme,VerseRef,Month,Day,Theme,VerseRef
    final parts = _parseCSVLine(lines[i]);
    if (parts.length < 4) continue;

    // Process left side (Jan-Jun)
    // Update current left month if specified
    if (parts[0].isNotEmpty) {
      final monthName = parts[0].trim();
      currentLeftMonth = monthMap[monthName];
    }

    if (currentLeftMonth != null && parts[1].trim().isNotEmpty) {
      final day = int.tryParse(parts[1].trim());
      final verseRef = parts[3].trim();

      if (day != null && verseRef.isNotEmpty) {
        final verseId = await _findVerseId(db, verseRef);
        if (verseId != null) {
          await db.insert('daily_verse_schedule', {
            'month': currentLeftMonth,
            'day': day,
            'verse_id': verseId,
          });
          totalInserted++;
        } else {
          print('⚠️  Missing: Month $currentLeftMonth Day $day - $verseRef');
          totalMissing++;
        }
      }
    }

    // Process right side (Jul-Dec)
    if (parts.length >= 8) {
      // Update current right month if specified
      if (parts[4].trim().isNotEmpty) {
        final monthName = parts[4].trim();
        currentRightMonth = monthMap[monthName];
      }

      if (currentRightMonth != null && parts[5].trim().isNotEmpty) {
        final day = int.tryParse(parts[5].trim());
        final verseRef = parts[7].trim();

        if (day != null && verseRef.isNotEmpty) {
          final verseId = await _findVerseId(db, verseRef);
          if (verseId != null) {
            await db.insert('daily_verse_schedule', {
              'month': currentRightMonth,
              'day': day,
              'verse_id': verseId,
            });
            totalInserted++;
          } else {
            print('⚠️  Missing: Month $currentRightMonth Day $day - $verseRef');
            totalMissing++;
          }
        }
      }
    }
  }

  await db.close();

  print('\n✅ Daily verse schedule populated!');
  print('📊 Stats:');
  print('   Total inserted: $totalInserted');
  print('   Missing verses: $totalMissing');
  if (totalInserted + totalMissing > 0) {
    print('   Success rate: ${(totalInserted / (totalInserted + totalMissing) * 100).toStringAsFixed(1)}%');
  }
}

/// Parse a CSV line respecting quoted fields
List<String> _parseCSVLine(String line) {
  final List<String> fields = [];
  StringBuffer currentField = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      inQuotes = !inQuotes;
    } else if (char == ',' && !inQuotes) {
      fields.add(currentField.toString());
      currentField.clear();
    } else {
      currentField.write(char);
    }
  }

  // Add the last field
  fields.add(currentField.toString());

  return fields;
}

/// Normalize book names to match database
String _normalizeBookName(String book) {
  final normalizations = {
    'Psalm': 'Psalms',
    'Song of Songs': 'Song of Solomon',
    '1 Thess.': '1 Thessalonians',
    '2 Thess.': '2 Thessalonians',
    '1 Cor.': '1 Corinthians',
    '2 Cor.': '2 Corinthians',
  };

  return normalizations[book] ?? book;
}

/// Find verse_id in verses table by reference string
Future<int?> _findVerseId(Database db, String reference) async {
  try {
    // Parse reference like "John 3:16" or "1 John 4:10" or "Psalm 121:7-8"
    reference = reference.trim();

    // Handle verse ranges like "Psalm 121:7-8" -> just use first verse
    if (reference.contains('-')) {
      final parts = reference.split('-');
      reference = parts[0].trim();
    }

    final refParts = reference.split(' ');
    if (refParts.length < 2) return null;

    String book;
    String chapterVerse;

    // Handle books with numbers (1 John, 2 Corinthians, etc.)
    if (refParts[0].contains(RegExp(r'^\d'))) {
      book = '${refParts[0]} ${refParts[1]}';
      chapterVerse = refParts.length > 2 ? refParts[2] : '';
    } else {
      book = refParts[0];
      chapterVerse = refParts.length > 1 ? refParts[1] : '';
    }

    // Normalize book name
    book = _normalizeBookName(book);

    final cvParts = chapterVerse.split(':');
    if (cvParts.length != 2) return null;

    final chapter = int.tryParse(cvParts[0]);
    final verse = int.tryParse(cvParts[1]);

    if (chapter == null || verse == null) return null;

    // Query the verses table (from bible.db) - using WEB translation
    var results = await db.query(
      'verses',
      columns: ['id'],
      where: 'book = ? AND chapter = ? AND verse_number = ? AND translation = ?',
      whereArgs: [book, chapter, verse, 'WEB'],
      limit: 1,
    );

    // Try case-insensitive if no exact match
    if (results.isEmpty) {
      results = await db.query(
        'verses',
        columns: ['id'],
        where: 'LOWER(book) = ? AND chapter = ? AND verse_number = ? AND translation = ?',
        whereArgs: [book.toLowerCase(), chapter, verse, 'WEB'],
        limit: 1,
      );
    }

    if (results.isEmpty) return null;

    return results.first['id'] as int;
  } catch (e) {
    print('❌ Error parsing "$reference": $e');
    return null;
  }
}
