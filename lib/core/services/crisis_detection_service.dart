/// Crisis Detection Service
/// Detects crisis situations in user input and triggers appropriate interventions
///
/// Handles:
/// - Suicide ideation
/// - Self-harm
/// - Abuse (physical, sexual, emotional)
/// - Severe mental health crises

import 'package:flutter/foundation.dart';

/// Types of crises that can be detected
enum CrisisType {
  suicide,
  selfHarm,
  abuse,
}

/// Crisis detection result with type and matched keywords
class CrisisDetectionResult {
  final CrisisType type;
  final List<String> matchedKeywords;
  final String userInput;

  const CrisisDetectionResult({
    required this.type,
    required this.matchedKeywords,
    required this.userInput,
  });

  /// Get crisis hotline for this crisis type
  String getHotline({String language = 'en'}) {
    switch (type) {
      case CrisisType.suicide:
        return '988';
      case CrisisType.selfHarm:
        return language == 'es' ? 'Envía HOLA al 741741' : 'Text HOME to 741741';
      case CrisisType.abuse:
        return '800-656-4673';
    }
  }

  /// Get crisis message for this type
  String getMessage({String language = 'en'}) {
    if (language == 'es') {
      switch (type) {
        case CrisisType.suicide:
          return 'Detectamos que puedes estar teniendo pensamientos suicidas. Tu vida importa. '
              'Por favor llama al 988 (Línea de Vida de Prevención del Suicidio) ahora mismo. Están disponibles 24/7.';
        case CrisisType.selfHarm:
          return 'Detectamos que puedes estar considerando autolesionarte. No tienes que enfrentar esto solo/a. '
              'Por favor envía HOLA al 741741 (Crisis Text Line) para apoyo inmediato.';
        case CrisisType.abuse:
          return 'Detectamos que puedes estar experimentando abuso. Tu seguridad importa. '
              'Por favor llama a RAINN al 800-656-4673 para apoyo confidencial.';
      }
    } else {
      switch (type) {
        case CrisisType.suicide:
          return 'We detected you may be having thoughts of suicide. Your life matters. '
              'Please call 988 (Suicide & Crisis Lifeline) right now. They\'re available 24/7.';
        case CrisisType.selfHarm:
          return 'We detected you may be considering self-harm. You don\'t have to face this alone. '
              'Please text HOME to 741741 (Crisis Text Line) for immediate support.';
        case CrisisType.abuse:
          return 'We detected you may be experiencing abuse. Your safety matters. '
              'Please call RAINN at 800-656-4673 for confidential support.';
      }
    }
  }
}

/// Service for detecting crisis situations in user input
class CrisisDetectionService {
  // Suicide ideation keywords (direct + indirect patterns)
  static const List<String> _suicideKeywords = [
    // Direct statements
    'kill myself',
    'end it all',
    'dont want to be alive',
    'don t want to be alive',
    'dont want to live',
    'don t want to live',
    'better off dead',
    'suicide',
    'suicidal',
    'want to die',
    'end my life',
    'take my life',
    'no reason to live',
    'cant go on',
    'can t go on',
    'everyone would be better without me',
    'world would be better without me',
    'goodbye forever',
    'final message',

    // Indirect patterns - hopelessness & trapped feelings
    'no way out',
    'cant see a way out',
    'can t see a way out',
    'nothing will ever change',
    'never going to get better',
    'never gonna get better',
    'stuck forever',
    'trapped',
    'burden to everyone',
    'burden to others',
    'want to disappear',
    'cant do this anymore',
    'can t do this anymore',
    'drowning',
    'cant cope',
    'can t cope',
    'end the pain',
    'no point anymore',
    'no point in living',
    'give up on life',
    'giving up',
    'hopeless',
    'unbearable',
    'cant take it',
    'can t take it',
  ];

  // Self-harm keywords (direct + indirect patterns)
  static const List<String> _selfHarmKeywords = [
    // Direct statements
    'cut myself',
    'hurt myself',
    'self harm',
    'self-harm',
    'cutting',
    'burn myself',
    'burning myself',
    'want to hurt',
    'harming myself',
    'ive been hurting',
    'i ve been hurting',

    // Indirect patterns - risky behaviors & coping struggles
    'punish myself',
    'need to feel pain',
    'deserve to hurt',
    'deserve pain',
    'only way to cope',
    'only way i cope',
    'cant stop hurting',
    'can t stop hurting',
    'keep hurting',
    'feel numb',
    'need to feel something',
    'release the pain',
    'physical pain helps',
    'cutting helps',
    'scars',
    'fresh cuts',
    'relapsed',
  ];

