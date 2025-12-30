/// Offline Preparation Service
///
/// Manages background downloading of all app assets for true offline capability.
/// Shows progress to user and only runs once per device.
library offline_preparation_service;

import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

/// Service to prepare the app for offline use by pre-caching all assets
class OfflinePreparationService {
  static const String _preparedKey = 'offline_preparation_complete';
  static const String _versionKey = 'offline_preparation_version';

  // Current version - increment when assets change significantly
  static const int _currentVersion = 1;

  final _progressController = StreamController<OfflineProgress>.broadcast();

  /// Stream of preparation progress updates
  Stream<OfflineProgress> get progressStream => _progressController.stream;

  /// Check if offline preparation has been completed for current version
  Future<bool> isPreparationComplete() async {
    if (!kIsWeb) return true; // Only needed for web

    final prefs = await SharedPreferences.getInstance();
    final isComplete = prefs.getBool(_preparedKey) ?? false;
    final savedVersion = prefs.getInt(_versionKey) ?? 0;

    // Re-prepare if version changed
    return isComplete && savedVersion >= _currentVersion;
  }

  /// Start the offline preparation process
  /// Returns a stream of progress updates
  Future<void> startPreparation() async {
    if (!kIsWeb) return;

    _progressController.add(const OfflineProgress(
      status: OfflineStatus.checking,
      message: 'Checking offline status...',
      progress: 0,
    ));

    // Check if already prepared
    if (await isPreparationComplete()) {
      _progressController.add(const OfflineProgress(
        status: OfflineStatus.complete,
        message: 'Ready for offline use',
        progress: 1.0,
      ));
      return;
    }

    _progressController.add(const OfflineProgress(
      status: OfflineStatus.downloading,
      message: 'Preparing offline mode...',
      progress: 0.05,
    ));

    try {
      // Get service worker registration
      final registration = await _getServiceWorkerRegistration();
      if (registration == null) {
        _progressController.add(const OfflineProgress(
          status: OfflineStatus.error,
          message: 'Service worker not available',
          progress: 0,
        ));
        return;
      }

      // Trigger the downloadOffline message
      await _triggerOfflineDownload(registration);

      // Monitor cache progress
      await _monitorCacheProgress();

      // Mark as complete
      await _markAsComplete();

      _progressController.add(const OfflineProgress(
        status: OfflineStatus.complete,
        message: 'Ready for offline use!',
        progress: 1.0,
      ));

    } catch (e) {
      debugPrint('Offline preparation error: $e');
      _progressController.add(const OfflineProgress(
        status: OfflineStatus.error,
        message: 'Could not prepare offline mode',
        progress: 0,
      ));
    }
  }

  Future<web.ServiceWorkerRegistration?> _getServiceWorkerRegistration() async {
    try {
      final container = web.window.navigator.serviceWorker;
      final registration = await container.ready.toDart;
      return registration;
    } catch (e) {
      debugPrint('Failed to get service worker: $e');
      return null;
    }
  }

  Future<void> _triggerOfflineDownload(web.ServiceWorkerRegistration registration) async {
    final controller = web.window.navigator.serviceWorker.controller;
    if (controller != null) {
      controller.postMessage('downloadOffline'.toJS);
      debugPrint('Triggered downloadOffline message to service worker');
    }
  }

  Future<void> _monitorCacheProgress() async {
    // Monitor cache size over time
    int previousCount = 0;
    int stableCount = 0;
    const maxWaitSeconds = 120; // Max 2 minutes
    const targetFiles = 100; // Approximate number of files to cache

    for (int i = 0; i < maxWaitSeconds; i++) {
      await Future.delayed(const Duration(seconds: 1));

      final cacheCount = await _getCacheCount();
      final progress = (cacheCount / targetFiles).clamp(0.05, 0.95);

      _progressController.add(OfflineProgress(
        status: OfflineStatus.downloading,
        message: 'Downloading assets ($cacheCount files)...',
        progress: progress,
      ));

      // Check if cache count is stable (download complete)
      if (cacheCount == previousCount && cacheCount > 30) {
        stableCount++;
        if (stableCount >= 3) {
          // Cache hasn't changed for 3 seconds, likely complete
          break;
        }
      } else {
        stableCount = 0;
      }

      previousCount = cacheCount;

      // Check for critical files
      if (await _hasCriticalFiles()) {
        debugPrint('Critical files cached, preparation complete');
        break;
      }
    }
  }

  Future<int> _getCacheCount() async {
    try {
      final caches = web.window.caches;
      final cache = await caches.open('flutter-app-cache').toDart;
      final keys = await cache.keys().toDart;
      // Convert to List to access length (SDK 3.3.0 compatible)
      final keysList = keys.toDart;
      return keysList.length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> _hasCriticalFiles() async {
    try {
      final caches = web.window.caches;
      final cache = await caches.open('flutter-app-cache').toDart;

      // Check for Bible database
      final bibleMatch = await cache.match('assets/assets/bible.db'.toJS).toDart;
      final canvaskitMatch = await cache.match('canvaskit/canvaskit.wasm'.toJS).toDart;

      return bibleMatch != null && canvaskitMatch != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _markAsComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preparedKey, true);
    await prefs.setInt(_versionKey, _currentVersion);
  }

  /// Reset preparation status (for testing)
  Future<void> resetPreparation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_preparedKey);
    await prefs.remove(_versionKey);
  }

  void dispose() {
    _progressController.close();
  }
}

/// Status of offline preparation
enum OfflineStatus {
  checking,
  downloading,
  complete,
  error,
}

/// Progress update for offline preparation
class OfflineProgress {
  final OfflineStatus status;
  final String message;
  final double progress; // 0.0 to 1.0

  const OfflineProgress({
    required this.status,
    required this.message,
    required this.progress,
  });
}
