// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devotional.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DevotionalImpl _$$DevotionalImplFromJson(Map<String, dynamic> json) =>
    _$DevotionalImpl(
      id: json['id'] as String,
      date: json['date'] as String,
      title: json['title'] as String,
      openingScriptureReference: json['openingScriptureReference'] as String,
      openingScriptureText: json['openingScriptureText'] as String,
      keyVerseReference: json['keyVerseReference'] as String,
      keyVerseText: json['keyVerseText'] as String,
      reflection: json['reflection'] as String,
      lifeApplication: json['lifeApplication'] as String,
      prayer: json['prayer'] as String,
      actionStep: json['actionStep'] as String,
      goingDeeper: (json['goingDeeper'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      readingTime: json['readingTime'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedDate: json['completedDate'] == null
          ? null
          : DateTime.parse(json['completedDate'] as String),
      actionStepCompleted: json['actionStepCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$DevotionalImplToJson(_$DevotionalImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'title': instance.title,
      'openingScriptureReference': instance.openingScriptureReference,
      'openingScriptureText': instance.openingScriptureText,
      'keyVerseReference': instance.keyVerseReference,
      'keyVerseText': instance.keyVerseText,
      'reflection': instance.reflection,
      'lifeApplication': instance.lifeApplication,
      'prayer': instance.prayer,
      'actionStep': instance.actionStep,
      'goingDeeper': instance.goingDeeper,
      'readingTime': instance.readingTime,
      'isCompleted': instance.isCompleted,
      'completedDate': instance.completedDate?.toIso8601String(),
      'actionStepCompleted': instance.actionStepCompleted,
    };
