import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// UIAudio - Audio manager for UI sounds following the "Audio as Haptic Proxy" pattern
///
/// Provides Contact-Confirm-Continuity audio feedback for UI interactions.
/// Audio is subtle and designed to complement haptic feedback, not replace it.
class UIAudio {
  static final UIAudio _instance = UIAudio._internal();
  factory UIAudio() => _instance;
  UIAudio._internal();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;
  double volume = 0.3;

  /// Click - Initial contact feedback (button press, tap)
  Future<void> playClick() async {
    if (!enabled) return;
    // In production: await _player.play(AssetSource('sounds/click.mp3'), volume: volume);
    if (kDebugMode) debugPrint('🔊 UIAudio: click');
  }

  /// Whoosh - Movement/transition feedback (menu open/close, swipe)
  Future<void> playWhoosh() async {
    if (!enabled) return;
    // In production: await _player.play(AssetSource('sounds/whoosh.mp3'), volume: volume);
    if (kDebugMode) debugPrint('🔊 UIAudio: whoosh');
  }

  /// Tick - Incremental feedback (scrolling through items, slider adjustment)
  Future<void> playTick() async {
    if (!enabled) return;
    // In production: await _player.play(AssetSource('sounds/tick.mp3'), volume: volume);
    if (kDebugMode) debugPrint('🔊 UIAudio: tick');
  }

  /// Confirm - Action completion feedback (successful submission, navigation)
  Future<void> playConfirm() async {
    if (!enabled) return;
    // In production: await _player.play(AssetSource('sounds/confirm.mp3'), volume: volume);
    if (kDebugMode) debugPrint('🔊 UIAudio: confirm');
  }

  void dispose() => _player.dispose();
}
