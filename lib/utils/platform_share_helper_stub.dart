import 'dart:typed_data';

/// Stub implementation - should never be called
/// Real implementations are in platform_share_helper_mobile.dart and platform_share_helper_web.dart
Future<void> shareImageWeb({
  required Uint8List imageBytes,
  required String text,
  required String filename,
}) async {
  throw UnimplementedError('Platform-specific implementation not loaded');
}

Future<void> shareImageMobile({
  required Uint8List imageBytes,
  required String text,
  String? subject,
  required String filename,
}) async {
  throw UnimplementedError('Platform-specific implementation not loaded');
}
