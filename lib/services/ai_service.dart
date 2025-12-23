import '../models/chat_message.dart';
import '../models/bible_verse.dart';

/// Abstract interface for AI services
abstract class AIService {
  /// Initialize the AI service
  Future<void> initialize();

  /// Check if the AI service is ready to use
  bool get isReady;

  /// Generate a response to user input
  Future<AIResponse> generateResponse({
    required String userInput,
    List<ChatMessage> conversationHistory = const [],
    Map<String, dynamic>? context,
    String language = 'en',
  });

  /// Generate a response with streaming (for real-time feel)
  Stream<String> generateResponseStream({
    required String userInput,
    List<ChatMessage> conversationHistory = const [],
    Map<String, dynamic>? context,
    String language = 'en',
  });

  /// Get relevant Bible verses for a topic
  Future<List<BibleVerse>> getRelevantVerses(String topic, {int limit = 3});

  /// Dispose of resources
  Future<void> dispose();
}

/// Response from AI service
class AIResponse {
  final String content;
  final List<BibleVerse> verses;
  final Map<String, dynamic>? metadata;
  final Duration processingTime;
  final double confidence;

  const AIResponse({
    required this.content,
    this.verses = const [],
    this.metadata,
    required this.processingTime,
    this.confidence = 1.0,
  });

  /// Create a response with error
  factory AIResponse.error(String error) {
    return AIResponse(
      content: 'I apologize, but I\'m having trouble processing your request right now. Please try again.',
      processingTime: Duration.zero,
      confidence: 0.0,
      metadata: {'error': error},
    );
  }

  /// Check if response has an error
  bool get hasError => metadata?['error'] != null;

  /// Get error message if any
  String? get error => metadata?['error'] as String?;
}

/// Configuration for AI responses
class AIConfig {
  final double temperature;
  final int maxTokens;
  final List<String> preferredThemes;
  final String responseStyle;
  final bool includeVerses;
  final int maxVerses;

  const AIConfig({
    this.temperature = 0.7,
    this.maxTokens = 500,
    this.preferredThemes = const ['comfort', 'hope', 'strength'],
    this.responseStyle = 'compassionate',
    this.includeVerses = true,
    this.maxVerses = 3,
  });

  /// Create config for different response types
  factory AIConfig.forSituation(String situation) {
    switch (situation.toLowerCase()) {
      case 'anxiety':
      case 'worry':
        return const AIConfig(
          temperature: 0.6,
          preferredThemes: ['peace', 'comfort', 'trust'],
          responseStyle: 'calming',
        );
      case 'depression':
      case 'sadness':
        return const AIConfig(
          temperature: 0.7,
          preferredThemes: ['hope', 'comfort', 'love'],
          responseStyle: 'encouraging',
        );
      case 'guidance':
      case 'decision':
        return const AIConfig(
          temperature: 0.5,
          preferredThemes: ['wisdom', 'guidance', 'discernment'],
          responseStyle: 'wise',
        );
      case 'strength':
      case 'challenge':
        return const AIConfig(
          temperature: 0.8,
          preferredThemes: ['strength', 'courage', 'perseverance'],
          responseStyle: 'empowering',
        );
      default:
        return const AIConfig();
    }
  }
}

/// Prompt templates for biblical guidance
class BiblicalPrompts {
  static const String systemPrompt = '''
You are a compassionate Christian AI assistant that provides biblical guidance and encouragement. Your role is to:

1. Listen with empathy and understanding
2. Provide relevant biblical wisdom and verses
3. Offer practical spiritual guidance
4. Encourage faith and hope
5. Be non-judgmental and loving

Guidelines:
- Always respond with love and compassion
- Include relevant Bible verses when appropriate
- Provide practical spiritual guidance
- Avoid theological debates or denominational issues
- Focus on comfort, hope, and encouragement
- Keep responses conversational and personal
- Acknowledge the person's feelings and struggles

Response style: Warm, encouraging, biblically grounded, and practical.
''';

  static String buildUserPrompt({
    required String userInput,
    List<String> preferredThemes = const [],
    String responseStyle = 'compassionate',
    List<ChatMessage> conversationHistory = const [],
  }) {
    final buffer = StringBuffer();

    // Add conversation context if available
    if (conversationHistory.isNotEmpty) {
      buffer.writeln('Previous conversation context:');
      for (final message in conversationHistory.take(3)) {
        buffer.writeln('${message.type.name}: ${message.content}');
      }
      buffer.writeln();
    }

    // Add current user input
    buffer.writeln('Current user message: $userInput');

    // Add guidance for response
    buffer.writeln('\nPlease respond with:');
    buffer.writeln('1. Empathetic acknowledgment of their situation');
    buffer.writeln('2. Biblical encouragement and wisdom');
    buffer.writeln('3. Practical spiritual guidance');
    buffer.writeln('4. Hope and comfort');

    if (preferredThemes.isNotEmpty) {
      buffer.writeln('\nPreferred biblical themes: ${preferredThemes.join(", ")}');
    }

    buffer.writeln('\nResponse style: $responseStyle');
    buffer.writeln('Keep the response personal, warm, and encouraging (150-300 words).');

    return buffer.toString();
  }

