import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/core/services/prayer_service.dart';
import 'package:everyday_christian/core/services/database_service.dart';
import 'package:everyday_christian/core/models/prayer_request.dart';

void main() {
  late PrayerService prayerService;
  late DatabaseService databaseService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize database for web platform
    databaseService = DatabaseService();
    await databaseService.initialize();

    // Create PrayerService instance
    prayerService = PrayerService(databaseService);
  });

  tearDownAll(() async {
    await databaseService.close();
  });

  group('PrayerService Web Platform Tests', () {
    group('Database Initialization', () {
      test('Database is initialized', () async {
        final db = await databaseService.database;
        expect(db, isNotNull);
      });

      test('Prayer tables exist', () async {
        final db = await databaseService.database;

        // Query each prayer table to verify they exist
        final prayerRequests = await db.query('prayer_requests');
        final prayerCategories = await db.query('prayer_categories');
        final streakActivity = await db.query('prayer_streak_activity');
        final sharedPrayers = await db.query('shared_prayers');

        expect(prayerRequests, isList);
        expect(prayerCategories, isList);
        expect(streakActivity, isList);
        expect(sharedPrayers, isList);
      });
    });

    group('CREATE Operations (INSERT)', () {
      test('Create prayer with createPrayer method', () async {
        final prayer = await prayerService.createPrayer(
          title: 'Web Test Prayer',
          description: 'Testing prayer creation on web platform',
          categoryId: 'cat_general',
        );

        expect(prayer, isNotNull);
        expect(prayer.id, isNotEmpty);
        expect(prayer.title, 'Web Test Prayer');
        expect(prayer.description, 'Testing prayer creation on web platform');
        expect(prayer.categoryId, 'cat_general');
        expect(prayer.isAnswered, false);
        expect(prayer.dateCreated, isNotNull);
      });

      test('Create prayer with addPrayer method', () async {
        final prayer = PrayerRequest(
          id: 'test-prayer-1',
          title: 'Manual Prayer Creation',
          description: 'Created using addPrayer method',
          categoryId: 'cat_general',
          dateCreated: DateTime.now(),
        );

        await prayerService.addPrayer(prayer);

        final prayers = await prayerService.getAllPrayers();
        final found = prayers.any((p) => p.id == 'test-prayer-1');
        expect(found, true);
      });

      test('Create multiple prayers in sequence', () async {
        final initialCount = await prayerService.getPrayerCount();

        for (int i = 0; i < 5; i++) {
          await prayerService.createPrayer(
            title: 'Batch Prayer $i',
            description: 'Testing batch creation',
            categoryId: 'cat_general',
          );
        }

        final finalCount = await prayerService.getPrayerCount();
        expect(finalCount, greaterThanOrEqualTo(initialCount + 5));
      });
    });

    group('READ Operations (QUERY)', () {
      test('Get all prayers', () async {
        final prayers = await prayerService.getAllPrayers();
        expect(prayers, isList);

        // Verify each prayer has required fields
        if (prayers.isNotEmpty) {
          final prayer = prayers.first;
          expect(prayer.id, isNotEmpty);
          expect(prayer.title, isNotEmpty);
          expect(prayer.description, isNotEmpty);
          expect(prayer.categoryId, isNotEmpty);
          expect(prayer.dateCreated, isNotNull);
        }
      });

      test('Get active prayers only', () async {
        // Create an unanswered prayer
        await prayerService.createPrayer(
          title: 'Active Prayer Test',
          description: 'This should appear in active prayers',
          categoryId: 'cat_general',
        );

        final activePrayers = await prayerService.getActivePrayers();
        expect(activePrayers, isList);

        // All prayers should be unanswered
        for (final prayer in activePrayers) {
          expect(prayer.isAnswered, false);
        }
      });

      test('Get answered prayers only', () async {
        // Create and answer a prayer
        final prayer = await prayerService.createPrayer(
          title: 'Prayer to be answered',
          description: 'Will be marked as answered',
          categoryId: 'cat_general',
        );

        await prayerService.markPrayerAnswered(
          prayer.id,
          'Test answer description',
        );

        final answeredPrayers = await prayerService.getAnsweredPrayers();

        // All prayers should be answered
        for (final p in answeredPrayers) {
          expect(p.isAnswered, true);
        }

        // Find our specific prayer
        final found = answeredPrayers.any((p) => p.id == prayer.id);
        expect(found, true);
      });

      test('Get prayers by category', () async {
        // Create prayer with specific category
        await prayerService.createPrayer(
          title: 'Health Prayer',
          description: 'Testing category filter',
          categoryId: 'cat_health',
        );

        final healthPrayers = await prayerService.getPrayersByCategory('cat_health');
        expect(healthPrayers, isNotEmpty);

        // All prayers should be in health category
        for (final prayer in healthPrayers) {
          expect(prayer.categoryId, 'cat_health');
        }
      });

      test('Filter active prayers by category', () async {
        await prayerService.createPrayer(
          title: 'Family Prayer',
          description: 'Testing category filter on active prayers',
          categoryId: 'cat_family',
        );

        final familyPrayers = await prayerService.getActivePrayers(
          categoryFilter: 'cat_family',
        );

        for (final prayer in familyPrayers) {
          expect(prayer.categoryId, 'cat_family');
          expect(prayer.isAnswered, false);
        }
      });

      test('Get prayer count', () async {
        final count = await prayerService.getPrayerCount();
        expect(count, isA<int>());
        expect(count, greaterThanOrEqualTo(0));
      });

      test('Get answered prayer count', () async {
        final count = await prayerService.getAnsweredPrayerCount();
        expect(count, isA<int>());
        expect(count, greaterThanOrEqualTo(0));
      });
    });

    group('UPDATE Operations', () {
      test('Update prayer details', () async {
        // Create a prayer
        final prayer = await prayerService.createPrayer(
          title: 'Original Title',
          description: 'Original description',
          categoryId: 'cat_general',
        );

        // Update it
        final updatedPrayer = prayer.copyWith(
          title: 'Updated Title',
          description: 'Updated description',
          categoryId: 'cat_family',
        );

        await prayerService.updatePrayer(updatedPrayer);

        // Verify update
        final prayers = await prayerService.getAllPrayers();
        final found = prayers.firstWhere((p) => p.id == prayer.id);

        expect(found.title, 'Updated Title');
        expect(found.description, 'Updated description');
        expect(found.categoryId, 'cat_family');
      });

      test('Mark prayer as answered', () async {
        final prayer = await prayerService.createPrayer(
          title: 'Prayer to Answer',
          description: 'Will be marked answered',
          categoryId: 'cat_general',
        );

        final beforeAnswer = DateTime.now();

        await prayerService.markPrayerAnswered(
          prayer.id,
          'God provided in an amazing way!',
        );

        // Retrieve and verify
        final prayers = await prayerService.getAllPrayers();
        final answered = prayers.firstWhere((p) => p.id == prayer.id);

        expect(answered.isAnswered, true);
        expect(answered.answerDescription, 'God provided in an amazing way!');
        expect(answered.dateAnswered, isNotNull);
        expect(
          answered.dateAnswered!.isAfter(beforeAnswer.subtract(const Duration(seconds: 1))),
          true,
        );
      });
    });

    group('DELETE Operations', () {
      test('Delete prayer by ID', () async {
        // Create a prayer
        final prayer = await prayerService.createPrayer(
          title: 'Prayer to Delete',
          description: 'Will be deleted',
          categoryId: 'cat_general',
        );

        // Delete it
        await prayerService.deletePrayer(prayer.id);

        // Verify deletion
        final prayers = await prayerService.getAllPrayers();
        final found = prayers.any((p) => p.id == prayer.id);
        expect(found, false);
      });

      test('Delete answered prayer', () async {
        final prayer = await prayerService.createPrayer(
          title: 'Answered Prayer to Delete',
          description: 'Will be answered then deleted',
          categoryId: 'cat_general',
        );

        await prayerService.markPrayerAnswered(prayer.id, 'Answered!');
        await prayerService.deletePrayer(prayer.id);

        final prayers = await prayerService.getAllPrayers();
        final found = prayers.any((p) => p.id == prayer.id);
        expect(found, false);
      });
    });

    group('Data Types and NULL Handling', () {
      test('Handle NULL dateAnswered correctly', () async {
        final prayer = await prayerService.createPrayer(
          title: 'Unanswered Prayer',
          description: 'Should have NULL dateAnswered',
          categoryId: 'cat_general',
        );

        final prayers = await prayerService.getAllPrayers();
        final found = prayers.firstWhere((p) => p.id == prayer.id);

        expect(found.dateAnswered, isNull);
        expect(found.answerDescription, isNull);
      });

      test('Handle NULL answerDescription correctly', () async {
        final prayer = await prayerService.createPrayer(
          title: 'Prayer to Answer',
          description: 'Will be answered without description',
          categoryId: 'cat_general',
        );

        // Mark answered with empty description
        await prayerService.markPrayerAnswered(prayer.id, '');

        final prayers = await prayerService.getAllPrayers();
        final found = prayers.firstWhere((p) => p.id == prayer.id);

        expect(found.answerDescription, '');
        expect(found.dateAnswered, isNotNull);
      });

      test('DateTime millisecondsSinceEpoch conversion', () async {
        final beforeCreate = DateTime.now();

        final prayer = await prayerService.createPrayer(
          title: 'DateTime Test',
          description: 'Testing date conversion',
          categoryId: 'cat_general',
        );

        final afterCreate = DateTime.now();

        expect(
          prayer.dateCreated.isAfter(beforeCreate.subtract(const Duration(seconds: 1))),
          true,
        );
        expect(
          prayer.dateCreated.isBefore(afterCreate.add(const Duration(seconds: 1))),
          true,
        );
      });

      test('Boolean to INTEGER conversion (is_answered)', () async {
        final prayer = await prayerService.createPrayer(
          title: 'Boolean Test',
          description: 'Testing boolean conversion',
          categoryId: 'cat_general',
        );

        // Verify unanswered (false -> 0)
        final db = await databaseService.database;
        var result = await db.query(
          'prayer_requests',
          where: 'id = ?',
          whereArgs: [prayer.id],
        );
        expect(result.first['is_answered'], 0);

        // Answer the prayer
        await prayerService.markPrayerAnswered(prayer.id, 'Answered');

        // Verify answered (true -> 1)
        result = await db.query(
          'prayer_requests',
          where: 'id = ?',
          whereArgs: [prayer.id],
        );
        expect(result.first['is_answered'], 1);
      });
    });

    group('Export Functionality', () {
      test('Export prayer journal', () async {
        // Create some test data
        await prayerService.createPrayer(
          title: 'Export Test 1',
          description: 'Active prayer for export',
          categoryId: 'cat_general',
        );

        final answered = await prayerService.createPrayer(
          title: 'Export Test 2',
          description: 'Answered prayer for export',
          categoryId: 'cat_family',
        );
        await prayerService.markPrayerAnswered(answered.id, 'Praise God!');

        final export = await prayerService.exportPrayerJournal();

        expect(export, isNotEmpty);
        expect(export, contains('Prayer Journal Export'));
        expect(export, contains('Total Prayers:'));
        expect(export, contains('ACTIVE PRAYERS'));
        expect(export, contains('Export Test 1'));

        if (export.contains('ANSWERED PRAYERS')) {
          expect(export, contains('Export Test 2'));
          expect(export, contains('Praise God!'));
        }
      });

      test('Export empty journal', () async {
        // Reset database
        await databaseService.resetDatabase();
        await databaseService.initialize();

        final service = PrayerService(databaseService);
        final export = await service.exportPrayerJournal();

        expect(export, contains('No prayers in journal yet'));
      });
    });

    group('Performance Tests', () {
      test('Bulk insert performance', () async {
        final stopwatch = Stopwatch()..start();

        // Create 50 prayers
        for (int i = 0; i < 50; i++) {
          await prayerService.createPrayer(
            title: 'Performance Test Prayer $i',
            description: 'Testing bulk insert performance on web',
            categoryId: 'cat_general',
          );
        }

        stopwatch.stop();

        print('50 prayer inserts: ${stopwatch.elapsedMilliseconds}ms');

        // Should complete in reasonable time (< 10 seconds for web)
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });

      test('Query performance with many records', () async {
        final stopwatch = Stopwatch()..start();

        // Query all prayers multiple times
        for (int i = 0; i < 10; i++) {
          await prayerService.getAllPrayers();
        }

        stopwatch.stop();

        print('10 queries: ${stopwatch.elapsedMilliseconds}ms');

        // Should be fast even with many records
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('Update performance', () async {
        // Create a prayer
        final prayer = await prayerService.createPrayer(
          title: 'Update Performance Test',
          description: 'Original',
          categoryId: 'cat_general',
        );

        final stopwatch = Stopwatch()..start();

        // Update it 20 times
        for (int i = 0; i < 20; i++) {
          final updated = prayer.copyWith(
            description: 'Updated $i times',
          );
          await prayerService.updatePrayer(updated);
        }

        stopwatch.stop();

        print('20 updates: ${stopwatch.elapsedMilliseconds}ms');

        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Create prayer with empty strings', () async {
        final prayer = await prayerService.createPrayer(
          title: '',
          description: '',
          categoryId: 'cat_general',
        );

        expect(prayer.title, '');
        expect(prayer.description, '');
      });

      test('Create prayer with special characters', () async {
        final prayer = await prayerService.createPrayer(
          title: 'Prayer with "quotes" and \'apostrophes\'',
          description: 'Special chars: <>&\'"\\n\\t',
          categoryId: 'cat_general',
        );

        final prayers = await prayerService.getAllPrayers();
        final found = prayers.firstWhere((p) => p.id == prayer.id);

        expect(found.title, contains('quotes'));
        expect(found.title, contains('apostrophes'));
        expect(found.description, contains('Special chars'));
      });

      test('Create prayer with very long text', () async {
        final longText = 'A' * 10000; // 10k characters

        final prayer = await prayerService.createPrayer(
          title: 'Long Text Test',
          description: longText,
          categoryId: 'cat_general',
        );

        final prayers = await prayerService.getAllPrayers();
        final found = prayers.firstWhere((p) => p.id == prayer.id);

        expect(found.description.length, 10000);
      });

      test('Update non-existent prayer', () async {
        final fakePrayer = PrayerRequest(
          id: 'non-existent-id',
          title: 'Fake',
          description: 'Does not exist',
          categoryId: 'cat_general',
          dateCreated: DateTime.now(),
        );

        // Should not throw, but also should not affect database
        await prayerService.updatePrayer(fakePrayer);

        final prayers = await prayerService.getAllPrayers();
        final found = prayers.any((p) => p.id == 'non-existent-id');
        expect(found, false);
      });

      test('Delete non-existent prayer', () async {
        // Should not throw
        await prayerService.deletePrayer('non-existent-id');
      });

      test('Category filter with non-existent category', () async {
        final prayers = await prayerService.getPrayersByCategory('cat_nonexistent');
        expect(prayers, isEmpty);
      });
    });

    group('Platform Consistency Tests', () {
      test('Prayer data structure consistency', () async {
        final prayer = await prayerService.createPrayer(
          title: 'Consistency Test',
          description: 'Testing data structure',
          categoryId: 'cat_general',
        );

        // Verify all required fields exist
        expect(prayer.id, isA<String>());
        expect(prayer.title, isA<String>());
        expect(prayer.description, isA<String>());
        expect(prayer.categoryId, isA<String>());
        expect(prayer.dateCreated, isA<DateTime>());
        expect(prayer.isAnswered, isA<bool>());
      });

      test('Query results return consistent types', () async {
        await prayerService.createPrayer(
          title: 'Type Test',
          description: 'Testing type consistency',
          categoryId: 'cat_general',
        );

        final prayers = await prayerService.getAllPrayers();

        for (final prayer in prayers) {
          expect(prayer.id, isA<String>());
          expect(prayer.title, isA<String>());
          expect(prayer.description, isA<String>());
          expect(prayer.categoryId, isA<String>());
          expect(prayer.dateCreated, isA<DateTime>());
          expect(prayer.isAnswered, isA<bool>());

          if (prayer.isAnswered) {
            if (prayer.dateAnswered != null) {
              expect(prayer.dateAnswered, isA<DateTime>());
            }
          }
        }
      });

      test('Ordering consistency (DESC by date_created)', () async {
        // Create prayers with slight delays
        final prayer1 = await prayerService.createPrayer(
          title: 'First Prayer',
          description: 'Created first',
          categoryId: 'cat_general',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final prayer2 = await prayerService.createPrayer(
          title: 'Second Prayer',
          description: 'Created second',
          categoryId: 'cat_general',
        );

        final prayers = await prayerService.getAllPrayers();

        // Find indices
        final index1 = prayers.indexWhere((p) => p.id == prayer1.id);
        final index2 = prayers.indexWhere((p) => p.id == prayer2.id);

        // Second prayer should come before first (DESC order)
        expect(index2, lessThan(index1));
      });
    });
  });
}
