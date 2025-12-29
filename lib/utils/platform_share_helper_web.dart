import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

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
      final blob = web.Blob(
        [imageBytes.toJS].toJS,
        web.BlobPropertyBag(type: 'image/png'),
      );
      final file = web.File(
        [blob].toJS,
        filename,
        web.FilePropertyBag(type: 'image/png'),
      );

      // Check if Web Share API is available and supports sharing files
      final navigator = web.window.navigator;
      final shareData = web.ShareData(
        files: [file].toJS,
        text: text,
      );

      // Try to share using Web Share API
      await navigator.share(shareData).toDart;
      return;
    } catch (e) {
      // Web Share API failed or doesn't support files
      // Fall through to download method
    }

    // Fallback: Download the image
    _downloadImage(imageBytes, filename);

    // Try to copy text to clipboard
    try {
      await web.window.navigator.clipboard.writeText(text).toDart;
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
  final blob = web.Blob(
    [imageBytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );

  // Create an object URL from the Blob
  final url = web.URL.createObjectURL(blob);

  // Create a temporary anchor element and trigger download
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();

  // Clean up
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
