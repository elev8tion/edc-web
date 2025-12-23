// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_verse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BibleVerseImpl _$$BibleVerseImplFromJson(Map<String, dynamic> json) =>
    _$BibleVerseImpl(
      id: json['id'] as String,
      text: json['text'] as String,
      reference: json['reference'] as String,
      category: $enumDecode(_$VerseCategoryEnumMap, json['category']),
      isFavorite: json['isFavorite'] as bool? ?? false,
      dateAdded: json['dateAdded'] == null
          ? null
          : DateTime.parse(json['dateAdded'] as String),
    );

Map<String, dynamic> _$$BibleVerseImplToJson(_$BibleVerseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'reference': instance.reference,
      'category': _$VerseCategoryEnumMap[instance.category]!,
      'isFavorite': instance.isFavorite,
      'dateAdded': instance.dateAdded?.toIso8601String(),
    };

const _$VerseCategoryEnumMap = {
  VerseCategory.faith: 'faith',
  VerseCategory.hope: 'hope',
  VerseCategory.love: 'love',
  VerseCategory.peace: 'peace',
  VerseCategory.strength: 'strength',
  VerseCategory.comfort: 'comfort',
  VerseCategory.guidance: 'guidance',
  VerseCategory.wisdom: 'wisdom',
  VerseCategory.forgiveness: 'forgiveness',
  VerseCategory.joy: 'joy',
  VerseCategory.courage: 'courage',
  VerseCategory.patience: 'patience',
};
