import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile implementation of image sharing using File-based approach
Future<void> shareImageWeb({
  required Uint8List imageBytes,
  required String text,
  required String filename,
}) async {
  throw UnimplementedError('Web sharing called on mobile platform');
}

Future<void> shareImageMobile({
  required Uint8List imageBytes,
  required String text,
  String? subject,
  required String filename,
}) async {
  try {
    // Save to temporary file
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/$filename';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(imageBytes);

    // Share the image with text
    await Share.shareXFiles(
      [XFile(imagePath)],
      text: text,
      subject: subject,
    );

    // Clean up temporary file after a delay
    Future.delayed(const Duration(seconds: 30), () {
      if (imageFile.existsSync()) {
        imageFile.delete();
      }
    });
  } catch (e) {
    throw Exception('Failed to share image on mobile: $e');
  }
}
