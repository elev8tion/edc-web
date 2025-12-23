// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PrayerCategoryImpl _$$PrayerCategoryImplFromJson(Map<String, dynamic> json) =>
    _$PrayerCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: (json['iconCodePoint'] as num).toInt(),
      colorValue: (json['colorValue'] as num).toInt(),
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      dateModified: json['dateModified'] == null
          ? null
          : DateTime.parse(json['dateModified'] as String),
    );

Map<String, dynamic> _$$PrayerCategoryImplToJson(
        _$PrayerCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconCodePoint': instance.iconCodePoint,
      'colorValue': instance.colorValue,
      'isDefault': instance.isDefault,
      'isActive': instance.isActive,
      'displayOrder': instance.displayOrder,
      'dateCreated': instance.dateCreated.toIso8601String(),
      'dateModified': instance.dateModified?.toIso8601String(),
    };
