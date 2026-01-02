import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Extension type for BeforeInstallPromptEvent
@JS('BeforeInstallPromptEvent')
extension type BeforeInstallPromptEvent._(JSObject _) implements web.Event {
  external JSPromise<UserChoiceResult> get userChoice;
  external JSPromise<JSAny?> prompt();
}

/// Extension type for the user choice result
@JS()
extension type UserChoiceResult._(JSObject _) implements JSObject {
  external String get outcome;
  external String? get platform;
}

/// Web implementation of PWA install service
///
/// Uses the native Web APIs for PWA installation:
/// - beforeinstallprompt event for capturing install prompt
/// - appinstalled event for tracking successful installs
/// - localStorage for persisting dismissal count
/// - matchMedia for detecting standalone mode
class PwaInstallServiceImpl {
  BeforeInstallPromptEvent? _deferredPrompt;
  bool _userDismissed = false;
  int _promptCount = 0;
  bool _hasPromptedThisSession = false;
  static const int _maxPrompts = 3;
  static const String _dismissCountKey = 'pwa_dismiss_count';
  static const String _installedKey = 'pwa_installed';

  /// Initialize the PWA install listener
  ///
  /// Sets up event listeners for:
  /// - beforeinstallprompt: Captures the install prompt for later use
  /// - appinstalled: Tracks when the app is successfully installed
  void initialize() {
    try {
      // Check if already dismissed too many times
      final dismissCount = web.window.localStorage.getItem(_dismissCountKey);
      if (dismissCount != null && dismissCount.isNotEmpty) {
        final parsed = int.tryParse(dismissCount);
        if (parsed != null) {
          _promptCount = parsed;
          if (_promptCount >= _maxPrompts) {
            _userDismissed = true;
            debugPrint('[PWA] User has dismissed $_promptCount times, not showing prompt');
            return;
          }
        }
      }

      // Listen for beforeinstallprompt event
      web.window.addEventListener(
        'beforeinstallprompt',
        ((web.Event event) {
          event.preventDefault();
          _deferredPrompt = event as BeforeInstallPromptEvent;
          debugPrint('[PWA] Install prompt captured and deferred');
        }).toJS,
      );

      // Track successful installs
      web.window.addEventListener(
        'appinstalled',
        ((web.Event event) {
          debugPrint('[PWA] App installed successfully');
          _deferredPrompt = null;
          web.window.localStorage.setItem(_installedKey, 'true');
        }).toJS,
      );

      debugPrint('[PWA] Install service initialized');
    } catch (e) {
      debugPrint('[PWA] Failed to initialize install service: $e');
    }
  }

  /// Check if PWA can be installed
  bool get canPrompt {
    if (_userDismissed) {
      debugPrint('[PWA] canPrompt: false (user dismissed)');
      return false;
    }
    if (_deferredPrompt == null) {
      debugPrint('[PWA] canPrompt: false (no deferred prompt)');
      return false;
    }
    if (isInstalled) {
      debugPrint('[PWA] canPrompt: false (already installed)');
      return false;
    }
    return true;
  }

  /// Check if already installed
  bool get isInstalled {
    try {
      // Check display mode (standalone or fullscreen)
      final standaloneQuery = web.window.matchMedia('(display-mode: standalone)');
      if (standaloneQuery.matches) {
        return true;
      }

      final fullscreenQuery = web.window.matchMedia('(display-mode: fullscreen)');
      if (fullscreenQuery.matches) {
        return true;
      }

      // Check localStorage flag (set after successful install)
      final installedFlag = web.window.localStorage.getItem(_installedKey);
      return installedFlag == 'true';
    } catch (e) {
      debugPrint('[PWA] Error checking installed status: $e');
      return false;
    }
  }

  /// Check if on iOS
  bool get isIOS {
    try {
      final ua = web.window.navigator.userAgent.toLowerCase();
      return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
    } catch (e) {
      return false;
    }
  }

  /// Trigger install prompt
  Future<bool> promptInstall() async {
    if (!canPrompt) {
      debugPrint('[PWA] Cannot prompt: conditions not met');
      return false;
    }

    try {
      debugPrint('[PWA] Triggering install prompt');

      final prompt = _deferredPrompt;
      if (prompt == null) {
        debugPrint('[PWA] No deferred prompt available');
        return false;
      }

      // Call prompt() on the deferred event
      await prompt.prompt().toDart;

      // Wait for user choice
      final choice = await prompt.userChoice.toDart;
      final outcome = choice.outcome;

      if (outcome == 'accepted') {
        debugPrint('[PWA] User accepted the install prompt');
        _deferredPrompt = null;
        return true;
      } else {
        debugPrint('[PWA] User dismissed the install prompt');
        _recordDismissal();
        return false;
      }
    } catch (e) {
      debugPrint('[PWA] Install prompt error: $e');
      _recordDismissal();
      return false;
    }
  }

  /// Record a dismissal
  void _recordDismissal() {
    _promptCount++;
    try {
      web.window.localStorage.setItem(_dismissCountKey, _promptCount.toString());
    } catch (e) {
      debugPrint('[PWA] Failed to save dismissal count: $e');
    }
    if (_promptCount >= _maxPrompts) {
      _userDismissed = true;
      debugPrint('[PWA] Max dismissals reached, will not show prompt again');
    }
  }

  /// Reset dismissal count
  void resetDismissals() {
    try {
      web.window.localStorage.removeItem(_dismissCountKey);
      _userDismissed = false;
      _promptCount = 0;
      debugPrint('[PWA] Dismissal count reset');
    } catch (e) {
      debugPrint('[PWA] Failed to reset dismissals: $e');
    }
  }

  /// Check if prompt was shown this session
  bool get hasPromptedThisSession => _hasPromptedThisSession;

  /// Mark prompt as shown
  void markPromptShown() {
    _hasPromptedThisSession = true;
  }
}
