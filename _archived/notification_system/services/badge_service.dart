import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// App Badge Service for PWA
/// Updates the badge count on the installed PWA icon
///
/// The Badge API allows installed PWAs to display a count or indicator
/// on their app icon. This is useful for showing unread notifications,
/// pending tasks, or other counts that require user attention.
///
/// Browser Support:
/// - Chrome: ✅ Supported
/// - Edge: ✅ Supported
/// - Safari: ✅ Supported (16.4+, requires PWA installed)
/// - Firefox: ❌ Not supported

// JS Interop for WebPush global object
@JS('window.WebPush')
external WebPushJS? get _webPush;

/// WebPush JS object (from web-push-client.js)
extension type WebPushJS._(JSObject _) implements JSObject {
  external JSBoolean isBadgeSupported();
  external JSPromise<JSBoolean> setAppBadge(JSNumber count);
  external JSPromise<JSBoolean> clearAppBadge();
}

class BadgeService {
  /// Check if Badge API is supported
  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      final webPush = _webPush;
      if (webPush == null) return false;

      final result = webPush.isBadgeSupported();
      return result.toDart;
    } catch (e) {
      return false;
    }
  }

  /// Set app badge count
  ///
  /// [count] - The number to display on the badge.
  ///           Use 0 to show a dot indicator without a number.
  ///
  /// Returns true if badge was set successfully, false otherwise.
  static Future<bool> setBadge(int count) async {
    if (!kIsWeb || !isSupported) return false;

    try {
      final webPush = _webPush;
      if (webPush == null) return false;

      final promise = webPush.setAppBadge(count.toJS);
      final result = await promise.toDart;
      return result.toDart;
    } catch (e) {
      debugPrint('[Badge] Failed to set badge: $e');
      return false;
    }
  }

  /// Clear app badge
  ///
  /// Removes the badge from the app icon entirely.
  /// Returns true if badge was cleared successfully, false otherwise.
  static Future<bool> clearBadge() async {
    if (!kIsWeb || !isSupported) return false;

    try {
      final webPush = _webPush;
      if (webPush == null) return false;

      final promise = webPush.clearAppBadge();
      final result = await promise.toDart;
      return result.toDart;
    } catch (e) {
      debugPrint('[Badge] Failed to clear badge: $e');
      return false;
    }
  }
}
