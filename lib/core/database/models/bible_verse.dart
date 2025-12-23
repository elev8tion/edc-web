import 'dart:convert';

class BibleVerse {
  final int? id;
  final String book;
  final int chapter;
  final int verseNumber;
  final String text;
  final String translation;
  final List<String> themes;
  final DateTime? createdAt;

  const BibleVerse({
    this.id,
    required this.book,
    required this.chapter,
    required this.verseNumber,
    required this.text,
    this.translation = 'ESV',
    this.themes = const [],
    this.createdAt,
  });

  /// Create BibleVerse from database map
  factory BibleVerse.fromMap(Map<String, dynamic> map) {
    return BibleVerse(
      id: map['id'] as int?,
      book: map['book'] as String,
      chapter: map['chapter'] as int,
      verseNumber: map['verse_number'] as int,
      text: map['text'] as String,
      translation: map['translation'] as String? ?? 'ESV',
      themes: _parseThemes(map['themes'] as String?),
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
    );
  }

  /// Convert BibleVerse to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'book': book,
      'chapter': chapter,
      'verse_number': verseNumber,
      'text': text,
      'translation': translation,
      'themes': jsonEncode(themes),
      if (createdAt != null) 'created_at': createdAt!.millisecondsSinceEpoch,
    };
  }

  /// Parse themes from JSON string
  static List<String> _parseThemes(String? themesJson) {
    if (themesJson == null || themesJson.isEmpty) return [];
    try {
      final List<dynamic> parsed = jsonDecode(themesJson);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get verse reference (e.g., "John 3:16")
  String get reference => '$book $chapter:$verseNumber';

  /// Get formatted verse with reference
  String get formattedVerse => '"$text" - $reference ($translation)';

  /// Check if verse contains theme
  bool hasTheme(String theme) {
    return themes.any((t) => t.toLowerCase() == theme.toLowerCase());
  }

  /// Check if verse contains any of the given themes
  bool hasAnyTheme(List<String> searchThemes) {
    return searchThemes.any((theme) => hasTheme(theme));
  }

  /// Get verse for sharing
  String getShareText({bool includeApp = true}) {
    final baseText = '"$text"\n\n$reference ($translation)';
    if (includeApp) {
      return '$baseText\n\nShared from Everyday Christian';
    }
    return baseText;
  }

  /// Copy with updated fields
  BibleVerse copyWith({
    int? id,
    String? book,
    int? chapter,
    int? verseNumber,
    String? text,
    String? translation,
    List<String>? themes,
    DateTime? createdAt,
  }) {
    return BibleVerse(
      id: id ?? this.id,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verseNumber: verseNumber ?? this.verseNumber,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      themes: themes ?? this.themes,
      createdAt: createdAt ?? this.createdAt,
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
    return 'BibleVerse(id: $id, reference: $reference, translation: $translation, themes: $themes)';
  }
}

/// Helper class for verse themes
class VerseTheme {
  static const String comfort = 'comfort';
  static const String strength = 'strength';
  static const String guidance = 'guidance';
  static const String hope = 'hope';
  static const String trust = 'trust';
  static const String peace = 'peace';
  static const String gratitude = 'gratitude';
  static const String love = 'love';
  static const String forgiveness = 'forgiveness';
  static const String faith = 'faith';
  static const String courage = 'courage';
  static const String wisdom = 'wisdom';
  static const String joy = 'joy';
  static const String patience = 'patience';
  static const String perseverance = 'perseverance';
  static const String provision = 'provision';
  static const String protection = 'protection';
  static const String healing = 'healing';
  static const String salvation = 'salvation';
  static const String purpose = 'purpose';

  static const List<String> allThemes = [
    comfort,
    strength,
    guidance,
    hope,
    trust,
    peace,
    gratitude,
    love,
    forgiveness,
    faith,
    courage,
    wisdom,
    joy,
    patience,
    perseverance,
    provision,
    protection,
    healing,
    salvation,
    purpose,
  ];

  /// Get theme display name
  static String getDisplayName(String theme) {
    switch (theme) {
      case comfort:
        return 'Comfort & Consolation';
      case strength:
        return 'Strength & Power';
      case guidance:
        return 'Guidance & Direction';
      case hope:
        return 'Hope & Encouragement';
      case trust:
        return 'Trust & Faith';
      case peace:
        return 'Peace & Rest';
      case gratitude:
        return 'Gratitude & Thanksgiving';
      case love:
        return 'Love & Compassion';
      case forgiveness:
        return 'Forgiveness & Mercy';
      case faith:
        return 'Faith & Belief';
      case courage:
        return 'Courage & Boldness';
      case wisdom:
        return 'Wisdom & Understanding';
      case joy:
        return 'Joy & Celebration';
      case patience:
        return 'Patience & Endurance';
      case perseverance:
        return 'Perseverance & Persistence';
      case provision:
        return 'Provision & Supply';
      case protection:
        return 'Protection & Safety';
      case healing:
        return 'Healing & Restoration';
      case salvation:
        return 'Salvation & Redemption';
      case purpose:
        return 'Purpose & Calling';
      default:
        return theme.substring(0, 1).toUpperCase() + theme.substring(1);
    }
  }

  /// Get theme description
  static String getDescription(String theme) {
    switch (theme) {
      case comfort:
        return 'Verses for times of sadness, grief, or distress';
      case strength:
        return 'Verses for when you need courage and perseverance';
      case guidance:
        return 'Verses for decision-making and direction';
      case hope:
        return 'Verses for encouragement and future faith';
      case trust:
        return 'Verses about relying on God\'s faithfulness';
      case peace:
        return 'Verses for anxiety and restlessness';
      case gratitude:
        return 'Verses for thanksgiving and appreciation';
      case love:
        return 'Verses about God\'s love and loving others';
      case forgiveness:
        return 'Verses about forgiveness and second chances';
      case faith:
        return 'Verses about believing and trusting in God';
      case courage:
        return 'Verses for facing fears and challenges';
      case wisdom:
        return 'Verses for understanding and discernment';
      case joy:
        return 'Verses for celebration and happiness';
      case patience:
        return 'Verses for waiting and enduring';
      case perseverance:
        return 'Verses for not giving up';
      case provision:
        return 'Verses about God\'s provision and care';
      case protection:
        return 'Verses about safety and security in God';
      case healing:
        return 'Verses for physical and emotional healing';
      case salvation:
        return 'Verses about eternal life and redemption';
      case purpose:
        return 'Verses about life\'s meaning and calling';
      default:
        return 'Biblical wisdom for life';
    }
  }
}