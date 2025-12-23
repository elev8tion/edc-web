import 'dart:convert';
import 'bible_verse.dart';

/// Represents a message in the chat conversation
class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final List<BibleVerse> verses;
  final Map<String, dynamic>? metadata;
  final String? userId;
  final String? sessionId;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.verses = const [],
    this.metadata,
    this.userId,
    this.sessionId,
  });

  /// Create a user message
  factory ChatMessage.user({
    required String content,
    String? userId,
    String? sessionId,
  }) {
    return ChatMessage(
      id: _generateId(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      userId: userId,
      sessionId: sessionId,
    );
  }

  /// Create an AI response message
  factory ChatMessage.ai({
    required String content,
    List<BibleVerse> verses = const [],
    Map<String, dynamic>? metadata,
    String? sessionId,
  }) {
    return ChatMessage(
      id: _generateId(),
      content: content,
      type: MessageType.ai,
      timestamp: DateTime.now(),
      verses: verses,
      metadata: metadata,
      sessionId: sessionId,
    );
  }

  /// Create a system message
  factory ChatMessage.system({
    required String content,
    Map<String, dynamic>? metadata,
    String? sessionId,
  }) {
    return ChatMessage(
      id: _generateId(),
      content: content,
      type: MessageType.system,
      timestamp: DateTime.now(),
      metadata: metadata,
      sessionId: sessionId,
    );
  }

  /// Create from database map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    List<BibleVerse> versesList = [];
    if (map['verse_references'] != null) {
      try {
        final List<dynamic> versesJson = jsonDecode(map['verse_references']);
        versesList = versesJson.map((v) => BibleVerse.fromJson(v)).toList();
      } catch (e) {
        // Handle malformed JSON gracefully
        versesList = [];
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

    return ChatMessage(
      id: map['id'] ?? _generateId(),
      content: map['user_input'] ?? map['ai_response'] ?? map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => map['ai_response'] != null ? MessageType.ai : MessageType.user,
      ),
      timestamp: map['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
        : DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      verses: versesList,
      metadata: metadataMap,
      userId: map['user_id'],
      sessionId: map['session_id'],
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId ?? '',  // Always include session_id (required by database schema)
      'content': content,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'verse_references': verses.isNotEmpty ? jsonEncode(verses.map((v) => v.toJson()).toList()) : null,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      if (userId != null) 'user_id': userId,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'verses': verses.map((v) => v.toJson()).toList(),
      if (metadata != null) 'metadata': metadata,
      if (userId != null) 'userId': userId,
      if (sessionId != null) 'sessionId': sessionId,
    };
  }

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<BibleVerse> versesList = [];
    if (json['verses'] != null) {
      final List<dynamic> versesJson = json['verses'];
      versesList = versesJson.map((v) => BibleVerse.fromJson(v)).toList();
    }

    return ChatMessage(
      id: json['id'] ?? _generateId(),
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.user,
      ),
      timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'])
        : DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      verses: versesList,
      metadata: json['metadata'],
      userId: json['userId'],
      sessionId: json['sessionId'],
    );
  }

  /// Check if message is from user
  bool get isUser => type == MessageType.user;

  /// Check if message is from AI
  bool get isAI => type == MessageType.ai;

  /// Check if message is a system message
  bool get isSystem => type == MessageType.system;

  /// Check if message has verses
  bool get hasVerses => verses.isNotEmpty;

  /// Get formatted timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get message preview for conversation list
  String get preview {
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }

  /// Copy message with modifications
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    List<BibleVerse>? verses,
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      verses: verses ?? this.verses,
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  /// Generate unique message ID
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        DateTime.now().microsecond.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: $type, content: ${content.length > 30 ? '${content.substring(0, 30)}...' : content})';
  }
}

/// Type of message in the chat
enum MessageType {
  user,
  ai,
  system,
}

/// Status of the message
enum MessageStatus {
  sending,
  sent,
  delivered,
  failed,
}

/// Extension for message type utilities
extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.user:
        return 'You';
      case MessageType.ai:
        return 'AI Assistant';
      case MessageType.system:
        return 'System';
    }
  }

  bool get isFromUser => this == MessageType.user;
  bool get isFromAI => this == MessageType.ai;
  bool get isSystem => this == MessageType.system;
}

/// Extension for message status utilities
extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.failed:
        return 'Failed to send';
    }
  }

  bool get isComplete => this == MessageStatus.sent || this == MessageStatus.delivered;
  bool get isFailed => this == MessageStatus.failed;
  bool get isPending => this == MessageStatus.sending;
}

/// Helper class for message threading/grouping
class MessageGroup {
  final MessageType type;
  final List<ChatMessage> messages;
  final DateTime startTime;
  final DateTime endTime;

  const MessageGroup({
    required this.type,
    required this.messages,
    required this.startTime,
    required this.endTime,
  });

  /// Check if messages should be grouped together
  static bool shouldGroup(ChatMessage msg1, ChatMessage msg2) {
    if (msg1.type != msg2.type) return false;
    if (msg1.userId != msg2.userId) return false;

    final timeDiff = msg2.timestamp.difference(msg1.timestamp);
    return timeDiff.inMinutes <= 5; // Group messages within 5 minutes
  }

  /// Create groups from message list
  static List<MessageGroup> fromMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return [];

    final groups = <MessageGroup>[];
    var currentGroup = <ChatMessage>[messages.first];
    var startTime = messages.first.timestamp;

    for (int i = 1; i < messages.length; i++) {
      if (shouldGroup(messages[i - 1], messages[i])) {
        currentGroup.add(messages[i]);
      } else {
        // Finish current group
        groups.add(MessageGroup(
          type: currentGroup.first.type,
          messages: List.from(currentGroup),
          startTime: startTime,
          endTime: currentGroup.last.timestamp,
        ));

        // Start new group
        currentGroup = [messages[i]];
        startTime = messages[i].timestamp;
      }
    }

    // Add final group
    if (currentGroup.isNotEmpty) {
      groups.add(MessageGroup(
        type: currentGroup.first.type,
        messages: List.from(currentGroup),
        startTime: startTime,
        endTime: currentGroup.last.timestamp,
      ));
    }

    return groups;
  }
}