import 'package:freezed_annotation/freezed_annotation.dart';

part 'bible_verse.freezed.dart';
part 'bible_verse.g.dart';

@freezed
class BibleVerse with _$BibleVerse {
  const factory BibleVerse({
    required String id,
    required String text,
    required String reference,
    required VerseCategory category,
    @Default(false) bool isFavorite,
    DateTime? dateAdded,
  }) = _BibleVerse;

  factory BibleVerse.fromJson(Map<String, dynamic> json) =>
      _$BibleVerseFromJson(json);
}

enum VerseCategory {
  faith,
  hope,
  love,
  peace,
  strength,
  comfort,
  guidance,
  wisdom,
  forgiveness,
  joy,
  courage,
  patience,
}

extension VerseCategoryExtension on VerseCategory {
  String get displayName {
    switch (this) {
      case VerseCategory.faith:
        return 'Faith';
      case VerseCategory.hope:
        return 'Hope';
      case VerseCategory.love:
        return 'Love';
      case VerseCategory.peace:
        return 'Peace';
      case VerseCategory.strength:
        return 'Strength';
      case VerseCategory.comfort:
        return 'Comfort';
      case VerseCategory.guidance:
        return 'Guidance';
      case VerseCategory.wisdom:
        return 'Wisdom';
      case VerseCategory.forgiveness:
        return 'Forgiveness';
      case VerseCategory.joy:
        return 'Joy';
      case VerseCategory.courage:
        return 'Courage';
      case VerseCategory.patience:
        return 'Patience';
    }
  }
}