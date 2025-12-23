import 'database_service.dart';

/// Service for tracking and managing prayer streaks
///
/// This service handles:
/// - Recording daily prayer activity
/// - Calculating current streak (consecutive days with prayer activity)
/// - Tracking longest streak achieved
/// - Checking if user has prayed today
class PrayerStreakService {
  final DatabaseService _database;

  PrayerStreakService(this._database);

  /// Record prayer activity for today
  ///
  /// This method is called whenever a user:
  /// - Adds a new prayer
  /// - Marks a prayer as answered
  ///
  /// It uses timezone-aware date handling to ensure accuracy across day boundaries
  Future<void> recordPrayerActivity() async {
    try {
      final db = await _database.database;
      final today = _getTodayDate();

      // Check if we already have an entry for today
      final existing = await db.query(
        'prayer_streak_activity',
        where: 'activity_date = ?',
        whereArgs: [today],
      );

      if (existing.isEmpty) {
        // Insert new activity record for today
        await db.insert('prayer_streak_activity', {
          'activity_date': today,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
      // If entry exists, we don't need to do anything - one entry per day
    } catch (e) {
      rethrow;
    }
  }

  /// Get the current prayer streak (consecutive days)
  ///
  /// Returns the number of consecutive days with prayer activity,
  /// including today if user has prayed today
  Future<int> getCurrentStreak() async {
    try {
      final db = await _database.database;

      // Get all activity dates in descending order
      final results = await db.query(
        'prayer_streak_activity',
        orderBy: 'activity_date DESC',
      );

      if (results.isEmpty) {
        return 0;
      }

      final today = _getTodayDate();
      int streak = 0;
      int expectedDate = today;

      // Count consecutive days from today backwards
      for (final row in results) {
        final activityDate = row['activity_date'] as int;

        if (activityDate == expectedDate) {
          streak++;
          expectedDate = _getPreviousDate(expectedDate);
        } else {
          // Gap in streak detected
          break;
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  /// Get the longest prayer streak ever achieved
  ///
  /// This calculates the longest consecutive streak in the user's history,
  /// which may be different from the current streak
  Future<int> getLongestStreak() async {
    try {
      final db = await _database.database;

      // Get all activity dates in ascending order
      final results = await db.query(
        'prayer_streak_activity',
        orderBy: 'activity_date ASC',
      );

      if (results.isEmpty) {
        return 0;
      }

      int longestStreak = 1;
      int currentStreak = 1;
      int? previousDate;

      for (final row in results) {
        final activityDate = row['activity_date'] as int;

        if (previousDate != null) {
          final nextExpected = _getNextDate(previousDate);

          if (activityDate == nextExpected) {
            // Consecutive day
            currentStreak++;
            if (currentStreak > longestStreak) {
              longestStreak = currentStreak;
            }
          } else {
            // Gap detected, reset current streak
            currentStreak = 1;
          }
        }

        previousDate = activityDate;
      }

      return longestStreak;
    } catch (e) {
      return 0;
    }
  }

  /// Check if the user has prayed today
  ///
  /// Returns true if there's a prayer activity record for today
  Future<bool> hasPrayedToday() async {
    try {
      final db = await _database.database;
      final today = _getTodayDate();

      final result = await db.query(
        'prayer_streak_activity',
        where: 'activity_date = ?',
        whereArgs: [today],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all activity dates for analytics
  ///
  /// Returns a list of all dates with prayer activity
  Future<List<DateTime>> getAllActivityDates() async {
    try {
      final db = await _database.database;

      final results = await db.query(
        'prayer_streak_activity',
        orderBy: 'activity_date DESC',
      );

      return results.map((row) {
        final dateInt = row['activity_date'] as int;
        return _dateIntToDateTime(dateInt);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get total number of days prayed (not consecutive)
  Future<int> getTotalDaysPrayed() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM prayer_streak_activity',
      );
      return result.first['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  // Helper methods for date handling

  /// Get today's date as an integer (YYYYMMDD format)
  ///
  /// This ensures timezone-aware handling of day boundaries
  int _getTodayDate() {
    final now = DateTime.now();
    return _dateTimeToDateInt(now);
  }

  /// Convert DateTime to date integer (YYYYMMDD format)
  int _dateTimeToDateInt(DateTime date) {
    // Use local timezone for accurate day boundaries
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.year * 10000 + localDate.month * 100 + localDate.day;
  }

  /// Convert date integer (YYYYMMDD) back to DateTime
  DateTime _dateIntToDateTime(int dateInt) {
    final year = dateInt ~/ 10000;
    final month = (dateInt % 10000) ~/ 100;
    final day = dateInt % 100;
    return DateTime(year, month, day);
  }

  /// Get the previous date as integer
  int _getPreviousDate(int dateInt) {
    final date = _dateIntToDateTime(dateInt);
    final previousDate = date.subtract(const Duration(days: 1));
    return _dateTimeToDateInt(previousDate);
  }

  /// Get the next date as integer
  int _getNextDate(int dateInt) {
    final date = _dateIntToDateTime(dateInt);
    final nextDate = date.add(const Duration(days: 1));
    return _dateTimeToDateInt(nextDate);
  }

  /// Clear all streak data (for testing or reset)
  Future<void> clearAllStreakData() async {
    try {
      final db = await _database.database;
      await db.delete('prayer_streak_activity');
    } catch (e) {
      rethrow;
    }
  }
}
