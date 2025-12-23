/// Intent Detection Service
/// Determines whether user wants pastoral guidance vs theological discussion
///
/// This helps the AI respond appropriately:
/// - Guidance: Empathetic, supportive, counseling tone
/// - Discussion: Conversational, educational, exploratory tone

import 'package:flutter/foundation.dart';

/// User's conversation intent
enum ConversationIntent {
  /// Seeking emotional support, prayer, pastoral care
  guidance,

  /// Wanting to learn, discuss theology, understand concepts
  discussion,

  /// Casual conversation about faith topics
  casual,
}

/// Result of intent detection
class IntentResult {
  final ConversationIntent intent;
  final double confidence;
  final List<String> detectedPatterns;

  const IntentResult({
    required this.intent,
    required this.confidence,
    required this.detectedPatterns,
  });
}

/// Service for detecting user's conversation intent
class IntentDetectionService {
  // ============================================================================
  // GUIDANCE PATTERNS (Seeking help, support, prayer)
  // ============================================================================

  static const List<String> _guidancePatterns = [
    // Emotional distress
    'i m struggling',
    'i m feeling',
    'i feel',
    'i m worried',
    'i m anxious',
    'i m depressed',
    'i m afraid',
    'i m scared',
    'i m lost',
    'i m hurting',
    'i m broken',

    // Requests for help
    'help me',
    'i need help',
    'i need guidance',

    // Life situations
    'i m going through',
    'i m dealing with',
    'i m facing',
    'i don t know what to do',
    'what should i do',
    'how do i handle',
    'how do i cope',
    'how can i deal',

    // Direct support requests
    'i need support',
    'i need encouragement',
    'i need hope',
    'i need wisdom',
    'i need advice',
    'counsel me',
    'guide me',

    // Life-threatening crisis (immediate pastoral care needed)
    'suicidal',
    'kill myself',
    'want to die',
    'end my life',
    'taking my life',
    'suicide',

    // Abuse (safety concern)
    'being abused',
    'abused',
    'abuse',
    'abusive',

    // Self-harm
    'self harm',
    'cutting myself',
    'hurting myself',
    'harm myself',

    // Faith crisis (harder to detect from tone alone)
    'losing faith',
    'lost faith',
    'losing my faith',
    'doubt god',
    'doubting god',
    'questioning god',
    'where is god',
    'god abandoned me',
    'feel abandoned by god',
    'god doesn t care',

    // Major life trauma (often stated matter-of-factly)
    'someone died',
    'died',
    'death of',
    'passed away',
    'funeral',
    'divorce',
    'divorcing',
    'getting divorced',
    'miscarriage',
    'lost the baby',
    'lost my baby',
  ];

  // ============================================================================
  // DISCUSSION PATTERNS (Intellectual curiosity, learning)
  // ============================================================================

  static const List<String> _discussionPatterns = [
    // Questions about theology
    'what does the bible say',
    'what does scripture say',
    'what does god say',
    'what does jesus say',
    'where in the bible',
    'is it biblical',
    'is it scriptural',

    // Explanation requests
    'can you explain',
    'help me understand',
    'i want to understand',
    'i m curious about',
    'i m wondering about',
    'what does it mean',
    'what is the meaning',
    'tell me about',
    'teach me about',

    // Discussion starters
    'let s talk about',
    'let s discuss',
    'i d like to discuss',
    'what are your thoughts',
    'what do you think about',
    'i ve been thinking about',
    'i ve been studying',

    // Doctrinal questions (present and past tense)
    'what is',
    'what was',
    'who is',
    'who was',
    'why is',
    'why was',
    'why did',
    'how is',
    'how was',
    'how did',
    'when is',
    'when was',
    'when did',
    'what happened',
    'what s the difference between',
    'compare',
    'contrast',
  ];

  // ============================================================================
  // CASUAL PATTERNS (General conversation)
  // ============================================================================

  static const List<String> _casualPatterns = [
    // Greetings
    'hello',
    'hi',
    'hey',
    'good morning',
    'good afternoon',
    'good evening',

    // General statements
    'that s interesting',
    'i see',
    'okay',
    'thanks',
    'thank you',
    'got it',
    'i understand',

    // Follow-ups
    'tell me more',
    'continue',
    'what else',
    'anything else',
  ];

  // ============================================================================
  // SPANISH GUIDANCE PATTERNS (Buscando ayuda, apoyo, oración)
  // ============================================================================

