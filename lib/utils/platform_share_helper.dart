import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

// Conditional imports for platform-specific code
import 'platform_share_helper_stub.dart'
    if (dart.library.io) 'platform_share_helper_mobile.dart'
    if (dart.library.html) 'platform_share_helper_web.dart';

/// Platform-aware helper for sharing images and content
///
/// Handles sharing differently on mobile vs web:
/// - Mobile: Uses File-based sharing with share_plus
/// - Web: Uses Blob URLs and download links (Web Share API when available)
class PlatformShareHelper {
  /// Share an image with text
  ///
  /// On mobile: Saves to temp file and shares via system share sheet
  /// On web: Creates download link or uses Web Share API if available
  ///
  /// Parameters:
  /// - [imageBytes]: PNG image data
  /// - [text]: Text to share along with image
  /// - [subject]: Email subject (mobile only)
  /// - [filename]: Suggested filename for the image
  static Future<void> shareImage({
    required Uint8List imageBytes,
    required String text,
    String? subject,
    required String filename,
  }) async {
    if (kIsWeb) {
      await shareImageWeb(
        imageBytes: imageBytes,
        text: text,
        filename: filename,
      );
    } else {
      await shareImageMobile(
        imageBytes: imageBytes,
        text: text,
        subject: subject,
        filename: filename,
      );
    }
  }

  /// Show a message to user after sharing/downloading
  static void showShareSuccess(BuildContext context, {required bool isWeb}) {
    final message = isWeb
        ? 'Image downloaded successfully'
        : 'Share sheet opened';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error message if sharing fails
  static void showShareError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to share: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
