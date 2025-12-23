/// Content Filter Service
/// Filters AI-generated responses for harmful theology and hate speech
///
/// Blocks:
/// - Prosperity gospel language
/// - Spiritual bypassing phrases
/// - Toxic positivity
/// - Hate speech
/// - Medical overreach

import 'package:flutter/foundation.dart';

/// Filter result with reason if rejected
class FilterResult {
  final bool approved;
  final String? rejectionReason;
  final List<String>? matchedPhrases;

  const FilterResult({
    required this.approved,
    this.rejectionReason,
    this.matchedPhrases,
  });

  factory FilterResult.approved() {
    return const FilterResult(approved: true);
  }

  factory FilterResult.rejected(String reason, {List<String>? matched}) {
    return FilterResult(
      approved: false,
      rejectionReason: reason,
      matchedPhrases: matched,
    );
  }

  bool get isRejected => !approved;
}

/// Service for filtering harmful content from AI responses
class ContentFilterService {
  // Prosperity gospel phrases (health/wealth theology)
  static const List<String> _prosperityGospelBlacklist = [
    'name it and claim it',
    'name it claim it',
    'positive confession',
    'speak it into existence',
    'seed faith',
    'sow a seed',
    'health and wealth gospel',
    'faith will make you rich',
    'faith will make you wealthy',
    'god wants you rich',
    'god wants you wealthy',
    'god wants you healthy',
    'if you have enough faith you will be healed',
    'if you had more faith',
    'your faith is weak',
    'lack of faith made you sick',
    'sin caused your illness',
  ];

  // Spiritual bypassing (minimizing real suffering)
  static const List<String> _spiritualBypassingBlacklist = [
    'just pray harder',
    'just have more faith',
    'real christians don t',
    'real christians dont',
    'if you were really saved',
    'true believers don t',
    'true believers dont',
    'god won t give you more than you can handle',
    'god wont give you more than you can handle',
    'everything happens for a reason',
    'it s all part of god s plan',
    'its all part of gods plan',
    'this is god punishing you',
    'god is punishing you',
    'you must have done something',
    'what sin caused this',
  ];

  // Toxic positivity (forcing positivity, denying lament)
  static const List<String> _toxicPositivityBlacklist = [
    'don t be sad',
    'dont be sad',
    'you shouldn t feel',
    'you shouldnt feel',
    'stop being negative',
    'just think positive',
    'look on the bright side',
    'it could be worse',
    'other people have it worse',
    'you should be grateful',
    'count your blessings',
    'god doesn t want you sad',
    'god doesnt want you sad',
    'depression is a sin',
    'anxiety is a sin',
    'anger is a sin',
  ];

  // Legalism (works-based salvation, performance pressure)
  static const List<String> _legalismBlacklist = [
    'you must earn',
    'you have to earn',
    'work for your salvation',
    'not a real christian if',
    'real christians must',
    'god only loves you if',
    'god will love you more if',
    'you re not saved if',
    'you re going to hell for',
    'youre going to hell for',
  ];

  // Hate speech (targeting identity groups)
  static const List<String> _hateSpeechBlacklist = [
    // Note: Actual slurs removed for brevity
    // This would include racial slurs, homophobic slurs, etc.
    'all [group] are',
    'burn in hell',
    'god hates',
    'you deserve to suffer',
    'you re an abomination',
    'youre an abomination',
  ];

  // Medical overreach (giving medical advice inappropriately)
  static const List<String> _medicalOverreachBlacklist = [
    'don t take medication',
    'dont take medication',
    'stop your medication',
    'you don t need therapy',
    'you dont need therapy',
    'medication is weak',
    'antidepressants are wrong',
    'mental illness is not real',
    'mental illness isn t real',
    'mental illness isnt real',
    'just stop being depressed',
    'depression is a choice',
    'anxiety is a choice',
  ];

