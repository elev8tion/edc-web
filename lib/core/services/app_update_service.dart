import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// Service to detect and handle PWA updates via Service Worker
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  static AppUpdateService get instance => _instance;

  AppUpdateService._();

  final _updateAvailableController = StreamController<bool>.broadcast();
  Stream<bool> get onUpdateAvailable => _updateAvailableController.stream;

  web.ServiceWorkerRegistration? _registration;
  bool _updateAvailable = false;

  bool get updateAvailable => _updateAvailable;

  /// Initialize the update service (call on app start, web only)
  Future<void> initialize() async {
    if (!kIsWeb) return;

    try {
      final sw = web.window.navigator.serviceWorker;
      _registration = await sw.ready.toDart;

      if (_registration == null) {
        debugPrint('[AppUpdateService] No service worker registration');
        return;
      }

      debugPrint('[AppUpdateService] Service worker ready, listening for updates');

      // Listen for new service worker installing
      _registration!.addEventListener(
        'updatefound',
        ((web.Event event) {
          debugPrint('[AppUpdateService] Update found!');
          final newWorker = _registration!.installing;
          if (newWorker != null) {
            _listenToWorkerState(newWorker);
          }
        }).toJS,
      );

      // Check for updates periodically (every 30 minutes)
      Timer.periodic(const Duration(minutes: 30), (_) => checkForUpdate());

      // Initial check
      await checkForUpdate();
    } catch (e) {
      debugPrint('[AppUpdateService] Error initializing: $e');
    }
  }

  void _listenToWorkerState(web.ServiceWorker worker) {
    worker.addEventListener(
      'statechange',
      ((web.Event event) {
        debugPrint('[AppUpdateService] Worker state: ${worker.state}');
        if (worker.state == 'installed') {
          // New version installed, waiting to activate
          _updateAvailable = true;
          _updateAvailableController.add(true);
          debugPrint('[AppUpdateService] New version ready!');
        }
      }).toJS,
    );
  }

  /// Manually check for updates
  Future<void> checkForUpdate() async {
    if (_registration == null) return;

    try {
      debugPrint('[AppUpdateService] Checking for updates...');
      await _registration!.update().toDart;
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking for update: $e');
    }
  }

  /// Apply the update by refreshing the page
  void applyUpdate() {
    if (!kIsWeb) return;

    debugPrint('[AppUpdateService] Applying update - reloading page');

    // Tell the waiting service worker to skip waiting and activate
    final waiting = _registration?.waiting;
    if (waiting != null) {
      waiting.postMessage('skipWaiting'.toJS);
    }

    // Reload the page to get the new version
    web.window.location.reload();
  }

  void dispose() {
    _updateAvailableController.close();
  }
}
