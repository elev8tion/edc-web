class PrayerRequest {
  final int? id;
  final String title;
  final String content;
  final String? category;
  final PrayerStatus status;
  final DateTime dateCreated;
  final DateTime? dateAnswered;
  final String? testimony;
  final bool isPrivate;
  final ReminderFrequency? reminderFrequency;

  const PrayerRequest({
    this.id,
    required this.title,
    required this.content,
    this.category,
    this.status = PrayerStatus.active,
    required this.dateCreated,
    this.dateAnswered,
    this.testimony,
    this.isPrivate = true,
    this.reminderFrequency,
  });

  /// Create PrayerRequest from database map
  factory PrayerRequest.fromMap(Map<String, dynamic> map) {
    return PrayerRequest(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String?,
      status: PrayerStatus.fromString(map['status'] as String? ?? 'active'),
      dateCreated: DateTime.fromMillisecondsSinceEpoch(map['date_created'] as int),
      dateAnswered: map['date_answered'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_answered'] as int)
          : null,
      testimony: map['testimony'] as String?,
      isPrivate: (map['is_private'] as int? ?? 1) == 1,
      reminderFrequency: map['reminder_frequency'] != null
          ? ReminderFrequency.fromString(map['reminder_frequency'] as String)
          : null,
    );
  }

  /// Convert PrayerRequest to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'category': category,
      'status': status.value,
      'date_created': dateCreated.millisecondsSinceEpoch,
      'date_answered': dateAnswered?.millisecondsSinceEpoch,
      'testimony': testimony,
      'is_private': isPrivate ? 1 : 0,
      'reminder_frequency': reminderFrequency?.value,
    };
  }

  /// Get formatted date created
  String get formattedDateCreated {
    final now = DateTime.now();

    // Compare dates only (ignore time) to handle midnight boundary correctly
    final today = DateTime(now.year, now.month, now.day);
    final prayerDate = DateTime(dateCreated.year, dateCreated.month, dateCreated.day);
    final daysDifference = today.difference(prayerDate).inDays;

    if (daysDifference == 0) {
      return 'Today';
    } else if (daysDifference == 1) {
      return 'Yesterday';
    } else if (daysDifference < 7) {
      return '$daysDifference days ago';
    } else if (daysDifference < 30) {
      final weeks = (daysDifference / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (daysDifference < 365) {
      final months = (daysDifference / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (daysDifference / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  /// Get days since created (calendar days, not 24-hour periods)
  int get daysSinceCreated {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prayerDate = DateTime(dateCreated.year, dateCreated.month, dateCreated.day);
    return today.difference(prayerDate).inDays;
  }

  /// Get days since answered (if answered) (calendar days, not 24-hour periods)
  int? get daysSinceAnswered {
    if (dateAnswered == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final answeredDate = DateTime(dateAnswered!.year, dateAnswered!.month, dateAnswered!.day);
    return today.difference(answeredDate).inDays;
  }

  /// Check if prayer is answered
  bool get isAnswered => status == PrayerStatus.answered;

  /// Check if prayer is active
  bool get isActive => status == PrayerStatus.active;

  /// Check if prayer is archived
  bool get isArchived => status == PrayerStatus.archived;

  /// Get display category
  String get displayCategory {
    if (category == null || category!.isEmpty) {
      return 'General';
    }
    return category!.substring(0, 1).toUpperCase() + category!.substring(1);
  }

  /// Get share text
  String getShareText({bool includeTestimony = true, bool includeApp = true}) {
    final buffer = StringBuffer();
    buffer.writeln('Prayer Request: $title');
    buffer.writeln();
    buffer.writeln(content);

    if (isAnswered && testimony != null && includeTestimony) {
      buffer.writeln();
      buffer.writeln('ANSWERED! 🙏');
      buffer.writeln(testimony);
    }

    if (includeApp) {
      buffer.writeln();
      buffer.writeln('Shared from Everyday Christian');
    }

    return buffer.toString();
  }

  /// Copy with updated fields
  PrayerRequest copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    PrayerStatus? status,
    DateTime? dateCreated,
    DateTime? dateAnswered,
    String? testimony,
    bool? isPrivate,
    ReminderFrequency? reminderFrequency,
  }) {
    return PrayerRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      status: status ?? this.status,
      dateCreated: dateCreated ?? this.dateCreated,
      dateAnswered: dateAnswered ?? this.dateAnswered,
      testimony: testimony ?? this.testimony,
      isPrivate: isPrivate ?? this.isPrivate,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PrayerRequest &&
        other.id == id &&
        other.title == title &&
        other.dateCreated == dateCreated;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ dateCreated.hashCode;
  }

  @override
  String toString() {
    return 'PrayerRequest(id: $id, title: $title, status: $status, category: $category)';
  }
}

enum PrayerStatus {
  active('active'),
  answered('answered'),
  archived('archived');

  const PrayerStatus(this.value);

  final String value;

  static PrayerStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return PrayerStatus.active;
      case 'answered':
        return PrayerStatus.answered;
      case 'archived':
        return PrayerStatus.archived;
      default:
        return PrayerStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case PrayerStatus.active:
        return 'Active';
      case PrayerStatus.answered:
        return 'Answered';
      case PrayerStatus.archived:
        return 'Archived';
    }
  }

  String get emoji {
    switch (this) {
      case PrayerStatus.active:
        return '🙏';
      case PrayerStatus.answered:
        return '✅';
      case PrayerStatus.archived:
        return '📁';
    }
  }
}

enum ReminderFrequency {
  none('none'),
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  const ReminderFrequency(this.value);

  final String value;

  static ReminderFrequency fromString(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'none':
        return ReminderFrequency.none;
      case 'daily':
        return ReminderFrequency.daily;
      case 'weekly':
        return ReminderFrequency.weekly;
      case 'monthly':
        return ReminderFrequency.monthly;
      default:
        return ReminderFrequency.none;
    }
  }

  String get displayName {
    switch (this) {
      case ReminderFrequency.none:
        return 'No Reminders';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
    }
  }
}

/// Helper class for prayer categories
class PrayerCategory {
  static const String personal = 'personal';
  static const String family = 'family';
  static const String health = 'health';
  static const String work = 'work';
  static const String finances = 'finances';
  static const String relationships = 'relationships';
  static const String church = 'church';
  static const String community = 'community';
  static const String world = 'world';
  static const String spiritual = 'spiritual';

  static const List<String> allCategories = [
    personal,
    family,
    health,
    work,
    finances,
    relationships,
    church,
    community,
    world,
    spiritual,
  ];

  static String getDisplayName(String category) {
    switch (category) {
      case personal:
        return 'Personal';
      case family:
        return 'Family';
      case health:
        return 'Health';
      case work:
        return 'Work';
      case finances:
        return 'Finances';
      case relationships:
        return 'Relationships';
      case church:
        return 'Church';
      case community:
        return 'Community';
      case world:
        return 'World';
      case spiritual:
        return 'Spiritual Growth';
      default:
        return category.substring(0, 1).toUpperCase() + category.substring(1);
    }
  }

  static String getEmoji(String category) {
    switch (category) {
      case personal:
        return '👤';
      case family:
        return '👨‍👩‍👧‍👦';
      case health:
        return '🏥';
      case work:
        return '💼';
      case finances:
        return '💰';
      case relationships:
        return '💕';
      case church:
        return '⛪';
      case community:
        return '🏘️';
      case world:
        return '🌍';
      case spiritual:
        return '✨';
      default:
        return '🙏';
    }
  }
}