  // Abuse keywords (direct + indirect patterns)
  static const List<String> _abuseKeywords = [
    // Direct statements
    'hitting me',
    'hurting me',
    'abusing me',
    'being abused',
    'im being abused',
    'i m being abused',
    'rape',
    'raped',
    'assault',
    'assaulted',
    'molest',
    'molested',
    'beating me',
    'violent',
    'threatens me',
    'afraid for my safety',
    'physically hurt',

    // Indirect patterns - fear, control, safety concerns
    'dont feel safe at home',
    'don t feel safe at home',
    'afraid to go home',
    'scared of my partner',
    'scared of my spouse',
    'controls everything i do',
    'wont let me leave',
    'won t let me leave',
    'isolates me',
    'tracks my phone',
    'checks my messages',
    'screams at me',
    'yells at me constantly',
    'calls me names',
    'makes me feel worthless',
    'blames me for everything',
    'punches walls',
    'destroys my things',
    'breaks things when angry',
    'afraid what they ll do',
    'afraid what they will do',
    'walking on eggshells',
    'cant talk about it',
    'can t talk about it',
    'made me do it',
    'forced me',
  ];

  // ============================================================================
  // SPANISH CRISIS KEYWORDS
  // ============================================================================

  // Spanish suicide keywords
  static const List<String> _spanishSuicideKeywords = [
    // Direct statements
    'matarme',
    'acabar con todo',
    'terminar con todo',
    'no quiero vivir',
    'no quiero estar vivo',
    'no quiero estar viva',
    'mejor muerto',
    'mejor muerta',
    'suicidio',
    'suicida',
    'quiero morir',
    'terminar con mi vida',
    'acabar con mi vida',
    'quitarme la vida',
    'quitar la vida', // Infinitive form (voy a quitar la vida)
    'no hay razón para vivir',
    'no hay razon para vivir',
    'no veo ninguna razón para vivir',
    'no veo ninguna razon para vivir',
    'no puedo seguir',
    'todos estarían mejor sin mi',
    'todos estarian mejor sin mi',
    'todos estarían mejor sin mí', // With accent on mí
    'todos estarian mejor sin mí',
    'el mundo estaría mejor sin mi',
    'el mundo estaria mejor sin mi',
    'el mundo estaría mejor sin mí',
    'el mundo estaria mejor sin mí',
    'adiós para siempre',
    'adios para siempre',
    'adiós a todos para siempre', // Extended goodbye
    'adios a todos para siempre',
    'mensaje final',

    // Indirect patterns
    'no hay salida',
    'no veo salida',
    'nada va a cambiar',
    'nunca va a mejorar',
    'atrapado para siempre',
    'atrapada para siempre',
    'atrapado',
    'atrapada',
    'una carga para todos',
    'carga para otros',
    'quiero desaparecer',
    'no puedo más',
    'no puedo mas',
    'no aguanto más',
    'no aguanto mas',
    'ahogarme',
    'no puedo lidiar',
    'terminar el dolor',
    'acabar el dolor',
    'no tiene sentido',
    'no hay sentido en vivir',
    'rendirme en la vida',
    'rendiéndome',
    'rindiendome',
    'sin esperanza',
    'insoportable',
    'no lo soporto',
  ];

