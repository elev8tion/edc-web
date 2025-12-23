import 'dart:convert';

/// Represents a chat session/conversation
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;
  final String? userId;
  final List<String> tags;
  final SessionStatus status;
  final Map<String, dynamic>? metadata;
  final String? summary;
  final List<String> themes; // Spiritual themes discussed

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    this.messageCount = 0,
    this.userId,
    this.tags = const [],
    this.status = SessionStatus.active,
    this.metadata,
    this.summary,
    this.themes = const [],
  });

  /// Create new session
  factory ChatSession.create({
    String? title,
    String? userId,
    List<String> tags = const [],
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return ChatSession(
      id: _generateId(),
      title: title ?? 'New Conversation',
      createdAt: now,
      lastMessageAt: now,
      userId: userId,
      tags: tags,
      metadata: metadata,
    );
  }

  /// Create from database map
  factory ChatSession.fromMap(Map<String, dynamic> map) {
    List<String> tagsList = [];
    if (map['tags'] != null) {
      try {
        tagsList = List<String>.from(jsonDecode(map['tags']));
      } catch (e) {
        tagsList = [];
      }
    }

    List<String> themesList = [];
    if (map['themes'] != null) {
      try {
        themesList = List<String>.from(jsonDecode(map['themes']));
      } catch (e) {
        themesList = [];
      }
    }

    Map<String, dynamic>? metadataMap;
    if (map['metadata'] != null) {
      try {
        metadataMap = jsonDecode(map['metadata']);
      } catch (e) {
        metadataMap = null;
      }
    }

    return ChatSession(
      id: map['id'] ?? _generateId(),
      title: map['title'] ?? 'Conversation',
      createdAt: map['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
        : DateTime.now(),
      lastMessageAt: map['last_message_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['last_message_at'])
        : DateTime.now(),
      messageCount: map['message_count'] ?? 0,
      userId: map['user_id'],
      tags: tagsList,
      status: SessionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SessionStatus.active,
      ),
      metadata: metadataMap,
      summary: map['summary'],
      themes: themesList,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_message_at': lastMessageAt.millisecondsSinceEpoch,
      'message_count': messageCount,
      if (userId != null) 'user_id': userId,
      'tags': jsonEncode(tags),
      'status': status.name,
      if (metadata != null) 'metadata': jsonEncode(metadata),
      if (summary != null) 'summary': summary,
      'themes': jsonEncode(themes),
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'messageCount': messageCount,
      if (userId != null) 'userId': userId,
      'tags': tags,
      'status': status.name,
      if (metadata != null) 'metadata': metadata,
      if (summary != null) 'summary': summary,
      'themes': themes,
    };
  }

  /// Create from JSON
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? _generateId(),
      title: json['title'] ?? 'Conversation',
      createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
      lastMessageAt: json['lastMessageAt'] != null
        ? DateTime.parse(json['lastMessageAt'])
        : DateTime.now(),
      messageCount: json['messageCount'] ?? 0,
      userId: json['userId'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      status: SessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SessionStatus.active,
      ),
      metadata: json['metadata'],
      summary: json['summary'],
      themes: json['themes'] != null ? List<String>.from(json['themes']) : [],
    );
  }

  /// Get formatted creation date
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).round()} weeks ago';
    } else {
      return '${(diff.inDays / 30).round()} months ago';
    }
  }

  /// Get session duration
  Duration get duration => lastMessageAt.difference(createdAt);

  /// Get formatted duration
  String get formattedDuration {
    final duration = this.duration;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Check if session is active
  bool get isActive => status == SessionStatus.active;

  /// Check if session is archived
  bool get isArchived => status == SessionStatus.archived;

  /// Check if session is deleted
  bool get isDeleted => status == SessionStatus.deleted;

  /// Check if session has themes
  bool get hasThemes => themes.isNotEmpty;

  /// Get primary theme
  String? get primaryTheme => themes.isNotEmpty ? themes.first : null;

  /// Generate smart title from first message
  static String generateSmartTitle(String firstMessage) {
    // Extract key topics or emotions from the first message
    final message = firstMessage.toLowerCase();

    // Common spiritual topics
    final topicMap = {
      'anxiety': 'Finding Peace',
      'worried': 'Overcoming Worry',
      'fear': 'Conquering Fear',
      'sad': 'Finding Comfort',
      'depressed': 'Hope in Darkness',
      'lonely': 'You Are Not Alone',
      'angry': 'Managing Anger',
      'stressed': 'Finding Rest',
      'purpose': 'Life Purpose',
      'direction': 'Seeking Direction',
      'decision': 'Making Decisions',
      'relationship': 'Relationships',
      'marriage': 'Marriage Guidance',
      'family': 'Family Matters',
      'work': 'Work & Career',
      'money': 'Financial Wisdom',
      'health': 'Health & Healing',
      'forgiveness': 'Forgiveness',
      'guilt': 'Freedom from Guilt',
      'doubt': 'Strengthening Faith',
      'prayer': 'Prayer Life',
      'worship': 'Worship & Praise',
    };

    for (final entry in topicMap.entries) {
      if (message.contains(entry.key)) {
        return entry.value;
      }
    }

    // Fallback: use first few words
    final words = firstMessage.split(' ').take(4).join(' ');
    return words.length > 30 ? '${words.substring(0, 27)}...' : words;
  }

  /// Copy session with modifications
  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    int? messageCount,
    String? userId,
    List<String>? tags,
    SessionStatus? status,
    Map<String, dynamic>? metadata,
    String? summary,
    List<String>? themes,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      summary: summary ?? this.summary,
      themes: themes ?? this.themes,
    );
  }

  /// Generate unique session ID
  static String _generateId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatSession(id: $id, title: $title, messages: $messageCount)';
  }
}

