import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

/// Error severity levels
enum ErrorSeverity {
  debug,
  info,
  warning,
  error,
  fatal,
}

@freezed
class AppError with _$AppError {
  const factory AppError.network({
    required String message,
    String? details,
    @Default(ErrorSeverity.error) ErrorSeverity severity,
  }) = NetworkError;

  const factory AppError.database({
    required String message,
    String? details,
    @Default(ErrorSeverity.error) ErrorSeverity severity,
    String? query,
    String? table,
  }) = DatabaseError;

  const factory AppError.validation({
    required String message,
    String? field,
    @Default(ErrorSeverity.warning) ErrorSeverity severity,
  }) = ValidationError;

  const factory AppError.permission({
    required String message,
    String? permission,
    @Default(ErrorSeverity.warning) ErrorSeverity severity,
  }) = PermissionError;

  const factory AppError.unknown({
    required String message,
    String? details,
    @Default(ErrorSeverity.error) ErrorSeverity severity,
  }) = UnknownError;

  const factory AppError.api({
    required String message,
    int? statusCode,
    String? details,
    @Default(ErrorSeverity.error) ErrorSeverity severity,
  }) = ApiError;

  const factory AppError.ai({
    required String message,
    String? details,
    @Default(ErrorSeverity.error) ErrorSeverity severity,
    String? modelPath,
    @Default(false) bool isOutOfMemory,
  }) = AIError;

  const factory AppError.notification({
    required String message,
    String? details,
    @Default(ErrorSeverity.warning) ErrorSeverity severity,
    @Default(false) bool isPermissionDenied,
  }) = NotificationError;

  const factory AppError.storage({
    required String message,
    String? path,
    String? details,
    @Default(ErrorSeverity.error) ErrorSeverity severity,
  }) = StorageError;

  const factory AppError.service({
    required String serviceName,
    required String operation,
    required String message,
    String? details,
    @Default(ErrorSeverity.error) ErrorSeverity severity,
  }) = ServiceError;
}

extension AppErrorExtension on AppError {
  /// Get user-friendly error message (no technical jargon)
  String get userMessage {
    return when(
      network: (message, _, __) => 'No internet connection. Please check your network settings.',
      database: (message, _, __, ___, ____) => 'We couldn\'t access your data. Please try again.',
      validation: (message, _, __) => message,
      permission: (message, permission, _) {
        if (permission != null && permission.toLowerCase().contains('notification')) {
          return 'Please enable notifications in your device settings to receive daily reminders.';
        }
        return 'Please grant the necessary permissions in your device settings.';
      },
      unknown: (message, _, __) => 'Something unexpected happened. Please try again.',
      api: (message, statusCode, _, __) {
        if (statusCode == 404) {
          return 'The requested resource could not be found.';
        } else if (statusCode == 500) {
          return 'Our servers are experiencing issues. Please try again later.';
        }
        return 'We couldn\'t connect to the server. Please try again later.';
      },
      ai: (message, _, __, ___, isOOM) {
        if (isOOM) {
          return 'Your device doesn\'t have enough memory for AI features right now. Try closing other apps.';
        }
        return 'AI features couldn\'t be loaded. The app will use simplified responses.';
      },
      notification: (message, _, __, isPermissionDenied) {
        if (isPermissionDenied) {
          return 'Please enable notifications in your device settings to receive daily reminders.';
        }
        return 'We couldn\'t set up your reminder. Please try again.';
      },
      storage: (message, _, __, ___) => 'We couldn\'t access the requested file. Please try again.',
      service: (serviceName, operation, message, _, __) => 'Something went wrong. Please try again.',
    );
  }

  /// Check if error is retryable
  bool get isRetryable {
    return when(
      network: (_, __, ___) => true,
      database: (_, __, ___, ____, _____) => true,
      validation: (_, __, ___) => false,
      permission: (_, __, ___) => false,
      unknown: (_, __, ___) => true,
      api: (_, statusCode, __, ___) => statusCode != 404 && statusCode != 403,
      ai: (_, __, ___, ____, isOOM) => !isOOM,
      notification: (_, __, ___, isPermissionDenied) => !isPermissionDenied,
      storage: (_, __, ___, ____) => true,
      service: (_, __, ___, ____, _____) => true,
    );
  }

  /// Get error severity
  ErrorSeverity get severity {
    return when(
      network: (_, __, severity) => severity,
      database: (_, __, severity, ___, ____) => severity,
      validation: (_, __, severity) => severity,
      permission: (_, __, severity) => severity,
      unknown: (_, __, severity) => severity,
      api: (_, __, ___, severity) => severity,
      ai: (_, __, severity, ___, ____) => severity,
      notification: (_, __, severity, ___) => severity,
      storage: (_, __, ___, severity) => severity,
      service: (_, __, ___, ____, severity) => severity,
    );
  }

  /// Get technical error message for logging
  String get technicalMessage {
    return when(
      network: (message, details, _) => 'Network error: $message${details != null ? " - $details" : ""}',
      database: (message, details, _, query, table) {
        final parts = <String>[message];
        if (table != null) parts.add('table: $table');
        if (query != null) parts.add('query: $query');
        if (details != null) parts.add('details: $details');
        return 'Database error: ${parts.join(", ")}';
      },
      validation: (message, field, _) => 'Validation error: $message${field != null ? " (field: $field)" : ""}',
      permission: (message, permission, _) => 'Permission error: $message${permission != null ? " ($permission)" : ""}',
      unknown: (message, details, _) => 'Unknown error: $message${details != null ? " - $details" : ""}',
      api: (message, statusCode, details, _) => 'API error: $message (status: ${statusCode ?? "unknown"})${details != null ? " - $details" : ""}',
      ai: (message, details, _, modelPath, isOOM) {
        final parts = <String>[message];
        if (modelPath != null) parts.add('model: $modelPath');
        if (isOOM) parts.add('OOM: true');
        if (details != null) parts.add('details: $details');
        return 'AI error: ${parts.join(", ")}';
      },
      notification: (message, details, _, isPermissionDenied) => 'Notification error: $message${details != null ? " - $details" : ""}${isPermissionDenied ? " (permission denied)" : ""}',
      storage: (message, path, details, _) => 'Storage error: $message${path != null ? " at $path" : ""}${details != null ? " - $details" : ""}',
      service: (serviceName, operation, message, details, _) => 'Service error [$serviceName.$operation]: $message${details != null ? " - $details" : ""}',
    );
  }

  /// Convert to map for logging
  Map<String, dynamic> toMap() {
    return {
      'type': runtimeType.toString(),
      'userMessage': userMessage,
      'technicalMessage': technicalMessage,
      'severity': severity.name,
      'isRetryable': isRetryable,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}