  /// Get theme-specific prompt additions
  static Map<String, String> getThemePrompts() {
    return {
      'anxiety': 'Focus on God\'s peace, care, and presence. Emphasize casting worries on Him.',
      'depression': 'Emphasize hope, God\'s love, and His plans for good. Focus on His constant presence.',
      'strength': 'Highlight God\'s power working through weakness and His strength in difficult times.',
      'guidance': 'Focus on seeking God\'s wisdom, trusting His direction, and discernment.',
      'forgiveness': 'Emphasize God\'s grace, mercy, and the freedom found in forgiveness.',
      'purpose': 'Focus on God\'s unique plan, calling, and the value He places on each person.',
      'relationships': 'Emphasize love, forgiveness, unity, and biblical principles for relationships.',
      'fear': 'Focus on God\'s protection, courage, and the truth that He is always with us.',
      'doubt': 'Emphasize faith, God\'s faithfulness, and His understanding of our struggles.',
      'gratitude': 'Focus on thankfulness, God\'s blessings, and cultivating a grateful heart.',
    };
  }

  /// Detect themes from user input
  static List<String> detectThemes(String userInput) {
    final input = userInput.toLowerCase();
    final themes = <String>[];

    final themeKeywords = {
      'anxiety': ['anxious', 'worried', 'stress', 'overwhelmed', 'panic'],
      'depression': ['sad', 'depressed', 'hopeless', 'down', 'discouraged'],
      'strength': ['weak', 'tired', 'exhausted', 'struggle', 'difficult'],
      'guidance': ['decision', 'choice', 'direction', 'confused', 'lost'],
      'forgiveness': ['forgive', 'hurt', 'angry', 'resentment', 'bitter'],
      'purpose': ['purpose', 'meaning', 'calling', 'why', 'direction'],
      'relationships': ['relationship', 'marriage', 'family', 'friend', 'conflict'],
      'fear': ['afraid', 'scared', 'fear', 'nervous', 'terrified'],
      'doubt': ['doubt', 'question', 'faith', 'believe', 'uncertain'],
      'gratitude': ['thankful', 'grateful', 'blessed', 'appreciate'],
    };

    for (final entry in themeKeywords.entries) {
      if (entry.value.any((keyword) => input.contains(keyword))) {
        themes.add(entry.key);
      }
    }

    return themes.isEmpty ? ['comfort', 'hope'] : themes;
  }
}

/// Fallback responses when AI is unavailable
class FallbackResponses {
  static const List<Map<String, dynamic>> responses = [
    {
      'content': 'I understand you\'re going through a difficult time. Please know that God sees you and cares deeply about what you\'re facing. His love for you never changes, and His strength is available to help you through this season.',
      'verses': [
        {
          'book': 'Psalm',
          'chapter': 34,
          'verse': 18,
          'text': 'The Lord is near to the brokenhearted and saves the crushed in spirit.',
          'translation': 'ESV',
          'themes': ['comfort', 'presence'],
          'category': 'comfort'
        }
      ]
    },
    {
      'content': 'Thank you for sharing your heart. Remember that God\'s plans for you are good, even when circumstances feel overwhelming. He is working all things together for your ultimate good and His glory.',
      'verses': [
        {
          'book': 'Jeremiah',
          'chapter': 29,
          'verse': 11,
          'text': 'For I know the plans I have for you, declares the Lord, plans for welfare and not for evil, to give you a future and a hope.',
          'translation': 'ESV',
          'themes': ['hope', 'future', 'plans'],
          'category': 'hope'
        }
      ]
    },
    {
      'content': 'I hear the concern in your words, and I want you to know that God is your refuge and strength. When life feels uncertain, you can find peace in His unchanging character and faithful promises.',
      'verses': [
        {
          'book': 'Psalm',
          'chapter': 46,
          'verse': 1,
          'text': 'God is our refuge and strength, a very present help in trouble.',
          'translation': 'ESV',
          'themes': ['strength', 'refuge', 'help'],
          'category': 'strength'
        }
      ]
    }
  ];

  static AIResponse getRandomResponse() {
    final response = responses[DateTime.now().millisecond % responses.length];
    return AIResponse(
      content: response['content'] as String,
      verses: (response['verses'] as List)
          .map((v) => BibleVerse.fromJson(v))
          .toList(),
      processingTime: const Duration(milliseconds: 500),
      confidence: 0.8,
      metadata: {'source': 'fallback'},
    );
  }

  static AIResponse getThemeResponse(String theme) {
    final themeResponses = {
      'anxiety': {
        'content': 'I can sense the anxiety you\'re experiencing, and I want you to know that it\'s okay to feel this way. God invites you to cast all your anxieties on Him because He cares for you deeply. His peace, which surpasses all understanding, is available to guard your heart and mind.',
        'verses': [
          {
            'book': '1 Peter',
            'chapter': 5,
            'verse': 7,
            'text': 'Casting all your anxieties on him, because he cares for you.',
            'translation': 'ESV',
            'themes': ['anxiety', 'care', 'peace'],
            'category': 'peace'
          }
        ]
      },
      'strength': {
        'content': 'When we feel weak and overwhelmed, that\'s often when God\'s strength shines brightest through us. His power is made perfect in our weakness, and He promises to strengthen and help us through every challenge we face.',
        'verses': [
          {
            'book': 'Isaiah',
            'chapter': 41,
            'verse': 10,
            'text': 'Fear not, for I am with you; be not dismayed, for I am your God; I will strengthen you, I will help you, I will uphold you with my righteous right hand.',
            'translation': 'ESV',
            'themes': ['strength', 'courage', 'fear'],
            'category': 'strength'
          }
        ]
      }
    };

    final response = themeResponses[theme] ?? themeResponses['anxiety']!;
    return AIResponse(
      content: response['content'] as String,
      verses: (response['verses'] as List)
          .map((v) => BibleVerse.fromJson(v))
          .toList(),
      processingTime: const Duration(milliseconds: 300),
      confidence: 0.9,
      metadata: {'source': 'theme_fallback', 'theme': theme},
    );
  }
}