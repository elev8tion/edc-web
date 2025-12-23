import 'dart:convert';

class User {
  final String id;
  final String? email;
  final String? name;
  final String? denomination;
  final List<String> spiritualInterests;
  final List<String> preferredVerseThemes;
  final String preferredTranslation;
  final DateTime? dateJoined;
  final bool isAnonymous;
  final UserProfile? profile;

  const User({
    required this.id,
    this.email,
    this.name,
    this.denomination,
    this.spiritualInterests = const [],
    this.preferredVerseThemes = const [],
    this.preferredTranslation = 'ESV',
    this.dateJoined,
    this.isAnonymous = false,
    this.profile,
  });

  /// Create User from JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      denomination: json['denomination'] as String?,
      spiritualInterests: _parseStringList(json['spiritual_interests']),
      preferredVerseThemes: _parseStringList(json['preferred_verse_themes']),
      preferredTranslation: json['preferred_translation'] as String? ?? 'ESV',
      dateJoined: json['date_joined'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['date_joined'] as int)
          : null,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert User to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'denomination': denomination,
      'spiritual_interests': spiritualInterests,
      'preferred_verse_themes': preferredVerseThemes,
      'preferred_translation': preferredTranslation,
      'date_joined': dateJoined?.millisecondsSinceEpoch,
      'is_anonymous': isAnonymous,
      'profile': profile?.toJson(),
    };
  }

  /// Parse string list from JSON
  static List<String> _parseStringList(dynamic list) {
    if (list == null) return [];
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    if (list is String) {
      try {
        final parsed = jsonDecode(list) as List;
        return parsed.map((e) => e.toString()).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Create anonymous user
  factory User.anonymous() {
    return User(
      id: 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
      isAnonymous: true,
      dateJoined: DateTime.now(),
      preferredVerseThemes: ['hope', 'strength', 'comfort'],
    );
  }

  /// Get display name
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!.split('@').first;
    }
    if (isAnonymous) {
      return 'Guest User';
    }
    return 'User';
  }

  /// Get user initials for avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'G'; // Guest
  }

  /// Check if user has completed profile setup
  bool get hasCompletedProfile {
    return name != null && preferredVerseThemes.isNotEmpty;
  }

  /// Get membership duration
  Duration? get membershipDuration {
    if (dateJoined == null) return null;
    return DateTime.now().difference(dateJoined!);
  }

  /// Copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? denomination,
    List<String>? spiritualInterests,
    List<String>? preferredVerseThemes,
    String? preferredTranslation,
    DateTime? dateJoined,
    bool? isAnonymous,
    UserProfile? profile,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      denomination: denomination ?? this.denomination,
      spiritualInterests: spiritualInterests ?? this.spiritualInterests,
      preferredVerseThemes: preferredVerseThemes ?? this.preferredVerseThemes,
      preferredTranslation: preferredTranslation ?? this.preferredTranslation,
      dateJoined: dateJoined ?? this.dateJoined,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      profile: profile ?? this.profile,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, anonymous: $isAnonymous)';
  }
}

class UserProfile {
  final String? bio;
  final String? favoriteVerse;
  final String? churchName;
  final List<String> spiritualGoals;
  final int prayerStreak;
  final int verseStreak;
  final int totalPrayers;
  final int answeredPrayers;
  final DateTime? lastActiveDate;

  const UserProfile({
    this.bio,
    this.favoriteVerse,
    this.churchName,
    this.spiritualGoals = const [],
    this.prayerStreak = 0,
    this.verseStreak = 0,
    this.totalPrayers = 0,
    this.answeredPrayers = 0,
    this.lastActiveDate,
  });

  /// Create UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      bio: json['bio'] as String?,
      favoriteVerse: json['favorite_verse'] as String?,
      churchName: json['church_name'] as String?,
      spiritualGoals: User._parseStringList(json['spiritual_goals']),
      prayerStreak: json['prayer_streak'] as int? ?? 0,
      verseStreak: json['verse_streak'] as int? ?? 0,
      totalPrayers: json['total_prayers'] as int? ?? 0,
      answeredPrayers: json['answered_prayers'] as int? ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_active_date'] as int)
          : null,
    );
  }

  /// Convert UserProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'favorite_verse': favoriteVerse,
      'church_name': churchName,
      'spiritual_goals': spiritualGoals,
      'prayer_streak': prayerStreak,
      'verse_streak': verseStreak,
      'total_prayers': totalPrayers,
      'answered_prayers': answeredPrayers,
      'last_active_date': lastActiveDate?.millisecondsSinceEpoch,
    };
  }

  /// Get answered prayer percentage
  double get answeredPrayerPercentage {
    if (totalPrayers == 0) return 0.0;
    return (answeredPrayers / totalPrayers) * 100;
  }

  /// Copy with updated fields
  UserProfile copyWith({
    String? bio,
    String? favoriteVerse,
    String? churchName,
    List<String>? spiritualGoals,
    int? prayerStreak,
    int? verseStreak,
    int? totalPrayers,
    int? answeredPrayers,
    DateTime? lastActiveDate,
  }) {
    return UserProfile(
      bio: bio ?? this.bio,
      favoriteVerse: favoriteVerse ?? this.favoriteVerse,
      churchName: churchName ?? this.churchName,
      spiritualGoals: spiritualGoals ?? this.spiritualGoals,
      prayerStreak: prayerStreak ?? this.prayerStreak,
      verseStreak: verseStreak ?? this.verseStreak,
      totalPrayers: totalPrayers ?? this.totalPrayers,
      answeredPrayers: answeredPrayers ?? this.answeredPrayers,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  @override
  String toString() {
    return 'UserProfile(prayerStreak: $prayerStreak, verseStreak: $verseStreak, totalPrayers: $totalPrayers)';
  }
}

/// Helper class for spiritual interests and denominations
class SpiritualData {
  // Common Christian denominations
  static const List<String> denominations = [
    'Non-denominational',
    'Baptist',
    'Methodist',
    'Presbyterian',
    'Lutheran',
    'Pentecostal',
    'Catholic',
    'Orthodox',
    'Anglican/Episcopal',
    'Reformed',
    'Assemblies of God',
    'Church of Christ',
    'Evangelical',
    'Other',
  ];

  // Spiritual interests
  static const List<String> spiritualInterests = [
    'Bible Study',
    'Prayer & Meditation',
    'Worship & Music',
    'Christian Fellowship',
    'Missions & Evangelism',
    'Social Justice',
    'Christian Parenting',
    'Marriage & Family',
    'Youth Ministry',
    'Senior Ministry',
    'Christian Leadership',
    'Theological Study',
    'Christian History',
    'Apologetics',
    'Spiritual Formation',
    'Christian Art & Creativity',
    'Biblical Counseling',
    'Church Planting',
    'Discipleship',
    'Christian Education',
  ];

  // Spiritual goals
  static const List<String> spiritualGoals = [
    'Read the Bible daily',
    'Develop a consistent prayer life',
    'Memorize Scripture verses',
    'Attend church regularly',
    'Join a Bible study group',
    'Volunteer in ministry',
    'Share faith with others',
    'Practice forgiveness',
    'Grow in patience and love',
    'Deepen relationship with God',
    'Learn to trust God more',
    'Develop spiritual disciplines',
    'Study Christian theology',
    'Practice gratitude daily',
    'Serve those in need',
    'Build Christian friendships',
    'Overcome sin patterns',
    'Seek God\'s will for life',
    'Grow in wisdom',
    'Develop Christ-like character',
  ];
}