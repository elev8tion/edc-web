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
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

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
    final window = html.window;
    final navigator = html.window.navigator;
    final screen = html.window.screen;

    final signals = <String, dynamic>{
      // Browser identification
      'userAgent': navigator.userAgent ?? '',
      'language': navigator.language ?? '',
      'languages': navigator.languages?.join(',') ?? '',
      'platform': navigator.platform ?? '',

      // Screen characteristics
      'screenWidth': screen?.width ?? 0,
      'screenHeight': screen?.height ?? 0,
      'screenColorDepth': screen?.colorDepth ?? 0,
      'screenPixelDepth': screen?.pixelDepth ?? 0,

      // Viewport
      'windowWidth': window.innerWidth ?? 0,
      'windowHeight': window.innerHeight ?? 0,

      // Time zone
      'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,

      // Hardware (if available)
      'hardwareConcurrency': _getHardwareConcurrency(navigator),
      'deviceMemory': _getDeviceMemory(navigator),

      // Touch support
      'maxTouchPoints': _getMaxTouchPoints(navigator),

      // Cookie enabled
      'cookieEnabled': navigator.cookieEnabled ?? false,

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

  /// Generate canvas fingerprint (most unique signal)
  ///
  /// Canvas fingerprinting works by rendering text and shapes,
  /// then reading back the pixel data. Minor variations in rendering
  /// (due to GPU, drivers, fonts, etc.) create a unique signature.
  static Future<String> _generateCanvasFingerprint() async {
    try {
      final canvas = html.CanvasElement(width: 200, height: 50);
      final ctx = canvas.getContext('2d') as html.CanvasRenderingContext2D;

      // Draw text with specific font
      ctx.textBaseline = 'top';
      ctx.font = '14px "Arial"';
      ctx.textBaseline = 'alphabetic';
      ctx.fillStyle = '#f60';
      ctx.fillRect(125, 1, 62, 20);

      ctx.fillStyle = '#069';
      ctx.fillText('EDC Trial 🙏', 2, 15);

      ctx.fillStyle = 'rgba(102, 204, 0, 0.7)';
      ctx.fillText('EDC Trial 🙏', 4, 17);

      // Get canvas data URL
      final dataUrl = canvas.toDataUrl('image/png');

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
      final canvas = html.CanvasElement();
      final gl = canvas.getContext('webgl') as html.RenderingContext?;

      if (gl != null) {
        final debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
        if (debugInfo != null) {
          return gl.getParameter(0x9245).toString(); // UNMASKED_VENDOR_WEBGL
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
      final canvas = html.CanvasElement();
      final gl = canvas.getContext('webgl') as html.RenderingContext?;

      if (gl != null) {
        final debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
        if (debugInfo != null) {
          return gl.getParameter(0x9246).toString(); // UNMASKED_RENDERER_WEBGL
        }
      }
    } catch (error) {
      debugPrint('[DeviceFingerprint] WebGL renderer error: $error');
    }
    return 'unknown';
  }

  /// Get hardware concurrency (CPU cores)
  static int _getHardwareConcurrency(html.Navigator navigator) {
    try {
      // Access via JS interop
      return (navigator as dynamic).hardwareConcurrency ?? 0;
    } catch (error) {
      return 0;
    }
  }

  /// Get device memory (GB)
  static dynamic _getDeviceMemory(html.Navigator navigator) {
    try {
      return (navigator as dynamic).deviceMemory ?? 'unknown';
    } catch (error) {
      return 'unknown';
    }
  }

  /// Get max touch points
  static int _getMaxTouchPoints(html.Navigator navigator) {
    try {
      return (navigator as dynamic).maxTouchPoints ?? 0;
    } catch (error) {
      return 0;
    }
  }

  /// Get Do Not Track setting
  static String _getDoNotTrack(html.Navigator navigator) {
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