/// Status of a chat session
enum SessionStatus {
  active,
  archived,
  deleted,
}

/// Extension for session status utilities
extension SessionStatusExtension on SessionStatus {
  String get displayName {
    switch (this) {
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.archived:
        return 'Archived';
      case SessionStatus.deleted:
        return 'Deleted';
    }
  }

  bool get isActive => this == SessionStatus.active;
  bool get isArchived => this == SessionStatus.archived;
  bool get isDeleted => this == SessionStatus.deleted;
}

/// Helper class for session statistics
class SessionStats {
  final int totalSessions;
  final int activeSessions;
  final int archivedSessions;
  final int totalMessages;
  final Duration totalChatTime;
  final List<String> commonThemes;
  final DateTime? lastActivity;

  const SessionStats({
    required this.totalSessions,
    required this.activeSessions,
    required this.archivedSessions,
    required this.totalMessages,
    required this.totalChatTime,
    required this.commonThemes,
    this.lastActivity,
  });

  /// Get average messages per session
  double get averageMessagesPerSession {
    return totalSessions > 0 ? totalMessages / totalSessions : 0.0;
  }

  /// Get average session duration
  Duration get averageSessionDuration {
    return totalSessions > 0
        ? Duration(milliseconds: totalChatTime.inMilliseconds ~/ totalSessions)
        : Duration.zero;
  }

  /// Get formatted total chat time
  String get formattedTotalTime {
    if (totalChatTime.inDays > 0) {
      return '${totalChatTime.inDays}d ${totalChatTime.inHours % 24}h';
    } else if (totalChatTime.inHours > 0) {
      return '${totalChatTime.inHours}h ${totalChatTime.inMinutes % 60}m';
    } else {
      return '${totalChatTime.inMinutes}m';
    }
  }
}

/// Helper class for session search/filtering
class SessionFilter {
  final List<String>? tags;
  final List<String>? themes;
  final SessionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final int? minMessages;
  final int? maxMessages;

  const SessionFilter({
    this.tags,
    this.themes,
    this.status,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.minMessages,
    this.maxMessages,
  });

  /// Check if session matches filter
  bool matches(ChatSession session) {
    if (status != null && session.status != status) return false;

    if (tags != null && tags!.isNotEmpty) {
      if (!tags!.any((tag) => session.tags.contains(tag))) return false;
    }

    if (themes != null && themes!.isNotEmpty) {
      if (!themes!.any((theme) => session.themes.contains(theme))) return false;
    }

    if (startDate != null && session.createdAt.isBefore(startDate!)) return false;
    if (endDate != null && session.createdAt.isAfter(endDate!)) return false;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!session.title.toLowerCase().contains(query) &&
          (session.summary?.toLowerCase().contains(query) != true)) {
        return false;
      }
    }

    if (minMessages != null && session.messageCount < minMessages!) return false;
    if (maxMessages != null && session.messageCount > maxMessages!) return false;

    return true;
  }
}
