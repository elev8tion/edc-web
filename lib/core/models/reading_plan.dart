import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../l10n/app_localizations.dart';

part 'reading_plan.freezed.dart';
part 'reading_plan.g.dart';

@freezed
class ReadingPlan with _$ReadingPlan {
  const factory ReadingPlan({
    required String id,
    required String title,
    required String description,
    required String duration,
    required PlanCategory category,
    required PlanDifficulty difficulty,
    required String estimatedTimePerDay,
    required int totalReadings,
    @Default(0) int completedReadings,
    @Default(false) bool isStarted,
    DateTime? startDate,
  }) = _ReadingPlan;

  factory ReadingPlan.fromJson(Map<String, dynamic> json) =>
      _$ReadingPlanFromJson(json);
}

@freezed
class DailyReading with _$DailyReading {
  const factory DailyReading({
    required String id,
    required String planId,
    required String title,
    required String description,
    required String book,
    required String chapters,
    required String estimatedTime,
    required DateTime date,
    @Default(false) bool isCompleted,
    DateTime? completedDate,
  }) = _DailyReading;

  factory DailyReading.fromJson(Map<String, dynamic> json) =>
      _$DailyReadingFromJson(json);
}

enum PlanCategory {
  completeBible,
  newTestament,
  oldTestament,
  gospels,
  epistles,
  psalms,
  proverbs,
  wisdom,
  prophecy,
}

enum PlanDifficulty {
  beginner,
  intermediate,
  advanced,
}

extension PlanCategoryExtension on PlanCategory {
  String get displayName {
    switch (this) {
      case PlanCategory.completeBible:
        return 'Complete Bible';
      case PlanCategory.newTestament:
        return 'New Testament';
      case PlanCategory.oldTestament:
        return 'Old Testament';
      case PlanCategory.gospels:
        return 'Gospels';
      case PlanCategory.epistles:
        return 'Epistles';
      case PlanCategory.psalms:
        return 'Psalms';
      case PlanCategory.proverbs:
        return 'Proverbs';
      case PlanCategory.wisdom:
        return 'Wisdom Literature';
      case PlanCategory.prophecy:
        return 'Prophecy';
    }
  }

  /// Get localized display name for the category
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case PlanCategory.completeBible:
        return l10n.categoryCompleteBible;
      case PlanCategory.newTestament:
        return l10n.categoryNewTestament;
      case PlanCategory.oldTestament:
        return l10n.categoryOldTestament;
      case PlanCategory.gospels:
        return l10n.categoryGospels;
      case PlanCategory.epistles:
        return l10n.categoryEpistles;
      case PlanCategory.psalms:
        return l10n.categoryPsalms;
      case PlanCategory.proverbs:
        return l10n.categoryProverbs;
      case PlanCategory.wisdom:
        return l10n.categoryWisdom;
      case PlanCategory.prophecy:
        return l10n.categoryProphecy;
    }
  }
}

extension PlanDifficultyExtension on PlanDifficulty {
  String get displayName {
    switch (this) {
      case PlanDifficulty.beginner:
        return 'Beginner';
      case PlanDifficulty.intermediate:
        return 'Intermediate';
      case PlanDifficulty.advanced:
        return 'Advanced';
    }
  }
}