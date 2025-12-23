import 'package:flutter/material.dart';
import '../error/app_error.dart';
import '../../theme/app_theme.dart';
import '../../utils/blur_dialog_utils.dart';

/// User-friendly error dialog widget
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      title: Row(
        children: [
          Icon(
            _getErrorIcon(),
            color: _getErrorColor(),
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Oops!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error.userMessage,
            style: const TextStyle(fontSize: 16),
          ),
          if (_shouldShowDetails()) ...[
            const SizedBox(height: 16),
            _buildDetailsSection(context),
          ],
        ],
      ),
      actions: [
        if (error.isRetryable && onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  IconData _getErrorIcon() {
    return error.when(
      network: (_, __, ___) => Icons.wifi_off_rounded,
      database: (_, __, ___, ____, _____) => Icons.storage_rounded,
      validation: (_, __, ___) => Icons.warning_rounded,
      permission: (_, __, ___) => Icons.lock_rounded,
      unknown: (_, __, ___) => Icons.error_outline_rounded,
      api: (_, __, ___, ____) => Icons.cloud_off_rounded,
      ai: (_, __, ___, ____, _____) => Icons.psychology_rounded,
      notification: (_, __, ___, ____) => Icons.notifications_off_rounded,
      storage: (_, __, ___, ____) => Icons.folder_off_rounded,
      service: (_, __, ___, ____, _____) => Icons.error_outline_rounded,
    );
  }

  Color _getErrorColor() {
    switch (error.severity) {
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
      case ErrorSeverity.fatal:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  bool _shouldShowDetails() {
    // Only show details in debug mode
    return false; // Change to kDebugMode for production
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: AppRadius.smallRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technical Details:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error.technicalMessage,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  static Future<void> show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showBlurredDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// Inline error widget for displaying errors in the UI
class InlineErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const InlineErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withValues(alpha: 0.1),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
        borderRadius: AppRadius.mediumRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(),
                color: _getBorderColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            error.userMessage,
            style: const TextStyle(fontSize: 14),
          ),
          if (error.isRetryable && onRetry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getBorderColor(),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    return error.when(
      network: (_, __, ___) => Icons.wifi_off_rounded,
      database: (_, __, ___, ____, _____) => Icons.storage_rounded,
      validation: (_, __, ___) => Icons.warning_rounded,
      permission: (_, __, ___) => Icons.lock_rounded,
      unknown: (_, __, ___) => Icons.error_outline_rounded,
      api: (_, __, ___, ____) => Icons.cloud_off_rounded,
      ai: (_, __, ___, ____, _____) => Icons.psychology_rounded,
      notification: (_, __, ___, ____) => Icons.notifications_off_rounded,
      storage: (_, __, ___, ____) => Icons.folder_off_rounded,
      service: (_, __, ___, ____, _____) => Icons.error_outline_rounded,
    );
  }

  Color _getBackgroundColor() {
    switch (error.severity) {
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
      case ErrorSeverity.fatal:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getBorderColor() {
    return _getBackgroundColor();
  }
}

/// Snackbar for showing error messages
class ErrorSnackBar {
  static void show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    final backgroundColor = error.severity == ErrorSeverity.warning
        ? Colors.orange
        : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIcon(error),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.userMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: error.isRetryable && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static IconData _getIcon(AppError error) {
    return error.when(
      network: (_, __, ___) => Icons.wifi_off_rounded,
      database: (_, __, ___, ____, _____) => Icons.storage_rounded,
      validation: (_, __, ___) => Icons.warning_rounded,
      permission: (_, __, ___) => Icons.lock_rounded,
      unknown: (_, __, ___) => Icons.error_outline_rounded,
      api: (_, __, ___, ____) => Icons.cloud_off_rounded,
      ai: (_, __, ___, ____, _____) => Icons.psychology_rounded,
      notification: (_, __, ___, ____) => Icons.notifications_off_rounded,
      storage: (_, __, ___, ____) => Icons.folder_off_rounded,
      service: (_, __, ___, ____, _____) => Icons.error_outline_rounded,
    );
  }
}
