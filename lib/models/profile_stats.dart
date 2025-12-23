/// Model for profile screen statistics
/// Consolidates all user stats to minimize database queries
class ProfileStats {
  final int devotionalStreak;
  final int totalPrayers;
  final int savedVerses;
  final int devotionalsCompleted;
  final int prayerStreak;
  final int readingPlansActive;
  final int sharedChats;
  final int discipleCompletionCount;  // How many times Disciple achievement earned (10, 20, 30 shares...)

  const ProfileStats({
    required this.devotionalStreak,
    required this.totalPrayers,
    required this.savedVerses,
    required this.devotionalsCompleted,
    required this.prayerStreak,
    required this.readingPlansActive,
    required this.sharedChats,
    required this.discipleCompletionCount,
  });

  /// Empty stats (used as default/loading state)
  static const empty = ProfileStats(
    devotionalStreak: 0,
    totalPrayers: 0,
    savedVerses: 0,
    devotionalsCompleted: 0,
    prayerStreak: 0,
    readingPlansActive: 0,
    sharedChats: 0,
    discipleCompletionCount: 0,
  );
}
