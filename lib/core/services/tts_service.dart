import 'dart:async';
import 'dart:io' show Platform;
import 'dart:developer' as developer;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bible_verse.dart';

/// Text-to-Speech service for Bible audio playback
///
/// Features:
/// - Play/pause/stop chapter audio
/// - Adjustable speech rate (0.5x - 2.0x)
/// - Verse-by-verse progress tracking
/// - Background audio support
/// - Automatic cleanup on completion
///
/// Platform-specific speech rates:
/// - iOS: Normal = 0.5 (0.375 = slow, 0.625 = fast)
/// - Android: Normal = 1.0 (0.75 = slow, 1.25 = fast)
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();

  // State management
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  List<BibleVerse> _currentVerses = [];
  int _currentVerseIndex = -1;
  Completer<void>? _speakCompleter;

  // Platform-specific speed presets
  // iOS uses 0.5 as normal (not 1.0!), Android uses 1.0
  static List<double> get speedPresets {
    if (Platform.isIOS) {
      return [0.375, 0.5, 0.625]; // 0.75x, 1.0x, 1.25x equivalents
    } else {
      return [0.75, 1.0, 1.25]; // Android normal values
    }
  }

  // Default to normal speed (index 1 in presets)
  static const int _defaultSpeedIndex = 1;
  static double get _defaultRate => speedPresets[_defaultSpeedIndex];

  double _speechRate = 0.5; // Will be set correctly in _loadSpeechRate
  int _currentSpeedIndex = _defaultSpeedIndex;

  // Preferred voice names (case-insensitive matching)
  static const List<String> _preferredVoiceNames = [
    'Siri',       // Siri voices (premium quality)
    'Samantha',   // Natural female voice
    'Alex',       // Natural male voice
    'Ava',        // Enhanced quality
    'Evan',       // Enhanced quality
  ];

  // Callbacks for UI updates
  Function(int verseIndex)? onVerseChanged;
  Function(bool isPlaying)? onPlayStateChanged;
  Function()? onPlaybackComplete;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  int get currentVerseIndex => _currentVerseIndex;
  int get totalVerses => _currentVerses.length;
  double get speechRate => _speechRate;

  /// Initialize TTS engine with platform-specific settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('[TtsService] Initializing TTS engine', name: 'TtsService');

      // Platform-specific initialization
      await _tts.setLanguage("en-US");
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Select best quality voice (Siri or enhanced quality)
      await _selectBestVoice();

      // Load saved speech rate and apply it
      await _loadSpeechRate();
      developer.log('[TtsService] 🔊 APPLYING SPEECH RATE: $_speechRate (index: $_currentSpeedIndex)', name: 'TtsService');
      await _tts.setSpeechRate(_speechRate); // CRITICAL: Apply loaded rate to engine
      developer.log('[TtsService] ✅ Speech rate applied successfully', name: 'TtsService');

      // iOS-specific: Enable background audio
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );

      // Set up completion handler
      _tts.setCompletionHandler(() {
        developer.log('[TtsService] Verse completed', name: 'TtsService');
        _speakCompleter?.complete();
      });

      // Set up error handler
      _tts.setErrorHandler((msg) {
        developer.log('[TtsService] Error: $msg', name: 'TtsService', error: msg);
        _speakCompleter?.completeError(msg);
      });

      _isInitialized = true;
      developer.log('[TtsService] Initialization complete', name: 'TtsService');
    } catch (e) {
      developer.log('[TtsService] Initialization failed: $e', name: 'TtsService', error: e);
      rethrow;
    }
  }

  /// Play chapter from the beginning
  Future<void> playChapter(List<BibleVerse> verses, {int startIndex = 0}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (verses.isEmpty) {
      developer.log('[TtsService] No verses to play', name: 'TtsService');
      return;
    }

    developer.log('[TtsService] Playing chapter: ${verses.length} verses from index $startIndex', name: 'TtsService');

    _currentVerses = verses;
    _currentVerseIndex = startIndex;
    _isPlaying = true;
    _isPaused = false;

    onPlayStateChanged?.call(true);

    await _playFromCurrentIndex();
  }

  /// Internal method to play verses sequentially from current index
  Future<void> _playFromCurrentIndex() async {
    try {
      for (int i = _currentVerseIndex; i < _currentVerses.length; i++) {
        if (!_isPlaying || _isPaused) {
          developer.log('[TtsService] Playback stopped/paused at verse $i', name: 'TtsService');
          break;
        }

        _currentVerseIndex = i;
        onVerseChanged?.call(i);

        final verse = _currentVerses[i];
        final textToSpeak = verse.text; // Just the verse text, no number

        developer.log('[TtsService] Speaking verse ${verse.verseNumber}', name: 'TtsService');

        // Create new completer for this verse
        _speakCompleter = Completer<void>();

        await _tts.speak(textToSpeak);

        // Wait for completion
        await _speakCompleter!.future;

        // Brief pause between verses
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Playback complete
      if (_isPlaying && !_isPaused && _currentVerseIndex == _currentVerses.length - 1) {
        developer.log('[TtsService] Playback complete', name: 'TtsService');
        await stop();
        onPlaybackComplete?.call();
      }
    } catch (e) {
      developer.log('[TtsService] Playback error: $e', name: 'TtsService', error: e);
      await stop();
    }
  }

  /// Pause playback (can be resumed)
  Future<void> pause() async {
    if (!_isPlaying || _isPaused) return;

    developer.log('[TtsService] Pausing playback', name: 'TtsService');

    _isPaused = true;
    await _tts.stop(); // flutter_tts doesn't have native pause, so we stop

    onPlayStateChanged?.call(false);
  }

  /// Resume playback from where it was paused
  Future<void> resume() async {
    if (!_isPaused) return;

    developer.log('[TtsService] Resuming playback from verse $_currentVerseIndex', name: 'TtsService');

    _isPaused = false;
    _isPlaying = true;

    onPlayStateChanged?.call(true);

    // Continue from current verse
    await _playFromCurrentIndex();
  }

  /// Stop playback completely (resets position)
  Future<void> stop() async {
    developer.log('[TtsService] Stopping playback', name: 'TtsService');

    _isPlaying = false;
    _isPaused = false;
    _currentVerseIndex = -1;

    await _tts.stop();

    onPlayStateChanged?.call(false);
  }

  /// Cycle through preset speeds: 0.75x → 1.0x → 1.25x
  Future<void> cycleSpeed() async {
    _currentSpeedIndex = (_currentSpeedIndex + 1) % speedPresets.length;
    _speechRate = speedPresets[_currentSpeedIndex];

    developer.log('[TtsService] Cycling speed to ${_speechRate}x', name: 'TtsService');

    await _tts.setSpeechRate(_speechRate);

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tts_speed_index', _currentSpeedIndex);
  }

  /// Get current speed as formatted string (e.g., "1.0x")
  /// Always shows user-friendly labels regardless of platform
  String get speedLabel {
    switch (_currentSpeedIndex) {
      case 0:
        return '0.75x'; // Slow
      case 1:
        return '1.0x'; // Normal
      case 2:
        return '1.25x'; // Fast
      default:
        return '1.0x';
    }
  }

  /// Select the best quality voice available
  /// Priority: Siri (premium) > Enhanced quality > Default
  Future<void> _selectBestVoice() async {
    try {
      final voices = await _tts.getVoices;

      if (voices == null || voices.isEmpty) {
        developer.log('[TtsService] No voices available, using default', name: 'TtsService');
        return;
      }

      developer.log('[TtsService] Found ${voices.length} available voices', name: 'TtsService');

      // DEBUG: Log all en-US voices for troubleshooting
      final enUsVoicesDebug = voices.where((voice) {
        final locale = voice['locale'] as String?;
        return locale != null && locale.toLowerCase().startsWith('en-us');
      }).toList();

      developer.log('[TtsService] 🔍 Available en-US voices:', name: 'TtsService');
      for (var voice in enUsVoicesDebug) {
        developer.log('[TtsService]   - ${voice['name']} (${voice['identifier']}) [locale: ${voice['locale']}]', name: 'TtsService');
      }

      // Filter for en-US voices only
      final enUsVoices = voices.where((voice) {
        final locale = voice['locale'] as String?;
        return locale != null && locale.toLowerCase().startsWith('en-us');
      }).toList();

      if (enUsVoices.isEmpty) {
        developer.log('[TtsService] No en-US voices found', name: 'TtsService');
        return;
      }

      dynamic selectedVoice;

      if (Platform.isIOS) {
        // Try to find voice from preferred list in order
        for (var preferredName in _preferredVoiceNames) {
          final matchingVoices = enUsVoices.where((voice) {
            final name = (voice['name'] as String?)?.toLowerCase() ?? '';
            return name.contains(preferredName.toLowerCase());
          }).toList();

          if (matchingVoices.isNotEmpty) {
            selectedVoice = matchingVoices.first;
            developer.log('[TtsService] 🎙️ Selected preferred voice: ${selectedVoice['name']} (${selectedVoice['identifier']})', name: 'TtsService');
            break;
          }
        }

        // If no preferred voice found, try enhanced quality (non-compact)
        if (selectedVoice == null) {
          final enhancedVoices = enUsVoices.where((voice) {
            final identifier = (voice['identifier'] as String?)?.toLowerCase() ?? '';
            return !identifier.contains('compact');
          }).toList();

          if (enhancedVoices.isNotEmpty) {
            selectedVoice = enhancedVoices.first;
            developer.log('[TtsService] 🎙️ Selected enhanced voice: ${selectedVoice['name']} (${selectedVoice['identifier']})', name: 'TtsService');
          } else {
            // Fallback: Use first available voice
            selectedVoice = enUsVoices.first;
            developer.log('[TtsService] 🎙️ Using default voice: ${selectedVoice['name']} (${selectedVoice['identifier']})', name: 'TtsService');
          }
        }

        // Set the voice using identifier (most reliable on iOS)
        if (selectedVoice != null && selectedVoice['identifier'] != null) {
          await _tts.setVoice({"identifier": selectedVoice['identifier']});
          developer.log('[TtsService] ✅ Voice set successfully', name: 'TtsService');
        }
      } else {
        // Android: Select highest quality voice available
        // Android voices have 'quality' field: low, normal, high, very_high
        final highQualityVoices = enUsVoices.where((voice) {
          final quality = (voice['quality'] as String?)?.toLowerCase() ?? '';
          return quality.contains('high') || quality.contains('premium');
        }).toList();

        if (highQualityVoices.isNotEmpty) {
          selectedVoice = highQualityVoices.first;
          developer.log('[TtsService] 🎙️ Selected high-quality Android voice: ${selectedVoice['name']}', name: 'TtsService');

          // Set voice using name and locale
          await _tts.setVoice({
            "name": selectedVoice['name'],
            "locale": selectedVoice['locale']
          });
        } else {
          developer.log('[TtsService] 🎙️ Using default Android voice', name: 'TtsService');
        }
      }
    } catch (e) {
      developer.log('[TtsService] Error selecting voice: $e', name: 'TtsService', error: e);
      // Continue with default voice on error
    }
  }

  /// Load saved speech rate preference
  Future<void> _loadSpeechRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // MIGRATION: Remove old preferences if they exist (from buggy 1.0 implementation)
      bool needsMigration = false;
      if (prefs.containsKey('tts_speech_rate')) {
        developer.log('[TtsService] Migrating from old tts_speech_rate preference', name: 'TtsService');
        await prefs.remove('tts_speech_rate');
        needsMigration = true;
      }
      if (prefs.containsKey('tts_speed_index') && needsMigration) {
        // Reset speed index too since old values were incorrect for iOS
        await prefs.remove('tts_speed_index');
      }

      _currentSpeedIndex = prefs.getInt('tts_speed_index') ?? _defaultSpeedIndex;

      // Clamp to valid range
      if (_currentSpeedIndex < 0 || _currentSpeedIndex >= speedPresets.length) {
        _currentSpeedIndex = _defaultSpeedIndex;
      }

      _speechRate = speedPresets[_currentSpeedIndex];

      final platform = Platform.isIOS ? 'iOS' : 'Android';
      developer.log('[TtsService] Loaded speed preset for $platform: $_speechRate (index $_currentSpeedIndex, displays as $speedLabel)', name: 'TtsService');
    } catch (e) {
      developer.log('[TtsService] Error loading speech rate: $e', name: 'TtsService', error: e);
      _speechRate = _defaultRate;
      _currentSpeedIndex = _defaultSpeedIndex;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    developer.log('[TtsService] Disposing TTS service', name: 'TtsService');

    await stop();
    _currentVerses.clear();

    onVerseChanged = null;
    onPlayStateChanged = null;
    onPlaybackComplete = null;
  }
}
