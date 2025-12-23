import 'dart:convert';

/// Model representing a Bible verse with metadata
class BibleVerse {
  final int? id;
  final String book;
  final int chapter;
  final int verseNumber;
  final String text;
  final String translation;
  final String reference;
  final List<String> themes;
  final String category;
  final DateTime? createdAt;
  final String? snippet; // For search results
  final double? relevanceScore; // For search ranking
  final bool isFavorite; // For UI state

  const BibleVerse({
    this.id,
    required this.book,
    required this.chapter,
    required this.verseNumber,
    required this.text,
    required this.translation,
    required this.reference,
    required this.themes,
    required this.category,
    this.createdAt,
    this.snippet,
    this.relevanceScore,
    this.isFavorite = false,
  });

  /// Create verse from database map
  factory BibleVerse.fromMap(Map<String, dynamic> map, {bool isFavorite = false}) {
    List<String> themesList = [];
    // Check both 'themes' and 'tags' fields (favorite_verses uses 'tags')
    final dynamic themesData = map['themes'] ?? map['tags'];
    if (themesData != null) {
      try {
        if (themesData is String) {
          themesList = List<String>.from(jsonDecode(themesData));
        } else if (themesData is List) {
          themesList = List<String>.from(themesData);
        }
      } catch (e) {
        // Handle malformed JSON gracefully
        themesList = [];
      }
    }

    // Construct reference if not provided
    String reference = map['reference'] ?? '';
    if (reference.isEmpty && map['book'] != null) {
      reference = '${map['book']} ${map['chapter']}:${map['verse_number'] ?? map['verse'] ?? ''}';
    }

    return BibleVerse(
      id: map['id'] as int?,
      book: map['book'] as String? ?? '',
      chapter: map['chapter'] as int? ?? 0,
      verseNumber: (map['verse_number'] ?? map['verse']) as int? ?? 0,
      text: map['text'] as String? ?? '',
      translation: map['translation'] as String? ?? 'WEB',
      reference: reference,
      themes: themesList,
      category: map['category'] as String? ?? 'general',
      createdAt: map['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt())
        : null,
      snippet: map['snippet'] as String?,
      relevanceScore: map['relevance_score'] != null
        ? (map['relevance_score'] as num).toDouble()
        : (map['rank'] != null ? (map['rank'] as num).toDouble() : null),
      isFavorite: isFavorite,
    );
  }

  /// Convert verse to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'book': book,
      'chapter': chapter,
      'verse_number': verseNumber,
      'text': text,
      'translation': translation,
      'reference': reference,
      'themes': jsonEncode(themes),
      'category': category,
      'created_at': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Create verse from JSON
  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    final chapter = json['chapter'] != null ? (json['chapter'] as num).toInt() : 0;
    final verse = (json['verse'] ?? json['verse_number']) != null
        ? ((json['verse'] ?? json['verse_number']) as num).toInt()
        : 0;
    final reference = '${json['book']} $chapter:$verse';

    List<String> themesList = [];
    if (json['themes'] != null) {
      if (json['themes'] is List) {
        themesList = List<String>.from(json['themes']);
      } else if (json['themes'] is String) {
        try {
          themesList = List<String>.from(jsonDecode(json['themes']));
        } catch (e) {
          themesList = [];
        }
      }
    }

    return BibleVerse(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      book: json['book'] as String? ?? '',
      chapter: chapter,
      verseNumber: verse,
      text: json['text'] as String? ?? '',
      translation: json['translation'] as String? ?? 'WEB',
      reference: reference,
      themes: themesList,
      category: json['category'] as String? ?? 'general',
      createdAt: json['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch((json['created_at'] as num).toInt())
        : null,
    );
  }

  /// Convert verse to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'book': book,
      'chapter': chapter,
      'verse': verseNumber,
      'text': text,
      'translation': translation,
      'reference': reference,
      'themes': themes,
      'category': category,
      if (createdAt != null) 'created_at': createdAt!.millisecondsSinceEpoch,
    };
  }

  /// Get formatted reference for display
  String get displayReference => reference;

  /// Get short reference (without book name)
  String get shortReference => '$chapter:$verseNumber';

  /// Check if verse contains a specific theme
  bool hasTheme(String theme) {
    return themes.any((t) => t.toLowerCase() == theme.toLowerCase()) ||
           category.toLowerCase() == theme.toLowerCase();
  }

  /// Get verse text with highlighting for search results
  String getDisplayText({String? highlightQuery}) {
    if (snippet != null) {
      return snippet!;
    }

    if (highlightQuery != null && highlightQuery.isNotEmpty) {
      return text.replaceAllMapped(
        RegExp(highlightQuery, caseSensitive: false),
        (match) => '<mark>${match.group(0)}</mark>',
      );
    }

    return text;
  }

  /// Get primary theme (first theme or category)
  String get primaryTheme {
    if (themes.isNotEmpty) {
      return themes.first;
    }
    return category;
  }

  /// Get verse length category
  VerseLength get length {
    final wordCount = text.split(' ').length;
    if (wordCount <= 10) return VerseLength.short;
    if (wordCount <= 25) return VerseLength.medium;
    return VerseLength.long;
  }

  /// Check if this is a popular/well-known verse
  bool get isPopular {
    final popularReferences = [
      'John 3:16',
      'Romans 8:28',
      'Philippians 4:13',
      'Jeremiah 29:11',
      'Psalm 23:1',
      'Isaiah 41:10',
      'Matthew 11:28',
      'Proverbs 3:5',
      '1 Peter 5:7',
      'Joshua 1:9',
    ];

    return popularReferences.contains(reference);
  }

  /// Copy verse with modifications
  BibleVerse copyWith({
    int? id,
    String? book,
    int? chapter,
    int? verseNumber,
    String? text,
    String? translation,
    String? reference,
    List<String>? themes,
    String? category,
    DateTime? createdAt,
    String? snippet,
    double? relevanceScore,
    bool? isFavorite,
  }) {
    return BibleVerse(
      id: id ?? this.id,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verseNumber: verseNumber ?? this.verseNumber,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      reference: reference ?? this.reference,
      themes: themes ?? this.themes,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      snippet: snippet ?? this.snippet,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BibleVerse &&
      other.book == book &&
      other.chapter == chapter &&
      other.verseNumber == verseNumber &&
      other.translation == translation;
  }

  @override
  int get hashCode {
    return book.hashCode ^
      chapter.hashCode ^
      verseNumber.hashCode ^
      translation.hashCode;
  }

  @override
  String toString() {
    return 'BibleVerse(reference: $reference, text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text})';
  }
}