  static const List<String> _spanishGuidancePatterns = [
    // Angustia emocional
    'estoy luchando',
    'me siento',
    'siento',
    'estoy preocupado',
    'estoy preocupada',
    'estoy ansioso',
    'estoy ansiosa',
    'estoy deprimido',
    'estoy deprimida',
    'tengo miedo',
    'estoy asustado',
    'estoy asustada',
    'estoy perdido',
    'estoy perdida',
    'estoy sufriendo',
    'estoy roto',
    'estoy rota',

    // Solicitudes de ayuda
    'ayúdame',
    'ayudame',
    'necesito ayuda',
    'necesito orientación',
    'necesito guía',

    // Situaciones de vida
    'estoy pasando por',
    'estoy enfrentando',
    'no sé qué hacer',
    'no se que hacer',
    'qué debo hacer',
    'que debo hacer',
    'cómo manejo',
    'como manejo',
    'cómo puedo lidiar',
    'como puedo lidiar',

    // Solicitudes directas de apoyo
    'necesito apoyo',
    'necesito aliento',
    'necesito esperanza',
    'necesito sabiduría',
    'necesito consejo',
    'aconséjame',
    'aconsejame',
    'guíame',
    'guiame',

    // Crisis de vida (cuidado pastoral inmediato)
    'suicida',
    'matarme',
    'quiero morir',
    'acabar con mi vida',
    'terminar con mi vida',
    'suicidio',

    // Abuso
    'siendo abusado',
    'siendo abusada',
    'abusado',
    'abusada',
    'abuso',
    'abusivo',
    'abusiva',

    // Autolesión
    'hacerme daño',
    'cortándome',
    'lastimarme',

    // Crisis de fe
    'perdiendo la fe',
    'perdí la fe',
    'perdi la fe',
    'dudar de dios',
    'dudando de dios',
    'cuestionando a dios',
    'dónde está dios',
    'donde esta dios',
    'dios me abandonó',
    'dios me abandono',
    'me siento abandonado por dios',
    'dios no le importa',

    // Trauma de vida mayor
    'alguien murió',
    'alguien murio',
    'murió',
    'murio',
    'muerte de',
    'falleció',
    'fallecio',
    'funeral',
    'divorcio',
    'divorciando',
    'divorciándome',
    'aborto espontáneo',
    'aborto espontaneo',
    'perdí el bebé',
    'perdi el bebe',
  ];

  // ============================================================================
  // SPANISH DISCUSSION PATTERNS (Curiosidad intelectual, aprendizaje)
  // ============================================================================

  static const List<String> _spanishDiscussionPatterns = [
    // Preguntas sobre teología
    'qué dice la biblia',
    'que dice la biblia',
    'qué dice la escritura',
    'que dice la escritura',
    'qué dice dios',
    'que dice dios',
    'qué dice jesús',
    'que dice jesus',
    'dónde en la biblia',
    'donde en la biblia',
    'es bíblico',
    'es biblico',

    // Solicitudes de explicación
    'puedes explicar',
    'ayúdame a entender',
    'ayudame a entender',
    'quiero entender',
    'tengo curiosidad sobre',
    'me pregunto sobre',
    'qué significa',
    'que significa',
    'cuál es el significado',
    'cual es el significado',
    'cuéntame sobre',
    'cuentame sobre',
    'enséñame sobre',
    'enseñame sobre',

    // Iniciadores de discusión
    'hablemos de',
    'hablemos sobre',
    'discutamos',
    'me gustaría discutir',
    'qué piensas sobre',
    'que piensas sobre',
    'qué opinas de',
    'que opinas de',
    'he estado pensando en',
    'he estado estudiando',

    // Preguntas doctrinales
    'qué es',
    'que es',
    'quién es',
    'quien es',
    'por qué es',
    'por que es',
    'cómo es',
    'como es',
    'cuándo es',
    'cuando es',
    'qué pasó',
    'que paso',
    'cuál es la diferencia entre',
    'cual es la diferencia entre',
    'compara',
    'contrasta',
  ];

  // ============================================================================
  // SPANISH CASUAL PATTERNS (Conversación general)
  // ============================================================================

  static const List<String> _spanishCasualPatterns = [
    // Saludos
    'hola',
    'buenos días',
    'buenos dias',
    'buenas tardes',
    'buenas noches',
    'qué tal',
    'que tal',

    // Declaraciones generales
    'eso es interesante',
    'ya veo',
    'entiendo',
    'de acuerdo',
    'gracias',
    'muchas gracias',
    'bendiciones',
    'dios te bendiga',

    // Seguimientos
    'cuéntame más',
    'cuentame mas',
    'continúa',
    'continua',
    'qué más',
    'que mas',
  ];

