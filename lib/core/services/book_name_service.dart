/// Service for mapping Bible book names between English and Spanish
class BookNameService {
  // Standard Bible abbreviations for large text scales (130%+)
  static const Map<String, String> _englishAbbreviations = {
    // Old Testament
    'Genesis': 'Gen.',
    'Exodus': 'Ex.',
    'Leviticus': 'Lev.',
    'Numbers': 'Num.',
    'Deuteronomy': 'Deut.',
    'Joshua': 'Josh.',
    'Judges': 'Judg.',
    '1 Samuel': '1 Sam.',
    '2 Samuel': '2 Sam.',
    '1 Chronicles': '1 Chron.',
    '2 Chronicles': '2 Chron.',
    'Nehemiah': 'Neh.',
    'Esther': 'Esth.',
    'Psalms': 'Ps.',
    'Proverbs': 'Prov.',
    'Ecclesiastes': 'Eccl.',
    'Song of Solomon': 'Song',
    'Isaiah': 'Isa.',
    'Jeremiah': 'Jer.',
    'Lamentations': 'Lam.',
    'Ezekiel': 'Ezek.',
    'Daniel': 'Dan.',
    'Obadiah': 'Obad.',
    'Habakkuk': 'Hab.',
    'Zephaniah': 'Zeph.',
    'Haggai': 'Hag.',
    'Zechariah': 'Zech.',
    'Malachi': 'Mal.',
    // New Testament
    'Matthew': 'Matt.',
    'Romans': 'Rom.',
    '1 Corinthians': '1 Cor.',
    '2 Corinthians': '2 Cor.',
    'Galatians': 'Gal.',
    'Ephesians': 'Eph.',
    'Philippians': 'Phil.',
    'Colossians': 'Col.',
    '1 Thessalonians': '1 Thess.',
    '2 Thessalonians': '2 Thess.',
    '1 Timothy': '1 Tim.',
    '2 Timothy': '2 Tim.',
    'Philemon': 'Philem.',
    'Hebrews': 'Heb.',
    '1 Peter': '1 Pet.',
    '2 Peter': '2 Pet.',
    'Revelation': 'Rev.',
  };

  // Standard Bible abbreviations for Spanish (large text scales 130%+)
  static const Map<String, String> _spanishAbbreviations = {
    // Antiguo Testamento
    'Génesis': 'Gén.',
    'Éxodo': 'Éx.',
    'Levítico': 'Lev.',
    'Números': 'Núm.',
    'Deuteronomio': 'Deut.',
    'Josué': 'Jos.',
    'Jueces': 'Jue.',
    '1 Samuel': '1 Sam.',
    '2 Samuel': '2 Sam.',
    '1 Reyes': '1 Re.',
    '2 Reyes': '2 Re.',
    '1 Crónicas': '1 Crón.',
    '2 Crónicas': '2 Crón.',
    'Esdras': 'Esd.',
    'Nehemías': 'Neh.',
    'Salmos': 'Sal.',
    'Proverbios': 'Prov.',
    'Eclesiastés': 'Ecl.',
    'Cantares': 'Cant.',
    'Isaías': 'Is.',
    'Jeremías': 'Jer.',
    'Lamentaciones': 'Lam.',
    'Ezequiel': 'Ez.',
    'Daniel': 'Dan.',
    'Miqueas': 'Miq.',
    'Habacuc': 'Hab.',
    'Sofonías': 'Sof.',
    'Zacarías': 'Zac.',
    'Malaquías': 'Mal.',
    // Nuevo Testamento
    'Romanos': 'Rom.',
    'Hechos': 'Hch.',
    '1 Corintios': '1 Cor.',
    '2 Corintios': '2 Cor.',
    'Gálatas': 'Gál.',
    'Efesios': 'Ef.',
    'Filipenses': 'Fil.',
    'Colosenses': 'Col.',
    '1 Tesalonicenses': '1 Tes.',
    '2 Tesalonicenses': '2 Tes.',
    '1 Timoteo': '1 Tim.',
    '2 Timoteo': '2 Tim.',
    'Filemón': 'Flm.',
    'Hebreos': 'Heb.',
    'Santiago': 'Stgo.',
    '1 Pedro': '1 Ped.',
    '2 Pedro': '2 Ped.',
    'Apocalipsis': 'Apoc.',
  };

