import 'dart:io';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

/// Script to generate daily_verses.json from verse_of_the_day_list.txt
/// Run with: dart run tools/generate_daily_verses.dart
void main() async {
  print('🔄 Starting daily verses generation...\n');

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

  // Open the Bible database
  final bibleDbPath = path.join(Directory.current.path, 'assets', 'bible.db');
  if (!await File(bibleDbPath).exists()) {
    print('❌ Error: assets/bible.db not found');
    exit(1);
  }

  final db = await openDatabase(bibleDbPath, readOnly: true);

  // Parse CSV and generate JSON
  final Map<String, List<Map<String, dynamic>>> monthlyVerses = {};
  final monthNames = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december'
  ];

  int totalVerses = 0;
  int foundVerses = 0;
  int missingVerses = 0;

  // Skip header row
  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;

    // Simple CSV parsing: split by comma, but respect quotes
    final parts = _parseCSVLine(lines[i]);
    if (parts.length < 5) {
      print('⚠️  Skipping malformed line $i: ${lines[i].substring(0, 50)}...');
      continue;
    }

    final monthName = parts[0].split(' ')[0].toLowerCase();
    final daysInMonth = int.tryParse(parts[0].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    // Extract verses from each category column (columns 1-4)
    final List<String> allVerseRefs = [];
    for (int col = 1; col <= 4; col++) {
      final refsStr = parts[col];
      final refs = refsStr.split(', ');
      allVerseRefs.addAll(refs.map((r) => r.trim()).where((r) => r.isNotEmpty));
    }

    print('📅 Processing $monthName ($daysInMonth days, ${allVerseRefs.length} verses listed)...');

    final monthVerses = <Map<String, dynamic>>[];

    for (final ref in allVerseRefs) {
      totalVerses++;

      final verseData = await _queryVerse(db, ref);
      if (verseData != null) {
        monthVerses.add(verseData);
        foundVerses++;
      } else {
        print('  ⚠️  Missing: $ref');
        missingVerses++;
      }
    }

    print('  ✓ Found ${monthVerses.length} verses for $monthName');
    monthlyVerses[monthName] = monthVerses;
  }

  await db.close();

  // Write JSON file
  final outputFile = File('assets/data/daily_verses.json');
  await outputFile.parent.create(recursive: true);

  final jsonOutput = {
    'metadata': {
      'generated': DateTime.now().toIso8601String(),
      'total_verses': totalVerses,
      'found_verses': foundVerses,
      'missing_verses': missingVerses,
    },
    'verses': monthlyVerses,
  };

  await outputFile.writeAsString(
    JsonEncoder.withIndent('  ').convert(jsonOutput),
  );

  print('\n✅ Generated daily_verses.json');
  print('📊 Stats:');
  print('   Total verses: $totalVerses');
  print('   Found: $foundVerses');
  print('   Missing: $missingVerses');
  print('   Success rate: ${(foundVerses / totalVerses * 100).toStringAsFixed(1)}%');
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
  // Handle common variations
  final normalizations = {
    'Psalm': 'Psalms',
    'Song of Songs': 'Song of Solomon',
  };

  return normalizations[book] ?? book;
}

/// Query a verse from the Bible database
Future<Map<String, dynamic>?> _queryVerse(Database db, String reference) async {
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

    // Query the database (try exact match first, then case-insensitive)
    var results = await db.query(
      'verses',
      where: 'book = ? AND chapter = ? AND verse_number = ? AND translation = ?',
      whereArgs: [book, chapter, verse, 'WEB'],
      limit: 1,
    );

    // Try case-insensitive if no exact match
    if (results.isEmpty) {
      results = await db.query(
        'verses',
        where: 'LOWER(book) = ? AND chapter = ? AND verse_number = ? AND translation = ?',
        whereArgs: [book.toLowerCase(), chapter, verse, 'WEB'],
        limit: 1,
      );
    }

    if (results.isEmpty) return null;

    final row = results.first;
    return {
      'reference': reference,
      'book': row['book'] as String,
      'chapter': chapter,
      'verse': verse,
      'text': row['clean_text'] as String,
    };
  } catch (e) {
    print('  ❌ Error parsing $reference: $e');
    return null;
  }
}