  /// Detect user's conversation intent
  IntentResult detectIntent(String userInput, {String language = 'en'}) {
    // Handle empty/whitespace input - default to guidance
    if (userInput.trim().isEmpty) {
      return const IntentResult(
        intent: ConversationIntent.guidance,
        confidence: 0.3,
        detectedPatterns: [],
      );
    }

    final normalized = _normalizeText(userInput);

    // Select patterns based on language
    final guidancePatterns = language == 'es' ? _spanishGuidancePatterns : _guidancePatterns;
    final discussionPatterns = language == 'es' ? _spanishDiscussionPatterns : _discussionPatterns;
    final casualPatterns = language == 'es' ? _spanishCasualPatterns : _casualPatterns;

    // Count pattern matches for each intent
    int guidanceScore = 0;
    int discussionScore = 0;
    int casualScore = 0;

    List<String> guidanceMatches = [];
    List<String> discussionMatches = [];
    List<String> casualMatches = [];

    // Check guidance patterns
    for (final pattern in guidancePatterns) {
      if (normalized.contains(pattern)) {
        // Skip "help me" if it's followed by "understand [specific topic]" (educational context)
        // But keep "help me" for "help me understand" alone (support request)
        if (pattern == 'help me' && normalized.contains('help me understand')) {
          // Check if there's a topic after "understand"
          final understandIndex = normalized.indexOf('help me understand') + 'help me understand'.length;
          final wordsAfter = normalized.substring(understandIndex).trim();
          if (wordsAfter.isNotEmpty) {
            // Has topic like "help me understand Romans 8" - skip guidance pattern
            continue;
          }
        }

        guidanceScore += 3; // Weight guidance higher (emotional needs prioritized)
        guidanceMatches.add(pattern);
      }
    }

    // Check discussion patterns
    for (final pattern in discussionPatterns) {
      if (normalized.contains(pattern)) {
        discussionScore += 2;
        discussionMatches.add(pattern);
      }
    }

    // Check casual patterns (with word boundary check for short patterns)
    for (final pattern in casualPatterns) {
      if (_matchesWithWordBoundary(normalized, pattern)) {
        casualScore += 1;
        casualMatches.add(pattern);
      }
    }

    // Additional heuristics

    // Question marks suggest discussion/learning
    if (normalized.contains('?')) {
      // But "what should I do?" is guidance
      if (!normalized.contains('what should i') &&
          !normalized.contains('how do i') &&
          !normalized.contains('can you help')) {
        discussionScore += 1;
      }
    }

    // First-person emotional language suggests guidance
    // BUT exclude intellectual curiosity phrases (those are discussion)
    if ((normalized.contains('i m') || normalized.contains('i feel')) &&
        !normalized.contains('i m curious') &&
        !normalized.contains('i m wondering')) {
      guidanceScore += 2;
    }

    // "Truth", "real", "fake" often in challenging questions (treat as discussion)
    if (normalized.contains('truth') ||
        normalized.contains('real') ||
        normalized.contains('fake')) {
      discussionScore += 1;
    }

    // Determine primary intent
    ConversationIntent intent;
    double confidence;
    List<String> detectedPatterns;

    // If NO patterns match at all, default to GUIDANCE (safer than casual)
    if (guidanceScore == 0 && discussionScore == 0 && casualScore == 0) {
      intent = ConversationIntent.guidance;
      confidence = 0.3; // Low confidence, but guidance is safer default
      detectedPatterns = [];
    } else if (guidanceScore > discussionScore && guidanceScore > casualScore) {
      intent = ConversationIntent.guidance;
      confidence = _calculateConfidence(guidanceScore, discussionScore, casualScore);
      detectedPatterns = guidanceMatches;
    } else if (discussionScore >= guidanceScore && discussionScore > casualScore) {
      // Discussion wins if it ties or beats guidance AND beats casual
      intent = ConversationIntent.discussion;
      confidence = _calculateConfidence(discussionScore, guidanceScore, casualScore);
      detectedPatterns = discussionMatches;
    } else if (guidanceScore >= casualScore) {
      // Guidance wins ties with casual (safety tie-breaker)
      intent = ConversationIntent.guidance;
      confidence = _calculateConfidence(guidanceScore, discussionScore, casualScore);
      detectedPatterns = guidanceMatches;
    } else {
      intent = ConversationIntent.casual;
      confidence = _calculateConfidence(casualScore, guidanceScore, discussionScore);
      detectedPatterns = casualMatches;
    }

    // Log detection
    if (kDebugMode) {
      debugPrint('💬 [IntentDetection] Input: "$userInput"');
      debugPrint('   Intent: ${intent.name} (confidence: ${(confidence * 100).toStringAsFixed(0)}%)');
      debugPrint('   Scores: guidance=$guidanceScore, discussion=$discussionScore, casual=$casualScore');
      if (detectedPatterns.isNotEmpty) {
        debugPrint('   Patterns: ${detectedPatterns.take(3).join(", ")}');
      }
    }

    return IntentResult(
      intent: intent,
      confidence: confidence,
      detectedPatterns: detectedPatterns,
    );
  }

  /// Calculate confidence score (0.0 to 1.0)
  double _calculateConfidence(int primaryScore, int secondaryScore, int tertiaryScore) {
    if (primaryScore == 0) return 0.3; // Default low confidence

    final total = primaryScore + secondaryScore + tertiaryScore;
    if (total == 0) return 0.3;

    final ratio = primaryScore / total;

    // Scale confidence based on dominance
    if (ratio > 0.7) return 0.95; // Very confident
    if (ratio > 0.5) return 0.80; // Confident
    if (ratio > 0.4) return 0.65; // Somewhat confident
    return 0.50; // Low confidence
  }

  /// Normalize text for pattern matching
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Check if pattern matches with word boundaries
  /// Prevents "hi" from matching inside "this" or "everything"
  bool _matchesWithWordBoundary(String text, String pattern) {
    // For very short patterns (1-3 chars), require word boundaries
    if (pattern.length <= 3) {
      final words = text.split(' ');
      return words.contains(pattern);
    }

    // For longer patterns, use standard contains check
    return text.contains(pattern);
  }
}
