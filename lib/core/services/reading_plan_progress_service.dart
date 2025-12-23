import 'package:flutter/foundation.dart';
import '../models/reading_plan.dart';
import 'database_service.dart';
import 'reading_plan_generator.dart';
import 'achievement_service.dart';

/// Service for tracking reading plan progress
class ReadingPlanProgressService {
  final DatabaseService _database;
  final AchievementService? _achievementService;
  late final ReadingPlanGenerator _generator;

  ReadingPlanProgressService(
    this._database, {
    AchievementService? achievementService,
  })  : _achievementService = achievementService {
    _generator = ReadingPlanGenerator(_database);
  }

  /// Mark a specific day/reading as complete
  Future<void> markDayComplete(String readingId) async {
    try {
      final db = await _database.database;
      final now = DateTime.now();

      // Update the daily reading
      await db.update(
        'daily_readings',
        {
          'is_completed': 1,
          'completed_date': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [readingId],
      );

      // Get the reading to find its plan
      final readings = await db.query(
        'daily_readings',
        where: 'id = ?',
        whereArgs: [readingId],
      );

      if (readings.isNotEmpty) {
        final planId = readings.first['plan_id'] as String;
        await _updatePlanProgress(planId);
      }
    } catch (e) {
      throw Exception('Failed to mark day complete: $e');
    }
  }

  /// Mark a day as incomplete (undo completion)
  Future<void> markDayIncomplete(String readingId) async {
    try {
      final db = await _database.database;

      // Get the reading to find its plan before updating
      final readings = await db.query(
        'daily_readings',
        where: 'id = ?',
        whereArgs: [readingId],
      );

      if (readings.isEmpty) return;

      final planId = readings.first['plan_id'] as String;

      // Update the daily reading
      await db.update(
        'daily_readings',
        {
          'is_completed': 0,
          'completed_date': null,
        },
        where: 'id = ?',
        whereArgs: [readingId],
      );

      await _updatePlanProgress(planId);
    } catch (e) {
      throw Exception('Failed to mark day incomplete: $e');
    }
  }

  /// Get progress percentage for a plan (0-100)
  Future<double> getProgressPercentage(String planId) async {
    try {
      final db = await _database.database;

      // Get total readings count from daily_readings table (actual readings created)
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ?',
        [planId],
      );

      final totalReadings = totalResult.first['count'] as int;
      if (totalReadings == 0) return 0.0;

      // Get completed readings count
      final completedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ? AND is_completed = 1',
        [planId],
      );

      final completedCount = completedResult.first['count'] as int;
      return (completedCount / totalReadings) * 100;
    } catch (e) {
      throw Exception('Failed to get progress percentage: $e');
    }
  }

  /// Get current day number in the plan
  Future<int> getCurrentDay(String planId) async {
    try {
      final db = await _database.database;

      // Get plan start date
      final plans = await db.query(
        'reading_plans',
        where: 'id = ?',
        whereArgs: [planId],
      );

      if (plans.isEmpty || plans.first['start_date'] == null) return 1;

      final startDate = DateTime.fromMillisecondsSinceEpoch(
        plans.first['start_date'] as int,
      );
      final today = DateTime.now();
      final daysSinceStart = today.difference(startDate).inDays;

      return daysSinceStart + 1; // Day 1, not Day 0
    } catch (e) {
      throw Exception('Failed to get current day: $e');
    }
  }

  /// Reset a plan (delete all readings and reset progress)
  Future<void> resetPlan(String planId) async {
    try {
      final db = await _database.database;

      // Delete all daily readings for this plan
      await db.delete(
        'daily_readings',
        where: 'plan_id = ?',
        whereArgs: [planId],
      );

      // Reset plan progress
      await db.update(
        'reading_plans',
        {
          'completed_readings': 0,
          'is_started': 0,
          'start_date': null,
        },
        where: 'id = ?',
        whereArgs: [planId],
      );
    } catch (e) {
      throw Exception('Failed to reset plan: $e');
    }
  }

  /// Get all completed readings for a plan
  Future<List<DailyReading>> getCompletedReadings(String planId) async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        'daily_readings',
        where: 'plan_id = ? AND is_completed = 1',
        whereArgs: [planId],
        orderBy: 'completed_date DESC',
      );

      return maps.map((map) => _readingFromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get completed readings: $e');
    }
  }

  /// Get all incomplete readings for a plan
  Future<List<DailyReading>> getIncompleteReadings(String planId) async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        'daily_readings',
        where: 'plan_id = ? AND is_completed = 0',
        whereArgs: [planId],
        orderBy: 'date ASC',
      );

      return maps.map((map) => _readingFromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get incomplete readings: $e');
    }
  }

  /// Get today's readings for a plan
  Future<List<DailyReading>> getTodaysReadings(String planId) async {
    try {
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
    } catch (e) {
      throw Exception('Failed to get today\'s readings: $e');
    }
  }

  /// Generate readings for a plan based on its category (NEW - uses real Bible data)
  Future<void> generateReadingsForPlan(String planId, PlanCategory category, int totalDays, {String language = 'en'}) async {
    try {
      await _generator.generateReadingsForPlan(planId, category, totalDays, language: language);
    } catch (e) {
      throw Exception('Failed to generate readings for plan: $e');
    }
  }

  /// Get reading streak (consecutive days completed)
  Future<int> getStreak(String planId) async {
    try {
      final db = await _database.database;
      final readings = await db.query(
        'daily_readings',
        where: 'plan_id = ? AND is_completed = 1',
        whereArgs: [planId],
        orderBy: 'completed_date DESC',
      );

      if (readings.isEmpty) return 0;

      int streak = 0;
      DateTime? lastDate;

      for (final reading in readings) {
        final completedDate = DateTime.fromMillisecondsSinceEpoch(
          reading['completed_date'] as int,
        );

        if (lastDate == null) {
          // First completed reading
          streak = 1;
          lastDate = completedDate;
        } else {
          // Check if consecutive
          final daysDifference = lastDate.difference(completedDate).inDays;
          if (daysDifference == 1) {
            streak++;
            lastDate = completedDate;
          } else {
            // Streak broken
            break;
          }
        }
      }

      // Validate if streak is still active (most recent completion within last day)
      if (lastDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final mostRecentDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final daysSinceMostRecent = today.difference(mostRecentDay).inDays;

        if (daysSinceMostRecent > 1) {
          return 0; // Streak is no longer active
        }
      }

      return streak;
    } catch (e) {
      throw Exception('Failed to get streak: $e');
    }
  }

  /// Get calendar heatmap data for a plan (last 30 days by default)
  /// Returns a map of dates to completion counts for that date
  Future<Map<DateTime, int>> getCalendarHeatmapData(String planId, {int days = 30}) async {
    try {
      final db = await _database.database;
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final readings = await db.query(
        'daily_readings',
        where: 'plan_id = ? AND completed_date >= ?',
        whereArgs: [planId, startDate.millisecondsSinceEpoch],
      );

      final Map<DateTime, int> heatmapData = {};

      for (final reading in readings) {
        if (reading['completed_date'] != null) {
          final completedDate = DateTime.fromMillisecondsSinceEpoch(
            reading['completed_date'] as int,
          );
          // Normalize to start of day
          final normalizedDate = DateTime(
            completedDate.year,
            completedDate.month,
            completedDate.day,
          );

          heatmapData[normalizedDate] = (heatmapData[normalizedDate] ?? 0) + 1;
        }
      }

      return heatmapData;
    } catch (e) {
      throw Exception('Failed to get heatmap data: $e');
    }
  }

  /// Get completion statistics for a plan
  Future<Map<String, dynamic>> getCompletionStats(String planId) async {
    try {
      final db = await _database.database;

      // Get total and completed readings
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ?',
        [planId],
      );
      final total = totalResult.first['count'] as int;

      final completedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ? AND is_completed = 1',
        [planId],
      );
      final completed = completedResult.first['count'] as int;

      // Get current streak
      final streak = await getStreak(planId);

      // Get longest streak
      final longestStreak = await _getLongestStreak(planId);

      // Get total days active (days with at least one completion)
      final heatmapData = await getCalendarHeatmapData(planId, days: 365);
      final totalDaysActive = heatmapData.length;

      // Calculate average completions per day (when active)
      final averagePerDay = totalDaysActive > 0 ? completed / totalDaysActive : 0.0;

      return {
        'total_readings': total,
        'completed_readings': completed,
        'incomplete_readings': total - completed,
        'progress_percentage': total > 0 ? (completed / total) * 100 : 0.0,
        'current_streak': streak,
        'longest_streak': longestStreak,
        'total_days_active': totalDaysActive,
        'average_per_day': averagePerDay,
      };
    } catch (e) {
      throw Exception('Failed to get completion stats: $e');
    }
  }

  /// Get the longest streak achieved for a plan
  Future<int> _getLongestStreak(String planId) async {
    try {
      final db = await _database.database;
      final readings = await db.query(
        'daily_readings',
        where: 'plan_id = ? AND is_completed = 1',
        whereArgs: [planId],
        orderBy: 'completed_date ASC',
      );

      if (readings.isEmpty) return 0;

      int longestStreak = 0;
      int currentStreak = 1;
      DateTime? lastDate;

      for (final reading in readings) {
        final completedDate = DateTime.fromMillisecondsSinceEpoch(
          reading['completed_date'] as int,
        );

        if (lastDate == null) {
          lastDate = completedDate;
        } else {
          final daysDifference = completedDate.difference(lastDate).inDays;
          if (daysDifference == 1) {
            currentStreak++;
          } else {
            longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
            currentStreak = 1;
          }
          lastDate = completedDate;
        }
      }

      // Check final streak
      longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;

      return longestStreak;
    } catch (e) {
      throw Exception('Failed to get longest streak: $e');
    }
  }

  /// Get missed days (days between start and today where reading was scheduled but not completed)
  Future<List<DateTime>> getMissedDays(String planId) async {
    try {
      final db = await _database.database;

      // Get plan start date
      final plans = await db.query(
        'reading_plans',
        where: 'id = ?',
        whereArgs: [planId],
      );

      if (plans.isEmpty || plans.first['start_date'] == null) return [];

      final today = DateTime.now();

      // Get all readings scheduled before today
      final readings = await db.query(
        'daily_readings',
        where: 'plan_id = ? AND date < ?',
        whereArgs: [planId, today.millisecondsSinceEpoch],
        orderBy: 'date ASC',
      );

      final missedDays = <DateTime>[];

      for (final reading in readings) {
        final scheduledDate = DateTime.fromMillisecondsSinceEpoch(
          reading['date'] as int,
        );
        final isCompleted = reading['is_completed'] == 1;

        // If scheduled date is in the past and not completed, it's missed
        if (!isCompleted && scheduledDate.isBefore(today)) {
          missedDays.add(DateTime(
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
          ));
        }
      }

      return missedDays;
    } catch (e) {
      throw Exception('Failed to get missed days: $e');
    }
  }

  /// Get weekly completion rate (last 7 days)
  Future<double> getWeeklyCompletionRate(String planId) async {
    try {
      final db = await _database.database;
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      // Get readings scheduled in the last 7 days
      final scheduledResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ? AND date >= ?',
        [planId, weekAgo.millisecondsSinceEpoch],
      );
      final scheduled = scheduledResult.first['count'] as int;

      if (scheduled == 0) return 0.0;

      // Get completed readings in the last 7 days
      final completedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ? AND date >= ? AND is_completed = 1',
        [planId, weekAgo.millisecondsSinceEpoch],
      );
      final completed = completedResult.first['count'] as int;

      return (completed / scheduled) * 100;
    } catch (e) {
      throw Exception('Failed to get weekly completion rate: $e');
    }
  }

  /// Get estimated completion date based on current pace
  Future<DateTime?> getEstimatedCompletionDate(String planId) async {
    try {
      final db = await _database.database;

      // Get plan start date
      final plans = await db.query(
        'reading_plans',
        where: 'id = ?',
        whereArgs: [planId],
      );

      if (plans.isEmpty || plans.first['start_date'] == null) return null;

      final startDate = DateTime.fromMillisecondsSinceEpoch(
        plans.first['start_date'] as int,
      );

      // Get total readings
      final totalReadings = plans.first['total_readings'] as int;

      // Get completed readings count
      final completedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ? AND is_completed = 1',
        [planId],
      );
      final completed = completedResult.first['count'] as int;

      if (completed == 0) {
        // No progress yet, can't estimate
        return null;
      }

      final now = DateTime.now();
      final daysSinceStart = now.difference(startDate).inDays;

      if (daysSinceStart == 0) {
        // Started today, can't estimate pace yet
        return null;
      }

      // Calculate average readings per day
      final averagePerDay = completed / daysSinceStart;

      if (averagePerDay == 0) return null;

      // Calculate remaining readings and days needed
      final remainingReadings = totalReadings - completed;
      final daysNeeded = (remainingReadings / averagePerDay).ceil();

      return now.add(Duration(days: daysNeeded));
    } catch (e) {
      throw Exception('Failed to get estimated completion date: $e');
    }
  }

  /// Internal method to update plan progress
  Future<void> _updatePlanProgress(String planId) async {
    final db = await _database.database;

    // Count completed readings
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM daily_readings WHERE plan_id = ? AND is_completed = 1',
      [planId],
    );

    final completedCount = (result.first['count'] as int?) ?? 0;

    // Check if plan is now complete
    final planResult = await db.query(
      'reading_plans',
      where: 'id = ?',
      whereArgs: [planId],
      limit: 1,
    );

    if (planResult.isNotEmpty) {
      final totalReadings = (planResult.first['total_readings'] as int?) ?? 0;
      final wasCompleted = (planResult.first['is_completed'] as int?) == 1;
      final isNowComplete = completedCount >= totalReadings;

      // Update plan with completion status
      await db.update(
        'reading_plans',
        {
          'completed_readings': completedCount,
          'is_completed': isNowComplete ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [planId],
      );

      // Check for Deep Diver achievement if plan just completed
      if (isNowComplete && !wasCompleted) {
        await _checkReadingPlanAchievements();
      }
    }
  }

  /// Check reading plan achievements after completing a plan
  Future<void> _checkReadingPlanAchievements() async {
    if (_achievementService == null) return;

    try {
      // Check Deep Diver (5 reading plans completed)
      final db = await _database.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM reading_plans WHERE is_completed = 1',
      );

      final completedPlans = result.first['count'] as int? ?? 0;

      if (completedPlans >= 5) {
        final completionCount = await _achievementService!.getCompletionCount(AchievementType.deepDiver);
        // Record if first completion or every 5 plans
        if (completionCount == 0 || completedPlans >= (completionCount + 1) * 5) {
          await _achievementService!.recordCompletion(
            type: AchievementType.deepDiver,
            progressValue: completedPlans,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to check reading plan achievements: $e');
    }
  }

  /// Helper method to convert map to DailyReading
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