  // Spanish self-harm keywords
  static const List<String> _spanishSelfHarmKeywords = [
    // Direct statements
    'cortarme',
    'cortando', // Gerund form (estado cortando)
    'cortar', // Infinitive (quiero cortar)
    'hacerme daño',
    'hacerme dano',
    'lastimarme',
    'autolesión',
    'autolesion',
    'auto lesión',
    'auto lesion',
    'cortándome',
    'cortandome',
    'estado cortando', // He estado cortando
    'estado cortándome',
    'estado cortandome',
    'cortarse', // Infinitive reflexive (hablando de cortarse)
    'quemarme',
    'quemándome',
    'quemandome',
    'quemando', // Gerund (estoy quemando)
    'quiero hacerme daño',
    'quiero hacerme dano',
    'he estado haciéndome daño',
    'he estado haciendome dano',

    // Indirect patterns
    'castigarme',
    'necesito sentir dolor',
    'merezco dolor',
    'merezco sufrir',
    'única forma de lidiar',
    'unica forma de lidiar',
    'no puedo dejar de hacerme daño',
    'no puedo dejar de hacerme dano',
    'sigo haciéndome daño',
    'sigo haciendome dano',
    'me siento vacío',
    'me siento vacio',
    'me siento vacía',
    'me siento vacia',
    'necesito sentir algo',
    'liberar el dolor',
    'dolor físico ayuda',
    'dolor fisico ayuda',
    'cortarme ayuda',
    'cicatrices',
    'cortes frescos',
    'cortes', // Cuts (found cuts on arms)
    'encontré cortes', // Found cuts
    'encontre cortes',
    'tiene cortes', // Has cuts
    'recaí',
    'recai',
  ];

  // Spanish abuse keywords
  static const List<String> _spanishAbuseKeywords = [
    // Direct statements
    'me pega',
    'me golpea',
    'me está pegando',
    'me esta pegando',
    'me lastima',
    'me está lastimando',
    'me esta lastimando',
    'me maltrata',
    'me está maltratando',
    'me esta maltratando',
    'maltratando',
    'maltratar',
    'maltratado',
    'maltratada',
    'maltrato',
    'abusando de mí',
    'abusando de mi',
    'siendo abusado',
    'siendo abusada',
    'me están abusando',
    'me estan abusando',
    'violación',
    'violacion',
    'violado',
    'violada',
    'asalto',
    'agresión',
    'agresion',
    'abusar',
    'abuso',
    'golpeándome',
    'golpeandome',
    'violento',
    'violenta',
    'violencia', // General violence
    'violencia en casa', // Violence at home
    'me amenaza',
    'temo por mi seguridad',
    'tengo miedo por mi seguridad', // Variant with "tengo miedo"
    'miedo por mi seguridad',
    'físicamente lastimado',
    'fisicamente lastimado',
    'físicamente lastimada',
    'fisicamente lastimada',

    // Indirect patterns
    'no me siento seguro en casa',
    'no me siento segura en casa',
    'tengo miedo de ir a casa',
    'miedo de mi pareja',
    'miedo de mi esposo',
    'miedo de mi esposa',
    'controla todo lo que hago',
    'no me deja salir',
    'me aísla',
    'me aisla',
    'revisa mi teléfono',
    'revisa mi telefono',
    'revisa mis mensajes',
    'me grita',
    'grita constantemente',
    'me insulta',
    'me hace sentir sin valor',
    'me culpa de todo',
    'golpea las paredes',
    'destruye mis cosas',
    'rompe cosas cuando está enojado',
    'rompe cosas cuando esta enojado',
    'rompe cosas cuando está enojada',
    'rompe cosas cuando esta enojada',
    'tengo miedo de lo que hará',
    'tengo miedo de lo que hara',
    'caminando en cáscaras de huevo',
    'caminando en cascaras de huevo',
    'no puedo hablar de eso',
    'me obligó',
    'me obligo',
    'me forzó',
    'me forzo',
  ];

  /// Detect if user input contains crisis keywords
  /// Returns CrisisDetectionResult if crisis detected, null otherwise
  CrisisDetectionResult? detectCrisis(String userInput) {
    if (userInput.isEmpty) return null;

    final normalized = _normalizeInput(userInput);

    // Check for suicide keywords (highest priority) - English + Spanish
    final suicideMatches = _findMatches(normalized, [..._suicideKeywords, ..._spanishSuicideKeywords]);
    if (suicideMatches.isNotEmpty) {
      return CrisisDetectionResult(
        type: CrisisType.suicide,
        matchedKeywords: suicideMatches,
        userInput: userInput,
      );
    }

    // Check for abuse keywords (second priority) - English + Spanish
    // Abuse is prioritized over self-harm because it indicates immediate external danger
    final abuseMatches = _findMatches(normalized, [..._abuseKeywords, ..._spanishAbuseKeywords]);
    if (abuseMatches.isNotEmpty) {
      return CrisisDetectionResult(
        type: CrisisType.abuse,
        matchedKeywords: abuseMatches,
        userInput: userInput,
      );
    }

    // Check for self-harm keywords - English + Spanish
    final selfHarmMatches = _findMatches(normalized, [..._selfHarmKeywords, ..._spanishSelfHarmKeywords]);
    if (selfHarmMatches.isNotEmpty) {
      return CrisisDetectionResult(
        type: CrisisType.selfHarm,
        matchedKeywords: selfHarmMatches,
        userInput: userInput,
      );
    }

    return null;
  }

