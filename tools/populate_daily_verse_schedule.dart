import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

/// Script to populate daily_verse_schedule table from verse_of_the_day_list.txt
/// Run with: dart run tools/populate_daily_verse_schedule.dart
void main() async {
  print('🔄 Starting daily verse schedule population...\n');

  // Initialize FFI for desktop SQLite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Read the CSV file
  final csvFile = File('verse_of_the_day_list.txt');
  if (!await csvFile.exists()) {
    print('❌ Error: verse_of_the_day_list.txt not found');
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

  print('✅ Created daily_verse_schedule table in bible.db\n');

  // Month configuration (days per month)
  final monthDays = {
    1: 31,  // January
    2: 29,  // February (leap year max)
    3: 31,  // March
    4: 30,  // April
    5: 31,  // May
    6: 30,  // June
    7: 31,  // July
    8: 31,  // August
    9: 30,  // September
    10: 31, // October
    11: 30, // November
    12: 31, // December
  };

  int totalInserted = 0;
  int totalMissing = 0;

  // Clear existing schedule
  await db.delete('daily_verse_schedule');
  print('🗑️  Cleared existing schedule\n');

  // Skip header row
  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;

    // Parse CSV line
    final parts = _parseCSVLine(lines[i]);
    if (parts.length < 5) {
      print('⚠️  Skipping malformed line $i');
      continue;
    }

    // Extract month number from line number (1-12)
    final monthNumber = i;
    final daysInMonth = monthDays[monthNumber] ?? 31;

    print('📅 Processing Month $monthNumber ($daysInMonth days)...');

    // Extract all verse references from columns 1-4
    final List<String> allVerseRefs = [];
    for (int col = 1; col <= 4; col++) {
      final refsStr = parts[col];
      final refs = refsStr.split(',');
      allVerseRefs.addAll(refs.map((r) => r.trim()).where((r) => r.isNotEmpty));
    }

    print('   Found ${allVerseRefs.length} verses for this month');

    // Check if we have enough verses for this month
    if (allVerseRefs.length < daysInMonth) {
      print('   ⚠️  Warning: Only ${allVerseRefs.length} verses for $daysInMonth days!');
    }

    // Assign verses to days (first N verses for N days)
    for (int day = 1; day <= daysInMonth && day <= allVerseRefs.length; day++) {
      final verseRef = allVerseRefs[day - 1];

      // Query bible_verses for this reference
      final verseId = await _findVerseId(db, verseRef);

      if (verseId != null) {
        await db.insert('daily_verse_schedule', {
          'month': monthNumber,
          'day': day,
          'verse_id': verseId,
        });
        totalInserted++;
      } else {
        print('   ⚠️  Day $day: Missing verse "$verseRef"');
        totalMissing++;
      }
    }

    print('   ✓ Completed Month $monthNumber\n');
  }

  await db.close();

  print('✅ Daily verse schedule populated!');
  print('📊 Stats:');
  print('   Total inserted: $totalInserted');
  print('   Missing verses: $totalMissing');
  print('   Success rate: ${(totalInserted / (totalInserted + totalMissing) * 100).toStringAsFixed(1)}%');
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
  };

  return normalizations[book] ?? book;
}

/// Find verse_id in bible_verses table by reference string
Future<int?> _findVerseId(Database db, String reference) async {
  try {
    // Parse reference like "John 3:16" or "1 John 4:10" or "Song of Solomon 2:4"
    final parts = reference.trim().split(' ');
    if (parts.length < 2) return null;

    String book;
    String chapterVerse;

    // Handle special multi-word books
    if (reference.startsWith('Song of Solomon')) {
      book = 'Song of Solomon';
      final cvMatch = RegExp(r'(\d+):(\d+)').firstMatch(reference);
      if (cvMatch == null) return null;
      chapterVerse = cvMatch.group(0)!;
    }
    // Handle books with numbers (1 John, 2 Corinthians, etc.)
    else if (parts[0].contains(RegExp(r'^\d'))) {
      book = '${parts[0]} ${parts[1]}';
      chapterVerse = parts.length > 2 ? parts[2] : '';
    } else {
      book = parts[0];
      chapterVerse = parts.length > 1 ? parts[1] : '';
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
    print('   ❌ Error parsing "$reference": $e');
    return null;
  }
}
