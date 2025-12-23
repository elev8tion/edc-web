import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/core/services/reading_plan_service.dart';
import 'package:everyday_christian/core/services/database_service.dart';
import 'package:everyday_christian/core/models/reading_plan.dart';

void main() {
  group('ReadingPlanService Web Compilation Tests', () {
    test('Service instantiates with DatabaseService dependency', () {
      final dbService = DatabaseService();
      expect(() => ReadingPlanService(dbService), returnsNormally);
    });

    test('All public methods compile', () {
      final dbService = DatabaseService();
      final service = ReadingPlanService(dbService);

      // Plan management
      expect(service.getAllPlans, isA<Function>());
      expect(service.getActivePlans, isA<Function>());
      expect(service.getCurrentPlan, isA<Function>());
      expect(service.startPlan, isA<Function>());
      expect(service.stopPlan, isA<Function>());
      expect(service.updateProgress, isA<Function>());

      // Reading management
      expect(service.getTodaysReadings, isA<Function>());
      expect(service.getReadingsForPlan, isA<Function>());
      expect(service.markReadingCompleted, isA<Function>());
      expect(service.getCompletedReadingsCount, isA<Function>());
    });

    test('ReadingPlan model compilation', () {
      final plan = ReadingPlan(
        id: 'plan1',
        title: 'Test Plan',
        description: 'A test reading plan',
        duration: '30 days',
        category: PlanCategory.completeBible,
        difficulty: PlanDifficulty.beginner,
        estimatedTimePerDay: '15 mins',
        totalReadings: 30,
        completedReadings: 5,
        isStarted: true,
        startDate: DateTime.now(),
      );

      expect(plan.id, 'plan1');
      expect(plan.title, 'Test Plan');
      expect(plan.category, PlanCategory.completeBible);
      expect(plan.difficulty, PlanDifficulty.beginner);
      expect(plan.isStarted, true);
    });

    test('DailyReading model compilation', () {
      final reading = DailyReading(
        id: 'reading1',
        planId: 'plan1',
        title: 'Genesis 1',
        description: 'Creation story',
        book: 'Genesis',
        chapters: '1-2',
        estimatedTime: '10 mins',
        date: DateTime.now(),
        isCompleted: false,
      );

      expect(reading.id, 'reading1');
      expect(reading.planId, 'plan1');
      expect(reading.book, 'Genesis');
      expect(reading.isCompleted, false);
    });

    test('PlanCategory enum compilation', () {
      expect(PlanCategory.completeBible, isA<PlanCategory>());
      expect(PlanCategory.newTestament, isA<PlanCategory>());
      expect(PlanCategory.oldTestament, isA<PlanCategory>());
      expect(PlanCategory.gospels, isA<PlanCategory>());
      expect(PlanCategory.epistles, isA<PlanCategory>());
      expect(PlanCategory.psalms, isA<PlanCategory>());
      expect(PlanCategory.proverbs, isA<PlanCategory>());
      expect(PlanCategory.wisdom, isA<PlanCategory>());
      expect(PlanCategory.prophecy, isA<PlanCategory>());
    });

    test('PlanCategory displayName extension', () {
      expect(PlanCategory.completeBible.displayName, 'Complete Bible');
      expect(PlanCategory.newTestament.displayName, 'New Testament');
      expect(PlanCategory.gospels.displayName, 'Gospels');
      expect(PlanCategory.wisdom.displayName, 'Wisdom Literature');
    });

    test('PlanDifficulty enum compilation', () {
      expect(PlanDifficulty.beginner, isA<PlanDifficulty>());
      expect(PlanDifficulty.intermediate, isA<PlanDifficulty>());
      expect(PlanDifficulty.advanced, isA<PlanDifficulty>());
    });

    test('PlanDifficulty displayName extension', () {
      expect(PlanDifficulty.beginner.displayName, 'Beginner');
      expect(PlanDifficulty.intermediate.displayName, 'Intermediate');
      expect(PlanDifficulty.advanced.displayName, 'Advanced');
    });

    test('ReadingPlan JSON serialization', () {
      final plan = ReadingPlan(
        id: 'plan1',
        title: 'Test Plan',
        description: 'Description',
        duration: '30 days',
        category: PlanCategory.newTestament,
        difficulty: PlanDifficulty.beginner,
        estimatedTimePerDay: '15 mins',
        totalReadings: 30,
      );

      // toJson
      final json = plan.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], 'plan1');
      expect(json['title'], 'Test Plan');

      // fromJson
      final reconstructed = ReadingPlan.fromJson(json);
      expect(reconstructed.id, plan.id);
      expect(reconstructed.title, plan.title);
      expect(reconstructed.category, plan.category);
    });

    test('DailyReading JSON serialization', () {
      final reading = DailyReading(
        id: 'reading1',
        planId: 'plan1',
        title: 'Genesis 1',
        description: 'Creation',
        book: 'Genesis',
        chapters: '1',
        estimatedTime: '10 mins',
        date: DateTime.now(),
      );

      // toJson
      final json = reading.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], 'reading1');

      // fromJson
      final reconstructed = DailyReading.fromJson(json);
      expect(reconstructed.id, reading.id);
      expect(reconstructed.planId, reading.planId);
    });

    test('ReadingPlan copyWith functionality', () {
      final plan = ReadingPlan(
        id: 'plan1',
        title: 'Original',
        description: 'Desc',
        duration: '30 days',
        category: PlanCategory.completeBible,
        difficulty: PlanDifficulty.beginner,
        estimatedTimePerDay: '15 mins',
        totalReadings: 30,
      );

      final modified = plan.copyWith(
        title: 'Modified',
        completedReadings: 10,
      );

      expect(modified.title, 'Modified');
      expect(modified.completedReadings, 10);
      expect(modified.id, plan.id);
      expect(modified.category, plan.category);
    });
  });
}
