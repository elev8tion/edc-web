import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/services/conversation_service.dart';
import 'package:everyday_christian/models/chat_message.dart';

void main() {
  group('ConversationService Web Compilation Tests', () {
    test('Service instantiates', () {
      expect(() => ConversationService(), returnsNormally);
    });

    test('All public methods compile', () {
      final service = ConversationService();

      // Message management
      expect(service.saveMessage, isA<Function>());
      expect(service.saveMessages, isA<Function>());
      expect(service.getMessages, isA<Function>());
      expect(service.getRecentMessages, isA<Function>());
      expect(service.deleteMessage, isA<Function>());
      expect(service.getMessageCount, isA<Function>());
      expect(service.searchMessages, isA<Function>());

      // Session management
      expect(service.createSession, isA<Function>());
      expect(service.getSessions, isA<Function>());
      expect(service.getLastActiveSession, isA<Function>());
      expect(service.sessionExists, isA<Function>());
      expect(service.updateSessionTitle, isA<Function>());
      expect(service.archiveSession, isA<Function>());
      expect(service.deleteSession, isA<Function>());

      // Export and cleanup
      expect(service.exportConversation, isA<Function>());
      expect(service.clearOldConversations, isA<Function>());
    });

    test('ChatMessage model serialization', () {
      final message = ChatMessage.user(
        content: 'Test message',
        userId: 'user1',
        sessionId: 'session1',
      );

      // Test toMap
      final map = message.toMap();
      expect(map, isA<Map<String, dynamic>>());
      expect(map['content'], 'Test message');
      expect(map['type'], 'user');
      expect(map['session_id'], 'session1');

      // Test fromMap
      final reconstructed = ChatMessage.fromMap(map);
      expect(reconstructed.content, message.content);
      expect(reconstructed.type, message.type);
      expect(reconstructed.sessionId, message.sessionId);
    });

    test('ChatMessage factory constructors', () {
      // User message
      final userMsg = ChatMessage.user(content: 'Hello');
      expect(userMsg.type, MessageType.user);
      expect(userMsg.isUser, true);
      expect(userMsg.isAI, false);

      // AI message
      final aiMsg = ChatMessage.ai(content: 'Hi there');
      expect(aiMsg.type, MessageType.ai);
      expect(aiMsg.isUser, false);
      expect(aiMsg.isAI, true);

      // System message
      final sysMsg = ChatMessage.system(content: 'System notification');
      expect(sysMsg.type, MessageType.system);
      expect(sysMsg.isSystem, true);
    });

    test('ChatMessage helper methods', () {
      final message = ChatMessage.user(
        content: 'This is a very long message that should be truncated for the preview',
        sessionId: 'session1',
      );

      // Preview should truncate long content
      expect(message.preview.length, lessThanOrEqualTo(50));

      // formattedTime should return a string
      expect(message.formattedTime, isA<String>());

      // hasVerses should be false for message without verses
      expect(message.hasVerses, false);
    });

    test('MessageType enum extensions', () {
      expect(MessageType.user.displayName, 'You');
      expect(MessageType.ai.displayName, 'AI Assistant');
      expect(MessageType.system.displayName, 'System');

      expect(MessageType.user.isFromUser, true);
      expect(MessageType.ai.isFromAI, true);
      expect(MessageType.system.isSystem, true);
    });

    test('MessageStatus enum extensions', () {
      expect(MessageStatus.sending.isPending, true);
      expect(MessageStatus.sent.isComplete, true);
      expect(MessageStatus.delivered.isComplete, true);
      expect(MessageStatus.failed.isFailed, true);
    });

    test('MessageGroup helper class', () {
      final msg1 = ChatMessage.user(content: 'Message 1');
      final msg2 = ChatMessage.user(content: 'Message 2');

      // Should group messages of same type
      expect(MessageGroup.shouldGroup(msg1, msg2), true);

      // Create groups from messages
      final groups = MessageGroup.fromMessages([msg1, msg2]);
      expect(groups, isA<List<MessageGroup>>());
      expect(groups.length, greaterThan(0));
    });

    test('ChatMessage copyWith', () {
      final original = ChatMessage.user(content: 'Original');
      final modified = original.copyWith(content: 'Modified');

      expect(modified.content, 'Modified');
      expect(modified.id, original.id);
      expect(modified.type, original.type);
    });

    test('ChatMessage JSON serialization', () {
      final message = ChatMessage.ai(content: 'Test');

      // toJson
      final json = message.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['content'], 'Test');

      // fromJson
      final reconstructed = ChatMessage.fromJson(json);
      expect(reconstructed.content, message.content);
      expect(reconstructed.type, message.type);
    });
  });
}
