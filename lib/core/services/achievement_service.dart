import 'package:uuid/uuid.dart';
import 'database_service.dart';
import 'dart:developer' as developer;

/// Achievement types matching profile_screen.dart achievements
enum AchievementType {
  unbroken,      // 7-day prayer streak
  relentless,    // 50 total prayers
  curator,       // 100 saved verses
  dailyBread,    // 30 devotionals (monthly)
  deepDiver,     // 5 reading plans
  disciple,      // 10 shared chats
}

/// Model for achievement completion records
class AchievementCompletion {
  final String id;
  final AchievementType achievementType;
  final DateTime completedAt;
  final int completionCount;  // How many times this achievement has been earned
  final int progressAtCompletion;  // The progress value when completed (e.g., 50 for relentless)

  AchievementCompletion({
    required this.id,
    required this.achievementType,
    required this.completedAt,
    required this.completionCount,
    required this.progressAtCompletion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'achievement_type': achievementType.name,
      'completed_at': completedAt.millisecondsSinceEpoch,
      'completion_count': completionCount,
      'progress_at_completion': progressAtCompletion,
    };
  }

  factory AchievementCompletion.fromMap(Map<String, dynamic> map) {
    return AchievementCompletion(
      id: map['id'] as String,
      achievementType: AchievementType.values.firstWhere(
        (e) => e.name == map['achievement_type'],
      ),
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int),
      completionCount: map['completion_count'] as int,
      progressAtCompletion: map['progress_at_completion'] as int,
    );
  }
}

/// Service for managing achievement completions and resets
class AchievementService {
  final DatabaseService _database;
  static const _uuid = Uuid();

  AchievementService(this._database);

  /// Check if achievement has been completed and should reset
  /// Returns the current completion count (0 if never completed)
  Future<int> getCompletionCount(AchievementType type) async {
    try {
      final db = await _database.database;
      final results = await db.query(
        'achievement_completions',
        where: 'achievement_type = ?',
        whereArgs: [type.name],
        orderBy: 'completion_count DESC',
        limit: 1,
      );

      if (results.isEmpty) {
        return 0;
      }

      return results.first['completion_count'] as int;
    } catch (e) {
      developer.log('Failed to get completion count: $e', name: 'AchievementService');
      return 0;
    }
  }

  /// Get all completion records for an achievement (history)
  Future<List<AchievementCompletion>> getCompletionHistory(AchievementType type) async {
    try {
      final db = await _database.database;
      final results = await db.query(
        'achievement_completions',
        where: 'achievement_type = ?',
        whereArgs: [type.name],
        orderBy: 'completed_at DESC',
      );

      return results.map((map) => AchievementCompletion.fromMap(map)).toList();
    } catch (e) {
      developer.log('Failed to get completion history: $e', name: 'AchievementService');
      return [];
    }
  }

  /// Record achievement completion
  /// This should be called when an achievement reaches its target (e.g., 50 prayers logged)
  Future<void> recordCompletion({
    required AchievementType type,
    required int progressValue,
  }) async {
    try {
      final db = await _database.database;

      // Get current completion count
      final currentCount = await getCompletionCount(type);
      final newCount = currentCount + 1;

      final completion = AchievementCompletion(
        id: _uuid.v4(),
        achievementType: type,
        completedAt: DateTime.now(),
        completionCount: newCount,
        progressAtCompletion: progressValue,
      );

      await db.insert('achievement_completions', completion.toMap());

      developer.log(
        '✅ Achievement completed: ${type.name} (${newCount}x) at progress $progressValue',
        name: 'AchievementService',
      );

      // Achievement completion logged successfully

    } catch (e) {
      developer.log('Failed to record achievement completion: $e', name: 'AchievementService');
      rethrow;
    }
  }

