/// Parser for reading references to extract book and chapter information
class ReadingReferenceParser {
  /// Parses a reading reference into its components
  ///
  /// Supports formats like:
  /// - "Genesis 1-3" → {book: "Genesis", start: 1, end: 3}
  /// - "Genesis 1" → {book: "Genesis", start: 1, end: 1}
  /// - "John 3" → {book: "John", start: 3, end: 3}
  /// - "1-3" (when book is provided separately) → {start: 1, end: 3}
  static ReadingReference parse(String reference, {String? book}) {
    // If book is provided separately, just parse the chapter range
    if (book != null && book.isNotEmpty) {
      return _parseChapterRange(book, reference);
    }

    // Parse full reference with book name and chapters
    // Matches patterns like: "Genesis 1-3", "John 3", "1 John 2"
    final pattern = RegExp(r'^(.+?)\s+(\d+)(?:-(\d+))?$');
    final match = pattern.firstMatch(reference.trim());

    if (match == null) {
      throw FormatException('Invalid reading reference: $reference');
    }

    final bookName = match.group(1)!.trim();
    final startChapter = int.parse(match.group(2)!);
    final endChapter = match.group(3) != null
        ? int.parse(match.group(3)!)
        : startChapter;

    return ReadingReference(
      book: bookName,
      startChapter: startChapter,
      endChapter: endChapter,
    );
  }

  /// Parses chapter range when book is known
  static ReadingReference _parseChapterRange(String book, String chapters) {
    // Handle ranges like "1-3" or single chapters like "1"
    final rangePattern = RegExp(r'^(\d+)(?:-(\d+))?$');
    final match = rangePattern.firstMatch(chapters.trim());

    if (match == null) {
      throw FormatException('Invalid chapter range: $chapters');
    }

    final startChapter = int.parse(match.group(1)!);
    final endChapter = match.group(2) != null
        ? int.parse(match.group(2)!)
        : startChapter;

    return ReadingReference(
      book: book,
      startChapter: startChapter,
      endChapter: endChapter,
    );
  }

  /// Parses from a DailyReading model
  static ReadingReference fromDailyReading(String book, String chapters) {
    return _parseChapterRange(book, chapters);
  }
}

/// Represents a parsed reading reference
class ReadingReference {
  final String book;
  final int startChapter;
  final int endChapter;

  ReadingReference({
    required this.book,
    required this.startChapter,
    required this.endChapter,
  });

  /// Returns true if this is a multi-chapter reading
  bool get isMultiChapter => endChapter > startChapter;

  /// Returns the number of chapters in this reading
  int get chapterCount => endChapter - startChapter + 1;

  /// Returns a human-readable description
  String get description {
    if (isMultiChapter) {
      return '$book $startChapter-$endChapter';
    }
    return '$book $startChapter';
  }

  @override
  String toString() => description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingReference &&
          runtimeType == other.runtimeType &&
          book == other.book &&
          startChapter == other.startChapter &&
          endChapter == other.endChapter;

  @override
  int get hashCode =>
      book.hashCode ^ startChapter.hashCode ^ endChapter.hashCode;
}
