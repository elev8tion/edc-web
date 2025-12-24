import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation of image sharing using Blob URLs and download links
Future<void> shareImageWeb({
  required Uint8List imageBytes,
  required String text,
  required String filename,
}) async {
  try {
    // Try Web Share API first (if available and supports files)
    try {
      // Create a Blob from the image bytes
      final blob = html.Blob([imageBytes], 'image/png');
      final file = html.File([blob], filename, {'type': 'image/png'});

      // Try to share using Web Share API
      await html.window.navigator.share({
        'files': [file],
        'text': text,
      });
      return;
    } catch (e) {
      // Web Share API failed or doesn't support files
      // Fall through to download method
    }

    // Fallback: Download the image
    _downloadImage(imageBytes, filename);

    // Try to copy text to clipboard
    try {
      await html.window.navigator.clipboard?.writeText(text);
    } catch (e) {
      // Clipboard write failed, ignore
    }
  } catch (e) {
    throw Exception('Failed to share image on web: $e');
  }
}

Future<void> shareImageMobile({
  required Uint8List imageBytes,
  required String text,
  String? subject,
  required String filename,
}) async {
  throw UnimplementedError('Mobile sharing called on web platform');
}

/// Download image by creating a temporary anchor element
void _downloadImage(Uint8List imageBytes, String filename) {
  // Create a Blob from the image bytes
  final blob = html.Blob([imageBytes], 'image/png');

  // Create an object URL from the Blob
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Create a temporary anchor element and trigger download
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();

  // Clean up
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