  // English to Spanish mapping
  static const Map<String, String> _englishToSpanish = {
    // Old Testament
    'Genesis': 'Génesis',
    'Exodus': 'Éxodo',
    'Leviticus': 'Levítico',
    'Numbers': 'Números',
    'Deuteronomy': 'Deuteronomio',
    'Joshua': 'Josué',
    'Judges': 'Jueces',
    'Ruth': 'Rut',
    '1 Samuel': '1 Samuel',
    '2 Samuel': '2 Samuel',
    '1 Kings': '1 Reyes',
    '2 Kings': '2 Reyes',
    '1 Chronicles': '1 Crónicas',
    '2 Chronicles': '2 Crónicas',
    'Ezra': 'Esdras',
    'Nehemiah': 'Nehemías',
    'Esther': 'Ester',
    'Job': 'Job',
    'Psalms': 'Salmos',
    'Proverbs': 'Proverbios',
    'Ecclesiastes': 'Eclesiastés',
    'Song of Solomon': 'Cantares',
    'Isaiah': 'Isaías',
    'Jeremiah': 'Jeremías',
    'Lamentations': 'Lamentaciones',
    'Ezekiel': 'Ezequiel',
    'Daniel': 'Daniel',
    'Hosea': 'Oseas',
    'Joel': 'Joel',
    'Amos': 'Amós',
    'Obadiah': 'Abdías',
    'Jonah': 'Jonás',
    'Micah': 'Miqueas',
    'Nahum': 'Nahúm',
    'Habakkuk': 'Habacuc',
    'Zephaniah': 'Sofonías',
    'Haggai': 'Hageo',
    'Zechariah': 'Zacarías',
    'Malachi': 'Malaquías',

    // New Testament
    'Matthew': 'Mateo',
    'Mark': 'Marcos',
    'Luke': 'Lucas',
    'John': 'Juan',
    'Acts': 'Hechos',
    'Romans': 'Romanos',
    '1 Corinthians': '1 Corintios',
    '2 Corinthians': '2 Corintios',
    'Galatians': 'Gálatas',
    'Ephesians': 'Efesios',
    'Philippians': 'Filipenses',
    'Colossians': 'Colosenses',
    '1 Thessalonians': '1 Tesalonicenses',
    '2 Thessalonians': '2 Tesalonicenses',
    '1 Timothy': '1 Timoteo',
    '2 Timothy': '2 Timoteo',
    'Titus': 'Tito',
    'Philemon': 'Filemón',
    'Hebrews': 'Hebreos',
    'James': 'Santiago',
    '1 Peter': '1 Pedro',
    '2 Peter': '2 Pedro',
    '1 John': '1 Juan',
    '2 John': '2 Juan',
    '3 John': '3 Juan',
    'Jude': 'Judas',
    'Revelation': 'Apocalipsis',
  };

  // Spanish to English mapping (generated from reverse)
  static final Map<String, String> _spanishToEnglish = {
    for (var entry in _englishToSpanish.entries) entry.value: entry.key,
  };

  /// Convert English book name to Spanish
  static String toSpanish(String englishName) {
    return _englishToSpanish[englishName] ?? englishName;
  }

  /// Convert Spanish book name to English
  static String toEnglish(String spanishName) {
    return _spanishToEnglish[spanishName] ?? spanishName;
  }

  /// Get book name based on language preference
  static String getBookName(String bookName, String language) {
    if (language == 'es') {
      return toSpanish(bookName);
    }
    return bookName; // Default to English
  }

  /// Check if a book name is in Spanish
  static bool isSpanish(String bookName) {
    return _spanishToEnglish.containsKey(bookName);
  }

  /// Check if a book name is in English
  static bool isEnglish(String bookName) {
    return _englishToSpanish.containsKey(bookName);
  }

  /// Get abbreviated book name for compact display (at large text scales)
  /// Returns the full name if no abbreviation is needed
  static String getAbbreviation(String bookName) {
    // Check English abbreviations first
    if (_englishAbbreviations.containsKey(bookName)) {
      return _englishAbbreviations[bookName]!;
    }
    // Check Spanish abbreviations
    if (_spanishAbbreviations.containsKey(bookName)) {
      return _spanishAbbreviations[bookName]!;
    }
    // Return original name if no abbreviation needed
    return bookName;
  }

  /// Check if a book name has an available abbreviation
  static bool hasAbbreviation(String bookName) {
    return _englishAbbreviations.containsKey(bookName) ||
        _spanishAbbreviations.containsKey(bookName);
  }
}
