import '../models/reading_plan.dart';
import 'database_service.dart';

class ReadingPlanService {
  final DatabaseService _database;

  ReadingPlanService(this._database);

  Future<List<ReadingPlan>> getAllPlans() async {
    final db = await _database.database;
    final maps = await db.query('reading_plans');
    return maps.map((map) => _planFromMap(map)).toList();
  }

  Future<List<ReadingPlan>> getActivePlans() async {
    final db = await _database.database;
    final maps = await db.query(
      'reading_plans',
      where: 'is_started = ?',
      whereArgs: [1],
    );
    return maps.map((map) => _planFromMap(map)).toList();
  }

  Future<ReadingPlan?> getCurrentPlan() async {
    final activePlans = await getActivePlans();
    return activePlans.isNotEmpty ? activePlans.first : null;
  }

  Future<void> startPlan(String planId) async {
    final db = await _database.database;

    // Stop all other plans
    await db.update(
      'reading_plans',
      {'is_started': 0},
      where: 'is_started = ?',
      whereArgs: [1],
    );

    // Start the selected plan
    await db.update(
      'reading_plans',
      {
        'is_started': 1,
        'start_date': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [planId],
    );
  }

  Future<void> stopPlan(String planId) async {
    final db = await _database.database;
    await db.update(
      'reading_plans',
      {'is_started': 0},
      where: 'id = ?',
      whereArgs: [planId],
    );
  }

  Future<void> updateProgress(String planId, int completedReadings) async {
    final db = await _database.database;
    await db.update(
      'reading_plans',
      {'completed_readings': completedReadings},
      where: 'id = ?',
      whereArgs: [planId],
    );
  }

  Future<List<DailyReading>> getTodaysReadings(String planId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final db = await _database.database;
    final maps = await db.query(
      'daily_readings',
      where: 'plan_id = ? AND date >= ? AND date < ?',
      whereArgs: [
        planId,
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );
    return maps.map((map) => _readingFromMap(map)).toList();
  }

  Future<List<DailyReading>> getReadingsForPlan(String planId) async {
    final db = await _database.database;
    final maps = await db.query(
      'daily_readings',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'date ASC',
    );
    return maps.map((map) => _readingFromMap(map)).toList();
  }

  Future<void> markReadingCompleted(String readingId) async {
    final db = await _database.database;
    await db.update(
      'daily_readings',
      {
        'is_completed': 1,
        'completed_date': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [readingId],
    );

    // Update plan progress
    final reading = await db.query(
      'daily_readings',
      where: 'id = ?',
      whereArgs: [readingId],
    );

    if (reading.isNotEmpty) {
      final planId = reading.first['plan_id'] as String;
      final completedCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ? AND is_completed = 1',
        [planId],
      );

      await updateProgress(planId, completedCount.first['count'] as int);
    }
  }

  Future<int> getCompletedReadingsCount(String planId) async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ? AND is_completed = 1',
      [planId],
    );
    return result.first['count'] as int;
  }

  ReadingPlan _planFromMap(Map<String, dynamic> map) {
    return ReadingPlan(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      duration: map['duration'],
      category: PlanCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => PlanCategory.completeBible,
      ),
      difficulty: PlanDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => PlanDifficulty.beginner,
      ),
      estimatedTimePerDay: map['estimated_time_per_day'],
      totalReadings: map['total_readings'],
      completedReadings: map['completed_readings'],
      isStarted: map['is_started'] == 1,
      startDate: map['start_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['start_date'])
          : null,
    );
  }

  DailyReading _readingFromMap(Map<String, dynamic> map) {
    return DailyReading(
      id: map['id'],
      planId: map['plan_id'],
      title: map['title'],
      description: map['description'],
      book: map['book'],
      chapters: map['chapters'],
      estimatedTime: map['estimated_time'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      isCompleted: map['is_completed'] == 1,
      completedDate: map['completed_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_date'])
          : null,
    );
  }
}