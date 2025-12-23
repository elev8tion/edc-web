// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadingPlanImpl _$$ReadingPlanImplFromJson(Map<String, dynamic> json) =>
    _$ReadingPlanImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      duration: json['duration'] as String,
      category: $enumDecode(_$PlanCategoryEnumMap, json['category']),
      difficulty: $enumDecode(_$PlanDifficultyEnumMap, json['difficulty']),
      estimatedTimePerDay: json['estimatedTimePerDay'] as String,
      totalReadings: (json['totalReadings'] as num).toInt(),
      completedReadings: (json['completedReadings'] as num?)?.toInt() ?? 0,
      isStarted: json['isStarted'] as bool? ?? false,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
    );

Map<String, dynamic> _$$ReadingPlanImplToJson(_$ReadingPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'duration': instance.duration,
      'category': _$PlanCategoryEnumMap[instance.category]!,
      'difficulty': _$PlanDifficultyEnumMap[instance.difficulty]!,
      'estimatedTimePerDay': instance.estimatedTimePerDay,
      'totalReadings': instance.totalReadings,
      'completedReadings': instance.completedReadings,
      'isStarted': instance.isStarted,
      'startDate': instance.startDate?.toIso8601String(),
    };

const _$PlanCategoryEnumMap = {
  PlanCategory.completeBible: 'completeBible',
  PlanCategory.newTestament: 'newTestament',
  PlanCategory.oldTestament: 'oldTestament',
  PlanCategory.gospels: 'gospels',
  PlanCategory.epistles: 'epistles',
  PlanCategory.psalms: 'psalms',
  PlanCategory.proverbs: 'proverbs',
  PlanCategory.wisdom: 'wisdom',
  PlanCategory.prophecy: 'prophecy',
};

const _$PlanDifficultyEnumMap = {
  PlanDifficulty.beginner: 'beginner',
  PlanDifficulty.intermediate: 'intermediate',
  PlanDifficulty.advanced: 'advanced',
};

_$DailyReadingImpl _$$DailyReadingImplFromJson(Map<String, dynamic> json) =>
    _$DailyReadingImpl(
      id: json['id'] as String,
      planId: json['planId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      book: json['book'] as String,
      chapters: json['chapters'] as String,
      estimatedTime: json['estimatedTime'] as String,
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedDate: json['completedDate'] == null
          ? null
          : DateTime.parse(json['completedDate'] as String),
    );

Map<String, dynamic> _$$DailyReadingImplToJson(_$DailyReadingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'planId': instance.planId,
      'title': instance.title,
      'description': instance.description,
      'book': instance.book,
      'chapters': instance.chapters,
      'estimatedTime': instance.estimatedTime,
      'date': instance.date.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'completedDate': instance.completedDate?.toIso8601String(),
    };
