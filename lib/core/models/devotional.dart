import 'package:freezed_annotation/freezed_annotation.dart';

part 'devotional.freezed.dart';
part 'devotional.g.dart';

@freezed
class Devotional with _$Devotional {
  const factory Devotional({
    required String id,
    required String date,
    required String title,
    required String openingScriptureReference,
    required String openingScriptureText,
    required String keyVerseReference,
    required String keyVerseText,
    required String reflection,
    required String lifeApplication,
    required String prayer,
    required String actionStep,
    required List<String> goingDeeper,
    required String readingTime,
    @Default(false) bool isCompleted,
    DateTime? completedDate,
    @Default(false) bool actionStepCompleted,
  }) = _Devotional;

  factory Devotional.fromJson(Map<String, dynamic> json) =>
      _$DevotionalFromJson(json);
}