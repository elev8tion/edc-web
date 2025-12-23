import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide ConflictAlgorithm;
import '../core/database/database_helper.dart';
import '../models/chat_message.dart';

/// Service for managing chat conversations and messages
class ConversationService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Verify and repair chat_sessions schema if needed
  Future<void> _verifyChatSessionsSchema() async {
    try {
      final db = await _dbHelper.database;

      // Check if columns exist by trying a query
      await db.rawQuery('''
        SELECT last_message_at, last_message_preview, updated_at
        FROM chat_sessions
        LIMIT 1
      ''');

      debugPrint('✅ Chat sessions schema verified');
    } catch (e) {
      debugPrint('⚠️ Chat sessions schema incomplete, repairing...');

      try {
        final db = await _dbHelper.database;

        // Try to add missing columns
        try {
          await db.execute('ALTER TABLE chat_sessions ADD COLUMN last_message_at INTEGER');
          debugPrint('✅ Added last_message_at column');
        } catch (_) {}

        try {
          await db.execute('ALTER TABLE chat_sessions ADD COLUMN last_message_preview TEXT');
          debugPrint('✅ Added last_message_preview column');
        } catch (_) {}

        try {
          await db.execute('ALTER TABLE chat_sessions ADD COLUMN updated_at INTEGER');
          debugPrint('✅ Added updated_at column');
        } catch (_) {}

        // Update any sessions with null updated_at
        await db.rawUpdate('''
          UPDATE chat_sessions
          SET updated_at = created_at
          WHERE updated_at IS NULL
        ''');

        debugPrint('✅ Chat sessions schema repaired successfully');
      } catch (repairError) {
        debugPrint('❌ Failed to repair schema: $repairError');
      }
    }
  }

  /// Save a message to the database
  Future<void> saveMessage(ChatMessage message) async {
    try {
      final db = await _dbHelper.database;
      final map = message.toMap();

      await db.insert(
        'chat_messages',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update session's last message
      if (message.sessionId != null) {
        await _updateSessionLastMessage(message);
      }

      debugPrint('✅ Message saved: ${message.id}');
    } catch (e) {
      debugPrint('❌ Failed to save message: $e');
      rethrow;
    }
  }

  /// Save multiple messages in a transaction
  Future<void> saveMessages(List<ChatMessage> messages) async {
    if (messages.isEmpty) return;

    try {
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        for (final message in messages) {
          await txn.insert(
            'chat_messages',
            message.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      // Update session last message
      if (messages.isNotEmpty && messages.last.sessionId != null) {
        await _updateSessionLastMessage(messages.last);
      }

      debugPrint('✅ Saved ${messages.length} messages');
    } catch (e) {
      debugPrint('❌ Failed to save messages: $e');
      rethrow;
    }
  }

  /// Get all messages for a session
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'chat_messages',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC',
      );

      return maps.map((map) => ChatMessage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get messages: $e');
      return [];
    }
  }

  /// Get recent messages for a session (limit)
  Future<List<ChatMessage>> getRecentMessages(
    String sessionId, {
    int limit = 50,
  }) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'chat_messages',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      // Reverse to get chronological order
      return maps.reversed.map((map) => ChatMessage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get recent messages: $e');
      return [];
    }
  }

  /// Create a new chat session
  Future<String> createSession({String? title}) async {
    try {
      // Verify schema first
      await _verifyChatSessionsSchema();

      final db = await _dbHelper.database;
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('chat_sessions', {
        'id': sessionId,
        'title': title ?? 'New Conversation',
        'created_at': now,
        'updated_at': now,
        'is_archived': 0,
        'message_count': 0,
        'last_message_at': now,
        'last_message_preview': null,
      });

      debugPrint('✅ Session created: $sessionId with all required fields');
      return sessionId;
    } catch (e) {
      debugPrint('❌ Failed to create session: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Get all chat sessions
  Future<List<Map<String, dynamic>>> getSessions({bool includeArchived = false}) async {
    try {
      // Verify schema first
      await _verifyChatSessionsSchema();

      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'chat_sessions',
        where: includeArchived ? null : 'is_archived = ?',
        whereArgs: includeArchived ? null : [0],
        orderBy: 'updated_at DESC',
      );

      debugPrint('✅ Retrieved ${maps.length} chat sessions');
      return maps;
    } catch (e) {
      debugPrint('❌ Failed to get sessions: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get the most recent active session (for resuming)
  Future<String?> getLastActiveSession() async {
    try {
      // Verify schema first
      await _verifyChatSessionsSchema();

      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'chat_sessions',
        where: 'is_archived = ?',
        whereArgs: [0],
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) {
        debugPrint('ℹ️ No active sessions found');
        return null;
      }

      final sessionId = maps.first['id'] as String;
      debugPrint('✅ Found last active session: $sessionId');
      return sessionId;
    } catch (e) {
      debugPrint('❌ Failed to get last active session: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Check if a session exists
  Future<bool> sessionExists(String sessionId) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.query(
        'chat_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Failed to check session existence: $e');
      return false;
    }
  }

  /// Update session title
  Future<void> updateSessionTitle(String sessionId, String title) async {
    try {
      final db = await _dbHelper.database;

      await db.update(
        'chat_sessions',
        {
          'title': title,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      debugPrint('✅ Session title updated: $sessionId');
    } catch (e) {
      debugPrint('❌ Failed to update session title: $e');
    }
  }

  /// Archive a session
  Future<void> archiveSession(String sessionId) async {
    try {
      final db = await _dbHelper.database;

      await db.update(
        'chat_sessions',
        {
          'is_archived': 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      debugPrint('✅ Session archived: $sessionId');
    } catch (e) {
      debugPrint('❌ Failed to archive session: $e');
    }
  }

  /// Delete a session and all its messages
  Future<void> deleteSession(String sessionId) async {
    try {
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // Delete all messages in the session
        await txn.delete(
          'chat_messages',
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );

        // Delete the session
        await txn.delete(
          'chat_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        );
      });

      debugPrint('✅ Session deleted: $sessionId');
    } catch (e) {
      debugPrint('❌ Failed to delete session: $e');
    }
  }

  /// Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    try {
      final db = await _dbHelper.database;

      await db.delete(
        'chat_messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );

      debugPrint('✅ Message deleted: $messageId');
    } catch (e) {
      debugPrint('❌ Failed to delete message: $e');
    }
  }

  /// Get message count for a session (excluding system messages)
  Future<int> getMessageCount(String sessionId) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chat_messages WHERE session_id = ? AND type != ?',
        [sessionId, 'system'],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('❌ Failed to get message count: $e');
      return 0;
    }
  }

  /// Update session's last message info
  Future<void> _updateSessionLastMessage(ChatMessage message) async {
    if (message.sessionId == null) {
      debugPrint('⚠️ Cannot update session - message has no sessionId');
      return;
    }

    try {
      final db = await _dbHelper.database;
      final messageCount = await getMessageCount(message.sessionId!);

      final updateData = {
        'updated_at': message.timestamp.millisecondsSinceEpoch,
        'last_message_at': message.timestamp.millisecondsSinceEpoch,
        'last_message_preview': message.preview,
        'message_count': messageCount,
      };

      final rowsAffected = await db.update(
        'chat_sessions',
        updateData,
        where: 'id = ?',
        whereArgs: [message.sessionId],
      );

      if (rowsAffected > 0) {
        debugPrint('✅ Updated session ${message.sessionId}: $messageCount messages, preview: "${message.preview}"');
      } else {
        debugPrint('⚠️ Session ${message.sessionId} not found for update');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to update session last message: $e');
      debugPrint('⚠️ Stack trace: ${StackTrace.current}');
      // Don't rethrow - this is not critical, but log the full error
    }
  }

  /// Search messages by content
  Future<List<ChatMessage>> searchMessages(String query) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'chat_messages',
        where: 'content LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'timestamp DESC',
        limit: 50,
      );

      return maps.map((map) => ChatMessage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Failed to search messages: $e');
      return [];
    }
  }

  /// Export conversation as text
  Future<String> exportConversation(String sessionId) async {
    try {
      final messages = await getMessages(sessionId);
      final buffer = StringBuffer();

      buffer.writeln('Conversation Export');
      buffer.writeln('Date: ${DateTime.now().toString()}');
      buffer.writeln('Total Messages: ${messages.length}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final message in messages) {
        buffer.writeln('[${message.type.displayName}] - ${message.formattedTime}');
        buffer.writeln(message.content);

        if (message.hasVerses) {
          buffer.writeln('\nRelevant Verses:');
          for (final verse in message.verses) {
            buffer.writeln('  ${verse.reference}: ${verse.text}');
          }
        }

        buffer.writeln();
        buffer.writeln('-' * 50);
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('❌ Failed to export conversation: $e');
      return '';
    }
  }

  /// Clear old conversations (older than specified days)
  Future<int> clearOldConversations(int daysOld) async {
    try {
      final db = await _dbHelper.database;
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: daysOld))
          .millisecondsSinceEpoch;

      // Get sessions to delete
      final sessionsToDelete = await db.query(
        'chat_sessions',
        columns: ['id'],
        where: 'updated_at < ?',
        whereArgs: [cutoffTime],
      );

      int deletedCount = 0;

      for (final session in sessionsToDelete) {
        await deleteSession(session['id'] as String);
        deletedCount++;
      }

      debugPrint('✅ Cleared $deletedCount old conversations');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Failed to clear old conversations: $e');
      return 0;
    }
  }
}
