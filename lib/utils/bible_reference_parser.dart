/// Utility class for parsing Bible references like "John 3:16" or "Gen 1:1-3"
class BibleReferenceParser {
  // Book abbreviations map
  static const Map<String, String> bookAbbreviations = {
    // Old Testament
    'gen': 'Genesis',
    'genesis': 'Genesis',
    'exo': 'Exodus',
    'exodus': 'Exodus',
    'lev': 'Leviticus',
    'leviticus': 'Leviticus',
    'num': 'Numbers',
    'numbers': 'Numbers',
    'deut': 'Deuteronomy',
    'deuteronomy': 'Deuteronomy',
    'josh': 'Joshua',
    'joshua': 'Joshua',
    'judg': 'Judges',
    'judges': 'Judges',
    'ruth': 'Ruth',
    '1sam': '1 Samuel',
    '1 samuel': '1 Samuel',
    '2sam': '2 Samuel',
    '2 samuel': '2 Samuel',
    '1king': '1 Kings',
    '1 kings': '1 Kings',
    '2king': '2 Kings',
    '2 kings': '2 Kings',
    '1chr': '1 Chronicles',
    '1 chronicles': '1 Chronicles',
    '2chr': '2 Chronicles',
    '2 chronicles': '2 Chronicles',
    'ezra': 'Ezra',
    'neh': 'Nehemiah',
    'nehemiah': 'Nehemiah',
    'esth': 'Esther',
    'esther': 'Esther',
    'job': 'Job',
    'ps': 'Psalms',
    'psalm': 'Psalms',
    'psalms': 'Psalms',
    'prov': 'Proverbs',
    'proverbs': 'Proverbs',
    'eccl': 'Ecclesiastes',
    'ecclesiastes': 'Ecclesiastes',
    'song': 'Song of Solomon',
    'isa': 'Isaiah',
    'isaiah': 'Isaiah',
    'jer': 'Jeremiah',
    'jeremiah': 'Jeremiah',
    'lam': 'Lamentations',
    'lamentations': 'Lamentations',
    'ezek': 'Ezekiel',
    'ezekiel': 'Ezekiel',
    'dan': 'Daniel',
    'daniel': 'Daniel',
    'hos': 'Hosea',
    'hosea': 'Hosea',
    'joel': 'Joel',
    'amos': 'Amos',
    'obad': 'Obadiah',
    'obadiah': 'Obadiah',
    'jonah': 'Jonah',
    'mic': 'Micah',
    'micah': 'Micah',
    'nah': 'Nahum',
    'nahum': 'Nahum',
    'hab': 'Habakkuk',
    'habakkuk': 'Habakkuk',
    'zeph': 'Zephaniah',
    'zephaniah': 'Zephaniah',
    'hag': 'Haggai',
    'haggai': 'Haggai',
    'zech': 'Zechariah',
    'zechariah': 'Zechariah',
    'mal': 'Malachi',
    'malachi': 'Malachi',

    // New Testament
    'matt': 'Matthew',
    'matthew': 'Matthew',
    'mark': 'Mark',
    'luke': 'Luke',
    'john': 'John',
    'acts': 'Acts',
    'rom': 'Romans',
    'romans': 'Romans',
    '1cor': '1 Corinthians',
    '1 corinthians': '1 Corinthians',
    '2cor': '2 Corinthians',
    '2 corinthians': '2 Corinthians',
    'gal': 'Galatians',
    'galatians': 'Galatians',
    'eph': 'Ephesians',
    'ephesians': 'Ephesians',
    'phil': 'Philippians',
    'philippians': 'Philippians',
    'col': 'Colossians',
    'colossians': 'Colossians',
    '1thess': '1 Thessalonians',
    '1 thessalonians': '1 Thessalonians',
    '2thess': '2 Thessalonians',
    '2 thessalonians': '2 Thessalonians',
    '1tim': '1 Timothy',
    '1 timothy': '1 Timothy',
    '2tim': '2 Timothy',
    '2 timothy': '2 Timothy',
    'titus': 'Titus',
    'philem': 'Philemon',
    'philemon': 'Philemon',
    'heb': 'Hebrews',
    'hebrews': 'Hebrews',
    'james': 'James',
    '1pet': '1 Peter',
    '1 peter': '1 Peter',
    '2pet': '2 Peter',
    '2 peter': '2 Peter',
    '1john': '1 John',
    '1 john': '1 John',
    '2john': '2 John',
    '2 john': '2 John',
    '3john': '3 John',
    '3 john': '3 John',
    'jude': 'Jude',
    'rev': 'Revelation',
    'revelation': 'Revelation',
  };

  /// Parse reference string (e.g., "John 3:16", "Gen 1:1-3")
  static ParsedReference? parse(String input) {
    if (input.trim().isEmpty) return null;

    // Regex: Book Chapter:Verse or Book Chapter:Verse-Verse
    final regexFull = RegExp(
      r'^([a-z0-9\s]+?)\s+(\d+):(\d+)(?:-(\d+))?$',
      caseSensitive: false,
    );

    final match = regexFull.firstMatch(input.trim());
    if (match == null) return null;

    final bookRaw = match.group(1)!.trim().toLowerCase();
    final chapter = int.tryParse(match.group(2)!);
    final startVerse = int.tryParse(match.group(3)!);
    final endVerse = match.group(4) != null ? int.tryParse(match.group(4)!) : null;

    if (chapter == null || startVerse == null) return null;

    // Resolve book name
    final bookName = bookAbbreviations[bookRaw] ?? _findBookByPartialMatch(bookRaw);
    if (bookName == null) return null;

    return ParsedReference(
      book: bookName,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
    );
  }

  /// Find book by partial match (e.g., "joh" → "John")
  static String? _findBookByPartialMatch(String partial) {
    final lower = partial.toLowerCase();

    // Check exact match first
    if (bookAbbreviations.containsKey(lower)) {
      return bookAbbreviations[lower];
    }

    // Check if any abbreviation starts with input
    for (final entry in bookAbbreviations.entries) {
      if (entry.key.startsWith(lower)) {
        return entry.value;
      }
    }

    // Check if any full book name starts with input
    for (final bookName in bookAbbreviations.values.toSet()) {
      if (bookName.toLowerCase().startsWith(lower)) {
        return bookName;
      }
    }

    return null;
  }

  /// Check if input looks like a reference
  static bool looksLikeReference(String input) {
    return RegExp(r'[a-z]+\s*\d+:\d+', caseSensitive: false).hasMatch(input);
  }
}

/// Parsed Bible reference data
class ParsedReference {
  final String book;
  final int chapter;
  final int startVerse;
  final int? endVerse;

  ParsedReference({
    required this.book,
    required this.chapter,
    required this.startVerse,
    this.endVerse,
  });

  bool get isRange => endVerse != null;

  @override
  String toString() =>
      '$book $chapter:$startVerse${endVerse != null ? '-$endVerse' : ''}';
}