  /// Reset achievement counter
  /// This resets the underlying counter to 0 for repeatable achievements
  Future<void> resetAchievementCounter(AchievementType type) async {
    try {
      developer.log('Resetting ${type.name} after celebration', name: 'AchievementService');

      switch (type) {
        case AchievementType.relentless:
          // Reset total prayer count
          // This will be handled by clearing relevant prayer data
          developer.log('Reset prayer count counter', name: 'AchievementService');
          break;

        case AchievementType.curator:
          // Reset saved verses count
          developer.log('Reset saved verses counter', name: 'AchievementService');
          break;

        case AchievementType.deepDiver:
          // Reset reading plans started count
          developer.log('Reset reading plans counter', name: 'AchievementService');
          break;

        case AchievementType.disciple:
          // Reset shared chats count
          final db = await _database.database;
          await db.delete('shared_chats');
          developer.log('✅ Reset shared_chats table', name: 'AchievementService');
          break;

        case AchievementType.unbroken:
          // Prayer streak resets automatically when user misses a day
          // No action needed here
          developer.log('Unbroken achievement resets automatically', name: 'AchievementService');
          break;

        case AchievementType.dailyBread:
          // Daily Bread has special monthly reset logic
          // Handled separately by DevotionalProgressService
          developer.log('Daily Bread has separate monthly reset logic', name: 'AchievementService');
          break;
      }

    } catch (e) {
      developer.log('Failed to reset achievement: $e', name: 'AchievementService');
      rethrow;
    }
  }

  /// Check if Daily Bread was completed (30/30) before month ended
  /// This is used to determine if we should celebrate vs just calendar reset
  Future<bool> wasDailyBreadCompletedThisMonth() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final db = await _database.database;
      final results = await db.query(
        'achievement_completions',
        where: 'achievement_type = ? AND completed_at >= ? AND completed_at <= ?',
        whereArgs: [
          AchievementType.dailyBread.name,
          monthStart.millisecondsSinceEpoch,
          monthEnd.millisecondsSinceEpoch,
        ],
      );

      return results.isNotEmpty;
    } catch (e) {
      developer.log('Failed to check Daily Bread completion: $e', name: 'AchievementService');
      return false;
    }
  }

  /// Get total number of times any achievement has been completed
  Future<int> getTotalAchievementsEarned() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM achievement_completions',
      );
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      developer.log('Failed to get total achievements: $e', name: 'AchievementService');
      return 0;
    }
  }

  /// Check Disciple achievement (10 total shares across all types)
  /// Counts shares from: shared_chats, shared_verses, shared_devotionals, shared_prayers
  /// This method should be called after any share action
  Future<void> checkAllSharesAchievement() async {
    try {
      final db = await _database.database;

      // Count all share types in parallel
      final results = await Future.wait<List<Map<String, dynamic>>>([
        db.rawQuery('SELECT COUNT(*) as count FROM shared_chats'),
        db.rawQuery('SELECT COUNT(*) as count FROM shared_verses'),
        db.rawQuery('SELECT COUNT(*) as count FROM shared_devotionals'),
        db.rawQuery('SELECT COUNT(*) as count FROM shared_prayers'),
      ]);

      final chatShares = results[0].first['count'] as int? ?? 0;
      final verseShares = results[1].first['count'] as int? ?? 0;
      final devotionalShares = results[2].first['count'] as int? ?? 0;
      final prayerShares = results[3].first['count'] as int? ?? 0;

      final totalShares = chatShares + verseShares + devotionalShares + prayerShares;

      if (totalShares >= 10) {
        final completionCount = await getCompletionCount(AchievementType.disciple);
        // Record if first completion or every 10 shares
        if (completionCount == 0 || totalShares >= (completionCount + 1) * 10) {
          await recordCompletion(
            type: AchievementType.disciple,
            progressValue: totalShares,
          );
        }
      }
    } catch (e) {
      developer.log('Failed to check all shares achievement: $e', name: 'AchievementService');
    }
  }

  /// Clear all achievement completion data (for testing or factory reset)
  Future<void> clearAllCompletions() async {
    try {
      final db = await _database.database;
      await db.delete('achievement_completions');
      developer.log('All achievement completions cleared', name: 'AchievementService');
    } catch (e) {
      developer.log('Failed to clear achievements: $e', name: 'AchievementService');
      rethrow;
    }
  }
}