  /// Normalize user input for keyword matching
  /// Preserves Spanish accents (á, é, í, ó, ú, ñ) and other Unicode characters
  String _normalizeInput(String input) {
    return input
        .toLowerCase()
        .trim()
        // Remove common punctuation but preserve letters (including accented ones)
        .replaceAll(RegExp('[.,;:!?¡¿()\\[\\]{}"\'`]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Find keyword matches in normalized input
  List<String> _findMatches(String normalizedInput, List<String> keywords) {
    final matches = <String>[];

    for (final keyword in keywords) {
      // Check for exact phrase match
      if (normalizedInput.contains(keyword.toLowerCase())) {
        matches.add(keyword);
      }
    }

    return matches;
  }

  /// Check if input is likely a crisis based on patterns
  /// This is a more lenient check for borderline cases
  /// Supports both English and Spanish patterns
  bool isPotentialCrisis(String userInput) {
    final normalized = _normalizeInput(userInput);

    // Check for concerning patterns (case insensitive)
    // English patterns
    final concerningPatterns = [
      RegExp(r"\b(no|don\s*t|dont)\s+(point|reason|want)\s+(to\s+)?(live|go\s+on)\b", caseSensitive: false),
      RegExp(r"\b(can\s*t|cant)\s+(take\s+it|do\s+this)\s+(anymore|any\s+more)\b", caseSensitive: false),
      RegExp(r'\b(give|giving)\s+up\b', caseSensitive: false),
      RegExp(r'\b(hopeless|worthless)\b', caseSensitive: false),
      RegExp(r'\b(any|no)\s+reason\s+to\s+live\b', caseSensitive: false),

      // Spanish patterns
      RegExp(r'\b(no\s+veo|ninguna)\s+(razón|razon)\s+para\s+vivir\b', caseSensitive: false), // No reason to live
      RegExp(r'\bno\s+(puedo|aguanto)\s+más\b', caseSensitive: false), // Can't take it anymore
      RegExp(r'\bno\s+(puedo|aguanto)\s+mas\b', caseSensitive: false), // Without accent
      RegExp(r'\b(rendirse|rindiéndome|rindiendome|rindiendo|rindiéndose)\b', caseSensitive: false), // Giving up
      RegExp(r'\bsin\s+esperanza\b', caseSensitive: false), // Hopeless
      RegExp(r'\binsoportable\b', caseSensitive: false), // Unbearable
      RegExp(r'\batrapado\b', caseSensitive: false), // Trapped
      RegExp(r'\batrapada\b', caseSensitive: false), // Trapped (feminine)
      RegExp(r'\bnada\s+va\s+a\s+cambiar\b', caseSensitive: false), // Nothing will change
      RegExp(r'\bnunca\s+va\s+a\s+mejorar\b', caseSensitive: false), // It will never get better
    ];

    for (final pattern in concerningPatterns) {
      if (pattern.hasMatch(normalized)) {
        return true;
      }
    }

    return false;
  }

  /// Get severity level (0-10) of detected crisis
  /// Used for logging and analytics, not for decision making
  int getCrisisSeverity(CrisisDetectionResult result) {
    switch (result.type) {
      case CrisisType.suicide:
        // Suicide is always maximum severity
        return 10;
      case CrisisType.selfHarm:
        // Self-harm is high severity
        return 8;
      case CrisisType.abuse:
        // Abuse is high severity
        return 9;
    }
  }

  /// Log crisis detection (for monitoring and improvement)
  void logCrisisDetection(CrisisDetectionResult result) {
    if (kDebugMode) {
    }

    // Do NOT log actual user input - privacy violation
  }
}
