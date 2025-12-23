// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PrayerRequestImpl _$$PrayerRequestImplFromJson(Map<String, dynamic> json) =>
    _$PrayerRequestImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      isAnswered: json['isAnswered'] as bool? ?? false,
      dateAnswered: json['dateAnswered'] == null
          ? null
          : DateTime.parse(json['dateAnswered'] as String),
      answerDescription: json['answerDescription'] as String?,
    );

Map<String, dynamic> _$$PrayerRequestImplToJson(_$PrayerRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'dateCreated': instance.dateCreated.toIso8601String(),
      'isAnswered': instance.isAnswered,
      'dateAnswered': instance.dateAnswered?.toIso8601String(),
      'answerDescription': instance.answerDescription,
    };
