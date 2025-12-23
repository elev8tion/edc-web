import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prayer_request.dart';
import '../error/error_handler.dart';
import 'app_providers.dart';
import 'category_providers.dart';

// Prayer Lists
final activePrayersProvider = FutureProvider<List<PrayerRequest>>((ref) async {
  try {
    final service = ref.read(prayerServiceProvider);
    final categoryFilter = ref.watch(selectedCategoryFilterProvider);
    return await service.getActivePrayers(categoryFilter: categoryFilter);
  } catch (error) {
    // Log error but return empty list instead of crashing
    debugPrint('Failed to load active prayers: $error');
    return [];
  }
});

final answeredPrayersProvider = FutureProvider<List<PrayerRequest>>((ref) async {
  try {
    final service = ref.read(prayerServiceProvider);
    final categoryFilter = ref.watch(selectedCategoryFilterProvider);
    return await service.getAnsweredPrayers(categoryFilter: categoryFilter);
  } catch (error) {
    // Log error but return empty list instead of crashing
    debugPrint('Failed to load answered prayers: $error');
    return [];
  }
});

// Prayer Statistics
final prayerStatsProvider = FutureProvider<PrayerStats>((ref) async {
  try {
    final service = ref.read(prayerServiceProvider);
    final totalCount = await service.getPrayerCount();
    final answeredCount = await service.getAnsweredPrayerCount();

    return PrayerStats(
      totalPrayers: totalCount,
      answeredPrayers: answeredCount,
      activePrayers: totalCount - answeredCount,
    );
  } catch (error) {
    // Log error but return default statistics instead of crashing
    debugPrint('Failed to load prayer statistics: $error');
    return PrayerStats(
      totalPrayers: 0,
      answeredPrayers: 0,
      activePrayers: 0,
    );
  }
});

// Prayer Actions
final prayerActionsProvider = Provider<PrayerActions>((ref) {
  final service = ref.read(prayerServiceProvider);
  final streakService = ref.read(prayerStreakServiceProvider);

  return PrayerActions(
    addPrayer: (title, description, categoryId) async {
      try {
        await service.createPrayer(
          title: title,
          description: description,
          categoryId: categoryId,
        );
        // Record prayer activity for streak tracking
        await streakService.recordPrayerActivity();

        // Invalidate providers to refresh UI
        ref.invalidate(activePrayersProvider);
        ref.invalidate(prayerStatsProvider);
        ref.invalidate(activePrayersCountProvider);
        ref.invalidate(answeredPrayersCountProvider);
        ref.invalidate(currentPrayerStreakProvider);
        ref.invalidate(longestPrayerStreakProvider);
        ref.invalidate(prayedTodayProvider);
        ref.invalidate(totalDaysPrayedProvider);
      } catch (error) {
        throw ErrorHandler.handle(error);
      }
    },
    markAnswered: (id, answer) async {
      try {
        await service.markPrayerAnswered(id, answer);
        // Record prayer activity for streak tracking
        await streakService.recordPrayerActivity();

        // Invalidate providers to refresh UI
        ref.invalidate(activePrayersProvider);
        ref.invalidate(answeredPrayersProvider);
        ref.invalidate(prayerStatsProvider);
        ref.invalidate(activePrayersCountProvider);
        ref.invalidate(answeredPrayersCountProvider);
        ref.invalidate(currentPrayerStreakProvider);
        ref.invalidate(longestPrayerStreakProvider);
        ref.invalidate(prayedTodayProvider);
        ref.invalidate(totalDaysPrayedProvider);
      } catch (error) {
        throw ErrorHandler.handle(error);
      }
    },
    deletePrayer: (id) async {
      try {
        await service.deletePrayer(id);
        // Invalidate providers to refresh UI
        ref.invalidate(activePrayersProvider);
        ref.invalidate(answeredPrayersProvider);
        ref.invalidate(prayerStatsProvider);
        ref.invalidate(activePrayersCountProvider);
        ref.invalidate(answeredPrayersCountProvider);
        ref.invalidate(currentPrayerStreakProvider);
        ref.invalidate(longestPrayerStreakProvider);
        ref.invalidate(prayedTodayProvider);
        ref.invalidate(totalDaysPrayedProvider);
      } catch (error) {
        throw ErrorHandler.handle(error);
      }
    },
  );
});

class PrayerStats {
  final int totalPrayers;
  final int answeredPrayers;
  final int activePrayers;

  PrayerStats({
    required this.totalPrayers,
    required this.answeredPrayers,
    required this.activePrayers,
  });
}

class PrayerActions {
  final Future<void> Function(String title, String description, String categoryId) addPrayer;
  final Future<void> Function(String id, String answer) markAnswered;
  final Future<void> Function(String id) deletePrayer;

  PrayerActions({
    required this.addPrayer,
    required this.markAnswered,
    required this.deletePrayer,
  });
}