/// Enum for verse length categories
enum VerseLength {
  short,
  medium,
  long,
}

/// Extension for verse length descriptions
extension VerseLengthExtension on VerseLength {
  String get description {
    switch (this) {
      case VerseLength.short:
        return 'Short (≤10 words)';
      case VerseLength.medium:
        return 'Medium (11-25 words)';
      case VerseLength.long:
        return 'Long (>25 words)';
    }
  }

  String get emoji {
    switch (this) {
      case VerseLength.short:
        return '📝';
      case VerseLength.medium:
        return '📄';
      case VerseLength.long:
        return '📜';
    }
  }
}

/// Helper class for verse search results
class VerseSearchResult {
  final BibleVerse verse;
  final double relevanceScore;
  final String? highlightedText;
  final List<String> matchingThemes;

  const VerseSearchResult({
    required this.verse,
    required this.relevanceScore,
    this.highlightedText,
    this.matchingThemes = const [],
  });

  factory VerseSearchResult.fromMap(Map<String, dynamic> map) {
    return VerseSearchResult(
      verse: BibleVerse.fromMap(map),
      relevanceScore: map['relevance_score']?.toDouble() ?? 0.0,
      highlightedText: map['snippet'],
      matchingThemes: [], // Would need to be calculated based on search query
    );
  }
}

/// Helper class for verse collections/themes
class VerseCollection {
  final String name;
  final String description;
  final List<String> themes;
  final String emoji;
  final List<BibleVerse> verses;

  const VerseCollection({
    required this.name,
    required this.description,
    required this.themes,
    required this.emoji,
    this.verses = const [],
  });

  static const List<VerseCollection> predefinedCollections = [
    VerseCollection(
      name: 'Comfort & Peace',
      description: 'Verses for times of worry and stress',
      themes: ['comfort', 'peace', 'rest'],
      emoji: '🕊️',
    ),
    VerseCollection(
      name: 'Strength & Courage',
      description: 'Verses for overcoming challenges',
      themes: ['strength', 'courage', 'perseverance'],
      emoji: '💪',
    ),
    VerseCollection(
      name: 'Hope & Future',
      description: 'Verses about God\'s plans and promises',
      themes: ['hope', 'future', 'plans', 'purpose'],
      emoji: '🌅',
    ),
    VerseCollection(
      name: 'Love & Relationships',
      description: 'Verses about God\'s love and loving others',
      themes: ['love', 'relationships', 'forgiveness'],
      emoji: '❤️',
    ),
    VerseCollection(
      name: 'Wisdom & Guidance',
      description: 'Verses for making decisions and seeking direction',
      themes: ['wisdom', 'guidance', 'discernment'],
      emoji: '🧭',
    ),
    VerseCollection(
      name: 'Faith & Trust',
      description: 'Verses about trusting God in all circumstances',
      themes: ['faith', 'trust', 'belief'],
      emoji: '🙏',
    ),
  ];
}