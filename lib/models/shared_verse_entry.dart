import 'dart:convert';

import 'bible_verse.dart';

/// Represents a verse that has been shared from the Verse Library.
class SharedVerseEntry {
  final String id;
  final int? verseId;
  final String book;
  final int chapter;
  final int verseNumber;
  final String reference;
  final String translation;
  final String text;
  final List<String> themes;
  final String? channel;
  final DateTime sharedAt;

  const SharedVerseEntry({
    required this.id,
    required this.verseId,
    required this.book,
    required this.chapter,
    required this.verseNumber,
    required this.reference,
    required this.translation,
    required this.text,
    required this.themes,
    required this.channel,
    required this.sharedAt,
  });

  factory SharedVerseEntry.fromMap(Map<String, dynamic> map) {
    List<String> parsedThemes = [];
    final rawThemes = map['themes'];

    if (rawThemes != null) {
      try {
        if (rawThemes is String && rawThemes.isNotEmpty) {
          parsedThemes = List<String>.from(jsonDecode(rawThemes));
        } else if (rawThemes is List) {
          parsedThemes = List<String>.from(rawThemes);
        }
      } catch (_) {
        parsedThemes = [];
      }
    }

    return SharedVerseEntry(
      id: map['id'] as String,
      verseId: map['verse_id'] as int?,
      book: map['book'] as String? ?? '',
      chapter: (map['chapter'] as num?)?.toInt() ?? 0,
      verseNumber: (map['verse_number'] as num?)?.toInt() ?? 0,
      reference: map['reference'] as String? ?? '',
      translation: map['translation'] as String? ?? 'WEB',
      text: map['text'] as String? ?? '',
      themes: parsedThemes,
      channel: map['channel'] as String?,
      sharedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['shared_at'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'verse_id': verseId,
      'book': book,
      'chapter': chapter,
      'verse_number': verseNumber,
      'reference': reference,
      'translation': translation,
      'text': text,
      'themes': jsonEncode(themes),
      'channel': channel,
      'shared_at': sharedAt.millisecondsSinceEpoch,
    };
  }

  /// Convenience helper to build a [BibleVerse] view for UI reuse.
  BibleVerse toBibleVerse() {
    return BibleVerse(
      id: verseId,
      book: book,
      chapter: chapter,
      verseNumber: verseNumber,
      text: text,
      translation: translation,
      reference: reference,
      themes: themes,
      category: themes.isNotEmpty ? themes.first : 'general',
    );
  }
}