  /// Filter AI-generated response
  /// Returns FilterResult with approval status
  FilterResult filterResponse(String response) {
    if (response.isEmpty) {
      return FilterResult.approved();
    }

    final normalized = _normalizeText(response);

    // Check prosperity gospel
    final prosperityMatches = _findMatches(normalized, _prosperityGospelBlacklist);
    if (prosperityMatches.isNotEmpty) {
      return FilterResult.rejected(
        'Prosperity gospel language detected',
        matched: prosperityMatches,
      );
    }

    // Check spiritual bypassing
    final bypassingMatches = _findMatches(normalized, _spiritualBypassingBlacklist);
    if (bypassingMatches.isNotEmpty) {
      return FilterResult.rejected(
        'Spiritual bypassing detected (minimizes suffering)',
        matched: bypassingMatches,
      );
    }

    // Check toxic positivity
    final toxicMatches = _findMatches(normalized, _toxicPositivityBlacklist);
    if (toxicMatches.isNotEmpty) {
      return FilterResult.rejected(
        'Toxic positivity detected',
        matched: toxicMatches,
      );
    }

    // Check legalism
    final legalismMatches = _findMatches(normalized, _legalismBlacklist);
    if (legalismMatches.isNotEmpty) {
      return FilterResult.rejected(
        'Legalistic language detected',
        matched: legalismMatches,
      );
    }

    // Check hate speech
    final hateMatches = _findMatches(normalized, _hateSpeechBlacklist);
    if (hateMatches.isNotEmpty) {
      return FilterResult.rejected(
        'Hate speech detected',
        matched: hateMatches,
      );
    }

    // Check medical overreach
    final medicalMatches = _findMatches(normalized, _medicalOverreachBlacklist);
    if (medicalMatches.isNotEmpty) {
      return FilterResult.rejected(
        'Medical overreach detected (inappropriate medical advice)',
        matched: medicalMatches,
      );
    }

    return FilterResult.approved();
  }

  /// Normalize text for matching
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Find phrase matches in normalized text
  List<String> _findMatches(String normalizedText, List<String> phrases) {
    final matches = <String>[];

    for (final phrase in phrases) {
      if (normalizedText.contains(phrase.toLowerCase())) {
        matches.add(phrase);
      }
    }

    return matches;
  }

  /// Get fallback response when content is filtered
  /// This provides a safe default response to the user
  String getFallbackResponse(String theme) {
    // Provide generic encouragement + scripture without harmful theology
    final fallbackResponses = {
      'anxiety': 'I hear you\'re struggling with anxiety. Remember: "Don\'t be anxious about anything, but in everything by prayer and petition, with thanksgiving, present your requests to God." (Philippians 4:6, WEB). Consider speaking with a counselor who can provide personalized support.',
      'depression': 'Depression is real and heavy. You don\'t have to carry this alone. "Yahweh is near to those who have a broken heart, and saves those who have a crushed spirit." (Psalm 34:18, WEB). Please reach out to a mental health professional.',
      'fear': 'Fear can be overwhelming. "For God didn\'t give us a spirit of fear, but of power, love, and self-control." (2 Timothy 1:7, WEB). You\'re not alone in this.',
      'doubt': 'Doubt is part of the journey. Bring your questions to God - He\'s not afraid of them. "Help my unbelief!" (Mark 9:24, WEB) is a prayer God honors.',
      'default': 'I\'m here to support you. Remember that God meets us in our struggles. "Cast all your worries on him, because he cares for you." (1 Peter 5:7, WEB). Consider reaching out to a pastor or counselor for personalized guidance.',
    };

    return fallbackResponses[theme] ?? fallbackResponses['default']!;
  }

  /// Check if response contains scripture reference
  /// Responses without scripture may need review
  bool hasScriptureReference(String response) {
    // Check for common Bible book names and verse patterns
    final scripturePattern = RegExp(
      r'\b(Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|'
      r'Samuel|Kings|Chronicles|Ezra|Nehemiah|Esther|Job|Psalms?|Proverbs|'
      r'Ecclesiastes|Song|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|Hosea|'
      r'Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|'
      r'Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|Romans|Corinthians|'
      r'Galatians|Ephesians|Philippians|Colossians|Thessalonians|Timothy|'
      r'Titus|Philemon|Hebrews|James|Peter|Jude|Revelation)\s+\d+',
      caseSensitive: false,
    );

    return scripturePattern.hasMatch(response);
  }

  /// Log filtered response (for improvement and monitoring)
  void logFilteredResponse(FilterResult result, String response) {
    if (result.isRejected && kDebugMode) {
      // Do NOT log actual response text - privacy
    }

    // Track filter rejection rates to improve model training
  }

  /// Get filter statistics (for monitoring)
  Map<String, int> getFilterStats() {
    // This would track rejection counts by category
    return {
      'prosperity_gospel': 0,
      'spiritual_bypassing': 0,
      'toxic_positivity': 0,
      'legalism': 0,
      'hate_speech': 0,
      'medical_overreach': 0,
    };
  }
}
