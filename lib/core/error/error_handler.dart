import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'app_error.dart';

/// Centralized error handler for the application
class ErrorHandler {

  /// Convert any exception to an AppError
  static AppError handle(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    // Already an AppError
    if (error is AppError) {
      _logError(error, stackTrace: stackTrace, context: context);
      return error;
    }

    // Network errors
    if (error is SocketException) {
      final appError = AppError.network(
        message: 'No internet connection',
        details: error.message,
      );
      _logError(appError, stackTrace: stackTrace, context: context);
      return appError;
    }

    if (error is HttpException) {
      final statusCode = _extractStatusCode(error.message);
      final appError = AppError.api(
        message: 'HTTP error occurred',
        statusCode: statusCode,
        details: error.message,
      );
      _logError(appError, stackTrace: stackTrace, context: context);
      return appError;
    }

    // Database errors
    if (error is DatabaseException) {
      final appError = AppError.database(
        message: 'Database operation failed',
        details: error.toString(),
        severity: _getDatabaseSeverity(error),
      );
      _logError(appError, stackTrace: stackTrace, context: context);
      return appError;
    }

    // Validation errors
    if (error is FormatException) {
      const appError = AppError.validation(
        message: 'Invalid data format',
      );
      _logError(appError, stackTrace: stackTrace, context: context);
      return appError;
    }

    if (error is ArgumentError) {
      final appError = AppError.validation(
        message: error.message?.toString() ?? 'Invalid input',
      );
      _logError(appError, stackTrace: stackTrace, context: context);
      return appError;
    }

    // File system errors
    if (error is FileSystemException) {
      final appError = AppError.storage(
        message: 'File system error',
        path: error.path,
        details: error.message,
      );
      _logError(appError, stackTrace: stackTrace, context: context);
      return appError;
    }

    // Timeout errors
    if (error is TimeoutException) {
      const appError = AppError.network(
        message: 'Request timeout',
        details: 'The operation took too long to complete',
      );
      _logError(appError, stackTrace: stackTrace, context: context);
      return appError;
    }

    // Out of memory (common with AI models)
    if (error.toString().toLowerCase().contains('out of memory') ||
        error.toString().toLowerCase().contains('oom')) {
      final appError = AppError.ai(
        message: 'Insufficient memory',
        details: error.toString(),
        isOutOfMemory: true,
        severity: ErrorSeverity.error,
      );
      _logError(appError, stackTrace: stackTrace, context: context);
      return appError;
    }

    // Default unknown error
    final appError = AppError.unknown(
      message: 'Unexpected error',
      details: error.toString(),
    );
    _logError(appError, stackTrace: stackTrace, context: context);
    return appError;
  }

  /// Handle errors with async operations
  static Future<T> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final error = handle(e, stackTrace: stackTrace, context: context);
      if (fallbackValue != null) {
        debugPrint('Warning: Returning fallback value after error: $error');
        return fallbackValue;
      }
      rethrow;
    }
  }

  /// Handle errors with sync operations
  static T handleSync<T>(
    T Function() operation, {
    String? context,
    T? fallbackValue,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      final error = handle(e, stackTrace: stackTrace, context: context);
      if (fallbackValue != null) {
        debugPrint('Warning: Returning fallback value after error: $error');
        return fallbackValue;
      }
      rethrow;
    }
  }

  /// Log error with context
  static void _logError(
    AppError error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final message = context != null
        ? '[$context] ${error.technicalMessage}'
        : error.technicalMessage;

    switch (error.severity) {
      case ErrorSeverity.debug:
        debugPrint('Debug: $message');
        break;
      case ErrorSeverity.info:
        debugPrint('Info: $message');
        break;
      case ErrorSeverity.warning:
        debugPrint('Warning: $message');
        break;
      case ErrorSeverity.error:
        debugPrint('Error: $message');
        break;
      case ErrorSeverity.fatal:
        debugPrint('Fatal: $message');
        break;
    }

    // In production, also send to crash reporting service
    _sendToCrashReporting(error, stackTrace: stackTrace, context: context);
  }

  /// Extract HTTP status code from error message
  static int? _extractStatusCode(String message) {
    final pattern = RegExp(r'\b(\d{3})\b');
    final match = pattern.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Determine database error severity
  static ErrorSeverity _getDatabaseSeverity(DatabaseException error) {
    final message = error.toString().toLowerCase();
    if (message.contains('corrupt') || message.contains('malformed')) {
      return ErrorSeverity.fatal;
    }
    if (message.contains('constraint') || message.contains('unique')) {
      return ErrorSeverity.warning;
    }
    return ErrorSeverity.error;
  }

  /// Send error to crash reporting service (Firebase Crashlytics, Sentry, etc.)
  static void _sendToCrashReporting(
    AppError error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    // Only send in release mode
    if (!kReleaseMode) return;

    // Example:
    // FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stackTrace,
    //   reason: context,
    //   fatal: error.severity == ErrorSeverity.fatal,
    // );

    debugPrint('Would send to crash reporting: ${error.technicalMessage}');
  }

  /// Create database error with context
  static AppError databaseError({
    required String message,
    String? details,
    String? query,
    String? table,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    return AppError.database(
      message: message,
      details: details,
      query: query,
      table: table,
      severity: severity,
    );
  }

  /// Create AI error with context
  static AppError aiError({
    required String message,
    String? details,
    String? modelPath,
    bool isOutOfMemory = false,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    return AppError.ai(
      message: message,
      details: details,
      modelPath: modelPath,
      isOutOfMemory: isOutOfMemory,
      severity: severity,
    );
  }

  /// Create notification error with context
  static AppError notificationError({
    required String message,
    String? details,
    bool isPermissionDenied = false,
    ErrorSeverity severity = ErrorSeverity.warning,
  }) {
    return AppError.notification(
      message: message,
      details: details,
      isPermissionDenied: isPermissionDenied,
      severity: severity,
    );
  }

  /// Create service error with context
  static AppError serviceError({
    required String serviceName,
    required String operation,
    required String message,
    String? details,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    return AppError.service(
      serviceName: serviceName,
      operation: operation,
      message: message,
      details: details,
      severity: severity,
    );
  }
}