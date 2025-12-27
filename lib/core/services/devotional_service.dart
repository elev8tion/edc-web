import '../models/devotional.dart';
import 'database_service.dart';

class DevotionalService {
  final DatabaseService _database;

  DevotionalService(this._database);

  Future<List<Devotional>> getAllDevotionals() async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        'devotionals',
        orderBy: 'date ASC',
      );
      return List<Devotional>.from(maps.map((map) => _devotionalFromMap(map)));
    } catch (e) {
      throw Exception('Failed to get all devotionals: $e');
    }
  }

  Future<Devotional?> getTodaysDevotional() async {
    try {
      final today = DateTime.now();
      final todayString = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final db = await _database.database;
      final maps = await db.query(
        'devotionals',
        where: 'date = ?',
        whereArgs: [todayString],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _devotionalFromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get today\'s devotional: $e');
    }
  }

  Future<List<Devotional>> getCompletedDevotionals() async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        'devotionals',
        where: 'is_completed = ?',
        whereArgs: [1],
        orderBy: 'completed_date DESC',
      );
      return List<Devotional>.from(maps.map((map) => _devotionalFromMap(map)));
    } catch (e) {
      throw Exception('Failed to get completed devotionals: $e');
    }
  }

  Future<void> markDevotionalCompleted(String id) async {
    try {
      final db = await _database.database;
      await db.update(
        'devotionals',
        {
          'is_completed': 1,
          'completed_date': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to mark devotional completed: $e');
    }
  }

  Future<void> markDevotionalIncomplete(String id) async {
    try {
      final db = await _database.database;
      await db.update(
        'devotionals',
        {
          'is_completed': 0,
          'completed_date': null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to mark devotional incomplete: $e');
    }
  }

  Future<void> toggleActionStepCompleted(String id, bool completed) async {
    try {
      final db = await _database.database;
      await db.update(
        'devotionals',
        {
          'action_step_completed': completed ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to toggle action step: $e');
    }
  }

  Future<int> getCompletedCount() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM devotionals WHERE is_completed = 1',
      );
      return result.isEmpty ? 0 : (result.first['count'] as int? ?? 0);
    } catch (e) {
      throw Exception('Failed to get completed count: $e');
    }
  }

  Future<int> getCurrentStreak() async {
    try {
      final devotionals = await getCompletedDevotionals();
      if (devotionals.isEmpty) return 0;

      int streak = 0;
      DateTime? lastDate;

      for (final devotional in devotionals) {
        if (devotional.completedDate == null) continue;

        final completedDate = devotional.completedDate!;
        final dayOnly = DateTime(
          completedDate.year,
          completedDate.month,
          completedDate.day,
        );

        if (lastDate == null) {
          lastDate = dayOnly;
          streak = 1;
        } else {
          final expectedDate = lastDate.subtract(const Duration(days: 1));
          if (dayOnly == expectedDate) {
            streak++;
            lastDate = dayOnly;
          } else {
            break;
          }
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  Devotional _devotionalFromMap(Map<String, dynamic> map) {
    return Devotional(
      id: map['id'],
      date: map['date'],
      title: map['title'],
      openingScriptureReference: map['opening_scripture_reference'],
      openingScriptureText: map['opening_scripture_text'],
      keyVerseReference: map['key_verse_reference'],
      keyVerseText: map['key_verse_text'],
      reflection: map['reflection'],
      lifeApplication: map['life_application'],
      prayer: map['prayer'],
      actionStep: map['action_step'],
      goingDeeper: (map['going_deeper'] as String).split('|||'),
      readingTime: map['reading_time'],
      isCompleted: map['is_completed'] == 1,
      completedDate: map['completed_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_date'])
          : null,
      actionStepCompleted: map['action_step_completed'] == 1,
    );
  }
}