import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// Native Web Push Notification Service
/// Uses standard Web Push API - no Firebase required
///
/// This service handles:
/// - Service worker registration for push events
/// - Push subscription management
/// - VAPID key configuration
/// - Permission status checking

// JS Interop for WebPush global object
@JS('window.WebPush')
external WebPushJS? get _webPush;

/// WebPush JS object (from web-push-client.js)
extension type WebPushJS._(JSObject _) implements JSObject {
  external JSBoolean setVapidKey(JSString vapidKey);
  external JSBoolean setUserId(JSString userId);
  external JSBoolean isSupported();
  external JSString getPermissionStatus();
  external JSPromise<JSString?> init();
  external JSPromise<JSString?> getExistingSubscription();
  external JSPromise<JSBoolean> unsubscribe();
  external JSPromise<JSBoolean> fetchVapidKey();
}

class WebPushNotificationService {
  static String? _subscriptionJson;
  static String? _vapidPublicKey;
  static String? _userId;

  /// Set the user ID for subscription tracking (call before initialize)
  static bool setUserId(String userId) {
    if (!kIsWeb) return false;

    try {
      _userId = userId;
      final webPush = _webPush;
      if (webPush == null) return false;

      final result = webPush.setUserId(userId.toJS);
      return result.toDart;
    } catch (e) {
      debugPrint('[WebPush] Failed to set user ID: $e');
      return false;
    }
  }

  /// Fetch VAPID key from server (auto-called by init if not set)
  static Future<bool> fetchVapidKey() async {
    if (!kIsWeb) return false;

    try {
      final webPush = _webPush;
      if (webPush == null) return false;

      final promise = webPush.fetchVapidKey();
      final result = await promise.toDart;
      return result.toDart;
    } catch (e) {
      debugPrint('[WebPush] Failed to fetch VAPID key: $e');
      return false;
    }
  }

  /// Set the VAPID public key (must be called before initialize)
  static bool setVapidKey(String vapidKey) {
    if (!kIsWeb) return false;

    try {
      _vapidPublicKey = vapidKey;
      final webPush = _webPush;
      if (webPush == null) return false;

      final result = webPush.setVapidKey(vapidKey.toJS);
      return result.toDart;
    } catch (e) {
      debugPrint('[WebPush] Failed to set VAPID key: $e');
      return false;
    }
  }

  /// Check if Web Push is supported in this browser
  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      final webPush = _webPush;
      if (webPush == null) return false;

      final result = webPush.isSupported();
      return result.toDart;
    } catch (e) {
      return false;
    }
  }

  /// Get current permission status: 'granted', 'denied', 'default', or 'unsupported'
  static String get permissionStatus {
    if (!kIsWeb) return 'unsupported';
    try {
      final webPush = _webPush;
      if (webPush == null) return 'unsupported';

      final result = webPush.getPermissionStatus();
      return result.toDart;
    } catch (e) {
      return 'unsupported';
    }
  }

  /// Initialize push notifications and get subscription
  /// Returns the PushSubscription JSON to send to backend, or null if failed
  static Future<String?> initialize() async {
    if (!kIsWeb) return null;
    if (!isSupported) return null;

    if (_vapidPublicKey == null) {
      debugPrint('[WebPush] VAPID key not set. Call setVapidKey first.');
      return null;
    }

    try {
      final webPush = _webPush;
      if (webPush == null) return null;

      // Call async JS function
      final promise = webPush.init();
      final result = await promise.toDart;

      if (result != null) {
        _subscriptionJson = result.toDart;
        debugPrint('[WebPush] Subscription obtained');
        return _subscriptionJson;
      }
      return null;
    } catch (e) {
      debugPrint('[WebPush] Initialization failed: $e');
      return null;
    }
  }

  /// Get existing subscription without prompting for permission
  static Future<String?> getExistingSubscription() async {
    if (!kIsWeb) return null;
    if (!isSupported) return null;

    try {
      final webPush = _webPush;
      if (webPush == null) return null;

      final promise = webPush.getExistingSubscription();
      final result = await promise.toDart;

      if (result != null) {
        _subscriptionJson = result.toDart;
        return _subscriptionJson;
      }
      return null;
    } catch (e) {
      debugPrint('[WebPush] Failed to get existing subscription: $e');
      return null;
    }
  }

  /// Unsubscribe from push notifications
  static Future<bool> unsubscribe() async {
    if (!kIsWeb) return false;

    try {
      final webPush = _webPush;
      if (webPush == null) return false;

      final promise = webPush.unsubscribe();
      final result = await promise.toDart;

      if (result.toDart) {
        _subscriptionJson = null;
        debugPrint('[WebPush] Unsubscribed successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[WebPush] Unsubscribe failed: $e');
      return false;
    }
  }

  /// Get cached subscription JSON
  static String? get subscriptionJson => _subscriptionJson;
}
