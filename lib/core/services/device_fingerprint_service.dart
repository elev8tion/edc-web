/// Device Fingerprint Service
///
/// Generates unique device fingerprints for PWA trial abuse prevention.
/// Uses browser characteristics to create a stable identifier that:
/// - Survives page refreshes
/// - Survives browser data clearing (uses multiple signals)
/// - Works across incognito/private mode
/// - Privacy-friendly (no PII collected)
///
/// Multi-signal approach (IP + fingerprint) prevents abuse while
/// maintaining zero friction for legitimate users.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class DeviceFingerprintService {
  /// Generate a unique device fingerprint based on browser characteristics
  ///
  /// Collects multiple signals:
  /// - User agent (browser type, version, OS)
  /// - Screen resolution and color depth
  /// - Timezone offset
  /// - Language preferences
  /// - Platform
  /// - Hardware concurrency (CPU cores)
  /// - Device memory (if available)
  /// - Canvas fingerprint (rendering variations)
  ///
  /// Returns: SHA-256 hash of combined signals
  static Future<String> generateFingerprint() async {
    try {
      if (!kIsWeb) {
        // Fallback for non-web platforms (should not happen in PWA)
        debugPrint('[DeviceFingerprint] Not running on web, using fallback');
        return _generateFallbackFingerprint();
      }

      final signals = await _collectBrowserSignals();
      final combined = _combineSignals(signals);
      final hash = _hashFingerprint(combined);

      debugPrint(
          '[DeviceFingerprint] Generated fingerprint: ${hash.substring(0, 16)}...');
      return hash;
    } catch (error) {
      debugPrint('[DeviceFingerprint] Error generating fingerprint: $error');
      return _generateFallbackFingerprint();
    }
  }

  /// Collect browser characteristics
  static Future<Map<String, dynamic>> _collectBrowserSignals() async {
    final window = web.window;
    final navigator = web.window.navigator;
    final screen = web.window.screen;

    final signals = <String, dynamic>{
      // Browser identification
      'userAgent': navigator.userAgent,
      'language': navigator.language,
      'languages': _getLanguages(navigator),
      'platform': _getPlatform(navigator),

      // Screen characteristics
      'screenWidth': screen.width,
      'screenHeight': screen.height,
      'screenColorDepth': screen.colorDepth,
      'screenPixelDepth': screen.pixelDepth,

      // Viewport
      'windowWidth': window.innerWidth,
      'windowHeight': window.innerHeight,

      // Time zone
      'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,

      // Hardware (if available)
      'hardwareConcurrency': navigator.hardwareConcurrency,
      'deviceMemory': _getDeviceMemory(navigator),

      // Touch support
      'maxTouchPoints': navigator.maxTouchPoints,

      // Cookie enabled
      'cookieEnabled': navigator.cookieEnabled,

      // Do Not Track
      'doNotTrack': _getDoNotTrack(navigator),

      // Canvas fingerprint (most unique signal)
      'canvasFingerprint': await _generateCanvasFingerprint(),

      // WebGL fingerprint
      'webglVendor': _getWebGLVendor(),
      'webglRenderer': _getWebGLRenderer(),
    };

    return signals;
  }

  /// Get languages as comma-separated string
  static String _getLanguages(web.Navigator navigator) {
    try {
      // Use dynamic access for compatibility
      final languagesArray = (navigator as dynamic).languages;
      if (languagesArray == null) return '';

      final list = <String>[];
      final length = (languagesArray.length as num?)?.toInt() ?? 0;
      for (int i = 0; i < length; i++) {
        final lang = languagesArray[i];
        if (lang != null) {
          list.add(lang.toString());
        }
      }
      return list.join(',');
    } catch (e) {
      return '';
    }
  }

  /// Get platform safely
  static String _getPlatform(web.Navigator navigator) {
    try {
      // platform is deprecated but still useful for fingerprinting
      return (navigator as dynamic).platform?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Generate canvas fingerprint (most unique signal)
  ///
  /// Canvas fingerprinting works by rendering text and shapes,
  /// then reading back the pixel data. Minor variations in rendering
  /// (due to GPU, drivers, fonts, etc.) create a unique signature.
  static Future<String> _generateCanvasFingerprint() async {
    try {
      final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      canvas.width = 200;
      canvas.height = 50;

      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;

      // Draw text with specific font
      ctx.textBaseline = 'top';
      ctx.font = '14px "Arial"';
      ctx.textBaseline = 'alphabetic';
      ctx.fillStyle = '#f60'.toJS;
      ctx.fillRect(125, 1, 62, 20);

      ctx.fillStyle = '#069'.toJS;
      ctx.fillText('EDC Trial', 2, 15);

      ctx.fillStyle = 'rgba(102, 204, 0, 0.7)'.toJS;
      ctx.fillText('EDC Trial', 4, 17);

      // Get canvas data URL
      final dataUrl = canvas.toDataURL('image/png');

      // Hash the canvas data
      final bytes = utf8.encode(dataUrl);
      final hash = sha256.convert(bytes);

      return hash.toString().substring(0, 16);
    } catch (error) {
      debugPrint('[DeviceFingerprint] Canvas fingerprint error: $error');
      return 'canvas_error';
    }
  }

  /// Get WebGL vendor
  static String _getWebGLVendor() {
    try {
      final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      final gl = canvas.getContext('webgl');

      if (gl != null) {
        // Use dynamic to access WebGL methods
        final glDynamic = gl as dynamic;
        final debugInfo = glDynamic.getExtension('WEBGL_debug_renderer_info');
        if (debugInfo != null) {
          // UNMASKED_VENDOR_WEBGL = 0x9245
          final vendor = glDynamic.getParameter(0x9245);
          return vendor?.toString() ?? 'unknown';
        }
      }
    } catch (error) {
      debugPrint('[DeviceFingerprint] WebGL vendor error: $error');
    }
    return 'unknown';
  }

  /// Get WebGL renderer
  static String _getWebGLRenderer() {
    try {
      final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      final gl = canvas.getContext('webgl');

      if (gl != null) {
        // Use dynamic to access WebGL methods
        final glDynamic = gl as dynamic;
        final debugInfo = glDynamic.getExtension('WEBGL_debug_renderer_info');
        if (debugInfo != null) {
          // UNMASKED_RENDERER_WEBGL = 0x9246
          final renderer = glDynamic.getParameter(0x9246);
          return renderer?.toString() ?? 'unknown';
        }
      }
    } catch (error) {
      debugPrint('[DeviceFingerprint] WebGL renderer error: $error');
    }
    return 'unknown';
  }

  /// Get device memory (GB)
  static dynamic _getDeviceMemory(web.Navigator navigator) {
    try {
      return (navigator as dynamic).deviceMemory ?? 'unknown';
    } catch (error) {
      return 'unknown';
    }
  }

  /// Get Do Not Track setting
  static String _getDoNotTrack(web.Navigator navigator) {
    try {
      return (navigator as dynamic).doNotTrack?.toString() ?? 'unknown';
    } catch (error) {
      return 'unknown';
    }
  }

  /// Combine all signals into a single string
  static String _combineSignals(Map<String, dynamic> signals) {
    // Sort keys for consistent ordering
    final sortedKeys = signals.keys.toList()..sort();

    // Build combined string
    final buffer = StringBuffer();
    for (final key in sortedKeys) {
      buffer.write('$key:${signals[key]};');
    }

    return buffer.toString();
  }

  /// Hash the combined fingerprint using SHA-256
  static String _hashFingerprint(String combined) {
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Fallback fingerprint for error cases or non-web platforms
  static String _generateFallbackFingerprint() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = '${timestamp}_fallback';
    final bytes = utf8.encode(random);
    final hash = sha256.convert(bytes);

    debugPrint('[DeviceFingerprint] Using fallback fingerprint');
    return hash.toString();
  }

  /// Validate fingerprint format (64 character hex string)
  static bool isValidFingerprint(String fingerprint) {
    if (fingerprint.length != 64) return false;

    final hexPattern = RegExp(r'^[0-9a-f]{64}$');
    return hexPattern.hasMatch(fingerprint);
  }

  /// Get a short version of fingerprint for logging (first 16 chars)
  static String shortFingerprint(String fingerprint) {
    if (fingerprint.length < 16) return fingerprint;
    return '${fingerprint.substring(0, 16)}...';
  }
}
