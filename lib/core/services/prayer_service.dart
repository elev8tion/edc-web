import 'package:uuid/uuid.dart';
import '../models/prayer_request.dart';
import 'database_service.dart';
import '../error/error_handler.dart';
import '../logging/app_logger.dart';
import 'achievement_service.dart';
import 'prayer_streak_service.dart';

class PrayerService {
  final DatabaseService _database;
  final AchievementService? _achievementService;
  final PrayerStreakService? _streakService;
  final Uuid _uuid = const Uuid();
  final AppLogger _logger = AppLogger.instance;

  PrayerService(
    this._database, {
    AchievementService? achievementService,
    PrayerStreakService? streakService,
  })  : _achievementService = achievementService,
        _streakService = streakService;

  Future<List<PrayerRequest>> getActivePrayers({String? categoryFilter}) async {
    return await ErrorHandler.handleAsync(
      () async {
        final db = await _database.database;

        String? where = 'is_answered = ?';
        List<dynamic> whereArgs = [0];

        if (categoryFilter != null && categoryFilter.isNotEmpty) {
          where = 'is_answered = ? AND category = ?';
          whereArgs = [0, categoryFilter];
        }

        final maps = await db.query(
          'prayer_requests',
          where: where,
          whereArgs: whereArgs,
          orderBy: 'date_created DESC',
        );

        _logger.debug('Retrieved ${maps.length} active prayers', context: 'PrayerService');
        return maps.map((map) => _prayerRequestFromMap(map)).toList();
      },
      context: 'PrayerService.getActivePrayers',
      fallbackValue: <PrayerRequest>[],
    );
  }

  Future<List<PrayerRequest>> getAnsweredPrayers({String? categoryFilter}) async {
    final db = await _database.database;

    String? where = 'is_answered = ?';
    List<dynamic> whereArgs = [1];

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      where = 'is_answered = ? AND category = ?';
      whereArgs = [1, categoryFilter];
    }

    final maps = await db.query(
      'prayer_requests',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date_answered DESC',
    );

