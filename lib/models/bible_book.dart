/// Model representing a Bible book with metadata for all languages
class BibleBook {
  final int id;
  final String testament;
  final String englishName;
  final String spanishName;
  final String abbreviation;
  final int chapters;

  BibleBook({
    required this.id,
    required this.testament,
    required this.englishName,
    required this.spanishName,
    required this.abbreviation,
    required this.chapters,
  });

  /// Factory constructor to create BibleBook from JSON
  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as int,
      testament: json['testament'] as String,
      englishName: json['englishName'] as String,
      spanishName: json['spanishName'] as String,
      abbreviation: json['abbreviation'] as String,
      chapters: json['chapters'] as int,
    );
  }

  /// Convert BibleBook to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testament': testament,
      'englishName': englishName,
      'spanishName': spanishName,
      'abbreviation': abbreviation,
      'chapters': chapters,
    };
  }

  /// Get the localized name based on language code
  String getName(String languageCode) {
    switch (languageCode) {
      case 'es':
        return spanishName;
      case 'en':
      default:
        return englishName;
    }
  }

  /// Check if this book matches a given name (in any language)
  bool matchesName(String name) {
    return englishName.toLowerCase() == name.toLowerCase() ||
        spanishName.toLowerCase() == name.toLowerCase();
  }

  @override
  String toString() {
    return 'BibleBook(id: $id, english: $englishName, spanish: $spanishName, chapters: $chapters)';
  }
}
