import 'bible_verse.dart';

/// Model for passing verse context data between Bible reading and chat screens
/// Used when user taps the avatar icon to discuss a specific verse
class VerseContext {
  final String book;
  final int chapter;
  final int verseNumber;
  final String verseText;
  final String translation;

  const VerseContext({
    required this.book,
    required this.chapter,
    required this.verseNumber,
    required this.verseText,
    this.translation = 'WEB',
  });

  /// Create from BibleVerse model
  factory VerseContext.fromVerse(BibleVerse verse) {
    return VerseContext(
      book: verse.book,
      chapter: verse.chapter,
      verseNumber: verse.verseNumber,
      verseText: verse.text,
      translation: verse.translation,
    );
  }

  /// Returns formatted reference (e.g., "John 3:16")
  String get reference => '$book $chapter:$verseNumber';

  /// Returns full reference with translation (e.g., "John 3:16 (WEB)" or "Juan 3:16 (RVR1909)")
  String get fullReference => '$reference ($translation)';

  /// Convert to map for ChatMessage metadata storage
  Map<String, dynamic> toMap() {
    return {
      'book': book,
      'chapter': chapter,
      'verseNumber': verseNumber,
      'verseText': verseText,
      'translation': translation,
    };
  }

  /// Create from map (for ChatMessage metadata retrieval)
  factory VerseContext.fromMap(Map<String, dynamic> map) {
    return VerseContext(
      book: map['book'] as String,
      chapter: map['chapter'] as int,
      verseNumber: map['verseNumber'] as int,
      verseText: map['verseText'] as String,
      translation: map['translation'] as String? ?? 'WEB',
    );
  }

  @override
  String toString() => fullReference;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VerseContext &&
        other.book == book &&
        other.chapter == chapter &&
        other.verseNumber == verseNumber &&
        other.verseText == verseText;
  }

  @override
  int get hashCode {
    return book.hashCode ^
        chapter.hashCode ^
        verseNumber.hashCode ^
        verseText.hashCode;
  }
}