    return maps.map((map) => _prayerRequestFromMap(map)).toList();
  }

  Future<List<PrayerRequest>> getAllPrayers({String? categoryFilter}) async {
    final db = await _database.database;

    String? where;
    List<dynamic>? whereArgs;

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      where = 'category = ?';
      whereArgs = [categoryFilter];
    }

    final maps = await db.query(
      'prayer_requests',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date_created DESC',
    );

    return maps.map((map) => _prayerRequestFromMap(map)).toList();
  }

  Future<List<PrayerRequest>> getPrayersByCategory(String categoryName) async {
    final db = await _database.database;
    final maps = await db.query(
      'prayer_requests',
      where: 'category = ?',
      whereArgs: [categoryName],
      orderBy: 'date_created DESC',
    );

    return maps.map((map) => _prayerRequestFromMap(map)).toList();
  }

  Future<void> addPrayer(PrayerRequest prayer) async {
    return await ErrorHandler.handleAsync(
      () async {
        final db = await _database.database;
        await db.insert('prayer_requests', _prayerRequestToMap(prayer));
        _logger.info('Added new prayer: ${prayer.title}', context: 'PrayerService');

        // Check for achievement completion
        await _checkPrayerAchievements();
      },
      context: 'PrayerService.addPrayer',
    );
  }

  /// Check prayer-based achievements after adding a prayer
  Future<void> _checkPrayerAchievements() async {
    if (_achievementService == null || _streakService == null) return;

    try {
      // Check Unbroken (7-day prayer streak)
      final streak = await _streakService!.getCurrentStreak();
      if (streak >= 7) {
        final completionCount = await _achievementService!.getCompletionCount(AchievementType.unbroken);
        // Only record if not already completed at this streak level
        if (completionCount == 0 || streak > completionCount * 7) {
          await _achievementService!.recordCompletion(
            type: AchievementType.unbroken,
            progressValue: streak,
          );
        }
      }

      // Check Relentless (50 total prayers)
      final totalPrayers = await getPrayerCount();
      if (totalPrayers >= 50) {
        final completionCount = await _achievementService!.getCompletionCount(AchievementType.relentless);
        // Only record if not already completed at this prayer count level
        if (completionCount == 0 || totalPrayers >= (completionCount + 1) * 50) {
          await _achievementService!.recordCompletion(
            type: AchievementType.relentless,
            progressValue: totalPrayers,
          );
        }
      }
    } catch (e) {
      _logger.error('Failed to check prayer achievements: $e', context: 'PrayerService');
    }
  }

  Future<void> updatePrayer(PrayerRequest prayer) async {
    final db = await _database.database;
    await db.update(
      'prayer_requests',
      _prayerRequestToMap(prayer),
      where: 'id = ?',
      whereArgs: [prayer.id],
    );
  }

  Future<void> deletePrayer(String id) async {
    return await ErrorHandler.handleAsync(
      () async {
        final db = await _database.database;
        await db.delete(
          'prayer_requests',
          where: 'id = ?',
          whereArgs: [id],
        );
        _logger.info('Deleted prayer: $id', context: 'PrayerService');
      },
      context: 'PrayerService.deletePrayer',
    );
  }

  Future<void> markPrayerAnswered(
    String id,
    String answerDescription,
  ) async {
    final db = await _database.database;
    await db.update(
      'prayer_requests',
      {
        'is_answered': 1,
        'date_answered': DateTime.now().millisecondsSinceEpoch,
        'answer_description': answerDescription,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<PrayerRequest> createPrayer({
    required String title,
    required String description,
    required String categoryId,
  }) async {
    final prayer = PrayerRequest(
      id: _uuid.v4(),
      title: title,
      description: description,
      categoryId: categoryId,
      dateCreated: DateTime.now(),
    );

    await addPrayer(prayer);
    return prayer;
  }

  Future<int> getPrayerCount() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM prayer_requests');
    return result.first['count'] as int;
  }

  Future<int> getAnsweredPrayerCount() async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_requests WHERE is_answered = 1',
    );
    return result.first['count'] as int;
  }

  PrayerRequest _prayerRequestFromMap(Map<String, dynamic> map) {
    return PrayerRequest(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      categoryId: map['category'] ?? 'cat_general',
      dateCreated: DateTime.fromMillisecondsSinceEpoch(map['date_created']),
      isAnswered: map['is_answered'] == 1,
      dateAnswered: map['date_answered'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_answered'])
          : null,
      answerDescription: map['answer_description'],
    );
  }

  Map<String, dynamic> _prayerRequestToMap(PrayerRequest prayer) {
    return {
      'id': prayer.id,
      'title': prayer.title,
      'description': prayer.description,
      'category': prayer.categoryId,
      'date_created': prayer.dateCreated.millisecondsSinceEpoch,
      'is_answered': prayer.isAnswered ? 1 : 0,
      'date_answered': prayer.dateAnswered?.millisecondsSinceEpoch,
      'answer_description': prayer.answerDescription,
    };
  }

  /// Export prayer journal as formatted text
  Future<String> exportPrayerJournal() async {
    try {
      final allPrayers = await getAllPrayers();
      final buffer = StringBuffer();

      buffer.writeln('Prayer Journal Export');
      buffer.writeln('Date: ${DateTime.now().toString().split('.')[0]}');
      buffer.writeln('Total Prayers: ${allPrayers.length}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      // Group prayers by status
      final activePrayers = allPrayers.where((p) => !p.isAnswered).toList();
      final answeredPrayers = allPrayers.where((p) => p.isAnswered).toList();

      // Active Prayers Section
      if (activePrayers.isNotEmpty) {
        buffer.writeln('ACTIVE PRAYERS (${activePrayers.length})');
        buffer.writeln('=' * 50);
        buffer.writeln();

        for (final prayer in activePrayers) {
          buffer.writeln('[${prayer.title}]');
          buffer.writeln('Category: ${prayer.categoryId}');
          buffer.writeln('Date Created: ${_formatDate(prayer.dateCreated)}');
          buffer.writeln();
          buffer.writeln(prayer.description);
          buffer.writeln();
          buffer.writeln('-' * 50);
          buffer.writeln();
        }
      }

      // Answered Prayers Section
      if (answeredPrayers.isNotEmpty) {
        buffer.writeln('ANSWERED PRAYERS (${answeredPrayers.length})');
        buffer.writeln('=' * 50);
        buffer.writeln();

        for (final prayer in answeredPrayers) {
          buffer.writeln('[${prayer.title}] ✓');
          buffer.writeln('Category: ${prayer.categoryId}');
          buffer.writeln('Date Created: ${_formatDate(prayer.dateCreated)}');
          if (prayer.dateAnswered != null) {
            buffer.writeln('Date Answered: ${_formatDate(prayer.dateAnswered!)}');
          }
          buffer.writeln();
          buffer.writeln('Request:');
          buffer.writeln(prayer.description);

          if (prayer.answerDescription != null && prayer.answerDescription!.isNotEmpty) {
            buffer.writeln();
            buffer.writeln('Answer:');
            buffer.writeln(prayer.answerDescription);
          }

          buffer.writeln();
          buffer.writeln('-' * 50);
          buffer.writeln();
        }
      }

      if (allPrayers.isEmpty) {
        buffer.writeln('No prayers in journal yet.');
      }

      _logger.info('Exported ${allPrayers.length} prayers', context: 'PrayerService');
      return buffer.toString();
    } catch (e) {
      _logger.error('Failed to export prayer journal: $e', context: 'PrayerService');
      return '';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}